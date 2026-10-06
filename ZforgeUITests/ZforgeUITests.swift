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

    @MainActor
    func testFolderSelectionCommandIsLocalizedAndDocumented() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixtures", "--ui-window-width", "680",
            "-appLanguagePreference", "portugueseBrazil", "-ApplePersistenceIgnoreState", "YES"]
        addTeardownBlock { app.terminate() }
        launchArchiveFixture(app)
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["Welcome.txt"].waitForExistence(timeout: 8))
        XCUIElement.perform(withKeyModifiers: .option) {
            app.menuBars.menuBarItems["File"].click()
            XCTAssertTrue(app.menuItems["Nova Pasta com Seleção"].exists, app.debugDescription)
            let menu = XCTAttachment(screenshot: app.screenshot())
            menu.name = "Portuguese folder selection alternate at 680 pt"
            menu.lifetime = .keepAlways
            add(menu)
        }
        app.terminate()
        launchArchiveFixture(app)
        app.typeKey("/", modifierFlags: .command)
        let shortcuts = app.windows.containing(.staticText, identifier: "Atalhos de Teclado").firstMatch
        XCTAssertTrue(shortcuts.waitForExistence(timeout: 3), app.debugDescription)
        let browserWindow = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        browserWindow.buttons[XCUIIdentifierCloseWindow].click()
        let search = shortcuts.searchFields.firstMatch
        search.click()
        // Preserve the user's clipboard while supplying the complete Unicode
        // query. XCTest's simulated typing drops characters during searchable updates.
        let pasteboard = NSPasteboard.general
        let savedItems = (pasteboard.pasteboardItems ?? []).map { source in
            let copy = NSPasteboardItem()
            for type in source.types {
                if let data = source.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
        var suppliedChangeCount = -1
        defer {
            if pasteboard.changeCount == suppliedChangeCount {
                pasteboard.clearContents()
                pasteboard.writeObjects(savedItems)
            }
        }
        pasteboard.clearContents()
        pasteboard.setString("Nova Pasta com Seleção", forType: .string)
        suppliedChangeCount = pasteboard.changeCount
        search.typeKey("v", modifierFlags: .command)
        XCTAssertEqual(search.value as? String, "Nova Pasta com Seleção", app.debugDescription)
        XCTAssertTrue(shortcuts.staticTexts["Nova Pasta com Seleção"].waitForExistence(timeout: 3))
        XCTAssertTrue(shortcuts.descendants(matching: .any).matching(identifier: "shortcut-⌃⌥⌘N").firstMatch.exists)
        let help = XCTAttachment(screenshot: app.screenshot())
        help.name = "Portuguese folder selection shortcut help"
        help.lifetime = .keepAlways
        add(help)
        app.typeKey("w", modifierFlags: .command)
    }

    @MainActor
    func testNewFolderWithSelectionMenuAndShortcutInEveryMode() throws {
        for mode in ["icons", "list", "columns", "gallery"] {
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
                if mode == "columns" { folder.click() } else { folder.doubleClick() }
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

    @MainActor
    func testFolderSelectionMenuAlternatesWithOptionInEveryMode() throws {
        for mode in ["icons", "list", "columns", "gallery"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "1100",
                "--ui-view-mode", mode, "-appLanguagePreference", "english", "-ApplePersistenceIgnoreState", "YES"]
            addTeardownBlock { app.terminate() }
            launchArchiveFixture(app)
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: mode == "gallery" ? 0.9 : 0.75)).click()
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
    func testViewModeIsIndependentBetweenWindows() throws {
        let app = XCUIApplication()
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
                dx: area.minX - window.frame.minX + area.width * (mode == "gallery" ? 0.95 : 0.2),
                dy: area.minY - window.frame.minY + area.height * (mode == "gallery" ? 0.97 : 0.8)
            ))
            let more = app.buttons["toolbar-more-menu"]
            XCTAssertTrue(more.exists, mode)
            for selected in [false, true] {
                if selected { file.click(); file.click() } else { blank.click() }
                more.click()
                XCTAssertTrue(popup.menuItems["Open"].waitForExistence(timeout: 2), mode)
                XCTAssertEqual(popup.menuItems["Open"].isEnabled, selected, mode)
                let expected = popup.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }
                app.typeKey(.escape, modifierFlags: [])
                blank.rightClick()
                XCTAssertTrue(popup.menuItems["Open"].waitForExistence(timeout: 2), "\(mode), selected: \(selected)")
                XCTAssertEqual(popup.menuItems.allElementsBoundByIndex.map { "\($0.label):\($0.isEnabled)" }, expected, mode)
                app.typeKey(.escape, modifierFlags: [])
            }
            // The blank-area monitor must leave the item-specific menu intact.
            file.rightClick()
            XCTAssertTrue(popup.menuItems["Open with"].waitForExistence(timeout: 2), mode)
            app.typeKey(.escape, modifierFlags: [])
            app.terminate()
        }
    }

    @MainActor
    private func launchArchiveFixture(_ app: XCUIApplication) {
        app.launch(); app.activate()
        // macOS can restore an application with no browser window. Create the
        // fixture's window before looking for rows; this is test setup only.
        let browser = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browser.waitForExistence(timeout: 3) {
            app.typeKey("n", modifierFlags: .command)
        }
        XCTAssertTrue(browser.waitForExistence(timeout: 8), app.debugDescription)
    }

    @MainActor
    func testArchiveMutationKeepsBackHistoryAndAncestorColumnsInEveryMode() throws {
        for mode in ["icons", "list", "columns", "gallery"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-archive-navigation-fixtures",
                "--ui-window-width", "1300", "--ui-view-mode", mode, "-appLanguagePreference", "english"]
            launchArchiveFixture(app)
            let initialTitle = app.windows.firstMatch.title
            for name in ["Sample.zip", "Inside", "Deep"] {
                let label = app.descendants(matching: .any).matching(identifier: "browser-item-\(name)").firstMatch.staticTexts[name].firstMatch
                XCTAssertTrue(label.waitForExistence(timeout: 8), app.debugDescription)
                if mode == "columns" { label.click() } else { label.doubleClick() }
            }
            XCTAssertTrue(app.windows["Deep"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
            let payload = app.descendants(matching: .any).matching(identifier: "browser-item-DeepPayload.txt").firstMatch.staticTexts["DeepPayload.txt"].firstMatch
            let leaf = app.descendants(matching: .any).matching(identifier: "browser-item-Leaf").firstMatch.staticTexts["Leaf"].firstMatch
            XCTAssertTrue(payload.waitForExistence(timeout: 8)); XCTAssertTrue(leaf.exists)
            XCUIElement.perform(withKeyModifiers: [.option]) { payload.click(forDuration: 0.3, thenDragTo: leaf) }
            XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
            app.typeKey(.return, modifierFlags: [])
            let expectedTitle = mode == "list" ? "Deep" : "Leaf"
            XCTAssertTrue(app.windows[expectedTitle].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
            let copies = app.descendants(matching: .any).matching(identifier: "browser-item-DeepPayload.txt")
            let duplicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %@", NSNumber(value: mode == "gallery" || mode == "icons" ? 1 : 2)), object: copies)
            XCTAssertEqual(XCTWaiter.wait(for: [duplicate], timeout: 8), .completed, app.debugDescription)
            if mode == "columns" {
                for (index, name) in ["Sample.zip", "Inside", "Deep", "Leaf", "DeepPayload.txt"].enumerated() {
                    let column = app.descendants(matching: .any).matching(identifier: "browser-column-\(index)").firstMatch
                    XCTAssertTrue(column.staticTexts[name].firstMatch.exists, "Missing ancestor \(name): \(app.debugDescription)")
                }
            }
            let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "Mutation hierarchy \(mode)"; capture.lifetime = .keepAlways; add(capture)
            let titles = mode == "list" ? ["Inside", "Sample.zip", initialTitle] : ["Deep", "Inside", "Sample.zip", initialTitle]
            for title in titles {
                app.buttons["Back"].firstMatch.click()
                XCTAssertTrue(app.windows[title].firstMatch.waitForExistence(timeout: 8), "Back skipped \(title): \(app.debugDescription)")
            }
            app.buttons["Forward"].firstMatch.click()
            XCTAssertTrue(app.windows["Sample.zip"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
            app.terminate()
        }
    }

    @MainActor
    func testArchiveDragCopiesIntoDroppedFolderInEveryMode() throws {
        for mode in ["list", "icons", "columns", "gallery"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-window-width", "1100",
                "--ui-view-mode", mode, "-appLanguagePreference", "english"]
            launchArchiveFixture(app)
            app.activate()
            let archive = app.staticTexts["Sample.zip"].firstMatch
            XCTAssertTrue(archive.waitForExistence(timeout: 8), app.debugDescription)
            if mode == "list" {
                app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch.buttons.firstMatch.click()
                let inside = app.staticTexts["Inside"].firstMatch
                XCTAssertTrue(inside.waitForExistence(timeout: 5))
                app.descendants(matching: .any).matching(identifier: "browser-item-Inside").firstMatch.buttons.firstMatch.click()
            } else {
                if mode == "columns" { archive.click() } else { archive.doubleClick() }
                let inside = app.staticTexts["Inside"].firstMatch
                XCTAssertTrue(inside.waitForExistence(timeout: 5))
                if mode == "columns" { inside.click() } else { inside.doubleClick() }
            }
            let payload = app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.staticTexts["Payload.txt"].firstMatch
            XCTAssertTrue(payload.waitForExistence(timeout: 5))
            let destination = app.descendants(matching: .any).matching(identifier: "sidebar-fixture-drop").firstMatch
            XCTAssertTrue(destination.waitForExistence(timeout: 5))
            payload.click(forDuration: 0.3, thenDragTo: destination)
            let picture = XCTAttachment(screenshot: app.screenshot()); picture.name = "Archive copy \(mode)"; picture.lifetime = .keepAlways; add(picture)
            destination.click()
            XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8), app.debugDescription)
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.waitForExistence(timeout: 8), app.debugDescription)
            app.terminate()
        }
    }

    @MainActor
    func testArchiveMoveUsesKeyboardConfirmationAndCancellation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        let archive = app.staticTexts["Sample.zip"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 8))
        app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch.buttons.firstMatch.click()
        let inside = app.staticTexts["Inside"].firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5))
        app.descendants(matching: .any).matching(identifier: "browser-item-Inside").firstMatch.buttons.firstMatch.click()
        let payload = app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.staticTexts["Payload.txt"].firstMatch
        let dropped = app.descendants(matching: .any).matching(identifier: "browser-item-Dropped").firstMatch.staticTexts["Dropped"].firstMatch
        XCTAssertTrue(payload.waitForExistence(timeout: 5)); XCTAssertTrue(dropped.exists)
        XCUIElement.perform(withKeyModifiers: [.option]) { payload.click(forDuration: 0.3, thenDragTo: dropped) }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(payload.waitForExistence(timeout: 5))
        app.descendants(matching: .any).matching(identifier: "browser-item-Dropped").firstMatch.buttons.firstMatch.click()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").count, 1)
        XCUIElement.perform(withKeyModifiers: [.option]) { payload.click(forDuration: 0.3, thenDragTo: dropped) }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.return, modifierFlags: [])
        app.descendants(matching: .any).matching(identifier: "sidebar-fixture-drop").firstMatch.click()
        XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt").firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testArchiveInternalMoveAndOptionCopyRevealExpandedDestination() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        let archive = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 8)); archive.buttons.firstMatch.click()
        let inside = app.descendants(matching: .any).matching(identifier: "browser-item-Inside").firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5)); inside.buttons.firstMatch.click()
        let payloads = app.descendants(matching: .any).matching(identifier: "browser-item-Payload.txt")
        let source = payloads.firstMatch.staticTexts["Payload.txt"].firstMatch
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        let target = app.descendants(matching: .any).matching(identifier: "browser-item-Target").firstMatch.staticTexts["Target"].firstMatch
        source.click(forDuration: 0.3, thenDragTo: target)
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(source.waitForExistence(timeout: 8))
        XCTAssertEqual(payloads.count, 1)
        // Refresh expands Target and leaves the surviving Inside directory expanded.
        let firstCapture = XCTAttachment(screenshot: app.screenshot()); firstCapture.name = "Internal move revealed"; firstCapture.lifetime = .keepAlways; add(firstCapture)
        let insideTarget = inside.staticTexts["Inside"].firstMatch
        XCUIElement.perform(withKeyModifiers: [.option]) { source.click(forDuration: 0.3, thenDragTo: insideTarget) }
        XCTAssertTrue(app.staticTexts["Modify the Original Archive?"].firstMatch.waitForExistence(timeout: 5))
        app.typeKey(.return, modifierFlags: [])
        let duplicated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: payloads)
        XCTAssertEqual(XCTWaiter.wait(for: [duplicated], timeout: 8), .completed)
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "Internal copy preserves both entries"; capture.lifetime = .keepAlways; add(capture)
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

    @MainActor
    func testLocalDragRetainsMoveAndOptionCopyBehavior() throws {
        for copying in [false, true] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
            launchArchiveFixture(app)
            let localRows = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt")
            let source = localRows.firstMatch.staticTexts["Local.txt"].firstMatch
            XCTAssertTrue(source.waitForExistence(timeout: 8))
            let destination = app.descendants(matching: .any).matching(identifier: "browser-item-Dropped").firstMatch
            let target = destination.staticTexts["Dropped"].firstMatch
            XCUIElement.perform(withKeyModifiers: copying ? [.option] : []) {
                source.click(forDuration: 0.3, thenDragTo: target)
            }
            destination.buttons.firstMatch.click()
            let count = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %d", copying ? 2 : 1), object: localRows)
            XCTAssertEqual(XCTWaiter.wait(for: [count], timeout: 8), .completed, app.debugDescription)
            target.doubleClick()
            XCTAssertTrue(app.windows["Dropped"].firstMatch.waitForExistence(timeout: 8))
            XCTAssertTrue(source.waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    @MainActor
    func testLocalDropIntoArchiveRetainsConfirmationAndSource() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-archive-drag-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english"]
        launchArchiveFixture(app)
        let local = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt").firstMatch.staticTexts["Local.txt"].firstMatch
        XCTAssertTrue(local.waitForExistence(timeout: 8))
        let archive = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        local.click(forDuration: 0.3, thenDragTo: archive.staticTexts["Sample.zip"].firstMatch)
        let addButton = app.windows.firstMatch.buttons["Add to Archive"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), app.debugDescription)
        addButton.click()
        archive.buttons.firstMatch.click()
        let rows = app.descendants(matching: .any).matching(identifier: "browser-item-Local.txt")
        let added = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 2"), object: rows)
        XCTAssertEqual(XCTWaiter.wait(for: [added], timeout: 8), .completed, app.debugDescription)
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
        let drop = finderWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.65))
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
    func testArchiveRemovalIsSharedByToolbarAndContextMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1100",
            "--ui-view-mode", "list", "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)
        app.activate()
        let archive = app.staticTexts["Sample.zip"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.doubleClick()
        let inside = app.staticTexts["Inside.txt"].firstMatch
        XCTAssertTrue(inside.waitForExistence(timeout: 5))
        inside.click()
        app.buttons["toolbar-more-menu"].click()
        XCTAssertTrue(app.menuItems["Remove from Archive…"].waitForExistence(timeout: 3))
        app.typeKey(.escape, modifierFlags: [])
        inside.rightClick()
        XCTAssertTrue(app.menuItems["Remove from Archive…"].waitForExistence(timeout: 3))
        app.typeKey(.escape, modifierFlags: [])
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
    func testColumnLoadingNeverDuplicatesParentRows() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-column-load-delay", "--ui-window-width", "1400",
            "--ui-view-mode", "columns", "-browser.finderColumnWidth", "260",
            "-browser.scale", "1", "-browser.previewVisible.columns", "YES",
            "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)

        app.buttons["Downloads"].click()
        let parent = app.descendants(matching: .any)["browser-column-0"]
        XCTAssertTrue(parent.staticTexts["Fixture Folder"].waitForExistence(timeout: 5))
        XCTAssertTrue(parent.staticTexts["Sample.zip"].waitForExistence(timeout: 5))
        let child = app.descendants(matching: .any)["browser-column-1"]
        // A delayed read holds the actual intermediate UI on screen. Final-state
        // assertions alone cannot detect a one-frame duplicate during navigation.
        for (container, result, previous) in [
            ("Sample.zip", "Inside.txt", "FolderChild.txt"),
            ("Fixture Folder", "FolderChild.txt", "Inside.txt"),
            ("Sample.zip", "Inside.txt", "FolderChild.txt")
        ] {
            parent.staticTexts[container].click()
            XCTAssertTrue(child.waitForExistence(timeout: 2))
            XCTAssertFalse(child.staticTexts[result].exists, "The fixture must still be loading.")
            for name in ["Welcome.txt", "Another.txt", "Sample.zip", "Fixture Folder", previous] {
                XCTAssertFalse(child.staticTexts[name].exists, "Loading \(container) duplicated \(name).")
            }
            XCTAssertTrue(parent.staticTexts["Welcome.txt"].exists)
            let pending = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            pending.name = "Loading column: \(container)"
            pending.lifetime = .keepAlways
            add(pending)

            XCTAssertTrue(child.staticTexts[result].waitForExistence(timeout: 6))
            XCTAssertEqual(child.staticTexts.count, 1)
            let loaded = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            loaded.name = "Loaded column: \(container)"
            loaded.lifetime = .keepAlways
            add(loaded)
        }
    }

    @MainActor
    func testColumnPreviewRecalculatesWidthForNewDepth() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-fixtures", "--ui-window-width", "1400", "--ui-view-mode", "columns",
            "-appLanguagePreference", "english"
        ]
        launchArchiveFixture(app)

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
        launchArchiveFixture(app)

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
        let sidebarFrame = app.outlines["browser-sidebar"].frame
        let clickX = max(rootColumn.frame.minX, sidebarFrame.maxX) + 24
        XCTAssertLessThan(clippedSampleLabel.frame.maxX, sidebarFrame.maxX)
        XCTAssertLessThan(clickX, rootColumn.frame.maxX)
        // The label is behind the sidebar after horizontal scrolling. Click
        // the visible part of its row, rather than a multiple of the text width.
        clippedSampleLabel.coordinate(
            withNormalizedOffset: CGVector(
                dx: (clickX - clippedSampleLabel.frame.minX) / clippedSampleLabel.frame.width,
                dy: 0.5
            )
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
