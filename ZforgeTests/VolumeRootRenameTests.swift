import AppKit
import Foundation
import Testing
@testable import Zforge

/// Zforge doesn't rename volumes (OR-25, removed 2026-10-30 at the user's request): the App Sandbox
/// denies Disk Arbitration's rename authorization for volumes the user doesn't own. A volume root
/// listed in the content views, such as the startup volume at the computer level, can't start the
/// inline rename from any entry point, while ordinary items still can.
@Suite("Volume roots can't be renamed")
@MainActor
struct VolumeRootRenameTests {
    private func makeState(suite: String, volumes: [SidebarVolume] = []) throws -> (FileBrowserState, UserDefaults) {
        let defaults = try #require(UserDefaults(suiteName: suite))
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine(),
            volumes: FixedVolumeCatalog(current: volumes), networkBrowser: SilentNetworkBrowser()
        )
        state.preferences.language = .english
        return (state, defaults)
    }

    private func renameItem(in menu: NSMenu, state: FileBrowserState) -> NSMenuItem? {
        let title = AppLocalization.string("Rename", locale: state.preferences.language.locale)
        return menu.items.first { $0.title == title }
    }

    private func actionsMenu(_ state: FileBrowserState) -> NSMenu {
        BrowserActionsMenu.make(state: state, showToast: { _ in }, catalogTags: [])
    }

    @Test("The startup volume at the computer level can't start a rename from any entry point",
          arguments: BrowserViewMode.allCases)
    func startupVolumeCannotBeRenamed(mode: BrowserViewMode) async throws {
        let suite = "ZforgeTestSuite.VolumeRootRename-\(UUID().uuidString)"
        // `/` is a volume root on every Mac.
        let startup = SidebarVolume(url: URL(fileURLWithPath: "/", isDirectory: true), name: "Macintosh HD",
                                    kind: .internalDisk, isEjectable: false, isRemovable: false,
                                    isRootFileSystem: true)
        let (state, defaults) = try makeState(suite: suite, volumes: [startup])
        defer { state.close(); defaults.removeTestSuite(named: suite) }
        state.viewMode = mode
        await state.navigateToComputer()
        let root = try #require(state.sortedColumnItems(at: .computer).first { $0.localURL?.path == "/" })

        state.select(root)
        #expect(state.selection == [root.id])
        #expect(!state.canRename(root))
        // The File menu item and its Return shortcut are disabled by `canRenameSelection`.
        #expect(!state.canRenameSelection)
        state.beginRenamingSelectedItem()
        #expect(state.renamingItemURL == nil)
        state.beginRenaming(root)
        #expect(state.renamingItemURL == nil)
        #expect(state.renameDraft.isEmpty)

        let contextRename = try #require(renameItem(in: BrowserNativeContextMenu.make(state: state, item: root, catalogTags: []),
                                                    state: state))
        #expect(!contextRename.isEnabled, "The item's context menu shows Rename disabled for a volume root")
        let moreRename = try #require(renameItem(in: actionsMenu(state), state: state))
        #expect(!moreRename.isEnabled, "The toolbar's More menu shows Rename disabled for a volume root")
    }

    @Test("An ordinary folder still starts the inline rename from the same entry points")
    func folderCanStillBeRenamed() async throws {
        let suite = "ZforgeTestSuite.VolumeRootRenameFolder-\(UUID().uuidString)"
        let base = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appendingPathComponent("VolumeRootRename-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("Folder"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: base.appendingPathComponent("Other"), withIntermediateDirectories: true)
        let (state, defaults) = try makeState(suite: suite)
        defer { state.close(); defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: base) }
        await state.navigateToSidebar(base, name: base.lastPathComponent)
        let folder = try #require(state.items.first { $0.name == "Folder" })
        let other = try #require(state.items.first { $0.name == "Other" })
        #expect(state.canRename(folder))

        state.select(folder)
        #expect(state.canRenameSelection)
        #expect(try #require(renameItem(in: BrowserNativeContextMenu.make(state: state, item: folder, catalogTags: []),
                                        state: state)).isEnabled)
        #expect(try #require(renameItem(in: actionsMenu(state), state: state)).isEnabled)

        state.select(other, modifiers: .command)
        #expect(!state.canRenameSelection, "A multiple selection never starts the inline rename")
        #expect(try #require(renameItem(in: actionsMenu(state), state: state)).isEnabled == false)

        state.select(folder)
        state.beginRenamingSelectedItem()
        #expect(state.renamingItemURL?.standardizedFileURL.path == folder.localURL?.standardizedFileURL.path)
        #expect(state.renameDraft == "Folder")
        state.cancelRenaming()
        #expect(state.renamingItemURL == nil)
    }
}

private struct FixedVolumeCatalog: VolumeCataloging {
    let current: [SidebarVolume]
    func volumes() async -> [SidebarVolume] { current }
}

/// Discovery that never reports a server, so these tests never browse the real network.
private struct SilentNetworkBrowser: NetworkServerBrowsing {
    func updates() -> AsyncStream<NetworkDiscoveryUpdate> { AsyncStream { _ in } }
}
