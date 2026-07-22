import Foundation

nonisolated enum BrowserFileTransferOperation: Equatable, Sendable {
    case automatic
    case copy
    case move
    case alias
}

nonisolated struct BrowserExactFileMove: Equatable, Sendable {
    let sourceURL: URL
    let destinationURL: URL
}

nonisolated protocol FileOperationServing: Sendable {
    func createFolder(in directory: URL) async throws -> URL
    func rename(_ sourceURL: URL, to newName: String) async throws -> URL
    func createAliases(for sourceURLs: [URL], in directory: URL) async throws -> [URL]
    func transfer(
        _ sourceURLs: [URL],
        to directory: URL,
        operation: BrowserFileTransferOperation
    ) async throws -> [URL]
    func aliasTarget(for url: URL) async throws -> URL?
    func removeItems(at urls: [URL]) async throws
    func moveItems(_ moves: [BrowserExactFileMove]) async throws
}

nonisolated enum BrowserFileOperationError: LocalizedError, Equatable, Sendable {
    case invalidName
    case undoDestinationExists(String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            String(localized: "Enter a valid file name without slashes or colons.")
        case let .undoDestinationExists(name):
            String(localized: "Cannot undo because an item named \(name) already exists.")
        }
    }
}

actor FileOperationService: FileOperationServing {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createFolder(in directory: URL) async throws -> URL {
        let destination = uniqueDestination(
            in: directory,
            baseName: String(localized: "Untitled Folder"),
            pathExtension: nil
        )
        try fileManager.createDirectory(
            at: destination,
            withIntermediateDirectories: false
        )
        return destination
    }

    func rename(_ sourceURL: URL, to newName: String) async throws -> URL {
        guard !newName.isEmpty,
              !newName.allSatisfy(\.isWhitespace),
              newName != ".",
              newName != "..",
              !newName.contains("/"),
              !newName.contains(":"),
              !newName.contains("\0") else {
            throw BrowserFileOperationError.invalidName
        }

        let source = sourceURL.standardizedFileURL
        let destination = source
            .deletingLastPathComponent()
            .appendingPathComponent(newName)
            .standardizedFileURL
        guard destination != source else { return source }
        try fileManager.moveItem(at: source, to: destination)
        return destination
    }

    func createAliases(for sourceURLs: [URL], in directory: URL) async throws -> [URL] {
        var created: [URL] = []
        for sourceURL in sourceURLs {
            let destination = uniqueDestination(
                in: directory,
                baseName: sourceURL.lastPathComponent + " " + String(localized: "alias"),
                pathExtension: nil
            )
            let bookmark = try sourceURL.bookmarkData(
                options: [.suitableForBookmarkFile],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            try URL.writeBookmarkData(bookmark, to: destination)
            created.append(destination)
        }
        return created
    }

    func transfer(
        _ sourceURLs: [URL],
        to directory: URL,
        operation: BrowserFileTransferOperation
    ) async throws -> [URL] {
        if operation == .alias {
            return try await createAliases(for: sourceURLs, in: directory)
        }

        var destinations: [URL] = []
        for sourceURL in sourceURLs {
            let source = sourceURL.standardizedFileURL
            let sourceParent = source.deletingLastPathComponent().standardizedFileURL
            let effectiveOperation = resolvedOperation(operation, source: source, destination: directory)

            if effectiveOperation == .move && sourceParent == directory.standardizedFileURL {
                destinations.append(source)
                continue
            }

            let destination: URL
            if effectiveOperation == .copy && sourceParent == directory.standardizedFileURL {
                let extensionName = source.pathExtension
                let stem = extensionName.isEmpty
                    ? source.lastPathComponent
                    : source.deletingPathExtension().lastPathComponent
                destination = uniqueDestination(
                    in: directory,
                    baseName: stem + " " + String(localized: "copy"),
                    pathExtension: extensionName.isEmpty ? nil : extensionName
                )
            } else {
                destination = uniqueDestination(
                    in: directory,
                    baseName: source.lastPathComponent,
                    pathExtension: nil
                )
            }

            switch effectiveOperation {
            case .copy:
                try fileManager.copyItem(at: source, to: destination)
            case .move:
                try fileManager.moveItem(at: source, to: destination)
            case .automatic, .alias:
                assertionFailure("The transfer operation must be resolved before execution.")
            }
            destinations.append(destination)
        }
        return destinations
    }

    func aliasTarget(for url: URL) async throws -> URL? {
        let values = try url.resourceValues(forKeys: [.isAliasFileKey])
        guard values.isAliasFile == true else { return nil }
        return try URL(
            resolvingAliasFileAt: url,
            options: [.withoutUI, .withoutMounting]
        ).standardizedFileURL.resolvingSymlinksInPath()
    }

    func removeItems(at urls: [URL]) async throws {
        for url in urls.reversed() where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func moveItems(_ moves: [BrowserExactFileMove]) async throws {
        for move in moves {
            let source = move.sourceURL.standardizedFileURL
            let destination = move.destinationURL.standardizedFileURL
            guard fileManager.fileExists(atPath: source.path) else { continue }
            guard !fileManager.fileExists(atPath: destination.path) else {
                throw BrowserFileOperationError.undoDestinationExists(
                    destination.lastPathComponent
                )
            }
            try fileManager.moveItem(at: source, to: destination)
        }
    }

    private func resolvedOperation(
        _ operation: BrowserFileTransferOperation,
        source: URL,
        destination: URL
    ) -> BrowserFileTransferOperation {
        guard operation == .automatic else { return operation }
        let sourceVolume = try? source.resourceValues(forKeys: [.volumeURLKey]).volume
        let destinationVolume = try? destination.resourceValues(forKeys: [.volumeURLKey]).volume
        return sourceVolume?.standardizedFileURL == destinationVolume?.standardizedFileURL
            ? .move
            : .copy
    }

    private func uniqueDestination(
        in directory: URL,
        baseName: String,
        pathExtension: String?
    ) -> URL {
        func candidate(_ suffix: String?) -> URL {
            let name = suffix.map { baseName + " " + $0 } ?? baseName
            let url = directory.appendingPathComponent(name)
            guard let pathExtension, !pathExtension.isEmpty else { return url }
            return url.appendingPathExtension(pathExtension)
        }

        var destination = candidate(nil)
        var index = 2
        while fileManager.fileExists(atPath: destination.path) {
            destination = candidate(String(index))
            index += 1
        }
        return destination
    }
}
