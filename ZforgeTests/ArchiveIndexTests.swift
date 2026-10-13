import AppIntents
import CoreGraphics
import Foundation
import Synchronization
import Testing
@testable import Zforge

@Suite("Archive index contracts", .serialized)
struct ArchiveIndexTests {
    @MainActor @Test("The test host never starts the production archive index")
    func testHostIsolation() {
        #expect(!ArchiveIndexRuntime.shared.isStarted)
    }
    @Test("Archive filename recognition preserves multipart, Unicode, hidden and nonarchive boundaries")
    func archiveFilenameRecognition() {
        for name in ["Example.zip", "Example.ZIP", "Example.7z.001", "Example.zip.001", "Résumé.tar.gz", "Archive name.xz", ".Hidden.zip"] {
            #expect(ArchiveFormatRegistry.recognizes(name))
        }
        for name in ["Example.zip.txt", "Examplezip", ".zip", "zip", "Example.7z.002", "directory.zip/Readme.txt"] {
            #expect(!ArchiveFormatRegistry.recognizes(name))
        }
    }
    @Test("Archive entities expose the IndexedEntity contract")
    func indexedEntityMetadata() {
        let type: Any.Type = ZforgeArchiveEntity.self
        #expect(type is any IndexedEntity.Type)
    }

    @Test("Contextual grants notify already-open observers after successful persistence")
    func grantChangeNotification() async throws {
        let suite = "ArchiveIndexNotification-" + UUID().uuidString
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: root) }
        let count = Mutex(0)
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name("ZforgeAutomationGrantsChanged"), object: store, queue: nil) { _ in
            count.withLock { $0 += 1 }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        try await store.add(root)
        #expect(count.withLock { $0 } == 1)
        #expect(await store.authorizedFolders() == [root.path])
        try await store.add(root)
        #expect(count.withLock { $0 } == 1)
        await store.remove(root.path)
        #expect(count.withLock { $0 } == 2)
        #expect(await store.authorizedFolders().isEmpty)
    }
    @Test("A snapshot includes only verified visible direct archives and canonicalizes aliases")
    func snapshotBoundaries() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        #expect(try await fixture.discovery.snapshot().isEmpty)
        try await fixture.store.add(fixture.root)
        let nested = fixture.root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data().write(to: nested.appendingPathComponent("Nested.zip"))
        try Data().write(to: fixture.root.appendingPathComponent(".Hidden.zip"))
        let outside = fixture.container.appendingPathComponent("Outside.zip")
        try Data().write(to: outside)
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("Escape.zip"), withDestinationURL: outside)
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("Alias.zip"), withDestinationURL: fixture.archive)
        #expect(try await fixture.discovery.snapshot().map(\.id) == [fixture.archive.path])
    }

    @Test("File links do not publish hidden or nested targets into the direct-child archive index")
    func snapshotFileLinkBoundary() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let hidden = fixture.root.appendingPathComponent(".Private.zip")
        try Data().write(to: hidden)
        let nested = fixture.root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        let nestedArchive = nested.appendingPathComponent("Private.zip")
        try Data().write(to: nestedArchive)
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("HiddenLink.zip"), withDestinationURL: hidden)
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("NestedLink.zip"), withDestinationURL: nestedArchive)
        let result = try await fixture.discovery.snapshot()
        #expect(result.map(\.id) == [fixture.archive.path])
        #expect(result.first?.presentationPaths == [fixture.archive.path])
    }

    @Test("Launch removes stale data; unchanged snapshots avoid writes; rename and deletion remove old identifiers")
    func indexLifecycle() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingArchiveIndex()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        try await fixture.store.add(fixture.root)
        _ = try await coordinator.reconcile()
        #expect(await writer.resetCount == 1)
        #expect(await writer.ids == [fixture.archive.path])
        let before = await writer.writeCount
        _ = try await coordinator.reconcile()
        #expect(await writer.writeCount == before)
        let renamed = fixture.root.appendingPathComponent("Renamed.zip")
        try FileManager.default.moveItem(at: fixture.archive, to: renamed)
        _ = try await coordinator.reconcile()
        #expect(await writer.ids == [renamed.path])
        #expect(await writer.removals.last == [fixture.archive.path])
        try FileManager.default.removeItem(at: renamed)
        _ = try await coordinator.reconcile()
        #expect(await writer.ids.isEmpty)
    }

    @Test("Revocation removes metadata, and reauthorization rebuilds the index from current files")
    func indexRevocationAndReindex() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingArchiveIndex()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        try await fixture.store.add(fixture.root)
        _ = try await coordinator.reconcile()
        await fixture.store.remove(fixture.root.path)
        #expect(try await coordinator.reconcile().isEmpty)
        #expect(await writer.ids.isEmpty)
        try await fixture.store.add(fixture.root)
        _ = try await coordinator.reconcile(reset: true)
        #expect(await writer.ids == [fixture.archive.path])
        #expect(await writer.resetCount == 2)
    }

    @Test("Publication failure clears partial metadata and the next request fully recovers")
    func indexFailureRecovery() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let writer = RecordingArchiveIndex()
        await writer.failNextWrite()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        await #expect(throws: AutomationError.notFound) { _ = try await coordinator.reconcile() }
        #expect(await writer.ids.isEmpty)
        #expect(await writer.resetCount == 2)
        _ = try await coordinator.reconcile()
        #expect(await writer.ids == [fixture.archive.path])
        #expect(await writer.resetCount == 3)
    }

    @Test("Cancelled publication clears partial results and overlapping reconciliations are refused")
    func indexCancellationAndConcurrency() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let writer = RecordingArchiveIndex()
        await writer.suspendNextWrite()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        let first = Task { try await coordinator.reconcile() }
        await writer.waitForWrite()
        await #expect(throws: AutomationError.busy) { _ = try await coordinator.reconcile() }
        first.cancel()
        await writer.resumeWrite()
        await #expect(throws: CancellationError.self) { _ = try await first.value }
        #expect(await writer.ids.isEmpty)
        _ = try await coordinator.reconcile()
        #expect(await writer.ids == [fixture.archive.path])
    }

    @Test("Duplicate names keep distinct targets and donation payloads have at most 100 entities")
    func duplicateNamesAndBatches() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let other = fixture.container.appendingPathComponent("Other")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: false)
        let duplicate = other.appendingPathComponent(fixture.archive.lastPathComponent)
        try Data().write(to: duplicate)
        try await fixture.store.add(other)
        for n in 0..<101 { try Data().write(to: fixture.root.appendingPathComponent("Batch-\(n).zip")) }
        let writer = RecordingArchiveIndex()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        let result = try await coordinator.reconcile()
        #expect(result.count == 103)
        #expect(Set(result.filter { $0.name == fixture.archive.lastPathComponent }.map(\.id)) == [fixture.archive.path, duplicate.path])
        #expect(await writer.batchSizes == [100, 3])
    }

    @MainActor @Test("Onscreen context disappears on revocation and never includes folders, hidden files or archive members")
    func contextEligibility() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        let item = try await FileSystemService().item(at: fixture.archive)
        let catalog = ArchiveContextCatalog()
        #expect(catalog.identifier(for: item) == nil)
        let entities = [ZforgeArchiveEntity(url: fixture.archive)]
        let associations = try await ArchiveContextPreparation.shared.identifiers(for: entities)
        catalog.replace(entities, associations: associations)
        let identifier = try #require(catalog.identifier(for: item))
        if #available(macOS 27.0, *) {
            let fileID = try #require(FileEntityIdentifier.entityIdentifier(for: identifier.identifier))
            #expect(try await fileID.fileURL?.path == fixture.archive.path)
        } else { #expect(identifier.identifier == fixture.archive.path) }
        let folder = try await FileSystemService().item(at: fixture.root)
        #expect(catalog.identifier(for: folder) == nil)
        catalog.clear()
        #expect(catalog.identifier(for: item) == nil)
    }

    @Test("Replacing an archive at the same path republishes its file identity")
    func replacedFileIdentity() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let writer = RecordingArchiveIndex()
        let coordinator = ArchiveIndexCoordinator(discovery: fixture.discovery, writer: writer)
        _ = try await coordinator.reconcile()
        #expect(await writer.writeCount == 1)
        let replacement = fixture.root.appendingPathComponent("Replacement.tmp")
        try Data("Replacement archive identity fixture".utf8).write(to: replacement)
        _ = try FileManager.default.replaceItemAt(fixture.archive, withItemAt: replacement)
        _ = try await coordinator.reconcile()
        #expect(await writer.writeCount == 2)
    }

    @MainActor @Test("The running index follows grant revocation and clears already-published context")
    func runtimeRevocation() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let writer = RecordingArchiveIndex()
        let catalog = ArchiveContextCatalog()
        let runtime = ArchiveIndexRuntime(access: fixture.store, writer: writer, catalog: catalog)
        defer { runtime.stop() }
        try await runtime.reindex()
        #expect(catalog.identifiers == [fixture.archive.path])
        await fixture.store.remove(fixture.root.path)
        try await runtime.reindex()
        #expect(catalog.identifiers.isEmpty)
        #expect(await writer.ids.isEmpty)
        #expect(!catalog.unavailable)
    }

    @MainActor @Test("A failed root monitor clears stale index data and exposes retry feedback")
    func runtimeMonitorFailure() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        let writer = RecordingArchiveIndex()
        let catalog = ArchiveContextCatalog()
        let runtime = ArchiveIndexRuntime(access: MissingIndexRoot(root: fixture.root.appendingPathComponent("Missing")), writer: writer, catalog: catalog)
        defer { runtime.stop() }
        await #expect(throws: AutomationError.notFound) { try await runtime.reindex() }
        #expect(catalog.unavailable)
        #expect(catalog.identifiers.isEmpty)
        #expect(await writer.ids.isEmpty)
    }

    @MainActor @Test("Canonical Spotlight identifiers also identify authorized archive views reached through a directory alias")
    func contextDirectoryAlias() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        let alias = fixture.container.appendingPathComponent("RootAlias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.root)
        try await fixture.store.add(alias)
        let presented = alias.appendingPathComponent(fixture.archive.lastPathComponent)
        let item = try await FileSystemService().item(at: presented)
        let catalog = ArchiveContextCatalog()
        let entities = try await fixture.discovery.snapshot()
        let associations = try await ArchiveContextPreparation.shared.identifiers(for: entities)
        catalog.replace(entities, associations: associations)
        let identifier = try #require(catalog.identifier(for: item))
        if #available(macOS 27.0, *) {
            let fileID = try #require(FileEntityIdentifier.entityIdentifier(for: identifier.identifier))
            #expect(try await fileID.fileURL?.path == fixture.archive.path)
        } else { #expect(identifier.identifier == fixture.archive.path) }
    }

    @MainActor @Test("An indexed physical archive retains its onscreen identity through a different directory presentation")
    func contextDifferentPresentation() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let alias = fixture.container.appendingPathComponent("PresentationAlias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.root)
        let presented = alias.appendingPathComponent(fixture.archive.lastPathComponent)
        let item = try await FileSystemService().item(at: presented)
        #expect(item.localURL?.path == presented.path)
        let entities = try await fixture.discovery.snapshot()
        #expect(entities.first?.presentationPaths == [fixture.archive.path])
        #expect(item.fileIdentity != nil)
        #expect(item.fileIdentity == entities.first?.fileIdentity)
        let associations = try await ArchiveContextPreparation.shared.identifiers(for: entities)
        let catalog = ArchiveContextCatalog()
        catalog.replace(entities, associations: associations)
        #expect(catalog.identifier(for: item) == associations[fixture.archive.path])
        let link = fixture.root.appendingPathComponent("FileLink.zip")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: fixture.archive)
        let linkedItem = try await FileSystemService().item(at: link)
        #expect(catalog.identifier(for: linkedItem) == nil)
        catalog.clear()
        #expect(catalog.identifier(for: item) == nil)
    }

    @MainActor @Test("Ambiguous hard-link identities require the indexed presentation path")
    func contextAmbiguousPhysicalIdentity() async throws {
        let fixture = try IndexFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let other = fixture.root.appendingPathComponent("Other.zip")
        try FileManager.default.linkItem(at: fixture.archive, to: other)
        let alias = fixture.container.appendingPathComponent("PresentationAlias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.root)
        let entities = try await fixture.discovery.snapshot()
        #expect(entities.count == 2)
        #expect(entities.first?.fileIdentity != nil)
        #expect(entities.first?.fileIdentity == entities.last?.fileIdentity)
        let associations = try await ArchiveContextPreparation.shared.identifiers(for: entities)
        let catalog = ArchiveContextCatalog()
        catalog.replace(entities, associations: associations)
        for url in [fixture.archive, other] {
            let direct = try await FileSystemService().item(at: url)
            #expect(catalog.identifier(for: direct) == associations[url.path])
            let presented = try await FileSystemService().item(at: alias.appendingPathComponent(url.lastPathComponent))
            #expect(catalog.identifier(for: presented) == nil)
        }
    }

    @Test("Context requests distinguish the selected item and the visible rectangle")
    func contextSelection() {
        let bounds = CGRect(x: 10, y: 20, width: 90, height: 30)
        #expect(ArchiveContextSelection.isRequested([.selected], bounds: bounds, isSelected: true))
        #expect(!ArchiveContextSelection.isRequested([.selected], bounds: bounds, isSelected: false))
        #expect(ArchiveContextSelection.isRequested([.visible(rect: bounds)], bounds: bounds, isSelected: false))
        #expect(!ArchiveContextSelection.isRequested([.visible(rect: CGRect(x: 200, y: 200, width: 10, height: 10))], bounds: bounds, isSelected: true))
        #expect(!ArchiveContextSelection.isRequested([], bounds: bounds, isSelected: true))
    }

}

