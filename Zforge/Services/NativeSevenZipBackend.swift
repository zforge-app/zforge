import Foundation
import Darwin

/// Counts the bytes native operations read from archives and their volumes (instrumentation
/// for the in-place reading contract; production engines do not install one).
nonisolated final class ArchiveSourceReadMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var total: UInt64 = 0
    private var cancelled = 0
    private var observer: (@Sendable (UInt64) -> Void)?
    var bytesRead: UInt64 { lock.withLock { total } }
    /// Operations that ended cancelled in the bridge.
    var cancelledOperations: Int { lock.withLock { cancelled } }
    /// Called on the native thread after each read, with that operation's bytes so far.
    var onRead: (@Sendable (UInt64) -> Void)? {
        get { lock.withLock { observer } }
        set { lock.withLock { observer = newValue } }
    }
    func reset() { lock.withLock { total = 0; cancelled = 0 } }
    fileprivate func finish(_ operation: ZFSevenZipOperation) {
        lock.withLock {
            total += operation.sourceBytesRead
            if operation.isCancelled { cancelled += 1 }
        }
    }
}

/// Why a native operation failed, from what the bridge reports (D-117, CURRENT-STATE “Failure
/// reasons”): 7-Zip's result for the first item that failed (`NArchive::NExtract::NOperationResult`)
/// with that item's path, else the error flags (`kpv_ErrorFlags_*`) of a handler that recognized
/// the file but could not open it.
nonisolated enum NativeFailureReason: Equatable {
    case unsupportedMethod(item: String?), dataError(item: String?), crcError(item: String?)
    case incomplete, unavailable, headers, dataAfterEnd, notArchive, unsupportedFeature, sparse
    case unreadable, unwritable

    /// Open error flags, most telling first: a missing end also breaks the headers after it.
    private static let flagReasons: [(bit: Int, reason: NativeFailureReason)] = [
        (5, .incomplete), (1, .headers), (2, .headers), (3, .unavailable), (4, .unavailable),
        (7, .unsupportedMethod(item: nil)), (8, .unsupportedFeature), (9, .dataError(item: nil)),
        (10, .crcError(item: nil)), (6, .dataAfterEnd), (0, .notArchive)
    ]

    init(userInfo: [String: Any], writing: Bool) {
        let item = (userInfo["failedItem"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        switch (userInfo["extractResult"] as? NSNumber)?.intValue ?? 0 {
        case 1: self = .unsupportedMethod(item: item); return
        case 2: self = .dataError(item: item); return
        case 3: self = .crcError(item: item); return
        case 4: self = .unavailable; return
        case 5: self = .incomplete; return
        case 6: self = .dataAfterEnd; return
        case 7: self = .notArchive; return
        case 8: self = .headers; return
        default: break
        }
        let flags = (userInfo["openErrorFlags"] as? NSNumber)?.uint32Value ?? 0
        if let match = Self.flagReasons.first(where: { flags & (UInt32(1) << $0.bit) != 0 }) {
            self = match.reason
        } else if (userInfo["HRESULT"] as? NSNumber)?.int32Value == 1 {
            // S_FALSE: no handler opened the file.
            self = .notArchive
        } else {
            self = writing ? .unwritable : .unreadable
        }
    }

    var message: String {
        switch self {
        case let .unsupportedMethod(item?): AppLocalization.string("archive.reason.unsupported_method \(item)")
        case .unsupportedMethod: AppLocalization.string("archive.reason.unsupported_method")
        case let .dataError(item?): AppLocalization.string("archive.reason.data_error \(item)")
        case .dataError: AppLocalization.string("archive.reason.data_error")
        case let .crcError(item?): AppLocalization.string("archive.reason.crc_error \(item)")
        case .crcError: AppLocalization.string("archive.reason.crc_error")
        case .incomplete: AppLocalization.string("archive.reason.incomplete")
        case .unavailable: AppLocalization.string("archive.reason.unavailable")
        case .headers: AppLocalization.string("archive.reason.headers")
        case .dataAfterEnd: AppLocalization.string("archive.reason.data_after_end")
        case .notArchive: AppLocalization.string("archive.reason.not_archive")
        case .unsupportedFeature: AppLocalization.string("archive.reason.unsupported_feature")
        case .sparse: AppLocalization.string("archive.reason.sparse")
        case .unreadable: AppLocalization.string("archive.reason.unreadable")
        case .unwritable: AppLocalization.string("archive.reason.unwritable")
        }
    }
}

/// Owns cancellation handles; the native calls run on workers and never hold the UI actor.
nonisolated final class NativeSevenZipBackend: @unchecked Sendable {
    private final class Operation: @unchecked Sendable {
        let id = UUID()
        let native = ZFSevenZipOperation()
        let resource: URL
        init(resource: URL) { self.resource = resource }
    }
    static func registeredFormats() -> [String] { ZFSevenZipBridge.formats() }

    private let lock = NSLock()
    private var operations: [UUID: Operation] = [:]
    private let readMeter: ArchiveSourceReadMeter?

    init(readMeter: ArchiveSourceReadMeter? = nil) { self.readMeter = readMeter }

    func cancelAll() {
        lock.lock()
        let active = Array(operations.values)
        lock.unlock()
        active.forEach { $0.native.cancel() }
    }

    func cancelOperations(in directory: URL) async {
        let prefix = directory.standardizedFileURL.path + "/"
        let active = lock.withLock { operations.values.filter { $0.resource.standardizedFileURL.path.hasPrefix(prefix) } }
        active.forEach { $0.native.cancel() }
        while lock.withLock({ active.contains { operations[$0.id] != nil } }) {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func perform<T: Sendable>(
        resource: URL, writing: Bool = false, _ body: @escaping @Sendable (ZFSevenZipOperation) throws -> T
    ) async throws -> T {
        let operation = Operation(resource: resource)
        if let readMeter { operation.native.readObserver = { readMeter.onRead?($0) } }
        lock.withLock { operations[operation.id] = operation }
        defer {
            _ = lock.withLock { operations.removeValue(forKey: operation.id) }
            readMeter?.finish(operation.native)
        }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try autoreleasepool { try body(operation.native) }
                        continuation.resume(returning: result)
                    } catch { continuation.resume(throwing: Self.translate(error, writing: writing)) }
                }
            }
        } onCancel: { operation.native.cancel() }
    }

    static func translate(_ error: Error, writing: Bool = false) -> Error {
        let native = error as NSError
        guard native.domain == "Zforge.SevenZip" else { return error }
        switch native.code {
        case 1: return ArchiveEngineError.passwordRequired
        case 2: return ArchiveEngineError.invalidPassword
        case 3: return ArchiveEngineError.sizeLimitExceeded
        case 4: return ArchiveEngineError.cancelled
        case 6: return ArchiveEngineError.insufficientSpace
        case 8: return ArchiveEngineError.archiveChangedSinceOpening
        case 9 where native.userInfo["missingVolume"] is String:
            return ArchiveEngineError.missingVolume(native.userInfo["missingVolume"] as? String ?? "")
        case 10: return ArchiveEngineError.invalidArchive(NativeFailureReason.sparse.message)
        default:
            return ArchiveEngineError.invalidArchive(NativeFailureReason(userInfo: native.userInfo, writing: writing).message)
        }
    }

    private static func signedSize(_ value: NSNumber?) -> Int64? {
        guard let value, value.uint64Value <= UInt64(Int64.max) else { return nil }
        return value.int64Value
    }

    /// `cancellationScope` registers the read under a session folder, so closing that session
    /// cancels it even though the archive is read in place elsewhere.
    func list(at url: URL, password: String?, cancellationScope: URL? = nil) async throws -> [String: ArchiveEntry] {
        try await listing(at: url, password: password, cancellationScope: cancellationScope).entries
    }

    /// The listing and whether reading it needed the password (encrypted names).
    func listing(at url: URL, password: String?, cancellationScope: URL? = nil) async throws
        -> (entries: [String: ArchiveEntry], needsPassword: Bool) {
        try await perform(resource: cancellationScope ?? url) { operation in
            let records = try ZFSevenZipBridge.entries(atPath: url.path, password: password, operation: operation)
            var entries: [String: ArchiveEntry] = [:]
            let fallback = url.deletingPathExtension().lastPathComponent
            for record in records {
                let path = try ArchivePathPolicy.safePath(record.path.isEmpty ? fallback : record.path)
                guard !path.isEmpty else { continue }
                var entry = ArchiveEntry(
                    path: path, isDirectory: record.directory, size: Self.signedSize(record.size),
                    packedSize: Self.signedSize(record.packedSize), modified: record.modified,
                    created: record.created, accessed: record.accessed, encrypted: record.encrypted,
                    checksum: record.checksum, method: record.method, attributes: record.symbolicLink ? "l" : nil
                )
                entry.nativeIndex = UInt32(clamping: record.index)
                if record.solidBlock {
                    entry.solidBlock = ArchiveSolidBlock(packedSize: Self.signedSize(record.solidBlockPackedSize))
                }
                entries[path] = entry
            }
            return (ArchiveEntry.withParents(entries), operation.passwordRequested)
        }
    }

    func test(at url: URL, password: String?) async throws {
        try await perform(resource: url) { operation in
            try ZFSevenZipBridge.test(atPath: url.path, password: password, operation: operation)
        }
    }

    /// Equivalent to `output.resolvingSymlinksInPath().path` for the containment check,
    /// resolving each parent directory once. Only a symbolic-link leaf can redirect a path
    /// beyond its resolved parent, so such leaves are still resolved in full.
    private struct ContainmentResolver {
        private var parents: [String: String] = [:]

        mutating func resolvedPath(of output: URL) -> String {
            var status = stat()
            if lstat(output.path, &status) == 0 && (status.st_mode & S_IFMT) == S_IFLNK {
                return output.resolvingSymlinksInPath().path
            }
            let parent = output.deletingLastPathComponent()
            let resolved: String
            if let cached = parents[parent.path] {
                resolved = cached
            } else {
                resolved = parent.resolvingSymlinksInPath().path
                parents[parent.path] = resolved
            }
            return resolved == "/" ? "/" + output.lastPathComponent : resolved + "/" + output.lastPathComponent
        }
    }

    /// Creates the missing folders of `directory` below `root`; returns the ones it created,
    /// outermost first.
    @discardableResult
    fileprivate static func prepareDirectory(_ directory: URL, under root: URL) throws -> [URL] {
        let relative = directory.path == root.path ? "" : String(directory.path.dropFirst(root.path.count + 1))
        var descriptor = open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ArchiveEngineError.unsafePath }
        defer { close(descriptor) }
        var created: [URL] = []
        var current = root
        for component in relative.split(separator: "/") {
            let name = String(component)
            current.appendPathComponent(name, isDirectory: true)
            if mkdirat(descriptor, name, 0o700) == 0 {
                created.append(current)
            } else if errno != EEXIST {
                throw errno == ENOSPC ? ArchiveEngineError.insufficientSpace : ArchiveEngineError.unsafePath
            }
            let child = openat(descriptor, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard child >= 0 else { throw ArchiveEngineError.unsafePath }
            close(descriptor); descriptor = child
        }
        return created
    }

    private static func changeLink(at output: URL, under root: URL, target: String?) throws {
        var descriptor = open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ArchiveEngineError.unsafePath }
        defer { close(descriptor) }
        let relative = String(output.deletingLastPathComponent().path.dropFirst(root.path.count))
        for component in relative.split(separator: "/") {
            let child = openat(descriptor, String(component), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard child >= 0 else { throw ArchiveEngineError.unsafePath }
            close(descriptor); descriptor = child
        }
        guard unlinkat(descriptor, output.lastPathComponent, 0) == 0 else { throw ArchiveEngineError.unsafePath }
        if let target, symlinkat(target, descriptor, output.lastPathComponent) != 0 {
            throw ArchiveEngineError.unsafePath
        }
    }

    /// Decides the destination of each archive record. Shared by indexed extraction, which
    /// plans every record before the native call, and sequential (compressed tar) extraction,
    /// which plans each record as the stream reaches it.
    private final class ExtractionPlan {
        let fileManager = FileManager.default
        let root: URL
        let paths: [String]
        let selection: ArchivePathSelection
        let outputFile: URL?
        let fallback: String
        /// Archive path whose own contents land directly in `root` (no ancestors).
        let base: String
        private var preparedDirectories = Set<String>()
        private var resolver = ContainmentResolver()
        private var outputFileAssigned = false
        private(set) var outputs: [(ZFSevenZipEntry, URL)] = []
        /// Folders this extraction created, outermost first.
        private var createdDirectories: [URL] = []

        init(root: URL, paths: [String], outputFile: URL?, fallback: String, base: String) {
            self.root = root; self.paths = paths; selection = ArchivePathSelection(paths)
            self.outputFile = outputFile; self.fallback = fallback; self.base = base
        }

        /// Destination path for the record, or nil when nothing is written for it.
        func destination(for record: ZFSevenZipEntry) throws -> String? {
            guard !outputFileAssigned else { return nil }
            let path = try ArchivePathPolicy.safePath(record.path.isEmpty ? fallback : record.path)
            guard paths.isEmpty || selection.contains(path) else { return nil }
            if let outputFile, !record.directory {
                outputFileAssigned = true
                outputs.append((record, outputFile))
                return outputFile.standardizedFileURL.resolvingSymlinksInPath().path
            }
            var relative = path
            if !base.isEmpty {
                if path == base {
                    // The base itself is the root: it already exists.
                    guard record.directory else { throw ArchiveEngineError.unsafePath }
                    return nil
                }
                if path.hasPrefix(base + "/") { relative = String(path.dropFirst(base.count + 1)) }
            }
            let output = root.appendingPathComponent(relative).standardizedFileURL
            guard resolver.resolvedPath(of: output).hasPrefix(root.path + "/") else { throw ArchiveEngineError.unsafePath }
            if record.directory {
                if preparedDirectories.insert(output.path).inserted { createdDirectories += try NativeSevenZipBackend.prepareDirectory(output, under: root) }
                return nil
            }
            // Existing destinations were resolved by the Swift conflict policy. Keep means skip.
            if fileManager.fileExists(atPath: output.path) { return nil }
            let parent = output.deletingLastPathComponent()
            if preparedDirectories.insert(parent.path).inserted { createdDirectories += try NativeSevenZipBackend.prepareDirectory(parent, under: root) }
            if record.symbolicLink && (record.size?.uint64Value ?? 0) > 4096 { throw ArchiveEngineError.unsafePath }
            outputs.append((record, output))
            return output.path
        }

        /// After a failed extraction, removes the folders it created that are still empty, so
        /// one that stopped at the password leaves nothing (D-117). Folders that were already
        /// there, or that hold anything, stay.
        func removeEmptyCreatedDirectories() {
            for directory in createdDirectories.reversed() { rmdir(directory.path) }
        }
    }

    /// Extracts the selected paths (all when empty) below `destination`. `base` strips that
    /// archive path from the outputs, so a selected folder's contents land in `destination`.
    /// `lastIndex` bounds a sequential pass: decompression stops after that native index.
    /// `verify` runs once the archive is open, before anything is written: false fails with
    /// `archiveChangedSinceOpening`.
    func extract(at url: URL, password: String?, paths: [String], destination: URL,
                 outputFile: URL? = nil, byteLimit: UInt64 = .max, base: String = "",
                 lastIndex: UInt32? = nil, cancellationScope: URL? = nil,
                 verify: (@Sendable () -> Bool)? = nil) async throws {
        try await perform(resource: cancellationScope ?? url) { operation in
            let root = destination.standardizedFileURL.resolvingSymlinksInPath()
            let plan = ExtractionPlan(root: root, paths: paths, outputFile: outputFile,
                fallback: url.deletingPathExtension().lastPathComponent, base: base)
            // One opening lists and extracts; `verify` confirms it is still the archive the
            // caller listed before anything is written (D-73: never items of a replaced archive).
            var plannerError: Error?
            do {
                try ZFSevenZipBridge.extractPlanned(atPath: url.path, password: password, rootPath: root.path,
                    byteLimit: byteLimit, last: lastIndex ?? UInt32.max, planner: { record, abort in
                        do { return try plan.destination(for: record) } catch {
                            plannerError = error; abort.pointee = true; return nil
                        }
                    }, ready: verify.map { check in { check() } }, operation: operation)
            } catch {
                plan.removeEmptyCreatedDirectories()
                throw plannerError ?? error
            }
            var links: [(URL, String)] = []
            for (record, output) in plan.outputs where record.symbolicLink && outputFile == nil {
                let data = try Data(contentsOf: output)
                guard let target = String(data: data, encoding: .utf8), !target.hasPrefix("/"),
                      !target.utf8.contains(0) else { throw ArchiveEngineError.unsafePath }
                let resolved = output.deletingLastPathComponent().appendingPathComponent(target)
                    .standardizedFileURL.resolvingSymlinksInPath()
                guard resolved.path.hasPrefix(root.path + "/") else { throw ArchiveEngineError.unsafePath }
                links.append((output, target))
            }
            var installed: [URL] = []
            do {
                for (output, target) in links {
                    try Self.changeLink(at: output, under: root, target: target)
                    installed.append(output)
                }
                for output in installed {
                    guard output.resolvingSymlinksInPath().path.hasPrefix(root.path + "/") else {
                        throw ArchiveEngineError.unsafePath
                    }
                }
            } catch {
                for output in installed { try? Self.changeLink(at: output, under: root, target: nil) }
                throw error
            }
        }
    }

    /// A file or folder read in place and stored under `archivePath`.
    struct WriteSource: Sendable {
        let url: URL
        let archivePath: String
    }

    func write(to url: URL, updating original: URL? = nil, options: CompressionOptions,
               password: String?, names: [String], directory: URL, excludingPaths: [String] = [],
               volumeSizes: [UInt64] = []) async throws {
        try await write(to: url, updating: original, options: options, password: password,
            sources: names.map { WriteSource(url: directory.appendingPathComponent($0), archivePath: $0) },
            excludingPaths: excludingPaths, volumeSizes: volumeSizes)
    }

    /// Writes the archive at `url`, or, with `volumeSizes`, the split archive `url.001`,
    /// `url.002`… of those sizes (the last one repeating, ZF-83).
    func write(to url: URL, updating original: URL? = nil, options: CompressionOptions,
               password: String?, sources items: [WriteSource], excludingPaths: [String] = [],
               volumeSizes: [UInt64] = []) async throws {
        let options = options.normalized()
        try await perform(resource: url, writing: true) { operation in
            let properties = try options.nativeProperties(password: password)
            let fm = FileManager.default
            var sources: [ZFSevenZipSource] = []
            func append(_ file: URL, name: String) throws {
                let values = try file.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isSymbolicLinkKey])
                let source = ZFSevenZipSource()
                source.path = file.path; source.archivePath = try ArchivePathPolicy.safePath(name)
                source.directory = values.isDirectory == true && values.isSymbolicLink != true
                let attributes = try fm.attributesOfItem(atPath: file.path)
                let permissions = (attributes[.posixPermissions] as? NSNumber)?.uint32Value ?? 0o644
                source.posixMode = permissions | (source.directory ? 0o040000 : 0o100000)
                if values.isSymbolicLink == true {
                    source.linkTarget = try fm.destinationOfSymbolicLink(atPath: file.path)
                    source.posixMode = permissions | 0o120000
                }
                source.size = UInt64(source.linkTarget?.utf8.count ?? max(values.fileSize ?? 0, 0))
                source.modified = values.contentModificationDate ?? Date()
                sources.append(source)
                if source.directory {
                    for child in try fm.contentsOfDirectory(at: file, includingPropertiesForKeys: nil).sorted(by: { $0.path < $1.path }) {
                        try append(child, name: name + "/" + child.lastPathComponent)
                    }
                }
            }
            for item in items { try append(item.url, name: item.archivePath) }
            try ZFSevenZipBridge.write(atPath: url.path, format: options.format.nativeHandlerName,
                updatingPath: original?.path, sources: sources, properties: properties,
                excludingPaths: excludingPaths, password: options.requiresPassword || original != nil ? password : nil,
                volumeSizes: volumeSizes.map { NSNumber(value: $0) }, operation: operation)
        }
    }
}
