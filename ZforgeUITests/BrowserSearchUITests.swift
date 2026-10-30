import XCTest

/// Real-window toolbar search. Offscreen tests cover the search state, results,
/// scopes, history and the toolbar item's place; only a real window proves that
/// ⌘F reaches the focused window and makes the toolbar field first responder,
/// and that Escape typed into that field collapses it.
final class BrowserSearchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCommandFFocusesToolbarSearchAndEscapeCollapsesIt() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "-appLanguagePreference", "english",
                               "-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO"]
        app.launch(); app.activate()
        let browser = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browser.waitForExistence(timeout: 3) {
            app.menuBars.menuBarItems["File"].click()
            app.menuItems["New Zforge Window"].click()
        }
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toolbar-search"].waitForExistence(timeout: 2))

        app.typeKey("f", modifierFlags: .command)
        let field = app.textFields["toolbar-search-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        // Typing goes straight into the field, so ⌘F made it first responder.
        app.typeText("Another")
        XCTAssertTrue(app.staticTexts["Another.txt"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Welcome.txt"].exists)

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.buttons["toolbar-search"].waitForExistence(timeout: 2))
        XCTAssertFalse(field.exists)
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 3))
    }
}
