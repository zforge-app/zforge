import AppKit
import Testing
@testable import Zforge

@Suite("Sidebar split constraint")
struct SidebarSplitConstraintTests {
    @Test("Applies an absolute native split-view limit")
    @MainActor
    func appliesNativeMaximumThickness() {
        let splitViewController = NSSplitViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: NSViewController())
        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(
            NSSplitViewItem(viewController: NSViewController())
        )
        splitViewController.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)

        let constraintView = SidebarSplitConstraintView()
        constraintView.update(minimumWidth: 180, maximumWidth: 540)
        constraintView.applyConstraint(to: sidebarItem)

        #expect(sidebarItem.minimumThickness == 180)
        #expect(sidebarItem.maximumThickness == 540)
        #expect(sidebarItem.holdingPriority > .defaultLow)
        #expect(sidebarItem.preferredThicknessFraction == NSSplitViewItem.unspecifiedDimension)
        let splitView = splitViewController.splitView
        splitView.setPosition(800, ofDividerAt: 0)
        splitView.layoutSubtreeIfNeeded()
        #expect(sidebarItem.viewController.view.frame.width <= 540)
    }

    @Test("Sidebar holds its width while content absorbs window resizing")
    @MainActor
    func preservesPreferredWidthAcrossWindowResizes() {
        let splitViewController = NSSplitViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: NSViewController())
        let contentItem = NSSplitViewItem(viewController: NSViewController())
        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(contentItem)
        splitViewController.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        splitViewController.view.layoutSubtreeIfNeeded()

        let constraintView = SidebarSplitConstraintView()
        constraintView.update(minimumWidth: 180, maximumWidth: 540)
        constraintView.applyConstraint(to: sidebarItem)
        contentItem.holdingPriority = .defaultLow
        splitViewController.splitView.setPosition(260, ofDividerAt: 0)
        splitViewController.view.layoutSubtreeIfNeeded()
        let chosenWidth = sidebarItem.viewController.view.frame.width

        splitViewController.view.frame.size.width = 1_200
        splitViewController.view.layoutSubtreeIfNeeded()
        let resizedWidth = sidebarItem.viewController.view.frame.width

        constraintView.update(minimumWidth: 180, maximumWidth: 840)
        constraintView.applyConstraint(to: sidebarItem)
        splitViewController.view.layoutSubtreeIfNeeded()
        let widthAfterMaximumUpdate = sidebarItem.viewController.view.frame.width

        #expect(sidebarItem.holdingPriority > contentItem.holdingPriority)
        #expect(sidebarItem.minimumThickness == 180)
        #expect(sidebarItem.maximumThickness == 840)
        #expect(abs(resizedWidth - chosenWidth) < 1)
        #expect(abs(widthAfterMaximumUpdate - chosenWidth) < 1)
    }

    /// D-75: the Settings window's sidebar ignored its 220 pt column width because SwiftUI reset
    /// the split item to a 140 pt minimum and a 144 pt width after the limits were applied.
    @Test("Limits reset after they were applied are applied again when the column leaves them")
    @MainActor
    func reappliesLimitsResetByTheFramework() async throws {
        let splitViewController = NSSplitViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: NSViewController())
        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(NSSplitViewItem(viewController: NSViewController()))
        splitViewController.view.frame = NSRect(x: 0, y: 0, width: 788, height: 600)
        let constraintView = SidebarSplitConstraintView()
        sidebarItem.viewController.view.addSubview(constraintView)
        constraintView.update(minimumWidth: 220, maximumWidth: 220)
        // Let the update scheduled by joining the view and by `update` run, as in a window.
        for _ in 0..<20 { await Task.yield() }
        splitViewController.view.layoutSubtreeIfNeeded()
        #expect(sidebarItem.minimumThickness == 220)
        #expect(abs(sidebarItem.viewController.view.frame.width - 220) < 1)

        // What SwiftUI does to the Settings sidebar once the window is up.
        sidebarItem.minimumThickness = 140
        sidebarItem.maximumThickness = NSSplitViewItem.unspecifiedDimension
        splitViewController.splitView.setPosition(144, ofDividerAt: 0)
        splitViewController.view.layoutSubtreeIfNeeded()
        #expect(sidebarItem.viewController.view.frame.width < 150)
        constraintView.frame = NSRect(x: 0, y: 0, width: 144, height: 600)

        for _ in 0..<20 where sidebarItem.minimumThickness != 220 { await Task.yield() }
        splitViewController.view.layoutSubtreeIfNeeded()
        #expect(sidebarItem.minimumThickness == 220)
        #expect(sidebarItem.maximumThickness == 220)
        #expect(abs(sidebarItem.viewController.view.frame.width - 220) < 1, "\(sidebarItem.viewController.view.frame.width)")
    }
}
