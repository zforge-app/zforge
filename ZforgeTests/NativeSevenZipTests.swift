import Foundation
import Testing
@testable import Zforge

@Suite("Native statically linked 7-Zip")
struct NativeSevenZipTests {
    private var fixture: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/sample-root.zip")
    }

    @Test("Native extraction remains anchored to the authorized output root")
    func outputRootBoundary() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destination = root.appendingPathComponent("Output")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let outside = root.appendingPathComponent("Escaped.txt")
        await #expect(throws: (any Error).self) {
            try await NativeSevenZipBackend().extract(at: fixture, password: nil, paths: [],
                destination: destination, outputFile: outside)
        }
        #expect(!FileManager.default.fileExists(atPath: outside.path))
    }

    @Test("Advanced properties work through the actual native handlers")
    func advancedProperties() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("Input.txt")
        let data = Data(repeating: 65, count: 10000)
        try data.write(to: source)
        let choices = [
            CompressionOptions(format: .sevenZip, level: 9, method: .lzma2, dictionaryMB: 16, fastBytes: 128, solid: false, threads: 2, requiresPassword: true, encryptFileNames: true),
            CompressionOptions(format: .zip, level: 9, method: .deflate, fastBytes: 128, threads: 2, requiresPassword: true, zipEncryption: .zipCrypto),
            CompressionOptions(format: .xz, level: 9, dictionaryMB: 16, threads: 2)
        ]
        let engine = NativeSevenZipArchiveEngine()
        for options in choices {
            let archive = root.appendingPathComponent("Options." + options.format.fileExtension)
            try await engine.createArchive(from: [source], outputURL: archive,
                options: options, password: options.requiresPassword ? "options-test" : nil, progress: { _ in })
            try await engine.testArchive(at: archive, password: "options-test")
            let opened = try await engine.openArchive(at: archive, password: "options-test")
            let entry = try #require(try await engine.items(at: opened.address).first)
            let result = try await engine.materialize(item: entry, purpose: .preview, automaticLimit: nil)
            #expect(try Data(contentsOf: result) == data)
            await engine.closeSession(opened.address.sessionID)
        }
    }

    @Test("Split 7z and ZIP volumes expose their actual archive entries")
    func splitVolumes() async throws {
        let engine = NativeSevenZipArchiveEngine()
        for name in ["split.7z.001", "split.zip.001"] {
            let archive = fixture.deletingLastPathComponent().appendingPathComponent(name)
            try await engine.testArchive(at: archive, password: nil)
            let opened = try await engine.openArchive(at: archive, password: nil)
            let entries = try await engine.items(at: opened.address)
            let item = try #require(entries.first { $0.name == "payload.bin" })
            #expect(item.size == 20000)
            let data = try await engine.materialize(item: item, purpose: .preview, automaticLimit: nil)
            #expect(try Data(contentsOf: data).count == 20000)
            await engine.closeSession(opened.address.sessionID)
        }
    }

    @Test("Symlink sources remain links and do not recurse into targets")
    func symlinkRoundTrip() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appendingPathComponent("Target.txt")
        let link = root.appendingPathComponent("Link.txt")
        try Data("link target".utf8).write(to: target)
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "Target.txt")
        let engine = NativeSevenZipArchiveEngine()
        for format in [ArchiveCompressionFormat.zip, .sevenZip, .tar] {
            let archive = root.appendingPathComponent("links." + format.fileExtension)
            try await engine.createArchive(from: [target, link], outputURL: archive,
                options: CompressionOptions(format: format), password: nil, progress: { _ in })
            let destination = root.appendingPathComponent(format.fileExtension)
            try await engine.extractArchive(at: archive, to: destination, password: nil,
                resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
            #expect(try FileManager.default.destinationOfSymbolicLink(atPath: destination.appendingPathComponent("Link.txt").path) == "Target.txt")
            #expect(try Data(contentsOf: destination.appendingPathComponent("Link.txt")) == Data("link target".utf8))
        }
    }

    @Test("All output formats and RAR handlers remain linked")
    func registeredFormats() {
        let formats = Set(NativeSevenZipBackend.registeredFormats())
        #expect(Set(["7z", "zip", "tar", "xz", "bzip2", "gzip", "wim", "Rar", "Rar5"]).isSubset(of: formats))
        #expect(formats.count == 60)
    }

    @Test("Native test detects an item CRC failure")
    func corruptedItem() async throws {
        let corrupt = fixture.deletingLastPathComponent().appendingPathComponent("corrupt-item.zip")
        await #expect(throws: (any Error).self) {
            try await NativeSevenZipBackend().test(at: corrupt, password: nil)
        }
    }

    @Test("Existing destination symlinks cannot redirect extraction")
    func symlinkDestination() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outside = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: outside) }
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("Folder"), withDestinationURL: outside)
        await #expect(throws: ArchiveEngineError.unsafePath) {
            try await NativeSevenZipBackend().extract(at: fixture, password: nil, paths: ["Folder"], destination: root)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: outside.path).isEmpty)
    }

    @Test("Native names preserve Unicode, delimiters and line breaks")
    func structuredNames() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let name = "ação 🗜️ = value\nsecond line.txt"
        let source = root.appendingPathComponent(name)
        let archive = root.appendingPathComponent("Names.7z")
        try Data("native names".utf8).write(to: source)
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [source], outputURL: archive,
            options: CompressionOptions(format: .sevenZip), password: nil, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: nil)
        let entry = try #require(try await engine.items(at: opened.address).first { $0.name == name })
        let materialized = try await engine.materialize(item: entry, purpose: .preview, automaticLimit: nil)
        #expect(try Data(contentsOf: materialized) == Data("native names".utf8))
        await engine.closeAllSessions()
    }

    @Test("Native output stream enforces actual byte limit")
    func outputLimit() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        await #expect(throws: ArchiveEngineError.sizeLimitExceeded) {
            try await NativeSevenZipBackend().extract(at: fixture, password: nil, paths: ["hello.txt"],
                destination: root, outputFile: root.appendingPathComponent("hello.txt"), byteLimit: 4)
        }
    }

    @Test("Cancellation reaches the native worker before opening")
    func cancelledTask() async throws {
        let work = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await NativeSevenZipBackend().test(at: fixture, password: nil)
        }
        do { try await work.value; Issue.record("Cancelled native work succeeded") }
        catch is CancellationError { }
        catch let error as ArchiveEngineError { #expect(error == .cancelled) }
    }

    @Test("Native extraction rejects traversal and does not create outside destination")
    func traversal() async throws {
        let archive = fixture.deletingLastPathComponent().appendingPathComponent("unsafe-path.zip")
        await #expect(throws: ArchiveEngineError.unsafePath) {
            _ = try await NativeSevenZipBackend().list(at: archive, password: nil)
        }
    }
}
