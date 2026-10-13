#if PROBE_SEARCH_IN_APP
import AppIntents
import OSLog

/// Opt-in control for Siri's in-app search fallback. Planner logs show that a
/// named request whose app-entity search returns nothing next calls
/// SearchInApp, which fails when no system.searchInApp action exists.
/// The result view keeps the synthetic entity annotated on screen.
@available(macOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct ProbeSearchInAppIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] { [.general] }
    var criteria: StringSearchCriteria

    @MainActor func perform() async throws -> some IntentResult {
        let matched = "Test Archive.zip".localizedStandardContains(criteria.term)
            || criteria.term.localizedStandardContains("Test Archive")
        // Log only the match result, never the request text.
        Logger(subsystem: "io.libor.ZforgeIntentProbe", category: "Routing").notice("Probe search-in-app action invoked; matched=\(matched).")
        ProbeState.shared.searchMatched = matched
        return .result()
    }
}
#endif
