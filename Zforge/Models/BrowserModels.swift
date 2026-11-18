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
    case creationDate
    case lastOpenedDate
    case dateAdded
    case size
    case kind
    case version
    case comments
    case tags
}

nonisolated enum BrowserListColumn: String, CaseIterable, Codable, Identifiable, Sendable {
    case name, modificationDate, creationDate, lastOpenedDate, dateAdded
    case size, kind, lastModifiedBy, sharedBy, version, comments, tags

    var id: String { rawValue }
    static let defaultVisible: [Self] = [.name, .modificationDate, .size, .kind]
    static let selectable = allCases.filter { $0 != .lastModifiedBy && $0 != .sharedBy }

    var titleKey: String.LocalizationValue {
        switch self {
        case .name: "Name"
        case .modificationDate: "Date Modified"
        case .creationDate: "Date Created"
        case .lastOpenedDate: "Date Last Opened"
        case .dateAdded: "Date Added"
        case .size: "Size"
        case .kind: "Kind"
        case .lastModifiedBy: "Last Modified By"
        case .sharedBy: "Shared By"
        case .version: "Version"
        case .comments: "Comments"
        case .tags: "Tags"
        }
    }

    var sortField: BrowserSortField? { BrowserSortField(rawValue: rawValue) }

    func title(locale: Locale) -> String {
        AppLocalization.string(titleKey, locale: locale)
    }
}

