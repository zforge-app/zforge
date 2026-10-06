import Foundation

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

    mutating func take() -> [URL] {
        let result = urls
        urls.removeAll(keepingCapacity: true)
        return result
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
        var maximumItems = 128
        var workSlice: Duration = .milliseconds(8)
        var pause: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    }

    static func read(_ urls: [URL], budget: Budget = Budget()) async -> Batch {
        let worker = Task.detached(priority: .utility) {
            let exclusion = TemporaryExclusion()
            let clock = ContinuousClock()
            var start = clock.now
            var inspected = 0
            var records: Batch = [:]
            for url in urls {
                guard !Task.isCancelled else { break }
                autoreleasepool {
                    let url = url.standardizedFileURL
                    // Canonicalize only for exclusion. Keep the enumerated
                    // item's identity so a later empty read removes that path.
                    let canonicalPath = url.resolvingSymlinksInPath().path
                    guard !exclusion.contains(path: canonicalPath) else { return }
                    records[url.path] = FinderTagMetadata.colorIndexes(at: url)
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
            return records
        }
        return await withTaskCancellationHandler {
            await worker.value
        } onCancel: { worker.cancel() }
    }

    static func scan(_ roots: [URL], budget: Budget = Budget(), onBatch: @escaping Publish) async {
        let worker = Task.detached(priority: .utility) {
            await discover(roots, budget: budget, onBatch: onBatch)
        }
        await withTaskCancellationHandler {
            await worker.value
        } onCancel: { worker.cancel() }
    }

    private static func discover(_ roots: [URL], budget: Budget, onBatch: @escaping Publish) async {
        let exclusion = TemporaryExclusion()
        let clock = ContinuousClock()
        var sliceStart = clock.now
        var inspected = 0
        var batch: Batch = [:]
        var uniqueRoots = TagScanRoots()
        for root in roots { uniqueRoots.insert(root.resolvingSymlinksInPath()) }
        var visitedRoots: Set<String> = []

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
            let priorityRoots = root == UserDirectoryService.homeURL ? [
                root.appendingPathComponent("Downloads"), root.appendingPathComponent("Documents"),
                root.appendingPathComponent("Desktop"), root.appendingPathComponent("Library/Mobile Documents"),
                root.appendingPathComponent("Library/CloudStorage"), root
            ] : [root]
            for candidate in priorityRoots {
                let directory = candidate.resolvingSymlinksInPath().standardizedFileURL
                guard !Task.isCancelled else { return }
                guard visitedRoots.insert(directory.path).inserted,
                      !exclusion.contains(path: directory.path) else { continue }
                autoreleasepool {
                    let colors = FinderTagMetadata.colorIndexes(at: directory)
                    if !colors.isEmpty { batch[directory.path] = colors }
                }
                inspected += 1
                guard await checkpoint() else { return }
                guard let enumerator = FileManager.default.enumerator(
                    at: directory, includingPropertiesForKeys: nil,
                    options: [.skipsPackageDescendants], errorHandler: { _, _ in true }
                ) else { continue }
                while !Task.isCancelled {
                    let hasNext: Bool = autoreleasepool {
                        guard let url = enumerator.nextObject() as? URL else { return false }
                        let path = url.path
                        if visitedRoots.contains(path) || exclusion.contains(path: path) {
                            enumerator.skipDescendants()
                            return true
                        }
                        let colors = FinderTagMetadata.colorIndexes(at: url)
                        if !colors.isEmpty {
                            // Enumerators do not traverse directory symlinks.
                            // Only tagged candidates need canonicalization to
                            // reject temporary aliases; untagged files need no
                            // additional resource lookup or symlink resolution.
                            let canonicalPath = url.resolvingSymlinksInPath().standardizedFileURL.path
                            if !exclusion.contains(path: canonicalPath) { batch[path] = colors }
                        }
                        return true
                    }
                    guard hasNext else { break }
                    inspected += 1
                    guard await checkpoint() else { return }
                }
                guard await checkpoint(force: true) else { return }
            }
        }
    }

    private struct TemporaryExclusion {
        let root = ZforgeTemporaryStorage.root().resolvingSymlinksInPath().standardizedFileURL.path
        func contains(path: String) -> Bool { TagScanRoots.covers(root, path) }
    }
}
