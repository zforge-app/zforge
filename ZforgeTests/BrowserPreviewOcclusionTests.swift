import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// List draws its preview above the trailing part of the rows. Rows watch the whole
/// window's mouse events (to start drags and open their menus), so a press on the
/// preview must not reach the row hidden beneath it. The real `ContentView` is laid
/// out offscreen (never ordered front) and each row is asked about window points.
/// The window is narrow enough that List scrolls horizontally: its rows then run
/// beneath the preview, as in the reported bug.
@Suite("Browser preview occlusion")
@MainActor
struct BrowserPreviewOcclusionTests {
    @Test("A press on List's preview neither drags nor opens the menu of the row beneath it")
    func listPreviewHidesRowsBeneathIt() async throws {
        let host = try await OcclusionWindowHost()
        defer { host.close() }
        let previewWidth = host.state.preferences.previewWidth * host.state.preferences.scale
        let contentMaxX = try #require(host.window.contentView).bounds.maxX
        // The preview fills the trailing `previewWidth` points of the content area.
        let previewMidX = contentMaxX - previewWidth / 2
        let rowsLeftOfPreviewX = contentMaxX - previewWidth - 20

        let rows = try await host.rowsReaching(x: previewMidX)
        #expect(!rows.isEmpty, "No row extends under the preview, so the scenario was not exercised.")
        for row in rows {
            let name = row.source.item?.name ?? "?"
            let inPreview = NSPoint(x: previewMidX, y: row.midY)
            let beside = NSPoint(x: rowsLeftOfPreviewX, y: row.midY)
            #expect(!row.source.startsDrag(at: inPreview), "Pressing the preview picks up \(name).")
            #expect(row.source.startsDrag(at: beside), "Pressing \(name) beside the preview does not pick it up.")
            let menu = try #require(row.menu, "\(name) has no item menu host.")
            #expect(!menu.presentsMenu(at: inPreview), "Secondary-clicking the preview opens \(name)'s menu.")
            #expect(menu.presentsMenu(at: beside), "Secondary-clicking \(name) beside the preview opens no menu.")
        }
    }
}

/// The real `ContentView` in List mode with the preview shown, in an isolated fixture.
@MainActor
private final class OcclusionWindowHost {
    let window: NSWindow
    let state: FileBrowserState
    private let suite = "ZforgeTestSuite.ZforgePreviewOcclusion-\(UUID().uuidString)"

    struct Row {
        let source: ArchiveDragSourceView
        let menu: BrowserItemMenuHost?
        let midY: CGFloat
    }

    init() async throws {
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.scale = 1
        preferences.viewMode = .list
        preferences.setPreviewVisible(true, in: .list)
        state = FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            recentItems: UIFixtureRecentItemsService(),
            taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: ContentView(browser: state))
        window.setContentSize(NSSize(width: 760, height: 600))
        await state.navigateToSidebar(URL(fileURLWithPath: "/ZforgeFixtures/Downloads"), name: "Downloads")
    }

    /// The rendered rows whose visible part spans `x`, once List has laid them out.
    func rowsReaching(x: CGFloat) async throws -> [Row] {
        for _ in 0..<200 {
            window.contentView?.layoutSubtreeIfNeeded()
            let root = try #require(window.contentView)
            let menus = root.descendants(of: BrowserItemMenuHost.self).filter { $0.item != nil }
            let rows = root.descendants(of: ArchiveDragSourceView.self).compactMap { source -> Row? in
                guard let item = source.item else { return nil }
                let frame = source.convert(source.bounds.intersection(source.visibleRect), to: nil)
                guard frame.minX < x, frame.maxX > x else { return nil }
                let menu = menus.first { $0.item?.id == item.id }
                return Row(source: source, menu: menu, midY: frame.midY)
            }
            if state.viewMode == .list, state.previewVisible, !state.items.isEmpty, !rows.isEmpty { return rows }
            try await Task.sleep(for: .milliseconds(10))
        }
        return []
    }

    func close() {
        window.close()
        window.contentViewController = nil
        state.close()
        UserDefaults.standard.removeTestSuite(named: suite)
    }
}

private extension NSView {
    func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { subview in [subview as? T].compactMap { $0 } + subview.descendants(of: type) }
    }
}
