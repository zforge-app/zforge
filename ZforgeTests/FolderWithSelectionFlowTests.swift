import AppKit
import Foundation
import Testing
@testable import Zforge

/// Per-mode parity of the New Folder with Selection command flow, previously
/// repeated by XCUITest in every mode: availability, grouping, inline rename,
/// opening the grouped folder, and the unchanged New Folder command afterwards;
/// also New Folder chosen from the shared blank-area/More menu (ZF-85).
@Suite("New folder with selection flow", .serialized)
@MainActor
struct FolderWithSelectionFlowTests {
    @Test("Without a selection the Option alternate is disabled", arguments: BrowserViewMode.allCases)
    func disabledWithoutSelection(mode: BrowserViewMode) async throws {
        try await withFixture(mode: mode) { state, root in
            #expect(state.selection.isEmpty, "\(mode)")
            #expect(state.canModifyCurrentDirectory, "New Folder stays available: \(mode)")
            #expect(!state.canCreateFolderWithSelection, "\(mode)")
            #expect(state.createNewFolderWithSelection() == nil, "\(mode)")
            let contents = try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
            #expect(contents == ["Dropped", "Local.txt", "Sample.zip"], "\(mode)")
        }
    }

    @Test("Grouping a file and an archive, renaming, opening, and returning keeps New Folder working",
          arguments: BrowserViewMode.allCases)
    func groupRenameOpenAndReturn(mode: BrowserViewMode) async throws {
        try await withFixture(mode: mode) { state, root in
            state.select(try item("Local.txt", in: state))
            state.select(try item("Sample.zip", in: state), modifiers: [.command])
            #expect(Set(state.selectedItems.map(\.name)) == ["Local.txt", "Sample.zip"], "\(mode)")
            #expect(state.canCreateFolderWithSelection, "The alternate is enabled with a selection: \(mode)")

            try await #require(state.createNewFolderWithSelection()).value
            #expect(state.renamingItemID == state.primarySelection?.id, "\(mode)")
            #expect(state.renameDraft == "untitled folder", "\(mode)")

            state.renameDraft = "Grouped Items"
            state.commitRename()
            try await waitUntil("rename completes in \(mode)") { !state.renameInProgress && state.renamingItemURL == nil }
            #expect(state.error == nil, "\(mode)")
            let names = state.items.map(\.name)
            #expect(names.contains("Grouped Items"), "\(mode)")
            #expect(!names.contains("Local.txt"), "Grouped file must be removed from its original folder in \(mode)")
            #expect(!names.contains("Sample.zip"), "Grouped archive must be removed from its original folder in \(mode)")

            let rootTitle = state.title
            let folder = try item("Grouped Items", in: state)
            if mode == .columns { await state.activateColumnItem(folder, in: state.location).value }
            else { await state.open(folder) }
            let groupedNames = mode == .columns
                ? (state.columnItems[folder.location] ?? []).map(\.name)
                : state.items.map(\.name)
            #expect(Set(groupedNames) == ["Local.txt", "Sample.zip"], "\(mode)")
            #expect(state.title == "Grouped Items", "\(mode)")
            await state.goBack()
            #expect(state.title == rootTitle, "\(mode)")
            #expect(state.items.map(\.name).sorted() == ["Dropped", "Grouped Items"], "\(mode)")
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("Grouped Items").path).sorted()
                    == ["Local.txt", "Sample.zip"], "\(mode)")

            // The original New Folder command still creates an empty folder and edits its name.
            state.select(try item("Dropped", in: state))
            state.createNewFolder()
            try await waitUntil("New Folder starts renaming in \(mode)") { state.renamingItemID != nil }
            #expect(state.renameDraft == "untitled folder", "The original New Folder command must still work in \(mode)")
            #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("untitled folder").path), "\(mode)")
            state.cancelRenaming()
        }
    }

    @Test("Choosing New Folder in the blank-area and More menu creates an untitled folder in the current folder, edits its name, and Undo removes it",
          arguments: BrowserViewMode.allCases)
    func contextMenuNewFolder(mode: BrowserViewMode) async throws {
        try await withFixture(mode: mode) { state, root in
            let undoManager = UndoManager()
            state.configureUndoManager(undoManager)
            // A selected folder keeps its place: the new folder goes to the folder shown, not into the selection.
            state.select(try item("Dropped", in: state))
            #expect(state.canModifyCurrentDirectory, "File ▸ New Folder is enabled: \(mode)")
            let overflow = BrowserActionsMenu.make(state: state, includesArchiveAction: true, includesShareAction: true, showToast: { _ in })
            #expect(overflow.items.first { $0.title == "New Folder" }?.isEnabled == true, "overflow, \(mode)")
            let menu = BrowserActionsMenu.make(state: state, showToast: { _ in })
            let index = try #require(menu.items.firstIndex { $0.title == "New Folder" }, "\(mode): \(menu.items.map(\.title))")
            #expect(index == 0, "\(mode)")
            #expect(menu.items[index].isEnabled, "\(mode)")
            menu.performActionForItem(at: index)
            try await waitUntil("New Folder starts renaming in \(mode)") { state.renamingItemID != nil }
            let created = root.appendingPathComponent("untitled folder")
            #expect(state.renameDraft == "untitled folder", "\(mode)")
            #expect(state.primarySelection?.name == "untitled folder", "\(mode)")
            var isDirectory: ObjCBool = false
            #expect(FileManager.default.fileExists(atPath: created.path, isDirectory: &isDirectory) && isDirectory.boolValue, "\(mode)")
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.appendingPathComponent("Dropped").path).isEmpty,
                    "Nothing is created inside the selected folder in \(mode)")
            state.cancelRenaming()
            #expect(undoManager.undoActionName == "New Folder", "\(mode)")
            undoManager.undo()
            try await waitUntil("Undo removes the new folder in \(mode)") { !FileManager.default.fileExists(atPath: created.path) }
            #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted() == ["Dropped", "Local.txt", "Sample.zip"],
                    "\(mode)")
        }
    }

    // MARK: - Support

    private func item(_ name: String, in state: FileBrowserState) throws -> BrowserItem {
        try #require(state.items.first(where: { $0.name == name }), "Missing fixture item \(name)")
    }

    private func waitUntil(_ description: String, _ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !predicate(), ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        try #require(predicate(), "Timed out waiting until \(description)")
    }

    private func withFixture(
        mode: BrowserViewMode, body: (FileBrowserState, URL) async throws -> Void
    ) async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FolderSelectionFlow-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let inside = root.appendingPathComponent("Inside", isDirectory: true)
        try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: false)
        try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [inside], outputURL: root.appendingPathComponent("Sample.zip"),
                                       format: .zip, progress: { _ in })
        try FileManager.default.removeItem(at: inside)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Dropped", isDirectory: true),
                                                withIntermediateDirectories: false)
        try Data("local".utf8).write(to: root.appendingPathComponent("Local.txt"))

        let suite = "ZforgeTestSuite.FolderSelectionFlow-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = mode
        preferences.language = .english
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
                                     recentItems: UIFixtureRecentItemsService(), taggedItems: UIFixtureTaggedItemsService(),
                                     grants: UIFixtureAccessGrantStore(), archives: engine)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        try await body(state, root)
    }
}
