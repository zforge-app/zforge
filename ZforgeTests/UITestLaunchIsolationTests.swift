import AppKit
import Testing
@testable import Zforge

/// What AppKit keeps in the application's preferences — window and split-view frames and the
/// open panel's state — stays out of the user's preferences in UI test launches (D-63, ZF-54).
@Suite("UI test launch isolation")
@MainActor
struct UITestLaunchIsolationTests {
    @Test("Open panels in UI test launches keep their state under their own identifier")
    func panelIdentifiers() {
        #expect(UITestLaunchIsolation.panelIdentifier(for: nil) == "ZforgeUITest")
        #expect(UITestLaunchIsolation.panelIdentifier(for: "automation-contextual-access") == "ZforgeUITest-automation-contextual-access")

        let plain = NSOpenPanel()
        UITestLaunchIsolation.isolate(plain, isolated: true)
        #expect(plain.identifier?.rawValue == "ZforgeUITest")
        let named = NSOpenPanel()
        named.identifier = NSUserInterfaceItemIdentifier("automation-contextual-access")
        UITestLaunchIsolation.isolate(named, isolated: true)
        #expect(named.identifier?.rawValue == "ZforgeUITest-automation-contextual-access")

        let ordinary = NSOpenPanel()
        UITestLaunchIsolation.isolate(ordinary, isolated: false)
        #expect(ordinary.identifier == nil, "Ordinary launches keep the panel's usual state")
    }

    /// Stand-ins that keep their autosave names without AppKit reading or writing the
    /// application's preferences; that nothing is saved in a real launch is checked by the
    /// preference re-audits after the UI and Unit runs (REGRESSION-COVERAGE, ZF-54).
    private final class NamedWindow: NSWindow {
        var name = ""
        override var frameAutosaveName: NSWindow.FrameAutosaveName { name }
        override func setFrameAutosaveName(_ name: NSWindow.FrameAutosaveName) -> Bool {
            self.name = name
            return true
        }
    }

    private final class NamedSplitView: NSSplitView {
        var name: NSSplitView.AutosaveName?
        override var autosaveName: NSSplitView.AutosaveName? {
            get { name }
            set { name = newValue }
        }
    }

    @Test("A window and the split view inside it stop saving their frames")
    func frameAutosaveDisabled() {
        let window = NamedWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                                 styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let splitView = NamedSplitView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let host = NSView(frame: splitView.frame)
        host.addSubview(splitView)
        window.contentView = host
        window.name = "browser-AppWindow-1"
        splitView.name = "SidebarNavigationSplitView"

        UITestLaunchIsolation.disableFrameAutosave(in: window)
        #expect(window.frameAutosaveName.isEmpty)
        #expect(splitView.autosaveName == nil)
    }

    @Test("A split view below the search depth is left alone, so window updates stay cheap")
    func splitViewSearchIsBounded() {
        let window = NamedWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                                 styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        var parent = NSView(frame: window.contentLayoutRect)
        window.contentView = parent
        for _ in 0..<UITestLaunchIsolation.splitViewSearchDepth {
            let child = NSView(frame: parent.bounds)
            parent.addSubview(child)
            parent = child
        }
        let deep = NamedSplitView(frame: parent.bounds)
        deep.name = "Deep"
        parent.addSubview(deep)
        UITestLaunchIsolation.disableFrameAutosave(in: window)
        #expect(deep.autosaveName == "Deep")
    }

    @Test("Starting again in an ordinary launch changes nothing")
    func ordinaryLaunchStartsNothing() {
        let wasObserving = UITestLaunchIsolation.isObservingWindows
        UITestLaunchIsolation.startIfNeeded(isolated: false)
        #expect(UITestLaunchIsolation.isObservingWindows == wasObserving)
    }
}
