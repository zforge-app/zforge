import Foundation

nonisolated protocol AccessGrantStoring: Sendable {
    func hasGrant(for url: URL) async -> Bool
    func storeGrant(for url: URL) async throws
    func activateGrant(for url: URL) async throws -> URL
    func removeGrant(for url: URL) async
    func stopAll() async
}

actor AccessGrantStore: AccessGrantStoring {
    private let defaults: UserDefaults
    private let storageKey = "securityScopedBookmarks"
    private var activeRoots: [URL: Int] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasGrant(for url: URL) -> Bool {
        bestGrantKey(for: url, in: bookmarks()) != nil
    }

    func storeGrant(for url: URL) throws {
        let standardized = url.standardizedFileURL
        let data = try standardized.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        var stored = bookmarks()
        stored[standardized.path] = data
        defaults.set(stored, forKey: storageKey)
    }

    func activateGrant(for url: URL) throws -> URL {
        let stored = bookmarks()
        guard let key = bestGrantKey(for: url, in: stored), let data = stored[key] else {
            throw BrowserError.permissionDenied(url)
        }

        var stale = false
        let root = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        guard root.startAccessingSecurityScopedResource() else {
            throw BrowserError.permissionDenied(url)
        }
        activeRoots[root, default: 0] += 1
        if stale {
            try storeGrant(for: root)
        }
        return url.standardizedFileURL
    }

    func removeGrant(for url: URL) {
        var stored = bookmarks()
        stored.removeValue(forKey: url.standardizedFileURL.path)
        defaults.set(stored, forKey: storageKey)
    }

    func stopAll() {
        for root in activeRoots.keys {
            root.stopAccessingSecurityScopedResource()
        }
        activeRoots.removeAll()
    }

    private func bookmarks() -> [String: Data] {
        defaults.dictionary(forKey: storageKey) as? [String: Data] ?? [:]
    }

    private func bestGrantKey(for url: URL, in bookmarks: [String: Data]) -> String? {
        let path = url.standardizedFileURL.path
        return bookmarks.keys
            .filter { path == $0 || path.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }
            .max(by: { $0.count < $1.count })
    }
}
