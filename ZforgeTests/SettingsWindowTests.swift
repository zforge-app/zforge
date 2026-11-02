import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// The Settings window in two columns, as System Settings (ZF-58): the sidebar of panes, the
/// remembered pane, what each pane holds and how it looks. Hosted offscreen; the real clicks on
/// the sidebar and on profile rows are proven by `SettingsUITests`.
@Suite("Settings window (ZF-58)")
@MainActor
struct SettingsWindowTests {
    @Test("The sidebar lists every pane once, in three groups, each with its symbol")
    func sidebarGroups() {
        #expect(SettingsPane.groups == [[.general, .viewOptions, .sidebar], [.compression, .previews], [.automation]])
        #expect(SettingsPane.groups.flatMap { $0 } == SettingsPane.allCases)
        for pane in SettingsPane.allCases {
            #expect(NSImage(systemSymbolName: pane.systemImage, accessibilityDescription: nil) != nil, "\(pane)")
        }
        let english = Locale(identifier: "en")
        #expect(SettingsPane.allCases.map { $0.title(locale: english) } == [
            "General", "View Options", "Sidebar", "Compression", "Previews in Archives", "Automation",
        ])
    }

    @Test("Each pane's tile has its own colour, lighter at the top, and the same in light and dark appearance")
    func tileColors() throws {
        func components(_ color: Color, _ appearance: NSAppearance.Name) throws -> [CGFloat] {
            var result: [CGFloat] = []
            try #require(NSAppearance(named: appearance)).performAsCurrentDrawingAppearance {
                let resolved = NSColor(color).usingColorSpace(.sRGB)
                result = [resolved?.redComponent, resolved?.greenComponent, resolved?.blueComponent].compactMap { $0 }
            }
            return result
        }
        var bottoms: [[CGFloat]] = []
        for pane in SettingsPane.allCases {
            let (top, bottom) = pane.tileColors
            let light = try components(bottom, .aqua)
            #expect(light.count == 3)
            #expect(try components(bottom, .darkAqua) == light, "\(pane) keeps its tile colour in dark appearance")
            #expect(try components(top, .aqua).reduce(0, +) > light.reduce(0, +), "\(pane) is lighter at the top")
            bottoms.append(light)
        }
        #expect(Set(bottoms.map { $0.map { Int($0 * 255) } }).count == SettingsPane.allCases.count, "Every pane has its own colour")
    }

    /// The pane snapshots show the form starting with the pane's own first section.
    @Test("A pane shows no header repeating its sidebar row; the window title names it")
    func paneHasNoHeader() {
        let form = String(reflecting: SettingsPaneForm<Text>.Body.self)
        #expect(!form.contains("SettingsIconTile") && !form.contains("VStack"), "\(form)")
        #expect(form.contains("SwiftUI.Form<SwiftUI.Text>"), "The form holds only the pane's content: \(form)")
    }

    @Test("Every pane title and description is translated in every language")
    func paneStringsAreTranslated() {
        let english = Locale(identifier: "en")
        for language in AppLanguagePreference.allCases where language != .system && language != .english {
            for pane in SettingsPane.allCases {
                let title = pane.title(locale: language.locale)
                let description = AppLocalization.string(pane.descriptionKey, locale: language.locale)
                #expect(!title.isEmpty, "\(language) \(pane)")
                #expect(description != AppLocalization.string(pane.descriptionKey, locale: english), "\(language) \(pane)")
            }
        }
        let portuguese = AppLanguagePreference.portugueseBrazil.locale
        #expect(SettingsPane.general.title(locale: portuguese) == "Geral")
        #expect(SettingsPane.viewOptions.title(locale: portuguese) == "Opções de visualização")
        #expect(AppLocalization.string("Profiles", locale: portuguese) == "Perfis")
        #expect(AppLocalization.string("Add Profile", locale: portuguese) == "Adicionar perfil")
        #expect(AppLocalization.string("Duplicate Profile", locale: portuguese) == "Duplicar perfil")
        #expect(AppLocalization.string("Delete “\("Auto")”?", locale: portuguese) == "Excluir “Auto”?")
        #expect(AppLocalization.string("Archives created with this profile are not affected.", locale: portuguese)
            == "Archives criados com este perfil não são afetados.")
        let german = AppLanguagePreference.german.locale
        #expect(SettingsPane.general.title(locale: german) == "Allgemein")
        #expect(AppLocalization.string("Delete “\("Auto")”?", locale: german) == "„Auto“ löschen?")
    }

    @Test("Settings opens on General at first, then on the pane chosen last")
    func paneIsRemembered() throws {
        let suite = "ZforgeTestSuite.SettingsPane-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        #expect(FileBrowserPreferences(defaults: defaults).settingsPane == .general)
        FileBrowserPreferences(defaults: defaults).settingsPane = .compression
        #expect(FileBrowserPreferences(defaults: defaults).settingsPane == .compression)
        defaults.set("archiveNavigation", forKey: "settings.selectedPane")
        #expect(FileBrowserPreferences(defaults: defaults).settingsPane == .general, "An unknown pane falls back to General")
    }

    @Test("Each sidebar item shows its own pane, with the sections that pane holds")
    func paneContents() {
        let panes = String(reflecting: SettingsPaneView.Body.self)
        for name in ["GeneralSettingsPane", "ViewOptionsSettingsPane", "SidebarSettingsPane",
                     "CompressionSettingsPane", "PreviewsSettingsPane", "AutomationSettingsPane"] {
            #expect(panes.contains(name), "\(name) in \(panes)")
        }
        let general = String(reflecting: GeneralSettingsPane.Body.self)
        #expect(general.contains("AppLanguagePreference") && general.contains("FinderExtensionSettingsSection"), "\(general)")
        let view = String(reflecting: ViewOptionsSettingsPane.Body.self)
        #expect(view.contains("BrowserViewMode") && view.contains("BrowserListColumn"), "\(view)")
        #expect(!view.contains("FinderExtensionSettingsSection"))
        #expect(String(reflecting: SidebarSettingsPane.Body.self).contains("SidebarSettingsSection"))
        #expect(String(reflecting: CompressionSettingsPane.Body.self).contains("CompressionSettingsSection"))
        #expect(String(reflecting: PreviewsSettingsPane.Body.self).contains("ArchivePreviewSettingsSection"))
        #expect(String(reflecting: AutomationSettingsPane.Body.self).contains("AutomationSettingsSection"))
    }

    @Test("Choosing a pane remembers it and leaves an open profile page; the window follows the pane")
    func choosingAPane() async throws {
        let fixture = try SettingsWindowFixture(pane: .general)
        defer { fixture.close() }
        let navigation = SettingsNavigation(preferences: fixture.preferences)
        let id = fixture.preferences.defaultCompressionProfileID
        navigation.choose(.compression)
        navigation.openProfile(id)
        #expect(navigation.path == [CompressionProfileRoute(id: id)])
        navigation.choose(.compression)
        #expect(navigation.path.count == 1, "Choosing the pane already shown keeps its page")
        let copy = try #require(fixture.preferences.duplicateCompressionProfile(id))
        navigation.showProfile(copy)
        #expect(navigation.path == [CompressionProfileRoute(id: copy)], "The copy replaces the original page")
        navigation.choose(.automation)
        #expect(navigation.path.isEmpty)
        #expect(fixture.preferences.settingsPane == .automation)
        navigation.choose(.compression)
        navigation.openProfile(id)
        navigation.closeProfile()
        #expect(navigation.path.isEmpty)

        // The open window shows the remembered pane: its title is the pane's.
        try await fixture.waitUntil("the window shows Compression") { fixture.window.title == "Compression" }
        fixture.preferences.settingsPane = .viewOptions
        try await fixture.waitUntil("the window shows View Options") { fixture.window.title == "View Options" }
        let sidebar = try #require(fixture.host.settingsDescendants(of: NSTableView.self).first)
        #expect(sidebar.numberOfRows >= SettingsPane.allCases.count, "The sidebar lists every pane")
    }

    /// D-75: the Settings scene's preference toolbar centred a profile page's back button on a
    /// second row under the title.
    @Test("The window uses the unified toolbar, so the back button sits beside the title")
    func unifiedToolbar() async throws {
        let fixture = try SettingsWindowFixture(pane: .compression, toolbarStyle: .preference)
        defer { fixture.close() }
        try await fixture.waitUntil("the toolbar is unified") { fixture.window.toolbarStyle == .unified }
    }

    @Test("The detail column keeps the Settings form width, so the size sliders keep their layout")
    func detailWidthMatchesTheForm() async throws {
        let fixture = try SettingsWindowFixture(pane: .previews)
        defer { fixture.close() }
        try await fixture.waitUntil("the preview sliders appear") {
            !fixture.host.settingsDescendants(of: ScaleSliderView.self).isEmpty
        }
        let inWindow = try #require(fixture.host.settingsDescendants(of: ScaleSliderView.self).first)

        // The same section in the 568 pt form the single-column Settings window had.
        let form = Form { ArchivePreviewSettingsSection(preferences: fixture.preferences) }.formStyle(.grouped)
        let size = CGSize(width: 568, height: 400)
        let reference = NSHostingView(rootView: form.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = reference
        reference.layoutSubtreeIfNeeded()
        let standalone = try #require(reference.settingsDescendants(of: ScaleSliderView.self).first)
        #expect(abs(inWindow.slider.frame.width - standalone.slider.frame.width) <= 1,
                "Slider width \(inWindow.slider.frame.width) in the pane, \(standalone.slider.frame.width) in the form")
    }

    // General, Sidebar and Automation show this Mac's state (the Finder extension, the computer
    // and home names, automation grants), so their look is checked in the real-run review.
    @Test("Snapshot: each pane", arguments: [
        (SettingsPane.viewOptions, "light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        (.compression, "light", .aqua, .english),
        (.previews, "light", .aqua, .english),
        (.compression, "dark", .darkAqua, .english),
        (.previews, "dark", .darkAqua, .english),
        (.viewOptions, "dark-de", .darkAqua, .german),
        (.compression, "light-pt-BR", .aqua, .portugueseBrazil),
    ])
    func paneSnapshot(pane: SettingsPane, name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) throws {
        // The pane as the detail column shows it. The sidebar's glass material is drawn by the
        // window server, so its look is reviewed in a real run (REGRESSION-COVERAGE, ZF-58).
        let suite = "ZforgeTestSuite.SettingsPaneSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        let view = NavigationStack { SettingsPaneView(pane: pane, preferences: preferences, openProfile: { _ in }) }
            .environment(\.locale, language.locale)
        let size = CGSize(width: SettingsLayout.detailWidth, height: SettingsLayout.height)
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        ZforgeSnapshot.assert(host, appearance: appearance, named: "\(pane.rawValue)-\(name)")
    }
}

