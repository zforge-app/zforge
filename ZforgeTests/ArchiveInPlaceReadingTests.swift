import CryptoKit
import Foundation
import Testing
@testable import Zforge

/// D-73 / ZF-55 stage 1: archives are read in place. Acceptance is structural, not timed (user,
/// 2026-11-02): these tests assert the absence of archive copies, bounded source reads while
/// listing, fingerprint checks, sequential compressed tar and the solid-block metadata.
@Suite("In-place archive reading (D-73)")
struct ArchiveInPlaceReadingTests {
    // MARK: Opening and browsing

    @Test("Opening and browsing list the original in place: no session folder and no copy of the archive",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func openingCopiesNothing(format: ArchiveCompressionFormat) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: format, largeFileBytes: 4 << 20, smallFiles: 50)
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let root = try await engine.items(at: opened.address)
        let folder = try #require(root.first { $0.name == "Small" })
        guard case let .archive(folderAddress) = folder.location else { throw ArchiveEngineError.itemNotFound }
        #expect(try await engine.items(at: folderAddress).count == 50)

        #expect(spy.copies.isEmpty, "Opening copied \(spy.copies)")
        let session = sessionDirectory(of: opened.address)
        #expect(!FileManager.default.fileExists(atPath: session.path), "Opening created \(session.path)")
        #expect(try copiesOf(archive).isEmpty)
    }

    @Test("Opening split volumes reads them in place without copying any volume")
    func splitVolumesInPlace() async throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        for name in ["split.7z.001", "split.zip.001"] {
            let spy = FileOperationRecorder()
            let meter = ArchiveSourceReadMeter()
            let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy), sourceReadMeter: meter)
            let first = fixtures.appendingPathComponent(name)
            let opened = try await engine.openArchive(at: first, password: nil)
            let item = try #require(try await engine.items(at: opened.address).first { $0.name == "payload.bin" })
            let preview = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
            #expect(try Data(contentsOf: preview).count == 20000)
            #expect(spy.copies.isEmpty, "\(name): \(spy.copies)")
            #expect(meter.bytesRead > 0)
            // The session holds the materialized item and nothing else.
            let stored = try regularFiles(below: sessionDirectory(of: opened.address))
            #expect(stored.map(\.lastPathComponent) == ["payload.bin"], "\(name): \(stored)")
            await engine.closeAllSessions()
        }
    }

    @Test("Listing ZIP and 7z reads a number of bytes bounded by the index, not by the archive size",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func listingReadsAreBoundedByTheIndex(format: ArchiveCompressionFormat) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: format, largeFileBytes: 16 << 20, smallFiles: 200)
        let size = try #require(try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize)
        let meter = ArchiveSourceReadMeter()
        let engine = NativeSevenZipArchiveEngine(sourceReadMeter: meter)
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let listed = meter.bytesRead
        #expect(listed > 0, "The meter observed no read")
        #expect(listed < 1 << 20, "Listing read \(listed) bytes of a \(size)-byte archive")
        #expect(listed * 16 < UInt64(size))
        // Browsing folders is served from the listing: no further reads.
        let root = try await engine.items(at: opened.address)
        for item in root where item.isDirectory {
            guard case let .archive(address) = item.location else { continue }
            _ = try await engine.items(at: address)
        }
        #expect(meter.bytesRead == listed)
    }

    @Test("Materializing reads the original in place and the session holds only the materialized item")
    func materializationStoresOnlyTheItem() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .zip, largeFileBytes: 1 << 20, smallFiles: 3)
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let large = try #require(try await engine.items(at: opened.address).first { $0.name == "Large.bin" })
        let preview = try await engine.materialize(item: large, purpose: .preview, automaticLimit: nil)
        #expect(try Data(contentsOf: preview) == Data(contentsOf: fixture.input.appendingPathComponent("Large.bin")))
        let stored = try regularFiles(below: sessionDirectory(of: opened.address))
        #expect(stored.map(\.lastPathComponent) == ["Large.bin"])
        #expect(spy.copies.isEmpty)
        #expect(try copiesOf(archive).isEmpty)
    }

    // MARK: Extraction, validation and writes

    @Test("Extraction and validation read the original: no copy and no working folder")
    func extractionAndValidationCopyNothing() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .sevenZip, largeFileBytes: 1 << 20, smallFiles: 5)
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let sessions = ZforgeTemporaryStorage.archiveSessionsRoot()

        try await engine.testArchive(at: archive, password: nil)
        let whole = fixture.root.appendingPathComponent("Whole")
        try await engine.extractArchive(at: archive, to: whole, password: nil,
            resolveConflict: { _ in .cancel }, progress: { _ in })
        #expect(try Data(contentsOf: whole.appendingPathComponent("Large.bin"))
            == Data(contentsOf: fixture.input.appendingPathComponent("Large.bin")))

        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let folder = try #require(try await engine.items(at: opened.address).first { $0.name == "Small" })
        let selected = fixture.root.appendingPathComponent("Selected")
        try await engine.extractItems([folder], to: selected, password: nil,
            resolveConflict: { _ in .cancel }, progress: { _ in })
        #expect(try FileManager.default.contentsOfDirectory(atPath: selected.appendingPathComponent("Small").path).count == 5)

        #expect(spy.copies.isEmpty, "\(spy.copies)")
        #expect(spy.createdDirectories.allSatisfy { !$0.path.hasPrefix(sessions.path + "/") },
                "Working folders: \(spy.createdDirectories)")
        #expect(!FileManager.default.fileExists(atPath: sessionDirectory(of: opened.address).path))
    }

    @Test("Adding and removing write the updated archive once beside the original, without copies",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func writesAreOnePass(format: ArchiveCompressionFormat) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: format, largeFileBytes: 1 << 20, smallFiles: 3)
        let added = fixture.root.appendingPathComponent("Added", isDirectory: true)
        try FileManager.default.createDirectory(at: added.appendingPathComponent("Nested"), withIntermediateDirectories: true)
        try Data("added".utf8).write(to: added.appendingPathComponent("Nested/Added.txt"))
        try FileManager.default.createSymbolicLink(atPath: added.appendingPathComponent("Link.txt").path,
                                                   withDestinationPath: "Nested/Added.txt")
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let sessions = ZforgeTemporaryStorage.archiveSessionsRoot()
        let originalIdentity = try fileIdentity(archive)

        try await engine.addItems(from: [added], to: archive, internalPath: "Small", password: nil, progress: { _ in })
        #expect(try fileIdentity(archive) != originalIdentity, "The original was not replaced")
        let opened = try await engine.openArchive(at: archive, password: nil)
        guard case let .archive(rootAddress) = try #require(try await engine.items(at: opened.address)
            .first { $0.name == "Small" }).location else { throw ArchiveEngineError.itemNotFound }
        let addedFolder = try #require(try await engine.items(at: rootAddress).first { $0.name == "Added" })
        guard case let .archive(addedAddress) = addedFolder.location else { throw ArchiveEngineError.itemNotFound }
        let addedItems = try await engine.items(at: addedAddress)
        #expect(Set(addedItems.map(\.name)) == ["Nested", "Link.txt"])
        #expect(addedItems.first { $0.name == "Link.txt" }?.isSymbolicLink == true)

        try await engine.removeItems([addedFolder], password: nil, progress: { _ in })
        let reopened = try await engine.openArchive(at: archive, password: nil)
        guard case let .archive(smallAddress) = try #require(try await engine.items(at: reopened.address)
            .first { $0.name == "Small" }).location else { throw ArchiveEngineError.itemNotFound }
        #expect(try await engine.items(at: smallAddress).count == 3)
        await engine.closeAllSessions()

        #expect(spy.copies.isEmpty, "\(spy.copies)")
        #expect(spy.createdDirectories.allSatisfy { !$0.path.hasPrefix(sessions.path + "/") },
                "Working folders: \(spy.createdDirectories)")
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: fixture.root.path).filter { $0.hasPrefix(".zforge-") }
        #expect(leftovers.isEmpty)
    }

    /// Regression (found by a crashed Unit run, 2026-11-02): the archive is read in place, so it
    /// can be replaced between the listing and the extraction of one read; an index from the old
    /// listing then lies past the new archive's items and the ZIP handler read out of bounds.
    @Test("Extraction refuses an item index past the archive's items instead of crashing")
    func extractionRejectsStaleIndex() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .zip, largeFileBytes: 1 << 10, smallFiles: 1)
        let destination = fixture.root.appendingPathComponent("Output", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let operation = ZFSevenZipOperation()
        #expect(throws: (any Error).self) {
            try ZFSevenZipBridge.extract(atPath: archive.path, password: nil, indices: [NSNumber(value: 1_000)],
                destinations: [destination.appendingPathComponent("Stale.bin").path],
                rootPath: destination.path, byteLimit: .max, operation: operation)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: destination.path).isEmpty)
    }

    /// D-73 stage 3: an archive replaced, with the same paths and more items, between the
    /// session's listing and an extraction is never extracted, not even its folders.
    @Test("Extraction never writes items of an archive replaced after it was listed", arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func replacedArchiveIsNeverExtracted(format: ArchiveCompressionFormat) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: format, largeFileBytes: 1 << 12, smallFiles: 3)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: archive, password: nil)
        let folder = try #require(try await engine.items(at: opened.address).first { $0.name == "Small" })
        try await fixture.replace(archive, withMoreItemsOf: format)
        let destination = fixture.root.appendingPathComponent("Output", isDirectory: true)
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            try await engine.extractItems([folder], to: destination, password: nil,
                resolveConflict: { _ in .cancel }, progress: { _ in })
        }
        #expect(try regularFiles(below: destination).isEmpty)
    }

    /// The same, when the replacement happens after the read has opened the archive: the
    /// check runs on the opened archive, before the first folder or file is written.
    @Test("A replacement after the read opened the archive is detected before anything is written")
    func replacementAfterOpeningIsDetected() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .zip, largeFileBytes: 1 << 12, smallFiles: 3)
        let fingerprint = try ArchiveSourceFingerprint.capture([archive])
        let destination = fixture.root.appendingPathComponent("Output", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let replacement = try await fixture.makeReplacement(for: archive, format: .zip)
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            try await NativeSevenZipBackend().extract(at: archive, password: nil, paths: [], destination: destination,
                verify: {
                    _ = try? FileManager.default.replaceItemAt(archive, withItemAt: replacement)
                    return fingerprint.matches([archive])
                })
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: destination.path).isEmpty)
    }

    // MARK: Fingerprint

    @Test("The fingerprint detects size, date and file replacement, and is stable otherwise")
    func fingerprintDetectsChanges() throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let file = fixture.root.appendingPathComponent("Archive.zip")
        try Data("original".utf8).write(to: file)
        let original = try ArchiveSourceFingerprint.capture([file])
        #expect(original.matches([file]))
        #expect(try ArchiveSourceFingerprint.capture([file]) == original)

        // Same size, different modification date; restoring the exact date matches again.
        let date = try #require(try file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
        let exact = try modificationTime(of: file)
        try FileManager.default.setAttributes([.modificationDate: date.addingTimeInterval(10)], ofItemAtPath: file.path)
        #expect(!original.matches([file]))
        try setModificationTime(exact, of: file)
        #expect(original.matches([file]))

        // Same size and exact date, different file (atomic replacement).
        let replacement = fixture.root.appendingPathComponent("Replacement")
        try Data("changed!".utf8).write(to: replacement)
        try setModificationTime(exact, of: replacement)
        _ = try FileManager.default.replaceItemAt(file, withItemAt: replacement)
        #expect(try modificationTime(of: file) == exact)
        #expect(!original.matches([file]))

        // Size change and disappearance.
        let current = try ArchiveSourceFingerprint.capture([file])
        try Data("longer content".utf8).write(to: file)
        #expect(!current.matches([file]))
        try FileManager.default.removeItem(at: file)
        #expect(!current.matches([file]))
    }

    @Test("Reads of a changed archive fail cleanly without publishing output, and writes report the change")
    func changedArchiveFailsCleanly() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .zip, largeFileBytes: 1 << 16, smallFiles: 2)
        let engine = NativeSevenZipArchiveEngine()
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let items = try await engine.items(at: opened.address)
        let large = try #require(items.first { $0.name == "Large.bin" })

        // Another writer changes the archive in place (same size, new date).
        let date = try #require(try archive.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
        try FileManager.default.setAttributes([.modificationDate: date.addingTimeInterval(60)], ofItemAtPath: archive.path)

        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            _ = try await engine.materialize(item: large, purpose: .preview, automaticLimit: nil)
        }
        #expect(try regularFiles(below: sessionDirectory(of: opened.address)).isEmpty)
        let destination = fixture.root.appendingPathComponent("Output")
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            try await engine.extractItems([large], to: destination, password: nil,
                resolveConflict: { _ in .cancel }, progress: { _ in })
        }
        #expect(!FileManager.default.fileExists(atPath: destination.appendingPathComponent("Large.bin").path))
        let exported = fixture.root.appendingPathComponent("Exported.bin")
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            try await engine.exportItem(large, to: exported, password: nil, progress: { _ in })
        }
        #expect(!FileManager.default.fileExists(atPath: exported.path))
        let before = try Data(contentsOf: archive)
        await #expect(throws: ArchiveEngineError.archiveChanged) {
            try await engine.removeItems([large], password: nil, progress: { _ in })
        }
        #expect(try Data(contentsOf: archive) == before)
    }

    // MARK: Publication

    @Test("Export writes files and folders directly at the destination, with no ancestors and no leftovers")
    func exportPublishesDirectly() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .sevenZip, largeFileBytes: 1 << 16, smallFiles: 3)
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let items = try await engine.items(at: opened.address)
        let large = try #require(items.first { $0.name == "Large.bin" })
        let folder = try #require(items.first { $0.name == "Small" })
        let output = fixture.root.appendingPathComponent("Output", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        try await engine.exportItem(large, to: output.appendingPathComponent("Copy.bin"), password: nil, progress: { _ in })
        try await engine.exportItem(folder, to: output.appendingPathComponent("Folder"), password: nil, progress: { _ in })
        try await engine.exportPromisedItem(large, to: output.appendingPathComponent("Promised.bin"), password: nil, progress: { _ in })
        try await engine.exportPromisedItem(folder, to: output.appendingPathComponent("PromisedFolder"), password: nil, progress: { _ in })

        let expected = try Data(contentsOf: fixture.input.appendingPathComponent("Large.bin"))
        #expect(try Data(contentsOf: output.appendingPathComponent("Copy.bin")) == expected)
        #expect(try Data(contentsOf: output.appendingPathComponent("Promised.bin")) == expected)
        for name in ["Folder", "PromisedFolder"] {
            let names = try FileManager.default.contentsOfDirectory(atPath: output.appendingPathComponent(name).path)
            #expect(Set(names) == Set((0..<3).map { "Item-\($0).txt" }), "\(name): \(names)")
        }
        #expect(Set(try FileManager.default.contentsOfDirectory(atPath: output.path))
            == ["Copy.bin", "Folder", "Promised.bin", "PromisedFolder"])
        #expect(spy.copies.isEmpty, "\(spy.copies)")
        #expect(!FileManager.default.fileExists(atPath: sessionDirectory(of: opened.address).path))

        // A promise never replaces an existing destination.
        let existing = output.appendingPathComponent("Existing.bin")
        try Data("existing".utf8).write(to: existing)
        await #expect(throws: (any Error).self) {
            try await engine.exportPromisedItem(large, to: existing, password: nil, progress: { _ in })
        }
        #expect(try Data(contentsOf: existing) == Data("existing".utf8))
    }

    // MARK: Parent index

    @Test("The parent index returns the same children as scanning every entry")
    func parentIndexMatchesScan() throws {
        let raw = ["a", "a/b", "a/b/c.txt", "a/b2.txt", "a//double", "Ação 🗜️/x", "Ação 🗜️", "Cafe\u{301}/menu.txt",
                   "z/\u{301}combining", "deep/1/2/3/4.txt", "file.txt", "dir/", "dir/child"]
        var entries: [String: ArchiveEntry] = [:]
        for path in raw {
            let safe = try ArchivePathPolicy.safePath(path)
            entries[safe] = ArchiveEntry(path: safe, isDirectory: false, size: nil, packedSize: nil, modified: nil,
                created: nil, accessed: nil, encrypted: false, checksum: nil, method: nil, attributes: nil)
        }
        entries = ArchiveEntry.withParents(entries)
        let index = ArchiveEntry.childIndex(of: entries)
        let parents = Set(entries.keys).union(["", "missing", "Caf\u{e9}", "a/", "deep/1"])
        for parent in parents {
            let normalized = ArchivePathPolicy.normalized(parent)
            let indexed = Set((index[normalized] ?? []).map { path in
                normalized.isEmpty ? path : normalized + "/" + String(path[path.index(after: path.lastIndex(of: "/")!)...])
            })
            #expect(indexed == scannedChildren(of: normalized, in: entries), "Parent \(parent)")
        }
    }

    @Test("Folder listings through the index match the archive's folders")
    func engineListingUsesIndex() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let archive = try await fixture.storedArchive(format: .zip, largeFileBytes: 1 << 10, smallFiles: 30)
        let engine = NativeSevenZipArchiveEngine()
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let root = try await engine.items(at: opened.address)
        #expect(Set(root.map(\.name)) == ["Large.bin", "Small"])
        let small = try #require(root.first { $0.name == "Small" })
        guard case let .archive(address) = small.location else { throw ArchiveEngineError.itemNotFound }
        let children = try await engine.items(at: address)
        #expect(Set(children.map(\.name)) == Set((0..<30).map { "Item-\($0).txt" }))
        #expect(children.allSatisfy {
            guard case let .archive(child) = $0.location else { return false }
            return child.internalPath == "Small/" + $0.name
        })
    }

    // MARK: Compressed tar streams

    @Test("Compressed tar lists and extracts by streaming, without a temporary tar",
          arguments: [ArchiveCompressionFormat.gzip, .bzip2, .xz])
    func compressedTarStreams(format: ArchiveCompressionFormat) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let folder = fixture.input.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Nested"), withIntermediateDirectories: true)
        try Data("first".utf8).write(to: fixture.input.appendingPathComponent("First.txt"))
        try Data("nested".utf8).write(to: folder.appendingPathComponent("Nested/Nested.txt"))
        try Data("second".utf8).write(to: folder.appendingPathComponent("Second.txt"))
        let archive = fixture.root.appendingPathComponent("Stream.tar.\(format.fileExtension)")
        try await NativeSevenZipArchiveEngine().createArchive(
            from: [fixture.input.appendingPathComponent("First.txt"), folder], outputURL: archive,
            options: CompressionOptions(format: format, level: 1), password: nil, progress: { _ in })
        try await verifyStreamedTar(archive, workspace: fixture, expected: [
            "First.txt": "first", "Folder/Second.txt": "second", "Folder/Nested/Nested.txt": "nested"
        ])
    }

    @Test("A zstd-compressed tar streams like the other compressed tar formats")
    func zstdTarStream() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/stream.tar.zst")
        let archive = fixture.root.appendingPathComponent("stream.tar.zst")
        try FileManager.default.copyItem(at: source, to: archive)
        try await verifyStreamedTar(archive, workspace: fixture, expected: [
            "First.txt": "first entry\n", "Folder/Second.txt": "second entry\n", "Folder/Third.txt": "third entry\n"
        ])
    }

    @Test("Materializing an early tar entry stops decompressing after it")
    func tarStreamStopsEarly() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let small = fixture.input.appendingPathComponent("A-Small.txt")
        let large = fixture.input.appendingPathComponent("B-Large.bin")
        try Data("small".utf8).write(to: small)
        try randomData(16 << 20).write(to: large)
        let archive = fixture.root.appendingPathComponent("Early.tar.gz")
        try await NativeSevenZipArchiveEngine().createArchive(from: [small, large], outputURL: archive,
            options: CompressionOptions(format: .gzip, level: 1), password: nil, progress: { _ in })
        let size = UInt64(try #require(try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize))
        let meter = ArchiveSourceReadMeter()
        let engine = NativeSevenZipArchiveEngine(sourceReadMeter: meter)
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        // Listing a stream reads every header, so the whole stream once.
        #expect(meter.bytesRead >= size)
        let item = try #require(try await engine.items(at: opened.address).first { $0.name == "A-Small.txt" })
        meter.reset()
        let preview = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
        #expect(try String(contentsOf: preview, encoding: .utf8) == "small")
        #expect(meter.bytesRead < size / 2, "Read \(meter.bytesRead) of \(size) bytes for the first entry")
    }

    @Test("A corrupted compressed tar fails to open instead of listing partial data")
    func corruptedTarStream() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let payload = fixture.input.appendingPathComponent("Payload.bin")
        try randomData(1 << 20).write(to: payload)
        let archive = fixture.root.appendingPathComponent("Corrupt.tar.gz")
        try await NativeSevenZipArchiveEngine().createArchive(from: [payload, fixture.input.appendingPathComponent("Small")],
            outputURL: archive, options: CompressionOptions(format: .gzip, level: 1), password: nil, progress: { _ in })
        var bytes = try Data(contentsOf: archive)
        bytes.removeLast(bytes.count / 3)
        try bytes.write(to: archive)
        let engine = NativeSevenZipArchiveEngine()
        await #expect(throws: (any Error).self) { _ = try await engine.openArchive(at: archive, password: nil) }
        await engine.closeAllSessions()
    }

    // MARK: Solid blocks

    @Test("Solid 7z members expose their block; non-solid 7z, ZIP and directories do not")
    func solidBlockMetadata() async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let files = try (0..<3).map { index -> URL in
            let url = fixture.input.appendingPathComponent("File-\(index).txt")
            try Data(String(repeating: "solid block \(index) ", count: 200).utf8).write(to: url)
            return url
        }
        let folder = fixture.input.appendingPathComponent("Small")
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }

        let solid = fixture.root.appendingPathComponent("Solid.7z")
        try await engine.createArchive(from: files + [folder], outputURL: solid,
            options: CompressionOptions(format: .sevenZip), password: nil, progress: { _ in })
        let solidItems = try await engine.items(at: try await engine.openArchive(at: solid, password: nil).address)
        let blocks = Set(solidItems.filter { !$0.isDirectory }.map(\.solidBlock))
        #expect(blocks.count == 1)
        let block = try #require(blocks.first ?? nil)
        let packed = try #require(block.packedSize)
        let archiveSize = Int64(try #require(try solid.resourceValues(forKeys: [.fileSizeKey]).fileSize))
        #expect(packed > 0 && packed < archiveSize)
        #expect(solidItems.filter(\.isDirectory).allSatisfy { $0.solidBlock == nil })

        var nonSolidOptions = CompressionOptions(format: .sevenZip)
        nonSolidOptions.solid = false
        for (name, options) in [("NonSolid.7z", nonSolidOptions), ("Plain.zip", CompressionOptions(format: .zip))] {
            let archive = fixture.root.appendingPathComponent(name)
            try await engine.createArchive(from: files, outputURL: archive, options: options, password: nil, progress: { _ in })
            let items = try await engine.items(at: try await engine.openArchive(at: archive, password: nil).address)
            #expect(items.count == 3)
            #expect(items.allSatisfy { $0.solidBlock == nil }, "\(name)")
        }
    }

    @Test("Compressed tar and single-file streams use the whole archive as their block",
          arguments: ["Stream.tar.gz", "Single.txt.gz", "Single.txt.xz", "Single.txt.bz2"])
    func streamBlocksAreTheWholeArchive(name: String) async throws {
        let fixture = try Workspace()
        defer { fixture.cleanUp() }
        let text = fixture.input.appendingPathComponent("Single.txt")
        try Data(String(repeating: "stream ", count: 500).utf8).write(to: text)
        let format: ArchiveCompressionFormat = name.hasSuffix("gz") ? .gzip : name.hasSuffix("xz") ? .xz : .bzip2
        let sources = name.contains(".tar.") ? [text, fixture.input.appendingPathComponent("Small")] : [text]
        let archive = fixture.root.appendingPathComponent(name)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        try await engine.createArchive(from: sources, outputURL: archive, options: CompressionOptions(format: format),
            password: nil, progress: { _ in })
        let size = Int64(try #require(try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize))
        let items = try await engine.items(at: try await engine.openArchive(at: archive, password: nil).address)
        let files = items.filter { !$0.isDirectory }
        #expect(!files.isEmpty)
        #expect(files.allSatisfy { $0.solidBlock == ArchiveSolidBlock(packedSize: size) }, "\(files.map(\.solidBlock))")
    }

    // MARK: Helpers

    private func verifyStreamedTar(_ archive: URL, workspace: Workspace, expected: [String: String]) async throws {
        let spy = FileOperationRecorder()
        let engine = NativeSevenZipArchiveEngine(fileManager: FileOperationSpy(recorder: spy))
        let sessions = ZforgeTemporaryStorage.archiveSessionsRoot()
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        #expect(!FileManager.default.fileExists(atPath: sessionDirectory(of: opened.address).path),
                "Opening wrote a temporary tar into the session")
        var listed: [String: BrowserItem] = [:]
        var pending = [opened.address]
        while let address = pending.popLast() {
            for item in try await engine.items(at: address) {
                guard case let .archive(child) = item.location else { continue }
                if item.isDirectory { pending.append(child) } else { listed[child.internalPath] = item }
            }
        }
        #expect(Set(listed.keys) == Set(expected.keys))
        for (path, text) in expected {
            let item = try #require(listed[path])
            #expect(item.size == Int64(text.utf8.count))
            let preview = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
            #expect(try String(contentsOf: preview, encoding: .utf8) == text, "\(path)")
        }
        // Only the materialized entries are stored, never the tar.
        let stored = try regularFiles(below: sessionDirectory(of: opened.address))
        #expect(stored.allSatisfy { $0.pathExtension != "tar" } && stored.count == expected.count, "\(stored)")

        let whole = workspace.root.appendingPathComponent("Whole-\(archive.lastPathComponent)")
        try await engine.extractArchive(at: archive, to: whole, password: nil,
            resolveConflict: { _ in .cancel }, progress: { _ in })
        let folder = try #require(try await engine.items(at: opened.address).first { $0.isDirectory })
        let selected = workspace.root.appendingPathComponent("Selected-\(archive.lastPathComponent)")
        try await engine.extractItems([folder], to: selected, password: nil,
            resolveConflict: { _ in .cancel }, progress: { _ in })
        for (path, text) in expected {
            #expect(try String(contentsOf: whole.appendingPathComponent(path), encoding: .utf8) == text)
            let inFolder = path.hasPrefix(folder.name + "/")
            #expect(FileManager.default.fileExists(atPath: selected.appendingPathComponent(path).path) == inFolder, "\(path)")
        }
        #expect(spy.copies.isEmpty, "\(spy.copies)")
        #expect(spy.createdDirectories.allSatisfy { $0.path.hasPrefix(sessionDirectory(of: opened.address).path + "/")
            || !$0.path.hasPrefix(sessions.path + "/") }, "\(spy.createdDirectories)")
    }

    private func scannedChildren(of parent: String, in entries: [String: ArchiveEntry]) -> Set<String> {
        // The listing algorithm used before the index (every entry scanned per folder).
        func immediateChildName(path: String) -> String? {
            if parent.isEmpty {
                guard !path.isEmpty else { return nil }
                return String(path.split(separator: "/", maxSplits: 1).first ?? "")
            }
            let prefix = parent + "/"
            guard path.hasPrefix(prefix) else { return nil }
            let remainder = String(path.dropFirst(prefix.count))
            guard !remainder.isEmpty else { return nil }
            return String(remainder.split(separator: "/", maxSplits: 1).first ?? "")
        }
        return Set(entries.values.compactMap { entry in
            guard let childName = immediateChildName(path: entry.path) else { return nil }
            let childPath = parent.isEmpty ? childName : "\(parent)/\(childName)"
            guard entry.path == childPath || entry.path == childPath + "/" else { return nil }
            return childPath
        })
    }
}

