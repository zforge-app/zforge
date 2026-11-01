import AppKit
import Testing
@testable import Zforge

/// Fixture window placement for UI tests (D-70): a cross-window drag must not depend on
/// moving a window by its title bar, so two side-by-side windows never overlap.
@Suite("UI test window placement")
struct UITestWindowPlacementTests {
    /// This Mac's main screen at its default scale, with the Dock at the bottom.
    let visible = NSRect(x: 0, y: 64, width: 1710, height: 1010)
    let size = NSSize(width: 780, height: 910)
    let cascaded = NSPoint(x: 465, y: 120)

    @Test("Side by side puts the first window at the leading edge and later ones at the trailing edge, at the top")
    func sideBySide() {
        let arguments = ["--ui-window-width", "780", UITestWindowPlacement.sideBySideArgument]
        let first = UITestWindowPlacement.origin(for: size, current: cascaded, visibleFrame: visible,
                                                 isFirstWindow: true, arguments: arguments)
        let second = UITestWindowPlacement.origin(for: size, current: cascaded, visibleFrame: visible,
                                                  isFirstWindow: false, arguments: arguments)
        #expect(first == NSPoint(x: 0, y: 164))
        #expect(second == NSPoint(x: 930, y: 164))
        let firstFrame = NSRect(origin: first, size: size), secondFrame = NSRect(origin: second, size: size)
        #expect(!firstFrame.intersects(secondFrame), "Neither window covers the other")
        #expect(visible.contains(firstFrame) && visible.contains(secondFrame), "Both windows are fully on screen")
    }

    @Test("Native cascading wins without a placement argument; only offscreen frames are clamped")
    func nativePositionIsKept() {
        let arguments = ["--ui-window-width", "780"]
        #expect(UITestWindowPlacement.origin(for: size, current: cascaded, visibleFrame: visible,
                                             isFirstWindow: false, arguments: arguments) == cascaded)
        #expect(UITestWindowPlacement.origin(for: size, current: NSPoint(x: 1500, y: 10), visibleFrame: visible,
                                             isFirstWindow: true, arguments: arguments) == NSPoint(x: 930, y: 64))
    }

    @Test("Leading anchors every window to the leading edge and keeps its height on screen")
    func leading() {
        let arguments = [UITestWindowPlacement.leadingArgument]
        #expect(UITestWindowPlacement.origin(for: size, current: cascaded, visibleFrame: visible,
                                             isFirstWindow: false, arguments: arguments) == NSPoint(x: 0, y: 120))
    }

    @Test("A window wider than the screen is pinned to the leading edge in every placement")
    func oversizedWindow() {
        let wide = NSSize(width: 2000, height: 1200)
        for arguments in [[], [UITestWindowPlacement.leadingArgument], [UITestWindowPlacement.sideBySideArgument]] {
            #expect(UITestWindowPlacement.origin(for: wide, current: cascaded, visibleFrame: visible,
                                                 isFirstWindow: false, arguments: arguments) == NSPoint(x: 0, y: 64))
        }
    }
}
