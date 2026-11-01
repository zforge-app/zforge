import AppIntents
import CoreSpotlight
import Foundation
import Testing
@testable import Zforge

@Suite("File-schema archive action contracts")
struct FileArchiveIntentTests {
    enum Transport: CaseIterable, Sendable { case independent, codable, systemString }

    @available(macOS 27.0, *)
    @Test("System transport resolves the authorized archive and preserves the exact requested identity", arguments: Transport.allCases)
    func transportedIdentity(_ transport: Transport) async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let entity = try ZforgeFileArchiveEntity.published(ZforgeArchiveEntity(url: fixture.archive))
        let incoming: FileEntityIdentifier
        switch transport {
        case .independent: incoming = try .file(url: fixture.archive)
        case .codable: incoming = try JSONDecoder().decode(FileEntityIdentifier.self, from: JSONEncoder().encode(entity.id))
        case .systemString: incoming = try #require(FileEntityIdentifier.entityIdentifier(for: entity.id.entityIdentifierString))
        }
        let result = try await fixture.query.entities(for: [incoming])
        #expect(result.count == 1)
        #expect(result.first?.archive.id == fixture.archive.path)
        #expect(result.first?.id == incoming)
        #expect(result.first?.id.entityIdentifierString == incoming.entityIdentifierString)
    }

    @available(macOS 27.0, *)
    @Test("Explicit paths are text-only drafts until contextual execution obtains consent")
    func explicitPathDraft() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let result = try await fixture.query.entities(matching: fixture.archive.path)
        let entity = try #require(result.first)
        #expect(entity.id.isDraft)
        #expect(entity.id.draftIdentifier == fixture.archive.path)
        #expect(entity.attributeSet.contentURL == nil)
        #expect(await fixture.store.authorizedFolders().isEmpty)
        let restored = try await fixture.query.entities(for: [entity.id])
        #expect(restored.first?.id == entity.id)
        let missing = fixture.root.appendingPathComponent("Missing.zip")
        #expect(try await fixture.query.entities(matching: missing.path).first?.id.draftIdentifier == missing.path)
        #expect(!FileManager.default.fileExists(atPath: missing.path))
    }

    @available(macOS 27.0, *)
    @Test("Name discovery publishes real file references only under current grants")
    func authorizedNames() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        #expect(try await fixture.query.entities(matching: "Example").isEmpty)
        try await fixture.store.add(fixture.root)
        let entity = try #require(try await fixture.query.entities(matching: "Example").first)
        #expect(!entity.id.isDraft)
        #expect(try await entity.id.fileURL?.path == fixture.archive.path)
        #expect(entity.attributeSet.contentURL?.path == fixture.archive.path)
        await fixture.store.remove(fixture.root.path)
        #expect(try await fixture.query.entities(matching: "Example").isEmpty)
        #expect(try await fixture.query.suggestedEntities().isEmpty)
    }

    @available(macOS 27.0, *)
    @Test("Directory and file aliases deduplicate physically while retaining the first requested identity")
    func aliases() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let alias = fixture.root.appendingPathComponent("Alias.zip")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.archive)
        let id = FileEntityIdentifier.draft(identifier: alias.path)
        let result = try await fixture.query.entities(for: [id, .draft(identifier: fixture.archive.path), id])
        #expect(result.count == 1)
        #expect(result.first?.id == id)
        #expect(result.first?.archive.id == alias.path)
    }

    @available(macOS 27.0, *)
    @Test("Malformed, oversized and cancelled requests never create grants")
    func argumentBoundaries() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        for path in ["relative.zip", "bad\0name", String(repeating: "/", count: 4097)] {
            await #expect(throws: AutomationError.invalidArguments) { _ = try await fixture.query.entities(for: [.draft(identifier: path)]) }
        }
        await #expect(throws: AutomationError.invalidArguments) {
            _ = try await fixture.query.entities(for: Array(repeating: .draft(identifier: fixture.archive.path), count: 257))
        }
        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await fixture.query.entities(for: [])
        }
        await #expect(throws: CancellationError.self) { _ = try await cancelled.value }
        #expect(await fixture.store.authorizedFolders().isEmpty)
    }

    @available(macOS 27.0, *)
    @MainActor @Test("File identity never replaces live consent and embedded paths cannot redirect opening")
    func permissionAndTarget() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let other = fixture.root.appendingPathComponent("Other.zip")
        try Data().write(to: other)
        let requested = try ZforgeFileArchiveEntity.published(ZforgeArchiveEntity(url: fixture.archive))
        let recorder = FileOpenRecorder()
        var intent = OpenZforgeFileContentIntent()
        intent.target = ZforgeFileArchiveEntity(archive: ZforgeArchiveEntity(url: other), id: requested.id)
        intent.permissions = NonInteractiveAutomationPermissions(store: fixture.store)
        intent.opener = { url, _ in await recorder.open(url) }
        _ = try await intent.perform()
        #expect(await recorder.paths == [fixture.archive.path])
        await fixture.store.remove(fixture.root.path)
        await #expect(throws: AutomationError.authorizationRequired) { _ = try await intent.perform() }
        #expect(await recorder.paths == [fixture.archive.path])
    }

    @available(macOS 27.0, *)
    @MainActor @Test("A draft requests the exact folder and continues the same invocation after consent")
    func contextualConsent() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let recorder = FileOpenRecorder()
        var intent = OpenZforgeFileContentIntent()
        intent.target = ZforgeFileArchiveEntity.candidate(ZforgeArchiveEntity(url: fixture.archive))
        intent.permissions = ContextualAutomationAccess(store: fixture.store, picker: { folder in
            #expect(folder == fixture.root)
            return folder
        })
        intent.opener = { url, _ in await recorder.open(url) }
        _ = try await intent.perform()
        #expect(await recorder.paths == [fixture.archive.path])
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
    }

    @available(macOS 27.0, *)
    @MainActor @Test("Cancelling draft consent opens nothing and persists no grant")
    func consentCancellation() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let recorder = FileOpenRecorder()
        var intent = OpenZforgeFileContentIntent()
        intent.target = ZforgeFileArchiveEntity.candidate(ZforgeArchiveEntity(url: fixture.archive))
        intent.permissions = ContextualAutomationAccess(store: fixture.store, picker: { _ in nil })
        intent.opener = { url, _ in await recorder.open(url) }
        await #expect(throws: CancellationError.self) { _ = try await intent.perform() }
        #expect(await recorder.paths.isEmpty)
        #expect(await fixture.store.authorizedFolders().isEmpty)
    }

    @available(macOS 27.0, *)
    @Test("Deleted authorized drafts disappear when rehydrated")
    func deletedTarget() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let draft = FileEntityIdentifier.draft(identifier: fixture.archive.path)
        try FileManager.default.removeItem(at: fixture.archive)
        #expect(try await fixture.query.entities(for: [draft]).isEmpty)
    }

    @available(macOS 27.0, *)
    @Test("Spotlight removal uses the published identity after the file is deleted")
    func publishedDeletion() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingFileArchiveIndex()
        let publication = ArchiveFilePublication(writer: writer)
        let archive = ZforgeArchiveEntity(url: fixture.archive)
        try await publication.upsert([archive])
        let identity = try #require(await writer.entities.first?.id)
        let context = try #require(try await publication.contextIdentifiers(for: [archive])[archive.id])
        #expect(context.identifier == identity.entityIdentifierString)
        try FileManager.default.removeItem(at: fixture.archive)
        try await publication.remove([archive.id])
        #expect(await writer.removed == [identity])
        await #expect(throws: AutomationError.notFound) { _ = try await publication.contextIdentifiers(for: [archive]) }
    }

    @available(macOS 27.0, *)
    @Test("Failed donation publishes no context and failed deletion retains its identity for cleanup")
    func publicationFailure() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingFileArchiveIndex()
        let publication = ArchiveFilePublication(writer: writer)
        let archive = ZforgeArchiveEntity(url: fixture.archive)
        await writer.failNext()
        await #expect(throws: AutomationError.notFound) { try await publication.upsert([archive]) }
        await #expect(throws: AutomationError.notFound) { _ = try await publication.contextIdentifiers(for: [archive]) }
        try await publication.upsert([archive])
        let context = try await publication.contextIdentifiers(for: [archive])
        await writer.failNext()
        await #expect(throws: AutomationError.notFound) { try await publication.remove([archive.id]) }
        #expect(try await publication.contextIdentifiers(for: [archive])[archive.id]?.identifier == context[archive.id]?.identifier)
        await writer.failNextDonation()
        await #expect(throws: AutomationError.notFound) { try await publication.upsert([archive]) }
        await #expect(throws: AutomationError.notFound) { _ = try await publication.contextIdentifiers(for: [archive]) }
        try await publication.reset()
        await #expect(throws: AutomationError.notFound) { _ = try await publication.contextIdentifiers(for: [archive]) }
    }

    @available(macOS 27.0, *)
    @Test("Republishing a replaced file removes its previous donated identity")
    func publishedReplacement() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingFileArchiveIndex()
        let publication = ArchiveFilePublication(writer: writer)
        let archive = ZforgeArchiveEntity(url: fixture.archive)
        try await publication.upsert([archive])
        let previous = try #require(await writer.entities.first?.id)
        let replacement = fixture.root.appendingPathComponent("Replacement.tmp")
        try Data("Published replacement fixture".utf8).write(to: replacement)
        _ = try FileManager.default.replaceItemAt(fixture.archive, withItemAt: replacement)
        try await publication.upsert([archive])
        #expect(await writer.removed == [previous])
        let current = try #require(await writer.entities.first?.id)
        #expect(current != previous)
        #expect(try await publication.contextIdentifiers(for: [archive])[archive.id]?.identifier == current.entityIdentifierString)
    }

    @available(macOS 27.0, *)
    @Test("Donation batches above 100 are refused without writing")
    func publicationBudget() async throws {
        let fixture = try FileArchiveFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingFileArchiveIndex()
        let publication = ArchiveFilePublication(writer: writer)
        await #expect(throws: AutomationError.listingTooLarge) {
            try await publication.upsert(Array(repeating: ZforgeArchiveEntity(url: fixture.archive), count: 101))
        }
        #expect(await writer.entities.isEmpty)
    }
}

