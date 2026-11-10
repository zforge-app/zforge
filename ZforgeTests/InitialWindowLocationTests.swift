import Foundation
import Testing
@testable import Zforge

/// ZF-77 / D-95: a window opened for an archive or folder (Finder, Open With, Siri, Shortcuts)
/// shows it as the root of the window's hierarchy: the path bar and the first Columns column
/// are that location, never the Recents placeholder the window was created with, and the
/// window has no history behind it.
@MainActor
@Suite("Initial window location is the window root (ZF-77, D-95)")
struct InitialWindowLocationTests {
    @Test("An archive the window is opened for is its root: one path component, first column, no Back")
    func archiveIsWindowRoot() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.zip(named: "Vega Demo.zip")
        let browser = fixture.browser(initialURL: archive)
        defer { browser.close() }
        await browser.start()

        guard case .archive = browser.location else { Issue.record("The archive did not open"); return }
        #expect(browser.pathComponents.count == 1, "Path bar and Columns start at the archive, not at Recents")
        #expect(browser.pathComponents.first?.name == "Vega Demo.zip")
        #expect(browser.pathComponents.first?.isArchive == true)
        #expect(browser.pathComponents.first?.location == browser.location, "The first column lists the archive")
        #expect(Set(browser.items.map(\.name)) == ["Folder", "Readme.txt"])
        #expect(!browser.canGoBack, "The window never showed anything before the archive")
        #expect(!browser.canGoForward)

        // Entering a folder and going back returns to the archive root, and no further.
        await browser.open(try #require(browser.items.first { $0.name == "Folder" }))
        #expect(browser.pathComponents.map(\.name) == ["Vega Demo.zip", "Folder"])
        await browser.goBack()
        #expect(browser.pathComponents.map(\.name) == ["Vega Demo.zip"])
        #expect(!browser.canGoBack)
        await browser.goUp()
        #expect(browser.pathComponents.map(\.name) == ["Vega Demo.zip"], "Enclosing Folder has nowhere to go")
    }

    @Test("An encrypted archive the window is opened for is still its root after the password")
    func encryptedArchiveIsWindowRootAfterPassword() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let payload = fixture.input.appendingPathComponent("Secret.txt")
        try Data("Encrypted initial archive fixture".utf8).write(to: payload)
        var options = CompressionOptions(format: .sevenZip)
        options.requiresPassword = true
        options.encryptFileNames = true
        let archive = fixture.root.appendingPathComponent("Secret.7z")
        try await NativeSevenZipArchiveEngine().createArchive(from: [payload], outputURL: archive, options: options,
            password: "right", progress: { _ in })
        let browser = fixture.browser(initialURL: archive)
        defer { browser.close() }
        await browser.start()
        #expect(browser.passwordOperation != nil)
        #expect(browser.location == .recents, "Nothing is shown before the password")

        await browser.submitPassword("wrong")
        #expect(browser.passwordError != nil)
        await browser.submitPassword("right")
        #expect(browser.passwordOperation == nil)
        guard case .archive = browser.location else { Issue.record("The archive did not open"); return }
        #expect(browser.pathComponents.map(\.name) == ["Secret.7z"])
        #expect(browser.items.map(\.name) == ["Secret.txt"])
        #expect(!browser.canGoBack)
    }

    @Test("A folder the window is opened for is its root, with no history behind it")
    func folderIsWindowRoot() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        let folder = fixture.root.appendingPathComponent("Shown", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("note".utf8).write(to: folder.appendingPathComponent("Note.txt"))
        let browser = fixture.browser(initialURL: folder)
        defer { browser.close() }
        await browser.start()

        #expect(browser.location == .fileSystem(folder))
        #expect(browser.pathComponents.map(\.name) == ["Shown"])
        #expect(browser.items.map(\.name) == ["Note.txt"])
        #expect(!browser.canGoBack)
    }

    @Test("An archive opened from a folder the window shows is entered from it, with Back")
    func archiveOpenedLaterIsEnteredFromItsFolder() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }
        _ = try await fixture.zip(named: "Later.zip")
        let browser = fixture.browser(initialURL: fixture.root)
        defer { browser.close() }
        await browser.start()

        await browser.open(try #require(browser.items.first { $0.name == "Later.zip" }))
        guard case .archive = browser.location else { Issue.record("The archive did not open"); return }
        #expect(browser.pathComponents.map(\.name) == [fixture.root.lastPathComponent, "Later.zip"])
        #expect(browser.canGoBack)
        await browser.goBack()
        #expect(browser.location == .fileSystem(fixture.root))
    }
}

@MainActor
private struct Fixture {
    let container: URL
    let root: URL
    let input: URL
    let suite: String
    let preferences: FileBrowserPreferences

    init() throws {
        container = FileManager.default.temporaryDirectory
            .appendingPathComponent("InitialWindowLocation-\(UUID().uuidString)", isDirectory: true)
        root = container.appendingPathComponent("Files", isDirectory: true)
        input = container.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        suite = "ZforgeTestSuite.InitialWindowLocation-\(UUID().uuidString)"
        preferences = FileBrowserPreferences(defaults: try #require(UserDefaults(suiteName: suite)))
        preferences.language = .english
        preferences.viewMode = .columns
    }

    /// A ZIP holding `Readme.txt` and `Folder/Inner.txt`.
    func zip(named name: String) async throws -> URL {
        let source = input.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let folder = source.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("readme".utf8).write(to: source.appendingPathComponent("Readme.txt"))
        try Data("inner".utf8).write(to: folder.appendingPathComponent("Inner.txt"))
        let archive = root.appendingPathComponent(name)
        try await NativeSevenZipArchiveEngine().createArchive(
            from: [source.appendingPathComponent("Readme.txt"), folder], outputURL: archive,
            options: CompressionOptions(format: .zip), password: nil, progress: { _ in })
        return archive
    }

    func browser(initialURL: URL) -> FileBrowserState {
        FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: ArchiveSessionClient(engine: NativeSevenZipArchiveEngine()),
            initialURL: initialURL)
    }

    func cleanUp() {
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
        try? FileManager.default.removeItem(at: container)
    }
}
