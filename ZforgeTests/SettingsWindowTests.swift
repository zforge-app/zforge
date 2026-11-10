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
    /// ZF-62 removed the three sidebar groups (browsing, archives, system integration): they
    /// separated panes by a gap that carried no meaning for the user. The order is unchanged.
    @Test("The sidebar is one flat list of every pane once, each with its symbol")
    func sidebarIsFlat() {
        #expect(SettingsPane.allCases == [.general, .viewOptions, .sidebar, .compression, .previews, .automation])
        for pane in SettingsPane.allCases {
            #expect(NSImage(systemSymbolName: pane.systemImage, accessibilityDescription: nil) != nil, "\(pane)")
        }
        let english = Locale(identifier: "en")
        #expect(SettingsPane.allCases.map { $0.title(locale: english) } == [
            "General", "View Options", "Sidebar", "Compression", "Previews in Archives", "Automation",
        ])
    }

    /// ZF-62 replaced the fixed gradient palette, the same in both appearances, with the macOS
    /// system colours, which adapt to light and dark appearance.
    /// ZF-62: uniform 28 pt rows with a 13 pt title; a title that does not fit one line wraps to a
    /// second one, never truncates, in every language.
    @Test("Every pane title fits the sidebar row in at most two lines, in every language")
    func sidebarTitlesDoNotTruncate() {
        let textWidth = SettingsLayout.sidebarTitleWidth
        for language in AppLanguagePreference.allCases where language != .system {
            for pane in SettingsPane.allCases {
                let title = pane.title(locale: language.locale)
                func height(lineLimit: Int?) -> CGFloat {
                    let text = Text(verbatim: title).font(.system(size: 13)).lineLimit(lineLimit).frame(width: textWidth).fixedSize(horizontal: false, vertical: true)
                    return NSHostingView(rootView: text).fittingSize.height
                }
                let natural = height(lineLimit: nil)
                #expect(height(lineLimit: 2) >= natural - 0.5, "\(language) “\(title)” needs more than two lines in \(textWidth) pt")
            }
        }
    }

    @Test("The sidebar shows the six panes as uniform 28 pt rows without group gaps")
    func sidebarRows() async throws {
        let fixture = try SettingsWindowFixture(pane: .viewOptions)
        defer { fixture.close() }
        let table = try #require(fixture.host.settingsDescendants(of: NSTableView.self).first)
        try await fixture.waitUntil("the rows appear") { table.numberOfRows >= SettingsPane.allCases.count }
        #expect(table.numberOfRows == SettingsPane.allCases.count, "One row per pane: no group headers or gaps")
        // English titles all fit one line: their rows are one height, 28 pt.
        let rowHeights = (0..<table.numberOfRows).map { table.rect(ofRow: $0).height }
        for (pane, height) in zip(SettingsPane.allCases, rowHeights) where pane != .previews {
            #expect(abs(height - SettingsLayout.sidebarRowHeight) <= 1, "\(pane) row is \(height) pt")
        }
        for row in 1..<table.numberOfRows {
            let gap = table.rect(ofRow: row).minY - table.rect(ofRow: row - 1).maxY
            #expect(abs(gap) <= 4, "Gap before row \(row): \(gap)")
        }
    }

    @Test("Each pane's tile is a distinct macOS system colour, lighter only at the top")
    func tileColors() throws {
        #expect(SettingsPane.general.tileColor == .gray)
        #expect(SettingsPane.viewOptions.tileColor == .blue)
        #expect(SettingsPane.sidebar.tileColor == .teal)
        #expect(SettingsPane.compression.tileColor == .orange)
        #expect(SettingsPane.previews.tileColor == .green)
        #expect(SettingsPane.automation.tileColor == .indigo)
        func components(_ color: Color, _ appearance: NSAppearance.Name) throws -> [CGFloat] {
            var result: [CGFloat] = []
            try #require(NSAppearance(named: appearance)).performAsCurrentDrawingAppearance {
                let resolved = NSColor(color).usingColorSpace(.sRGB)
                result = [resolved?.redComponent, resolved?.greenComponent, resolved?.blueComponent].compactMap { $0 }
            }
            return result
        }
        var bottoms: [[Int]] = []
        for pane in SettingsPane.allCases {
            let (top, bottom) = pane.tileColors
            let light = try components(bottom, .aqua)
            #expect(light.count == 3)
            #expect(try components(top, .aqua).reduce(0, +) > light.reduce(0, +), "\(pane) is lighter at the top")
            let topDelta = zip(try components(top, .aqua), light).map { $0 - $1 }.max() ?? 1
            #expect(topDelta < 0.4, "\(pane) is only slightly lighter at the top")
            bottoms.append(light.map { Int($0 * 255) })
        }
        #expect(Set(bottoms).count == SettingsPane.allCases.count, "Every pane has its own colour")
    }

    /// The pane snapshots show the form starting with the pane's own first section.
    @Test("A pane shows no header repeating its sidebar row; the window title names it")
    func paneHasNoHeader() {
        let form = String(reflecting: SettingsPaneForm<Text>.Body.self)
        #expect(!form.contains("SettingsIconTile") && !form.contains("VStack"), "\(form)")
        #expect(form.contains("SettingsPaneColumn<SwiftUI.Text>"), "The column holds only the pane's content: \(form)")
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

    /// ZF-62: the pane title sat in a 32 pt title bar in the small grey window-title style, unlike the
    /// browser window's 52 pt toolbar with its 15 pt semibold title (measured in the offscreen browser
    /// window: toolbar 52 pt, `.SFNS-Semibold` 15 pt, `labelColor`).
    @Test("The title bar is the browser window's 52 pt toolbar with the pane title in its title style")
    func titleBarMatchesTheBrowserToolbar() async throws {
        let fixture = try SettingsWindowFixture(pane: .viewOptions)
        defer { fixture.close() }
        let window = fixture.window
        func titlebar() -> NSView? { window.contentView?.superview?.settingsDescendants(named: "NSTitlebarContainerView").first }
        func title() -> NSTextField? {
            window.contentView?.superview?.settingsDescendants(of: NSTextField.self).first { $0.stringValue == "View Options" }
        }
        func sidebarWidth() -> CGFloat? {
            window.contentView?.superview?.settingsDescendants(named: "NSTitlebarBackgroundView").map(\.frame).filter { $0.minX == 0 }.map(\.width).first
        }
        try await fixture.waitUntil("the toolbar title appears beside a 220 pt sidebar") {
            title() != nil && window.toolbar != nil && sidebarWidth() == SettingsLayout.sidebarWidth
        }
        let bar = try #require(titlebar())
        #expect(abs(bar.frame.height - 52) < 0.5, "Title bar height \(bar.frame.height)")
        let label = try #require(title())
        let font = try #require(label.font)
        #expect(font.pointSize == 15, "Title size \(font.pointSize)")
        #expect(font.fontName.contains("Semibold"), "Title font \(font.fontName)")
        #expect(label.textColor == .labelColor)
        // Leading-aligned with the detail content's 20 pt margin.
        let titleX = label.convert(label.bounds, to: nil).minX
        let expectedX = SettingsLayout.sidebarWidth + SettingsMetrics.margin
        #expect(abs(titleX - expectedX) <= 3, "Title starts at \(titleX), content at \(expectedX)")
        // The traffic lights are centred in the bar.
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            guard let button = window.standardWindowButton(kind) else { continue }
            let centre = button.convert(button.bounds, to: bar).midY
            #expect(abs(centre - bar.bounds.midY) <= 1, "\(kind) centre \(centre) in a bar of \(bar.bounds.height)")
        }
    }

    @Test("The detail column keeps the Settings form width, so the size sliders keep their layout")
    func detailWidthMatchesTheForm() async throws {
        let fixture = try SettingsWindowFixture(pane: .previews)
        defer { fixture.close() }
        try await fixture.waitUntil("the preview sliders appear") {
            !fixture.host.settingsDescendants(of: ScaleSliderView.self).isEmpty
        }
        let inWindow = try #require(fixture.host.settingsDescendants(of: ScaleSliderView.self).first)

        // The 568 pt grouped form the single-column Settings window had gave the slider a 484 pt track;
        // the new pane (20 pt margins, 12 pt row padding, a 10 pt slider inset) keeps that measure
        // (ZF-62 replaced the grouped form this test used as its reference with that measured value).
        #expect(abs(inWindow.slider.frame.width - 484) <= 1, "Slider width \(inWindow.slider.frame.width) in the pane, 484 in the former form")
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
        (.viewOptions, "light-es", .aqua, .spanish),
    ])
    func paneSnapshot(pane: SettingsPane, name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) throws {
        try snapshotPane(named: "\(pane.rawValue)-\(name)", appearance: appearance, language: language, testName: #function) { preferences in
            SettingsPaneView(pane: pane, preferences: preferences, openProfile: { _ in })
        }
    }

    /// The Sidebar pane lists this Mac's name and home folder, so the snapshot fixes both.
    @Test("Snapshot: the Sidebar pane", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        ("dark", .darkAqua, .english),
        ("light-es", .aqua, .spanish),
    ])
    func sidebarPaneSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) throws {
        try snapshotPane(named: "sidebar-\(name)", appearance: appearance, language: language, testName: #function) { preferences in
            SidebarSettingsPane(preferences: preferences, computerName: "Studio Mac", homeName: "felipe")
        }
    }

    /// The pane as the detail column shows it. The sidebar's glass material is drawn by the
    /// window server, so its look is reviewed in a real run (REGRESSION-COVERAGE, ZF-58).
    private func snapshotPane<Pane: View>(
        named name: String, appearance: NSAppearance.Name, language: AppLanguagePreference,
        testName: String, pane: (FileBrowserPreferences) -> Pane
    ) throws {
        let suite = "ZforgeTestSuite.SettingsPaneSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        let view = NavigationStack { pane(preferences) }
            .background { Color(nsColor: .windowBackgroundColor).ignoresSafeArea() }
            .environment(\.locale, language.locale)
        let size = CGSize(width: SettingsLayout.detailWidth, height: SettingsLayout.height)
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        ZforgeSnapshot.assert(host, appearance: appearance, named: name, testName: testName)
    }
}

