import Foundation
import Testing
@testable import Zforge

@Suite("List hierarchy")
struct ListHierarchyPerformanceTests {
    @Test("Option disclosure alternates the entire cached hierarchy")
    @MainActor
    func recursiveDisclosureToggle() async {
        let state = FileBrowserState()
        let parent = item("Parent", isFolder: true)
        let child = item("Child", isFolder: true)
        let leaf = item("Leaf.txt", isFolder: false)
        state.items = [parent]
        state.expandedChildren[parent.id] = [child]
        state.expandedChildren[child.id] = [leaf]

        await state.toggleAllDescendants(of: parent)
        #expect(state.expandedItems == [parent.id, child.id])
        #expect(state.flattenedList().map(\.id) == [parent.id, child.id, leaf.id])

        await state.toggleAllDescendants(of: parent)
        #expect(state.expandedItems.isEmpty)
        #expect(state.flattenedList().map(\.id) == [parent.id])
    }

    @Test("Cached list derivations invalidate after content and sort changes")
    @MainActor
    func derivedListInvalidation() {
        let state = FileBrowserState()
        let alpha = item("Alpha", isFolder: false)
        let beta = item("Beta", isFolder: false)
        state.preferences.sort = BrowserSort(field: .name, ascending: true)
        state.items = [beta, alpha]

        #expect(state.sortedItems.map(\.id) == [alpha.id, beta.id])
        #expect(state.flattenedList().map(\.id) == [alpha.id, beta.id])
        #expect(state.flattenedItems().map(\.id) == [alpha.id, beta.id])

        state.preferences.sort = BrowserSort(field: .name, ascending: false)
        #expect(state.sortedItems.map(\.id) == [beta.id, alpha.id])
        #expect(state.flattenedList().map(\.id) == [beta.id, alpha.id])
        #expect(state.flattenedItems().map(\.id) == [beta.id, alpha.id])

        let gamma = item("Gamma", isFolder: false)
        state.items.append(gamma)
        #expect(state.sortedItems.map(\.id) == [gamma.id, beta.id, alpha.id])
    }

    @Test("Expanded folders refresh their contents and preserve the cursor position")
    @MainActor
    func expandedFolderRefresh() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeExpandedHierarchy-\(UUID().uuidString)", isDirectory: true)
        let dev = root.appendingPathComponent("dev", isDirectory: true)
        let projectOne = dev.appendingPathComponent("project1", isDirectory: true)
        let projectTwo = dev.appendingPathComponent("project2", isDirectory: true)
        try FileManager.default.createDirectory(at: projectOne, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: projectTwo, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeExpandedHierarchy-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        preferences.sort = BrowserSort(field: .name, ascending: true)
        preferences.language = .english
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let devItem = try #require(state.items.first(where: { $0.name == "dev" }))
        await state.toggleExpansion(devItem)
        let firstItem = try #require(
            state.flattenedItems().first(where: { $0.name == "project1" })
        )
        state.select(firstItem, orderedItems: state.flattenedItems())

        try FileManager.default.removeItem(at: projectOne)
        await state.reload()

        #expect(!state.flattenedItems().contains(where: { $0.name == "project1" }))
        #expect(state.primarySelection?.name == "project2")
        let projectTwoID = try #require(state.primarySelection?.id)
        #expect(state.selection == [projectTwoID])

        try FileManager.default.removeItem(at: projectTwo)
        await state.reload()

        #expect(state.flattenedItems().map(\.name) == ["dev"])
        #expect(state.primarySelection?.id == devItem.id)

        let projectThree = dev.appendingPathComponent("project3", isDirectory: true)
        try FileManager.default.createDirectory(at: projectThree, withIntermediateDirectories: false)
        for _ in 0..<100 where !state.flattenedItems().contains(where: { $0.name == "project3" }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(state.flattenedItems().contains(where: { $0.name == "project3" }))
    }

