import AppKit
import FinderSync
import OSLog

/// Adds a single Zforge submenu to Finder's shortcut menu. Finder's own archive
/// items cannot be redirected, so nothing is placed beside them at the top level.
/// The extension only describes the request; the app authorizes and runs it.
final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "io.libor.Zforge.FinderExtension", category: "FinderMenu")

    override init() {
        super.init()
        // Finder offers extension menus only inside monitored folders.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems,
              let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return nil }
        let actions = FinderMenuPolicy.actions(for: urls, isDirectory: Self.isDirectory)
        guard !actions.isEmpty else { return nil }
        nonisolated(unsafe) var menu: NSMenu?
        Self.onMain { menu = Self.makeMenu(actions: actions, urls: urls) }
        return menu
    }

    @MainActor private static func makeMenu(actions: [BrowserSelectionAction], urls: [URL]) -> NSMenu {
        let submenu = NSMenu(title: "Zforge")
        // Finder shows extension images as they are; the menu is rebuilt each time it
        // opens, so painting the symbols in the current text color follows theme changes.
        let textColor = MenuSymbolImage.menuTextColor(for: NSApplication.shared.effectiveAppearance)
        let imageWidth = actions.compactMap { $0.menuSymbol.flatMap { MenuSymbolImage.image(for: $0)?.size } }
            .map { max($0.width, $0.height) }.max() ?? 0
        for action in actions {
            let item = NSMenuItem(title: title(action, urls: urls), action: #selector(performAction(_:)), keyEquivalent: "")
            // Finder copies menu items and keeps their tag, not their represented object.
            item.tag = BrowserSelectionAction.allCases.firstIndex(of: action) ?? -1
            // Finder reserves no image column: symbols share one width, and an item without
            // a symbol would get a blank image of that width to keep its title aligned.
            item.image = MenuSymbolImage.bitmapCopy(action.menuSymbol.flatMap { MenuSymbolImage.image(for: $0) },
                                                    size: NSSize(width: imageWidth, height: imageWidth), tint: textColor)
            submenu.addItem(item)
        }
        let root = NSMenuItem(title: "Zforge", action: nil, keyEquivalent: "")
        root.image = appIcon()
        root.submenu = submenu
        let menu = NSMenu(title: "")
        menu.addItem(root)
        return menu
    }

    @objc func performAction(_ sender: Any?) {
        nonisolated(unsafe) let sender = sender
        var tag = -1
        Self.onMain { tag = (sender as? NSMenuItem)?.tag ?? -1 }
        guard BrowserSelectionAction.allCases.indices.contains(tag),
              let urls = FIFinderSyncController.default().selectedItemURLs(), !urls.isEmpty else { return }
        let action = BrowserSelectionAction.allCases[tag]
        guard FinderMenuPolicy.actions(for: urls, isDirectory: Self.isDirectory).contains(action) else { return }
        guard let inbox = FinderRequestInbox.shared() else {
            logger.error("The Finder request inbox is unavailable.")
            return
        }
        do {
            try inbox.submit(FinderMenuRequest(action: action, urls: urls))
            NSWorkspace.shared.open(FinderRequestInbox.wakeURL)
        } catch {
            logger.error("Could not submit a Finder request: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? url.hasDirectoryPath
    }

    private static func title(_ action: BrowserSelectionAction, urls: [URL]) -> String {
        switch action {
        case .open: String(localized: "Open")
        case .compress: String(localized: "Compress")
        case .compressCustom: String(localized: "Compress Custom…")
        case .addToArchive: String(localized: "Add to Archive…")
        case .removeFromArchive: String(localized: "Remove from Archive…")
        case .extractHere: String(localized: "Extract Here")
        case .extractNamed:
            String(format: String(localized: "Extract to \"%@\""),
                   FinderMenuPolicy.extractionNames(for: urls, fallback: String(localized: "Archive")))
        case .extractChoose: String(localized: "Extract…")
        case .validate: String(localized: "Validate")
        }
    }

    /// The containing app's icon, sized for a menu item. Finder drops the whole menu
    /// when an image cannot cross into its process, as with the icon services image
    /// returned by NSWorkspace; a full-color bitmap copy can.
    @MainActor private static func appIcon() -> NSImage? {
        // Zforge.app/Contents/PlugIns/ZforgeFinderExtension.appex
        let app = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let icon = NSWorkspace.shared.icon(forFile: app.path)
        icon.size = NSSize(width: 16, height: 16)
        return MenuSymbolImage.bitmapCopy(icon)
    }

    /// Finder calls the extension off the main thread; AppKit menus are built on it.
    private static func onMain(_ body: @MainActor () -> Void) {
        if Thread.isMainThread { MainActor.assumeIsolated(body) } else { DispatchQueue.main.sync { MainActor.assumeIsolated(body) } }
    }
}