/// The sidebar's tiles and titles as the rows draw them. The real sidebar's glass and selection are
/// drawn by the window server (an offscreen window shows them wrongly), so the rows are hosted in a
/// plain 204 pt column with the chosen row drawn as an accent capsule.
extension SettingsWindowTests {
    @Test("Snapshot: the sidebar rows", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        ("dark", .darkAqua, .english),
        ("light-es", .aqua, .spanish),
        ("dark-de", .darkAqua, .german),
    ])
    func sidebarRowsSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) {
        let rows = VStack(spacing: 0) {
            ForEach(SettingsPane.allCases) { pane in
                SettingsSidebarRow(pane: pane)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .foregroundStyle(pane == .viewOptions ? Color.white : Color.primary)
                    .background(pane == .viewOptions ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, language.locale)
        .background(Color(nsColor: .windowBackgroundColor))
        ZforgeSnapshot.assert(rows, size: CGSize(width: 224, height: 240), appearance: appearance, named: name)
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
        // As the browser window is hosted: SwiftUI installs the window toolbar only this way.
        window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size),
                          styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.toolbarStyle = toolbarStyle
        window.contentViewController = NSHostingController(rootView: ZforgeSettingsView(preferences: preferences))
        window.setContentSize(Self.size)
        let host = try #require(window.contentView)
        host.layoutSubtreeIfNeeded()
        self.host = host
    }

    func close() {
        window.close()
        window.contentViewController = nil
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
    func settingsDescendants(named className: String) -> [NSView] {
        subviews.flatMap { child -> [NSView] in
            (String(describing: type(of: child)) == className ? [child] : []) + child.settingsDescendants(named: className)
        }
    }

    func settingsDescendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { child -> [T] in ((child as? T).map { [$0] } ?? []) + child.settingsDescendants(of: type) }
    }
}
