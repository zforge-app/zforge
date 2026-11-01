import Foundation
import AppIntents
import Testing
@testable import Zforge

@Suite("Siri archive action contracts")
struct SiriArchiveIntentTests {
    @Test("Modern archive metadata pairs the file schema with its system-open action")
    func fileSchemaMetadata() throws {
        let file = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Metadata.appintents/extract.actionsdata")
        let payload = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let entities = try #require(payload["entities"] as? [String: [String: Any]])
        let entity = try #require(entities["ZforgeFileArchiveEntity"])
        let schemas = try #require(entity["assistantDefinedSchemas"] as? [[String: Any]])
        #expect(schemas.count == 1)
        #expect(schemas.first?["domain"] as? String == "files")
        #expect(schemas.first?["name"] as? String == "FileEntity")
        let actions = try #require(payload["actions"] as? [String: [String: Any]])
        let action = try #require(actions["OpenZforgeFileContentIntent"])
        let actionSchemas = try #require(action["assistantDefinedSchemas"] as? [[String: Any]])
        #expect(actionSchemas.first?["domain"] as? String == "system")
        #expect(actionSchemas.first?["name"] as? String == "OpenIntent")
        let parameters = try #require(action["parameters"] as? [[String: Any]])
        let valueType = try #require(parameters.first?["valueType"] as? [String: Any])
        let target = try #require(valueType["entity"] as? [String: Any])
        let wrapper = try #require(target["wrapper"] as? [String: Any])
        #expect(wrapper["typeName"] as? String == "ZforgeFileArchiveEntity")
        #expect(action["isDiscoverable"] as? Bool == true)
        #expect(actions["OpenZforgeContentIntent"]?["isDiscoverable"] as? Bool == false)
        #expect(actions["OpenZforgeIndexedArchiveIntent"] != nil)
    }

    @Test("The installed action metadata publishes the generic system-open schema")
    func systemOpenMetadata() throws {
        let file = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Metadata.appintents/extract.actionsdata")
        let payload = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let actions = try #require(payload["actions"] as? [String: [String: Any]])
        let action = try #require(actions["OpenZforgeContentIntent"])
        let schemas = try #require(action["assistantDefinedSchemas"] as? [[String: Any]])
        #expect(schemas.count == 1)
        #expect(schemas.first?["domain"] as? String == "system")
        #expect(schemas.first?["name"] as? String == "OpenIntent")
        let availability = try #require(action["availabilityAnnotations"] as? [String: [String: String]])
        #expect(availability["LNPlatformNameMACOS"]?["introducedVersion"] == "27.0")
        #expect(actions["CompressZforgeFilesIntent"] != nil)
        #expect(actions["ExtractZforgeArchiveIntent"] != nil)
        #expect(actions["TestZforgeArchiveIntent"] != nil)
        #expect(actions["OpenZforgeArchiveIntent"] != nil)
    }

