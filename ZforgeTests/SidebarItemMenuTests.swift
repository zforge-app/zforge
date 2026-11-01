import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("Shared sidebar item menu")
@MainActor
struct SidebarItemMenuTests {
    private let english = Locale(identifier: "en")
    private let downloads = URL(fileURLWithPath: "/Users/tester/Downloads", isDirectory: true)

    private func menu(for url: URL, canRemove: Bool = true, locale: Locale? = Locale(identifier: "en"),
                      perform: @escaping @MainActor (SidebarItemMenuCommand) -> Void = { _ in }) -> NSMenu {
        SidebarItemMenu.standard(for: url, canRemoveFromSidebar: canRemove, locale: locale, perform: perform).nsMenu()
    }

    /// Titles in order, with "—" for each separator.
    private func layout(_ menu: NSMenu) -> [String] {
        menu.items.map { $0.isSeparatorItem ? "—" : $0.title }
    }

    @Test("A favorite offers Finder's commands in Finder's order and grouping")
    func favoriteOrderAndGrouping() {
        #expect(layout(menu(for: downloads)) == [
            "Open in New Tab", "Show in Enclosing Folder", "—",
            "Remove from Sidebar", "—",
            "Get Info"
        ])
        #expect(menu(for: downloads).items.compactMap { $0.identifier?.rawValue } == [
            "sidebar-menu-open-in-new-tab", "sidebar-menu-show-in-enclosing-folder",
            "sidebar-menu-remove-from-sidebar", "sidebar-menu-get-info"
        ])
    }

    @Test("Every command has a symbol, is enabled for a favorite, and Add to Dock is not offered")
    func symbolsAndEnablement() {
        let items = menu(for: downloads).items.filter { !$0.isSeparatorItem }
        #expect(items.allSatisfy { $0.image != nil })
        #expect(items.allSatisfy { $0.isEnabled })
        // Removed at the user's request (2026-10-29): the App Sandbox cannot add Dock items.
        #expect(!items.contains { $0.title == "Add to Dock" })
        #expect(SidebarItemMenuCommand.allCases == [.openInNewTab, .showInEnclosingFolder, .removeFromSidebar, .getInfo])
    }

    @Test("The startup disk root has no enclosing folder to show")
    func rootHasNoEnclosingFolder() throws {
        let root = menu(for: URL(fileURLWithPath: "/"))
        let reveal = try #require(root.items.first { $0.identifier?.rawValue == "sidebar-menu-show-in-enclosing-folder" })
        #expect(!reveal.isEnabled)
        #expect(root.items.first { $0.identifier?.rawValue == "sidebar-menu-open-in-new-tab" }?.isEnabled == true)
    }

    @Test("A destination that cannot be removed omits Remove from Sidebar and its separator")
    func nonRemovableDestination() {
        #expect(layout(menu(for: downloads, canRemove: false)) == [
            "Open in New Tab", "Show in Enclosing Folder", "—", "Get Info"
        ])
    }

    @Test("Choosing each enabled item runs exactly its own command")
    func itemsRunTheirCommands() {
        final class Recorder { var commands: [SidebarItemMenuCommand] = [] }
        let recorder = Recorder()
        let built = menu(for: downloads) { recorder.commands.append($0) }
        for index in built.items.indices where built.items[index].isEnabled && !built.items[index].isSeparatorItem {
            built.performActionForItem(at: index)
        }
        #expect(recorder.commands == [.openInNewTab, .showInEnclosingFolder, .removeFromSidebar, .getInfo])
    }

    @Test("Sections insert their own groups between the shared groups")
    func insertedGroupKeepsSharedOrder() {
        let extra = SidebarItemMenuItem(id: "eject", title: "Eject", systemImage: "eject", isEnabled: true) {}
        let shared = SidebarItemMenu.standard(for: downloads, canRemoveFromSidebar: true, locale: english) { _ in }
        #expect(layout(shared.inserting([extra], at: 1).nsMenu()) == [
            "Open in New Tab", "Show in Enclosing Folder", "—", "Eject", "—",
            "Remove from Sidebar", "—", "Get Info"
        ])
        #expect(layout(shared.inserting([extra], at: 99).nsMenu()).suffix(2) == ["—", "Eject"])
    }

    @Test("Titles follow the app language", arguments: [
        ("pt-BR", ["Abrir em Nova Aba", "Mostrar na Pasta Superior", "Remover da barra lateral", "Obter Informações"]),
        ("de", ["In neuem Tab öffnen", "Im umgebenden Ordner anzeigen", "Aus Seitenleiste entfernen", "Informationen"]),
        ("ja", ["新規タブで開く", "内包しているフォルダに表示", "サイドバーから削除", "情報を見る"])
    ])
    func localizedTitles(identifier: String, expected: [String]) {
        let titles = menu(for: downloads, locale: Locale(identifier: identifier)).items
            .filter { !$0.isSeparatorItem }.map(\.title)
        #expect(titles == expected)
    }
}

@Suite("Sidebar item menu actions")
@MainActor
struct SidebarItemMenuActionTests {
    private actor DenyingGrantStore: AccessGrantStoring {
        func hasGrant(for url: URL) async -> Bool { false }
        func storeGrant(for url: URL) async throws {}
        func activateGrant(for url: URL) async throws -> URL { url }
        func removeGrant(for url: URL) async {}
        func stopAll() async {}
    }

