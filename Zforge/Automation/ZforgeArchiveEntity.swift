import AppIntents
import Foundation

/// A path identifies app content; it never grants access to that content.
nonisolated struct ZforgeArchiveEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive" }
    static var defaultQuery: ZforgeArchiveQuery { ZforgeArchiveQuery() }
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(url: URL) {
        id = url.path
        name = url.lastPathComponent
    }
}

nonisolated struct ZforgeArchiveQuery: EntityStringQuery {
    var service = AutomationArchiveEntities.shared
    func entities(for identifiers: [String]) async throws -> [ZforgeArchiveEntity] {
        try await service.entities(for: identifiers)
    }
    func entities(matching string: String) async throws -> [ZforgeArchiveEntity] {
        try await service.matching(string)
    }
    func suggestedEntities() async throws -> [ZforgeArchiveEntity] { [] }
}

/// Discovery is on demand and noninteractive. It does not create grants or a Spotlight index.
actor AutomationArchiveEntities {
    static let shared = AutomationArchiveEntities()
    private let access: any AutomationAuthorizing
    private var reading = false
    init(access: any AutomationAuthorizing = AutomationGrantStore.shared) { self.access = access }

    func entities(for identifiers: [String]) async throws -> [ZforgeArchiveEntity] {
        try Task.checkCancellation()
        guard identifiers.count <= 256 else { throw AutomationError.invalidArguments }
        var result: [ZforgeArchiveEntity] = []
        var seen: Set<String> = []
        for identifier in identifiers {
            try Task.checkCancellation()
            let url = try AutomationPath.url(identifier)
            if let candidate = try await entity(at: url, allowUnverified: true), seen.insert(candidate.identity).inserted {
                result.append(candidate.entity)
            }
        }
        try Task.checkCancellation()
        return result
    }

    func matching(_ string: String) async throws -> [ZforgeArchiveEntity] {
        try Task.checkCancellation()
        guard !string.isEmpty, string.utf8.count <= 4096, !string.contains("\0") else { throw AutomationError.invalidArguments }
        if string.hasPrefix("/") {
            // An explicit path supplies its own name. Returning that candidate
            // reveals no filesystem metadata and lets perform request consent.
            let url = try AutomationPath.url(string)
            return ArchiveFormatRegistry.recognizes(url.lastPathComponent) ? [ZforgeArchiveEntity(url: url)] : []
        }
        guard !reading else { throw AutomationError.busy }
        reading = true
        defer { reading = false }
        var matches: [ZforgeArchiveEntity] = []
        var seen: Set<String> = []
        var inspected = 0
        let folders = await access.authorizedFolders()
        try Task.checkCancellation()
        guard folders.count <= 128 else { throw AutomationError.invalidArguments }
        for path in folders.sorted() {
            try Task.checkCancellation()
            let folder = try AutomationPath.url(path)
            let lease: AutomationAccessLease
            do { lease = try await access.authorize([folder]) }
            catch AutomationError.authorizationRequired { continue }
            defer { withExtendedLifetime(lease) {} }
            var enumerationError: (any Error)?
            guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil,
                options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, error in enumerationError = error; return false }) else { throw AutomationError.notFound }
            while let url = enumerator.nextObject() as? URL {
                try Task.checkCancellation()
                guard inspected < 10_000 else { throw AutomationError.listingTooLarge }
                inspected += 1
                guard url.lastPathComponent.localizedStandardContains(string),
                      let value = try await entity(at: url),
                      seen.insert(value.identity).inserted else { continue }
                matches.append(value.entity)
            }
            if let enumerationError { throw enumerationError }
        }
        try Task.checkCancellation()
        return Array(matches.sorted { $0.id < $1.id }.prefix(100))
    }

    private func entity(at url: URL, allowUnverified: Bool = false) async throws -> (entity: ZforgeArchiveEntity, identity: String)? {
        guard ArchiveFormatRegistry.recognizes(url.lastPathComponent) else { return nil }
        let lease: AutomationAccessLease
        do { lease = try await access.authorize([url]) }
        catch AutomationError.authorizationRequired {
            // Native execution rehydrates a selected identifier before perform.
            // Preserve caller-supplied text so contextual consent can run there.
            // This branch must not inspect the target or imply it exists.
            return allowUnverified ? (ZforgeArchiveEntity(url: url), url.path) : nil
        }
        defer { withExtendedLifetime(lease) {} }
        try Task.checkCancellation()
        do {
            let physical = AutomationPath.resolvedForAccess(url)
            let metadata = try physical.resourceValues(forKeys: [.isRegularFileKey])
            guard metadata.isRegularFile == true else { return nil }
            return (ZforgeArchiveEntity(url: url), physical.path)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return nil
        }
    }
}
