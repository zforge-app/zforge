import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("New folder with selection", .serialized)
struct FolderWithSelectionTests {
    @Test("Groups selected files and folders without changing unselected items or colliding names")
    func groupsSelectedItems() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let existing = root.appendingPathComponent("untitled folder", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: false)
        let service = FileOperationService()

        let result = try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))

        #expect(result.folderURL.lastPathComponent == "untitled folder 2")
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
                == ["Unselected.txt", "untitled folder", "untitled folder 2"])
        #expect(try Data(contentsOf: result.folderURL.appendingPathComponent("Document.txt")) == Data("document".utf8))
        #expect(try Data(contentsOf: result.folderURL.appendingPathComponent("Folder/Child.txt")) == Data("child".utf8))
        #expect(try Data(contentsOf: root.appendingPathComponent("Unselected.txt")) == Data("unselected".utf8))
    }

    @Test("A failed move restores completed moves and removes the empty new folder")
    func failedMoveRestoresSources() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService(fileManager: FailingSelectionFileManager(failingMoves: [2]))

        await #expect(throws: (any Error).self) {
            try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
        }

        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
                == ["Document.txt", "Folder", "Unselected.txt"])
        #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
        #expect(try Data(contentsOf: sources[1].appendingPathComponent("Child.txt")) == Data("child".utf8))
    }

    @Test("A failed recovery preserves the new folder and every surviving original")
    func failedRecoveryPreservesFiles() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService(fileManager: FailingSelectionFileManager(failingMoves: [2, 3]))

        await #expect(throws: (any Error).self) {
            try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
        }

        let created = root.appendingPathComponent("untitled folder", isDirectory: true)
        #expect(try Data(contentsOf: created.appendingPathComponent("Document.txt")) == Data("document".utf8))
        #expect(try Data(contentsOf: sources[1].appendingPathComponent("Child.txt")) == Data("child".utf8))
        #expect(FileManager.default.fileExists(atPath: created.path))
    }

    @Test("Cancellation after the first move restores the complete selection")
    func cancellationRestoresSelection() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService(fileManager: CancellingSelectionFileManager())
        let operation = Task {
            try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
        }
        await #expect(throws: CancellationError.self) { try await operation.value }
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
                == ["Document.txt", "Folder", "Unselected.txt"])
        #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
        #expect(try Data(contentsOf: sources[1].appendingPathComponent("Child.txt")) == Data("child".utf8))
    }

    @Test("Groups and restores 1000 files while recording the local move baseline")
    func largeSelectionWorkload() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try (0..<1000).map { index in
            let url = root.appendingPathComponent("Item-\(index).txt")
            try Data("fixture-\(index)".utf8).write(to: url)
            return url
        }
        let baseline = root.appendingPathComponent("Baseline", isDirectory: true)
        try FileManager.default.createDirectory(at: baseline, withIntermediateDirectories: false)
        let service = FileOperationService()
        let clock = ContinuousClock()
        for iteration in 1...3 {
            let moveStart = clock.now
            let destinations = try await service.transfer(sources, to: baseline, operation: .move)
            let moveDuration = moveStart.duration(to: clock.now)
            try await service.moveItems(zip(destinations, sources).map {
                BrowserExactFileMove(sourceURL: $0.0, destinationURL: $0.1)
            })
            let groupStart = clock.now
            let folder = try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
            let groupDuration = groupStart.duration(to: clock.now)
            #expect(try FileManager.default.contentsOfDirectory(atPath: folder.folderURL.path).count == 1000)
            try await service.setSelectionFolder(folder, grouped: false)
            #expect(!FileManager.default.fileExists(atPath: folder.folderURL.path))
            for (index, url) in sources.enumerated() {
                #expect(try Data(contentsOf: url) == Data("fixture-\(index)".utf8))
            }
            print("Folder selection workload \(iteration): baseline=\(moveDuration), grouping=\(groupDuration), files=1000")
        }
    }

    @Test("Missing, duplicate, and differently parented sources are rejected before creating a folder")
    func invalidSourcesDoNotCreateFolder() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService()
        for invalid in [[URL](), [sources[0], sources[0]], [sources[1].appendingPathComponent("Child.txt")],
                        [root.appendingPathComponent("Missing.txt")]] {
            await #expect(throws: (any Error).self) {
                try await service.createFolder(containing: invalid, in: root, locale: Locale(identifier: "en"))
            }
            #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("untitled folder").path))
            #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
        }
    }

    @Test("Undo and redo restore exact paths and reject collisions without moving any item")
    func reversibleGroupingAndConflicts() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService()
        let result = try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
        try Data("conflict".utf8).write(to: sources[1])

        await #expect(throws: BrowserFileOperationError.selectionFolderDestinationExists("Folder")) {
            try await service.setSelectionFolder(result, grouped: false)
        }
        #expect(!FileManager.default.fileExists(atPath: sources[0].path))
        #expect(try Data(contentsOf: result.folderURL.appendingPathComponent("Document.txt")) == Data("document".utf8))
        #expect(try Data(contentsOf: sources[1]) == Data("conflict".utf8))
        try FileManager.default.removeItem(at: sources[1])

        try await service.setSelectionFolder(result, grouped: false)
        #expect(!FileManager.default.fileExists(atPath: result.folderURL.path))
        #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
        #expect(try Data(contentsOf: sources[1].appendingPathComponent("Child.txt")) == Data("child".utf8))

        try await service.setSelectionFolder(result, grouped: true)
        #expect(!FileManager.default.fileExists(atPath: sources[0].path))
        #expect(try Data(contentsOf: result.folderURL.appendingPathComponent("Document.txt")) == Data("document".utf8))
        try await service.setSelectionFolder(result, grouped: false)
        try FileManager.default.createDirectory(at: result.folderURL, withIntermediateDirectories: false)
        await #expect(throws: BrowserFileOperationError.selectionFolderDestinationExists("untitled folder")) {
            try await service.setSelectionFolder(result, grouped: true)
        }
        #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
    }

    @Test("Undo never deletes content added after grouping")
    func undoPreservesAddedContent() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let service = FileOperationService()
        let result = try await service.createFolder(containing: sources, in: root, locale: Locale(identifier: "en"))
        let added = result.folderURL.appendingPathComponent("Added.txt")
        try Data("added".utf8).write(to: added)
        await #expect(throws: (any Error).self) { try await service.setSelectionFolder(result, grouped: false) }
        #expect(try Data(contentsOf: added) == Data("added".utf8))
        #expect(try Data(contentsOf: result.folderURL.appendingPathComponent("Document.txt")) == Data("document".utf8))
        #expect(!FileManager.default.fileExists(atPath: sources[0].path))
    }

    @Test("All four modes select the grouped folder and start inline rename", arguments: BrowserViewMode.allCases)
    @MainActor
    func groupingSelectsFolderAndRenames(mode: BrowserViewMode) async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let state = makeState(mode: mode)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        for (index, source) in sources.enumerated() {
            let item = try #require(state.items.first(where: { $0.localURL?.path == source.path }))
            state.select(item, modifiers: index == 0 ? [] : [.command])
        }
        #expect(state.canCreateFolderWithSelection)

        let operation = try #require(state.createNewFolderWithSelection())
        #expect(state.fileOperationInProgress)
        #expect(!state.canCreateFolderWithSelection)
        await operation.value

        #expect(!state.fileOperationInProgress)
        #expect(state.primarySelection?.name == "untitled folder")
        #expect(state.renamingItemID == state.primarySelection?.id)
        #expect(state.renameDraft == "untitled folder")
        #expect(state.error == nil)
        #expect(try Data(contentsOf: root.appendingPathComponent("untitled folder/Document.txt")) == Data("document".utf8))
    }

    @Test("Selection grouping is disabled without eligible local siblings or while busy")
    @MainActor
    func groupingEligibility() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let state = makeState(mode: .list)
        defer { state.close() }
        #expect(!state.canCreateFolderWithSelection)
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        #expect(!state.canCreateFolderWithSelection)
        let folder = try #require(state.items.first(where: { $0.name == "Folder" }))
        await state.toggleExpansion(folder)
        let child = try #require(state.flattenedItems().first(where: { $0.name == "Child.txt" }))
        let document = try #require(state.items.first(where: { $0.name == "Document.txt" }))
        state.select(document)
        state.select(child, modifiers: [.command], orderedItems: state.flattenedItems())
        #expect(!state.canCreateFolderWithSelection)
        #expect(state.createNewFolderWithSelection() == nil)
        #expect(FileManager.default.fileExists(atPath: sources[0].path))
        state.select(document)
        #expect(state.canCreateFolderWithSelection)
        state.fileOperationInProgress = true
        #expect(!state.canCreateFolderWithSelection)
        state.fileOperationInProgress = false
        state.archiveOperationInProgress = true
        #expect(!state.canCreateFolderWithSelection)
        state.archiveOperationInProgress = false
        state.renameInProgress = true
        #expect(!state.canCreateFolderWithSelection)
        state.renameInProgress = false
        await state.navigateToRecents()
        #expect(!state.canCreateFolderWithSelection)
    }

    @Test("An open Columns folder groups in its selected parent and removes obsolete child columns")
    @MainActor
    func groupingOpenedColumnFolder() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try makeSources(in: root)
        let state = makeState(mode: .columns)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let rootLocation = state.location
        let folder = try #require(state.items.first(where: { $0.name == "Folder" }))
        await state.activateColumnItem(folder, in: rootLocation).value
        #expect(state.canCreateFolderWithSelection)

        try await #require(state.createNewFolderWithSelection()).value

        #expect(state.location == rootLocation)
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.columnItems[folder.location] == nil)
        #expect(state.primarySelection?.name == "untitled folder")
        #expect(state.renamingItemID == state.primarySelection?.id)
        #expect(state.error == nil)
    }

    @Test("Undo and redo retain grouping after renaming its folder")
    @MainActor
    func groupingUndoRedoAfterRename() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = try makeSources(in: root)
        let state = makeState(mode: .icons)
        defer { state.close() }
        let manager = UndoManager()
        manager.groupsByEvent = false
        state.configureUndoManager(manager)
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        state.select(try #require(state.items.first(where: { $0.name == "Document.txt" })))
        manager.beginUndoGrouping()
        try await #require(state.createNewFolderWithSelection()).value
        manager.endUndoGrouping()
        manager.beginUndoGrouping()
        state.renameDraft = "Grouped"
        state.commitRename()
        try await waitUntil { !state.renameInProgress }
        manager.endUndoGrouping()

        manager.undo()
        await state.fileUndoTask?.value
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("untitled folder/Document.txt").path))
        manager.undo()
        await state.fileUndoTask?.value
        #expect(try Data(contentsOf: sources[0]) == Data("document".utf8))
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("untitled folder").path))
        #expect(manager.canRedo)
        manager.redo()
        await state.fileUndoTask?.value
        manager.redo()
        await state.fileUndoTask?.value
        #expect(try Data(contentsOf: root.appendingPathComponent("Grouped/Document.txt")) == Data("document".utf8))
        #expect(!FileManager.default.fileExists(atPath: sources[0].path))
        #expect(state.error == nil)
    }

    @Test("Navigation during a pending refresh does not publish a stale rename or selection")
    @MainActor
    func navigationDuringGroupingRefresh() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try makeSources(in: root)
        let other = root.appendingPathComponent("Other", isDirectory: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: false)
        let fileSystem = SuspendedGroupingRefreshFileSystem(root: root)
        let state = makeState(mode: .icons, fileSystem: fileSystem)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        state.select(try #require(state.items.first(where: { $0.name == "Document.txt" })))

        let operation = try #require(state.createNewFolderWithSelection())
        #expect(state.createNewFolderWithSelection() == nil)
        await fileSystem.waitForRefresh()
        await state.navigateToSidebar(other, name: other.lastPathComponent)
        await fileSystem.finishRefresh()
        await operation.value

        #expect(state.location == .fileSystem(other))
        #expect(state.renamingItemURL == nil)
        #expect(state.selection.isEmpty)
        #expect(!state.fileOperationInProgress)
        #expect(try Data(contentsOf: root.appendingPathComponent("untitled folder/Document.txt")) == Data("document".utf8))
    }

    private func makeDirectory() throws -> URL {
        let result = FileManager.default.temporaryDirectory.appendingPathComponent("FolderSelection-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: result, withIntermediateDirectories: false)
        return result
    }

    private func makeSources(in root: URL) throws -> [URL] {
        let document = root.appendingPathComponent("Document.txt")
        let folder = root.appendingPathComponent("Folder", isDirectory: true)
        try Data("document".utf8).write(to: document)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        try Data("child".utf8).write(to: folder.appendingPathComponent("Child.txt"))
        try Data("unselected".utf8).write(to: root.appendingPathComponent("Unselected.txt"))
        return [document, folder]
    }

    @MainActor
    private func makeState(mode: BrowserViewMode, fileSystem: any FileSystemServing = FileSystemService()) -> FileBrowserState {
        let defaults = UserDefaults(suiteName: "ZforgeTestSuite.FolderSelectionPreferences-\(UUID().uuidString)")!
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = mode
        preferences.language = .english
        return FileBrowserState(preferences: preferences, fileSystem: fileSystem,
                                fileOperations: FileOperationService(), recentItems: UIFixtureRecentItemsService(),
                                taggedItems: UIFixtureTaggedItemsService(), grants: UIFixtureAccessGrantStore(),
                                archives: UIFixtureArchiveEngine())
    }

    @MainActor
    private func waitUntil(_ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while !predicate(), ContinuousClock.now < deadline { await Task.yield() }
        #expect(predicate(), "The file operation did not complete before the deadline")
    }
}

