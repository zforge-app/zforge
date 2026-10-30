import AppKit
import SwiftUI
import Testing
@testable import Zforge

@Suite("Sidebar icon tint")
@MainActor
struct SidebarIconTintTests {
    @Test("Favorites keep the accent and Locations use neutral gray while the window is active")
    func activeWindowRoles() {
        #expect(SidebarIconTint.accent.appearance(appearsActive: true, isDropTarget: false) == .accent)
        #expect(SidebarIconTint.neutral.appearance(appearsActive: true, isDropTarget: false) == .neutral)
    }

    @Test("Every sidebar icon turns gray while the window is inactive")
    func inactiveWindowIsGray() {
        #expect(SidebarIconTint.accent.appearance(appearsActive: false, isDropTarget: false) == .inactive)
        #expect(SidebarIconTint.neutral.appearance(appearsActive: false, isDropTarget: false) == .inactive)
    }

    @Test("A drop target shows a white icon on the accent background, even in an inactive window")
    func dropTargetIsWhite() {
        for tint in [SidebarIconTint.accent, .neutral] {
            for active in [true, false] {
                #expect(tint.appearance(appearsActive: active, isDropTarget: true) == .dropTarget)
            }
        }
    }

    @Test("Neutral and inactive icons use semantic gray label colors that adapt to the theme")
    func semanticColors() {
        #expect(SidebarIconTint.Appearance.accent.color == Color.accentColor)
        #expect(SidebarIconTint.Appearance.neutral.color == Color(nsColor: .secondaryLabelColor))
        #expect(SidebarIconTint.Appearance.inactive.color == Color(nsColor: .tertiaryLabelColor))
        #expect(SidebarIconTint.Appearance.dropTarget.color == Color.white)
        #expect(SidebarIconTint.Appearance.neutral.color != SidebarIconTint.Appearance.inactive.color,
                "An inactive window is visibly lighter than the active Locations gray")
    }

    @Test("Sidebar icons render per section role and window state",
          arguments: ZforgeSnapshot.appearances.map(\.name), [true, false])
    func snapshot(appearanceName: String, appearsActive: Bool) throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == appearanceName }?.appearance)
        let size = CGSize(width: 240, height: 410)
        let host = NSHostingView(rootView: SidebarIconTintFixture()
            .environment(\.appearsActive, appearsActive)
            .frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        ZforgeSnapshot.assert(host, appearance: appearance,
                              named: "sidebar-\(appearsActive ? "active" : "inactive")-\(appearanceName)")
    }
}

/// Mirrors the sidebar structure: the Locations role is set once on its section, as in `BrowserSidebar`,
/// so the snapshot also proves that the section environment reaches its rows. Recents uses the production
/// `SidebarActionRow`; every name uses `sidebarLabelStyle`, so all of them turn gray together. Shared has
/// no rows without a mounted share, so its header is hidden, and Network closes Locations as in Finder.
private struct SidebarIconTintFixture: View {
    var body: some View {
        List {
            SidebarActionRow(title: "Recents", systemImage: "clock") {}
            Section("Favorites") {
                row("Desktop", "menubar.dock.rectangle")
                row("Downloads", "arrow.down.circle", selected: true)
            }
            Section("Locations") {
                row("felipe", "house")
                row("Macintosh HD", "internaldrive")
                row("Ventoy", "externaldrive", selected: true)
                row("Network", "network")
            }
            .environment(\.sidebarIconTint, .neutral)
            Section("Tags") {
                Label { Text("Blue").sidebarLabelStyle() } icon: { SidebarTagDot(colorIndex: 4) }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ name: String, _ symbol: String, selected: Bool = false) -> some View {
        Label {
            Text(name).sidebarLabelStyle().fontWeight(selected ? .semibold : .regular)  // as `destinationRow`
        } icon: {
            Image(systemName: symbol)
                .resizable().scaledToFit().frame(width: 16, height: 16)
                .sidebarIconStyle()
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(selected ? Color(nsColor: .unemphasizedSelectedContentBackgroundColor) : .clear)
                .padding(.horizontal, 10)
        )
    }
}
