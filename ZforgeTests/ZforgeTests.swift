import Foundation
import Testing
@testable import Zforge

@Suite("File browser domain")
struct ZforgeTests {
    @Test("Sidebar maximum width always reserves 360 points for content")
    func sidebarMaximumWidth() {
        #expect(BrowserSidebarLayout.maximumWidth(for: 640) == 280)
        #expect(BrowserSidebarLayout.maximumWidth(for: 900) == 540)
        #expect(BrowserSidebarLayout.maximumWidth(for: 1_100) == 740)
    }

    @Test("The sidebar places the real user directory in Locations")
    @MainActor
    func sidebarUsesRealUserHome() {
        let sidebar = SidebarState()

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
        let limit: Int64 = 3 * 1_073_741_824
        let policy = ArchiveBrowsingPolicy(maximumNestedArchiveDepth: 7, rootSizeLimit: limit)
        #expect(policy.maximumNestedArchiveDepth == 7)
        #expect(policy.rootSizeLimit == limit)
        #expect(policy.allowsNestedArchives(forOutermostSize: limit - 1))
        #expect(!policy.allowsNestedArchives(forOutermostSize: limit))
        #expect(!policy.allowsNestedArchives(forOutermostSize: limit + 1))
        #expect(!policy.allowsNestedArchives(forOutermostSize: nil))

        let clamped = ArchiveBrowsingPolicy(
            maximumNestedArchiveDepth: 50,
            rootSizeLimit: 12 * 1_073_741_824
        )
        #expect(clamped.maximumNestedArchiveDepth == 10)
        #expect(clamped.rootSizeLimit == 5 * 1_073_741_824)

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

        preferences.archiveNestingLimit = 30
        preferences.archiveRootSizeLimitGB = 12
        #expect(preferences.archiveNestingLimit == 10)
        #expect(preferences.archiveRootSizeLimitGB == 5)

        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(reloaded.archiveNestingLimit == 10)
        #expect(reloaded.archiveRootSizeLimitGB == 5)
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
        #expect(state.archiveToolbarAction == .extractSelected)
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

        preferences.viewMode = .gallery
        state.updatePreview()
        try await Task.sleep(for: .milliseconds(120))
        #expect(state.previewVisible)
        #expect(state.previewURL == document.localURL)

        state.togglePreviewVisibility()
        #expect(!state.previewVisible)

        preferences.viewMode = .columns
        #expect(state.previewVisible)

        state.togglePreviewVisibility()
        #expect(!state.previewVisible)

        preferences.viewMode = .icons
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
        let state = FileBrowserState()
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
    func multipleSelectionPreviewsEligibleFiles() {
        let state = FileBrowserState()
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
        let engine = SevenZipArchiveEngine(helperURL: helperURL)
        let opened = try await engine.openArchive(at: fixturesURL.appendingPathComponent("sample-root.zip"), password: nil)
        let rootItems = try await engine.items(at: opened.address)
        #expect(rootItems.contains(where: { $0.name == "hello.txt" }))
        #expect(rootItems.contains(where: { $0.name == "Folder" && $0.isDirectory }))

        let hello = try #require(rootItems.first(where: { $0.name == "hello.txt" }))
        let materialized = try await engine.materialize(item: hello, purpose: .preview, automaticLimit: 10 * 1_024 * 1_024)
        #expect(try String(contentsOf: materialized, encoding: .utf8) == "Hello from Zforge.\n")
        await engine.closeSession(opened.address.sessionID)
    }

    @Test("List recursively expands fast nested archives when the outer archive is small")
    @MainActor
    func listInlineArchiveExpansion() async throws {
        let fileSystem = FileSystemService()
        let engine = SevenZipArchiveEngine(helperURL: helperURL)
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(),
            fileSystem: fileSystem,
            grants: UIFixtureAccessGrantStore(),
            archives: engine
        )
        defer { Task { await engine.closeAllSessions() } }

        let zip = try await fileSystem.item(at: fixturesURL.appendingPathComponent("sample-root.zip"))
        state.items = [zip]
        await state.toggleExpansion(zip)

        #expect(state.expandedItems.contains(zip.id))
        let folder = try #require(state.expandedChildren[zip.id]?.first(where: { $0.name == "Folder" }))
        #expect(folder.canExpandInlineInList)

        await state.toggleExpansion(folder)
        #expect(state.flattenedList().contains(where: { $0.depth == 2 && $0.item.name == "nested.txt" }))

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
        let engine = SevenZipArchiveEngine(helperURL: helperURL)
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
        await engine.closeSession(opened.address.sessionID)
    }

    @Test("Nested archives open recursively in the same session")
    func nestedArchive() async throws {
        let engine = SevenZipArchiveEngine(helperURL: helperURL)
        let policy = ArchiveBrowsingPolicy(maximumNestedArchiveDepth: 1, rootSizeLimit: 1_073_741_824)
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
        let nestedItems = try await engine.items(at: nested.address)
        #expect(nestedItems.contains(where: { $0.name == "hello.txt" }))
        await engine.closeSession(outer.address.sessionID)
    }

    @Test("Archive engine rejects a nested archive when its root session disallows recursion")
    func blockedNestedArchive() async {
        let engine = SevenZipArchiveEngine(helperURL: helperURL)
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

    private var helperURL: URL {
        Bundle.main.url(forAuxiliaryExecutable: "7zz")
            ?? projectRoot.appendingPathComponent("Vendor/7zz")
    }
    private var fixturesURL: URL { projectRoot.appendingPathComponent("ZforgeTests/Fixtures") }

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
