import Foundation

nonisolated enum AutomationError: String, Error, LocalizedError, Sendable {
    case invalidArguments, authorizationRequired, destinationExists, busy, notFound, listingTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidArguments: AppLocalization.string("Invalid automation parameters. Use absolute paths and valid options.")
        case .authorizationRequired: AppLocalization.string("Allow this folder in Zforge Settings > Automation before running this action.")
        case .destinationExists: AppLocalization.string("The destination already exists. Choose a new name; automation never replaces existing items.")
        case .busy: AppLocalization.string("Another automation operation is running. Wait for it to finish or cancel it.")
        case .notFound: AppLocalization.string("The requested item or operation is no longer available.")
        case .listingTooLarge: AppLocalization.string("This listing exceeds the automation limit of 10,000 items. Choose a smaller folder.")
        }
    }
}

/// Each request holds its scopes until its actual work completes, including cancellation cleanup.
nonisolated final class AutomationAccessLease: @unchecked Sendable {
    private let roots: [URL]
    init(roots: [URL] = []) { self.roots = roots }
    deinit { roots.forEach { $0.stopAccessingSecurityScopedResource() } }
}

nonisolated protocol AutomationAuthorizing: Sendable {
    func authorize(_ urls: [URL]) async throws -> AutomationAccessLease
    func authorize(_ targets: [AutomationAccessTarget]) async throws -> AutomationAccessLease
    func authorizedFolders() async -> [String]
}

extension AutomationAuthorizing {
    func authorizedFolders() async -> [String] { [] }
    func authorize(_ targets: [AutomationAccessTarget]) async throws -> AutomationAccessLease {
        try await authorize(targets.map(\.url))
    }
}

nonisolated struct AutomationAccessTarget: Sendable {
    enum Kind: Sendable { case directory, existingItem, newItem }
    let url: URL
    let kind: Kind
}

nonisolated struct AutomationFolder: Identifiable, Sendable {
    let id: String
    let url: URL
}

