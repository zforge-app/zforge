import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("Pinned sidebar folders")
@MainActor
struct PinnedFolderTests {
    private func fixture() throws -> (URL, UserDefaults, String) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for name in ["A", "B", "C"] {
            try FileManager.default.createDirectory(at: root.appendingPathComponent(name), withIntermediateDirectories: true)
        }
        let suite = "ZforgeTestSuite.PinnedFolderTests.\(UUID())"
        return (root, UserDefaults(suiteName: suite)!, suite)
    }

    @Test("Insertion order and removals survive relaunch without changing folders")
    func persistsOrderAndRemoval() throws {
        let (root, defaults, suite) = try fixture()
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("A"), b = root.appendingPathComponent("B"), c = root.appendingPathComponent("C")
        let store = PinnedFolderStore(defaults: defaults, initialURLs: [a, b])
        try store.pin([c], before: b)
        #expect(store.urls == [a, c, b])
        let restored = PinnedFolderStore(defaults: defaults, initialURLs: [])
        #expect(restored.urls == [a, c, b])
        restored.remove(c)
        #expect(PinnedFolderStore(defaults: defaults, initialURLs: []).urls == [a, b])
        #expect(FileManager.default.fileExists(atPath: c.path))
    }

    @Test("Repeated folders and symlink paths do not create duplicate favorites")
    func deduplicatesCanonicalFolders() throws {
        let (root, defaults, suite) = try fixture()
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("A"), link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: a)
        let store = PinnedFolderStore(defaults: defaults, initialURLs: [])
        try store.pin([a, a, link])
        #expect(store.urls == [a.resolvingSymlinksInPath()])
        try store.pin([link])
        #expect(store.urls.count == 1)
        defaults.removeTestSuite(named: suite)
        let seeded = PinnedFolderStore(defaults: defaults, initialURLs: [link])
        try seeded.pin([a])
        #expect(seeded.urls.count == 1)
    }

    @Test("A mixed file/folder batch is rejected without partial insertion")
    func rejectsFilesAtomically() throws {
        let (root, defaults, suite) = try fixture()
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("file.zip")
        try Data().write(to: file)
        let store = PinnedFolderStore(defaults: defaults, initialURLs: [])
        #expect(throws: (any Error).self) { try store.pin([root.appendingPathComponent("A"), file]) }
        #expect(store.urls.isEmpty)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Packages and virtual/non-file destinations cannot be pinned")
    func rejectsPackagesAndRemoteURLs() throws {
        let (root, defaults, suite) = try fixture()
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Sample.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let store = PinnedFolderStore(defaults: defaults, initialURLs: [])
        #expect(throws: (any Error).self) { try store.pin([app]) }
        #expect(throws: (any Error).self) { try store.pin([URL(string: "smb://server/folder")!]) }
        #expect(store.urls.isEmpty)
    }

    @Test("Dropped URL providers pin folders in payload order without moving their contents")
    func consumesDropProviders() async throws {
        let (root, defaults, suite) = try fixture()
        let a = root.appendingPathComponent("A"), b = root.appendingPathComponent("B")
        let store = PinnedFolderStore.shared
        defer {
            for url in [a, b] { store.remove(url.resolvingSymlinksInPath()) }
            defaults.removeTestSuite(named: suite)
            try? FileManager.default.removeItem(at: root)
        }
        let browser = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
                                       fileSystem: FileSystemService(), grants: PinTestGrants(),
                                       archives: NativeSevenZipArchiveEngine())
        let anchor = store.urls.first
        #expect(browser.performPinDrop(providers: [NSItemProvider(object: b as NSURL),
                                                   NSItemProvider(object: a as NSURL)], before: anchor))
        for _ in 0..<100 {
            if store.contains(a) && store.contains(b) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(browser.error == nil)
        let paths = store.urls.map(\.path)
        let bIndex = try #require(paths.firstIndex(of: b.resolvingSymlinksInPath().path))
        #expect(paths[bIndex + 1] == a.resolvingSymlinksInPath().path)
        if let anchor { #expect(paths[bIndex + 2] == anchor.path) }
        #expect(FileManager.default.fileExists(atPath: a.path))
        #expect(FileManager.default.fileExists(atPath: b.path))
    }

    @Test("The actual drag URL data pins the original folder, not a temporary file")
    func consumesFileURLData() async throws {
        let (root, defaults, suite) = try fixture()
        let folder = root.appendingPathComponent("A")
        let store = PinnedFolderStore.shared
        defer {
            store.remove(folder.resolvingSymlinksInPath())
            defaults.removeTestSuite(named: suite)
            try? FileManager.default.removeItem(at: root)
        }
        let browser = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
                                       fileSystem: FileSystemService(), grants: PinTestGrants(),
                                       archives: NativeSevenZipArchiveEngine())
        defer { browser.close() }
        let provider = NSItemProvider()
        let payload = BrowserDraggedFile(url: folder).fileURLData
        provider.registerDataRepresentation(forTypeIdentifier: "public.file-url", visibility: .all) { completion in
            completion(payload, nil)
            return nil
        }
        #expect(provider.canLoadObject(ofClass: NSURL.self))
        #expect(browser.performPinDrop(providers: [provider], before: nil))
        for _ in 0..<100 where !store.contains(folder) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(browser.error == nil)
        #expect(store.urls.last?.path == folder.resolvingSymlinksInPath().path)
        #expect(FileManager.default.fileExists(atPath: folder.path))
    }

    @Test("The merged native menu offers sidebar pinning alongside quick tags")
    func nativeMenuKeepsPinAndTags() async throws {
        let suite = "ZforgeTestSuite.SidebarNativeMenu-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let state = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(), recentItems: UIFixtureRecentItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine())
        defer { state.close() }
        await state.start()
        let folderItems = try await UIFixtureFileSystemService().items(in: URL(fileURLWithPath: "/ZforgeFixtures"), showHidden: false)
        let folder = try #require(folderItems.first { $0.isDirectory && !$0.isPackage })
        let title = AppLocalization.string("Add to Sidebar", locale: state.preferences.language.locale)
        let menu = BrowserNativeContextMenu.make(state: state, item: folder)
        let pin = try #require(menu.items.first { $0.title == title })
        #expect(pin.isEnabled == !PinnedFolderStore.shared.contains(try #require(folder.localURL)))
        #expect(menu.items.contains { $0.identifier?.rawValue == "quick-tags-\(folder.name)" })
        let file = try #require(state.items.first { !$0.isDirectory && !$0.isContainer })
        #expect(!BrowserNativeContextMenu.make(state: state, item: file).items.contains { $0.title == title })
    }

    @Test("An explicitly empty favorites list stays empty after relaunch")
    func preservesEmptyList() throws {
        let (root, defaults, suite) = try fixture()
        defer { defaults.removeTestSuite(named: suite); try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("A")
        let store = PinnedFolderStore(defaults: defaults, initialURLs: [a])
        store.remove(a)
        #expect(PinnedFolderStore(defaults: defaults, initialURLs: [a]).urls.isEmpty)
    }
}

private actor PinTestGrants: AccessGrantStoring {
    func hasGrant(for url: URL) -> Bool { true }
    func storeGrant(for url: URL) throws {}
    func activateGrant(for url: URL) throws -> URL { url }
    func removeGrant(for url: URL) {}
    func stopAll() {}
}
