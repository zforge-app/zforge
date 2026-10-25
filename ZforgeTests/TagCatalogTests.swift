import AppKit
import Darwin
import CoreServices
import Foundation
import Testing
@testable import Zforge

@Suite("Global Finder tags")
struct TagCatalogTests {
    @Test("Indexes produced before Unicode and physical-journal corrections require one rebuild")
    func obsoleteDiscoveryContractRequiresRebuild() {
        let scope = TagJournal.Scope(path: "/fixture/Legacy", inode: 42, journal: "Fixture Journal")
        var obsolete = TagIndexSnapshot(scopes: [scope], cursors: [scope.path: 42], records: [:])
        obsolete.version = 3
        #expect(!obsolete.matches([scope]))
        let current = TagIndexSnapshot(scopes: [scope], cursors: [scope.path: 42], records: [:])
        #expect(current.matches([scope]))
    }

    @Test("Device-relative monitoring resolves an authorized directory alias and preserves logical event paths")
    @MainActor
    func journalMonitorsPhysicalAliasTarget() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let physical = root.appendingPathComponent("A")
        let alias = root.appendingPathComponent("Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: physical)
        let description = try #require(TagJournal.describe([alias]))
        #expect(description.scopes.map(\.path) == [alias.path])
        let mapping = try #require(description.volumes.first?.paths.first)
        #expect(mapping.logical == alias.path)
        #expect(mapping.relative.hasSuffix("/A"))
        #expect(!mapping.relative.hasSuffix("/Alias"))
        var changes: [TagFileChange] = []
        let journal = TagJournal(onChanges: { changes += $0 }, onHistory: {})
        journal.start(description, since: [:])
        defer { journal.stop() }
        #expect(journal.available)
        await journal.waitForHistory()
        let file = physical.appendingPathComponent("first.txt")
        let logicalFile = alias.appendingPathComponent("first.txt")
        try writeTags(["Alias Journal\n6"], to: file)
        try await waitUntil({ changes.contains { $0.path == logicalFile.path } },
            stage: "Physical alias metadata event", diagnostics: { "Received paths: \(changes.map(\.path))" })
        #expect(changes.filter { $0.path.hasSuffix("/first.txt") }.allSatisfy { $0.path == logicalFile.path })
    }

    @Test("Scope boundaries accept leading combining marks and preserve canonical Unicode equivalence", arguments: [
        ("/fixture/A", "/fixture/A/\u{301}file.txt", true),
        ("/fixture/A/", "/fixture/A/\u{301}file.txt", true),
        ("/", "/\u{301}file.txt", true),
        ("/fixture/A", "/fixture/A", true),
        ("/fixture/A/", "/fixture/A", false),
        ("/fixture/A", "/fixture/AB/file.txt", false),
        ("/fixture/Roote\u{301}", "/fixture/Root\u{e9}/file.txt", true),
        ("/fixture/Root\u{e9}", "/fixture/Roote\u{301}/\u{301}file.txt", true)
    ])
    func scopeBoundariesPreserveUnicode(root: String, path: String, expected: Bool) {
        #expect(TagScanRoots.covers(root, path) == expected)
    }

    @Test("Path normalization detects empty, current and parent components after the first", arguments: [
        ("/fixture/A/file.txt", false), ("/fixture/A/../file.txt", true), ("/fixture/./A", true),
        ("/fixture//A", true), ("/fixture/A/", true), ("/fixture/A/.", true), ("/fixture/A/..", true),
        ("/fixture/.hidden/file", false), ("/fixture/...", false), ("/fixture/..x/file", false),
        ("/", true), ("", false), ("relative/./x", true), ("./relative", false), ("/fixture/\u{301}file", false)
    ])
    func emptyOrRelativeComponentDetection(path: String, expected: Bool) {
        #expect(TagVisibilityBatch.hasEmptyOrRelativeComponent(path) == expected)
    }

