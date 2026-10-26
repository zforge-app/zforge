import SwiftUI
import UniformTypeIdentifiers

/// Decorative play glyph drawn over content thumbnails of video files so they read as
/// playable media. It never receives hits and stays out of the accessibility tree.
struct VideoPlayBadge: View {
    let thumbnailSize: CGSize
    @Environment(\.colorSchemeContrast) private var contrast

    nonisolated static func diameter(for thumbnailSize: CGSize) -> CGFloat {
        min(56, max(16, min(thumbnailSize.width, thumbnailSize.height) * 0.36))
    }

    private var diameter: CGFloat { Self.diameter(for: thumbnailSize) }

    var body: some View {
        Image(systemName: "play.fill")
            .font(.system(size: diameter * 0.42, weight: .bold))
            .foregroundStyle(.white)
            // The triangle's visual mass sits left of its bounds; nudge it to look centered.
            .offset(x: diameter * 0.04)
            .frame(width: diameter, height: diameter)
            .background(.black.opacity(contrast == .increased ? 0.7 : 0.45), in: Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.9), lineWidth: max(1, diameter * 0.06))
            }
            .shadow(color: .black.opacity(0.3), radius: diameter * 0.12, y: diameter * 0.04)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

nonisolated extension BrowserItem {
    /// Video files show a play badge over their content thumbnail. Containers and archives
    /// keep static icons, so they never qualify.
    var showsVideoPlayBadge: Bool {
        !isDirectory && !usesStaticIconPreview && contentType?.conforms(to: .movie) == true
    }
}
