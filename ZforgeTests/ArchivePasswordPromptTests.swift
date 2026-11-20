import Foundation
import Testing
@testable import Zforge

/// The password sheet says what the password unlocks (D-116): browsing, extracting or
/// validating, and whether Zforge keeps it for the window.
@Suite("Archive password prompt")
@MainActor
struct ArchivePasswordPromptTests {
    private typealias Operation = FileBrowserState.PasswordOperation
    private static let english = Locale(identifier: "en")
    private static let browse = "Enter the password to browse this archive. It stays in memory only for this window."

    @Test("Opening, entering or expanding an archive asks to browse it")
    func browsingPrompt() {
        let archive = Self.localItem("Backup.zip")
        let inner = Self.archiveItem("Inner.7z")
        #expect(Operation.openFile(URL(fileURLWithPath: "/tmp/Backup.zip"), asWindowRoot: false).prompt(locale: Self.english) == Self.browse)
        #expect(Operation.openInnerArchive(inner, columnParent: nil).prompt(locale: Self.english) == Self.browse)
        #expect(Operation.expandInline(archive).prompt(locale: Self.english) == Self.browse)
    }

    @Test("Extracting or validating archive files names the archive and keeps nothing")
    func archiveFilePrompts() {
        let archive = Self.localItem("Backup.zip")
        #expect(Operation.extractArchive(archive).prompt(locale: Self.english) == "Enter the password to extract “Backup.zip”.")
        #expect(Operation.validateArchive(archive).prompt(locale: Self.english) == "Enter the password to validate “Backup.zip”.")
    }

    @Test("Extracting items of an open archive names them and keeps the password for the window")
    func itemExtractionPrompts() {
        let destination = URL(fileURLWithPath: "/tmp/Out", isDirectory: true)
        let one = Self.archiveItem("Report.txt")
        let two = Self.archiveItem("Notes.txt")
        #expect(Operation.extractItems([one], destinationURL: destination).prompt(locale: Self.english)
            == "Enter the password to extract “Report.txt”. It stays in memory only for this window.")
        #expect(Operation.extractItems([one, two], destinationURL: destination).prompt(locale: Self.english)
            == "Enter the password to extract the selected items. It stays in memory only for this window.")
    }

    @Test("Every prompt is translated", arguments: AppLanguagePreference.supportedLanguages.filter { $0 != .english })
    func promptsAreTranslated(language: AppLanguagePreference) {
        let archive = Self.localItem("Backup.zip")
        let destination = URL(fileURLWithPath: "/tmp/Out", isDirectory: true)
        let operations: [Operation] = [
            .expandInline(archive), .extractArchive(archive), .validateArchive(archive),
            .extractItems([Self.archiveItem("Report.txt")], destinationURL: destination),
            .extractItems([Self.archiveItem("A.txt"), Self.archiveItem("B.txt")], destinationURL: destination)
        ]
        let english = operations.map { $0.prompt(locale: Self.english) }
        let translated = operations.map { $0.prompt(locale: language.locale) }
        for (index, text) in translated.enumerated() {
            #expect(text != english[index], "\(language): \(text)")
        }
        #expect(Set(translated).count == translated.count, "\(language) distinguishes every action: \(translated)")
        #expect(translated[1].contains("Backup.zip") && translated[3].contains("Report.txt"), "\(language)")
    }

    static func localItem(_ name: String) -> BrowserItem {
        item(name, location: .fileSystem(URL(fileURLWithPath: "/tmp").appendingPathComponent(name)), isArchive: true)
    }

    static func archiveItem(_ name: String) -> BrowserItem {
        item(name, location: .archive(ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: name)),
             isArchive: name.hasSuffix(".7z"))
    }

    private static func item(_ name: String, location: BrowserLocation, isArchive: Bool) -> BrowserItem {
        BrowserItem(id: BrowserItemID(rawValue: name), name: name, location: location, isContainer: false,
            isDirectory: false, isPackage: false, isSymbolicLink: false, isHidden: false, isArchive: isArchive,
            size: 10, packedSize: nil, creationDate: nil, modificationDate: nil, accessDate: nil, tags: [],
            contentTypeIdentifier: nil, encrypted: false, checksum: nil, compressionMethod: nil)
    }
}
