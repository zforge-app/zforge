import Foundation
import Testing
@testable import Zforge

/// Archives whose names are visible but whose contents are encrypted (ZIP AES-256, 7z without
/// encrypted names) open without a password; reading an item asks for it in the password sheet,
/// as extraction does, instead of reporting “A password is required…” (D-116).
@Suite("Archives with encrypted contents", .serialized)
@MainActor
struct ArchiveContentEncryptionTests {
    static let password = "content-secret"
    static let contents = "Encrypted contents"
    private static let english = Locale(identifier: "en")

    @Test("The archive opens and lists its names without a password", arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func listsWithoutPassword(format: ArchiveCompressionFormat) async throws {
        let fixture = try await EncryptedContentsFixture.make(format: format)
        defer { fixture.cleanUp() }
        let state = try await fixture.browser()
        #expect(state.passwordOperation == nil)
        #expect(state.items.map(\.name).sorted() == ["Plain.txt", "Secret.txt"])
        #expect(state.items.first { $0.name == "Secret.txt" }?.encrypted == true)
    }

    @Test("Validating or reading an item reports a missing or wrong password as such, for ZIP AES and 7z",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func engineReportsPasswordErrors(format: ArchiveCompressionFormat) async throws {
        let fixture = try await EncryptedContentsFixture.make(format: format)
        defer { fixture.cleanUp() }
        let engine = fixture.engine
        // 7z has no password check: a wrong password shows as a data error in the encrypted
        // item, which the bridge reports as a wrong password, as 7-Zip's own UI does.
        await #expect(throws: ArchiveEngineError.passwordRequired) { try await engine.testArchive(at: fixture.archive, password: nil) }
        await #expect(throws: ArchiveEngineError.invalidPassword) { try await engine.testArchive(at: fixture.archive, password: "wrong-password") }
        try await engine.testArchive(at: fixture.archive, password: Self.password)

        let opened = try await engine.openArchive(at: fixture.archive, password: nil)
        defer { Task { await engine.closeAllSessions() } }
        let secret = try #require(try await engine.items(at: opened.address).first { $0.name == "Secret.txt" })
        await #expect(throws: ArchiveEngineError.passwordRequired) {
            try await engine.materialize(item: secret, purpose: .preview, automaticLimit: nil)
        }
        await #expect(throws: ArchiveEngineError.invalidPassword) {
            try await engine.materialize(item: secret, purpose: .preview, automaticLimit: nil, password: "wrong-password")
        }
        // A wrong password is not kept: the session still has none.
        await #expect(throws: ArchiveEngineError.passwordRequired) {
            try await engine.materialize(item: secret, purpose: .openExternally, automaticLimit: nil)
        }
        let url = try await engine.materialize(item: secret, purpose: .preview, automaticLimit: nil, password: Self.password)
        #expect(try String(contentsOf: url, encoding: .utf8) == Self.contents)
        // The right one is kept for the session's later reads.
        let other = try await engine.materialize(item: secret, purpose: .openExternally, automaticLimit: nil)
        #expect(try String(contentsOf: other, encoding: .utf8) == Self.contents)
    }

    @Test("The automatic preview shows Load Preview, saying the contents are encrypted, with no alert",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func automaticPreviewWaits(format: ArchiveCompressionFormat) async throws {
        let fixture = try await EncryptedContentsFixture.make(format: format)
        defer { fixture.cleanUp() }
        let state = try await fixture.browser()
        let secret = try #require(state.items.first { $0.name == "Secret.txt" })

        state.select(secret)
        await state.previewTask?.value

        #expect(state.error == nil, "No alert for a preview the user did not ask for: \(String(describing: state.error))")
        #expect(state.passwordOperation == nil, "Selecting an item does not open the password sheet")
        #expect(state.previewRequiresManualLoad)
        #expect(state.manualPreviewExplanation(for: secret) == "The contents of this item are encrypted. Load Preview asks for the password.")
    }

    @Test("Load Preview asks for the password, refuses a wrong one, and previews with the right one, which the window keeps",
          arguments: [ArchiveCompressionFormat.zip, .sevenZip])
    func loadPreviewAsksForThePassword(format: ArchiveCompressionFormat) async throws {
        let fixture = try await EncryptedContentsFixture.make(format: format)
        defer { fixture.cleanUp() }
        let state = try await fixture.browser()
        let secret = try #require(state.items.first { $0.name == "Secret.txt" })
        state.select(secret)
        await state.previewTask?.value

        state.updatePreview(manual: true)
        await state.previewTask?.value
        #expect(state.error == nil, "\(String(describing: state.error))")
        #expect(state.passwordOperation?.prompt(locale: Self.english)
            == "Enter the password to preview “Secret.txt”. It stays in memory only for this window.")
        #expect(state.passwordError == nil)

        await state.submitPassword("wrong-password")
        await state.previewTask?.value
        #expect(state.error == nil)
        #expect(state.passwordOperation != nil, "A wrong password asks again")
        #expect(state.passwordError == "Incorrect password. Try again.")
        #expect(state.previewURL == nil)

        await state.submitPassword(Self.password)
        await state.previewTask?.value
        #expect(state.passwordOperation == nil)
        #expect(state.error == nil)
        let previewURL = try #require(state.previewURL)
        #expect(try String(contentsOf: previewURL, encoding: .utf8) == Self.contents)

        // The password stays with the archive's session: the next item previews automatically.
        let plain = try #require(state.items.first { $0.name == "Plain.txt" })
        state.select(plain)
        await state.previewTask?.value
        state.select(secret)
        await state.previewTask?.value
        #expect(state.previewURL != nil)
        #expect(state.passwordOperation == nil)
    }

    @Test("Open, Open With, Quick Look and Share ask for the password instead of reporting an error",
          arguments: ["open", "openWith", "quickLook", "share"])
    func explicitReadsAskForThePassword(action: String) async throws {
        let fixture = try await EncryptedContentsFixture.make(format: .zip)
        defer { fixture.cleanUp() }
        let state = try await fixture.browser(previewVisible: false)
        let secret = try #require(state.items.first { $0.name == "Secret.txt" })
        state.select(secret)

        let verb: String
        switch action {
        case "open":
            verb = "open"
            await state.open(secret)
        case "openWith":
            verb = "open"
            state.openWith([secret], application: URL(fileURLWithPath: "/System/Applications/TextEdit.app"))
        case "quickLook":
            verb = "preview"
            state.openQuickLook()
        default:
            verb = "share"
            state.shareItems()
        }
        try await until("the password sheet or an error") { state.passwordOperation != nil || state.error != nil }

        #expect(state.error == nil, "\(action): \(String(describing: state.error))")
        #expect(state.passwordOperation?.prompt(locale: Self.english)
            == "Enter the password to \(verb) “Secret.txt”. It stays in memory only for this window.", "\(action)")

        // A wrong password asks again; nothing is opened or shared.
        await state.submitPassword("wrong-password")
        try await until("the sheet again") { state.passwordError != nil || state.error != nil }
        #expect(state.error == nil, "\(action): \(String(describing: state.error))")
        #expect(state.passwordOperation != nil, "\(action)")
        #expect(state.passwordError == "Incorrect password. Try again.", "\(action)")
    }

    /// Waits for a condition the code under test reaches from a task it starts itself.
    private func until(_ description: String, _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for \(description)")
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}

