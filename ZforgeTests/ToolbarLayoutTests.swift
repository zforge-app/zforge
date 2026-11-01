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
}
