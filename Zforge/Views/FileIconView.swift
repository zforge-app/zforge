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

enum FolderTagIconColor {
    nonisolated static func index(tags: [String], colors: [String: Int]) -> Int? {
        FinderTagPresentation.folderColor(tags: tags, colors: colors)
    }

    /// Replace the blue material's hue, retaining neutral paper, badges and shadows.
    @MainActor
    static func compose(_ image: NSImage, colorIndex: Int) -> NSImage {
        guard image.size.width > 0, image.size.height > 0 else { return image }
        // NSWorkspace images often have a 32 pt logical size with larger native
        // representations. Draw at preview resolution before changing pixels.
        let width = 512, height = 512
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .copy, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
        guard rendered else { return image }
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[offset + 3]) / 255
            guard alpha > 0 else { continue }
            let rgb = recolored(red: Double(pixels[offset]) / 255 / alpha,
                                green: Double(pixels[offset + 1]) / 255 / alpha,
                                blue: Double(pixels[offset + 2]) / 255 / alpha, index: colorIndex)
            pixels[offset] = UInt8(clamping: Int((rgb.0 * alpha * 255).rounded()))
            pixels[offset + 1] = UInt8(clamping: Int((rgb.1 * alpha * 255).rounded()))
            pixels[offset + 2] = UInt8(clamping: Int((rgb.2 * alpha * 255).rounded()))
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let output = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return image }
        return NSImage(cgImage: output, size: image.size)
    }

    nonisolated static func recolored(red r: Double, green g: Double, blue b: Double, index: Int) -> (Double, Double, Double) {
        let maximum = max(r, g, b), minimum = min(r, g, b)
        let chroma = maximum - minimum
        guard maximum > 0, chroma > 0.06, b > r, b >= g * 0.95 else { return (r, g, b) }
        // A gradual mask avoids fringes around antialiased material and neutral highlights.
        let mask = min(1, max(0, (b - r - 0.04) / 0.12))
        let hue: Double = switch index {
        case 2: 0.34
        case 3: 0.79
        case 4: 0.56
        case 5: 0.14
        case 6: 0.0
        case 7: 0.075
        default: 0
        }
        let saturation = index == 1 ? 0 : min(1, chroma / maximum * 1.35)
        let value = maximum * (index == 1 ? 0.82 : index == 2 ? 0.9 : 1)
        let sector = hue * 6
        let c = value * saturation
        let x = c * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let m = value - c
        let components: (Double, Double, Double) = switch Int(sector) {
        case 0: (c, x, 0)
        case 1: (x, c, 0)
        case 2: (0, c, x)
        case 3: (0, x, c)
        case 4: (x, 0, c)
        default: (c, 0, x)
        }
        return (r + (components.0 + m - r) * mask,
                g + (components.1 + m - g) * mask,
                b + (components.2 + m - b) * mask)
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

        let base = icon(
            for: url,
            isDirectory: item.isDirectory,
            isPackage: item.isPackage,
            modificationDate: item.modificationDate
        )
        return coloredFolder(base, item: item)
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

        let icon = isDirectory && !isPackage && !Self.isVolumeRoot(standardizedURL)
            ? localDirectoryIcon(hasContents: hasContents)
            : NSWorkspace.shared.icon(forFile: standardizedURL.path)
        cache.setObject(icon, forKey: key)
        return icon
    }

    /// A mounted volume's root shows the system icon of its volume type (internal disk, external
    /// or removable drive, disk image, network volume), as in Finder, never the composed folder.
    private static func isVolumeRoot(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isVolumeKey]))?.isVolume == true
    }

    func openFolderIcon(for item: BrowserItem) -> NSImage {
        guard let url = item.localURL else { return localDirectoryIcon(hasContents: false, isOpen: true) }
        let base = openFolderIcon(
            for: url,
            isDirectory: item.isDirectory,
            isPackage: item.isPackage,
            modificationDate: item.modificationDate
        )
        return coloredFolder(base, item: item, isOpen: true)
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
        guard isDirectory, !isPackage, !Self.isVolumeRoot(url.standardizedFileURL) else {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        let hasContents = FolderContentsDetector.hasContents(
            at: url.standardizedFileURL,
            modificationDate: modificationDate,
            cache: &directoryContentsCache
        )
        return localDirectoryIcon(hasContents: hasContents, isOpen: true)
    }

    private func coloredFolder(_ image: NSImage, item: BrowserItem, isOpen: Bool = false) -> NSImage {
        guard item.isDirectory, !item.isPackage,
              let index = FolderTagIconColor.index(tags: item.tags, colors: item.tagColorIndexes) else { return image }
        let key = "tag|\(item.id)|\(item.modificationDate?.timeIntervalSinceReferenceDate ?? 0)|\(index)|\(isOpen)|\(ObjectIdentifier(image))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let colored = FolderTagIconColor.compose(image, colorIndex: index)
        cache.setObject(colored, forKey: key)
        return colored
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
            } else if let networkIcon = NetworkLevelCatalog.icon(for: item) {
                Image(nsImage: networkIcon)
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
