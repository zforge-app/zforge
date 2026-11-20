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
        (650.0, ["toolbar-overflow-menu", "toolbar-search"], false),
        (720.0, ["view-mode-selector-compact", "toolbar-overflow-menu", "toolbar-search"], false),
        (860.0, ["view-mode-selector-compact", "archive-contextual-action-compact",
                 "toolbar-overflow-menu", "toolbar-search"], false),
        (1_100.0, ["view-mode-selector-expanded", "toolbar-search-field-item"], true)
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
        // The search item (button, or the field at rest where it fits, ZF-88) trails the
        // toolbar in its own capsule, after a fixed space.
        if let last = primaryItemIDs.last, last.hasPrefix("toolbar-search"), items.count >= 2 {
            #expect(items.last?.itemIdentifier.rawValue == last)
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
            650: ["toolbar-overflow-menu", "toolbar-search"],
            720: ["view-mode-selector-compact", "toolbar-overflow-menu", "toolbar-search"],
            860: ["view-mode-selector-compact", "archive-contextual-action-compact", "toolbar-overflow-menu", "toolbar-search"],
            1_100: ["view-mode-selector-expanded", "toolbar-search-field-item"]
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

    /// ZF-88 (user request 2026-11-19): the smallest stage keeps the search button beside the
    /// double-chevron menu while it fits (until then it always moved into that menu).
    @Test("Below 678 points the search button stays beside the menu, and the field replaces it during a search")
    func unifiedStageSearchField() async throws {
        let host = try await BrowserWindowHost(width: 650)
        defer { host.close() }
        func identifiers() -> [String] {
            (host.window.toolbar?.items ?? []).filter { !$0.isHidden }.map(\.itemIdentifier.rawValue)
        }
        try await host.waitUntil { identifiers().last == "toolbar-search" && !identifiers().contains("toolbar-search-field-item") }
        host.state.beginSearch()
        try await host.waitUntil { identifiers().last == "toolbar-search-field-item" && !identifiers().contains("toolbar-search") }
        host.state.dismissSearchFieldIfIdle()
        try await host.waitUntil { identifiers().last == "toolbar-search" && !identifiers().contains("toolbar-search-field-item") }
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
            host.window.toolbar?.items.first { $0.itemIdentifier.rawValue == "toolbar-search-field-item" && !$0.isHidden }?.view?
                .descendants(of: NSTextField.self).first { $0.accessibilityIdentifier() == "toolbar-search-field" }
        }
        try await host.waitUntil {
            guard let field = field(), field.window === host.window,
                  let editor = host.window.firstResponder as? NSTextView else { return false }
            return editor.delegate === field
        }
        let searchField = try #require(field())
        // Lay the title bar out as the next display would: an offscreen window has no display
        // cycle, and the field can take the focus before the toolbar re-tiles around it.
        host.window.contentView?.superview?.layoutSubtreeIfNeeded()
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

    /// ZF-88: with room to spare the search item is a field at rest, as in Finder, and it does
    /// not take the keyboard focus from the browser content when it appears.
    @Test("Wide windows show the search field at rest without taking the focus; narrower ones show the button")
    func searchFieldAtRestFollowsWidth() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        func visibleItem(_ identifier: String) -> NSView? {
            host.window.toolbar?.items.first { $0.itemIdentifier.rawValue == identifier && !$0.isHidden }?.view
        }
        func searchItemView() -> NSView? { visibleItem("toolbar-search") }
        func restField() -> NSTextField? {
            visibleItem("toolbar-search-field-item")?.descendants(of: NSTextField.self)
                .first { $0.accessibilityIdentifier() == "toolbar-search-field" }
        }
        func contentHasFocus() -> Bool {
            guard let responder = host.window.firstResponder as? NSView, let content = host.window.contentView else { return false }
            return responder.isDescendant(of: content) && !(responder is NSText)
        }

        try await host.waitUntil { restField()?.window === host.window && contentHasFocus() }
        #expect(searchItemView() == nil, "The button is hidden while the field shows")
        let contentResponder = host.window.firstResponder
        #expect(!host.state.isSearchPresented, "A field at rest is not a search in use")
        #expect(!host.state.searchFieldHasFocus)
        #expect(host.state.searchFieldFocusRequest == 0)
        let field = try #require(restField())
        #expect(field.bounds.width >= 150, "The field at rest has the open field's width: \(field.bounds.width) pt")
        #expect(field.placeholderString == "Search")

        // Narrower than 1,049 points (with this 180 pt sidebar) the field would not fit beside every
        // control: the button returns.
        for width in [1_048.0, 960, 860] {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await host.waitUntil { searchItemView() != nil && restField() == nil }
            #expect(host.window.firstResponder === contentResponder, "Focus kept at \(width) pt")
            #expect(!host.state.isSearchPresented)
        }
        host.window.setContentSize(NSSize(width: 1_049, height: 600))
        try await host.waitUntil { restField()?.window === host.window }
        #expect(host.window.firstResponder === contentResponder, "The field shown again does not take the focus")
        #expect(!host.state.isSearchPresented)
    }

    /// ZF-88 follow-up (user recording, 2026-11-19): the field was drawn over the action group
    /// (More's dots showed through “Search”) because its toolbar item kept the button's width.
    @Test("The search item's field fits its own toolbar item and overlaps no other control across widths and searches")
    func searchItemNeverOverlapsToolbarControls() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        func visibleFrames() -> [(id: String, frame: CGRect)] {
            (host.window.toolbar?.items ?? []).filter { !$0.isHidden }.compactMap { item in
                guard let view = item.view, view.window === host.window, !view.isHiddenOrHasHiddenAncestor else { return nil }
                return (item.itemIdentifier.rawValue, view.convert(view.bounds, to: nil))
            }
        }
        func searchField() -> NSTextField? {
            (host.window.toolbar?.items ?? []).filter { !$0.isHidden }.compactMap(\.view)
                .flatMap { $0.descendants(of: NSTextField.self) }
                .first { $0.accessibilityIdentifier() == "toolbar-search-field" && !$0.isHiddenOrHasHiddenAncestor }
        }
        func layoutIsSound() -> Bool {
            let frames = visibleFrames()
            for (index, first) in frames.enumerated() {
                for second in frames.dropFirst(index + 1) where first.frame.insetBy(dx: 1, dy: 1).intersects(second.frame) {
                    return false
                }
            }
            if let field = searchField() {
                let fieldFrame = field.convert(field.bounds, to: nil)
                guard frames.contains(where: { $0.frame.insetBy(dx: -1, dy: -1).contains(fieldFrame) }) else { return false }
                // The field has its own item, measured at the field's full width; the button's item is hidden.
                guard let item = frames.first(where: { $0.id == "toolbar-search-field-item" }),
                      item.frame.width >= BrowserToolbarSearchField.fieldWidth,
                      !frames.contains(where: { $0.id == "toolbar-search" }) else { return false }
            }
            return true
        }
        func check(_ label: String, expectsField: Bool) async throws {
            try await host.waitUntil { (searchField() != nil) == expectsField && layoutIsSound() }
            #expect(layoutIsSound(), "\(label): \(visibleFrames()) field \(searchField().map { $0.convert($0.bounds, to: nil) } as Any)")
        }

        try await check("1,100 pt at rest", expectsField: true)
        for (width, field) in [(1_048.0, false), (1_049.0, true), (960.0, false), (1_100.0, true), (860.0, false), (1_060.0, true)] {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await check("\(width) pt at rest", expectsField: field)
        }
        host.window.setContentSize(NSSize(width: 960, height: 600))
        try await check("960 pt", expectsField: false)
        host.state.beginSearch()
        try await check("960 pt searching", expectsField: true)
        await host.state.cancelSearch()
        try await check("960 pt after Escape", expectsField: false)
        host.window.setContentSize(NSSize(width: 1_100, height: 600))
        host.state.beginSearch()
        try await check("1,100 pt searching", expectsField: true)
        host.window.setContentSize(NSSize(width: 900, height: 600))
        try await check("900 pt searching", expectsField: true)
    }

    /// ZF-88 follow-up (user recording, 2026-11-19): with a sidebar wider than its minimum the field
    /// at rest sent the search and More into `NSToolbar`'s own overflow menu. The field shows only
    /// while every control of the expanded stage stays in the toolbar beside it.
    @Test("The field at rest never sends a control into NSToolbar's overflow and gives way exactly when it would")
    func searchFieldAtRestFollowsToolbarRoom() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        let toolbar = try ToolbarProbe(host: host)

        // The sidebar's width decides, not the window's alone: 869 pt from the sidebar's edge.
        for (position, field) in [(180.0, true), (220.0, true), (231.0, true), (232.0, false), (300.0, false), (200.0, true)] {
            try await toolbar.setSidebar(position)
            try await toolbar.settle("sidebar \(position) pt in a 1,100 pt window", fieldShown: field)
            if position == 231 {
                // Exactly at the limit: no spare room is left beside the title's minimum.
                #expect(toolbar.gap() == 172, "Room between the navigation group and the view selector: \(toolbar.gap())")
            }
        }
        try await toolbar.setSidebar(300)
        host.window.setContentSize(NSSize(width: 1_169, height: 600))
        try await toolbar.settle("1,169 pt with a 300 pt sidebar", fieldShown: true)
        host.window.setContentSize(NSSize(width: 1_168, height: 600))
        try await toolbar.settle("1,168 pt with a 300 pt sidebar", fieldShown: false)

        // With the sidebar collapsed the toolbar starts after the traffic lights.
        try await toolbar.collapseSidebar()
        host.window.setContentSize(NSSize(width: 957, height: 600))
        try await toolbar.settle("957 pt, sidebar collapsed", fieldShown: true)
        host.window.setContentSize(NSSize(width: 956, height: 600))
        try await toolbar.settle("956 pt, sidebar collapsed", fieldShown: false)
    }

    /// ZF-88 follow-up (user screenshots, 2026-11-19): the stages followed the window width as if the
    /// sidebar were at its 180 pt minimum, so with a wider sidebar `NSToolbar` replaced the search
    /// button (or More, or the search field) with its own double-chevron menu next to Zforge's.
    @Test("No stage sends a control into NSToolbar's own overflow, whatever the sidebar's width",
          arguments: [180.0, 224.0, 300.0, 0.0])
    func stagesNeverUseNativeOverflow(sidebar: Double) async throws {
        let host = try await BrowserWindowHost(width: 1_300)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        let toolbar = try ToolbarProbe(host: host)
        if sidebar == 0 { try await toolbar.collapseSidebar() } else { try await toolbar.setSidebar(sidebar) }
        let label = sidebar == 0 ? "collapsed sidebar" : "\(Int(sidebar)) pt sidebar"
        for width in stride(from: 1_300.0, through: 640, by: -6) {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await toolbar.settle("\(Int(width)) pt, \(label)")
        }
        // An open search field keeps every control in the toolbar too.
        host.state.beginSearch()
        for width in stride(from: 640.0, through: 1_300, by: 12) {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await toolbar.settle("\(Int(width)) pt searching, \(label)", fieldShown: true)
        }
    }

    /// ZF-88 regression found by the stage sweep: when ⌘F switched the stage, `NSToolbar` moved the
    /// field's glass capsule, which ended its editing, and the empty search closed at once. Seen
    /// after resizing down with a collapsed sidebar that had been wide.
    @Test("Find keeps the empty search open and focused when the toolbar re-tiles around the field")
    func findSurvivesToolbarRetiling() async throws {
        let host = try await BrowserWindowHost(width: 1_300)
        defer { host.close() }
        try await host.waitUntil { !host.state.items.isEmpty }
        let toolbar = try ToolbarProbe(host: host)
        try await toolbar.setSidebar(300)
        try await toolbar.collapseSidebar()
        for width in stride(from: 1_300.0, through: 640, by: -6) {
            host.window.setContentSize(NSSize(width: width, height: 600))
            try await toolbar.settle("\(Int(width)) pt")
        }
        func fieldIsFirstResponder() -> Bool {
            ((host.window.firstResponder as? NSTextView)?.delegate as? NSTextField)?.accessibilityIdentifier() == "toolbar-search-field"
        }
        host.state.beginSearch()
        try await toolbar.settle("640 pt after Find", fieldShown: true)
        try await host.waitUntil { fieldIsFirstResponder() }
        // Several more passes: the search stays open and the field keeps the keyboard focus.
        for _ in 0..<5 {
            host.window.contentView?.superview?.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(host.state.isSearchPresented)
        #expect(host.state.searchFieldHasFocus)
        #expect(fieldIsFirstResponder())
    }

    /// ZF-89 (user recording 2026-11-19): in Columns the first column's rows start under the
    /// sidebar divider's hit area, so pressing there with the resize pointer and dragging picked up
    /// the file under it instead of resizing the sidebar.
    @Test("A press on the sidebar divider never picks up the item under it", arguments: BrowserViewMode.allCases)
    func dividerPressStartsNoItemDrag(mode: BrowserViewMode) async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        host.state.viewMode = mode
        try await host.waitUntil { !host.state.items.isEmpty }
        let split = try #require(host.window.contentView?.descendants(of: NSSplitView.self).first)
        let dividerX = split.arrangedSubviews[0].frame.maxX
        func sources() -> [ArchiveDragSourceView] {
            (host.window.contentView?.descendants(of: ArchiveDragSourceView.self) ?? [])
                .filter { $0.item != nil && !$0.isHiddenOrHasHiddenAncestor }
        }
        try await host.waitUntil { !sources().isEmpty }
        // The item drawn nearest the divider.
        let source = try #require(sources().min { $0.convert($0.bounds, to: nil).minX < $1.convert($1.bounds, to: nil).minX })
        let frame = source.convert(source.bounds, to: nil)
        let y = frame.midY
        // Every point the window routes to the split view (its divider) refuses the item drag.
        let frameView = try #require(host.window.contentView?.superview)
        var dividerPoints = 0
        for x in stride(from: dividerX - 6, through: dividerX + 6, by: 0.5) {
            let point = NSPoint(x: x, y: y)
            guard frameView.hitTest(point) is NSSplitView else { continue }
            dividerPoints += 1
            #expect(!source.startsDrag(at: point), "\(mode): a press at x = \(x) on the divider starts an item drag")
        }
        #expect(dividerPoints > 0, "The divider takes presses near x = \(dividerX)")
        if mode == .columns {
            #expect(frame.minX <= dividerX + 2, "Columns: the first item reaches the divider (\(frame.minX)), the case the user hit")
        }
        // Away from the divider the item still drags.
        #expect(source.startsDrag(at: NSPoint(x: frame.midX, y: y)), "\(mode): the item drags from its middle")
    }

    /// ZF-90 (user screenshot 2026-11-19): the drag image of a Columns row showed grey strips of the
    /// column (and its separator lines) on both sides of the blue selection, and grey rounded corners;
    /// Icons carried a grey square around the tile and the name, Gallery grey tile corners.
    @Test("An item's drag image is its own shape, transparent around it", arguments: BrowserViewMode.allCases)
    func rowDragImageIsTheSelectionShape(mode: BrowserViewMode) async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        host.state.viewMode = mode
        try await host.waitUntil { !host.state.items.isEmpty }
        let item = try #require(host.state.items.first)
        host.state.select(item)
        func source() -> ArchiveDragSourceView? {
            host.window.contentView?.descendants(of: ArchiveDragSourceView.self)
                .first { $0.item?.id == item.id && !$0.isHiddenOrHasHiddenAncestor && !$0.visibleRect.isEmpty }
        }
        try await host.waitUntil { source() != nil }
        let view = try #require(source())
        let contentView = try #require(host.window.contentView)
        let (frame, image) = try #require(view.dragImage(in: contentView))
        let cgImage = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        Attachment.record(try #require(bitmap.representation(using: .png, properties: [:])), named: "drag-\(mode.rawValue).png")
        let scaleX = CGFloat(bitmap.pixelsWide) / frame.width, scaleY = CGFloat(bitmap.pixelsHigh) / frame.height
        func alpha(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
            bitmap.colorAt(x: Int(x * scaleX), y: Int(y * scaleY))?.alphaComponent ?? -1
        }
        let inset = mode == .columns ? BrowserMetrics.horizontalInset * host.state.preferences.scale : 0
        // Outside the shape: the column margin (Columns) and the rounded corners are transparent.
        #expect(alpha(0.5, 0.5) == 0, "\(mode): top-left corner")
        #expect(alpha(frame.width - 0.5, frame.height - 0.5) == 0, "\(mode): bottom-right corner")
        if inset > 0 {
            #expect(alpha(inset / 2, frame.height / 2) == 0, "Columns: left margin")
            #expect(alpha(frame.width - inset / 2, frame.height / 2) == 0, "Columns: right margin")
        }
        // Inside it the item is drawn opaque: the row's selection, or Icons' tile and name capsule.
        if mode == .icons {
            #expect(alpha(frame.width / 2, frame.height * 0.3) == 1, "Icons: the icon's tile")
            #expect(alpha(frame.width / 2, frame.height - 8 * host.state.preferences.scale - 6) == 1, "Icons: the name's capsule")
            #expect(alpha(4, frame.height * 0.3) == 0, "Icons: beside the tile")
        } else {
            #expect(alpha(inset + 20, frame.height / 2) == 1, "\(mode): inside the selection")
            #expect(alpha(frame.width - inset - 20, frame.height / 2) == 1, "\(mode): inside the selection, trailing")
        }
    }

    @Test("Clicking into the field at rest puts it in use; Escape returns it to rest and the focus to the content")
    func searchFieldAtRestTakesClicksAndEscape() async throws {
        let host = try await BrowserWindowHost(width: 1_100)
        defer { host.close() }
        let recents = ["Welcome.txt", "Sample.zip", "Another.txt"]
        try await host.waitUntil { host.state.items.map(\.name) == recents }
        func restField() -> NSTextField? {
            host.window.toolbar?.items.first { $0.itemIdentifier.rawValue == "toolbar-search-field-item" && !$0.isHidden }?.view?
                .descendants(of: NSTextField.self).first { $0.accessibilityIdentifier() == "toolbar-search-field" }
        }
        func contentHasFocus() -> Bool {
            guard let responder = host.window.firstResponder as? NSView, let content = host.window.contentView else { return false }
            return responder.isDescendant(of: content) && !(responder is NSText)
        }
        try await host.waitUntil { restField()?.window === host.window && contentHasFocus() }
        let contentResponder = host.window.firstResponder
        let field = try #require(restField())

        // A click gives an NSTextField the first responder through AppKit itself.
        #expect(host.window.makeFirstResponder(field))
        try await host.waitUntil { host.state.isSearchPresented && host.state.searchFieldHasFocus }
        let editor = try #require(host.window.firstResponder as? NSTextView)
        editor.insertText("Another", replacementRange: editor.selectedRange())
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        try await host.waitUntil { host.state.fileSearch != nil && host.state.items.map(\.name) == ["Another.txt"] }

        editor.doCommand(by: #selector(NSResponder.cancelOperation(_:)))
        try await host.waitUntil { !host.state.isSearchPresented && host.state.items.map(\.name) == recents }
        #expect(host.state.searchText.isEmpty)
        try await host.waitUntil { contentHasFocus() && host.window.firstResponder === contentResponder }
        #expect(restField() === field, "The field stays shown at rest, the same view, without a collapse")
        #expect(field.stringValue.isEmpty)
    }

    @Test("The sidebar cannot consume the content's last 400 points")
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

        #expect(sidebarItem.viewController.view.frame.width == 500)
        #expect(splitViewController.splitViewItems.last?.viewController.view.frame.width ?? 0 >= 400)
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
        (650.0, ["View", "Compress Selected", "Share", "Open", "Quick Look", "Get Info", "Edit Tags", "Rename", "Duplicate"],
         ["Search"]),
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
        let contents = BrowserToolbarLayout.WidthClass(windowWidth: width)
            .overflowMenuContents(for: BrowserToolbarLayout.stage(for: width))
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
/// Reads the real window's toolbar: which items `NSToolbar` moved into its own overflow menu and
/// the room left between the navigation group and the next item (ZF-88).
private struct ToolbarProbe {
    let host: BrowserWindowHost
    let split: NSSplitView
    let controller: NSSplitViewController

    init(host: BrowserWindowHost) throws {
        self.host = host
        split = try #require(host.window.contentView?.descendants(of: NSSplitView.self).first)
        controller = try #require(split.delegate as? NSSplitViewController)
    }

    var sidebarWidth: CGFloat? {
        guard let item = controller.splitViewItems.first(where: { $0.behavior == .sidebar }), !item.isCollapsed else { return nil }
        return item.viewController.view.frame.width
    }

    func setSidebar(_ width: CGFloat) async throws {
        split.setPosition(width, ofDividerAt: 0)
        try await host.waitUntil { sidebarWidth.map { abs($0 - width) < 0.5 } == true }
    }

    /// Collapses the sidebar and waits for its animation to end (the sidebar is then hidden).
    func collapseSidebar() async throws {
        controller.toggleSidebar(nil)
        try await host.waitUntil {
            sidebarWidth == nil && controller.splitViewItems.first?.viewController.view.isHiddenOrHasHiddenAncestor == true
        }
    }

    func fieldShown() -> Bool {
        host.window.toolbar?.items.contains { $0.itemIdentifier.rawValue == "toolbar-search-field-item" && !$0.isHidden } == true
    }

    /// Presented items (not hidden by a stage) that `NSToolbar` moved into its own overflow menu.
    func overflowed() -> [String] {
        (host.window.toolbar?.items ?? []).filter { !$0.isHidden && $0.view != nil && !$0.isVisible }
            .map(\.itemIdentifier.rawValue)
    }

    func gap() -> CGFloat {
        let frames = (host.window.toolbar?.items ?? []).filter { !$0.isHidden && $0.isVisible }
            .compactMap { $0.view.map { $0.convert($0.bounds, to: nil) } }.sorted { $0.minX < $1.minX }
        return (frames.dropFirst().first?.minX ?? 0) - (frames.first?.maxX ?? 0)
    }

    /// The named items the stage for the current window and sidebar presents.
    func expectedItems() -> [String] {
        let widthClass = BrowserToolbarLayout.WidthClass(windowWidth: host.window.frame.width, sidebarTrailingEdge: sidebarWidth)
        let searching = host.state.isSearchPresented
        let search = searching || widthClass.showsSearchFieldAtRest ? "toolbar-search-field-item" : "toolbar-search"
        switch widthClass.stage(searchFieldExpanded: searching) {
        case .expanded: return ["view-mode-selector-expanded", search]
        case .compactWithArchiveAction:
            return ["view-mode-selector-compact", "archive-contextual-action-compact", "toolbar-overflow-menu", search]
        case .compactWithActionsOverflow: return ["view-mode-selector-compact", "toolbar-overflow-menu", search]
        case .unifiedOverflow:
            return ["toolbar-overflow-menu"] + (searching || widthClass.keepsSearchButtonInSmallestStage ? [search] : [])
        }
    }

    func presentedItems() -> [String] {
        (host.window.toolbar?.items ?? []).filter { !$0.isHidden }.map(\.itemIdentifier.rawValue).filter { identifier in
            UUID(uuidString: identifier) == nil && !identifier.hasPrefix("com.apple.")
                && identifier != NSToolbarItem.Identifier.space.rawValue
        }
    }

    /// Waits until the toolbar presents the stage for the current window and sidebar, lays the
    /// title bar out, then checks that nothing is in `NSToolbar`'s overflow menu.
    func settle(_ label: String, fieldShown expectsField: Bool? = nil) async throws {
        try await host.waitUntil { presentedItems() == expectedItems() }
        host.window.contentView?.superview?.layoutSubtreeIfNeeded()
        #expect(overflowed().isEmpty, "\(label): in NSToolbar's overflow menu \(overflowed())")
        if let expectsField { #expect(fieldShown() == expectsField, "\(label)") }
    }
}

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
