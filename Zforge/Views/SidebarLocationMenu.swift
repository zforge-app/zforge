import AppKit
import SwiftUI

/// Finder's sidebar settings show or hide Locations items by category, not one by one.
/// "Remove from Sidebar" on a Locations item hides its whole category, and Settings ▸ Sidebar
/// shows it again.
nonisolated enum SidebarLocationCategory: String, CaseIterable, Sendable {
    case computer
    case home
    case hardDisks
    case externalDisks
    case connectedServers
}

/// The kinds of items in the sidebar Locations and Shared sections, each with its own
/// Finder context menu.
nonisolated enum SidebarLocationKind: Hashable, Sendable {
    case computer
    case home
    case bootVolume
    case internalVolume
    case externalVolume
    case networkVolume

    var category: SidebarLocationCategory {
        switch self {
        case .computer: .computer
        case .home: .home
        case .bootVolume, .internalVolume: .hardDisks
        case .externalVolume: .externalDisks
        case .networkVolume: .connectedServers
        }
    }

    var isVolume: Bool {
        switch self {
        case .computer, .home: false
        case .bootVolume, .internalVolume, .externalVolume, .networkVolume: true
        }
    }
}

/// Commands a Locations item adds to the shared `SidebarItemMenu`.
/// Zforge doesn't rename volumes: the App Sandbox denies Disk Arbitration's rename
/// authorization for volumes the user doesn't own (OR-25, Rename “Name” removed 2026-10-30).
nonisolated enum SidebarVolumeMenuCommand: String, CaseIterable, Hashable, Sendable {
    case eject
}

/// Which volume commands a Locations item shows, following Finder:
///
///   Open in New Tab · Show in Enclosing Folder
///   ───  Eject “Name”            (ejectable volumes and network shares)
///   ───  Remove from Sidebar
///   ───  Get Info
nonisolated enum SidebarLocationMenu {
    static func commands(for kind: SidebarLocationKind, canEject: Bool) -> Set<SidebarVolumeMenuCommand> {
        var commands: Set<SidebarVolumeMenuCommand> = []
        if kind.isVolume, canEject { commands.insert(.eject) }
        // Finder's Erase Disk… and Rename “Name” are not offered: the App Sandbox blocks erasing
        // (OR-23) and renaming volumes the user doesn't own (OR-25); both removed 2026-10-30.
        return commands
    }
}

extension SidebarVolume {
    /// Local ejectable volumes (USB drives, SD cards, external disks, disk images) are external
    /// disks; Finder files them under Settings ▸ Sidebar ▸ External disks.
    var locationKind: SidebarLocationKind {
        if kind == .network { return .networkVolume }
        if isRootFileSystem { return .bootVolume }
        return isEjectable ? .externalVolume : .internalVolume
    }
}

extension SidebarItemMenu {
    /// The shared sidebar menu with a Locations item's volume groups added in Finder's order.
    /// `standard` must be built with `canRemoveFromSidebar: true`.
    static func location(
        standard: SidebarItemMenu,
        name: String,
        commands: Set<SidebarVolumeMenuCommand>,
        isEjecting: Bool = false,
        locale: Locale?,
        perform: @escaping @MainActor (SidebarVolumeMenuCommand) -> Void
    ) -> SidebarItemMenu {
        func item(_ command: SidebarVolumeMenuCommand, _ title: String.LocalizationValue,
                  _ systemImage: String, enabled: Bool = true) -> SidebarItemMenuItem {
            SidebarItemMenuItem(id: command.rawValue, title: AppLocalization.string(title, locale: locale),
                                systemImage: systemImage, isEnabled: enabled) { perform(command) }
        }
        var menu = standard
        let removeIndex = menu.groups.firstIndex {
            $0.contains { $0.id == SidebarItemMenuCommand.removeFromSidebar.rawValue }
        } ?? 1
        var volumeGroups: [[SidebarItemMenuItem]] = []
        if commands.contains(.eject) {
            volumeGroups.append([item(.eject, "Eject “\(name)”", "eject", enabled: !isEjecting)])
        }
        menu.groups.insert(contentsOf: volumeGroups, at: min(removeIndex, menu.groups.count))
        return menu
    }
}

extension SidebarItemMenuActions {
    /// The computer item opens the virtual computer level, which has no folder to reveal or
    /// inspect and cannot open in a tab yet, so its menu only removes it from the sidebar.
    func computerMenu() -> SidebarItemMenu {
        virtualLocationMenu(hiding: .computer)
    }

    private func virtualLocationMenu(hiding category: SidebarLocationCategory) -> SidebarItemMenu {
        let title = AppLocalization.string("Remove from Sidebar", locale: browser.preferences.language.locale)
        return SidebarItemMenu(groups: [[
            SidebarItemMenuItem(id: SidebarItemMenuCommand.removeFromSidebar.rawValue, title: title,
                                systemImage: "pin.slash", isEnabled: true) {
                browser.preferences.setSidebarLocation(category, visible: false)
                restoreContentFocus()
            }
        ]])
    }

    /// The context menu of a Locations or Shared item. Remove from Sidebar hides the item's
    /// category (Settings ▸ Sidebar shows it again) instead of unpinning a favorite.
    func locationMenu(name: String, url: URL, kind: SidebarLocationKind, canEject: Bool) -> SidebarItemMenu {
        let locale = browser.preferences.language.locale
        let standard = SidebarItemMenu.standard(for: url, canRemoveFromSidebar: true, locale: locale) { command in
            guard command == .removeFromSidebar else { return perform(command, url: url) }
            browser.preferences.setSidebarLocation(kind.category, visible: false)
            restoreContentFocus()
        }
        return .location(
            standard: standard, name: name,
            commands: SidebarLocationMenu.commands(for: kind, canEject: canEject),
            isEjecting: browser.ejectingVolumeURLs.contains(url.standardizedFileURL), locale: locale
        ) { command in
            switch command {
            case .eject:
                restoreContentFocus()
                Task { await browser.ejectVolume(at: url, name: name) }
            }
        }
    }
}
