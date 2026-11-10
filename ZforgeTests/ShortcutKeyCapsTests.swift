import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// The notation of the shortcut reference parsed into key caps, its spoken form, and the
/// category filter of the Keyboard Shortcuts window.
@Suite("Shortcut key caps and categories")
@MainActor
struct ShortcutKeyCapsTests {
    private func glyphs(_ texts: [String]) -> [ShortcutKey] { texts.map { ShortcutKey(text: $0, kind: .glyph) } }

    @Test("Each glyph of a modified shortcut is its own cap")
    func glyphSplitting() {
        #expect(ShortcutNotation.parse("⌘Z") == [ShortcutCombination(keys: glyphs(["⌘", "Z"]), action: nil)])
        #expect(ShortcutNotation.parse("⌃⌥⌘N").first?.keys == glyphs(["⌃", "⌥", "⌘", "N"]))
        #expect(ShortcutNotation.parse("⌥⌘⌫").first?.keys == glyphs(["⌥", "⌘", "⌫"]))
        #expect(ShortcutNotation.parse("⌘[").first?.keys == glyphs(["⌘", "["]))
        #expect(ShortcutNotation.parse("⌘−").first?.keys == glyphs(["⌘", "−"]))
        #expect(ShortcutNotation.parse("⇧⌘.").first?.keys == glyphs(["⇧", "⌘", "."]))
    }

    @Test("A word key is one wider cap")
    func wordKeys() {
        #expect(ShortcutNotation.parse("Return") == [ShortcutCombination(keys: [ShortcutKey(text: "Return", kind: .word)], action: nil)])
        #expect(ShortcutNotation.parse("Space").first?.keys == [ShortcutKey(text: "Space", kind: .word)])
    }

    @Test("Alternatives split on the bar and keep their own keys")
    func alternatives() {
        let zoomIn = ShortcutNotation.parse("⌘+|⌘=")
        #expect(zoomIn.map(\.keys) == [glyphs(["⌘", "+"]), glyphs(["⌘", "="])])
        let quickLook = ShortcutNotation.parse("Space|⌘Y")
        #expect(quickLook.map(\.keys) == [[ShortcutKey(text: "Space", kind: .word)], glyphs(["⌘", "Y"])])
        #expect(quickLook.allSatisfy { $0.action == nil })
    }

    @Test("A pointer gesture follows the modifier caps and is not a cap")
    func mouseActions() {
        let expected: [(String, [String], String)] = [
            ("⌘ + double-click", ["⌘"], "double-click"),
            ("⌘ + drag", ["⌘"], "drag"),
            ("⌥⌘ + drag", ["⌥", "⌘"], "drag"),
            ("⌥ + click disclosure", ["⌥"], "click disclosure"),
            ("⌘ + click window title", ["⌘"], "click window title")
        ]
        for (input, keys, action) in expected {
            #expect(ShortcutNotation.parse(input) == [ShortcutCombination(keys: glyphs(keys), action: action)], "\(input)")
        }
    }

    @Test("Every catalog shortcut parses into caps, and only mouse entries carry a gesture")
    func wholeCatalog() {
        for section in KeyboardShortcutCatalog.sections {
            for item in section.items {
                let combinations = ShortcutNotation.parse(item.input)
                #expect(!combinations.isEmpty && combinations.allSatisfy { !$0.keys.isEmpty }, "\(item.input)")
                #expect(combinations.contains { $0.action != nil } == (section.id == "mouse"), "\(item.input)")
            }
        }
    }

