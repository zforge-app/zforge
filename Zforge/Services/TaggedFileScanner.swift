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
        if path == root { return true }
        let prefix = root.hasSuffix("/") ? root.dropLast() : root[...]
        // A slash followed by a combining mark is one Swift grapheme. Check
        // the POSIX separator byte, preserving canonical-equivalent scope
        // names through the fallback rather than changing filesystem identity.
        if let separated = bytePrefix(prefix, of: path) { return separated }
        return path.hasPrefix(prefix) && path.dropFirst(prefix.count).utf8.first == 0x2f
    }

    /// When `path`'s UTF-8 bytes begin with `prefix`, whether a separator byte
    /// follows; nil when the bytes differ. One contiguous comparison instead of
    /// generic per-element iteration (hot in cached restoration).
    private static func bytePrefix(_ prefix: Substring, of path: String) -> Bool? {
        var path = path
        var prefix = prefix
        return path.withUTF8 { pathBytes in
            prefix.withUTF8 { prefixBytes -> Bool? in
                guard pathBytes.count >= prefixBytes.count else { return nil }
                if !prefixBytes.isEmpty,
                   memcmp(pathBytes.baseAddress!, prefixBytes.baseAddress!, prefixBytes.count) != 0 { return nil }
                return pathBytes.count > prefixBytes.count && pathBytes[prefixBytes.count] == 0x2f
            }
        }
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

/// Visibility is shared only within one finite batch. Cache ancestors, not
/// thousands of distinct leaves, so sibling files reuse their directory probes.
/// String paths avoid constructing a URL for every ancestor of every record.
nonisolated struct TagVisibilityBatch {
    struct FileInfo {
        var flags: UInt32
        var needsMetadataRefresh = false
    }
    private let roots: [String]
    private(set) var metadataRechecks: Set<String> = []
    private var ancestorFlags: [String: UInt32] = [:]
    var cachedAncestorCount: Int { ancestorFlags.count }

    init(policy: TagDiscoveryPolicy) {
        roots = policy.roots.map { $0.standardizedFileURL.path }
    }

    func contains(normalizedPath path: String) -> Bool {
        roots.contains { TagScanRoots.covers($0, path) }
    }

    /// Scanner/checkpoint keys normally already have the scope's canonical
    /// prefix and no relative components. Avoid Foundation path construction
    /// on that common path; retain normalization for aliases and unusual inputs.
    func normalizedPath(_ path: String) -> String {
        if contains(normalizedPath: path), !Self.hasEmptyOrRelativeComponent(path) {
            return path
        }
        return URL(fileURLWithPath: path, isDirectory: false).standardizedFileURL.path
    }

    /// Whether any separator-delimited component after the first is empty, `.`
    /// or `..`. One byte pass, without allocating the component array.
    static func hasEmptyOrRelativeComponent(_ path: String) -> Bool {
        var component = 0
        var length = 0
        var dotsOnly = true
        func flagged() -> Bool { component > 0 && (length == 0 || (dotsOnly && length <= 2)) }
        for byte in path.utf8 {
            if byte == 0x2f {
                if flagged() { return true }
                component += 1
                length = 0
                dotsOnly = true
            } else {
                length += 1
                if byte != 0x2e { dotsOnly = false }
            }
        }
        return flagged()
    }

    mutating func isVisible(_ url: URL, readInfo: (String) -> FileInfo? = Self.info(at:)) -> Bool {
        isVisible(normalizedPath: url.standardizedFileURL.path, recordPath: url.path, readInfo: readInfo)
    }

    mutating func isVisible(normalizedPath path: String, recordPath: String? = nil,
                            readInfo: (String) -> FileInfo? = Self.info(at:)) -> Bool {
        guard let root = roots.first(where: { TagScanRoots.covers($0, path) }) else { return false }
        var ancestors: [String] = []
        var current = path
        while current != "/" {
            // POSIX separators are bytes, independent of Unicode grapheme
            // clusters (a leading combining mark can combine with the slash).
            let bytes = current.utf8
            guard let separator = bytes.lastIndex(of: 0x2f) else { return false }
            let nameStart = bytes.index(after: separator)
            if nameStart != bytes.endIndex, bytes[nameStart] == 0x2e { return false }
            ancestors.append(current)
            if current == root { break }
            current = separator == bytes.startIndex ? "/" : String(decoding: bytes[..<separator], as: UTF8.self)
        }
        for ancestor in ancestors.reversed() {
            let flags: UInt32
            if ancestor != path, let cached = ancestorFlags[ancestor] { flags = cached }
            else {
                let info = readInfo(ancestor)
                flags = info?.flags ?? 0
                if ancestor == path, info == nil || info?.needsMetadataRefresh == true { metadataRechecks.insert(recordPath ?? path) }
                if ancestor != path, ancestorFlags.count < 512 { ancestorFlags[ancestor] = flags }
            }
            if flags & UInt32(UF_HIDDEN) != 0 { return false }
        }
        return true
    }

    static func info(at path: String) -> FileInfo? {
        var info = stat()
        guard lstat(path, &info) == 0 else { return nil }
        let kind = info.st_mode & S_IFMT
        // Changes to a linked target may occur outside every watched scope.
        // Discover this during the existing visibility probe, with no extra stat.
        let refresh = kind == S_IFLNK || (kind == S_IFREG && info.st_nlink > 1)
        return FileInfo(flags: info.st_flags, needsMetadataRefresh: refresh)
    }
}

/// Reads real Finder metadata even where a sandboxed Spotlight query omits it.
/// One utility worker drains Foundation temporaries per item and yields between
/// bounded slices without a CPU duty cycle. There are no periodic wakeups after return.
nonisolated enum TaggedFileScanner {
    typealias Batch = [String: [String: Int]]
    typealias Publish = @Sendable (Batch) async -> Void
    typealias Scan = @Sendable ([URL], @escaping Publish) async -> Void
    typealias Read = @Sendable ([URL]) async -> Batch

    struct Budget: Sendable {
        var usesBulkEnumeration = true
        var maximumItems = 128
        var workSlice: Duration = .milliseconds(8)
        /// Runs between bounded slices. The user removed the CPU duty-cycle cap
        /// on 2026-10-24: the default only yields the utility thread and
        /// observes cancellation; it never sleeps. Tests inject gates here.
        var yieldSlice: @Sendable () async throws -> Void = {
            await Task.yield()
            try Task.checkCancellation()
        }
    }

    /// One worker's bounded slice: at most `maximumItems` items or `workSlice`
    /// of wall time between publication, interleaving and cancellation points.
    /// There is no CPU duty cycle.
    struct WorkSlice {
        let budget: Budget
        private let clock = ContinuousClock()
        private var start: ContinuousClock.Instant
        private(set) var items = 0

        init(_ budget: Budget) {
            self.budget = budget
            start = clock.now
        }

        var exhausted: Bool { items >= budget.maximumItems || start.duration(to: clock.now) >= budget.workSlice }
        mutating func inspected() { items += 1 }

        /// Throws when canceled, like the injected yield.
        mutating func yield() async throws {
            try await budget.yieldSlice()
            restart()
        }

        mutating func restart() {
            items = 0
            start = clock.now
        }
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

    /// Validate a whole delivery away from the main actor, with the same
    /// bounded utility slices as metadata work. Empty records still remove
    /// indexed paths; outside-policy records cannot be published.
    struct VisibilityResult: Sendable {
        var records: Batch
        var metadataRechecks: [URL]
    }

    static func visibleRecords(_ batch: Batch, policy: TagDiscoveryPolicy, budget: Budget = Budget()) async -> Batch {
        await visibilityResult(batch, policy: policy, budget: budget).records
    }

    static func visibilityResult(_ batch: Batch, policy: TagDiscoveryPolicy, budget: Budget = Budget()) async -> VisibilityResult {
        // Most traversal checkpoints carry no tagged records. Avoid a worker
        // and two executor hops per empty interleaving checkpoint.
        guard !batch.isEmpty else { return VisibilityResult(records: [:], metadataRechecks: []) }
        let worker = Task.detached(priority: .utility) {
            var visibility = TagVisibilityBatch(policy: policy)
            var result: Batch = [:]
            var slice = WorkSlice(budget)
            for (path, colors) in batch {
                guard !Task.isCancelled else { break }
                autoreleasepool {
                    let normalized = visibility.normalizedPath(path)
                    guard visibility.contains(normalizedPath: normalized) else { return }
                    result[path] = colors.isEmpty || visibility.isVisible(normalizedPath: normalized, recordPath: path) ? colors : [:]
                }
                slice.inspected()
                if slice.exhausted {
                    do { try await slice.yield() } catch { break }
                }
            }
            if slice.items > 0, !Task.isCancelled {
                try? await slice.yield()
            }
            return Task.isCancelled ? VisibilityResult(records: [:], metadataRechecks: [])
                : VisibilityResult(records: result, metadataRechecks: visibility.metadataRechecks.map { URL(fileURLWithPath: $0) })
        }
        return await withTaskCancellationHandler { await worker.value } onCancel: { worker.cancel() }
    }

    static func read(_ urls: [URL], budget: Budget = Budget()) async -> Batch {
        await readResult(urls, budget: budget).records
    }

    static func readResult(_ urls: [URL], budget: Budget = Budget()) async -> ReadResult {
        let worker = Task.detached(priority: .utility) {
            let exclusion = TemporaryExclusion()
            var slice = WorkSlice(budget)
            var records: Batch = [:]
            var complete = true
            var deferred = TagScanRoots()
            let boundaries = [FileManager.default.temporaryDirectory] + TagDiscoveryPolicy.standardRoots
            var visibility = TagVisibilityBatch(policy: TagDiscoveryPolicy(roots: boundaries))
            for url in urls {
                guard !Task.isCancelled else { break }
                autoreleasepool {
                    let url = url.standardizedFileURL
                    // Canonicalize only for exclusion. Keep the enumerated
                    // item's identity so a later empty read removes that path.
                    let canonicalPath = url.resolvingSymlinksInPath().path
                    guard !exclusion.contains(path: canonicalPath) else { return }
                    // Preserve the conservative ancestor check for unusual
                    // explicitly supplied paths outside the standard boundaries.
                    let visible = visibility.contains(normalizedPath: url.path)
                        ? visibility.isVisible(normalizedPath: url.path) : TagDiscoveryPolicy.isVisible(url)
                    guard visible else { records[url.path] = [:]; return }
                    let metadata = url.withUnsafeFileSystemRepresentation { FinderTagMetadata.readColorIndexes(atPath: $0!) }
                    if metadata.complete { records[url.path] = metadata.colors }
                    else { complete = false; deferred.deferRetry(url) }
                }
                slice.inspected()
                if slice.exhausted {
                    do { try await slice.yield() } catch { break }
                }
            }
            if slice.items > 0, !Task.isCancelled {
                try? await slice.yield()
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
        var slice = WorkSlice(budget)
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
            guard force || slice.exhausted else { return true }
            // Empty checkpoints allow incremental reads to interleave even
            // while traversing a large subtree containing no tags.
            await onBatch(batch)
            batch.removeAll(keepingCapacity: true)
            guard !Task.isCancelled else { return false }
            if slice.items > 0 {
                // Yield the utility thread between slices; no CPU cap applies.
                do { try await slice.yield() } catch { return false }
            } else { slice.restart() }
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
                slice.inspected()
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
                            // Bulk Finder info rules out most packages without a
                            // second per-directory attribute request.
                            descend = !entry.mayBePackage || (try? URL(fileURLWithPath: path, isDirectory: true)
                                .resourceValues(forKeys: [.isPackageKey]).isPackage) != true
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
                    slice.inspected()
                    totalInspected += 1
                    // Avoid entering an async function for every untagged item.
                    // The suspension/publication remains bounded by both limits.
                    if slice.exhausted {
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
        var mayBePackage = true
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
                return Entry(rawPath: path, descend: entry.isDirectory, hidden: entry.isHidden, mayHaveXattrs: entry.mayHaveXattrs,
                             hasError: entry.hasError, mayBePackage: entry.mayBePackage)
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
