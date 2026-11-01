import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var current: AppDelegate?
    static let archiveURLsReceived = Notification.Name("ZforgeArchiveURLsReceived")

    /// How long the window opened at launch may still present a request that
    /// launched Zforge, rather than a second window opening beside it.
    static let launchWindowGracePeriod: Duration = .seconds(10)

    private var pendingArchives: [BrowserWindowRequest] = []
    private var archiveIndexRuntime: ArchiveIndexRuntime?
    private var launchWindowOffered = false
    private var launchWindow: (id: UUID, deadline: ContinuousClock.Instant)?
    private var interactionMonitor: Any?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // UI test launches keep window frames out of the user's preferences (D-63).
        UITestLaunchIsolation.startIfNeeded()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        if !ProcessInfo.processInfo.arguments.contains("--ui-fixtures"),
           ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
           NSClassFromString("XCTestCase") == nil {
            archiveIndexRuntime = .shared
            archiveIndexRuntime?.start()
        }
        // Once the user acts in Zforge, its launch window is theirs to keep.
        interactionMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown, .scrollWheel]
        ) { [weak self] event in
            self?.endLaunchWindowOffer()
            return event
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        archiveIndexRuntime?.stop()
        BrowserWindowLifecycle.shared.applicationWillTerminate(orderedWindows: NSApp.orderedWindows)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.contains(where: { $0.scheme == FinderRequestInbox.urlScheme }) {
            receiveFinderRequests(from: FinderRequestInbox.shared())
        }
        let archives = urls.filter { ArchiveFormatRegistry.recognizes($0.lastPathComponent) }
        guard !archives.isEmpty else { return }

        pendingArchives.append(contentsOf: archives.map { BrowserWindowRequest(initialURL: $0) })
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
    }

    func receiveAutomationArchive(_ url: URL, lease: AutomationAccessLease) {
        guard ArchiveFormatRegistry.recognizes(url.lastPathComponent) else { return }
        pendingArchives.append(BrowserWindowRequest(initialURL: url, automationAccess: BrowserOpeningAccess(lease)))
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
    }

    /// Each action chosen in Finder's Zforge submenu opens a window that shows its
    /// items and runs the action there. The wake URL carries no request itself.
    func receiveFinderRequests(from inbox: FinderRequestInbox?) {
        guard let inbox else {
            Logger(subsystem: "io.libor.Zforge", category: "Finder").error("The Finder request inbox is unavailable.")
            return
        }
        let requests = inbox.drain()
        guard !requests.isEmpty else { return }
        pendingArchives.append(contentsOf: requests.map { BrowserWindowRequest(finderRequest: $0) })
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
    }

    /// Opens a results window for an archive name search requested by Siri.
    func receiveArchiveSearch(_ term: String) {
        pendingArchives.append(BrowserWindowRequest(archiveSearch: term))
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
    }

    /// The value of a browser window opened without one. The first such window
    /// of a launch stays available to a request that arrives shortly after, so
    /// a request that launches Zforge opens one window instead of two.
    func makeDefaultWindowRequest(now: ContinuousClock.Instant = .now) -> BrowserWindowRequest {
        if let pending = takeNextArchiveRequest() { return pending }
        let request = BrowserWindowRequest()
        if !launchWindowOffered {
            launchWindowOffered = true
            launchWindow = (request.id, now.advanced(by: Self.launchWindowGracePeriod))
        }
        return request
    }

    /// The next request, when `id` is the untouched launch window and it may
    /// still present it. The launch window can be reused only once.
    func takeRequest(forLaunchWindow id: UUID, now: ContinuousClock.Instant = .now) -> BrowserWindowRequest? {
        guard let launchWindow, launchWindow.id == id, !pendingArchives.isEmpty else { return nil }
        endLaunchWindowOffer()
        guard now <= launchWindow.deadline else { return nil }
        return takeNextArchiveRequest()
    }

    /// Ends the launch window's offer when it closes or presents other content.
    func releaseLaunchWindow(_ id: UUID) {
        if launchWindow?.id == id { endLaunchWindowOffer() }
    }

    private func endLaunchWindowOffer() {
        launchWindowOffered = true
        launchWindow = nil
        if let interactionMonitor { NSEvent.removeMonitor(interactionMonitor) }
        interactionMonitor = nil
    }

    func takeNextArchiveRequest() -> BrowserWindowRequest? {
        guard !pendingArchives.isEmpty else { return nil }
        return pendingArchives.removeFirst()
    }

    func takePendingArchiveRequests() -> [BrowserWindowRequest] {
        defer { pendingArchives.removeAll() }
        return pendingArchives
    }

    func takeNextArchiveURL() -> URL? {
        takeNextArchiveRequest()?.initialURL
    }

    func takePendingArchiveURLs() -> [URL] {
        takePendingArchiveRequests().compactMap(\.initialURL)
    }
}
