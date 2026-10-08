import AppKit
import Foundation
import OSLog

nonisolated protocol AutomationPermissionRequesting: AutomationAuthorizing {
    func authorize(_ urls: [URL], foreground: @escaping @Sendable () async throws -> Void) async throws -> AutomationAccessLease
}

/// Interactive access is an adapter policy; the engine's explicit-grant boundary remains unchanged.
actor ContextualAutomationAccess: AutomationPermissionRequesting {
    static let shared = ContextualAutomationAccess()
    typealias Picker = @Sendable (URL) async throws -> URL?
    private let store: AutomationGrantStore
    private let picker: Picker
    private struct Pending {
        let id: UUID
        let task: Task<Void, Never>
        var waiters: [UUID: CheckedContinuation<Void, any Error>]
    }
    private var pending: [String: Pending] = [:]

    init(store: AutomationGrantStore = .shared,
         picker: @escaping Picker = { try await AutomationFolderPermissionPanel.shared.choose($0) }) {
        self.store = store
        self.picker = picker
    }

    func authorizedFolders() async -> [String] { await store.authorizedFolders() }

    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease {
        try await authorize(urls, foreground: {})
    }

    func authorize(_ urls: [URL], foreground: @escaping @Sendable () async throws -> Void) async throws -> AutomationAccessLease {
        try await authorize(urls.map { AutomationAccessTarget(url: $0, kind: .existingItem) }, foreground: foreground)
    }

    func authorize(_ targets: [AutomationAccessTarget]) async throws -> AutomationAccessLease {
        try await authorize(targets, foreground: {})
    }

    private func authorize(_ targets: [AutomationAccessTarget], foreground: @escaping @Sendable () async throws -> Void) async throws -> AutomationAccessLease {
        let urls = targets.map(\.url)
        try Task.checkCancellation()
        do { return try await store.authorize(urls) }
        catch AutomationError.authorizationRequired {} // Other errors must not request broader access.
        var missing: [URL] = []
        var seen: Set<String> = []
        for target in targets {
            do {
                let lease = try await store.authorize([target.url])
                withExtendedLifetime(lease) {}
            } catch AutomationError.authorizationRequired {
                let folder = try Self.folder(for: target)
                if seen.insert(AutomationPath.resolvedForAccess(folder).path).inserted { missing.append(folder) }
            }
        }
        guard missing.count <= 128 else { throw AutomationError.invalidArguments }
        Logger(subsystem: "io.libor.Zforge", category: "Automation").info("Automation access requires contextual folder consent.")
        try await foreground()
        for folder in missing {
            try Task.checkCancellation()
            // Another invocation may have granted this scope while foregrounding or queueing.
            if let lease = try? await store.authorize([folder]) { withExtendedLifetime(lease) {}; continue }
            try await request(folder)
        }
        try Task.checkCancellation()
        return try await store.authorize(urls)
    }

    nonisolated static func folder(for target: AutomationAccessTarget) throws -> URL {
        let value = target.url.standardizedFileURL
        guard value.isFileURL else { throw AutomationError.invalidArguments }
        let directory = target.kind == .directory || (target.kind != .newItem && (try? value.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true)
        let folder = directory ? value : value.deletingLastPathComponent()
        // A mistyped/missing top-level path must never turn into a request for the whole disk.
        guard directory || folder.path != "/" else { throw AutomationError.authorizationRequired }
        do {
            guard try folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { throw AutomationError.invalidArguments }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            throw AutomationError.authorizationRequired
        } catch let error as CocoaError where error.code == .fileReadNoPermission {
            // Metadata may itself require the grant. The picker supplies the authoritative URL.
        }
        return folder
    }

    /// Used to synchronize concurrency characterization without arbitrary delays.
    var pendingWaiterCount: Int { pending.values.reduce(0) { $0 + $1.waiters.count } }

    private func request(_ folder: URL) async throws {
        let key = AutomationPath.resolvedForAccess(folder).path
        let waiter = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                if pending[key] == nil {
                    guard pending.count < 32 else { continuation.resume(throwing: AutomationError.busy); return }
                    let id = UUID()
                    let picker = self.picker
                    let store = self.store
                    let task = Task<Void, Never> {
                        let result: Result<Void, any Error>
                        do {
                            try Task.checkCancellation()
                            guard let selected = try await picker(folder) else { throw CancellationError() }
                            try Task.checkCancellation()
                            guard AutomationPath.resolvedForAccess(selected).path == key else { throw AutomationFolderSelectionError() }
                            try await store.add(selected)
                            result = .success(())
                        } catch { result = .failure(error) }
                        finish(key, id: id, result: result)
                    }
                    pending[key] = Pending(id: id, task: task, waiters: [:])
                }
                pending[key]?.waiters[waiter] = continuation
            }
            try Task.checkCancellation()
        } onCancel: {
            Task { await self.cancel(key, waiter: waiter) }
        }
    }

    private func finish(_ key: String, id: UUID, result: Result<Void, any Error>) {
        guard let request = pending[key], request.id == id else { return }
        pending.removeValue(forKey: key)
        request.waiters.values.forEach { $0.resume(with: result) }
    }

    private func cancel(_ key: String, waiter: UUID) {
        guard let continuation = pending[key]?.waiters.removeValue(forKey: waiter) else { return }
        continuation.resume(throwing: CancellationError())
        if pending[key]?.waiters.isEmpty == true {
            pending[key]?.task.cancel()
            pending.removeValue(forKey: key)
        }
    }

    func cancelPending() {
        let requests = Array(pending.values)
        pending.removeAll()
        for request in requests {
            request.task.cancel()
            request.waiters.values.forEach { $0.resume(throwing: CancellationError()) }
        }
    }

}

