import AppKit
import Foundation
import Testing
@testable import Zforge

/// Offscreen characterization of the File menu built by `BrowserCommands`:
/// the native menu structure AppKit presents, and the focused browser state
/// that drives each command's availability and action.
@Suite("File menu commands", .serialized)
@MainActor
struct FileMenuCommandTests {
    @Test("File Open is unique and immediately precedes Open with in the native File menu")
    func openPrecedesOpenWith() async throws {
        let items = try await fileMenuItems()
        let open = AppLocalization.string("Open")
        let openWith = AppLocalization.string("Open with")
        let titles = items.map(\.title)
        #expect(titles.filter { $0 == open }.count == 1, "Unique File Open, entries: \(titles)")
        #expect(titles.filter { $0 == openWith }.count == 1, "Unique File Open with, entries: \(titles)")
        let openIndex = try #require(titles.firstIndex(of: open))
        let openWithIndex = try #require(titles.firstIndex(of: openWith))
        #expect(openIndex + 1 == openWithIndex, "File Open must immediately precede Open with, entries: \(titles)")
        #expect(!items[openIndex].isAlternate)
        #expect(!items[openWithIndex].isAlternate)
        #expect(items[openWithIndex].submenu != nil, "Open with must present a submenu of applications")
    }

    @Test("Option replaces New Folder with New Folder with Selection without Control in its visibility condition")
    func folderSelectionIsTheOptionAlternate() async throws {
        let items = try await fileMenuItems()
        let titles = items.map(\.title)
        let index = try #require(titles.firstIndex(of: AppLocalization.string("New Folder")), "Entries: \(titles)")
        let newFolder = items[index]
        #expect(!newFolder.isAlternate)
        #expect(newFolder.keyEquivalent == "n")
        #expect(newFolder.keyEquivalentModifierMask == [.command, .shift])

        try #require(items.indices.contains(index + 1))
        let alternate = items[index + 1]
        #expect(alternate.title == AppLocalization.string("New Folder with Selection"))
        #expect(alternate.isAlternate, "AppKit shows the item only while Option is held")
        // AppKit pairs an alternate with the preceding item when the key
        // equivalents match and only the modifier mask differs.
        #expect(alternate.keyEquivalent == newFolder.keyEquivalent)
        #expect(alternate.keyEquivalentModifierMask == [.command, .shift, .option])
        #expect(!alternate.keyEquivalentModifierMask.contains(.control),
                "Control would change AppKit's visibility condition for the Option alternate")
        #expect(titles.filter { $0 == alternate.title }.count == 1)
    }

    @Test("Option replaces Open with with Always open with")
    func alwaysOpenWithIsTheOptionAlternate() async throws {
        let items = try await fileMenuItems()
        let titles = items.map(\.title)
        let index = try #require(titles.firstIndex(of: AppLocalization.string("Open with")))
        try #require(items.indices.contains(index + 1))
        let alternate = items[index + 1]
        #expect(alternate.title == AppLocalization.string("Always open with"))
        #expect(alternate.isAlternate)
        #expect(alternate.keyEquivalent == items[index].keyEquivalent)
        #expect(alternate.keyEquivalentModifierMask == items[index].keyEquivalentModifierMask.union(.option))
    }

    @Test("Open and Open with track empty, single, multiple, and folder selections", arguments: BrowserViewMode.allCases)
    func availabilityTracksSelection(mode: BrowserViewMode) async throws {
        try await withFixture(mode: mode) { state, _ in
            #expect(state.selection.isEmpty, "Empty selection: \(mode)")
            #expect(!state.canOpenSelection, "Empty selection: \(mode)")
            #expect(!state.canOpenSelectionWithApplication, "Empty selection: \(mode)")
            #expect(!state.canAlwaysOpenSelectionWithApplication, "Empty selection: \(mode)")

            state.select(try item("Welcome.txt", in: state))
            #expect(state.canOpenSelection, "Single selection: \(mode)")
            #expect(state.canOpenSelectionWithApplication, "Single selection: \(mode)")
            #expect(state.canAlwaysOpenSelectionWithApplication, "Single selection: \(mode)")

            state.select(try item("Another.txt", in: state), modifiers: [.command])
            #expect(state.selectedItems.count == 2, "Multiple selection: \(mode)")
            #expect(state.canOpenSelection, "Multiple selection: \(mode)")
            #expect(state.canOpenSelectionWithApplication, "Multiple selection: \(mode)")
            #expect(state.canAlwaysOpenSelectionWithApplication, "Multiple selection: \(mode)")

            state.archiveOperationInProgress = true
            #expect(!state.canOpenSelection, "An archive operation disables Open: \(mode)")
            state.archiveOperationInProgress = false

            state.select(try item("Dropped", in: state))
            #expect(state.canOpenSelection, "Folder selection: \(mode)")
            #expect(!state.canOpenSelectionWithApplication, "Folders are not opened with an application: \(mode)")
            #expect(!state.canAlwaysOpenSelectionWithApplication, "Folders are not opened with an application: \(mode)")

            state.select(try item("Welcome.txt", in: state), modifiers: [.command])
            #expect(state.canOpenSelection, "Mixed selection: \(mode)")
            #expect(!state.canOpenSelectionWithApplication, "Mixed selection with a folder: \(mode)")
        }
    }

    @Test("File Open navigates a selected folder and a selected archive", arguments: BrowserViewMode.allCases)
    func openNavigatesFolderAndArchive(mode: BrowserViewMode) async throws {
        try await withFixture(mode: mode) { state, root in
            let rootTitle = state.title
            #expect(rootTitle == root.lastPathComponent)

            state.select(try item("Dropped", in: state))
            #expect(state.title == rootTitle, "Selecting must not navigate: \(mode)")
            #expect(state.canOpenSelection)
            await state.openSelection().value
            #expect(state.title == "Dropped", "\(mode)")
            #expect(state.location.fileSystemURL?.lastPathComponent == "Dropped", "\(mode)")

            await state.goBack()
            #expect(state.title == rootTitle, "\(mode)")
            state.select(try item("Sample.zip", in: state))
            #expect(state.title == rootTitle, "Selecting must not navigate: \(mode)")
            await state.openSelection().value
            #expect(state.title == "Sample.zip", "\(mode)")
            guard case .archive = state.location else {
                Issue.record("File Open must navigate into the archive in \(mode)")
                return
            }
            #expect(state.items.contains(where: { $0.name == "Inside" }), "\(mode)")
            #expect(state.error == nil, "\(mode)")
        }
    }

    @Test("File Open captures the selection before it runs")
    func openCapturesSelection() async throws {
        try await withFixture(mode: .list) { state, _ in
            state.select(try item("Dropped", in: state))
            let operation = state.openSelection()
            state.select(try item("Sample.zip", in: state))
            await operation.value
            #expect(state.title == "Dropped")
        }
    }

    @Test("Changing language or mode does not invent a selection", arguments: BrowserViewMode.allCases)
    func languageAndModeKeepEmptySelection(mode: BrowserViewMode) async throws {
        try await withFixture(mode: .icons) { state, _ in
            for language in AppLanguagePreference.supportedLanguages {
                state.preferences.language = language
                state.viewMode = mode
                // ContentView prepares Columns from the current selection on this change.
                if mode == .columns { await state.prepareColumnView().value }
                #expect(state.selection.isEmpty, "\(language) in \(mode)")
                #expect(!state.canOpenSelection, "\(language) in \(mode)")
                #expect(AppLocalization.string("Open", locale: state.preferences.language.locale)
                        == FileMenuLocalizationTests.openTitles[language])
            }
        }
    }

    // MARK: - Support

    private func fileMenuItems() async throws -> [NSMenuItem] {
        // SwiftUI installs its commands after launch; wait for the File menu,
        // identified by New Zforge Window (⌘N), with an explicit deadline.
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while ContinuousClock.now < deadline {
            if let menu = NSApp.mainMenu?.items.lazy.compactMap(\.submenu).first(where: { menu in
                menu.items.contains { $0.keyEquivalent == "n" && $0.keyEquivalentModifierMask == [.command] }
                    && menu.items.contains { $0.title == AppLocalization.string("Open") }
            }) {
                return menu.items
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        Issue.record("The File menu was not installed: \(NSApp.mainMenu?.items.map(\.title) ?? [])")
        throw CancellationError()
    }

    private func item(_ name: String, in state: FileBrowserState) throws -> BrowserItem {
        try #require(state.items.first(where: { $0.name == name }), "Missing fixture item \(name)")
    }

    private func withFixture(
        mode: BrowserViewMode, body: (FileBrowserState, URL) async throws -> Void
    ) async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileMenuOpen-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let inside = root.appendingPathComponent("Inside", isDirectory: true)
        try FileManager.default.createDirectory(at: inside, withIntermediateDirectories: false)
        try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [inside], outputURL: root.appendingPathComponent("Sample.zip"),
                                       format: .zip, progress: { _ in })
        try FileManager.default.removeItem(at: inside)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Dropped", isDirectory: true),
                                                withIntermediateDirectories: false)
        try Data("welcome".utf8).write(to: root.appendingPathComponent("Welcome.txt"))
        try Data("another".utf8).write(to: root.appendingPathComponent("Another.txt"))

        let suite = "FileMenuOpen-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = mode
        preferences.language = .english
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
                                     recentItems: UIFixtureRecentItemsService(), taggedItems: UIFixtureTaggedItemsService(),
                                     grants: UIFixtureAccessGrantStore(), archives: engine)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        #expect(state.viewMode == mode)
        try await body(state, root)
    }
}