    @Test("VoiceOver hears modifiers and gestures spelled out in the app language")
    func spokenForm() {
        let english = AppLanguagePreference.english.locale
        #expect(ShortcutNotation.spokenDescription(of: "⌘Z", locale: english) == "Command Z")
        #expect(ShortcutNotation.spokenDescription(of: "⇧⌘N", locale: english) == "Shift Command N")
        #expect(ShortcutNotation.spokenDescription(of: "⌃⌥⌘N", locale: english) == "Control Option Command N")
        #expect(ShortcutNotation.spokenDescription(of: "⌥⌘⌫", locale: english) == "Option Command Delete")
        #expect(ShortcutNotation.spokenDescription(of: "⌘↑", locale: english) == "Command Up Arrow")
        #expect(ShortcutNotation.spokenDescription(of: "Space|⌘Y", locale: english) == "Space or Command Y")
        #expect(ShortcutNotation.spokenDescription(of: "⌥⌘ + drag", locale: english) == "Option Command drag")
        let german = AppLanguagePreference.german.locale
        #expect(ShortcutNotation.spokenDescription(of: "⇧⌘N", locale: german) == "Umschalt Befehl N")
        #expect(ShortcutNotation.spokenDescription(of: "Space|⌘Y", locale: german) == "Leertaste oder Befehl Y")
        #expect(ShortcutNotation.spokenDescription(of: "⌘ + drag", locale: german) == "Befehl Ziehen")
    }

    @Test("All Shortcuts lists every section; a category lists only its own")
    func categoryFiltering() {
        let english = AppLanguagePreference.english.locale
        let all = KeyboardShortcutCatalog.sections(in: .all, matching: "", locale: english)
        #expect(all.map(\.id) == KeyboardShortcutCatalog.sections.map(\.id))
        for section in KeyboardShortcutCatalog.sections {
            let only = KeyboardShortcutCatalog.sections(in: .section(section.id), matching: "", locale: english)
            #expect(only.map(\.id) == [section.id])
            #expect(only.first?.items.count == section.items.count)
            #expect(KeyboardShortcutCategory.section(section.id).itemCount == section.items.count)
        }
        #expect(KeyboardShortcutCategory.all.itemCount == KeyboardShortcutCatalog.sections.flatMap(\.items).count)
    }

    @Test("Search filters inside the selected category and counts stay the catalog totals")
    func searchWithinCategory() {
        let english = AppLanguagePreference.english.locale
        let everywhere = KeyboardShortcutCatalog.sections(in: .all, matching: "Open", locale: english)
        #expect(Set(everywhere.map(\.id)) == ["go", "navigation", "mouse"])
        // “Open” appears in Navigation (⌘↓); inside View the same query finds nothing.
        #expect(KeyboardShortcutCatalog.sections(in: .section("view"), matching: "Open", locale: english).isEmpty)
        #expect(KeyboardShortcutCatalog.sections(in: .section("navigation"), matching: "Open", locale: english)
            .flatMap(\.items).map(\.action) == ["Open"])
        #expect(KeyboardShortcutCatalog.sections(in: .section("navigation"), matching: "zzz", locale: english).isEmpty)
        #expect(KeyboardShortcutCategory.section("navigation").itemCount == 4)
    }

    @Test("Every category has a symbol, a title key and distinct tile colours")
    func categoryPresentation() {
        let categories: [KeyboardShortcutCategory] = [.all] + KeyboardShortcutCatalog.sections.map { .section($0.id) }
        for category in categories {
            #expect(NSImage(systemSymbolName: category.systemImage, accessibilityDescription: nil) != nil, "\(category.id)")
            #expect(!category.title(locale: AppLanguagePreference.english.locale).isEmpty)
        }
        #expect(KeyboardShortcutCategory.all.title(locale: AppLanguagePreference.english.locale) == "All Shortcuts")
        #expect(KeyboardShortcutCategory.all.title(locale: AppLanguagePreference.portugueseBrazil.locale) == "Todos os Atalhos")
        #expect(KeyboardShortcutCategory.section("mouse").title(locale: AppLanguagePreference.english.locale) == "Mouse and Drag")
    }
}

/// The window as a plain two-column layout for snapshots. `NavigationSplitView` and the sidebar
/// `List` do not draw offscreen (the sidebar material and list are window-server backed), so the
/// snapshots stack the real category rows in a padded column with a drawn selection, beside the
/// real detail view under a title band that stands in for the toolbar. The real window's sidebar,
/// search field and title bar still need a look in a real run.
private struct KeyboardShortcutsSnapshotWindow: View {
    let preferences: FileBrowserPreferences
    var category: KeyboardShortcutCategory = .all
    var searchText = ""

