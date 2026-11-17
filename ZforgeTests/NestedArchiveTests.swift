import Foundation
import Testing
@testable import Zforge

/// D-98 / ZF-80: archives inside archives are browsed in place, at any depth, from copies
/// kept until their root archive closes. Every archive has one shared session (D-73); a
/// modified archive inside an archive is written back into the archive containing it when
/// it closes, and that one into its own when it closes, up to the archive on disk.
@Suite("Archives inside archives: navigation, shared sessions and write-back (D-98)")
struct NestedArchiveTests {
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

    // MARK: Archives inside archives (engine)

    @Test("An inner archive's copy is kept after it closes, for returning to it, until its root archive closes")
    func innerCopyLifetime() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let outer = try await engine.openArchive(at: archive, password: nil)
        let innerItem = try #require(try await engine.items(at: outer.address).first { $0.name == "Inner.zip" })
        #expect(innerItem.canNavigateAsArchive && innerItem.isArchiveInsideArchive)
        let inner = try await engine.openInnerArchive(item: innerItem, password: nil)
        let again = try await engine.openInnerArchive(item: innerItem, password: nil)
        #expect(again.address == inner.address, "The same inner archive shares one session")
        #expect(inner.displayName == "Inner.zip")
        #expect(inner.parentSessionID == outer.address.sessionID)
        let copy = try await engine.archiveRootURL(for: inner.address)
        let innerDirectory = ZforgeTemporaryStorage.archiveSessionsRoot().appendingPathComponent(inner.address.sessionID.uuidString)
        #expect(copy.path.hasPrefix(innerDirectory.path + "/"))

        // Closed, the unmodified inner archive keeps its copy while its root is open.
        await engine.closeSession(inner.address.sessionID)
        await engine.closeSession(again.address.sessionID)
        #expect(await engine.sessionReferences()[inner.address.sessionID] == 0)
        #expect(FileManager.default.fileExists(atPath: copy.path))
        #expect(await engine.pendingWriteBacks().isEmpty)
        let modified = try FileManager.default.attributesOfItem(atPath: copy.path)[.modificationDate] as? Date
        let returned = try await engine.openInnerArchive(item: innerItem, password: nil)
        #expect(returned.address == inner.address, "Returning reuses the kept copy")
        #expect(try FileManager.default.attributesOfItem(atPath: copy.path)[.modificationDate] as? Date == modified)
        #expect(try await engine.items(at: returned.address).map(\.name) == ["Inner.txt"])
        await engine.closeSession(returned.address.sessionID)

