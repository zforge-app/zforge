//
//  ZforgeUITests.swift
//  ZforgeUITests
//
//  Created by Felipe Libório on 12/07/26.
//

import XCTest

final class ZforgeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Fixture Folder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Welcome.txt"].exists)
    }

    @MainActor
    func testArrowNavigationKeepsContentFocusAfterChangingView() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "1100",
            "--ui-view-mode", "list",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Fixture Folder"].waitForExistence(timeout: 5))

        selectView(named: "Icons", in: app)
        selectView(named: "List", in: app)

        let contextualAction = app.buttons["archive-contextual-action"]
        XCTAssertTrue(contextualAction.waitForExistence(timeout: 2))
        XCTAssertFalse(contextualAction.isEnabled)

        app.typeKey(.downArrow, modifierFlags: [])

        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: contextualAction)
        waitForExpectations(timeout: 2)
    }

    @MainActor
    func testNarrowToolbarUsesOneFunctionalMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "650",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 5))

        let overflowButton = app.buttons["toolbar-overflow-menu"]
        XCTAssertTrue(overflowButton.waitForExistence(timeout: 2))
        XCTAssertEqual(overflowButton.value as? String, "Collapsed")
        overflowButton.click()
        XCTAssertEqual(overflowButton.value as? String, "Expanded")

        for title in [
            "View", "Compress Selected", "Share", "Open", "Quick Look",
            "Get Info", "Add Tag", "Rename", "Duplicate"
        ] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the unified toolbar menu")
        }

        app.typeKey(.escape, modifierFlags: [])
        let collapsed = NSPredicate(format: "value == %@", "Collapsed")
        expectation(for: collapsed, evaluatedWith: overflowButton)
        waitForExpectations(timeout: 2)
        app.staticTexts["Welcome.txt"].click()
        overflowButton.click()
        let archiveAction = app.menuItems["Compress Selected"]
        XCTAssertTrue(archiveAction.isEnabled)
        archiveAction.click()
        XCTAssertTrue(app.staticTexts["Compress selected items."].waitForExistence(timeout: 2))

        selectView(named: "List", in: app)
        let listBrowser = app.descendants(matching: .any)["browser-mode-list"]
        XCTAssertTrue(listBrowser.waitForExistence(timeout: 2))
    }

    @MainActor
    func testIntermediateToolbarKeepsViewOutsideOverflow() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "720",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["view-mode-selector-compact"].waitForExistence(timeout: 2))

        let overflowButton = app.buttons["toolbar-overflow-menu"]
        XCTAssertTrue(overflowButton.waitForExistence(timeout: 2))
        overflowButton.click()
        XCTAssertFalse(app.menuItems["View"].exists)
        for title in ["Compress Selected", "Share", "Open", "Quick Look", "Get Info"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the toolbar overflow")
        }

        app.typeKey(.escape, modifierFlags: [])
        selectView(named: "List", in: app)
        let listBrowser = app.descendants(matching: .any)["browser-mode-list"]
        XCTAssertTrue(listBrowser.waitForExistence(timeout: 2))
    }

    @MainActor
    func testViewCompactsBeforeArchiveActionIsHidden() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "860",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Fixture Folder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["view-mode-selector-compact"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.descendants(matching: .any)["view-mode-icons"].exists)
        XCTAssertTrue(app.buttons["archive-contextual-action"].waitForExistence(timeout: 2))

        let overflowButton = app.buttons["toolbar-overflow-menu"]
        XCTAssertTrue(overflowButton.waitForExistence(timeout: 2))
        overflowButton.click()
        XCTAssertFalse(app.menuItems["View"].exists)
        XCTAssertFalse(app.menuItems["Compress Selected"].exists)
        for title in ["Share", "Open", "Quick Look", "Get Info", "Add Tag", "Rename", "Duplicate"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the partial toolbar overflow")
        }
    }

    @MainActor
    func testKeyboardShortcutHelpOpensAndFilters() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 5))

        app.typeKey("/", modifierFlags: .command)

        let shortcutsWindow = app.windows["Keyboard Shortcuts"]
        XCTAssertTrue(shortcutsWindow.waitForExistence(timeout: 3))
        let searchField = shortcutsWindow.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.click()
        searchField.typeText("Rename")

        XCTAssertTrue(shortcutsWindow.staticTexts["Rename"].waitForExistence(timeout: 2))
        XCTAssertFalse(shortcutsWindow.staticTexts["New Folder"].exists)
    }

    @MainActor
    func testSidebarCannotConsumeLast360Points() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "900",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Fixture Folder"].waitForExistence(timeout: 5))

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 2))
        let sidebar = app.descendants(matching: .any)["browser-sidebar"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 2))

        let divider = sidebar.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
        let farRight = window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        divider.press(forDuration: 0.15, thenDragTo: farRight)

        let maximumSidebarWidth = window.frame.width - 360
        XCTAssertLessThanOrEqual(sidebar.frame.width, maximumSidebarWidth + 4)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-fixtures"]
            app.launch()
        }
    }

    @MainActor
    private func selectView(named name: String, in app: XCUIApplication) {
        let identifier = "view-mode-\(name.lowercased())"
        let segment = app.descendants(matching: .any)[identifier]
        if segment.exists {
            segment.click()
            return
        }

        let compactButton = app.buttons["view-mode-selector-compact"]
        if compactButton.exists {
            compactButton.click()
            let menuItem = app.menuItems[name]
            XCTAssertTrue(menuItem.waitForExistence(timeout: 2))
            menuItem.click()
            return
        }

        let overflowButton = app.buttons["toolbar-overflow-menu"]
        XCTAssertTrue(overflowButton.waitForExistence(timeout: 2))
        overflowButton.click()
        let viewItem = app.menuItems["View"]
        XCTAssertTrue(viewItem.waitForExistence(timeout: 2))
        viewItem.click()
        let menuItem = app.menuItems[name]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 2))
        menuItem.click()
    }
}
