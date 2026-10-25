import Foundation
import Testing
@testable import Zforge

@Suite("Native statically linked 7-Zip")
struct NativeSevenZipTests {
    private var fixture: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/sample-root.zip")
    }

    @Test("Archive folder paper reflects files, including zero-byte nested files, not empty directories")
    func archiveDirectoryContentsState() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let input = root.appendingPathComponent("Input")
        defer { try? FileManager.default.removeItem(at: root) }
        for path in ["Empty", "OnlyEmpty/Nested", "Full/Nested", "FullSibling"] {
            try FileManager.default.createDirectory(at: input.appendingPathComponent(path), withIntermediateDirectories: true)
        }
        try Data().write(to: input.appendingPathComponent("Full/Nested/.zero-byte.txt"))
        let engine = NativeSevenZipArchiveEngine()
        for format in [ArchiveCompressionFormat.zip, .sevenZip] {
            let archive = root.appendingPathComponent("Contents." + format.fileExtension)
            try await engine.createArchive(from: [input], outputURL: archive,
                options: CompressionOptions(format: format), password: nil, progress: { _ in })
            let opened = try await engine.openArchive(at: archive, password: nil)
            let parent = try #require(try await engine.items(at: opened.address).first { $0.name == "Input" })
            #expect(parent.archiveDirectoryContainsFiles)
            guard case let .archive(inputAddress) = parent.location else { throw ArchiveEngineError.itemNotFound }
            let children = try await engine.items(at: inputAddress)
            for name in ["Empty", "OnlyEmpty", "FullSibling"] {
                let empty = try #require(children.first { $0.name == name })
                #expect(!empty.archiveDirectoryContainsFiles)
            }
            let full = try #require(children.first { $0.name == "Full" })
            #expect(full.archiveDirectoryContainsFiles)
            guard case let .archive(fullAddress) = full.location else { throw ArchiveEngineError.itemNotFound }
            let nested = try #require(try await engine.items(at: fullAddress).first { $0.name == "Nested" })
            #expect(nested.archiveDirectoryContainsFiles)
            await engine.closeSession(opened.address.sessionID)
        }
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

    @Test("Partial extraction maps every selected entry to its own destination",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func partialSelectionMapping(format: ArchiveCompressionFormat) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let input = root.appendingPathComponent("Input")
        defer { try? FileManager.default.removeItem(at: root) }
        // Enough entries that a wrong index-to-destination association is observable, with
        // siblings sharing a name prefix, a nested folder and a Unicode folder name.
        var contents: [String: Data] = [:]
        for folder in ["Folder", "Folder/Nested", "Folder2", "Ação 🗜️"] {
            try FileManager.default.createDirectory(at: input.appendingPathComponent(folder), withIntermediateDirectories: true)
            for index in 0..<150 {
                contents["\(folder)/Item-\(index).txt"] = Data("\(folder) item \(index) payload".utf8)
            }
        }
        contents["Folder.txt"] = Data("Sibling file sharing the folder prefix".utf8)
        for (path, data) in contents { try data.write(to: input.appendingPathComponent(path)) }
        let archive = root.appendingPathComponent("Selection." + format.fileExtension)
        let engine = NativeSevenZipArchiveEngine()
        let sources = try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil)
        try await engine.createArchive(from: sources, outputURL: archive,
            options: CompressionOptions(format: format), password: nil, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let rootItems = try await engine.items(at: opened.address)
        let folder = try #require(rootItems.first { $0.name == "Folder" })
        let unicode = try #require(rootItems.first { $0.name == "Ação 🗜️" })
        let folder2 = try #require(rootItems.first { $0.name == "Folder2" })
        guard case let .archive(folder2Address) = folder2.location else { throw ArchiveEngineError.itemNotFound }
        let single = try #require(try await engine.items(at: folder2Address).first { $0.name == "Item-7.txt" })
        let destination = root.appendingPathComponent("Output")
        try await engine.extractItems([single, unicode, folder], to: destination, password: nil,
            resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })

        let expected = contents.filter { path, _ in
            path.hasPrefix("Folder/") || path.hasPrefix("Ação 🗜️/") || path == "Folder2/Item-7.txt"
        }
        var extracted: [String: Data] = [:]
        let enumerator = try #require(FileManager.default.enumerator(at: destination, includingPropertiesForKeys: [.isRegularFileKey]))
        for case let file as URL in enumerator.allObjects where try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true {
            let relative = String(file.standardizedFileURL.path.dropFirst(destination.standardizedFileURL.path.count + 1))
            extracted[relative] = try Data(contentsOf: file)
        }
        #expect(expected.count == 451)
        #expect(Set(extracted.keys) == Set(expected.keys))
        for (path, data) in expected { #expect(extracted[path] == data, "Wrong content at \(path)") }
    }

    @Test("Extraction conflicts of a selection ask only about selected items and honor keep, replace and cancel",
          arguments: ["keep", "replace", "cancel"])
    func selectedExtractionConflicts(decision: String) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let input = root.appendingPathComponent("Input")
        let destination = root.appendingPathComponent("Output")
        defer { try? FileManager.default.removeItem(at: root) }
        for folder in ["Folder", "Folder2"] {
            try FileManager.default.createDirectory(at: input.appendingPathComponent(folder), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: destination.appendingPathComponent(folder), withIntermediateDirectories: true)
            try Data("archived \(folder)".utf8).write(to: input.appendingPathComponent("\(folder)/item.txt"))
            try Data("existing \(folder)".utf8).write(to: destination.appendingPathComponent("\(folder)/item.txt"))
        }
        try Data("archived new".utf8).write(to: input.appendingPathComponent("Folder/new.txt"))
        let archive = root.appendingPathComponent("Conflicts.zip")
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil),
            outputURL: archive, options: CompressionOptions(format: .zip), password: nil, progress: { _ in })
        let opened = try await engine.openArchive(at: archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let folder = try #require(try await engine.items(at: opened.address).first { $0.name == "Folder" })
        let asked = ConflictLog()
        let choice: ArchiveConflictDecision = switch decision {
        case "keep": .keep(applyToAll: false)
        case "replace": .replace(applyToAll: false)
        default: .cancel
        }
        let extraction = { try await engine.extractItems([folder], to: destination, password: nil,
            resolveConflict: { conflict in await asked.append(conflict.path); return choice }, progress: { _ in }) }
        if decision == "cancel" {
            await #expect(throws: ArchiveEngineError.cancelled) { try await extraction() }
        } else {
            try await extraction()
        }
        // The sibling sharing the "Folder" prefix is neither asked about nor touched.
        #expect(await asked.paths == ["Folder/item.txt"])
        let contents = { (path: String) in try String(contentsOf: destination.appendingPathComponent(path), encoding: .utf8) }
        #expect(try contents("Folder2/item.txt") == "existing Folder2")
        #expect(try contents("Folder/item.txt") == (decision == "replace" ? "archived Folder" : "existing Folder"))
        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("Folder/new.txt").path) == (decision != "cancel"))
    }

    @Test("Existing destination file links are resolved before extraction writes")
    func symlinkLeafDestination() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outside = root.appendingPathComponent("Outside")
        let destination = root.appendingPathComponent("Output")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let target = outside.appendingPathComponent("target.txt")
        try Data("outside".utf8).write(to: target)
        try FileManager.default.createSymbolicLink(at: destination.appendingPathComponent("hello.txt"), withDestinationURL: target)
        await #expect(throws: ArchiveEngineError.unsafePath) {
            try await NativeSevenZipBackend().extract(at: fixture, password: nil, paths: [], destination: destination)
        }
        #expect(try Data(contentsOf: target) == Data("outside".utf8))

        // A link that stays inside the destination is an existing item; Keep skips it untouched.
        let contained = root.appendingPathComponent("Contained")
        try FileManager.default.createDirectory(at: contained, withIntermediateDirectories: true)
        try Data("kept".utf8).write(to: contained.appendingPathComponent("kept.txt"))
        try FileManager.default.createSymbolicLink(atPath: contained.appendingPathComponent("hello.txt").path,
                                                   withDestinationPath: "kept.txt")
        try await NativeSevenZipBackend().extract(at: fixture, password: nil, paths: ["hello.txt"], destination: contained)
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: contained.appendingPathComponent("hello.txt").path) == "kept.txt")
        #expect(try Data(contentsOf: contained.appendingPathComponent("kept.txt")) == Data("kept".utf8))
    }
}

