import Foundation

/// One browser window's access to the shared archive engine (D-73). Windows that show
/// the same archive share its engine session; this client counts the references its
/// window holds, releases exactly those when the window closes, and cancels only the
/// operations its window started.
nonisolated final class ArchiveSessionClient: ArchiveServing, @unchecked Sendable {
    let engine: NativeSevenZipArchiveEngine
    private let lock = NSLock()
    private var held: [UUID: Int] = [:]
    private var cancellers: [UUID: @Sendable () -> Void] = [:]

    init(engine: NativeSevenZipArchiveEngine = .shared) {
        self.engine = engine
    }

    /// Sessions this window holds, with their reference counts.
    var heldSessions: [UUID: Int] { lock.withLock { held } }

    nonisolated var sessionChangeSource: AnyObject? { engine }

    private func hold(_ sessionID: UUID) {
        lock.withLock { held[sessionID, default: 0] += 1 }
    }

    /// Removes one reference this window holds; false when it holds none.
    private func drop(_ sessionID: UUID) -> Bool {
        lock.withLock {
            guard let count = held[sessionID], count > 0 else { return false }
            held[sessionID] = count > 1 ? count - 1 : nil
            return true
        }
    }

    /// Runs engine work as a child of this window, so `cancelAllOperations` reaches it.
    private func run<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) async throws -> T {
        let id = UUID()
        let task = Task { try await body() }
        lock.withLock { cancellers[id] = { task.cancel() } }
        defer { _ = lock.withLock { cancellers.removeValue(forKey: id) } }
        return try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
    }

    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult {
        let result = try await run { try await self.engine.openArchive(at: url, password: password) }
        hold(result.address.sessionID)
        return result
    }

    func openInnerArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        let result = try await run { try await self.engine.openInnerArchive(item: item, password: password) }
        hold(result.address.sessionID)
        return result
    }

    func reopenSession(_ sessionID: UUID, at url: URL, password: String?) async throws -> ArchiveOpenResult {
        let result = try await run { try await self.engine.reopenSession(sessionID, at: url, password: password) }
        if result.address.sessionID != sessionID {
            // The session had closed: the engine opened the archive again for this window.
            lock.withLock { held[sessionID] = nil }
            hold(result.address.sessionID)
        }
        return result
    }

    func retainSession(_ sessionID: UUID) async throws {
        try await engine.retainSession(sessionID)
        hold(sessionID)
    }

    func closeSession(_ sessionID: UUID) async {
        guard drop(sessionID) else { return }
        await engine.closeSession(sessionID)
    }

    func closeAllSessions() async {
        let released = lock.withLock { () -> [UUID: Int] in
            defer { held.removeAll() }
            return held
        }
        for (sessionID, count) in released {
            for _ in 0..<count { await engine.closeSession(sessionID) }
        }
    }

    func cancelAllOperations() async {
        let pending = lock.withLock { Array(cancellers.values) }
        pending.forEach { $0() }
    }

    func items(at address: ArchiveAddress) async throws -> [BrowserItem] {
        try await engine.items(at: address)
    }

    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?) async throws -> URL {
        try await run { try await self.engine.materialize(item: item, purpose: purpose, automaticLimit: automaticLimit) }
    }

    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?,
                     password: String?) async throws -> URL {
        try await run {
            try await self.engine.materialize(item: item, purpose: purpose, automaticLimit: automaticLimit, password: password)
        }
    }

    func createArchive(from sourceURLs: [URL], outputURL: URL, options: CompressionOptions, password: String?,
                       progress: @escaping ArchiveProgressHandler) async throws {
        try await run {
            try await self.engine.createArchive(from: sourceURLs, outputURL: outputURL, options: options,
                password: password, progress: progress)
        }
    }

    func addItems(from sourceURLs: [URL], to archiveURL: URL, internalPath: String, password: String?,
                  progress: @escaping ArchiveProgressHandler) async throws {
        try await run {
            try await self.engine.addItems(from: sourceURLs, to: archiveURL, internalPath: internalPath,
                password: password, progress: progress)
        }
    }

    func exportItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        try await run { try await self.engine.exportItem(item, to: url, password: password, progress: progress) }
    }

    func exportPromisedItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        try await run { try await self.engine.exportPromisedItem(item, to: url, password: password, progress: progress) }
    }

    @discardableResult
    func removeItems(_ items: [BrowserItem], password: String?, progress: @escaping ArchiveProgressHandler) async throws -> String? {
        try await run { try await self.engine.removeItems(items, password: password, progress: progress) }
    }

    func reorganizeItems(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool, password: String?,
                         resolveConflict: @escaping ArchiveConflictResolver,
                         progress: @escaping ArchiveProgressHandler) async throws -> ArchiveReorganizationResult {
        try await run {
            try await self.engine.reorganizeItems(items, to: destination, moving: moving, password: password,
                resolveConflict: resolveConflict, progress: progress)
        }
    }

    func extractArchive(at url: URL, to destinationURL: URL, password: String?,
                        resolveConflict: @escaping ArchiveConflictResolver,
                        progress: @escaping ArchiveProgressHandler) async throws {
        try await run {
            try await self.engine.extractArchive(at: url, to: destinationURL, password: password,
                resolveConflict: resolveConflict, progress: progress)
        }
    }

    func testArchive(at url: URL, password: String?) async throws {
        try await run { try await self.engine.testArchive(at: url, password: password) }
    }

    func extractItems(_ items: [BrowserItem], to destinationURL: URL, password: String?,
                      resolveConflict: @escaping ArchiveConflictResolver,
                      progress: @escaping ArchiveProgressHandler) async throws {
        try await run {
            try await self.engine.extractItems(items, to: destinationURL, password: password,
                resolveConflict: resolveConflict, progress: progress)
        }
    }

    func recursiveSize(of item: BrowserItem) async throws -> Int64 {
        try await engine.recursiveSize(of: item)
    }

    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String] {
        try await engine.archiveHierarchy(for: address)
    }

    func archiveRootURL(for address: ArchiveAddress) async throws -> URL {
        try await engine.archiveRootURL(for: address)
    }

    func outermostArchiveURL(for address: ArchiveAddress) async throws -> URL {
        try await engine.outermostArchiveURL(for: address)
    }

    func setPassword(_ password: String?, for sessionID: UUID) async {
        await engine.setPassword(password, for: sessionID)
    }

    func cleanupStaleSessions() async {
        await engine.cleanupStaleSessions()
    }
}
