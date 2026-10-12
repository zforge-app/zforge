import AppIntents
import CoreSpotlight
import Foundation
import OSLog
import UniformTypeIdentifiers

/// Apple's file representation adapts the existing authorized archive model.
/// A transported file identifier is a reference, never an automation grant.
@available(macOS 27.0, *)
@AppEntity(schema: .files.file)
nonisolated struct ZforgeFileArchiveEntity: IndexedEntity, FileEntity {
    let id: FileEntityIdentifier
    let archive: ZforgeArchiveEntity
    static var defaultQuery: ZforgeFileArchiveQuery { ZforgeFileArchiveQuery() }
    // Metadata export requires compile-time constants. Archive subclasses are
    // selectable, while the shared filename registry still validates execution.
    static var supportedContentTypes: [UTType] { [.archive, .zip, .gzip, .bz2] }
    var creationDate: Date? { nil }
    var fileModificationDate: Date? { nil }
    var displayRepresentation: DisplayRepresentation { archive.displayRepresentation }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = archive.attributeSet
        // Drafts contain caller-supplied text only, with no verified file URL.
        if !id.isDraft { attributes.contentURL = URL(fileURLWithPath: archive.id) }
        return attributes
    }

    init(archive: ZforgeArchiveEntity, id: FileEntityIdentifier) {
        self.archive = archive
        self.id = id
    }

    /// Call only under a live authorized scope. Freeze the wire representation
    /// once so Spotlight and onscreen context share the published identity.
    static func published(_ archive: ZforgeArchiveEntity) throws -> Self {
        let identifier = try FileEntityIdentifier.file(url: AutomationPath.url(archive.id))
        guard let transported = FileEntityIdentifier.entityIdentifier(for: identifier.entityIdentifierString) else {
            throw AutomationError.invalidArguments
        }
        return Self(archive: archive, id: transported)
    }

    static func candidate(_ archive: ZforgeArchiveEntity) -> Self {
        Self(archive: archive, id: .draft(identifier: archive.id))
    }

    static func url(for identifier: FileEntityIdentifier) async throws -> URL {
        if let path = identifier.draftIdentifier { return try AutomationPath.url(path) }
        guard let url = try await identifier.fileURL else { throw AutomationError.notFound }
        guard url.isFileURL else { throw AutomationError.invalidArguments }
        return try AutomationPath.url(url.path)
    }
}

@available(macOS 27.0, *)
nonisolated struct ZforgeFileArchiveQuery: EntityStringQuery {
    var service = AutomationArchiveEntities.shared

    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [ZforgeFileArchiveEntity] {
        try Task.checkCancellation()
        guard identifiers.count <= 256 else { throw AutomationError.invalidArguments }
        let logger = Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery")
        logger.notice("File archive identifier query; count=\(identifiers.count).")
        var paths: [String] = []
        var requested: [String: FileEntityIdentifier] = [:]
        for identifier in identifiers {
            try Task.checkCancellation()
            let url: URL
            do { url = try await ZforgeFileArchiveEntity.url(for: identifier) }
            catch AutomationError.notFound { continue }
            catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile { continue }
            if requested[url.path] == nil {
                requested[url.path] = identifier
                paths.append(url.path)
            }
        }
        let archives = try await service.entities(for: paths)
        try Task.checkCancellation()
        let result = try archives.map { archive in
            guard let identifier = requested[archive.id] else { throw AutomationError.invalidArguments }
            // Resolve physical aliases using the shared service, but retain the
            // exact incoming identity needed by system dispatch.
            return ZforgeFileArchiveEntity(archive: archive, id: identifier)
        }
        logger.notice("File archive identifier query returned; count=\(result.count).")
        return result
    }

    func entities(matching string: String) async throws -> [ZforgeFileArchiveEntity] {
        let logger = Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery")
        logger.notice("File archive name query received.")
        let result = try await service.fileMatches(string)
        logger.notice("File archive name query returned; count=\(result.count).")
        return result
    }
    func suggestedEntities() async throws -> [ZforgeFileArchiveEntity] {
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("File archive suggestions query returned; count=0.")
        return []
    }
}

@available(macOS 27.0, *)
extension ZforgeFileArchiveQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [FileEntityIdentifier], indexDescription: CSSearchableIndexDescription) async throws {
        try await ArchiveIndexRuntime.shared.reindex()
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await ArchiveIndexRuntime.shared.reindex()
    }
}
