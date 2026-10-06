import AppKit
import Darwin
import CoreServices
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

    @Test("Overlapping authorized roots publish each discovered file once")
    func overlappingRootsDoNotRepeatDiscovery() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Shared\n6"], to: file)
        let result = ScanBatchProbe()
        await TaggedFileScanner.scan([root, root.appendingPathComponent("A"), root]) {
            await result.append($0)
        }
        #expect(await result.occurrences(file.path) == 1)
    }

    @Test("Canceling a scan stops its detached worker before the next publication")
    func cancellationReachesScanner() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("TagCancellation-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for index in 0..<1_001 {
            let file = root.appendingPathComponent("file-\(index).txt")
            try Data().write(to: file)
            try writeTags(["Shared\n6"], to: file)
        }
        let probe = ScanBatchProbe()
        let gate = ScanGate()
        let worker = Task {
            await TaggedFileScanner.scan([root]) { batch in
                await probe.append(batch)
                await gate.arriveAndWait()
            }
        }
        await gate.waitForArrival()
        worker.cancel()
        await gate.open()
        await worker.value
        #expect(await probe.batchCount == 1)
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
        try await waitUntil({ catalog.itemURLs(tagged: name).count == 1 }, stage: "Initial discovery",
            diagnostics: { "paths=\(catalog.itemURLs(tagged: name)), idle=\(catalog.isIdle), revision=\(catalog.revision)" })
        try writeTags([name + "\n6"], to: second)
        try await waitUntil({ catalog.itemURLs(tagged: name).count == 2 }, stage: "Live addition",
            diagnostics: { "paths=\(catalog.itemURLs(tagged: name)), idle=\(catalog.isIdle), revision=\(catalog.revision)" })
        try writeTags([name + " changed\n4"], to: first)
        try await waitUntil({
            catalog.itemURLs(tagged: name).count == 1
                && catalog.tags.contains { $0.name == name + " changed" }
        }, stage: "Live tag replacement",
            diagnostics: { "paths=\(catalog.itemURLs(tagged: name)), idle=\(catalog.isIdle), revision=\(catalog.revision)" })
        try FileManager.default.removeItem(at: second)
        try await waitUntil({ catalog.itemURLs(tagged: name).isEmpty }, stage: "Live deletion",
            diagnostics: { "paths=\(catalog.itemURLs(tagged: name)), idle=\(catalog.isIdle), revision=\(catalog.revision)" })
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

    @Test("Completed discovery is reused by repeated refreshes and descendant scopes")
    @MainActor
    func refreshReusesDiscovery() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, publish in
            await probe.scanned(roots)
            await publish([roots[0].appendingPathComponent("A/first.txt").path: ["Shared": 6]])
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        for _ in 0..<10 { catalog.refresh(searchScopes: [root, root.appendingPathComponent("A")]) }
        catalog.refresh()
        await catalog.waitForIdle()
        #expect(await probe.scans.count == 1)
        #expect(catalog.itemURLs(tagged: "Shared").count == 1)
        #expect(catalog.isIdle)
    }

    @Test("Directory tag edits read only the directory and do not rescan its descendants")
    @MainActor
    func directoryTagEditIsIncremental() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("A")
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
            await probe.read(urls)
            return [directory.path: ["New Folder Tag": 4]]
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        catalog.filesChanged([TagFileChange(path: directory.path, flags:
            FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod | kFSEventStreamEventFlagItemIsDir))])
        await catalog.waitForIdle()
        #expect(await probe.scans.count == 1)
        #expect(await probe.reads == [[directory]])
        #expect(catalog.itemURLs(tagged: "New Folder Tag") == [directory])
        #expect(catalog.isIdle)
    }

    @Test("Overlapping directory events are coalesced and content-only writes schedule no work")
    @MainActor
    func eventsCoalesceSubtrees() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
            await probe.read(urls); return [:]
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        let flags = FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemIsDir)
        catalog.filesChanged([
            TagFileChange(path: root.appendingPathComponent("A").path, flags: flags),
            TagFileChange(path: root.appendingPathComponent("A/child").path, flags: flags),
            TagFileChange(path: root.appendingPathComponent("A").path, flags: flags)
        ])
        await catalog.waitForIdle()
        #expect(await probe.scans.map { $0.map(\.path) } == [[root.path], [root.appendingPathComponent("A").path]])
        let revision = catalog.revision
        catalog.filesChanged([TagFileChange(path: root.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))])
        await catalog.waitForIdle()
        #expect(await probe.scans.count == 2)
        #expect(catalog.revision == revision)
        #expect(catalog.isIdle)
    }

    @Test("An event burst recovers every affected authorization with bounded read batches")
    @MainActor
    func eventOverflowReconcilesAllScopes() async throws {
        let first = try fixtureRoot()
        let second = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: first); try? FileManager.default.removeItem(at: second) }
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
            await probe.read(urls); return [:]
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [first, second])
        await catalog.waitForIdle()
        catalog.filesChanged((0..<513).map { index in
            TagFileChange(path: (index.isMultiple(of: 2) ? first : second).appendingPathComponent("file-\(index)").path,
                flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
        })
        await catalog.waitForIdle()
        let scans = await probe.scans
        #expect(scans.count == 2)
        #expect(Set(scans[1].map(\.path)) == [first.path, second.path])
        #expect(await probe.reads.allSatisfy { $0.count <= 128 })
        #expect(catalog.isIdle)
    }

    @Test("Stopped discovery cannot publish stale results or overlap a restarted worker")
    @MainActor
    func stopAndRestartRetiresOldWork() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let gate = ScanGate()
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, publish in
            await probe.begin(roots)
            if await probe.scans.count == 1 { await gate.arriveAndWait() }
            // Intentionally attempt publication after cancellation to exercise
            // the catalog generation guard independently of worker cooperation.
            await publish([root.appendingPathComponent("A/first.txt").path:
                [Task.isCancelled ? "Stale" : "Current": 6]])
            await probe.end()
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await gate.waitForArrival()
        catalog.stop()
        catalog.refresh(searchScopes: [root])
        await gate.open()
        await catalog.waitForIdle()
        #expect(await probe.maximumActive == 1)
        #expect(await probe.scans.count == 2)
        #expect(catalog.itemURLs(tagged: "Stale").isEmpty)
        #expect(catalog.itemURLs(tagged: "Current").count == 1)
        #expect(catalog.isIdle)
    }

    @Test("Live reads are serviced during an untagged scan rather than waiting for full discovery")
    @MainActor
    func incrementalReadsInterleaveDiscovery() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        let entered = ScanGate()
        let eventReady = ScanGate()
        let readReady = ScanGate()
        let catalog = FinderTagCatalog(scanner: { _, publish in
            await entered.arriveAndWait()
            // An empty production checkpoint must still drain live reads.
            await publish([:])
            await readReady.arriveAndWait()
        }, reader: { urls in
            await eventReady.arriveAndWait()
            return [file.path: ["Live": 6]]
        }, monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await entered.waitForArrival()
        catalog.filesChanged([TagFileChange(path: file.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))])
        // Await the debounce task directly, without waiting for the blocked scan.
        await catalog.waitForEvents()
        await entered.open()
        await eventReady.waitForArrival()
        await eventReady.open()
        await readReady.waitForArrival()
        #expect(catalog.itemURLs(tagged: "Live") == [file])
        await readReady.open()
        await catalog.waitForIdle()
        #expect(catalog.isIdle)
    }

    @Test("Tag references survive partial removal and disappear after the last tagged file")
    @MainActor
    func incrementalTagReferencesRemainAccurate() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        try writeTags(["Reference Fixture\n6"], to: first)
        try writeTags(["Reference Fixture\n6"], to: second)
        let catalog = FinderTagCatalog(monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        try writeTags([], to: first)
        catalog.observe([try await FileSystemService().item(at: first)])
        #expect(catalog.tags.contains { $0.name == "Reference Fixture" })
        try FileManager.default.removeItem(at: root.appendingPathComponent("B"))
        catalog.filesChanged([TagFileChange(path: root.appendingPathComponent("B").path,
            flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemIsDir))])
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Reference Fixture").isEmpty)
        #expect(!catalog.tags.contains { $0.name == "Reference Fixture" })
    }

    @Test("Tagged output stays bounded while untagged trees still yield between work slices")
    func scannerBoundsBatchesAndYields() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("TagBudget-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for index in 0..<257 {
            let file = root.appendingPathComponent("file-\(index).txt")
            try Data().write(to: file)
            try writeTags(["Bounded Fixture\n6"], to: file)
        }
        let probe = BudgetProbe()
        let budget = TaggedFileScanner.Budget(pause: { await probe.paused($0) })
        await TaggedFileScanner.scan([root], budget: budget) { await probe.published($0) }
        #expect(await probe.maximumBatch <= 128)
        #expect(await probe.recordCount == 257)
        #expect(await probe.pauses.count >= 3)
        #expect(await probe.pauses.allSatisfy { $0 > .zero })
        for index in 0..<257 { try writeTags([], to: root.appendingPathComponent("file-\(index).txt")) }
        let untagged = BudgetProbe()
        await TaggedFileScanner.scan([root], budget: TaggedFileScanner.Budget(pause: { await untagged.paused($0) })) {
            await untagged.published($0)
        }
        #expect(await untagged.recordCount == 0)
        #expect(await untagged.pauses.count >= 3)
        #expect(await untagged.publications >= 3)
    }

    @Test("Incremental metadata reads preserve symlink item identity and clear its indexed tags")
    @MainActor
    func incrementalReadsPreserveSymlinkIdentity() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appendingPathComponent("A/first.txt")
        let alias = root.appendingPathComponent("linked.txt")
        try writeTags(["Linked Fixture\n6"], to: target)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: target)
        let initial = await TaggedFileScanner.read([alias])
        #expect(initial[alias.path] == ["Linked Fixture": 6])
        #expect(initial[target.path] == nil)
        let catalog = FinderTagCatalog(monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        #expect(Set(catalog.itemURLs(tagged: "Linked Fixture").map(\.path)) == [target.path, alias.path])
        try writeTags([], to: target)
        let updated = await TaggedFileScanner.read([alias])
        #expect(updated[alias.path] == [:])
        catalog.filesChanged([TagFileChange(path: alias.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))])
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Linked Fixture").map(\.path) == [target.path])
        catalog.filesChanged([TagFileChange(path: target.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))])
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Linked Fixture").isEmpty)
        #expect(catalog.isIdle)
    }

    @Test("Scan exclusion preserves package boundaries, temporary aliases and sibling path boundaries")
    func scannerPreservesExclusionBoundaries() async throws {
        let root = try fixtureRoot()
        let temporary = ZforgeTemporaryStorage.root().appendingPathComponent("TagExclusion-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: temporary) }
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        let secret = temporary.appendingPathComponent("temporary.txt")
        try Data().write(to: secret)
        try writeTags(["Excluded Fixture\n6"], to: secret)
        let alias = root.appendingPathComponent("alias.txt")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: secret)
        let package = root.appendingPathComponent("Fixture.app")
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        let internalFile = package.appendingPathComponent("internal.txt")
        try Data().write(to: internalFile)
        try writeTags(["Excluded Fixture\n6"], to: internalFile)
        let external = root.appendingPathComponent("A/first.txt")
        try writeTags(["Included Fixture\n4"], to: external)
        let result = ScanResults()
        await TaggedFileScanner.scan([root, temporary]) { await result.append($0) }
        let records = await result.records
        #expect(records[external.path] == ["Included Fixture": 4])
        #expect(records.values.allSatisfy { $0["Excluded Fixture"] == nil })
        #expect(await TaggedFileScanner.read([alias, secret]).isEmpty)
        var roots = TagScanRoots()
        roots.insert(URL(fileURLWithPath: "/fixture/Parent"))
        roots.insert(URL(fileURLWithPath: "/fixture/Parent Other"))
        roots.insert(URL(fileURLWithPath: "/fixture/Parent/Child"))
        #expect(roots.urls.count == 2)
    }

    @Test("A burst inside one folder reconciles that folder instead of repeating the whole authorization")
    @MainActor
    func eventBurstKeepsSmallestAffectedSubtree() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(scanner: { roots, _ in await probe.scanned(roots) },
            monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        catalog.filesChanged((0..<513).map {
            TagFileChange(path: root.appendingPathComponent("A/file-\($0).txt").path,
                flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
        })
        await catalog.waitForIdle()
        #expect(await probe.scans.map { $0.map(\.path) } == [[root.path], [root.appendingPathComponent("A").path]])
        #expect(catalog.isIdle)
    }

    @Test("Lost file events reconcile removed and cleared tags without dropping surviving results")
    @MainActor
    func lostEventsReconcileIndexedMetadata() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        let folder = root.appendingPathComponent("B")
        for url in [first, second, folder] { try writeTags(["Reconcile Fixture\n6"], to: url) }
        let catalog = FinderTagCatalog(monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        try writeTags([], to: first)
        try FileManager.default.removeItem(at: second)
        catalog.filesChanged([TagFileChange(path: root.path, flags:
            FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs))])
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Reconcile Fixture") == [folder])
        #expect(catalog.isIdle)
    }

    @Test("Spotlight updates read only added, changed and removed paths, with deduplication")
    func spotlightUsesIncrementalResults() throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        let a = try #require(MDItemCreate(kCFAllocatorDefault, first.path as CFString))
        let b = try #require(MDItemCreate(kCFAllocatorDefault, second.path as CFString))
        let changes: [AnyHashable: Any] = [
            kMDQueryUpdateAddedItems as String: [a],
            kMDQueryUpdateChangedItems as String: [a],
            kMDQueryUpdateRemovedItems as String: [b]
        ]
        #expect(Set(FinderTagQueryUpdates.urls(in: changes).map(\.path)) == [first.path, second.path])
        #expect(FinderTagQueryUpdates.urls(in: [:]).isEmpty)
        #expect(FinderTagQueryUpdates.urls(in: nil).isEmpty)
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
    private func waitUntil(_ condition: () -> Bool, stage: String, diagnostics: () -> String) async throws {
        let start = Date()
        let deadline = start.addingTimeInterval(8)
        var polls = 0
        var longestSuspension: TimeInterval = 0
        while !condition(), Date() < deadline {
            let before = Date()
            try await Task.sleep(for: .milliseconds(100))
            longestSuspension = max(longestSuspension, Date().timeIntervalSince(before))
            polls += 1
        }
        #expect(condition(), Comment(rawValue: "\(stage): elapsed=\(Date().timeIntervalSince(start)), polls=\(polls), longest suspension=\(longestSuspension), \(diagnostics())"))
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

private actor ScanBatchProbe {
    private var counts: [String: Int] = [:]
    private(set) var batchCount = 0
    func append(_ batch: [String: [String: Int]]) {
        batchCount += 1
        for key in batch.keys { counts[key, default: 0] += 1 }
    }
    func occurrences(_ path: String) -> Int { counts[path, default: 0] }
}

private actor ScanGate {
    private var arrived = false
    private var opened = false
    private var arrivals: [CheckedContinuation<Void, Never>] = []
    private var blocked: [CheckedContinuation<Void, Never>] = []
    func waitForArrival() async {
        if arrived { return }
        await withCheckedContinuation { arrivals.append($0) }
    }
    func arriveAndWait() async {
        arrived = true
        for waiter in arrivals { waiter.resume() }
        arrivals.removeAll()
        if opened { return }
        await withCheckedContinuation { blocked.append($0) }
    }
    func open() {
        opened = true
        for waiter in blocked { waiter.resume() }
        blocked.removeAll()
    }
}

private actor CatalogWorkProbe {
    private(set) var scans: [[URL]] = []
    private(set) var reads: [[URL]] = []
    private var active = 0
    private(set) var maximumActive = 0
    func scanned(_ roots: [URL]) { scans.append(roots) }
    func read(_ urls: [URL]) { reads.append(urls) }
    func begin(_ roots: [URL]) {
        scanned(roots)
        active += 1
        maximumActive = max(maximumActive, active)
    }
    func end() { active -= 1 }
}

private actor BudgetProbe {
    private(set) var pauses: [Duration] = []
    private(set) var recordCount = 0
    private(set) var maximumBatch = 0
    private(set) var publications = 0
    func paused(_ duration: Duration) { pauses.append(duration) }
    func published(_ batch: TaggedFileScanner.Batch) {
        publications += 1
        recordCount += batch.count
        maximumBatch = max(maximumBatch, batch.count)
    }
}
