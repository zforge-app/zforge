import Foundation
import Testing
@testable import Zforge

/// D-117: every engine failure names its cause (CURRENT-STATE “Failure reasons”). Before, a
/// damaged item, a truncated archive and a file that is not an archive all read “The archive
/// is empty or unsupported.”, in the validation report, the error alerts and extraction.
@Suite("Engine failure reasons")
struct ArchiveFailureReasonTests {
    private static func invalid(_ message: String) -> ArchiveEngineError { .invalidArchive(message) }

    // MARK: Real archives through the statically linked 7-Zip

    private final class Folder {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        init() throws { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
        deinit { try? FileManager.default.removeItem(at: url) }
        func file(_ name: String, _ data: Data) throws -> URL {
            let file = url.appendingPathComponent(name)
            try data.write(to: file)
            return file
        }
    }

    /// A one-entry ZIP written byte by byte, so each damage is exact: `method` 0 stores,
    /// 8 deflates, 97 is a method 7-Zip does not implement. The CRC is always 0, which is
    /// wrong for the stored text.
    private static func zip(entry: String, method: UInt16, payload: Data, unpackedSize: Int) -> Data {
        var data = Data()
        func u16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        let name = Data(entry.utf8)
        u32(0x0403_4B50); u16(20); u16(0); u16(method); u16(0); u16(0)
        u32(0); u32(UInt32(payload.count)); u32(UInt32(unpackedSize)); u16(UInt16(name.count)); u16(0)
        data.append(name); data.append(payload)
        let central = data.count
        u32(0x0201_4B50); u16(20); u16(20); u16(0); u16(method); u16(0); u16(0)
        u32(0); u32(UInt32(payload.count)); u32(UInt32(unpackedSize)); u16(UInt16(name.count))
        u16(0); u16(0); u16(0); u16(0); u32(0); u32(0)
        data.append(name)
        let centralSize = data.count - central
        u32(0x0605_4B50); u16(0); u16(0); u16(1); u16(1); u32(UInt32(centralSize)); u32(UInt32(central)); u16(0)
        return data
    }

    private static let text = Data(String(repeating: "Quarterly notes\n", count: 8).utf8)