private actor SuspendedGroupingRefreshFileSystem: FileSystemServing {
    private let service = FileSystemService()
    private let root: URL
    private var refreshStarted = false
    private var refreshFinished = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var refreshWaiters: [CheckedContinuation<Void, Never>] = []

    init(root: URL) { self.root = root }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        let result = try await service.items(in: directory, showHidden: showHidden)
        if directory == root, result.contains(where: { $0.name == "untitled folder" }), !refreshFinished {
            await withCheckedContinuation { continuation in
                refreshStarted = true
                refreshWaiters.append(continuation)
                startWaiters.forEach { $0.resume() }
                startWaiters.removeAll()
            }
        }
        return result
    }

    func waitForRefresh() async {
        if refreshStarted { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func finishRefresh() {
        refreshFinished = true
        refreshWaiters.forEach { $0.resume() }
        refreshWaiters.removeAll()
    }

    func item(at url: URL) async throws -> BrowserItem { try await service.item(at: url) }
    func recursiveSize(at url: URL) async throws -> Int64 { try await service.recursiveSize(at: url) }
    func resolveNavigationURL(_ url: URL) async throws -> URL { try await service.resolveNavigationURL(url) }
}

private final class FailingSelectionFileManager: FileManager {
    private var moveCount = 0
    private let failingMoves: Set<Int>

    init(failingMoves: Set<Int>) {
        self.failingMoves = failingMoves
        super.init()
    }

    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        moveCount += 1
        if failingMoves.contains(moveCount) { throw NSError(domain: "FolderSelectionFixture", code: moveCount) }
        try super.moveItem(at: srcURL, to: dstURL)
    }
}

private final class CancellingSelectionFileManager: FileManager {
    private var hasCancelled = false

    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try super.moveItem(at: srcURL, to: dstURL)
        if !hasCancelled {
            hasCancelled = true
            withUnsafeCurrentTask { $0?.cancel() }
        }
    }
}
