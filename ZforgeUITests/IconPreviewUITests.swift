import XCTest

final class IconPreviewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Thumbnails, archive entries, the video badge, every mode, relaunch persistence, Portuguese,
    /// narrow widths and zoom limits are characterized offscreen in `IconPreviewGridTests`. This
    /// scenario keeps what needs the real app: clicking a cell, the menu shortcuts, the Get Info
    /// window and the Settings toggle updating the open Icons grid.
    @MainActor
    func testSettingsToggleUpdatesTheOpenGridAndKeepsSelection() throws {
        let app = fixtureApplication()
        launchFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        browserFile(named: "Preview.png", in: app).click()
        waitForIconSelection(named: "Preview.png", in: app)
        assertSelection(named: "Preview.png", in: app)

        // The icon content is present before and after the side preview panel is shown.
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        app.typeKey("p", modifierFlags: [.command, .shift])
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        assertSelection(named: "Preview.png", in: app)
        attachScreenshot(app, named: "Selected thumbnail with the preview panel shown")

        let toggle = openIconPreviewSettings(in: app)
        XCTAssertEqual(controlState(toggle), 1, app.debugDescription)
        attachScreenshot(app, named: "Icon preview setting enabled by default")
        toggle.click()
        waitForToggle(toggle, enabled: false)
        XCTAssertEqual(controlState(toggle), 0, app.debugDescription)
        XCTAssertTrue(fallback(named: "Preview.png", in: app).waitForExistence(timeout: 5))
        closeSettings(in: app)
        XCTAssertFalse(preview(named: "Preview.png", in: app).exists)
        assertSelection(named: "Preview.png", in: app)
        attachScreenshot(app, named: "Open grid after disabling icon previews")

        let restoredToggle = openIconPreviewSettings(in: app)
        XCTAssertEqual(controlState(restoredToggle), 0, app.debugDescription)
        restoredToggle.click()
        waitForToggle(restoredToggle, enabled: true)
        closeSettings(in: app)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        assertSelection(named: "Preview.png", in: app)
    }

    @MainActor
    private func fixtureApplication() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-icon-preview-fixtures", "--ui-window-width", "1200", "--ui-view-mode", "icons",
            "-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO",
            "-AppleInterfaceStyle", "Light",
            "-browser.scale", "1", "-browser.previewVisible.icons", "NO",
            "-appLanguagePreference", "english"
        ]
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeTestSuite.ZforgeIconPreviewUI-\(UUID().uuidString)"
        return app
    }

    @MainActor
    private func launchFixture(_ app: XCUIApplication) {
        app.launch()
        app.activate()
        if !app.windows.firstMatch.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(app.descendants(matching: .any)["browser-mode-icons"].firstMatch
            .waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(app.windows.count, 1, "The fixture starts with one browser window")
        XCTAssertTrue(browserFile(named: "Preview.png", in: app).waitForExistence(timeout: 10),
            app.debugDescription)
    }

    @MainActor
    private func browserFile(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "browser-item-\(name)")
            .firstMatch.staticTexts[name].firstMatch
    }

    @MainActor
    private func preview(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "icon-preview-\(name)").firstMatch
    }

    @MainActor
    private func fallback(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "icon-fallback-\(name)").firstMatch
    }

    @MainActor
    private func controlState(_ control: XCUIElement) -> Int? {
        if let number = control.value as? NSNumber { return number.intValue }
        return (control.value as? String).flatMap(Int.init)
    }

    @MainActor
    private func waitForIconSelection(named name: String, in app: XCUIApplication) {
        let selected = expectation(for: NSPredicate(format: "selected == true"),
            evaluatedWith: browserFile(named: name, in: app))
        wait(for: [selected], timeout: 5)
    }

    @MainActor
    private func waitForToggle(_ toggle: XCUIElement, enabled: Bool) {
        let value = expectation(for: NSPredicate(format: "value == %@", NSNumber(value: enabled ? 1 : 0)),
            evaluatedWith: toggle)
        wait(for: [value], timeout: 5)
    }

    @MainActor
    private func openIconPreviewSettings(in app: XCUIApplication) -> XCUIElement {
        app.typeKey(",", modifierFlags: .command)
        let toggle = app.descendants(matching: .any)
            .matching(identifier: "settings-show-icon-previews").firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), app.debugDescription)
        if toggle.elementType == .checkBox || toggle.elementType == .switch { return toggle }
        let checkbox = toggle.checkBoxes.firstMatch
        let control = checkbox.exists ? checkbox : toggle.switches.firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 5), app.debugDescription)
        return control
    }

    @MainActor
    private func assertSelection(named name: String, in app: XCUIApplication) {
        app.typeKey("i", modifierFlags: .command)
        let information = app.windows["Info: \(name)"].firstMatch
        XCTAssertTrue(information.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(information.staticTexts[name].exists)
        information.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(information.waitForNonExistence(timeout: 5))
    }

    @MainActor
    private func closeSettings(in app: XCUIApplication) {
        app.windows["com_apple_SwiftUI_Settings_window"].buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(app.descendants(matching: .any)["settings-show-icon-previews"].firstMatch
            .waitForNonExistence(timeout: 5))
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let settings = app.windows["com_apple_SwiftUI_Settings_window"]
        let window = settings.exists ? settings : app.windows.firstMatch
        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
