import Foundation
import Darwin

/// A minimal set of subtree roots, used for authorization and pending work.
nonisolated struct TagScanRoots: Sendable {
    private(set) var urls: [URL] = []

    mutating func insert(_ url: URL) {
        let url = url.standardizedFileURL
        guard !contains(url) else { return }
        urls.removeAll { Self.covers(url.path, $0.path) }
        urls.append(url)
    }

    func contains(_ url: URL) -> Bool {
        urls.contains { Self.covers($0.path, url.path) }
    }

    static func covers(_ root: String, _ path: String) -> Bool {
        path == root || path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }

    mutating func remove(coveredBy scopes: [URL]) {
        urls.removeAll { item in scopes.contains { Self.covers($0.path, item.path) } }
    }

    /// Bound error paths as well as ordinary work. A widespread failure can
    /// conservatively retain one common subtree rather than millions of URLs.
    mutating func deferRetry(_ url: URL) {
        insert(url)
        if urls.count > 512 {
            var ancestor = urls[0]
            for item in urls.dropFirst() {
                while !Self.covers(ancestor.path, item.path) { ancestor.deleteLastPathComponent() }
            }
            urls = [ancestor]
        }
    }

    mutating func take() -> [URL] {
        let result = urls
        urls.removeAll(keepingCapacity: true)
        return result
    }
}

/// Product discovery boundaries are separate from filesystem authorization.
nonisolated struct TagDiscoveryPolicy: Sendable {
    static var standardRoots: [URL] {
        [UserDirectoryService.homeURL, URL(fileURLWithPath: "/Users/Shared", isDirectory: true)]
    }
    let roots: [URL]

    func contains(_ url: URL) -> Bool {
        roots.contains { TagScanRoots.covers($0.standardizedFileURL.path, url.standardizedFileURL.path) }
    }

    func intersection(_ grant: URL) -> [URL] {
        roots.compactMap { root in
            if TagScanRoots.covers(grant.path, root.path) { return root }
            if TagScanRoots.covers(root.path, grant.path),
               TagScanRoots.covers(root.resolvingSymlinksInPath().path, grant.resolvingSymlinksInPath().path) {
                return grant
            }
            return nil
        }
    }

    func isVisible(_ url: URL, readFlags: (URL) -> UInt32? = Self.flags(at:)) -> Bool {
        guard let root = roots.first(where: { TagScanRoots.covers($0.path, url.path) }) else { return false }
        return Self.isVisible(url, boundary: root, readFlags: readFlags)
    }

    static func flags(at url: URL) -> UInt32? {
        var info = stat()
        return url.withUnsafeFileSystemRepresentation { lstat($0!, &info) } == 0 ? info.st_flags : nil
    }

    static func isVisible(_ url: URL, boundary: URL? = nil, readFlags: (URL) -> UInt32? = Self.flags(at:)) -> Bool {
        var current = url.standardizedFileURL
        var ancestors: [URL] = []
        while current.path != "/" {
            if current.lastPathComponent.hasPrefix(".") { return false }
            ancestors.append(current)
            if current.path == boundary?.standardizedFileURL.path { break }
            current.deleteLastPathComponent()
        }
        // A hidden ancestor rejects the whole subtree before probing any of
        // its descendants, including inaccessible or frequently changing items.
        for ancestor in ancestors.reversed() {
            if (readFlags(ancestor) ?? 0) & UInt32(UF_HIDDEN) != 0 { return false }
        }
        return true
    }
}

