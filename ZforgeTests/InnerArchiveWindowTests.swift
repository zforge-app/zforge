import Foundation
import Testing
@testable import Zforge

/// D-73 / ZF-55 stage 2: archives inside archives open as root archives in their own
/// windows, every archive has one shared session, and a modified inner archive is written
/// back into its outer archive when its last window closes.
@Suite("Inner archive windows, shared sessions and write-back (D-73)")
struct InnerArchiveWindowTests {
    // MARK: Shared sessions (engine)

    @Test("Opening an archive that is already open joins its session; it closes with the last reference")
    func sharedRootSession() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let first = try await engine.openArchive(at: archive, password: nil)
        let second = try await engine.openArchive(at: archive, password: nil)
        #expect(second.address == first.address)
        #expect(await engine.sessionReferences()[first.address.sessionID] == 2)
        await engine.closeSession(first.address.sessionID)
        #expect(await engine.sessionReferences()[first.address.sessionID] == 1)
        #expect(try await !engine.items(at: second.address).isEmpty)
        await engine.closeSession(second.address.sessionID)
        #expect(await engine.sessionReferences()[first.address.sessionID] == nil)
    }

    @Test("Joining an archive whose names are encrypted needs its password")
    func sharedEncryptedSession() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let payload = fixture.input.appendingPathComponent("Secret.txt")
        try Data("secret".utf8).write(to: payload)
        var options = CompressionOptions(format: .sevenZip)
        options.requiresPassword = true
        options.encryptFileNames = true
        let archive = fixture.root.appendingPathComponent("Secret.7z")
        try await NativeSevenZipArchiveEngine().createArchive(from: [payload], outputURL: archive, options: options,
            password: "right", progress: { _ in })
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: archive, password: "right")
        await #expect(throws: ArchiveEngineError.passwordRequired) { try await engine.openArchive(at: archive, password: nil) }
        await #expect(throws: ArchiveEngineError.invalidPassword) { try await engine.openArchive(at: archive, password: "wrong") }
        #expect(try await engine.openArchive(at: archive, password: "right").address == opened.address)
        #expect(await engine.sessionReferences()[opened.address.sessionID] == 2)
    }

    @Test("A change written through one reference updates the shared session in place for all")
    func changeUpdatesSharedSession() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let windowA = ArchiveSessionClient(engine: engine)
        let windowB = ArchiveSessionClient(engine: engine)
        let a = try await windowA.openArchive(at: archive, password: nil)
        let b = try await windowB.openArchive(at: archive, password: nil)
        #expect(a.address == b.address)
        let changes = SessionChangeLog(engine: engine)
        let outerText = try #require(try await windowA.items(at: a.address).first { $0.name == "Outer.txt" })
        try await windowA.removeItems([outerText], password: nil, progress: { _ in })
        #expect(try await windowB.items(at: b.address).map(\.name) == ["Inner.zip"])
        let refreshed = try await windowB.reopenSession(b.address.sessionID, at: archive, password: nil)
        #expect(refreshed.address == b.address)
        #expect(refreshed.revision == 1)
        #expect(await changes.revisions(of: b.address.sessionID) == [1])
        // Each window releases exactly its own reference.
        await windowA.closeAllSessions()
        #expect(await engine.sessionReferences()[a.address.sessionID] == 1)
        await windowB.closeAllSessions()
        #expect(await engine.sessionReferences()[a.address.sessionID] == nil)
    }

    // MARK: Inner archives (engine)

    @Test("An inner archive's copy belongs to its session: it outlives the outer window and goes with its session")
    func innerCopyLifetime() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let outer = try await engine.openArchive(at: archive, password: nil)
        let innerItem = try #require(try await engine.items(at: outer.address).first { $0.name == "Inner.zip" })
        let inner = try await engine.openInnerArchive(item: innerItem, password: nil)
        let again = try await engine.openInnerArchive(item: innerItem, password: nil)
        #expect(again.address == inner.address, "The same inner archive shares one session")
        await engine.closeSession(again.address.sessionID)
        let copy = try await engine.archiveRootURL(for: inner.address)
        let innerDirectory = ZforgeTemporaryStorage.archiveSessionsRoot().appendingPathComponent(inner.address.sessionID.uuidString)
        #expect(copy.path.hasPrefix(innerDirectory.path + "/"))
        #expect(inner.displayName == "Outer.zip › Inner.zip")

        // Closing the outer window keeps the outer session for the inner one.
        await engine.closeSession(outer.address.sessionID)
        #expect(await engine.sessionReferences()[outer.address.sessionID] == 1)
        #expect(FileManager.default.fileExists(atPath: copy.path))
        #expect(try await engine.items(at: inner.address).map(\.name) == ["Inner.txt"])

        // Unmodified, the last release ends the inner session, then the outer one.
        await engine.closeSession(inner.address.sessionID)
        #expect(!FileManager.default.fileExists(atPath: innerDirectory.path))
        #expect(await engine.sessionReferences().isEmpty)
        #expect(await engine.pendingWriteBacks().isEmpty)
    }

    @Test("A modified inner archive is written back when its last reference goes, replacing its entry")
    func writeBackReplacesEntry() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let changes = SessionChangeLog(engine: engine)
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        let before = try Data(contentsOf: archive)

        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.pendingWriteBacks() == [inner.address.sessionID])
        #expect(try Data(contentsOf: archive) == before, "Nothing is written before the write-back")
        try await engine.writeBack(inner.address.sessionID)

        #expect(await engine.pendingWriteBacks().isEmpty)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        // The outer session shows the new archive (same addresses) and its windows are told.
        #expect(try await engine.items(at: outer.address).map(\.name).sorted() == ["Inner.zip", "Outer.txt"])
        #expect(await changes.revisions(of: outer.address.sessionID) == [1])
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: fixture.root.path).filter { $0.hasPrefix(".zforge-") }
        #expect(leftovers.isEmpty)
        await engine.closeAllSessions()
    }

    @Test("Chains write back from the innermost archive up")
    @MainActor
    func chainWritesBackInOrder() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.chain()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let a = try await engine.openArchive(at: archive, password: nil)
        let b = try await fixture.openInner(named: "B.zip", in: a, engine: engine)
        let c = try await fixture.openInner(named: "C.zip", in: b, engine: engine)
        try await fixture.addNote(to: c, engine: engine)
        // Windows close outer first: the inner sessions keep their outer ones open.
        await engine.closeSession(a.address.sessionID)
        await engine.closeSession(b.address.sessionID)
        await engine.closeSession(c.address.sessionID)
        await coordinator.finishPendingWriteBacks()

        #expect(presenter.progress == ["C.zip → A.zip › B.zip", "B.zip → A.zip"])
        #expect(await engine.sessionReferences().isEmpty)
        let names = try await Fixture.names(at: ["B.zip", "C.zip"], in: archive)
        #expect(names == ["C.txt", "Note.txt"])
    }

    @Test("When the outer archive changed, the user chooses: replace anyway, save the inner archive as, or discard",
          arguments: [ArchiveWriteBackConflictChoice.replaceAnyway, .saveInnerArchiveAs, .discardChanges])
    @MainActor
    func outerChangedConflict(choice: ArchiveWriteBackConflictChoice) async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        presenter.conflictChoices = [choice]
        presenter.saveDestination = fixture.root.appendingPathComponent("Saved Inner.zip")
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        // Another writer changes the outer archive.
        let other = fixture.input.appendingPathComponent("Other.txt")
        try Data("other".utf8).write(to: other)
        try await NativeSevenZipArchiveEngine().addItems(from: [other], to: archive, internalPath: "", password: nil, progress: { _ in })
        let changed = try Data(contentsOf: archive)
        await engine.closeSession(outer.address.sessionID)
        await engine.closeSession(inner.address.sessionID)
        await coordinator.finishPendingWriteBacks()

        #expect(presenter.conflicts == ["Inner.zip / Outer.zip"])
        #expect(await engine.pendingWriteBacks().isEmpty)
        #expect(await engine.sessionReferences().isEmpty)
        switch choice {
        case .replaceAnyway:
            #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
            #expect(try await Fixture.rootNames(of: archive).contains("Other.txt"), "The other change is kept")
        case .saveInnerArchiveAs:
            #expect(try Data(contentsOf: archive) == changed)
            #expect(try await Fixture.rootNames(of: presenter.saveDestination!) == ["Inner.txt", "Note.txt"])
        case .discardChanges:
            #expect(try Data(contentsOf: archive) == changed)
        }
    }

    @Test("A failed write-back keeps the modified copy and offers Try Again and Save Inner Archive As")
    @MainActor
    func failedWriteBackRetries() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        let copy = try await engine.archiveRootURL(for: inner.address)
        // The outer archive's folder refuses the hidden file the rebuild writes beside it.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: fixture.root.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fixture.root.path) }
        presenter.onFailure = { [root = fixture.root] in
            #expect(FileManager.default.fileExists(atPath: copy.path), "The modified copy is kept")
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: root.path)
            return .tryAgain
        }
        await engine.closeSession(outer.address.sessionID)
        await engine.closeSession(inner.address.sessionID)
        await coordinator.finishPendingWriteBacks()

        #expect(presenter.failures.count == 1)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        #expect(await engine.sessionReferences().isEmpty)
    }

    @Test("A cancelled write-back keeps the modified copy for another attempt")
    func cancelledWriteBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        let before = try Data(contentsOf: archive)
        await engine.closeSession(inner.address.sessionID)
        let attempt = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await engine.writeBack(inner.address.sessionID)
        }
        await #expect(throws: CancellationError.self) { try await attempt.value }
        #expect(try Data(contentsOf: archive) == before)
        #expect(await engine.pendingWriteBacks() == [inner.address.sessionID])
        try await engine.writeBack(inner.address.sessionID)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
    }

    @Test("An encrypted outer archive is written back with the password in its session, asked only when unknown")
    @MainActor
    func encryptedOuterArchive() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip(format: .sevenZip, password: "outer secret")
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        presenter.passwords = ["outer secret"]
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let outer = try await engine.openArchive(at: archive, password: "outer secret")
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        await engine.closeSession(outer.address.sessionID)
        await engine.closeSession(inner.address.sessionID)
        await coordinator.finishPendingWriteBacks()
        #expect(presenter.passwordRequests == 0, "The session's password was used")
        #expect(try await Fixture.names(inInnerOf: archive, password: "outer secret") == ["Inner.txt", "Note.txt"])

        // Without a known password, it is asked for.
        let reopened = try await engine.openArchive(at: archive, password: "outer secret")
        let second = try await fixture.openInner(in: reopened, engine: engine)
        try await fixture.addNote(to: second, engine: engine, named: "Second.txt")
        await engine.setPassword(nil, for: reopened.address.sessionID)
        await engine.closeSession(reopened.address.sessionID)
        await engine.closeSession(second.address.sessionID)
        await coordinator.finishPendingWriteBacks()
        #expect(presenter.passwordRequests == 1)
        #expect(try await Fixture.names(inInnerOf: archive, password: "outer secret") == ["Inner.txt", "Note.txt", "Second.txt"])
    }

    @Test("An archive inside an archive that cannot be updated is read-only")
    func readOnlyInnerArchive() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let innerZip = try await fixture.innerZip()
        let archive = fixture.root.appendingPathComponent("Outer.tar.gz")
        try await NativeSevenZipArchiveEngine().createArchive(from: [innerZip, fixture.input.appendingPathComponent("Outer.txt")],
            outputURL: archive, options: CompressionOptions(format: .gzip), password: nil, progress: { _ in })
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: archive, password: nil)
        #expect(outer.isReadOnly)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        #expect(inner.isReadOnly)
        let item = try #require(try await engine.items(at: inner.address).first)
        await #expect(throws: ArchiveEngineError.updateUnsupported) {
            try await engine.removeItems([item], password: nil, progress: { _ in })
        }
        let copy = try await engine.archiveRootURL(for: inner.address)
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        await #expect(throws: ArchiveEngineError.updateUnsupported) {
            try await engine.addItems(from: [note], to: copy, internalPath: "", password: nil, progress: { _ in })
        }
        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.pendingWriteBacks().isEmpty)
    }

    // MARK: Windows (state)

    @Test("Open on an inner archive shows it in a new window that shares its session")
    @MainActor
    func innerArchiveWindow() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let outerWindow = windows.make()
        await outerWindow.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await outerWindow.open(try #require(outerWindow.items.first { $0.name == "Outer.zip" }))
        let innerItem = try #require(outerWindow.items.first { $0.name == "Inner.zip" })
        #expect(!innerItem.isNavigableContainer)
        await outerWindow.open(innerItem)
        guard case .archive = outerWindow.location else { Issue.record("The outer window left its archive"); return }
        #expect(outerWindow.title == "Outer.zip", "The outer window stays where it was")

        let innerWindow = try await windows.adoptLastRequest()
        guard case let .archive(address) = innerWindow.location else { Issue.record("No inner archive shown"); return }
        #expect(innerWindow.title == "Outer.zip › Inner.zip")
        #expect(innerWindow.pathComponents.map(\.name) == ["Outer.zip › Inner.zip"])
        #expect(!innerWindow.canGoBack, "The inner archive is the window's root, with no history behind it (D-95)")
        #expect(innerWindow.items.map(\.name) == ["Inner.txt"])
        #expect(innerWindow.heldArchiveSessionIDs == [address.sessionID])
        #expect(!outerWindow.heldArchiveSessionIDs.contains(address.sessionID), "The reference moved to the new window")
        #expect(await engine.sessionReferences()[address.sessionID] == 1)

        // Opening it again attaches another window to the same session.
        await outerWindow.open(innerItem)
        let secondWindow = try await windows.adoptLastRequest()
        guard case let .archive(second) = secondWindow.location else { Issue.record("No second inner window"); return }
        #expect(second.sessionID == address.sessionID)
        #expect(await engine.sessionReferences()[address.sessionID] == 2)
    }

    @Test("A change in one window appears in every window of the archive, keeping location and selection")
    @MainActor
    func changePropagatesToOtherWindows() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let first = windows.make()
        let second = windows.make()
        for window in [first, second] {
            await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
            await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
        }
        guard case let .archive(a) = first.location, case let .archive(b) = second.location else {
            Issue.record("Archive not shown"); return
        }
        #expect(a.sessionID == b.sessionID)
        let innerInSecond = try #require(second.items.first { $0.name == "Inner.zip" })
        second.select(innerInSecond)
        let outerText = try #require(first.items.first { $0.name == "Outer.txt" })
        await first.deleteArchiveItems([outerText])
        #expect(first.items.map(\.name) == ["Inner.zip"])

        try await second.awaitArchiveSessionChange()
        #expect(second.items.map(\.name) == ["Inner.zip"])
        #expect(second.location == .archive(b))
        #expect(second.selection == [innerInSecond.id], "The surviving selection is kept")
    }

    @Test("A window whose folder was removed elsewhere moves to the nearest surviving folder")
    @MainActor
    func removedFolderMovesUp() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let folder = fixture.input.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Deep"), withIntermediateDirectories: true)
        try Data("deep".utf8).write(to: folder.appendingPathComponent("Deep/Deep.txt"))
        let archive = fixture.root.appendingPathComponent("Folders.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [folder], outputURL: archive, format: .zip, progress: { _ in })
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let first = windows.make()
        let second = windows.make()
        for window in [first, second] {
            await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
            await window.open(try #require(window.items.first { $0.name == "Folders.zip" }))
        }
        await second.open(try #require(second.items.first { $0.name == "Folder" }))
        await second.open(try #require(second.items.first { $0.name == "Deep" }))
        let deep = try #require(first.items.first { $0.name == "Folder" })
        await first.open(deep)
        await first.deleteArchiveItems([try #require(first.items.first { $0.name == "Deep" })])

        try await second.awaitArchiveSessionChange()
        guard case let .archive(address) = second.location else { Issue.record("Left the archive"); return }
        #expect(address.internalPath == "Folder")
        #expect(second.items.isEmpty)
    }

    @Test("Closing the last window of an archive closes its inner archive windows first, innermost first")
    @MainActor
    func closingOrder() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.chain()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let a = windows.make(name: "A")
        await a.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await a.open(try #require(a.items.first { $0.name == "A.zip" }))
        await a.open(try #require(a.items.first { $0.name == "B.zip" }))
        let b = try await windows.adoptLastRequest(name: "B")
        await b.open(try #require(b.items.first { $0.name == "C.zip" }))
        let c = try await windows.adoptLastRequest(name: "C")
        let otherA = windows.make(name: "A2")
        await otherA.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await otherA.open(try #require(otherA.items.first { $0.name == "A.zip" }))

        // Another window still shows A.zip: its inner windows stay open.
        a.close()
        #expect(windows.closed.isEmpty)
        otherA.close()
        #expect(windows.closed == ["C", "B"])
        #expect(c.isClosedForRegistry && b.isClosedForRegistry)
    }

    @Test("Closing a modified inner archive's window writes it back; the outer window reloads, keeping its selection")
    @MainActor
    func closingInnerWindowWritesBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let outerWindow = windows.make()
        await outerWindow.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await outerWindow.open(try #require(outerWindow.items.first { $0.name == "Outer.zip" }))
        let outerText = try #require(outerWindow.items.first { $0.name == "Outer.txt" })
        await outerWindow.open(try #require(outerWindow.items.first { $0.name == "Inner.zip" }))
        outerWindow.select(outerText)
        let innerWindow = try await windows.adoptLastRequest()
        #expect(innerWindow.isArchiveSessionWritable(try #require(innerWindow.heldArchiveSessionIDs.first)))
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        guard case let .archive(innerRoot) = innerWindow.location else { Issue.record("No inner archive"); return }
        await innerWindow.requestArchiveAddition([note], to: innerRoot)
        let request = try #require(innerWindow.pendingArchiveAddition)
        #expect(request.archiveURL.lastPathComponent == "Inner.zip")
        await innerWindow.confirmArchiveAddition(request)
        #expect(innerWindow.items.map(\.name).sorted() == ["Inner.txt", "Note.txt"])

        innerWindow.close()
        await innerWindow.closingTask?.value
        await coordinator.finishPendingWriteBacks()
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        try await outerWindow.awaitArchiveSessionChange()
        #expect(outerWindow.items.map(\.name).sorted() == ["Inner.zip", "Outer.txt"])
        #expect(outerWindow.selection == [outerText.id])
    }

    @Test("An inner window of an archive that cannot be updated offers no write actions")
    @MainActor
    func readOnlyInnerWindow() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let innerZip = try await fixture.innerZip()
        let archive = fixture.root.appendingPathComponent("Outer.tar.gz")
        try await NativeSevenZipArchiveEngine().createArchive(from: [innerZip, fixture.input.appendingPathComponent("Outer.txt")],
            outputURL: archive, options: CompressionOptions(format: .gzip), password: nil, progress: { _ in })
        try FileManager.default.removeItem(at: innerZip)
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let outerWindow = windows.make()
        await outerWindow.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await outerWindow.open(try #require(outerWindow.items.first { $0.name == "Outer.tar.gz" }))
        await outerWindow.open(try #require(outerWindow.items.first { $0.name == "Inner.zip" }))
        let innerWindow = try await windows.adoptLastRequest()
        let inside = try #require(innerWindow.items.first)
        #expect(!innerWindow.canRemoveArchiveItems([inside]))
        #expect(innerWindow.archiveDropAddress == nil)
        guard case let .archive(root) = innerWindow.location else { Issue.record("No inner archive"); return }
        #expect(!innerWindow.canReorganizeArchiveItems([inside], to: root))
        await innerWindow.requestArchiveAddition([fixture.input.appendingPathComponent("Outer.txt")], to: root)
        #expect(innerWindow.pendingArchiveAddition == nil)
        #expect(innerWindow.error != nil)
    }
}

// MARK: - Support

/// Archives for the scenarios, in a temporary folder.
private struct Fixture {
    let root: URL
    let input: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("InnerArchive-\(UUID().uuidString)", isDirectory: true)
        input = root.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        try Data("outer".utf8).write(to: input.appendingPathComponent("Outer.txt"))
    }

    func cleanUp() {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: root.path)
        try? FileManager.default.removeItem(at: root)
    }

    func innerZip() async throws -> URL {
        let text = input.appendingPathComponent("Inner.txt")
        try Data("inner".utf8).write(to: text)
        let inner = input.appendingPathComponent("Inner.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [text], outputURL: inner, format: .zip, progress: { _ in })
        return inner
    }

    /// `Outer.<ext>` holding `Inner.zip` (with `Inner.txt`) and `Outer.txt`.
    func outerZip(format: ArchiveCompressionFormat = .zip, password: String? = nil) async throws -> URL {
        let inner = try await innerZip()
        let archive = root.appendingPathComponent("Outer.\(format.fileExtension)")
        var options = CompressionOptions(format: format)
        if password != nil { options.requiresPassword = true; options.encryptFileNames = true }
        try await NativeSevenZipArchiveEngine().createArchive(from: [inner, input.appendingPathComponent("Outer.txt")],
            outputURL: archive, options: options, password: password, progress: { _ in })
        try FileManager.default.removeItem(at: inner)
        return archive
    }

    /// `A.zip` › `B.zip` › `C.zip` (with `C.txt`).
    func chain() async throws -> URL {
        let text = input.appendingPathComponent("C.txt")
        try Data("c".utf8).write(to: text)
        var previous = text
        for name in ["C.zip", "B.zip"] {
            let archive = input.appendingPathComponent(name)
            try await NativeSevenZipArchiveEngine().createArchive(from: [previous], outputURL: archive, format: .zip, progress: { _ in })
            previous = archive
        }
        let archive = root.appendingPathComponent("A.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [previous], outputURL: archive, format: .zip, progress: { _ in })
        return archive
    }

    func openInner(named name: String = "Inner.zip", in outer: ArchiveOpenResult,
                   engine: NativeSevenZipArchiveEngine) async throws -> ArchiveOpenResult {
        let item = try #require(try await engine.items(at: outer.address).first { $0.name == name })
        return try await engine.openInnerArchive(item: item, password: nil)
    }

    /// Writes into the inner archive's copy, as an Add to Archive in its window does.
    func addNote(to inner: ArchiveOpenResult, engine: NativeSevenZipArchiveEngine, named name: String = "Note.txt") async throws {
        let note = input.appendingPathComponent(name)
        try Data("note".utf8).write(to: note)
        let copy = try await engine.archiveRootURL(for: inner.address)
        try await engine.addItems(from: [note], to: copy, internalPath: "", password: nil, progress: { _ in })
    }

    static func rootNames(of archive: URL, password: String? = nil) async throws -> [String] {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: archive, password: password)
        return try await engine.items(at: opened.address).map(\.name).sorted()
    }

    /// Names at the root of the archive reached through `path` (inner archive names).
    static func names(at path: [String], in archive: URL, password: String? = nil) async throws -> [String] {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        var current = try await engine.openArchive(at: archive, password: password)
        for name in path {
            let item = try #require(try await engine.items(at: current.address).first { $0.name == name })
            current = try await engine.openInnerArchive(item: item, password: nil)
        }
        return try await engine.items(at: current.address).map(\.name).sorted()
    }

    static func names(inInnerOf archive: URL, password: String? = nil) async throws -> [String] {
        try await names(at: ["Inner.zip"], in: archive, password: password)
    }
}

/// Revisions of shared-session changes an engine announced.
private final class SessionChangeLog: @unchecked Sendable {
    private let lock = NSLock()
    private var received: [UUID: [Int]] = [:]
    private var observer: NSObjectProtocol?

    init(engine: NativeSevenZipArchiveEngine) {
        observer = NotificationCenter.default.addObserver(forName: NativeSevenZipArchiveEngine.sessionDidChange,
            object: engine, queue: nil) { [weak self] notification in
            guard let id = notification.userInfo?["sessionID"] as? UUID,
                  let revision = notification.userInfo?["revision"] as? Int else { return }
            self?.lock.withLock { self?.received[id, default: []].append(revision) }
        }
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    func revisions(of sessionID: UUID) async -> [Int] { lock.withLock { received[sessionID] ?? [] } }
}

/// Write-back interface with scripted answers.
@MainActor
private final class ScriptedPresenter: ArchiveWriteBackPresenting {
    var progress: [String] = []
    var conflicts: [String] = []
    var failures: [String] = []
    var conflictChoices: [ArchiveWriteBackConflictChoice] = []
    var onFailure: (() -> ArchiveWriteBackFailureChoice)?
    var saveDestination: URL?
    var passwords: [String] = []
    var passwordRequests = 0

    func showProgress(inner: String, outer: String, cancel: @escaping @MainActor () -> Void) {
        progress.append("\(inner) → \(outer)")
    }
    func hideProgress() {}
    func resolveConflict(inner: String, outer: String) async -> ArchiveWriteBackConflictChoice {
        conflicts.append("\(inner) / \(outer)")
        return conflictChoices.isEmpty ? .discardChanges : conflictChoices.removeFirst()
    }
    func resolveFailure(inner: String, outer: String, error: any Error) async -> ArchiveWriteBackFailureChoice {
        failures.append("\(inner) / \(outer)")
        return onFailure?() ?? .saveInnerArchiveAs
    }
    func saveDestination(inner: String) async -> URL? { saveDestination }
    func password(outer: String, retry: Bool) async -> String? {
        passwordRequests += 1
        return passwords.isEmpty ? nil : passwords.removeFirst()
    }
}

/// Browser windows sharing one engine, with captured window requests and close actions.
@MainActor
private final class Windows {
    let engine: NativeSevenZipArchiveEngine
    let preferences: FileBrowserPreferences
    private let suite: String
    private var requests: [BrowserWindowRequest] = []
    private var states: [FileBrowserState] = []
    private(set) var closed: [String] = []

    init(engine: NativeSevenZipArchiveEngine) throws {
        self.engine = engine
        suite = "ZforgeTestSuite.InnerArchiveWindows-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
    }

    func make(name: String = "", handoff: ArchiveSessionHandoff? = nil) -> FileBrowserState {
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: ArchiveSessionClient(engine: engine),
            initialArchiveSession: handoff)
        state.configureOpenArchiveWindowAction { [weak self] in self?.requests.append($0) }
        state.configureWindowCloseAction { [weak self, weak state] in
            self?.closed.append(name)
            state?.close()
        }
        states.append(state)
        return state
    }

    /// The window the last Open of an inner archive asked for, started.
    func adoptLastRequest(name: String = "") async throws -> FileBrowserState {
        let handoff = try #require(requests.last?.archiveSession)
        let state = make(name: name, handoff: handoff)
        await state.start()
        return state
    }

    func closeAll() {
        for state in states.reversed() { state.close() }
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
    }
}

extension FileBrowserState {
    /// Waits for this window to apply a shared-session change announced by its engine.
    @MainActor
    func awaitArchiveSessionChange() async throws {
        for _ in 0..<10_000 where sessionChangeTask == nil { await Task.yield() }
        let task = try #require(sessionChangeTask, "No session change reached the window")
        await task.value
    }
}