/// Offscreen localization contracts of the File menu and the Settings language picker.
@Suite("File menu and language picker localization")
struct FileMenuLocalizationTests {
    nonisolated static let openTitles: [AppLanguagePreference: String] = [
        .english: "Open", .portugueseBrazil: "Abrir", .chineseSimplified: "打开", .chineseTraditional: "打開",
        .japanese: "開く", .german: "Öffnen", .french: "Ouvrir", .spanish: "Abrir", .korean: "열기",
        .italian: "Apri", .russian: "Открыть", .polish: "Otwórz", .ukrainian: "Відкрити", .turkish: "Aç",
        .thai: "เปิด", .danish: "Åbn", .czech: "Otevřít", .dutch: "Open", .swedish: "Öppna",
        .hindi: "खोलें", .bengali: "খুলুন"
    ]

    nonisolated static let pickerNames: [AppLanguagePreference: String] = [
        .english: "English", .portugueseBrazil: "Português (Brasil)", .chineseSimplified: "简体中文",
        .chineseTraditional: "繁體中文", .japanese: "日本語", .german: "Deutsch", .french: "Français",
        .spanish: "Español", .korean: "한국어", .italian: "Italiano", .russian: "Русский", .polish: "Polski",
        .ukrainian: "Українська", .turkish: "Türkçe", .thai: "ไทย", .danish: "Dansk", .czech: "Čeština",
        .dutch: "Nederlands", .swedish: "Svenska", .hindi: "हिन्दी", .bengali: "বাংলা"
    ]

