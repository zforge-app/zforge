#if PROBE_SEARCH_IN_APP
import AppIntents
import Testing
@testable import Intent_Probe

@Suite("In-app search control", .serialized)
@MainActor struct ProbeSearchInAppTests {
    @Test("Searching for the fixture name records a match; an unrelated term records no match")
    func perform() async throws {
        let intent = ProbeSearchInAppIntent()
        intent.criteria = StringSearchCriteria(term: "Test Archive")
        _ = try await intent.perform()
        #expect(ProbeState.shared.searchMatched == true)

        intent.criteria = StringSearchCriteria(term: "Unrelated Fixture")
        _ = try await intent.perform()
        #expect(ProbeState.shared.searchMatched == false)
        ProbeState.shared.searchMatched = nil
    }
}
#endif
