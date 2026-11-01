import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// Lays out the real browser window offscreen (never ordered front), so the
/// responsive toolbar and the sidebar limit are checked without XCUITest.
@Suite("Browser window layout")
@MainActor
struct BrowserWindowLayoutTests {
    @Test("Each toolbar stage presents its controls in the real window", arguments: [
        (650.0, ["toolbar-overflow-menu-unified"], false),
        (720.0, ["view-mode-selector-compact-actions", "toolbar-overflow-menu-compact-actions", "toolbar-search"], false),
        (860.0, ["view-mode-selector-compact-archive", "archive-contextual-action-compact",
                 "toolbar-overflow-menu-compact-archive", "toolbar-search"], false),
        (1_100.0, ["view-mode-selector-expanded", "toolbar-search"], true)
    ])
    func toolbarStages(width: Double, primaryItemIDs: [String], showsSegmentedSelector: Bool) async throws {
        let host = try await BrowserWindowHost(width: CGFloat(width))
        defer { host.close() }

        let items = host.window.toolbar?.items ?? []
        let namedItems = items.map(\.itemIdentifier.rawValue).filter { identifier in
            UUID(uuidString: identifier) == nil && !identifier.hasPrefix("com.apple.")
                && identifier != NSToolbarItem.Identifier.space.rawValue
        }
        #expect(namedItems == primaryItemIDs, "Toolbar at \(width) points")
        // The search item trails the toolbar in its own capsule, after a fixed space.
        if primaryItemIDs.last == "toolbar-search", items.count >= 2 {
            #expect(items.last?.itemIdentifier.rawValue == "toolbar-search")
            #expect(items[items.count - 2].itemIdentifier == .space)
        }

        // The segmented selector shows each mode as a segment; compact stages
        // replace it with one menu button, so no segment remains visible.
        let segmentedControls = items.compactMap(\.view).flatMap { $0.descendants(of: NSSegmentedControl.self) }
        if showsSegmentedSelector {
            #expect(segmentedControls.map(\.segmentCount) == [BrowserViewMode.allCases.count])
        } else {
            #expect(segmentedControls.isEmpty, "Toolbar at \(width) points shows the segmented view selector")
        }
    }

    @Test("Below 678 points the search field appears in the toolbar only while a search is in use")
    func unifiedStageSearchField() async throws {
        let host = try await BrowserWindowHost(width: 650)
        defer { host.close() }
        func identifiers() -> [String] { (host.window.toolbar?.items ?? []).map(\.itemIdentifier.rawValue) }
        #expect(!identifiers().contains("toolbar-search"))
        host.state.beginSearch()
        try await host.waitUntil { identifiers().last == "toolbar-search" }
        host.state.dismissSearchFieldIfIdle()
        try await host.waitUntil { !identifiers().contains("toolbar-search") }
    }

    /// Toolbar items are hosted outside the window's SwiftUI focus system, so this checks the
    /// AppKit first responder of the real window rather than any SwiftUI focus value.
    @Test("Find gives the toolbar field keyboard focus; typing searches, Return submits and Escape collapses it")
    func findFocusesToolbarSearchField() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        func contentHasFocus() -> Bool {
            guard let responder = host.window.firstResponder as? NSView, let content = host.window.contentView else { return false }
            return responder.isDescendant(of: content) && !(responder is NSText)
        }
        try await host.waitUntil(contentHasFocus)
        let contentResponder = host.window.firstResponder
        func searchFieldEditor() -> NSTextView? {
            guard let editor = host.window.firstResponder as? NSTextView,
                  (editor.delegate as? NSTextField)?.accessibilityIdentifier() == "toolbar-search-field" else { return nil }
            return editor
        }

        host.state.beginSearch()
        try await host.waitUntil { searchFieldEditor() != nil }
        #expect(host.state.searchFieldHasFocus, "The field reports its focus so content focus and menu keys leave it alone")

        let editor = try #require(searchFieldEditor())
        editor.insertText("Another", replacementRange: editor.selectedRange())
        #expect(host.state.searchText == "Another")
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        try await host.waitUntil { host.state.location == .recents && host.state.items.map(\.name) == ["Another.txt"] }
        #expect(searchFieldEditor() != nil, "Return keeps the focus in the field")

