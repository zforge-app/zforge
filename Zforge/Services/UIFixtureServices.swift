import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
enum IconPreviewUIFixture {
    static func create(at directory: URL, archives: any ArchiveServing) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("Empty Folder", isDirectory: true),
            withIntermediateDirectories: true
        )
        guard let imageContext = CGContext(data: nil, width: 160, height: 120,
            bitsPerComponent: 8, bytesPerRow: 640,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CocoaError(.fileWriteUnknown)
        }
        imageContext.setFillColor(CGColor(red: 0, green: 0.7, blue: 0.75, alpha: 1))
        imageContext.fill(CGRect(x: 0, y: 0, width: 160, height: 120))
        imageContext.setFillColor(CGColor(red: 1, green: 0.45, blue: 0, alpha: 1))
        imageContext.fill(CGRect(x: 0, y: 0, width: 160, height: 60))
        guard let image = imageContext.makeImage() else { throw CocoaError(.fileWriteUnknown) }
        for (type, name) in [(UTType.png, "Preview.png"), (.jpeg, "Preview.jpg")] {
            guard let destination = CGImageDestinationCreateWithURL(
                directory.appendingPathComponent(name) as CFURL, type.identifier as CFString, 1, nil
            ) else { throw CocoaError(.fileWriteUnknown) }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        }

        var page = CGRect(x: 0, y: 0, width: 240, height: 320)
        guard let context = CGContext(directory.appendingPathComponent("Preview.pdf") as CFURL,
            mediaBox: &page, nil) else { throw CocoaError(.fileWriteUnknown) }
        context.beginPDFPage(nil)
        context.setFillColor(NSColor.systemTeal.cgColor)
        context.fill(CGRect(x: 24, y: 190, width: 192, height: 106))
        context.setFillColor(NSColor.systemOrange.cgColor)
        context.fillEllipse(in: CGRect(x: 70, y: 44, width: 100, height: 100))
        context.endPDFPage()
        context.closePDF()

        try Data("Icon preview fixture\nA plain text document with a visible content preview.\n".utf8)
            .write(to: directory.appendingPathComponent("Preview.txt"))
        try Data("<!doctype html><html><body><h1>Icon preview fixture</h1><p>HTML content preview.</p></body></html>".utf8)
            .write(to: directory.appendingPathComponent("Preview.html"))
        try Data(repeating: 0xFF, count: 128).write(to: directory.appendingPathComponent("Unsupported.bin"))
        try await archives.createArchive(
            from: [directory.appendingPathComponent("Preview.png")],
            outputURL: directory.appendingPathComponent("Sample.zip"),
            format: .zip, progress: { _ in }
        )
    }
}

@MainActor
final class UIFixtureRecentItemsService: RecentItemsServing {
    func recentItemURLs() async -> [URL] {
        let originals = ["Fixture Folder", "Welcome.txt", "Sample.zip", "Another.txt"].map {
            URL(fileURLWithPath: "/ZforgeFixtures/\($0)")
        }
        guard ProcessInfo.processInfo.arguments.contains("--ui-recents-duplicates") else {
            return originals
        }
        let sessionsRoot = ZforgeTemporaryStorage.archiveSessionsRoot()
        return [
            sessionsRoot.appendingPathComponent("First/Sample.zip"),
            originals[0], originals[1], originals[2], originals[3],
            sessionsRoot.appendingPathComponent("Second/Sample.zip")
        ]
    }

    func stop() {}
}

@MainActor
final class UIFixtureTaggedItemsService: TaggedItemsServing {
    func itemURLs(tagged tag: String) async -> [URL] {
        tag == "Red" ? [URL(fileURLWithPath: "/ZforgeFixtures/Welcome.txt")] : []
    }

    func stop() {}
}

actor UIFixtureFileSystemService: FileSystemServing {
    private let itemsDelay: Duration

    init(itemsDelay: Duration = .zero) {
        self.itemsDelay = itemsDelay
    }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        if itemsDelay > .zero, directory.lastPathComponent == "Fixture Folder" {
            try await Task.sleep(for: itemsDelay)
            return [makeItem(name: "FolderChild.txt", url: directory.appendingPathComponent("FolderChild.txt"))]
        }
        let items = [
            makeItem(name: "Fixture Folder", directory: true),
            makeItem(name: "Welcome.txt", size: 1_024),
            makeItem(name: "Another.txt", size: 2_048),
            makeItem(name: "Sample.zip", archive: true, size: 4_096),
            makeItem(name: ".Hidden Fixture", size: 32, hidden: true)
        ]
        return showHidden ? items : items.filter { !$0.isHidden }
    }

    func item(at url: URL) async throws -> BrowserItem {
        makeItem(
            name: url.lastPathComponent,
            directory: url.lastPathComponent == "Fixture Folder",
            archive: ArchiveFormatRegistry.recognizes(url.lastPathComponent),
            url: url
        )
    }

    func recursiveSize(at url: URL) async throws -> Int64 { 0 }

    func resolveNavigationURL(_ url: URL) async throws -> URL { url }

    private func makeItem(
        name: String, directory: Bool = false, archive: Bool = false,
        size: Int64? = nil, hidden: Bool = false, url: URL? = nil
    ) -> BrowserItem {
        let url = url ?? URL(fileURLWithPath: "/ZforgeFixtures/\(name)")
        return BrowserItem(
            id: BrowserItemID(rawValue: "fixture:\(url.standardizedFileURL.path)"),
            name: name, location: .fileSystem(url),
            isContainer: directory, isDirectory: directory, isPackage: false,
            isSymbolicLink: false, isHidden: hidden, isArchive: archive, size: size,
            packedSize: nil, creationDate: nil, modificationDate: Date(timeIntervalSince1970: 1_700_000_000),
            accessDate: nil, tags: name == "Welcome.txt" ? ["Red"] : [],
            contentTypeIdentifier: nil, encrypted: false,
            checksum: nil, compressionMethod: archive ? "Deflate" : nil
        )
    }
}

