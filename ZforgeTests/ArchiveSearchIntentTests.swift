import AppIntents
import Foundation
import Testing
@testable import Zforge

@Suite("In-app archive search for Siri", .serialized)
struct ArchiveSearchIntentTests {
    @Test("The search action publishes the macOS 27 searchInApp schema and opens Zforge")
    func searchInAppMetadata() throws {
        let file = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Metadata.appintents/extract.actionsdata")
        let payload = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let actions = try #require(payload["actions"] as? [String: [String: Any]])
        let action = try #require(actions["SearchZforgeArchivesIntent"])
        let schemas = try #require(action["assistantDefinedSchemas"] as? [[String: Any]])
        #expect(schemas.count == 1)
        #expect(schemas.first?["domain"] as? String == "system")
        #expect(schemas.first?["name"] as? String == "SystemSearchInAppIntent")
        #expect(action["isDiscoverable"] as? Bool == true)
        #expect(action["openAppWhenRun"] as? Bool == true)
        let availability = try #require(action["availabilityAnnotations"] as? [String: [String: String]])
        #expect(availability["LNPlatformNameMACOS"]?["introducedVersion"] == "27.0")
        let parameters = try #require(action["parameters"] as? [[String: Any]])
        #expect(parameters.map { $0["name"] as? String } == ["criteria"])
        // Searching must not replace the discoverable file-schema opening action.
        #expect(actions["OpenZforgeFileContentIntent"]?["isDiscoverable"] as? Bool == true)
    }

    @Test("Search returns only direct archives in allowed folders, with a scope that keeps them readable")
    func authorizedResults() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        #expect(try await fixture.search.search("Vega").urls.isEmpty)
        try await fixture.store.add(fixture.root)
        let nested = fixture.root.appendingPathComponent("Nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("Nested fixture".utf8).write(to: nested.appendingPathComponent("Vega Nested.zip"))
        try Data("Text fixture".utf8).write(to: fixture.root.appendingPathComponent("Vega Notes.txt"))
        let results = try await fixture.search.search("  Vega Demo  ")
        #expect(results.urls.map(\.path) == [fixture.archive.path])
        #expect(try await fixture.search.search("Vega Demo.zip").urls.map(\.path) == [fixture.archive.path])
        #expect(try await fixture.search.search("Orion").urls.isEmpty)
        await fixture.store.remove(fixture.root.path)
        #expect(try await fixture.search.search("Vega").urls.isEmpty)
    }

