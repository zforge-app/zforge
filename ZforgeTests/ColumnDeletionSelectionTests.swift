import AppKit
import Foundation
import Testing
@testable import Zforge

/// Columns follow the cursor rule of the other modes after a deletion (ZF-82, D-100):
/// the item that took the removed item's position in its column is selected; when the
/// column is left empty, its folder stays selected in the previous column.
@Suite("Column deletion selection", .serialized)
struct ColumnDeletionSelectionTests {
    @Test("Deleting the selected file selects the item that followed it")
    @MainActor
    func deletingFileSelectsFollowingItem() async throws {
        let fixture = try ColumnDeletionFixture(files: ["Alpha.txt", "Beta.txt", "Gamma.txt"])
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let beta = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Beta.txt" })
        await state.activateColumnItem(beta, in: rootLocation).value

        try await deletePermanently(state)

        #expect(!FileManager.default.fileExists(atPath: fixture.url("Beta.txt").path))
        let gamma = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Gamma.txt" })
        #expect(state.selection == [gamma.id])
        #expect(state.primarySelection?.id == gamma.id)
        #expect(state.columnSelections[rootLocation] == gamma.id)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.pathComponents.map(\.location) == [rootLocation])
        #expect(state.error == nil)
    }

    @Test("Deleting the last file of a column selects the new last item")
    @MainActor
    func deletingLastFileSelectsPrecedingItem() async throws {
        let fixture = try ColumnDeletionFixture(files: ["Alpha.txt", "Beta.txt", "Gamma.txt"])
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let gamma = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Gamma.txt" })
        await state.activateColumnItem(gamma, in: rootLocation).value

        try await deletePermanently(state)

        let beta = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Beta.txt" })
        #expect(state.sortedColumnItems(at: rootLocation).map(\.name) == ["Alpha.txt", "Beta.txt"])
        #expect(state.selection == [beta.id])
        #expect(state.columnSelections[rootLocation] == beta.id)
        #expect(state.activeColumnLocation == rootLocation)
    }

    @Test("Deleting an open folder selects the following folder and shows its contents")
    @MainActor
    func deletingOpenFolderOpensFollowingFolder() async throws {
        let fixture = try ColumnDeletionFixture(
            files: ["Alpha/Inside.txt", "Beta/Nested.txt", "Gamma.txt"]
        )
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let alpha = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Alpha" })
        await state.activateColumnItem(alpha, in: rootLocation).value
        #expect(state.pathComponents.count == 2)

        try await deletePermanently(state)

        let beta = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Beta" })
        let betaLocation = BrowserLocation.fileSystem(fixture.url("Beta").standardizedFileURL)
        #expect(state.selection == [beta.id])
        #expect(state.columnSelections[rootLocation] == beta.id)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.location == betaLocation)
        #expect(state.pathComponents.map(\.location) == [rootLocation, betaLocation])
        #expect(state.sortedColumnItems(at: betaLocation).map(\.name) == ["Nested.txt"])
        #expect(state.error == nil)
    }

    @Test("Deleting the only item of a nested column keeps its folder selected in the previous column")
    @MainActor
    func deletingOnlyNestedItemSelectsParentFolder() async throws {
        let fixture = try ColumnDeletionFixture(files: ["Folder/Only.txt", "Other.txt"])
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let folder = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Folder" })
        await state.activateColumnItem(folder, in: rootLocation).value
        let folderLocation = BrowserLocation.fileSystem(fixture.url("Folder").standardizedFileURL)
        let only = try #require(state.sortedColumnItems(at: folderLocation).first { $0.name == "Only.txt" })
        await state.activateColumnItem(only, in: folderLocation).value
        #expect(state.activeColumnLocation == folderLocation)

        try await deletePermanently(state)

        #expect(state.sortedColumnItems(at: folderLocation).isEmpty)
        #expect(state.selection == [folder.id])
        #expect(state.columnSelections[rootLocation] == folder.id)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.pathComponents.map(\.location) == [rootLocation, folderLocation])
    }

