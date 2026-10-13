import AppIntents
import CoreSpotlight
import OSLog
import SwiftUI
import UniformTypeIdentifiers

@AppEntity(schema: .files.file)
nonisolated struct ProbeEntity: IndexedEntity, FileEntity {
    let id: FileEntityIdentifier
    let fixtureURL: URL
    static var supportedContentTypes: [UTType] { [.zip] }
    var creationDate: Date? { nil }
    var fileModificationDate: Date? { nil }
    static var defaultQuery: ProbeQuery { ProbeQuery() }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "Lyra Control.zip") }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .archive)
        attributes.title = "Lyra Control.zip"
        attributes.displayName = "Lyra Control.zip"
        attributes.contentURL = fixtureURL
        return attributes
    }
    init(url: URL) throws {
        id = try .file(url: url)
        fixtureURL = url
    }
    static func fixture() throws -> ProbeEntity {
        guard let url = Bundle.main.url(forResource: "Lyra Control", withExtension: "zip") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try ProbeEntity(url: url)
    }
}

nonisolated struct ProbeQuery: EntityStringQuery {
    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [ProbeEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe identifier query received.")
        let entity = try ProbeEntity.fixture()
        // System string transport preserves the file URL without preserving
        // equality with a newly constructed bookmark-backed identifier.
        for identifier in identifiers {
            if let url = try await identifier.fileURL,
               url.standardizedFileURL == entity.fixtureURL.standardizedFileURL {
                Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe identifier query returned; count=1.")
                return [entity]
            }
        }
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe identifier query returned; count=0.")
        return []
    }
    func entities(matching string: String) async throws -> [ProbeEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe name query received.")
        return "Lyra Control.zip".localizedStandardContains(string) ? [try ProbeEntity.fixture()] : []
    }
    func suggestedEntities() async throws -> [ProbeEntity] { [try ProbeEntity.fixture()] }
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
    var entity: ProbeEntity?
    var indexStatus = "Publishing the synthetic entity…"
}

@main struct IntentProbeApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                if let entity = ProbeState.shared.entity {
                    Text("Lyra Control.zip").font(.title)
                        .appEntityIdentifier(EntityIdentifier(for: entity))
                }
                Text(ProbeState.shared.opened ? "The OpenIntent ran." : "No OpenIntent has run.")
                Text(ProbeState.shared.indexStatus).font(.caption)
            }
            .padding(32)
            .frame(minWidth: 420, minHeight: 180)
            .task {
                guard !CommandLine.arguments.contains("--probe-tests"),
                      ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
                      NSClassFromString("XCTestCase") == nil else { return }
                do {
                    let entity = try ProbeEntity.fixture()
                    ProbeState.shared.entity = entity
                    let index = CSSearchableIndex(name: "ZforgeIntentProbe")
                    try await index.deleteAppEntities(ofType: ProbeEntity.self)
                    try await index.indexAppEntities([entity])
                    ProbeState.shared.indexStatus = "The synthetic entity is indexed."
                    Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe entity indexed.")
                } catch {
                    ProbeState.shared.indexStatus = "Indexing failed."
                }
            }
        }
    }
}
