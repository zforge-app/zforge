import Foundation
import Testing
@testable import Zforge

@Suite("Window view mode isolation")
@MainActor
struct WindowViewModeTests {
    @Test("All four modes remain independent with shared preferences")
    func independentModes() throws {
        let suite = "ZforgeWindowModes-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .icons
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }

        for mode in BrowserViewMode.allCases {
            first.viewMode = mode
            #expect(second.viewMode == .icons)
            second.viewMode = .gallery
            #expect(first.viewMode == mode)
            second.viewMode = .icons
            #expect(preferences.viewMode == .icons)
            #expect(FileBrowserPreferences(defaults: defaults).viewMode == .icons)
        }
    }

    @Test("Default View affects future windows and survives preference reload")
    func defaultAppliesToFutureWindows() throws {
        let suite = "ZforgeWindowDefault-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        let existing = makeState(preferences)
        defer { existing.close() }
        #expect(existing.viewMode == .list)

        preferences.viewMode = .columns
        #expect(existing.viewMode == .list)
        let newWindow = makeState(preferences)
        let reopened = makeState(FileBrowserPreferences(defaults: defaults))
        defer { newWindow.close(); reopened.close() }
        #expect(newWindow.viewMode == .columns)
        #expect(reopened.viewMode == .columns)

        // Other application preferences retain their existing shared behavior.
        preferences.showHiddenFiles.toggle()
        #expect(existing.preferences.showHiddenFiles == newWindow.preferences.showHiddenFiles)
    }

    @Test("Preview lookup uses each window's active mode")
    func previewUsesLocalMode() throws {
        let suite = "ZforgeWindowPreview-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.setPreviewVisible(false, in: .list)
        preferences.setPreviewVisible(true, in: .icons)
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }
        first.viewMode = .list
        second.viewMode = .icons
        #expect(!first.previewVisible)
        #expect(second.previewVisible)
        first.previewVisible = true
        #expect(preferences.previewVisible(in: .list))
        #expect(second.previewVisible)
    }

    private func makeState(_ preferences: FileBrowserPreferences) -> FileBrowserState {
        FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
    }
}
