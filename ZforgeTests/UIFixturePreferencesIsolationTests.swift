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
        let defaults = FileBrowserPreferences.applicationDefaults(arguments: ["Zforge"], environment: [:])
        #expect(defaults === UserDefaults.standard)
    }

    @Test("A fixture launch without its own suite starts from the defaults, whatever the previous launch saved",
          arguments: ["--ui-fixtures", "--ui-icon-preview-fixtures"])
    func fixtureLaunchStartsClean(argument: String) throws {
        let userValue = UserDefaults.standard.object(forKey: Self.viewModeKey) as? String
        let pristine = try #require(UserDefaults(suiteName: "ZforgePristine-\(UUID().uuidString)"))
        let defaultMode = FileBrowserPreferences(defaults: pristine).viewMode
        let otherMode: BrowserViewMode = defaultMode == .gallery ? .list : .gallery

        // The previous UI test's launch changes the default view mode, as `--ui-view-mode` does.
        let previousLaunch = FileBrowserPreferences.applicationDefaults(arguments: ["Zforge", argument], environment: [:])
        #expect(previousLaunch !== UserDefaults.standard)
        FileBrowserPreferences(defaults: previousLaunch).viewMode = otherMode
        #expect(FileBrowserPreferences(defaults: previousLaunch).viewMode == otherMode)

        // The next launch opens with the default mode, and the user's preference never changed.
        let nextLaunch = FileBrowserPreferences.applicationDefaults(arguments: ["Zforge", argument], environment: [:])
        #expect(FileBrowserPreferences(defaults: nextLaunch).viewMode == defaultMode)
        #expect(UserDefaults.standard.object(forKey: Self.viewModeKey) as? String == userValue)
        nextLaunch.removePersistentDomain(forName: FileBrowserPreferences.fixtureDefaultsSuite)
    }

    @Test("A fixture launch that names its suite keeps it across launches, for relaunch tests")
    func namedSuitePersistsAcrossLaunches() throws {
        let suite = "ZforgeFixtureRelaunch-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let environment = ["ZFORGE_UI_PREFERENCES_SUITE": suite]
        let first = FileBrowserPreferences.applicationDefaults(arguments: ["Zforge", "--ui-fixtures"], environment: environment)
        FileBrowserPreferences(defaults: first).viewMode = .columns
        let second = FileBrowserPreferences.applicationDefaults(arguments: ["Zforge", "--ui-fixtures"], environment: environment)
        #expect(second !== UserDefaults.standard)
        #expect(FileBrowserPreferences(defaults: second).viewMode == .columns)
    }
}
