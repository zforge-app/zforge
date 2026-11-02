import AppKit
import Foundation
import Testing
import SwiftUI
@testable import Zforge

@Suite("Archive removal and outbound drag")
struct ArchiveMutationTests {
    @Test("Deletion rewrites ZIP/7z, preserves survivors and opens an empty archive",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip], [false, true])
    func deletion(format: ArchiveCompressionFormat, encrypted: Bool) async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let keep = root.appendingPathComponent("Keep.txt")
        let removed = root.appendingPathComponent("Remove", isDirectory: true)
        let similar = root.appendingPathComponent("RemoveOther.txt")
        try FileManager.default.createDirectory(at: removed, withIntermediateDirectories: true)
        try Data("keep".utf8).write(to: keep)
        try Data("child".utf8).write(to: removed.appendingPathComponent("Child.txt"))
        try Data("similar".utf8).write(to: similar)
        let archive = root.appendingPathComponent("Target.\(format.fileExtension)")
        var options = CompressionOptions(format: format)
        options.requiresPassword = encrypted
        options.encryptFileNames = encrypted && format == .sevenZip
        let password = encrypted ? "Test password" : nil
        try await engine.createArchive(from: [keep, removed, similar], outputURL: archive,
            options: options, password: password, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: password)
        let items = try await engine.items(at: opened.address)
        let folder = try #require(items.first(where: { $0.name == "Remove" }))
        let before = try Data(contentsOf: archive)
        if encrypted {
            // Never rely on the cached session password to test a wrong explicit password.
            await #expect(throws: (any Error).self) {
                try await engine.removeItems([folder], password: "wrong", progress: { _ in })
            }
            #expect(try Data(contentsOf: archive) == before)
        }
        try await engine.removeItems([folder], password: password, progress: { _ in })
        let refreshed = try await engine.openArchive(at: archive, password: password)
        let surviving = try await engine.items(at: refreshed.address)
        #expect(Set(surviving.map(\.name)) == ["Keep.txt", "RemoveOther.txt"])
        let kept = try #require(surviving.first(where: { $0.name == "Keep.txt" }))
        let extracted = try await engine.materialize(item: kept, purpose: .preview, automaticLimit: 1024)
        #expect(try String(contentsOf: extracted, encoding: .utf8) == "keep")
        try await engine.removeItems(surviving, password: password, progress: { _ in })
        try await engine.testArchive(at: archive, password: password)
        let empty = try await engine.openArchive(at: archive, password: password)
        #expect(try await engine.items(at: empty.address).isEmpty)
        await engine.closeAllSessions()
    }

    @Test("Outbound copy is non-mutating; move publishes then removes and restores inline tree",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip], [false, true])
    @MainActor
    func outboundTransfer(format: ArchiveCompressionFormat, moving: Bool) async throws {
        try await runOutboundTransfer(format: format, moving: moving, encrypted: false)
    }

    @Test("File promises fulfill before drag end and remove sources only after acceptance",
          arguments: [false, true])
    @MainActor
    func outboundPromises(moving: Bool) async throws {
        try await runOutboundTransfer(format: .zip, moving: moving, encrypted: false, promises: true)
    }

    @Test("Cancelling a drag after fulfilling promises preserves every source")
    @MainActor
    func cancelledOutboundPromises() async throws {
        try await runOutboundTransfer(format: .zip, moving: true, encrypted: false, promises: true, cancelled: true)
    }

    @Test("Native destination extracts into its supplied folder and preserves copy/move semantics", arguments: [false, true])
    @MainActor
    func nativeDestination(moving: Bool) async throws {
        try await runOutboundTransfer(format: .zip, moving: moving, encrypted: false, nativeDrop: true)
    }

    @Test("Moving from encrypted 7z preserves its password for the refreshed tree")
    @MainActor
    func encryptedOutboundTransfer() async throws {
        try await runOutboundTransfer(format: .sevenZip, moving: true, encrypted: true)
    }

    @MainActor
    private func runOutboundTransfer(format: ArchiveCompressionFormat, moving: Bool, encrypted: Bool,
                                     promises: Bool = false, cancelled: Bool = false, nativeDrop: Bool = false) async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let engine = NativeSevenZipArchiveEngine()
        let inside = root.appendingPathComponent("Inside", isDirectory: true)
        try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: true)
        try Data("payload".utf8).write(to: inside.appendingPathComponent("File.txt"))
        if promises { try Data("second".utf8).write(to: inside.appendingPathComponent("Second.txt")) }
        let archive = root.appendingPathComponent("Target.\(format.fileExtension)")
        var options = CompressionOptions(format: format)
        options.requiresPassword = encrypted
        options.encryptFileNames = encrypted
        let password = encrypted ? "Test password" : nil
        try await engine.createArchive(from: [inside], outputURL: archive, options: options,
            password: password, progress: { _ in })
        let defaultsName = "ZforgeTestSuite.ArchiveOutbound-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removeTestSuite(named: defaultsName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: engine)
        state.archiveTransferConfirmation = { _ in true }
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let target = try #require(state.items.first(where: { $0.name == archive.lastPathComponent }))
        await state.toggleExpansion(target, password: password)
        let folder = try #require(state.expandedChildren[target.id]?.first(where: { $0.name == "Inside" }))
        await state.toggleExpansion(folder)
        let file = try #require(state.expandedChildren[folder.id]?.first(where: { $0.name == "File.txt" }))
        state.select(folder)
        state.select(file, modifiers: .command)
        #expect(state.archiveDragItems(startingWith: folder).map(\.name) == ["Inside"])
        #expect(state.contextualActions(for: [file]).contains(.removeFromArchive))
        let before = try Data(contentsOf: archive)
        let directory = root.appendingPathComponent("Dropped", isDirectory: true)
        if nativeDrop { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
        let destination = nativeDrop ? directory.appendingPathComponent("File.txt") : root.appendingPathComponent("Export.txt")
        if nativeDrop {
            let transfer = ArchiveDragTransfer(state: state, items: [file])
            let delegate = ArchivePromiseDelegate(transfer: transfer, index: 0, name: file.name)
            transfer.delegates = [delegate]
            let board = NSPasteboard.withUniqueName()
            defer { board.releaseGlobally() }
            let provider = ArchiveDragPromise(type: "public.data", delegate: delegate, token: transfer.token)
            #expect(board.writeObjects([provider]))
            #expect(transfer.isDragging)
            let view = ArchiveDropDestinationView()
            #expect(view.accept(pasteboard: board, directory: directory, operation: moving ? .move : .copy))
            // AppKit sends the end notification immediately after performDrop.
            // The asynchronous export must retain the identity until completion.
            transfer.ended(moving ? .move : .copy)
            #expect(!transfer.isDragging)
            await transfer.waitForCompletion()
            #expect(ArchiveDragTransfer.active[transfer.token] == nil)
            #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("File.txt").path))
            #expect(!view.accept(pasteboard: board, directory: directory, operation: .copy))
        } else if promises {
            let second = try #require(state.expandedChildren[folder.id]?.first(where: { $0.name == "Second.txt" }))
            let transfer = ArchiveDragTransfer(state: state, items: [file, second], optionPressed: { moving })
            let board = NSPasteboard.withUniqueName()
            defer { board.releaseGlobally() }
            let urls = [destination, root.appendingPathComponent("Second Export.txt")]
            let providers = transfer.items.enumerated().map { index, item in
                let delegate = ArchivePromiseDelegate(transfer: transfer, index: index, name: urls[index].lastPathComponent)
                transfer.delegates.append(delegate)
                let provider = ArchiveDragPromise(type: "public.data", delegate: delegate, token: transfer.token)
                #expect(provider.token == transfer.token)
                return provider
            }
            #expect(board.writeObjects(providers))
            #expect(board.data(forType: NSPasteboard.PasteboardType(ArchiveDragPolicy.type)) == Data(transfer.token.utf8))
            // A receiver may await one file before asking for the next one.
            for (index, url) in urls.enumerated() {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    transfer.receive(index: index, url: url) { error in
                        if let error { continuation.resume(throwing: error) }
                        else { continuation.resume() }
                    }
                }
                #expect(FileManager.default.fileExists(atPath: url.path))
                #expect(try Data(contentsOf: archive) == before)
            }
            #expect(try Data(contentsOf: archive) == before)
            transfer.ended(cancelled ? [] : moving ? .move : .copy)
            await transfer.waitForCompletion()
            #expect(ArchiveDragTransfer.active[transfer.token] == nil)
        } else {
            try await state.transferArchiveItems([file], to: [destination], moving: moving, resolveConflicts: false)
        }
        #expect(try String(contentsOf: destination, encoding: .utf8) == "payload")
        #expect(state.expandedItems.contains(target.id))
        let newFolder = try #require(state.expandedChildren[target.id]?.first(where: { $0.name == "Inside" }))
        #expect(state.expandedItems.contains(newFolder.id))
        #expect(state.expandedChildren[newFolder.id]?.contains(where: { $0.name == "File.txt" }) == !(moving && !cancelled))
        if !moving || cancelled { #expect(try Data(contentsOf: archive) == before) }
    }

    @Test("A partial export failure never removes any of the selected sources")
    @MainActor
    func partialExportFailure() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let engine = NativeSevenZipArchiveEngine()
        let first = root.appendingPathComponent("First.txt")
        let second = root.appendingPathComponent("Second.txt")
        try Data("first".utf8).write(to: first)
        try Data("second".utf8).write(to: second)
        let archive = root.appendingPathComponent("Target.zip")
        try await engine.createArchive(from: [first, second], outputURL: archive, format: .zip, progress: { _ in })
        let suite = "ZforgeTestSuite.ArchiveFailure-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let state = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: FileSystemService(), grants: UIFixtureAccessGrantStore(), archives: engine)
        state.archiveTransferConfirmation = { _ in true }
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let target = try #require(state.items.first(where: { $0.name == "Target.zip" }))
        await state.openArchive(target)
        let firstItem = try #require(state.items.first(where: { $0.name == "First.txt" }))
        let secondItem = try #require(state.items.first(where: { $0.name == "Second.txt" }))
        let output = root.appendingPathComponent("Export.txt")
        let before = try Data(contentsOf: archive)
        await #expect(throws: (any Error).self) {
            try await state.transferArchiveItems([firstItem, secondItem], to: [output, second], moving: true, resolveConflicts: false)
        }
        #expect(try Data(contentsOf: archive) == before)
        #expect(try String(contentsOf: output, encoding: .utf8) == "first")
        #expect(try String(contentsOf: second, encoding: .utf8) == "second")
        #expect(!state.archiveOperationInProgress)
    }

    @Test("Folder promises flatten ancestors and preserve the archive after an export failure")
    func exportFolderAndFailure() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Outer/Inner", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("folder".utf8).write(to: source.appendingPathComponent("File.txt"))
        let archive = root.appendingPathComponent("Target.zip")
        try await engine.createArchive(from: [source.deletingLastPathComponent()], outputURL: archive, format: .zip, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: nil)
        let outer = try #require(try await engine.items(at: opened.address).first)
        guard case let .archive(outerAddress) = outer.location else { return }
        let inner = try #require(try await engine.items(at: outerAddress).first)
        let exported = root.appendingPathComponent("Promised Folder", isDirectory: true)
        try await engine.exportItem(inner, to: exported, password: nil, progress: { _ in })
        #expect(try String(contentsOf: exported.appendingPathComponent("File.txt"), encoding: .utf8) == "folder")
        #expect(!FileManager.default.fileExists(atPath: exported.appendingPathComponent("Outer").path))
        let before = try Data(contentsOf: archive)
        await #expect(throws: (any Error).self) {
            try await engine.exportItem(inner, to: exported, password: nil, progress: { _ in })
        }
        #expect(try Data(contentsOf: archive) == before)
        await engine.closeAllSessions()
    }

    @Test("Removal refuses a stale session and multiple volumes")
    func refusedRemoval() async throws {
        let engine = NativeSevenZipArchiveEngine()
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("File.txt")
        try Data("old".utf8).write(to: source)
        let archive = root.appendingPathComponent("Target.zip")
        try await engine.createArchive(from: [source], outputURL: archive, format: .zip, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: nil)
        let file = try #require(try await engine.items(at: opened.address).first)
        let volume = root.appendingPathComponent("Target.z01")
        try Data().write(to: volume)
        await #expect(throws: ArchiveEngineError.multiVolumeUpdateUnsupported) {
            try await engine.removeItems([file], password: nil, progress: { _ in })
        }
        try FileManager.default.removeItem(at: volume)
        try Data("new".utf8).write(to: source)
        // Another writer (D-73: the engine's own writes update its shared sessions in place).
        try await NativeSevenZipArchiveEngine().addItems(from: [source], to: archive, internalPath: "", password: nil, progress: { _ in })
        let changed = try Data(contentsOf: archive)
        await #expect(throws: ArchiveEngineError.archiveChanged) {
            try await engine.removeItems([file], password: nil, progress: { _ in })
        }
        #expect(try Data(contentsOf: archive) == changed)
        await engine.closeAllSessions()
    }

    @Test("Virtual drag explicitly reverses Option while local drag keeps its rule")
    @MainActor
    func dragOperation() {
        #expect(ArchiveDragPolicy.operation(option: false) == .copy)
        #expect(ArchiveDragPolicy.operation(option: true) == .move)
        #expect(BrowserFileDropOperationResolver.operation(for: [.option]) == .copy)
        let provider = ArchiveDragPromise()
        let type = NSPasteboard.PasteboardType(ArchiveDragPolicy.type)
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        #expect(provider.writingOptions(forType: type, pasteboard: board).isEmpty)
        #expect(provider.pasteboardPropertyList(forType: type) as? Data == Data(provider.token.utf8))
    }

    @Test("Internal transfers preserve payloads, survivors and password", arguments: [ArchiveCompressionFormat.zip, .sevenZip], [false, true])
    func internalTransfers(format: ArchiveCompressionFormat, moving: Bool) async throws {
        try await withReorganizationFixture(format: format, encrypted: true) { engine, root, archive, opened, source, target in
            let before = try Data(contentsOf: archive)
            let result = try await engine.reorganizeItems([source], to: target, moving: moving,
                password: "Test password", resolveConflict: { _ in .cancel }, progress: { _ in })
            #expect(result.paths == ["Target/Payload.txt"])
            if format == .sevenZip {
                await #expect(throws: ArchiveEngineError.passwordRequired) {
                    try await engine.openArchive(at: archive, password: nil)
                }
            }
            #expect(try Data(contentsOf: archive) != before)
            let refreshed = try await engine.openArchive(at: archive, password: "Test password")
            let roots = try await engine.items(at: refreshed.address)
            #expect(Set(roots.map(\.name)) == ["Inside", "Target"])
            let inside = try await engine.items(at: refreshed.address.appending("Inside"))
            #expect(inside.contains(where: { $0.name == "Payload.txt" }) == !moving)
            #expect(inside.contains(where: { $0.name == "Survivor.txt" }))
            let copied = try #require(try await engine.items(at: refreshed.address.appending("Target")).first(where: { $0.name == "Payload.txt" }))
            let output = root.appendingPathComponent("Export.txt")
            try await engine.exportItem(copied, to: output, password: "Test password", progress: { _ in })
            #expect(try String(contentsOf: output, encoding: .utf8) == "payload")
        }
    }

    @Test("Different selected entries with equal names never overwrite one another")
    func equalNamesInSelection() async throws {
        try await withReorganizationFixture { engine, root, archive, _, _, _ in
            let other = root.appendingPathComponent("Payload.txt")
            try Data("second payload".utf8).write(to: other)
            try await engine.addItems(from: [other], to: archive, internalPath: "Other", password: nil, progress: { _ in })
            let opened = try await engine.openArchive(at: archive, password: nil)
            let first = try #require(try await engine.items(at: opened.address.appending("Inside")).first(where: { $0.name == "Payload.txt" }))
            let second = try #require(try await engine.items(at: opened.address.appending("Other")).first)
            let result = try await engine.reorganizeItems([first, second], to: opened.address.appending("Target"), moving: true,
                password: nil, resolveConflict: { _ in Issue.record("Selected entries should receive unique names"); return .cancel }, progress: { _ in })
            #expect(result.paths.count == 2); #expect(Set(result.paths).count == 2)
            let refreshed = try await engine.openArchive(at: archive, password: nil)
            let entries = try await engine.items(at: refreshed.address.appending("Target"))
            var contents: Set<String> = []
            for entry in entries {
                let output = root.appendingPathComponent("Export-" + entry.name)
                try await engine.exportItem(entry, to: output, password: nil, progress: { _ in })
                contents.insert(try String(contentsOf: output, encoding: .utf8))
            }
            #expect(contents == ["payload", "second payload"])
            #expect(try await engine.items(at: refreshed.address.appending("Other")).isEmpty)
        }
    }

    @Test("Same-parent move is unchanged; same-parent copy receives a distinct name")
    func sameParent() async throws {
        try await withReorganizationFixture { engine, _, archive, opened, source, _ in
            let before = try Data(contentsOf: archive)
            let target = opened.address.appending("Inside")
            let moved = try await engine.reorganizeItems([source], to: target, moving: true, password: nil,
                resolveConflict: { _ in .cancel }, progress: { _ in })
            #expect(moved.paths.isEmpty)
            #expect(try Data(contentsOf: archive) == before)
            let copied = try await engine.reorganizeItems([source], to: target, moving: false, password: nil,
                resolveConflict: { _ in .cancel }, progress: { _ in })
            #expect(copied.paths == ["Inside/Payload 2.txt"])
            let reopened = try await engine.openArchive(at: archive, password: nil)
            #expect(Set(try await engine.items(at: reopened.address.appending("Inside")).map(\.name)) == ["Payload.txt", "Payload 2.txt", "Survivor.txt"])
        }
    }

    @Test("Folder and descendant selection is normalized; cycles are rejected before mutation")
    func foldersAndCycles() async throws {
        try await withReorganizationFixture { engine, _, archive, opened, source, target in
            let folder = try #require(try await engine.items(at: opened.address).first(where: { $0.name == "Inside" }))
            let before = try Data(contentsOf: archive)
            await #expect(throws: ArchiveEngineError.unsafePath) {
                try await engine.reorganizeItems([folder], to: opened.address.appending("Inside"), moving: true,
                    password: nil, resolveConflict: { _ in .cancel }, progress: { _ in })
            }
            #expect(try Data(contentsOf: archive) == before)
            let result = try await engine.reorganizeItems([folder, source], to: target, moving: true, password: nil,
                resolveConflict: { _ in .cancel }, progress: { _ in })
            #expect(result.paths == ["Target/Inside"])
            let reopened = try await engine.openArchive(at: archive, password: nil)
            #expect(try await engine.items(at: reopened.address).map(\.name) == ["Target"])
            #expect(Set(try await engine.items(at: reopened.address.appending("Target/Inside")).map(\.name)) == ["Payload.txt", "Survivor.txt"])
        }
    }

    @Test("Internal conflicts keep/cancel without mutation and replace only after validation", arguments: [0, 1, 2])
    func internalConflict(decision: Int) async throws {
        try await withReorganizationFixture(conflict: true) { engine, root, archive, opened, source, target in
            let before = try Data(contentsOf: archive)
            if decision == 0 {
                await #expect(throws: ArchiveEngineError.cancelled) {
                    try await engine.reorganizeItems([source], to: target, moving: true, password: nil,
                        resolveConflict: { _ in .cancel }, progress: { _ in })
                }
                #expect(try Data(contentsOf: archive) == before)
            } else {
                let result = try await engine.reorganizeItems([source], to: target, moving: true, password: nil,
                    resolveConflict: { _ in decision == 1 ? .keep(applyToAll: true) : .replace(applyToAll: true) }, progress: { _ in })
                #expect(result.paths == (decision == 1 ? [] : ["Target/Payload.txt"]))
                if decision == 1 { #expect(try Data(contentsOf: archive) == before) }
                let refreshed = try await engine.openArchive(at: archive, password: nil)
                let item = try #require(try await engine.items(at: refreshed.address.appending("Target")).first(where: { $0.name == "Payload.txt" }))
                let output = root.appendingPathComponent("Output.txt")
                try await engine.exportItem(item, to: output, password: nil, progress: { _ in })
                #expect(try String(contentsOf: output, encoding: .utf8) == (decision == 1 ? "existing" : "payload"))
            }
        }
    }

    @Test("A stale session and wrong password never change the original during reorganization")
    func internalSafety() async throws {
        try await withReorganizationFixture(encrypted: true) { engine, root, archive, _, source, target in
            let before = try Data(contentsOf: archive)
            await #expect(throws: (any Error).self) {
                try await engine.reorganizeItems([source], to: target, moving: true, password: "wrong",
                    resolveConflict: { _ in .cancel }, progress: { _ in })
            }
            #expect(try Data(contentsOf: archive) == before)
            let new = root.appendingPathComponent("New.txt")
            try Data("new".utf8).write(to: new)
            // Another writer (D-73: the engine's own writes update its shared sessions in place).
            try await NativeSevenZipArchiveEngine().addItems(from: [new], to: archive, internalPath: "", password: "Test password", progress: { _ in })
            let changed = try Data(contentsOf: archive)
            await #expect(throws: ArchiveEngineError.archiveChanged) {
                try await engine.reorganizeItems([source], to: target, moving: true, password: "Test password",
                    resolveConflict: { _ in .cancel }, progress: { _ in })
            }
            #expect(try Data(contentsOf: archive) == changed)
        }
    }

    @Test("Rejecting move confirmation leaves destination and archive unchanged", arguments: [false, true])
    @MainActor
    func rejectedConfirmation(internalDrop: Bool) async throws {
        try await withReorganizationFixture { engine, root, archive, _, _, _ in
            let defaults = try #require(UserDefaults(suiteName: "ZforgeTestSuite.Cancel-\(UUID().uuidString)"))
            let state = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
                grants: UIFixtureAccessGrantStore(), archives: engine)
            defer { state.close() }
            await state.navigateToSidebar(root, name: root.lastPathComponent)
            let archiveItem = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            await state.openArchive(archiveItem)
            let inside = try #require(state.items.first(where: { $0.name == "Inside" }))
            await state.toggleExpansion(inside)
            let item = try #require(state.expandedChildren[inside.id]?.first(where: { $0.name == "Payload.txt" }))
            let targetItem = try #require(state.items.first(where: { $0.name == "Target" }))
            guard case let .archive(target) = targetItem.location else { Issue.record("Missing address"); return }
            var captured: FileBrowserState.ArchiveTransferConfirmation?
            state.archiveTransferConfirmation = { captured = $0; return false }
            let before = try Data(contentsOf: archive)
            let output = root.appendingPathComponent("Cancelled.txt")
            await #expect(throws: ArchiveEngineError.cancelled) {
                if internalDrop { try await state.reorganizeArchiveItems([item], to: target, moving: true) }
                else { try await state.transferArchiveItems([item], to: [output], moving: true, resolveConflicts: false) }
            }
            #expect(!FileManager.default.fileExists(atPath: output.path))
            #expect(try Data(contentsOf: archive) == before)
            #expect(captured?.archiveURL.standardizedFileURL == archive.standardizedFileURL)
            #expect(captured?.itemCount == 1)
            let request = try #require(captured)
            let alert = state.archiveTransferAlert(request)
            #expect(alert.buttons[0].keyEquivalent == "\r")
            #expect(alert.buttons[1].keyEquivalent == "\u{1b}")
            #expect(alert.informativeText.contains(archive.lastPathComponent))
            #expect(!state.archiveOperationInProgress)
        }
    }

    @Test("Context and Option determine all four operations; mode formations match local visuals")
    @MainActor
    func internalPolicyAndFormation() {
        #expect(ArchiveDragPolicy.operation(option: false, insideArchive: true) == .move)
        #expect(ArchiveDragPolicy.operation(option: true, insideArchive: true) == .copy)
        #expect(BrowserViewMode.list.archiveDragFormation == .list)
        #expect(BrowserViewMode.columns.archiveDragFormation == .list)
        #expect(BrowserViewMode.icons.archiveDragFormation == .default)
        #expect(BrowserViewMode.gallery.archiveDragFormation == .default)
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 600, height: 500),
            styleMask: [.titled], backing: .buffered, defer: false)
        let host = try! #require(window.contentView)
        let root = ArchiveDropDestinationView(frame: host.bounds)
        root.directory = URL(fileURLWithPath: "/root")
        host.addSubview(root)
        let folder = ArchiveDropDestinationView(frame: NSRect(x: 20, y: 40, width: 200, height: 30))
        folder.directory = URL(fileURLWithPath: "/root/folder")
        host.addSubview(folder)
        #expect(root.destination(at: NSPoint(x: 50, y: 55)) === folder)
        #expect(root.destination(at: NSPoint(x: 450, y: 350)) === root)
        folder.removeFromSuperview()
        #expect(root.destination(at: NSPoint(x: 50, y: 55)) === root)
    }

    @Test("Refresh reveals the internal result in every mode", arguments: BrowserViewMode.allCases, [false, true])
    @MainActor
    func internalRefresh(mode: BrowserViewMode, moving: Bool) async throws {
        try await withReorganizationFixture { engine, root, _, _, _, _ in
            let suite = "ZforgeTestSuite.ReorganizationRefresh-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removeTestSuite(named: suite) }
            let preferences = FileBrowserPreferences(defaults: defaults); preferences.viewMode = mode
            let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(), grants: UIFixtureAccessGrantStore(), archives: engine)
            // Changing Settings affects future windows, not this window's
            // archive refresh, disclosure restoration, or destination reveal.
            preferences.viewMode = mode == .list ? .icons : .list
            #expect(state.viewMode == mode)
            state.archiveTransferConfirmation = { _ in true }
            defer { state.close() }
            await state.navigateToSidebar(root, name: root.lastPathComponent)
            let archive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            await state.openArchive(archive)
            let inside = try #require(state.items.first(where: { $0.name == "Inside" }))
            let target = try #require(state.items.first(where: { $0.name == "Target" }))
            guard case let .archive(destination) = target.location else { Issue.record("Missing address"); return }
            let source: BrowserItem
            if mode == .list {
                await state.toggleExpansion(inside)
                source = try #require(state.expandedChildren[inside.id]?.first(where: { $0.name == "Payload.txt" }))
            } else {
                await state.open(inside)
                source = try #require(state.items.first(where: { $0.name == "Payload.txt" }))
            }
            try await state.reorganizeArchiveItems([source], to: destination, moving: moving)
            guard case let .archive(address) = state.location else { Issue.record("Archive was closed"); return }
            #expect(address.internalPath == (mode == .list ? "" : "Target"))
            #expect(state.selectedItems.map(\.name) == ["Payload.txt"])
            if mode == .list {
                let refreshedTarget = try #require(state.items.first(where: { $0.name == "Target" }))
                #expect(state.expandedItems.contains(refreshedTarget.id))
                #expect(state.expandedChildren[refreshedTarget.id]?.contains(where: { $0.name == "Payload.txt" }) == true)
                let survivingInside = try #require(state.items.first(where: { $0.name == "Inside" }))
                #expect(state.expandedItems.contains(survivingInside.id))
                #expect(state.expandedChildren[survivingInside.id]?.contains(where: { $0.name == "Payload.txt" }) == !moving)
            } else {
                for component in state.pathComponents {
                    #expect(state.columnItems[component.location] != nil)
                }
                await state.goBack()
                guard case let .archive(previous) = state.location else { Issue.record("Back left the archive"); return }
                #expect(previous.internalPath == "Inside")
                await state.goForward()
                guard case let .archive(next) = state.location else { Issue.record("Forward lost the archive"); return }
                #expect(next.internalPath == "Target")
            }
        }
    }

    @Test("Archive mutations retain deep Back/Forward history and populated ancestor columns",
          arguments: BrowserViewMode.allCases, [ArchiveCompressionFormat.zip, .sevenZip].flatMap { format in
              ["remove", "moveOut", "add"].map { ($0, format) }
          })
    @MainActor
    func mutationPreservesNavigation(mode: BrowserViewMode, scenario: (String, ArchiveCompressionFormat)) async throws {
        let (operation, format) = scenario
        try await withNavigationFixture(mode: mode, format: format) { state, _, root, archive in
            guard case let .archive(oldAddress) = state.location else { Issue.record("Missing archive"); return }
            #expect(oldAddress.internalPath == "Inside/Deep")
            #expect(state.canGoForward)
            let payload = try #require(state.items.first(where: { $0.name == "Payload.txt" }))
            switch operation {
            case "remove": await state.deleteArchiveItems([payload])
            case "moveOut":
                try await state.transferArchiveItems([payload], to: [root.appendingPathComponent("Exported/Payload.txt")], moving: true, resolveConflicts: false)
            default:
                let addition = root.appendingPathComponent("Added.txt")
                try Data("added".utf8).write(to: addition)
                await state.confirmArchiveAddition(.init(sourceURLs: [addition], archiveURL: archive, internalPath: oldAddress.internalPath))
            }
            #expect(state.error == nil)
            guard case let .archive(updated) = state.location else { Issue.record("Mutation left archive"); return }
            // D-73: the shared session is updated in place, so addresses stay valid in every window.
            #expect(updated.sessionID == oldAddress.sessionID)
            #expect(updated.internalPath == "Inside/Deep")
            #expect(state.canGoForward)
            for (index, component) in state.pathComponents.enumerated() {
                let rows = try #require(state.columnItems[component.location])
                #expect(!rows.isEmpty)
                if index + 1 < state.pathComponents.count {
                    let next = state.pathComponents[index + 1]
                    let selected = try #require(rows.first(where: { $0.name == next.name }))
                    #expect(state.columnSelections[component.location] == selected.id)
                }
                if case let .archive(address) = component.location { #expect(address.sessionID == updated.sessionID) }
            }
            await state.goForward()
            guard case let .archive(leaf) = state.location else { Issue.record("Forward lost the archive"); return }
            #expect(leaf.internalPath == "Inside/Deep/Leaf")
            #expect(state.items.map(\.name) == ["Keep.txt"])
            for expected in ["Inside/Deep", "Inside", ""] {
                await state.goBack()
                guard case let .archive(address) = state.location else { Issue.record("Back skipped an archive ancestor"); return }
                #expect(address.internalPath == expected)
                #expect(address.sessionID == updated.sessionID)
                #expect(state.error == nil)
            }
            await state.goBack()
            #expect(state.location == .fileSystem(root))
        }
    }

    @Test("Refresh discards removed history branches and falls back only to the surviving parent",
          arguments: BrowserViewMode.allCases, [ArchiveCompressionFormat.zip, .sevenZip].flatMap { format in
              [false, true].map { ($0, format) }
          })
    @MainActor
    func removedNavigationBranch(mode: BrowserViewMode, scenario: (Bool, ArchiveCompressionFormat)) async throws {
        let (viewingRemoved, format) = scenario
        try await withNavigationFixture(mode: mode, format: format) { state, _, _, _ in
            let leaf = try #require(state.items.first(where: { $0.name == "Leaf" }))
            if viewingRemoved { await state.goForward() }
            await state.deleteArchiveItems([leaf])
            #expect(state.error == nil)
            guard case let .archive(address) = state.location else { Issue.record("Archive closed after deleting branch"); return }
            #expect(address.internalPath == "Inside/Deep")
            #expect(!state.canGoForward)
            #expect(!state.items.contains(where: { $0.name == "Leaf" }))
            await state.goBack()
            guard case let .archive(parent) = state.location else { Issue.record("Valid parent history was removed"); return }
            #expect(parent.internalPath == "Inside")
            #expect(state.error == nil)
        }
    }

    @MainActor
    private func withNavigationFixture(mode: BrowserViewMode, format: ArchiveCompressionFormat,
        body: (FileBrowserState, NativeSevenZipArchiveEngine, URL, URL) async throws -> Void) async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let deep = root.appendingPathComponent("Inside/Deep", isDirectory: true)
        let leaf = deep.appendingPathComponent("Leaf", isDirectory: true)
        try FileManager.default.createDirectory(at: leaf, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Exported"), withIntermediateDirectories: true)
        try Data("payload".utf8).write(to: deep.appendingPathComponent("Payload.txt"))
        try Data("keep".utf8).write(to: leaf.appendingPathComponent("Keep.txt"))
        let archive = root.appendingPathComponent("Navigation.\(format.fileExtension)")
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [root.appendingPathComponent("Inside")], outputURL: archive, format: format, progress: { _ in })
        let suite = "ZforgeTestSuite.ArchiveNavigation-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults); preferences.viewMode = mode
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(), grants: UIFixtureAccessGrantStore(), archives: engine)
        state.archiveTransferConfirmation = { _ in true }
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        for name in [archive.lastPathComponent, "Inside", "Deep", "Leaf"] {
            let item = try #require(state.items.first(where: { $0.name == name }))
            if mode == .columns { await state.activateColumnItem(item, in: state.location).value }
            else { await state.open(item) }
        }
        await state.goBack()
        try await body(state, engine, root, archive)
    }

    @Test("External move promises rejected by confirmation publish nothing and retain every entry")
    @MainActor
    func rejectedPromise() async throws {
        try await withReorganizationFixture { engine, root, archive, _, _, _ in
            let suite = "ZforgeTestSuite.PromiseCancel-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removeTestSuite(named: suite) }
            let preferences = FileBrowserPreferences(defaults: defaults); preferences.viewMode = .list
            let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(), grants: UIFixtureAccessGrantStore(), archives: engine)
            state.archiveTransferConfirmation = { _ in false }
            defer { state.close() }
            await state.navigateToSidebar(root, name: root.lastPathComponent)
            await state.openArchive(try #require(state.items.first(where: { $0.name == "Sample.zip" })))
            await state.open(try #require(state.items.first(where: { $0.name == "Inside" })))
            let files = state.items
            let transfer = ArchiveDragTransfer(state: state, items: files, optionPressed: { true })
            let before = try Data(contentsOf: archive)
            for (index, file) in files.enumerated() {
                let output = root.appendingPathComponent("Cancelled " + file.name)
                let error = await withCheckedContinuation { continuation in
                    transfer.receive(index: index, url: output) { continuation.resume(returning: $0 as? ArchiveEngineError) }
                }
                #expect(error == .cancelled)
                #expect(!FileManager.default.fileExists(atPath: output.path))
            }
            transfer.ended(.move); await transfer.waitForCompletion()
            #expect(try Data(contentsOf: archive) == before)
            #expect(state.error == nil)
            #expect(ArchiveDragTransfer.active[transfer.token] == nil)
        }
    }

    @Test("A concurrent change while resolving a conflict is never overwritten")
    func concurrentReorganization() async throws {
        try await withReorganizationFixture(conflict: true) { engine, _, archive, _, source, destination in
            let concurrent = Data("another writer".utf8)
            await #expect(throws: ArchiveEngineError.archiveChanged) {
                try await engine.reorganizeItems([source], to: destination, moving: true, password: nil,
                    resolveConflict: { _ in
                        try? concurrent.write(to: archive)
                        return .replace(applyToAll: false)
                    }, progress: { _ in })
            }
            #expect((try? Data(contentsOf: archive)) == concurrent)
        }
    }

    @Test("Cancelled reorganization never modifies the original")
    func cancelledReorganization() async throws {
        try await withReorganizationFixture { engine, _, archive, _, source, destination in
            let before = try Data(contentsOf: archive)
            let task = Task {
                try await engine.reorganizeItems([source], to: destination, moving: true, password: nil,
                    resolveConflict: { _ in .cancel }, progress: { _ in })
            }
            task.cancel()
            await #expect(throws: (any Error).self) { try await task.value }
            #expect(try Data(contentsOf: archive) == before)
        }
    }

    private func withReorganizationFixture(format: ArchiveCompressionFormat = .zip, encrypted: Bool = false,
        conflict: Bool = false,
        body: (NativeSevenZipArchiveEngine, URL, URL, ArchiveOpenResult, BrowserItem, ArchiveAddress) async throws -> Void) async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let engine = NativeSevenZipArchiveEngine()
        let inside = root.appendingPathComponent("Inside", isDirectory: true)
        let target = root.appendingPathComponent("Target", isDirectory: true)
        try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
        try Data("survivor".utf8).write(to: inside.appendingPathComponent("Survivor.txt"))
        if conflict { try Data("existing".utf8).write(to: target.appendingPathComponent("Payload.txt")) }
        let archive = root.appendingPathComponent("Sample.\(format.fileExtension)")
        var options = CompressionOptions(format: format)
        options.requiresPassword = encrypted; options.encryptFileNames = encrypted && format == .sevenZip
        let password = encrypted ? "Test password" : nil
        try await engine.createArchive(from: [inside, target], outputURL: archive, options: options, password: password, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: password)
        let source = try #require(try await engine.items(at: opened.address.appending("Inside")).first(where: { $0.name == "Payload.txt" }))
        try await body(engine, root, archive, opened, source, opened.address.appending("Target"))
        await engine.closeAllSessions()
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ArchiveMutation-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
