import AppKit
import Testing

/// Closing a window that a test creates must not free it under its Swift owner (D-81, ZF-64).
@Suite("Test window lifetime")
@MainActor
struct TestWindowLifetimeTests {
    private static let frame = NSRect(x: 0, y: 0, width: 320, height: 200)

    /// How many references `close()` dropped that the caller did not give up. An extra
    /// reference keeps the window alive during the measurement, and any reference that
    /// close took away is given back, so the measurement itself never over-releases.
    private func referencesTakenByClose(_ window: NSWindow) -> Int {
        let guardReference = Unmanaged.passRetained(window)
        defer { guardReference.release() }
        let before = CFGetRetainCount(window)
        autoreleasepool { window.close() }
        let taken = before - CFGetRetainCount(window)
        for _ in 0..<max(taken, 0) { _ = guardReference.retain() }
        return taken
    }

    @Test("A window left at AppKit's default releases itself on close, behind its Swift owner")
    func defaultWindowReleasesItselfOnClose() {
        // Characterizes the cause of the test host crash: this is the configuration the
        // offending tests used, and the reference it drops is the one their owner releases.
        let window = autoreleasepool {
            NSWindow(contentRect: Self.frame, styleMask: [.titled], backing: .buffered, defer: false)
        }
        #expect(window.isReleasedWhenClosed)
        #expect(referencesTakenByClose(window) == 1, "close() is expected to release the window once")
    }

    @Test("A test window survives close while referenced and is freed once when released")
    func testWindowIsOwnedOnlyByItsReferences() {
        weak var observed: NSWindow?
        autoreleasepool {
            let window = autoreleasepool { TestWindow.make(contentRect: Self.frame) }
            observed = window
            #expect(!window.isReleasedWhenClosed)
            #expect(referencesTakenByClose(window) == 0, "close() must not release a test window")
            // Closing twice, as a deferred close after an explicit one does, is harmless.
            #expect(referencesTakenByClose(window) == 0)
            #expect(observed === window)
        }
        #expect(observed == nil, "The window is freed when its last reference goes away")
    }
}
