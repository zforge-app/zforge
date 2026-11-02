import AppKit
import Testing
@testable import Zforge

/// The unit test host stays out of the user's way (RNF-Q08, 2026-11-02). XCTest launches Zforge
/// only to load the `Unit` plan, so that launch opens no browser window (and therefore asks for no
/// folder access) and keeps the app out of the Dock and the app switcher.
@MainActor
struct UnitTestHostPresentationTests {
    @Test("This unit test host shows no browser window, no open panel and no Dock icon")
    func runningHostIsQuiet() {
        let browserWindows = NSApp.windows.filter { $0.identifier?.rawValue.hasPrefix("browser") == true }
        #expect(browserWindows.isEmpty, "The test host opened browser windows: \(browserWindows.map(\.title))")
        let panels = NSApp.windows.filter { $0 is NSOpenPanel && $0.isVisible }
        #expect(panels.isEmpty, "The test host shows open panels: \(panels.map(\.title))")
        #expect(NSApp.activationPolicy() == .accessory, "The test host is in the Dock (policy \(NSApp.activationPolicy().rawValue))")
    }

    @Test("Only the unit test host is a quiet launch")
    func quietLaunchKinds() {
        let host = ["XCTestConfigurationFilePath": "/tmp/ZforgeTests.xctestconfiguration"]
        #expect(UnitTestHostPresentation.isQuiet(arguments: ["Zforge"], environment: host))
        #expect(!UnitTestHostPresentation.isQuiet(arguments: ["Zforge"], environment: [:]), "An ordinary launch")
        #expect(!UnitTestHostPresentation.isQuiet(arguments: ["Zforge", "--ui-fixtures"], environment: [:]), "A UI test launch")
        #expect(!UnitTestHostPresentation.isQuiet(arguments: ["Zforge", "--ui-fixtures"], environment: host),
                "A UI test launch keeps its windows even with an XCTest configuration")
    }

    @Test("Only a quiet launch changes the activation policy")
    func ordinaryLaunchKeepsItsPolicy() {
        let before = NSApp.activationPolicy()
        UnitTestHostPresentation.applyIfNeeded(to: NSApp, quiet: false)
        #expect(NSApp.activationPolicy() == before)
    }
}
