import XCTest

/// Settings interactions that need real event delivery.
final class SettingsUITests: XCTestCase {
    /// The scale's steps and holds are covered offscreen by `SettingsSliderTests`, which call
    /// the slider's action directly. Only real mouse tracking proves that the knob, while
    /// AppKit drags it, holds on a round value and then continues with the next step.
    @MainActor
    func testArchiveSizeLimitSliderHoldsRoundValuesWhileDragging() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeSettingsUI-\(UUID().uuidString)"
        app.launchArguments = ["--ui-fixtures", "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        app.activate()
        defer { app.terminate() }

        app.typeKey(",", modifierFlags: .command)
        let settingsWindow = app.windows["com_apple_SwiftUI_Settings_window"]
        let slider = app.sliders["settings-archive-root-size-limit"]
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
        func drag(by distance: CGFloat) {
            knob().click(forDuration: 0.3, thenDragTo: knob().withOffset(CGVector(dx: distance, dy: 0)))
        }

        // One step is about 2 pt at this width: without the hold, 2 pt would read 1.03 GB.
        drag(by: 2)
        XCTAssertEqual(slider.value as? String, "1 GB", "The knob holds on the round value")
        // Past the hold (about 4 pt), the very next steps follow: 1.03 GB, then 1.06 GB.
        drag(by: 8)
        XCTAssertEqual(slider.value as? String, "1.06 GB", "Steps continue right after the hold")
        XCTAssertTrue(settingsWindow.staticTexts["1.06 GB"].exists, "The row shows the dragged value")

        let capture = XCTAttachment(screenshot: settingsWindow.screenshot())
        capture.name = "Root archive size limit after drag"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
