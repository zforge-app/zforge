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
    /// Every browser window, to know whether one is open to take a request.
    private let browserWindows = NSHashTable<NSWindow>.weakObjects()
    /// Opens a browser window. SwiftUI adds no window for files and URLs opened from outside
    /// (`handlesExternalEvents(matching: [])`), so a request that no open window takes, such as
    /// the archive that launched Zforge, opens its own through this (ZF-78).
    private(set) var windowOpener: ((BrowserWindowRequest) -> Void)?
    /// Until launching ends, SwiftUI may still create the default window, which takes the
    /// waiting requests; the opener is used only after.
    private(set) var hasFinishedLaunching = false
    /// Open-or-extract questions are asked one at a time.
    private var archiveChoice: Task<Void, Never>?
    lazy var archiveOpening = FinderArchiveOpeningEnvironment.live

    func applicationWillFinishLaunching(_ notification: Notification) {
        // UI test launches keep window frames out of the user's preferences (D-63).
        UITestLaunchIsolation.startIfNeeded()
        // The unit test host stays out of the Dock and the app switcher (RNF-Q08).
        UnitTestHostPresentation.applyIfNeeded(to: NSApplication.shared)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        launchDidFinish()
        // Archives inside archives write back into the archives containing them when they close.
        ArchiveWriteBackCoordinator.shared.start()
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

    /// Quitting waits for archives inside archives to be written back (D-98): the windows
    /// close, releasing them innermost first, and the write-backs run with visible progress.
    /// An extraction started from Finder is cancelled first (ZF-78).
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let coordinator = ArchiveWriteBackCoordinator.shared
        let extraction = ArchiveExtractionCoordinator.shared
        guard ArchiveWindowRegistry.shared.showsInnerArchives || !coordinator.isIdle || !extraction.isIdle else {
            return .terminateNow
        }
        Task { @MainActor in
            extraction.cancelAll()
            await extraction.waitUntilIdle()
            await ArchiveWindowRegistry.shared.closeAllWindows()
            await coordinator.finishPendingWriteBacks()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        archiveIndexRuntime?.stop()
        BrowserWindowLifecycle.shared.applicationWillTerminate(orderedWindows: NSApp.orderedWindows)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.contains(where: { $0.scheme == FinderRequestInbox.urlScheme }) {
            receiveFinderRequests(from: FinderRequestInbox.shared())
        }
        // Several volumes of one split archive open or extract it once (ZF-83).
        let archives = ArchiveVolumeName.onePerSet(
            urls.filter { $0.isFileURL && ArchiveFormatRegistry.recognizes($0.lastPathComponent) })
        guard !archives.isEmpty else { return }
        receiveOpenedArchives(archives)
    }

    /// Archives sent by Finder (double click, Open With, a drop on the Dock icon). Where
    /// Zforge opens the archive's type by default, the Settings choice decides: ask,
    /// open, or extract showing only the progress (ZF-78); the others open.
    func receiveOpenedArchives(_ archives: [URL]) {
        let routing = FinderArchiveRouting.route(
            archives, choice: archiveOpening.preferences.finderArchiveOpening,
            opensByDefault: archiveOpening.opensByDefault)
        openArchives(routing.open)
        if !routing.extract.isEmpty { archiveOpening.extract(routing.extract) }
        if !routing.ask.isEmpty { askOpenOrExtract(routing.ask) }
    }

    private func openArchives(_ archives: [URL]) {
        guard !archives.isEmpty else { return }
        pendingArchives.append(contentsOf: archives.map { BrowserWindowRequest(initialURL: $0) })
        announcePendingRequests()
    }

    private func askOpenOrExtract(_ archives: [URL]) {
        let previous = archiveChoice
        archiveChoice = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            let answer = await archiveOpening.ask(archives.map(\.lastPathComponent))
            if let answer, answer.remember { archiveOpening.preferences.finderArchiveOpening = answer.choice }
            switch answer?.choice {
            case .open: openArchives(archives)
            case .extract: archiveOpening.extract(archives)
            default: break
            }
        }
    }

    /// Waits until every open-or-extract question asked so far is answered (tests).
    func waitForArchiveChoices() async {
        await archiveChoice?.value
    }

    /// Open browser windows take waiting requests; with none open, each opens its own window.
    private func announcePendingRequests() {
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
        openUntakenRequests()
    }

    /// Launching is over: a launch by a file or URL creates no default window, so the
    /// requests that no window took open their own (ZF-78).
    func launchDidFinish() {
        hasFinishedLaunching = true
        openUntakenRequests()
    }

    private func openUntakenRequests() {
        guard hasFinishedLaunching, !pendingArchives.isEmpty, !hasOpenBrowserWindow, let windowOpener else { return }
        for request in takePendingArchiveRequests() { windowOpener(request) }
    }

    private var hasOpenBrowserWindow: Bool {
        browserWindows.allObjects.contains { $0.isVisible || $0.isMiniaturized }
    }

    /// The app's way to open a browser window, from its commands, which exist before any
    /// window does; the first one offered is kept. Requests waiting with no window to take
    /// them open right after, outside the SwiftUI update that offered it.
    func offerWindowOpener(_ opener: @escaping (BrowserWindowRequest) -> Void) {
        guard windowOpener == nil else { return }
        windowOpener = opener
        DispatchQueue.main.async { [weak self] in self?.openUntakenRequests() }
    }

    /// Records a browser window, so requests go to the open ones.
    func registerBrowserWindow(_ window: NSWindow) {
        browserWindows.add(window)
    }

    func receiveAutomationArchive(_ url: URL, lease: AutomationAccessLease) {
        guard ArchiveFormatRegistry.recognizes(url.lastPathComponent) else { return }
        pendingArchives.append(BrowserWindowRequest(initialURL: url, automationAccess: BrowserOpeningAccess(lease)))
        announcePendingRequests()
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
        announcePendingRequests()
    }

    /// Opens a results window for an archive name search requested by Siri.
    func receiveArchiveSearch(_ term: String) {
        pendingArchives.append(BrowserWindowRequest(archiveSearch: term))
        announcePendingRequests()
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

    /// Ends the launch window's offer when it presents other content.
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
