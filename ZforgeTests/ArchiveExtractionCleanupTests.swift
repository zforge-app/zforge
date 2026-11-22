import Foundation
import Testing
@testable import Zforge

/// D-117: an extraction that stops at the password writes nothing. 7-Zip creates an item's
/// output before it asks for the password, so Extract Here cancelled at the password sheet
/// left an empty file (and the item's folders) beside the archive, and a retry after a wrong
/// password met that file as a conflict (CURRENT-STATE “Extraction”).
@Suite("Extraction leaves nothing when it stops at the password")
struct ArchiveExtractionCleanupTests {
    private static let password = "cleanup-secret"

    private final class Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ExtractionCleanup-\(UUID().uuidString)")
        let archive: URL
        let format: ArchiveCompressionFormat

        init(format: ArchiveCompressionFormat, zipEncryption: ZIPEncryption) async throws {
            self.format = format
            let input = root.appendingPathComponent("Input", isDirectory: true)
            let docs = input.appendingPathComponent("Docs", isDirectory: true)
            try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
            try Data("Contract terms".utf8).write(to: docs.appendingPathComponent("Contract.txt"))
            try Data("Meeting notes".utf8).write(to: input.appendingPathComponent("Notes.txt"))
            var options = CompressionOptions(format: format)
            options.requiresPassword = true
            options.encryptFileNames = false
            if format == .zip { options.zipEncryption = zipEncryption }
            // Extract Here writes into the archive's own folder.
            let here = root.appendingPathComponent("Here", isDirectory: true)
            try FileManager.default.createDirectory(at: here, withIntermediateDirectories: true)
            archive = here.appendingPathComponent("Contents.\(format.fileExtension)")
            try await NativeSevenZipArchiveEngine().createArchive(
                from: [docs, input.appendingPathComponent("Notes.txt")], outputURL: archive, options: options,
                password: ArchiveExtractionCleanupTests.password, progress: { _ in })
        }

        var here: URL { archive.deletingLastPathComponent() }
        deinit { try? FileManager.default.removeItem(at: root) }

        /// Every path below the folder, relative to it.
        func contents() -> [String] {
            let enumerator = FileManager.default.enumerator(atPath: here.path)
            return (enumerator?.allObjects as? [String] ?? []).sorted()
        }
    }

    private final class Conflicts: @unchecked Sendable {
        private let lock = NSLock()
        private var names: [String] = []
        var asked: [String] { lock.withLock { names } }
        func record(_ conflict: ArchiveConflict) { lock.withLock { names.append(conflict.destinationURL.lastPathComponent) } }
    }

    @Test("Without the password or with a wrong one nothing is written; the right one then extracts with no conflict",
          arguments: [(ArchiveCompressionFormat.zip, ZIPEncryption.zipCrypto), (.zip, .aes256), (.sevenZip, .aes256)])
    func passwordFailuresLeaveNothing(format: ArchiveCompressionFormat, zipEncryption: ZIPEncryption) async throws {
        let fixture = try await Fixture(format: format, zipEncryption: zipEncryption)
        let engine = NativeSevenZipArchiveEngine()
        let conflicts = Conflicts()
        func extract(_ password: String?) async throws {
            try await engine.extractArchive(at: fixture.archive, to: fixture.here, password: password,
                resolveConflict: { conflict in conflicts.record(conflict); return .keep(applyToAll: true) },
                progress: { _ in })
        }
        let before = fixture.contents()
        #expect(before == ["Contents.\(format.fileExtension)"])

        await #expect(throws: ArchiveEngineError.passwordRequired) { try await extract(nil) }
        #expect(fixture.contents() == before, "Cancel at the password sheet must leave nothing")

        await #expect(throws: ArchiveEngineError.invalidPassword) { try await extract("wrong-password") }
        #expect(fixture.contents() == before, "A wrong password must leave nothing")

        try await extract(Self.password)
        #expect(conflicts.asked.isEmpty, "The retry met files a failed attempt left: \(conflicts.asked)")
        #expect(fixture.contents() == before + ["Docs", "Docs/Contract.txt", "Notes.txt"].sorted())
        #expect(try String(contentsOf: fixture.here.appendingPathComponent("Docs/Contract.txt"), encoding: .utf8) == "Contract terms")
        #expect(try String(contentsOf: fixture.here.appendingPathComponent("Notes.txt"), encoding: .utf8) == "Meeting notes")
    }

    @Test("A folder that was already there stays, even when empty")
    func existingFoldersStay() async throws {
        let fixture = try await Fixture(format: .zip, zipEncryption: .aes256)
        try FileManager.default.createDirectory(at: fixture.here.appendingPathComponent("Docs"), withIntermediateDirectories: false)
        await #expect(throws: ArchiveEngineError.passwordRequired) {
            try await NativeSevenZipArchiveEngine().extractArchive(at: fixture.archive, to: fixture.here, password: nil,
                resolveConflict: { _ in .keep(applyToAll: true) }, progress: { _ in })
        }
        #expect(fixture.contents() == ["Contents.zip", "Docs"])
    }
}
