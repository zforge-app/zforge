import XCTest

extension XCUIApplication {
    /// Opens Settings (⌘,) on one of its panes by clicking the pane in the sidebar (ZF-58).
    /// Settings opens on the pane shown last, so tests choose theirs explicitly.
    @MainActor
    @discardableResult
    func openSettingsPane(_ pane: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let window = windows["com_apple_SwiftUI_Settings_window"]
        if !window.exists { typeKey(",", modifierFlags: .command) }
        let item = window.descendants(matching: .any).matching(identifier: "settings-pane-" + pane).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Settings sidebar item \(pane)\n\(debugDescription)", file: file, line: line)
        item.click()
        return window
    }
}
