import Foundation
import Testing
@testable import Zforge

@Suite("File browser domain")
struct ZforgeTests {
    @Test("Folder icons distinguish empty directories from directories with contents")
    func folderContentsDetection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeFolderIcon-\(UUID().uuidString)", isDirectory: true)
        let empty = root.appendingPathComponent("Empty", isDirectory: true)
        let nonEmpty = root.appendingPathComponent("NonEmpty", isDirectory: true)
        let hiddenOnly = root.appendingPathComponent("HiddenOnly", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nonEmpty, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: hiddenOnly, withIntermediateDirectories: true)
        try Data().write(to: nonEmpty.appendingPathComponent("document.txt"))
        try Data().write(to: hiddenOnly.appendingPathComponent(".hidden"))

        var cache: [String: FolderContentsCacheEntry] = [:]
        let emptyDate = try empty.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        let nonEmptyDate = try nonEmpty.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        let hiddenOnlyDate = try hiddenOnly.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        #expect(!FolderContentsDetector.hasContents(at: empty, modificationDate: emptyDate, cache: &cache))
        #expect(FolderContentsDetector.hasContents(at: nonEmpty, modificationDate: nonEmptyDate, cache: &cache))
        #expect(FolderContentsDetector.hasContents(at: hiddenOnly, modificationDate: hiddenOnlyDate, cache: &cache))
    }

    @Test("Get Info calculates the recursive size of folders")
    func getInfoCalculatesRecursiveFolderSize() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeFolderSize-\(UUID().uuidString)", isDirectory: true)
        let nested = root.appendingPathComponent("Nested", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 3).write(to: root.appendingPathComponent("Root.bin"))
        try Data(repeating: 0, count: 5).write(to: nested.appendingPathComponent(".Hidden.bin"))

        let size = try await FileSystemService().recursiveSize(at: root)

        #expect(size == 8)
    }

    @Test("Get Info reports folder size calculation and its result")
    func getInfoFolderSizeSummary() {
        let folder = item("Folder", directory: true, size: nil)
        let locale = Locale(identifier: "en")

        let calculating = BrowserSelectionSummary(
            items: [folder],
            locale: locale,
            calculatingSizeIDs: [folder.id]
        )
        #expect(calculating.subtitle == "Folder · Calculating…")

        let resolved = BrowserSelectionSummary(
            items: [folder],
            locale: locale,
            sizeOverrides: [folder.id: 8]
        )
        #expect(resolved.subtitle == "Folder · 8 bytes")
    }

    @Test("Sidebar maximum width always reserves 360 points for content")
    func sidebarMaximumWidth() {
        #expect(BrowserSidebarLayout.maximumWidth(for: 640) == 280)
        #expect(BrowserSidebarLayout.maximumWidth(for: 900) == 540)
        #expect(BrowserSidebarLayout.maximumWidth(for: 1_100) == 740)
    }

    @Test("Hidden items remain distinguishable while preserving selected legibility")
    func hiddenItemVisualEmphasis() {
        let regular = BrowserItemVisualStyle.contentOpacity(isHidden: false, isSelected: false)
        let hidden = BrowserItemVisualStyle.contentOpacity(isHidden: true, isSelected: false)
        let selectedHidden = BrowserItemVisualStyle.contentOpacity(isHidden: true, isSelected: true)

        #expect(regular == 1)
        #expect(hidden < selectedHidden)
        #expect(selectedHidden < regular)
    }

    @Test("The sidebar places the real user directory in Locations")
    @MainActor
    func sidebarUsesRealUserHome() throws {
        let suite = "SidebarDefaults-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let sidebar = SidebarState()
        sidebar.pinnedFolders = PinnedFolderStore(defaults: defaults)

        #expect(sidebar.userHome.url == UserDirectoryService.homeURL)
        #expect(sidebar.userHome.name == UserDirectoryService.homeURL.lastPathComponent)
        #expect(sidebar.userHome.name == NSUserName())
        #expect(!sidebar.userHome.url.path.contains("/Library/Containers/"))
        #expect(sidebar.userHome.name != "Data")
        #expect(!sidebar.favorites.contains { $0.url == sidebar.userHome.url })

        let favorites = Dictionary(uniqueKeysWithValues: sidebar.favorites.map { ($0.name, $0.url) })
        #expect(favorites["Desktop"] == UserDirectoryService.homeURL.appendingPathComponent("Desktop", isDirectory: true))
        #expect(favorites["Documents"] == UserDirectoryService.homeURL.appendingPathComponent("Documents", isDirectory: true))
        #expect(favorites["Downloads"] == UserDirectoryService.homeURL.appendingPathComponent("Downloads", isDirectory: true))
        #expect(sidebar.favorites.allSatisfy { !$0.url.path.contains("/Library/Containers/") })
    }

    @Test("Go to Folder expands tilde from the real user directory")
    func goToFolderUsesRealUserHome() {
        let home = UserDirectoryService.homeURL.standardizedFileURL

        #expect(UserDirectoryService.url(forUserEnteredPath: "~") == home)
        #expect(
            UserDirectoryService.url(forUserEnteredPath: "~/Documents")
                == home.appendingPathComponent("Documents", isDirectory: true).standardizedFileURL
        )
        #expect(
            UserDirectoryService.url(forUserEnteredPath: "/Applications")
                == URL(fileURLWithPath: "/Applications", isDirectory: true).standardizedFileURL
        )
        #expect(!UserDirectoryService.url(forUserEnteredPath: "~").path.contains("/Library/Containers/"))
    }

    @Test("Filesystem breadcrumbs include the volume and every ancestor")
    @MainActor
    func filesystemBreadcrumbShowsCompletePath() async {
        let home = UserDirectoryService.homeURL
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(),
            fileSystem: UIFixtureFileSystemService(),
            recentItems: RecentItemsStub(urls: []),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )

        await state.navigateToSidebar(home, name: home.lastPathComponent)

        #expect(state.pathComponents.map(\.name) == [home.lastPathComponent])
        #expect(state.breadcrumbComponents.map(\.location) == [
            .fileSystem(URL(fileURLWithPath: "/", isDirectory: true)),
            .fileSystem(URL(fileURLWithPath: "/Users", isDirectory: true)),
            .fileSystem(home)
        ])
        #expect(state.breadcrumbComponents.map(\.name).suffix(2) == ["Users", home.lastPathComponent])
        #expect(state.breadcrumbComponents.first?.name == "Macintosh HD")

        let users = state.breadcrumbComponents[1]
        await state.navigateBreadcrumb(to: users)
        #expect(state.location == .fileSystem(URL(fileURLWithPath: "/Users", isDirectory: true)))
        #expect(state.pathComponents.map(\.name) == ["Users"])
        #expect(state.breadcrumbComponents.map(\.name) == ["Macintosh HD", "Users"])
    }

    @Test("Archive registry excludes specialized ZIP documents")
    func archiveRecognition() {
        #expect(ArchiveFormatRegistry.recognizes("backup.7z"))
        #expect(ArchiveFormatRegistry.recognizes("photos.tar.gz"))
        #expect(ArchiveFormatRegistry.recognizes("parts.7z.001"))
        #expect(!ArchiveFormatRegistry.recognizes("report.docx"))
        #expect(!ArchiveFormatRegistry.recognizes("disk.dmg"))
    }

    @Test("Inline archive trees use the conservative fast-format policy")
    func inlineArchiveRecognition() {
        #expect(ArchiveFormatRegistry.supportsFastTreeListing("backup.7z"))
        #expect(ArchiveFormatRegistry.supportsFastTreeListing("backup.zip"))
        #expect(!ArchiveFormatRegistry.supportsFastTreeListing("backup.tar"))
        #expect(!ArchiveFormatRegistry.supportsFastTreeListing("backup.tar.gz"))
        #expect(!ArchiveFormatRegistry.supportsFastTreeListing("backup.rar"))
        #expect(!ArchiveFormatRegistry.supportsFastTreeListing("backup.7z.001"))

        let rootArchive = item("backup.zip", archive: true)
        #expect(rootArchive.canExpandInlineInList)
        #expect(rootArchive.usesStaticIconPreview)

        let address = ArchiveAddress(
            sessionID: UUID(),
            archiveID: UUID(),
            internalPath: "inner.zip",
            allowsNestedArchives: true
        )
        let nestedArchive = BrowserItem(
            id: BrowserItemID(rawValue: "inner.zip"), name: "inner.zip", location: .archive(address),
            isContainer: false, isDirectory: false, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: true, size: 100,
            packedSize: 50, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: "Deflate"
        )
        #expect(nestedArchive.canExpandInlineInList)
        #expect(nestedArchive.canNavigateAsArchive)

        let blockedAddress = ArchiveAddress(
            sessionID: address.sessionID,
            archiveID: address.archiveID,
            internalPath: "blocked.zip",
            allowsNestedArchives: false
        )
        let blockedArchive = BrowserItem(
            id: BrowserItemID(rawValue: "blocked.zip"), name: "blocked.zip", location: .archive(blockedAddress),
            isContainer: false, isDirectory: false, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: true, size: 100,
            packedSize: 50, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: "Deflate"
        )
        #expect(!blockedArchive.canExpandInlineInList)
        #expect(!blockedArchive.canNavigateAsArchive)
        #expect(!blockedArchive.isNavigableContainer)

        let nestedRAR = BrowserItem(
            id: BrowserItemID(rawValue: "inner.rar"), name: "inner.rar", location: .archive(address),
            isContainer: false, isDirectory: false, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: true, size: 100,
            packedSize: 50, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: nil
        )
        #expect(nestedRAR.canNavigateAsArchive)
        #expect(!nestedRAR.canExpandInlineInList)
    }

    @Test("Nested archive policy uses configurable size and depth limits")
    func nestedArchivePolicy() {
        let limit: Int64 = 3 * 1_000_000_000
        let policy = ArchiveBrowsingPolicy(maximumNestedArchiveDepth: 7, rootSizeLimit: limit)
        #expect(policy.maximumNestedArchiveDepth == 7)
        #expect(policy.rootSizeLimit == limit)
        #expect(policy.allowsNestedArchives(forOutermostSize: limit - 1))
        #expect(!policy.allowsNestedArchives(forOutermostSize: limit))
        #expect(!policy.allowsNestedArchives(forOutermostSize: limit + 1))
        #expect(!policy.allowsNestedArchives(forOutermostSize: nil))

        let clamped = ArchiveBrowsingPolicy(
            maximumNestedArchiveDepth: 50,
            rootSizeLimit: 12 * 1_000_000_000
        )
        #expect(clamped.maximumNestedArchiveDepth == 10)
        #expect(clamped.rootSizeLimit == 5 * 1_000_000_000)

        let address = ArchiveAddress(
            sessionID: UUID(), archiveID: UUID(), internalPath: "Folder",
            allowsNestedArchives: true,
            nestedArchiveDepth: 7,
            maximumNestedArchiveDepth: 7
        )
        let childAddress = address.appending("Inner.zip")
        #expect(childAddress.allowsNestedArchives)
        #expect(childAddress.nestedArchiveDepth == 7)
        #expect(childAddress.maximumNestedArchiveDepth == 7)
        #expect(!childAddress.canOpenNestedArchive)
    }

    @Test("Archive preferences persist defaults and clamp their ranges")
    @MainActor
    func archivePreferences() throws {
        let suiteName = "ZforgeTests.archivePreferences.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.archiveNestingLimit == 5)
        #expect(preferences.archiveRootSizeLimitGB == 1)
        #expect(preferences.archiveBrowsingPolicy == .standard)
        #expect(preferences.defaultCompressionFormat == .zip)

        preferences.archiveNestingLimit = 30
        preferences.archiveRootSizeLimitGB = 12
        preferences.defaultCompressionFormat = .gzip
        #expect(preferences.archiveNestingLimit == 10)
        #expect(preferences.archiveRootSizeLimitGB == 5)

        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(reloaded.archiveNestingLimit == 10)
        #expect(reloaded.archiveRootSizeLimitGB == 5)
        #expect(reloaded.defaultCompressionFormat == .gzip)
    }

    @Test("Compression profiles persist settings but never persist passwords")
    @MainActor
    func compressionProfiles() throws {
        let suiteName = "ZforgeTests.compressionProfiles.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.defaultCompressionProfile.name == "Auto")
        let options = CompressionOptions(
            format: .sevenZip, level: 9, method: .lzma2, dictionaryMB: 64,
            fastBytes: 128, solid: false, threads: 4,
            requiresPassword: true, encryptFileNames: true
        )
        let id = preferences.createCompressionProfile(name: "Private", options: options)
        preferences.defaultCompressionProfileID = id
        preferences.setSessionPassword("only-in-memory", for: id)

        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(reloaded.defaultCompressionProfileID == id)
        #expect(reloaded.defaultCompressionProfile.options == options)
        #expect(reloaded.sessionPassword(for: id).isEmpty)

        reloaded.deleteCompressionProfile(id)
        #expect(reloaded.defaultCompressionProfileID != id)
        #expect(reloaded.compressionProfiles.count == 1)
    }

    @Test("The former built-in profile name migrates to Auto")
    @MainActor
    func defaultCompressionProfileNameMigration() throws {
        let suiteName = "ZforgeTests.defaultCompressionProfileNameMigration.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let oldProfile = CompressionProfile(name: "Default", options: CompressionOptions(format: .sevenZip))
        defaults.set(try JSONEncoder().encode([oldProfile]), forKey: "archive.compressionProfiles")
        defaults.set(oldProfile.id.uuidString, forKey: "archive.defaultCompressionProfileID")

        let migrated = FileBrowserPreferences(defaults: defaults)
        #expect(migrated.defaultCompressionProfile.name == "Auto")
        #expect(migrated.defaultCompressionProfile.options.format == .sevenZip)
        #expect(FileBrowserPreferences(defaults: defaults).defaultCompressionProfile.name == "Auto")
    }

    @Test("Compression properties are format-aware and never include the password")
    func compressionOptionSwitches() throws {
        let options = CompressionOptions(
            format: .sevenZip, level: 9, method: .lzma2, dictionaryMB: 64,
            fastBytes: 128, solid: false, threads: 4,
            requiresPassword: true, encryptFileNames: true
        )
        let args = try options.nativeProperties(password: "secret-sample")
        #expect(args["d"] == "64m" as NSString)
        #expect(args["fb"] == NSNumber(value: 128))
        #expect(args["s"] == NSNumber(value: false))
        #expect(args["he"] == NSNumber(value: true))
        #expect(!args.description.contains("secret-sample"))
        #expect(throws: ArchiveEngineError.passwordRequired) {
            _ = try options.nativeProperties(password: nil)
        }

        var tar = options
        tar.format = .tar
        let tarArgs = try tar.nativeProperties(password: nil)
        #expect(tarArgs.isEmpty)
    }

    @Test("Folders remain first while size order changes")
    func sorting() {
        let folder = item("Folder", directory: true, size: nil)
        let small = item("Small.txt", size: 10)
        let large = item("Large.txt", size: 100)

        let ascending = BrowserSort(field: .size, ascending: true).sorted([large, small, folder])
        #expect(ascending.map(\.name) == ["Folder", "Small.txt", "Large.txt"])

        let descending = BrowserSort(field: .size, ascending: false).sorted([small, folder, large])
        #expect(descending.map(\.name) == ["Folder", "Large.txt", "Small.txt"])
    }

    @Test("List expands Name only after every column fits beside the preview")
    @MainActor
    func listResponsiveLayout() {
        let narrowWidth: CGFloat = 450
        let previewWidth: CGFloat = 300
        let minimumWidth = BrowserListLayout.minimumTableWidth(scale: 1)

        #expect(minimumWidth == 612)
        #expect(BrowserListLayout.tableWidth(availableWidth: narrowWidth, scale: 1) == minimumWidth)
        #expect(BrowserListLayout.tableWidth(availableWidth: 900, scale: 1) == 900)
        #expect(
            BrowserListLayout.tableWidth(
                availableWidth: 750,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == minimumWidth
        )
        #expect(
            BrowserListLayout.tableWidth(
                availableWidth: minimumWidth + previewWidth,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == minimumWidth
        )
        #expect(
            BrowserListLayout.tableWidth(
                availableWidth: minimumWidth + previewWidth + 1,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == minimumWidth + 1
        )
        #expect(
            BrowserListLayout.tableWidth(
                availableWidth: 1_000,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == 700
        )
        #expect(
            BrowserListLayout.scrollContentWidth(
                availableWidth: narrowWidth,
                obscuredTrailingWidth: 0,
                scale: 1
            ) == minimumWidth
        )
        #expect(
            BrowserListLayout.scrollContentWidth(
                availableWidth: 750,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == minimumWidth + previewWidth
        )
        #expect(
            BrowserListLayout.scrollContentWidth(
                availableWidth: 1_000,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            ) == 1_000
        )
        #expect(
            BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: narrowWidth,
                obscuredTrailingWidth: 0,
                scale: 1
            )
        )
        #expect(
            BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: 750,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            )
        )
        #expect(
            !BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: minimumWidth + previewWidth,
                obscuredTrailingWidth: previewWidth,
                scale: 1
            )
        )
        #expect(
            !BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: 900,
                obscuredTrailingWidth: 0,
                scale: 1
            )
        )
        #expect(BrowserListLayout.minimumTableWidth(scale: 1.6) == minimumWidth * 1.6)
    }

    @Test("List range selection follows flattened visible rows")
    @MainActor
    func listRangeSelectionUsesVisibleOrder() async {
        let before = item("Before", directory: true)
        let parent = item("Parent", directory: true)
        let firstChild = item("First child", directory: true)
        let secondChild = item("Second child", directory: true)
        let after = item("After", directory: true)
        let state = FileBrowserState()
        state.items = [before, parent, after]
        state.expandedItems = [parent.id]
        state.expandedChildren[parent.id] = [firstChild, secondChild]

        let visibleItems = state.flattenedList().map(\.item)
        let parentIndex = try! #require(visibleItems.firstIndex(where: { $0.id == parent.id }))
        state.select(parent, orderedItems: visibleItems)
        state.moveSelection(by: 2, extending: true, orderedItems: visibleItems)

        let expandedRange = Set(visibleItems[parentIndex...(parentIndex + 2)].map(\.id))
        #expect(state.selection == expandedRange)
        #expect(state.focusedItemID == visibleItems[parentIndex + 2].id)
        #expect(!state.selection.contains(after.id))

        state.moveSelection(by: -1, extending: true, orderedItems: visibleItems)
        let contractedRange = Set(visibleItems[parentIndex...(parentIndex + 1)].map(\.id))
        #expect(state.selection == contractedRange)
        #expect(state.focusedItemID == visibleItems[parentIndex + 1].id)

        state.select(firstChild, orderedItems: visibleItems)
        await state.moveListSelectionLeft()
        #expect(state.selection == [parent.id])
        #expect(state.focusedItemID == parent.id)

        await state.moveListSelectionLeft()
        #expect(!state.expandedItems.contains(parent.id))
        #expect(state.selection == [parent.id])
    }

    @Test("Archive toolbar action follows location and selection")
    @MainActor
    func archiveToolbarAction() {
        let archiveOne = item("One.zip", archive: true)
        let archiveTwo = item("Two.7z", archive: true)
        let document = item("Document.txt")
        let state = FileBrowserState()
        state.items = [archiveOne, archiveTwo, document]

        #expect(state.archiveToolbarAction == .unavailableOutsideArchive)

        state.location = .fileSystem(URL(fileURLWithPath: "/tmp/ArchiveToolbar"))
        state.selection = [archiveOne.id, archiveTwo.id]
        #expect(state.archiveToolbarAction == .extractAll)

        state.selection = [archiveOne.id, document.id]
        #expect(state.archiveToolbarAction == .compress)

        state.location = .archive(
            ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: "")
        )
        state.selection.removeAll()
        #expect(state.archiveToolbarAction == .unavailableInsideArchive)

        state.selection = [document.id]
        #expect(state.archiveToolbarAction == .compress)

        state.selection = [archiveOne.id]
        #expect(state.archiveToolbarAction == .extractAll)
    }

    @Test("Dragging a selected item includes every selected local item")
    @MainActor
    func dragPayloadUsesTheFullSelection() {
        let first = item("First.zip", archive: true)
        let second = item("Second.zip", archive: true)
        let unselected = item("Third.zip", archive: true)
        let state = FileBrowserState()
        state.items = [first, second, unselected]
        state.selection = [first.id, second.id]
        state.focusedItemID = second.id

        let selectedURLs = state.dragSelectionURLs
        #expect(Set(selectedURLs) == Set([first.localURL, second.localURL].compactMap { $0 }))
        #expect(state.prepareDragPayload(selectedURLs) == selectedURLs)
        #expect(state.selection == [first.id, second.id])

        let unselectedURL = try! #require(unselected.localURL)
        #expect(state.prepareDragPayload([unselectedURL]) == [unselectedURL])
        #expect(state.selection == [unselected.id])
    }

    @Test("Column compression creates the archive beside the selected folder")
    @MainActor
    func columnCompressionUsesSelectedItemParent() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnCompression-\(UUID().uuidString)", isDirectory: true)
        let sourceDirectory = root.appendingPathComponent("7z2602-mac", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try Data("Zforge".utf8).write(to: sourceDirectory.appendingPathComponent("readme.txt"))
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeColumnCompression-\(UUID().uuidString)"
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
            archives: NativeSevenZipArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let sourceItem = try #require(state.items.first(where: { $0.name == sourceDirectory.lastPathComponent }))
        let openingTask = state.activateColumnItem(sourceItem, in: state.location)
        await openingTask.value

        #expect(state.archiveToolbarAction == .compress)
        #expect(await state.performArchiveToolbarAction() != nil)
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("7z2602-mac.zip").path))
        #expect(!FileManager.default.fileExists(atPath: sourceDirectory.appendingPathComponent("7z2602-mac.zip").path))
        #expect(
            state.columnItems[.fileSystem(root)]?.contains(where: {
                $0.name == "7z2602-mac.zip"
            }) == true
        )
    }

    @Test("Quick compression uses the selected default profile")
    @MainActor
    func quickCompressionUsesProfile() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeCompressionProfile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("readme.txt")
        try Data("Profile settings".utf8).write(to: source)

        let suiteName = "ZforgeCompressionProfile-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        let id = preferences.createCompressionProfile(
            name: "High compression",
            options: CompressionOptions(format: .sevenZip, level: 9, method: .lzma2, dictionaryMB: 16)
        )
        preferences.defaultCompressionProfileID = id
        let state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(),
            fileOperations: FileOperationService(), grants: UIFixtureAccessGrantStore(),
            archives: NativeSevenZipArchiveEngine()
        )
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let item = try #require(state.items.first(where: { $0.name == source.lastPathComponent }))
        state.select(item)
        #expect(await state.performArchiveToolbarAction() != nil)
        let output = root.appendingPathComponent("readme.7z")
        #expect(FileManager.default.fileExists(atPath: output.path))
        let engine = NativeSevenZipArchiveEngine()
        try await engine.testArchive(at: output, password: nil)
    }

    @Test("Extracting an internal folder refreshes its destination column")
    @MainActor
    func columnInternalExtractionRefreshesDestination() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnExtraction-\(UUID().uuidString)", isDirectory: true)
        let archiveURL = root.appendingPathComponent("work_zipped.zip")
        let destination = root.appendingPathComponent("work_zipped", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: fixturesURL.appendingPathComponent("sample-root.zip"),
            to: archiveURL
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeColumnExtraction-\(UUID().uuidString)"
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
            archives: NativeSevenZipArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let archiveItem = try #require(state.items.first(where: { $0.name == archiveURL.lastPathComponent }))
        await state.activateColumnItem(archiveItem, in: state.location).value
        let folder = try #require(state.items.first(where: { $0.name == "Folder" }))
        state.select(folder)

        #expect(state.archiveToolbarAction == .extractSelected)
        #expect(await state.performArchiveToolbarAction() != nil)
        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("Folder").path))
        #expect(
            state.columnItems[.fileSystem(root)]?.contains(where: {
                $0.name == destination.lastPathComponent
            }) == true
        )
    }

    @Test("Extracting from nested archives preserves every archive boundary")
    @MainActor
    func columnNestedArchiveExtractionPreservesHierarchy() async throws {
        let fileManager = FileManager.default
        let buildRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ZforgeNestedArchiveBuild-\(UUID().uuidString)", isDirectory: true)
        let browsingRoot = fileManager.temporaryDirectory
            .appendingPathComponent("ZforgeNestedArchiveExtraction-\(UUID().uuidString)", isDirectory: true)
        let sourceFolder = buildRoot
            .appendingPathComponent("Payload", isDirectory: true)
            .appendingPathComponent("work", isDirectory: true)
        let selectedFolder = sourceFolder
            .appendingPathComponent("qintess", isDirectory: true)
            .appendingPathComponent("sgo", isDirectory: true)
            .appendingPathComponent("gestao-orcamentaria-nginx", isDirectory: true)
        let readmeURL = selectedFolder.appendingPathComponent("README.md")
        let workArchiveURL = buildRoot.appendingPathComponent("work.zip")
        let middleArchiveURL = buildRoot.appendingPathComponent("Archive.zip")
        let outerArchiveURL = browsingRoot.appendingPathComponent("Archive 2.zip")
        try fileManager.createDirectory(at: selectedFolder, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: browsingRoot, withIntermediateDirectories: true)
        try Data("# Nested archive".utf8).write(to: readmeURL)
        defer {
            try? fileManager.removeItem(at: buildRoot)
            try? fileManager.removeItem(at: browsingRoot)
        }

        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(
            from: [sourceFolder],
            outputURL: workArchiveURL,
            format: .zip,
            progress: { _ in }
        )
        try await engine.createArchive(
            from: [workArchiveURL],
            outputURL: middleArchiveURL,
            format: .zip,
            progress: { _ in }
        )
        try await engine.createArchive(
            from: [middleArchiveURL],
            outputURL: outerArchiveURL,
            format: .zip,
            progress: { _ in }
        )

        let suiteName = "ZforgeNestedArchiveExtraction-\(UUID().uuidString)"
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
            archives: engine
        )
        defer { state.close() }

        await state.navigateToSidebar(browsingRoot, name: browsingRoot.lastPathComponent)
        let outerArchive = try #require(state.items.first(where: { $0.name == "Archive 2.zip" }))
        await state.activateColumnItem(outerArchive, in: state.location).value
        let middleArchive = try #require(state.items.first(where: { $0.name == "Archive.zip" }))
        await state.activateColumnItem(middleArchive, in: state.location).value
        let workArchive = try #require(state.items.first(where: { $0.name == "work.zip" }))
        await state.activateColumnItem(workArchive, in: state.location).value

        for folderName in ["work", "qintess", "sgo", "gestao-orcamentaria-nginx"] {
            let folder = try #require(state.items.first(where: { $0.name == folderName }))
            await state.activateColumnItem(folder, in: state.location).value
        }
        let readme = try #require(state.items.first(where: { $0.name == "README.md" }))
        state.select(readme)

        #expect(state.archiveToolbarAction == .extractSelected)
        #expect(await state.performArchiveToolbarAction() != nil)
        let expectedURL = browsingRoot
            .appendingPathComponent("Archive 2", isDirectory: true)
            .appendingPathComponent("Archive", isDirectory: true)
            .appendingPathComponent("work", isDirectory: true)
            .appendingPathComponent("work", isDirectory: true)
            .appendingPathComponent("qintess", isDirectory: true)
            .appendingPathComponent("sgo", isDirectory: true)
            .appendingPathComponent("gestao-orcamentaria-nginx", isDirectory: true)
            .appendingPathComponent("README.md")
        #expect(fileManager.fileExists(atPath: expectedURL.path))
        #expect(
            state.columnItems[.fileSystem(browsingRoot)]?.contains(where: {
                $0.name == "Archive 2"
            }) == true
        )
    }

    @Test("Column action extracts an external archive selected in the base column")
    @MainActor
    func columnExternalArchiveExtractionFromBaseColumn() async throws {
        try await assertColumnExternalArchiveExtraction(nestedInDirectory: false)
    }

    @Test("Column action extracts an external archive selected in a right column")
    @MainActor
    func columnExternalArchiveExtractionFromRightColumn() async throws {
        try await assertColumnExternalArchiveExtraction(nestedInDirectory: true)
    }

    @Test("Deleting an open archive removes its virtual column and refreshes its parent")
    @MainActor
    func deletingOpenColumnArchiveRefreshesParent() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnArchiveDeletion-\(UUID().uuidString)", isDirectory: true)
        let archiveURL = root.appendingPathComponent("Codex.zip")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: fixturesURL.appendingPathComponent("sample-root.zip"),
            to: archiveURL
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeColumnArchiveDeletion-\(UUID().uuidString)"
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
            archives: NativeSevenZipArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let parentLocation = state.location
        let archiveItem = try #require(state.items.first(where: { $0.name == "Codex.zip" }))
        await state.activateColumnItem(archiveItem, in: parentLocation).value
        let archiveLocation = state.location

        #expect(archiveLocation != parentLocation)
        #expect(state.columnItems[archiveLocation]?.isEmpty == false)

        try FileManager.default.removeItem(at: archiveURL)
        await state.refreshColumnsAfterRemovingLocalItems([archiveURL])

        #expect(state.error == nil)
        #expect(state.location == parentLocation)
        #expect(state.activeColumnLocation == parentLocation)
        #expect(state.pathComponents.map(\.location) == [parentLocation])
        #expect(state.columnItems[archiveLocation] == nil)
        #expect(state.columnItems[parentLocation]?.contains(where: { $0.name == "Codex.zip" }) != true)
        #expect(state.items.contains(where: { $0.name == "Codex.zip" }) == false)
    }

    @Test("A regular window starts in Recents and loads Spotlight results")
    @MainActor
    func defaultLocationIsRecents() async {
        let recentURLs = [
            URL(fileURLWithPath: "/Users/example/Documents/Latest.txt"),
            URL(fileURLWithPath: "/Users/example/Downloads/Archive.zip")
        ]
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(),
            fileSystem: UIFixtureFileSystemService(),
            recentItems: RecentItemsStub(urls: recentURLs),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )

        #expect(state.location == .recents)
        #expect(state.title == "Recents")
        #expect(state.pathComponents.map(\.location) == [.recents])

        await state.start()

        #expect(Set(state.items.map(\.name)) == ["Latest.txt", "Archive.zip"])
        #expect(state.archiveToolbarAction == .unavailableOutsideArchive)
    }

    @Test("Preview visibility persists independently for every browser mode")
    @MainActor
    func previewVisibility() async throws {
        let suiteName = "ZforgeTests.preview.\(UUID().uuidString)"
        let defaults = try! #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        let document = item("Preview.txt")
        state.items = [document]
        state.select(document)
        try await Task.sleep(for: .milliseconds(120))

        #expect(state.previewVisible)
        #expect(state.previewURL == document.localURL)

        state.togglePreviewVisibility()
        #expect(!state.previewVisible)
        #expect(state.previewURL == nil)

        state.viewMode = .gallery
        state.updatePreview()
        try await Task.sleep(for: .milliseconds(120))
        #expect(state.previewVisible)
        #expect(state.previewURL == document.localURL)

        state.togglePreviewVisibility()
        #expect(!state.previewVisible)

        state.viewMode = .columns
        #expect(state.previewVisible)

        state.togglePreviewVisibility()
        #expect(!state.previewVisible)

        state.viewMode = .icons
        #expect(state.previewVisible)

        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(reloaded.previewVisible(in: .icons))
        #expect(!reloaded.previewVisible(in: .list))
        #expect(!reloaded.previewVisible(in: .columns))
        #expect(!reloaded.previewVisible(in: .gallery))
    }

    @Test("A pending preview never publishes after the focused item changes")
    @MainActor
    func obsoletePreviewIsDiscarded() async throws {
        let suite = "ZforgeObsoletePreview-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .icons
        preferences.setPreviewVisible(true, in: .icons)
        let state = FileBrowserState(
            preferences: preferences, fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        let first = item("First.txt")
        let second = item("Second.txt")
        state.items = [first, second]

        state.select(first)
        try await Task.sleep(for: .milliseconds(20))
        state.select(second)
        try await Task.sleep(for: .milliseconds(120))

        #expect(state.focusedItemID == second.id)
        #expect(state.previewURL == second.localURL)
        #expect(state.previewURL != first.localURL)
    }

    @Test("Multiple selection previews every eligible file alongside static items")
    @MainActor
    func multipleSelectionPreviewsEligibleFiles() throws {
        let suiteName = "ZforgeMultiplePreview-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        let firstDocument = item("First.pdf")
        let secondDocument = item("Second.png")
        let folder = item("Folder", directory: true)
        let archive = item("Archive.zip", archive: true)
        state.items = [firstDocument, folder, secondDocument, archive]
        state.selection = Set(state.items.map(\.id))
        state.focusedItemID = firstDocument.id

        state.updatePreview()

        #expect(state.previewURL(for: firstDocument) == firstDocument.localURL)
        #expect(state.previewURL(for: secondDocument) == secondDocument.localURL)
        #expect(state.previewURL(for: folder) == nil)
        #expect(state.previewURL(for: archive) == nil)
    }

    @Test("Column navigation replaces the obsolete right branch")
    @MainActor
    func columnNavigationReplacesRightBranch() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let oldURL = rootURL.appendingPathComponent("Old", isDirectory: true)
        let oldNestedURL = oldURL.appendingPathComponent("Nested", isDirectory: true)
        let replacementURL = rootURL.appendingPathComponent("Replacement", isDirectory: true)
        let documentURL = rootURL.appendingPathComponent("Document.txt")
        try FileManager.default.createDirectory(at: oldNestedURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: replacementURL, withIntermediateDirectories: true)
        try Data("Document".utf8).write(to: documentURL)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let fileSystem = FileSystemService()
        let replacement = try await fileSystem.item(at: replacementURL)
        let document = try await fileSystem.item(at: documentURL)
        let rootLocation = BrowserLocation.fileSystem(rootURL)
        let oldLocation = BrowserLocation.fileSystem(oldURL)
        let oldNestedLocation = BrowserLocation.fileSystem(oldNestedURL)
        let state = FileBrowserState()
        state.pathComponents = [
            BrowserPathComponent(location: rootLocation, name: "Root", isArchive: false),
            BrowserPathComponent(location: oldLocation, name: "Old", isArchive: false),
            BrowserPathComponent(location: oldNestedLocation, name: "Nested", isArchive: false)
        ]
        state.location = oldNestedLocation
        state.items = []
        state.columnItems[rootLocation] = [replacement, document]
        state.columnSelections[oldLocation] = BrowserItemID(rawValue: "obsolete")
        state.previewURL = documentURL

        let replacementActivation = state.activateColumnItem(replacement, in: rootLocation)

        #expect(state.primarySelection?.id == replacement.id)
        #expect(state.previewURL == nil)

        await replacementActivation.value

        #expect(state.pathComponents.map(\.location) == [rootLocation, .fileSystem(replacementURL)])
        #expect(state.location == .fileSystem(replacementURL))
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.selection == [replacement.id])
        #expect(state.primarySelection?.id == replacement.id)
        #expect(state.columnSelections[oldLocation] == nil)

        await state.activateColumnItem(document, in: rootLocation).value

        #expect(state.pathComponents.map(\.location) == [rootLocation])
        #expect(state.location == rootLocation)
        #expect(state.selection == [document.id])
    }

    @Test("Entering a right column activates and opens its first item")
    @MainActor
    func enteringRightColumnActivatesFirstItem() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let containerURL = rootURL.appendingPathComponent("Archive 3", isDirectory: true)
        let firstItemURL = containerURL.appendingPathComponent("dev", isDirectory: true)
        let nestedURL = firstItemURL.appendingPathComponent("Zforge", isDirectory: true)
        let fileContainerURL = rootURL.appendingPathComponent("Files", isDirectory: true)
        let documentURL = fileContainerURL.appendingPathComponent("Document.txt")
        try FileManager.default.createDirectory(at: nestedURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: fileContainerURL,
            withIntermediateDirectories: true
        )
        try Data("Preview".utf8).write(to: documentURL)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let suiteName = "ZforgeEnterRightColumn-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .columns
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(rootURL, name: rootURL.lastPathComponent)
        let rootLocation = state.location
        let container = try #require(state.items.first(where: { $0.name == "Archive 3" }))
        await state.activateColumnItem(container, in: rootLocation).value

        let containerLocation = state.location
        let firstItem = try #require(state.sortedColumnItems(at: containerLocation).first)
        #expect(firstItem.name == "dev")

        await state.activateFirstItemInColumn(at: containerLocation).value

        let firstItemLocation = BrowserLocation.fileSystem(try #require(firstItem.localURL))
        #expect(state.activeColumnLocation == containerLocation)
        #expect(state.columnSelections[containerLocation] == firstItem.id)
        #expect(state.location == firstItemLocation)
        #expect(state.pathComponents.last?.location == firstItemLocation)
        #expect(
            state.columnItems[firstItemLocation]?.contains(where: { $0.name == "Zforge" }) == true
        )

        await state.navigateToSidebar(rootURL, name: rootURL.lastPathComponent)
        let fileContainer = try #require(state.items.first(where: { $0.name == "Files" }))
        await state.activateColumnItem(fileContainer, in: state.location).value

        let fileContainerLocation = state.location
        let document = try #require(state.sortedColumnItems(at: fileContainerLocation).first)
        #expect(document.name == "Document.txt")
        await state.activateFirstItemInColumn(at: fileContainerLocation).value
        for _ in 0..<100 where state.previewURL != document.localURL {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(state.activeColumnLocation == fileContainerLocation)
        #expect(state.columnSelections[fileContainerLocation] == document.id)
        #expect(state.location == fileContainerLocation)
        #expect(state.previewURL == document.localURL)
    }

    @Test("Rapid column archive selection cancels the previous load before opening the next")
    @MainActor
    func rapidColumnArchiveSelectionPublishesOnlyCurrentArchive() async throws {
        let suiteName = "ZforgeColumnArchiveRace-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .columns
        preferences.language = .english
        let engine = ColumnArchiveRaceEngine()
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: engine
        )
        defer { state.close() }

        let rootLocation = BrowserLocation.fileSystem(
            URL(fileURLWithPath: "/tmp/ZforgeColumnArchiveRace", isDirectory: true)
        )
        let firstArchive = item("First.zip", archive: true)
        let secondArchive = item("Second.zip", archive: true)
        state.location = rootLocation
        state.pathComponents = [
            BrowserPathComponent(location: rootLocation, name: "Race", isArchive: false)
        ]
        state.items = [firstArchive, secondArchive]
        state.columnItems[rootLocation] = [firstArchive, secondArchive]
        state.archiveOperationDescription = "Compressing selected items…"

        let firstActivation = state.activateColumnItem(firstArchive, in: rootLocation)
        // End the setup immediately if the start signal never arrives.
        do {
            try await engine.waitUntilStarted("First.zip")
        } catch {
            state.close()
            await engine.shutdown()
            throw error
        }
        #expect(state.archiveOperationInProgress)
        #expect(state.archiveOperationDescription == "Loading…")
        let secondActivation = state.activateColumnItem(secondArchive, in: rootLocation)

        await secondActivation.value
        await firstActivation.value
        await engine.shutdown()

        let events = await engine.eventsSnapshot()
        let firstCancellation = try #require(events.firstIndex(of: "cancelled:First.zip"))
        let secondStart = try #require(events.firstIndex(of: "started:Second.zip"))
        #expect(firstCancellation < secondStart)
        #expect(!events.contains("completed:First.zip"))
        #expect(events.contains("completed:Second.zip"))
        #expect(state.pathComponents.last?.name == "Second.zip")
        #expect(state.pathComponents.contains(where: { $0.name == "First.zip" }) == false)
        #expect(state.items.map(\.name) == ["Second.zip content"])
    }

    @Test("Archive start signals remain available to late waiters")
    func archiveRaceSignalBeforeWaiter() async throws {
        let engine = ColumnArchiveRaceEngine()
        _ = try await engine.openArchive(at: URL(fileURLWithPath: "/tmp/Second.zip"),
                                         password: nil, policy: .standard)
        try await engine.waitUntilStarted("Second.zip")
        #expect(await engine.pendingWaiterCount() == 0)
        await engine.shutdown()
    }

    @Test("Archive start waits time out and release their continuations")
    func archiveRaceSignalTimeout() async throws {
        let engine = ColumnArchiveRaceEngine()
        await #expect(throws: ColumnArchiveRaceEngine.WaitError.timedOut("started:Missing.zip")) {
            try await engine.waitUntilStarted("Missing.zip", timeout: .milliseconds(20))
        }
        #expect(await engine.pendingWaiterCount() == 0)
        await engine.shutdown()
    }

    @Test("Cancelled archive start waits release their continuations")
    func archiveRaceSignalCancellation() async throws {
        let engine = ColumnArchiveRaceEngine()
        let waiting = Task { try await engine.waitUntilStarted("Missing.zip") }
        waiting.cancel()
        await #expect(throws: CancellationError.self) { try await waiting.value }
        #expect(await engine.pendingWaiterCount() == 0)
        await engine.shutdown()
    }

    @Test("Shutting down the race engine releases a pending archive load")
    func archiveRaceShutdownStopsPendingLoad() async throws {
        let engine = ColumnArchiveRaceEngine()
        let loading = Task {
            try await engine.openArchive(at: URL(fileURLWithPath: "/tmp/First.zip"),
                                         password: nil, policy: .standard)
        }
        do { try await engine.waitUntilStarted("First.zip") }
        catch {
            loading.cancel()
            await engine.shutdown()
            throw error
        }
        await engine.shutdown()
        await #expect(throws: ColumnArchiveRaceEngine.WaitError.shutDown) { try await loading.value }
        #expect(await engine.pendingWaiterCount() == 0)
    }

    @Test("Entering column view opens the selected folder without changing history")
    @MainActor
    func enteringColumnViewOpensSelectedFolder() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let selectedURL = rootURL.appendingPathComponent("Selected", isDirectory: true)
        let childURL = selectedURL.appendingPathComponent("Child.txt")
        try FileManager.default.createDirectory(at: selectedURL, withIntermediateDirectories: true)
        try Data("Child".utf8).write(to: childURL)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let fileSystem = FileSystemService()
        let selectedFolder = try await fileSystem.item(at: selectedURL)
        let rootLocation = BrowserLocation.fileSystem(rootURL)
        let selectedLocation = BrowserLocation.fileSystem(selectedURL)
        let state = FileBrowserState()
        state.pathComponents = [
            BrowserPathComponent(location: rootLocation, name: "Root", isArchive: false)
        ]
        state.location = rootLocation
        state.items = [selectedFolder]
        state.selection = [selectedFolder.id]
        state.focusedItemID = selectedFolder.id

        await state.prepareColumnView().value

        #expect(state.pathComponents.map(\.location) == [rootLocation, selectedLocation])
        #expect(state.location == selectedLocation)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.columnSelections[rootLocation] == selectedFolder.id)
        #expect(state.columnItems[selectedLocation]?.contains(where: { $0.name == "Child.txt" }) == true)
        #expect(!state.canGoBack)

        await state.prepareStandardViewAfterColumns().value

        #expect(state.pathComponents.map(\.location) == [rootLocation])
        #expect(state.location == rootLocation)
        #expect(state.selection == [selectedFolder.id])
        #expect(state.primarySelection?.id == selectedFolder.id)
        #expect(state.items.contains(where: { $0.id == selectedFolder.id }))
        #expect(!state.canGoBack)
    }

    @Test("Filesystem metadata handles hidden files and packages")
    func fileSystemMetadata() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("visible".utf8).write(to: root.appendingPathComponent("visible.txt"))
        try Data("hidden".utf8).write(to: root.appendingPathComponent(".hidden"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Demo.app"), withIntermediateDirectories: true)

        let service = FileSystemService()
        let visible = try await service.items(in: root, showHidden: false)
        #expect(!visible.contains(where: { $0.name == ".hidden" }))
        #expect(visible.first(where: { $0.name == "Demo.app" })?.isContainer == false)

        let all = try await service.items(in: root, showHidden: true)
        #expect(all.contains(where: { $0.name == ".hidden" && $0.isHidden }))
    }

    @Test("Real ZIP lists a virtual tree and materializes one item")
    func archiveRoundTrip() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let opened = try await engine.openArchive(at: fixturesURL.appendingPathComponent("sample-root.zip"), password: nil)
        let rootItems = try await engine.items(at: opened.address)
        #expect(rootItems.contains(where: { $0.name == "hello.txt" }))
        #expect(rootItems.contains(where: { $0.name == "Folder" && $0.isDirectory }))

        let hello = try #require(rootItems.first(where: { $0.name == "hello.txt" }))
        let folder = try #require(rootItems.first(where: { $0.name == "Folder" }))
        let folderAddress: ArchiveAddress
        switch folder.location {
        case let .archive(address):
            folderAddress = address
        case .fileSystem, .recents:
            Issue.record("The archive folder did not have a virtual address")
            return
        }
        let folderItems = try await engine.items(at: folderAddress)
        let expectedFolderSize = folderItems.compactMap(\.size).reduce(0, +)
        #expect(try await engine.recursiveSize(of: folder) == expectedFolderSize)
        let materialized = try await engine.materialize(item: hello, purpose: .preview, automaticLimit: 10 * 1_024 * 1_024)
        #expect(try String(contentsOf: materialized, encoding: .utf8) == "Hello from Zforge.\n")
        await engine.closeSession(opened.address.sessionID)
    }

    @Test("Archive confirmation survives dialog dismissal and refreshes the open archive",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip], ["", "Inside"])
    @MainActor
    func archiveAdditionAfterDialogDismissal(format: ArchiveCompressionFormat, internalPath: String) async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeArchiveConfirmation-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("Original.txt")
        let addition = root.appendingPathComponent("Added.txt")
        let archive = root.appendingPathComponent("Target.\(format.fileExtension)")
        try Data("original".utf8).write(to: original)
        try Data("added".utf8).write(to: addition)
        try await engine.createArchive(from: [original], outputURL: archive, format: format, progress: { _ in })
        let suiteName = "ZforgeArchiveConfirmation-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
        let state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: engine
        )
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let archiveItem = try #require(state.items.first(where: { $0.name == archive.lastPathComponent }))
        await state.openArchive(archiveItem)
        guard case let .archive(oldAddress) = state.location else {
            Issue.record("Archive did not open")
            return
        }
        let before = try Data(contentsOf: archive)
        state.requestArchiveAddition([addition], to: archive, internalPath: internalPath)
        state.pendingArchiveAddition = nil // Cancel/dismiss without confirming must not write.
        #expect(try Data(contentsOf: archive) == before)

        state.requestArchiveAddition([addition], to: archive, internalPath: internalPath)
        let confirmed = try #require(state.pendingArchiveAddition)
        // SwiftUI resets isPresented before the Button's async task runs.
        state.pendingArchiveAddition = nil
        await state.confirmArchiveAddition(confirmed)
        #expect(state.error == nil)
        #expect(state.contextualFeedbackMessage == "Items added to archive successfully.")
        #expect(!state.archiveOperationInProgress)
        #expect(state.pendingArchiveAddition == nil)
        #expect(state.items.contains(where: { $0.name == "Original.txt" }))
        guard case let .archive(newAddress) = state.location else {
            Issue.record("Updated archive did not reopen")
            return
        }
        #expect(newAddress.sessionID != oldAddress.sessionID)
        #expect(newAddress.internalPath.isEmpty)
        #expect(state.pathComponents.first?.location == .fileSystem(root))
        let addedItems: [BrowserItem]
        if internalPath.isEmpty {
            addedItems = state.items
        } else {
            let folder = try #require(state.items.first(where: { $0.name == internalPath }))
            guard case let .archive(folderAddress) = folder.location else {
                Issue.record("Internal folder has no archive address")
                return
            }
            addedItems = try await engine.items(at: folderAddress)
        }
        let added = try #require(addedItems.first(where: { $0.name == "Added.txt" }))
        let extracted = try await engine.materialize(item: added, purpose: .preview, automaticLimit: 1024)
        #expect(try String(contentsOf: extracted, encoding: .utf8) == "added")
        #expect(try String(contentsOf: addition, encoding: .utf8) == "added")
        #expect(state.selectedItems.map(\.name) == ["Added.txt"])
        if !internalPath.isEmpty {
            let folder = try #require(state.items.first(where: { $0.name == internalPath }))
            #expect(state.expandedItems.contains(folder.id))
            #expect(state.flattenedItems().contains(where: { $0.name == "Added.txt" }))
        }
    }

    @Test("Updating an inline archive restores disclosures and leaves other archives open",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    @MainActor
    func archiveAdditionPreservesInlineHierarchy(format: ArchiveCompressionFormat) async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeInlineUpdate-\(UUID().uuidString)", isDirectory: true)
        let sources = root.appendingPathComponent("Sources", isDirectory: true)
        let folder = sources.appendingPathComponent("Inside/Deep", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let sibling = sources.appendingPathComponent("Inside/Sibling", isDirectory: true)
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("original".utf8).write(to: folder.appendingPathComponent("Original.txt"))
        try Data("sibling".utf8).write(to: sibling.appendingPathComponent("Untouched.txt"))
        let addition = sources.appendingPathComponent("Added.txt")
        let secondAddition = sources.appendingPathComponent("Second.txt")
        try Data("added".utf8).write(to: addition)
        try Data("second".utf8).write(to: secondAddition)
        let archive = root.appendingPathComponent("Target.\(format.fileExtension)")
        let otherArchive = root.appendingPathComponent("Other.zip")
        for destination in [archive, otherArchive] {
            try await engine.createArchive(
                from: [sources.appendingPathComponent("Inside")], outputURL: destination,
                format: destination == archive ? format : .zip, progress: { _ in }
            )
        }
        let suiteName = "ZforgeInlineUpdate-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        let state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: engine
        )
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let target = try #require(state.items.first(where: { $0.name == archive.lastPathComponent }))
        let other = try #require(state.items.first(where: { $0.name == "Other.zip" }))
        await state.toggleExpansion(target)
        await state.toggleExpansion(other)
        let otherChildren = try #require(state.expandedChildren[other.id])
        let inside = try #require(state.expandedChildren[target.id]?.first(where: { $0.name == "Inside" }))
        await state.toggleExpansion(inside)
        let oldSibling = try #require(state.expandedChildren[inside.id]?.first(where: { $0.name == "Sibling" }))
        await state.toggleExpansion(oldSibling)
        let deep = try #require(state.expandedChildren[inside.id]?.first(where: { $0.name == "Deep" }))
        // Drop into a collapsed descendant: restoring the destination must open it.
        guard case let .archive(oldAddress) = deep.location else {
            Issue.record("Missing virtual folder address")
            return
        }
        await state.requestArchiveAddition([addition, secondAddition], to: oldAddress)
        let request = try #require(state.pendingArchiveAddition)
        state.pendingArchiveAddition = nil
        await state.confirmArchiveAddition(request)
        #expect(state.error == nil)
        #expect(state.location == .fileSystem(root))
        #expect(state.expandedItems.contains(target.id))
        #expect(state.expandedItems.contains(other.id))
        #expect(state.expandedChildren[other.id] == otherChildren)
        let newInside = try #require(state.expandedChildren[target.id]?.first(where: { $0.name == "Inside" }))
        let newDeep = try #require(state.expandedChildren[newInside.id]?.first(where: { $0.name == "Deep" }))
        #expect(state.expandedItems.contains(newInside.id))
        #expect(state.expandedItems.contains(newDeep.id))
        let newSibling = try #require(state.expandedChildren[newInside.id]?.first(where: { $0.name == "Sibling" }))
        #expect(state.expandedItems.contains(newSibling.id))
        #expect(state.expandedChildren[newSibling.id]?.contains(where: { $0.name == "Untouched.txt" }) == true)
        guard case let .archive(newAddress) = newDeep.location else {
            Issue.record("Missing refreshed folder address")
            return
        }
        #expect(newAddress.sessionID != oldAddress.sessionID)
        #expect(state.expandedChildren[inside.id] == nil)
        #expect(Set(state.selectedItems.map(\.name)) == ["Added.txt", "Second.txt"])
        #expect(Set(state.flattenedItems().filter { state.selection.contains($0.id) }.map(\.name)) == ["Added.txt", "Second.txt"])
        #expect(state.expandedChildren[newDeep.id]?.contains(where: { $0.name == "Original.txt" }) == true)
        let added = try #require(state.expandedChildren[newDeep.id]?.first(where: { $0.name == "Added.txt" }))
        let extracted = try await engine.materialize(item: added, purpose: .preview, automaticLimit: 1024)
        #expect(try String(contentsOf: extracted, encoding: .utf8) == "added")
        #expect(try String(contentsOf: addition, encoding: .utf8) == "added")
    }

    @Test("Archive engine adds files to existing ZIP and 7z, including an internal folder")
    func addsToExistingArchives() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeArchiveUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("Original.txt")
        let addition = root.appendingPathComponent("Added.txt")
        try Data("original".utf8).write(to: original)
        try Data("added".utf8).write(to: addition)

        for format in [ArchiveCompressionFormat.zip, .sevenZip] {
            let archive = root.appendingPathComponent("Target.\(format.fileExtension)")
            try await engine.createArchive(
                from: [original], outputURL: archive, format: format, progress: { _ in }
            )
            try await engine.addItems(
                from: [addition], to: archive, internalPath: "Inside",
                password: nil, progress: { _ in }
            )
            let opened = try await engine.openArchive(at: archive, password: nil)
            let rootItems = try await engine.items(at: opened.address)
            #expect(rootItems.contains(where: { $0.name == "Original.txt" }))
            let folder = try #require(rootItems.first(where: { $0.name == "Inside" }))
            guard case let .archive(folderAddress) = folder.location else {
                Issue.record("Added folder has no archive address")
                continue
            }
            #expect(try await engine.items(at: folderAddress).contains(where: { $0.name == "Added.txt" }))
            await engine.closeSession(opened.address.sessionID)
            await #expect(throws: ArchiveEngineError.archiveIncludedInSources) {
                try await engine.addItems(
                    from: [archive], to: archive, internalPath: "",
                    password: nil, progress: { _ in }
                )
            }
            if format == .zip {
                let volume = root.appendingPathComponent("Target.z01")
                try Data().write(to: volume)
                await #expect(throws: ArchiveEngineError.multiVolumeUpdateUnsupported) {
                    try await engine.addItems(
                        from: [addition], to: archive, internalPath: "",
                        password: nil, progress: { _ in }
                    )
                }
                try FileManager.default.removeItem(at: volume)
                let alias = root.appendingPathComponent("Link.zip")
                try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: archive)
                try await engine.addItems(
                    from: [addition], to: alias, internalPath: "ViaLink",
                    password: nil, progress: { _ in }
                )
                #expect(try alias.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
                let reopened = try await engine.openArchive(at: archive, password: nil)
                #expect(try await engine.items(at: reopened.address).contains(where: { $0.name == "ViaLink" }))
                await engine.closeSession(reopened.address.sessionID)
            }
        }
    }

    @Test("Updating encrypted archives needs the password and preserves the original on failure")
    func addsToEncryptedArchives() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeEncryptedUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("Original.txt")
        let addition = root.appendingPathComponent("Added.txt")
        try Data("secret".utf8).write(to: original)
        try Data("new".utf8).write(to: addition)

        for format in [ArchiveCompressionFormat.zip, .sevenZip] {
            let archive = root.appendingPathComponent("Encrypted.\(format.fileExtension)")
            var options = CompressionOptions(format: format)
            options.requiresPassword = true
            try await engine.createArchive(
                from: [original], outputURL: archive, options: options,
                password: "passphrase", progress: { _ in }
            )
            let before = try Data(contentsOf: archive)
            await #expect(throws: ArchiveEngineError.invalidPassword) {
                try await engine.addItems(
                    from: [addition], to: archive, internalPath: "",
                    password: "wrong", progress: { _ in }
                )
            }
            #expect(try Data(contentsOf: archive) == before)
            try await engine.addItems(
                from: [addition], to: archive, internalPath: "",
                password: "passphrase", progress: { _ in }
            )
            try await engine.testArchive(at: archive, password: "passphrase")
            let opened = try await engine.openArchive(at: archive, password: "passphrase")
            let entries = try await engine.items(at: opened.address)
            #expect(entries.contains(where: { $0.name == "Original.txt" }))
            #expect(entries.contains(where: { $0.name == "Added.txt" }))
            #expect(entries.first(where: { $0.name == "Added.txt" })?.encrypted == true)
            if format == .sevenZip {
                await #expect(throws: ArchiveEngineError.passwordRequired) {
                    _ = try await engine.openArchive(at: archive, password: nil)
                }
            } else {
                #expect(entries.first(where: { $0.name == "Added.txt" })?.compressionMethod?.contains("AES") == true)
            }
            await engine.closeSession(opened.address.sessionID)
        }
    }

    @Test("Archive engine creates every supported output format")
    func createsSupportedArchiveFormats() async throws {
        #expect(ArchiveCompressionFormat.allCases == [.sevenZip, .zip, .tar, .xz, .bzip2, .gzip, .wim])
        #expect(ArchiveCompressionFormat.bzip2.fileExtension == "bz2")
        #expect(ArchiveCompressionFormat.gzip.fileExtension == "gz")

        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeArchiveFormats-\(UUID().uuidString)", isDirectory: true)
        let folder = root.appendingPathComponent("Folder", isDirectory: true)
        let file = root.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("Hello from formats.\n".utf8).write(to: file)
        try Data("Nested format file.\n".utf8).write(to: folder.appendingPathComponent("nested.txt"))
        defer {
            Task { await engine.closeAllSessions() }
            try? FileManager.default.removeItem(at: root)
        }

        for format in ArchiveCompressionFormat.allCases {
            let extensionName = format.isStream ? "tar.\(format.fileExtension)" : format.fileExtension
            let output = root.appendingPathComponent("Output-\(format.rawValue).\(extensionName)")
            try await engine.createArchive(
                from: [file, folder],
                outputURL: output,
                format: format,
                progress: { _ in }
            )
            #expect(FileManager.default.fileExists(atPath: output.path))
            let opened = try await engine.openArchive(at: output, password: nil)
            #expect(try await !engine.items(at: opened.address).isEmpty)
            await engine.closeSession(opened.address.sessionID)
        }

        for format in [ArchiveCompressionFormat.xz, .bzip2, .gzip] {
            let output = root.appendingPathComponent("Single-\(format.rawValue).\(format.fileExtension)")
            try await engine.createArchive(
                from: [file],
                outputURL: output,
                format: format,
                progress: { _ in }
            )
            #expect(FileManager.default.fileExists(atPath: output.path))
            let opened = try await engine.openArchive(at: output, password: nil)
            let items = try await engine.items(at: opened.address)
            #expect(items.count == 1)
            let extracted = try await engine.materialize(
                item: try #require(items.first),
                purpose: .preview,
                automaticLimit: 10 * 1_024 * 1_024
            )
            #expect(try Data(contentsOf: extracted) == Data("Hello from formats.\n".utf8))
            await engine.closeSession(opened.address.sessionID)
        }
    }

    @Test("Archive engine creates encrypted 7z and ZIP with advanced options")
    func createsEncryptedArchives() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeEncryptedCreation-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("secret.txt")
        try Data("Private contents".utf8).write(to: source)

        for format in [ArchiveCompressionFormat.sevenZip, .zip] {
            var options = CompressionOptions(format: format)
            options.requiresPassword = true
            if format == .sevenZip {
                options.dictionaryMB = 16
                options.fastBytes = 64
                options.threads = 2
                options.encryptFileNames = true
            } else {
                options.method = .deflate
                options.fastBytes = 64
                options.zipEncryption = .aes256
            }
            let output = root.appendingPathComponent("Encrypted.\(format.fileExtension)")
            try await engine.createArchive(
                from: [source], outputURL: output, options: options,
                password: "sample-password", progress: { _ in }
            )
            #expect(FileManager.default.fileExists(atPath: output.path))
            try await engine.testArchive(at: output, password: "sample-password")
            do {
                try await engine.testArchive(at: output, password: "wrong-password")
                Issue.record("Archive accepted an incorrect password")
            } catch {}
        }
    }

    @Test("Archive engine extracts external archives and selected virtual items")
    func extractsArchivesAndSelectedItems() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeArchiveExtraction-\(UUID().uuidString)", isDirectory: true)
        let externalDestination = root.appendingPathComponent("External", isDirectory: true)
        let selectedDestination = root.appendingPathComponent("Selected", isDirectory: true)
        let resolver: ArchiveConflictResolver = { _ in .replace(applyToAll: true) }
        defer {
            Task { await engine.closeAllSessions() }
            try? FileManager.default.removeItem(at: root)
        }

        try await engine.extractArchive(
            at: fixturesURL.appendingPathComponent("sample-root.zip"),
            to: externalDestination,
            password: nil,
            resolveConflict: resolver,
            progress: { _ in }
        )
        #expect(FileManager.default.fileExists(atPath: externalDestination.appendingPathComponent("hello.txt").path))
        #expect(FileManager.default.fileExists(atPath: externalDestination.appendingPathComponent("Folder/nested.txt").path))

        let opened = try await engine.openArchive(
            at: fixturesURL.appendingPathComponent("sample-root.zip"),
            password: nil
        )
        let items = try await engine.items(at: opened.address)
        let hello = try #require(items.first(where: { $0.name == "hello.txt" }))
        try await engine.extractItems(
            [hello],
            to: selectedDestination,
            password: nil,
            resolveConflict: resolver,
            progress: { _ in }
        )
        #expect(FileManager.default.fileExists(atPath: selectedDestination.appendingPathComponent("hello.txt").path))
        await engine.closeSession(opened.address.sessionID)
    }

    @Test("List recursively expands fast nested archives when the outer archive is small")
    @MainActor
    func listInlineArchiveExpansion() async throws {
        let fileSystem = FileSystemService()
        let engine = NativeSevenZipArchiveEngine()
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(),
            fileSystem: fileSystem,
            grants: UIFixtureAccessGrantStore(),
            archives: engine
        )
        state.location = .fileSystem(fixturesURL)
        defer { Task { await engine.closeAllSessions() } }

        let zip = try await fileSystem.item(at: fixturesURL.appendingPathComponent("sample-root.zip"))
        state.items = [zip]
        await state.toggleExpansion(zip)

        #expect(state.expandedItems.contains(zip.id))
        let folder = try #require(state.expandedChildren[zip.id]?.first(where: { $0.name == "Folder" }))
        #expect(folder.canExpandInlineInList)

        await state.toggleExpansion(folder)
        #expect(state.flattenedList().contains(where: { $0.depth == 2 && $0.item.name == "nested.txt" }))
        let nestedItem = try #require(
            state.expandedChildren[folder.id]?.first(where: { $0.name == "nested.txt" })
        )
        state.selection = [nestedItem.id]
        #expect(state.archiveToolbarAction == .extractSelected)

        let nested = try await fileSystem.item(at: fixturesURL.appendingPathComponent("nested.7z"))
        state.items = [nested]
        await state.toggleExpansion(nested)
        let innerArchive = try #require(
            state.expandedChildren[nested.id]?.first(where: { $0.name == "inner.zip" })
        )

        #expect(innerArchive.isArchive)
        #expect(innerArchive.canExpandInlineInList)
        await state.toggleExpansion(innerArchive)
        #expect(state.expandedItems.contains(innerArchive.id))
        #expect(state.expandedChildren[innerArchive.id]?.contains(where: { $0.name == "hello.txt" }) == true)
    }

    @Test("Encrypted archive requires and accepts an in-memory password")
    func encryptedArchive() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeEncryptedExtraction-\(UUID().uuidString)", isDirectory: true)
        defer {
            Task { await engine.closeAllSessions() }
            try? FileManager.default.removeItem(at: destination)
        }
        do {
            _ = try await engine.openArchive(at: fixturesURL.appendingPathComponent("encrypted.7z"), password: nil)
            Issue.record("The encrypted fixture opened without a password")
        } catch let error as ArchiveEngineError {
            #expect(error == .passwordRequired)
        }

        let opened = try await engine.openArchive(
            at: fixturesURL.appendingPathComponent("encrypted.7z"),
            password: "zforge-test"
        )
        #expect(try await !engine.items(at: opened.address).isEmpty)
        let resolver: ArchiveConflictResolver = { _ in .replace(applyToAll: true) }
        do {
            try await engine.extractArchive(
                at: fixturesURL.appendingPathComponent("encrypted.7z"),
                to: destination,
                password: nil,
                resolveConflict: resolver,
                progress: { _ in }
            )
            Issue.record("The encrypted fixture was extracted without a password")
        } catch let error as ArchiveEngineError {
            #expect(error == .passwordRequired)
        }
        try await engine.extractArchive(
            at: fixturesURL.appendingPathComponent("encrypted.7z"),
            to: destination,
            password: "zforge-test",
            resolveConflict: resolver,
            progress: { _ in }
        )
        #expect(try !FileManager.default.contentsOfDirectory(at: destination, includingPropertiesForKeys: nil).isEmpty)
        await engine.closeSession(opened.address.sessionID)
    }

    @Test("Nested archives open recursively in the same session")
    func nestedArchive() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let policy = ArchiveBrowsingPolicy(maximumNestedArchiveDepth: 1, rootSizeLimit: 1_000_000_000)
        let outer = try await engine.openArchive(
            at: fixturesURL.appendingPathComponent("nested.7z"),
            password: nil,
            policy: policy
        )
        let outerItems = try await engine.items(at: outer.address)
        let inner = try #require(outerItems.first(where: { $0.name == "inner.zip" && $0.isArchive }))
        #expect(inner.canNavigateAsArchive)
        let nested = try await engine.openNestedArchive(item: inner, password: nil)
        #expect(nested.address.nestedArchiveDepth == 1)
        #expect(nested.address.maximumNestedArchiveDepth == 1)
        #expect(!nested.address.canOpenNestedArchive)
        let hierarchy = try await engine.archiveHierarchy(for: nested.address)
        #expect(
            hierarchy == ["nested.7z", "inner.zip"],
            "Unexpected archive hierarchy: \(hierarchy)"
        )
        let nestedItems = try await engine.items(at: nested.address)
        #expect(nestedItems.contains(where: { $0.name == "hello.txt" }))
        await engine.closeSession(outer.address.sessionID)
    }

    @Test("Archive engine rejects a nested archive when its root session disallows recursion")
    func blockedNestedArchive() async {
        let engine = NativeSevenZipArchiveEngine()
        let address = ArchiveAddress(
            sessionID: UUID(), archiveID: UUID(), internalPath: "inner.zip",
            allowsNestedArchives: false
        )
        let inner = BrowserItem(
            id: BrowserItemID(rawValue: "blocked-inner"), name: "inner.zip", location: .archive(address),
            isContainer: false, isDirectory: false, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: true, size: 100,
            packedSize: 50, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: "Deflate"
        )

        do {
            _ = try await engine.openNestedArchive(item: inner, password: nil)
            Issue.record("A nested archive was opened despite the root size policy")
        } catch let error as ArchiveEngineError {
            #expect(error == .nestedArchiveNotAllowed)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }


    private var fixturesURL: URL { projectRoot.appendingPathComponent("ZforgeTests/Fixtures") }

    @MainActor
    private func assertColumnExternalArchiveExtraction(
        nestedInDirectory: Bool
    ) async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeColumnExternalExtraction-\(UUID().uuidString)", isDirectory: true)
        let archiveDirectory = nestedInDirectory
            ? root.appendingPathComponent("Nested", isDirectory: true)
            : root
        let archiveName = nestedInDirectory ? "Right.zip" : "Base.zip"
        let archiveURL = archiveDirectory.appendingPathComponent(archiveName)
        let destination = archiveDirectory.appendingPathComponent(
            archiveURL.deletingPathExtension().lastPathComponent,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: archiveDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(
            at: fixturesURL.appendingPathComponent("sample-root.zip"),
            to: archiveURL
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let suiteName = "ZforgeColumnExternalExtraction-\(UUID().uuidString)"
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
            archives: NativeSevenZipArchiveEngine()
        )
        defer { state.close() }

        await state.navigateToSidebar(root, name: root.lastPathComponent)
        if nestedInDirectory {
            let directoryItem = try #require(state.items.first(where: { $0.name == "Nested" }))
            await state.activateColumnItem(directoryItem, in: state.location).value
        }

        let archiveParentLocation = state.location
        let archiveItem = try #require(state.items.first(where: {
            $0.localURL?.standardizedFileURL.path == archiveURL.standardizedFileURL.path
        }))
        await state.activateColumnItem(archiveItem, in: archiveParentLocation).value

        #expect(state.location != archiveParentLocation)
        #expect(archiveItem.localURL != nil)
        #expect(state.archiveToolbarAction == .extractAll)
        #expect(await state.performArchiveToolbarAction() != nil)
        #expect(FileManager.default.fileExists(
            atPath: destination.appendingPathComponent("hello.txt").path
        ))
        #expect(
            state.columnItems[archiveParentLocation]?.contains(where: {
                $0.localURL?.standardizedFileURL.path == destination.standardizedFileURL.path
            }) == true
        )
    }

    private func item(
        _ name: String,
        directory: Bool = false,
        archive: Bool = false,
        size: Int64? = 0
    ) -> BrowserItem {
        let url = URL(fileURLWithPath: "/tmp/\(name)")
        return BrowserItem(
            id: BrowserItemID(rawValue: name), name: name, location: .fileSystem(url),
            isContainer: directory, isDirectory: directory, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: archive, size: size,
            packedSize: nil, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil,
            compressionMethod: nil
        )
    }
}

