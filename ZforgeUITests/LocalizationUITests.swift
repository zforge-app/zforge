import XCTest

final class LocalizationUITests: XCTestCase {
    private let languages: [(name: String, preference: String, open: String)] = [
        ("English", "english", "Open"), ("Português (Brasil)", "portugueseBrazil", "Abrir"),
        ("简体中文", "chineseSimplified", "打开"), ("繁體中文", "chineseTraditional", "打開"),
        ("日本語", "japanese", "開く"), ("Deutsch", "german", "Öffnen"),
        ("Français", "french", "Ouvrir"), ("Español", "spanish", "Abrir"),
        ("한국어", "korean", "열기"), ("Italiano", "italian", "Apri"),
        ("Русский", "russian", "Открыть"), ("Polski", "polish", "Otwórz"),
        ("Українська", "ukrainian", "Відкрити"), ("Türkçe", "turkish", "Aç"),
        ("ไทย", "thai", "เปิด"), ("Dansk", "danish", "Åbn"),
        ("Čeština", "czech", "Otevřít"), ("Nederlands", "dutch", "Open"),
        ("Svenska", "swedish", "Öppna"), ("हिन्दी", "hindi", "खोलें"),
        ("বাংলা", "bengali", "খুলুন")
    ]

    @MainActor
    func testLanguageSelectionUpdatesOpenMenusInAllBrowserModesAndPersists() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let suite = "ZforgeLocalizationUI-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.set("english", forKey: "appLanguagePreference")
        defer { defaults.removePersistentDomain(forName: suite) }
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = suite
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "-AppleLanguages", "(en)", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }
        XCTAssertTrue(app.windows["browser-main-window"].waitForExistence(timeout: 5))

        for language in languages {
            app.typeKey(",", modifierFlags: .command)
            let picker = app.popUpButtons["settings-language"].firstMatch
            XCTAssertTrue(picker.waitForExistence(timeout: 5), "Language picker must be available")
            picker.click()
            let option = app.menuItems[language.name].firstMatch
            XCTAssertTrue(option.waitForExistence(timeout: 3), "Missing language option: \(language.name)")
            option.click()
            let settings = app.windows["com_apple_SwiftUI_Settings_window"]
            let capture = XCTAttachment(screenshot: settings.screenshot())
            capture.name = "Settings localization - \(language.preference)"
            capture.lifetime = .keepAlways
            add(capture)
            settings.buttons[XCUIIdentifierCloseWindow].click()
            XCTAssertTrue(picker.waitForNonExistence(timeout: 5))

            for shortcut in ["1", "2", "3", "4"] {
                app.typeKey(shortcut, modifierFlags: .command)
                app.menuBars.menuBarItems["File"].click()
                let menu = app.menuBars.menuBarItems["File"].menus.firstMatch
                let open = menu.menuItems[language.open].firstMatch
                XCTAssertTrue(open.waitForExistence(timeout: 3), "File Open must follow \(language.name) in mode \(shortcut)")
                XCTAssertFalse(open.isEnabled, "Changing language or mode must not invent a selection")
                app.typeKey(.escape, modifierFlags: [])
            }
        }

        app.terminate()
        app.launch()
        app.activate()
        app.menuBars.menuBarItems["File"].click()
        XCTAssertTrue(app.menuItems["খুলুন"].firstMatch.waitForExistence(timeout: 5), "The final language must survive relaunch")
        app.typeKey(.escape, modifierFlags: [])
    }
}