    @Test("Blank or malformed terms are refused, and explicit paths neither match nor grant access")
    func searchArguments() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        for term in ["", "   ", "bad\0name", String(repeating: "x", count: 4097)] {
            await #expect(throws: AutomationError.invalidArguments) { _ = try await fixture.search.search(term) }
        }
        #expect(try await fixture.search.search(fixture.archive.path).urls.isEmpty)
        #expect(await fixture.store.authorizedFolders().isEmpty)
    }

    @available(macOS 27.0, *)
    @MainActor @Test("Siri's search request presents the trimmed term in Zforge and rejects blank terms")
    func performPresentsResults() async throws {
        let recorder = SearchPresentationRecorder()
        var intent = SearchZforgeArchivesIntent()
        intent.criteria = StringSearchCriteria(term: "  Vega Demo.zip ")
        intent.presenter = { recorder.terms.append($0) }
        _ = try await intent.perform()
        #expect(recorder.terms == ["Vega Demo.zip"])
        intent.criteria = StringSearchCriteria(term: " ")
        await #expect(throws: AutomationError.invalidArguments) { _ = try await intent.perform() }
        #expect(recorder.terms == ["Vega Demo.zip"])
    }

    @MainActor @Test("A search request opens its own window request and restoration repeats only the search")
    func windowRequest() throws {
        let delegate = AppDelegate()
        delegate.receiveArchiveSearch("Vega Demo")
        let request = try #require(delegate.takeNextArchiveRequest())
        #expect(request.archiveSearch == "Vega Demo")
        #expect(request.initialURL == nil)
        #expect(request.automationAccess == nil)
        #expect(delegate.takeNextArchiveRequest() == nil)
        let restored = try JSONDecoder().decode(BrowserWindowRequest.self, from: JSONEncoder().encode(request))
        #expect(restored == request)
        #expect(restored.archiveSearch == "Vega Demo")
        #expect(BrowserWindowRequest(id: request.id) != request)
    }

    @MainActor @Test("A request that launches Zforge reuses the untouched launch window once, within its grace period")
    func launchWindowReuse() throws {
        let start = ContinuousClock.now
        let delegate = AppDelegate()
        let launch = delegate.makeDefaultWindowRequest(now: start)
        #expect(launch.archiveSearch == nil)
        #expect(delegate.takeRequest(forLaunchWindow: launch.id, now: start) == nil, "Nothing to present yet")
        delegate.receiveArchiveSearch("Vega Demo")
        delegate.receiveArchiveSearch("Orion")
        #expect(delegate.takeRequest(forLaunchWindow: UUID(), now: start) == nil)
        #expect(delegate.takeRequest(forLaunchWindow: launch.id, now: start.advanced(by: .seconds(2)))?.archiveSearch == "Vega Demo")
        #expect(delegate.takeRequest(forLaunchWindow: launch.id, now: start) == nil, "The launch window is reused once")
        #expect(delegate.takePendingArchiveRequests().map(\.archiveSearch) == ["Orion"], "Later requests open their own windows")
        let reopened = delegate.makeDefaultWindowRequest(now: start)
        delegate.receiveArchiveSearch("Vega")
        #expect(delegate.takeRequest(forLaunchWindow: reopened.id, now: start) == nil, "Only the first default window is offered")

        let late = AppDelegate()
        let lateLaunch = late.makeDefaultWindowRequest(now: start)
        late.receiveArchiveSearch("Vega")
        let expired = start.advanced(by: AppDelegate.launchWindowGracePeriod + .seconds(1))
        #expect(late.takeRequest(forLaunchWindow: lateLaunch.id, now: expired) == nil, "A window already shown for a while stays")
        #expect(late.takePendingArchiveRequests().count == 1)

        let closed = AppDelegate()
        let closedLaunch = closed.makeDefaultWindowRequest(now: start)
        closed.releaseLaunchWindow(closedLaunch.id)
        closed.receiveArchiveSearch("Vega")
        #expect(closed.takeRequest(forLaunchWindow: closedLaunch.id, now: start) == nil)
        #expect(closed.makeDefaultWindowRequest(now: start).archiveSearch == "Vega", "A new default window presents a waiting request")
    }

    @MainActor @Test("A single result is listed under a search title, selected, and kept readable until the window closes")
    func singleResultWindow() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        var lease: AutomationAccessLease? = AutomationAccessLease()
        weak var observed = lease
        let search = StubArchiveSearch(urls: [fixture.archive], lease: try #require(lease))
        lease = nil
        let browser = try fixture.browser(search: search, initialSearch: "Vega Demo")
        await browser.start()
        #expect(browser.location == .recents)
        #expect(browser.archiveSearchTerm == "Vega Demo")
        #expect(browser.selectedSidebarTag == nil)
        #expect(browser.items.map(\.name) == ["Vega Demo.zip"])
        #expect(browser.selectedItems.map(\.name) == ["Vega Demo.zip"])
        #expect(browser.title == "Search: “Vega Demo”")
        #expect(browser.pathComponents.first?.systemImage == "magnifyingglass")
        #expect(await search.terms == ["Vega Demo"])
        #expect(observed != nil)
        await browser.navigateToRecents()
        #expect(browser.archiveSearchTerm == nil)
        #expect(observed != nil, "Archives opened from the results remain readable after navigation")
        browser.close()
        #expect(observed == nil)
    }

    @MainActor @Test("Several results are listed without choosing one, and history restores the search")
    func multipleResultsAndHistory() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        let second = fixture.root.appendingPathComponent("Vega Backup.zip")
        try Data("Second fixture".utf8).write(to: second)
        let search = StubArchiveSearch(urls: [second, fixture.archive])
        let browser = try fixture.browser(search: search, initialSearch: "Vega")
        defer { browser.close() }
        await browser.start()
        #expect(Set(browser.items.map(\.name)) == ["Vega Backup.zip", "Vega Demo.zip"])
        #expect(browser.selectedItems.isEmpty)
        await browser.navigateToRecents()
        #expect(browser.archiveSearchTerm == nil)
        #expect(browser.title == "Recents")
        await browser.goBack()
        #expect(browser.archiveSearchTerm == "Vega")
        #expect(browser.title == "Search: “Vega”")
        #expect(Set(browser.items.map(\.name)) == ["Vega Backup.zip", "Vega Demo.zip"])
        #expect(await search.terms == ["Vega", "Vega"])
        await browser.goForward()
        #expect(browser.archiveSearchTerm == nil)
    }

    @MainActor @Test("No matches leave an empty search list, and a failed search reports an error")
    func emptyAndFailedSearch() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        let empty = try fixture.browser(search: StubArchiveSearch(urls: []), initialSearch: "Orion")
        defer { empty.close() }
        await empty.start()
        #expect(empty.archiveSearchTerm == "Orion")
        #expect(empty.items.isEmpty)
        #expect(empty.error == nil)
        let failing = try fixture.browser(search: StubArchiveSearch(urls: [], failure: AutomationError.listingTooLarge), initialSearch: "Vega")
        defer { failing.close() }
        await failing.start()
        #expect(failing.archiveSearchTerm == "Vega")
        #expect(failing.items.isEmpty)
        #expect(failing.error != nil)
    }

    @MainActor @Test("Leaving a search before it finishes never publishes its stale results")
    func staleSearch() async throws {
        let fixture = try ArchiveSearchFixture()
        defer { fixture.cleanUp() }
        let search = StubArchiveSearch(urls: [fixture.archive], suspends: true)
        let browser = try fixture.browser(search: search, initialSearch: "Vega")
        defer { browser.close() }
        let starting = Task { await browser.start() }
        await search.waitUntilRequested()
        await browser.navigateToTag("Red")
        await search.resume()
        await starting.value
        #expect(browser.archiveSearchTerm == nil)
        #expect(browser.selectedSidebarTag == "Red")
        #expect(!browser.items.contains { $0.name == "Vega Demo.zip" })
    }
}

