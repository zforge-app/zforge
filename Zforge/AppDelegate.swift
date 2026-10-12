import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var current: AppDelegate?
    static let archiveURLsReceived = Notification.Name("ZforgeArchiveURLsReceived")

    private var pendingArchives: [BrowserWindowRequest] = []
    private var archiveIndexRuntime: ArchiveIndexRuntime?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        if !ProcessInfo.processInfo.arguments.contains("--ui-fixtures"),
           ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
           NSClassFromString("XCTestCase") == nil {
            archiveIndexRuntime = .shared
            archiveIndexRuntime?.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        archiveIndexRuntime?.stop()
        BrowserWindowLifecycle.shared.applicationWillTerminate(orderedWindows: NSApp.orderedWindows)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
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
