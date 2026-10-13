#if PROBE_COMPATIBILITY_SCHEMA
import AppIntents
import Foundation
import Testing
@testable import Intent_Probe

@Suite("Hidden compatibility schema control", .serialized)
struct ProbeCompatibilitySchemaTests {
    @Test("The control adds one hidden String-target open schema without changing the published file action")
    func metadata() throws {
        let url = try #require(Bundle.main.url(forResource: "extract", withExtension: "actionsdata", subdirectory: "Metadata.appintents"))
        let metadata = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let actions = try #require(metadata["actions"] as? [String: [String: Any]])
        let modern = try #require(actions["OpenProbeContentIntent"])
        let compatibility = try #require(actions["OpenProbeCompatibilityContentIntent"])
        #expect(modern["isDiscoverable"] as? Bool == true)
        #expect(compatibility["isDiscoverable"] as? Bool == false)
        for action in [modern, compatibility] {
            let schemas = try #require(action["assistantDefinedSchemas"] as? [[String: Any]])
            #expect(schemas.count == 1)
            #expect(schemas.first?["domain"] as? String == "system")
            #expect(schemas.first?["name"] as? String == "OpenIntent")
            #expect(action["openAppWhenRun"] as? Bool == true)
        }
        #expect(actions.count == 2)
        let queries = try #require(metadata["queries"] as? [String: [String: Any]])
        #expect(queries["ProbeQuery"]?["capabilities"] as? Int == 70)
        let entities = try #require(metadata["entities"] as? [String: [String: Any]])
        let file = try #require(entities["ProbeEntity"])
        let schemas = try #require(file["assistantDefinedSchemas"] as? [[String: Any]])
        #expect(schemas.count == 1)
        #expect(schemas.first?["domain"] as? String == "files")
    }

    @Test("Compatibility lookup is confined to the bundled synthetic fixture and deduplicates identifiers")
    func lookup() async throws {
        let fixture = try ProbeEntity.fixture()
        let query = ProbeCompatibilityQuery()
        let byName = try await query.entities(matching: "Lyra Control")
        #expect(byName.count == 1)
        #expect(byName.first?.id == fixture.fixtureURL.path)
        let byID = try await query.entities(for: [fixture.fixtureURL.path, fixture.fixtureURL.path, "Unknown.zip"])
        #expect(byID.count == 1)
        #expect(byID.first?.id == fixture.fixtureURL.path)
        #expect(try await query.entities(for: ["Unknown.zip"]).isEmpty)
        #expect(try await query.entities(matching: "Unknown").isEmpty)
        #expect(try await query.suggestedEntities().isEmpty)
    }

    @MainActor @Test("The added action reports its own execution without changing the modern action marker")
    func execution() async throws {
        let state = ProbeState.shared
        state.opened = false
        state.compatibilityOpened = false
        defer { state.opened = false; state.compatibilityOpened = false }
        let intent = OpenProbeCompatibilityContentIntent()
        intent.target = ProbeCompatibilityEntity(id: "Unknown.zip")
        await #expect(throws: CocoaError.self) { _ = try await intent.perform() }
        #expect(!state.opened)
        #expect(!state.compatibilityOpened)
        intent.target = ProbeCompatibilityEntity(id: try ProbeEntity.fixture().fixtureURL.path)
        _ = try await intent.perform()
        #expect(!state.opened)
        #expect(state.compatibilityOpened)
    }
}
#endif
