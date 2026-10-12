import AppIntents
import CoreSpotlight
import OSLog
import SwiftUI
import UniformTypeIdentifiers

nonisolated struct ProbeEntity: IndexedEntity {
    let id = "lyra-control"
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive" }
    static var defaultQuery: ProbeQuery { ProbeQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "Lyra Control.zip") }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .archive)
        attributes.title = "Lyra Control.zip"
        attributes.displayName = "Lyra Control.zip"
        return attributes
    }
}

nonisolated struct ProbeQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ProbeEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe identifier query received.")
        return identifiers.contains("lyra-control") ? [ProbeEntity()] : []
    }
    func entities(matching string: String) async throws -> [ProbeEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe name query received.")
        return "Lyra Control.zip".localizedStandardContains(string) ? [ProbeEntity()] : []
    }
    func suggestedEntities() async throws -> [ProbeEntity] { [ProbeEntity()] }
}

@AppIntent(schema: .system.open)
struct OpenProbeContentIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Archive" }
    static var supportedModes: IntentModes { .foreground }
    @Parameter(title: "Archive") var target: ProbeEntity
    @MainActor func perform() async throws -> some IntentResult {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe open action invoked.")
        ProbeState.shared.opened = true
        return .result()
    }
}

@MainActor @Observable final class ProbeState {
    static let shared = ProbeState()
    var opened = false
    var indexStatus = "Publishing the synthetic entity…"
}

@main struct IntentProbeApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Text("Lyra Control.zip").font(.title)
                    .appEntityIdentifier(EntityIdentifier(for: ProbeEntity()))
                Text(ProbeState.shared.opened ? "The OpenIntent ran." : "No OpenIntent has run.")
                Text(ProbeState.shared.indexStatus).font(.caption)
            }
            .padding(32)
            .frame(minWidth: 420, minHeight: 180)
            .task {
                do {
                    let index = CSSearchableIndex(name: "ZforgeIntentProbe")
                    try await index.deleteAppEntities(ofType: ProbeEntity.self)
                    try await index.indexAppEntities([ProbeEntity()])
                    ProbeState.shared.indexStatus = "The synthetic entity is indexed."
                    Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe entity indexed.")
                } catch {
                    ProbeState.shared.indexStatus = "Indexing failed."
                }
            }
        }
    }
}
