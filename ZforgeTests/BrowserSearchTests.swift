import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// Holds each debounce until the test releases it; a cancelled debounce throws.
private final class DebounceGate: @unchecked Sendable {
    private let lock = NSLock()
    private var waiters: [UUID: CheckedContinuation<Void, Error>] = [:]

    var pendingCount: Int { lock.withLock { waiters.count } }

    func wait() async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                lock.withLock {
                    if Task.isCancelled { continuation.resume(throwing: CancellationError()) } else { waiters[id] = continuation }
                }
            }
        } onCancel: {
            lock.withLock { waiters.removeValue(forKey: id) }?.resume(throwing: CancellationError())
        }
    }

    func releaseAll() {
        let all = lock.withLock { () -> [CheckedContinuation<Void, Error>] in
            defer { waiters.removeAll() }
            return Array(waiters.values)
        }
        all.forEach { $0.resume() }
    }
}

/// Records requests. Immediate mode answers from `matches` and finishes; manual
/// mode keeps each stream open for the test to feed and finish.
@MainActor
private final class ControlledSearcher: BrowserSearching {
    var matches: (BrowserSearchRequest) -> [BrowserSearchMatch] = { _ in [] }
    let isManual: Bool
    private(set) var requests: [BrowserSearchRequest] = []
    private(set) var continuations: [AsyncThrowingStream<[BrowserSearchMatch], Error>.Continuation] = []
    private(set) var terminatedCount = 0

    init(manual: Bool = false) { isManual = manual }

    func results(for request: BrowserSearchRequest) -> AsyncThrowingStream<[BrowserSearchMatch], Error> {
        requests.append(request)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: [BrowserSearchMatch].self)
        continuation.onTermination = { [weak self] _ in Task { @MainActor in self?.terminatedCount += 1 } }
        if isManual {
            continuations.append(continuation)
        } else {
            let found = matches(request)
            if !found.isEmpty { continuation.yield(found) }
            continuation.finish()
        }
        return stream
    }
}

/// A real folder tree and a browser opened on it with isolated English preferences.
@MainActor
private final class SearchFixture {
    let root: URL
    let defaults: UserDefaults
    let suite = "ZforgeBrowserSearch-\(UUID().uuidString)"
    let gate = DebounceGate()

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserSearch-\(UUID().uuidString)", isDirectory: true)
        let deep = root.appendingPathComponent("Notes/Deep", isDirectory: true)
        let package = root.appendingPathComponent("Notes/Bundle.app/Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        for path in ["Alpha Report.txt", "Notes/beta-report.md", "Notes/Deep/Report Final.pdf",
                     "Notes/Bundle.app/Contents/report-inside.txt", ".hidden-report.txt", "Other.txt", "Résumé.txt"] {
            try Data(path.utf8).write(to: root.appendingPathComponent(path))
        }
        defaults = try #require(UserDefaults(suiteName: suite))
    }

    func url(_ path: String) -> URL { root.appendingPathComponent(path) }

    func browser(searcher: (any BrowserSearching)? = nil, archives: any ArchiveServing = UIFixtureArchiveEngine(),
                 initialURL: URL? = nil) -> FileBrowserState {
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let gate = gate
        return FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(),
            recentItems: UIFixtureRecentItemsService(), taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: archives,
            initialURL: initialURL ?? root, searcher: searcher,
            searchDebounce: { try await gate.wait() }
        )
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
    }
}

/// Waits for asynchronous state on the main actor, failing after a bounded number of passes.
@MainActor
private func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
    for _ in 0..<500 {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(2))
    }
    Issue.record("The condition was not reached", sourceLocation: sourceLocation)
    throw CancellationError()
}

private func collect(_ stream: AsyncThrowingStream<[BrowserSearchMatch], Error>) async throws -> [BrowserSearchMatch] {
    var all: [BrowserSearchMatch] = []
    for try await batch in stream { all += batch }
    return all
}

