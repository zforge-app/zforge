import Foundation
import Darwin

/// Counts the bytes native operations read from archives and their volumes (instrumentation
/// for the in-place reading contract; production engines do not install one).
nonisolated final class ArchiveSourceReadMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var total: UInt64 = 0
    var bytesRead: UInt64 { lock.withLock { total } }
    func reset() { lock.withLock { total = 0 } }
    fileprivate func add(_ bytes: UInt64) { lock.withLock { total += bytes } }
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
        resource: URL, _ body: @escaping @Sendable (ZFSevenZipOperation) throws -> T
    ) async throws -> T {
        let operation = Operation(resource: resource)
        lock.withLock { operations[operation.id] = operation }
        defer {
            _ = lock.withLock { operations.removeValue(forKey: operation.id) }
            readMeter?.add(operation.native.sourceBytesRead)
        }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try autoreleasepool { try body(operation.native) }
                        continuation.resume(returning: result)
                    } catch { continuation.resume(throwing: Self.translate(error)) }
                }
            }
        } onCancel: { operation.native.cancel() }
    }

    private static func translate(_ error: Error) -> Error {
        let native = error as NSError
        guard native.domain == "Zforge.SevenZip" else { return error }
        switch native.code {
        case 1: return ArchiveEngineError.passwordRequired
        case 2: return ArchiveEngineError.invalidPassword
        case 3: return ArchiveEngineError.sizeLimitExceeded
        case 4: return ArchiveEngineError.cancelled
        case 6: return ArchiveEngineError.insufficientSpace
        default: return ArchiveEngineError.invalidArchive(AppLocalization.string("archive.empty_or_unsupported"))
        }
    }

    private static func signedSize(_ value: NSNumber?) -> Int64? {
        guard let value, value.uint64Value <= UInt64(Int64.max) else { return nil }
        return value.int64Value
    }

    /// `cancellationScope` registers the read under a session folder, so closing that session
    /// cancels it even though the archive is read in place elsewhere.
    func list(at url: URL, password: String?, cancellationScope: URL? = nil) async throws -> [String: ArchiveEntry] {
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
            return ArchiveEntry.withParents(entries)
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

    fileprivate static func prepareDirectory(_ directory: URL, under root: URL) throws {
        let relative = directory.path == root.path ? "" : String(directory.path.dropFirst(root.path.count + 1))
        var descriptor = open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw ArchiveEngineError.unsafePath }
        defer { close(descriptor) }
        for component in relative.split(separator: "/") {
            let name = String(component)
            if mkdirat(descriptor, name, 0o700) != 0 && errno != EEXIST {
                throw errno == ENOSPC ? ArchiveEngineError.insufficientSpace : ArchiveEngineError.unsafePath
            }
            let child = openat(descriptor, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard child >= 0 else { throw ArchiveEngineError.unsafePath }
            close(descriptor); descriptor = child
        }
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
                if preparedDirectories.insert(output.path).inserted { try NativeSevenZipBackend.prepareDirectory(output, under: root) }
                return nil
            }
            // Existing destinations were resolved by the Swift conflict policy. Keep means skip.
            if fileManager.fileExists(atPath: output.path) { return nil }
            let parent = output.deletingLastPathComponent()
            if preparedDirectories.insert(parent.path).inserted { try NativeSevenZipBackend.prepareDirectory(parent, under: root) }
            if record.symbolicLink && (record.size?.uint64Value ?? 0) > 4096 { throw ArchiveEngineError.unsafePath }
            outputs.append((record, output))
            return output.path
        }
    }

    /// Extracts the selected paths (all when empty) below `destination`. `base` strips that
    /// archive path from the outputs, so a selected folder's contents land in `destination`.
    /// `lastIndex` bounds a sequential pass: decompression stops after that native index.
    func extract(at url: URL, password: String?, paths: [String], destination: URL,
                 outputFile: URL? = nil, byteLimit: UInt64 = .max, base: String = "",
                 lastIndex: UInt32? = nil, cancellationScope: URL? = nil) async throws {
        try await perform(resource: cancellationScope ?? url) { operation in
            let root = destination.standardizedFileURL.resolvingSymlinksInPath()
            let plan = ExtractionPlan(root: root, paths: paths, outputFile: outputFile,
                fallback: url.deletingPathExtension().lastPathComponent, base: base)
            if ZFSevenZipBridge.isCompressedTarPath(url.path) {
                var plannerError: Error?
                do {
                    try ZFSevenZipBridge.extractStream(atPath: url.path, password: password, rootPath: root.path,
                        byteLimit: byteLimit, last: lastIndex ?? UInt32.max, planner: { record, abort in
                            do { return try plan.destination(for: record) } catch {
                                plannerError = error; abort.pointee = true; return nil
                            }
                        }, operation: operation)
                } catch {
                    throw plannerError ?? error
                }
            } else {
                let records = try ZFSevenZipBridge.entries(atPath: url.path, password: password, operation: operation)
                var indices: [NSNumber] = []
                var destinations: [String] = []
                for record in records {
                    guard let output = try plan.destination(for: record) else { continue }
                    indices.append(NSNumber(value: record.index)); destinations.append(output)
                }
                try ZFSevenZipBridge.extract(atPath: url.path, password: password, indices: indices,
                    destinations: destinations, rootPath: root.path, byteLimit: byteLimit, operation: operation)
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
               password: String?, names: [String], directory: URL, excludingPaths: [String] = []) async throws {
        try await write(to: url, updating: original, options: options, password: password,
            sources: names.map { WriteSource(url: directory.appendingPathComponent($0), archivePath: $0) },
            excludingPaths: excludingPaths)
    }

    func write(to url: URL, updating original: URL? = nil, options: CompressionOptions,
               password: String?, sources items: [WriteSource], excludingPaths: [String] = []) async throws {
        let options = options.normalized()
        try await perform(resource: url) { operation in
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
                excludingPaths: excludingPaths, password: options.requiresPassword || original != nil ? password : nil, operation: operation)
        }
    }
}
