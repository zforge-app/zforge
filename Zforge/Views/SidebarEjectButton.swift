import SwiftUI

/// Finder's inline ⏏ button at the trailing edge of an ejectable sidebar volume row. It ejects
/// through the shared `FileBrowserState.ejectVolume(at:name:)` and shows a small spinner while that
/// eject is in flight.
struct SidebarEjectButton: View {
    /// Square hit area; the row reserves the same width so the name truncates before the button.
    static let size: CGFloat = 20

    @Bindable var browser: FileBrowserState
    let name: String
    let url: URL
    let isDropTarget: Bool
    let restoreContentFocus: () -> Void

    private var isEjecting: Bool { browser.ejectingVolumeURLs.contains(url.standardizedFileURL) }

    var body: some View {
        Button {
            restoreContentFocus()
            Task { await browser.ejectVolume(at: url, name: name) }
        } label: {
            ZStack {
                if isEjecting {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "eject.fill")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .frame(width: Self.size, height: Self.size)
            .contentShape(Rectangle())
        }
        .buttonStyle(SidebarEjectButtonStyle(isDropTarget: isDropTarget))
        .disabled(isEjecting)
        .help(Text("Eject “\(name)”"))
        .accessibilityLabel(Text("Eject “\(name)”"))
        .accessibilityIdentifier("sidebar-eject-\(url.standardizedFileURL.path)")
    }
}

/// Secondary glyph that strengthens on hover and press, white over the accent drop-target fill,
/// and follows the window's active state like the other sidebar glyphs.
private struct SidebarEjectButtonStyle: ButtonStyle {
    let isDropTarget: Bool

    func makeBody(configuration: Configuration) -> some View {
        SidebarEjectButtonBody(configuration: configuration, isDropTarget: isDropTarget)
    }
}

private struct SidebarEjectButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isDropTarget: Bool
    @Environment(\.appearsActive) private var appearsActive
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .foregroundStyle(color)
            .onHover { isHovered = $0 }
    }

    private var color: Color {
        if isDropTarget { return .white }
        if configuration.isPressed { return Color(nsColor: .labelColor) }
        if !appearsActive { return Color(nsColor: .tertiaryLabelColor) }
        return Color(nsColor: isHovered ? .labelColor : .secondaryLabelColor)
    }
}
