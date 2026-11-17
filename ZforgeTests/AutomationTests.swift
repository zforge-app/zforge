import Foundation
import AppIntents
import MCP
import Testing
@testable import Zforge

@Suite("Agent automation contracts")
struct AutomationTests {
    @Test("Path validation rejects relative paths, URLs, NUL and unsafe child names")
    func paths() throws {
        for path in ["relative/file", "~/file", "file:///tmp/file", "/tmp/file\0name"] {
            #expect(throws: AutomationError.invalidArguments) { try AutomationPath.url(path) }
        }
        for name in ["", ".", "..", "../outside", "nested/name", "invalid\0name"] {
            #expect(throws: AutomationError.invalidArguments) { try AutomationPath.newChild(in: URL(fileURLWithPath: "/tmp"), name: name) }
        }
        #expect(try AutomationPath.url("/tmp/Folder/../Item.txt").path == "/tmp/Item.txt")
        #expect(AutomationGrantStore.contains(root: "/Allowed", path: "/Allowed/Child"))
        #expect(!AutomationGrantStore.contains(root: "/Allowed", path: "/AllowedElsewhere/Child"))
    }

    @Test("Automation starts with no browser grants and explicit grants persist and revoke")
    func grantPersistence() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let suite = "ZforgeTestSuite.ZforgeAutomationTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        defaults.set([fixture.root.path: Data()], forKey: "securityScopedBookmarks")
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        #expect(await store.folders().isEmpty)
        await #expect(throws: AutomationError.authorizationRequired) { try await store.authorize([fixture.source]) }
        try await store.add(fixture.root)
        let reopened = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        #expect(await reopened.folders().map(\.id) == [fixture.root.path])
        let lease = try await reopened.authorize([fixture.source])
        withExtendedLifetime(lease) {}
        await reopened.remove(fixture.root.path)
        await #expect(throws: AutomationError.authorizationRequired) { try await reopened.authorize([fixture.source]) }
    }

    @Test("Authorized folder symlinks cannot expose targets outside the physical root")
    func symlinkEscape() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let outside = fixture.root.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: outside) }
        let link = fixture.root.appendingPathComponent("Escape")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        let suite = "ZforgeTestSuite.ZforgeAutomationTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        try await store.add(fixture.root)
        await #expect(throws: AutomationError.authorizationRequired) {
            try await store.authorize([link.appendingPathComponent("new.txt")])
        }
    }

    @Test("An authorized root accepts a physical alias but still refuses outside descendants")
    func grantedAlias() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let alias = fixture.root.deletingLastPathComponent().appendingPathComponent("Alias-" + UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.root)
        defer { try? FileManager.default.removeItem(at: alias) }
        let suite = "ZforgeTestSuite.ZforgeAutomationTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        try await store.add(fixture.root)
        let lease = try await store.authorize([alias.appendingPathComponent("Input.txt"), alias.appendingPathComponent("New.zip")])
        withExtendedLifetime(lease) {}
        await #expect(throws: AutomationError.authorizationRequired) { try await store.authorize([fixture.root.deletingLastPathComponent().appendingPathComponent("Outside")]) }
    }

    @Test("Folder listing respects hidden files, direct children and bounded sorted pages")
    func directoryPages() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        try Data("hidden".utf8).write(to: fixture.root.appendingPathComponent(".Hidden.txt"))
        let nested = fixture.root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("nested".utf8).write(to: nested.appendingPathComponent("Child.txt"))
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        let first = try await service.listDirectory(path: fixture.root.path, limit: 1)
        #expect(first.total == 2)
        #expect(first.items.map(\.name) == ["Input.txt"])
        #expect(first.nextOffset == 1)
        let second = try await service.listDirectory(path: fixture.root.path, offset: 1, limit: 1)
        #expect(second.items.map(\.name) == ["Nested"])
        #expect(second.nextOffset == nil)
        let hidden = try await service.listDirectory(path: fixture.root.path, showHidden: true)
        #expect(hidden.total == 3)
        #expect(!hidden.items.contains { $0.name == "Child.txt" })
        await #expect(throws: AutomationError.invalidArguments) { try await service.listDirectory(path: fixture.root.path, limit: 201) }
    }

    @Test("System no-follow file paths retain native protection and respect automation grants")
    func systemNoFollowPaths() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let suite = "ZforgeTestSuite.ZforgeAutomationTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        try await store.add(fixture.root)
        let physical = fixture.root.resolvingSymlinksInPath()
        let protectedSource = URL(fileURLWithPath: "/.nofollow" + physical.appendingPathComponent("Input.txt").path)
        let protectedOutput = URL(fileURLWithPath: "/.nofollow" + physical.appendingPathComponent("Protected.zip").path)
        let lease = try await store.authorize([protectedSource, protectedOutput])
        withExtendedLifetime(lease) {}
        #expect(try AutomationIntentRunner.path(IntentFile(fileURL: protectedSource)) == protectedSource.path)
        let operations = AutomationOperations(access: store)
        let job = try await operations.compress(sources: [protectedSource.path], destination: protectedOutput.path, format: .zip)
        #expect(job.outputPath == protectedOutput.path)
        #expect(try await operations.wait(job.id).state == .succeeded)
        #expect(try await operations.listArchive(path: protectedOutput.path).items.map(\.name) == ["Input.txt"])
        let outside = fixture.root.deletingLastPathComponent().appendingPathComponent("Outside-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: outside) }
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("Escape"), withDestinationURL: outside)
        let escape = URL(fileURLWithPath: "/.nofollow" + physical.appendingPathComponent("Escape/New.zip").path)
        await #expect(throws: AutomationError.authorizationRequired) { try await store.authorize([escape]) }
        await #expect(throws: AutomationError.authorizationRequired) {
            try await store.authorize([URL(fileURLWithPath: "/.nofollow" + outside.appendingPathComponent("New.zip").path)])
        }
        await store.remove(fixture.root.path)
        await #expect(throws: AutomationError.authorizationRequired) { try await store.authorize([protectedSource]) }
        let protectedRoot = URL(fileURLWithPath: "/.nofollow" + physical.path, isDirectory: true)
        try await store.add(protectedRoot)
        let aliasLease = try await store.authorize([fixture.source])
        withExtendedLifetime(aliasLease) {}
        await store.remove(protectedRoot.path)
    }

    @Test("MCP validates required, optional and unknown arguments and returns structured authorization errors")
    func mcpArguments() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        for arguments: [String: Value] in [[:], ["path": .string(fixture.root.path), "show_hidden": 1],
            ["path": .string(fixture.root.path), "limit": "100"], ["path": .string(fixture.root.path), "extra": true]] {
            let result = await ZforgeMCPServer.call(name: "list_directory", arguments: arguments, operations: service)
            #expect(result.isError == true)
            #expect(result.structuredContent?.objectValue?["error_code"] == "invalidArguments")
        }
        let denied = await ZforgeMCPServer.call(name: "list_directory", arguments: ["path": "/Forbidden"], operations: service)
        #expect(denied.isError == true)
        #expect(denied.structuredContent?.objectValue?["error_code"] == "authorizationRequired")
        let valid = await ZforgeMCPServer.call(name: "list_directory", arguments: ["path": .string(fixture.root.path)], operations: service)
        #expect(valid.isError == false)
        #expect(valid.structuredContent?.objectValue?["total"] == 1)
        #expect(ZforgeMCPServer.tools.count == 8)
        #expect(Set(ZforgeMCPServer.tools.map(\.name)).count == 8)
    }

    @Test("MCP compression, archive listing, integrity and extraction round-trip real ZIP and 7z", arguments: ["zip", "7z"])
    func mcpRoundTrip(format: String) async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        let archive = fixture.root.appendingPathComponent("Output." + format)
        let compressed = await ZforgeMCPServer.call(name: "compress", arguments: ["sources": [.string(fixture.source.path)],
            "destination": .string(archive.path), "format": .string(format)], operations: service)
        let compressedID = try jobID(compressed)
        #expect(try await service.wait(compressedID).state == .succeeded)
        let page = try await service.listArchive(path: archive.path)
        #expect(page.items.map(\.name) == ["Input.txt"])
        let tested = await ZforgeMCPServer.call(name: "test_archive", arguments: ["archive": .string(archive.path)], operations: service)
        #expect(try await service.wait(jobID(tested)).state == .succeeded)
        let destination = fixture.root.appendingPathComponent("Extracted")
        let extracted = await ZforgeMCPServer.call(name: "extract", arguments: ["archive": .string(archive.path), "destination": .string(destination.path)], operations: service)
        #expect(try await service.wait(jobID(extracted)).state == .succeeded)
        #expect(try Data(contentsOf: destination.appendingPathComponent("Input.txt")) == Data("Automation fixture".utf8))
        let status = await ZforgeMCPServer.call(name: "operation_status", arguments: ["operation_id": .string(compressedID.uuidString)], operations: service)
        #expect(status.structuredContent?.objectValue?["state"] == "succeeded")
        await service.shutdown()
    }

    @Test("MCP compression with volume_size writes a split archive that lists and tests from any volume (ZF-83)")
    func mcpSplitCompression() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let source = fixture.root.appendingPathComponent("Big.bin")
        try Data((0..<2_500_000).map { _ in UInt8.random(in: 0...255) }).write(to: source)
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        let archive = fixture.root.appendingPathComponent("Output.7z")
        let compressed = await ZforgeMCPServer.call(name: "compress", arguments: ["sources": [.string(source.path)],
            "destination": .string(archive.path), "format": .string("7z"), "volume_size": .int(1_000_000)], operations: service)
        #expect(try await service.wait(jobID(compressed)).state == .succeeded)
        let second = fixture.root.appendingPathComponent("Output.7z.002")
        #expect(FileManager.default.fileExists(atPath: second.path))
        #expect(try await service.listArchive(path: second.path).items.map(\.name) == ["Big.bin"])
        let tested = await ZforgeMCPServer.call(name: "test_archive", arguments: ["archive": .string(second.path)], operations: service)
        #expect(try await service.wait(jobID(tested)).state == .succeeded)
        let refused = await ZforgeMCPServer.call(name: "compress", arguments: ["sources": [.string(source.path)],
            "destination": .string(fixture.root.appendingPathComponent("Small.7z").path), "format": .string("7z"),
            "volume_size": .int(999)], operations: service)
        #expect(refused.isError == true)
        await service.shutdown()
    }

    @Test("Existing destinations and dangling symlinks are preserved")
    func refuseReplacement() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        await #expect(throws: AutomationError.destinationExists) {
            try await service.compress(sources: [fixture.source.path], destination: fixture.source.path, format: .zip)
        }
        let existing = fixture.root.appendingPathComponent("Existing")
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: false)
        await #expect(throws: AutomationError.destinationExists) {
            try await service.extract(archive: fixture.source.path, destination: existing.path)
        }
        let dangling = fixture.root.appendingPathComponent("Dangling.zip")
        try FileManager.default.createSymbolicLink(atPath: dangling.path, withDestinationPath: "Missing.txt")
        await #expect(throws: AutomationError.destinationExists) {
            try await service.compress(sources: [fixture.source.path], destination: dangling.path, format: .zip)
        }
        #expect(try Data(contentsOf: fixture.source) == Data("Automation fixture".utf8))
    }

    @Test("Cancellation waits for cleanup, rejects concurrent jobs, and allows the next job")
    func cancellation() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let engine = ControlledAutomationEngine()
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root), engine: engine)
        let first = try await service.test(archive: fixture.source.path)
        await engine.started.wait()
        await #expect(throws: AutomationError.busy) { try await service.test(archive: fixture.source.path) }
        _ = try await service.cancel(first.id)
        #expect(try await service.wait(first.id).state == .cancelled)
        let second = try await service.test(archive: fixture.source.path)
        #expect(try await service.wait(second.id).state == .succeeded)
        #expect(try await service.cancel(second.id).state == .succeeded)
        await #expect(throws: AutomationError.notFound) { try await service.status(UUID()) }
    }

    @Test("Disconnect cancels a running job and keeps its terminal state explicit")
    func shutdown() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let engine = ControlledAutomationEngine()
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root), engine: engine)
        let job = try await service.test(archive: fixture.source.path)
        await engine.started.wait()
        await service.shutdown()
        #expect(try await service.status(job.id).state == .cancelled)
    }

    @Test("Disconnect during authorization prevents a late job from starting")
    func disconnectDuringAuthorization() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let access = ControlledAutomationAccess()
        let operations = AutomationOperations(access: access)
        let request = Task { try await operations.test(archive: fixture.source.path) }
        await access.started.wait()
        await operations.shutdown()
        await access.released.signal()
        await #expect(throws: AutomationError.notFound) { try await request.value }
        await #expect(throws: AutomationError.notFound) { try await operations.test(archive: fixture.source.path) }
    }

    @Test("Invalid and encrypted archives report failure and can be retried with the correct password")
    func archiveErrors() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/encrypted.7z")
        let encrypted = fixture.root.appendingPathComponent("Encrypted.7z")
        try FileManager.default.copyItem(at: source, to: encrypted)
        let service = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        let invalid = try await service.test(archive: fixture.source.path)
        #expect(try await service.wait(invalid.id).state == .failed)
        let locked = try await service.test(archive: encrypted.path)
        #expect(try await service.wait(locked.id).state == .failed)
        let unlocked = try await service.test(archive: encrypted.path, password: "zforge-test")
        #expect(try await service.wait(unlocked.id).state == .succeeded)
    }

    @Test("Native intent input mapping rejects data-only files and returns file URLs without loading contents")
    func intentParameters() throws {
        #expect(throws: AutomationError.invalidArguments) {
            try AutomationIntentRunner.path(IntentFile(data: Data(), filename: "Input.txt"))
        }
        #expect(try AutomationIntentRunner.path(IntentFile(fileURL: URL(fileURLWithPath: "/Allowed/Input.txt"))) == "/Allowed/Input.txt")
        #expect(ZforgeIntentFormat.zip.format == .zip)
        #expect(ZforgeIntentFormat.sevenZip.format == .sevenZip)
    }

    @Test("An actual SDK client initializes, discovers tools and receives tool results")
    func sdkClient() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        let operations = AutomationOperations(access: TestAutomationAccess(root: fixture.root))
        let server = await ZforgeMCPServer.make(operations: operations)
        let transports = await InMemoryTransport.createConnectedPair()
        try await server.start(transport: transports.server)
        let client = Client(name: "ZforgeContractTests", version: "1.0")
        let initialized = try await client.connect(transport: transports.client)
        #expect(initialized.serverInfo.name == "Zforge")
        let definitions = try await client.listTools()
        #expect(definitions.tools.count == 8)
        let result = try await client.callTool(name: "list_directory", arguments: ["path": .string(fixture.root.path)])
        #expect(result.isError == false)
        guard case let .text(text, _, _) = try #require(result.content.first) else { throw AutomationError.invalidArguments }
        let data = try #require(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        #expect(data["total"] as? Int == 1)
        await client.disconnect()
        await server.stop()
        await operations.shutdown()
    }

    @Test("Native compression, extraction and integrity actions execute through the same real services")
    func nativeActions() async throws {
        let fixture = try AutomationFixture()
        defer { fixture.remove() }
        try await AutomationGrantStore.shared.add(fixture.root)
        do {
            let compress = CompressZforgeFilesIntent()
            compress.files = [IntentFile(fileURL: fixture.source)]
            compress.destinationFolder = IntentFile(fileURL: fixture.root)
            compress.archiveName = "Native.zip"
            compress.format = .zip
            _ = try await compress.perform()
            let output = fixture.root.appendingPathComponent("Native.zip")
            #expect(FileManager.default.fileExists(atPath: output.path))
            var test = TestZforgeArchiveIntent()
            test.archive = IntentFile(fileURL: output)
            _ = try await test.perform()
            let extract = ExtractZforgeArchiveIntent()
            extract.archive = IntentFile(fileURL: output)
            extract.destinationFolder = IntentFile(fileURL: fixture.root)
            extract.folderName = "Native Extracted"
            _ = try await extract.perform()
            #expect(try Data(contentsOf: fixture.root.appendingPathComponent("Native Extracted/Input.txt")) == Data("Automation fixture".utf8))
            await #expect(throws: AutomationError.destinationExists) { try await compress.perform() }
            await AutomationGrantStore.shared.remove(fixture.root.path)
            // Denied consent/noninteractive execution must preserve the original no-grant boundary.
            test.permissions = NonInteractiveAutomationPermissions()
            await #expect(throws: AutomationError.authorizationRequired) { try await test.perform() }
        } catch {
            await AutomationGrantStore.shared.remove(fixture.root.path)
            throw error
        }
    }

    @Test("MCP configuration safely encodes executable paths with spaces and quotes")
    func configuration() throws {
        let path = "/Applications/Test \"Zforge\".app/Contents/MacOS/Zforge"
        let data = Data(try AutomationSettingsSection.configuration(executable: path).utf8)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let servers = try #require(object["mcpServers"] as? [String: [String: Any]])
        #expect(servers["zforge"]?["command"] as? String == path)
        #expect(servers["zforge"]?["args"] as? [String] == ["--mcp"])
    }

    private func jobID(_ result: CallTool.Result) throws -> UUID {
        #expect(result.isError == false)
        let text = try #require(result.structuredContent?.objectValue?["operation_id"]?.stringValue)
        return try #require(UUID(uuidString: text))
    }
}