    @Test("Name resolution returns only visible direct archives inside authorized scopes")
    func nameResolution() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        try Data("Hidden fixture".utf8).write(to: fixture.root.appendingPathComponent(".Hidden.zip"))
        try FileManager.default.createDirectory(at: fixture.root.appendingPathComponent("Folder.zip"), withIntermediateDirectories: false)
        let nested = fixture.root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("Nested fixture".utf8).write(to: nested.appendingPathComponent("Nested.zip"))
        let result = try await fixture.service.matching("zip")
        #expect(result.map(\.id) == [fixture.archive.path])
        #expect(result.first?.name == "Example.zip")
        #expect(try await fixture.service.matching("missing").isEmpty)
    }

    @Test("Entity identifiers preserve protected paths and candidates while authorized missing content disappears")
    func identifiersAndRevocation() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let protected = "/.nofollow" + AutomationPath.resolvedForAccess(fixture.archive).path
        #expect(try await fixture.service.entities(for: [protected]).map(\.id) == [protected])
        #expect(try await fixture.service.matching(fixture.archive.path).map(\.id) == [fixture.archive.path])
        await fixture.store.remove(fixture.root.path)
        #expect(try await fixture.service.entities(for: [protected]).map(\.id) == [protected])
        try await fixture.store.add(fixture.root)
        try FileManager.default.removeItem(at: fixture.archive)
        #expect(try await fixture.service.entities(for: [fixture.archive.path]).isEmpty)
    }

    @Test("Outside symlinks never authorize access or appear in name discovery and authorized aliases resolve once")
    func entityBoundaries() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        let outside = fixture.container.appendingPathComponent("Outside.zip")
        try Data("Outside fixture".utf8).write(to: outside)
        let escape = fixture.root.appendingPathComponent("Escape.zip")
        try FileManager.default.createSymbolicLink(at: escape, withDestinationURL: outside)
        let alias = fixture.root.appendingPathComponent("Alias.zip")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.archive)
        try await fixture.store.add(fixture.root)
        #expect(try await fixture.service.entities(for: [escape.path, fixture.archive.path, alias.path]).map(\.id) == [escape.path, fixture.archive.path])
        await #expect(throws: AutomationError.authorizationRequired) { _ = try await fixture.store.authorize([escape]) }
        #expect(try await fixture.service.matching("Escape").isEmpty)
    }

    @Test("Malformed and oversized entity requests are refused without creating grants")
    func entityArguments() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        for query in ["", "bad\0name", String(repeating: "x", count: 4097)] {
            await #expect(throws: AutomationError.invalidArguments) { _ = try await fixture.service.matching(query) }
        }
        await #expect(throws: AutomationError.invalidArguments) { _ = try await fixture.service.entities(for: ["relative.zip"]) }
        await #expect(throws: AutomationError.invalidArguments) { _ = try await fixture.service.entities(for: Array(repeating: fixture.archive.path, count: 257)) }
        #expect(await fixture.store.authorizedFolders().isEmpty)
    }

    @Test("An explicitly supplied path creates only a candidate and does not grant filesystem access")
    func explicitPathCandidate() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        #expect(try await fixture.service.matching(fixture.archive.path).map(\.id) == [fixture.archive.path])
        #expect(await fixture.store.authorizedFolders().isEmpty)
        #expect(try await fixture.service.entities(for: [fixture.archive.path]).map(\.id) == [fixture.archive.path])
        await #expect(throws: AutomationError.authorizationRequired) { _ = try await fixture.store.authorize([fixture.archive]) }
    }

    @Test("Name results are deterministic and limited to 100 archive choices")
    func resultLimit() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        var expected = [fixture.archive.path]
        for index in 0..<110 {
            let url = fixture.root.appendingPathComponent(String(format: "Choice-%03d.zip", index))
            try Data("Choice fixture".utf8).write(to: url)
            expected.append(url.path)
        }
        #expect(try await fixture.service.matching("zip").map(\.id) == Array(expected.sorted().prefix(100)))
    }

    @Test("The 10000-candidate discovery budget refuses oversized folders")
    func discoveryBudget() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        for index in 0..<10_000 {
            try Data().write(to: fixture.root.appendingPathComponent("Candidate-\(index).txt"))
        }
        await #expect(throws: AutomationError.listingTooLarge) { _ = try await fixture.service.matching("missing") }
    }

    @Test("A cancelled discovery request returns cancellation rather than stale choices")
    func discoveryCancellation() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await fixture.service.matching("zip")
        }
        await #expect(throws: CancellationError.self) { _ = try await task.value }
    }

    @Test("Overlapping name queries are refused while the first waits for its authorized roots")
    func discoveryConcurrency() async throws {
        let access = SuspendedArchiveAccess()
        let service = AutomationArchiveEntities(access: access)
        let first = Task { try await service.matching("zip") }
        await access.waitUntilRequested()
        await #expect(throws: AutomationError.busy) { _ = try await service.matching("zip") }
        await access.resume()
        #expect(try await first.value.isEmpty)
        #expect(try await service.matching("zip").isEmpty)
    }

    @Test("Cancellation while resolving roots prevents publication and releases the query slot")
    func suspendedDiscoveryCancellation() async throws {
        let access = SuspendedArchiveAccess()
        let service = AutomationArchiveEntities(access: access)
        let first = Task { try await service.matching("zip") }
        await access.waitUntilRequested()
        first.cancel()
        await access.resume()
        await #expect(throws: CancellationError.self) { _ = try await first.value }
        #expect(try await service.matching("zip").isEmpty)
    }

    @available(macOS 27.0, *)
    @MainActor @Test("The Siri open action uses the shared permission boundary and preserves its target")
    func performOpen() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let record = ArchiveOpenRecorder()
        var intent = OpenZforgeContentIntent()
        intent.target = ZforgeArchiveEntity(url: fixture.archive)
        intent.permissions = NonInteractiveAutomationPermissions(store: fixture.store)
        intent.opener = { url, _ in await record.open(url) }
        _ = try await intent.perform()
        #expect(await record.paths == [fixture.archive.path])
        await fixture.store.remove(fixture.root.path)
        await #expect(throws: AutomationError.authorizationRequired) { _ = try await intent.perform() }
        #expect(await record.paths.count == 1)
    }

    @MainActor @Test("Foreground archive opening routes one original URL through the existing app delegate")
    func nativeURLRouting() async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        let delegate = AppDelegate()
        let protected = URL(fileURLWithPath: "/.nofollow" + AutomationPath.resolvedForAccess(fixture.archive).path)
        try await fixture.store.add(fixture.root)
        let lease = try await fixture.store.authorize([fixture.archive])
        try await AutomationArchiveOpening.open(protected, lease: lease, delegate: delegate)
        #expect(delegate.takeNextArchiveRequest()?.initialURL == protected)
        #expect(delegate.takeNextArchiveURL() == nil)
    }
    @MainActor @Test("Live opening scopes are consumed once and never serialized with restored windows")
    func openingRequestPersistence() throws {
        let lease = AutomationAccessLease()
        let access = BrowserOpeningAccess(lease)
        let request = BrowserWindowRequest(initialURL: URL(fileURLWithPath: "/Example.zip"), tabSourceWindowNumber: 42, automationAccess: access)
        let restored = try JSONDecoder().decode(BrowserWindowRequest.self, from: JSONEncoder().encode(request))
        #expect(restored == request)
        #expect(Set([restored, request]).count == 1)
        #expect(restored.automationAccess == nil)
        #expect(access.take() === lease)
        #expect(access.take() == nil)
    }

    @MainActor @Test("Opening keeps access across suspension and releases it after success, error or cancellation", arguments: ["success", "error", "cancelled"])
    func openingScopeLifetime(outcome: String) async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        let engine = NativeSevenZipArchiveEngine()
        let payload = fixture.root.appendingPathComponent("Payload.txt")
        try Data("Opening scope payload".utf8).write(to: payload)
        if outcome == "error" { try Data().write(to: fixture.archive) }
        if outcome != "error" {
            try FileManager.default.removeItem(at: fixture.archive)
            try await engine.createArchive(from: [payload], outputURL: fixture.archive, options: CompressionOptions(format: .zip), password: nil, progress: { _ in })
        }
        try await fixture.store.add(fixture.root)
        var lease: AutomationAccessLease? = try await fixture.store.authorize([fixture.archive])
        weak var observed = lease
        let delegate = AppDelegate()
        try await AutomationArchiveOpening.open(fixture.archive, lease: try #require(lease), delegate: delegate)
        lease = nil
        let request = try #require(delegate.takeNextArchiveRequest())
        let fileSystem = SuspendedOpeningFileSystem()
        let defaults = try #require(UserDefaults(suiteName: fixture.suite))
        let browser = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults), fileSystem: fileSystem,
            grants: UIFixtureAccessGrantStore(), archives: engine, initialURL: request.initialURL,
            automationAccessLease: request.automationAccess?.take())
        defer { browser.close() }
        #expect(request.automationAccess?.take() == nil)
        let opening = Task { await browser.start() }
        await fileSystem.waitUntilRequested()
        #expect(observed != nil)
        if outcome == "cancelled" { opening.cancel() }
        await fileSystem.resume()
        await opening.value
        #expect(observed == nil)
        if outcome == "success" {
            #expect(browser.items.contains { $0.name == "Payload.txt" })
            #expect(browser.error == nil)
        } else {
            if outcome == "error" { #expect(browser.error != nil) }
            else { #expect(browser.error == nil); #expect(browser.location == .recents) }
            #expect(!browser.items.contains { $0.name == "Payload.txt" })
        }
    }

    @MainActor @Test("Encrypted opening retains its scope through incorrect passwords and releases it after completion or dismissal", arguments: ["complete", "dismiss", "close", "closeDuringRetry", "dismissDuringRetry"])
    func encryptedOpeningScope(outcome: String) async throws {
        let fixture = try SiriArchiveFixture()
        defer { fixture.cleanUp() }
        let engine = NativeSevenZipArchiveEngine()
        let payload = fixture.root.appendingPathComponent("Secret.txt")
        let archive = fixture.root.appendingPathComponent("Encrypted.7z")
        try Data("Encrypted opening fixture".utf8).write(to: payload)
        var options = CompressionOptions(format: .sevenZip)
        options.requiresPassword = true
        options.encryptFileNames = true
        try await engine.createArchive(from: [payload], outputURL: archive, options: options, password: "Opening password", progress: { _ in })
        try await fixture.store.add(fixture.root)
        var lease: AutomationAccessLease? = try await fixture.store.authorize([archive])
        weak var observed = lease
        let fileSystem = SuspendedOpeningFileSystem(suspendOnCall: 3)
        let browser = FileBrowserState(preferences: FileBrowserPreferences(defaults: try #require(UserDefaults(suiteName: fixture.suite))),
            fileSystem: fileSystem, grants: UIFixtureAccessGrantStore(), archives: engine, initialURL: archive, automationAccessLease: lease)
        lease = nil
        defer { browser.close() }
        await browser.start()
        #expect(browser.passwordOperation != nil)
        #expect(observed != nil)
        await browser.submitPassword("Incorrect opening password")
        #expect(browser.passwordOperation != nil)
        #expect(browser.passwordError != nil)
        #expect(observed != nil)
        if outcome == "dismiss" { browser.passwordOperation = nil }
        else if outcome == "close" { browser.close() }
        else if outcome == "closeDuringRetry" || outcome == "dismissDuringRetry" {
            let retry = Task { await browser.submitPassword("Opening password") }
            await fileSystem.waitUntilRequested()
            if outcome == "closeDuringRetry" { browser.close() }
            else { browser.passwordOperation = nil }
            #expect(observed != nil)
            await fileSystem.resume()
            await retry.value
            #expect(!browser.items.contains { $0.name == "Secret.txt" })
        }
        else {
            let completion = Task { await browser.submitPassword("Opening password") }
            await fileSystem.waitUntilRequested()
            await fileSystem.resume()
            await completion.value
            #expect(browser.passwordOperation == nil)
            #expect(browser.items.contains { $0.name == "Secret.txt" })
            #expect(browser.error == nil)
        }
        #expect(observed == nil)
    }

}

private actor ArchiveOpenRecorder {
    var paths: [String] = []
    func open(_ url: URL) { paths.append(url.path) }
}

private actor SuspendedArchiveAccess: AutomationAuthorizing {
    private var requested = false
    private var released = false
    private var observer: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<[String], Never>?

    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease { throw AutomationError.authorizationRequired }
    func authorizedFolders() async -> [String] {
        if released { return [] }
        return await withCheckedContinuation {
            pending = $0
            requested = true
            observer?.resume()
            observer = nil
        }
    }
    func waitUntilRequested() async {
        if requested { return }
        await withCheckedContinuation { observer = $0 }
    }
    func resume() {
        released = true
        pending?.resume(returning: [])
        pending = nil
    }
}

private struct SiriArchiveFixture: Sendable {
    let container: URL
    let root: URL
    let archive: URL
    let suite: String
    let store: AutomationGrantStore
    let service: AutomationArchiveEntities
    init() throws {
        container = FileManager.default.temporaryDirectory.appendingPathComponent("SiriArchive-" + UUID().uuidString)
        root = container.appendingPathComponent("Allowed")
        archive = root.appendingPathComponent("Example.zip")
        suite = "ZforgeTestSuite.SiriArchiveTests-" + UUID().uuidString
        store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        service = AutomationArchiveEntities(access: store)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("Entity metadata fixture".utf8).write(to: archive)
    }
    func cleanUp() {
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
        try? FileManager.default.removeItem(at: container)
    }
}


private actor SuspendedOpeningFileSystem: FileSystemServing {
    private let service = FileSystemService()
    private var requested = false
    private var observer: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<Void, Never>?
    private var calls = 0
    private let suspendOnCall: Int
    init(suspendOnCall: Int = 1) { self.suspendOnCall = suspendOnCall }
    func item(at url: URL) async throws -> BrowserItem {
        calls += 1
        guard calls == suspendOnCall else { return try await service.item(at: url) }
        await withCheckedContinuation {
            pending = $0
            requested = true
            observer?.resume()
            observer = nil
        }
        try Task.checkCancellation()
        return try await service.item(at: url)
    }
    func waitUntilRequested() async {
        if requested { return }
        await withCheckedContinuation { observer = $0 }
    }
    func resume() { pending?.resume(); pending = nil }
    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        try await service.items(in: directory, showHidden: showHidden)
    }
    func recursiveSize(at url: URL) async throws -> Int64 { try await service.recursiveSize(at: url) }
    func resolveNavigationURL(_ url: URL) async throws -> URL { try await service.resolveNavigationURL(url) }
}
