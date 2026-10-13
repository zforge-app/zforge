import Foundation

/// Archives matched by an in-app search. The lease keeps the matched
/// authorized roots readable while a window presents the results.
nonisolated struct ArchiveSearchResults: Sendable {
    let urls: [URL]
    let lease: AutomationAccessLease
}

nonisolated protocol ArchiveSearching: Sendable {
    func search(_ term: String) async throws -> ArchiveSearchResults
}

/// Searches the names of direct archives inside the allowed automation folders,
/// with the same bounded, noninteractive discovery used by Siri entity queries.
/// A search term never authorizes a path: explicit paths produce no results.
nonisolated struct AuthorizedArchiveSearch: ArchiveSearching {
    private let access: any AutomationAuthorizing

    init(access: any AutomationAuthorizing = AutomationGrantStore.shared) { self.access = access }

    static func normalizedTerm(_ term: String) -> String? {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.utf8.count <= 4096, !trimmed.contains("\0") else { return nil }
        return trimmed
    }

    func search(_ term: String) async throws -> ArchiveSearchResults {
        guard let term = Self.normalizedTerm(term) else { throw AutomationError.invalidArguments }
        guard !term.contains("/") else { return ArchiveSearchResults(urls: [], lease: AutomationAccessLease()) }
        // A discovery instance per search keeps overlapping refreshes, and any
        // concurrent system entity query, from being refused as busy.
        let urls = try await AutomationArchiveEntities(access: access).matching(term).map { URL(fileURLWithPath: $0.id) }
        try Task.checkCancellation()
        guard !urls.isEmpty else { return ArchiveSearchResults(urls: [], lease: AutomationAccessLease()) }
        return ArchiveSearchResults(urls: urls, lease: try await access.authorize(urls))
    }
}
