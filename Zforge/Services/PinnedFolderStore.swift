import Foundation
import Observation

/// The ordered favorites are shared by windows; navigation and selection remain per window.
@MainActor
@Observable
final class PinnedFolderStore {
    static let shared = PinnedFolderStore(defaults: ZforgeDefaults.application)
    private struct Entry: Codable {
        var path: String
        var bookmark: Data?
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "sidebarPinnedFolders.v1"
    private var entries: [Entry]

    static var defaultURLs: [URL] {
        [UserDirectoryService.desktopURL, UserDirectoryService.documentsURL,
         UserDirectoryService.downloadsURL, URL(fileURLWithPath: "/Applications")]
    }

    init(defaults: UserDefaults = ZforgeDefaults.application, initialURLs: [URL]? = nil) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = saved
        } else {
            entries = (initialURLs ?? Self.defaultURLs).map { Entry(path: $0.standardizedFileURL.resolvingSymlinksInPath().path) }
        }
        // Resolve identity bookmarks once, preserving unavailable destinations for later use/removal.
        var seen = Set<String>()
        entries = entries.compactMap { entry in
            var entry = entry
            entry.path = URL(fileURLWithPath: entry.path).resolvingSymlinksInPath().path
            if let bookmark = entry.bookmark {
                var stale = false
                if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI],
                                      relativeTo: nil, bookmarkDataIsStale: &stale) {
                    entry.path = url.standardizedFileURL.path
                    if stale {
                        let started = url.startAccessingSecurityScopedResource()
                        defer { if started { url.stopAccessingSecurityScopedResource() } }
                        entry.bookmark = (try? Self.bookmark(for: url)) ?? bookmark
                    }
                }
            }
            return seen.insert(entry.path).inserted ? entry : nil
        }
        persist()
    }

    var urls: [URL] { entries.map { URL(fileURLWithPath: $0.path) } }

    func contains(_ url: URL) -> Bool {
        entries.contains { $0.path == url.standardizedFileURL.resolvingSymlinksInPath().path }
    }

    /// Validate the entire batch before changing favorites. Pinning never changes filesystem contents.
    func pin(_ urls: [URL], before anchor: URL? = nil) throws {
        var additions: [Entry] = []
        var seen = Set(entries.map(\.path))
        for source in urls {
            let url = source.standardizedFileURL.resolvingSymlinksInPath()
            guard url.isFileURL else { throw invalidFolder() }
            let started = source.startAccessingSecurityScopedResource()
            defer { if started { source.stopAccessingSecurityScopedResource() } }
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            guard values.isDirectory == true, values.isPackage != true else { throw invalidFolder() }
            if seen.insert(url.path).inserted {
                additions.append(Entry(path: url.path, bookmark: try Self.bookmark(for: url)))
            }
        }
        let index = anchor.flatMap { url in entries.firstIndex { $0.path == url.standardizedFileURL.path } }
            ?? entries.endIndex
        entries.insert(contentsOf: additions, at: index)
        persist()
    }

    /// Resolve the bookmark so a new window can recover access granted by a previous drop/picker.
    func bookmarkedURL(for url: URL) -> URL? {
        guard let data = entries.first(where: { $0.path == url.standardizedFileURL.path })?.bookmark else { return nil }
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                        relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    func remove(_ url: URL) {
        entries.removeAll { $0.path == url.standardizedFileURL.path }
        persist()
    }

    private static func bookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private func invalidFolder() -> BrowserError {
        .unavailable(AppLocalization.string("Only folders can be added to Favorites."))
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: storageKey) }
    }
}
