import Foundation
import Testing
@testable import Zforge

@Suite("Icon preview preferences")
@MainActor
struct IconPreviewPreferencesTests {
    @Test("Icon previews are enabled when no preference was saved")
    func enabledByDefault() throws {
        let suite = "ZforgeIconPreviewDefault-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.showIconPreviews)
        #expect(FileBrowserPreferences(defaults: defaults).showIconPreviews)
    }

    @Test("Both enabled and disabled choices survive preference reload", arguments: [false, true])
    func savedChoiceIsRestored(isEnabled: Bool) throws {
        let suite = "ZforgeIconPreviewPersistence-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.showIconPreviews = isEnabled

        let restored = FileBrowserPreferences(defaults: defaults)
        #expect(restored.showIconPreviews == isEnabled)
        restored.showIconPreviews.toggle()
        #expect(FileBrowserPreferences(defaults: defaults).showIconPreviews == !isEnabled)
    }

    @Test("Icon previews remain independent from preview panels in every mode")
    func independentFromPreviewPanels() throws {
        let suite = "ZforgeIconPreviewPanels-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        for mode in BrowserViewMode.allCases {
            preferences.setPreviewVisible(false, in: mode)
        }
        #expect(preferences.showIconPreviews)

        preferences.showIconPreviews = false
        for mode in BrowserViewMode.allCases {
            #expect(!preferences.previewVisible(in: mode))
            preferences.setPreviewVisible(true, in: mode)
            #expect(!preferences.showIconPreviews)
        }

        preferences.showIconPreviews = true
        let restored = FileBrowserPreferences(defaults: defaults)
        #expect(restored.showIconPreviews)
        for mode in BrowserViewMode.allCases {
            #expect(restored.previewVisible(in: mode))
        }
    }

    @Test("Windows sharing application preferences observe icon preview changes")
    func sharedAcrossWindows() throws {
        let suite = "ZforgeIconPreviewWindows-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = FileBrowserPreferences(defaults: defaults)
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }

        first.preferences.showIconPreviews = false
        #expect(!second.preferences.showIconPreviews)
        second.preferences.showIconPreviews = true
        #expect(first.preferences.showIconPreviews)
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
