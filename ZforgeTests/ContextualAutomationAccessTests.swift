import Foundation
import Testing
@testable import Zforge

@Suite("Contextual automation folder permission")
struct ContextualAutomationAccessTests {
    @Test("Missing source and destination grants prompt once per folder and continue the same archive request")
    func grantsAndContinues() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ContextualAccess-" + UUID().uuidString)
        let sourceFolder = root.appendingPathComponent("Source", isDirectory: true)
        let outputFolder = root.appendingPathComponent("Destination", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = sourceFolder.appendingPathComponent("Input.txt")
        try Data("Contextual permission fixture".utf8).write(to: source)
        let suite = "ContextualAccessTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        let initialCount = await store.authorizedFolders().count
        #expect(initialCount == 0)
        let recorder = PermissionPickerRecorder()
        let access = ContextualAutomationAccess(store: store, picker: { folder in await recorder.choose(folder) })
        let operations = AutomationOperations(access: access)
        let output = outputFolder.appendingPathComponent("Output.zip")
        let job = try await operations.compress(sources: [source.path], destination: output.path, format: .zip)
        #expect(try await operations.wait(job.id).state == .succeeded)
        #expect(try await operations.listArchive(path: output.path).items.map(\.name) == ["Input.txt"])
        #expect(await recorder.folders.map(\.lastPathComponent) == ["Source", "Destination"])
        let finalCount = await store.authorizedFolders().count
        #expect(finalCount == 2)
        let again = try await access.authorize([source, output])
        withExtendedLifetime(again) {}
        #expect(await recorder.folders.count == 2)
    }
    @Test("Cancelling destination permission preserves explicit source consent without creating an archive")
    func cancelDestination() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let access = ContextualAutomationAccess(store: fixture.store, picker: { folder in
            folder.lastPathComponent == "Source" ? folder : nil
        })
        let operations = AutomationOperations(access: access)
        await #expect(throws: CancellationError.self) {
            _ = try await operations.compress(sources: [fixture.input.path], destination: fixture.output.path, format: .zip)
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.output.path))
        #expect(await fixture.store.authorizedFolders() == [fixture.source.path])
    }

    @Test("Selecting a broader folder rejects the request and creates no grant")
    func rejectBroaderFolder() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let access = ContextualAutomationAccess(store: fixture.store, picker: { _ in fixture.root })
        await #expect(throws: AutomationFolderSelectionError.self) { _ = try await access.authorize([fixture.input]) }
        #expect(await fixture.store.authorizedFolders().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fixture.output.path))
    }

    @Test("Existing grants avoid foreground continuation and folder selection")
    func existingGrant() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.source)
        let access = ContextualAutomationAccess(store: fixture.store, picker: { _ in
            Issue.record("An authorized request must not present a picker")
            return nil
        })
        let lease = try await access.authorize([fixture.input], foreground: {
            Issue.record("An authorized request must not request foreground continuation")
        })
        withExtendedLifetime(lease) {}
        #expect(await access.authorizedFolders() == [fixture.source.path])
    }

    @Test("A requested directory grants that directory rather than its parent")
    func directoryScope() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let recorder = PermissionPickerRecorder()
        let access = ContextualAutomationAccess(store: fixture.store, picker: { await recorder.choose($0) })
        let lease = try await access.authorize([AutomationAccessTarget(url: fixture.source, kind: .directory)])
        withExtendedLifetime(lease) {}
        #expect(await recorder.folders == [fixture.source])
        await #expect(throws: AutomationError.authorizationRequired) { _ = try await fixture.store.authorize([fixture.destination]) }
    }

    @Test("A missing top-level path never requests access to the whole disk")
    func missingTopLevel() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let access = ContextualAutomationAccess(store: fixture.store, picker: { _ in
            Issue.record("A missing top-level path must not request a root grant")
            return nil
        })
        await #expect(throws: AutomationError.authorizationRequired) {
            _ = try await access.authorize([URL(fileURLWithPath: "/MissingContextualPermission-" + UUID().uuidString)])
        }
        #expect(await fixture.store.authorizedFolders().isEmpty)
    }

    @Test("Cancelling an outstanding picker leaves no grant and permits a fresh request")
    func cancelledRequestCanRetry() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let picker = SuspendedPermissionPicker()
        let access = ContextualAutomationAccess(store: fixture.store, picker: { try await picker.choose($0) })
        let task = Task { try await access.authorize([fixture.input]) }
        await picker.waitUntilPresented()
        task.cancel()
        await #expect(throws: CancellationError.self) { _ = try await task.value }
        #expect(await fixture.store.authorizedFolders().isEmpty)
        let retry = ContextualAutomationAccess(store: fixture.store, picker: { $0 })
        let lease = try await retry.authorize([fixture.input])
        withExtendedLifetime(lease) {}
        #expect(await fixture.store.authorizedFolders() == [fixture.source.path])
    }

    @Test("Concurrent access to one folder asks once and resumes all callers")
    func concurrentRequests() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let recorder = PermissionPickerRecorder()
        let access = ContextualAutomationAccess(store: fixture.store, picker: { await recorder.choose($0) })
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let lease = try await access.authorize([fixture.input])
                    withExtendedLifetime(lease) {}
                }
            }
            try await group.waitForAll()
        }
        #expect(await recorder.folders == [fixture.source])
        #expect(await fixture.store.authorizedFolders() == [fixture.source.path])
    }

    @Test("Cancelling one coalesced caller returns immediately while another caller can still consent")
    func independentCallerCancellation() async throws {
        let fixture = try PermissionFixture()
        defer { fixture.cleanUp() }
        let picker = SuspendedPermissionPicker()
        let access = ContextualAutomationAccess(store: fixture.store, picker: { try await picker.choose($0) })
        let first = Task { try await access.authorize([fixture.input]) }
        await picker.waitUntilPresented()
        let second = Task { try await access.authorize([fixture.input]) }
        // Synchronize on joining the shared request, rather than elapsed wall time.
        while await access.pendingWaiterCount != 2 { await Task.yield() }
        first.cancel()
        await #expect(throws: CancellationError.self) { _ = try await first.value }
        #expect(await fixture.store.authorizedFolders().isEmpty)
        await picker.approve(fixture.source)
        let lease = try await second.value
        withExtendedLifetime(lease) {}
        #expect(await fixture.store.authorizedFolders() == [fixture.source.path])
    }

}

