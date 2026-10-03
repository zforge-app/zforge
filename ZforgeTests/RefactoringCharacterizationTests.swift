import Foundation
import Testing
@testable import Zforge

@Suite("ZF-08 behavior characterization")
struct RefactoringCharacterizationTests {
    @Test("Finder tag metadata preserves colors and uncolored custom tags")
    func finderTagMetadata() throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["UFAPE\n6", "UDEMY", "Roxo\n3", "Cinza\n1"],
            format: .binary,
            options: 0
        )
        #expect(FinderTagMetadata.colorIndexes(in: data) == [
            "UFAPE": 6, "UDEMY": 0, "Roxo": 3, "Cinza": 1
        ])
        #expect(FinderTagMetadata.defaultColorIndex(for: "Laranja") == 7)
    }

    @Test("Contextual action matrix preserves each selection class")
    @MainActor
    func contextualActions() throws {
        let defaultsName = "ZF08-Actions-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        let file = item("Note.txt")
        let archive = item("First.zip", archive: true)
        let secondArchive = item("Second.7z", archive: true)
        let virtual = BrowserItem(
            id: BrowserItemID(rawValue: "virtual"), name: "Inside.txt",
            location: .archive(ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: "Inside.txt")),
            isContainer: false, isDirectory: false, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: false,
            size: 1, packedSize: nil, creationDate: nil, modificationDate: nil,
            accessDate: nil, tags: [], contentTypeIdentifier: nil,
            encrypted: false, checksum: nil, compressionMethod: nil
        )

        #expect(state.contextualActions(for: []) == [])
        #expect(state.contextualActions(for: [file]) == [.open, .compress, .compressCustom, .addToArchive])
        #expect(state.contextualActions(for: [archive]) == [
            .open, .extractHere, .extractNamed, .extractChoose, .validate, .addToArchive
        ])
        #expect(state.contextualActions(for: [archive, secondArchive]) == [
            .open, .extractHere, .extractNamed, .extractChoose, .validate,
            .compress, .compressCustom, .addToArchive
        ])
        #expect(state.contextualActions(for: [archive, file]) == [.open, .compress, .compressCustom, .addToArchive])
        #expect(state.contextualActions(for: [virtual]) == [.open])
        state.preferences.language = .english
        #expect(state.contextualTitle(.extractNamed, items: [archive, secondArchive]).contains("First, Second"))
    }

    @Test("Zoom, widths and preview visibility keep their persisted contracts")
    @MainActor
    func persistedLayoutPreferences() throws {
        let name = "ZF08-Preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        for _ in 0..<20 { preferences.zoomIn() }
        #expect(preferences.scale == 1.6)
        for _ in 0..<20 { preferences.zoomOut() }
        #expect(preferences.scale == 0.7)
        preferences.resetZoom()
        #expect(preferences.scale == 1)
        preferences.setListColumnWidth(1, for: .name)
        preferences.setListColumnWidth(1_000, for: .size)
        preferences.setFinderColumnWidth(1)
        preferences.setPreviewWidth(1_000)
        preferences.setPreviewVisible(false, in: .list)
        let firstFolder = BrowserLocation.fileSystem(URL(fileURLWithPath: "/tmp/zforge-column-folder-a"))
        let secondFolder = BrowserLocation.fileSystem(URL(fileURLWithPath: "/tmp/zforge-column-folder-b"))
        #expect(preferences.globalListColumns == [.name, .modificationDate, .size, .kind])
        preferences.setGlobalListColumns([.name, .tags, .kind, .dateAdded])
        preferences.setListColumns([.name, .comments, .tags], for: firstFolder)
        preferences.rememberSidebarTags(["Red", "Blue", "Red"])
        #expect(preferences.visibleListColumns(for: firstFolder) == [.name, .comments, .tags])
        #expect(preferences.visibleListColumns(for: secondFolder) == [.name, .tags, .kind, .dateAdded])
        #expect(preferences.listColumnWidth(.name) == 168)
        #expect(preferences.listColumnWidth(.size) == 800)
        #expect(preferences.finderColumnWidth == 180)
        #expect(preferences.previewWidth == 800)
        #expect(preferences.previewVisible(in: .icons))
        #expect(!preferences.previewVisible(in: .list))

        let restored = FileBrowserPreferences(defaults: defaults)
        #expect(restored.listColumnWidth(.name) == 168)
        #expect(restored.listColumnWidth(.size) == 800)
        #expect(restored.finderColumnWidth == 180)
        #expect(restored.previewWidth == 800)
        #expect(!restored.previewVisible(in: .list))
        #expect(restored.previewVisible(in: .columns))
        #expect(restored.visibleListColumns(for: firstFolder) == [.name, .comments, .tags])
        #expect(restored.visibleListColumns(for: secondFolder) == [.name, .tags, .kind, .dateAdded])
        #expect(restored.knownSidebarTags == ["Blue", "Red"])
        restored.resetListColumns(for: firstFolder)
        #expect(restored.visibleListColumns(for: firstFolder) == restored.globalListColumns)
        restored.setGlobalListColumns([.tags, .tags, .sharedBy, .name])
        #expect(restored.globalListColumns == [.name, .tags])
    }

    @Test("Sidebar tag navigation shows matching files and restores Recents")
    @MainActor
    func sidebarTagNavigation() async throws {
        let suiteName = "ZF-Tags-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(),
            recentItems: UIFixtureRecentItemsService(),
            taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        await state.start()
        #expect(state.sidebarTags.contains("Red"))
        let beforeTag = state.items.map(\.name)
        await state.navigateToTag("Red")
        #expect(state.selectedSidebarTag == "Red")
        #expect(state.items.map(\.name) == ["Welcome.txt"])
        await state.goBack()
        #expect(state.selectedSidebarTag == nil)
        #expect(state.items.map(\.name) == beforeTag)
        state.close()
    }

    @Test("Resize geometry respects scale and the preview's reversed drag direction")
    func resizeGeometry() {
        #expect(BrowserResizeGeometry.width(
            startWidth: 300, dragStartX: 100, currentX: 140,
            scale: 1, direction: 1
        ) == 340)
        #expect(BrowserResizeGeometry.width(
            startWidth: 300, dragStartX: 100, currentX: 140,
            scale: 2, direction: 1
        ) == 320)
        #expect(BrowserResizeGeometry.width(
            startWidth: 300, dragStartX: 100, currentX: 140,
            scale: 2, direction: -1
        ) == 280)
    }

    @Test("Column preview uses the space available when each file is loaded")
    func columnPreviewInitialWidth() {
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 1_400, columnCount: 1, columnWidth: 260
        ) == 1_140)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 1_400, columnCount: 4, columnWidth: 260
        ) == 360)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 900, columnCount: 4, columnWidth: 260
        ) == 240)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 1_400, columnCount: 1, columnWidth: 390
        ) == 1_010)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 500, columnCount: 1, columnWidth: 182
        ) == 318)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 400, columnCount: 1, columnWidth: 182
        ) == 240)
        #expect(BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 5_000, columnCount: 1, columnWidth: 260
        ) == 4_740)
    }

    @Test("Expanded terminal columns retain their slot when replaced by a preview")
    func columnTerminalWidth() {
        let initialPreview = BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: 1_000, columnCount: 1, columnWidth: 600
        )
        let terminalColumn = BrowserColumnsLayout.terminalColumnWidth(
            availableWidth: 1_000, precedingColumnCount: 1,
            columnWidth: 600, minimumWidth: 240
        )
        #expect(initialPreview == 400)
        #expect(terminalColumn == 600)
        #expect(BrowserColumnsLayout.terminalColumnWidth(
            availableWidth: 1_000, precedingColumnCount: 1,
            columnWidth: 260, minimumWidth: 240
        ) == 740)
        #expect(BrowserColumnsLayout.terminalColumnWidth(
            availableWidth: 600, precedingColumnCount: 2,
            columnWidth: 180, minimumWidth: 240
        ) == 240)
    }

    @Test("Compiled app declares and bundles its macOS icon")
    func appIconBundle() throws {
        let bundle = Bundle(for: AppDelegate.self)
        #expect(bundle.object(forInfoDictionaryKey: "CFBundleIconName") as? String == "zforge_icon")
        #expect(bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String == "zforge_icon")
        #expect(bundle.url(forResource: "Assets", withExtension: "car") != nil)
        #expect(bundle.url(forResource: "zforge_icon", withExtension: "icns") != nil)
    }

    @Test("Recents keeps distinct same-named files and discards duplicate URLs")
    @MainActor
    func recentItemsByIdentity() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZF08-Recents-\(UUID().uuidString)", isDirectory: true)
        let firstDirectory = root.appendingPathComponent("A", isDirectory: true)
        let secondDirectory = root.appendingPathComponent("B", isDirectory: true)
        try FileManager.default.createDirectory(at: firstDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = firstDirectory.appendingPathComponent("Same.txt")
        let second = secondDirectory.appendingPathComponent("Same.txt")
        try Data("same".utf8).write(to: first)
        try Data("same".utf8).write(to: second)
        let sharedModificationDate = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: sharedModificationDate], ofItemAtPath: first.path)
        try FileManager.default.setAttributes([.modificationDate: sharedModificationDate], ofItemAtPath: second.path)
        let hidden = root.appendingPathComponent(".Hidden.txt")
        try Data("hidden".utf8).write(to: hidden)

        let defaultsName = "ZF08-Recents-Defaults-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let recent = ZF08RecentItemsStub(urls: [first, first, second, hidden])
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
            recentItems: recent, grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.reload()
        #expect(state.items.count == 2)
        #expect(Set(state.items.compactMap(\.localURL)) == [first, second])
        state.preferences.showHiddenFiles = true
        await state.reload()
        #expect(state.items.count == 3)
    }

    @Test("Spotlight identity filter deduplicates symlinks and hard links before its limit")
    func spotlightIdentityFilter() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZF08-Identity-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("First.txt")
        let second = root.appendingPathComponent("Second.txt")
        let symlink = root.appendingPathComponent("First link.txt")
        let hardlink = root.appendingPathComponent("First hardlink.txt")
        try Data("same".utf8).write(to: first)
        try Data("same".utf8).write(to: second)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: first)
        try FileManager.default.linkItem(at: first, to: hardlink)

        var filter = RecentFileIdentityFilter(maximumCount: 2)
        for url in [first, first, symlink, hardlink, second] {
            filter.appendIfNew(url)
        }
        #expect(filter.urls == [first, second])
        #expect(filter.isFull)
    }

    @Test("Recents never displays Zforge's staged archive copies")
    @MainActor
    func stagedArchivesStayOutOfRecents() async throws {
        let fileManager = FileManager.default
        let fixtureID = UUID().uuidString
        let originalDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("ZF-Recents-Original-\(fixtureID)", isDirectory: true)
        let sessionsRoot = fileManager.temporaryDirectory
            .appendingPathComponent("Zforge", isDirectory: true)
            .appendingPathComponent("ArchiveSessions", isDirectory: true)
        let sessionDirectory = sessionsRoot
            .appendingPathComponent(fixtureID, isDirectory: true)
        let nestedSessionDirectory = sessionsRoot
            .appendingPathComponent("Operations", isDirectory: true)
            .appendingPathComponent(fixtureID, isDirectory: true)
        try fileManager.createDirectory(at: originalDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: nestedSessionDirectory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: originalDirectory)
            try? fileManager.removeItem(at: sessionDirectory)
            try? fileManager.removeItem(at: nestedSessionDirectory)
        }

        let original = originalDirectory.appendingPathComponent("Archive.7z")
        let staged = sessionDirectory.appendingPathComponent("Archive.7z")
        let operationCopy = nestedSessionDirectory.appendingPathComponent("Archive.7z")
        let stagedLink = originalDirectory.appendingPathComponent("Staged link.7z")
        try Data("archive".utf8).write(to: original)
        try fileManager.copyItem(at: original, to: staged)
        try fileManager.copyItem(at: original, to: operationCopy)
        try fileManager.createSymbolicLink(at: stagedLink, withDestinationURL: staged)

        var filter = RecentFileIdentityFilter(maximumCount: 1)
        for url in [staged, stagedLink, operationCopy, original] { filter.appendIfNew(url) }
        #expect(filter.urls == [original])

        let defaultsName = "ZF-Recents-Defaults-\(fixtureID)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(),
            recentItems: ZF08RecentItemsStub(urls: [staged, stagedLink, operationCopy, original]),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.reload()
        #expect(state.items.compactMap(\.localURL) == [original])
        for mode in BrowserViewMode.allCases {
            state.preferences.viewMode = mode
            #expect(state.flattenedList().map(\.item.id) == state.items.map(\.id))
        }
    }

    @Test("Archive metadata preserves metadata and synthesizes parent directories")
    func listingParser() throws {
        let entry = ArchiveEntry(path: "Folder/hello.txt", isDirectory: false,
            size: 5, packedSize: 3, modified: Date(), created: nil, accessed: nil,
            encrypted: true, checksum: "ABCD1234", method: "Deflate", attributes: nil)
        let entries = ArchiveEntry.withParents([entry.path: entry])
        #expect(entries.count == 2)
        #expect(entries["Folder"]?.isDirectory == true)
        #expect(entries["Folder/hello.txt"]?.size == 5)
        #expect(entries["Folder/hello.txt"]?.packedSize == 3)
        #expect(entries["Folder/hello.txt"]?.encrypted == true)
        #expect(entries["Folder/hello.txt"]?.method == "Deflate")
        #expect(entries["Folder/hello.txt"]?.modified != nil)
    }

    @Test("Archive path policy rejects absolute paths and traversal")
    func listingRejectsUnsafePaths() {
        for path in ["nul\0path", "/absolute.txt", "../escape.txt", "Folder/../escape.txt", "\\absolute.txt"] {
            #expect(throws: ArchiveEngineError.unsafePath) {
                _ = try ArchivePathPolicy.safePath(path)
            }
        }
    }

    @Test("A delayed reload cannot overwrite a newer result for the same location")
    @MainActor
    func delayedReloadIsDiscarded() async {
        let older = item("Old.txt")
        let newer = item("New.txt")
        let fileSystem = ZF08RacingFileSystem(older: older, newer: newer)
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(), fileSystem: fileSystem,
            recentItems: ZF08RecentItemsStub(urls: []),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        let firstReload = Task {
            await state.navigateToSidebar(URL(fileURLWithPath: "/tmp"), name: "tmp")
        }
        await fileSystem.waitUntilFirstLoadStarts()
        await state.reload()
        await fileSystem.releaseFirstLoad()
        await firstReload.value
        #expect(state.items.map(\.name) == ["New.txt"])
    }

    @Test("A stale expanded-folder load cannot replace the newer hierarchy")
    @MainActor
    func delayedExpandedHierarchyIsDiscarded() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ZF08-Hierarchy-\(UUID().uuidString)", isDirectory: true
        )
        let folderURL = root.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = BrowserItem(
            id: BrowserItemID(rawValue: folderURL.path), name: "Folder",
            location: .fileSystem(folderURL), isContainer: true, isDirectory: true,
            isPackage: false, isSymbolicLink: false, isHidden: false,
            isArchive: false, size: nil, packedSize: nil, creationDate: nil,
            modificationDate: nil, accessDate: nil, tags: [],
            contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: nil
        )
        let old = item("OldChild.txt")
        let new = item("NewChild.txt")
        let fileSystem = ZF08RacingHierarchyFileSystem(
            root: root, folder: folder, older: old, newer: new
        )
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(), fileSystem: fileSystem,
            recentItems: ZF08RecentItemsStub(urls: []),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        state.location = .fileSystem(root)
        state.pathComponents = [BrowserPathComponent(
            location: .fileSystem(root), name: root.lastPathComponent, isArchive: false
        )]
        state.expandedItems = [folder.id]

        let firstReload = Task { await state.reload() }
        await fileSystem.waitUntilFirstChildLoadStarts()
        await state.reload()
        await fileSystem.releaseFirstChildLoad()
        await firstReload.value

        #expect(state.expandedChildren[folder.id]?.map(\.name) == ["NewChild.txt"])
    }

    private func item(_ name: String, archive: Bool = false) -> BrowserItem {
        let url = URL(fileURLWithPath: "/tmp/\(name)")
        return BrowserItem(
            id: BrowserItemID(rawValue: url.path), name: name,
            location: .fileSystem(url), isContainer: false, isDirectory: false,
            isPackage: false, isSymbolicLink: false, isHidden: false,
            isArchive: archive, size: 1, packedSize: nil, creationDate: nil,
            modificationDate: nil, accessDate: nil, tags: [],
            contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: nil
        )
    }
}