        // The root archive's last reference removes every copy made from it.
        await engine.closeSession(outer.address.sessionID)
        #expect(!FileManager.default.fileExists(atPath: innerDirectory.path))
        #expect(await engine.sessionReferences().isEmpty)
    }

    @Test("A root archive closed while an inner archive is still shown stays open until the inner one closes")
    func rootWaitsForShownInnerArchive() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        await engine.closeSession(outer.address.sessionID)
        #expect(await engine.sessionReferences()[outer.address.sessionID] == 0)
        #expect(try await engine.items(at: inner.address).map(\.name) == ["Inner.txt"])
        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.sessionReferences().isEmpty)
    }

    @Test("A modified inner archive is written back when it closes, replacing its entry, and stays for returning")
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
        #expect(await engine.pendingWriteBacks().isEmpty, "Nothing is due while the inner archive is open")

        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.pendingWriteBacks() == [inner.address.sessionID])
        #expect(try Data(contentsOf: archive) == before, "Nothing is written before the write-back")
        try await engine.writeBack(inner.address.sessionID)

        #expect(await engine.pendingWriteBacks().isEmpty)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        // The outer session shows the new archive (same addresses) and its windows are told.
        #expect(try await engine.items(at: outer.address).map(\.name).sorted() == ["Inner.zip", "Outer.txt"])
        #expect(await changes.revisions(of: outer.address.sessionID) == [1])
        #expect(await engine.sessionReferences()[inner.address.sessionID] == 0, "The written copy is kept")
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: fixture.root.path).filter { $0.hasPrefix(".zforge-") }
        #expect(leftovers.isEmpty)

        // Returning to it shows the written archive without a new copy, and closing it
        // again without changes writes nothing.
        let returned = try await fixture.openInner(in: outer, engine: engine)
        #expect(returned.address == inner.address)
        let written = try Data(contentsOf: archive)
        await engine.closeSession(returned.address.sessionID)
        #expect(await engine.pendingWriteBacks().isEmpty)
        #expect(try Data(contentsOf: archive) == written)
        await engine.closeSession(outer.address.sessionID)
        #expect(await engine.sessionReferences().isEmpty)
    }

    @Test("Going back into an inner archive whose write-back is due reuses its copy, and the write-back includes later changes")
    func returnBeforeWriteBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.pendingWriteBacks() == [inner.address.sessionID])
        // The user goes back into it before the write-back and changes it again.
        let returned = try await fixture.openInner(in: outer, engine: engine)
        #expect(returned.address == inner.address, "The pending copy is shown, not a new one from the outer archive")
        #expect(try await engine.items(at: returned.address).map(\.name).sorted() == ["Inner.txt", "Note.txt"])
        try await fixture.addNote(to: inner, engine: engine, named: "Second.txt")
        try await engine.writeBack(inner.address.sessionID)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt", "Second.txt"])

        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.pendingWriteBacks().isEmpty, "Everything was written")
    }

    @Test("Chains write back from the innermost archive up, whatever order they close in")
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
        try await fixture.addNote(to: b, engine: engine, named: "B note.txt")
        // Closed outer first: B, modified itself, waits until C is written into it.
        await engine.closeSession(a.address.sessionID)
        await engine.closeSession(b.address.sessionID)
        #expect(await engine.pendingWriteBacks().isEmpty, "B waits while C is open")
        await engine.closeSession(c.address.sessionID)
        await coordinator.finishPendingWriteBacks()

        #expect(presenter.progress == ["C.zip → B.zip", "B.zip → A.zip"], "Each archive is written back once, innermost first")
        #expect(await engine.sessionReferences().isEmpty, "The root closed once nothing was pending")
        #expect(try await Fixture.names(at: ["B.zip"], in: archive) == ["B note.txt", "C.zip"])
        #expect(try await Fixture.names(at: ["B.zip", "C.zip"], in: archive) == ["C.txt", "Note.txt"])
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

    @Test("When the inner archive's entry was replaced in the outer archive, its write-back reports the conflict")
    func replacedEntryConflict() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let ended = EndedSessionLog(engine: engine)
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        // The same session writes a different Inner.zip over the entry.
        let replacement = fixture.input.appendingPathComponent("Replacement", isDirectory: true)
        try FileManager.default.createDirectory(at: replacement, withIntermediateDirectories: true)
        let text = replacement.appendingPathComponent("Other.txt")
        try Data("other".utf8).write(to: text)
        let other = replacement.appendingPathComponent("Inner.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [text], outputURL: other, format: .zip, progress: { _ in })
        try await engine.addItems(from: [other], to: archive, internalPath: "", password: nil, progress: { _ in })
        #expect(await ended.sessions.isEmpty, "A modified copy is kept for the user to decide")

        await engine.closeSession(inner.address.sessionID)
        await #expect(throws: ArchiveEngineError.archiveChanged) { try await engine.writeBack(inner.address.sessionID) }
        try await engine.writeBack(inner.address.sessionID, replacingChangedOuter: true)
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
    }

    @Test("Removing or replacing an inner archive's entry ends its unmodified session and tells the windows")
    func removedEntryEndsSession() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let ended = EndedSessionLog(engine: engine)
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        let copyDirectory = ZforgeTemporaryStorage.archiveSessionsRoot().appendingPathComponent(inner.address.sessionID.uuidString)
        // Still shown: the session ends when its window leaves it, and refuses writes meanwhile.
        let innerItem = try #require(try await engine.items(at: outer.address).first { $0.name == "Inner.zip" })
        try await engine.removeItems([innerItem], password: nil, progress: { _ in })
        #expect(await ended.sessions == [inner.address.sessionID])
        #expect(await engine.sessionReferences()[inner.address.sessionID] == 1)
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        let copy = try await engine.archiveRootURL(for: inner.address)
        await #expect(throws: ArchiveEngineError.updateUnsupported) {
            try await engine.addItems(from: [note], to: copy, internalPath: "", password: nil, progress: { _ in })
        }
        await engine.closeSession(inner.address.sessionID)
        #expect(await engine.sessionReferences()[inner.address.sessionID] == nil)
        #expect(!FileManager.default.fileExists(atPath: copyDirectory.path))
        #expect(await engine.pendingWriteBacks().isEmpty)
        #expect(try await Fixture.rootNames(of: archive) == ["Outer.txt"], "Nothing writes it back")
    }

    @Test("An inner archive follows its entry when it is moved inside the outer archive")
    func movedEntryKeepsSession() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let folder = fixture.input.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("keep".utf8).write(to: folder.appendingPathComponent("Keep.txt"))
        let innerZip = try await fixture.innerZip()
        let archive = fixture.root.appendingPathComponent("Outer.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [innerZip, folder], outputURL: archive,
            format: .zip, progress: { _ in })
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let ended = EndedSessionLog(engine: engine)
        let outer = try await engine.openArchive(at: archive, password: nil)
        let inner = try await fixture.openInner(in: outer, engine: engine)
        try await fixture.addNote(to: inner, engine: engine)
        let rows = try await engine.items(at: outer.address)
        let innerItem = try #require(rows.first { $0.name == "Inner.zip" })
        let folderItem = try #require(rows.first { $0.name == "Folder" })
        guard case let .archive(folderAddress) = folderItem.location else { Issue.record("No folder"); return }
        _ = try await engine.reorganizeItems([innerItem], to: folderAddress, moving: true, password: nil,
            resolveConflict: { _ in .cancel }, progress: { _ in })
        #expect(await ended.sessions.isEmpty)

        await engine.closeSession(inner.address.sessionID)
        try await engine.writeBack(inner.address.sessionID)
        #expect(try await Fixture.names(at: ["Folder", "Inner.zip"], in: archive) == ["Inner.txt", "Note.txt"])
        #expect(try await Fixture.rootNames(of: archive) == ["Folder"], "Nothing is written at the old path")
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

    @Test("Open on an archive inside an archive enters it in place; Back and Forward return through its kept copy")
    @MainActor
    func entersInPlace() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
        guard case let .archive(outer) = window.location else { Issue.record("Outer archive not shown"); return }
        let innerItem = try #require(window.items.first { $0.name == "Inner.zip" })
        #expect(innerItem.isNavigableContainer)
        await window.open(innerItem)
        await window.innerArchiveSyncTask?.value

        guard case let .archive(address) = window.location, address.sessionID != outer.sessionID else {
            Issue.record("The inner archive was not entered"); return
        }
        #expect(window.title == "Inner.zip")
        #expect(window.pathComponents.map(\.name) == [fixture.root.lastPathComponent, "Outer.zip", "Inner.zip"])
        #expect(window.items.map(\.name) == ["Inner.txt"])
        #expect(window.innerArchiveHolds == [address.sessionID: 1])
        #expect(await engine.sessionReferences()[address.sessionID] == 1)

        await window.goBack()
        await window.innerArchiveSyncTask?.value
        #expect(window.location == .archive(outer))
        #expect(window.innerArchiveHolds.isEmpty, "Leaving it closes it")
        #expect(await engine.sessionReferences()[address.sessionID] == 0, "Its copy is kept")

        await window.goForward()
        await window.innerArchiveSyncTask?.value
        #expect(window.location == .archive(address))
        #expect(window.items.map(\.name) == ["Inner.txt"])
        #expect(window.innerArchiveHolds == [address.sessionID: 1], "Shown again, it is held again")

        // Leaving every archive keeps the root open until the window closes.
        await window.navigateBreadcrumb(to: try #require(window.pathComponents.first))
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.isEmpty)
        #expect(await engine.sessionReferences()[address.sessionID] == 0)
        window.close()
        await window.closingTask?.value
        #expect(await engine.sessionReferences().isEmpty)
    }

    @Test("Leaving a modified archive inside an archive writes it back; the outer listing reloads, keeping the selection")
    @MainActor
    func leavingWritesBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
        await window.open(try #require(window.items.first { $0.name == "Inner.zip" }))
        guard case let .archive(innerRoot) = window.location else { Issue.record("No inner archive"); return }
        #expect(window.isArchiveSessionWritable(innerRoot.sessionID))
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        await window.requestArchiveAddition([note], to: innerRoot)
        let request = try #require(window.pendingArchiveAddition)
        #expect(request.archiveURL.lastPathComponent == "Inner.zip")
        await window.confirmArchiveAddition(request)
        #expect(window.items.map(\.name).sorted() == ["Inner.txt", "Note.txt"])
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt"], "Written back only when it closes")

        await window.goUp()
        await window.innerArchiveSyncTask?.value
        let outerText = try #require(window.items.first { $0.name == "Outer.txt" })
        window.select(outerText)
        let writtenSize = window.items.first { $0.name == "Inner.zip" }?.size
        await coordinator.finishPendingWriteBacks()
        #expect(presenter.progress == ["Inner.zip → Outer.zip"])
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        for _ in 0..<10_000 where window.items.first(where: { $0.name == "Inner.zip" })?.size == writtenSize {
            await Task.yield()
        }
        #expect(window.items.first { $0.name == "Inner.zip" }?.size != writtenSize, "The outer listing shows the new entry")
        #expect(window.items.map(\.name).sorted() == ["Inner.zip", "Outer.txt"])
        #expect(window.selection == [outerText.id])
    }

    @Test("Leaving a chain of archives writes each one back into the next, up to the archive on disk")
    @MainActor
    func leavingChainWritesBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.chain()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        for name in ["A.zip", "B.zip", "C.zip"] { await window.open(try #require(window.items.first { $0.name == name })) }
        #expect(window.pathComponents.map(\.name) == [fixture.root.lastPathComponent, "A.zip", "B.zip", "C.zip"])
        guard case let .archive(c) = window.location else { Issue.record("No C.zip"); return }
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        await window.requestArchiveAddition([note], to: c)
        await window.confirmArchiveAddition(try #require(window.pendingArchiveAddition))
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.count == 2, "B.zip and C.zip are shown")

        await window.navigateBreadcrumb(to: try #require(window.pathComponents.first))
        await window.innerArchiveSyncTask?.value
        await coordinator.finishPendingWriteBacks()
        #expect(presenter.progress == ["C.zip → B.zip", "B.zip → A.zip"])
        #expect(try await Fixture.names(at: ["B.zip", "C.zip"], in: archive) == ["C.txt", "Note.txt"])
    }

    @Test("Closing a window inside a modified archive inside an archive writes it back")
    @MainActor
    func closingWindowWritesBack() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let presenter = ScriptedPresenter()
        let coordinator = ArchiveWriteBackCoordinator(engine: engine, presenter: presenter)
        coordinator.start()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
        await window.open(try #require(window.items.first { $0.name == "Inner.zip" }))
        guard case let .archive(innerRoot) = window.location else { Issue.record("No inner archive"); return }
        #expect(window.hasOpenedInnerArchives)
        let note = fixture.input.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        await window.requestArchiveAddition([note], to: innerRoot)
        await window.confirmArchiveAddition(try #require(window.pendingArchiveAddition))

        window.close()
        await window.closingTask?.value
        await coordinator.finishPendingWriteBacks()
        #expect(try await Fixture.names(inInnerOf: archive) == ["Inner.txt", "Note.txt"])
        #expect(await engine.sessionReferences().isEmpty, "The root closed after the write-back, with its copies")
    }

    @Test("Columns enters an archive inside an archive by selection within the preview limit, explicitly beyond it")
    @MainActor
    func columnsEntry() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine, viewMode: .columns)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let outerItem = try #require(window.items.first { $0.name == "Outer.zip" })
        await window.activateColumnItem(outerItem, in: window.location).value
        guard case .archive = window.location else { Issue.record("Outer archive not shown"); return }
        let outerColumn = window.location

        // Within the limit, selecting it shows its contents in the next column.
        let innerItem = try #require(window.items.first { $0.name == "Inner.zip" })
        #expect(window.opensColumnBranch(innerItem))
        await window.activateColumnItem(innerItem, in: outerColumn).value
        #expect(window.pathComponents.map(\.name) == [fixture.root.lastPathComponent, "Outer.zip", "Inner.zip"])
        #expect(window.items.map(\.name) == ["Inner.txt"])
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.count == 1)

        // Selecting another item closes it.
        let outerText = try #require(window.sortedColumnItems(at: outerColumn).first { $0.name == "Outer.txt" })
        await window.activateColumnItem(outerText, in: outerColumn).value
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.isEmpty)

        // Where previews are off (a network volume by default), selection only selects it;
        // Right Arrow, Return or a double click enter it.
        window.volumeClassifier = { _ in .network }
        await window.navigateBreadcrumb(to: try #require(window.pathComponents.first))
        await window.activateColumnItem(try #require(window.items.first { $0.name == "Outer.zip" }), in: window.location).value
        let remoteOuterColumn = window.location
        let remoteInner = try #require(window.items.first { $0.name == "Inner.zip" })
        #expect(!window.opensColumnBranch(remoteInner))
        await window.activateColumnItem(remoteInner, in: remoteOuterColumn).value
        #expect(window.location == remoteOuterColumn, "Selection alone does not enter it")
        #expect(window.selection == [remoteInner.id])
        await window.activateColumnItem(remoteInner, in: remoteOuterColumn, entersExplicitly: true).value
        #expect(window.pathComponents.last?.name == "Inner.zip")
        #expect(window.items.map(\.name) == ["Inner.txt"])

        // Return (Open) on the selection enters it the same way.
        await window.activateColumnItem(remoteInner, in: remoteOuterColumn).value
        #expect(window.pathComponents.last?.name == "Outer.zip")
        await window.open(remoteInner)
        #expect(window.pathComponents.last?.name == "Inner.zip")
        #expect(window.columnSelections[remoteOuterColumn] == remoteInner.id)
    }

    @Test("List expands an archive inside an archive inline; collapsing closes it; expanding all leaves it closed")
    @MainActor
    func listInlineExpansion() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        let outerItem = try #require(window.items.first { $0.name == "Outer.zip" })

        // Expanding everything opens the archive on disk but not the one inside it.
        await window.expandAllDescendants(of: outerItem)
        let innerItem = try #require(window.expandedChildren[outerItem.id]?.first { $0.name == "Inner.zip" })
        #expect(innerItem.canExpandInlineInList)
        #expect(!window.expandedItems.contains(innerItem.id))
        #expect(window.innerArchiveHolds.isEmpty)

        await window.toggleExpansion(innerItem)
        await window.innerArchiveSyncTask?.value
        #expect(window.expandedItems.contains(innerItem.id))
        #expect(window.flattenedList().contains { $0.depth == 2 && $0.item.name == "Inner.txt" })
        #expect(window.innerArchiveHolds.count == 1)

        await window.toggleExpansion(innerItem)
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.isEmpty, "Collapsing it closes it")
        await window.toggleExpansion(innerItem)
        await window.innerArchiveSyncTask?.value
        #expect(window.innerArchiveHolds.count == 1, "Expanded again from its kept copy")
    }

    @Test("Extracting a selection inside an archive expanded inline keeps its archive boundary")
    @MainActor
    func inlineSelectionExtraction() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
        let innerItem = try #require(window.items.first { $0.name == "Inner.zip" })
        await window.toggleExpansion(innerItem)
        let innerText = try #require(window.expandedChildren[innerItem.id]?.first { $0.name == "Inner.txt" })
        window.select(innerText)
        #expect(window.archiveToolbarAction == .extractSelected)
        #expect(await window.performArchiveToolbarAction() != nil)
        let expected = fixture.root.appendingPathComponent("Outer/Inner/Inner.txt")
        #expect(FileManager.default.fileExists(atPath: expected.path), "Extracted beside the archive on disk, per archive")
    }

    @Test("Windows inside an inner archive whose entry is removed leave it, and forget it in their history")
    @MainActor
    func removedEntryMovesWindowOut() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.outerZip()
        let engine = NativeSevenZipArchiveEngine()
        let windows = try Windows(engine: engine)
        defer { windows.closeAll() }
        let inside = windows.make()
        let remembering = windows.make()
        for window in [inside, remembering] {
            await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
            await window.open(try #require(window.items.first { $0.name == "Outer.zip" }))
            await window.open(try #require(window.items.first { $0.name == "Inner.zip" }))
        }
        guard case let .archive(innerRoot) = inside.location else { Issue.record("No inner archive"); return }
        await remembering.goBack()
        guard case let .archive(outer) = remembering.location else { Issue.record("No outer archive"); return }
        #expect(remembering.canGoForward)

        await remembering.deleteArchiveItems([try #require(remembering.items.first { $0.name == "Inner.zip" })])
        for _ in 0..<10_000 where remembering.canGoForward { await Task.yield() }
        #expect(!remembering.canGoForward, "Forward no longer leads into it")
        for _ in 0..<10_000 where inside.location != .archive(outer) { await Task.yield() }
        #expect(inside.location == .archive(outer))
        #expect(inside.pathComponents.map(\.name) == [fixture.root.lastPathComponent, "Outer.zip"])
        for _ in 0..<10_000 where inside.items.map(\.name) != ["Outer.txt"] { await Task.yield() }
        #expect(inside.items.map(\.name) == ["Outer.txt"])
        await inside.innerArchiveSyncTask?.value
        #expect(inside.innerArchiveHolds.isEmpty)
        #expect(await engine.sessionReferences()[innerRoot.sessionID] == nil, "It ended once no window showed it")
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

    @Test("An archive inside an archive that cannot be updated offers no write actions")
    @MainActor
    func readOnlyInnerArchiveInWindow() async throws {
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
        let window = windows.make()
        await window.navigateToSidebar(fixture.root, name: fixture.root.lastPathComponent)
        await window.open(try #require(window.items.first { $0.name == "Outer.tar.gz" }))
        await window.open(try #require(window.items.first { $0.name == "Inner.zip" }))
        let inside = try #require(window.items.first)
        #expect(!window.canRemoveArchiveItems([inside]))
        #expect(window.archiveDropAddress == nil)
        guard case let .archive(root) = window.location else { Issue.record("No inner archive"); return }
        #expect(!window.canReorganizeArchiveItems([inside], to: root))
        await window.requestArchiveAddition([fixture.input.appendingPathComponent("Outer.txt")], to: root)
        #expect(window.pendingArchiveAddition == nil)
        #expect(window.error != nil)
    }
}

// MARK: - Support

/// Archives for the scenarios, in a temporary folder.
private struct Fixture {
    let root: URL
    let input: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("NestedArchive-\(UUID().uuidString)", isDirectory: true)
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

    /// Writes into the inner archive's copy, as an Add to Archive inside it does.
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

    /// Names at the root of the archive reached through `path` (folder and archive names).
    static func names(at path: [String], in archive: URL, password: String? = nil) async throws -> [String] {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        var current = try await engine.openArchive(at: archive, password: password).address
        for name in path {
            let item = try #require(try await engine.items(at: current).first { $0.name == name })
            if item.isArchiveInsideArchive {
                current = try await engine.openInnerArchive(item: item, password: nil).address
            } else {
                guard case let .archive(address) = item.location else { throw ArchiveEngineError.itemNotFound }
                current = address
            }
        }
        return try await engine.items(at: current).map(\.name).sorted()
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

/// Inner archive sessions an engine announced as ended.
private final class EndedSessionLog: @unchecked Sendable {
    private let lock = NSLock()
    private var received: [UUID] = []
    private var observer: NSObjectProtocol?

    init(engine: NativeSevenZipArchiveEngine) {
        observer = NotificationCenter.default.addObserver(forName: NativeSevenZipArchiveEngine.sessionsDidEnd,
            object: engine, queue: nil) { [weak self] notification in
            guard let ids = notification.userInfo?["sessionIDs"] as? [UUID] else { return }
            self?.lock.withLock { self?.received += ids }
        }
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    var sessions: [UUID] { get async { lock.withLock { received } } }
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

/// Browser windows sharing one engine.
@MainActor
private final class Windows {
    let engine: NativeSevenZipArchiveEngine
    let preferences: FileBrowserPreferences
    private let suite: String
    private var states: [FileBrowserState] = []

    init(engine: NativeSevenZipArchiveEngine, viewMode: BrowserViewMode = .list) throws {
        self.engine = engine
        suite = "ZforgeTestSuite.NestedArchives-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = viewMode
    }

    func make() -> FileBrowserState {
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: ArchiveSessionClient(engine: engine))
        states.append(state)
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
