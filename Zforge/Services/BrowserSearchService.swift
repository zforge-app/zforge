import Foundation

/// Where the toolbar search looks, as in Finder's “Search: This Mac | “Folder”” bar.
nonisolated enum BrowserSearchScope: String, CaseIterable, Hashable, Sendable {
    /// Spotlight over the locations Zforge may read (the App Sandbox limits it
    /// to authorized folders, normally Home).
    case thisMac
    /// A recursive name search of the folder or archive folder where the search began.
    case currentFolder
}

/// A search shown in the browser's virtual results location.
nonisolated struct BrowserFileSearch: Hashable, Sendable {
    let query: String
    let scope: BrowserSearchScope
    /// The path of the folder or archive folder where the search began.
    let origin: [BrowserPathComponent]

    var originLocation: BrowserLocation? { origin.last?.location }

    /// Whether the current-folder scope can search `location`; virtual
    /// locations such as Recents, tags and Computer only offer This Mac.
    static func supportsCurrentFolder(_ location: BrowserLocation?) -> Bool {
        switch location {
        case .fileSystem, .archive: true
        case .recents, .computer, .network, .networkServer, nil: false
        }
    }

    /// Trims the typed text; blank or NUL-containing text is not a query.
    static func normalizedQuery(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("\0") else { return nil }
        return trimmed
    }

    /// Finder's name matching: case-, diacritic- and width-insensitive containment.
    static func name(_ name: String, matches query: String) -> Bool {
        name.localizedStandardContains(query)
    }
}

nonisolated enum BrowserSearchTarget: Hashable, Sendable {
    case thisMac(scopes: [URL])
    case folder(URL)
    case archive(ArchiveAddress)
}

nonisolated struct BrowserSearchRequest: Hashable, Sendable {
    let query: String
    let target: BrowserSearchTarget
    let showsHiddenFiles: Bool
}

/// A match is a local file, which the browser reads like a Recents entry, or an
/// archive item that is already a complete browser item.
nonisolated enum BrowserSearchMatch: Hashable, Sendable {
    case file(URL)
    case item(BrowserItem)
}

/// Streams matches in batches. Ending iteration or cancelling the consuming task
/// stops the underlying query or traversal.
@MainActor
protocol BrowserSearching: AnyObject {
    func results(for request: BrowserSearchRequest) -> AsyncThrowingStream<[BrowserSearchMatch], Error>
}

@MainActor
final class BrowserSearchService: BrowserSearching {
    /// Results beyond this count are not listed; the scope bar says so.
    nonisolated static let maximumResultCount = 1_000
    /// A batch is published once it holds this many matches or has waited this long.
    nonisolated static let batchSize = 64
    nonisolated static let batchInterval: Duration = .milliseconds(100)

    private let archives: any ArchiveServing

    init(archives: any ArchiveServing) {
        self.archives = archives
    }

    func results(for request: BrowserSearchRequest) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        switch request.target {
        case let .thisMac(scopes):
            SpotlightNameSearch.results(query: request.query, scopes: scopes, limit: Self.maximumResultCount)
        case let .folder(url):
            FolderNameSearch.results(query: request.query, root: url, showsHiddenFiles: request.showsHiddenFiles,
                                     limit: Self.maximumResultCount)
        case let .archive(address):
            ArchiveNameSearch.results(query: request.query, root: address, archives: archives,
                                      limit: Self.maximumResultCount)
        }
    }
}

/// Collects matches and publishes them in bounded batches.
nonisolated private struct SearchBatcher {
    private var pending: [BrowserSearchMatch] = []
    private var lastFlush = ContinuousClock.now
    private(set) var count = 0
    let limit: Int

    var isFull: Bool { count >= limit }

    mutating func append(_ match: BrowserSearchMatch,
                         to continuation: AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation) {
        guard !isFull else { return }
        pending.append(match)
        count += 1
        flushIfDue(to: continuation)
    }

    mutating func flushIfDue(to continuation: AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation) {
        guard !pending.isEmpty, pending.count >= BrowserSearchService.batchSize || isFull
            || lastFlush.duration(to: .now) >= BrowserSearchService.batchInterval else { return }
        flush(to: continuation)
    }

    mutating func flush(to continuation: AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation) {
        lastFlush = .now
        guard !pending.isEmpty else { return }
        continuation.yield(pending)
        pending.removeAll(keepingCapacity: true)
    }
}