nonisolated struct BrowserExtendedMetadata: Hashable, Sendable {
    var lastOpenedDate: Date? = nil
    var dateAdded: Date? = nil
    var version: String? = nil
    var comments: String? = nil
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
            case .creationDate:
                compare(lhs.creationDate ?? .distantPast, rhs.creationDate ?? .distantPast)
            case .lastOpenedDate:
                compare(lhs.extendedMetadata.lastOpenedDate ?? .distantPast,
                        rhs.extendedMetadata.lastOpenedDate ?? .distantPast)
            case .dateAdded:
                compare(lhs.extendedMetadata.dateAdded ?? .distantPast,
                        rhs.extendedMetadata.dateAdded ?? .distantPast)
            case .size:
                compare(lhs.size ?? 0, rhs.size ?? 0)
            case .kind:
                lhs.kindSortKey.localizedStandardCompare(rhs.kindSortKey)
            case .version:
                (lhs.extendedMetadata.version ?? "").localizedStandardCompare(rhs.extendedMetadata.version ?? "")
            case .comments:
                (lhs.extendedMetadata.comments ?? "").localizedStandardCompare(rhs.extendedMetadata.comments ?? "")
            case .tags:
                lhs.tags.joined(separator: ", ").localizedStandardCompare(rhs.tags.joined(separator: ", "))
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
    /// Finder's computer level: the mounted volumes and Network. Virtual, so it
    /// accepts no file operations, drops or new folders.
    case computer
    /// Finder's Network level: file servers discovered on the local network. Virtual
    /// and read-only like `computer`.
    case network
    /// A discovered server (an item of the Network level, never a browsed level):
    /// opening it connects to its Bonjour address.
    case networkServer(URL)
    case fileSystem(URL)
    case archive(ArchiveAddress)

    var fileSystemURL: URL? {
        guard case let .fileSystem(url) = self else { return nil }
        return url
    }

    /// The archive folder a drop would add to; writability is decided by the window,
    /// which knows whether the archive's session is read-only.
    var archiveAddress: ArchiveAddress? {
        guard case let .archive(address) = self else { return nil }
        return address
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

    /// The same symbols as the menus' Compress and Extract Here.
    var symbol: MenuSymbol {
        usesExtractionIcon ? .extract : .compress
    }
}

extension BrowserSelectionActionPolicy {
    static func actions(for selected: [BrowserItem]) -> [BrowserSelectionAction] {
        guard !selected.isEmpty else { return [] }
        guard selected.allSatisfy({ $0.localURL != nil }) else { return [.open] }
        return actions(localItemsAreArchives: selected.map(\.isArchive))
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


}

nonisolated struct ArchiveAddress: Hashable, Sendable {
    let sessionID: UUID
    let archiveID: UUID
    let internalPath: String

    init(sessionID: UUID, archiveID: UUID, internalPath: String) {
        self.sessionID = sessionID
        self.archiveID = archiveID
        self.internalPath = internalPath
    }

    func appending(_ component: String) -> ArchiveAddress {
        let path = internalPath.isEmpty ? component : "\(internalPath)/\(component)"
        return ArchiveAddress(sessionID: sessionID, archiveID: archiveID, internalPath: path)
    }
}

nonisolated struct BrowserPathComponent: Identifiable, Hashable, Sendable {
    let location: BrowserLocation
    let name: String
    let isArchive: Bool
    /// Overrides the location's symbol, for example for archive search results.
    var systemImage: String? = nil

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
    var tagColorIndexes: [String: Int] = [:]
    let contentTypeIdentifier: String?
    let encrypted: Bool
    let checksum: String?
    let compressionMethod: String?
    var extendedMetadata = BrowserExtendedMetadata()
    /// True when an archive directory has at least one file anywhere below it.
    var archiveDirectoryContainsFiles = false
    /// Set for archive entries whose decoding starts at the beginning of a shared solid block.
    var solidBlock: ArchiveSolidBlock? = nil
    /// For a volume of a split archive on disk (ZF-83): its place in the set. Any volume acts
    /// on the whole set; only the volume that opens the set expands inline.
    var archiveVolume: ArchiveVolumeName? = nil
    /// For a split archive stored inside an archive (ZF-83 stage 2): the total size of its
    /// volumes, which entering it copies, and their preview measure (sizes or solid blocks).
    var archiveSetSize: Int64? = nil
    var archiveSetMeasure: Int64? = nil

    /// What entering an archive inside an archive copies: its entry, or every volume of a
    /// split archive.
    var innerArchiveCopySize: Int64? { archiveSetSize ?? size }
    /// Cached local resource identity. It is a context hint, never an access grant.
    var fileIdentity: Data? = nil

    var localURL: URL? { location.fileSystemURL }

    var contentType: UTType? {
        if let contentTypeIdentifier, let type = UTType(contentTypeIdentifier) {
            return type
        }
        return UTType(filenameExtension: URL(fileURLWithPath: name).pathExtension)
    }

    var kindSortKey: String {
        if isDirectory { return "folder" }
        if archiveVolume != nil { return "archive.split" }
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
    /// Ejecting a volume failed; `inUse` marks a busy volume (open files, a running process).
    case ejectFailed(volumeName: String, inUse: Bool, detail: String)

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
        case let .ejectFailed(volumeName, true, _):
            AppLocalization.string("error.eject_in_use \(volumeName)")
        case let .ejectFailed(volumeName, false, detail):
            AppLocalization.string("error.eject_failed \(volumeName) \(detail)")
        }
    }
}

nonisolated extension BrowserItem {
    var usesStaticIconPreview: Bool {
        isContainer || isArchive || isNetworkEntry
    }

    var canExpandInlineInList: Bool {
        if isContainer { return !isNetworkEntry }
        guard canNavigateAsArchive else { return false }
        if let archiveVolume, !archiveVolume.opensSet { return false }
        return ArchiveFormatRegistry.supportsFastTreeListing(name)
    }

    /// Its size is calculated when shown: a folder's contents, or a split archive's volumes (ZF-83).
    var hasComputedSize: Bool {
        (isDirectory && !isSymbolicLink) || archiveVolume != nil
    }

    /// A local archive file that local items can be added to by a drop or Add to Archive:
    /// a ZIP or 7z, whole or split in `.NNN` volumes (ZF-83 stage 3); not a spanned ZIP or RAR.
    var acceptsArchiveAdditions: Bool {
        guard isArchive, case .fileSystem = location else { return false }
        if let archiveVolume, !archiveVolume.scheme.isNumbered { return false }
        return ArchiveFormatRegistry.supportsUpdating(name)
    }

    /// Archives are browsed in place, on disk and inside other archives, at any depth
    /// (D-98). An archive inside an archive is opened from a copy of it, made when it is
    /// entered: in Columns, only selecting one within the preview limit enters it.
    var canNavigateAsArchive: Bool {
        guard isArchive else { return false }
        switch location {
        case .fileSystem: return true
        case .archive: return !isDirectory
        case .recents, .computer, .network, .networkServer: return false
        }
    }

    /// An archive stored inside an archive (D-98).
    var isArchiveInsideArchive: Bool {
        guard isArchive, !isDirectory, case .archive = location else { return false }
        return true
    }

    var isNavigableContainer: Bool {
        isContainer || canNavigateAsArchive
    }
}
