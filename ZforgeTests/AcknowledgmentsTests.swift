import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// The license notices the app ships (D-93): the list `Scripts/update-notices.py` writes into the
/// bundle, the texts it names, their agreement with the vendored 7-Zip and the pinned packages,
/// and the Acknowledgments window that shows them.
@Suite("Acknowledgments and shipped license notices (D-93)")
@MainActor
struct AcknowledgmentsTests {
    private static let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    @Test("The bundle lists Zforge, 7-Zip and the linked packages, and ships every text it names")
    func bundleShipsEveryNotice() throws {
        let components = Acknowledgments.components()
        #expect(components.map(\.id) == ["zforge", "7zip", "eventsource", "swift-sdk", "swift-log", "swift-system"])
        for component in components {
            #expect(!component.files.isEmpty, "\(component.id) names no license text")
            for file in component.files {
                let text = try #require(Acknowledgments.text(ofFile: file.name), "\(file.name) is not in the bundle")
                #expect(text.count > 200, "\(file.name) is \(text.count) characters")
            }
        }
        let zforge = try #require(components.first)
        #expect(Acknowledgments.text(ofFile: zforge.files[0].name)?.hasPrefix("MIT License") == true)
        #expect(Acknowledgments.displayVersion(of: zforge) == Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }

    @Test("7-Zip's notices are the vendored release's License, LGPL and unRAR texts, at its version")
    func sevenZipNoticesMatchTheVendoredRelease() throws {
        let sevenZip = try #require(Acknowledgments.components().first { $0.id == "7zip" })
        let provenance = try JSONSerialization.jsonObject(with: Data(contentsOf: Self.repository.appendingPathComponent("Vendor/7zip-provenance.json"))) as? [String: Any]
        #expect(sevenZip.version == provenance?["version"] as? String)
        let documents = Self.repository.appendingPathComponent("Vendor/7zip/DOC")
        let expected = ["7-Zip-License.txt": "License.txt", "7-Zip-LGPL.txt": "copying.txt", "7-Zip-unRAR.txt": "unRarLicense.txt"]
        #expect(Set(sevenZip.files.map(\.name)) == Set(expected.keys))
        for file in sevenZip.files {
            let source = try #require(expected[file.name])
            #expect(file.source == "DOC/\(source)")
            let vendored = try String(contentsOf: documents.appendingPathComponent(source), encoding: .utf8)
            #expect(Acknowledgments.text(ofFile: file.name) == vendored, "\(file.name) differs from DOC/\(source)")
        }
    }

    @Test("Package notices carry the versions pinned in Package.resolved")
    func packageVersionsMatchTheResolvedPins() throws {
        let resolved = Self.repository.appendingPathComponent("Zforge.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        let pins = try #require((try JSONSerialization.jsonObject(with: Data(contentsOf: resolved)) as? [String: Any])?["pins"] as? [[String: Any]])
        let versions = Dictionary(uniqueKeysWithValues: pins.compactMap { pin -> (String, String)? in
            guard let identity = pin["identity"] as? String, let state = pin["state"] as? [String: Any],
                  let version = state["version"] as? String else { return nil }
            return (identity, version)
        })
        for component in Acknowledgments.components() where !["zforge", "7zip"].contains(component.id) {
            #expect(component.version == versions[component.id], "\(component.id)")
        }
    }

    @Test("Each license text is titled by the upstream file it copies")
    func fileTitles() throws {
        let components = Acknowledgments.components()
        let sevenZip = try #require(components.first { $0.id == "7zip" })
        #expect(sevenZip.files.map(\.source) == ["DOC/License.txt", "DOC/copying.txt", "DOC/unRarLicense.txt"])
        let log = try #require(components.first { $0.id == "swift-log" })
        #expect(log.files.map(\.source) == ["LICENSE.txt", "NOTICE.txt"])
        #expect(components.first?.files.map(\.source) == ["LICENSE"])
    }

    @Test("A bundle without the list shows no component instead of failing")
    func missingListIsEmpty() {
        #expect(Acknowledgments.components(in: Bundle(for: BundleMarker.self)).isEmpty)
    }

    @Test("The window opens on Zforge and titles its toolbar with the chosen component")
    func windowTitlesTheChosenComponent() async throws {
        for (selection, title) in [(nil, "Zforge"), ("7zip", "7-Zip")] as [(String?, String)] {
            let suite = "ZforgeTestSuite.Acknowledgments-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removeTestSuite(named: suite) }
            let preferences = FileBrowserPreferences(defaults: defaults)
            preferences.language = .english
            let size = CGSize(width: KeyboardShortcutsLayout.defaultWidth, height: KeyboardShortcutsLayout.defaultHeight)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                  styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: AcknowledgmentsView(preferences: preferences, selection: selection))
            window.setContentSize(size)
            defer { window.close(); window.contentViewController = nil }
            func toolbarTitle() -> NSTextField? {
                window.contentView?.superview?.settingsDescendants(of: NSTextField.self).first { $0.stringValue == title }
            }
            for _ in 0..<400 where toolbarTitle() == nil {
                window.layoutIfNeeded()
                try await Task.sleep(for: .milliseconds(5))
            }
            #expect(toolbarTitle() != nil, "No toolbar title \(title)")
        }
    }

    @Test("7-Zip's page at the default size, light and dark")
    func sevenZipPageSnapshot() throws {
        let sevenZip = try #require(Acknowledgments.components().first { $0.id == "7zip" })
        let size = CGSize(width: KeyboardShortcutsLayout.defaultWidth - KeyboardShortcutsLayout.sidebarWidth,
                          height: KeyboardShortcutsLayout.defaultHeight)
        for (name, appearance) in ZforgeSnapshot.appearances {
            ZforgeSnapshot.assert(
                AcknowledgmentDetail(component: sevenZip, bundle: .main)
                    .environment(\.locale, Locale(identifier: "en"))
                    .background(Color(nsColor: .windowBackgroundColor)),
                size: size, appearance: appearance, named: name
            )
        }
    }
}

private final class BundleMarker {}
