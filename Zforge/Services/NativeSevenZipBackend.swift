import Foundation
import Darwin

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
        defer { _ = lock.withLock { operations.removeValue(forKey: operation.id) } }
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

    func list(at url: URL, password: String?) async throws -> [String: ArchiveEntry] {
        try await perform(resource: url) { operation in
            let records = try ZFSevenZipBridge.entries(atPath: url.path, password: password, operation: operation)
            var entries: [String: ArchiveEntry] = [:]
            for record in records {
                let fallback = url.deletingPathExtension().lastPathComponent
                let path = try ArchivePathPolicy.safePath(record.path.isEmpty ? fallback : record.path)
                guard !path.isEmpty else { continue }
                entries[path] = ArchiveEntry(
                    path: path, isDirectory: record.directory, size: Self.signedSize(record.size),
                    packedSize: Self.signedSize(record.packedSize), modified: record.modified,
                    created: record.created, accessed: record.accessed, encrypted: record.encrypted,
                    checksum: record.checksum, method: record.method, attributes: record.symbolicLink ? "l" : nil
                )
            }
            return ArchiveEntry.withParents(entries)
        }
    }

    func test(at url: URL, password: String?) async throws {
        try await perform(resource: url) { operation in
            try ZFSevenZipBridge.test(atPath: url.path, password: password, operation: operation)
        }
    }

    private static func prepareDirectory(_ directory: URL, under root: URL) throws {
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

    func extract(at url: URL, password: String?, paths: [String], destination: URL,
                 outputFile: URL? = nil, byteLimit: UInt64 = .max) async throws {
        try await perform(resource: url) { operation in
            let records = try ZFSevenZipBridge.entries(atPath: url.path, password: password, operation: operation)
            let fm = FileManager.default
            let root = destination.standardizedFileURL.resolvingSymlinksInPath()
            var indices: [NSNumber] = []
            var destinations: [String] = []
            var outputs: [(ZFSevenZipEntry, URL)] = []
            var preparedDirectories = Set<String>()
            for record in records {
                let fallback = url.deletingPathExtension().lastPathComponent
                let path = try ArchivePathPolicy.safePath(record.path.isEmpty ? fallback : record.path)
                guard paths.isEmpty || paths.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) else { continue }
                if let outputFile, !record.directory {
                    indices.append(NSNumber(value: record.index)); destinations.append(outputFile.standardizedFileURL.resolvingSymlinksInPath().path)
                    outputs.append((record, outputFile))
                    break
                }
                let output = root.appendingPathComponent(path).standardizedFileURL
                let resolved = output.resolvingSymlinksInPath()
                guard resolved.path.hasPrefix(root.path + "/") else { throw ArchiveEngineError.unsafePath }
                if record.directory {
                    if preparedDirectories.insert(output.path).inserted { try Self.prepareDirectory(output, under: root) }
                } else {
                    // Existing destinations were resolved by the Swift conflict policy. Keep means skip.
                    if fm.fileExists(atPath: output.path) { continue }
                    let parent = output.deletingLastPathComponent()
                    if preparedDirectories.insert(parent.path).inserted { try Self.prepareDirectory(parent, under: root) }
                    if record.symbolicLink && (record.size?.uint64Value ?? 0) > 4096 { throw ArchiveEngineError.unsafePath }
                    indices.append(NSNumber(value: record.index)); destinations.append(output.path)
                    outputs.append((record, output) )
                }
            }
            try ZFSevenZipBridge.extract(atPath: url.path, password: password, indices: indices,
                destinations: destinations, rootPath: root.path, byteLimit: byteLimit, operation: operation)
            var links: [(URL, String)] = []
            for (record, output) in outputs {
                if record.symbolicLink && outputFile == nil {
                    let data = try Data(contentsOf: output)
                    guard let target = String(data: data, encoding: .utf8), !target.hasPrefix("/"),
                          !target.utf8.contains(0) else { throw ArchiveEngineError.unsafePath }
                    let resolved = output.deletingLastPathComponent().appendingPathComponent(target)
                        .standardizedFileURL.resolvingSymlinksInPath()
                    guard resolved.path.hasPrefix(root.path + "/") else { throw ArchiveEngineError.unsafePath }
                    links.append((output, target))
                } else {
                    // Native metadata is applied on the already-open output descriptor.
                }
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

    func write(to url: URL, updating original: URL? = nil, options: CompressionOptions,
               password: String?, names: [String], directory: URL, excludingPaths: [String] = []) async throws {
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
            for name in names { try append(directory.appendingPathComponent(name), name: name) }
            try ZFSevenZipBridge.write(atPath: url.path, format: options.format.nativeHandlerName,
                updatingPath: original?.path, sources: sources, properties: properties,
                excludingPaths: excludingPaths, password: options.requiresPassword || original != nil ? password : nil, operation: operation)
        }
    }
}