@MainActor
private final class ZF08RecentItemsStub: RecentItemsServing {
    let urls: [URL]
    init(urls: [URL]) { self.urls = urls }
    func recentItemURLs() async -> [URL] { urls }
    func stop() {}
}

private actor ZF08RacingFileSystem: FileSystemServing {
    let older: BrowserItem
    let newer: BrowserItem
    private var loadCount = 0
    private var firstLoadStarted: CheckedContinuation<Void, Never>?
    private var firstLoadRelease: CheckedContinuation<Void, Never>?

    init(older: BrowserItem, newer: BrowserItem) {
        self.older = older
        self.newer = newer
    }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        loadCount += 1
        if loadCount == 1 {
            firstLoadStarted?.resume()
            firstLoadStarted = nil
            await withCheckedContinuation { firstLoadRelease = $0 }
            return [older]
        }
        return [newer]
    }

    func waitUntilFirstLoadStarts() async {
        guard loadCount == 0 else { return }
        await withCheckedContinuation { firstLoadStarted = $0 }
    }

    func releaseFirstLoad() {
        firstLoadRelease?.resume()
        firstLoadRelease = nil
    }

    func item(at url: URL) async throws -> BrowserItem { newer }
    func recursiveSize(at url: URL) async throws -> Int64 { 0 }
    func resolveNavigationURL(_ url: URL) async throws -> URL { url }
}

