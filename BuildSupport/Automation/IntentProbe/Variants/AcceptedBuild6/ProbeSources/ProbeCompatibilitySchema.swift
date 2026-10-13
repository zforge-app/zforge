#if PROBE_COMPATIBILITY_SCHEMA
import AppIntents
import CoreSpotlight
import Foundation
import OSLog

/// Opt-in control for the extra hidden String-target schema in Zforge.
/// It refers only to the existing fixture; it is never donated to Spotlight.
nonisolated struct ProbeCompatibilityEntity: IndexedEntity {
    let id: String
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive" }
    static var defaultQuery: ProbeCompatibilityQuery { ProbeCompatibilityQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "Test Archive.zip") }
    var attributeSet: CSSearchableItemAttributeSet { CSSearchableItemAttributeSet(contentType: .archive) }
}

nonisolated struct ProbeCompatibilityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ProbeCompatibilityEntity] {
        let logger = Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing")
        logger.notice("Probe compatibility identifier query received.")
        let fixture = try ProbeEntity.fixture()
        let result = identifiers.contains(fixture.fixtureURL.path) ? [ProbeCompatibilityEntity(id: fixture.fixtureURL.path)] : []
        logger.notice("Probe compatibility identifier query returned; count=\(result.count).")
        return result
    }
    func entities(matching string: String) async throws -> [ProbeCompatibilityEntity] {
        let logger = Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing")
        logger.notice("Probe compatibility name query received.")
        let result = "Test Archive.zip".localizedStandardContains(string)
            ? [ProbeCompatibilityEntity(id: try ProbeEntity.fixture().fixtureURL.path)] : []
        logger.notice("Probe compatibility name query returned; count=\(result.count).")
        return result
    }
    func suggestedEntities() async throws -> [ProbeCompatibilityEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe compatibility suggestions query returned; count=0.")
        return []
    }
}

@available(macOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenProbeCompatibilityContentIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Archive" }
    static var supportedModes: IntentModes { .foreground }
    static var isDiscoverable: Bool { false }
    @Parameter(title: "Archive") var target: ProbeCompatibilityEntity
    @MainActor func perform() async throws -> some IntentResult {
        guard target.id == (try ProbeEntity.fixture().fixtureURL.path) else { throw CocoaError(.fileNoSuchFile) }
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe compatibility open action invoked.")
        ProbeState.shared.compatibilityOpened = true
        return .result()
    }
}
#endif
