//
//  ZforgeUITests.swift
//  ZforgeUITests
//
//  Created by Felipe Libório on 12/07/26.
//

import XCTest
import AppKit

final class ZforgeUITests: XCTestCase {

    @MainActor
    private func waitForSelected(_ element: XCUIElement) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "selected == true"), object: element
        )], timeout: 3) == .completed
    }

    /// Real menu bar, Option alternate, ⌃⌥⌘N/⇧⌘N delivery and inline editor in
    /// List. Parity across the four modes is covered offscreen by
    /// `FolderWithSelectionFlowTests` and `FolderWithSelectionTests`.
    @MainActor
    func testNewFolderWithSelectionMenuAndShortcutInListMode() throws {
        let mode = "list"
        do {
            for activation in ["shortcut", "menu"] {
                let app = XCUIApplication()
                app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "1100",
                    "--ui-view-mode", mode, "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
                addTeardownBlock { app.terminate() }
                launchArchiveFixture(app)
                defer { app.terminate() }
                app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.75)).click()

                let local = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt").firstMatch.staticTexts["Local.txt"].firstMatch
                let archive = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch.staticTexts["Sample.zip"].firstMatch
                XCTAssertTrue(local.waitForExistence(timeout: 8), mode)
                let localCell = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt").firstMatch
                let archiveCell = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
                local.click()
                XCTAssertTrue(waitForSelected(localCell), mode)
                XCUIElement.perform(withKeyModifiers: .command) {
                    archive.click()
                    XCTAssertTrue(waitForSelected(archiveCell), mode)
                }
                XCTAssertTrue(localCell.isSelected, mode)

                if activation == "menu" {
                    XCUIElement.perform(withKeyModifiers: .option) {
                        app.menuBars.menuBarItems["File"].click()
                        let action = app.menuItems["New Folder with Selection"]
                        XCTAssertTrue(action.isEnabled, mode)
                        let enabledMenu = XCTAttachment(screenshot: app.screenshot())
                        enabledMenu.name = "Enabled selection alternate - \(mode)"
                        enabledMenu.lifetime = .keepAlways
                        add(enabledMenu)
                        action.hover()
                        app.typeKey(.return, modifierFlags: .option)
                    }
                } else {
                    app.typeKey("n", modifierFlags: [.control, .option, .command])
                }

                let editor = app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH %@", "rename-field-")).firstMatch
                XCTAssertTrue(editor.waitForExistence(timeout: 8), app.debugDescription)
                XCTAssertEqual(editor.value as? String, "untitled folder", mode)
                editor.typeText("Grouped Items")
                app.typeKey(.return, modifierFlags: [])
                let folder = app.descendants(matching: .any).matching(identifier: "browser-item-Grouped Items").firstMatch.staticTexts["Grouped Items"].firstMatch
                XCTAssertTrue(folder.waitForExistence(timeout: 8), app.debugDescription)
                folder.doubleClick()
                XCTAssertTrue(app.windows["Grouped Items"].firstMatch.waitForExistence(timeout: 8), mode)
                XCTAssertTrue(local.waitForExistence(timeout: 8), mode)
                XCTAssertTrue(archive.waitForExistence(timeout: 8), mode)
                app.buttons["Back"].firstMatch.click()
                XCTAssertTrue(folder.waitForExistence(timeout: 8), mode)
                XCTAssertFalse(local.exists, "Grouped file must be removed from its original folder in \(mode)")
                XCTAssertFalse(archive.exists, "Grouped archive must be removed from its original folder in \(mode)")
                app.typeKey("n", modifierFlags: [.shift, .command])
                XCTAssertTrue(editor.waitForExistence(timeout: 8), "The original New Folder shortcut must still work in \(mode)")
                app.typeKey(.escape, modifierFlags: [])
            }
        }
    }

    /// Real Option alternation in the menu bar, in List. The native alternate
    /// pairing is characterized by `FileMenuCommandTests` and the disabled state
    /// without a selection in every mode by `FolderWithSelectionFlowTests`.
    @MainActor
    func testFolderSelectionMenuAlternatesWithOptionInListMode() throws {
        let mode = "list"
        do {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "1100",
                "--ui-view-mode", mode, "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
            addTeardownBlock { app.terminate() }
            launchArchiveFixture(app)
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.75)).click()
            let selectedCells = app.descendants(matching: .any).matching(NSPredicate(
                format: "identifier BEGINSWITH %@ AND selected == true", "browser-item-"
            ))
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count == 0"), object: selectedCells
            )], timeout: 3), .completed, mode)
            app.menuBars.menuBarItems["File"].click()
            XCTAssertTrue(app.menuItems["New Folder"].exists, mode)
            let normal = XCTAttachment(screenshot: app.screenshot())
            normal.name = "File menu without Option - \(mode)"
            normal.lifetime = .keepAlways
            add(normal)
            XCUIElement.perform(withKeyModifiers: .option) {
                let alternate = app.menuItems["New Folder with Selection"]
                XCTAssertTrue(alternate.exists, mode)
                XCTAssertFalse(alternate.isEnabled, mode)
                let capture = XCTAttachment(screenshot: app.screenshot())
                capture.name = "File menu with Option - \(mode)"
                capture.lifetime = .keepAlways
                add(capture)
            }
            let released = XCTAttachment(screenshot: app.screenshot())
            released.name = "File menu after releasing Option - \(mode)"
            released.lifetime = .keepAlways
            add(released)
            app.terminate()
        }
    }

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
    func testViewModeIsPerWindowAndLastClosedWindowRestoresIt() throws {
        // Per-mode parity of window isolation and of both close orders lives in
        // WindowViewModeTests; this keeps the real shortcut, toolbar, close, Quit
        // and relaunch path for one representative sequence.
        let app = XCUIApplication()
        app.launchEnvironment["ZFORGE_UI_PREFERENCES_SUITE"] = "ZforgeViewRelaunch-\(UUID().uuidString)"
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", "icons",
            "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)
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

        // Close the most recently changed window first: the last window closed,
        // not the latest change, supplies the next mode.
        let listWindow = app.windows.containing(.any, identifier: "browser-mode-list").firstMatch
        let galleryWindow = app.windows.containing(.any, identifier: "browser-mode-gallery").firstMatch
        galleryWindow.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(listWindow.exists)
        listWindow.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertTrue(app.windows.firstMatch.waitForNonExistence(timeout: 5))
        // Opening again in the same process must also use the saved mode.
        app.typeKey("n", modifierFlags: .command)
        let restored = app.descendants(matching: .any)["browser-mode-list"].firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 5))
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100",
            "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        XCTAssertTrue(restored.waitForExistence(timeout: 5), "Relaunch must restore list")
    }

    /// Real File menu presentation and the Open with submenu in List. Order
    /// and alternates of the native menu are characterized by `FileMenuCommandTests`,
    /// which also covers availability for every mode.
    @MainActor
    func testFileOpenPrecedesOpenWithAndTracksSelectionInListMode() throws {
        let mode = "list"
        do {
            let app = XCUIApplication()
            app.launchArguments = [
                "--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", mode,
                "-appLanguagePreference", "english"
            ]
            launchArchiveFixture(app)
            defer { app.terminate() }

            let welcome = app.descendants(matching: .any)
                .matching(identifier: "browser-item-Welcome.txt").firstMatch
                .staticTexts["Welcome.txt"].firstMatch
            let another = app.descendants(matching: .any)
                .matching(identifier: "browser-item-Another.txt").firstMatch
                .staticTexts["Another.txt"].firstMatch
            XCTAssertTrue(welcome.waitForExistence(timeout: 5), mode)
            XCTAssertTrue(another.exists, mode)

            // Establish the empty-selection precondition by clicking the background.
            let content = app.descendants(matching: .any)["browser-mode-\(mode)"].firstMatch
            let area = content.frame
            let window = app.windows.firstMatch
            window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: area.minX - window.frame.minX + area.width * 0.2,
                dy: area.minY - window.frame.minY + area.height * 0.8
            )).click()
            let emptyMenu = openFileMenu(in: app)
            assertOpenPrecedesOpenWith(in: emptyMenu, open: "Open", openWith: "Open with", context: mode)
            XCTAssertFalse(emptyMenu.menuItems["Open"].isEnabled, "Empty selection: \(mode)")
            assertOpenWithAvailability(in: emptyMenu, app: app, enabled: false, context: "Empty selection: \(mode)")
            app.typeKey(.escape, modifierFlags: [])

            welcome.click()
            let selectedMenu = openFileMenu(in: app)
            XCTAssertTrue(selectedMenu.menuItems["Open"].isEnabled, "Single selection: \(mode)")
            assertOpenWithAvailability(in: selectedMenu, app: app, enabled: true, context: "Single selection: \(mode)")
            app.typeKey(.escape, modifierFlags: [])

            XCUIElement.perform(withKeyModifiers: [.command]) { another.click() }
            let multipleMenu = openFileMenu(in: app)
            XCTAssertTrue(multipleMenu.menuItems["Open"].isEnabled, "Multiple selection: \(mode)")
            assertOpenWithAvailability(in: multipleMenu, app: app, enabled: true, context: "Multiple selection: \(mode)")
            assertOpenPrecedesOpenWith(in: multipleMenu, open: "Open", openWith: "Open with", context: mode)
            _ = openFileMenu(in: app)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "File menu Open with multiple selection: \(mode)"
            capture.lifetime = .keepAlways
            add(capture)
            app.typeKey(.escape, modifierFlags: [])
        }
    }

    /// Real File ▸ Open click in Columns, whose Command-click selection does not
    /// expand the container. Navigation in every mode is covered offscreen by
    /// `FileMenuCommandTests`.
    @MainActor
    func testFileOpenNavigatesSelectedFolderAndArchiveInColumnsMode() throws {
        let mode = "columns"
        do {
            let app = XCUIApplication()
            app.launchArguments = [
                "--ui-archive-drag-fixtures", "--ui-window-width", "1100", "--ui-view-mode", mode,
                "-appLanguagePreference", "english"
            ]
            launchArchiveFixture(app)
            defer { app.terminate() }
            let initialTitle = app.windows.firstMatch.title
            let folder = app.descendants(matching: .any)
                .matching(identifier: "browser-item-Dropped").firstMatch
                .staticTexts["Dropped"].firstMatch
            XCTAssertTrue(folder.waitForExistence(timeout: 8), mode)
            // Command-click selects a container without expanding it in Columns.
            // Navigation below therefore has to come from the File command.
            XCUIElement.perform(withKeyModifiers: [.command]) { folder.click() }
            XCTAssertEqual(app.windows.firstMatch.title, initialTitle, mode)
            let folderMenu = openFileMenu(in: app)
            XCTAssertTrue(folderMenu.menuItems["Open"].isEnabled, mode)
            assertOpenWithAvailability(in: folderMenu, app: app, enabled: false, context: mode)
            folderMenu.menuItems["Open"].click()
            XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8), mode)

            app.buttons["Back"].firstMatch.click()
            XCTAssertTrue(app.windows[initialTitle].firstMatch.waitForExistence(timeout: 8), mode)
            let archive = app.descendants(matching: .any)
                .matching(identifier: "browser-item-Sample.zip").firstMatch
                .staticTexts["Sample.zip"].firstMatch
            XCTAssertTrue(archive.waitForExistence(timeout: 8), mode)
            XCUIElement.perform(withKeyModifiers: [.command]) { archive.click() }
            XCTAssertEqual(app.windows.firstMatch.title, initialTitle, mode)
            let archiveMenu = openFileMenu(in: app)
            XCTAssertTrue(archiveMenu.menuItems["Open"].isEnabled, mode)
            archiveMenu.menuItems["Open"].click()
            XCTAssertTrue(app.windows["Sample.zip"].firstMatch.waitForExistence(timeout: 8), mode)
            XCTAssertTrue(app.descendants(matching: .any)
                .matching(identifier: "browser-item-Inside").firstMatch
                .staticTexts["Inside"].firstMatch.waitForExistence(timeout: 8), mode)
            let capture = XCTAttachment(screenshot: app.windows["Sample.zip"].firstMatch.screenshot())
            capture.name = "File Open navigated into archive: \(mode)"
            capture.lifetime = .keepAlways
            add(capture)
        }
    }

    @MainActor
    private func openFileMenu(in app: XCUIApplication) -> XCUIElement {
        app.activate()
        // AX exposes closed menus too; close any previous popup before presenting File.
        app.typeKey(.escape, modifierFlags: [])
        let file = app.menuBars.menuBarItems["File"].firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 2))
        file.click()
        let menu = file.menus.firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        XCTAssertTrue(menu.menuItems["New Zforge Window"].isHittable, "File menu must be visible")
        return menu
    }

    @MainActor
    private func assertOpenWithAvailability(in menu: XCUIElement, app: XCUIApplication, enabled: Bool, context: String) {
        // SwiftUI disables the submenu's actions, while its parent remains enabled in AX.
        menu.menuItems["Open with"].click()
        let other = menu.menuItems["Open with"].menus.firstMatch.menuItems["Other…"].firstMatch
        XCTAssertTrue(other.waitForExistence(timeout: 2), context)
        XCTAssertEqual(other.isEnabled, enabled, context)
        app.typeKey(.leftArrow, modifierFlags: [])
    }

    @MainActor
    private func assertOpenPrecedesOpenWith(
        in menu: XCUIElement, open: String, openWith: String, context: String
    ) {
        // Native menu items expose title rather than label. Direct children keep
        // the order check independent of dynamically populated submenus.
        let entries = menu.children(matching: .menuItem).allElementsBoundByAccessibilityElement.map(\.title)
        XCTAssertEqual(entries.filter { $0 == open }.count, 1, "Unique File Open: \(context), entries: \(entries)")
        XCTAssertEqual(entries.filter { $0 == openWith }.count, 1, "Unique File Open with: \(context)")
        guard let openIndex = entries.firstIndex(of: open),
              let openWithIndex = entries.firstIndex(of: openWith) else {
            XCTFail("Missing File Open or Open with: \(context)")
            return
        }
        XCTAssertEqual(openIndex + 1, openWithIndex, "File Open must immediately precede Open with: \(context)")
    }

    @MainActor
    func testBlankAreaUsesMoreMenuInEveryView() throws {
        for mode in ["icons", "list", "columns", "gallery"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", mode, "-appLanguagePreference", "english"]
            launchArchiveFixture(app)
            app.activate()
            // Preview titles can repeat the file name. Keep every interaction
            // on the actual browser cell when selection opens its preview.
            let file = app.descendants(matching: .any)
                .matching(identifier: "browser-item-Welcome.txt").firstMatch
                .staticTexts["Welcome.txt"].firstMatch
            XCTAssertTrue(file.waitForExistence(timeout: 5), mode)
            let content = app.descendants(matching: .any)["browser-mode-\(mode)"].firstMatch
            XCTAssertTrue(content.exists, mode)
            let area = content.frame
            let window = app.windows.firstMatch
            let popup = window.menus.firstMatch
            let blank = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                // Gallery's inspector inherits the mode identifier. Anchor the
                // empty strip to the actual cell's vertical position instead.
                dx: mode == "gallery" ? window.frame.width - 26 : area.minX - window.frame.minX + area.width * 0.2,
                dy: mode == "gallery" ? file.frame.midY - window.frame.minY : area.minY - window.frame.minY + area.height * 0.8
            ))
            let more = app.buttons["toolbar-more-menu"]
            XCTAssertTrue(more.exists, mode)
            let editTags = app.buttons["edit-tags-action"]
            for selected in [false, true] {
                if selected { file.click(); file.click() } else { blank.click() }
                // The menus' contents for every selection and mode are compared offscreen
                // (BrowserMenuParityTests); one mode keeps the real More button's parity.
                var expected: [String]?
                if mode == "list" {
                    more.click()
                    XCTAssertTrue(popup.menuItems["Open"].waitForExistence(timeout: 2), mode)
                    XCTAssertEqual(popup.menuItems["Open"].isEnabled, selected, mode)
                    expected = popup.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }
                    app.typeKey(.escape, modifierFlags: [])
                }
                blank.rightClick()
                XCTAssertTrue(popup.menuItems["Open"].waitForExistence(timeout: 2), "\(mode), selected: \(selected)")
                XCTAssertEqual(popup.menuItems["Open"].isEnabled, selected, "\(mode), selected: \(selected)")
                XCTAssertFalse(popup.menuItems["Open with"].exists, "A blank area must show the More menu, not an item's menu: \(mode)")
                if let expected {
                    XCTAssertEqual(popup.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }, expected, mode)
                }
                app.typeKey(.escape, modifierFlags: [])
            }
            // The blank-area monitor must leave the item-specific menu intact, and right-clicking
            // the selected item must keep the selection the toolbar acts on.
            XCTAssertTrue(editTags.isEnabled, mode)
            file.rightClick()
            XCTAssertTrue(popup.menuItems["Open with"].waitForExistence(timeout: 2), mode)
            XCTAssertTrue(popup.menuItems["Edit Tags"].exists, mode)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quick-tag-")).count, 7, mode)
            app.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(editTags.isEnabled, "Right-clicking the selected item must keep the selection in \(mode)")
            app.terminate()
        }
    }

    @MainActor
    private func launchArchiveFixture(_ app: XCUIApplication) {
        // Saved windows from a previous test must not cover the fixture or change
        // the initial window count required by the interaction scenarios.
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO"]
        app.launch(); app.activate()
        // macOS can restore an application with no browser window. Create the
        // fixture's window before looking for rows; this is test setup only.
        let browser = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browser.waitForExistence(timeout: 3) {
            // XCTest may not target synthesized keys when no window exists.
            // Establish the fixture's first window through its native menu.
            app.menuBars.menuBarItems["File"].click()
            app.menuItems["New Zforge Window"].click()
        }
        XCTAssertTrue(browser.waitForExistence(timeout: 8), app.debugDescription)
    }

    /// Real Option-drag inside an archive in Columns, with Escape and Return in the
    /// native confirmation. Per-mode reveal, duplicate counts, history and the move
    /// variants are characterized offscreen by `ArchiveDragDropTests`.
    @MainActor
    func testArchiveInternalCopyConfirmationKeepsHistoryAndAncestorColumns() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-archive-navigation-fixtures",
            "--ui-window-width", "1300", "--ui-view-mode", "columns", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        let initialTitle = app.windows.firstMatch.title
        for name in ["Sample.zip", "Inside", "Deep"] {
            let label = app.descendants(matching: .any).matching(identifier: "browser-item-\(name)").firstMatch.staticTexts[name].firstMatch
            XCTAssertTrue(label.waitForExistence(timeout: 8), app.debugDescription)
            label.click()
        }
        XCTAssertTrue(app.windows["Deep"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
        let payload = app.descendants(matching: .any).matching(identifier: "browser-item-DeepPayload.txt").firstMatch.staticTexts["DeepPayload.txt"].firstMatch
        let leaf = app.descendants(matching: .any).matching(identifier: "browser-item-Leaf").firstMatch.staticTexts["Leaf"].firstMatch
        XCTAssertTrue(payload.waitForExistence(timeout: 8)); XCTAssertTrue(leaf.exists)
        let copies = app.descendants(matching: .any).matching(identifier: "browser-item-DeepPayload.txt")
        // Escape cancels the confirmation: the archive and the view stay unchanged.
        XCUIElement.perform(withKeyModifiers: [.option]) { payload.click(forDuration: 0.3, thenDragTo: leaf) }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.escape, modifierFlags: [])
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
            object: app.staticTexts["Modify the Original Archive?"].firstMatch)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed, app.debugDescription)
        XCTAssertTrue(app.windows["Deep"].firstMatch.exists, app.debugDescription)
        XCTAssertTrue(payload.exists)
        XCTAssertEqual(copies.count, 1, app.debugDescription)
        // Return confirms the copy.
        XCUIElement.perform(withKeyModifiers: [.option]) { payload.click(forDuration: 0.3, thenDragTo: leaf) }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(app.windows["Leaf"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
        let duplicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: copies)
        XCTAssertEqual(XCTWaiter.wait(for: [duplicate], timeout: 8), .completed, app.debugDescription)
        for (index, name) in ["Sample.zip", "Inside", "Deep", "Leaf", "DeepPayload.txt"].enumerated() {
            let column = app.descendants(matching: .any).matching(identifier: "browser-column-\(index)").firstMatch
            XCTAssertTrue(column.staticTexts[name].firstMatch.exists, "Missing ancestor \(name): \(app.debugDescription)")
        }
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "Mutation hierarchy columns"; capture.lifetime = .keepAlways; add(capture)
        for title in ["Deep", "Inside", "Sample.zip", initialTitle] {
            app.buttons["Back"].firstMatch.click()
            XCTAssertTrue(app.windows[title].firstMatch.waitForExistence(timeout: 8), "Back skipped \(title): \(app.debugDescription)")
        }
        app.buttons["Forward"].firstMatch.click()
        XCTAssertTrue(app.windows["Sample.zip"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
    }

    /// Real archive drag from Icons onto a sidebar folder. The copy semantics in
    /// every mode are characterized offscreen by `ArchiveDragDropTests`.
    @MainActor
    func testArchiveDragCopiesIntoSidebarFolder() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "1100",
            "--ui-view-mode", "icons", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        app.activate()
        let archive = app.staticTexts["Sample.zip"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 8), app.debugDescription)
        archive.doubleClick()
        let inside = app.staticTexts["Inside"].firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5))
        inside.doubleClick()
        let payload = app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.staticTexts["Payload.txt"].firstMatch
        XCTAssertTrue(payload.waitForExistence(timeout: 5))
        let destination = app.descendants(matching: .any).matching(identifier: "sidebar-fixture-drop").firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        payload.click(forDuration: 0.3, thenDragTo: destination)
        let picture = XCTAttachment(screenshot: app.screenshot()); picture.name = "Archive copy icons"; picture.lifetime = .keepAlways; add(picture)
        destination.click()
        XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.waitForExistence(timeout: 8), app.debugDescription)
    }

    @MainActor
    func testArchiveCopyIntoAnotherZforgeWindow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "780", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        app.launch(); app.activate()
        let firstTitle = app.windows.firstMatch.title
        let sourceWindow = app.windows.matching(NSPredicate(format: "title == %@", firstTitle)).firstMatch
        let archive = sourceWindow.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 8)); archive.buttons.firstMatch.click()
        let inside = sourceWindow.descendants(matching: .any).matching(identifier: "browser-item-Inside").firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5)); inside.buttons.firstMatch.click()
        let payload = sourceWindow.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch
        XCTAssertTrue(payload.waitForExistence(timeout: 5))
        app.typeKey("n", modifierFlags: [.command])
        let second = app.windows.matching(NSPredicate(format: "title != %@ AND title BEGINSWITH %@", firstTitle, "ArchiveDragFixture-")).firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 8), app.debugDescription)
        let origin = second.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: 400, dy: 6)).click(forDuration: 0.3,
            thenDragTo: origin.withOffset(CGVector(dx: 1200 - second.frame.minX, dy: 44 - second.frame.minY)))
        // Drop onto a directory row in the new window, then inspect its contents.
        let target = second.descendants(matching: .any).matching(identifier: "browser-item-Dropped").firstMatch.staticTexts["Dropped"].firstMatch
        payload.staticTexts["Payload.txt"].firstMatch.click(forDuration: 0.3, thenDragTo: target)
        target.doubleClick()
        let dropped = app.windows["Dropped"].firstMatch
        XCTAssertTrue(dropped.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(dropped.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(payload.exists)
    }

    /// Real local-file drags in List: Option-copy onto a folder row, then a drop
    /// onto an archive row confirmed through the SwiftUI dialog. Move without
    /// modifiers and the addition semantics are characterized by `ArchiveDragDropTests`.
    @MainActor
    func testLocalDragsOptionCopyAndConfirmAdditionToArchive() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        let localRows = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt")
        let local = localRows.firstMatch.staticTexts["Local.txt"].firstMatch
        XCTAssertTrue(local.waitForExistence(timeout: 8))
        let archive = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        local.click(forDuration: 0.3, thenDragTo: archive.staticTexts["Sample.zip"].firstMatch)
        let addButton = app.windows.firstMatch.buttons["Add to Archive"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), app.debugDescription)
        addButton.click()
        archive.buttons.firstMatch.click()
        let added = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: localRows)
        XCTAssertEqual(XCTWaiter.wait(for: [added], timeout: 8), .completed, app.debugDescription)
        // Collapse the archive so the only Local.txt row is the local file (an archive
        // entry with Option would be moved out of the archive); Option copies it into Dropped.
        archive.buttons.firstMatch.click()
        let collapsed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 1"), object: localRows)
        XCTAssertEqual(XCTWaiter.wait(for: [collapsed], timeout: 8), .completed, app.debugDescription)
        let destination = app.descendants(matching: .any).matching(identifier: "browser-item-Dropped").firstMatch
        let target = destination.staticTexts["Dropped"].firstMatch
        XCUIElement.perform(withKeyModifiers: [.option]) {
            local.click(forDuration: 0.3, thenDragTo: target)
        }
        destination.buttons.firstMatch.click()
        let copied = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: localRows)
        XCTAssertEqual(XCTWaiter.wait(for: [copied], timeout: 8), .completed, app.debugDescription)
        target.doubleClick()
        XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(local.waitForExistence(timeout: 5))
    }

    @MainActor
    func testArchivePromisesPublishIntoFinderBeforeRemovingOriginal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ZforgeFinderDrag-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "780", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        app.launch(); app.activate()
        let archive = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 8)); archive.buttons.firstMatch.click()
        let inside = app.descendants(matching: .any).matching(identifier: "browser-item-Inside").firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5)); inside.buttons.firstMatch.click()
        let payload = app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.staticTexts["Payload.txt"].firstMatch
        XCTAssertTrue(payload.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch
        let origin = window.coordinate(withNormalizedOffset: .zero)
        window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1)).withOffset(CGVector(dx: -2, dy: -2))
            .click(forDuration: 0.2, thenDragTo: origin.withOffset(CGVector(dx: 780, dy: 720)))
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate(); finder.typeKey(.escape, modifierFlags: [])
        // Open only the test-owned fixture directory. Gestures and assertions below
        // still use the native Finder receiver through XCTest.
        XCTAssertTrue(NSWorkspace.shared.open(directory))
        let finderWindow = finder.windows.matching(NSPredicate(format: "title CONTAINS %@", directory.lastPathComponent)).firstMatch
        XCTAssertTrue(finderWindow.waitForExistence(timeout: 5), finder.debugDescription)
        defer { finder.activate(); finder.typeKey("w", modifierFlags: [.command]) }
        let finderOrigin = finderWindow.coordinate(withNormalizedOffset: .zero)
        let titlePoint = finderOrigin.withOffset(CGVector(dx: 300, dy: 14))
        let desiredTitle = finderOrigin.withOffset(CGVector(dx: 1200 - finderWindow.frame.minX, dy: 74 - finderWindow.frame.minY))
        titlePoint.click(forDuration: 0.2, thenDragTo: desiredTitle)
        app.activate()
        // Moving Finder by its title is best effort: where its title bar is free
        // depends on the user's Finder sidebar width. Drop on Finder's content
        // where Zforge does not cover it, never on Zforge itself.
        let finderFrame = finderWindow.frame
        let uncoveredMinX = max(finderFrame.minX, window.frame.maxX)
        XCTAssertGreaterThan(finderFrame.maxX - uncoveredMinX, 60, "Zforge covers the Finder window: source \(window.frame), Finder \(finderFrame)")
        let drop = finderWindow.coordinate(withNormalizedOffset: CGVector(
            dx: ((uncoveredMinX + finderFrame.maxX) / 2 - finderFrame.minX) / finderFrame.width, dy: 0.65))
        print("Source \(window.frame), Finder \(finderWindow.frame), payload \(payload.frame)")
        let arrangement = XCTAttachment(screenshot: app.screenshot()); arrangement.name = "Finder drop arrangement"; arrangement.lifetime = .keepAlways; add(arrangement)
        payload.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click(forDuration: 0.3, thenDragTo: drop)
        let published = directory.appendingPathComponent("Payload.txt")
        let written = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in FileManager.default.fileExists(atPath: published.path) }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [written], timeout: 10), .completed)
        XCTAssertEqual(try String(contentsOf: published, encoding: .utf8), "payload")
        app.activate(); XCTAssertTrue(payload.exists)
        try FileManager.default.removeItem(at: published)
        XCUIElement.perform(withKeyModifiers: [.option]) {
            payload.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click(forDuration: 0.3, thenDragTo: drop)
        }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        app.typeKey(.return, modifierFlags: [])
        let moved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in FileManager.default.fileExists(atPath: published.path) }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 10), .completed)
        XCTAssertEqual(try String(contentsOf: published, encoding: .utf8), "payload")
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: payload)
        XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 10), .completed)
    }

    @MainActor
    func testTagEditorIsSharedByToolbarAndContextMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "1100", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        app.launch()
        app.activate()
        openFixtureBrowserIfNeeded(app)
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
        // The editor item is found by identifier because hovering a circle retitles it with the tag name.
        let edit = app.menuItems["edit-tags"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        XCTAssertEqual(edit.title, "Edit Tags")
        // The seven circles and the applied Red mark are checked offscreen
        // (BrowserMenuParityTests); this test keeps the real hover and sheet.
        let applied = app.buttons["quick-tag-Red"]
        XCTAssertTrue(applied.exists)
        let contextCapture = XCTAttachment(screenshot: app.screenshot())
        contextCapture.name = "Quick tag circles"
        contextCapture.lifetime = .keepAlways
        add(contextCapture)
        applied.hover()
        let hover = XCTAttachment(screenshot: app.screenshot())
        hover.name = "Applied tag hover"
        hover.lifetime = .keepAlways
        add(hover)
        XCTAssertEqual(edit.title, "Red")
        edit.hover()
        XCTAssertEqual(edit.title, "Edit Tags")
        edit.click()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["UI draft tag"].exists)
        app.buttons["Cancel"].click()
    }

    @MainActor
    func testCustomCompressionPanelOpensFolderChooser() throws {
        // The panel's fields, alignment, password expansion and name preservation are
        // checked offscreen (CompressionPanelLayoutTests); the real menu, sheet and
        // folder chooser stay here.
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
        let panel = app.sheets.firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), app.debugDescription)
        let whereButton = app.buttons["compression-save-where"]
        XCTAssertTrue(whereButton.waitForExistence(timeout: 5), app.debugDescription)
        let compactScreenshot = XCTAttachment(screenshot: panel.screenshot())
        compactScreenshot.name = "Compress Custom compact"
        compactScreenshot.lifetime = .keepAlways
        add(compactScreenshot)
        whereButton.click()
        let folderChooser = app.dialogs["Choose Folder…"]
        XCTAssertTrue(folderChooser.waitForExistence(timeout: 5), app.debugDescription)
        folderChooser.buttons["Cancel"].click()
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testColumnPreviewRefitsAfterUserScrollsLeft() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1200", "--ui-view-mode", "columns",
            "-browser.finderColumnWidth", "600", "-browser.scale", "1",
            "-browser.previewVisible.columns", "YES", "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)

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
    func testListKeyboardZoomAndArrowNavigationAfterChangingView() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "--ui-window-width", "1100",
            "--ui-view-mode", "list",
            "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)
        // Recents lists files only; a folder cannot be its readiness signal.
        XCTAssertTrue(app.staticTexts["Welcome.txt"].firstMatch.waitForExistence(timeout: 5))

        // Zoom shortcuts reach the active view (steps: ZoomStepTests.zoomSteps).
        let browser = app.descendants(matching: .any)["browser-mode-list"]
        XCTAssertTrue(browser.waitForExistence(timeout: 5))
        app.typeKey("0", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "100%")
        app.typeKey("=", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "110%")
        app.typeKey("-", modifierFlags: .command)
        XCTAssertEqual(browser.value as? String, "100%")

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
    func testCompactToolbarMenusOpenFromTheirToolbarButtons() throws {
        // Which controls each width (650/720/860 pt) shows and which titles its
        // menu offers are covered offscreen by BrowserWindowLayoutTests and
        // ToolbarOverflowMenuTests. The pop-up menus need a real click event.
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
        XCTAssertEqual(overflowButton.value as? String, "Collapsed")
        overflowButton.click()
        XCTAssertEqual(overflowButton.value as? String, "Expanded")
        XCTAssertFalse(app.menuItems["View"].exists)
        for title in ["Compress Selected", "Share", "Open", "Quick Look", "Get Info"] {
            XCTAssertTrue(app.menuItems[title].exists, "Missing \(title) from the toolbar overflow")
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
    func testKeyboardShortcutHelpOpensAndFilters() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures",
            "-appLanguagePreference", "english"
        ]
        addTeardownBlock { app.terminate() }
        launchArchiveFixture(app)
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 5))

        app.typeKey("/", modifierFlags: .command)

        let shortcutsWindow = app.windows["Keyboard Shortcuts"]
        XCTAssertTrue(shortcutsWindow.waitForExistence(timeout: 3))
        app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
            .buttons[XCUIIdentifierCloseWindow].click()
        let searchField = shortcutsWindow.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.click()
        searchField.typeText("Rename")

        XCTAssertTrue(shortcutsWindow.staticTexts["Rename"].waitForExistence(timeout: 2))
        XCTAssertFalse(shortcutsWindow.staticTexts["New Folder"].exists)
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

    @MainActor
    private func openFixtureBrowserIfNeeded(_ app: XCUIApplication) {
        // macOS may restore a windowless application after the preceding runner.
        // Tag tests exercise browser interactions, not automatic scene creation.
        if app.windows.count == 0 {
            app.typeKey("n", modifierFlags: [.command])
            XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
        }
    }

}
