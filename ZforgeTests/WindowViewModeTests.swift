import Foundation
import AppKit
import Testing
@testable import Zforge

@Suite("Window view mode isolation")
@MainActor
struct WindowViewModeTests {
    @Test("All four modes remain independent with shared preferences")
    func independentModes() throws {
        let suite = "ZforgeTestSuite.ZforgeWindowModes-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .icons
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }

        for mode in BrowserViewMode.allCases {
            first.viewMode = mode
            #expect(second.viewMode == .icons)
            second.viewMode = .gallery
            #expect(first.viewMode == mode)
            second.viewMode = .icons
            #expect(preferences.viewMode == .icons)
            #expect(FileBrowserPreferences(defaults: defaults).viewMode == .icons)
        }
    }

    @Test("Default View affects future windows and survives preference reload")
    func defaultAppliesToFutureWindows() throws {
        let suite = "ZforgeTestSuite.ZforgeWindowDefault-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .list
        let existing = makeState(preferences)
        defer { existing.close() }
        #expect(existing.viewMode == .list)

        preferences.viewMode = .columns
        #expect(existing.viewMode == .list)
        let newWindow = makeState(preferences)
        let reopened = makeState(FileBrowserPreferences(defaults: defaults))
        defer { newWindow.close(); reopened.close() }
        #expect(newWindow.viewMode == .columns)
        #expect(reopened.viewMode == .columns)

        // Other application preferences retain their existing shared behavior.
        preferences.showHiddenFiles.toggle()
        #expect(existing.preferences.showHiddenFiles == newWindow.preferences.showHiddenFiles)
    }

    @Test("Preview lookup uses each window's active mode")
    func previewUsesLocalMode() throws {
        let suite = "ZforgeTestSuite.ZforgeWindowPreview-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.setPreviewVisible(false, in: .list)
        preferences.setPreviewVisible(true, in: .icons)
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }
        first.viewMode = .list
        second.viewMode = .icons
        #expect(!first.previewVisible)
        #expect(second.previewVisible)
        first.previewVisible = true
        #expect(preferences.previewVisible(in: .list))
        #expect(second.previewVisible)
    }

    private func makeState(_ preferences: FileBrowserPreferences) -> FileBrowserState {
        FileBrowserState(
            preferences: preferences,
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(),
            archives: UIFixtureArchiveEngine()
        )
    }

    @Test("The last native window closed supplies the next mode in either close order",
          arguments: BrowserViewMode.allCases, [true, false])
    func lastClosedWindow(mode: BrowserViewMode, closeFirst: Bool) throws {
        let suite = "ZforgeTestSuite.ZforgeWindowClose-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        let otherMode: BrowserViewMode = mode == .gallery ? .list : .gallery
        preferences.viewMode = otherMode
        let first = makeState(preferences)
        let second = makeState(preferences)
        defer { first.close(); second.close() }
        let winner = closeFirst ? second : first
        let loser = closeFirst ? first : second
        winner.viewMode = mode
        let firstWindow = makeWindow()
        let secondWindow = makeWindow()
        let lifecycle = BrowserWindowLifecycle()
        lifecycle.register(firstWindow, browser: first)
        lifecycle.register(secondWindow, browser: second)

        #expect(FileBrowserPreferences(defaults: defaults).viewMode == otherMode)
        (closeFirst ? firstWindow : secondWindow).close()
        #expect(winner.viewMode == mode)
        #expect(loser.viewMode == otherMode)
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == otherMode)
        (closeFirst ? secondWindow : firstWindow).close()
        let reopened = makeState(FileBrowserPreferences(defaults: defaults))
        defer { reopened.close() }
        #expect(reopened.viewMode == mode)
        #expect(preferences.viewMode == mode)
        // Duplicate or delayed teardown cannot overwrite the last close.
        NotificationCenter.default.post(name: NSWindow.willCloseNotification,
            object: closeFirst ? firstWindow : secondWindow)
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == mode)
    }

    @Test("Quit preserves the frontmost remaining browser and ignores auxiliary windows",
          arguments: BrowserViewMode.allCases)
    func quitWithOpenWindows(mode: BrowserViewMode) throws {
        let suite = "ZforgeTestSuite.ZforgeWindowQuit-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = mode == .icons ? .gallery : .icons
        let back = makeState(preferences)
        let front = makeState(preferences)
        front.viewMode = mode
        defer { back.close(); front.close() }
        let frontWindow = makeWindow()
        let backWindow = makeWindow()
        let auxiliaryWindow = makeWindow()
        let lifecycle = BrowserWindowLifecycle()
        lifecycle.register(backWindow, browser: back)
        lifecycle.register(frontWindow, browser: front)
        lifecycle.applicationWillTerminate(orderedWindows: [auxiliaryWindow, frontWindow, backWindow])
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == mode)
        frontWindow.close()
        backWindow.close()
        auxiliaryWindow.close()
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == mode)
    }

    @Test("Scene replacement and unrelated closes do not save an obsolete browser mode")
    func replacementAndUnrelatedWindows() throws {
        let suite = "ZforgeTestSuite.ZforgeWindowReplacement-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .icons
        let original = makeState(preferences)
        let replacement = makeState(preferences)
        original.viewMode = .gallery
        replacement.viewMode = .columns
        defer { replacement.close() }
        let window = makeWindow()
        let auxiliary = makeWindow()
        let lifecycle = BrowserWindowLifecycle()
        lifecycle.register(window, browser: original)
        lifecycle.register(window, browser: replacement)
        original.close()
        auxiliary.close()
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == .icons)
        window.close()
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == .columns)
        lifecycle.applicationWillTerminate(orderedWindows: [])
        #expect(FileBrowserPreferences(defaults: defaults).viewMode == .columns)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }
}