    private func fixture() throws -> (root: URL, folder: URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("SidebarMenu-\(UUID().uuidString)")
        let folder = root.appendingPathComponent("Pinned", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("sibling".utf8).write(to: root.appendingPathComponent("Sibling.txt"))
        return (root, folder)
    }

    private func state(defaults: UserDefaults, grants: any AccessGrantStoring) -> FileBrowserState {
        FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
                         grants: grants, archives: UIFixtureArchiveEngine())
    }

    @Test("Show in Enclosing Folder opens the parent in this browser with the destination selected")
    func showInEnclosingFolderSelectsDestination() async throws {
        let (root, folder) = try fixture()
        let suite = "ZforgeTestSuite.SidebarMenuReveal-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let browser = state(defaults: defaults, grants: UIFixtureAccessGrantStore())
        defer { browser.close() }

        await browser.showInEnclosingFolder(folder)

        #expect(browser.error == nil)
        #expect(browser.currentDirectoryURL?.standardizedFileURL.path == root.standardizedFileURL.path)
        #expect(browser.selectedItems.map(\.name) == ["Pinned"])
    }

    @Test("Show in Enclosing Folder asks for the parent when it is not authorized and leaves the view unchanged")
    func showInEnclosingFolderRequestsParentAccess() async throws {
        let (root, folder) = try fixture()
        let suite = "ZforgeTestSuite.SidebarMenuRevealDenied-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let browser = state(defaults: defaults, grants: DenyingGrantStore())
        defer { browser.close() }
        let before = browser.currentDirectoryURL

        await browser.showInEnclosingFolder(folder)

        #expect(browser.pendingAuthorizationURL?.standardizedFileURL.path == root.standardizedFileURL.path)
        #expect(browser.currentDirectoryURL == before)
        #expect(browser.selectedItems.isEmpty)
    }

    @Test("Open in New Tab hands the destination to this window's tab opener once access is active")
    func openInNewTabUsesTabOpener() async throws {
        let (root, folder) = try fixture()
        let suite = "ZforgeTestSuite.SidebarMenuTab-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let browser = state(defaults: defaults, grants: UIFixtureAccessGrantStore())
        defer { browser.close() }
        var opened: [URL] = []
        var openedWindows: [URL?] = []
        browser.configureOpenTabAction { opened.append($0) }
        browser.configureOpenWindowAction { openedWindows.append($0) }

        await browser.openSidebarDestinationInNewTab(folder)

        #expect(opened == [folder])
        #expect(openedWindows.isEmpty)
        #expect(browser.pendingAuthorizationURL == nil)
    }

    @Test("Open in New Tab without access asks for the folder and opens the tab only after authorization")
    func openInNewTabAfterAuthorization() async throws {
        let (root, folder) = try fixture()
        let suite = "ZforgeTestSuite.SidebarMenuTabDenied-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let browser = state(defaults: defaults, grants: DenyingGrantStore())
        defer { browser.close() }
        var opened: [URL] = []
        browser.configureOpenTabAction { opened.append($0) }

        await browser.openSidebarDestinationInNewTab(folder)
        #expect(opened.isEmpty)
        #expect(browser.pendingAuthorizationURL == folder)

        await browser.authorize(folder, intendedURL: folder)
        #expect(opened == [folder])
        #expect(browser.pendingAuthorizationURL == nil)
    }

    @Test("Get Info for a missing destination reports an error instead of opening an empty window")
    func getInfoForMissingDestinationReportsError() async throws {
        let suite = "ZforgeTestSuite.SidebarMenuInfo-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let browser = state(defaults: defaults, grants: UIFixtureAccessGrantStore())
        defer { browser.close() }
        let missingName = "Missing-\(UUID().uuidString)"

        await browser.showGetInfo(forSidebarDestination: FileManager.default.temporaryDirectory
            .appendingPathComponent(missingName))

        #expect(browser.error != nil)
        // Other suites open windows in parallel, so look for this item's info window only.
        #expect(!NSApp.windows.contains { $0.title.contains(missingName) })
    }

    @Test("Remove from Sidebar unpins only the chosen favorite and keeps the folder")
    func removeFromSidebarUnpins() async throws {
        let (root, folder) = try fixture()
        let other = root.appendingPathComponent("Other", isDirectory: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        let suite = "ZforgeTestSuite.SidebarMenuRemove-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let browser = state(defaults: defaults, grants: UIFixtureAccessGrantStore())
        defer { browser.close() }
        let sidebar = SidebarState()
        sidebar.pinnedFolders = PinnedFolderStore(defaults: defaults, initialURLs: [folder, other])
        var focusRestored = 0
        let actions = SidebarItemMenuActions(browser: browser, sidebar: sidebar) { focusRestored += 1 }

        let built = actions.menu(for: folder, canRemoveFromSidebar: true).nsMenu()
        let remove = try #require(built.items.firstIndex { $0.identifier?.rawValue == "sidebar-menu-remove-from-sidebar" })
        built.performActionForItem(at: remove)

        #expect(sidebar.favorites.map(\.url.lastPathComponent) == ["Other"])
        #expect(FileManager.default.fileExists(atPath: folder.path))
        #expect(focusRestored == 1)
    }
}
