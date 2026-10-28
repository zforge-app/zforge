import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// Offscreen contracts of the Keyboard Shortcuts help window: its search
/// filter in the app language and the documented New Folder with Selection entry.
@Suite("Keyboard shortcut help")
@MainActor
struct KeyboardShortcutHelpTests {
    private func matches(_ query: String, _ language: AppLanguagePreference) -> [(action: String, input: String)] {
        KeyboardShortcutCatalog.sections(matching: query, locale: language.locale)
            .flatMap(\.items).map { ($0.action, $0.input) }
    }

    @Test("An empty query lists every documented shortcut")
    func emptyQuery() {
        let all = KeyboardShortcutCatalog.sections.flatMap(\.items).count
        #expect(KeyboardShortcutCatalog.sections(matching: "  ", locale: AppLanguagePreference.english.locale)
            .flatMap(\.items).count == all)
        #expect(all > 0)
    }

    @Test("Searching Rename keeps Rename and hides New Folder")
    func englishFilter() {
        let result = matches("Rename", .english)
        #expect(result.contains { $0.action == "Rename" && $0.input == "Return" })
        #expect(!result.contains { $0.action == "New Folder" })
    }

    @Test("The Portuguese name of New Folder with Selection finds its ⌃⌥⌘N shortcut")
    func portugueseFolderSelection() {
        let result = matches("Nova Pasta com Seleção", .portugueseBrazil)
        #expect(result.count == 1, "Matches: \(result)")
        #expect(result.first?.action == "New Folder with Selection")
        #expect(result.first?.input == "⌃⌥⌘N")
        // Folding ignores case and diacritics in the app language.
        #expect(matches("nova pasta com selecao", .portugueseBrazil).map(\.input) == ["⌃⌥⌘N"])
        #expect(!matches("Nova Pasta com Seleção", .portugueseBrazil).contains { $0.action == "New Folder" })
    }

    @Test("Portuguese help shows the localized title and the folder selection shortcut")
    func portugueseSnapshot() throws {
        let suite = "ShortcutHelpSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .portugueseBrazil
        ZforgeSnapshot.assert(
            KeyboardShortcutsView(preferences: preferences, searchText: "Nova Pasta com Seleção"),
            size: CGSize(width: 720, height: 520), appearance: .aqua, named: "portuguese-folder-selection"
        )
    }
}
