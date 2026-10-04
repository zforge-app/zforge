import AppKit
import SwiftUI
import UniformTypeIdentifiers

private struct BrowserDropTargetURLKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

extension EnvironmentValues {
    var browserDropTargetURL: URL? {
        get { self[BrowserDropTargetURLKey.self] }
        set { self[BrowserDropTargetURLKey.self] = newValue }
    }
}

nonisolated enum BrowserItemVisualStyle {
    static let hiddenOpacity = 0.55
    static let selectedHiddenOpacity = 0.72

    static func contentOpacity(isHidden: Bool, isSelected: Bool) -> Double {
        guard isHidden else { return 1 }
        return isSelected ? selectedHiddenOpacity : hiddenOpacity
    }
}

extension View {
    func browserItemEmphasis(_ item: BrowserItem, isSelected: Bool = false) -> some View {
        opacity(
            BrowserItemVisualStyle.contentOpacity(
                isHidden: item.isHidden,
                isSelected: isSelected
            )
        )
    }
}

@MainActor
final class FileIconCache {
    static let shared = FileIconCache()

    private let cache = NSCache<NSString, NSImage>()
    private var directoryContentsCache: [String: FolderContentsCacheEntry] = [:]
    private lazy var nativeFolderIcon = NSWorkspace.shared.icon(for: .folder)
    private struct ArchiveFolderKey: Hashable {
        let scale: ArchiveFolderIconComposer.Scale
        let containsFiles: Bool
        let isExpanded: Bool
    }
    private var archiveFolderIcons: [ArchiveFolderKey: NSImage] = [:]
    private var localFolderIcons: [ArchiveFolderKey: NSImage] = [:]

    private func localDirectoryIcon(hasContents: Bool, isOpen: Bool = false) -> NSImage {
        let key = ArchiveFolderKey(scale: .large, containsFiles: hasContents, isExpanded: isOpen)
        if let cached = localFolderIcons[key] { return cached }
        let icon = ArchiveFolderIconComposer.compose(from: nativeFolderIcon, scale: .large,
            containsFiles: hasContents, isOpen: isOpen, showsArchiveStamp: false)
        localFolderIcons[key] = icon
        return icon
    }

    private init() {
        cache.countLimit = 2_048
    }

    func archiveDirectoryIcon(size: CGFloat, containsFiles: Bool = false, isExpanded: Bool = false) -> NSImage {
        let scale = ArchiveFolderIconComposer.Scale(size: size)
        let key = ArchiveFolderKey(scale: scale, containsFiles: containsFiles, isExpanded: isExpanded)
        if let cached = archiveFolderIcons[key] { return cached }
        let icon = ArchiveFolderIconComposer.compose(from: nativeFolderIcon, scale: scale, containsFiles: containsFiles, isOpen: isExpanded)
        archiveFolderIcons[key] = icon
        return icon
    }

    func icon(for item: BrowserItem) -> NSImage {
        guard let url = item.localURL else {
            return NSImage(named: NSImage.folderName) ?? NSImage()
        }

        return icon(
            for: url,
            isDirectory: item.isDirectory,
            isPackage: item.isPackage,
            modificationDate: item.modificationDate
        )
    }