    @Test("File operations target the folder containing the active list row")
    @MainActor
    func contextualFileOperationDestination() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeContextualDestination-\(UUID().uuidString)", isDirectory: true)
        let dev = root.appendingPathComponent("dev", isDirectory: true)
        let uiDemo = dev.appendingPathComponent("UIDemo", isDirectory: true)
        try FileManager.default.createDirectory(at: uiDemo, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeContextualDestination-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        preferences.sort = BrowserSort(field: .name, ascending: true)
        preferences.language = .english
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let devItem = try #require(state.items.first(where: { $0.name == "dev" }))
        await state.toggleExpansion(devItem)
        let orderedItems = state.flattenedItems()
        let uiDemoItem = try #require(orderedItems.first(where: { $0.name == "UIDemo" }))

        state.select(devItem, orderedItems: orderedItems)
        #expect(state.fileOperationDestinationURL == root.standardizedFileURL)

        state.select(uiDemoItem, orderedItems: orderedItems)
        #expect(state.fileOperationDestinationURL == dev.standardizedFileURL)
        #expect(state.fileDropDestinationURL == root.standardizedFileURL)

        state.createNewFolder()
        for _ in 0..<100 where state.renamingItemID == nil {
            try await Task.sleep(for: .milliseconds(10))
        }

        let createdFolder = dev.appendingPathComponent("untitled folder", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: createdFolder.path))
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("untitled folder").path))
        #expect(state.primarySelection?.localURL?.standardizedFileURL == createdFolder.standardizedFileURL)
        #expect(state.renamingItemID == state.primarySelection?.id)
    }

    @Test("Column transfers refresh both the source and destination columns")
    @MainActor
    func columnTransferRefreshesBothColumns() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnTransfer-" + UUID().uuidString, isDirectory: true)
        let destination = root.appendingPathComponent("dev", isDirectory: true)
        let source = root.appendingPathComponent("work.zip")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("Zforge".utf8).write(to: source)
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeColumnTransfer-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .columns
        preferences.language = .english
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let devItem = try #require(state.items.first(where: { $0.name == "dev" }))
        let openingTask = state.activateColumnItem(devItem, in: state.location)
        await openingTask.value

        let sourceItem = try #require(
            state.columnItems[.fileSystem(root)]?.first(where: { $0.name == source.lastPathComponent })
        )
        #expect(state.columnItems[.fileSystem(root)]?.contains(where: { $0.name == source.lastPathComponent }) == true)
        #expect(state.columnItems[.fileSystem(destination)]?.contains(where: { $0.name == source.lastPathComponent }) != true)

        #expect(
            state.performDrop(
                providers: [try #require(state.itemProvider(for: sourceItem))],
                to: destination,
                operation: .move
            )
        )

        for _ in 0..<100 where FileManager.default.fileExists(atPath: source.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        for _ in 0..<100 where state.columnItems[.fileSystem(destination)]?.contains(where: {
            $0.name == source.lastPathComponent
        }) != true {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(
            state.columnItems[.fileSystem(root)]?.contains(where: {
                $0.name == source.lastPathComponent
            }) != true
        )
        #expect(
            state.columnItems[.fileSystem(destination)]?.contains(where: {
                $0.name == source.lastPathComponent
            }) == true
        )
    }

    private func item(_ name: String, isFolder: Bool) -> BrowserItem {
        BrowserItem(
            id: BrowserItemID(rawValue: name),
            name: name,
            location: .fileSystem(URL(fileURLWithPath: "/tmp/\(name)")),
            isContainer: isFolder,
            isDirectory: isFolder,
            isPackage: false,
            isSymbolicLink: false,
            isHidden: false,
            isArchive: false,
            size: isFolder ? nil : 0,
            packedSize: nil,
            creationDate: nil,
            modificationDate: nil,
            accessDate: nil,
            tags: [],
            contentTypeIdentifier: nil,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
    }
}