@Suite("Search engines")
struct BrowserSearchEngineTests {
    @Test("Current Folder lists matching names recursively without entering packages or hidden files")
    @MainActor
    func folderSearch() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let matches = try await collect(FolderNameSearch.results(
            query: "report", root: fixture.root, showsHiddenFiles: false, limit: 100))
        let names = Set(matches.compactMap { match -> String? in
            if case let .file(url) = match { return url.lastPathComponent }
            return nil
        })
        #expect(names == ["Alpha Report.txt", "beta-report.md", "Report Final.pdf"])

        let hidden = try await collect(FolderNameSearch.results(
            query: "hidden", root: fixture.root, showsHiddenFiles: true, limit: 100))
        #expect(hidden.count == 1, "Show Hidden Files also searches hidden names")
        let accents = try await collect(FolderNameSearch.results(
            query: "resume", root: fixture.root, showsHiddenFiles: false, limit: 100))
        #expect(accents == [.file(fixture.url("Résumé.txt"))], "Matching ignores case and diacritics")
        let limited = try await collect(FolderNameSearch.results(
            query: "report", root: fixture.root, showsHiddenFiles: false, limit: 2))
        #expect(limited.count == 2)
    }

    @Test("This Mac matches Spotlight file names literally, with wildcards escaped")
    @MainActor
    func spotlightPredicate() {
        let predicate = SpotlightNameSearch.predicate(for: "a*b?")
        #expect(predicate.evaluate(with: [NSMetadataItemFSNameKey: "Xa*b?.txt"]))
        #expect(!predicate.evaluate(with: [NSMetadataItemFSNameKey: "axxbz.txt"]))
        #expect(SpotlightNameSearch.predicate(for: "report").evaluate(with: [NSMetadataItemFSNameKey: "Alpha REPORT.txt"]))
    }

    @Test("This Mac without authorized folders finishes with no results")
    @MainActor
    func spotlightWithoutScopes() async throws {
        #expect(try await collect(SpotlightNameSearch.results(query: "report", scopes: [], limit: 10)).isEmpty)
    }

    @Test("Inside an archive the listing is searched below the current folder")
    func archiveSearch() async throws {
        let engine = UIFixtureArchiveEngine()
        let opened = try await engine.openArchive(at: URL(fileURLWithPath: "/tmp/Sample.zip"), password: nil,
                                                  policy: .standard)
        let found = try await collect(ArchiveNameSearch.results(query: "INSIDE", root: opened.address,
                                                                archives: engine, limit: 10))
        guard case let .item(item)? = found.first else {
            Issue.record("No archive item matched")
            return
        }
        #expect(found.count == 1 && item.name == "Inside.txt")
        #expect(try await collect(ArchiveNameSearch.results(query: "zzz", root: opened.address,
                                                            archives: engine, limit: 10)).isEmpty)
    }
}

@Suite("Toolbar search state")
@MainActor
struct BrowserSearchStateTests {
    @Test("Typing waits for a pause and searches only the last text in the current folder")
    func debounce() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher()
        searcher.matches = { _ in [.file(fixture.url("Alpha Report.txt"))] }
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        browser.beginSearch()
        #expect(browser.isSearchPresented)
        #expect(browser.searchFieldFocusRequest == 1)
        #expect(browser.searchScope == .currentFolder)

        browser.updateSearchText("a")
        browser.updateSearchText("al")
        browser.updateSearchText("alp")
        try await waitUntil { fixture.gate.pendingCount == 1 }
        #expect(searcher.requests.isEmpty, "Nothing is searched before the pause")
        fixture.gate.releaseAll()
        try await waitUntil { browser.fileSearch != nil && !browser.isLoading }