actor UIFixtureAccessGrantStore: AccessGrantStoring {
    func hasGrant(for url: URL) async -> Bool { true }
    func storeGrant(for url: URL) async throws {}
    func activateGrant(for url: URL) async throws -> URL { url }
    func removeGrant(for url: URL) async {}
    func stopAll() async {}
}

actor UIFixtureArchiveEngine: ArchiveServing {
    private let sessionID = UUID()
    private let itemsDelay: Duration

    init(itemsDelay: Duration = .zero) {
        self.itemsDelay = itemsDelay
    }

    func openArchive(
        at url: URL,
        password: String?,
        policy: ArchiveBrowsingPolicy
    ) async throws -> ArchiveOpenResult {
        return ArchiveOpenResult(
            address: ArchiveAddress(
                sessionID: sessionID,
                archiveID: UUID(),
                internalPath: "",
                maximumNestedArchiveDepth: policy.maximumNestedArchiveDepth
            ),
            displayName: url.lastPathComponent
        )
    }

    func items(at address: ArchiveAddress) async throws -> [BrowserItem] {
        if itemsDelay > .zero { try await Task.sleep(for: itemsDelay) }
        let childAddress = ArchiveAddress(
            sessionID: address.sessionID,
            archiveID: address.archiveID,
            internalPath: address.internalPath.isEmpty ? "Inside.txt" : "\(address.internalPath)/Inside.txt",
            allowsNestedArchives: address.allowsNestedArchives,
            nestedArchiveDepth: address.nestedArchiveDepth,
            maximumNestedArchiveDepth: address.maximumNestedArchiveDepth
        )
        return [BrowserItem(
            id: BrowserItemID(rawValue: "fixture-archive:Inside.txt"), name: "Inside.txt",
            location: .archive(childAddress), isContainer: false, isDirectory: false,
            isPackage: false, isSymbolicLink: false, isHidden: false, isArchive: false,
            size: 128, packedSize: 64, creationDate: nil, modificationDate: nil,
            accessDate: nil, tags: [], contentTypeIdentifier: "public.plain-text",
            encrypted: false, checksum: nil, compressionMethod: "Deflate"
        )]
    }

    func openNestedArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        guard case let .archive(address) = item.location,
              address.canOpenNestedArchive else {
            throw ArchiveEngineError.nestedArchiveNotAllowed
        }
        return ArchiveOpenResult(
            address: ArchiveAddress(
                sessionID: sessionID,
                archiveID: UUID(),
                internalPath: "",
                allowsNestedArchives: address.allowsNestedArchives,
                nestedArchiveDepth: address.nestedArchiveDepth + 1,
                maximumNestedArchiveDepth: address.maximumNestedArchiveDepth
            ),
            displayName: item.name
        )
    }

    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(item.name)
        try Data("Fixture preview".utf8).write(to: url)
        return url
    }

    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        progress(ArchiveProgress(phase: .compressing, fraction: 1))
    }

    func testArchive(at url: URL, password: String?) async throws {}

    func extractArchive(
        at url: URL,
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        progress(ArchiveProgress(phase: .extracting, fraction: 1))
    }

    func extractItems(
        _ items: [BrowserItem],
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        progress(ArchiveProgress(phase: .extracting, fraction: 1))
    }

    func recursiveSize(of item: BrowserItem) async throws -> Int64 { item.size ?? 0 }

    func archiveRootURL(for address: ArchiveAddress) async throws -> URL {
        URL(fileURLWithPath: "/ZforgeFixtures/Sample.zip")
    }

    func setPassword(_ password: String?, for sessionID: UUID) async {}
    func closeSession(_ sessionID: UUID) async {}
    func closeAllSessions() async {}
    func cancelAllOperations() async {}
    func cleanupStaleSessions() async {}
}
