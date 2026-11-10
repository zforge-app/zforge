import AppKit
import Observation
import SwiftUI
import Testing
@testable import Zforge

/// A List Columns row keeps its view while a drag moves it (D-85, ZF-67).
///
/// The handle's `DragGesture` lives in the dragged row's view. The drag reorders the rows live,
/// so if a move rebuilt the row instead of moving it, the gesture would end with the first move
/// and the column would land one place from where it started, whatever the distance dragged.
/// That happened after ZF-62, when `SettingsRows` keyed its rows by position. The pane is hosted
/// offscreen and each row's switch, an AppKit view that SwiftUI keeps for as long as the row
/// exists, tells whether the row was moved or rebuilt. Synthesized mouse events do not reach
/// SwiftUI gestures offscreen; the real drag is proven by
/// `SettingsUITests.testListColumnsReorderByDragging`.
@Suite("List Columns rows keep their views while dragged (D-85)")
@MainActor
struct ListColumnDragTests {
    @Test("Dragging Kind up two places moves its row; no row is rebuilt")
    func dragUpKeepsRows() async throws {
        let fixture = try ListColumnPaneFixture(order: [.name, .modificationDate, .size, .kind])
        defer { fixture.close() }
        let views = try fixture.switchesByColumn()

        // The live moves of one drag from Kind's handle to Date Modified.
        fixture.preferences.moveGlobalListColumn(.kind, onto: .size)
        try await fixture.expectRows(views, in: [.name, .modificationDate, .kind, .size])
        fixture.preferences.moveGlobalListColumn(.kind, onto: .modificationDate)
        try await fixture.expectRows(views, in: [.name, .kind, .modificationDate, .size])
    }

    @Test("Dragging Date Modified down two places moves its row; no row is rebuilt")
    func dragDownKeepsRows() async throws {
        let fixture = try ListColumnPaneFixture(order: [.name, .modificationDate, .size, .kind])
        defer { fixture.close() }
        let views = try fixture.switchesByColumn()

        // The live moves of one drag from Date Modified's handle to Kind.
        fixture.preferences.moveGlobalListColumn(.modificationDate, onto: .size)
        try await fixture.expectRows(views, in: [.name, .size, .modificationDate, .kind])
        fixture.preferences.moveGlobalListColumn(.modificationDate, onto: .kind)
        try await fixture.expectRows(views, in: [.name, .size, .kind, .modificationDate])
    }

    @Test("Showing a column moves its row up without rebuilding any row")
    func showingColumnKeepsRows() async throws {
        let fixture = try ListColumnPaneFixture(order: [.name, .modificationDate, .size, .kind])
        defer { fixture.close() }
        let views = try fixture.switchesByColumn()

        // Tags is hidden: switching it on appends it to the visible columns, above the hidden rows.
        fixture.preferences.setGlobalListColumns([.name, .modificationDate, .size, .kind, .tags])
        try await fixture.expectRows(views, in: [.name, .modificationDate, .size, .kind, .tags])
    }
}

/// `SettingsRows` is shared by every Settings pane: a row inserted or moved among its rows must
/// not rebuild the others, or they lose their state, their focus and any gesture in progress.
@Suite("Settings rows keep their identity (D-85)")
@MainActor
struct SettingsRowsIdentityTests {
    @Observable
    final class RowTitles {
        var titles: [String]
        init(_ titles: [String]) { self.titles = titles }
    }

    struct RowsView: View {
        let model: RowTitles

        var body: some View {
            SettingsRows {
                ForEach(model.titles, id: \.self) { title in
                    SettingsToggleRow(Text(verbatim: title), identifier: title, isOn: .constant(true))
                }
            }
            .frame(width: 400)
        }
    }

    @Test("A row inserted first and a row moved last leave every row's view in place")
    func insertAndMoveKeepRows() async throws {
        let model = RowTitles(["Alpha", "Bravo", "Charlie"])
        let host = NSHostingView(rootView: RowsView(model: model))
        let window = TestWindow.make(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400))
        window.contentView = host
        defer {
            window.close()
            window.contentView = nil
        }
        func switches() -> [NSView] {
            host.layoutSubtreeIfNeeded()
            return host.settingsDescendants(named: "PlatformSwitch")
                .sorted { $0.convert($0.bounds, to: nil).midY > $1.convert($1.bounds, to: nil).midY }
        }
        let initial = switches()
        try #require(initial.count == 3)

