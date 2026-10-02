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
