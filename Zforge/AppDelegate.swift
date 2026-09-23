import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let archiveURLsReceived = Notification.Name("ZforgeArchiveURLsReceived")

    private var pendingArchiveURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else { return }
        NSApplication.shared.applicationIconImage = icon
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let archives = urls.filter { ArchiveFormatRegistry.recognizes($0.lastPathComponent) }
        guard !archives.isEmpty else { return }

        pendingArchiveURLs.append(contentsOf: archives)
        NotificationCenter.default.post(name: Self.archiveURLsReceived, object: self)
    }

    func takeNextArchiveURL() -> URL? {
        guard !pendingArchiveURLs.isEmpty else { return nil }
        return pendingArchiveURLs.removeFirst()
    }

    func takePendingArchiveURLs() -> [URL] {
        defer { pendingArchiveURLs.removeAll() }
        return pendingArchiveURLs
    }
}
