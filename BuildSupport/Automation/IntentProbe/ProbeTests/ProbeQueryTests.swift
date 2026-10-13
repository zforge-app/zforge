import AppIntents
import Foundation
import Testing
@testable import Intent_Probe

@Suite("Published synthetic file resolution", .serialized)
struct ProbeQueryTests {
    enum Transport: CaseIterable, Sendable {
        case freshFile, codable, entityIdentifierString
    }

    @Test("The published file resolves after independent construction or system transport", arguments: Transport.allCases)
    func resolvesPublishedFile(transport: Transport) async throws {
        let fixture = try ProbeEntity.fixture()
        let incoming: FileEntityIdentifier
        switch transport {
        case .freshFile:
            incoming = try .file(url: fixture.fixtureURL)
        case .codable:
            let data = try JSONEncoder().encode(fixture.id)
            incoming = try JSONDecoder().decode(FileEntityIdentifier.self, from: data)
        case .entityIdentifierString:
            incoming = try #require(FileEntityIdentifier.entityIdentifier(for: fixture.id.entityIdentifierString))
        }
        let url = try #require(await incoming.fileURL)
        #expect(url.standardizedFileURL == fixture.fixtureURL.standardizedFileURL)
        let results = try await ProbeQuery().entities(for: [incoming])
        #expect(results.count == 1)
        #expect(results.first?.fixtureURL == fixture.fixtureURL)
    }

    @Test("A resolved entity retains the exact identifier requested by the system")
    func retainsTransportedIdentity() async throws {
        let fixture = try ProbeEntity.fixture()
        let incoming = try #require(FileEntityIdentifier.entityIdentifier(for: fixture.id.entityIdentifierString))
        let results = try await ProbeQuery().entities(for: [incoming])
        #expect(results.count == 1)
        #expect(results.first?.id == incoming)
        #expect(results.first?.id.entityIdentifierString == incoming.entityIdentifierString)
    }

    @Test("Empty and draft identifiers do not resolve to the published file")
    func rejectsUnknownIdentifiers() async throws {
        #expect(try await ProbeQuery().entities(for: []).isEmpty)
        #expect(try await ProbeQuery().entities(for: [.draft(identifier: "unpublished-draft")]).isEmpty)
    }

    @Test("A different ZIP is not the published synthetic file")
    func rejectsDifferentFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixture = try ProbeEntity.fixture()
        let other = directory.appendingPathComponent("Unpublished Control.zip")
        try FileManager.default.copyItem(at: fixture.fixtureURL, to: other)
        #expect(try await ProbeQuery().entities(for: [FileEntityIdentifier.file(url: other)]).isEmpty)
    }

    @Test("Repeated identifiers return the published file only once")
    func deduplicatesPublishedFile() async throws {
        let fixture = try ProbeEntity.fixture()
        let transported = try #require(FileEntityIdentifier.entityIdentifier(for: fixture.id.entityIdentifierString))
        #expect(try await ProbeQuery().entities(for: [fixture.id, transported, transported]).count == 1)
    }

    @Test("Name discovery and suggestions expose only the published synthetic archive")
    func discoversPublishedFile() async throws {
        let fixture = try ProbeEntity.fixture()

        #expect(fixture.fixtureURL.lastPathComponent == "Test Archive.zip")
        let byName = try await ProbeQuery().entities(matching: "test archive")
        #expect(byName.count == 1)
        #expect(byName.first?.fixtureURL == fixture.fixtureURL)
        #expect(try await ProbeQuery().entities(matching: "Unpublished Archive").isEmpty)
        #expect(try await ProbeQuery().entities(matching: "Lyra Control").isEmpty)
        let suggestions = try await ProbeQuery().suggestedEntities()
        #expect(suggestions.count == 1)
        #expect(suggestions.first?.fixtureURL == fixture.fixtureURL)
    }
}

#if PROBE_RUNTIME_AVAILABILITY
@Suite("Explicit runtime availability control")
struct ProbeAvailabilityTests {
    @Test("The diagnostic exports the same macOS 27 availability boundary as production")
    func metadata() throws {
        let url = try #require(Bundle.main.url(forResource: "extract", withExtension: "actionsdata", subdirectory: "Metadata.appintents"))
        let metadata = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        for (section, identifier) in [("entities", "ProbeEntity"), ("actions", "OpenProbeContentIntent"), ("queries", "ProbeQuery")] {
            let records = try #require(metadata[section] as? [String: [String: Any]])
            let record = try #require(records[identifier])
            let availability = try #require(record["availabilityAnnotations"] as? [String: [String: String]])
            #expect(availability["LNPlatformNameMACOS"]?["introducedVersion"] == "27.0")
        }
    }
}
#endif

#if PROBE_WILDCARD_AVAILABILITY
@Suite("Wildcard availability recovery control")
struct ProbeWildcardAvailabilityTests {
    @Test("The restored diagnostic exports wildcard availability for all modern types")
    func metadata() throws {
        let url = try #require(Bundle.main.url(forResource: "extract", withExtension: "actionsdata", subdirectory: "Metadata.appintents"))
        let metadata = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        for (section, identifier) in [("entities", "ProbeEntity"), ("actions", "OpenProbeContentIntent"), ("queries", "ProbeQuery")] {
            let records = try #require(metadata[section] as? [String: [String: Any]])
            let record = try #require(records[identifier])
            let availability = try #require(record["availabilityAnnotations"] as? [String: [String: String]])
            #expect(availability["LNPlatformNameWildcard"]?["introducedVersion"] == "*")
            #expect(availability["LNPlatformNameMACOS"] == nil)
        }
    }
}
#endif
