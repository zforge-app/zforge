import Foundation
import CoreServices

@MainActor
protocol RecentItemsServing: AnyObject {
    func recentItemURLs() async -> [URL]
    func stop()
}

/// Preserves Spotlight order while accepting each physical file only once.
/// The query itself stays in the adapter below; this rule can be exercised
/// with ordinary temporary files, including symlinks and hard links.
nonisolated struct RecentFileIdentityFilter {
    private(set) var urls: [URL] = []
    private var seenPaths: Set<String> = []
    private var seenFileIdentities: Set<String> = []
    let maximumCount: Int

    var isFull: Bool { urls.count >= maximumCount }

    init(maximumCount: Int) {
        self.maximumCount = max(0, maximumCount)
    }

    mutating func appendIfNew(_ url: URL) {
        guard !isFull else { return }
        guard !ZforgeTemporaryStorage.contains(url) else { return }
        let standardizedPath = url.resolvingSymlinksInPath().standardizedFileURL.path
        guard seenPaths.insert(standardizedPath).inserted else { return }
        if let values = try? url.resourceValues(forKeys: [
            .fileResourceIdentifierKey, .volumeIdentifierKey
        ]), let fileID = values.fileResourceIdentifier,
           let volumeID = values.volumeIdentifier {
            let identity = "\(volumeID):\(fileID)"
            guard seenFileIdentities.insert(identity).inserted else { return }
        }
        urls.append(url)
    }
}

@MainActor
final class SpotlightRecentItemsService: NSObject, RecentItemsServing {
    private static let maximumResultCount = 250

    private var query: NSMetadataQuery?
    private var continuation: CheckedContinuation<[URL], Never>?

    func recentItemURLs() async -> [URL] {
        stop()

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        guard let predicate = NSPredicate(
            fromMetadataQueryString: "kMDItemLastUsedDate >= $time.today(-30)"
        ) else { return [] }
        query.predicate = predicate
        query.sortDescriptors = [
            NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)
        ]
        self.query = query

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(queryDidFinishGathering(_:)),
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: query
            )
            if !query.start() {
                finish(with: [])
            }
        }
    }

    func stop() {
        finish(with: [])
    }

    @objc private func queryDidFinishGathering(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery, query === self.query else { return }
        query.disableUpdates()

        var results = RecentFileIdentityFilter(maximumCount: Self.maximumResultCount)
        for index in 0..<query.resultCount {
            let result = query.result(at: index) as AnyObject
            guard let path = result.value(forKey: NSMetadataItemPathKey) as? String else { continue }
            results.appendIfNew(URL(fileURLWithPath: path))
            if results.isFull { break }
        }

        finish(with: results.urls)
    }

    private func finish(with urls: [URL]) {
        guard query != nil || continuation != nil else { return }
        if let query {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: query
            )
            query.stop()
        }
        query = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(returning: urls)
    }
}

@MainActor
protocol TaggedItemsServing: AnyObject {
    func itemURLs(tagged tag: String) async -> [URL]
    func stop()
}

@MainActor
final class SpotlightTaggedItemsService: NSObject, TaggedItemsServing {
    private let catalog: FinderTagCatalog
    private var activeTag: String?
    private var generation: UInt64 = 0
    private var query: MDQuery?
    private var notificationToken: NSObjectProtocol?
    private var continuation: CheckedContinuation<[URL], Never>?

    init(catalog: FinderTagCatalog? = nil) {
        self.catalog = catalog ?? FinderTagCatalog.shared
        super.init()
    }

    func itemURLs(tagged tag: String) async -> [URL] {
        stop()
        activeTag = tag
        let generation = generation
        let escapedTag = tag
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        guard let query = MDQueryCreate(
            kCFAllocatorDefault,
            "kMDItemUserTags == \"\(escapedTag)\"" as CFString,
            nil,
            nil
        ) else { return catalog.itemURLs(tagged: tag) }
        self.query = query
        MDQuerySetDispatchQueue(query, .main)
        MDQuerySetSearchScope(query, catalog.discoveryPolicy.roots.map(\.path) as CFArray, 0)
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            notificationToken = NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: kMDQueryDidFinishNotification as String),
                object: query,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard self?.generation == generation else { return }
                    self?.queryDidFinishGathering()
                }
            }
            if !MDQueryExecute(query, CFOptionFlags(kMDQueryWantsUpdates.rawValue)) {
                finish(with: catalog.itemURLs(tagged: tag))
            }
        }
    }

    func stop() { generation &+= 1; finish(with: []) }

    private func queryDidFinishGathering() {
        guard let query else { return }
        MDQueryDisableUpdates(query)
        var results = RecentFileIdentityFilter(maximumCount: .max)
        for index in 0..<MDQueryGetResultCount(query) {
            guard let pointer = MDQueryGetResultAtIndex(query, index) else { continue }
            let item = unsafeBitCast(pointer, to: MDItem.self)
            guard let path = MDItemCopyAttribute(item, "kMDItemPath" as CFString) as? String else {
                continue
            }
            let url = URL(fileURLWithPath: path)
            guard catalog.discoveryPolicy.contains(url), catalog.discoveryPolicy.isVisible(url) else { continue }
            results.appendIfNew(url)
        }
        for url in catalog.itemURLs(tagged: activeTag ?? "") {
            results.appendIfNew(url)
        }
        finish(with: results.urls)
    }

    private func finish(with urls: [URL]) {
        guard query != nil || continuation != nil else { return }
        if let query {
            if let notificationToken { NotificationCenter.default.removeObserver(notificationToken) }
            notificationToken = nil
            MDQueryStop(query)
        }
        query = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(returning: urls)
    }
}