/// Reads real Finder metadata even where a sandboxed Spotlight query omits it.
/// One utility worker drains Foundation temporaries per item and cooperatively
/// suspends between bounded slices. There are no periodic wakeups after return.
nonisolated enum TaggedFileScanner {
    typealias Batch = [String: [String: Int]]
    typealias Publish = @Sendable (Batch) async -> Void
    typealias Scan = @Sendable ([URL], @escaping Publish) async -> Void
    typealias Read = @Sendable ([URL]) async -> Batch

    struct Budget: Sendable {
        var usesBulkEnumeration = true
        var maximumItems = 128
        var workSlice: Duration = .milliseconds(8)
        var pause: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    }

    struct ReadResult: Sendable {
        var records: Batch
        var complete: Bool
        var deferred: [URL] = []
    }

    struct ScanResult: Sendable {
        var interrupted = false
        var deferred: [URL] = []
        var inspected: UInt64 = 0
        var metadataReads: UInt64 = 0
        var complete: Bool { !interrupted && deferred.isEmpty }
    }

    static func read(_ urls: [URL], budget: Budget = Budget()) async -> Batch {
        await readResult(urls, budget: budget).records
    }

    static func readResult(_ urls: [URL], budget: Budget = Budget()) async -> ReadResult {
        let worker = Task.detached(priority: .utility) {
            let exclusion = TemporaryExclusion()
            let clock = ContinuousClock()
            var start = clock.now
            var inspected = 0
            var records: Batch = [:]
            var complete = true
            var deferred = TagScanRoots()
            for url in urls {
                guard !Task.isCancelled else { break }
                autoreleasepool {
                    let url = url.standardizedFileURL
                    // Canonicalize only for exclusion. Keep the enumerated
                    // item's identity so a later empty read removes that path.
                    let canonicalPath = url.resolvingSymlinksInPath().path
                    guard !exclusion.contains(path: canonicalPath) else { return }
                    let boundary = ([FileManager.default.temporaryDirectory] + TagDiscoveryPolicy.standardRoots)
                        .first { TagScanRoots.covers($0.path, url.path) }
                    guard TagDiscoveryPolicy.isVisible(url, boundary: boundary) else { records[url.path] = [:]; return }
                    let metadata = url.withUnsafeFileSystemRepresentation { FinderTagMetadata.readColorIndexes(atPath: $0!) }
                    if metadata.complete { records[url.path] = metadata.colors }
                    else { complete = false; deferred.deferRetry(url) }
                }
                inspected += 1
                let elapsed = start.duration(to: clock.now)
                if inspected >= budget.maximumItems || elapsed >= budget.workSlice {
                    do { try await budget.pause(elapsed * 4) } catch { break }
                    start = clock.now
                    inspected = 0
                }
            }
            if inspected > 0, !Task.isCancelled {
                try? await budget.pause(start.duration(to: clock.now) * 4)
            }
            return ReadResult(records: records, complete: complete && !Task.isCancelled, deferred: deferred.urls)
        }
        return await withTaskCancellationHandler {
            await worker.value
        } onCancel: { worker.cancel() }
    }

    @discardableResult
    static func scan(_ roots: [URL], budget: Budget = Budget(), onBatch: @escaping Publish) async -> Bool {
        await scanResult(roots, budget: budget, onBatch: onBatch).complete
    }

    static func scanResult(_ roots: [URL], budget: Budget = Budget(), onBatch: @escaping Publish) async -> ScanResult {
        let worker = Task.detached(priority: .utility) {
            await discover(roots, budget: budget, onBatch: onBatch)
        }
        return await withTaskCancellationHandler {
            await worker.value
        } onCancel: { worker.cancel() }
    }

    private static func discover(_ roots: [URL], budget: Budget, onBatch: @escaping Publish) async -> ScanResult {
        let exclusion = TemporaryExclusion()
        let clock = ContinuousClock()
        var sliceStart = clock.now
        var inspected = 0
        var batch: Batch = [:]
        var uniqueRoots = TagScanRoots()
        for root in roots { uniqueRoots.insert(root.resolvingSymlinksInPath()) }
        var visitedRoots: Set<String> = []
        var deferred = TagScanRoots()
        var totalInspected: UInt64 = 0
        var metadataReads: UInt64 = 0

        // Bound tagged output as well as untagged enumeration. Publication never
        // holds an autorelease pool across an await.
        func checkpoint(force: Bool = false) async -> Bool {
            guard !Task.isCancelled else { return false }
            let elapsed = sliceStart.duration(to: clock.now)
            guard force || inspected >= budget.maximumItems || elapsed >= budget.workSlice else { return true }
            // Empty checkpoints allow incremental reads to interleave even
            // while traversing a large subtree containing no tags.
            await onBatch(batch)
            batch.removeAll(keepingCapacity: true)
            guard !Task.isCancelled else { return false }
            if inspected > 0 {
                // Target a 20% duty cycle for this single worker. A filesystem
                // syscall cannot be preempted at an exact 8 ms boundary.
                do { try await budget.pause(elapsed * 4) } catch { return false }
            }
            inspected = 0
            sliceStart = clock.now
            return !Task.isCancelled
        }

        for root in uniqueRoots.urls {
            let identityRoot = roots.first { $0.resolvingSymlinksInPath().path == root.path } ?? root
            func identity(_ path: String) -> String {
                identityRoot.path + path.dropFirst(root.path.count)
            }
            let priorityRoots = root == UserDirectoryService.homeURL ? [
                root.appendingPathComponent("Downloads"), root.appendingPathComponent("Documents"),
                root.appendingPathComponent("Desktop"), root.appendingPathComponent("Library/Mobile Documents"),
                root.appendingPathComponent("Library/CloudStorage"), root
            ] : [root]
            for candidate in priorityRoots {
                let directory = candidate.resolvingSymlinksInPath().standardizedFileURL
                guard !Task.isCancelled else { return ScanResult(interrupted: true) }
                guard visitedRoots.insert(directory.path).inserted,
                      TagScanRoots.covers(root.path, directory.path),
                      !exclusion.contains(path: directory.path),
                      TagDiscoveryPolicy.isVisible(directory, boundary: root) else { continue }
                autoreleasepool {
                    metadataReads += 1
                    let metadata = directory.withUnsafeFileSystemRepresentation { FinderTagMetadata.readColorIndexes(atPath: $0!) }
                    if !metadata.complete { deferred.deferRetry(URL(fileURLWithPath: identity(directory.path))) }
                    if !metadata.colors.isEmpty { batch[identity(directory.path)] = metadata.colors }
                }
                inspected += 1
                totalInspected += 1
                guard await checkpoint() else { return ScanResult(interrupted: true) }
                if (try? directory.resourceValues(forKeys: [.isPackageKey]).isPackage) == true {
                    guard await checkpoint(force: true) else { return ScanResult(interrupted: true) }
                    continue
                }
                // Batch names, object types and hidden flags in one filesystem
                // call. Keep one bounded buffer per active directory, not per file.
                var stack = [TagDirectoryEntries(directory, useBulk: budget.usesBulkEnumeration)]
                while !Task.isCancelled, let current = stack.last {
                    guard let entry = current.next() else {
                        if current.failed { deferred.deferRetry(URL(fileURLWithPath: identity(current.directory.path))) }
                        stack.removeLast()
                        continue
                    }
                    var descend = false
                    autoreleasepool {
                        guard !entry.hidden else { return }
                        if entry.hasError {
                            deferred.deferRetry(URL(fileURLWithPath: identity(entry.path)))
                            return
                        }
                        if entry.descend {
                            let path = entry.path
                            guard !visitedRoots.contains(path), !exclusion.contains(path: path) else { return }
                            let url = URL(fileURLWithPath: path, isDirectory: true)
                            descend = (try? url.resourceValues(forKeys: [.isPackageKey]).isPackage) != true
                        }
                        // A reported absence is definitive for this inode. New
                        // attributes added during scanning are caught by the watcher.
                        guard entry.mayHaveXattrs else { return }
                        metadataReads += 1
                        let metadata = FinderTagMetadata.readColorIndexes(atPath: entry.rawPath)
                        if !metadata.complete { deferred.deferRetry(URL(fileURLWithPath: identity(entry.path))) }
                        let colors = metadata.colors
                        if !colors.isEmpty {
                            let path = entry.path
                            let canonicalPath = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
                            if !exclusion.contains(path: canonicalPath) { batch[identity(path)] = colors }
                        }
                    }
                    if descend { stack.append(TagDirectoryEntries(URL(fileURLWithPath: entry.path, isDirectory: true), useBulk: budget.usesBulkEnumeration)) }
                    inspected += 1
                    totalInspected += 1
                    // Avoid entering an async function for every untagged item.
                    // The suspension/publication remains bounded by both limits.
                    if inspected >= budget.maximumItems || sliceStart.duration(to: clock.now) >= budget.workSlice {
                        guard await checkpoint(force: true) else { return ScanResult(interrupted: true) }
                    }
                }
                guard await checkpoint(force: true) else { return ScanResult(interrupted: true) }
            }
        }
        return ScanResult(interrupted: Task.isCancelled, deferred: deferred.urls, inspected: totalInspected, metadataReads: metadataReads)
    }

    private struct TemporaryExclusion {
        let root = ZforgeTemporaryStorage.root().resolvingSymlinksInPath().standardizedFileURL.path
        func contains(path: String) -> Bool { TagScanRoots.covers(root, path) }
    }
}

