import Foundation
import UniformTypeIdentifiers

nonisolated protocol FileSystemServing: Sendable {
    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem]
    func item(at url: URL) async throws -> BrowserItem
    func resolveNavigationURL(_ url: URL) async throws -> URL
}

actor FileSystemService: FileSystemServing {
    private let fileManager: FileManager

    private nonisolated static let keys: Set<URLResourceKey> = [
        .nameKey,
        .isDirectoryKey,
        .isPackageKey,
        .isSymbolicLinkKey,
        .isHiddenKey,
        .fileSizeKey,
        .creationDateKey,
        .contentModificationDateKey,
        .contentAccessDateKey,
        .tagNamesKey,
        .contentTypeKey,
        .fileResourceIdentifierKey
    ]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Array(Self.keys),
                options: options
            )
            return try urls.map { try makeItem(at: $0) }
        } catch CocoaError.fileReadNoPermission {
            throw BrowserError.permissionDenied(directory)
        } catch {
            throw BrowserError.unavailable(error.localizedDescription)
        }
    }

    func item(at url: URL) async throws -> BrowserItem {
        try makeItem(at: url)
    }

    func resolveNavigationURL(_ url: URL) async throws -> URL {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey, .isAliasFileKey])
        if values.isSymbolicLink == true {
            return url.resolvingSymlinksInPath()
        }
        if values.isAliasFile == true {
            return try URL(resolvingAliasFileAt: url, options: [.withoutUI, .withoutMounting])
        }
        return url
    }

    private func makeItem(at url: URL) throws -> BrowserItem {
        let values = try url.resourceValues(forKeys: Self.keys)
        let isDirectory = values.isDirectory ?? false
        let isPackage = values.isPackage ?? false
        let name = values.name ?? url.lastPathComponent
        return BrowserItem(
            id: BrowserItemID(rawValue: "file:\(url.standardizedFileURL.path)"),
            name: name,
            location: .fileSystem(url),
            isContainer: isDirectory && !isPackage,
            isDirectory: isDirectory,
            isPackage: isPackage,
            isSymbolicLink: values.isSymbolicLink ?? false,
            isHidden: values.isHidden ?? name.hasPrefix("."),
            isArchive: !isDirectory && ArchiveFormatRegistry.recognizes(name),
            size: values.fileSize.map(Int64.init),
            packedSize: nil,
            creationDate: values.creationDate,
            modificationDate: values.contentModificationDate,
            accessDate: values.contentAccessDate,
            tags: values.tagNames ?? [],
            contentTypeIdentifier: values.contentType?.identifier,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
    }
}
