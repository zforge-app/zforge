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
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "Test Archive.zip") }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .archive)
        attributes.title = "Test Archive.zip"
        attributes.displayName = "Test Archive.zip"
        attributes.contentURL = fixtureURL
        return attributes
    }
    init(url: URL) throws {
        self.init(id: try .file(url: url), url: url)
    }
    init(id: FileEntityIdentifier, url: URL) {
        self.id = id
        fixtureURL = url
    }
    static func fixture() throws -> ProbeEntity {
        guard let url = Bundle.main.url(forResource: "Test Archive", withExtension: "zip") else {
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
                // Preserve the requested identity as well as the resolved file.
                // A fresh bookmark identifier cannot replace a transported one.
                return [ProbeEntity(id: identifier, url: entity.fixtureURL)]
            }
        }
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe identifier query returned; count=0.")
        return []
    }
    func entities(matching string: String) async throws -> [ProbeEntity] {
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe name query received.")
        return "Test Archive.zip".localizedStandardContains(string) ? [try ProbeEntity.fixture()] : []
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
    #if PROBE_COMPATIBILITY_SCHEMA
    var compatibilityOpened = false
    #endif
    var entity: ProbeEntity?
    var indexStatus = "Publishing the synthetic entity…"
}

@main struct IntentProbeApp: App {
    @State private var selectedFixture: String? = "synthetic"
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                if let entity = ProbeState.shared.entity {
                    if CommandLine.arguments.contains("--probe-selected-context") {
                        List(selection: $selectedFixture) {
                            Text("Test Archive.zip").tag("synthetic")
                        }
                        .appEntityIdentifier(forSelectionType: String.self) { _ in EntityIdentifier(for: entity) }
                        .accessibilityIdentifier("probe.selectedFixture")
                        .frame(height: 80)
                    } else { Text("Test Archive.zip").font(.title)
                        .appEntityIdentifier(EntityIdentifier(for: entity))
                    }
                }
                #if PROBE_COMPATIBILITY_SCHEMA
                Text(ProbeState.shared.compatibilityOpened ? "The compatibility OpenIntent ran."
                     : (ProbeState.shared.opened ? "The OpenIntent ran." : "No OpenIntent has run."))
                    .accessibilityIdentifier("probe.openStatus")
                #else
                Text(ProbeState.shared.opened ? "The OpenIntent ran." : "No OpenIntent has run.")
                    .accessibilityIdentifier("probe.openStatus")
                #endif
                Text(ProbeState.shared.indexStatus).font(.caption)
                    .accessibilityIdentifier("probe.indexStatus")
            }
            .padding(32)
            .frame(minWidth: 420, minHeight: 180)
            .task {
                let isTestHost = CommandLine.arguments.contains("--probe-tests")
                    || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                    || NSClassFromString("XCTestCase") != nil
                #if DEBUG
                if isTestHost && !CommandLine.arguments.contains("--probe-system-tests") { return }
                #else
                if isTestHost { return }
                #endif
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