        #expect(searcher.requests.map(\.query) == ["alp"])
        #expect(searcher.requests.first?.target == .folder(fixture.root))
        #expect(browser.location == .recents)
        #expect(browser.title == "Searching “alp”")
        #expect(browser.pathComponents.map(\.systemImage) == ["magnifyingglass"])
        #expect(browser.items.map(\.name) == ["Alpha Report.txt"])
    }

    @Test("Results appear while the search runs, and a new query stops the old one")
    func streamingAndCancellation() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher(manual: true)
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        let originHistory = browser.canGoBack

        browser.updateSearchText("report")
        let first = Task { await browser.applySearchText() }
        try await waitUntil { searcher.requests.count == 1 }
        searcher.continuations[0].yield([.file(fixture.url("Alpha Report.txt"))])
        try await waitUntil { browser.items.count == 1 }
        #expect(browser.isLoading, "The first batch is listed before the search finishes")
        browser.select(try #require(browser.items.first))

        browser.updateSearchText("beta")
        let second = Task { await browser.applySearchText() }
        try await waitUntil { searcher.requests.count == 2 }
        try await waitUntil { searcher.terminatedCount == 1 }
        searcher.continuations[0].yield([.file(fixture.url("Other.txt"))])
        searcher.continuations[1].yield([.file(fixture.url("Notes/beta-report.md"))])
        searcher.continuations[1].finish()
        await second.value
        await first.value

        #expect(browser.items.map(\.name) == ["beta-report.md"], "Late batches of the old query are discarded")
        #expect(browser.title == "Searching “beta”")
        #expect(browser.selectedItems.isEmpty)
        #expect(!browser.isLoading)
        await browser.goBack()
        #expect(browser.location == .fileSystem(fixture.root), "Refining a query adds no history entry")
        #expect(browser.canGoBack == originHistory)
    }

    @Test("A result selected while results stream in stays selected when the search finishes")
    func selectionDuringStreaming() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher(manual: true)
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        browser.updateSearchText("report")
        let run = Task { await browser.applySearchText() }
        try await waitUntil { searcher.requests.count == 1 }
        searcher.continuations[0].yield([.file(fixture.url("Alpha Report.txt"))])
        try await waitUntil { browser.items.count == 1 }
        browser.select(try #require(browser.items.first))
        searcher.continuations[0].yield([.file(fixture.url("Notes/beta-report.md"))])
        searcher.continuations[0].finish()
        await run.value
        #expect(browser.items.count == 2)
        #expect(browser.selectedItems.map(\.name) == ["Alpha Report.txt"])
    }

    @Test("Back returns to the folder and collapses the field; Forward restores the search and its text")
    func history() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher()
        searcher.matches = { _ in [.file(fixture.url("Alpha Report.txt")), .file(fixture.url("Notes/beta-report.md"))] }
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        browser.beginSearch()
        browser.updateSearchText("report")
        await browser.applySearchText()
        #expect(browser.items.count == 2)

        await browser.goBack()
        #expect(browser.location == .fileSystem(fixture.root))
        #expect(browser.fileSearch == nil)
        #expect(browser.searchText.isEmpty)
        #expect(!browser.isSearchPresented)

        await browser.goForward()
        #expect(browser.fileSearch?.query == "report")
        #expect(browser.searchText == "report")
        #expect(browser.isSearchPresented)
        #expect(browser.title == "Searching “report”")
        #expect(browser.items.count == 2)
    }

    @Test("Clearing the text returns to the folder and keeps the field; Escape also collapses it")
    func clearingAndEscape() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher()
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        let originHistory = browser.canGoBack
        browser.beginSearch()
        browser.updateSearchText("report")
        await browser.applySearchText()
        #expect(browser.canGoBack)

        browser.updateSearchText("")
        await browser.applySearchText()
        #expect(browser.location == .fileSystem(fixture.root))
        #expect(browser.fileSearch == nil)
        #expect(browser.isSearchPresented, "The emptied field stays open while it is in use")
        #expect(browser.canGoBack == originHistory, "Ending a search leaves no history entry behind")

        browser.updateSearchText("alpha")
        await browser.applySearchText()
        await browser.cancelSearch()
        #expect(browser.location == .fileSystem(fixture.root))
        #expect(!browser.isSearchPresented)
        #expect(browser.searchText.isEmpty)

        browser.beginSearch()
        browser.dismissSearchFieldIfIdle()
        #expect(!browser.isSearchPresented, "Clicking away from an empty field collapses it")
    }

    @Test("Switching scope searches again in place; Recents only offers This Mac")
    func scopes() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher()
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        browser.updateSearchText("report")
        await browser.applySearchText()
        #expect(browser.availableSearchScopes == [.thisMac, .currentFolder])
        #expect(browser.currentFolderSearchName == FileManager.default.displayName(atPath: fixture.root.path))
        let historyBefore = browser.canGoBack

        await browser.setSearchScope(.thisMac)
        #expect(searcher.requests.map(\.target) == [.folder(fixture.root), .thisMac(scopes: [])])
        #expect(browser.fileSearch?.scope == .thisMac)
        #expect(browser.canGoBack == historyBefore)
        await browser.goBack()
        #expect(browser.location == .fileSystem(fixture.root), "Back skips the replaced scope")

        await browser.navigateToRecents()
        browser.beginSearch()
        #expect(browser.searchScope == .thisMac)
        #expect(browser.availableSearchScopes == [.thisMac])
        #expect(browser.currentFolderSearchName == nil)
        browser.updateSearchText("report")
        await browser.setSearchScope(.currentFolder)
        await browser.applySearchText()
        #expect(searcher.requests.last?.target == .thisMac(scopes: []), "Recents has no folder to search")
    }

    @Test("Opening a folder result shows its real path and leaves the search; Back returns to the results")
    func openingResults() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher()
        searcher.matches = { _ in [.file(fixture.url("Notes")), .file(fixture.url("Notes/Deep/Report Final.pdf"))] }
        let browser = fixture.browser(searcher: searcher)
        defer { browser.close() }
        await browser.start()
        browser.updateSearchText("e")
        await browser.applySearchText()

        let report = try #require(browser.items.first { $0.name == "Report Final.pdf" })
        browser.select(report)
        let path = browser.breadcrumbComponents
        #expect(path.first?.systemImage == "magnifyingglass")
        #expect(path.suffix(2).map(\.name) == ["Notes", "Deep"], "The path bar shows where the selected result is")

        let folder = try #require(browser.items.first { $0.name == "Notes" })
        await browser.open(folder)
        #expect(browser.location == .fileSystem(fixture.url("Notes").standardizedFileURL))
        #expect(browser.fileSearch == nil)
        #expect(!browser.isSearchPresented)
        #expect(browser.pathComponents.map(\.name) == ["Notes"])
        #expect(browser.breadcrumbComponents.dropLast().last?.location == .fileSystem(fixture.root.standardizedFileURL))

        await browser.goBack()
        #expect(browser.fileSearch?.query == "e")
        #expect(browser.items.count == 2)
    }

    @Test("Inside an archive Current Folder searches the archive and results open in place")
    func archiveScope() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        try Data("zip".utf8).write(to: fixture.url("Sample.zip"))
        let browser = fixture.browser()
        defer { browser.close() }
        await browser.start()
        let archive = try #require(browser.items.first { $0.name == "Sample.zip" })
        await browser.open(archive)
        guard case .archive = browser.location else {
            Issue.record("The archive did not open: \(browser.location)")
            return
        }
        browser.beginSearch()
        #expect(browser.searchScope == .currentFolder)
        browser.updateSearchText("inside")
        await browser.applySearchText()
        #expect(browser.items.map(\.name) == ["Inside.txt"])
        #expect(browser.currentFolderSearchName == "Sample.zip")
        await browser.goBack()
        #expect(browser.pathComponents.last?.name == "Sample.zip")
    }

    @Test("Closing the window stops a running query")
    func closingCancels() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let searcher = ControlledSearcher(manual: true)
        let browser = fixture.browser(searcher: searcher)
        await browser.start()
        browser.updateSearchText("report")
        let run = Task { await browser.applySearchText() }
        try await waitUntil { searcher.requests.count == 1 }
        browser.close()
        try await waitUntil { searcher.terminatedCount == 1 }
        await run.value
    }
}

