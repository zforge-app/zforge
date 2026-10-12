import AppIntentsTesting
import XCTest

/// Opt-in acceptance against the signed installed application. The separate
/// harness avoids registering another Zforge development bundle during testing.
final class ZforgeDispatchTests: XCTestCase {
    @MainActor
    func testDocumentsArchiveRunsOpenIntentThroughSystem() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.Zforge")
        app.launch()
        defer { app.terminate() }
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.Zforge")
        let entityType = definitions.entities["ZforgeFileArchiveEntity"]
        let named = try await entityType.entities(matching: "Vega Demo")
        XCTAssertEqual(named.count, 1)
        try await definitions.intents["OpenZforgeFileContentIntent"].makeIntent(target: try XCTUnwrap(named.first)).run()
        XCTAssertTrue(app.windows["Vega Demo.zip"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["browser-item-Readme.txt"].firstMatch.exists)
        let indexed = try await entityType.spotlightQuery("Vega Demo")
        XCTAssertEqual(indexed.count, 1)
        try await definitions.intents["OpenZforgeFileContentIntent"].makeIntent(target: try XCTUnwrap(indexed.first)).run()
        XCTAssertTrue(app.windows["Vega Demo.zip"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["browser-item-Readme.txt"].firstMatch.exists)
    }

    @MainActor
    func testCanonicalRootProvidesSelectedArchiveAnnotation() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.Zforge")
        app.launchArguments = ["--archive-context-diagnostics"]
        app.launch()
        defer { app.terminate() }
        app.activate()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let field = app.textFields["/path/to/folder"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.click()
        app.typeKey("a", modifierFlags: .command)
        field.typeText("/private/tmp/ZforgeAutomationSmoke-20261007")
        app.buttons["Go"].click()
        let window = app.windows["ZforgeAutomationSmoke-20261007"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        window.radioButtons["view-mode-list"].click()
        let item = window.descendants(matching: .any)["browser-item-Orion Demo.zip"].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.click()
        waitForArchiveSelection(item, in: window)
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.Zforge")
        let indexed = try await definitions.entities["ZforgeFileArchiveEntity"].spotlightQuery("Orion Demo")
        let entity = try XCTUnwrap(indexed.first)
        let annotations = try await definitions.entities["ZforgeFileArchiveEntity"].viewAnnotations()
        print("Archive context diagnostic: count=\(annotations.count); selected=\(annotations.filter { $0.isSelected }.count); matching=\(annotations.filter { $0.entity.identifier == entity.identifier }.count); selectedMatching=\(annotations.filter { $0.isSelected && $0.entity.identifier == entity.identifier }.count)")
        XCTAssertTrue(annotations.contains { $0.isSelected && $0.entity.identifier == entity.identifier })
    }

    @MainActor
    func testNamedArchiveRunsOpenIntentThroughSystem() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.Zforge")
        app.launch()
        defer { app.terminate() }
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.Zforge")
        let entities = try await definitions.entities["ZforgeFileArchiveEntity"].entities(matching: "Orion Demo")
        XCTAssertEqual(entities.count, 1)
        let entity = try XCTUnwrap(entities.first)
        try await definitions.intents["OpenZforgeFileContentIntent"].makeIntent(target: entity).run()
        XCTAssertTrue(app.windows["Orion Demo.zip"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["browser-item-Readme.txt"].firstMatch.exists, app.debugDescription)
    }

    @MainActor
    func testSpotlightArchiveRunsOpenIntentThroughSystem() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.Zforge")
        app.launch()
        defer { app.terminate() }
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.Zforge")
        let entities = try await definitions.entities["ZforgeFileArchiveEntity"].spotlightQuery("Orion Demo")
        XCTAssertEqual(entities.count, 1)
        let entity = try XCTUnwrap(entities.first)
        try await definitions.intents["OpenZforgeFileContentIntent"].makeIntent(target: entity).run()
        XCTAssertTrue(app.windows["Orion Demo.zip"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["browser-item-Readme.txt"].firstMatch.exists, app.debugDescription)
    }

    @MainActor
    func testAllBrowserModesExposeTheSelectedPublishedFileIdentity() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.Zforge")
        app.launch()
        defer { app.terminate() }
        app.activate()
        app.typeKey("g", modifierFlags: [.command, .shift])
        let field = app.textFields["/path/to/folder"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), app.debugDescription)
        field.click()
        app.typeKey("a", modifierFlags: .command)
        field.typeText("/tmp/ZforgeAutomationSmoke-20261007")
        app.buttons["Go"].click()
        let namedWindow = app.windows["ZforgeAutomationSmoke-20261007"]
        XCTAssertTrue(namedWindow.waitForExistence(timeout: 5), app.debugDescription)
        // Columns legitimately changes the title when an archive container
        // opens. Retain the stable window identifier across that transition.
        let window = app.windows[namedWindow.identifier]
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.Zforge")
        let indexed = try await definitions.entities["ZforgeFileArchiveEntity"].spotlightQuery("Orion Demo")
        XCTAssertEqual(indexed.count, 1)
        let entity = try XCTUnwrap(indexed.first)
        let modes = ["view-mode-icons", "view-mode-list", "view-mode-columns", "view-mode-gallery"]
        let previous = modes.first { (window.radioButtons[$0].value as? String) == "1" }
        defer { if let previous { window.radioButtons[previous].click() } }
        for mode in modes {
            window.radioButtons[mode].click()
            let item = window.descendants(matching: .any)["browser-item-Orion Demo.zip"].firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 5), app.debugDescription)
            item.click()
            if mode == "view-mode-columns" {
                XCTAssertTrue(app.windows["Orion Demo.zip"].waitForExistence(timeout: 5))
                XCTAssertTrue(window.descendants(matching: .any)["browser-item-Readme.txt"].firstMatch.waitForExistence(timeout: 5))
                let trail = try await definitions.entities["ZforgeFileArchiveEntity"].viewAnnotations()
                XCTAssertTrue(trail.contains { $0.entity.identifier == entity.identifier }, "The visible archive trail must retain its published identity.")
                XCTAssertFalse(trail.contains { $0.isSelected && $0.entity.identifier == entity.identifier }, "An inactive Columns trail must not be reported as selected.")
                app.typeKey(.leftArrow, modifierFlags: [])
            }
            waitForArchiveSelection(item, in: window)
            let annotations = try await definitions.entities["ZforgeFileArchiveEntity"].viewAnnotations()
            XCTAssertTrue(annotations.contains { $0.isSelected && $0.entity.identifier == entity.identifier }, "The selected archive must retain its published identity in \(mode).")
        }
    }

    @MainActor
    private func waitForArchiveSelection(_ item: XCUIElement, in window: XCUIElement) {
        // The single tap commits after native double-click disambiguation.
        // Wait for observable selection rather than sleeping or querying stale state.
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"), object: item)
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: window.buttons["archive-contextual-action"])
        XCTAssertEqual(XCTWaiter.wait(for: [selected, enabled], timeout: 5), .completed, "The visible archive selection and toolbar action must both commit.")
    }
}
