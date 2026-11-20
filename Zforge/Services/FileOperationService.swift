import Foundation
import Darwin

nonisolated enum BrowserFileTransferOperation: Equatable, Sendable {
    case automatic
    case copy
    case move
    case alias
}

/// Drop destinations Zforge refuses without an error, as Finder does (ZF-89): an item dropped on
/// itself, a folder copied or moved into one of its own folders, and a move into the folder an item
/// is already in (a no-op; a copy there duplicates it, as in Finder). An alias may go anywhere but
/// onto the item itself.
nonisolated enum BrowserDropDestinationPolicy {
    static func refuses(_ destination: URL, for sources: [URL], operation: BrowserFileTransferOperation) -> Bool {
        let target = components(destination)
        return sources.contains { source in
            let item = components(source)
            if target == item { return true }
            if operation == .alias { return false }
            if target.count > item.count, Array(target.prefix(item.count)) == item { return true }
            let moves = operation == .move || operation == .automatic
            return moves && Array(item.dropLast()) == target
        }
    }

    private static func components(_ url: URL) -> [String] {
        url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
    }
}

nonisolated struct BrowserExactFileMove: Equatable, Sendable {
    let sourceURL: URL
    let destinationURL: URL
}

nonisolated struct BrowserSelectionFolder: Equatable, Sendable {
    let folderURL: URL
    let moves: [BrowserExactFileMove]
}

nonisolated protocol FileOperationServing: Sendable {
    func createFolder(in directory: URL, locale: Locale?) async throws -> URL
    func createFolder(containing sourceURLs: [URL], in directory: URL, locale: Locale?) async throws -> BrowserSelectionFolder
    func setSelectionFolder(_ folder: BrowserSelectionFolder, grouped: Bool) async throws
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
    case invalidFolderSelection
    case selectionFolderDestinationExists(String)
    case selectionFolderContentsChanged(String)
    case selectionFolderRecoveryFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            AppLocalization.string("Enter a valid file name without slashes or colons.")
        case let .undoDestinationExists(name):
            AppLocalization.string("Cannot undo because an item named \(name) already exists.")
        case .invalidFolderSelection:
            AppLocalization.string("Select items from the same folder to create a folder with selection.")
        case let .selectionFolderDestinationExists(name):
            String(format: AppLocalization.string("Cannot complete this operation because an item named %@ already exists."), name)
        case let .selectionFolderContentsChanged(name):
            String(format: AppLocalization.string("Cannot undo because the contents of %@ have changed."), name)
        case let .selectionFolderRecoveryFailed(original, recovery):
            String(format: AppLocalization.string("The operation failed: %@ Some items could not be restored: %@"), original, recovery)
        }
    }
}

