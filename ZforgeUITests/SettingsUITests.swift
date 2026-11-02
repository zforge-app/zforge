import XCTest

/// Settings interactions that need real event delivery. The column order logic is
/// covered offscreen by `ListColumnOrderTests`; this proves the drag gesture reaches it.
final class SettingsUITests: XCTestCase {
    @MainActor
    func testListColumnsReorderByDragging() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeTestSuite.ZforgeSettingsUI-\(UUID().uuidString)"
        app.launchArguments = ["--ui-fixtures", "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }

        app.openSettingsPane("viewOptions")
        func row(_ column: String) -> XCUIElement {
            app.descendants(matching: .any).matching(identifier: "settings-list-column-" + column).firstMatch
        }
        func visibleOrder() -> [String] {
            ["modificationDate", "size", "kind"].sorted { row($0).frame.minY < row($1).frame.minY }
        }
        let kind = row("kind")
        XCTAssertTrue(kind.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(visibleOrder(), ["modificationDate", "size", "kind"])

        // The section sits below the fold; the gesture needs its rows on screen.
        let settingsWindow = app.windows["com_apple_SwiftUI_Settings_window"]
        func rowsOnScreen() -> Bool {
            ["modificationDate", "kind"].allSatisfy { settingsWindow.frame.insetBy(dx: 0, dy: 40).contains(row($0).frame) }
        }
        for _ in 0..<20 where !rowsOnScreen() {
            settingsWindow.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -120)
        }
        XCTAssertTrue(rowsOnScreen(), "List Columns rows must be scrolled into view")

        // One drag from Kind's leading handle moves it two places, above Date Modified.
        let start = kind.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5)).withOffset(CGVector(dx: 8, dy: 0))
        let target = row("modificationDate").coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.4))
            .withOffset(CGVector(dx: 8, dy: 0))
        start.click(forDuration: 0.3, thenDragTo: target)

        let reordered = NSPredicate { _, _ in visibleOrder() == ["kind", "modificationDate", "size"] }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: reordered, object: nil)], timeout: 5),
                       .completed, "Order after the drag: \(visibleOrder())")
        let capture = XCTAttachment(screenshot: app.windows["com_apple_SwiftUI_Settings_window"].screenshot())
        capture.name = "List columns after drag"
        capture.lifetime = .keepAlways
        add(capture)

        // The browser's List header follows the new default order.
        app.windows["com_apple_SwiftUI_Settings_window"].buttons[XCUIIdentifierCloseWindow].click()
        let browserWindow = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browserWindow.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(browserWindow.waitForExistence(timeout: 5), app.debugDescription)
        app.typeKey("2", modifierFlags: .command)
        let headers = ["Kind", "Date Modified", "Size"].map { app.buttons[$0].firstMatch }
        XCTAssertTrue(headers[0].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(headers.map(\.frame.minX), headers.map(\.frame.minX).sorted(), "List header order")
    }

    /// The scale's steps, holds and the drag distances at this width are covered offscreen by
    /// `SettingsSliderTests`, which call the slider's action directly. Only real mouse tracking
    /// proves that the knob, while AppKit drags it, holds on a round value and then continues
    /// with the next step, including in a slow drag of many small movements. D-73 removed the
    /// root archive size limit that hosted this slider; the Settings fixture
    /// (`--ui-scale-slider-fixture`) shows the same slider and scale until the preview limits.
    @MainActor
    func testArchiveSizeLimitSliderHoldsRoundValuesWhileDragging() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeTestSuite.ZforgeSettingsUI-\(UUID().uuidString)"
        app.launchArguments = ["--ui-fixtures", "--ui-scale-slider-fixture", "-appLanguagePreference", "english",
                               "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }

        let settingsWindow = app.openSettingsPane("previews")
        let slider = app.sliders["ui-fixture-size-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5), app.debugDescription)
        for _ in 0..<20 where !settingsWindow.frame.insetBy(dx: 0, dy: 40).contains(slider.frame) {
            settingsWindow.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -120)
        }
        XCTAssertEqual(slider.value as? String, "1 GB")

        // 1 GB is the third of seven evenly spaced tick marks; the knob travels between
        // half a knob (about 10 pt) from each end. Grabbing anywhere on the knob works.
        let travel = slider.frame.width - 20
        func knob() -> XCUICoordinate {
            slider.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.3))
                .withOffset(CGVector(dx: 10 + travel / 3, dy: 0))
        }
        func drag(by distance: CGFloat, from offset: CGFloat = 0) {
            let start = knob().withOffset(CGVector(dx: offset, dy: 0))
            start.click(forDuration: 0.3, thenDragTo: start.withOffset(CGVector(dx: distance, dy: 0)))
        }

        // Each doubling is about 66 pt long at this width, in 32 steps on a logarithmic track, so
        // the first step after 1 GB is about 2.9 pt: without the hold, 2 pt would read 1.03 GB.
        drag(by: 2)
        XCTAssertEqual(slider.value as? String, "1 GB", "The knob holds on the round value")
        // Past the hold (about 4 pt), the very next steps follow: 1.03 GB from about 5.4 pt,
        // then 1.06 GB from about 8.3 pt to 11.2 pt (distances: `SettingsSliderTests`). A slow
        // drag, as a person makes, crosses the hold in many small movements on its way.
        // (`press(forDuration:thenDragTo:withVelocity:...)` synthesizes no events on this slider.)
        knob().click(forDuration: 0.3, thenDragTo: knob().withOffset(CGVector(dx: 10, dy: 0)),
                     withVelocity: XCUIGestureVelocity(20), thenHoldForDuration: 0.1)
        XCTAssertEqual(slider.value as? String, "1.06 GB", "A slow drag leaves the hold and continues step by step")
        XCTAssertTrue(settingsWindow.staticTexts["1.06 GB"].exists, "The row shows the dragged value")

        let capture = XCTAttachment(screenshot: settingsWindow.screenshot())
        capture.name = "Size slider fixture after drag"
        capture.lifetime = .keepAlways
        add(capture)

        // One quick movement back from where the knob now is crosses the hold again and stops on it.
        drag(by: -10, from: 10)
        XCTAssertEqual(slider.value as? String, "1 GB", "Dragging back stops on the round value")
        XCTAssertTrue(settingsWindow.staticTexts["1 GB"].exists, "The row shows the dragged value")
    }

    /// Pushing a profile row, typing in the profile page, the toolbar back button and the
    /// delete confirmation need real event delivery and sheet presentation (ZF-58). The list,
    /// the summaries, saving while typing and Duplicate are covered offscreen by
    /// `CompressionProfileSettingsTests`.
    @MainActor
    func testCompressionProfileOpensSavesAndDeletes() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeTestSuite.ZforgeSettingsUI-\(UUID().uuidString)"
        app.launchArguments = ["--ui-fixtures", "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }

        let settings = app.openSettingsPane("compression")
        // The window keeps a 220 pt sidebar beside the 568 pt detail column, so every English
        // pane title fits on one line (D-75: SwiftUI had reset the sidebar to 144 pt).
        let columns = settings.scrollViews.allElementsBoundByIndex.map(\.frame).sorted { $0.minX < $1.minX }
        XCTAssertEqual(columns.first?.width ?? 0, 220, accuracy: 1, "Columns: \(columns)")
        XCTAssertEqual(columns.last?.width ?? 0, 568, accuracy: 1, "Columns: \(columns)")
        for pane in ["general", "viewOptions", "sidebar", "compression", "previews", "automation"] {
            let title = settings.descendants(matching: .any).matching(identifier: "settings-pane-" + pane).firstMatch
            XCTAssertLessThan(title.frame.height, 26, "\(pane) wraps: \(title.frame)")
        }
        func profileRow(_ name: String) -> XCUIElement {
            settings.descendants(matching: .any).matching(identifier: "settings-compression-profile-" + name).firstMatch
        }
        XCTAssertTrue(profileRow("Auto").waitForExistence(timeout: 5), app.debugDescription)
        let list = XCTAttachment(screenshot: settings.screenshot())
        list.name = "Compression pane"
        list.lifetime = .keepAlways
        add(list)

        // Add Profile opens the new profile's page, titled with its name.
        settings.buttons["settings-add-compression-profile"].click()
        let name = settings.textFields["settings-profile-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(name.value as? String, "New Profile")
        XCTAssertEqual(settings.title, "New Profile")

        // Typing renames it at once; the window title follows.
        name.click()
        name.typeKey(.rightArrow, modifierFlags: .command)
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "New Profile".count))
        name.typeText("Sharing")
        let renamed = NSPredicate { _, _ in settings.title == "Sharing" }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: renamed, object: nil)], timeout: 5),
                       .completed, "Window title: \(settings.title)")
        let capture = XCTAttachment(screenshot: settings.screenshot())
        capture.name = "Compression profile page"
        capture.lifetime = .keepAlways
        add(capture)

        // The toolbar's back button returns to the list, which shows the renamed profile.
        let back = settings.toolbars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), app.debugDescription)
        back.click()
        XCTAssertTrue(profileRow("Sharing").waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(settings.title, "Compression")

        // A row opens its profile; Delete Profile asks first, and Cancel keeps it.
        profileRow("Sharing").click()
        XCTAssertTrue(name.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(name.value as? String, "Sharing")
        let delete = settings.buttons["settings-delete-compression-profile"]
        delete.click()
        let confirm = app.sheets.firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(confirm.staticTexts["Delete “Sharing”?"].exists, app.debugDescription)
        confirm.buttons["Cancel"].click()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Sharing")

        // Confirming deletes it and returns to the list.
        delete.click()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        confirm.buttons["Delete Profile"].click()
        XCTAssertTrue(profileRow("Sharing").waitForNonExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(profileRow("Auto").exists)
        XCTAssertEqual(settings.title, "Compression")

        // The last profile cannot be deleted.
        profileRow("Auto").click()
        XCTAssertTrue(delete.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(delete.isEnabled, "The only profile cannot be deleted")
    }
}