        // ⌘F while the field already has the focus keeps it there.
        host.state.beginSearch()
        try await host.waitUntil { searchFieldEditor() != nil }

        editor.doCommand(by: #selector(NSResponder.cancelOperation(_:)))
        try await host.waitUntil { !host.state.isSearchPresented && host.state.items.map(\.name) == ["Welcome.txt", "Sample.zip", "Another.txt"] }
        #expect(host.state.searchText.isEmpty)
        try await host.waitUntil { searchFieldEditor() == nil && !host.state.searchFieldHasFocus }
        // The keyboard focus returns to the browser content, so the arrow keys move the selection again.
        try await host.waitUntil { contentHasFocus() && host.window.firstResponder === contentResponder }
    }

    @Test("Deleting the toolbar field's text shows Recents again in every mode", arguments: BrowserViewMode.allCases)
    func deletingSearchTextRestoresRecents(mode: BrowserViewMode) async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        host.state.viewMode = mode
        let recents = ["Welcome.txt", "Sample.zip", "Another.txt"]
        try await host.waitUntil { host.state.items.map(\.name) == recents }
        host.state.beginSearch()
        try await host.waitUntil {
            ((host.window.firstResponder as? NSTextView)?.delegate as? NSTextField)?.accessibilityIdentifier() == "toolbar-search-field"
        }
        let editor = try #require(host.window.firstResponder as? NSTextView)
        editor.insertText("Another", replacementRange: editor.selectedRange())
        try await host.waitUntil { host.state.fileSearch != nil && host.state.items.map(\.name) == ["Another.txt"] }

        editor.selectAll(nil)
        editor.deleteBackward(nil)
        try await host.waitUntil { host.state.fileSearch == nil && !host.state.isLoading }
        #expect(host.state.items.map(\.name) == recents, "Recents in \(mode)")
        #expect(host.state.title == "Recents")
        #expect(host.state.isSearchPresented, "The emptied field stays open while it has focus")
    }

    @Test("Moving the focus away from an empty toolbar field collapses it")
    func emptySearchFieldCollapsesOnFocusLoss() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        host.state.beginSearch()
        try await host.waitUntil {
            ((host.window.firstResponder as? NSTextView)?.delegate as? NSTextField)?.accessibilityIdentifier() == "toolbar-search-field"
        }
        host.window.makeFirstResponder(nil)
        try await host.waitUntil { !host.state.isSearchPresented && !host.state.searchFieldHasFocus }
    }

    @Test("The sidebar cannot consume the content's last 360 points")
    func sidebarLeavesMinimumContentWidth() async throws {
        let host = try await BrowserWindowHost(width: 900)
        defer { host.close() }
        let splitViewController = try #require(host.window.contentView?.descendants(of: NSSplitView.self)
            .compactMap { $0.delegate as? NSSplitViewController }.first)
        let sidebarItem = try #require(splitViewController.splitViewItems.first { $0.behavior == .sidebar })
        try await host.waitUntil { sidebarItem.maximumThickness == 900 - BrowserSidebarLayout.minimumDetailWidth }

        // Drag the divider toward the window's far right edge.
        splitViewController.splitView.setPosition(900 * 0.95, ofDividerAt: 0)
        splitViewController.splitView.layoutSubtreeIfNeeded()

        #expect(sidebarItem.viewController.view.frame.width == 540)
        #expect(splitViewController.splitViewItems.last?.viewController.view.frame.width ?? 0 >= 360)
    }

    @Test("A fixture window opens in Recents with the fixture files and no folders")
    func fixtureLaunchListing() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        #expect(host.state.location == .recents)
        #expect(host.window.title == "Recents")
        // Recents lists files only, so the recent "Fixture Folder" is not shown.
        #expect(host.state.items.map(\.name) == ["Welcome.txt", "Sample.zip", "Another.txt"])
    }
}

