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

        let firstFolder = try await service.createFolder(in: root)
        let secondFolder = try await service.createFolder(in: root)
        #expect(firstFolder.lastPathComponent == "Untitled Folder")
        #expect(secondFolder.lastPathComponent == "Untitled Folder 2")

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
                state.primarySelection?.name == "Untitled Folder",
                "New folder was not selected in \(viewMode.rawValue) view"
            )
            #expect(
                state.renamingItemID == state.primarySelection?.id,
                "Rename state was not assigned in \(viewMode.rawValue) view"
            )
            #expect(
                state.renameDraft == "Untitled Folder",
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

    @Test("Drag modifiers resolve to Finder-style file operations")
    func dragModifierOperations() {
        #expect(BrowserFileDropOperationResolver.operation(for: []) == .automatic)
        #expect(BrowserFileDropOperationResolver.operation(for: [.option]) == .copy)
        #expect(BrowserFileDropOperationResolver.operation(for: [.command]) == .move)
        #expect(
            BrowserFileDropOperationResolver.operation(for: [.option, .command]) == .alias
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

    var body: some View {
        BrowserContent(state: state, contentFocus: $browserFocus)
    }
}
