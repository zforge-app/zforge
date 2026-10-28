import Foundation
import Testing
@testable import Zforge

@Suite("Recents with archive session copies")
@MainActor
struct RecentsArchiveSessionCopyTests {
    @Test("Recents lists the original archive once when archive sessions contain copies")
    func originalArchiveAppearsOnce() async throws {
        let defaultsName = "RecentsSessionCopies-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        preferences.language = .english
        // The same fixture the app uses for `--ui-recents-duplicates`: two copies of
        // Sample.zip inside Zforge's archive sessions surround the user's originals.
        let recents = UIFixtureRecentItemsService(includesArchiveSessionCopies: true)
        let reported = await recents.recentItemURLs()
        #expect(reported.filter { $0.lastPathComponent == "Sample.zip" }.count == 3)

        let state = FileBrowserState(
            preferences: preferences, fileSystem: UIFixtureFileSystemService(),
            recentItems: recents, taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        defer { state.close() }
        await state.start()

        #expect(state.location == .recents)
        #expect(state.items.compactMap(\.localURL) == ["Welcome.txt", "Sample.zip", "Another.txt"].map {
            URL(fileURLWithPath: "/ZforgeFixtures/\($0)")
        })
        for mode in BrowserViewMode.allCases {
            state.viewMode = mode
            let rendered = state.flattenedList().map(\.item.name)
            #expect(rendered.filter { $0 == "Sample.zip" }.count == 1, "\(mode) rendered \(rendered).")
        }
    }
}
