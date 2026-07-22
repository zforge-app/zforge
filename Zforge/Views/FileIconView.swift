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

enum BrowserItemVisualStyle {
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
    private lazy var cachedOpenFolderIcon: NSImage = {
        let osTypeTag = UTTagClass(rawValue: "com.apple.ostype")
        guard let contentType = UTType(
            tag: "ofld",
            tagClass: osTypeTag,
            conformingTo: nil
        ) else {
            return NSImage(named: NSImage.folderName) ?? NSImage()
        }
        return NSWorkspace.shared.icon(for: contentType)
    }()

    private init() {
        cache.countLimit = 2_048
    }

    func icon(for url: URL) -> NSImage {
        let key = url.standardizedFileURL.path as NSString
        if let icon = cache.object(forKey: key) {
            return icon
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(icon, forKey: key)
        return icon
    }

    var openFolderIcon: NSImage { cachedOpenFolderIcon }
}

struct FileIconView: View {
    @Environment(\.browserDropTargetURL) private var dropTargetURL
    let item: BrowserItem
    var size: CGFloat = 48

    var body: some View {
        Group {
            if isOpenDropTarget {
                Image(nsImage: FileIconCache.shared.openFolderIcon)
                    .resizable()
                    .interpolation(.high)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            } else if let url = item.localURL {
                Image(nsImage: FileIconCache.shared.icon(for: url))
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
        .id(isOpenDropTarget)
        .frame(width: size, height: size)
        .animation(.snappy(duration: 0.18), value: isOpenDropTarget)
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