@MainActor
private final class EncryptedContentsFixture {
    let root: URL
    let archive: URL
    let engine: NativeSevenZipArchiveEngine
    private var suites: [String] = []
    private var browsers: [FileBrowserState] = []

    private init(root: URL, archive: URL) {
        self.root = root
        self.archive = archive
        engine = NativeSevenZipArchiveEngine()
    }

    static func make(format: ArchiveCompressionFormat) async throws -> EncryptedContentsFixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("EncryptedContents-\(UUID().uuidString)")
        let input = root.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        let secret = input.appendingPathComponent("Secret.txt")
        try Data(ArchiveContentEncryptionTests.contents.utf8).write(to: secret)
        let plain = input.appendingPathComponent("Plain.txt")
        try Data("Also encrypted".utf8).write(to: plain)
        var options = CompressionOptions(format: format)
        options.requiresPassword = true
        options.encryptFileNames = false
        if format == .zip { options.zipEncryption = .aes256 }
        let archive = root.appendingPathComponent("Contents.\(format.fileExtension)")
        try await NativeSevenZipArchiveEngine().createArchive(from: [secret, plain], outputURL: archive, options: options,
            password: ArchiveContentEncryptionTests.password, progress: { _ in })
        return EncryptedContentsFixture(root: root, archive: archive)
    }

    func cleanUp() {
        browsers.forEach { $0.close() }
        for suite in suites { UserDefaults(suiteName: suite)?.removeTestSuite(named: suite) }
        try? FileManager.default.removeItem(at: root)
    }

    /// A browser inside the archive: Gallery (the preview always shown) or List without the preview.
    func browser(previewVisible: Bool = true) async throws -> FileBrowserState {
        let suite = "ZforgeTestSuite.EncryptedContents-\(UUID().uuidString)"
        suites.append(suite)
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = previewVisible ? .gallery : .list
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: ArchiveSessionClient(engine: engine))
        browsers.append(state)
        state.volumeClassifier = { _ in .internalDisk }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        await state.openArchive(try #require(state.items.first { $0.name == archive.lastPathComponent }))
        return state
    }
}
