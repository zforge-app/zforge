import Foundation

/// An action chosen in Finder's Zforge submenu, handed from the Finder extension to the app.
nonisolated struct FinderMenuRequest: Codable, Equatable, Hashable, Sendable {
    static let maximumItems = 256

    let id: UUID
    let action: BrowserSelectionAction
    let paths: [String]
    let createdAt: Date

    init(id: UUID = UUID(), action: BrowserSelectionAction, urls: [URL], createdAt: Date = Date()) {
        self.id = id
        self.action = action
        paths = urls.map { $0.standardizedFileURL.path }
        self.createdAt = createdAt
    }

    var urls: [URL] { paths.map { URL(fileURLWithPath: $0).standardizedFileURL } }

    /// Requests are data from another process: accept only the actions Finder offers
    /// and a bounded list of absolute paths.
    var isWellFormed: Bool {
        FinderMenuPolicy.offeredActions.contains(action)
            && (1...Self.maximumItems).contains(paths.count)
            && paths.allSatisfy { $0.hasPrefix("/") && $0 != "/" && !$0.contains("\0") && $0.utf8.count <= 4096 }
    }
}

nonisolated enum FinderMenuPolicy {
    /// Actions that can appear in Finder's Zforge submenu.
    static let offeredActions: Set<BrowserSelectionAction> = Set(BrowserSelectionAction.allCases).subtracting([.removeFromArchive])

    /// The browser's actions for the same selection. Opening plain files and folders
    /// is left to Finder's own Open, so the submenu offers Open only for archives.
    static func actions(for urls: [URL], isDirectory: (URL) -> Bool) -> [BrowserSelectionAction] {
        guard (1...FinderMenuRequest.maximumItems).contains(urls.count) else { return [] }
        let archives = urls.map { !isDirectory($0) && ArchiveFormatRegistry.recognizes($0.lastPathComponent) }
        let actions = BrowserSelectionActionPolicy.actions(localItemsAreArchives: archives)
        return archives.allSatisfy { $0 } ? actions : actions.filter { $0 != .open }
    }

    /// The names listed by Extract to "Name", in selection order.
    static func extractionNames(for urls: [URL], fallback: String) -> String {
        urls.map { ArchiveNaming.extractionDirectoryName(for: $0.lastPathComponent, fallback: fallback) }
            .joined(separator: ", ")
    }
}

/// Requests travel through the shared app group container, so only Zforge's own
/// extension can submit them. The URL scheme only wakes the app to read its inbox.
nonisolated struct FinderRequestInbox: Sendable {
    static let urlScheme = "zforge-finder"
    static let wakeURL = URL(string: "zforge-finder://requests")!
    static let appGroupInfoKey = "ZforgeAppGroupIdentifier"
    /// A request that waited longer than this, for example while Zforge could not
    /// launch, is discarded instead of acting on files unexpectedly later.
    static let maximumAge: TimeInterval = 120
    private static let maximumFileSize = 1 << 20

    let directory: URL

    init(directory: URL) { self.directory = directory }

    static func shared(bundle: Bundle = .main) -> FinderRequestInbox? {
        guard let group = bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }
        return FinderRequestInbox(directory: container.appendingPathComponent("FinderRequests", isDirectory: true))
    }

    func submit(_ request: FinderMenuRequest) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(request)
        try data.write(to: directory.appendingPathComponent("\(request.id.uuidString).json"), options: [.atomic])
    }

    /// Removes every pending request and returns the valid, recent ones in submission order.
    func drain(now: Date = Date()) -> [FinderMenuRequest] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        var requests: [FinderMenuRequest] = []
        for file in files where file.pathExtension == "json" {
            defer { try? FileManager.default.removeItem(at: file) }
            guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= Self.maximumFileSize,
                  let data = try? Data(contentsOf: file),
                  let request = try? JSONDecoder().decode(FinderMenuRequest.self, from: data),
                  request.isWellFormed,
                  now.timeIntervalSince(request.createdAt) <= Self.maximumAge,
                  request.createdAt.timeIntervalSince(now) <= 5 else { continue }
            requests.append(request)
        }
        return requests.sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }
}