    private var sidebar: some View {
        VStack(spacing: 1) {
            Spacer().frame(height: 52)
            row(.all)
            Divider().padding(.vertical, 5).padding(.horizontal, 8)
            ForEach(KeyboardShortcutCatalog.sections) { row(.section($0.id)) }
            Spacer()
        }
        .padding(.horizontal, 10)
    }

    private func row(_ row: KeyboardShortcutCategory) -> some View {
        KeyboardShortcutCategoryRow(category: row)
            .padding(.horizontal, 8)
            .frame(minHeight: 28)
            .background(row == category ? Color.accentColor.opacity(0.9) : .clear, in: RoundedRectangle(cornerRadius: 6))
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: KeyboardShortcutsLayout.sidebarWidth)
                .background(Color(nsColor: .underPageBackgroundColor))
            Divider()
            VStack(spacing: 0) {
                Text(verbatim: category.title(locale: preferences.language.locale))
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, KeyboardShortcutsLayout.contentMargin)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                Divider()
                KeyboardShortcutsDetail(category: category, searchText: searchText, locale: preferences.language.locale)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, preferences.language.locale)
    }
}

/// Appearance contracts of the redesigned Keyboard Shortcuts window (default size, minimum width,
/// light and dark, one non-English language), recorded with `ZforgeSnapshot`.
@Suite("Keyboard shortcuts window snapshots")
@MainActor
struct KeyboardShortcutsSnapshotTests {
    private func preferences(_ language: AppLanguagePreference) throws -> (FileBrowserPreferences, () -> Void) {
        let suite = "ZforgeTestSuite.ShortcutsWindowSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        return (preferences, { defaults.removeTestSuite(named: suite) })
    }

    private let defaultSize = CGSize(width: KeyboardShortcutsLayout.defaultWidth, height: KeyboardShortcutsLayout.defaultHeight)

    @Test("All Shortcuts at the default size, light and dark")
    func allShortcuts() throws {
        let (preferences, cleanup) = try preferences(.english)
        defer { cleanup() }
        for (name, appearance) in ZforgeSnapshot.appearances {
            ZforgeSnapshot.assert(KeyboardShortcutsSnapshotWindow(preferences: preferences), size: defaultSize, appearance: appearance, named: name)
        }
    }

    @Test("A single category shows only its group without a header, light and dark")
    func singleCategory() throws {
        let (preferences, cleanup) = try preferences(.english)
        defer { cleanup() }
        for (name, appearance) in ZforgeSnapshot.appearances {
            ZforgeSnapshot.assert(
                KeyboardShortcutsSnapshotWindow(preferences: preferences, category: .section("view")),
                size: defaultSize, appearance: appearance, named: name
            )
        }
    }

    @Test("The mouse category shows modifier caps followed by the gesture")
    func mouseCategory() throws {
        let (preferences, cleanup) = try preferences(.english)
        defer { cleanup() }
        for (name, appearance) in ZforgeSnapshot.appearances {
            ZforgeSnapshot.assert(
                KeyboardShortcutsSnapshotWindow(preferences: preferences, category: .section("mouse")),
                size: defaultSize, appearance: appearance, named: name
            )
        }
    }

    @Test("German at the minimum width does not clip the sidebar or the rows")
    func germanNarrow() throws {
        let (preferences, cleanup) = try preferences(.german)
        defer { cleanup() }
        let size = CGSize(width: KeyboardShortcutsLayout.minimumWidth, height: 520)
        ZforgeSnapshot.assert(KeyboardShortcutsSnapshotWindow(preferences: preferences), size: size, appearance: .aqua, named: "light")
        ZforgeSnapshot.assert(
            KeyboardShortcutsSnapshotWindow(preferences: preferences, category: .section("mouse")),
            size: size, appearance: .darkAqua, named: "mouse-dark"
        )
    }

    @Test("A search without matches shows No Results")
    func noResults() throws {
        let (preferences, cleanup) = try preferences(.english)
        defer { cleanup() }
        ZforgeSnapshot.assert(
            KeyboardShortcutsSnapshotWindow(preferences: preferences, searchText: "zzzz"),
            size: defaultSize, appearance: .aqua, named: "light"
        )
    }
}
