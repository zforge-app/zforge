import Foundation
import CoreServices
import UniformTypeIdentifiers

nonisolated protocol FileSystemServing: Sendable {
    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem]
    func items(in directory: URL, showHidden: Bool, includeExtendedMetadata: Bool) async throws -> [BrowserItem]
    func item(at url: URL) async throws -> BrowserItem
    func item(at url: URL, includeExtendedMetadata: Bool) async throws -> BrowserItem
    func recursiveSize(at url: URL) async throws -> Int64
    func resolveNavigationURL(_ url: URL) async throws -> URL
}

extension FileSystemServing {
    func items(in directory: URL, showHidden: Bool, includeExtendedMetadata: Bool) async throws -> [BrowserItem] {
        try await items(in: directory, showHidden: showHidden)
    }

    func item(at url: URL, includeExtendedMetadata: Bool) async throws -> BrowserItem {
        try await item(at: url)
    }
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
        try await items(in: directory, showHidden: showHidden, includeExtendedMetadata: true)
    }

    func items(in directory: URL, showHidden: Bool, includeExtendedMetadata: Bool) async throws -> [BrowserItem] {
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Array(Self.keys),
                options: options
            )
            return try urls.map { try makeItem(at: $0, includeExtendedMetadata: includeExtendedMetadata) }
        } catch CocoaError.fileReadNoPermission {
            throw BrowserError.permissionDenied(directory)
        } catch {
            throw BrowserError.unavailable(error.localizedDescription)
        }
    }

    func item(at url: URL) async throws -> BrowserItem {
        try await item(at: url, includeExtendedMetadata: true)
    }

    func item(at url: URL, includeExtendedMetadata: Bool) async throws -> BrowserItem {
        // Search results and expanded hierarchies can retain URL resource
        // caches after Finder changes tags on the same physical file.
        var refreshedURL = url
        refreshedURL.removeAllCachedResourceValues()
        return try makeItem(at: refreshedURL, includeExtendedMetadata: includeExtendedMetadata)
    }

    func recursiveSize(at url: URL) async throws -> Int64 {
        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            guard values.isDirectory == true else {
                return Int64(values.fileSize ?? 0)
            }

            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: []
            ) else {
                throw BrowserError.unavailable(
                    AppLocalization.string("The folder size could not be calculated.")
                )
            }

            var total: Int64 = 0
            while let childURL = enumerator.nextObject() as? URL {
                try Task.checkCancellation()
                let childValues = try childURL.resourceValues(
                    forKeys: [.isRegularFileKey, .fileSizeKey]
                )
                if childValues.isRegularFile == true {
                    total += Int64(childValues.fileSize ?? 0)
                }
            }
            return total
        } catch is CancellationError {
            throw CancellationError()
        } catch CocoaError.fileReadNoPermission {
            throw BrowserError.permissionDenied(url)
        } catch let error as BrowserError {
            throw error
        } catch {
            throw BrowserError.unavailable(error.localizedDescription)
        }
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

    private func makeItem(at url: URL, includeExtendedMetadata: Bool) throws -> BrowserItem {
        let values = try url.resourceValues(forKeys: Self.keys)
        let isDirectory = values.isDirectory ?? false
        let isPackage = values.isPackage ?? false
        let name = values.name ?? url.lastPathComponent
        var item = BrowserItem(
            id: BrowserItemID(rawValue: "file:\(url.standardizedFileURL.path)"),
            name: name,
            location: .fileSystem(url),
            isContainer: isDirectory && !isPackage,
            isDirectory: isDirectory,
            isPackage: isPackage,
            isSymbolicLink: values.isSymbolicLink ?? false,
            isHidden: values.isHidden == true || name.hasPrefix("."),
            isArchive: !isDirectory && ArchiveFormatRegistry.recognizes(name),
            size: values.fileSize.map(Int64.init),
            packedSize: nil,
            creationDate: values.creationDate,
            modificationDate: values.contentModificationDate,
            accessDate: values.contentAccessDate,
            tags: values.tagNames ?? [],
            tagColorIndexes: values.tagNames?.isEmpty == false
                ? FinderTagMetadata.colorIndexes(at: url) : [:],
            contentTypeIdentifier: values.contentType?.identifier,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
        if includeExtendedMetadata,
           let metadataItem = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) {
            item.extendedMetadata = BrowserExtendedMetadata(
                lastOpenedDate: MDItemCopyAttribute(metadataItem, kMDItemLastUsedDate) as? Date,
                dateAdded: MDItemCopyAttribute(metadataItem, kMDItemDateAdded) as? Date,
                version: MDItemCopyAttribute(metadataItem, kMDItemVersion) as? String,
                comments: MDItemCopyAttribute(metadataItem, kMDItemFinderComment) as? String
            )
        }
        return item
    }
}