/// The production Settings view in an offscreen window over isolated preferences.
@MainActor
final class SettingsWindowFixture {
    static let size = CGSize(width: SettingsLayout.sidebarWidth + SettingsLayout.detailWidth, height: SettingsLayout.height)
    let suite = "ZforgeTestSuite.SettingsWindow-\(UUID().uuidString)"
    let defaults: UserDefaults
    let preferences: FileBrowserPreferences
    let window: NSWindow
    let host: NSView

    init(pane: SettingsPane, language: AppLanguagePreference = .english,
         toolbarStyle: NSWindow.ToolbarStyle = .automatic) throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        preferences.settingsPane = pane
        let host = NSHostingView(rootView: ZforgeSettingsView(preferences: preferences))
        window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size),
                          styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.toolbarStyle = toolbarStyle
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: Self.size)
        host.layoutSubtreeIfNeeded()
        self.host = host
    }

    func close() {
        window.close()
        defaults.removeTestSuite(named: suite)
    }

    func waitUntil(_ description: String, _ condition: () -> Bool) async throws {
        for _ in 0..<400 where !condition() {
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition(), "Timed out waiting until \(description)")
        if !condition() { throw CancellationError() }
    }
}

extension NSView {
    func settingsDescendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { child -> [T] in ((child as? T).map { [$0] } ?? []) + child.settingsDescendants(of: type) }
    }
}
