import AppIntents
import CoreSpotlight

@available(macOS 27.0, *)
nonisolated protocol FileArchiveIndexWriting: Sendable {
    func reset() async throws
    func remove(_ identifiers: [FileEntityIdentifier]) async throws
    func upsert(_ entities: [ZforgeFileArchiveEntity]) async throws
}

/// Retain the successfully published bookmark identities, including after the
/// referenced file is deleted. Removal must not recreate an identifier from it.
@available(macOS 27.0, *)
actor ArchiveFilePublication {
    private let writer: any FileArchiveIndexWriting
    private var identifiers: [String: FileEntityIdentifier] = [:]
    init(writer: any FileArchiveIndexWriting) { self.writer = writer }

    func reset() async throws {
        try await writer.reset()
        identifiers = [:]
    }
    func remove(_ paths: [String]) async throws {
        let removed = paths.compactMap { identifiers[$0] }
        if !removed.isEmpty { try await writer.remove(removed) }
        for path in paths { identifiers.removeValue(forKey: path) }
    }
    func upsert(_ archives: [ZforgeArchiveEntity]) async throws {
        try Task.checkCancellation()
        guard archives.count <= 100, identifiers.count + archives.filter({ identifiers[$0.id] == nil }).count <= 10_000 else {
            throw AutomationError.listingTooLarge
        }
        let entities = try archives.map(ZforgeFileArchiveEntity.published)
        try Task.checkCancellation()
        let replaced = archives.compactMap { identifiers[$0.id] }
        if !replaced.isEmpty {
            try await writer.remove(replaced)
            // Successful removal invalidates the old context even if the next
            // donation fails. The coordinator clears any partial system writes.
            for archive in archives { identifiers.removeValue(forKey: archive.id) }
        }
        try Task.checkCancellation()
        try await writer.upsert(entities)
        try Task.checkCancellation()
        for entity in entities { identifiers[entity.archive.id] = entity.id }
    }
    func contextIdentifiers(for archives: [ZforgeArchiveEntity]) throws -> [String: EntityIdentifier] {
        var result: [String: EntityIdentifier] = [:]
        for archive in archives {
            try Task.checkCancellation()
            guard let identifier = identifiers[archive.id] else { throw AutomationError.notFound }
            result[archive.id] = EntityIdentifier(for: ZforgeFileArchiveEntity.self, identifier: identifier)
        }
        return result
    }
}

/// Availability-erased storage keeps the macOS 26 writer loadable.
nonisolated final class ArchiveFilePublicationHolder: @unchecked Sendable {
    private let storage: Any?
    init(index: CSSearchableIndex) {
        if #available(macOS 27.0, *) { storage = ArchiveFilePublication(writer: SpotlightFileArchiveIndex(index: index)) }
        else { storage = nil }
    }
    @available(macOS 27.0, *)
    var publication: ArchiveFilePublication { storage as! ArchiveFilePublication }
}

@available(macOS 27.0, *)
nonisolated private final class SpotlightFileArchiveIndex: FileArchiveIndexWriting, @unchecked Sendable {
    private let index: CSSearchableIndex
    init(index: CSSearchableIndex) { self.index = index }
    func reset() async throws { try await index.deleteAppEntities(ofType: ZforgeFileArchiveEntity.self) }
    func remove(_ identifiers: [FileEntityIdentifier]) async throws {
        try await index.deleteAppEntities(identifiedBy: identifiers, ofType: ZforgeFileArchiveEntity.self)
    }
    func upsert(_ entities: [ZforgeFileArchiveEntity]) async throws { try await index.indexAppEntities(entities) }
}