@available(macOS 27.0, *)
private struct FileArchiveFixture: Sendable {
    let root: URL
    let archive: URL
    let suite: String
    let store: AutomationGrantStore
    var query: ZforgeFileArchiveQuery { ZforgeFileArchiveQuery(service: AutomationArchiveEntities(access: store)) }
    init() throws {
        let physicalPath = FileManager.default.temporaryDirectory.appendingPathComponent("FileArchive-" + UUID().uuidString).resolvingSymlinksInPath().path
        root = URL(fileURLWithPath: physicalPath, isDirectory: true)
        archive = root.appendingPathComponent("Example.zip")
        suite = "ZforgeTestSuite.FileArchive-" + UUID().uuidString
        store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("File identity fixture".utf8).write(to: archive)
    }
    func cleanUp() {
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
        try? FileManager.default.removeItem(at: root)
    }
}

private actor FileOpenRecorder {
    private(set) var paths: [String] = []
    func open(_ url: URL) { paths.append(url.path) }
}

@available(macOS 27.0, *)
private actor RecordingFileArchiveIndex: FileArchiveIndexWriting {
    private(set) var entities: [ZforgeFileArchiveEntity] = []
    private(set) var removed: [FileEntityIdentifier] = []
    private var fail = false
    private var failDonation = false
    func failNext() { fail = true }
    func failNextDonation() { failDonation = true }
    private func check() throws {
        if fail { fail = false; throw AutomationError.notFound }
    }
    func reset() throws { try check(); entities = [] }
    func remove(_ identifiers: [FileEntityIdentifier]) throws { try check(); removed += identifiers }
    func upsert(_ entities: [ZforgeFileArchiveEntity]) throws {
        try check()
        if failDonation { failDonation = false; throw AutomationError.notFound }
        self.entities = entities
    }
}
