import XCTest

final class IconPreviewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDefaultIconPreviewsIncludeSupportedFilesAndArchiveEntries() throws {
        let app = fixtureApplication()
        launchFixture(app)
        defer { app.terminate() }

        for name in previewFileNames {
            XCTAssertTrue(preview(named: name, in: app).waitForExistence(timeout: 10), name)
        }
        for name in ["Unsupported.bin", "Empty Folder", "Sample.zip"] {
            XCTAssertTrue(fallback(named: name, in: app).exists, name)
            XCTAssertFalse(preview(named: name, in: app).exists, name)
        }
        attachScreenshot(app, named: "Default icon previews with the preview panel hidden")

        browserFile(named: "Sample.zip", in: app).doubleClick()
        XCTAssertTrue(browserFile(named: "Preview.jpg", in: app).waitForNonExistence(timeout: 5))
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        XCTAssertFalse(browserFile(named: "Preview.jpg", in: app).exists)
        attachScreenshot(app, named: "Archive entry icon preview")
    }

    @MainActor
    func testSettingsToggleUpdatesTheOpenGridAndPersistsAcrossRelaunch() throws {
        let app = fixtureApplication()
        launchFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))

        let toggle = openIconPreviewSettings(in: app)
        XCTAssertEqual(controlState(toggle), 1, app.debugDescription)
        attachScreenshot(app, named: "Icon preview setting enabled by default")
        toggle.click()
        waitForToggle(toggle, enabled: false)
        XCTAssertEqual(controlState(toggle), 0, app.debugDescription)
        XCTAssertTrue(fallback(named: "Preview.png", in: app).waitForExistence(timeout: 5))
        closeSettings(in: app)
        for name in previewFileNames {
            XCTAssertTrue(fallback(named: name, in: app).waitForExistence(timeout: 5), name)
            XCTAssertFalse(preview(named: name, in: app).exists, name)
        }
        attachScreenshot(app, named: "Open grid after disabling icon previews")

        app.terminate()
        launchFixture(app)
        XCTAssertTrue(fallback(named: "Preview.png", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(preview(named: "Preview.png", in: app).exists)
        let savedToggle = openIconPreviewSettings(in: app)
        XCTAssertEqual(controlState(savedToggle), 0, app.debugDescription)
        savedToggle.click()
        waitForToggle(savedToggle, enabled: true)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        closeSettings(in: app)
        attachScreenshot(app, named: "Open grid after enabling icon previews again")

        app.terminate()
        launchFixture(app)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        let restoredToggle = openIconPreviewSettings(in: app)
        XCTAssertEqual(controlState(restoredToggle), 1, app.debugDescription)
    }

    @MainActor
    func testIconPreviewSettingPreservesSelectionAcrossEveryModeAndPanelVisibility() throws {
        let app = fixtureApplication()
        launchFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        browserFile(named: "Preview.png", in: app).click()
        waitForIconSelection(named: "Preview.png", in: app)
        assertSelection(named: "Preview.png", in: app)

        // The icon content is present before the side preview panel is shown.
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        app.typeKey("p", modifierFlags: [.command, .shift])
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        assertSelection(named: "Preview.png", in: app)
        attachScreenshot(app, named: "Selected thumbnail with the preview panel shown")

        let toggle = openIconPreviewSettings(in: app)
        toggle.click()
        waitForToggle(toggle, enabled: false)
        closeSettings(in: app)
        XCTAssertTrue(fallback(named: "Preview.png", in: app).waitForExistence(timeout: 5))
        assertSelection(named: "Preview.png", in: app)

        for (key, mode) in [("2", "list"), ("3", "columns"), ("4", "gallery"), ("1", "icons")] {
            app.typeKey(key, modifierFlags: .command)
            XCTAssertTrue(app.descendants(matching: .any)["browser-mode-\(mode)"].firstMatch
                .waitForExistence(timeout: 5), mode)
            assertSelection(named: "Preview.png", in: app)
            XCTAssertFalse(preview(named: "Preview.png", in: app).exists, mode)
            if mode == "icons" {
                XCTAssertTrue(fallback(named: "Preview.png", in: app).exists)
            }
        }

        let restoredToggle = openIconPreviewSettings(in: app)
        restoredToggle.click()
        waitForToggle(restoredToggle, enabled: true)
        closeSettings(in: app)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        assertSelection(named: "Preview.png", in: app)
    }

    @MainActor
    func testVideoThumbnailShowsPlayBadgeInIconsAndSelectionStack() throws {
        let app = fixtureApplication()
        launchFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(preview(named: "Preview.mov", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        attachScreenshot(app, named: "Video thumbnail with play badge in Icons")

        // The last selected item tops the stack, so select the movie last to keep its badge visible.
        browserFile(named: "Preview.png", in: app).click()
        waitForIconSelection(named: "Preview.png", in: app)
        XCUIElement.perform(withKeyModifiers: .command) {
            browserFile(named: "Preview.mov", in: app).click()
        }
        waitForIconSelection(named: "Preview.mov", in: app)
        app.typeKey("4", modifierFlags: .command)
        XCTAssertTrue(app.descendants(matching: .any)["browser-mode-gallery"].firstMatch.waitForExistence(timeout: 5))
        attachScreenshot(app, named: "Video thumbnail with play badge in the Gallery selection stack")
    }

    @MainActor
    func testPortugueseNarrowWindowPreservesPreviewsAndMultipleSelectionAtZoomLimits() throws {
        let app = fixtureApplication(width: "720", language: "portugueseBrazil", appearance: "Dark")
        launchFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))

        browserFile(named: "Preview.png", in: app).click()
        waitForIconSelection(named: "Preview.png", in: app)
        assertSelection(named: "Preview.png", titlePrefix: "Informações", in: app)
        for _ in 0..<3 { app.typeKey("-", modifierFlags: .command) }
        let content = app.descendants(matching: .any)["browser-mode-icons"].firstMatch
        let minimumZoom = expectation(for: NSPredicate(format: "value == %@", "70%"), evaluatedWith: content)
        wait(for: [minimumZoom], timeout: 5)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        let smallFrame = preview(named: "Preview.png", in: app).frame
        assertSelection(named: "Preview.png", titlePrefix: "Informações", in: app)
        attachScreenshot(app, named: "Portuguese narrow window at 70 percent zoom")

        XCUIElement.perform(withKeyModifiers: .command) {
            browserFile(named: "Preview.jpg", in: app).click()
        }
        waitForIconSelection(named: "Preview.jpg", in: app)
        XCTAssertTrue(browserFile(named: "Preview.png", in: app).isSelected)
        assertMultipleSelection(title: "Informações: 2 Itens", summary: "2 itens", in: app)
        XCTAssertTrue(preview(named: "Preview.png", in: app).exists)
        XCTAssertTrue(preview(named: "Preview.jpg", in: app).exists)
        attachScreenshot(app, named: "Portuguese narrow window with two selected image previews")

        for _ in 0..<9 { app.typeKey("=", modifierFlags: .command) }
        let maximumZoom = expectation(for: NSPredicate(format: "value == %@", "160%"), evaluatedWith: content)
        wait(for: [maximumZoom], timeout: 5)
        XCTAssertTrue(preview(named: "Preview.png", in: app).waitForExistence(timeout: 10))
        XCTAssertGreaterThan(preview(named: "Preview.png", in: app).frame.width, smallFrame.width)
        assertMultipleSelection(title: "Informações: 2 Itens", summary: "2 itens", in: app)
        attachScreenshot(app, named: "Portuguese narrow window at 160 percent zoom")

        let toggle = openIconPreviewSettings(in: app)
        XCTAssertTrue(app.staticTexts["Mostrar pré-visualizações na visão de ícones"].exists,
            app.debugDescription)
        XCTAssertEqual(controlState(toggle), 1, app.debugDescription)
        attachScreenshot(app, named: "Portuguese icon preview Settings label")
        toggle.click()
        waitForToggle(toggle, enabled: false)
        XCTAssertEqual(controlState(toggle), 0, app.debugDescription)
        closeSettings(in: app)
        XCTAssertTrue(fallback(named: "Preview.png", in: app).waitForExistence(timeout: 5))
        assertMultipleSelection(title: "Informações: 2 Itens", summary: "2 itens", in: app)
    }

    private var previewFileNames: [String] {
        ["Preview.png", "Preview.jpg", "Preview.pdf", "Preview.txt", "Preview.html", "Preview.mov"]
    }

    @MainActor
    private func fixtureApplication(width: String = "1200", language: String = "english",
                                    appearance: String = "Light") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-icon-preview-fixtures", "--ui-window-width", width, "--ui-view-mode", "icons",
            "-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO",
            "-AppleInterfaceStyle", appearance,
            "-browser.scale", "1", "-browser.previewVisible.icons", "NO",
            "-appLanguagePreference", language
        ]
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeIconPreviewUI-\(UUID().uuidString)"
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
    private func assertSelection(named name: String, titlePrefix: String = "Info", in app: XCUIApplication) {
        app.typeKey("i", modifierFlags: .command)
        let information = app.windows["\(titlePrefix): \(name)"].firstMatch
        XCTAssertTrue(information.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(information.staticTexts[name].exists)
        information.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(information.waitForNonExistence(timeout: 5))
    }

    @MainActor
    private func assertMultipleSelection(title: String, summary: String, in app: XCUIApplication) {
        app.typeKey("i", modifierFlags: .command)
        let information = app.windows[title].firstMatch
        XCTAssertTrue(information.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(information.staticTexts[summary].exists, app.debugDescription)
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
