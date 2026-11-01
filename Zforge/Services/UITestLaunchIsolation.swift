import AppKit

/// The preferences every store of this process reads and writes (RNF-Q08, D-63).
///
/// A UI test launch is any launch with a `--ui-` argument. It never reads or writes the
/// user's preferences: a test that checks persistence across launches names its own suite
/// (`ZFORGE_UI_PREFERENCES_SUITE`); any other UI test launch starts from the defaults in a
/// private suite cleared once, at launch, so one test's settings cannot reach the next test.
nonisolated enum ZforgeDefaults {
    /// The private suite of UI test launches that do not name their own.
    static let fixtureSuite = "ZforgeUIFixturePreferences"

    /// Resolved once per process, so the preferences, the sidebar favorites, the language
    /// lookup and the automation folders share one suite and it is cleared only once.
    /// `UserDefaults` is documented as thread-safe; the constant itself never changes.
    nonisolated(unsafe) static let application: UserDefaults = resolve(
        arguments: ProcessInfo.processInfo.arguments, environment: ProcessInfo.processInfo.environment)

    static let isUITestLaunch = isUITestLaunch(arguments: ProcessInfo.processInfo.arguments)

    static func isUITestLaunch(arguments: [String]) -> Bool {
        arguments.dropFirst().contains { $0.hasPrefix("--ui-") }
    }

    /// The defaults for a launch's arguments and environment. A UI test launch without a
    /// named suite gets the private suite, cleared by this call.
    static func resolve(arguments: [String], environment: [String: String]) -> UserDefaults {
        guard isUITestLaunch(arguments: arguments) else { return .standard }
        if let suite = environment["ZFORGE_UI_PREFERENCES_SUITE"], let defaults = UserDefaults(suiteName: suite) {
            return defaults
        }
        // Only the app's own identifier and the global domain are refused as suite names.
        guard let defaults = UserDefaults(suiteName: fixtureSuite) else {
            preconditionFailure("The UI fixture preferences suite could not be created")
        }
        defaults.removePersistentDomain(forName: fixtureSuite)
        return defaults
    }
}

/// What AppKit itself keeps in the application's preferences: window and split-view frames
/// (autosave) and the open panel's last folder and size. UI test launches keep none of it in
/// the user's preferences.
@MainActor
enum UITestLaunchIsolation {
    static let panelIdentifierPrefix = "ZforgeUITest"

    /// The open panel stores its state under its identifier; UI test launches use their own.
    static func panelIdentifier(for identifier: String?) -> String {
        [panelIdentifierPrefix, identifier].compactMap { $0 }.joined(separator: "-")
    }

    /// Gives a panel the UI test identifier in UI test launches; ordinary launches are unchanged.
    static func isolate(_ panel: NSSavePanel, isUITestLaunch: Bool = ZforgeDefaults.isUITestLaunch) {
        guard isUITestLaunch else { return }
        panel.identifier = NSUserInterfaceItemIdentifier(panelIdentifier(for: panel.identifier?.rawValue))
    }

    /// The app's open panels come from here, so UI test launches keep their state apart.
    static func openPanel(isUITestLaunch: Bool = ZforgeDefaults.isUITestLaunch) -> NSOpenPanel {
        let panel = NSOpenPanel()
        isolate(panel, isUITestLaunch: isUITestLaunch)
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

    /// In UI test launches, turns autosave off in every window as SwiftUI creates and fills it.
    static func startIfNeeded(isUITestLaunch: Bool = ZforgeDefaults.isUITestLaunch) {
        guard isUITestLaunch, updateObserver == nil else { return }
        updateObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification, object: nil, queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            MainActor.assumeIsolated { disableFrameAutosave(in: window) }
        }
        NSApp.windows.forEach(disableFrameAutosave)
    }
}
