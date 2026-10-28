import Foundation

// Shared by the app and its Finder extension. The browser's context menu and
// Finder's Zforge submenu must offer the same actions for the same selection.

nonisolated enum BrowserSelectionAction: String, CaseIterable, Codable, Hashable, Sendable {
    case open
    case compress
    case compressCustom
    case addToArchive
    case removeFromArchive
    case extractHere
    case extractNamed
    case extractChoose
    case validate

    /// The menu symbol. A badge is drawn over the symbol's lower trailing corner.
    var menuSymbol: MenuSymbol? {
        switch self {
        case .open: MenuSymbol("arrow.up.forward.app")
        case .compress: .compress
        case .compressCustom: MenuSymbol("archivebox", badge: "gearshape.fill")
        case .addToArchive: MenuSymbol("archivebox", badge: "plus.circle.fill")
        case .removeFromArchive: MenuSymbol("trash")
        case .extractHere: .extract
        case .extractNamed: MenuSymbol("folder.badge.plus")
        case .extractChoose: MenuSymbol("folder")
        case .validate: MenuSymbol("checkmark.circle")
        }
    }
}

nonisolated struct MenuSymbol: Equatable, Sendable {
    let name: String
    let badge: String?

    init(_ name: String, badge: String? = nil) {
        self.name = name
        self.badge = badge
    }

    /// Compress and extract, shared by the menus and the toolbar's archive action.
    static let compress = MenuSymbol("archivebox", badge: "arrow.down.circle.fill")
    static let extract = MenuSymbol("archivebox", badge: "arrow.up.circle.fill")
}

nonisolated enum BrowserSelectionActionPolicy {
    /// Actions for a selection of local items, one archive flag per item.
    static func actions(localItemsAreArchives archives: [Bool]) -> [BrowserSelectionAction] {
        guard !archives.isEmpty else { return [] }
        guard archives.allSatisfy({ $0 }) else {
            return [.open, .compress, .compressCustom, .addToArchive]
        }
        let extraction: [BrowserSelectionAction] = [
            .open, .extractHere, .extractNamed, .extractChoose, .validate
        ]
        return archives.count > 1 ? extraction + [.compress, .compressCustom, .addToArchive] : extraction + [.addToArchive]
    }
}

nonisolated enum ArchiveNaming {
    /// The archive name without its format suffix, including compound tar suffixes.
    static func baseName(_ name: String) -> String {
        let lowercased = name.lowercased()
        for suffix in [".tar.gz", ".tar.bz2", ".tar.xz", ".tgz", ".tbz2", ".txz"] {
            if lowercased.hasSuffix(suffix) {
                return String(name.dropLast(suffix.count))
            }
        }
        return URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
    }

    /// The folder name used by Extract to "Name"; `fallback` replaces names that cannot name a folder.
    static func extractionDirectoryName(for archiveName: String, fallback: String) -> String {
        let baseName = baseName(archiveName)
        return baseName.isEmpty || baseName == "." || baseName == ".." ? fallback : baseName
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
        // This is filename classification, not URL resolution. Constructing a
        // relative file URL repeatedly consults the working directory.
        return commonExtensions.contains((lowercased as NSString).pathExtension)
    }

    static func supportsUpdating(_ name: String) -> Bool {
        let lowercased = name.lowercased()
        return lowercased.hasSuffix(".zip") || lowercased.hasSuffix(".7z")
    }

    /// Formats whose directory metadata can be read without walking a
    /// sequentially compressed payload. Keep this deliberately conservative:
    /// inline list expansion must feel as immediate as expanding a folder.
    static func supportsFastTreeListing(_ name: String) -> Bool {
        let extensionName = URL(fileURLWithPath: name.lowercased()).pathExtension
        return extensionName == "zip" || extensionName == "7z"
    }
}
