import Foundation

/// The open browser windows, so that quitting can close them before it waits for the
/// write-backs of the archives inside archives they leave (D-98).
@MainActor
final class ArchiveWindowRegistry {
    static let shared = ArchiveWindowRegistry()

    private struct Entry {
        weak var state: FileBrowserState?
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    var openBrowsers: [FileBrowserState] {
        entries.values.compactMap(\.state)
    }

    func register(_ state: FileBrowserState) {
        entries[ObjectIdentifier(state)] = Entry(state: state)
    }

    func unregister(_ state: FileBrowserState) {
        entries.removeValue(forKey: ObjectIdentifier(state))
    }

    /// Closes every browser window and waits until each has released its sessions, which
    /// writes modified archives inside archives back from the innermost up (quitting).
    func closeAllWindows() async {
        let browsers = openBrowsers
        for browser in browsers where !browser.isClosedForRegistry { browser.closeWindow() }
        for browser in browsers { await browser.closingTask?.value }
    }

    /// Whether a window entered an archive inside an archive: quitting then waits for the
    /// write-backs that closing it may start.
    var showsInnerArchives: Bool {
        openBrowsers.contains(where: \.hasOpenedInnerArchives)
    }
}
