import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// The Keyboard Shortcuts window hosted as the app hosts it (a titled window with a hosting
/// controller, which is the only way SwiftUI installs the window toolbar), measured against the
/// browser window and the Settings window (ZF-59 after ZF-62).
@MainActor
final class ShortcutsWindowFixture {
    static let size = CGSize(width: KeyboardShortcutsLayout.defaultWidth, height: KeyboardShortcutsLayout.defaultHeight)
    let suite = "ZforgeTestSuite.ShortcutsWindow-\(UUID().uuidString)"
    let defaults: UserDefaults
    let window: NSWindow
    let host: NSView

    init(category: KeyboardShortcutCategory = .all) throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size),
                          styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: KeyboardShortcutsView(preferences: preferences, category: category))
        window.setContentSize(Self.size)
        let host = try #require(window.contentView)
        host.layoutSubtreeIfNeeded()
        self.host = host
    }

    func close() {
        window.close()
        window.contentViewController = nil
        defaults.removeTestSuite(named: suite)
    }

    func waitUntil(_ description: String, _ condition: () -> Bool) async throws {
        for _ in 0..<400 where !condition() {
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition(), "Timed out waiting until \(description)")
        if !condition() { throw CancellationError() }
    }
}

@Suite("Keyboard shortcuts window metrics (ZF-59)")
@MainActor
struct KeyboardShortcutsWindowTests {
    /// The same measurements as Settings' `titleBarMatchesTheBrowserToolbar`: the browser window's
    /// toolbar is 52 pt with a 15 pt semibold title in the label colour.
    @Test("The title bar is the browser window's 52 pt toolbar with the category in its title style")
    func titleBarMatchesTheBrowserToolbar() async throws {
        let fixture = try ShortcutsWindowFixture()
        defer { fixture.close() }
        let window = fixture.window
        func titlebar() -> NSView? { window.contentView?.superview?.settingsDescendants(named: "NSTitlebarContainerView").first }
        func title() -> NSTextField? {
            window.contentView?.superview?.settingsDescendants(of: NSTextField.self).first { $0.stringValue == "All Shortcuts" }
        }
        func sidebarWidth() -> CGFloat? {
            window.contentView?.superview?.settingsDescendants(named: "NSTitlebarBackgroundView").map(\.frame).filter { $0.minX == 0 }.map(\.width).first
        }
        try await fixture.waitUntil("the toolbar title appears beside a 206 pt sidebar") {
            title() != nil && window.toolbar != nil && sidebarWidth() == KeyboardShortcutsLayout.sidebarWidth
        }
        let bar = try #require(titlebar())
        #expect(abs(bar.frame.height - 52) < 0.5, "Title bar height \(bar.frame.height)")
        let label = try #require(title())
        let font = try #require(label.font)
        #expect(font.pointSize == 15, "Title size \(font.pointSize)")
        #expect(font.fontName.contains("Semibold"), "Title font \(font.fontName)")
        #expect(label.textColor == .labelColor)
        let titleX = label.convert(label.bounds, to: nil).minX
        let expectedX = KeyboardShortcutsLayout.sidebarWidth + SettingsMetrics.margin
        #expect(abs(titleX - expectedX) <= 3, "Title starts at \(titleX), content at \(expectedX)")
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            guard let button = window.standardWindowButton(kind) else { continue }
            let centre = button.convert(button.bounds, to: bar).midY
            #expect(abs(centre - bar.bounds.midY) <= 1, "\(kind) centre \(centre) in a bar of \(bar.bounds.height)")
        }
    }

    @Test("The title follows the selected category")
    func titleFollowsTheCategory() async throws {
        let fixture = try ShortcutsWindowFixture(category: .section("mouse"))
        defer { fixture.close() }
        try await fixture.waitUntil("the window is titled Mouse and Drag") { fixture.window.title == "Mouse and Drag" }
    }

    @Test("Sidebar rows are the Settings sidebar's uniform 28 pt rows")
    func sidebarRows() async throws {
        let fixture = try ShortcutsWindowFixture()
        defer { fixture.close() }
        let table = try #require(fixture.host.settingsDescendants(of: NSTableView.self).first)
        let categories = 1 + KeyboardShortcutCatalog.sections.count
        // The offscreen sidebar is narrower (D-75) until its width constraint applies; measure after.
        try await fixture.waitUntil("the rows appear in a 206 pt sidebar") {
            table.numberOfRows >= categories && abs(table.frame.width - KeyboardShortcutsLayout.sidebarWidth) <= 1
        }
        let heights = (0..<table.numberOfRows).map { table.rect(ofRow: $0).height }
        // One divider row between All Shortcuts and the sections; every other row is a category.
        #expect(table.numberOfRows == categories + 1, "Rows: \(heights)")
        let tall = heights.filter { abs($0 - SettingsLayout.sidebarRowHeight) <= 1 }
        #expect(tall.count == categories, "Category rows are \(SettingsLayout.sidebarRowHeight) pt: \(heights)")
        #expect(SettingsLayout.sidebarContentHeight + 8 == SettingsLayout.sidebarRowHeight)
    }

    private func fittingHeight(_ view: some View, width: CGFloat = 574) -> CGFloat {
        let host = NSHostingView(rootView: view.frame(width: width))
        return host.fittingSize.height
    }

    private func section(items: Int) -> KeyboardShortcutSection {
        KeyboardShortcutSection(
            id: "files", title: "Files and Items", systemImage: "doc",
            items: (0..<items).map { KeyboardShortcutItem(id: "i\($0)", action: "Copy", input: "⌘C") }
        )
    }

    @Test("Rows are Settings rows: 36 pt, a 1 pt hairline between neighbours, no group header in a single category")
    func rowMetrics() {
        let three = fittingHeight(KeyboardShortcutGroup(section: section(items: 3), showsHeader: false))
        #expect(abs(three - (3 * SettingsMetrics.rowMinHeight + 2)) <= 1, "Three rows measure \(three)")
        let one = fittingHeight(KeyboardShortcutGroup(section: section(items: 1), showsHeader: false))
        #expect(abs(one - SettingsMetrics.rowMinHeight) <= 1, "One row measures \(one)")
    }

    @Test("A group header is Settings' 13 pt semibold header, 8 pt above the rows")
    func headerMetrics() {
        let without = fittingHeight(KeyboardShortcutGroup(section: section(items: 2), showsHeader: false))
        let with = fittingHeight(KeyboardShortcutGroup(section: section(items: 2), showsHeader: true))
        let header = with - without - SettingsMetrics.headerGap
        let lineHeight = NSFont.systemFont(ofSize: 13, weight: .semibold).boundingRectForFont.height
        #expect(header > 10 && header <= lineHeight + 2, "Header text measures \(header) pt (line \(lineHeight))")
    }

    @Test("Category tiles use system colours, lighter only at the top, each category its own")
    func tileColors() throws {
        let categories: [KeyboardShortcutCategory] = [.all] + KeyboardShortcutCatalog.sections.map { .section($0.id) }
        func components(_ color: Color) throws -> [CGFloat] {
            var result: [CGFloat] = []
            try #require(NSAppearance(named: .aqua)).performAsCurrentDrawingAppearance {
                let resolved = NSColor(color).usingColorSpace(.sRGB)
                result = [resolved?.redComponent, resolved?.greenComponent, resolved?.blueComponent].compactMap { $0 }
            }
            return result
        }
        #expect(KeyboardShortcutCategory.section("files").tileColor == .blue)
        #expect(KeyboardShortcutCategory.section("mouse").tileColor == .red)
        var bottoms: Set<[Int]> = []
        for category in categories {
            let (top, bottom) = category.tileColors
            #expect(try components(top).reduce(0, +) > components(bottom).reduce(0, +), "\(category.id) is lighter at the top")
            bottoms.insert(try components(bottom).map { Int($0 * 255) })
        }
        #expect(bottoms.count == categories.count, "Every category has its own colour")
    }
}
