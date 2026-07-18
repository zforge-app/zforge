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
}
