import AppIntentsTesting
import XCTest

final class ProbeDispatchTests: XCTestCase {
    @MainActor
    func testNativeListReportsItsSelectedSyntheticEntity() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        app.launchArguments = ["--probe-selected-context"]
        app.launch()
        defer { app.terminate() }
        app.activate()
        XCTAssertTrue(marker("The synthetic entity is indexed.", in: app).waitForExistence(timeout: 5))
        let list = app.descendants(matching: .any)["probe.selectedFixture"].firstMatch
        let row = list.descendants(matching: .outlineRow).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(row.isSelected, "The standard List control must visibly select the synthetic entity.")
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        let annotations = try await definitions.entities["ProbeEntity"].viewAnnotations()
        print("Probe selected context diagnostic: count=\(annotations.count); selected=\(annotations.filter { $0.isSelected }.count)")
        XCTAssertEqual(annotations.count, 1)
        XCTAssertTrue(annotations.first?.isSelected == true, "The native List annotation must retain its actual selection.")
    }

    @MainActor
    func testBundledFileProvidesAnOnscreenAnnotation() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        app.launch()
        defer { app.terminate() }
        app.activate()
        XCTAssertTrue(marker("The synthetic entity is indexed.", in: app).waitForExistence(timeout: 5))
        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        let annotations = try await definitions.entities["ProbeEntity"].viewAnnotations()
        XCTAssertEqual(annotations.count, 1)
    }

    @MainActor
    func testNamedEntityRunsOpenIntentThroughSystem() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(marker("No OpenIntent has run.", in: app).waitForExistence(timeout: 5))

        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        let entities = try await definitions.entities["ProbeEntity"].entities(matching: "Lyra Control")
        XCTAssertEqual(entities.count, 1)
        let entity = try XCTUnwrap(entities.first)
        try await definitions.intents["OpenProbeContentIntent"].makeIntent(target: entity).run()

        XCTAssertTrue(marker("The OpenIntent ran.", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testSpotlightEntityRunsOpenIntentThroughSystem() async throws {
        let app = XCUIApplication(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(marker("No OpenIntent has run.", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(marker("The synthetic entity is indexed.", in: app).waitForExistence(timeout: 5))

        let definitions = IntentDefinitions(bundleIdentifier: "io.libor.ZforgeIntentProbe")
        let entities = try await definitions.entities["ProbeEntity"].spotlightQuery("Lyra Control")
        XCTAssertEqual(entities.count, 1)
        let entity = try XCTUnwrap(entities.first)
        try await definitions.intents["OpenProbeContentIntent"].makeIntent(target: entity).run()

        XCTAssertTrue(marker("The OpenIntent ran.", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    private func marker(_ text: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "value == %@", text)).firstMatch
    }
}
