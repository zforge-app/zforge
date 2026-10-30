import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("Sidebar Locations item menu")
@MainActor
struct SidebarLocationMenuTests {
    private let english = Locale(identifier: "en")

    private func volume(_ name: String, path: String, kind: SidebarVolume.Kind, ejectable: Bool,
                        root: Bool = false) -> SidebarVolume {
        SidebarVolume(url: URL(fileURLWithPath: path, isDirectory: true), name: name, kind: kind,
                      isEjectable: ejectable, isRemovable: kind == .removable, isRootFileSystem: root)
    }

    private var ventoy: SidebarVolume { volume("Ventoy", path: "/Volumes/Ventoy", kind: .removable, ejectable: true) }
    private var macintoshHD: SidebarVolume {
        volume("Macintosh HD", path: "/", kind: .internalDisk, ejectable: false, root: true)
    }
    private var dataDisk: SidebarVolume { volume("Data", path: "/Volumes/Data", kind: .internalDisk, ejectable: false) }
    private var share: SidebarVolume { volume("Projects", path: "/Volumes/Projects", kind: .network, ejectable: true) }

    private func menu(_ volume: SidebarVolume, isEjecting: Bool = false,
                      perform: @escaping @MainActor (SidebarVolumeMenuCommand) -> Void = { _ in }) -> NSMenu {
        menu(volume.name, volume.url, kind: volume.locationKind, canEject: volume.isEjectable,
             isEjecting: isEjecting, perform: perform)
    }

    private func menu(_ name: String, _ url: URL, kind: SidebarLocationKind, canEject: Bool = false,
                      isEjecting: Bool = false,
                      perform: @escaping @MainActor (SidebarVolumeMenuCommand) -> Void = { _ in }) -> NSMenu {
        let standard = SidebarItemMenu.standard(for: url, canRemoveFromSidebar: true, locale: english) { _ in }
        return SidebarItemMenu.location(
            standard: standard, name: name,
            commands: SidebarLocationMenu.commands(for: kind, canEject: canEject),
            isEjecting: isEjecting, locale: english, perform: perform
        ).nsMenu()
    }

    /// Titles in order, with "—" for each separator.
    private func layout(_ menu: NSMenu) -> [String] {
        menu.items.map { $0.isSeparatorItem ? "—" : $0.title }
    }

    private func enabledTitles(_ menu: NSMenu) -> [String] {
        menu.items.filter { !$0.isSeparatorItem && $0.isEnabled }.map(\.title)
    }

    // MARK: - Per-kind layout

