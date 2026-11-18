import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// Lays out the real browser window offscreen (never ordered front), so the
/// responsive toolbar and the sidebar limit are checked without XCUITest.
/// Serialized (D-71): each case lays out a whole window synchronously on the main actor;
/// dozens of them in parallel held the shared main actor for long stretches.
@Suite("Browser window layout", .serialized)
@MainActor
struct BrowserWindowLayoutTests {
    @Test("Each toolbar stage presents its controls in the real window", arguments: [
        (650.0, ["toolbar-overflow-menu"], false),
        (720.0, ["view-mode-selector-compact", "toolbar-overflow-menu", "toolbar-search"], false),
        (860.0, ["view-mode-selector-compact", "archive-contextual-action-compact",
                 "toolbar-overflow-menu", "toolbar-search"], false),
        (1_100.0, ["view-mode-selector-expanded", "toolbar-search"], true)
    ])
    func toolbarStages(width: Double, primaryItemIDs: [String], showsSegmentedSelector: Bool) async throws {
        let host = try await BrowserWindowHost(width: CGFloat(width))
        defer { host.close() }

        // Every stage keeps all the items and hides those it does not present (D-110).
        let items = (host.window.toolbar?.items ?? []).filter { !$0.isHidden }
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

    /// D-110: replacing the toolbar's items at a stage switch made `NSToolbar` and SwiftUI rebuild
    /// the toolbar, which stalled live resizing for 100–550 ms. A switch only hides and shows items.
    @Test("Resizing across every stage keeps the same toolbar items, only hidden or shown")
    func stageSwitchesKeepToolbarItems() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        let original = host.window.toolbar?.items ?? []
        let presented: [Double: [String]] = [
            650: ["toolbar-overflow-menu"],
            720: ["view-mode-selector-compact", "toolbar-overflow-menu", "toolbar-search"],
            860: ["view-mode-selector-compact", "archive-contextual-action-compact", "toolbar-overflow-menu", "toolbar-search"],
            1_100: ["view-mode-selector-expanded", "toolbar-search"]
        ]
        func named(_ items: [NSToolbarItem]) -> [String] {
            items.filter { !$0.isHidden }.map(\.itemIdentifier.rawValue).filter { identifier in
                UUID(uuidString: identifier) == nil && !identifier.hasPrefix("com.apple.")
                    && identifier != NSToolbarItem.Identifier.space.rawValue
            }
        }
        for width in [860.0, 720, 650, 720, 860, 1_100] {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await host.waitUntil { named(host.window.toolbar?.items ?? []) == presented[width] }
            let items = host.window.toolbar?.items ?? []
            #expect(items.count == original.count, "Toolbar items at \(width) points")
            #expect(zip(items, original).allSatisfy { $0 === $1 }, "Toolbar item instances replaced at \(width) points")
        }
    }

    @Test("Below 678 points the search field appears in the toolbar only while a search is in use")
    func unifiedStageSearchField() async throws {
        let host = try await BrowserWindowHost(width: 650)
        defer { host.close() }
        func identifiers() -> [String] {
            (host.window.toolbar?.items ?? []).filter { !$0.isHidden }.map(\.itemIdentifier.rawValue)
        }
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

    /// `NSToolbar` moves an item that does not fit into its own overflow menu, where a text
    /// field cannot be typed into. Opening the search must leave the field in the toolbar.
    @Test("At every supported width the opened search field is in the toolbar, whole, and takes typing",
          arguments: Array(stride(from: 640, through: 1_200, by: 20)))
    func searchFieldFitsAtEveryWidth(width: Int) async throws {
        let host = try await BrowserWindowHost(width: CGFloat(width))
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        host.state.beginSearch()
        func field() -> NSTextField? {
            host.window.toolbar?.items.first { $0.itemIdentifier.rawValue == "toolbar-search" }?.view?
                .descendants(of: NSTextField.self).first { $0.accessibilityIdentifier() == "toolbar-search-field" }
        }
        try await host.waitUntil {
            guard let field = field(), field.window === host.window,
                  let editor = host.window.firstResponder as? NSTextView else { return false }
            return editor.delegate === field
        }
        let searchField = try #require(field())
        let inWindow = searchField.convert(searchField.bounds, to: nil)
        let windowBounds = try #require(host.window.contentView?.superview?.bounds)
        #expect(windowBounds.contains(inWindow), "Field \(inWindow) inside the window at \(width) pt")
        // The 200 pt control is never narrowed: its text keeps well over 150 pt beside the magnifying glass.
        #expect(searchField.bounds.width >= 150, "Text width at \(width) pt: \(searchField.bounds.width) pt")
        let editor = try #require(host.window.firstResponder as? NSTextView)
        editor.insertText("Another", replacementRange: editor.selectedRange())
        #expect(host.state.searchText == "Another")
        // The longer “Searching …” title must not push the field out once the results show.
        try await host.waitUntil { host.state.fileSearch != nil && host.state.items.map(\.name) == ["Another.txt"] }
        try await host.waitUntil {
            guard let field = field(), field.window === host.window else { return false }
            return (host.window.firstResponder as? NSTextView)?.delegate === field
                && windowBounds.contains(field.convert(field.bounds, to: nil))
        }
        #expect(host.window.title == "Searching “Another”", "The window keeps its title for the Window menu")
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
        let suite = "ZforgeTestSuite.ZforgeZoomSteps-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
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
    private let suite = "ZforgeTestSuite.ZforgeWindowLayout-\(UUID().uuidString)"

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
        UserDefaults.standard.removeTestSuite(named: suite)
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
