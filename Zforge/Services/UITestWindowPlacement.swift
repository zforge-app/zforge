import AppKit

/// Where a UI-test fixture window goes after `--ui-window-width` sizes it.
///
/// Without a placement argument the window keeps its native (cascaded) position, clamped
/// onto the screen. `--ui-window-leading` anchors it to the screen's leading edge, for tests
/// that need the rest of the screen free (Finder drops). `--ui-window-side-by-side` anchors the
/// first browser window to the leading edge and every later one to the trailing edge, both at
/// the top of the visible frame, so a test that drags between two windows starts with neither
/// covering the other (D-70) instead of moving one by its title bar.
nonisolated enum UITestWindowPlacement {
    static let leadingArgument = "--ui-window-leading"
    static let sideBySideArgument = "--ui-window-side-by-side"

    /// - Parameters:
    ///   - isFirstWindow: no other browser window is on screen.
    static func origin(
        for size: NSSize,
        current: NSPoint,
        visibleFrame: NSRect,
        isFirstWindow: Bool,
        arguments: [String]
    ) -> NSPoint {
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - size.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - size.height)
        func clamped(x: CGFloat, y: CGFloat) -> NSPoint {
            NSPoint(x: min(max(x, visibleFrame.minX), maxX), y: min(max(y, visibleFrame.minY), maxY))
        }
        if arguments.contains(sideBySideArgument) {
            return clamped(x: isFirstWindow ? visibleFrame.minX : maxX, y: maxY)
        }
        let x = arguments.contains(leadingArgument) ? visibleFrame.minX : current.x
        return clamped(x: x, y: current.y)
    }
}
