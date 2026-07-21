import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var externalWindows: [NSWindowController] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where ArchiveFormatRegistry.recognizes(url.lastPathComponent) {
            let content = NSHostingController(rootView: ContentView(initialURL: url))
            let window = NSWindow(contentViewController: content)
            let controller = NSWindowController(window: window)
            window.title = url.lastPathComponent
            window.setContentSize(NSSize(width: 1100, height: 720))
            window.minSize = NSSize(width: 678, height: 460)
            window.tabbingIdentifier = "io.libor.Zforge.browser"
            window.tabbingMode = .automatic
            window.representedURL = url
            window.center()
            window.delegate = self
            externalWindows.append(controller)
            controller.showWindow(nil)
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        externalWindows.removeAll { $0.window === window }
    }
}
