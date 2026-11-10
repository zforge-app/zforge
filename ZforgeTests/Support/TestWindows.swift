import AppKit

/// Windows that tests create in code (D-81, ZF-64).
///
/// `NSWindow` defaults to `isReleasedWhenClosed = true`: `close()` then releases the window
/// once more, behind the back of the Swift reference that owns it. The owner's own release
/// at the end of its scope is then one release too many, and the object is freed while a
/// later release (an autorelease pool, SwiftUI or KVO) still points at it. In the hosted
/// unit test run that crashed the test host in `objc_release` when a main-actor job's
/// autorelease pool was drained, and every test still running was reported as failed.
/// A window made here is owned only by its Swift references, so it can be closed any
/// number of times and is freed exactly once, when the last reference goes away.
@MainActor
enum TestWindow {
    static func make(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask = [.titled],
        defer deferCreation: Bool = false
    ) -> NSWindow {
        let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: deferCreation)
        window.isReleasedWhenClosed = false
        return window
    }
}
