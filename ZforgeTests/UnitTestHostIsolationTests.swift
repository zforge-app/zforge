import AppKit
import Testing
@testable import Zforge

/// The `Unit` plan runs inside the app (its test host). No run reads or writes the user's
/// preferences, and the suites the tests create leave nothing behind (RNF-Q08, ZF-54).
@Suite("Unit test host isolation")
@MainActor
struct UnitTestHostIsolationTests {
    /// Checks the decision only: resolving it would clear this host's own live suite.
    @Test("A test host launch keeps its preferences in its own private suite, not the user's")
    func testHostEnvironmentIsIsolated() {
        let environment = ["XCTestConfigurationFilePath": "/tmp/Zforge.xctestconfiguration"]
        #expect(ZforgeDefaults.storage(arguments: ["Zforge"], environment: environment) == .cleared(ZforgeDefaults.testHostSuite))
        #expect(ZforgeDefaults.storage(arguments: ["Zforge"], environment: [:]) == .user)
        #expect(ZforgeDefaults.storage(arguments: ["Zforge", "--ui-fixtures"], environment: environment) == .cleared(ZforgeDefaults.fixtureSuite),
                "A UI test argument decides first")
        #expect(ZforgeDefaults.storage(arguments: ["Zforge", "--ui-fixtures"], environment: ["ZFORGE_UI_PREFERENCES_SUITE": "Relaunch"]) == .named("Relaunch"))
    }

    @Test("This test host uses its own preferences and keeps window frames out of the user's preferences")
    func thisHostIsIsolated() {
        #expect(ZforgeDefaults.application !== UserDefaults.standard, "FileBrowserPreferences.shared and the other stores")
        #expect(UITestLaunchIsolation.isObservingWindows, "Window and split-view frame autosave is turned off")
    }

    @Test("Removing a test suite empties it")
    func removedSuiteIsEmpty() throws {
        let suite = TestSuites.prefix + "SuiteCleanup-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set("value", forKey: "key")
        defaults.removeTestSuite(named: suite)
        #expect(try #require(UserDefaults(suiteName: suite)).object(forKey: "key") == nil)
    }

    /// Runs on a folder of its own: the container's preferences folder holds other tests'
    /// suites, which a sweep at this moment would also match.
    @Test("Test suite files left by earlier runs are deleted; this run's and other files are kept")
    func earlierRunsAreSwept() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("TestSuiteSweep-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID().uuidString
        let earlier = directory.appendingPathComponent("\(TestSuites.prefix)SweepEarlier-\(id).plist")
        let current = directory.appendingPathComponent("\(TestSuites.prefix)SweepCurrent-\(id).plist")
        let other = directory.appendingPathComponent("ZforgeSweepControl-\(id).plist")
        let cutoff = Date()
        for url in [earlier, current, other] { try Data("<plist/>".utf8).write(to: url) }
        defer { for url in [earlier, current, other] { try? FileManager.default.removeItem(at: url) } }
        try FileManager.default.setAttributes([.modificationDate: cutoff.addingTimeInterval(-3_600)], ofItemAtPath: earlier.path)
        try FileManager.default.setAttributes([.modificationDate: cutoff.addingTimeInterval(-3_600)], ofItemAtPath: other.path)
        try FileManager.default.setAttributes([.modificationDate: cutoff.addingTimeInterval(60)], ofItemAtPath: current.path)

        let swept = TestSuites.sweep(olderThan: cutoff, in: directory)
        #expect(swept == [earlier.lastPathComponent])
        #expect(!FileManager.default.fileExists(atPath: earlier.path))
        #expect(FileManager.default.fileExists(atPath: current.path), "Files written in this run stay until the next run")
        #expect(FileManager.default.fileExists(atPath: other.path), "Only test suite files are deleted")
    }

    @Test("The test host started before its tests ran")
    func processStartIsKnown() {
        #expect(TestSuites.processStart < Date())
        #expect(TestSuites.processStart > Date().addingTimeInterval(-24 * 3_600))
    }
}