/// Recursive name search of a local folder, off the main actor. Packages are
/// not entered, as in Finder; unreadable subfolders are skipped.
nonisolated enum FolderNameSearch {
    static func results(query: String, root: URL, showsHiddenFiles: Bool,
                        limit: Int) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
                if !showsHiddenFiles { options.insert(.skipsHiddenFiles) }
                guard let enumerator = FileManager.default.enumerator(
                    at: root, includingPropertiesForKeys: [], options: options, errorHandler: { _, _ in true }
                ) else {
                    continuation.finish()
                    return
                }
                var batcher = SearchBatcher(limit: limit)
                while let url = enumerator.nextObject() as? URL {
                    if Task.isCancelled { break }
                    if BrowserFileSearch.name(url.lastPathComponent, matches: query),
                       !ZforgeTemporaryStorage.contains(url) {
                        batcher.append(.file(url), to: continuation)
                        if batcher.isFull { break }
                    } else {
                        batcher.flushIfDue(to: continuation)
                    }
                }
                batcher.flush(to: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Breadth-first name search of an open archive's listing below `root`.
/// Nested archives are listed when they match but are not opened.
nonisolated enum ArchiveNameSearch {
    static func results(query: String, root: ArchiveAddress, archives: any ArchiveServing,
                        limit: Int) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var batcher = SearchBatcher(limit: limit)
                var pending = [root]
                do {
                    while !pending.isEmpty, !batcher.isFull {
                        try Task.checkCancellation()
                        let address = pending.removeFirst()
                        for item in try await archives.items(at: address) {
                            if BrowserFileSearch.name(item.name, matches: query) {
                                batcher.append(.item(item), to: continuation)
                                if batcher.isFull { break }
                            }
                            if item.isDirectory, case let .archive(child) = item.location { pending.append(child) }
                        }
                        batcher.flushIfDue(to: continuation)
                    }
                    batcher.flush(to: continuation)
                    continuation.finish()
                } catch {
                    batcher.flush(to: continuation)
                    continuation.finish(throwing: error is CancellationError ? nil : error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Spotlight file-name search through `NSMetadataQuery`. Under the App Sandbox
/// the query is scoped to the folders Zforge holds grants for, so every result
/// can be read and opened; locations outside those grants are not searched.
@MainActor
enum SpotlightNameSearch {
    static func predicate(for query: String) -> NSPredicate {
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "*", with: "\\*")
            .replacingOccurrences(of: "?", with: "\\?")
        return NSPredicate(format: "%K LIKE[cd] %@", NSMetadataItemFSNameKey, "*\(escaped)*")
    }

    static func results(query: String, scopes: [URL],
                        limit: Int) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        AsyncThrowingStream { continuation in
            guard !scopes.isEmpty else {
                continuation.finish()
                return
            }
            let run = SpotlightNameSearchRun(limit: limit, continuation: continuation)
            continuation.onTermination = { _ in Task { @MainActor in run.stop() } }
            run.start(predicate: predicate(for: query), scopes: scopes)
        }
    }
}

@MainActor
private final class SpotlightNameSearchRun {
    private let query = NSMetadataQuery()
    private let limit: Int
    private let continuation: AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation
    private var observers: [NSObjectProtocol] = []
    private var delivered = 0
    private var stopped = false

    init(limit: Int, continuation: AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation) {
        self.limit = limit
        self.continuation = continuation
    }

    func start(predicate: NSPredicate, scopes: [URL]) {
        query.predicate = predicate
        query.searchScopes = scopes
        query.notificationBatchingInterval = 0.1
        let center = NotificationCenter.default
        for name in [Notification.Name.NSMetadataQueryGatheringProgress, .NSMetadataQueryDidFinishGathering] {
            observers.append(center.addObserver(forName: name, object: query, queue: .main) { [weak self] notification in
                let finished = notification.name == .NSMetadataQueryDidFinishGathering
                MainActor.assumeIsolated { self?.deliver(finished: finished) }
            })
        }
        if !query.start() {
            stop()
            continuation.finish()
        }
    }

    private func deliver(finished: Bool) {
        guard !stopped else { return }
        query.disableUpdates()
        var matches: [BrowserSearchMatch] = []
        var seenPaths: Set<String> = []
        let available = min(query.resultCount, limit)
        while delivered < available {
            if let item = query.result(at: delivered) as? NSMetadataItem,
               let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
               seenPaths.insert(path).inserted {
                let url = URL(fileURLWithPath: path)
                if !ZforgeTemporaryStorage.contains(url) { matches.append(.file(url)) }
            }
            delivered += 1
        }
        query.enableUpdates()
        if !matches.isEmpty { continuation.yield(matches) }
        if finished || delivered >= limit {
            stop()
            continuation.finish()
        }
    }

    func stop() {
        guard !stopped else { return }
        stopped = true
        query.stop()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }
}

/// Matches the UI fixture's Recents names, so UI tests search without Spotlight.
@MainActor
final class UIFixtureSearchService: BrowserSearching {
    func results(for request: BrowserSearchRequest) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        let matches = ["Fixture Folder", "Welcome.txt", "Sample.zip", "Another.txt"]
            .filter { BrowserFileSearch.name($0, matches: request.query) }
            .map { BrowserSearchMatch.file(URL(fileURLWithPath: "/ZforgeFixtures/\($0)")) }
        return AsyncThrowingStream { continuation in
            if !matches.isEmpty { continuation.yield(matches) }
            continuation.finish()
        }
    }
}