// MARK: - Support

private func sessionDirectory(of address: ArchiveAddress) -> URL {
    ZforgeTemporaryStorage.archiveSessionsRoot().appendingPathComponent(address.sessionID.uuidString, isDirectory: true)
}

private func regularFiles(below directory: URL) throws -> [URL] {
    guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
    let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])
    return try (enumerator?.allObjects as? [URL] ?? []).filter {
        try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
    }
}

/// Files under Zforge's temporary storage with the archive's exact content.
private func copiesOf(_ archive: URL) throws -> [URL] {
    let original = try Data(contentsOf: archive)
    let digest = SHA256.hash(data: original)
    return try regularFiles(below: ZforgeTemporaryStorage.root()).filter { candidate in
        guard (try? candidate.resourceValues(forKeys: [.fileSizeKey]).fileSize) == original.count,
              let data = try? Data(contentsOf: candidate) else { return false }
        return SHA256.hash(data: data) == digest
    }
}

private func fileIdentity(_ url: URL) throws -> UInt64 {
    var status = stat()
    guard stat(url.path, &status) == 0 else { throw ArchiveEngineError.itemNotFound }
    return UInt64(status.st_ino)
}

private func modificationTime(of url: URL) throws -> [Int] {
    var status = stat()
    guard stat(url.path, &status) == 0 else { throw ArchiveEngineError.itemNotFound }
    return [Int(status.st_mtimespec.tv_sec), Int(status.st_mtimespec.tv_nsec)]
}

