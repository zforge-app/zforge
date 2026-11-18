import AppKit
import Foundation
import Testing
@testable import Zforge

/// ZF-83 / D-101: split archives have the features of whole archives. The fixtures cover the four
/// volume schemes: `.7z.NNN` and `.zip.NNN` (byte slices of one archive, 7-Zip `-v`), a
/// WinZip-style `spanned.zip` + `.z01`/`.z02` (Info-ZIP `zip -s 64k`), a RAR5 `parts.partN.rar`
/// set (RARLAB `rar` 7.23 `-v16k`) and the same RAR set renamed to the legacy `.rar`/`.r00`/`.r01`
/// names (RAR 7 no longer writes legacy names; 7-Zip follows a set by its names).
@Suite("Split archives (ZF-83)")
struct SplitArchiveTests {
    struct SplitSet: CustomTestStringConvertible, Sendable {
        let first: String
        let volumes: [String]
        /// Expected files: internal path → size.
        let files: [String: Int64]
        var testDescription: String { first }
        /// `.7z.NNN`/`.zip.NNN` sets are written since ZF-83 stage 3; spanned ZIP and RAR never.
        var writable: Bool { ArchiveVolumeName.parse(first)?.scheme.isNumbered == true }
    }

    static let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")

    static let sevenZip = SplitSet(first: "split.7z.001", volumes: ["split.7z.001", "split.7z.002", "split.7z.003"],
                                   files: ["payload.bin": 20000])
    static let zipNumbered = SplitSet(first: "split.zip.001", volumes: ["split.zip.001", "split.zip.002", "split.zip.003"],
                                      files: ["payload.bin": 20000])
    static let zipSpanned = SplitSet(first: "spanned.zip", volumes: ["spanned.z01", "spanned.z02", "spanned.zip"],
                                     files: ["big.bin": 140000, "docs/readme.txt": 23])
    static let rarParts = SplitSet(first: "parts.part1.rar", volumes: ["parts.part1.rar", "parts.part2.rar", "parts.part3.rar"],
                                   files: ["payload.bin": 40000, "docs/readme.txt": 23])
    static let rarLegacy = SplitSet(first: "legacy.rar", volumes: ["legacy.rar", "legacy.r00", "legacy.r01"],
                                    files: ["payload.bin": 40000, "docs/readme.txt": 23])
    static let all = [sevenZip, zipNumbered, zipSpanned, rarParts, rarLegacy]

    // MARK: Reading from the first volume (characterization, ZF-83 stage 0)

    @Test("Every scheme lists, previews and validates from its first volume", arguments: all)
    func readsFromFirstVolume(set: SplitSet) async throws {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let archive = Self.fixtures.appendingPathComponent(set.first)
        try await engine.testArchive(at: archive, password: nil)
        let opened = try await engine.openArchive(at: archive, password: nil)
        let listed = try await allFiles(engine: engine, address: opened.address)
        #expect(listed.mapValues(\.size) == set.files)
        for (path, size) in set.files {
            let item = try #require(listed[path])
            let data = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
            #expect(try Data(contentsOf: data).count == Int(size), "\(set.first): \(path)")
        }
    }

