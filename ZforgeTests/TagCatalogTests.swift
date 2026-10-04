import AppKit
import Darwin
import Foundation
import Testing
@testable import Zforge

@Suite("Global Finder tags")
struct TagCatalogTests {
    @Test("The global scan includes tagged files in different directories and tagged folders")
    func scansAcrossDirectories() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        try writeTags(["Shared\n6"], to: first)
        try writeTags(["Shared\n6", "Custom"], to: second)
        try writeTags(["Folder Tag\n4"], to: root.appendingPathComponent("B"))
        let result = ScanResults()
        await TaggedFileScanner.scan([root]) { await result.append($0) }
        let records = await result.records
        #expect(records[first.path] == ["Shared": 6])
        #expect(records[second.path] == ["Shared": 6, "Custom": 0])
        #expect(records[root.appendingPathComponent("B").path] == ["Folder Tag": 4])
        #expect(records[root.appendingPathComponent("A/unmarked.txt").path] == nil)
    }

    @Test("The tag service includes unindexed files from the global catalogue")
    @MainActor
    func fallsBackToActualFileTags() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let name = "Zforge unit \(UUID().uuidString)"
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        try writeTags([name + "\n6"], to: first)
        try writeTags([name + "\n6"], to: second)
        let fileSystem = FileSystemService()
        let catalog = FinderTagCatalog()
        catalog.observe([try await fileSystem.item(at: first), try await fileSystem.item(at: second)])
        let service = SpotlightTaggedItemsService(catalog: catalog)
        defer { service.stop(); catalog.stop() }
        let urls = await service.itemURLs(tagged: name)
        #expect(Set(urls.map(\.standardizedFileURL)) == [first, second])
        #expect(await service.itemURLs(tagged: name + " absent").isEmpty)
    }

    @Test("File events update tags and results without navigating or refreshing")
    @MainActor
    func updatesGlobalCatalogueLive() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        let name = "Zforge live \(UUID().uuidString)"
        try writeTags([name + "\n6"], to: first)
        let catalog = FinderTagCatalog()
        catalog.refresh(searchScopes: [root])
        defer { catalog.stop() }
        try await waitUntil { catalog.itemURLs(tagged: name).count == 1 }
        try writeTags([name + "\n6"], to: second)
        try await waitUntil { catalog.itemURLs(tagged: name).count == 2 }
        try writeTags([name + " changed\n4"], to: first)
        try await waitUntil {
            catalog.itemURLs(tagged: name).count == 1
                && catalog.tags.contains { $0.name == name + " changed" }
        }
        try FileManager.default.removeItem(at: second)
        try await waitUntil { catalog.itemURLs(tagged: name).isEmpty }
    }

    @Test("Navigation verifies exact current tags across folders and restores tag history")
    @MainActor
    func navigationFiltersCurrentTags() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        let wrong = root.appendingPathComponent("A/unmarked.txt")
        let folder = root.appendingPathComponent("B")
        let name = "Zforge navigation \(UUID())"
        for url in [first, second, folder] { try writeTags([name + "\n6"], to: url) }
        try writeTags([name + " other\n4"], to: wrong)
        let suite = "TagNavigation-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(),
            taggedItems: FixedTaggedItems(urls: [first, second, wrong, folder]),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine(),
            initialURL: root.appendingPathComponent("A")
        )
        defer { state.close() }
        await state.start()
        await state.navigateToTag(name)
        #expect(Set(state.items.compactMap(\.localURL)) == [first, second, folder])
        await state.goBack()
        #expect(state.selectedSidebarTag == nil)
        await state.goForward()
        #expect(state.selectedSidebarTag == name)
        try writeTags(["Changed\n4"], to: first)
        await state.reload()
        #expect(Set(state.items.compactMap(\.localURL)) == [second, folder])
        await state.navigateToSidebar(folder, name: "B")
        #expect(state.selectedSidebarTag == nil)
        #expect(state.location == .fileSystem(folder))
    }

    @Test("Editing Finder tags retains unrelated tags and colors on files and folders")
    func editsTagsWithoutReplacingOtherNames() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let folder = root.appendingPathComponent("B")
        try writeTags(["Keep\n4", "Remove\n6"], to: first)
        try writeTags(["Different\n2"], to: folder)
        for url in [first, folder] {
            try FinderTagWriter.apply(additions: ["New": 3], removals: ["Remove"], to: url)
        }
        #expect(FinderTagMetadata.colorIndexes(at: first) == ["Keep": 4, "New": 3])
        #expect(FinderTagMetadata.colorIndexes(at: folder) == ["Different": 2, "New": 3])
        let fileSystem = FileSystemService()
        let item = try await fileSystem.item(at: first)
        #expect(Set(item.tags) == ["Keep", "New"])
        #expect(item.tagColorIndexes == ["Keep": 4, "New": 3])
        try FinderTagWriter.apply(additions: [:], removals: ["Keep", "New"], to: first)
        #expect(try await fileSystem.item(at: first).tags.isEmpty)
    }

    @Test("Tag editing updates the window and keeps a multiple selection")
    @MainActor
    func refreshesEditedSelection() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let name = "Zforge edit \(UUID())"
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Keep\n4"], to: file)
        let suite = "TagEditing-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(), grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine(), initialURL: root.appendingPathComponent("A")
        )
        defer { state.close() }
        await state.start()
        #expect(!state.canEditTags)
        state.selection = Set(state.items.map(\.id))
        state.editTags()
        let request = try #require(state.tagEditingRequest)
        #expect(request.items.count == 2)
        #expect(state.canEditTags)
        let failure = await state.applyTags(additions: [name: 6], removals: [], items: request.items)
        #expect(failure == nil)
        #expect(state.selection.count == 2)
        #expect(state.selectedItems.allSatisfy { $0.tags.contains(name) })
        #expect(state.selectedItems.first { $0.name == "first.txt" }?.tags.contains("Keep") == true)
        #expect(FinderTagCatalog.shared.itemURLs(tagged: name).count == 2)
        _ = await state.applyTags(additions: [:], removals: [name], items: state.selectedItems)
        #expect(FinderTagCatalog.shared.itemURLs(tagged: name).isEmpty)
    }

    @Test("New tags join the front of the visual stack without reordering existing metadata")
    func preservesTagOrder() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Yellow\n5", "Purple\n3"], to: file)
        try FinderTagWriter.apply(additions: ["Gray": 1], removals: [], to: file)
        let item = try await FileSystemService().item(at: file)
        #expect(item.tags == ["Yellow", "Purple", "Gray"])
        #expect(FolderTagIconColor.index(tags: item.tags, colors: item.tagColorIndexes) == 1)
        try FinderTagWriter.apply(additions: ["Yellow": 6], removals: ["Purple"], to: file)
        #expect(try await FileSystemService().item(at: file).tags == ["Yellow", "Gray"])
    }

    @Test("Invalid names and unreadable metadata are rejected without overwriting tags")
    func protectsExistingMetadata() throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Keep\n6"], to: file)
        #expect(throws: (any Error).self) {
            try FinderTagWriter.apply(additions: ["bad\nname": 4], removals: [], to: file)
        }
        #expect(FinderTagMetadata.colorIndexes(at: file) == ["Keep": 6])
        #expect(throws: (any Error).self) {
            try FinderTagWriter.apply(additions: ["New": 4], removals: [], to: root.appendingPathComponent("missing"))
        }
    }

    @Test("Folder tint follows the frontmost tag in the reversed metadata stack")
    func choosesFolderColor() {
        #expect(FolderTagIconColor.index(tags: ["A", "Z", "None"], colors: ["Z": 6, "A": 1, "None": 0]) == 6)
        #expect(FinderTagPresentation.leadingNames(["Yellow", "Purple", "Gray"]) == ["Gray", "Purple", "Yellow"])
        #expect(FolderTagIconColor.index(tags: ["Yellow", "Purple", "Gray"], colors: ["Yellow": 5, "Purple": 3, "Gray": 1]) == 1)
        #expect(FinderTagPresentation.quickTags((0..<10).map { FinderTag(name: String($0), colorIndex: 0) }).map(\.name) == (0..<7).map(String.init))
        #expect(FolderTagIconColor.index(tags: ["None"], colors: ["None": 0]) == nil)
        #expect(FolderTagIconColor.index(tags: [], colors: [:]) == nil)
    }

    @Test("Native menu circles share the current selection's applied tag state")
    @MainActor
    func nativeMenuAppliedState() async throws {
        let suite = "TagMenu-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(), recentItems: UIFixtureRecentItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine())
        defer { state.close() }
        await state.start()
        let file = try #require(state.items.first { $0.name == "Welcome.txt" })
        state.select(file)
        let menu = BrowserNativeContextMenu.make(state: state, item: file)
        let row = try #require(menu.items.first { $0.identifier?.rawValue == "quick-tags-Welcome.txt" })
        let buttons = row.view?.subviews.compactMap { $0 as? FinderTagQuickButton } ?? []
        let red = try #require(buttons.first { $0.finderTag.name == "Red" })
        #expect(red.applied)
        #expect(red.symbolName == "checkmark")
        #expect(red.accessibilityValue() as? String == "1")
    }

    private func fixtureRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("TagCatalogue-\(UUID())")
        for name in ["A", "B"] {
            let directory = root.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("fixture".utf8).write(to: directory.appendingPathComponent(name == "A" ? "first.txt" : "second.txt"))
        }
        try Data("unmarked".utf8).write(to: root.appendingPathComponent("A/unmarked.txt"))
        return root
    }

    private func writeTags(_ names: [String], to url: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: names, format: .binary, options: 0)
        let result = data.withUnsafeBytes { bytes in
            url.withUnsafeFileSystemRepresentation { path in
                setxattr(path!, FinderTagMetadata.attribute, bytes.baseAddress, data.count, 0, 0)
            }
        }
        #expect(result == 0)
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(8)
        while !condition(), Date() < deadline { try await Task.sleep(for: .milliseconds(100)) }
        #expect(condition())
    }
}

private actor ScanResults {
    private(set) var records: [String: [String: Int]] = [:]
    func append(_ batch: [String: [String: Int]]) { records.merge(batch) { _, new in new } }
}

@MainActor
private final class FixedTaggedItems: TaggedItemsServing {
    let urls: [URL]
    init(urls: [URL]) { self.urls = urls }
    func itemURLs(tagged tag: String) async -> [URL] { urls }
    func stop() {}
}
