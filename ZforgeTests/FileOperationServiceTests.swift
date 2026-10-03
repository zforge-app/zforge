import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

@Suite("File operations")
struct FileOperationServiceTests {
    @Test("Creates unique folders and Finder aliases")
    func foldersAndAliases() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let service = FileOperationService()

        let english = Locale(identifier: "en")
        let firstFolder = try await service.createFolder(in: root, locale: english)
        let secondFolder = try await service.createFolder(in: root, locale: english)
        #expect(firstFolder.lastPathComponent == "untitled folder")
        #expect(secondFolder.lastPathComponent == "untitled folder 2")

        let source = root.appendingPathComponent("Document.txt")
        try Data("Zforge".utf8).write(to: source)
        let aliases = try await service.createAliases(for: [source], in: root)
        let alias = try #require(aliases.first)
        #expect(FileManager.default.fileExists(atPath: alias.path))
        #expect(
            try await service.aliasTarget(for: alias)
                == source.standardizedFileURL.resolvingSymlinksInPath()
        )
    }

    @Test("Copies and moves dropped files with collision-safe names")
    func transfers() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        let service = FileOperationService()

        let source = root.appendingPathComponent("Document.txt")
        try Data("Zforge".utf8).write(to: source)
        let copied = try await service.transfer([source], to: destination, operation: .copy)
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(copied.first?.lastPathComponent == "Document.txt")

        let moved = try await service.transfer([source], to: destination, operation: .move)
        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(moved.first?.lastPathComponent == "Document.txt 2")
    }

    @Test("Default same-directory drags do not copy files or folders through alternate URL spellings")
    func sameDirectoryDragDoesNothing() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Document.pdf")
        let folder = root.appendingPathComponent("Folder", isDirectory: true)
        try Data("original".utf8).write(to: source)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        let link = root.appendingPathComponent("Link", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root)
        let service = FileOperationService()
        for destination in [URL(fileURLWithPath: root.path, isDirectory: false), link] {
            for operation in [BrowserFileTransferOperation.automatic, .move] {
                let result = try await service.transfer([source, folder], to: destination, operation: operation)
                #expect(result == [source.standardizedFileURL, folder.standardizedFileURL])
                #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()
                        == ["Document.pdf", "Folder", "Link"])
                #expect(try Data(contentsOf: source) == Data("original".utf8))
            }
        }
        // Explicit copy remains available for Option-drag / paste / duplicate.
        let copied = try await service.transfer([source], to: link, operation: .copy)
        #expect(copied.count == 1 && copied[0].lastPathComponent != source.lastPathComponent)
        #expect(try Data(contentsOf: copied[0]) == Data("original".utf8))
    }

    @Test("Renames an item and rejects invalid names")
    func renaming() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let service = FileOperationService()
        let source = root.appendingPathComponent("Original.txt")
        try Data("Zforge".utf8).write(to: source)

        let renamed = try await service.rename(source, to: "Renamed.txt")
        #expect(renamed.lastPathComponent == "Renamed.txt")
        #expect(FileManager.default.fileExists(atPath: renamed.path))
        #expect(!FileManager.default.fileExists(atPath: source.path))

        await #expect(throws: BrowserFileOperationError.invalidName) {
            try await service.rename(renamed, to: "Invalid/Name")
        }
    }

    @Test("A newly created folder immediately enters rename mode")
    @MainActor
    func newFolderStartsRenaming() async throws {
        for viewMode in BrowserViewMode.allCases {
            let root = try makeTemporaryDirectory()
            defer { try? FileManager.default.removeItem(at: root) }
            let suiteName = "ZforgeRenameTest-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suiteName))
            defer { defaults.removePersistentDomain(forName: suiteName) }
            let preferences = FileBrowserPreferences(defaults: defaults)
            preferences.viewMode = viewMode
            preferences.language = .english
            let state = FileBrowserState(
                preferences: preferences,
                fileSystem: FileSystemService(),
                fileOperations: FileOperationService(),
                grants: UIFixtureAccessGrantStore(),
                archives: UIFixtureArchiveEngine()
            )
            await state.navigateToSidebar(root, name: root.lastPathComponent)

            let controller = NSHostingController(rootView: RenameBrowserHarness(state: state))
            let window = NSWindow(contentViewController: controller)
            window.setContentSize(NSSize(width: 760, height: 520))
            window.makeKeyAndOrderFront(nil)

            state.createNewFolder()
            for _ in 0..<100 where state.renamingItemID == nil || !(window.firstResponder is NSTextView) {
                try await Task.sleep(for: .milliseconds(10))
            }

            #expect(
                state.primarySelection?.name == "untitled folder",
                "New folder was not selected in \(viewMode.rawValue) view"
            )
            #expect(
                state.renamingItemID == state.primarySelection?.id,
                "Rename state was not assigned in \(viewMode.rawValue) view"
            )
            #expect(
                state.renameDraft == "untitled folder",
                "Rename draft was not populated in \(viewMode.rawValue) view"
            )
            #expect(
                window.firstResponder is NSTextView,
                "Rename editor did not receive focus in \(viewMode.rawValue) view"
            )
            window.close()
        }
    }

    @Test("Copy providers preserve the original file URL for move operations")
    @MainActor
    func copyProviderPreservesOriginalURL() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Document.txt")
        try Data("Zforge".utf8).write(to: source)
        let fileSystem = FileSystemService()
        let item = try await fileSystem.item(at: source)
        let state = FileBrowserState()
        state.items = [item]
        state.select(item)

        let provider = try #require(state.copyItemProviders().first)
        let providedURL: URL? = await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSURL.self) { object, _ in
                continuation.resume(returning: (object as? NSURL).map { $0 as URL })
            }
        }

        #expect(providedURL?.standardizedFileURL == source.standardizedFileURL)
    }

    @Test("Command-V copies and Option-Command-V moves the original Clipboard URL")
    @MainActor
    func pasteCopiesAndMoveRemovesSource() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sources = root.appendingPathComponent("Sources", isDirectory: true)
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        let copySource = sources.appendingPathComponent("Copy.txt")
        let moveSource = sources.appendingPathComponent("Move.txt")
        try Data("Copy".utf8).write(to: copySource)
        try Data("Move".utf8).write(to: moveSource)

        let suiteName = "ZforgePasteTest-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.navigateToSidebar(destination, name: destination.lastPathComponent)

        state.pasteItemProviders([NSItemProvider(object: copySource as NSURL)])
        let copiedURL = destination.appendingPathComponent(copySource.lastPathComponent)
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: copiedURL.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: copySource.path))
        #expect(FileManager.default.fileExists(atPath: copiedURL.path))

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        await state.navigateToSidebar(sources, name: sources.lastPathComponent)
        let moveItem = try #require(state.items.first(where: {
            $0.localURL?.standardizedFileURL == moveSource.standardizedFileURL
        }))
        state.select(moveItem)
        #expect(state.copySelectionToPasteboard(pasteboard))

        let clipboardURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL]
        #expect(clipboardURLs?.map(\.standardizedFileURL) == [moveSource.standardizedFileURL])

        await state.navigateToSidebar(destination, name: destination.lastPathComponent)
        state.moveClipboardItemsHere()
        let movedURL = destination.appendingPathComponent(moveSource.lastPathComponent)
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: movedURL.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!FileManager.default.fileExists(atPath: moveSource.path))
        #expect(FileManager.default.fileExists(atPath: movedURL.path))
    }

    @Test("Paste shows progress until the file transfer finishes")
    @MainActor
    func pasteShowsProgressUntilTransferFinishes() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Document.txt")
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        try Data("Zforge".utf8).write(to: source)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)

        let suiteName = "ZforgePasteProgressTest-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let fileOperations = SuspendedTransferFileOperationService()
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: fileOperations,
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.navigateToSidebar(destination, name: destination.lastPathComponent)

        state.pasteItemProviders([NSItemProvider(object: source as NSURL)])
        for _ in 0..<100 {
            if await fileOperations.transferStarted() { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(await fileOperations.transferStarted())
        #expect(state.fileOperationInProgress)
        #expect(state.fileOperationDescription == "Copying items…")

        await fileOperations.finishTransfer()
        for _ in 0..<100 where state.fileOperationInProgress {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!state.fileOperationInProgress)
        #expect(state.fileOperationDescription.isEmpty)
    }

    @Test("Column paste targets the active column instead of its open child")
    @MainActor
    func columnPasteTargetsActiveColumn() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Codex", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: false)
        try Data("Zforge".utf8).write(to: source.appendingPathComponent("README.txt"))

        let suiteName = "ZforgeColumnPasteTest-\(UUID().uuidString)"
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
        let rootLocation = state.location
        let sourceItem = try #require(state.items.first(where: { $0.name == "Codex" }))
        await state.activateColumnItem(sourceItem, in: rootLocation).value

        #expect(state.location == .fileSystem(try #require(sourceItem.localURL)))
        #expect(state.activeColumnLocation == rootLocation)
        #expect(state.fileOperationDestinationURL == root.standardizedFileURL)

        state.pasteItemProviders([NSItemProvider(object: source as NSURL)])
        let copy = root.appendingPathComponent("Codex copy", isDirectory: true)
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: copy.path) {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(FileManager.default.fileExists(atPath: copy.path))
        #expect(FileManager.default.fileExists(
            atPath: copy.appendingPathComponent("README.txt").path
        ))
        #expect(!FileManager.default.fileExists(
            atPath: source.appendingPathComponent("Codex").path
        ))
        for _ in 0..<100 where state.columnItems[rootLocation]?.contains(where: {
            $0.name == "Codex copy"
        }) != true {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(state.columnItems[rootLocation]?.contains(where: { $0.name == "Codex copy" }) == true)
    }

    @Test("Drag modifiers resolve to Finder-style file operations")
    @MainActor
    func dragModifierOperations() {
        #expect(BrowserFileDropOperationResolver.operation(for: []) == .automatic)
        #expect(BrowserFileDropOperationResolver.operation(for: [.option]) == .copy)
        #expect(BrowserFileDropOperationResolver.operation(for: [.command]) == .move)
        #expect(
            BrowserFileDropOperationResolver.operation(for: [.option, .command]) == .alias
        )

        let session = BrowserFileDragSession()
        session.modifiers = [.option]
        #expect(BrowserFileDropOperationResolver.operation(for: session.modifiers) == .copy)
        session.modifiers = [.option, .command]
        #expect(BrowserFileDropOperationResolver.operation(for: session.modifiers) == .alias)

    }

    @Test("The default drag proposal does not advertise a copy")
    func defaultDragProposalDoesNotShowCopyIndicator() {
        #expect(
            BrowserFileDropProposalResolver.operation(for: .automatic) == .move
        )
        #expect(
            BrowserFileDropProposalResolver.operation(for: .copy) == .copy
        )
        #expect(
            BrowserFileDropProposalResolver.operation(for: .move) == .move
        )
        #expect(
            BrowserFileDropProposalResolver.operation(for: .alias) == .alias
        )
    }

    @Test("Dropped providers copy files and create aliases")
    @MainActor
    func droppedProvidersTransferFiles() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Dropped.txt")
        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        try Data("Zforge".utf8).write(to: source)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)

        let suiteName = "ZforgeDropTest-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let draggedItem = try #require(state.items.first(where: {
            $0.localURL?.standardizedFileURL == source.standardizedFileURL
        }))

        #expect(
            state.performDrop(
                providers: [try #require(state.itemProvider(for: draggedItem))],
                to: destination,
                operation: .copy
            )
        )
        let copy = destination.appendingPathComponent("Dropped.txt")
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: copy.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: copy.path))

        #expect(
            state.performDrop(
                providers: [try #require(state.itemProvider(for: draggedItem))],
                to: destination,
                operation: .alias
            )
        )
        let alias = destination.appendingPathComponent("Dropped.txt alias")
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: alias.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: alias.path))
        #expect(
            try await FileOperationService().aliasTarget(for: alias)
                == source.standardizedFileURL.resolvingSymlinksInPath()
        )
    }

    @Test("Localizes the default folder name in the requested locale")
    func localizedDefaultFolderName() throws {
        let appBundle = try #require(Self.applicationBundle)
        let folderName = AppLocalization.string(
            "untitled folder",
            locale: Locale(identifier: "pt-BR"),
            bundle: appBundle
        )

        #expect(folderName == "pasta sem título")
    }

    private static var applicationBundle: Bundle? {
        let testBundle = Bundle.main
        let siblingAppBundleURL = testBundle.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let candidates = [
            testBundle,
            Bundle(url: siblingAppBundleURL)
        ].compactMap { $0 }
        return candidates.first {
            $0.path(forResource: "pt-BR", ofType: "lproj") != nil
        }
    }

    @Test("Command-Z undo records reverse creation, rename, and copy")
    @MainActor
    func undoReversesFileOperations() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let suiteName = "ZforgeUndoTest-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        let undoManager = UndoManager()
        state.configureUndoManager(undoManager)
        await state.navigateToSidebar(root, name: root.lastPathComponent)

        state.createNewFolder()
        let folder = root.appendingPathComponent("untitled folder", isDirectory: true)
        for _ in 0..<100 where !undoManager.canUndo {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: folder.path))
        #expect(undoManager.canUndo)
        state.cancelRenaming()
        undoManager.undo()
        for _ in 0..<100 where FileManager.default.fileExists(atPath: folder.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!FileManager.default.fileExists(atPath: folder.path))

        let source = root.appendingPathComponent("Original.txt")
        try Data("Zforge".utf8).write(to: source)
        await state.reload()
        for _ in 0..<100 where !state.items.contains(where: {
            $0.localURL?.standardizedFileURL == source.standardizedFileURL
        }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        let sourceItem = try #require(state.items.first(where: {
            $0.localURL?.standardizedFileURL == source.standardizedFileURL
        }))
        state.beginRenaming(sourceItem)
        state.renameDraft = "Renamed.txt"
        state.commitRename()
        let renamed = root.appendingPathComponent("Renamed.txt")
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: renamed.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        for _ in 0..<100 where state.renameInProgress {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(undoManager.canUndo)
        undoManager.undo()
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: source.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(!FileManager.default.fileExists(atPath: renamed.path))

        let destination = root.appendingPathComponent("Destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        await state.reload()
        for _ in 0..<100 where !state.items.contains(where: {
            $0.localURL?.standardizedFileURL == source.standardizedFileURL
        }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        let draggedItem = try #require(state.items.first(where: {
            $0.localURL?.standardizedFileURL == source.standardizedFileURL
        }))
        #expect(
            state.performDrop(
                providers: [try #require(state.itemProvider(for: draggedItem))],
                to: destination,
                operation: .copy
            )
        )
        let copy = destination.appendingPathComponent("Original.txt")
        for _ in 0..<100 where !FileManager.default.fileExists(atPath: copy.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        for _ in 0..<100 where !undoManager.canUndo {
            try await Task.sleep(for: .milliseconds(10))
        }
        undoManager.undo()
        for _ in 0..<100 where FileManager.default.fileExists(atPath: copy.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(!FileManager.default.fileExists(atPath: copy.path))
    }

    @Test("Permanent deletion waits for confirmation and cannot be undone")
    @MainActor
    func permanentDeletionRequiresConfirmation() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Delete.txt")
        try Data("Zforge".utf8).write(to: source)
        let suiteName = "ZforgePermanentDeletionTest-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let state = FileBrowserState(
            preferences: preferences,
            fileSystem: FileSystemService(),
            fileOperations: FileOperationService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        let undoManager = UndoManager()
        state.configureUndoManager(undoManager)
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let item = try #require(state.items.first(where: { $0.name == "Delete.txt" }))
        state.select(item)

        state.requestPermanentDeletion()

        #expect(
            state.pendingPermanentDeletion?.urls.map(\.standardizedFileURL)
                == [source.standardizedFileURL]
        )
        #expect(FileManager.default.fileExists(atPath: source.path))

        state.confirmPermanentDeletion()
        for _ in 0..<100 where FileManager.default.fileExists(atPath: source.path) {
            try await Task.sleep(for: .milliseconds(10))
        }
        for _ in 0..<100 where state.fileOperationInProgress {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(state.pendingPermanentDeletion == nil)
        #expect(!undoManager.canUndo)
        #expect(!state.fileOperationInProgress)
        #expect(state.fileOperationDescription.isEmpty)
    }

    @Test("Permanent deletion keyboard selection starts on Cancel")
    func permanentDeletionKeyboardSelection() {
        for direction in [
            PermanentDeletionConfirmationDirection.left,
            .right,
            .up,
            .down
        ] {
            #expect(
                PermanentDeletionConfirmationNavigation.nextChoice(
                    after: nil,
                    moving: direction
                ) == .cancel
            )
        }

        #expect(
            PermanentDeletionConfirmationNavigation.nextChoice(
                after: .cancel,
                moving: .right
            ) == .delete
        )
        #expect(
            PermanentDeletionConfirmationNavigation.nextChoice(
                after: .cancel,
                moving: .down
            ) == .delete
        )
        #expect(
            PermanentDeletionConfirmationNavigation.nextChoice(
                after: .delete,
                moving: .left
            ) == .cancel
        )
        #expect(
            PermanentDeletionConfirmationNavigation.nextChoice(
                after: .delete,
                moving: .up
            ) == .cancel
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeFileOperations-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }
}

