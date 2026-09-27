import Foundation
import UniformTypeIdentifiers

nonisolated enum BrowserViewMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case icons
    case list
    case columns
    case gallery

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .icons: "square.grid.2x2"
        case .list: "list.bullet"
        case .columns: "rectangle.split.3x1"
        case .gallery: "rectangle.bottomthird.inset.filled"
        }
    }

    var titleKey: String.LocalizationValue {
        switch self {
        case .icons: "view.icons"
        case .list: "view.list"
        case .columns: "view.columns"
        case .gallery: "view.gallery"
        }
    }

    func title(locale: Locale) -> String {
        AppLocalization.string(titleKey, locale: locale)
    }
}

nonisolated enum BrowserSortField: String, CaseIterable, Codable, Sendable {
    case name
    case modificationDate
    case size
    case kind
}

nonisolated struct BrowserSort: Codable, Equatable, Hashable, Sendable {
    var field: BrowserSortField = .name
    var ascending = true

    func sorted(_ items: [BrowserItem]) -> [BrowserItem] {
        items.sorted { lhs, rhs in
            if lhs.isContainer != rhs.isContainer {
                return lhs.isContainer
            }

            let comparison: ComparisonResult = switch field {
            case .name:
                lhs.name.localizedStandardCompare(rhs.name)
            case .modificationDate:
                compare(lhs.modificationDate ?? .distantPast, rhs.modificationDate ?? .distantPast)
            case .size:
                compare(lhs.size ?? 0, rhs.size ?? 0)
            case .kind:
                lhs.kindSortKey.localizedStandardCompare(rhs.kindSortKey)
            }

            if comparison == .orderedSame {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }
}

nonisolated enum BrowserLocation: Hashable, Sendable {
    case recents
    case fileSystem(URL)
    case archive(ArchiveAddress)

    var fileSystemURL: URL? {
        guard case let .fileSystem(url) = self else { return nil }
        return url
    }
}

nonisolated enum ArchiveToolbarAction: Equatable, Sendable {
    case extractAll
    case extractSelected
    case compress
    case unavailableInsideArchive
    case unavailableOutsideArchive

    var isEnabled: Bool {
        switch self {
        case .extractAll, .extractSelected, .compress: true
        case .unavailableInsideArchive, .unavailableOutsideArchive: false
        }
    }

    var usesExtractionIcon: Bool {
        switch self {
        case .extractAll, .extractSelected, .unavailableInsideArchive: true
        case .compress, .unavailableOutsideArchive: false
        }
    }
}

nonisolated enum BrowserSelectionAction: CaseIterable, Hashable, Sendable {
    case open
    case compress
    case compressCustom
    case extractHere
    case extractNamed
    case extractChoose
    case validate

    var systemImage: String {
        switch self {
        case .open: "arrow.up.forward.app"
        case .compress, .compressCustom: "archivebox"
        case .extractHere, .extractNamed, .extractChoose: "arrow.down.to.line.compact"
        case .validate: "checkmark.shield"
        }
    }
}

nonisolated enum BrowserSelectionActionPolicy {
    static func actions(for selected: [BrowserItem]) -> [BrowserSelectionAction] {
        guard !selected.isEmpty else { return [] }
        guard selected.allSatisfy({ $0.localURL != nil }) else { return [.open] }
        guard selected.allSatisfy(\.isArchive) else {
            return [.open, .compress, .compressCustom]
        }
        let extraction: [BrowserSelectionAction] = [
            .open, .extractHere, .extractNamed, .extractChoose, .validate
        ]
        return selected.count > 1 ? extraction + [.compress, .compressCustom] : extraction
    }
}

nonisolated enum ArchiveCompressionFormat: String, CaseIterable, Codable, Identifiable, Sendable {
    case sevenZip = "7z"
    case zip
    case tar
    case xz
    case bzip2
    case gzip
    case wim

    var id: Self { self }

    var fileExtension: String {
        switch self {
        case .bzip2: "bz2"
        case .gzip: "gz"
        default: rawValue
        }
    }

    var titleKey: String.LocalizationValue {
        switch self {
        case .sevenZip: "7z"
        case .zip: "ZIP"
        case .tar: "TAR"
        case .xz: "XZ"
        case .bzip2: "BZIP2"
        case .gzip: "GZIP"
        case .wim: "WIM"
        }
    }

    func title(locale: Locale) -> String {
        AppLocalization.string(titleKey, locale: locale)
    }

    var isStream: Bool {
        switch self {
        case .xz, .bzip2, .gzip: true
        case .sevenZip, .zip, .tar, .wim: false
        }
    }

    var sevenZipTypeSwitch: String {
        "-t\(rawValue)"
    }
}

nonisolated struct ArchiveAddress: Hashable, Sendable {
    let sessionID: UUID
    let archiveID: UUID
    let internalPath: String
    let allowsNestedArchives: Bool
    let nestedArchiveDepth: Int
    let maximumNestedArchiveDepth: Int

    init(
        sessionID: UUID,
        archiveID: UUID,
        internalPath: String,
        allowsNestedArchives: Bool = true,
        nestedArchiveDepth: Int = 0,
        maximumNestedArchiveDepth: Int = 5
    ) {
        self.sessionID = sessionID
        self.archiveID = archiveID
        self.internalPath = internalPath
        self.allowsNestedArchives = allowsNestedArchives
        self.nestedArchiveDepth = nestedArchiveDepth
        self.maximumNestedArchiveDepth = maximumNestedArchiveDepth
    }

    var canOpenNestedArchive: Bool {
        allowsNestedArchives && nestedArchiveDepth < maximumNestedArchiveDepth
    }

    func appending(_ component: String) -> ArchiveAddress {
        let path = internalPath.isEmpty ? component : "\(internalPath)/\(component)"
        return ArchiveAddress(
            sessionID: sessionID,
            archiveID: archiveID,
            internalPath: path,
            allowsNestedArchives: allowsNestedArchives,
            nestedArchiveDepth: nestedArchiveDepth,
            maximumNestedArchiveDepth: maximumNestedArchiveDepth
        )
    }
}

nonisolated struct BrowserPathComponent: Identifiable, Hashable, Sendable {
    let location: BrowserLocation
    let name: String
    let isArchive: Bool

    var id: BrowserLocation { location }
}

nonisolated struct BrowserItemID: Hashable, Sendable {
    let rawValue: String
}

nonisolated struct BrowserItem: Identifiable, Hashable, Sendable {
    let id: BrowserItemID
    let name: String
    let location: BrowserLocation
    let isContainer: Bool
    let isDirectory: Bool
    let isPackage: Bool
    let isSymbolicLink: Bool
    let isHidden: Bool
    let isArchive: Bool
    let size: Int64?
    let packedSize: Int64?
    let creationDate: Date?
    let modificationDate: Date?
    let accessDate: Date?
    let tags: [String]
    let contentTypeIdentifier: String?
    let encrypted: Bool
    let checksum: String?
    let compressionMethod: String?

    var localURL: URL? { location.fileSystemURL }

    var contentType: UTType? {
        if let contentTypeIdentifier, let type = UTType(contentTypeIdentifier) {
            return type
        }
        return UTType(filenameExtension: URL(fileURLWithPath: name).pathExtension)
    }

    var kindSortKey: String {
        if isDirectory { return "folder" }
        if isArchive { return "archive" }
        return contentType?.identifier ?? URL(fileURLWithPath: name).pathExtension.lowercased()
    }

    func formattedSize(locale: Locale) -> String {
        guard !isDirectory, let size else { return "—" }
        return AppLocalization.byteCount(size, locale: locale)
    }

    func formattedDate(_ date: Date?, locale: Locale) -> String {
        guard let date else { return "—" }
        return date.formatted(.dateTime.locale(locale).year().month(.abbreviated).day().hour().minute())
    }
}

nonisolated struct VisibleBrowserItem: Identifiable, Hashable, Sendable {
    let item: BrowserItem
    let depth: Int
    let isExpanded: Bool
    let rowIndex: Int

    var id: BrowserItemID { item.id }
}

nonisolated enum BrowserError: LocalizedError, Equatable {
    case permissionDenied(URL)
    case unavailable(String)
    case archive(String)
    case cancelled
    case invalidServerURL
    case previewTooLarge(Int64)

    var errorDescription: String? {
        switch self {
        case let .permissionDenied(url):
            AppLocalization.string("error.permission \(url.lastPathComponent)")
        case let .unavailable(message), let .archive(message):
            message
        case .cancelled:
            AppLocalization.string("error.cancelled")
        case .invalidServerURL:
            AppLocalization.string("error.invalid_server")
        case let .previewTooLarge(size):
            AppLocalization.string("error.preview_too_large \(AppLocalization.byteCount(size))")
        }
    }
}

nonisolated enum ArchiveFormatRegistry {
    static let commonExtensions: Set<String> = [
        "7z", "zip", "rar", "tar", "tgz", "tbz", "tbz2", "txz", "tzst",
        "gz", "gzip", "bz2", "bzip2", "xz", "zst", "lzma", "cab", "arj",
        "lzh", "lha", "cpio", "xar", "wim", "swm", "iso"
    ]

    static func recognizes(_ name: String) -> Bool {
        let lowercased = name.lowercased()
        if lowercased.hasSuffix(".7z.001") || lowercased.hasSuffix(".zip.001") { return true }
        return commonExtensions.contains(URL(fileURLWithPath: lowercased).pathExtension)
    }

    /// Formats whose directory metadata can be read without walking a
    /// sequentially compressed payload. Keep this deliberately conservative:
    /// inline list expansion must feel as immediate as expanding a folder.
    static func supportsFastTreeListing(_ name: String) -> Bool {
        let extensionName = URL(fileURLWithPath: name.lowercased()).pathExtension
        return extensionName == "zip" || extensionName == "7z"
    }
}

nonisolated struct ArchiveBrowsingPolicy: Equatable, Sendable {
    static let standard = ArchiveBrowsingPolicy(maximumNestedArchiveDepth: 5, rootSizeLimit: 1_000_000_000)

    let maximumNestedArchiveDepth: Int
    let rootSizeLimit: Int64

    init(maximumNestedArchiveDepth: Int, rootSizeLimit: Int64) {
        self.maximumNestedArchiveDepth = min(max(maximumNestedArchiveDepth, 1), 10)
        self.rootSizeLimit = min(max(rootSizeLimit, 1_000_000_000), 5 * 1_000_000_000)
    }

    func allowsNestedArchives(forOutermostSize size: Int64?) -> Bool {
        guard let size else { return false }
        return size < rootSizeLimit
    }
}

extension BrowserItem {
    var usesStaticIconPreview: Bool {
        isContainer || isArchive
    }

    var canExpandInlineInList: Bool {
        if isContainer { return true }
        guard canNavigateAsArchive else { return false }
        return ArchiveFormatRegistry.supportsFastTreeListing(name)
    }

    var canNavigateAsArchive: Bool {
        guard isArchive else { return false }
        switch location {
        case .recents:
            return false
        case .fileSystem:
            return true
        case let .archive(address):
            return address.canOpenNestedArchive
        }
    }

    var isNavigableContainer: Bool {
        isContainer || canNavigateAsArchive
    }
}