private func setModificationTime(_ time: [Int], of url: URL) throws {
    var times = [timespec(tv_sec: 0, tv_nsec: Int(UTIME_OMIT)), timespec(tv_sec: time[0], tv_nsec: time[1])]
    guard utimensat(AT_FDCWD, url.path, &times, 0) == 0 else { throw ArchiveEngineError.itemNotFound }
}

private func randomData(_ count: Int) -> Data {
    var generator = SystemRandomNumberGenerator()
    var data = Data(count: count)
    data.withUnsafeMutableBytes { raw in
        let words = raw.bindMemory(to: UInt64.self)
        for index in words.indices { words[index] = generator.next() }
    }
    return data
}

/// A temporary folder with an `Input` folder of sources.
private struct Workspace {
    let root: URL
    let input: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("InPlaceReading-\(UUID().uuidString)", isDirectory: true)
        input = root.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: input.appendingPathComponent("Small"), withIntermediateDirectories: true)
    }

    func cleanUp() { try? FileManager.default.removeItem(at: root) }

    /// A different archive at a sibling path: the same paths (other contents) and more items.
    func makeReplacement(for archive: URL, format: ArchiveCompressionFormat) async throws -> URL {
        let other = root.appendingPathComponent("Replacement-\(UUID().uuidString)", isDirectory: true)
        let small = other.appendingPathComponent("Small", isDirectory: true)
        try FileManager.default.createDirectory(at: small, withIntermediateDirectories: true)
        for index in 0..<6 { try Data("replaced \(index)".utf8).write(to: small.appendingPathComponent("Item-\(index).txt")) }
        try Data("replaced".utf8).write(to: other.appendingPathComponent("Large.bin"))
        let output = root.appendingPathComponent("Replacement-\(UUID().uuidString).\(format.fileExtension)")
        try await NativeSevenZipArchiveEngine().createArchive(
            from: [other.appendingPathComponent("Large.bin"), small], outputURL: output,
            options: CompressionOptions(format: format, level: 0), password: nil, progress: { _ in })
        return output
    }

    func replace(_ archive: URL, withMoreItemsOf format: ArchiveCompressionFormat) async throws {
        _ = try FileManager.default.replaceItemAt(archive, withItemAt: try await makeReplacement(for: archive, format: format))
    }

    /// An archive (stored, level 0) holding `Large.bin` of random bytes and `Small/Item-N.txt`.
    func storedArchive(format: ArchiveCompressionFormat, largeFileBytes: Int, smallFiles: Int) async throws -> URL {
        let large = input.appendingPathComponent("Large.bin")
        try randomData(largeFileBytes).write(to: large)
        let small = input.appendingPathComponent("Small", isDirectory: true)
        for index in 0..<smallFiles {
            try Data("small item \(index)".utf8).write(to: small.appendingPathComponent("Item-\(index).txt"))
        }
        let archive = root.appendingPathComponent("Archive.\(format.fileExtension)")
        try await NativeSevenZipArchiveEngine().createArchive(from: [large, small], outputURL: archive,
            options: CompressionOptions(format: format, level: 0), password: nil, progress: { _ in })
        return archive
    }
}

/// Copies and folder creations made through the engine's file manager.
private final class FileOperationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedCopies: [String] = []
    private var recordedDirectories: [URL] = []

    var copies: [String] { lock.withLock { recordedCopies } }
    var createdDirectories: [URL] { lock.withLock { recordedDirectories } }
    func copied(_ description: String) { lock.withLock { recordedCopies.append(description) } }
    func created(_ url: URL) { lock.withLock { recordedDirectories.append(url.standardizedFileURL) } }
}

/// A file manager that reports to a recorder; the engine owns it.
private final class FileOperationSpy: FileManager {
    private let recorder: FileOperationRecorder

    init(recorder: FileOperationRecorder) {
        self.recorder = recorder
        super.init()
    }

    override func copyItem(at srcURL: URL, to dstURL: URL) throws {
        recorder.copied("\(srcURL.path) -> \(dstURL.path)")
        try super.copyItem(at: srcURL, to: dstURL)
    }

    override func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        recorder.copied("\(srcPath) -> \(dstPath)")
        try super.copyItem(atPath: srcPath, toPath: dstPath)
    }

    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool,
                                  attributes: [FileAttributeKey: Any]? = nil) throws {
        recorder.created(url)
        try super.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
}
