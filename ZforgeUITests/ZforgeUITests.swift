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
    func testViewModeIsIndependentBetweenWindows() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", "icons",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        app.activate()
        defer { app.terminate() }
        let content = { (mode: String) in
            app.descendants(matching: .any).matching(identifier: "browser-mode-\(mode)")
        }
        XCTAssertTrue(content("icons").firstMatch.waitForExistence(timeout: 5))
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(content("list").firstMatch.waitForExistence(timeout: 5))
        app.typeKey("n", modifierFlags: .command)
        XCTAssertTrue(content("icons").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.windows.count, 2)
        XCTAssertEqual(content("list").count, 1)

        // Commands target the focused scene and leave the first window in List.
        for (key, mode) in [("3", "columns"), ("4", "gallery"), ("1", "icons")] {
            app.typeKey(key, modifierFlags: .command)
            XCTAssertTrue(content(mode).firstMatch.waitForExistence(timeout: 5))
            XCTAssertEqual(content("list").count, 1)
        }
        // Exercise the toolbar binding in the window that is still in Icons.
        let iconsWindow = app.windows.containing(.any, identifier: "browser-mode-icons").firstMatch
        let gallery = iconsWindow.descendants(matching: .any)["view-mode-gallery"]
        XCTAssertTrue(gallery.exists)
        gallery.click()
        XCTAssertTrue(content("gallery").firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(content("list").count, 1)
        XCTAssertEqual(content("icons").count, 0)
    }

    @MainActor
    func testBlankAreaUsesMoreMenuInEveryView() throws {
        for mode in ["icons", "list", "columns", "gallery"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", mode, "-appLanguagePreference", "english"]
            app.launch()
            app.activate()
            let file = app.staticTexts["Welcome.txt"].firstMatch
            XCTAssertTrue(file.waitForExistence(timeout: 5), mode)
            let content = app.descendants(matching: .any)["browser-mode-\(mode)"].firstMatch
            XCTAssertTrue(content.exists, mode)
            let area = content.frame
            let window = app.windows.firstMatch
            let blank = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: area.minX - window.frame.minX + area.width * (mode == "gallery" ? 0.95 : 0.2),
                dy: area.minY - window.frame.minY + area.height * (mode == "gallery" ? 0.97 : 0.8)
            ))
            let more = app.buttons["toolbar-more-menu"]
            XCTAssertTrue(more.exists, mode)
            for selected in [false, true] {
                if selected { file.click(); file.click() } else { blank.click() }
                more.click()
                XCTAssertTrue(app.menuItems["Open"].waitForExistence(timeout: 2), mode)
                XCTAssertEqual(app.menuItems["Open"].isEnabled, selected, mode)
                let expected = app.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }
                app.typeKey(.escape, modifierFlags: [])
                blank.rightClick()
                XCTAssertTrue(app.menuItems["Open"].waitForExistence(timeout: 2), "\(mode), selected: \(selected)")
                XCTAssertEqual(app.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }, expected, mode)
                app.typeKey(.escape, modifierFlags: [])
            }
            // The blank-area monitor must leave the item-specific menu intact.
            file.rightClick()
            XCTAssertTrue(app.menuItems["Open with"].waitForExistence(timeout: 2), mode)
            app.typeKey(.escape, modifierFlags: [])
            app.terminate()
        }
    }

    @MainActor
    func testTagEditorIsSharedByToolbarAndContextMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        app.launch()
        app.activate()
        let file = app.staticTexts["Welcome.txt"].firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5))
        let rowFrame = file.frame
        let window = app.windows.firstMatch
        let rowPoint = window.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: rowFrame.midX - window.frame.minX, dy: rowFrame.midY - window.frame.minY)
        )
        file.click()
        file.click()
        let tags = app.buttons["edit-tags-action"]
        XCTAssertTrue(tags.exists)
        XCTAssertTrue(tags.isEnabled)
        tags.click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["New Tag"].exists)
        let name = app.textFields["Tag name"]
        name.click()
        name.typeText("UI draft tag")
        app.buttons["Add"].click()
        XCTAssertTrue(app.buttons["UI draft tag"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.typeKey(.escape, modifierFlags: [])
        let dismissed = NSPredicate(format: "exists == false")
        expectation(for: dismissed, evaluatedWith: app.sheets.firstMatch)
        waitForExpectations(timeout: 3)
        rowPoint.rightClick()
        let edit = app.menuItems["Edit Tags"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        let quickButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quick-tag-"))
        XCTAssertEqual(quickButtons.count, 7)
        let applied = app.buttons["quick-tag-Red"]
        XCTAssertTrue(applied.exists)
        let contextCapture = XCTAttachment(screenshot: app.screenshot())
        contextCapture.name = "Quick tag circles"
        contextCapture.lifetime = .keepAlways
        add(contextCapture)
        XCTAssertEqual(applied.value as? String, "1", app.debugDescription)
        applied.hover()
        let hover = XCTAttachment(screenshot: app.screenshot())
        hover.name = "Applied tag hover"
        hover.lifetime = .keepAlways
        add(hover)
        edit.click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["UI draft tag"].exists)
        app.buttons["Cancel"].click()
    }

    @MainActor
    func testIconModeTagContextMenuPreservesSelection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", "icons", "-appLanguagePreference", "english"]
        app.launch()
        app.activate()
        let file = app.staticTexts["Welcome.txt"].firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5))
        let frame = file.frame
        let window = app.windows.firstMatch
        let rowPoint = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX - window.frame.minX, dy: frame.midY - window.frame.minY))
        file.click()
        file.click()
        XCTAssertTrue(app.buttons["edit-tags-action"].isEnabled)
        rowPoint.rightClick()
        XCTAssertTrue(app.menuItems["Edit Tags"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quick-tag-")).count, 7)
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(app.buttons["edit-tags-action"].isEnabled)
    }

    @MainActor
    func testTagContextMenuInGalleryAndColumns() throws {
        for mode in ["gallery", "columns"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", mode, "-appLanguagePreference", "english"]
            app.launch()
            app.activate()
            let file = app.staticTexts["Welcome.txt"].firstMatch
            XCTAssertTrue(file.waitForExistence(timeout: 5), mode)
            file.rightClick()
            XCTAssertTrue(app.menuItems["Edit Tags"].waitForExistence(timeout: 3), mode)
            XCTAssertEqual(app.buttons["quick-tag-Red"].value as? String, "1", mode)
            app.typeKey(.escape, modifierFlags: [])
            app.terminate()
        }
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
    func testCompressionProfilesAreAvailableInSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "-appLanguagePreference", "english"]
        app.launch()
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Compression"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["Default compression profile"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["Archive format"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.buttons["Save as New Profile"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCustomCompressionShowsProfileOptions() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-view-mode", "list",
            "-appLanguagePreference", "english"
        ]
        app.launch()
        app.activate()
        let file = app.staticTexts["Welcome.txt"]
        if !file.waitForExistence(timeout: 5) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(file.waitForExistence(timeout: 5))
        file.rightClick()
        let custom = app.menuItems["Compress Custom…"]
        XCTAssertTrue(custom.waitForExistence(timeout: 3))
        custom.click()
        XCTAssertTrue(app.descendants(matching: .any)["Compression profile"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any)["Archive format"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(app.textFields["Profile name"].exists)
        XCTAssertFalse(app.buttons["Save Profile"].exists)
        XCTAssertFalse(app.buttons["Save as New Profile"].exists)
        let autoProfile = app.popUpButtons.matching(
            NSPredicate(format: "value == %@", "Auto")
        ).firstMatch
        XCTAssertTrue(autoProfile.exists)
        let panel = app.sheets.firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertLessThan(panel.frame.width, 700)
        XCTAssertLessThan(panel.frame.height, 700)
        let nameField = app.textFields["compression-save-name"]
        let tagsField = app.textFields["compression-save-tags"]
        let whereButton = app.buttons["compression-save-where"]
        XCTAssertTrue(nameField.exists)
        XCTAssertTrue(tagsField.exists)
        XCTAssertTrue(whereButton.exists)
        XCTAssertGreaterThan(nameField.frame.width, 380)
        XCTAssertLessThan(abs(nameField.frame.width - tagsField.frame.width), 5)
        XCTAssertLessThan(abs(nameField.frame.maxX - whereButton.frame.maxX), 5)
        XCTAssertGreaterThan(tagsField.frame.minY, nameField.frame.maxY)
        XCTAssertGreaterThan(whereButton.frame.minY, tagsField.frame.maxY)
        let format = app.popUpButtons["Archive format"]
        XCTAssertTrue(format.exists, panel.debugDescription)
        let dictionary = app.popUpButtons["Dictionary size"]
        XCTAssertTrue(dictionary.exists)
        XCTAssertGreaterThan(format.frame.midY, app.staticTexts["Archive format"].frame.midY)
        XCTAssertGreaterThan(dictionary.frame.midY, app.staticTexts["Dictionary size"].frame.midY)
        XCTAssertLessThan(abs(format.frame.width - dictionary.frame.width), 5)
        let profile = app.popUpButtons["Compression profile"]
        XCTAssertTrue(profile.exists)
        let title = panel.staticTexts["Compress Custom…"]
        let profileLabel = panel.staticTexts["Compression profile"]
        let formatLabel = panel.staticTexts["Archive format"]
        let saveButton = panel.buttons["Save"]
        XCTAssertLessThan(abs(title.frame.minX - profileLabel.frame.minX), 3)
        XCTAssertLessThan(abs(title.frame.minX - formatLabel.frame.minX), 3)
        XCTAssertLessThan(abs(title.frame.minX - format.frame.minX), 3)
        XCTAssertLessThan(abs(profile.frame.maxX - dictionary.frame.maxX), 3)
        XCTAssertLessThan(abs(nameField.frame.maxX - dictionary.frame.maxX), 5)
        XCTAssertLessThan(abs(whereButton.frame.maxX - dictionary.frame.maxX), 5)
        XCTAssertLessThan(abs(saveButton.frame.maxX - dictionary.frame.maxX), 5)
        let compactScreenshot = XCTAttachment(screenshot: panel.screenshot())
        compactScreenshot.name = "Compress Custom compact"
        compactScreenshot.lifetime = .keepAlways
        add(compactScreenshot)
        whereButton.click()
        let folderChooser = app.dialogs["Choose Folder…"]
        XCTAssertTrue(folderChooser.waitForExistence(timeout: 5), app.debugDescription)
        folderChooser.buttons["Cancel"].click()
        format.click()
        app.menuItems["7z"].click()
        XCTAssertTrue(
            (nameField.value as? String)?.hasPrefix("Welcome") == true,
            "Changing an archive option must preserve the proposed file name."
        )
        let solid = app.checkBoxes["Solid archive"]
        let password = app.checkBoxes["Protect with password"]
        XCTAssertTrue(solid.waitForExistence(timeout: 3))
        XCTAssertTrue(password.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(password.frame.minY, solid.frame.minY)
        XCTAssertLessThan(abs(password.frame.minX - solid.frame.minX), 12)
        let compactHeight = panel.frame.height
        password.click()
        XCTAssertTrue(
            (nameField.value as? String)?.hasPrefix("Welcome") == true,
            "Expanding password options must preserve the proposed file name."
        )
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(passwordField.frame.minY, password.frame.maxY)
        XCTAssertLessThan(abs(passwordField.frame.minX - password.frame.minX), 30)
        XCTAssertGreaterThan(app.checkBoxes["Encrypt file names"].frame.minX, password.frame.maxX)
        XCTAssertGreaterThan(panel.frame.height, compactHeight + 40)
        XCTAssertTrue(
            (nameField.value as? String)?.hasPrefix("Welcome") == true,
            "Resizing the panel must preserve the proposed file name."
        )
        let passwordScreenshot = XCTAttachment(screenshot: panel.screenshot())
        passwordScreenshot.name = "Compress Custom with password"
        passwordScreenshot.lifetime = .keepAlways
        add(passwordScreenshot)
        passwordField.click()
        XCTAssertTrue(
            (nameField.value as? String)?.hasPrefix("Welcome") == true,
            "Leaving the name field must preserve the proposed file name."
        )
        password.click()
        XCTAssertFalse(passwordField.exists)
        XCTAssertLessThan(abs(panel.frame.height - compactHeight), 5)
        app.typeKey(.escape, modifierFlags: [])
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
        let archive = app.staticTexts["Sample.zip"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        let frame = archive.frame
        let window = app.windows.firstMatch
        let rowPoint = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX - window.frame.minX, dy: frame.midY - window.frame.minY))
        archive.click()

        let toolbarMenu = app.buttons["toolbar-more-menu"]
        XCTAssertTrue(toolbarMenu.waitForExistence(timeout: 2))
        toolbarMenu.click()
        for title in ["Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate", "Add to Archive…"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the toolbar menu")
        }
        XCTAssertFalse(app.menuItems["Compress"].exists)
        app.typeKey(.escape, modifierFlags: [])

        rowPoint.rightClick()
        for title in ["Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate", "Add to Archive…"] {
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
            "Get Info", "Edit Tags", "Rename", "Duplicate"
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
        for title in ["Share", "Open", "Quick Look", "Get Info", "Edit Tags", "Rename", "Duplicate"] {
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