private struct IndexFixture: Sendable {
    let container: URL
    let root: URL
    let archive: URL
    let suite: String
    let store: AutomationGrantStore
    let discovery: AutomationArchiveEntities
    init() throws {
        container = FileManager.default.temporaryDirectory.appendingPathComponent("ArchiveIndex-" + UUID().uuidString).resolvingSymlinksInPath()
        root = container.appendingPathComponent("Allowed")
        archive = root.appendingPathComponent("Example.zip")
        suite = "ArchiveIndex-" + UUID().uuidString
        store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        discovery = AutomationArchiveEntities(access: store)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("Archive metadata fixture".utf8).write(to: archive)
    }
    func cleanUp() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: container)
    }
}

private actor RecordingArchiveIndex: ArchiveIndexWriting {
    private(set) var ids: Set<String> = ["/stale/Example.zip"]
    private(set) var removals: [[String]] = []
    private(set) var resetCount = 0
    private(set) var writeCount = 0
    private(set) var batchSizes: [Int] = []
    private var failWrite = false
    private var suspendWrite = false
    private var writing = false
    private var waiter: CheckedContinuation<Void, Never>?
    private var suspended: CheckedContinuation<Void, Never>?
    func reset() { resetCount += 1; ids = [] }
    func remove(_ identifiers: [String]) { removals.append(identifiers); ids.subtract(identifiers) }
    func upsert(_ entities: [ZforgeArchiveEntity]) async throws {
        writeCount += 1
        batchSizes.append(entities.count)
        ids.formUnion(entities.map(\.id))
        if failWrite { failWrite = false; throw AutomationError.notFound }
        if suspendWrite {
            suspendWrite = false
            writing = true
            await withCheckedContinuation { continuation in
                suspended = continuation
                waiter?.resume(); waiter = nil
            }
            writing = false
        }
    }
    func failNextWrite() { failWrite = true }
    func suspendNextWrite() { suspendWrite = true }
    func waitForWrite() async {
        if writing { return }
        await withCheckedContinuation { waiter = $0 }
    }
    func resumeWrite() { suspended?.resume(); suspended = nil }
}

private actor MissingIndexRoot: AutomationAuthorizing {
    let root: URL
    init(root: URL) { self.root = root }
    func authorizedFolders() -> [String] { [root.path] }
    func authorize(_ urls: [URL]) -> AutomationAccessLease { AutomationAccessLease() }
}
