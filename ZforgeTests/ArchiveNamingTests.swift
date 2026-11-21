import Foundation
import Testing
@testable import Zforge

/// The folder Extract to “Name” and the Finder Extract flow create is named after the
/// archive without every suffix of its format (D-116).
@Suite("Archive naming")
struct ArchiveNamingTests {
    @Test("A compressed tar loses both suffixes, for every compression the app recognizes", arguments: [
        "Backup.tar.gz", "Backup.tar.gzip", "Backup.tar.bz2", "Backup.tar.bzip2", "Backup.tar.xz",
        "Backup.tar.zst", "Backup.tar.lzma", "Backup.TAR.ZST", "Backup.Tar.Gz"
    ])
    func compoundTarSuffix(name: String) {
        #expect(ArchiveFormatRegistry.recognizes(name), "\(name) must be recognized as an archive")
        #expect(ArchiveNaming.baseName(name) == "Backup", "\(name)")
        #expect(ArchiveNaming.extractionDirectoryName(for: name, fallback: "Archive") == "Backup", "\(name)")
    }

    @Test("A single-suffix tar shorthand loses its suffix", arguments: [
        "Backup.tgz", "Backup.tbz", "Backup.tbz2", "Backup.txz", "Backup.tzst", "Backup.tar"
    ])
    func tarShorthand(name: String) {
        #expect(ArchiveFormatRegistry.recognizes(name), "\(name) must be recognized as an archive")
        #expect(ArchiveNaming.baseName(name) == "Backup", "\(name)")
    }

    @Test("Every compressed-tar suffix the format recognition accepts is stripped whole")
    func everyRecognizedCompressionIsCovered() {
        for compression in ArchiveFormatRegistry.streamCompressionExtensions {
            let name = "Backup.tar.\(compression)"
            #expect(ArchiveFormatRegistry.recognizes(name), "\(name)")
            #expect(ArchiveNaming.baseName(name) == "Backup", "\(name)")
        }
    }

    @Test("Only a tar inside a compressed stream loses two suffixes")
    func otherDoubleSuffixesKeepTheirStem() {
        // A single compressed file is named after the file it holds, as 7-Zip does.
        #expect(ArchiveNaming.baseName("notes.txt.gz") == "notes.txt")
        #expect(ArchiveNaming.baseName("Backup.zip") == "Backup")
        #expect(ArchiveNaming.baseName("Report 2.0.7z") == "Report 2.0")
        // A name that is only the suffix keeps the fallback for the folder.
        #expect(ArchiveNaming.extractionDirectoryName(for: ".tar.zst", fallback: "Archive") == "Archive")
    }
}