    @Test("Initial discovery and cached reopening retain a filename beginning with a combining mark")
    @MainActor
    func discoveryRetainsLeadingCombiningFilename() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let scope = root.appendingPathComponent("A")
        let file = scope.appendingPathComponent("\u{301}file.txt")
        try Data("Unicode boundary fixture".utf8).write(to: file)
        try writeTags(["Unicode Boundary\n6"], to: file)
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        for _ in 0..<2 {
            let catalog = FinderTagCatalog(discoveryRoots: [scope], usesSpotlight: false, indexStore: store)
            catalog.refresh(searchScopes: [scope])
            await catalog.waitForIdle()
            #expect(catalog.itemURLs(tagged: "Unicode Boundary") == [file])
            #expect(await store.load()?.records[file.path] == ["Unicode Boundary": 6])
            catalog.stop()
        }
    }

    @Test("Authorized outside roots cannot expand discovery and observed items obey the same boundary")
    @MainActor
    func restrictsGlobalDiscoveryRoots() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let home = root.appendingPathComponent("A")
        let shared = root.appendingPathComponent("B")
        let outside = root.appendingPathComponent("outside.txt")
        try Data("fixture".utf8).write(to: outside)
        let files = [home.appendingPathComponent("first.txt"), shared.appendingPathComponent("second.txt"), outside]
        for file in files { try writeTags(["Boundary\n6"], to: file) }
        let catalog = FinderTagCatalog(discoveryRoots: [home, shared], monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root, outside])
        await catalog.waitForIdle()
        #expect(Set(catalog.itemURLs(tagged: "Boundary")) == Set(files.prefix(2)))
        let fileSystem = FileSystemService()
        catalog.observe([try await fileSystem.item(at: outside)])
        #expect(Set(catalog.itemURLs(tagged: "Boundary")) == Set(files.prefix(2)))
        #expect(TagDiscoveryPolicy.standardRoots.map(\.path) == [UserDirectoryService.homeURL.path, "/Users/Shared"])
        #expect(!TagDiscoveryPolicy(roots: [home]).contains(root.appendingPathComponent("AB/file.txt")))
        let escape = home.appendingPathComponent("escape")
        try FileManager.default.createSymbolicLink(at: escape, withDestinationURL: shared)
        #expect(TagDiscoveryPolicy(roots: [home]).intersection(escape).isEmpty)
        let revision = catalog.revision
        catalog.filesChanged([TagFileChange(path: home.appendingPathComponent(".noise/file.txt").path,
            flags: FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs))])
        #expect(catalog.isIdle)
        #expect(catalog.revision == revision)
        #expect(chflags(home.path, UInt32(UF_HIDDEN)) == 0)
        catalog.filesChanged([TagFileChange(path: home.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemFinderInfoMod | kFSEventStreamEventFlagItemIsDir))])
        await catalog.waitForEvents()
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Boundary") == [files[1]])
        #expect(chflags(home.path, 0) == 0)
        catalog.filesChanged([TagFileChange(path: home.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemFinderInfoMod | kFSEventStreamEventFlagItemIsDir))])
        await catalog.waitForEvents()
        await catalog.waitForIdle()
        #expect(Set(catalog.itemURLs(tagged: "Boundary")) == Set(files.prefix(2)))
    }

    @Test("Discovery excludes dot files, hidden flags and hidden ancestors while local tags remain readable")
    func skipsHiddenItemsAndSubtrees() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let hiddenDirectory = root.appendingPathComponent(".hidden")
        let flaggedDirectory = root.appendingPathComponent("flagged")
        for directory in [hiddenDirectory, flaggedDirectory] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let visible = root.appendingPathComponent("A/first.txt")
        let hidden = [root.appendingPathComponent(".dot.txt"), root.appendingPathComponent("flag.txt"),
                      hiddenDirectory.appendingPathComponent("child.txt"), flaggedDirectory.appendingPathComponent("child.txt")]
        for file in [visible] + hidden {
            try Data("fixture".utf8).write(to: file)
            try writeTags(["Visibility\n6"], to: file)
        }
        #expect(chflags(hidden[1].path, UInt32(UF_HIDDEN)) == 0)
        #expect(chflags(flaggedDirectory.path, UInt32(UF_HIDDEN)) == 0)
        let result = ScanResults()
        await TaggedFileScanner.scan([root, hiddenDirectory, flaggedDirectory]) { await result.append($0) }
        #expect(Set(await result.records.keys) == [visible.path])
        let updated = await TaggedFileScanner.read(hidden)
        #expect(updated.values.allSatisfy { $0.isEmpty })
        #expect(FinderTagMetadata.colorIndexes(at: hidden[0]) == ["Visibility": 6])
    }

    @Test("Visibility filtering never probes descendants below a hidden ancestor")
    func hiddenAncestorBoundsMetadataProbes() throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let hidden = root.appendingPathComponent("A")
        let parent = hidden.appendingPathComponent("First/Second/Third")
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let file = parent.appendingPathComponent("file.txt")
        try Data("Visibility fixture".utf8).write(to: file)
        #expect(chflags(hidden.path, UInt32(UF_HIDDEN)) == 0)
        var probes: [URL] = []
        let visible = TagDiscoveryPolicy.isVisible(file, boundary: root, readFlags: { url in
            probes.append(url)
            var info = stat()
            return lstat(url.path, &info) == 0 ? info.st_flags : nil
        })
        #expect(!visible)
        #expect(probes.count <= 2)
        #expect(probes.allSatisfy { !TagScanRoots.covers(hidden.path + "/", $0.path) })
    }

    @Test("Sibling visibility checks share ancestor probes and discard them between batches")
    func visibilityBatchSharesOnlyAncestorFlags() {
        let root = URL(fileURLWithPath: "/fixture/Batch")
        let directory = root.appendingPathComponent("A")
        var batch = TagVisibilityBatch(policy: .init(roots: [root]))
        var probes: [String: Int] = [:]
        for index in 0..<100 {
            let file = directory.appendingPathComponent("file-\(index).txt")
            let visible = batch.isVisible(file, readInfo: { path in probes[path, default: 0] += 1; return .init(flags: 0) })
            #expect(visible)
            #expect(probes[file.path] == 1)
        }
        #expect(probes[root.path] == 1)
        #expect(probes[directory.path] == 1)
        #expect(batch.cachedAncestorCount == 2)
        var next = TagVisibilityBatch(policy: .init(roots: [root]))
        var nextProbes: [String] = []
        let hidden = next.isVisible(directory.appendingPathComponent("file-0.txt"), readInfo: { path in
            nextProbes.append(path)
            return .init(flags: path == directory.path ? UInt32(UF_HIDDEN) : 0)
        })
        #expect(!hidden)
        #expect(nextProbes == [root.path, directory.path])
    }

    @Test("Batch path preparation preserves canonical keys and resolves unusual components before scope checks")
    func visibilityBatchNormalizesOnlyUnusualKeys() {
        let batch = TagVisibilityBatch(policy: .init(roots: [URL(fileURLWithPath: "/fixture/Batch")]))
        #expect(batch.normalizedPath("/fixture/Batch/A/file.txt") == "/fixture/Batch/A/file.txt")
        #expect(batch.normalizedPath("/fixture/Batch/A/../B/file.txt") == "/fixture/Batch/B/file.txt")
        #expect(batch.normalizedPath("/fixture/Batch//A/file.txt") == "/fixture/Batch/A/file.txt")
        let outside = batch.normalizedPath("/fixture/Batch/A/../../../Outside/file.txt")
        #expect(outside == "/Outside/file.txt")
        #expect(!batch.contains(normalizedPath: outside))
    }

    @Test("Combining characters at a filename boundary cannot bypass a hidden ancestor")
    func visibilityChecksUnicodeBoundaryAncestors() {
        let root = URL(fileURLWithPath: "/fixture/Batch")
        let directory = root.appendingPathComponent("A")
        let file = directory.appendingPathComponent("\u{301}file.txt")
        var batch = TagVisibilityBatch(policy: .init(roots: [root]))
        var probes: [String] = []
        let visible = batch.isVisible(file, readInfo: { path in
            probes.append(path)
            return .init(flags: path == directory.path ? UInt32(UF_HIDDEN) : 0)
        })
        #expect(!visible)
        #expect(probes == [root.path, directory.path])
    }

    @Test("An unavailable cached item identity requires conservative metadata reconciliation")
    func unavailableVisibilityIdentityRequiresReread() {
        let root = URL(fileURLWithPath: "/fixture/Batch")
        let file = root.appendingPathComponent("unavailable.txt")
        var batch = TagVisibilityBatch(policy: .init(roots: [root]))
        let visible = batch.isVisible(file, readInfo: { path in
            path == file.path ? nil : .init(flags: 0)
        })
        #expect(visible)
        #expect(batch.metadataRechecks == [file.path])
    }

    @Test("Visibility batches cap ancestor storage and reject hidden lexical paths and outside scopes")
    func visibilityBatchBoundsAndExclusions() {
        let root = URL(fileURLWithPath: "/fixture/Batch")
        var batch = TagVisibilityBatch(policy: .init(roots: [root]))
        var probes = 0
        for index in 0..<600 {
            let visible = batch.isVisible(root.appendingPathComponent("directory-\(index)/file.txt"), readInfo: { _ in
                probes += 1; return .init(flags: 0)
            })
            #expect(visible)
        }
        #expect(batch.cachedAncestorCount == 512)
        let beforeExcluded = probes
        for file in [root.appendingPathComponent(".hidden/file.txt"), root.appendingPathComponent("A/.file"),
                     URL(fileURLWithPath: "/fixture/BatchOutside/file.txt")] {
            let visible = batch.isVisible(file, readInfo: { _ in probes += 1; return .init(flags: 0) })
            #expect(!visible)
        }
        #expect(probes == beforeExcluded)
    }

    @Test("Asynchronous visibility filtering retains removals and rejects hidden and outside records")
    func visibilityFilteringPreservesRecordContract() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let visible = root.appendingPathComponent("A/first.txt")
        let removed = root.appendingPathComponent("A/removed.txt")
        let hidden = root.appendingPathComponent("B/second.txt")
        #expect(chflags(hidden.path, UInt32(UF_HIDDEN)) == 0)
        let outside = root.appendingPathComponent("Outside/file.txt")
        let result = await TaggedFileScanner.visibleRecords([
            visible.path: ["Batch Label": 6], removed.path: [:],
            hidden.path: ["Hidden Label": 4], outside.path: ["Outside Label": 2]
        ], policy: .init(roots: [root.appendingPathComponent("A"), root.appendingPathComponent("B")]))
        #expect(result == [visible.path: ["Batch Label": 6], removed.path: [:], hidden.path: [:]])
    }

    @Test("Canceling a visibility batch discards partial results and stops subsequent probes")
    func canceledVisibilityBatchDoesNotPublishPartialRecords() async {
        let root = URL(fileURLWithPath: "/fixture/Batch")
        let gate = ScanGate()
        var budget = TaggedFileScanner.Budget()
        budget.maximumItems = 1
        budget.yieldSlice = { await gate.arriveAndWait() }
        let batch = Dictionary(uniqueKeysWithValues: (0..<256).map {
            (root.appendingPathComponent("file-\($0).txt").path, ["Cancellation Label": 6])
        })
        let worker = Task { await TaggedFileScanner.visibleRecords(batch, policy: .init(roots: [root]), budget: budget) }
        await gate.waitForArrival()
        worker.cancel()
        await gate.open()
        #expect(await worker.value.isEmpty)
        #expect(await gate.count == 1)
    }

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
        _ = await worker.value
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory])
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory])
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
        #expect(!TagDiscoveryPolicy(roots: TagDiscoveryPolicy.standardRoots).isVisible(root))
        #expect(FinderTagCatalog.shared.itemURLs(tagged: name).isEmpty)
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
        let contextMenu = BrowserNativeContextMenu.make(state: state, item: file)
        #expect(contextMenu.items.contains { $0.identifier?.rawValue == "quick-tags-Welcome.txt" })
        // The Mac's own Finder tags would decide which seven circles appear, so
        // the circle states are checked against a fixed catalog.
        let menu = NSMenu()
        FinderTagQuickMenu.append(to: menu, state: state, items: [file],
            catalogTags: [FinderTag(name: "Blue", colorIndex: 4), FinderTag(name: "Red", colorIndex: 6)])
        let row = try #require(menu.items.first { $0.identifier?.rawValue == "quick-tags-Welcome.txt" })
        let buttons = row.view?.subviews.compactMap { $0 as? FinderTagQuickButton } ?? []
        #expect(buttons.map(\.finderTag.name) == ["Blue", "Red"])
        let red = try #require(buttons.first { $0.finderTag.name == "Red" })
        #expect(red.applied)
        #expect(red.symbolName == "checkmark")
        #expect(red.accessibilityValue() as? String == "1")
        let blue = try #require(buttons.first { $0.finderTag.name == "Blue" })
        #expect(!blue.applied)
        #expect(blue.accessibilityValue() as? String == "0")
    }

    @Test("Completed discovery is reused by repeated refreshes and descendant scopes")
    @MainActor
    func refreshReusesDiscovery() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, publish in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, _ in await probe.scanned(roots) }, reader: { urls in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, publish in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { _, publish in
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], monitorsFiles: false, usesSpotlight: false)
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
        let budget = TaggedFileScanner.Budget(yieldSlice: { await probe.yielded() })
        await TaggedFileScanner.scan([root], budget: budget) { await probe.published($0) }
        #expect(await probe.maximumBatch <= 128)
        #expect(await probe.recordCount == 257)
        // The former positive-pause-duration assertion encoded the 20% CPU
        // duty cycle, removed by the user on 2026-10-24; slices still yield.
        #expect(await probe.yields >= 3)
        for index in 0..<257 { try writeTags([], to: root.appendingPathComponent("file-\(index).txt")) }
        let untagged = BudgetProbe()
        await TaggedFileScanner.scan([root], budget: TaggedFileScanner.Budget(yieldSlice: { await untagged.yielded() })) {
            await untagged.published($0)
        }
        #expect(await untagged.recordCount == 0)
        #expect(await untagged.yields >= 3)
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], monitorsFiles: false, usesSpotlight: false)
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
        await TaggedFileScanner.scan([root, temporary, package]) { await result.append($0) }
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], scanner: { roots, _ in await probe.scanned(roots) },
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
        let catalog = FinderTagCatalog(discoveryRoots: [FileManager.default.temporaryDirectory], monitorsFiles: false, usesSpotlight: false)
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

    @Test("Hidden noise and continued visible changes do not postpone queued tag reconciliation", arguments: [false, true])
    @MainActor
    func eventCoalescingCannotBeStarved(hiddenOnly: Bool) async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let probe = CatalogWorkProbe()
        let delay = ScanGate()
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent(hiddenOnly ? ".hidden.txt" : "B/second.txt")
        let catalog = FinderTagCatalog(discoveryRoots: [root], scanner: { _, _ in }, reader: { urls in
            await probe.read(urls); return [:]
        }, monitorsFiles: false, usesSpotlight: false, eventDelay: { await delay.arriveAndWait() })
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        catalog.filesChanged([TagFileChange(path: first.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))])
        await delay.waitForArrival()
        catalog.filesChanged([TagFileChange(path: second.path, flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))])
        await delay.open()
        await catalog.waitForIdle()
        #expect(await delay.count == 1)
        #expect(Set(await probe.reads.flatMap { $0 }) == Set(hiddenOnly ? [first] : [first, second]))
        #expect(catalog.isIdle)
    }

    @Test("A completed persistent catalog reopens without scanning the same authorized tree")
    @MainActor
    func reopensCompletedIndexWithoutRecursiveScan() async throws {
        let root = try fixtureRoot()
        let storage = root.appendingPathComponent(".index.json")
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Persistent Fixture\n6"], to: file)
        let store = TagIndexStore(url: storage)
        let first = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        first.refresh(searchScopes: [root])
        await first.waitForIdle()
        #expect(await store.load() != nil)
        first.stop()
        let probe = CatalogWorkProbe()
        let second = FinderTagCatalog(discoveryRoots: [root], scanner: { roots, _ in await probe.scanned(roots) },
            usesSpotlight: false, indexStore: store)
        defer { second.stop() }
        second.refresh(searchScopes: [root])
        await second.waitForIdle()
        #expect(await probe.scans.isEmpty)
        #expect(second.itemURLs(tagged: "Persistent Fixture") == [file])
        #expect(second.isIdle)
    }

    @Test("A valid quiet checkpoint restores unchanged tags without scheduling metadata rereads")
    @MainActor
    func quietCheckpointDoesNotRereadTaggedRecords() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let initial = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        initial.refresh(searchScopes: [root])
        await initial.waitForIdle()
        // Observe the fixture write through the native journal before saving
        // its quiet checkpoint. Initial filesystem-event delivery is async;
        // draining discovery alone is not a fence for a pre-start metadata write.
        try writeTags(["Quiet Cached\n6"], to: file)
        try await waitUntil({ initial.itemURLs(tagged: "Quiet Cached") == [file] },
            stage: "Quiet fixture native metadata delivery", diagnostics: { "revision=\(initial.revision)" })
        await initial.waitForIdle()
        #expect(await store.load()?.records[file.path] == ["Quiet Cached": 6])
        initial.stop()
        let probe = CatalogWorkProbe()
        let reopened = FinderTagCatalog(discoveryRoots: [root], scanner: { scopes, publish in
            await probe.scanned(scopes)
            await TaggedFileScanner.scan(scopes, onBatch: publish)
        }, reader: { urls in
            await probe.read(urls)
            return await TaggedFileScanner.read(urls)
        }, usesSpotlight: false, indexStore: store)
        defer { reopened.stop() }
        reopened.refresh(searchScopes: [root])
        await reopened.waitForIdle()
        #expect(reopened.itemURLs(tagged: "Quiet Cached") == [file])
        #expect(await probe.scans.isEmpty)
        #expect(await probe.reads.isEmpty)
        #expect(reopened.isIdle)
    }

    @Test("Restored linked items revalidate target metadata changed outside the watched scope", arguments: [false, true])
    @MainActor
    func restoredLinksRevalidateExternalTargets(hardLink: Bool) async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let scope = root.appendingPathComponent("A")
        let target = root.appendingPathComponent("B/second.txt")
        let alias = scope.appendingPathComponent("linked.txt")
        try writeTags(["Linked Cached\n6"], to: target)
        if hardLink { try FileManager.default.linkItem(at: target, to: alias) }
        else { try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: target) }
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let initial = FinderTagCatalog(discoveryRoots: [scope], usesSpotlight: false, indexStore: store)
        initial.refresh(searchScopes: [scope])
        await initial.waitForIdle()
        #expect(initial.itemURLs(tagged: "Linked Cached") == [alias])
        initial.stop()
        try writeTags(["Linked Updated\n4"], to: target)
        let reopened = FinderTagCatalog(discoveryRoots: [scope], usesSpotlight: false, indexStore: store)
        defer { reopened.stop() }
        reopened.refresh(searchScopes: [scope])
        await reopened.waitForIdle()
        #expect(reopened.itemURLs(tagged: "Linked Cached").isEmpty)
        #expect(reopened.itemURLs(tagged: "Linked Updated") == [alias])
        #expect(await store.load()?.records[alias.path] == ["Linked Updated": 4])
    }

    @Test("Staged authorization restores each cached scope without replacing the other scope's checkpoint", arguments: [false, true])
    @MainActor
    func restoresStagedAuthorization(quitBetweenGrants: Bool) async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let scopes = [root.appendingPathComponent("A"), root.appendingPathComponent("B")]
        let file = scopes[0].appendingPathComponent("first.txt")
        try writeTags(["Staged Cached\n6"], to: file)
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let first = FinderTagCatalog(discoveryRoots: scopes, usesSpotlight: false, indexStore: store)
        first.refresh(searchScopes: scopes)
        await first.waitForIdle()
        #expect(await store.load()?.scopes.count == 2)
        first.stop()
        try writeTags(["Staged Offline\n4"], to: file)
        let probe = CatalogWorkProbe()
        let second = FinderTagCatalog(discoveryRoots: scopes, scanner: { scopes, publish in
            await probe.scanned(scopes)
            await TaggedFileScanner.scan(scopes, onBatch: publish)
        }, usesSpotlight: false, indexStore: store)
        defer { second.stop() }
        second.refresh(searchScopes: [scopes[1]])
        await second.waitForIdle()
        #expect(second.itemURLs(tagged: "Staged Cached").isEmpty)
        let final: FinderTagCatalog
        if quitBetweenGrants {
            second.stop()
            final = FinderTagCatalog(discoveryRoots: scopes, scanner: { scopes, publish in
                await probe.scanned(scopes)
                await TaggedFileScanner.scan(scopes, onBatch: publish)
            }, usesSpotlight: false, indexStore: store)
            final.refresh(searchScopes: [scopes[1]])
            await final.waitForIdle()
        } else { final = second }
        defer { final.stop() }
        final.refresh(searchScopes: [scopes[0]])
        await final.waitForIdle()
        #expect(await probe.scans.isEmpty)
        #expect(final.itemURLs(tagged: "Staged Offline") == [file])
        #expect(await store.load()?.scopes.count == 2)
    }

    @Test("Persistent replay discovers offline edits, moves, additions and deletions without a full rescan")
    @MainActor
    func replaysOfflineChanges() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        let deleted = root.appendingPathComponent("B/second.txt")
        for url in [file, deleted] { try writeTags(["Offline Old\n6"], to: url) }
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let first = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        first.refresh(searchScopes: [root])
        await first.waitForIdle()
        #expect(await store.load() != nil)
        first.stop()
        try writeTags(["Offline Changed\n4"], to: file)
        let moved = root.appendingPathComponent("B/moved.txt")
        try FileManager.default.moveItem(at: file, to: moved)
        try FileManager.default.removeItem(at: deleted)
        let added = root.appendingPathComponent("A/added.txt")
        try Data().write(to: added)
        try writeTags(["Offline Added\n2"], to: added)
        let directory = root.appendingPathComponent("C")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let child = directory.appendingPathComponent("child.txt")
        try Data().write(to: child)
        try writeTags(["Offline Child\n5"], to: child)
        let hidden = root.appendingPathComponent(".hidden.txt")
        try Data().write(to: hidden)
        try writeTags(["Offline Hidden\n6"], to: hidden)
        let probe = CatalogWorkProbe()
        let second = FinderTagCatalog(discoveryRoots: [root], scanner: { roots, publish in
            await probe.scanned(roots)
            await TaggedFileScanner.scan(roots, onBatch: publish)
        }, usesSpotlight: false, indexStore: store)
        defer { second.stop() }
        second.refresh(searchScopes: [root])
        try await waitUntil({ second.itemURLs(tagged: "Offline Changed") == [moved]
            && second.itemURLs(tagged: "Offline Added") == [added]
            && second.itemURLs(tagged: "Offline Child") == [child]
            && second.itemURLs(tagged: "Offline Old").isEmpty }, stage: "Offline history replay",
            diagnostics: { "idle=\(second.isIdle), revision=\(second.revision)" })
        await second.waitForIdle()
        #expect(second.itemURLs(tagged: "Offline Hidden").isEmpty)
        #expect(await probe.scans.flatMap { $0 }.allSatisfy { $0 != root })
        #expect(await store.load()?.records[child.path] == ["Offline Child": 5])
    }

    @Test("Native inode visibility events discover and remove tagged directory descendants")
    @MainActor
    func inodeVisibilityEventsReconcileDescendants() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("A")
        let file = directory.appendingPathComponent("first.txt")
        try writeTags(["Inode Visibility\n6"], to: file)
        #expect(chflags(directory.path, UInt32(UF_HIDDEN)) == 0)
        let catalog = FinderTagCatalog(discoveryRoots: [root], monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        #expect(catalog.itemURLs(tagged: "Inode Visibility").isEmpty)
        let event = TagFileChange(path: directory.path,
            flags: FSEventStreamEventFlags(kFSEventStreamEventFlagItemInodeMetaMod | kFSEventStreamEventFlagItemIsDir))
        for hidden in [false, true, false] {
            #expect(chflags(directory.path, hidden ? UInt32(UF_HIDDEN) : 0) == 0)
            catalog.filesChanged([event])
            await catalog.waitForIdle()
            #expect(catalog.itemURLs(tagged: "Inode Visibility") == (hidden ? [] : [file]))
        }
    }

    @Test("Persistent replay discovers tags in a previously hidden directory when it becomes visible")
    @MainActor
    func replaysOfflineVisibilityChanges() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("A")
        let file = directory.appendingPathComponent("first.txt")
        try writeTags(["Offline Visibility\n6"], to: file)
        #expect(chflags(directory.path, UInt32(UF_HIDDEN)) == 0)
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let first = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        first.refresh(searchScopes: [root])
        await first.waitForIdle()
        #expect(first.itemURLs(tagged: "Offline Visibility").isEmpty)
        first.stop()
        #expect(chflags(directory.path, 0) == 0)
        let probe = CatalogWorkProbe()
        let second = FinderTagCatalog(discoveryRoots: [root], scanner: { scopes, publish in
            await probe.scanned(scopes)
            await TaggedFileScanner.scan(scopes, onBatch: publish)
        }, usesSpotlight: false, indexStore: store)
        defer { second.stop() }
        second.refresh(searchScopes: [root])
        try await waitUntil({ second.itemURLs(tagged: "Offline Visibility") == [file] },
            stage: "Offline directory visibility replay", diagnostics: { "idle=\(second.isIdle)" })
        await second.waitForIdle()
        #expect(await probe.scans.flatMap { $0 }.allSatisfy { $0 != root })
    }

    @Test("Incomplete initial discovery cannot be persisted as a completed index")
    @MainActor
    func interruptedIndexIsNotReusable() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let gate = ScanGate()
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let catalog = FinderTagCatalog(discoveryRoots: [root], scanner: { _, publish in
            await publish([root.appendingPathComponent("A/first.txt").path: ["Partial": 6]])
            await gate.arriveAndWait()
        }, usesSpotlight: false, indexStore: store)
        catalog.refresh(searchScopes: [root])
        await gate.waitForArrival()
        #expect(await store.load() == nil)
        catalog.stop()
        await gate.open()
        await catalog.waitForIdle()
        #expect(await store.load() == nil)
        #expect(catalog.isIdle)
    }

    @Test("Invalid cache schema, scope identity, volume history or future cursor requires rebuilding", arguments: 0..<5)
    @MainActor
    func invalidPersistentIndexRebuilds(reason: Int) async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let description = try #require(TagJournal.describe([root]))
        let scope = try #require(description.scopes.first)
        var snapshot = TagIndexSnapshot(scopes: description.scopes,
            cursors: [scope.path: FSEventsGetCurrentEventId()], records: [:])
        switch reason {
        case 0: snapshot.version = 0
        case 1: snapshot = TagIndexSnapshot(scopes: [TagJournal.Scope(path: scope.path, inode: scope.inode + 1, journal: scope.journal)], cursors: snapshot.cursors, records: [:])
        case 2: snapshot = TagIndexSnapshot(scopes: [TagJournal.Scope(path: scope.path, inode: scope.inode, journal: "Invalidated Journal")], cursors: snapshot.cursors, records: [:])
        case 3: snapshot = TagIndexSnapshot(scopes: snapshot.scopes, cursors: [scope.path: UInt64.max - 1], records: [:])
        default: snapshot = TagIndexSnapshot(scopes: snapshot.scopes, cursors: [:], records: [:])
        }
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        #expect(await store.save(snapshot))
        let probe = CatalogWorkProbe()
        let catalog = FinderTagCatalog(discoveryRoots: [root], scanner: { roots, _ in await probe.scanned(roots) },
            usesSpotlight: false, indexStore: store)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        let scannedPaths = await probe.scans.map { $0.map(\.path) }
        #expect(scannedPaths == [[root.path]], Comment(rawValue: "Scanned paths: \(scannedPaths)"))
    }

    @Test("Corrupt storage and unavailable checkpoint paths preserve current tag discovery")
    @MainActor
    func indexStorageFailuresKeepDiscovery() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Storage Fixture\n6"], to: file)
        let corrupted = root.appendingPathComponent(".corrupt.json")
        try Data("invalid index".utf8).write(to: corrupted)
        for url in [corrupted, file.appendingPathComponent("index.json")] {
            let store = TagIndexStore(url: url)
            #expect(await store.load() == nil)
            let catalog = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
            catalog.refresh(searchScopes: [root])
            await catalog.waitForIdle()
            #expect(catalog.itemURLs(tagged: "Storage Fixture") == [file])
            #expect(catalog.isIdle)
            catalog.stop()
        }
    }

    @Test("A saved cache cannot restore ungranted scopes or expand discovery boundaries")
    @MainActor
    func cacheDoesNotExpandAuthorization() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("A/first.txt")
        let second = root.appendingPathComponent("B/second.txt")
        try writeTags(["Authorized Fixture\n6"], to: first)
        try writeTags(["Outside Fixture\n4"], to: second)
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let initial = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        initial.refresh(searchScopes: [root])
        await initial.waitForIdle()
        initial.stop()
        let limited = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        defer { limited.stop() }
        limited.refresh(searchScopes: [root.appendingPathComponent("A")])
        await limited.waitForIdle()
        #expect(limited.itemURLs(tagged: "Authorized Fixture") == [first])
        #expect(limited.itemURLs(tagged: "Outside Fixture").isEmpty)
    }

    @Test("Dropped volume events reconcile every watched root even when their event path is hidden")
    @MainActor
    func journalLossReconcilesVolume() {
        var received: [TagFileChange] = []
        let journal = TagJournal(onChanges: { received += $0 }, onHistory: {})
        let volume = TagJournal.Volume(device: 0, journal: "Test Journal",
            paths: [("/fixture/Home", "/fixture/Home"), ("/fixture/Shared", "/fixture/Shared")])
        for flag in [kFSEventStreamEventFlagUserDropped, kFSEventStreamEventFlagKernelDropped,
                     kFSEventStreamEventFlagEventIdsWrapped, kFSEventStreamEventFlagRootChanged] {
            received.removeAll()
            journal.receive(volume: volume, paths: ["/fixture/Home/.hidden"],
                flags: [FSEventStreamEventFlags(flag)], ids: [42])
            #expect(Set(received.map(\.path)) == ["/fixture/Home", "/fixture/Shared"])
            #expect(received.allSatisfy { $0.requiresRecursiveScan })
        }
        journal.stop()
    }

    @Test("A lost event from one native stream reconciles its sibling scope on the same volume")
    @MainActor
    func journalLossIncludesSiblingStream() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let roots = [root.appendingPathComponent("A"), root.appendingPathComponent("B")]
        let description = try #require(TagJournal.describe(roots))
        var received: [TagFileChange] = []
        let journal = TagJournal(onChanges: { received += $0 }, onHistory: {})
        journal.start(description, since: [:])
        defer { journal.stop() }
        #expect(journal.available)
        await journal.waitForHistory()
        for flag in [kFSEventStreamEventFlagUserDropped, kFSEventStreamEventFlagKernelDropped,
                     kFSEventStreamEventFlagEventIdsWrapped, kFSEventStreamEventFlagRootChanged] {
            received.removeAll()
            journal.receive(volume: description.volumes[0], paths: [roots[0].appendingPathComponent(".hidden").path],
                flags: [FSEventStreamEventFlags(flag)], ids: [42])
            #expect(Set(received.map(\.path)) == Set(roots.map(\.path)))
            #expect(received.allSatisfy { $0.requiresRecursiveScan })
        }
    }

    @Test("Physical traversal reads tagged roots and packages without following directory aliases")
    func nativeTraversalPreservesRootAndLinkBoundaries() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        try writeTags(["Root Fixture\n6"], to: file)
        let result = ScanResults()
        await TaggedFileScanner.scan([file]) { await result.append($0) }
        #expect(await result.records == [file.path: ["Root Fixture": 6]])
        let link = root.appendingPathComponent("directory-link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root.appendingPathComponent("A"))
        let all = ScanResults()
        await TaggedFileScanner.scan([root]) { await all.append($0) }
        #expect(await all.records[link.appendingPathComponent("first.txt").path] == nil)
        let fallback = ScanResults()
        await TaggedFileScanner.scan([root], budget: .init(usesBulkEnumeration: false)) { await fallback.append($0) }
        #expect(await fallback.records == all.records)
    }

    @Test("A partial index retries its inaccessible subtree without rescanning accessible items")
    @MainActor
    func unreadableSubtreePreventsCheckpoint() async throws {
        let root = try fixtureRoot()
        let denied = root.appendingPathComponent("Denied")
        try FileManager.default.createDirectory(at: denied, withIntermediateDirectories: true)
        defer { chmod(denied.path, 0o700); try? FileManager.default.removeItem(at: root) }
        #expect(chmod(denied.path, 0) == 0)
        // Unsettled setup events would legitimately be replayed after the
        // checkpoint and rescan accessible fixture folders.
        try await settleFileEvents(in: root)
        let result = ScanResults()
        let complete = await TaggedFileScanner.scan([root]) { await result.append($0) }
        #expect(!complete)
        let store = TagIndexStore(url: root.appendingPathComponent(".index.json"))
        let catalog = FinderTagCatalog(discoveryRoots: [root], usesSpotlight: false, indexStore: store)
        defer { catalog.stop() }
        catalog.refresh(searchScopes: [root])
        await catalog.waitForIdle()
        let saved = try #require(await store.load())
        #expect(!saved.complete)
        #expect(saved.deferredPaths == [denied.path])
        #expect(catalog.isIdle)
        catalog.stop()
        let probe = CatalogWorkProbe()
        let reopened = FinderTagCatalog(discoveryRoots: [root], scanner: { scopes, publish in
            await probe.scanned(scopes)
            await TaggedFileScanner.scan(scopes, onBatch: publish)
        }, usesSpotlight: false, indexStore: store)
        defer { reopened.stop() }
        reopened.refresh(searchScopes: [root])
        await reopened.waitForIdle()
        #expect(await probe.scans.map { $0.map(\.path) } == [[denied.path]])
    }

    @Test("Bulk decoding preserves long names, Unicode names and package exclusion")
    func bulkDecodingPreservesNames() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let names = ["Café notes.txt", String(repeating: "x", count: 250) + ".txt"]
        let files = names.map { root.appendingPathComponent($0) }
        for file in files {
            try Data().write(to: file)
            try writeTags(["Name Fixture\n6"], to: file)
        }
        let native = ScanResults()
        let fallback = ScanResults()
        #expect(await TaggedFileScanner.scan([root]) { await native.append($0) })
        #expect(await TaggedFileScanner.scan([root], budget: .init(usesBulkEnumeration: false)) { await fallback.append($0) })
        #expect(Set(await native.records.keys) == Set(files.map(\.path)))
        #expect(await native.records == fallback.records)
    }

    @Test("The bulk xattr-presence hint skips only confirmed attribute-free inodes and keeps symlink target tags")
    func bulkPresenceHintIsConservative() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        // System provenance cannot be reliably removed on this host. Use the
        // documented flags as controlled input, then verify real tagged items.
        #expect(!ZFTagMayHaveXattrs(UInt32(VREG.rawValue), true, UInt64(EF_NO_XATTRS)))
        #expect(ZFTagMayHaveXattrs(UInt32(VREG.rawValue), false, UInt64(EF_NO_XATTRS)))
        #expect(ZFTagMayHaveXattrs(UInt32(VREG.rawValue), true, 0))
        #expect(ZFTagMayHaveXattrs(UInt32(VLNK.rawValue), true, UInt64(EF_NO_XATTRS)))
        let initial = await TaggedFileScanner.scanResult([root], onBatch: { _ in })
        #expect(initial.complete)
        try writeTags(["Presence Fixture\n6"], to: file)
        let link = root.appendingPathComponent("linked.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        // When bulk object type is unavailable, lstat must retain the link
        // identity so an attribute-free link still reads its tagged target.
        var linkInfo = stat()
        #expect(lstat(link.path, &linkInfo) == 0)
        #expect(ZFTagObjectTypeFromMode(UInt32(linkInfo.st_mode)) == UInt32(VLNK.rawValue))
        #expect(ZFTagMayHaveXattrs(ZFTagObjectTypeFromMode(UInt32(linkInfo.st_mode)), true, UInt64(EF_NO_XATTRS)))
        let result = ScanResults()
        let updated = await TaggedFileScanner.scanResult([root]) { await result.append($0) }
        #expect(updated.complete)
        #expect(Set(await result.records.keys) == [file.path, link.path])
    }

    @Test("The attribute-name prefilter reads listed tags and treats similar names as untagged")
    func attributeListPrefilterMatchesExactTagName() throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        let tagName = FinderTagMetadata.attribute
        for name in [tagName + "X", String(tagName.dropLast()), "io.zforge.fixture"] {
            try writeAttribute(name, value: Data("Similar attribute fixture".utf8), to: file)
        }
        try file.path.withCString { path in
            #expect(FinderTagMetadata.listsTagAttribute(atPath: path) == false)
            let untagged = FinderTagMetadata.readColorIndexes(atPath: path)
            #expect(untagged.complete)
            #expect(untagged.colors.isEmpty)
            try writeTags(["Listed Fixture\n6", "Plain Listed Fixture"], to: file)
            #expect(FinderTagMetadata.listsTagAttribute(atPath: path) == true)
            let tagged = FinderTagMetadata.readColorIndexes(atPath: path)
            #expect(tagged.complete)
            #expect(tagged.colors == ["Listed Fixture": 6, "Plain Listed Fixture": 0])
        }
        // A missing item remains complete empty metadata, as with a direct read.
        let missing = FinderTagMetadata.readColorIndexes(atPath: root.appendingPathComponent("missing.txt").path)
        #expect(missing.complete)
        #expect(missing.colors.isEmpty)
        let names = Array("first\0\(tagName)\0".utf8)
        names.withUnsafeBytes { list in
            #expect(FinderTagMetadata.attributeNames(list, contain: Array(tagName.utf8)))
            #expect(!FinderTagMetadata.attributeNames(UnsafeRawBufferPointer(rebasing: list[..<6]), contain: Array(tagName.utf8)))
        }
        #expect(!FinderTagMetadata.attributeNames(UnsafeRawBufferPointer(start: nil, count: 0), contain: Array(tagName.utf8)))
    }

    @Test("An attribute-name list larger than the prefilter buffer keeps the direct tag read")
    func oversizedAttributeListFallsBackToDirectRead() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("A/first.txt")
        // Names are limited to 127 bytes; 40 names of 120 bytes exceed the 4 KiB list.
        for index in 0..<40 {
            let name = "io.zforge.fixture.long-attribute-name-\(index)-"
            try writeAttribute(name + String(repeating: "x", count: 120 - name.utf8.count), value: Data([UInt8(index)]), to: file)
        }
        try file.path.withCString { path in
            #expect(FinderTagMetadata.listsTagAttribute(atPath: path, capacity: 4096) == nil)
            #expect(FinderTagMetadata.readColorIndexes(atPath: path).complete)
            #expect(FinderTagMetadata.readColorIndexes(atPath: path).colors.isEmpty)
            try writeTags(["Oversized List Fixture\n4"], to: file)
            #expect(FinderTagMetadata.listsTagAttribute(atPath: path, capacity: 4096) == nil)
            #expect(FinderTagMetadata.readColorIndexes(atPath: path).colors == ["Oversized List Fixture": 4])
        }
        let result = ScanResults()
        #expect(await TaggedFileScanner.scan([root]) { await result.append($0) })
        #expect(await result.records == [file.path: ["Oversized List Fixture": 4]])
    }

    @Test("Bulk Finder info skips the package lookup only for extensionless directories without the bundle bit")
    func bulkPackagePrecheckPreservesBundleBitAndExtensions() async throws {
        let root = try fixtureRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        var finderInfo = [UInt8](repeating: 0, count: 32)
        #expect(!ZFTagMayBePackage("Plain", finderInfo))
        #expect(ZFTagMayBePackage("Plain.app", finderInfo))
        #expect(ZFTagMayBePackage("Version 1.2", finderInfo))
        #expect(ZFTagMayBePackage("Plain", nil))
        finderInfo[8] = 0x20
        #expect(ZFTagMayBePackage("Plain", finderInfo))
        // A dotless directory with the bundle bit is a package to LaunchServices;
        // a plain dotless folder and a dotted ordinary folder are traversed.
        let flagged = root.appendingPathComponent("FlaggedBundle")
        let plain = root.appendingPathComponent("PlainFolder")
        let dotted = root.appendingPathComponent("Version 1.2")
        for directory in [flagged, plain, dotted] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let file = directory.appendingPathComponent("inside.txt")
            try Data("Package fixture".utf8).write(to: file)
            try writeTags(["Package Boundary\n6"], to: file)
        }
        try writeAttribute("com.apple.FinderInfo", value: Data(finderInfo), to: flagged)
        #expect(try flagged.resourceValues(forKeys: [.isPackageKey]).isPackage == true)
        #expect(try plain.resourceValues(forKeys: [.isPackageKey]).isPackage == false)
        #expect(try dotted.resourceValues(forKeys: [.isPackageKey]).isPackage == false)
        let native = ScanResults()
        let fallback = ScanResults()
        #expect(await TaggedFileScanner.scan([root]) { await native.append($0) })
        #expect(await TaggedFileScanner.scan([root], budget: .init(usesBulkEnumeration: false)) { await fallback.append($0) })
        let expected = Set([plain, dotted].map { $0.appendingPathComponent("inside.txt").path })
        #expect(Set(await native.records.keys) == expected)
        #expect(await native.records == fallback.records)
    }

    @Test("Slice boundaries bound work, yield without a CPU pause and observe cancellation")
    func sliceBoundariesYieldAndObserveCancellation() async {
        var slice = TaggedFileScanner.WorkSlice(TaggedFileScanner.Budget(maximumItems: 2, workSlice: .seconds(60)))
        slice.inspected()
        #expect(!slice.exhausted)
        slice.inspected()
        #expect(slice.exhausted)
        // The default boundary yields and returns without a timed suspension.
        try? await slice.yield()
        #expect(slice.items == 0)
        #expect(TaggedFileScanner.WorkSlice(TaggedFileScanner.Budget(workSlice: .zero)).exhausted)
        let canceled = Task { () -> Bool in
            var slice = TaggedFileScanner.WorkSlice(TaggedFileScanner.Budget())
            slice.inspected()
            withUnsafeCurrentTask { $0?.cancel() }
            do { try await slice.yield(); return false } catch { return error is CancellationError }
        }
        #expect(await canceled.value)
    }

    private func writeAttribute(_ name: String, value: Data, to url: URL) throws {
        let result = value.withUnsafeBytes { bytes in
            url.withUnsafeFileSystemRepresentation { path in
                setxattr(path!, name, bytes.baseAddress, value.count, 0, 0)
            }
        }
        #expect(result == 0, "setxattr \(name) failed: \(errno)")
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

    /// Changes made just before an FSEvents stream starts can still be delivered
    /// to it, with later event IDs. Waits until a hidden marker written after the
    /// fixture arrives; events are ordered, so every earlier change has arrived too.
    private func settleFileEvents(in root: URL) async throws {
        final class Marker: @unchecked Sendable {
            let lock = NSLock()
            var continuation: CheckedContinuation<Bool, Never>?
            func finish(_ delivered: Bool) {
                lock.lock(); let continuation = self.continuation; self.continuation = nil; lock.unlock()
                continuation?.resume(returning: delivered)
            }
        }
        let marker = Marker()
        let unmanaged = Unmanaged.passRetained(marker)
        defer { unmanaged.release() }
        var context = FSEventStreamContext(version: 0, info: unmanaged.toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let stream = try #require(FSEventStreamCreate(nil, { _, info, count, paths, _, _ in
            let paths = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
            guard let info, paths.prefix(count).contains(where: { $0.hasSuffix("/.events-settled") }) else { return }
            Unmanaged<Marker>.fromOpaque(info).takeUnretainedValue().finish(true)
        }, &context, [root.path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)))
        FSEventStreamSetDispatchQueue(stream, DispatchQueue(label: "TagCatalogTests.settle"))
        defer { FSEventStreamStop(stream); FSEventStreamInvalidate(stream); FSEventStreamRelease(stream) }
        #expect(FSEventStreamStart(stream))
        let delivered = await withCheckedContinuation { continuation in
            marker.lock.lock(); marker.continuation = continuation; marker.lock.unlock()
            do { try Data().write(to: root.appendingPathComponent(".events-settled")) } catch { marker.finish(false) }
            DispatchQueue.global().asyncAfter(deadline: .now() + 8) { marker.finish(false) }
        }
        #expect(delivered, "The fixture's file events were not delivered")
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
    private(set) var count = 0
    private var arrived = false
    private var opened = false
    private var arrivals: [CheckedContinuation<Void, Never>] = []
    private var blocked: [CheckedContinuation<Void, Never>] = []
    func waitForArrival() async {
        if arrived { return }
        await withCheckedContinuation { arrivals.append($0) }
    }
    func arriveAndWait() async {
        count += 1
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
    private(set) var yields = 0
    private(set) var recordCount = 0
    private(set) var maximumBatch = 0
    private(set) var publications = 0
    func yielded() { yields += 1 }
    func published(_ batch: TaggedFileScanner.Batch) {
        publications += 1
        recordCount += batch.count
        maximumBatch = max(maximumBatch, batch.count)
    }
}