    @Test("A removable volume matches Finder's menu for Ventoy item by item")
    func removableVolumeMatchesFinder() {
        let built = menu(ventoy)
        #expect(layout(built) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Eject “Ventoy”", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
        #expect(built.items.compactMap { $0.identifier?.rawValue } == [
            "sidebar-menu-open-in-new-tab", "sidebar-menu-show-in-enclosing-folder", "sidebar-menu-eject",
            "sidebar-menu-remove-from-sidebar", "sidebar-menu-get-info"
        ])
        #expect(built.items.filter { !$0.isSeparatorItem }.allSatisfy { $0.image != nil })
        #expect(!layout(built).contains("Erase Disk…"))
        #expect(!layout(built).contains("Rename “Ventoy”"))
        #expect(SidebarVolumeMenuCommand.allCases == [.eject])
        // Add to Dock (2026-10-29), Erase Disk… and Rename “Name” (2026-10-30) were removed at the
        // user's request: the App Sandbox cannot perform them (Ventoy, mounted by root, refused the
        // rename). Every remaining item is enabled.
        #expect(enabledTitles(built) == [
            "Open in New Tab", "Show in Enclosing Folder", "Eject “Ventoy”",
            "Remove from Sidebar", "Get Info"
        ])
    }

    @Test("The boot volume is never ejected or renamed, and has no enclosing folder")
    func bootVolume() {
        let built = menu(macintoshHD)
        #expect(macintoshHD.locationKind == .bootVolume)
        #expect(layout(built) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
        #expect(!enabledTitles(built).contains("Show in Enclosing Folder"))
    }

    @Test("A fixed internal volume has no Eject or Rename")
    func internalVolume() {
        #expect(dataDisk.locationKind == .internalVolume)
        #expect(layout(menu(dataDisk)) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
    }

    @Test("No Locations item offers Rename, whatever its kind")
    func noVolumeOffersRename() {
        let image = volume("Installer", path: "/Volumes/Installer", kind: .removable, ejectable: true)
        for built in [menu(ventoy), menu(macintoshHD), menu(dataDisk), menu(share), menu(image)] {
            #expect(!built.items.contains { $0.identifier?.rawValue == "sidebar-menu-rename" })
            #expect(!built.items.contains { $0.title.hasPrefix("Rename") })
        }
        #expect(layout(menu(image)).contains("Eject “Installer”"))
    }

    @Test("An ejectable external disk that is not removable media is still an external disk")
    func ejectableInternalKindIsExternal() {
        let external = volume("Backup", path: "/Volumes/Backup", kind: .internalDisk, ejectable: true)
        #expect(external.locationKind == .externalVolume)
        #expect(layout(menu(external)).contains("Eject “Backup”"))
    }

    @Test("A network share can be ejected")
    func networkVolume() {
        #expect(share.locationKind == .networkVolume)
        #expect(layout(menu(share)) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Eject “Projects”", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
    }

    @Test("The home folder gets the shared menu only")
    func homeFolder() {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        #expect(layout(menu("tester", home, kind: .home, canEject: true)) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
    }

    @Test("Eject is disabled while that volume is ejecting")
    func ejectDisabledWhileEjecting() throws {
        let built = menu(ventoy, isEjecting: true)
        let eject = try #require(built.items.first { $0.identifier?.rawValue == "sidebar-menu-eject" })
        #expect(!eject.isEnabled)
    }

    @Test("Volume titles are localized with the volume name")
    func localizedTitles() {
        let standard = SidebarItemMenu.standard(for: ventoy.url, canRemoveFromSidebar: true,
                                                locale: Locale(identifier: "pt-BR")) { _ in }
        let built = SidebarItemMenu.location(
            standard: standard, name: "Ventoy", commands: [.eject],
            locale: Locale(identifier: "pt-BR")) { _ in }.nsMenu()
        let titles = built.items.filter { !$0.isSeparatorItem }.map(\.title)
        #expect(titles.contains("Ejetar “Ventoy”"))
    }

    @Test("Each volume item runs exactly its own command")
    func itemsRunTheirCommands() {
        final class Recorder { var commands: [SidebarVolumeMenuCommand] = [] }
        let recorder = Recorder()
        let built = menu(ventoy) { recorder.commands.append($0) }
        let eject = built.items.firstIndex { $0.identifier?.rawValue == "sidebar-menu-eject" }
        if let eject { built.performActionForItem(at: eject) }
        #expect(recorder.commands == [.eject])
    }

    // MARK: - Categories and names

    @Test("Each kind is hidden through Finder's Settings ▸ Sidebar category")
    func categories() {
        #expect(SidebarLocationKind.home.category == .home)
        #expect(SidebarLocationKind.computer.category == .computer)
        #expect(SidebarLocationKind.bootVolume.category == .hardDisks)
        #expect(SidebarLocationKind.internalVolume.category == .hardDisks)
        #expect(SidebarLocationKind.externalVolume.category == .externalDisks)
        #expect(SidebarLocationKind.networkVolume.category == .connectedServers)
        #expect(SidebarLocationMenu.commands(for: .computer, canEject: true).isEmpty)
        #expect(SidebarLocationCategory.allCases == [.computer, .home, .hardDisks, .externalDisks, .network, .connectedServers],
                "Settings ▸ Sidebar lists the categories in the order of the Locations and Shared rows")
    }

    @Test("Hidden Locations categories persist and can be shown again")
    func hiddenCategoriesPersist() throws {
        let suite = "SidebarLocationsHidden-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(SidebarLocationCategory.allCases.allSatisfy(preferences.isSidebarLocationVisible))

        preferences.setSidebarLocation(.externalDisks, visible: false)
        preferences.setSidebarLocation(.home, visible: false)
        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(!reloaded.isSidebarLocationVisible(.externalDisks))
        #expect(!reloaded.isSidebarLocationVisible(.home))
        #expect(reloaded.isSidebarLocationVisible(.hardDisks))

        reloaded.setSidebarLocation(.externalDisks, visible: true)
        #expect(FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.externalDisks))
    }

    // MARK: - Actions in a window

    private func state(defaults: UserDefaults) -> FileBrowserState {
        FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
                         grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine())
    }

    @Test("Remove from Sidebar on a volume hides its category and leaves Favorites alone")
    func removeFromSidebarHidesCategory() throws {
        let suite = "SidebarLocationsRemove-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let browser = state(defaults: defaults)
        defer { browser.close() }
        let sidebar = SidebarState()
        let pinned = URL(fileURLWithPath: "/Volumes/Ventoy", isDirectory: true)
        sidebar.pinnedFolders = PinnedFolderStore(defaults: defaults, initialURLs: [pinned])
        var focusRestored = 0
        let actions = SidebarItemMenuActions(browser: browser, sidebar: sidebar) { focusRestored += 1 }

        let built = actions.locationMenu(name: "Ventoy", url: ventoy.url, kind: .externalVolume,
                                         canEject: true).nsMenu()
        let remove = try #require(built.items.firstIndex { $0.identifier?.rawValue == "sidebar-menu-remove-from-sidebar" })
        built.performActionForItem(at: remove)

        #expect(!browser.preferences.isSidebarLocationVisible(.externalDisks))
        #expect(browser.preferences.isSidebarLocationVisible(.hardDisks))
        #expect(sidebar.pinnedFolders.urls.map(\.path) == [pinned.path])
        #expect(focusRestored == 1)
    }

    @Test("The computer item's menu only removes it, hiding the computer category")
    func computerMenuRemovesComputer() throws {
        let suite = "SidebarLocationsComputer-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let browser = state(defaults: defaults)
        defer { browser.close() }
        let actions = SidebarItemMenuActions(browser: browser, sidebar: SidebarState())

        let built = actions.computerMenu().nsMenu()
        #expect(built.items.compactMap { $0.identifier?.rawValue } == ["sidebar-menu-remove-from-sidebar"])
        built.performActionForItem(at: 0)

        #expect(!browser.preferences.isSidebarLocationVisible(.computer))
        #expect(browser.preferences.isSidebarLocationVisible(.home))
    }

    @Test("The Network item's menu only removes it, hiding the Network category until Settings shows it again")
    func networkMenuRemovesNetwork() throws {
        let suite = "SidebarLocationsNetwork-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let browser = state(defaults: defaults)
        defer { browser.close() }
        browser.preferences.language = .english
        var focusRestored = 0
        let actions = SidebarItemMenuActions(browser: browser, sidebar: SidebarState()) { focusRestored += 1 }
        #expect(browser.preferences.isSidebarLocationVisible(.network), "Network is shown by default")

        let built = actions.networkMenu().nsMenu()
        #expect(layout(built) == ["Remove from Sidebar"], "No folder command applies to the virtual Network level")
        #expect(built.items.compactMap { $0.identifier?.rawValue } == ["sidebar-menu-remove-from-sidebar"])
        built.performActionForItem(at: 0)

        #expect(!browser.preferences.isSidebarLocationVisible(.network))
        #expect(browser.preferences.isSidebarLocationVisible(.computer))
        #expect(browser.preferences.isSidebarLocationVisible(.connectedServers), "Shared volumes stay")
        #expect(focusRestored == 1)
        #expect(!FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.network), "The choice persists")

        browser.preferences.setSidebarLocation(.network, visible: true)
        #expect(FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.network))
    }

    /// Zforge no longer renames volumes, but one renamed by Finder or Disk Utility is still followed.
    @Test("A window inside a renamed volume follows it to the same folder at the new mount point")
    func followsRenamedVolume() async throws {
        let base = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("SidebarRename-\(UUID())")
        let old = base.appendingPathComponent("OldName", isDirectory: true)
        let new = base.appendingPathComponent("NewName", isDirectory: true)
        try FileManager.default.createDirectory(at: old.appendingPathComponent("Sub"), withIntermediateDirectories: true)
        let suite = "SidebarLocationsFollow-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite); try? FileManager.default.removeItem(at: base) }
        let browser = state(defaults: defaults)
        defer { browser.close() }
        await browser.navigateToSidebar(old.appendingPathComponent("Sub"), name: "Sub")
        try FileManager.default.moveItem(at: old, to: new)

        await browser.followRenamedVolume(from: base.appendingPathComponent("Unrelated"), to: new)
        #expect(browser.currentDirectoryURL?.standardizedFileURL.path == old.appendingPathComponent("Sub").path)

        await browser.followRenamedVolume(from: old, to: new)
        #expect(browser.currentDirectoryURL?.standardizedFileURL.path
            == new.appendingPathComponent("Sub").standardizedFileURL.path)
    }
}
