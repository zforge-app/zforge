import CoreGraphics
import Testing
@testable import Zforge

@Suite("Toolbar layout")
struct ToolbarLayoutTests {
    @Test("The view selector compacts before the archive action is hidden")
    @MainActor
    func responsivePriority() {
        #expect(BrowserToolbarLayout.stage(for: 900) == .expanded)
        #expect(BrowserToolbarLayout.stage(for: 899) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 840) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 839) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 678) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 677) == .unifiedOverflow)
    }

    @Test("An open search field moves controls into the menu 150 pt earlier and hides the title in the smallest stage")
    @MainActor
    func expandedSearchStages() {
        #expect(BrowserToolbarLayout.stage(for: 1_050, searchFieldExpanded: true) == .expanded)
        #expect(BrowserToolbarLayout.stage(for: 1_049, searchFieldExpanded: true) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 990, searchFieldExpanded: true) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 989, searchFieldExpanded: true) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 828, searchFieldExpanded: true) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 827, searchFieldExpanded: true) == .unifiedOverflow)
        #expect(BrowserToolbarLayout.stage(for: 1_000, searchFieldExpanded: false) == .expanded)
        #expect(!BrowserToolbarLayout.hidesTitle(for: 828, searchFieldExpanded: true))
        #expect(BrowserToolbarLayout.hidesTitle(for: 827, searchFieldExpanded: true))
        #expect(BrowserToolbarLayout.hidesTitle(for: 640, searchFieldExpanded: true))
        #expect(!BrowserToolbarLayout.hidesTitle(for: 640, searchFieldExpanded: false))
    }

    /// ZF-88 follow-up: the stages follow the toolbar's room, from the sidebar's trailing edge (or
    /// the traffic lights with the sidebar collapsed), with the same widths for a 180 pt sidebar.
    @Test("Stages follow the room the sidebar leaves the toolbar, in the same order")
    @MainActor
    func stagesFollowSidebar() {
        // A 224 pt sidebar takes 44 pt more: every stage switches 44 pt later.
        #expect(BrowserToolbarLayout.stage(for: 944, sidebarTrailingEdge: 224) == .expanded)
        #expect(BrowserToolbarLayout.stage(for: 943, sidebarTrailingEdge: 224) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 884, sidebarTrailingEdge: 224) == .compactWithArchiveAction)
        #expect(BrowserToolbarLayout.stage(for: 883, sidebarTrailingEdge: 224) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 722, sidebarTrailingEdge: 224) == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.stage(for: 721, sidebarTrailingEdge: 224) == .unifiedOverflow)
        // Collapsed: the toolbar starts after the traffic lights, 92 pt earlier than with 180 pt.
        #expect(BrowserToolbarLayout.stage(for: 808, sidebarTrailingEdge: nil) == .expanded)
        #expect(BrowserToolbarLayout.stage(for: 807, sidebarTrailingEdge: nil) == .compactWithArchiveAction)
        // An open field still moves controls 150 pt earlier: 1,000 − 44 − 150 = 806 pt.
        #expect(BrowserToolbarLayout.stage(for: 1_000, sidebarTrailingEdge: 224, searchFieldExpanded: true)
                == .compactWithActionsOverflow)
        #expect(BrowserToolbarLayout.WidthClass(windowWidth: 944, sidebarTrailingEdge: 224).stage == .expanded)
    }

    @Test("With a sidebar near its maximum the open field narrows and the title stays")
    @MainActor
    func sidebarNearMaximum() {
        // 416 pt of room hold the full open field; the content keeps 400 pt, so the title always fits.
        #expect(!BrowserToolbarLayout.WidthClass(windowWidth: 700, sidebarTrailingEdge: 284).usesCompactSearchField)
        #expect(BrowserToolbarLayout.WidthClass(windowWidth: 700, sidebarTrailingEdge: 285).usesCompactSearchField)
        #expect(!BrowserToolbarLayout.WidthClass(windowWidth: 700, sidebarTrailingEdge: 300).hidesTitle(searchFieldExpanded: false))
        #expect(!BrowserToolbarLayout.WidthClass(windowWidth: 1_100).hidesTitle(searchFieldExpanded: false))
    }

    @Test("The smallest stage keeps the search button while 418 pt of room hold it beside the menu")
    @MainActor
    func searchButtonInSmallestStage() {
        #expect(BrowserToolbarLayout.WidthClass(windowWidth: 640).keepsSearchButtonInSmallestStage)
        #expect(BrowserToolbarLayout.WidthClass(windowWidth: 640, sidebarTrailingEdge: 222).keepsSearchButtonInSmallestStage)
        #expect(!BrowserToolbarLayout.WidthClass(windowWidth: 640, sidebarTrailingEdge: 223).keepsSearchButtonInSmallestStage)
        #expect(BrowserToolbarLayout.WidthClass(windowWidth: 640, sidebarTrailingEdge: nil).keepsSearchButtonInSmallestStage)
        let widthClass = BrowserToolbarLayout.WidthClass(windowWidth: 640, sidebarTrailingEdge: 223)
        #expect(widthClass.overflowMenuContents(for: widthClass.stage).includesSearchAction)
        #expect(!BrowserToolbarLayout.WidthClass(windowWidth: 640).overflowMenuContents(for: .unifiedOverflow).includesSearchAction)
    }
}