    @Test("Every scheme extracts in full from its first volume", arguments: all)
    func extractsFromFirstVolume(set: SplitSet) async throws {
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplit-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: destination) }
        let engine = NativeSevenZipArchiveEngine()
        try await engine.extractArchive(at: Self.fixtures.appendingPathComponent(set.first), to: destination,
            password: nil, resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
        for (path, size) in set.files {
            let attributes = try FileManager.default.attributesOfItem(atPath: destination.appendingPathComponent(path).path)
            #expect((attributes[.size] as? NSNumber)?.int64Value == size, "\(set.first): \(path)")
        }
    }

    // MARK: Volume names and sets (ZF-83 stage 1)

    @Test("Volume names give their scheme, stem and reading position")
    func volumeNames() throws {
        func parsed(_ name: String) -> ArchiveVolumeName? { ArchiveVolumeName.parse(name) }
        func text(_ volume: ArchiveVolumeName?) -> String {
            volume.map { "\($0.scheme.rawValue) \($0.stem) \($0.number)" } ?? "nil"
        }
        #expect(parsed("Backup.7z.001")?.scheme == .sevenZipNumbered)
        #expect(text(parsed("Backup.7Z.002")) == "sevenZipNumbered Backup 2")
        #expect(text(parsed("Backup.zip.1000")) == "zipNumbered Backup 1000")
        #expect(text(parsed("my.backup.part1.rar")) == "rarParts my.backup 1")
        #expect(parsed("x.PART02.RAR")?.siblingName(number: 3) == "x.PART03.RAR")
        #expect(text(parsed("x.z01")) == "zipSpanned x 1")
        #expect(parsed("x.z100")?.number == 100)
        #expect(text(parsed("x.r00")) == "rarLegacy x 1")
        #expect(parsed("x.r00")?.openingName == "x.rar")
        #expect(parsed("x.z07")?.openingName == "x.zip")
        #expect(parsed("x.7z.012")?.openingName == "x.7z.001")
        #expect(parsed("x.part12.rar")?.openingName == "x.part01.rar")
        // A plain .zip or .rar is a volume only beside its .z01 or .r00.
        #expect(parsed("x.zip") == nil)
        #expect(parsed("x.rar") == nil)
        #expect(text(ArchiveVolumeName.parse("x.zip") { $0 == "x.z01" }) == "zipSpanned x \(Int.max)")
        #expect(text(ArchiveVolumeName.parse("x.rar") { $0 == "x.r00" }) == "rarLegacy x 0")
        for whole in ["x.7z", "x.7z.000", "x.tar.gz", "x.part1.zip", "x.z1", "x.r", "notes.txt", "x.001"] {
            #expect(parsed(whole) == nil, "\(whole)")
        }
    }

    @Test("A set lists its volumes in numeric reading order and names the missing ones")
    func volumeSets() throws {
        let folder = URL(fileURLWithPath: "/Volumes/Set")
        func set(_ name: String, _ siblings: [String]) -> ArchiveVolumeSet? {
            ArchiveVolumeSet.resolve(name: name, folder: folder, siblings: siblings)
        }
        let parts = (1...11).map { "x.part\($0).rar" }.shuffled() + ["x.rar", "y.part3.rar", "notes.txt"]
        let rar = try #require(set("x.part7.rar", parts))
        #expect(rar.members.map(\.lastPathComponent) == (1...11).map { "x.part\($0).rar" })
        #expect(rar.opening.lastPathComponent == "x.part1.rar")
        #expect(rar.missing.isEmpty)
        #expect(rar.successorName == "x.part12.rar")

        let spanned = (1...100).map { String(format: "s.z%02d", $0) }.shuffled() + ["s.zip", "s.7z.001"]
        let zip = try #require(set("s.z99", spanned))
        #expect(zip.members.map(\.lastPathComponent) == (1...100).map { String(format: "s.z%02d", $0) } + ["s.zip"])
        #expect(zip.opening.lastPathComponent == "s.zip")
        #expect(zip.successorName == "s.z101")
        #expect(set("s.zip", spanned)?.members.count == 101)

        let legacy = try #require(set("l.r01", ["l.r01", "l.rar", "l.r00", "l.zip"]))
        #expect(legacy.members.map(\.lastPathComponent) == ["l.rar", "l.r00", "l.r01"])
        #expect(legacy.opening.lastPathComponent == "l.rar")

        let mixedCase = try #require(set("Backup.7Z.001", ["Backup.7Z.001", "backup.7z.002", "Backupx.7z.003"]))
        #expect(mixedCase.members.map(\.lastPathComponent) == ["Backup.7Z.001", "backup.7z.002"])

        #expect(set("g.7z.001", ["g.7z.001", "g.7z.003"])?.missing == ["g.7z.002"])
        let firstMissing = try #require(set("g.7z.002", ["g.7z.002", "g.7z.003"]))
        #expect(firstMissing.missing == ["g.7z.001"])
        #expect(firstMissing.opening.lastPathComponent == "g.7z.001")
        #expect(set("a.z01", ["a.z01", "a.z02"])?.missing == ["a.zip"])
        #expect(set("p.part3.rar", ["p.part3.rar"])?.missing == ["p.part1.rar", "p.part2.rar"])

        #expect(set("w.zip", ["w.zip", "w.z1"]) == nil)
        #expect(set("w.rar", ["w.rar", "w.part1.rar"]) == nil)
        #expect(set("w.7z", ["w.7z", "w.7z.001"]) == nil)
    }

    @Test("Every volume is an archive and names the set without its volume suffix")
    func volumeRecognitionAndNaming() {
        for name in ["x.7z.001", "x.7z.002", "x.zip.003", "x.z01", "x.r00", "x.part2.rar", "x.zip", "x.rar"] {
            #expect(ArchiveFormatRegistry.recognizes(name), "\(name)")
        }
        #expect(ArchiveNaming.baseName("Backup.7z.001") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.zip.002") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.part2.rar") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.z01") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.r00") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.zip") == "Backup")
        #expect(ArchiveNaming.baseName("Backup.tar.gz") == "Backup")
    }

    // MARK: Opening any volume (ZF-83 stage 1)

    @Test("Opening any volume opens the whole set in one shared session", arguments: all)
    func opensFromAnyVolume(set: SplitSet) async throws {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let first = try await engine.openArchive(at: Self.fixtures.appendingPathComponent(set.first), password: nil)
        #expect(first.isReadOnly == !set.writable)
        for volume in set.volumes {
            let opened = try await engine.openArchive(at: Self.fixtures.appendingPathComponent(volume), password: nil)
            #expect(opened.address.sessionID == first.address.sessionID, "\(volume)")
            #expect(opened.displayName == set.first, "\(volume)")
            let listed = try await allFiles(engine: engine, address: opened.address)
            #expect(listed.mapValues(\.size) == set.files, "\(volume)")
        }
    }

    @Test("Extracting or validating any volume reads the whole set", arguments: all)
    func extractsAndValidatesFromAnyVolume(set: SplitSet) async throws {
        let engine = NativeSevenZipArchiveEngine()
        for volume in set.volumes {
            let archive = Self.fixtures.appendingPathComponent(volume)
            try await engine.testArchive(at: archive, password: nil)
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplit-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: destination) }
            try await engine.extractArchive(at: archive, to: destination, password: nil,
                resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
            for (path, size) in set.files {
                let attributes = try FileManager.default.attributesOfItem(atPath: destination.appendingPathComponent(path).path)
                #expect((attributes[.size] as? NSNumber)?.int64Value == size, "\(volume): \(path)")
            }
        }
    }

    @Test("A missing volume is named when opening, extracting or validating", arguments: [
        (sevenZip, "split.7z.002"), (sevenZip, "split.7z.001"), (zipNumbered, "split.zip.002"),
        (zipSpanned, "spanned.z01"), (zipSpanned, "spanned.z02"), (zipSpanned, "spanned.zip"),
        (rarParts, "parts.part2.rar"), (rarParts, "parts.part3.rar"), (rarParts, "parts.part1.rar"),
        (rarLegacy, "legacy.r01"), (rarLegacy, "legacy.rar"),
    ])
    func missingVolume(set: SplitSet, missing: String) async throws {
        let folder = try copy(set)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.removeItem(at: folder.appendingPathComponent(missing))
        let present = try #require(set.volumes.first { $0 != missing })
        let archive = folder.appendingPathComponent(present)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        await #expect(throws: ArchiveEngineError.missingVolume(missing)) {
            _ = try await engine.openArchive(at: archive, password: nil)
        }
        await #expect(throws: ArchiveEngineError.missingVolume(missing)) {
            try await engine.testArchive(at: archive, password: nil)
        }
        await #expect(throws: ArchiveEngineError.missingVolume(missing)) {
            try await engine.extractArchive(at: archive, to: folder.appendingPathComponent("Out"), password: nil,
                resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
        }
    }

    @Test("A volume added to or removed from an open set changes it", arguments: [sevenZip, rarParts, zipSpanned])
    func setChanges(set: SplitSet) async throws {
        let folder = try copy(set)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: folder.appendingPathComponent(set.first), password: nil)
        let files = try await allFiles(engine: engine, address: opened.address)
        let path = try #require(set.files.keys.sorted().last)
        let item = try #require(files[path])
        let volume = try #require(ArchiveVolumeName.parse(folder.appendingPathComponent(set.volumes[0])))
        let lastNumber = set.volumes.compactMap { ArchiveVolumeName.parse($0, firstSiblingExists: { _ in true })?.number }
            .filter { $0 != Int.max }.max() ?? 0
        let added = folder.appendingPathComponent(volume.siblingName(number: lastNumber + 1))
        try Data("extra".utf8).write(to: added)
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            _ = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
        }
        try FileManager.default.removeItem(at: added)
        let reopened = try await engine.openArchive(at: folder.appendingPathComponent(set.first), password: nil)
        let again = try #require(try await allFiles(engine: engine, address: reopened.address)[path])
        try FileManager.default.removeItem(at: folder.appendingPathComponent(set.volumes[1]))
        await #expect(throws: ArchiveEngineError.archiveChangedSinceOpening) {
            _ = try await engine.materialize(item: again, purpose: .preview, automaticLimit: nil)
        }
    }

    @Test("Spanned ZIP and RAR split sets are read-only", arguments: [zipSpanned, rarParts, rarLegacy])
    func splitSetsAreReadOnly(set: SplitSet) async throws {
        let folder = try copy(set)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("Added.txt")
        try Data("added".utf8).write(to: source)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        #expect(try await engine.openArchive(at: folder.appendingPathComponent(set.first), password: nil).isReadOnly)
        for volume in set.volumes {
            await #expect(throws: (any Error).self) {
                try await engine.addItems(from: [source], to: folder.appendingPathComponent(volume), internalPath: "",
                                          password: nil, progress: { _ in })
            }
        }
        for volume in set.volumes {
            #expect(try Data(contentsOf: folder.appendingPathComponent(volume))
                    == Data(contentsOf: Self.fixtures.appendingPathComponent(volume)), "\(volume)")
        }
    }

    // MARK: Editing `.NNN` split sets (ZF-83 stage 3)

    @Test("Adding to a .NNN set rewrites it in volumes of its own sizes and names", arguments: [sevenZip, zipNumbered])
    func addingGrowsTheSet(set: SplitSet) async throws {
        let folder = try copy(set)
        defer { try? FileManager.default.removeItem(at: folder) }
        let added = folder.appendingPathComponent("Added.bin")
        try Data((0..<30000).map { _ in UInt8.random(in: 0...255) }).write(to: added)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: folder.appendingPathComponent(set.volumes[1]), password: nil)
        #expect(!opened.isReadOnly)
        // Any volume adds to the set.
        try await engine.addItems(from: [added], to: folder.appendingPathComponent(set.volumes[2]), internalPath: "Docs",
                                  password: nil, progress: { _ in })
        let volumes = try volumeFiles(in: folder, like: set.first)
        #expect(volumes.count > set.volumes.count, "\(volumes)")
        #expect(Array(volumes.prefix(set.volumes.count)) == set.volumes)
        let sizes = try volumes.map { try size(folder.appendingPathComponent($0)) }
        #expect(sizes.dropLast().allSatisfy { $0 == 8192 }, "\(sizes)")
        #expect(try stagingFolders(in: folder).isEmpty)
        try await engine.testArchive(at: folder.appendingPathComponent(set.first), password: nil)
        let listed = try await allFiles(engine: engine, address: opened.address)
        #expect(listed["Docs/Added.bin"]?.size == 30000)
        #expect(listed["payload.bin"]?.size == 20000)
    }

    @Test("Removing from a .NNN set shrinks it and removes the volumes it no longer needs", arguments: [sevenZip, zipNumbered])
    func removingShrinksTheSet(set: SplitSet) async throws {
        let folder = try copy(set)
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = folder.appendingPathComponent("Note.txt")
        try Data("kept".utf8).write(to: note)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        try await engine.addItems(from: [note], to: folder.appendingPathComponent(set.first), internalPath: "",
                                  password: nil, progress: { _ in })
        let opened = try await engine.openArchive(at: folder.appendingPathComponent(set.first), password: nil)
        let payload = try #require(try await engine.items(at: opened.address).first { $0.name == "payload.bin" })
        _ = try await engine.removeItems([payload], password: nil, progress: { _ in })
        #expect(try volumeFiles(in: folder, like: set.first) == [set.first])
        #expect(try stagingFolders(in: folder).isEmpty)
        let listed = try await allFiles(engine: engine, address: opened.address)
        #expect(listed.mapValues(\.size) == ["Note.txt": 4])
    }

    @Test("Moving items inside a .NNN set rewrites it")
    func reorganizesTheSet() async throws {
        let folder = try copy(Self.sevenZip)
        defer { try? FileManager.default.removeItem(at: folder) }
        let target = folder.appendingPathComponent("Target")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: target.appendingPathComponent("Keep.txt"))
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        try await engine.addItems(from: [target], to: folder.appendingPathComponent("split.7z.001"), internalPath: "",
                                  password: nil, progress: { _ in })
        let opened = try await engine.openArchive(at: folder.appendingPathComponent("split.7z.001"), password: nil)
        let root = try await engine.items(at: opened.address)
        let payload = try #require(root.first { $0.name == "payload.bin" })
        let targetFolder = try #require(root.first { $0.name == "Target" })
        guard case let .archive(destination) = targetFolder.location else { throw ArchiveEngineError.itemNotFound }
        _ = try await engine.reorganizeItems([payload], to: destination, moving: true, password: nil,
            resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
        let listed = try await allFiles(engine: engine, address: opened.address)
        #expect(listed["Target/payload.bin"]?.size == 20000)
        #expect(listed["payload.bin"] == nil)
        try await engine.testArchive(at: folder.appendingPathComponent("split.7z.002"), password: nil)
    }

    @Test("An encrypted .NNN set is rewritten with its password")
    func encryptedSet() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitEncrypted-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("Secret.bin")
        try Data((0..<20000).map { _ in UInt8.random(in: 0...255) }).write(to: source)
        let whole = folder.appendingPathComponent("Whole.7z")
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        var options = CompressionOptions(format: .sevenZip)
        options.requiresPassword = true
        try await engine.createArchive(from: [source], outputURL: whole, options: options, password: "secret", progress: { _ in })
        try slice(whole, into: 8192, named: "Locked.7z", in: folder)
        try FileManager.default.removeItem(at: whole)
        let note = folder.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        await #expect(throws: ArchiveEngineError.invalidPassword) {
            try await engine.addItems(from: [note], to: folder.appendingPathComponent("Locked.7z.001"), internalPath: "",
                                      password: "wrong", progress: { _ in })
        }
        #expect(try stagingFolders(in: folder).isEmpty)
        #expect(try volumeFiles(in: folder, like: "Locked.7z.001").count == 3)
        try await engine.addItems(from: [note], to: folder.appendingPathComponent("Locked.7z.001"), internalPath: "",
                                  password: "secret", progress: { _ in })
        try await engine.testArchive(at: folder.appendingPathComponent("Locked.7z.001"), password: "secret")
        let opened = try await engine.openArchive(at: folder.appendingPathComponent("Locked.7z.001"), password: "secret")
        let listed = try await allFiles(engine: engine, address: opened.address)
        #expect(listed.mapValues(\.size) == ["Secret.bin": 20000, "Note.txt": 4])
        #expect(listed["Note.txt"]?.encrypted == true)
        await #expect(throws: ArchiveEngineError.passwordRequired) {
            _ = try await NativeSevenZipArchiveEngine().openArchive(at: folder.appendingPathComponent("Locked.7z.002"), password: nil)
        }
    }

    @Test("A volume changed since the set was opened stops the write, keeping every volume")
    func changedVolumeStopsTheWrite() async throws {
        let folder = try copy(Self.sevenZip)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: folder.appendingPathComponent("split.7z.001"), password: nil)
        let payload = try #require(try await engine.items(at: opened.address).first { $0.name == "payload.bin" })
        let third = folder.appendingPathComponent("split.7z.003")
        let bytes = try Data(contentsOf: third)
        try FileManager.default.removeItem(at: third)
        try bytes.write(to: third)
        await #expect(throws: ArchiveEngineError.archiveChanged) {
            _ = try await engine.removeItems([payload], password: nil, progress: { _ in })
        }
        for volume in Self.sevenZip.volumes {
            #expect(try Data(contentsOf: folder.appendingPathComponent(volume))
                    == Data(contentsOf: Self.fixtures.appendingPathComponent(volume)))
        }
        #expect(try stagingFolders(in: folder).isEmpty)
    }

    @Test("Volume metadata survives the rewrite")
    func metadataSurvives() async throws {
        let folder = try copy(Self.sevenZip)
        defer { try? FileManager.default.removeItem(at: folder) }
        for volume in Self.sevenZip.volumes {
            let url = folder.appendingPathComponent(volume)
            try FileManager.default.setAttributes([.posixPermissions: 0o640], ofItemAtPath: url.path)
            try (url as NSURL).setResourceValue(["Blue"], forKey: .tagNamesKey)
        }
        let note = folder.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        try await NativeSevenZipArchiveEngine().addItems(from: [note], to: folder.appendingPathComponent("split.7z.001"),
            internalPath: "", password: nil, progress: { _ in })
        for volume in try volumeFiles(in: folder, like: "split.7z.001") {
            let url = folder.appendingPathComponent(volume)
            let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
            #expect(permissions?.intValue == 0o640, "\(volume)")
            #expect(try url.resourceValues(forKeys: [.tagNamesKey]).tagNames == ["Blue"], "\(volume)")
        }
    }

    @Test("A failure at any step of the volume swap puts the old set back", arguments: [(3, 2), (3, 5), (3, 3)])
    func swapFailureUndoes(oldCount: Int, newCount: Int) throws {
        for failing in 0..<max(oldCount, newCount) {
            let (folder, staging, old, new) = try replacementFixture(oldCount: oldCount, newCount: newCount)
            defer { try? FileManager.default.removeItem(at: folder) }
            var replacement = try ArchiveVolumeReplacement(folder: folder, staging: staging, old: old, new: new)
            replacement.beforeStep = { step in if step == failing { throw CocoaError(.fileWriteUnknown) } }
            #expect(throws: CocoaError.self) { try replacement.commit() }
            #expect(try volumeContents(folder) == (0..<oldCount).map { "old \($0)" }, "failing at \(failing)")
        }
    }

    @Test("A crash during the volume swap is undone when the set is next opened", arguments: [(3, 2), (3, 5), (3, 3)])
    func crashIsRecovered(oldCount: Int, newCount: Int) async throws {
        for crashing in 0..<max(oldCount, newCount) {
            let (folder, staging, old, new) = try replacementFixture(oldCount: oldCount, newCount: newCount)
            defer { try? FileManager.default.removeItem(at: folder) }
            var replacement = try ArchiveVolumeReplacement(folder: folder, staging: staging, old: old, new: new)
            replacement.simulatesCrash = { $0 == crashing }
            #expect(throws: ArchiveVolumeReplacement.SimulatedCrash.self) { try replacement.commit() }
            ArchiveVolumeReplacement.recover(in: folder)
            #expect(try volumeContents(folder) == (0..<oldCount).map { "old \($0)" }, "crashing at \(crashing)")
            #expect(try stagingFolders(in: folder).isEmpty)
        }
        // A completed replacement whose staging folder survived a crash is kept.
        let (folder, staging, old, new) = try replacementFixture(oldCount: oldCount, newCount: newCount)
        defer { try? FileManager.default.removeItem(at: folder) }
        try ArchiveVolumeReplacement(folder: folder, staging: staging, old: old, new: new).commit()
        #expect(try volumeContents(folder) == (0..<newCount).map { "new \($0)" })
    }

    @Test("Opening a set whose rewrite crashed restores its volumes first")
    func openingRecovers() async throws {
        let folder = try copy(Self.sevenZip)
        defer { try? FileManager.default.removeItem(at: folder) }
        let staging = folder.appendingPathComponent(ArchiveVolumeReplacement.stagingPrefix + "test")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let replacementVolume = staging.appendingPathComponent("split.7z.001")
        try Data("not an archive".utf8).write(to: replacementVolume)
        let old = Self.sevenZip.volumes.map { folder.appendingPathComponent($0) }
        var replacement = try ArchiveVolumeReplacement(folder: folder, staging: staging, old: old, new: [replacementVolume])
        replacement.simulatesCrash = { $0 == 1 }
        #expect(throws: ArchiveVolumeReplacement.SimulatedCrash.self) { try replacement.commit() }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: folder.appendingPathComponent("split.7z.002"), password: nil)
        #expect(try await allFiles(engine: engine, address: opened.address).mapValues(\.size) == ["payload.bin": 20000])
        #expect(try stagingFolders(in: folder).isEmpty)
    }

    // MARK: Write-back with split archives (ZF-83 stages 3 and 4)

    @Test("A .NNN set inside an archive is edited and written back with all of its volumes", arguments: [true, false])
    func innerSetWriteBack(growing: Bool) async throws {
        let (outerURL, folder) = try await outerArchive(holding: Self.sevenZip.volumes)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: outerURL, password: nil)
        let sets = try await setsAddress(in: outer, engine: engine)
        let member = try #require(try await engine.items(at: sets).first { $0.name == "split.7z.002" })
        let inner = try await engine.openInnerArchive(item: member, password: nil)
        #expect(!inner.isReadOnly)
        if growing {
            let added = folder.appendingPathComponent("Added.bin")
            try Data((0..<30000).map { _ in UInt8.random(in: 0...255) }).write(to: added)
            try await engine.addItems(from: [added], to: try await engine.archiveRootURL(for: inner.address),
                                      internalPath: "", password: nil, progress: { _ in })
        } else {
            let note = folder.appendingPathComponent("Note.txt")
            try Data("note".utf8).write(to: note)
            try await engine.addItems(from: [note], to: try await engine.archiveRootURL(for: inner.address),
                                      internalPath: "", password: nil, progress: { _ in })
            let payload = try #require(try await engine.items(at: inner.address).first { $0.name == "payload.bin" })
            _ = try await engine.removeItems([payload], password: nil, progress: { _ in })
        }
        await engine.closeSession(inner.address.sessionID)
        try await engine.writeBack(inner.address.sessionID)

        let fresh = NativeSevenZipArchiveEngine()
        defer { Task { await fresh.closeAllSessions() } }
        let reopened = try await fresh.openArchive(at: outerURL, password: nil)
        let stored = try await fresh.items(at: try await setsAddress(in: reopened, engine: fresh)).map(\.name).sorted()
        if growing {
            #expect(stored.count > 3, "\(stored)")
            #expect(stored.allSatisfy { $0.hasPrefix("split.7z.") })
        } else {
            #expect(stored == ["split.7z.001"])
        }
        let first = try #require(try await fresh.items(at: try await setsAddress(in: reopened, engine: fresh)).first { $0.name == "split.7z.001" })
        let innerAgain = try await fresh.openInnerArchive(item: first, password: nil)
        let listed = try await allFiles(engine: fresh, address: innerAgain.address)
        #expect(listed.mapValues(\.size) == (growing ? ["payload.bin": 20000, "Added.bin": 30000] : ["Note.txt": 4]))
    }

    @Test("An archive inside a .NNN set is written back into the set")
    func writeBackIntoSplitOuter() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitOuterSet-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let filler = folder.appendingPathComponent("Filler.bin")
        try Data((0..<12000).map { _ in UInt8.random(in: 0...255) }).write(to: filler)
        let inner = folder.appendingPathComponent("Inner.zip")
        try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent("inner.zip"), to: inner)
        let whole = folder.appendingPathComponent("Whole.7z")
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        try await engine.createArchive(from: [filler, inner], outputURL: whole, format: .sevenZip, progress: { _ in })
        try slice(whole, into: 4096, named: "Outer.7z", in: folder)
        for name in [whole, filler, inner] { try FileManager.default.removeItem(at: name) }
        let outer = try await engine.openArchive(at: folder.appendingPathComponent("Outer.7z.001"), password: nil)
        #expect(!outer.isReadOnly)
        let innerItem = try #require(try await engine.items(at: outer.address).first { $0.name == "Inner.zip" })
        let opened = try await engine.openInnerArchive(item: innerItem, password: nil)
        #expect(!opened.isReadOnly)
        let note = folder.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: note)
        try await engine.addItems(from: [note], to: try await engine.archiveRootURL(for: opened.address), internalPath: "",
                                  password: nil, progress: { _ in })
        try FileManager.default.removeItem(at: note)
        await engine.closeSession(opened.address.sessionID)
        try await engine.writeBack(opened.address.sessionID)
        #expect(try stagingFolders(in: folder).isEmpty)
        let sizes = try volumeFiles(in: folder, like: "Outer.7z.001").map { try size(folder.appendingPathComponent($0)) }
        #expect(sizes.dropLast().allSatisfy { $0 == 4096 }, "\(sizes)")
        let fresh = NativeSevenZipArchiveEngine()
        defer { Task { await fresh.closeAllSessions() } }
        try await fresh.testArchive(at: folder.appendingPathComponent("Outer.7z.001"), password: nil)
        let reopened = try await fresh.openArchive(at: folder.appendingPathComponent("Outer.7z.002"), password: nil)
        let item = try #require(try await fresh.items(at: reopened.address).first { $0.name == "Inner.zip" })
        let innerAgain = try await fresh.openInnerArchive(item: item, password: nil)
        #expect(try await fresh.items(at: innerAgain.address).contains { $0.name == "Note.txt" })
    }

    @Test("Spanned ZIP and RAR sets inside an archive stay read-only", arguments: [zipSpanned, rarParts])
    func readOnlyInnerSets(set: SplitSet) async throws {
        let (outerURL, folder) = try await outerArchive(holding: set.volumes)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: outerURL, password: nil)
        let item = try #require(try await engine.items(at: try await setsAddress(in: outer, engine: engine)).first { $0.name == set.first })
        #expect(try await engine.openInnerArchive(item: item, password: nil).isReadOnly)
    }

    // MARK: Creating split archives (ZF-83 stage 5)

    @Test("Compressing with a volume size writes Name.7z.001, .002… that read as one archive", arguments: [ArchiveCompressionFormat.sevenZip, .zip])
    func createsSplitArchives(format: ArchiveCompressionFormat) async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitCreate-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("Big.bin")
        try Data((0..<2_500_000).map { _ in UInt8.random(in: 0...255) }).write(to: source)
        var options = CompressionOptions(format: format)
        options.volumeSize = 1_000_000
        let output = folder.appendingPathComponent("Out." + format.fileExtension)
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        try await engine.createArchive(from: [source], outputURL: output, options: options, password: nil, progress: { _ in })
        #expect(!FileManager.default.fileExists(atPath: output.path))
        let volumes = try volumeFiles(in: folder, like: output.lastPathComponent + ".001")
        #expect(volumes == (1...3).map { output.lastPathComponent + String(format: ".%03d", $0) })
        #expect(try volumes.dropLast().map { try size(folder.appendingPathComponent($0)) } == [1_000_000, 1_000_000])
        try await engine.testArchive(at: folder.appendingPathComponent(volumes[1]), password: nil)
        let opened = try await engine.openArchive(at: folder.appendingPathComponent(volumes[2]), password: nil)
        #expect(!opened.isReadOnly)
        #expect(try await allFiles(engine: engine, address: opened.address).mapValues(\.size) == ["Big.bin": 2_500_000])
    }

    @Test("A volume name already taken stops the creation before any volume is written")
    func creationConflict() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitConflict-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("Big.bin")
        try Data((0..<2_500_000).map { _ in UInt8.random(in: 0...255) }).write(to: source)
        let taken = folder.appendingPathComponent("Out.7z.002")
        try Data("mine".utf8).write(to: taken)
        var options = CompressionOptions(format: .sevenZip)
        options.volumeSize = 1_000_000
        await #expect(throws: CocoaError.self) {
            try await NativeSevenZipArchiveEngine().createArchive(from: [source], outputURL: folder.appendingPathComponent("Out.7z"),
                options: options, password: nil, progress: { _ in })
        }
        #expect(try String(contentsOf: taken, encoding: .utf8) == "mine")
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted() == ["Big.bin", "Out.7z.002"])
    }

    @Test("Volume sizes apply to ZIP and 7z, whole megabytes from 1 MB, and survive in saved profiles")
    func volumeOptions() throws {
        var options = CompressionOptions(format: .sevenZip)
        options.volumeSize = 100_000_000
        #expect(options.normalized().volumeSize == 100_000_000)
        #expect(options.summary(locale: Locale(identifier: "en")).hasSuffix("Volumes of 100 MB"))
        options.volumeSize = 999_999
        #expect(options.normalized().volumeSize == nil)
        options.volumeSize = 100_000_000
        options.format = .tar
        #expect(options.normalized().volumeSize == nil)
        let legacy = try JSONEncoder().encode(CompressionOptions(format: .zip))
        let json = try #require(String(data: legacy, encoding: .utf8)).replacingOccurrences(of: ",\"volumeSize\":null", with: "")
        #expect(try JSONDecoder().decode(CompressionOptions.self, from: Data(json.utf8)).volumeSize == nil)
        options.format = .zip
        let saved = try JSONDecoder().decode(CompressionOptions.self, from: JSONEncoder().encode(options))
        #expect(saved.volumeSize == 100_000_000)
    }

    // MARK: Browsing a folder of volumes (ZF-83 stage 1)

    @Test("In a folder, every volume is an archive that stands for its set")
    @MainActor
    func folderOfVolumes() async throws {
        try await withVolumeFolder { state, folder in
            let items = state.items
            func item(_ name: String) throws -> BrowserItem { try #require(items.first { $0.name == name }, "\(name)") }
            for set in Self.all {
                for volume in set.volumes {
                    let entry = try item(volume)
                    #expect(entry.isArchive, "\(volume)")
                    #expect(entry.archiveVolume?.opensSet == (volume == set.first), "\(volume)")
                    #expect(entry.acceptsArchiveAdditions == set.writable, "\(volume)")
                    #expect(entry.hasComputedSize, "\(volume)")
                    if volume != set.first { #expect(!entry.canExpandInlineInList, "\(volume)") }
                }
                let total = set.volumes.reduce(Int64(0)) { total, name in
                    total + Int64((try? FileManager.default.attributesOfItem(atPath: folder.appendingPathComponent(name).path)[.size] as? NSNumber)?.int64Value ?? 0)
                }
                for volume in set.volumes {
                    #expect(try await state.recursiveSize(of: try item(volume)) == total, "\(volume)")
                }
            }
            #expect(try item("Whole.zip").archiveVolume == nil)
            #expect(try item("Whole.zip").acceptsArchiveAdditions)
        }
    }

    @Test("Adding to a spanned ZIP or RAR split archive is refused before the confirmation",
          arguments: ["spanned.zip", "spanned.z01", "parts.part1.rar", "legacy.r00"])
    @MainActor
    func additionRefusedEarly(volume: String) async throws {
        try await withVolumeFolder { state, folder in
            state.requestArchiveAddition([folder.appendingPathComponent("Local.txt")], to: folder.appendingPathComponent(volume))
            #expect(state.pendingArchiveAddition == nil)
            #expect(state.error != nil)
        }
    }

    @Test("Adding to a .NNN split archive from any volume asks for confirmation, then rewrites the set")
    @MainActor
    func additionToNumberedSet() async throws {
        try await withVolumeFolder { state, folder in
            state.requestArchiveAddition([folder.appendingPathComponent("Local.txt")], to: folder.appendingPathComponent("split.zip.002"))
            let request = try #require(state.pendingArchiveAddition)
            state.pendingArchiveAddition = nil
            await state.confirmArchiveAddition(request)
            #expect(state.error == nil)
            let engine = NativeSevenZipArchiveEngine()
            defer { Task { await engine.closeAllSessions() } }
            let opened = try await engine.openArchive(at: folder.appendingPathComponent("split.zip.001"), password: nil)
            #expect(try await engine.items(at: opened.address).contains { $0.name == "Local.txt" })
            #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Local.txt").path))
        }
    }

    @Test("Extracting several volumes of one set extracts it once, into a folder named after the set")
    @MainActor
    func extractsEachSetOnce() async throws {
        try await withVolumeFolder { state, folder in
            let items = state.items
            let selected = ["parts.part2.rar", "parts.part1.rar", "split.7z.003", "legacy.r00"].compactMap { name in
                items.first { $0.name == name }
            }
            #expect(selected.count == 4)
            #expect(state.contextualActions(for: selected).contains(.extractNamed))
            _ = await state.performContextualAction(.extractNamed, items: selected)
            #expect(state.error == nil)
            let names = try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { !$0.contains(".") }.sorted()
            #expect(names == ["legacy", "parts", "split"])
            #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("parts/docs/readme.txt").path))
            #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("split/payload.bin").path))
        }
    }

    // MARK: Inline expansion and split archives inside archives (ZF-83 stage 2)

    @Test("List expands a 7z or ZIP split archive from its opening volume only")
    @MainActor
    func inlineExpansion() async throws {
        try await withVolumeFolder { state, _ in
            let items = state.items
            func item(_ name: String) throws -> BrowserItem { try #require(items.first { $0.name == name }, "\(name)") }
            for (opening, file) in [("split.7z.001", "payload.bin"), ("split.zip.001", "payload.bin"), ("spanned.zip", "big.bin")] {
                let archive = try item(opening)
                #expect(archive.canExpandInlineInList, "\(opening)")
                await state.toggleExpansion(archive)
                #expect(state.error == nil, "\(opening)")
                let children = try #require(state.expandedChildren[archive.id], "\(opening)")
                #expect(children.contains { $0.name == file }, "\(opening): \(children.map(\.name))")
                await state.toggleExpansion(archive)
            }
            for name in ["split.7z.002", "split.zip.003", "spanned.z01", "parts.part1.rar", "parts.part2.rar", "legacy.rar", "legacy.r00"] {
                #expect(!(try item(name)).canExpandInlineInList, "\(name)")
            }
        }
    }

    @Test("A split archive stored inside an archive opens from any of its volumes; only .NNN sets are writable", arguments: all)
    func insideAnArchive(set: SplitSet) async throws {
        let (outerURL, folder) = try await outerArchive(holding: set.volumes)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: outerURL, password: nil)
        let setsFolder = try #require(try await engine.items(at: outer.address).first { $0.name == "Sets" })
        guard case let .archive(setsAddress) = setsFolder.location else { throw ArchiveEngineError.itemNotFound }
        let stored = try await engine.items(at: setsAddress)
        let total = set.volumes.reduce(Int64(0)) { total, name in
            total + Int64((try? FileManager.default.attributesOfItem(atPath: Self.fixtures.appendingPathComponent(name).path)[.size] as? NSNumber)?.int64Value ?? 0)
        }
        var sessions = Set<UUID>()
        for volume in set.volumes {
            let item = try #require(stored.first { $0.name == volume })
            #expect(item.isArchiveInsideArchive)
            #expect(item.archiveVolume?.opensSet == (volume == set.first), "\(volume)")
            #expect(item.archiveSetSize == total, "\(volume)")
            let inner = try await engine.openInnerArchive(item: item, password: nil)
            #expect(inner.isReadOnly == !set.writable, "\(volume)")
            #expect(inner.displayName == set.first, "\(volume)")
            sessions.insert(inner.address.sessionID)
            let listed = try await allFiles(engine: engine, address: inner.address)
            #expect(listed.mapValues(\.size) == set.files, "\(volume)")
        }
        #expect(sessions.count == 1)
    }

    @Test("A split archive inside an archive names its missing volume")
    func missingVolumeInsideAnArchive() async throws {
        let (outerURL, folder) = try await outerArchive(holding: ["split.7z.001", "split.7z.003"])
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let outer = try await engine.openArchive(at: outerURL, password: nil)
        let setsFolder = try #require(try await engine.items(at: outer.address).first { $0.name == "Sets" })
        guard case let .archive(setsAddress) = setsFolder.location else { throw ArchiveEngineError.itemNotFound }
        let item = try #require(try await engine.items(at: setsAddress).first { $0.name == "split.7z.003" })
        await #expect(throws: ArchiveEngineError.missingVolume("split.7z.002")) {
            _ = try await engine.openInnerArchive(item: item, password: nil)
        }
    }

    // MARK: Helpers

    /// The volumes of `first`'s set in `folder`, in reading order.
    private func volumeFiles(in folder: URL, like first: String) throws -> [String] {
        try #require(ArchiveVolumeSet.resolve(folder.appendingPathComponent(first))).members.map(\.lastPathComponent)
    }

    private func size(_ url: URL) throws -> Int64 {
        (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? -1
    }

    private func stagingFolders(in folder: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasPrefix(".zforge-") }
    }

    /// Byte slices of `archive` named `name.001`, `name.002`… in `folder`, as 7-Zip `-v` writes.
    private func slice(_ archive: URL, into size: Int, named name: String, in folder: URL) throws {
        let data = try Data(contentsOf: archive)
        for (index, start) in stride(from: 0, to: data.count, by: size).enumerated() {
            try data.subdata(in: start..<min(data.count, start + size))
                .write(to: folder.appendingPathComponent(name + String(format: ".%03d", index + 1)))
        }
    }

    /// `Set.7z.001`… holding "old N", and staged replacements holding "new N".
    private func replacementFixture(oldCount: Int, newCount: Int) throws -> (URL, URL, [URL], [URL]) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSwap-\(UUID().uuidString)")
        let staging = folder.appendingPathComponent(ArchiveVolumeReplacement.stagingPrefix + "test")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let old = try (0..<oldCount).map { index in
            let url = folder.appendingPathComponent(String(format: "Set.7z.%03d", index + 1))
            try Data("old \(index)".utf8).write(to: url)
            return url
        }
        let new = try (0..<newCount).map { index in
            let url = staging.appendingPathComponent(String(format: "Set.7z.%03d", index + 1))
            try Data("new \(index)".utf8).write(to: url)
            return url
        }
        return (folder, staging, old, new)
    }

    /// The contents of `Set.7z.NNN` in `folder`, in order.
    private func volumeContents(_ folder: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: folder.path).filter { $0.hasPrefix("Set.7z.") }.sorted()
            .map { try String(contentsOf: folder.appendingPathComponent($0), encoding: .utf8) }
    }

    /// A private copy of the set's volumes, so that tests may add or remove volumes.
    private func copy(_ set: SplitSet) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitSet-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for volume in set.volumes {
            try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent(volume), to: folder.appendingPathComponent(volume))
        }
        return folder
    }

    /// A folder holding every fixture set, a whole ZIP and a local file, shown in List.
    @MainActor
    private func withVolumeFolder(body: (FileBrowserState, URL) async throws -> Void) async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitFolder-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for volume in Self.all.flatMap(\.volumes) {
            try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent(volume), to: folder.appendingPathComponent(volume))
        }
        try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent("sample.zip"), to: folder.appendingPathComponent("Whole.zip"))
        try Data("local".utf8).write(to: folder.appendingPathComponent("Local.txt"))
        let suite = "ZforgeTestSuite.SplitArchives-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: NativeSevenZipArchiveEngine())
        defer { state.close() }
        await state.navigateToSidebar(folder, name: folder.lastPathComponent)
        try await body(state, folder)
    }

    private func setsAddress(in outer: ArchiveOpenResult, engine: NativeSevenZipArchiveEngine) async throws -> ArchiveAddress {
        let folder = try #require(try await engine.items(at: outer.address).first { $0.name == "Sets" })
        guard case let .archive(address) = folder.location else { throw ArchiveEngineError.itemNotFound }
        return address
    }

    /// A ZIP holding the given fixture volumes in its `Sets` folder.
    private func outerArchive(holding volumes: [String]) async throws -> (URL, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeSplitOuter-\(UUID().uuidString)")
        let sets = folder.appendingPathComponent("Sets")
        try FileManager.default.createDirectory(at: sets, withIntermediateDirectories: true)
        for volume in volumes {
            try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent(volume), to: sets.appendingPathComponent(volume))
        }
        let outer = folder.appendingPathComponent("Outer.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [sets], outputURL: outer, format: .zip, progress: { _ in })
        return (outer, folder)
    }

    // MARK: Volume presentation (D-104)

    @Test("Every volume's Kind is “Split archive” in List and in the preview; whole archives stay “Archive”")
    func volumeKind() async throws {
        let english = Locale(identifier: "en_US")
        let items = try await FileSystemService().items(in: Self.fixtures, showHidden: false)
        func item(_ name: String) throws -> BrowserItem { try #require(items.first { $0.name == name }, "\(name)") }
        for name in Self.all.flatMap(\.volumes) {
            let volume = try item(name)
            #expect(volume.displayKind(locale: english) == "Split archive", "List Kind: \(name)")
            #expect(BrowserSelectionSummary(items: [volume], locale: english).subtitle.hasPrefix("Split archive · "),
                    "Preview Kind: \(name)")
        }
        for name in ["sample.zip", "nested.7z"] {
            #expect(try item(name).displayKind(locale: english) == "Archive", "\(name)")
        }
        // Sorting by Kind keeps the volumes together, apart from whole archives.
        let volumeKeys = Set(try Self.all.flatMap(\.volumes).map { try item($0).kindSortKey })
        #expect(volumeKeys.count == 1)
        #expect(try volumeKeys.first != item("sample.zip").kindSortKey)
    }

    @Test("Every volume of a set shows the icon of a whole archive of its format")
    @MainActor
    func volumeIcons() async throws {
        func pixels(_ image: NSImage) throws -> Data {
            let bitmap = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 64, pixelsHigh: 64,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            image.draw(in: NSRect(x: 0, y: 0, width: 64, height: 64))
            NSGraphicsContext.restoreGraphicsState()
            return try #require(bitmap.tiffRepresentation)
        }
        // Whole archives of each format, in a folder of their own so that no set claims them.
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeVolumeIcons-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for (source, whole) in [("nested.7z", "whole.7z"), ("sample.zip", "whole.zip"), ("parts.part1.rar", "whole.rar")] {
            try FileManager.default.copyItem(at: Self.fixtures.appendingPathComponent(source),
                                             to: folder.appendingPathComponent(whole))
        }
        let wholes = try await FileSystemService().items(in: folder, showHidden: false)
        let volumes = try await FileSystemService().items(in: Self.fixtures, showHidden: false)
        func icon(_ name: String, in items: [BrowserItem]) throws -> Data {
            try pixels(FileIconCache.shared.icon(for: try #require(items.first { $0.name == name }, "\(name)")))
        }
        let expected: [(SplitSet, String)] = [(Self.sevenZip, "whole.7z"), (Self.zipNumbered, "whole.zip"),
            (Self.zipSpanned, "whole.zip"), (Self.rarParts, "whole.rar"), (Self.rarLegacy, "whole.rar")]
        for (set, whole) in expected {
            let wholeIcon = try icon(whole, in: wholes)
            for name in set.volumes {
                #expect(try icon(name, in: volumes) == wholeIcon, "\(name) vs \(whole)")
            }
        }
    }

    private func allFiles(engine: NativeSevenZipArchiveEngine, address: ArchiveAddress, prefix: String = "") async throws -> [String: BrowserItem] {
        var files: [String: BrowserItem] = [:]
        for item in try await engine.items(at: address) {
            let path = prefix.isEmpty ? item.name : prefix + "/" + item.name
            if item.isDirectory, case let .archive(child) = item.location {
                files.merge(try await allFiles(engine: engine, address: child, prefix: path)) { $1 }
            } else {
                files[path] = item
            }
        }
        return files
    }
}