@MainActor private final class SearchPresentationRecorder {
    var terms: [String] = []
}

private actor StubArchiveSearch: ArchiveSearching {
    private let urls: [URL]
    // Handed over once, so the browser is the scope's only owner.
    private var lease: AutomationAccessLease?
    private let failure: (any Error)?
    private let suspends: Bool
    private(set) var terms: [String] = []
    private var requested = false
    private var observer: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<Void, Never>?

    init(urls: [URL], lease: AutomationAccessLease = AutomationAccessLease(), failure: (any Error)? = nil, suspends: Bool = false) {
        self.urls = urls
        self.lease = lease
        self.failure = failure
        self.suspends = suspends
    }

    func search(_ term: String) async throws -> ArchiveSearchResults {
        terms.append(term)
        if suspends {
            await withCheckedContinuation {
                pending = $0
                requested = true
                observer?.resume()
                observer = nil
            }
        }
        if let failure { throw failure }
        defer { lease = nil }
        return ArchiveSearchResults(urls: urls, lease: lease ?? AutomationAccessLease())
    }
    func waitUntilRequested() async {
        if requested { return }
        await withCheckedContinuation { observer = $0 }
    }
    func resume() { pending?.resume(); pending = nil }
}

private struct ArchiveSearchFixture: Sendable {
    let container: URL
    let root: URL
    let archive: URL
    let suite: String
    let store: AutomationGrantStore
    let search: AuthorizedArchiveSearch

    init() throws {
        container = FileManager.default.temporaryDirectory.appendingPathComponent("ArchiveSearch-" + UUID().uuidString)
        root = container.appendingPathComponent("Allowed")
        archive = root.appendingPathComponent("Vega Demo.zip")
        suite = "ZforgeTestSuite.ArchiveSearchTests-" + UUID().uuidString
        store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        search = AuthorizedArchiveSearch(access: store)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("Search metadata fixture".utf8).write(to: archive)
    }

    @MainActor func browser(search: any ArchiveSearching, initialSearch: String) throws -> FileBrowserState {
        let preferences = FileBrowserPreferences(defaults: try #require(UserDefaults(suiteName: suite)))
        preferences.language = .english
        return FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            recentItems: UIFixtureRecentItemsService(), taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: NativeSevenZipArchiveEngine(),
            archiveSearch: search, initialArchiveSearch: initialSearch)
    }

    func cleanUp() {
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
        try? FileManager.default.removeItem(at: container)
    }
}
