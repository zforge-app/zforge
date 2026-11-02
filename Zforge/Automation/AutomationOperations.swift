import Foundation

nonisolated struct AutomationItem: Codable, Sendable, Equatable {
    let name: String
    let path: String
    let isDirectory: Bool
    let isSymbolicLink: Bool
    let size: Int64?

    init(_ item: BrowserItem) {
        name = item.name
        path = item.localURL?.path ?? {
            if case let .archive(address) = item.location { return address.internalPath }
            return item.name
        }()
        isDirectory = item.isDirectory
        isSymbolicLink = item.isSymbolicLink
        size = item.size
    }
}

nonisolated struct AutomationPage: Codable, Sendable {
    let items: [AutomationItem]
    let nextOffset: Int?
    let total: Int
}

nonisolated struct AutomationOperation: Codable, Sendable, Equatable {
    enum State: String, Codable, Sendable { case running, cancelling, succeeded, failed, cancelled }
    let id: UUID
    let kind: String
    var state: State
    var phase: String?
    var fraction: Double?
    var outputPath: String?
    var errorCode: String?
}

/// Uses the same filesystem service and native engine as the browser, with explicit targets.
/// One active job per connection keeps cancellation local to that job; completed history is bounded.
actor AutomationOperations {
    static let shared = AutomationOperations()
    private let access: any AutomationAuthorizing
    private let files: any FileSystemServing
    private let engine: any ArchiveServing
    private var operations: [UUID: AutomationOperation] = [:]
    private var order: [UUID] = []
    private var active: (id: UUID, task: Task<Void, Never>)?
    private var reserved = false
    private var reading = false
    private var closed = false

    init(access: any AutomationAuthorizing = AutomationGrantStore.shared,
         files: any FileSystemServing = FileSystemService(),
         engine: any ArchiveServing = NativeSevenZipArchiveEngine()) {
        self.access = access
        self.files = files
        self.engine = engine
    }

    func authorizedFolders() async -> [String] { await access.authorizedFolders() }

    func listDirectory(path: String, showHidden: Bool = false, offset: Int = 0, limit: Int = 100) async throws -> AutomationPage {
        guard !closed else { throw AutomationError.notFound }
        guard !reading else { throw AutomationError.busy }
        reading = true
        defer { reading = false }
        let url = try AutomationPath.url(path)
        let lease = try await access.authorize([AutomationAccessTarget(url: url, kind: .directory)])
        defer { withExtendedLifetime(lease) {} }
        guard try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { throw AutomationError.invalidArguments }
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [.skipsSubdirectoryDescendants] : [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
        var enumerationError: (any Error)?
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: options,
            errorHandler: { _, error in enumerationError = error; return false }) else { throw AutomationError.notFound }
        var items: [AutomationItem] = []
        while let child = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            guard items.count < 10_000 else { throw AutomationError.listingTooLarge }
            items.append(AutomationItem(try await files.item(at: child, includeExtendedMetadata: false)))
        }
        if let enumerationError { throw enumerationError }
        return try Self.page(items, offset: offset, limit: limit)
    }

    func listArchive(path: String, internalPath: String = "", password: String? = nil,
                     offset: Int = 0, limit: Int = 100) async throws -> AutomationPage {
        guard !closed else { throw AutomationError.notFound }
        guard !reading else { throw AutomationError.busy }
        reading = true
        defer { reading = false }
        let url = try AutomationPath.url(path)
        let lease = try await access.authorize([url])
        defer { withExtendedLifetime(lease) {} }
        guard !internalPath.hasPrefix("/"), !internalPath.split(separator: "/").contains(".."), !internalPath.contains("\0") else {
            throw AutomationError.invalidArguments
        }
        // Independent session/engine: cancelling a job must not cancel an unrelated listing.
        let reader = NativeSevenZipArchiveEngine()
        let result = try await reader.openArchive(at: url, password: password)
        do {
            let root = result.address
            let address = ArchiveAddress(sessionID: root.sessionID, archiveID: root.archiveID, internalPath: internalPath)
            let items = try await reader.items(at: address)
            guard items.count <= 10_000 else { throw AutomationError.listingTooLarge }
            let page = try Self.page(items.map(AutomationItem.init), offset: offset, limit: limit)
            await reader.closeSession(root.sessionID)
            return page
        } catch {
            await reader.closeSession(result.address.sessionID)
            throw error
        }
    }

    func compress(sources: [String], destination: String, format: ArchiveCompressionFormat) async throws -> AutomationOperation {
        guard (1...256).contains(sources.count), [.zip, .sevenZip].contains(format) else { throw AutomationError.invalidArguments }
        let urls = try sources.map(AutomationPath.url)
        let output = try AutomationPath.url(destination)
        return try await start(kind: "compress", inputs: urls, output: output) { engine, progress in
            try await engine.createArchive(from: urls, outputURL: output, options: CompressionOptions(format: format),
                                           password: nil, progress: progress)
        }
    }

    func extract(archive: String, destination: String, password: String? = nil) async throws -> AutomationOperation {
        let url = try AutomationPath.url(archive)
        let output = try AutomationPath.url(destination)
        return try await start(kind: "extract", inputs: [url], output: output) { engine, progress in
            // Atomically claim the new folder across independent MCP connections before extracting.
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: false)
            try await engine.extractArchive(at: url, to: output, password: password,
                resolveConflict: { _ in .cancel }, progress: progress)
        }
    }

    func test(archive: String, password: String? = nil) async throws -> AutomationOperation {
        let url = try AutomationPath.url(archive)
        return try await start(kind: "test", inputs: [url], output: nil) { engine, _ in
            try await engine.testArchive(at: url, password: password)
        }
    }

    func status(_ id: UUID) throws -> AutomationOperation {
        guard let value = operations[id] else { throw AutomationError.notFound }
        return value
    }

    func cancel(_ id: UUID) async throws -> AutomationOperation {
        guard operations[id] != nil else { throw AutomationError.notFound }
        if let job = active, job.id == id {
            operations[id]?.state = .cancelling
            job.task.cancel()
            // The native backend cancels this task's operation through its cancellation handler.
            // A global engine cancel could race with, and cancel, the next job.
        }
        return try status(id)
    }

    func wait(_ id: UUID) async throws -> AutomationOperation {
        if let job = active, job.id == id { await job.task.value }
        return try status(id)
    }

    func shutdown() async {
        closed = true
        if let job = active {
            _ = try? await cancel(job.id)
            await job.task.value
        }
        await engine.closeAllSessions()
    }

    private func start(kind: String, inputs: [URL], output: URL?,
        action: @escaping @Sendable (any ArchiveServing, @escaping ArchiveProgressHandler) async throws -> Void) async throws -> AutomationOperation {
        guard !closed else { throw AutomationError.notFound }
        guard active == nil, !reserved else { throw AutomationError.busy }
        reserved = true
        defer { reserved = false }
        let targets = inputs.map { AutomationAccessTarget(url: $0, kind: .existingItem) }
            + (output.map { [AutomationAccessTarget(url: $0, kind: .newItem)] } ?? [])
        let lease = try await access.authorize(targets)
        guard !closed else { throw AutomationError.notFound }
        guard inputs.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }) else { throw AutomationError.notFound }
        if let output {
            // Check both normal and dangling symlinks; never replace any preexisting destination.
            if (try? FileManager.default.attributesOfItem(atPath: output.path)) != nil { throw AutomationError.destinationExists }
            let parent = output.deletingLastPathComponent()
            guard try parent.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else { throw AutomationError.invalidArguments }
        }
        let id = UUID()
        let value = AutomationOperation(id: id, kind: kind, state: .running, outputPath: output?.path)
        operations[id] = value
        order.append(id)
        while order.count > 64 { operations.removeValue(forKey: order.removeFirst()) }
        let engine = self.engine
        let owner = self
        let task = Task {
            defer { withExtendedLifetime(lease) {} }
            do {
                try Task.checkCancellation()
                try await action(engine) { progress in
                    Task { await owner.progress(id, value: progress) }
                }
                try Task.checkCancellation()
                await owner.finish(id, state: .succeeded, error: nil)
            } catch {
                let cancelled = Task.isCancelled || error is CancellationError || (error as? ArchiveEngineError) == .cancelled
                await owner.finish(id, state: cancelled ? .cancelled : .failed, error: Self.errorCode(error))
            }
        }
        active = (id, task)
        return value
    }

    private func progress(_ id: UUID, value: ArchiveProgress) {
        guard operations[id]?.state == .running else { return }
        operations[id]?.phase = switch value.phase { case .staging: "staging"; case .compressing: "compressing"; case .extracting: "extracting" }
        operations[id]?.fraction = value.fraction
    }

    private func finish(_ id: UUID, state: AutomationOperation.State, error: String?) {
        operations[id]?.state = state
        operations[id]?.errorCode = error
        if state == .succeeded { operations[id]?.fraction = 1 }
        if active?.id == id { active = nil }
    }

    nonisolated static func errorCode(_ error: any Error) -> String {
        if let value = error as? AutomationError { return value.rawValue }
        if let value = error as? ArchiveEngineError {
            switch value {
            case .passwordRequired: return "passwordRequired"
            case .invalidPassword: return "invalidPassword"
            case .unsafePath: return "unsafePath"
            case .cancelled: return "cancelled"
            case .insufficientSpace: return "insufficientSpace"
            default: return "archiveFailed"
            }
        }
        if error is CancellationError { return "cancelled" }
        return "operationFailed"
    }

    nonisolated static func page(_ items: [AutomationItem], offset: Int, limit: Int) throws -> AutomationPage {
        guard offset >= 0, offset <= items.count, (1...200).contains(limit) else { throw AutomationError.invalidArguments }
        let sorted = items.sorted { $0.path < $1.path }
        let end = min(offset + limit, sorted.count)
        return AutomationPage(items: Array(sorted[offset..<end]), nextOffset: end < sorted.count ? end : nil, total: sorted.count)
    }
}