private actor ConflictLog {
    private(set) var paths: [String] = []
    func append(_ path: String) { paths.append(path) }
}

@Suite("Archive path selection")
struct ArchivePathSelectionTests {
    @Test("Selected items match themselves and descendants only")
    func itemsAndDescendants() {
        let selection = ArchivePathSelection(["Folder", "Docs/Report.txt"])
        for path in ["Folder", "Folder/a.txt", "Folder/Nested/b.txt", "Docs/Report.txt"] {
            #expect(selection.contains(path), "\(path) should be selected")
        }
        for path in ["Folder2", "Folder2/a.txt", "Folder.txt", "Docs", "Docs/Report.txt.bak", "Other", ""] {
            #expect(!selection.contains(path), "\(path) should not be selected")
        }
        #expect(!ArchivePathSelection([]).contains("Folder"))
    }

    @Test("Selection keeps String equality semantics for names and separators")
    func stringSemantics() {
        // Canonically equivalent spellings compare equal, as with String ==.
        #expect(ArchivePathSelection(["Cafe\u{301}"]).contains("Caf\u{e9}/menu.txt"))
        #expect(ArchivePathSelection(["Caf\u{e9}"]).contains("Cafe\u{301}"))
        // A combining mark attached to the separator does not form a path boundary.
        #expect(!ArchivePathSelection(["a"]).contains("a/\u{301}b"))
        // Empty components after the selected item still denote descendants.
        #expect(ArchivePathSelection(["a"]).contains("a//b"))
        #expect(ArchivePathSelection(["a/"]).contains("a//b"))
    }
}