/// Workload: 20,000 files in 200 folders, 200 names matching (1%), searched
/// through the real state and Current Folder engine. Records the first-result
/// latency, the total time and the longest main-actor stall (a 5 ms ticker),
/// without timing gates; the measurements are recorded in REGRESSION-COVERAGE.
@Suite("Toolbar search workload", .serialized)
@MainActor
struct BrowserSearchWorkloadTests {
    @Test("Current Folder over 20,000 files streams results without stalling the main actor")
    func folderWorkload() async throws {
        let fixture = try SearchFixture()
        defer { fixture.cleanUp() }
        let tree = fixture.url("Workload")
        for folder in 0..<200 {
            let directory = tree.appendingPathComponent("Folder \(folder)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for file in 0..<100 {
                let name = file == 0 ? "Needle \(folder).txt" : "Item \(file).txt"
                FileManager.default.createFile(atPath: directory.appendingPathComponent(name).path, contents: nil)
            }
        }
        let browser = fixture.browser(searcher: nil, initialURL: tree)
        defer { browser.close() }
        await browser.start()

        // Baseline: the same ticker for one second with no search running.
        var idleStall = Duration.zero
        do {
            var last = ContinuousClock.now
            let end = last.advanced(by: .seconds(1))
            while ContinuousClock.now < end {
                try await Task.sleep(for: .milliseconds(5))
                let now = ContinuousClock.now
                idleStall = max(idleStall, last.duration(to: now) - .milliseconds(5))
                last = now
            }
        }
        var longestStall = Duration.zero
        let ticker = Task { @MainActor in
            var last = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(5))
                let now = ContinuousClock.now
                longestStall = max(longestStall, last.duration(to: now) - .milliseconds(5))
                last = now
            }
        }
        let clock = ContinuousClock()
        let start = clock.now
        browser.updateSearchText("needle")
        let run = Task { await browser.applySearchText() }
        try await waitUntil { browser.items.contains { $0.name.hasPrefix("Needle") } }
        let firstResult = start.duration(to: clock.now)
        await run.value
        let total = start.duration(to: clock.now)
        ticker.cancel()

        #expect(browser.items.count == 200)
        print("BrowserSearchWorkload first=\(firstResult) total=\(total) longestMainStall=\(longestStall) idleStall=\(idleStall) results=\(browser.items.count)")
    }
}