private actor ZF08RacingHierarchyFileSystem: FileSystemServing {
    let root: URL
    let folder: BrowserItem
    let older: BrowserItem
    let newer: BrowserItem
    private var childLoadCount = 0
    private var firstChildLoadStarted: CheckedContinuation<Void, Never>?
    private var firstChildLoadRelease: CheckedContinuation<Void, Never>?

    init(root: URL, folder: BrowserItem, older: BrowserItem, newer: BrowserItem) {
        self.root = root
        self.folder = folder
        self.older = older
        self.newer = newer
    }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        guard directory != root else { return [folder] }
        childLoadCount += 1
        if childLoadCount == 1 {
            firstChildLoadStarted?.resume()
            firstChildLoadStarted = nil
            await withCheckedContinuation { firstChildLoadRelease = $0 }
            return [older]
        }
        return [newer]
    }

    func waitUntilFirstChildLoadStarts() async {
        guard childLoadCount == 0 else { return }
        await withCheckedContinuation { firstChildLoadStarted = $0 }
    }

    func releaseFirstChildLoad() {
        firstChildLoadRelease?.resume()
        firstChildLoadRelease = nil
    }

    func item(at url: URL) async throws -> BrowserItem { folder }
    func recursiveSize(at url: URL) async throws -> Int64 { 0 }
    func resolveNavigationURL(_ url: URL) async throws -> URL { url }
}