actor AutomationGrantStore: AutomationAuthorizing {
    static let shared = AutomationGrantStore()
    private let defaults: UserDefaults
    private let key = "automationSecurityScopedFolders"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func authorizedFolders() async -> [String] { bookmarks().keys.sorted() }

    func folders() -> [AutomationFolder] {
        bookmarks().keys.sorted().map { AutomationFolder(id: $0, url: URL(fileURLWithPath: $0)) }
    }

    func add(_ url: URL) throws {
        let root = url.standardizedFileURL
        let selectedPath = AutomationPath.resolvedForAccess(root).path
        guard try URL(fileURLWithPath: selectedPath).resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            throw AutomationError.invalidArguments
        }
        let original = bookmarks()
        var values = original
        // Resolve only usable scopes. Unknown/unavailable bookmarks are retained.
        let physicalRoots = original.compactMapValues { Self.activePhysicalPath(for: $0) }
        let ancestor = physicalRoots.filter { Self.contains(root: $0.value, path: selectedPath) }
            .sorted { $0.value.count == $1.value.count ? $0.key < $1.key : $0.value.count < $1.value.count }
            .first
        let retainedID: String
        let physicalRoot: String
        let bookmark: Data
        if let ancestor, let existing = original[ancestor.key] {
            // Reuse the broadest usable ancestor and clean legacy redundant entries too.
            retainedID = ancestor.key
            physicalRoot = ancestor.value
            bookmark = existing
        } else {
            // Directory aliases grant their selected physical target. Foundation
            // cannot reliably create a scoped bookmark for the symlink itself.
            let isSymbolicLink = try root.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true
            let bookmarkURL = isSymbolicLink ? root.resolvingSymlinksInPath() : root
            bookmark = try bookmarkURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            guard let validatedPath = Self.activePhysicalPath(for: bookmark), validatedPath == selectedPath else {
                throw AutomationError.authorizationRequired
            }
            retainedID = root.path
            physicalRoot = validatedPath
        }
        // Validate the covering bookmark before removing anything. Running leases
        // own their scopes independently of the persisted list.
        for (id, path) in physicalRoots where id != retainedID && Self.contains(root: physicalRoot, path: path) {
            values.removeValue(forKey: id)
        }
        guard values.count < 128 || values[retainedID] != nil else { throw AutomationError.invalidArguments }
        values[retainedID] = bookmark
        if values != original { defaults.set(values, forKey: key) }
    }

    private static func activePhysicalPath(for bookmark: Data) -> String? {
        var stale = false
        guard let root = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope],
                                  relativeTo: nil, bookmarkDataIsStale: &stale),
              root.startAccessingSecurityScopedResource() else { return nil }
        defer { root.stopAccessingSecurityScopedResource() }
        return AutomationPath.resolvedForAccess(root).path
    }

    func remove(_ id: String) {
        var values = bookmarks()
        values.removeValue(forKey: id)
        defaults.set(values, forKey: key)
    }

    func authorize(_ urls: [URL]) throws -> AutomationAccessLease {
        let stored = bookmarks()
        var active: [URL] = []
        do {
            for url in urls {
                // Prefer lexical matches, but also accept canonical aliases such as /tmp and /private/tmp.
                // Every candidate still requires an active bookmark and a physical boundary check.
                let candidates = stored.keys.sorted {
                    let left = Self.contains(root: $0, path: url.standardizedFileURL.path)
                    let right = Self.contains(root: $1, path: url.standardizedFileURL.path)
                    return left == right ? $0.count > $1.count : left
                }
                var permitted = false
                for key in candidates {
                    guard let data = stored[key] else { continue }
                    var stale = false
                    guard let root = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope],
                                              relativeTo: nil, bookmarkDataIsStale: &stale),
                          root.startAccessingSecurityScopedResource() else { continue }
                    let physicalRoot = AutomationPath.resolvedForAccess(root).path
                    let physicalPath = AutomationPath.resolvedForAccess(url).path
                    guard Self.contains(root: physicalRoot, path: physicalPath) else {
                        root.stopAccessingSecurityScopedResource()
                        continue
                    }
                    active.append(root)
                    permitted = true
                    break
                }
                guard permitted else { throw AutomationError.authorizationRequired }
            }
            return AutomationAccessLease(roots: active)
        } catch {
            active.forEach { $0.stopAccessingSecurityScopedResource() }
            throw error
        }
    }

    private func bookmarks() -> [String: Data] { defaults.dictionary(forKey: key) as? [String: Data] ?? [:] }

    nonisolated static func contains(root: String, path: String) -> Bool {
        path.utf8.elementsEqual(root.utf8) || path.utf8.starts(with: (root.hasSuffix("/") ? root : root + "/").utf8)
    }
}

nonisolated enum AutomationPath {
    static func url(_ path: String) throws -> URL {
        guard path.hasPrefix("/"), path.utf8.count <= 4096, !path.contains("\0") else {
            throw AutomationError.invalidArguments
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    /// Foundation does not resolve parent symlinks when the final component does not exist.
    /// Resolve the nearest existing ancestor first, then append the not-yet-created components.
    /// This is an authorization comparison only. Operations and bookmark leases retain their
    /// original URLs, including the kernel's no-follow protection on URLs delivered by Shortcuts.
    static func resolvedForAccess(_ url: URL) -> URL {
        var ancestor = url.standardizedFileURL
        if ancestor.path.hasPrefix("/.nofollow/") {
            ancestor = URL(fileURLWithPath: String(ancestor.path.dropFirst("/.nofollow".count)),
                           isDirectory: ancestor.hasDirectoryPath)
        }
        var missing: [String] = []
        while !FileManager.default.fileExists(atPath: ancestor.path), ancestor.path != "/" {
            missing.append(ancestor.lastPathComponent)
            ancestor.deleteLastPathComponent()
        }
        var resolved = ancestor.resolvingSymlinksInPath().standardizedFileURL
        for component in missing.reversed() { resolved.appendPathComponent(component) }
        return resolved
    }

    static func newChild(in folder: URL, name: String) throws -> URL {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0"),
              name.utf8.count <= 255 else { throw AutomationError.invalidArguments }
        return folder.appendingPathComponent(name)
    }
}
