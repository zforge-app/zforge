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
        UITestLaunchIsolation.isolate(plain, isUITestLaunch: true)
        #expect(plain.identifier?.rawValue == "ZforgeUITest")
        let named = NSOpenPanel()
        named.identifier = NSUserInterfaceItemIdentifier("automation-contextual-access")
        UITestLaunchIsolation.isolate(named, isUITestLaunch: true)
        #expect(named.identifier?.rawValue == "ZforgeUITest-automation-contextual-access")

        let ordinary = NSOpenPanel()
        UITestLaunchIsolation.isolate(ordinary, isUITestLaunch: false)
        #expect(ordinary.identifier == nil, "Ordinary launches keep the panel's usual state")
    }

    /// The window and split view write under names unique to this test, removed afterwards.
    @Test("A window and its split view stop saving their frames")
    func frameAutosaveDisabled() throws {
        let name = "ZforgeIsolationTest-\(UUID().uuidString)"
        let key = "NSWindow Frame \(name)"
        let splitKey = "NSSplitView Subview Frames \(name)-split"
        defer {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: splitKey)
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let splitView = NSSplitView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let host = NSView(frame: splitView.frame)
        host.addSubview(splitView)
        window.contentView = host
        splitView.autosaveName = "\(name)-split"
        window.setFrameAutosaveName(name)
        window.setFrame(NSRect(x: 10, y: 10, width: 420, height: 310), display: false)
        #expect(UserDefaults.standard.string(forKey: key) != nil, "AppKit saves a named window's frame")
        UserDefaults.standard.removeObject(forKey: key)

        UITestLaunchIsolation.disableFrameAutosave(in: window)
        #expect(window.frameAutosaveName.isEmpty)
        #expect(splitView.autosaveName == nil)
        window.setFrame(NSRect(x: 20, y: 20, width: 440, height: 320), display: false)
        window.saveFrame(usingName: window.frameAutosaveName)
        #expect(UserDefaults.standard.string(forKey: key) == nil, "No frame is saved once autosave is off")
    }

    @Test("Ordinary launches do not observe windows")
    func ordinaryLaunchLeavesWindowsAlone() {
        UITestLaunchIsolation.startIfNeeded(isUITestLaunch: false)
        #expect(!UITestLaunchIsolation.isObservingWindows)
    }
}
