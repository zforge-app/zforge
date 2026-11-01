import Foundation
import Testing
@testable import Zforge

/// UI test launches share one application container. These tests check which preferences a
/// launch reads, so one UI test's settings (for example `--ui-view-mode gallery`) can reach
/// neither the next test nor the user's own preferences.
@Suite("UI fixture preference isolation")
@MainActor
struct UIFixturePreferencesIsolationTests {
    private static let viewModeKey = "browser.viewMode"

    @Test("An ordinary launch uses the user's preferences")
    func ordinaryLaunchUsesStandardDefaults() {
        let defaults = ZforgeDefaults.resolve(arguments: ["Zforge"], environment: [:])
        #expect(defaults === UserDefaults.standard)
    }

    @Test("A UI test launch without its own suite starts from the defaults, whatever the previous launch saved",
          arguments: ["--ui-fixtures", "--ui-icon-preview-fixtures", "--ui-archive-drag-fixtures", "--ui-finder-fixtures", "--ui-window-width"])
    func fixtureLaunchStartsClean(argument: String) throws {
        let pristineSuite = "ZforgeTestSuite.ZforgePristine-\(UUID().uuidString)"
        let pristine = try #require(UserDefaults(suiteName: pristineSuite))
        defer { pristine.removeTestSuite(named: pristineSuite) }
        let defaultMode = FileBrowserPreferences(defaults: pristine).viewMode
        let otherMode: BrowserViewMode = defaultMode == .gallery ? .list : .gallery

        // The previous UI test's launch changes the default view mode, as `--ui-view-mode` does.
        let previousLaunch = ZforgeDefaults.resolve(arguments: ["Zforge", argument], environment: [:])
        // Stop before writing if the launch would use the user's own preferences.
        try #require(previousLaunch !== UserDefaults.standard)
        FileBrowserPreferences(defaults: previousLaunch).viewMode = otherMode
        #expect(FileBrowserPreferences(defaults: previousLaunch).viewMode == otherMode)
        // The write landed in the launch's own suite (the user's preferences are never read here).
        #expect(previousLaunch.string(forKey: Self.viewModeKey) == otherMode.rawValue)

        // The next launch opens with the default mode.
        let nextLaunch = ZforgeDefaults.resolve(arguments: ["Zforge", argument], environment: [:])
        #expect(nextLaunch !== UserDefaults.standard)
        #expect(FileBrowserPreferences(defaults: nextLaunch).viewMode == defaultMode)
        nextLaunch.removeTestSuite(named: ZforgeDefaults.fixtureSuite)
    }

    @Test("A fixture launch that names its suite keeps it across launches, for relaunch tests")
    func namedSuitePersistsAcrossLaunches() throws {
        let suite = "ZforgeTestSuite.ZforgeFixtureRelaunch-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removeTestSuite(named: suite) }
        let environment = ["ZFORGE_UI_PREFERENCES_SUITE": suite]
        let first = ZforgeDefaults.resolve(arguments: ["Zforge", "--ui-fixtures"], environment: environment)
        FileBrowserPreferences(defaults: first).viewMode = .columns
        let second = ZforgeDefaults.resolve(arguments: ["Zforge", "--ui-fixtures"], environment: environment)
        #expect(second !== UserDefaults.standard)
        #expect(FileBrowserPreferences(defaults: second).viewMode == .columns)
    }

    @Test("Every UI test argument marks a UI test launch; the program name and other arguments do not")
    func uiTestLaunchDetection() {
        #expect(ZforgeDefaults.isUITestLaunch(arguments: ["Zforge", "--ui-archive-drag-fixtures"]))
        #expect(ZforgeDefaults.isUITestLaunch(arguments: ["Zforge", "-appLanguagePreference", "english", "--ui-view-mode", "list"]))
        #expect(!ZforgeDefaults.isUITestLaunch(arguments: ["Zforge"]))
        #expect(!ZforgeDefaults.isUITestLaunch(arguments: ["--ui-fixtures"]), "Only arguments after the program name count")
        #expect(!ZforgeDefaults.isUITestLaunch(arguments: ["Zforge", "-NSDocumentRevisionsDebugMode", "YES"]))
        #expect(!ZforgeDefaults.isUITestLaunch, "The unit test host has no UI test argument")
        #expect(ZforgeDefaults.isTestHost && ZforgeDefaults.isIsolatedLaunch, "The unit test host is isolated (ZF-54)")
    }

    @Test("A UI test launch's sidebar favorites live in its own suite")
    func pinnedFoldersFollowTheLaunchDefaults() throws {
        let launch = ZforgeDefaults.resolve(arguments: ["Zforge", "--ui-archive-drag-fixtures"], environment: [:])
        try #require(launch !== UserDefaults.standard)
        defer { launch.removeTestSuite(named: ZforgeDefaults.fixtureSuite) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PinnedIsolation-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = PinnedFolderStore(defaults: launch)
        #expect(store.urls == PinnedFolderStore.defaultURLs.map { $0.standardizedFileURL.resolvingSymlinksInPath() },
                "A UI test launch starts from the default favorites, not the user's")
        try store.pin([folder])
        #expect(launch.data(forKey: "sidebarPinnedFolders.v1") != nil, "The pin is saved in the launch's own suite")
        #expect(store.urls.contains(folder.standardizedFileURL.resolvingSymlinksInPath()))
    }
}
