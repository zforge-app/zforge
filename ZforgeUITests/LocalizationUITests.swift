import XCTest

final class LocalizationUITests: XCTestCase {
    // Two consecutive live changes through the real Settings picker and menu bar.
    // Every one of the 21 languages (File Open title and picker names) and the
    // empty selection after language/mode changes in all four modes are covered
    // offscreen by `FileMenuLocalizationTests` and `FileMenuCommandTests`.
    private let languages: [(name: String, preference: String, open: String)] = [
        ("Português (Brasil)", "portugueseBrazil", "Abrir"), ("বাংলা", "bengali", "খুলুন")
    ]

    @MainActor
    func testLanguageSelectionUpdatesOpenMenuAndPersists() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let suite = "ZforgeTestSuite.ZforgeLocalizationUI-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.set("english", forKey: "appLanguagePreference")
        defer { defaults.removePersistentDomain(forName: suite) }
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = suite
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "-AppleLanguages", "(en)", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }
        waitForBrowserWindow(app)

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

            for shortcut in ["2"] {
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
        // File > Open takes its language from the focused browser window.
        waitForBrowserWindow(app)
        app.menuBars.menuBarItems["File"].click()
        XCTAssertTrue(app.menuItems["খুলুন"].firstMatch.waitForExistence(timeout: 5), "The final language must survive relaunch")
        app.typeKey(.escape, modifierFlags: [])
    }

    /// Browser windows are identified as `browser-AppWindow-N`. Like the other
    /// fixture launches, open one when the launch restores none.
    @MainActor
    private func waitForBrowserWindow(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let browserWindow = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browserWindow.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(browserWindow.waitForExistence(timeout: 5), app.debugDescription, file: file, line: line)
    }
}
