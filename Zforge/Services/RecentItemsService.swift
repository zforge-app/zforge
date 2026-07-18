import Foundation

@MainActor
protocol RecentItemsServing: AnyObject {
    func recentItemURLs() async -> [URL]
    func stop()
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

        var seenPaths: Set<String> = []
        var urls: [URL] = []
        let count = min(query.resultCount, Self.maximumResultCount)
        urls.reserveCapacity(count)
        for index in 0..<count {
            let result = query.result(at: index) as AnyObject
            guard let path = result.value(forKey: NSMetadataItemPathKey) as? String else { continue }
            let url = URL(fileURLWithPath: path)
            let standardizedPath = url.standardizedFileURL.path
            guard seenPaths.insert(standardizedPath).inserted else { continue }
            urls.append(url)
        }

        finish(with: urls)
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