    @Test("Deleting a file in a nested column selects the following item in that column")
    @MainActor
    func deletingNestedFileSelectsFollowingItemInSameColumn() async throws {
        let fixture = try ColumnDeletionFixture(
            files: ["Folder/One.txt", "Folder/Two.txt", "Folder/Three.txt", "Other.txt"]
        )
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let folder = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Folder" })
        await state.activateColumnItem(folder, in: rootLocation).value
        let folderLocation = BrowserLocation.fileSystem(fixture.url("Folder").standardizedFileURL)
        // Name order: One.txt, Three.txt, Two.txt.
        let one = try #require(state.sortedColumnItems(at: folderLocation).first { $0.name == "One.txt" })
        await state.activateColumnItem(one, in: folderLocation).value

        try await deletePermanently(state)

        let three = try #require(state.sortedColumnItems(at: folderLocation).first { $0.name == "Three.txt" })
        #expect(state.selection == [three.id])
        #expect(state.columnSelections[folderLocation] == three.id)
        #expect(state.columnSelections[rootLocation] == folder.id)
        #expect(state.activeColumnLocation == folderLocation)
        #expect(state.pathComponents.map(\.location) == [rootLocation, folderLocation])
    }

    @Test("Deleting several items puts the cursor at the focused item's position, as in the other modes")
    @MainActor
    func deletingMultipleItemsKeepsCursorPosition() async throws {
        let fixture = try ColumnDeletionFixture(
            files: ["A.txt", "B.txt", "C.txt", "D.txt", "E.txt"]
        )
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let ordered = state.sortedColumnItems(at: rootLocation)
        let b = try #require(ordered.first { $0.name == "B.txt" })
        let c = try #require(ordered.first { $0.name == "C.txt" })
        await state.activateColumnItem(b, in: rootLocation).value
        await state.activateColumnItem(c, in: rootLocation, modifiers: .command).value
        #expect(state.selection == [b.id, c.id])

        try await deletePermanently(state)

        // The focused item C.txt was third; the third remaining item is E.txt.
        #expect(state.sortedColumnItems(at: rootLocation).map(\.name) == ["A.txt", "D.txt", "E.txt"])
        let e = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "E.txt" })
        #expect(state.selection == [e.id])
        #expect(state.columnSelections[rootLocation] == e.id)
    }

    @Test("An open folder removed outside Zforge moves the cursor to the following item")
    @MainActor
    func externalRemovalOfOpenFolderSelectsFollowingItem() async throws {
        let fixture = try ColumnDeletionFixture(files: ["Alpha/Inside.txt", "Beta.txt", "Gamma.txt"])
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let alpha = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Alpha" })
        await state.activateColumnItem(alpha, in: rootLocation).value
        #expect(state.location == .fileSystem(fixture.url("Alpha").standardizedFileURL))

        try FileManager.default.removeItem(at: fixture.url("Alpha"))
        await state.reload()

        let beta = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Beta.txt" })
        #expect(state.selection == [beta.id])
        #expect(state.columnSelections[rootLocation] == beta.id)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.pathComponents.map(\.location) == [rootLocation])
        #expect(state.error == nil)
    }

    @Test("Deleting every item of the root column leaves no selection")
    @MainActor
    func deletingWholeRootColumnLeavesNoSelection() async throws {
        let fixture = try ColumnDeletionFixture(files: ["Alpha.txt"])
        defer { fixture.tearDown() }
        let state = fixture.makeState()
        defer { state.close() }
        await state.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let rootLocation = state.location
        let alpha = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == "Alpha.txt" })
        await state.activateColumnItem(alpha, in: rootLocation).value

        try await deletePermanently(state)

        #expect(state.sortedColumnItems(at: rootLocation).isEmpty)
        #expect(state.selection.isEmpty)
        #expect(state.columnSelections[rootLocation] == nil)
        #expect(state.location == rootLocation)
        #expect(state.error == nil)
    }

    /// Runs the confirmed permanent deletion of the current selection and waits for the
    /// operation, including its column refresh, to finish.
    @MainActor
    private func deletePermanently(_ state: FileBrowserState) async throws {
        state.requestPermanentDeletion()
        let urls = try #require(state.pendingPermanentDeletion?.urls)
        state.confirmPermanentDeletion()
        #expect(state.fileOperationInProgress)
        for _ in 0..<500 where state.fileOperationInProgress {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!state.fileOperationInProgress)
        #expect(urls.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })
    }
}

@MainActor
private struct ColumnDeletionFixture {
    let root: URL
    let suiteName: String
    let defaults: UserDefaults

    init(files: [String]) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnDeletion-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for path in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("Zforge".utf8).write(to: url)
        }
        suiteName = "ZforgeTestSuite.ZforgeColumnDeletion-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    func url(_ path: String) -> URL {
        root.appendingPathComponent(path)
    }

    func makeState() -> FileBrowserState {
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .columns
        preferences.sort = BrowserSort(field: .name, ascending: true)
        preferences.language = .english
        return FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: root)
        defaults.removeTestSuite(named: suiteName)
    }
}