private struct AutomationFixture {
    let root: URL
    let source: URL
    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("Automation-" + UUID().uuidString)
        source = root.appendingPathComponent("Input.txt")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        try Data("Automation fixture".utf8).write(to: source)
    }
    func remove() { try? FileManager.default.removeItem(at: root) }
}

private struct TestAutomationAccess: AutomationAuthorizing {
    let root: URL
    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease {
        guard urls.allSatisfy({ AutomationGrantStore.contains(root: root.path, path: $0.resolvingSymlinksInPath().path) }) else {
            throw AutomationError.authorizationRequired
        }
        return AutomationAccessLease()
    }
}

private actor AutomationTestSignal {
    private var signalled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        if signalled { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func signal() {
        signalled = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

private actor ControlledAutomationEngine: ArchiveServing {
    let started = AutomationTestSignal()
    private let released = AutomationTestSignal()
    func testArchive(at url: URL, password: String?) async throws {
        await started.signal()
        await withTaskCancellationHandler { await released.wait() } onCancel: {
            Task { await self.released.signal() }
        }
        try Task.checkCancellation()
    }
    func cancelAllOperations() async { await released.signal() }
    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult { throw AutomationError.notFound }
    func items(at address: ArchiveAddress) async throws -> [BrowserItem] { [] }
    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?) async throws -> URL { throw AutomationError.notFound }
    func createArchive(from sourceURLs: [URL], outputURL: URL, options: CompressionOptions, password: String?, progress: @escaping ArchiveProgressHandler) async throws {}
    func extractArchive(at url: URL, to destinationURL: URL, password: String?, resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {}
    func extractItems(_ items: [BrowserItem], to destinationURL: URL, password: String?, resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {}
    func recursiveSize(of item: BrowserItem) async throws -> Int64 { 0 }
    func archiveRootURL(for address: ArchiveAddress) async throws -> URL { throw AutomationError.notFound }
    func setPassword(_ password: String?, for sessionID: UUID) async {}
    func closeSession(_ sessionID: UUID) async {}
    func closeAllSessions() async {}
    func cleanupStaleSessions() async {}
}

private actor ControlledAutomationAccess: AutomationAuthorizing {
    let started = AutomationTestSignal()
    let released = AutomationTestSignal()
    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease {
        await started.signal()
        await released.wait()
        return AutomationAccessLease()
    }
}