actor FileOperationService: FileOperationServing {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createFolder(in directory: URL, locale: Locale? = nil) async throws -> URL {
        let destination = uniqueDestination(
            in: directory,
            baseName: AppLocalization.string("untitled folder", locale: locale),
            pathExtension: nil
        )
        try fileManager.createDirectory(
            at: destination,
            withIntermediateDirectories: false
        )
        return destination
    }

    func createFolder(
        containing sourceURLs: [URL],
        in directory: URL,
        locale: Locale? = nil
    ) async throws -> BrowserSelectionFolder {
        let sources = sourceURLs.map(\.standardizedFileURL)
        let parent = directory.standardizedFileURL
        guard !sources.isEmpty,
              Set(sources.map(\.path)).count == sources.count,
              sources.allSatisfy({
                  $0.deletingLastPathComponent().resolvingSymlinksInPath().path
                      == parent.resolvingSymlinksInPath().path
              }) else {
            throw BrowserFileOperationError.invalidFolderSelection
        }
        // Validate the complete selection before any mutation, including dangling
        // symlinks (which fileExists alone treats as missing).
        for source in sources { _ = try fileManager.attributesOfItem(atPath: source.path) }
        let folderURL = uniqueDestination(in: parent,
            baseName: AppLocalization.string("untitled folder", locale: locale), pathExtension: nil)
        let folder = BrowserSelectionFolder(folderURL: folderURL, moves: sources.map {
            BrowserExactFileMove(sourceURL: $0, destinationURL: folderURL.appendingPathComponent($0.lastPathComponent))
        })
        try await setSelectionFolder(folder, grouped: true)
        return folder
    }

    func setSelectionFolder(_ folder: BrowserSelectionFolder, grouped: Bool) async throws {
        let moves = grouped ? folder.moves : folder.moves.map {
            BrowserExactFileMove(sourceURL: $0.destinationURL, destinationURL: $0.sourceURL)
        }
        guard !moves.isEmpty else { throw BrowserFileOperationError.invalidFolderSelection }
        if grouped {
            guard !itemExists(at: folder.folderURL) else {
                throw BrowserFileOperationError.selectionFolderDestinationExists(folder.folderURL.lastPathComponent)
            }
        } else {
            let contents = try fileManager.contentsOfDirectory(at: folder.folderURL, includingPropertiesForKeys: nil)
            guard Set(contents.map(\.lastPathComponent)) == Set(folder.moves.map { $0.destinationURL.lastPathComponent }) else {
                throw BrowserFileOperationError.selectionFolderContentsChanged(folder.folderURL.lastPathComponent)
            }
        }
        for move in moves {
            _ = try fileManager.attributesOfItem(atPath: move.sourceURL.path)
            guard !itemExists(at: move.destinationURL) else {
                throw BrowserFileOperationError.selectionFolderDestinationExists(move.destinationURL.lastPathComponent)
            }
        }
        if grouped { try fileManager.createDirectory(at: folder.folderURL, withIntermediateDirectories: false) }
        var completed: [BrowserExactFileMove] = []
        do {
            for move in moves {
                try Task.checkCancellation()
                try fileManager.moveItem(at: move.sourceURL, to: move.destinationURL)
                completed.append(move)
            }
            if !grouped { try removeEmptyDirectory(at: folder.folderURL) }
        } catch {
            let operationError = error
            var recoveryFailures: [String] = []
            for move in completed.reversed() {
                do { try fileManager.moveItem(at: move.destinationURL, to: move.sourceURL) }
                catch { recoveryFailures.append("\(move.sourceURL.lastPathComponent): \(error.localizedDescription)") }
            }
            if grouped, recoveryFailures.isEmpty {
                do { try removeEmptyDirectory(at: folder.folderURL) }
                catch { recoveryFailures.append(error.localizedDescription) }
            }
            guard recoveryFailures.isEmpty else {
                // Never recursively remove a recovery folder: it may hold the
                // user's only remaining copy of an item that failed to restore.
                throw BrowserFileOperationError.selectionFolderRecoveryFailed(
                    operationError.localizedDescription, recoveryFailures.joined(separator: "\n"))
            }
            throw operationError
        }
    }

    private func itemExists(at url: URL) -> Bool {
        (try? fileManager.attributesOfItem(atPath: url.path)) != nil
    }

    private func removeEmptyDirectory(at url: URL) throws {
        let result = url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return Int32(-1) }
            return Darwin.rmdir(path)
        }
        guard result == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
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
                baseName: sourceURL.lastPathComponent + " " + AppLocalization.string("alias"),
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
            let sameParent = sourceParent.resolvingSymlinksInPath().path
                == directory.standardizedFileURL.resolvingSymlinksInPath().path
            if sameParent && (operation == .automatic || operation == .move) {
                destinations.append(source)
                continue
            }
            let effectiveOperation = resolvedOperation(operation, source: source, destination: directory)

            if effectiveOperation == .move && sameParent {
                destinations.append(source)
                continue
            }

            let destination: URL
            if effectiveOperation == .copy && sameParent {
                let extensionName = source.pathExtension
                let stem = extensionName.isEmpty
                    ? source.lastPathComponent
                    : source.deletingPathExtension().lastPathComponent
                destination = uniqueDestination(
                    in: directory,
                    baseName: stem + " " + AppLocalization.string("copy"),
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