@Suite("Toolbar search presentation")
@MainActor
struct BrowserSearchPresentationTests {
    private func browser(_ defaults: UserDefaults) -> FileBrowserState {
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        return FileBrowserState(preferences: preferences, fileSystem: UIFixtureFileSystemService(),
            recentItems: UIFixtureRecentItemsService(), grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine(), searcher: ControlledSearcher())
    }

    @Test("The expanded field and the scope bar in light and dark", arguments: ZforgeSnapshot.appearances)
    func snapshots(appearance: (name: String, appearance: NSAppearance.Name)) async throws {
        let suite = "SearchSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = browser(defaults)
        defer { state.close() }
        let folder = URL(fileURLWithPath: "/ZforgeFixtures/Fixture Folder")
        await state.open(try await UIFixtureFileSystemService().item(at: folder))
        state.beginSearch()
        state.updateSearchText("Report")
        await state.applySearchText()

        ZforgeSnapshot.assert(
            HStack { BrowserToolbarSearchControl(state: state) }.padding(8).background(.background),
            size: CGSize(width: 240, height: 40), appearance: appearance.appearance, named: "field-\(appearance.name)")
        ZforgeSnapshot.assert(
            BrowserSearchScopeBar(state: state).environment(\.locale, Locale(identifier: "en")),
            size: CGSize(width: 520, height: 36), appearance: appearance.appearance, named: "scope-bar-\(appearance.name)")
    }

    @Test("The overflow menu offers Search only when the toolbar has no room for it", arguments: [
        (650.0, true), (720.0, false), (860.0, false), (1_100.0, false)
    ])
    func overflowSearch(width: Double, offersSearch: Bool) async throws {
        let suite = "SearchOverflow-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = browser(defaults)
        defer { state.close() }
        let contents = BrowserToolbarLayout.stage(for: CGFloat(width)).overflowMenuContents
        #expect(contents.includesSearchAction == offersSearch)
        let menu = BrowserActionsMenu.make(state: state, includesSearchAction: contents.includesSearchAction,
                                           showToast: { _ in })
        let item = menu.items.first { $0.title == "Search" }
        #expect((item != nil) == offersSearch)
        if let item, let index = menu.items.firstIndex(of: item) {
            #expect(item.keyEquivalent == "f" && item.keyEquivalentModifierMask == .command)
            menu.performActionForItem(at: index)
            #expect(state.isSearchPresented)
            #expect(state.searchFieldFocusRequest == 1)
        }
    }
}
