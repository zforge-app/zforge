import Foundation

/// Files under this directory are working copies owned by Zforge, not user files.
nonisolated enum ZforgeTemporaryStorage {
    static func root(fileManager: FileManager = .default) -> URL {
        fileManager.temporaryDirectory.appendingPathComponent("Zforge", isDirectory: true)
    }

    static func archiveSessionsRoot(fileManager: FileManager = .default) -> URL {
        root(fileManager: fileManager).appendingPathComponent("ArchiveSessions", isDirectory: true)
    }

    static func contains(_ url: URL, fileManager: FileManager = .default) -> Bool {
        let rootPath = root(fileManager: fileManager)
            .resolvingSymlinksInPath().standardizedFileURL.path
        let candidatePath = url.resolvingSymlinksInPath().standardizedFileURL.path
        return candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/")
    }
}