nonisolated struct AutomationFolderSelectionError: LocalizedError {
    var errorDescription: String? { AppLocalization.string("Select the requested folder to continue. A different or broader folder cannot authorize this request.") }
}

/// Injectable noninteractive policy for contexts which cannot obtain human consent.
nonisolated struct NonInteractiveAutomationPermissions: AutomationPermissionRequesting {
    let store: AutomationGrantStore
    init(store: AutomationGrantStore = .shared) { self.store = store }
    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease { try await store.authorize(urls) }
    func authorize(_ urls: [URL], foreground: @escaping @Sendable () async throws -> Void) async throws -> AutomationAccessLease {
        try await store.authorize(urls)
    }
    func authorizedFolders() async -> [String] { await store.authorizedFolders() }
}

@MainActor
final class AutomationFolderPermissionPanel: NSObject, NSOpenSavePanelDelegate {
    static let shared = AutomationFolderPermissionPanel()
    private struct Request {
        let id: UUID
        let folder: URL
        let continuation: CheckedContinuation<URL?, any Error>
    }
    private var queue: [Request] = []
    private var active: Request?
    private var panel: NSOpenPanel?

    func choose(_ folder: URL) async throws -> URL? {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                guard queue.count < 32 else { continuation.resume(throwing: AutomationError.busy); return }
                queue.append(Request(id: id, folder: folder, continuation: continuation))
                presentNext()
            }
        } onCancel: {
            Task { @MainActor in self.cancel(id) }
        }
    }

    private func presentNext() {
        guard active == nil, !queue.isEmpty else { return }
        let request = queue.removeFirst()
        guard NSWorkspace.shared.frontmostApplication != nil else {
            request.continuation.resume(throwing: AutomationError.authorizationRequired)
            presentNext()
            return
        }
        active = request
        let app = NSApplication.shared
        if ProcessInfo.processInfo.arguments.contains("--mcp") {
            app.setActivationPolicy(.accessory)
        }
        app.activate()
        let panel = NSOpenPanel()
        self.panel = panel
        panel.title = AppLocalization.string("Authorize Folder to Continue")
        panel.prompt = AppLocalization.string("Authorize and Continue")
        panel.message = String.localizedStringWithFormat(AppLocalization.string("Zforge needs access to %@ for this action. Authorizing this folder also permits future agent and shortcut requests to read and write inside it."), AutomationPath.resolvedForAccess(request.folder).path)
        panel.directoryURL = AutomationPath.resolvedForAccess(request.folder)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.delegate = self
        panel.identifier = NSUserInterfaceItemIdentifier("automation-contextual-access")
        Logger(subsystem: "io.libor.Zforge", category: "Automation").info("Presenting contextual folder permission panel.")
        panel.begin { [weak self] response in
            guard let self, let active = self.active, active.id == request.id else { return }
            let selected = response == .OK ? panel.url : nil
            self.panel = nil
            self.active = nil
            active.continuation.resume(returning: selected)
            self.presentNext()
        }
    }

    func panel(_ sender: Any, validate url: URL) throws {
        guard let active, AutomationPath.resolvedForAccess(url).path == AutomationPath.resolvedForAccess(active.folder).path else {
            throw AutomationFolderSelectionError()
        }
    }

    private func cancel(_ id: UUID) {
        if active?.id == id { panel?.cancel(nil) }
        else if let index = queue.firstIndex(where: { $0.id == id }) {
            queue.remove(at: index).continuation.resume(throwing: CancellationError())
        }
    }

}
