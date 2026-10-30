import AppKit
import SwiftUI

// Shared context menu for sidebar destinations, in Finder's order and grouping:
//
//   Open in New Tab · Show in Enclosing Folder
//   ─────────────
//   Remove from Sidebar
//   ─────────────
//   Get Info
//
// API (Favorites uses it; other sections append their own items):
// - `SidebarItemMenu.standard(for:canRemoveFromSidebar:locale:perform:)` builds the model
//   for a folder or volume URL. `perform` receives the chosen `SidebarItemMenuCommand`.
// - `groups` is `[[SidebarItemMenuItem]]`; each inner array is one separator-delimited
//   group. Insert section-specific groups (for example volume actions) with
//   `inserting(_:at:)` before rendering; build extra items with `SidebarItemMenuItem.init`.
// - `SidebarItemMenuContent(menu:)` renders the model inside `.contextMenu { }`;
//   `nsMenu()` builds the equivalent `NSMenu` so tests can check titles, order,
//   separators, enablement and actions offscreen.
// - `SidebarItemMenuActions(browser:sidebar:)` executes the standard commands for a window.

/// The standard sidebar item commands, shared by every sidebar section.
enum SidebarItemMenuCommand: String, CaseIterable, Hashable {
    case openInNewTab = "open-in-new-tab"
    case showInEnclosingFolder = "show-in-enclosing-folder"
    case removeFromSidebar = "remove-from-sidebar"
    case getInfo = "get-info"
}

struct SidebarItemMenuItem: Identifiable {
    /// Stable identifier; standard items use their command's raw value.
    let id: String
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let perform: @MainActor () -> Void
}

struct SidebarItemMenu {
    var groups: [[SidebarItemMenuItem]]

    static func standard(
        for url: URL,
        canRemoveFromSidebar: Bool,
        locale: Locale?,
        perform: @escaping @MainActor (SidebarItemMenuCommand) -> Void
    ) -> SidebarItemMenu {
        func item(_ command: SidebarItemMenuCommand, _ title: String.LocalizationValue,
                  _ systemImage: String, enabled: Bool = true) -> SidebarItemMenuItem {
            SidebarItemMenuItem(id: command.rawValue, title: AppLocalization.string(title, locale: locale),
                                systemImage: systemImage, isEnabled: enabled) { perform(command) }
        }
        let hasEnclosingFolder = url.standardizedFileURL.path != "/"
        var groups = [[
            item(.openInNewTab, "Open in New Tab", "plus.rectangle.on.rectangle"),
            item(.showInEnclosingFolder, "Show in Enclosing Folder", "folder", enabled: hasEnclosingFolder)
        ]]
        if canRemoveFromSidebar {
            groups.append([item(.removeFromSidebar, "Remove from Sidebar", "pin.slash")])
        }
        groups.append([item(.getInfo, "Get Info", "info.circle")])
        return SidebarItemMenu(groups: groups)
    }

    func inserting(_ group: [SidebarItemMenuItem], at index: Int) -> SidebarItemMenu {
        var copy = self
        copy.groups.insert(group, at: min(max(index, 0), groups.count))
        return copy
    }

    @MainActor
    func nsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for (index, group) in groups.enumerated() where !group.isEmpty {
            if index > 0 { menu.addItem(.separator()) }
            for entry in group {
                let menuItem = ClosureMenuItem(title: entry.title, systemImage: entry.systemImage,
                                               isEnabled: entry.isEnabled, handler: entry.perform)
                menuItem.identifier = NSUserInterfaceItemIdentifier("sidebar-menu-\(entry.id)")
                menu.addItem(menuItem)
            }
        }
        return menu
    }
}

struct SidebarItemMenuContent: View {
    let menu: SidebarItemMenu

    var body: some View {
        ForEach(Array(menu.groups.enumerated()), id: \.offset) { index, group in
            if index > 0 { Divider() }
            ForEach(group) { entry in
                Button(entry.title, systemImage: entry.systemImage) { entry.perform() }
                    .disabled(!entry.isEnabled)
                    .accessibilityIdentifier("sidebar-menu-\(entry.id)")
            }
        }
    }
}

/// Runs the standard commands in the window that owns `browser`.
@MainActor
struct SidebarItemMenuActions {
    let browser: FileBrowserState
    let sidebar: SidebarState
    var restoreContentFocus: () -> Void = {}

    func perform(_ command: SidebarItemMenuCommand, url: URL) {
        switch command {
        case .openInNewTab:
            Task { await browser.openSidebarDestinationInNewTab(url) }
        case .showInEnclosingFolder:
            Task { await browser.showInEnclosingFolder(url) }
        case .removeFromSidebar:
            sidebar.pinnedFolders.remove(url)
        case .getInfo:
            Task { await browser.showGetInfo(forSidebarDestination: url) }
            return
        }
        restoreContentFocus()
    }

    func menu(for url: URL, canRemoveFromSidebar: Bool) -> SidebarItemMenu {
        SidebarItemMenu.standard(for: url, canRemoveFromSidebar: canRemoveFromSidebar,
                                 locale: browser.preferences.language.locale) { perform($0, url: url) }
    }
}
