import Foundation

@MainActor
final class UIFixtureRecentItemsService: RecentItemsServing {
    func recentItemURLs() async -> [URL] {
        ["Fixture Folder", "Welcome.txt", "Sample.zip"].map {
            URL(fileURLWithPath: "/ZforgeFixtures/\($0)")
        }
    }

    func stop() {}
}

actor UIFixtureFileSystemService: FileSystemServing {
    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        let items = [
            makeItem(name: "Fixture Folder", directory: true),
            makeItem(name: "Welcome.txt", size: 1_024),
            makeItem(name: "Sample.zip", archive: true, size: 4_096),
            makeItem(name: ".Hidden Fixture", size: 32, hidden: true)
        ]
        return showHidden ? items : items.filter { !$0.isHidden }
    }

    func item(at url: URL) async throws -> BrowserItem {
        makeItem(name: url.lastPathComponent, archive: ArchiveFormatRegistry.recognizes(url.lastPathComponent))
    }

    func recursiveSize(at url: URL) async throws -> Int64 { 0 }

    func resolveNavigationURL(_ url: URL) async throws -> URL { url }

    private func makeItem(
        name: String, directory: Bool = false, archive: Bool = false,
        size: Int64? = nil, hidden: Bool = false
    ) -> BrowserItem {
        let url = URL(fileURLWithPath: "/ZforgeFixtures/\(name)")
        return BrowserItem(
            id: BrowserItemID(rawValue: "fixture:\(name)"), name: name, location: .fileSystem(url),
            isContainer: directory, isDirectory: directory, isPackage: false,
            isSymbolicLink: false, isHidden: hidden, isArchive: archive, size: size,
            packedSize: nil, creationDate: nil, modificationDate: Date(timeIntervalSince1970: 1_700_000_000),
            accessDate: nil, tags: [], contentTypeIdentifier: nil, encrypted: false,
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
        format: ArchiveCompressionFormat,
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
