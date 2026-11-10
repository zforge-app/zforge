import SwiftUI

/// The window toolbar of the browser window, shared by the Settings and Keyboard Shortcuts
/// windows (ZF-62, ZF-59): a 52 pt unified toolbar with the traffic lights centred in it and the
/// window title inline at 15 pt semibold in the label colour, no bar background over scrolling
/// content.
extension View {
    /// Titles the window with `title` in the browser window's toolbar look. Apply it to the
    /// window's detail content, and add `unifiedWindowToolbarStyle()` once to the window's root.
    func windowToolbar(title: Text) -> some View {
        navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .toolbar(.visible, for: .windowToolbar)
            .toolbar { WindowToolbarAnchor() }
    }

    /// Gives the window the unified toolbar style. A Settings scene gets AppKit's preference
    /// toolbar, which centres toolbar items under the title: a profile page's back button sat
    /// alone on a second row (D-75). The unified style puts the back button and the title in one
    /// row at the detail column's leading edge, as in System Settings.
    func unifiedWindowToolbarStyle() -> some View {
        background { UnifiedWindowToolbarStyle() }
    }
}

/// An empty toolbar item. SwiftUI gives a window the 52 pt unified toolbar, with the title in the
/// toolbar's own title style, only while the window has a toolbar item; a Settings pane or the
/// shortcut list has none of its own, so without this the window kept the 32 pt title bar and its
/// small grey title.
private struct WindowToolbarAnchor: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(id: "window-toolbar-anchor", placement: .primaryAction) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
        }
        .sharedBackgroundVisibility(.hidden)
    }
}

private struct UnifiedWindowToolbarStyle: NSViewRepresentable {
    func makeNSView(context: Context) -> UnifiedWindowToolbarStyleView { UnifiedWindowToolbarStyleView() }
    func updateNSView(_ view: UnifiedWindowToolbarStyleView, context: Context) { view.applyStyle() }
}

final class UnifiedWindowToolbarStyleView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyStyle()
    }

    func applyStyle() {
        guard let window, window.toolbarStyle != .unified else { return }
        window.toolbarStyle = .unified
    }
}
