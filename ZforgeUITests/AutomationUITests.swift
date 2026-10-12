import XCTest
import AppKit

final class AutomationUITests: XCTestCase {
    @MainActor
    func testSettingsProvidesLocalizedAgentSetupAndNativeCancellation() throws {
        let pasteboard = NSPasteboard.general
        let saved = (pasteboard.pasteboardItems ?? []).map { source in
            let copy = NSPasteboardItem()
            for type in source.types { if let data = source.data(forType: type) { copy.setData(data, forType: type) } }
            return copy
        }
        var ownChangeCount = -1
        defer {
            if pasteboard.changeCount == ownChangeCount {
                pasteboard.clearContents()
                pasteboard.writeObjects(saved)
            }
        }
        for (language, allow) in [("english", "Allow"), ("portugueseBrazil", "Autorizar")] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-fixtures", "-appLanguagePreference", language, "-ApplePersistenceIgnoreState", "YES"]
            app.launch()
            app.activate()
            defer { app.terminate() }
            app.typeKey(",", modifierFlags: .command)
            let button = app.buttons["automation-copy-mcp"]
            XCTAssertTrue(button.waitForExistence(timeout: 5), app.debugDescription)
            // The delivery contract includes MCP setup; native Apple automation is deferred.
            XCTAssertFalse(app.buttons["automation-open-shortcuts"].exists)
            XCTAssertFalse(app.staticTexts["automation-shortcuts-instructions"].exists)
            button.click()
            ownChangeCount = pasteboard.changeCount
            let text = try XCTUnwrap(pasteboard.string(forType: .string))
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
            let servers = try XCTUnwrap(object["mcpServers"] as? [String: [String: Any]])
            XCTAssertEqual(servers["zforge"]?["args"] as? [String], ["--mcp"])
            XCTAssertTrue((servers["zforge"]?["command"] as? String)?.hasSuffix("/Contents/MacOS/Zforge") == true)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Automation Settings - " + language
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.buttons["automation-allow-folder"].click()
            // Scope to the actual panel; app-wide queries can select Touch Bar buttons.
            let panel = app.windows["open-panel"]
            XCTAssertTrue(panel.waitForExistence(timeout: 5), app.debugDescription)
            XCTAssertTrue(panel.buttons[allow].firstMatch.exists)
            panel.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(button.isEnabled)
            app.terminate()
        }
    }
    @MainActor
    func testMCPContextualPermissionCancellationAndDisconnect() throws {
        for (language, title, prompt) in [("english", "Authorize Folder to Continue", "Authorize and Continue"),
                                         ("portugueseBrazil", "Autorizar pasta para continuar", "Autorizar e continuar")] {
            for disconnect in [false, true] {
                let app = XCUIApplication()
                app.launchArguments = ["--ui-fixtures", "--ui-contextual-permission", "-appLanguagePreference", language, "-ApplePersistenceIgnoreState", "YES"]
                app.launch()
                defer { app.terminate() }
                let panel = app.windows["open-panel"]
                XCTAssertTrue(panel.waitForExistence(timeout: 5), app.debugDescription)
                XCTAssertEqual(panel.title, title)
                XCTAssertTrue(panel.buttons[prompt].firstMatch.exists, app.debugDescription)
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "Contextual permission - " + language + (disconnect ? " - disconnect" : " - cancel")
                screenshot.lifetime = .keepAlways
                add(screenshot)
                if disconnect {
                    app.menuBars.menuBarItems["Automation test"].click()
                    let disconnectItem = app.menuItems["Disconnect test client"]
                    XCTAssertTrue(disconnectItem.isEnabled)
                    disconnectItem.click()
                } else {
                    panel.typeKey(.escape, modifierFlags: [])
                }
                let result = app.staticTexts["contextual-permission-result"]
                let completed = NSPredicate(format: "value == %@", "cancelled; grants=0; output=false")
                expectation(for: completed, evaluatedWith: result)
                waitForExpectations(timeout: 5)
                XCTAssertFalse(panel.exists)
                XCTAssertEqual(result.value as? String, "cancelled; grants=0; output=false")
                app.terminate()
            }
        }
    }
}