    func icon(for url: URL) -> NSImage {
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .isPackageKey,
            .contentModificationDateKey
        ])
        return icon(
            for: url,
            isDirectory: values?.isDirectory ?? false,
            isPackage: values?.isPackage ?? false,
            modificationDate: values?.contentModificationDate
        )
    }

    private func icon(
        for url: URL,
        isDirectory: Bool,
        isPackage: Bool,
        modificationDate: Date?
    ) -> NSImage {
        let standardizedURL = url.standardizedFileURL
        let hasContents = isDirectory && !isPackage
            ? FolderContentsDetector.hasContents(
                at: standardizedURL,
                modificationDate: modificationDate,
                cache: &directoryContentsCache
            )
            : false
        let key = cacheKey(
            for: standardizedURL,
            modificationDate: modificationDate,
            hasContents: hasContents
        ) as NSString
        if let icon = cache.object(forKey: key) {
            return icon
        }

        let icon = isDirectory && !isPackage
            ? localDirectoryIcon(hasContents: hasContents)
            : NSWorkspace.shared.icon(forFile: standardizedURL.path)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func openFolderIcon(for item: BrowserItem) -> NSImage {
        guard let url = item.localURL else { return localDirectoryIcon(hasContents: false, isOpen: true) }
        return openFolderIcon(
            for: url,
            isDirectory: item.isDirectory,
            isPackage: item.isPackage,
            modificationDate: item.modificationDate
        )
    }

    func openFolderIcon(for url: URL) -> NSImage {
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .isPackageKey,
            .contentModificationDateKey
        ])
        return openFolderIcon(
            for: url,
            isDirectory: values?.isDirectory ?? false,
            isPackage: values?.isPackage ?? false,
            modificationDate: values?.contentModificationDate
        )
    }

    private func openFolderIcon(
        for url: URL,
        isDirectory: Bool,
        isPackage: Bool,
        modificationDate: Date?
    ) -> NSImage {
        guard isDirectory, !isPackage else { return NSWorkspace.shared.icon(forFile: url.path) }
        let hasContents = FolderContentsDetector.hasContents(
            at: url.standardizedFileURL,
            modificationDate: modificationDate,
            cache: &directoryContentsCache
        )
        return localDirectoryIcon(hasContents: hasContents, isOpen: true)
    }

    private func cacheKey(
        for url: URL,
        modificationDate: Date?,
        hasContents: Bool
    ) -> String {
        let modification = modificationDate?.timeIntervalSinceReferenceDate ?? 0
        return "\(url.path)|\(modification)|\(hasContents)"
    }
}

nonisolated struct FolderContentsCacheEntry {
    let modificationDate: Date?
    let hasContents: Bool
}

nonisolated enum FolderContentsDetector {
    static func hasContents(
        at directory: URL,
        modificationDate: Date?,
        cache: inout [String: FolderContentsCacheEntry],
        fileManager: FileManager = .default
    ) -> Bool {
        let key = directory.standardizedFileURL.path
        if let cached = cache[key], cached.modificationDate == modificationDate {
            return cached.hasContents
        }

        let hasContents = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: []
        ).isEmpty == false) ?? false
        cache[key] = FolderContentsCacheEntry(
            modificationDate: modificationDate,
            hasContents: hasContents
        )
        return hasContents
    }
}

struct FolderIconTransition: View {
    let closedIcon: NSImage
    let openIcon: NSImage
    let isOpen: Bool

    var body: some View {
        ZStack {
            Image(nsImage: closedIcon)
                .resizable()
                .interpolation(.high)
                .opacity(isOpen ? 0 : 1)

            Image(nsImage: openIcon)
                .resizable()
                .interpolation(.high)
                .opacity(isOpen ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.18), value: isOpen)
    }
}

struct FileIconView: View {
    @Environment(\.browserDropTargetURL) private var dropTargetURL
    let item: BrowserItem
    var size: CGFloat = 48
    var isExpanded: Bool = false

    var body: some View {
        Group {
            if item.isDirectory, case .archive = item.location {
                Image(nsImage: FileIconCache.shared.archiveDirectoryIcon(size: size, containsFiles: item.archiveDirectoryContainsFiles, isExpanded: isExpanded))
                    .resizable()
                    .interpolation(.high)
            } else if item.isDirectory, !item.isPackage, item.localURL != nil {
                FolderIconTransition(
                    closedIcon: FileIconCache.shared.icon(for: item),
                    openIcon: FileIconCache.shared.openFolderIcon(for: item),
                    isOpen: isExpanded || isOpenDropTarget
                )
            } else if item.localURL != nil {
                Image(nsImage: FileIconCache.shared.icon(for: item))
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.isDirectory ? .blue : .secondary)
                    .padding(size * 0.12)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var isOpenDropTarget: Bool {
        guard item.isDirectory,
              let itemURL = item.localURL?.standardizedFileURL,
              let dropTargetURL = dropTargetURL?.standardizedFileURL else { return false }
        return itemURL == dropTargetURL
    }

    private var systemImage: String {
        if item.isDirectory { return "folder.fill" }
        if item.isArchive { return "archivebox.fill" }
        if item.contentType?.conforms(to: .image) == true { return "photo.fill" }
        if item.contentType?.conforms(to: .audio) == true { return "waveform" }
        if item.contentType?.conforms(to: .movie) == true { return "film.fill" }
        if item.contentType?.conforms(to: .pdf) == true { return "doc.richtext.fill" }
        return "doc.fill"
    }
}
