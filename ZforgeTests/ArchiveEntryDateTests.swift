import Foundation
import Testing
@testable import Zforge

/// D-103: a date an archive does not store is unavailable, never the FILETIME epoch.
@Suite("Archive entry dates (D-103)")
struct ArchiveEntryDateTests {
    static let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")

    /// `sample.zip` stores each entry's times in an NTFS extra field whose creation and access
    /// times are zero (unset); only the modification time is set. 7-Zip treats a zero FILETIME as
    /// empty, so Zforge must report those dates as missing.
    @Test("Zero NTFS creation and access times are missing dates; the modification date is kept")
    func zeroFileTimesAreMissing() async throws {
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let opened = try await engine.openArchive(at: Self.fixtures.appendingPathComponent("sample.zip"), password: nil)
        let items = try await engine.items(at: opened.address)
        let hello = try #require(items.first { $0.name == "hello.txt" })
        #expect(hello.creationDate == nil)
        #expect(hello.accessDate == nil)
        let modified = try #require(hello.modificationDate)
        #expect(Calendar(identifier: .gregorian).component(.year, from: modified) == 2026)

        let summary = BrowserSelectionSummary(items: [hello], locale: Locale(identifier: "en_US"))
        #expect(summary.creationRange == "—")
        #expect(summary.accessRange == "—")
        #expect(summary.modificationRange != "—")
    }
}
