import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// Settings ▸ Compression as a list of profiles that open their own page (ZF-58): the summary
/// under each name, Add Profile, Duplicate Profile and changes saved as they are made. Hosted
/// offscreen; pushing a row, the back button and the delete confirmation are proven by
/// `SettingsUITests.testCompressionProfileOpensSavesAndDeletes`.
@Suite("Settings compression profiles (ZF-58)")
@MainActor
struct CompressionProfileSettingsTests {
    private let english = Locale(identifier: "en")

    @Test("The summary names the format, then the level, method, solid mode and password that apply")
    func summary() {
        var options = CompressionOptions(format: .sevenZip, level: 5, method: .lzma2, solid: true)
        #expect(options.summary(locale: english) == "7z · Normal · LZMA2 · Solid")
        options.requiresPassword = true
        #expect(options.summary(locale: english) == "7z · Normal · LZMA2 · Solid · Password")
        options.solid = false
        options.method = .automatic
        options.level = 9
        #expect(options.summary(locale: english) == "7z · Ultra · Password", "The automatic method is not named")

        #expect(CompressionOptions(format: .zip, level: 3, method: .deflate).summary(locale: english) == "ZIP · Fast · Deflate")
        #expect(CompressionOptions(format: .zip, level: 0).summary(locale: english) == "ZIP · Store")
        // Solid mode exists only in 7z; TAR and WIM have no level.
        #expect(CompressionOptions(format: .tar, solid: true).summary(locale: english) == "TAR")
        #expect(CompressionOptions(format: .wim).summary(locale: english) == "WIM")
        #expect(CompressionOptions(format: .xz, level: 7).summary(locale: english) == "XZ · Maximum")
        // A password left in an unsupported format is dropped, as the profile normalizes it.
        #expect(CompressionOptions(format: .gzip, level: 1, requiresPassword: true).summary(locale: english) == "GZIP · Fastest")

        let german = AppLanguagePreference.german.locale
        let protected = CompressionOptions(format: .sevenZip, level: 7, solid: true, requiresPassword: true)
        #expect(protected.summary(locale: german) == "7z · Maximum · Solide · Passwort")
        let portuguese = AppLanguagePreference.portugueseBrazil.locale
        #expect(protected.summary(locale: portuguese) == "7z · Máximo · Sólido · Senha")
    }

    @Test("Add Profile appends a profile with the standard options named New Profile, made unique")
    func addProfile() throws {
        let (preferences, cleanup) = try makePreferences()
        defer { cleanup() }
        let defaultID = preferences.defaultCompressionProfileID
        let first = preferences.addCompressionProfile()
        let second = preferences.addCompressionProfile()
        #expect(preferences.compressionProfiles.map(\.name) == ["Auto", "New Profile", "New Profile 2"])
        #expect(preferences.compressionProfiles.map(\.id).suffix(2) == [first, second])
        #expect(preferences.compressionProfiles[1].options == CompressionOptions().normalized())
        #expect(preferences.defaultCompressionProfileID == defaultID, "Adding a profile keeps the default")
    }

    @Test("Duplicate Profile copies the options and the session password under a new name")
    func duplicateProfile() throws {
        let (preferences, cleanup) = try makePreferences()
        defer { cleanup() }
        let original = preferences.defaultCompressionProfileID
        let options = CompressionOptions(format: .sevenZip, level: 9, requiresPassword: true)
        preferences.updateCompressionProfile(original, options: options)
        preferences.setSessionPassword("secret", for: original)

        let copy = try #require(preferences.duplicateCompressionProfile(original))
        let profile = try #require(preferences.compressionProfiles.first { $0.id == copy })
        #expect(profile.name == "Auto 2")
        #expect(profile.options == options.normalized())
        #expect(preferences.sessionPassword(for: copy) == "secret")
        #expect(preferences.defaultCompressionProfileID == original)
        #expect(preferences.duplicateCompressionProfile(UUID()) == nil)
    }

    @Test("The session password is kept once both fields match, and cleared when both are empty")
    func sessionPasswordPairs() {
        #expect(CompressionProfileDetailView.sessionPassword(password: "secret", confirmation: "secret") == "secret")
        #expect(CompressionProfileDetailView.sessionPassword(password: "secret", confirmation: "sec") == nil)
        #expect(CompressionProfileDetailView.sessionPassword(password: "", confirmation: "secret") == nil)
        #expect(CompressionProfileDetailView.sessionPassword(password: "", confirmation: "") == "")
    }