    @Test("Validate names the damaged item and the kind of damage")
    func damagedItems() async throws {
        let folder = try Folder()
        let backend = NativeSevenZipBackend()
        // 7-Zip: “CRC Failed : notes.txt”.
        let crc = try folder.file("checksum.zip", Self.zip(entry: "notes.txt", method: 0, payload: Self.text, unpackedSize: Self.text.count))
        await #expect(throws: Self.invalid("The archive is damaged: “notes.txt” does not match its checksum.")) {
            try await backend.test(at: crc, password: nil)
        }
        // 7-Zip: “Data Error : notes.txt” (0xFF bytes start a deflate block of a reserved type).
        let data = try folder.file("data.zip", Self.zip(entry: "notes.txt", method: 8, payload: Data(repeating: 0xFF, count: 32), unpackedSize: 128))
        await #expect(throws: Self.invalid("The archive is damaged: “notes.txt” cannot be decompressed.")) {
            try await backend.test(at: data, password: nil)
        }
        // 7-Zip: “Unsupported Method : notes.txt”.
        let method = try folder.file("method.zip", Self.zip(entry: "Reports/notes.txt", method: 97, payload: Self.text, unpackedSize: Self.text.count))
        await #expect(throws: Self.invalid("“Reports/notes.txt” uses a compression method Zforge does not support.")) {
            try await backend.test(at: method, password: nil)
        }
    }

    @Test("Extraction reports the same reason as Validate")
    func extractionReason() async throws {
        let folder = try Folder()
        let archive = try folder.file("data.zip", Self.zip(entry: "notes.txt", method: 8, payload: Data(repeating: 0xFF, count: 32), unpackedSize: 128))
        let engine = NativeSevenZipArchiveEngine()
        await #expect(throws: Self.invalid("The archive is damaged: “notes.txt” cannot be decompressed.")) {
            try await engine.extractArchive(at: archive, to: folder.url.appendingPathComponent("Output"), password: nil,
                resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
        }
    }

    @Test("A truncated 7z reads as incomplete when opened and validated")
    func truncatedArchive() async throws {
        let folder = try Folder()
        let source = try folder.file("Report.txt", Data((0..<20_000).map { UInt8(truncatingIfNeeded: $0 &* 7919 >> 3) }))
        let whole = folder.url.appendingPathComponent("Whole.7z")
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [source], outputURL: whole,
            options: CompressionOptions(format: .sevenZip), password: nil, progress: { _ in })
        let bytes = try Data(contentsOf: whole)
        // 7-Zip: “Cannot open the file as [7z] archive”, “ERRORS: Unexpected end of archive”.
        let truncated = try folder.file("Truncated.7z", bytes.prefix(bytes.count / 2))
        let expected = Self.invalid("The archive is incomplete: its end is missing.")
        await #expect(throws: expected) { try await NativeSevenZipBackend().test(at: truncated, password: nil) }
        await #expect(throws: expected) { _ = try await engine.openArchive(at: truncated, password: nil) }
        await engine.closeAllSessions()
    }

    @Test("A file that no handler opens is not an archive")
    func notAnArchive() async throws {
        let folder = try Folder()
        let file = try folder.file("notes.zip", Self.text)
        await #expect(throws: Self.invalid("The file is not an archive, or its format is not supported.")) {
            try await NativeSevenZipBackend().test(at: file, password: nil)
        }
    }

    @Test("A damaged compressed tar reports its outer stream's damage")
    func damagedCompressedTar() async throws {
        let folder = try Folder()
        let fixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/stream.tar.zst")
        var bytes = try Data(contentsOf: fixture)
        bytes[100] ^= 0xFF
        // 7-Zip: “Data Error : stream.tar”; the stream has no item path of its own.
        let archive = try folder.file("stream.tar.zst", bytes)
        await #expect(throws: Self.invalid("The archive is damaged: some of its data cannot be decompressed.")) {
            try await NativeSevenZipBackend().test(at: archive, password: nil)
        }
    }

    @Test("A write that fails says the archive could not be written")
    func writeFailure() async throws {
        let folder = try Folder()
        let source = try folder.file("Locked.txt", Self.text)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: source.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: source.path) }
        await #expect(throws: Self.invalid("The archive could not be written.")) {
            try await NativeSevenZipBackend().write(to: folder.url.appendingPathComponent("Out.zip"),
                options: CompressionOptions(format: .zip), password: nil,
                sources: [.init(url: source, archivePath: "Locked.txt")])
        }
    }

    // MARK: Every code the bridge reports (values from 7-Zip's IArchive.h and PropID.h)

    private static func bridgeError(code: Int = 5, result: Int32 = 1, extractResult: Int = 0,
                                    item: String? = nil, flags: UInt32 = 0) -> NSError {
        var info: [String: Any] = ["HRESULT": result, "extractResult": extractResult, "openErrorFlags": flags]
        if let item { info["failedItem"] = item }
        return NSError(domain: "Zforge.SevenZip", code: code, userInfo: info)
    }

    private static func reason(_ error: NSError, writing: Bool = false) -> Error {
        NativeSevenZipBackend.translate(error, writing: writing)
    }

    @Test("Each 7-Zip item result has its own reason, with the item when known", arguments: [
        (1, "a/b.txt", "“a/b.txt” uses a compression method Zforge does not support."),
        (1, nil, "The archive uses a compression method Zforge does not support."),
        (2, "b.txt", "The archive is damaged: “b.txt” cannot be decompressed."),
        (2, nil, "The archive is damaged: some of its data cannot be decompressed."),
        (3, "b.txt", "The archive is damaged: “b.txt” does not match its checksum."),
        (3, nil, "The archive is damaged: some of its data does not match its checksum."),
        (4, "b.txt", "Part of the archive is missing."),
        (5, "b.txt", "The archive is incomplete: its end is missing."),
        (6, "b.txt", "The file has unexpected data after the end of the archive."),
        (7, "b.txt", "The file is not an archive, or its format is not supported."),
        (8, "b.txt", "The archive is damaged: its headers cannot be read."),
    ] as [(Int, String?, String)])
    func itemResults(result: Int, item: String?, expected: String) {
        let error = Self.reason(Self.bridgeError(result: -2_147_467_259, extractResult: result, item: item))
        #expect(error as? ArchiveEngineError == Self.invalid(expected))
    }

    @Test("Each 7-Zip open error flag has its own reason", arguments: [
        (UInt32(1) << 1, "The archive is damaged: its headers cannot be read."),
        (UInt32(1) << 2, "The archive is damaged: its headers cannot be read."),
        (UInt32(1) << 3, "Part of the archive is missing."),
        (UInt32(1) << 4, "Part of the archive is missing."),
        (UInt32(1) << 5, "The archive is incomplete: its end is missing."),
        (UInt32(1) << 6, "The file has unexpected data after the end of the archive."),
        (UInt32(1) << 7, "The archive uses a compression method Zforge does not support."),
        (UInt32(1) << 8, "The archive uses a feature Zforge does not support."),
        (UInt32(1) << 9, "The archive is damaged: some of its data cannot be decompressed."),
        (UInt32(1) << 10, "The archive is damaged: some of its data does not match its checksum."),
        // Several flags: the incomplete end explains the rest.
        (UInt32(1) << 5 | UInt32(1) << 6 | UInt32(1) << 1, "The archive is incomplete: its end is missing."),
    ])
    func openFlags(flags: UInt32, expected: String) {
        #expect(Self.reason(Self.bridgeError(flags: flags)) as? ArchiveEngineError == Self.invalid(expected))
    }

    @Test("The bridge's own failures keep their reasons and the rest is generic")
    func otherFailures() {
        // An item result does not override the reasons the bridge decides itself.
        #expect(Self.reason(Self.bridgeError(code: 2, extractResult: 2, item: "b.txt")) as? ArchiveEngineError == .invalidPassword)
        #expect(Self.reason(Self.bridgeError(code: 6, extractResult: 2)) as? ArchiveEngineError == .insufficientSpace)
        // The item result explains the failure better than the archive's flags.
        #expect(Self.reason(Self.bridgeError(extractResult: 3, item: "b.txt", flags: 1 << 5)) as? ArchiveEngineError
            == Self.invalid("The archive is damaged: “b.txt” does not match its checksum."))
        #expect(Self.reason(Self.bridgeError(code: 10)) as? ArchiveEngineError
            == Self.invalid("The archive contains a sparse file, which Zforge does not support."))
        // No handler opened the file (S_FALSE) and none recognized it.
        #expect(Self.reason(Self.bridgeError(result: 1)) as? ArchiveEngineError
            == Self.invalid("The file is not an archive, or its format is not supported."))
        #expect(Self.reason(Self.bridgeError(result: 1, flags: 1)) as? ArchiveEngineError
            == Self.invalid("The file is not an archive, or its format is not supported."))
        // E_FAIL with nothing else known.
        #expect(Self.reason(Self.bridgeError(result: -2_147_467_259)) as? ArchiveEngineError
            == Self.invalid("The archive could not be read."))
        #expect(Self.reason(Self.bridgeError(result: -2_147_467_259), writing: true) as? ArchiveEngineError
            == Self.invalid("The archive could not be written."))
        let foreign = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
        #expect((Self.reason(foreign) as NSError) == foreign)
    }

    @Test("Every reason is translated", arguments: AppLanguagePreference.supportedLanguages.filter { $0 != .english })
    func reasonsAreTranslated(language: AppLanguagePreference) {
        let keys = ["archive.reason.unsupported_method %@", "archive.reason.data_error %@", "archive.reason.crc_error %@",
                    "archive.reason.unsupported_method", "archive.reason.data_error", "archive.reason.crc_error",
                    "archive.reason.incomplete", "archive.reason.unavailable", "archive.reason.headers",
                    "archive.reason.data_after_end", "archive.reason.not_archive", "archive.reason.unsupported_feature",
                    "archive.reason.sparse", "archive.reason.unreadable", "archive.reason.unwritable"]
        for key in keys {
            let english = AppLocalization.string(String.LocalizationValue(key), locale: AppLanguagePreference.english.locale)
            let translated = AppLocalization.string(String.LocalizationValue(key), locale: language.locale)
            #expect(english != key && translated != english && translated != key, "\(language): \(key) = \(translated)")
        }
    }
}
