import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// Offscreen layout checks for the Compress Custom… panel (Settings ▸ Compression is covered by
/// `CompressionProfileSettingsTests`). The panel is built by its production session but never presented, so no
/// window appears on screen. AppKit-backed controls (text fields, pop-up buttons and
/// secure fields) are measured numerically; SwiftUI-drawn labels, buttons and checkboxes
/// expose no offscreen frames, so their placement is guarded by the snapshots.
@Suite("Compress Custom panel layout")
@MainActor
struct CompressionPanelLayoutTests {
    @Test("Compress Custom lays out aligned columns, grows for password options and preserves the proposed name")
    func customCompressionPanel() async throws {
        let fixture = try PanelFixture(format: .zip)
        defer { fixture.close() }
        let panel = fixture.panel
        let host = try #require(panel.contentView)
        host.layoutSubtreeIfNeeded()

        // The panel opens at its content's height, below 700 pt in both directions.
        #expect(abs(panel.contentLayoutRect.height - host.fittingSize.height) <= 1)
        #expect(panel.contentLayoutRect.width == CompressionSaveDialogLayout.width)
        #expect(panel.frame.width < 700)
        #expect(panel.frame.height < 700)
        #expect(panel.title == "Compress Custom…")

        // Profile editing belongs to Settings: only the save fields are editable text.
        #expect(fixture.textFields().count == 2)
        let profile = try fixture.popUp("Compression profile")
        #expect(profile.titleOfSelectedItem == "Auto")
        let zipFormat = try fixture.popUp("Archive format")
        #expect(zipFormat.titleOfSelectedItem == "ZIP")
        #expect(fixture.popUpIfPresent("Dictionary size") == nil)
        try expectSaveFields(fixture, alignedWith: fixture.popUp("CPU threads"))
        ZforgeSnapshot.assert(host, appearance: .aqua, named: "compact-zip")

        // Choosing 7z through the pop-up's own action changes the options but not the name.
        try fixture.choose("7z", in: "Archive format")
        try await fixture.waitUntil("7z options appear") { fixture.popUpIfPresent("Dictionary size") != nil }
        #expect(try fixture.nameField().stringValue == "Welcome.zip", "Changing an archive option must preserve the proposed file name.")
        let format = try fixture.popUp("Archive format")
        let dictionary = try fixture.popUp("Dictionary size")
        #expect(abs(format.windowFrame.width - dictionary.windowFrame.width) < 5)
        #expect(abs(format.windowFrame.minX - CompressionSaveDialogLayout.horizontalInset) < 3)
        #expect(abs(try fixture.popUp("Compression profile").windowFrame.maxX - dictionary.windowFrame.maxX) < 3)
        #expect(dictionary.windowFrame.minX > format.windowFrame.maxX)
        try expectSaveFields(fixture, alignedWith: dictionary)
        try await fixture.waitUntil("the panel fits its 7z content") {
            abs(panel.contentLayoutRect.height - host.fittingSize.height) <= 1
        }
        let compactHeight = panel.contentLayoutRect.height
        #expect(fixture.secureFields().isEmpty)
        ZforgeSnapshot.assert(host, appearance: .aqua, named: "compact-7z")

        // Protect with password (bound to this option) expands the password fields.
        fixture.draft.options.requiresPassword = true
        try await fixture.waitUntil("the panel grows for the password fields") {
            panel.contentLayoutRect.height > compactHeight + 40
        }
        #expect(try fixture.nameField().stringValue == "Welcome.zip", "Expanding password options must preserve the proposed file name.")
        let secure = fixture.secureFields()
        #expect(secure.count == 2)
        let password = try #require(secure.max { $0.windowFrame.maxY < $1.windowFrame.maxY })
        let lowestLeftPopUp = try #require(fixture.popUps().filter { $0.windowFrame.minX < dictionary.windowFrame.minX }
            .min { $0.windowFrame.minY < $1.windowFrame.minY })
        #expect(password.windowFrame.maxY < lowestLeftPopUp.windowFrame.minY, "The password field sits below the left column's options.")
        #expect(abs(password.windowFrame.minX - format.windowFrame.minX) < 30)
        #expect(password.windowFrame.maxX < dictionary.windowFrame.minX, "The password stays in the left column.")
        #expect(abs(panel.contentLayoutRect.height - host.fittingSize.height) <= 1)
        try expectSaveFields(fixture, alignedWith: dictionary)
        #expect(try fixture.nameField().stringValue == "Welcome.zip", "Resizing the panel must preserve the proposed file name.")
        ZforgeSnapshot.assert(host, appearance: .aqua, named: "password-7z")