actor PermissionPickerRecorder {
    private(set) var folders: [URL] = []
    func choose(_ folder: URL) -> URL? { folders.append(folder); return folder }
}

private struct PermissionFixture: Sendable {
    let root: URL
    let source: URL
    let destination: URL
    let input: URL
    let output: URL
    let suite: String
    let store: AutomationGrantStore
    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("ContextualPermission-" + UUID().uuidString)
        source = root.appendingPathComponent("Source", isDirectory: true)
        destination = root.appendingPathComponent("Destination", isDirectory: true)
        input = source.appendingPathComponent("Input.txt")
        output = destination.appendingPathComponent("Output.zip")
        suite = "ContextualPermissionTests-" + UUID().uuidString
        store = AutomationGrantStore(defaults: UserDefaults(suiteName: suite)!)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("Contextual permission fixture".utf8).write(to: input)
    }
    func cleanUp() {
        try? FileManager.default.removeItem(at: root)
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }
}

private actor SuspendedPermissionPicker {
    private var selection: CheckedContinuation<URL?, any Error>?
    private var presented = false
    private var observers: [CheckedContinuation<Void, Never>] = []
    func choose(_ folder: URL) async throws -> URL? {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                selection = continuation
                presented = true
                observers.forEach { $0.resume() }
                observers.removeAll()
            }
        } onCancel: { Task { await self.cancel() } }
    }
    func waitUntilPresented() async {
        if presented { return }
        await withCheckedContinuation { observers.append($0) }
    }
    func approve(_ folder: URL) {
        selection?.resume(returning: folder)
        selection = nil
    }
    private func cancel() {
        selection?.resume(throwing: CancellationError())
        selection = nil
    }
}