        model.titles.insert("Zulu", at: 0)
        try await waitUntil { switches().count == 4 }
        #expect(Array(switches().dropFirst()) == initial, "Inserting a first row rebuilt the rows below it")

        let zulu = try #require(switches().first)
        model.titles = ["Alpha", "Bravo", "Charlie", "Zulu"]
        try await waitUntil { switches().last !== zulu ? !switches().contains(zulu) : true }
        #expect(switches() == initial + [zulu], "Moving a row rebuilt it or its neighbours")
    }

    /// Lets SwiftUI apply a change it has not laid out yet; returns as soon as `condition` holds.
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<400 where !condition() {
            try await Task.sleep(for: .milliseconds(5))
        }
    }
}

/// The View Options pane hosted offscreen, tall enough to lay out every List Columns row.
@MainActor
final class ListColumnPaneFixture {
    let suite = "ZforgeTestSuite.ListColumnDrag-\(UUID().uuidString)"
    let defaults: UserDefaults
    let preferences: FileBrowserPreferences
    let window: NSWindow
    let host: NSView

    init(order: [BrowserListColumn]) throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.setGlobalListColumns(order)
        let size = CGSize(width: SettingsLayout.detailWidth, height: 1000)
        window = TestWindow.make(contentRect: NSRect(origin: .zero, size: size))
        let host = NSHostingView(rootView: ViewOptionsSettingsPane(preferences: preferences))
        host.frame = NSRect(origin: .zero, size: size)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        self.host = host
    }

    func close() {
        window.close()
        window.contentView = nil
        defaults.removeTestSuite(named: suite)
    }

    /// The rows in the order the pane shows them: the visible columns, then the hidden ones.
    var displayedColumns: [BrowserListColumn] {
        preferences.globalListColumns + BrowserListColumn.selectable.filter { !preferences.globalListColumns.contains($0) }
    }

    /// The List Columns rows' switches, top to bottom. They are the last switches of the pane.
    func switches() -> [NSView] {
        host.layoutSubtreeIfNeeded()
        let all = host.settingsDescendants(named: "PlatformSwitch")
            .sorted { $0.convert($0.bounds, to: nil).midY > $1.convert($1.bounds, to: nil).midY }
        return Array(all.suffix(BrowserListColumn.selectable.count))
    }

    /// Each row's switch, by the column the row shows.
    func switchesByColumn() throws -> [BrowserListColumn: NSView] {
        let views = switches()
        try #require(views.count == BrowserListColumn.selectable.count, "Every List Columns row is laid out")
        return Dictionary(uniqueKeysWithValues: zip(displayedColumns, views))
    }

    /// Waits until the pane has laid out the change, then expects every row to be the view it
    /// was before the change, now at its column's place in `order`.
    func expectRows(_ views: [BrowserListColumn: NSView], in order: [BrowserListColumn],
                    sourceLocation: SourceLocation = #_sourceLocation) async throws {
        #expect(preferences.globalListColumns == order, sourceLocation: sourceLocation)
        let expected = displayedColumns.compactMap { views[$0] }
        // Until SwiftUI lays out the change the rows keep their old places; a rebuilt row is
        // final, so the wait ends as soon as one appears.
        for _ in 0..<400 where switches() != expected {
            if Set(switches().map(ObjectIdentifier.init)) != Set(expected.map(ObjectIdentifier.init)) { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        let shown = switches()
        let rebuilt = displayedColumns.filter { column in !shown.contains { $0 === views[column] } }
        #expect(rebuilt.isEmpty, "Rows rebuilt instead of moved: \(rebuilt.map(\.rawValue))", sourceLocation: sourceLocation)
        #expect(shown == expected, "Rows out of place for \(order.map(\.rawValue))", sourceLocation: sourceLocation)
    }
}
