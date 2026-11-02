import AppKit

/// The preferences every store of this process reads and writes (RNF-Q08, D-63, ZF-54).
///
/// Test launches never read or write the user's preferences. A UI test launch is any launch
/// with a `--ui-` argument: a test that checks persistence across launches names its own suite
/// (`ZFORGE_UI_PREFERENCES_SUITE`); any other UI test launch starts from the defaults in a
/// private suite cleared once, at launch, so one test's settings cannot reach the next test.
/// The unit test host (the app launched by XCTest to run the `Unit` plan) uses a private
/// suite of its own the same way.
nonisolated enum ZforgeDefaults {
    /// The private suite of UI test launches that do not name their own.
    static let fixtureSuite = "ZforgeUIFixturePreferences"
    /// The private suite of the unit test host.
    static let testHostSuite = "ZforgeUnitTestHostPreferences"

    /// Resolved once per process, so the preferences, the sidebar favorites, the language
    /// lookup and the automation folders share one suite and it is cleared only once.
    /// `UserDefaults` is documented as thread-safe; the constant itself never changes.
    nonisolated(unsafe) static let application: UserDefaults = resolve(
        arguments: ProcessInfo.processInfo.arguments, environment: ProcessInfo.processInfo.environment)

    static let isUITestLaunch = isUITestLaunch(arguments: ProcessInfo.processInfo.arguments)
    static let isTestHost = isTestHost(environment: ProcessInfo.processInfo.environment)
    /// UI test launches and the unit test host: neither touches the user's preferences.
    static let isIsolatedLaunch = isUITestLaunch || isTestHost

    static func isUITestLaunch(arguments: [String]) -> Bool {
        arguments.dropFirst().contains { $0.hasPrefix("--ui-") }
    }

    /// XCTest launches the app as the host of the `Unit` plan with its configuration file.
    static func isTestHost(environment: [String: String]) -> Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }

    /// Where a launch keeps its preferences: the user's (`nil`), a suite a UI test named to
    /// keep across launches, or a private suite cleared at launch.
    enum Storage: Equatable {
        case user
        case named(String)
        case cleared(String)
    }

    static func storage(arguments: [String], environment: [String: String]) -> Storage {
        if isUITestLaunch(arguments: arguments) {
            if let suite = environment["ZFORGE_UI_PREFERENCES_SUITE"] { return .named(suite) }
            return .cleared(fixtureSuite)
        }
        return isTestHost(environment: environment) ? .cleared(testHostSuite) : .user
    }

    /// The defaults for a launch's arguments and environment. A private suite is cleared by
    /// this call, so only the process's own resolution (`application`) may run it for the
    /// suite the process is using.
    static func resolve(arguments: [String], environment: [String: String]) -> UserDefaults {
        switch storage(arguments: arguments, environment: environment) {
        case .user: return .standard
        case let .named(suite):
            guard let defaults = UserDefaults(suiteName: suite) else {
                preconditionFailure("The UI test preferences suite \(suite) could not be created")
            }
            return defaults
        case let .cleared(suite): return clearedSuite(suite)
        }
    }

    private static func clearedSuite(_ name: String) -> UserDefaults {
        // Only the app's own identifier and the global domain are refused as suite names.
        guard let defaults = UserDefaults(suiteName: name) else {
            preconditionFailure("The test preferences suite \(name) could not be created")
        }
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

/// The unit test host stays out of the user's way (RNF-Q08, 2026-11-02). XCTest launches Zforge
/// only to load the `Unit` plan while the user keeps working, so that launch opens no browser
/// window (which would also ask for folder access, since the host has no grants) and keeps the
/// app out of the Dock and the app switcher. UI test launches and ordinary launches are unchanged.
nonisolated enum UnitTestHostPresentation {
    static func isQuiet(arguments: [String], environment: [String: String]) -> Bool {
        ZforgeDefaults.isTestHost(environment: environment) && !ZforgeDefaults.isUITestLaunch(arguments: arguments)
    }

    static let isQuietLaunch = isQuiet(
        arguments: ProcessInfo.processInfo.arguments, environment: ProcessInfo.processInfo.environment)

    /// Called before launch finishes, so the Dock never keeps the host's icon.
    @MainActor
    static func applyIfNeeded(to app: NSApplication, quiet: Bool = isQuietLaunch) {
        guard quiet else { return }
        app.setActivationPolicy(.accessory)
    }
}

/// What AppKit itself keeps in the application's preferences: window and split-view frames
/// (autosave) and the open panel's last folder and size. Test launches (UI tests and the unit
/// test host) keep none of it in the user's preferences.
@MainActor
enum UITestLaunchIsolation {
    static let panelIdentifierPrefix = "ZforgeUITest"

    /// The open panel stores its state under its identifier; test launches use their own.
    static func panelIdentifier(for identifier: String?) -> String {
        [panelIdentifierPrefix, identifier].compactMap { $0 }.joined(separator: "-")
    }

    /// Gives a panel the test identifier in test launches; ordinary launches are unchanged.
    static func isolate(_ panel: NSSavePanel, isolated: Bool = ZforgeDefaults.isIsolatedLaunch) {
        guard isolated else { return }
        panel.identifier = NSUserInterfaceItemIdentifier(panelIdentifier(for: panel.identifier?.rawValue))
    }

    /// The app's open panels come from here, so test launches keep their state apart.
    static func openPanel(isolated: Bool = ZforgeDefaults.isIsolatedLaunch) -> NSOpenPanel {
        let panel = NSOpenPanel()
        isolate(panel, isolated: isolated)
        return panel
    }

    /// Stops a window and its split views from saving their frames. Split views that save
    /// frames (SwiftUI's sidebar split) sit near the top of the window; the search stops a few
    /// levels down so window updates stay cheap however many rows the content shows.
    static func disableFrameAutosave(in window: NSWindow) {
        if !window.frameAutosaveName.isEmpty { window.setFrameAutosaveName("") }
        if let content = window.contentView { disableSplitViewAutosave(in: content, depth: 0) }
    }

    static let splitViewSearchDepth = 8

    private static func disableSplitViewAutosave(in view: NSView, depth: Int) {
        if let splitView = view as? NSSplitView, splitView.autosaveName != nil { splitView.autosaveName = nil }
        guard depth < splitViewSearchDepth else { return }
        for subview in view.subviews { disableSplitViewAutosave(in: subview, depth: depth + 1) }
    }

    private static var updateObserver: NSObjectProtocol?
    static var isObservingWindows: Bool { updateObserver != nil }

    /// In test launches, turns autosave off in every window as SwiftUI creates and fills it.
    static func startIfNeeded(isolated: Bool = ZforgeDefaults.isIsolatedLaunch) {
        guard isolated, updateObserver == nil else { return }
        updateObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification, object: nil, queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            MainActor.assumeIsolated { disableFrameAutosave(in: window) }
        }
        NSApp.windows.forEach(disableFrameAutosave)
    }
}
