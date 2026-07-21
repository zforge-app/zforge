import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
}

struct FileIconView: View {
    let item: BrowserItem
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let url = item.localURL {
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
        .frame(width: size, height: size)
        .accessibilityHidden(true)
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