        #expect(panel.makeFirstResponder(try fixture.nameField()))
        #expect(panel.makeFirstResponder(password))
        #expect(try fixture.nameField().stringValue == "Welcome.zip", "Leaving the name field must preserve the proposed file name.")

        fixture.draft.options.requiresPassword = false
        try await fixture.waitUntil("the password fields collapse") { fixture.secureFields().isEmpty }
        try await fixture.waitUntil("the panel returns to its compact height") {
            abs(panel.contentLayoutRect.height - compactHeight) < 5
        }
        #expect(try fixture.nameField().stringValue == "Welcome.zip")
    }

    private func expectSaveFields(_ fixture: PanelFixture, alignedWith rightEdge: NSView) throws {
        let name = try fixture.nameField().windowFrame
        let tags = try fixture.tagsField().windowFrame
        #expect(name.width > 380)
        #expect(abs(name.width - tags.width) < 5)
        #expect(tags.maxY <= name.minY, "Tags sit below Save As.")
        #expect(abs(name.maxX - rightEdge.windowFrame.maxX) < 5)
    }
}

/// The production Compress Custom… session, built over isolated preferences and never presented.
@MainActor
private final class PanelFixture {
    let draft: CompressionDraft
    let panel: NSPanel
    private let session: CompressionSaveDialogSession
    private let defaults: UserDefaults
    private let suite: String

    init(format: ArchiveCompressionFormat) throws {
        suite = "ZforgeTestSuite.CompressionPanel-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.defaultCompressionFormat = format
        draft = CompressionDraft(preferences: preferences)
        session = CompressionSaveDialogSession(draft: draft, preferences: preferences, name: "Welcome.zip",
                                               directory: URL(fileURLWithPath: "/ZforgeFixtures", isDirectory: true))
        panel = session.makePanel()
        panel.isReleasedWhenClosed = false
    }

    func close() {
        panel.close()
        defaults.removeTestSuite(named: suite)
    }

    private var host: NSView { panel.contentView! }

    func popUps() -> [NSPopUpButton] { host.descendants(of: NSPopUpButton.self) }
    func popUpIfPresent(_ label: String) -> NSPopUpButton? { popUps().first { $0.accessibilityLabel() == label } }
    func popUp(_ label: String) throws -> NSPopUpButton {
        try #require(popUpIfPresent(label), "\(label) among \(popUps().map { $0.accessibilityLabel() ?? "" })")
    }

    func textFields() -> [NSTextField] {
        host.descendants(of: NSTextField.self).filter { $0.isEditable && !($0 is NSSecureTextField) }
    }
    func secureFields() -> [NSSecureTextField] { host.descendants(of: NSSecureTextField.self) }
    /// The save fields expose their identifiers only to accessibility clients, so they are
    /// told apart by position: Save As is the top field and Tags the one below it.
    private func saveField(_ index: Int) throws -> NSTextField {
        let fields = textFields().sorted { $0.windowFrame.maxY > $1.windowFrame.maxY }
        return try #require(fields.indices.contains(index) ? fields[index] : nil, "\(fields.count) save fields")
    }
    func nameField() throws -> NSTextField { try saveField(0) }
    func tagsField() throws -> NSTextField { try saveField(1) }

    /// Picks an item the way a click in the pop-up's menu does: select it, then send the action.
    func choose(_ title: String, in label: String) throws {
        let button = try popUp(label)
        button.selectItem(withTitle: title)
        #expect(button.titleOfSelectedItem == title)
        #expect(button.sendAction(button.action, to: button.target))
    }

    /// Lets SwiftUI and the session's deferred resize, queued on the main queue, run until `condition` holds.
    func waitUntil(_ description: String, _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while true {
            host.layoutSubtreeIfNeeded()
            if condition() { return }
            guard ContinuousClock.now < deadline else { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Timed out waiting until \(description)")
        throw CancellationError()
    }
}

extension NSView {
    fileprivate func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { child -> [T] in ((child as? T).map { [$0] } ?? []) + child.descendants(of: type) }
    }

    fileprivate var windowFrame: NSRect { convert(bounds, to: nil) }
}
