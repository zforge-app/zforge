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
    func testColumnPreviewRecalculatesWidthForNewDepth() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1400", "--ui-view-mode", "columns",
            "-appLanguagePreference", "english"
        ]
        app.launch()

        let rootFile = app.staticTexts["Welcome.txt"]
        XCTAssertTrue(rootFile.waitForExistence(timeout: 5))
        rootFile.click()
        let preview = app.descendants(matching: .any)["column-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let rootWidth = preview.frame.width

        app.staticTexts["Sample.zip"].click()
        let nestedFile = app.staticTexts["Inside.txt"]
        XCTAssertTrue(nestedFile.waitForExistence(timeout: 5))
        nestedFile.click()
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let nestedWidth = preview.frame.width

        XCTAssertGreaterThan(rootWidth, nestedWidth)
        XCTAssertGreaterThanOrEqual(nestedWidth, 240)
    }

    @MainActor
    func testColumnPreviewKeepsExpandedTerminalAlignment() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1200", "--ui-view-mode", "columns",
            "-browser.finderColumnWidth", "600", "-browser.scale", "1",
            "-browser.previewVisible.columns", "YES", "-appLanguagePreference", "english"
        ]
        app.launch()

        let rootColumn = app.descendants(matching: .any)["browser-column-0"]
        XCTAssertTrue(rootColumn.waitForExistence(timeout: 5))
        let rootFile = rootColumn.staticTexts["Welcome.txt"]
        XCTAssertTrue(rootFile.waitForExistence(timeout: 5))
        rootFile.click()

        let preview = app.descendants(matching: .any)["column-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let initialPreviewWidth = preview.frame.width

        rootColumn.staticTexts["Sample.zip"].click()
        let childColumn = app.descendants(matching: .any)["browser-column-1"]
        XCTAssertTrue(childColumn.waitForExistence(timeout: 5))
        let expandedFrame = childColumn.frame
        XCTAssertGreaterThan(expandedFrame.width, initialPreviewWidth)

        rootFile.click()
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let replacementFrame = preview.frame
        XCTAssertEqual(replacementFrame.width, expandedFrame.width, accuracy: 1)
        XCTAssertEqual(replacementFrame.minX, expandedFrame.minX, accuracy: 1)
        XCTAssertEqual(replacementFrame.maxX, expandedFrame.maxX, accuracy: 1)

        let clippedSampleLabel = rootColumn.staticTexts["Sample.zip"]
        clippedSampleLabel.coordinate(
            withNormalizedOffset: CGVector(dx: 2, dy: 0.5)
        ).click()
        XCTAssertTrue(childColumn.waitForExistence(timeout: 5))
        XCTAssertEqual(childColumn.frame.minX, expandedFrame.minX, accuracy: 1)
        XCTAssertEqual(childColumn.frame.width, expandedFrame.width, accuracy: 1)
    }

    @MainActor
    func testColumnPreviewRefitsAfterUserScrollsLeft() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1200", "--ui-view-mode", "columns",
            "-browser.finderColumnWidth", "600", "-browser.scale", "1",
            "-browser.previewVisible.columns", "YES", "-appLanguagePreference", "english"
        ]
        app.launch()

        let rootColumn = app.descendants(matching: .any)["browser-column-0"]
        let window = app.windows.firstMatch
        XCTAssertTrue(rootColumn.waitForExistence(timeout: 5))
        XCTAssertTrue(window.exists)
        let initialTitle = window.title
        rootColumn.staticTexts["Welcome.txt"].click()

        let preview = app.descendants(matching: .any)["column-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let firstWidth = preview.frame.width

        rootColumn.staticTexts["Sample.zip"].click()
        let childColumn = app.descendants(matching: .any)["browser-column-1"]
        XCTAssertTrue(childColumn.waitForExistence(timeout: 5))
        rootColumn.staticTexts["Welcome.txt"].click()
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        let expandedWidth = preview.frame.width
        XCTAssertGreaterThan(expandedWidth, firstWidth)

        let scrolledRootX = rootColumn.frame.minX
        rootColumn.scroll(byDeltaX: 400, deltaY: 0)
        if rootColumn.frame.minX <= scrolledRootX + 10 {
            rootColumn.scroll(byDeltaX: -800, deltaY: 0)
        }
        XCTAssertEqual(window.title, initialTitle)
        XCTAssertGreaterThan(rootColumn.frame.minX, scrolledRootX + 10)
        XCTAssertGreaterThan(preview.frame.maxX, window.frame.maxX + 10)
        XCTAssertEqual(preview.frame.width, expandedWidth, accuracy: 1)

        rootColumn.staticTexts["Another.txt"].click()
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertLessThan(preview.frame.width, expandedWidth)
        XCTAssertGreaterThanOrEqual(preview.frame.width, 240)
        XCTAssertLessThanOrEqual(preview.frame.maxX, window.frame.maxX)

        rootColumn.staticTexts["Sample.zip"].click()
        XCTAssertTrue(childColumn.waitForExistence(timeout: 5))
        XCTAssertEqual(childColumn.frame.width, expandedWidth, accuracy: 1)
        XCTAssertLessThanOrEqual(childColumn.frame.maxX, window.frame.maxX)
    }

    @MainActor
    func testRecentsShowsOriginalOnlyOnceWhenArchiveSessionsContainCopies() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-recents-duplicates", "--ui-view-mode", "list",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        let archive = app.staticTexts["Sample.zip"]
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Sample.zip").count, 1)
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
        app.typeKey("h", modifierFlags: [.command, .shift])
        let movedFromRecents = NSPredicate(format: "label != %@", "Recents")
        expectation(for: movedFromRecents, evaluatedWith: app.windows.firstMatch)
        waitForExpectations(timeout: 3)

        let contextualAction = app.buttons["archive-contextual-action"]
        XCTAssertTrue(contextualAction.waitForExistence(timeout: 2))
        XCTAssertFalse(contextualAction.isEnabled)

        app.typeKey(.downArrow, modifierFlags: [])

        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: contextualAction)
        waitForExpectations(timeout: 2)
    }

    @MainActor
    func testZoomShortcutsUpdateTheActiveView() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-view-mode", "list",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        let browser = app.descendants(matching: .any)["browser-mode-list"]
        XCTAssertTrue(browser.waitForExistence(timeout: 5))
        app.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "100%")
        app.typeKey("=", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "110%")
        app.typeKey("-", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "100%")
    }

    @MainActor
    func testArchiveActionsMatchToolbarAndSecondaryMenus() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1100",
            "--ui-view-mode", "list", "-appLanguagePreference", "english"
        ]
        app.launch()
        let archive = app.staticTexts["Sample.zip"]
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.click()

        let toolbarMenu = app.buttons["toolbar-more-menu"]
        XCTAssertTrue(toolbarMenu.waitForExistence(timeout: 2))
        toolbarMenu.click()
        for title in ["Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the toolbar menu")
        }
        XCTAssertFalse(app.menuItems["Compress"].exists)
        app.typeKey(.escape, modifierFlags: [])

        archive.rightClick()
        for title in ["Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the secondary menu")
        }
        XCTAssertFalse(app.menuItems["Compress"].exists)
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
            let menuItem = app.windows.firstMatch.menuItems[name].firstMatch
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
        let menuItem = app.windows.firstMatch.menuItems[name].firstMatch
        XCTAssertTrue(menuItem.waitForExistence(timeout: 2))
        menuItem.click()
    }
}