    private var applicationBundle: Bundle { Bundle(for: AppDelegate.self) }

    @Test("File Open follows each of the 21 app languages", arguments: AppLanguagePreference.supportedLanguages)
    func openTitle(language: AppLanguagePreference) throws {
        let expected = try #require(Self.openTitles[language])
        #expect(AppLocalization.string("Open", locale: language.locale, bundle: applicationBundle) == expected)
    }

    @Test("Every language keeps its native name in the Settings picker whatever the interface language",
          arguments: AppLanguagePreference.allCases)
    func pickerNames(interface: AppLanguagePreference) throws {
        #expect(Set(Self.pickerNames.keys) == Set(AppLanguagePreference.supportedLanguages))
        for language in AppLanguagePreference.supportedLanguages {
            let expected = try #require(Self.pickerNames[language])
            #expect(AppLocalization.string(language.titleKey, locale: interface.locale, bundle: applicationBundle) == expected,
                    "\(language) in the \(interface) interface")
        }
    }

    @Test("Brazilian Portuguese File menu and shortcut help titles")
    func portugueseTitles() {
        let locale = AppLanguagePreference.portugueseBrazil.locale
        #expect(AppLocalization.string("Open", locale: locale, bundle: applicationBundle) == "Abrir")
        #expect(AppLocalization.string("Open with", locale: locale, bundle: applicationBundle) == "Abrir com")
        #expect(AppLocalization.string("New Folder with Selection", locale: locale, bundle: applicationBundle)
                == "Nova Pasta com Seleção")
        #expect(AppLocalization.string("Keyboard Shortcuts", locale: locale, bundle: applicationBundle) == "Atalhos de Teclado")
    }
}