@MainActor
private final class RecentItemsStub: RecentItemsServing {
    let urls: [URL]

    init(urls: [URL]) {
        self.urls = urls
    }

    func recentItemURLs() async -> [URL] { urls }
    func stop() {}
}

private actor ColumnArchiveRaceEngine: ArchiveServing {
    private var events: [String] = []
    private var namesByArchiveID: [UUID: String] = [:]
    private struct Waiter {
        let event: String
        let continuation: CheckedContinuation<Void, any Error>
        let timeout: Task<Void, Never>
    }
    enum WaitError: Error, Equatable {
        case timedOut(String)
        case shutDown
    }
    private var waiters: [UUID: Waiter] = [:]
    private var isShutDown = false

    func openArchive(
        at url: URL,
        password: String?,
        policy: ArchiveBrowsingPolicy
    ) async throws -> ArchiveOpenResult {
        let name = url.lastPathComponent
        record("started:\(name)")
        do {
            // Keep the first load pending until the next selection cancels it.
            // A timeout detects broken cancellation instead of completing it by chance.
            if name == "First.zip" {
                try await wait(for: "release:\(name)")
            }
            try Task.checkCancellation()
        } catch {
            record(error is CancellationError ? "cancelled:\(name)" : "failed:\(name)")
            throw error
        }

        let archiveID = UUID()
        namesByArchiveID[archiveID] = name
        events.append("completed:\(name)")
        return ArchiveOpenResult(
            address: ArchiveAddress(
                sessionID: UUID(),
                archiveID: archiveID,
                internalPath: "",
                maximumNestedArchiveDepth: policy.maximumNestedArchiveDepth
            ),
            displayName: name
        )
    }

    func items(at address: ArchiveAddress) async throws -> [BrowserItem] {
        let archiveName = namesByArchiveID[address.archiveID] ?? "Unknown.zip"
        let childName = "\(archiveName) content"
        return [
            BrowserItem(
                id: BrowserItemID(rawValue: "race:\(address.archiveID):\(childName)"),
                name: childName,
                location: .archive(address.appending(childName)),
                isContainer: false,
                isDirectory: false,
                isPackage: false,
                isSymbolicLink: false,
                isHidden: false,
                isArchive: false,
                size: 1,
                packedSize: 1,
                creationDate: nil,
                modificationDate: nil,
                accessDate: nil,
                tags: [],
                contentTypeIdentifier: "public.data",
                encrypted: false,
                checksum: nil,
                compressionMethod: nil
            )
        ]
    }

    func waitUntilStarted(_ name: String, timeout: Duration = .seconds(10)) async throws {
        try await wait(for: "started:\(name)", timeout: timeout)
    }

    private func wait(for event: String, timeout: Duration = .seconds(10)) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            guard !isShutDown else { throw WaitError.shutDown }
            // Remember signals delivered before a waiter registers.
            if events.contains(event) { return }
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let watchdog = Task {
                    do { try await Task.sleep(for: timeout) }
                    catch { return }
                    finish(id, result: .failure(WaitError.timedOut(event)))
                }
                waiters[id] = Waiter(event: event, continuation: continuation, timeout: watchdog)
            }
        } onCancel: {
            Task { await self.finish(id, result: .failure(CancellationError())) }
        }
    }

    private func record(_ event: String) {
        events.append(event)
        let matching = waiters.filter { $0.value.event == event }.map(\.key)
        for id in matching { finish(id, result: .success(())) }
    }

    private func finish(_ id: UUID, result: Result<Void, any Error>) {
        guard let waiter = waiters.removeValue(forKey: id) else { return }
        waiter.timeout.cancel()
        waiter.continuation.resume(with: result)
    }

    func shutdown() {
        isShutDown = true
        for id in Array(waiters.keys) { finish(id, result: .failure(WaitError.shutDown)) }
    }

    func pendingWaiterCount() -> Int { waiters.count }

    func eventsSnapshot() -> [String] { events }

    func openNestedArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        throw ArchiveEngineError.itemNotFound
    }

    func materialize(
        item: BrowserItem,
        purpose: ArchiveMaterializationPurpose,
        automaticLimit: Int64?
    ) async throws -> URL {
        throw ArchiveEngineError.itemNotFound
    }

    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws {}

    func extractArchive(
        at url: URL,
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {}

    func extractItems(
        _ items: [BrowserItem],
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {}

    func recursiveSize(of item: BrowserItem) async throws -> Int64 { item.size ?? 0 }

    func archiveRootURL(for address: ArchiveAddress) async throws -> URL {
        URL(fileURLWithPath: "/tmp/\(namesByArchiveID[address.archiveID] ?? "Unknown.zip")")
    }

    func setPassword(_ password: String?, for sessionID: UUID) async {}
    func closeSession(_ sessionID: UUID) async {}
    func closeAllSessions() async {}
    func cancelAllOperations() async {}
    func cleanupStaleSessions() async {}
}
