import AppIntents
import CoreSpotlight
import Foundation
import OSLog
import UniformTypeIdentifiers

/// A path identifies app content; it never grants access to that content.
nonisolated struct ZforgeArchiveEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive" }
    static var defaultQuery: ZforgeArchiveQuery { ZforgeArchiveQuery() }
    let id: String
    let name: String
    let fileIdentity: Data?
    var presentationPaths: Set<String>
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .archive)
        attributes.title = name
        attributes.displayName = name
        return attributes
    }

    init(url: URL, presentationPath: String? = nil, fileIdentity: Data? = nil) {
        id = url.path
        name = url.lastPathComponent
        self.fileIdentity = fileIdentity
        presentationPaths = [url.path]
        if let presentationPath { presentationPaths.insert(presentationPath) }
    }
}

/// A separate target type is required by the metadata exporter: OpenIntent
/// targets must be unique even when their OS availability never overlaps.
nonisolated struct ZforgeLegacyArchiveEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive" }
    static var defaultQuery: ZforgeLegacyArchiveQuery { ZforgeLegacyArchiveQuery() }
    let archive: ZforgeArchiveEntity
    var id: String { archive.id }
    var displayRepresentation: DisplayRepresentation { archive.displayRepresentation }
    var attributeSet: CSSearchableItemAttributeSet { archive.attributeSet }
    init(_ archive: ZforgeArchiveEntity) { self.archive = archive }
}

nonisolated struct ZforgeLegacyArchiveQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ZforgeLegacyArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Legacy archive identifier query; count=\(identifiers.count).")
        return try await AutomationArchiveEntities.shared.entities(for: identifiers).map(ZforgeLegacyArchiveEntity.init)
    }
    func entities(matching string: String) async throws -> [ZforgeLegacyArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Legacy archive name query received.")
        return try await AutomationArchiveEntities.shared.matching(string).map(ZforgeLegacyArchiveEntity.init)
    }
    func suggestedEntities() async throws -> [ZforgeLegacyArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Legacy archive suggestions query returned; count=0.")
        return []
    }
}

nonisolated struct ZforgeArchiveQuery: EntityStringQuery {
    var service = AutomationArchiveEntities.shared
    func entities(for identifiers: [String]) async throws -> [ZforgeArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Archive identifier query; count=\(identifiers.count).")
        return try await service.entities(for: identifiers)
    }
    func entities(matching string: String) async throws -> [ZforgeArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Archive name query received.")
        return try await service.matching(string)
    }
    func suggestedEntities() async throws -> [ZforgeArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Archive suggestions query returned; count=0.")
        return []
    }
}

/// Bounded, noninteractive metadata discovery. Paths never create grants.
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
        return Array(try await scan(matching: string).prefix(100))
    }

    /// Unlike caller-supplied identifiers, every published entity is verified.
    func snapshot() async throws -> [ZforgeArchiveEntity] { try await scan(matching: nil) }

    @available(macOS 27.0, *)
    func fileMatches(_ string: String) async throws -> [ZforgeFileArchiveEntity] {
        let archives = try await matching(string)
        if string.hasPrefix("/") { return archives.map(ZforgeFileArchiveEntity.candidate) }
        var result: [ZforgeFileArchiveEntity] = []
        for archive in archives {
            try Task.checkCancellation()
            let lease: AutomationAccessLease
            do { lease = try await access.authorize([AutomationPath.url(archive.id)]) }
            catch AutomationError.authorizationRequired { continue }
            defer { withExtendedLifetime(lease) {} }
            do { result.append(try ZforgeFileArchiveEntity.published(archive)) }
            catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile { continue }
        }
        try Task.checkCancellation()
        return result
    }

    private func scan(matching string: String?) async throws -> [ZforgeArchiveEntity] {
        try Task.checkCancellation()
        guard !reading else { throw AutomationError.busy }
        reading = true
        defer { reading = false }
        var matches: [ZforgeArchiveEntity] = []
        var seen: Set<String> = []
        var positions: [String: Int] = [:]
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
            // Foundation does not reliably enumerate a symlink used as the
            // root. The live scope authorizes its resolved physical directory;
            // retain the presented path separately for query/UI association.
            let physicalFolder = AutomationPath.resolvedForAccess(folder)
            guard let enumerator = FileManager.default.enumerator(at: physicalFolder, includingPropertiesForKeys: nil,
                options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, error in enumerationError = error; return false }) else { throw AutomationError.notFound }
            while let url = enumerator.nextObject() as? URL {
                try Task.checkCancellation()
                guard inspected < 10_000 else { throw AutomationError.listingTooLarge }
                inspected += 1
                let name = url.lastPathComponent
                if let string, !name.localizedStandardContains(string) { continue }
                guard ArchiveFormatRegistry.recognizes(name) else { continue }
                // Construct operational URLs only for archive candidates. URL
                // construction may infer directory metadata for ordinary files.
                let presented = folder.appendingPathComponent(name)
                guard let value = try await entity(at: presented, excludeFileLinks: string == nil) else { continue }
                if string == nil {
                    if let position = positions[value.identity] {
                        matches[position].presentationPaths.insert(value.entity.id)
                    } else {
                        positions[value.identity] = matches.count
                        matches.append(ZforgeArchiveEntity(url: URL(fileURLWithPath: value.identity), presentationPath: value.entity.id, fileIdentity: value.entity.fileIdentity))
                    }
                } else if seen.insert(value.identity).inserted { matches.append(value.entity) }
            }
            if let enumerationError { throw enumerationError }
        }
        try Task.checkCancellation()
        return matches.sorted { $0.id < $1.id }
    }

    private func entity(at url: URL, allowUnverified: Bool = false, excludeFileLinks: Bool = false) async throws -> (entity: ZforgeArchiveEntity, identity: String)? {
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
            if excludeFileLinks {
                let link = try url.resourceValues(forKeys: [.isSymbolicLinkKey, .isAliasFileKey])
                guard link.isSymbolicLink != true, link.isAliasFile != true else { return nil }
            }
            let physical = AutomationPath.resolvedForAccess(url)
            let metadata = try physical.resourceValues(forKeys: [.isRegularFileKey, .fileResourceIdentifierKey])
            guard metadata.isRegularFile == true else { return nil }
            return (ZforgeArchiveEntity(url: url, fileIdentity: metadata.fileResourceIdentifier as? Data), physical.path)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return nil
        }
    }
}

@available(macOS 27.0, *)
extension ZforgeArchiveQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [String], indexDescription: CSSearchableIndexDescription) async throws {
        try await ArchiveIndexRuntime.shared.reindex()
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await ArchiveIndexRuntime.shared.reindex()
    }
}