@MainActor
private struct RenameBrowserHarness: View {
    @Bindable var state: FileBrowserState
    @FocusState private var browserFocus: BrowserFocusTarget?
    @State private var dragSession = BrowserFileDragSession()

    var body: some View {
        BrowserContent(
            state: state,
            contentFocus: $browserFocus,
            dragSession: dragSession
        )
    }
}

private actor SuspendedTransferFileOperationService: FileOperationServing {
    private let service = FileOperationService()
    private var didStartTransfer = false
    private var transferContinuation: CheckedContinuation<Void, Never>?

    func createFolder(in directory: URL, locale: Locale?) async throws -> URL {
        try await service.createFolder(in: directory, locale: locale)
    }

    func rename(_ sourceURL: URL, to newName: String) async throws -> URL {
        try await service.rename(sourceURL, to: newName)
    }

    func createAliases(for sourceURLs: [URL], in directory: URL) async throws -> [URL] {
        try await service.createAliases(for: sourceURLs, in: directory)
    }

    func transfer(
        _ sourceURLs: [URL],
        to directory: URL,
        operation: BrowserFileTransferOperation
    ) async throws -> [URL] {
        await withCheckedContinuation { continuation in
            didStartTransfer = true
            transferContinuation = continuation
        }
        return []
    }

    func aliasTarget(for url: URL) async throws -> URL? {
        try await service.aliasTarget(for: url)
    }

    func removeItems(at urls: [URL]) async throws {
        try await service.removeItems(at: urls)
    }

    func moveItems(_ moves: [BrowserExactFileMove]) async throws {
        try await service.moveItems(moves)
    }

    func transferStarted() -> Bool {
        didStartTransfer
    }

    func finishTransfer() {
        transferContinuation?.resume()
        transferContinuation = nil
    }
}