@Suite("Toolbar overflow menus")
@MainActor
struct ToolbarOverflowMenuTests {
    @Test("Each compact stage's menu offers the controls the toolbar moved into it", arguments: [
        (650.0, ["View", "Search", "Compress Selected", "Share", "Open", "Quick Look", "Get Info", "Edit Tags", "Rename", "Duplicate"],
         [String]()),
        (720.0, ["Compress Selected", "Share", "Open", "Quick Look", "Get Info"], ["View", "Search"]),
        (860.0, ["Share", "Open", "Quick Look", "Get Info", "Edit Tags", "Rename", "Duplicate"],
         ["View", "Search", "Compress Selected"])
    ])
    func overflowContents(width: Double, present: [String], absent: [String]) async throws {
        let fixture = try BrowserFixture()
        defer { fixture.close() }
        await fixture.state.start()
        #expect(fixture.state.selectedItems.isEmpty)

        let titles = makeMenu(for: CGFloat(width), state: fixture.state).items.map(\.title)
        for title in present {
            #expect(titles.contains(title), "Missing \(title) from the toolbar menu at \(width) points: \(titles)")
        }
        for title in absent {
            #expect(!titles.contains(title), "Unexpected \(title) in the toolbar menu at \(width) points")
        }
    }

    @Test("The unified menu's View submenu switches to every mode", arguments: BrowserViewMode.allCases)
    func viewSubmenu(target: BrowserViewMode) async throws {
        let fixture = try BrowserFixture()
        defer { fixture.close() }
        let initial: BrowserViewMode = target == .icons ? .gallery : .icons
        fixture.state.viewMode = initial

        let menu = makeMenu(for: 650, state: fixture.state)
        let viewItem = try #require(menu.items.first { $0.title == "View" })
        let submenu = try #require(viewItem.submenu)
        #expect(submenu.items.map(\.title) == ["Icons", "List", "Columns", "Gallery"])
        #expect(submenu.items.filter { $0.state == .on }.map(\.title) == [initial.title(locale: Locale(identifier: "en"))])

        let index = try #require(BrowserViewMode.allCases.firstIndex(of: target))
        submenu.performActionForItem(at: index)
        #expect(fixture.state.viewMode == target)
    }

    private func makeMenu(for width: CGFloat, state: FileBrowserState) -> NSMenu {
        let contents = BrowserToolbarLayout.stage(for: width).overflowMenuContents
        return BrowserActionsMenu.make(
            state: state,
            includesViewSelector: contents.includesViewSelector,
            includesArchiveAction: contents.includesArchiveAction,
            includesShareAction: contents.includesShareAction,
            includesSearchAction: contents.includesSearchAction,
            showToast: { _ in }
        )
    }
}

@Suite("Zoom steps")
@MainActor
struct ZoomStepTests {
    @Test("Zoom shortcuts step by ten percent from Actual Size")
    func zoomSteps() throws {
        let suite = "ZforgeZoomSteps-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.zoomIn()
        preferences.resetZoom()
        #expect(preferences.scale == 1)
        preferences.zoomIn()
        #expect(preferences.scale == 1.1)
        preferences.zoomOut()
        #expect(preferences.scale == 1)
    }
}

/// A fixture browser with isolated preferences in English.
@MainActor
private final class BrowserFixture {
    let state: FileBrowserState
    private let suite = "ZforgeWindowLayout-\(UUID().uuidString)"

    init() throws {
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        state = FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            recentItems: UIFixtureRecentItemsService(),
            taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine(),
            // As with `--ui-fixtures`: the toolbar search lists fixture names, never Spotlight results.
            searcher: UIFixtureSearchService()
        )
    }

    func close() {
        state.close()
        UserDefaults.standard.removePersistentDomain(forName: suite)
    }
}

/// The real `ContentView` in a titled window of the requested content width.
@MainActor
private final class BrowserWindowHost {
    let window: NSWindow
    private let fixture: BrowserFixture

    var state: FileBrowserState { fixture.state }

    init(width: CGFloat) async throws {
        fixture = try BrowserFixture()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: ContentView(browser: fixture.state))
        window.setContentSize(NSSize(width: width, height: 600))
        // SwiftUI installs the toolbar after its first update pass.
        try await waitUntil { [window] in window.toolbar?.items.isEmpty == false }
    }

    /// Lays out and yields to SwiftUI until the condition holds, failing after a bounded number of passes.
    func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        for _ in 0..<200 {
            window.contentView?.layoutSubtreeIfNeeded()
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("The offscreen browser window did not reach the expected state", sourceLocation: sourceLocation)
        throw CancellationError()
    }

    func close() {
        window.close()
        window.contentViewController = nil
        fixture.close()
    }
}

private extension NSView {
    func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { subview in [subview as? T].compactMap { $0 } + subview.descendants(of: type) }
    }
}