    @Test("Typing a profile's name saves it as it is typed; an emptied name returns to the saved one")
    func nameIsSavedWhileTyping() async throws {
        let (preferences, cleanup) = try makePreferences()
        defer { cleanup() }
        let id = preferences.defaultCompressionProfileID
        let page = try DetailPage(preferences: preferences, id: id)
        defer { page.close() }
        let field = try page.nameField()
        #expect(field.stringValue == "Auto")

        try page.type(" 7z", into: field)
        try await page.waitUntil("the typed name is saved") { preferences.compressionProfiles[0].name == "Auto 7z" }

        try page.replaceText(of: field, with: "")
        try await page.waitUntil("the field is empty") { field.stringValue.isEmpty }
        #expect(preferences.compressionProfiles[0].name == "Auto 7z", "An empty name is never saved")
        page.window.makeFirstResponder(nil)
        try await page.waitUntil("the field shows the saved name again") { field.stringValue == "Auto 7z" }
    }

    @Test("Snapshot: the profile list", arguments: ZforgeSnapshot.appearances.map(\.name))
    func listSnapshot(name: String) async throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == name }).appearance
        let (preferences, cleanup) = try makePreferences()
        defer { cleanup() }
        let zip = preferences.createCompressionProfile(
            name: "ZIP for sharing", options: CompressionOptions(format: .zip, level: 3, method: .deflate))
        preferences.updateCompressionProfile(preferences.compressionProfiles[0].id,
                                             options: CompressionOptions(format: .sevenZip, method: .lzma2, solid: true))
        _ = preferences.createCompressionProfile(
            name: "Maximum, encrypted", options: CompressionOptions(format: .sevenZip, level: 9, requiresPassword: true))
        preferences.defaultCompressionProfileID = zip
        let pane = NavigationStack { CompressionSettingsPane(preferences: preferences, openProfile: { _ in }) }
            .environment(\.locale, english)
        let (host, window) = hostOffscreen(pane)
        defer { window.close() }
        ZforgeSnapshot.assert(host, appearance: appearance, named: "profiles-\(name)")
    }

    @Test("Snapshot: a profile's page", arguments: [
        ("zip-light", NSAppearance.Name.aqua, ArchiveCompressionFormat.zip, false),
        ("7z-password-light", .aqua, .sevenZip, true),
        ("7z-password-dark", .darkAqua, .sevenZip, true),
    ])
    func detailSnapshot(name: String, appearance: NSAppearance.Name, format: ArchiveCompressionFormat, password: Bool) async throws {
        let (preferences, cleanup) = try makePreferences()
        defer { cleanup() }
        let id = preferences.defaultCompressionProfileID
        preferences.updateCompressionProfile(id, options: CompressionOptions(format: format, requiresPassword: password))
        let page = try DetailPage(preferences: preferences, id: id)
        defer { page.close() }
        #expect(page.secureFields().count == (password ? 2 : 0))
        ZforgeSnapshot.assert(page.host, appearance: appearance, named: "profile-\(name)")
    }

    private func makePreferences() throws -> (FileBrowserPreferences, () -> Void) {
        let suite = "ZforgeTestSuite.CompressionProfiles-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        return (preferences, { defaults.removeTestSuite(named: suite) })
    }
}

@MainActor private let detailSize = CGSize(width: SettingsLayout.detailWidth, height: SettingsLayout.height)

/// Hosts a view in an offscreen window, which the caller keeps and closes.
@MainActor
private func hostOffscreen<V: View>(_ view: V) -> (host: NSView, window: NSWindow) {
    let host = NSHostingView(rootView: view.frame(width: detailSize.width, height: detailSize.height))
    let window = NSWindow(contentRect: NSRect(origin: .zero, size: detailSize), styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    return (host, window)
}

/// A profile's page in a navigation stack, offscreen.
@MainActor
private final class DetailPage {
    let host: NSView
    let window: NSWindow

    init(preferences: FileBrowserPreferences, id: UUID) throws {
        (host, window) = hostOffscreen(NavigationStack {
            CompressionProfileDetailView(preferences: preferences, id: id, show: { _ in }, close: {})
        }.environment(\.locale, Locale(identifier: "en")))
    }

    func close() { window.close() }

    func nameField() throws -> NSTextField {
        let fields = host.settingsDescendants(of: NSTextField.self).filter { $0.isEditable && !($0 is NSSecureTextField) }
        #expect(fields.count == 1, "Editable fields: \(fields.map(\.stringValue))")
        return try #require(fields.first)
    }

    func secureFields() -> [NSSecureTextField] { host.settingsDescendants(of: NSSecureTextField.self) }

    /// Types at the end of the field through its field editor, as the keyboard does.
    func type(_ text: String, into field: NSTextField) throws {
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor() as? NSTextView)
        editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
        editor.insertText(text, replacementRange: editor.selectedRange())
    }

    func replaceText(of field: NSTextField, with text: String) throws {
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor() as? NSTextView)
        editor.selectAll(nil)
        if text.isEmpty { editor.deleteBackward(nil) } else { editor.insertText(text, replacementRange: editor.selectedRange()) }
    }

    func waitUntil(_ description: String, _ condition: () -> Bool) async throws {
        for _ in 0..<400 where !condition() { try await Task.sleep(for: .milliseconds(5)) }
        #expect(condition(), "Timed out waiting until \(description)")
        if !condition() { throw CancellationError() }
    }
}