/// Worker-local directory cursor. Bulk attributes describe the link itself;
/// symlinks are read as items and never traversed. Unsupported filesystems use
/// the characterized Foundation enumerator instead of omitting their contents.
nonisolated private final class TagDirectoryEntries {
    struct Entry {
        let rawPath: UnsafePointer<CChar>
        var path: String { String(cString: rawPath) }
        let descend: Bool
        let hidden: Bool
        let mayHaveXattrs: Bool
        let hasError: Bool
    }
    let directory: URL
    private let path: String
    private var cursor: OpaquePointer?
    private var fallback: FileManager.DirectoryEnumerator?
    private var fallbackPath: UnsafeMutablePointer<CChar>?
    private var finished = false
    private(set) var failed = false

    init(_ directory: URL, useBulk: Bool) {
        self.directory = directory
        self.path = directory.path
        if useBulk {
            cursor = path.withCString { ZFTagDirectoryOpen($0) }
            if cursor == nil { failed = errno != ENOENT && errno != ENOTDIR; finished = true }
        } else { startFallback() }
    }

    deinit { if let cursor { ZFTagDirectoryClose(cursor) }; free(fallbackPath) }

    private func startFallback() {
        if let cursor { ZFTagDirectoryClose(cursor); self.cursor = nil }
        fallback = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil,
            options: [.skipsPackageDescendants, .skipsHiddenFiles], errorHandler: { [weak self] _, error in
                if (error as NSError).code != NSFileNoSuchFileError { self?.failed = true }
                return true
            })
        if fallback == nil { failed = true; finished = true }
    }

    func next() -> Entry? {
        if let cursor {
            var entry = ZFTagDirectoryEntry()
            switch ZFTagDirectoryNext(cursor, &entry) {
            case 1:
                guard let path = entry.path else { failed = true; finished = true; return nil }
                return Entry(rawPath: path, descend: entry.isDirectory, hidden: entry.isHidden, mayHaveXattrs: entry.mayHaveXattrs, hasError: entry.hasError)
            case -1: startFallback()
            default: failed = failed || ZFTagDirectoryFailed(cursor); finished = true
            }
        }
        guard !finished, let fallback else { return nil }
        let url: URL? = autoreleasepool { fallback.nextObject() as? URL }
        guard let url else { finished = true; return nil }
        let entryPath = path + "/" + url.pathComponents.suffix(fallback.level).joined(separator: "/")
        free(fallbackPath)
        fallbackPath = strdup(entryPath)
        guard let fallbackPath else { failed = true; finished = true; return nil }
        return Entry(rawPath: UnsafePointer(fallbackPath), descend: false, hidden: false, mayHaveXattrs: true, hasError: false)
    }
}
