import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// ZF-78: opening an archive from Finder when Zforge is the default app for its type asks
/// whether to open or extract it (with “Don’t ask again”), or applies the choice saved in
/// Settings ▸ General; Extract shows only its progress, with no browser window.
@MainActor
@Suite("Archives opened from Finder: open or extract (ZF-78)")
struct FinderArchiveOpeningTests {
    // MARK: Routing and preference

    @Test("The choice applies only to archives Zforge opens by default; the others open")
    func routing() {
        let byDefault = URL(fileURLWithPath: "/Files/Default.zip")
        let explicit = URL(fileURLWithPath: "/Files/Explicit.7z")
        let opensByDefault: (URL) -> Bool = { $0 == byDefault }
        #expect(FinderArchiveRouting.route([byDefault, explicit], choice: .ask, opensByDefault: opensByDefault)
            == FinderArchiveRouting(open: [explicit], ask: [byDefault]))
        #expect(FinderArchiveRouting.route([byDefault, explicit], choice: .open, opensByDefault: opensByDefault)
            == FinderArchiveRouting(open: [byDefault, explicit]))
        #expect(FinderArchiveRouting.route([byDefault, explicit], choice: .extract, opensByDefault: opensByDefault)
            == FinderArchiveRouting(open: [explicit], extract: [byDefault]))
    }

    static let footerEnglish = "When you double-click an archive whose type opens with Zforge, choose Zforge in Open With, or drop it on the Dock icon, Zforge asks, opens it, or extracts it into a folder named after it, next to it, showing only the progress. An archive whose type opens with another app always opens."

    @Test("The Settings footer says Open With and a Dock drop follow the choice for types that open with Zforge (D-116)")
    func settingsFooterCoversEveryWayOfOpening() {
        #expect(FinderArchiveOpeningSettingsSection.footer(locale: Locale(identifier: "en")) == Self.footerEnglish)
        for language in AppLanguagePreference.supportedLanguages where language != .english {
            let text = FinderArchiveOpeningSettingsSection.footer(locale: language.locale)
            #expect(text != Self.footerEnglish, "\(language) must be translated")
        }
    }

    @Test("The saved choice defaults to Ask, persists, and an unknown value falls back to Ask")
    func preference() throws {
        let suite = "ZforgeTestSuite.FinderArchiveOpening-\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suite)?.removeTestSuite(named: suite) }
        let defaults = try #require(UserDefaults(suiteName: suite))
        #expect(FileBrowserPreferences(defaults: defaults).finderArchiveOpening == .ask)
        FileBrowserPreferences(defaults: defaults).finderArchiveOpening = .extract
        #expect(FileBrowserPreferences(defaults: defaults).finderArchiveOpening == .extract)
        defaults.set("unknown", forKey: FinderArchiveOpeningChoice.defaultsKey)
        #expect(FileBrowserPreferences(defaults: defaults).finderArchiveOpening == .ask)
        #expect(FinderArchiveOpeningChoice.allCases == [.ask, .open, .extract])
        #expect(FinderArchiveOpeningChoice.allCases.map { AppLocalization.string($0.titleKey, locale: Locale(identifier: "en")) }
            == ["Ask Each Time", "Open in Zforge", "Extract"])
    }

    @Test("Zforge is the default app only when macOS opens the file with Zforge's bundle identifier")
    func defaultApplication() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("DefaultApp-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let text = folder.appendingPathComponent("Note.txt")
        try Data("note".utf8).write(to: text)
        let textApplication = try #require(NSWorkspace.shared.urlForApplication(toOpen: text))
        let textIdentifier = try #require(Bundle(url: textApplication)?.bundleIdentifier)
        #expect(FinderArchiveDefaultApplication.opensWithZforge(text, bundleIdentifier: textIdentifier))
        #expect(!FinderArchiveDefaultApplication.opensWithZforge(text, bundleIdentifier: "io.libor.Zforge.not-the-handler"))
        #expect(!FinderArchiveDefaultApplication.opensWithZforge(text, bundleIdentifier: nil))
        let unknown = folder.appendingPathComponent("Data.zforge-no-handler-\(UUID().uuidString.prefix(6))")
        try Data("x".utf8).write(to: unknown)
        #expect(!FinderArchiveDefaultApplication.opensWithZforge(unknown, bundleIdentifier: textIdentifier))
    }

    // MARK: Dialog

    @Test("The dialog offers Open (Return), Extract and Cancel, with Don’t ask again")
    func dialog() {
        let english = Locale(identifier: "en")
        let single = FinderArchiveChoiceAlert.make(archiveNames: ["Vega Demo.zip"], locale: english)
        #expect(single.messageText == "Open or extract “Vega Demo.zip”?")
        #expect(single.informativeText == "Extract creates a folder named after the archive, next to it. You can change this choice in Settings ▸ General.")
        #expect(single.buttons.map(\.title) == ["Open", "Extract", "Cancel"])
        #expect(single.buttons.first?.keyEquivalent == "\r")
        #expect(single.buttons.last?.keyEquivalent == "\u{1b}")
        #expect(single.showsSuppressionButton)
        #expect(single.suppressionButton?.title == "Don’t ask again")

        let several = FinderArchiveChoiceAlert.make(archiveNames: ["A.zip", "B.7z"], locale: english)
        #expect(several.messageText == "Open or extract these archives?")
        #expect(several.informativeText.hasPrefix("A.zip and B.7z\n\n"))

        let portuguese = FinderArchiveChoiceAlert.make(archiveNames: ["Vega Demo.zip"], locale: Locale(identifier: "pt-BR"))
        #expect(portuguese.messageText == "Abrir ou extrair “Vega Demo.zip”?")
        #expect(portuguese.buttons.map(\.title) == ["Abrir", "Extrair", "Cancelar"])
        #expect(portuguese.suppressionButton?.title == "Não perguntar novamente")

        #expect(FinderArchiveChoiceAlert.answer(for: .alertFirstButtonReturn, suppressed: false)
            == FinderArchiveChoiceAnswer(choice: .open, remember: false))
        #expect(FinderArchiveChoiceAlert.answer(for: .alertSecondButtonReturn, suppressed: true)
            == FinderArchiveChoiceAnswer(choice: .extract, remember: true))
        #expect(FinderArchiveChoiceAlert.answer(for: .alertThirdButtonReturn, suppressed: true) == nil)
    }

    // MARK: AppDelegate

    @Test("A saved choice opens or extracts without asking; an archive of a type that opens with another app always opens")
    func savedChoice() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        harness.preferences.finderArchiveOpening = .extract
        harness.delegate.receiveOpenedArchives([harness.byDefault, harness.explicit])
        #expect(harness.extracted == [[harness.byDefault]])
        #expect(harness.asked.isEmpty)
        #expect(harness.delegate.takePendingArchiveRequests().map(\.initialURL) == [harness.explicit])

        harness.preferences.finderArchiveOpening = .open
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        #expect(harness.extracted.count == 1)
        #expect(harness.delegate.takePendingArchiveRequests().map(\.initialURL) == [harness.byDefault])
    }

    @Test("Asking: Open, Extract, Cancel, and Don’t ask again saves the choice", arguments: ["open", "extract", "cancel", "openRemember", "extractRemember"])
    func asking(answer: String) async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        harness.answer = switch answer {
        case "open": FinderArchiveChoiceAnswer(choice: .open, remember: false)
        case "extract": FinderArchiveChoiceAnswer(choice: .extract, remember: false)
        case "openRemember": FinderArchiveChoiceAnswer(choice: .open, remember: true)
        case "extractRemember": FinderArchiveChoiceAnswer(choice: .extract, remember: true)
        default: nil
        }
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        await harness.delegate.waitForArchiveChoices()
        #expect(harness.asked == [["Default.zip"]])
        let opened = harness.delegate.takePendingArchiveRequests().map(\.initialURL)
        #expect(opened == (answer.hasPrefix("open") ? [harness.byDefault] : []))
        #expect(harness.extracted == (answer.hasPrefix("extract") ? [[harness.byDefault]] : []))
        let saved: FinderArchiveOpeningChoice = switch answer {
        case "openRemember": .open
        case "extractRemember": .extract
        default: .ask
        }
        #expect(harness.preferences.finderArchiveOpening == saved)
    }

    @Test("Questions are asked one at a time, in order")
    func serializedQuestions() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        let gate = AsyncGate()
        harness.askGate = gate
        harness.answer = FinderArchiveChoiceAnswer(choice: .open, remember: false)
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        let second = URL(fileURLWithPath: harness.byDefault.deletingLastPathComponent().path + "/Second.zip")
        harness.defaults.insert(second)
        harness.delegate.receiveOpenedArchives([second])
        await gate.waitUntilEntered()
        #expect(harness.asked == [["Default.zip"]], "The second question waits for the first answer")
        await gate.open()
        await harness.delegate.waitForArchiveChoices()
        #expect(harness.asked == [["Default.zip"], ["Second.zip"]])
        #expect(harness.delegate.takePendingArchiveRequests().map(\.initialURL) == [harness.byDefault, second])
    }

    @Test("With no browser window open, an archive to open opens its own window; SwiftUI adds none")
    func openerWithoutWindows() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        var opened: [BrowserWindowRequest] = []
        harness.delegate.offerWindowOpener { opened.append($0) }
        harness.delegate.offerWindowOpener { _ in Issue.record("Only the first opener offered is kept") }
        await harness.delegate.drainMainQueue()
        harness.preferences.finderArchiveOpening = .open
        harness.delegate.receiveOpenedArchives([harness.byDefault, harness.explicit])
        #expect(opened.map(\.initialURL) == [harness.byDefault, harness.explicit])
        #expect(harness.delegate.takePendingArchiveRequests().isEmpty)

        harness.preferences.finderArchiveOpening = .ask
        harness.answer = FinderArchiveChoiceAnswer(choice: .open, remember: false)
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        await harness.delegate.waitForArchiveChoices()
        #expect(opened.map(\.initialURL) == [harness.byDefault, harness.explicit, harness.byDefault])
    }

    @Test("An open browser window takes the request; extracting or asking leaves it as it is")
    func openWindowTakesRequests() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        var opened: [BrowserWindowRequest] = []
        harness.delegate.offerWindowOpener { opened.append($0) }
        await harness.delegate.drainMainQueue()
        let window = RecordingWindow()
        window.reportsVisible = true
        harness.delegate.registerBrowserWindow(window)
        harness.delegate.receiveOpenedArchives([harness.explicit])
        #expect(opened.isEmpty, "The open window's root takes it from the queue")
        #expect(harness.delegate.takePendingArchiveRequests().map(\.initialURL) == [harness.explicit])

        harness.answer = nil
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        await harness.delegate.waitForArchiveChoices()
        harness.preferences.finderArchiveOpening = .extract
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        #expect(harness.extracted == [[harness.byDefault]])
        #expect(window.alphaValue == 1 && !window.closed, "A window the user has open is never hidden or closed")

        // Closed or minimized windows: a minimized one still takes requests, a closed one does not.
        window.reportsVisible = false
        window.reportsMiniaturized = true
        harness.delegate.receiveOpenedArchives([harness.explicit])
        #expect(opened.isEmpty)
        _ = harness.delegate.takePendingArchiveRequests()
        window.reportsMiniaturized = false
        harness.delegate.receiveOpenedArchives([harness.explicit])
        #expect(opened.map(\.initialURL) == [harness.explicit])
    }

    @Test("While launching, requests wait for the default window SwiftUI may still create; then they open their own")
    func launchingWaits() async throws {
        let harness = try Harness(launched: false)
        defer { harness.cleanUp() }
        var opened: [BrowserWindowRequest] = []
        harness.delegate.offerWindowOpener { opened.append($0) }
        await harness.delegate.drainMainQueue()
        harness.preferences.finderArchiveOpening = .open
        harness.delegate.receiveOpenedArchives([harness.byDefault, harness.explicit])
        #expect(opened.isEmpty, "Not before launching ends")
        // A default window created at launch takes the first one.
        #expect(harness.delegate.makeDefaultWindowRequest().initialURL == harness.byDefault)
        harness.delegate.launchDidFinish()
        #expect(opened.map(\.initialURL) == [harness.explicit], "The rest opens its own window")
        #expect(harness.delegate.takePendingArchiveRequests().isEmpty)
    }

    @Test("A request that arrives before the opener exists opens once it is offered")
    func lateOpener() async throws {
        let harness = try Harness()
        defer { harness.cleanUp() }
        harness.preferences.finderArchiveOpening = .open
        harness.delegate.receiveOpenedArchives([harness.byDefault])
        var opened: [BrowserWindowRequest] = []
        harness.delegate.offerWindowOpener { opened.append($0) }
        #expect(opened.isEmpty, "Not during the SwiftUI update that offers it")
        await harness.delegate.drainMainQueue()
        #expect(opened.map(\.initialURL) == [harness.byDefault])
        #expect(harness.delegate.takePendingArchiveRequests().isEmpty)
    }

    // MARK: Windowless extraction

    @Test("Extract writes a folder named after the archive next to it, showing only progress")
    func extraction() async throws {
        let fixture = try ExtractionFixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.zip(named: "Vega Demo.zip")
        let coordinator = fixture.coordinator(grants: FixedGrants(granted: [fixture.root]))
        coordinator.extract([archive])
        await coordinator.waitUntilIdle()
        let output = fixture.root.appendingPathComponent("Vega Demo", isDirectory: true)
        #expect(try String(contentsOf: output.appendingPathComponent("Readme.txt"), encoding: .utf8) == "readme")
        #expect(try String(contentsOf: output.appendingPathComponent("Folder/Inner.txt"), encoding: .utf8) == "inner")
        #expect(fixture.presenter.events.first == "show Vega Demo.zip")
        #expect(fixture.presenter.events.last == "hide")
        #expect(!fixture.presenter.events.contains { $0.hasPrefix("access") || $0.hasPrefix("failure") })
        #expect(coordinator.isIdle)
    }

    @Test("Without access to the archive's folder the user grants it, or nothing is extracted", arguments: [true, false])
    func folderAccess(grants: Bool) async throws {
        let fixture = try ExtractionFixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.zip(named: "Locked.zip")
        let store = FixedGrants(granted: [])
        fixture.presenter.accessAnswer = grants ? fixture.root.deletingLastPathComponent() : nil
        let coordinator = fixture.coordinator(grants: store)
        coordinator.extract([archive])
        await coordinator.waitUntilIdle()
        #expect(fixture.presenter.events.first == "access \(fixture.root.lastPathComponent)")
        let output = fixture.root.appendingPathComponent("Locked", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: output.path) == grants)
        #expect(await store.stored == (grants ? [fixture.root.deletingLastPathComponent()] : []))
        #expect(!fixture.presenter.events.contains { $0.hasPrefix("failure") }, "Declining is not an error")
    }

    @Test("A password is asked, asked again when wrong, and cancelling leaves nothing behind", arguments: [true, false])
    func password(completes: Bool) async throws {
        let fixture = try ExtractionFixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.encrypted7z(named: "Secret.7z", password: "right")
        fixture.presenter.passwords = completes ? ["wrong", "right"] : ["wrong"]
        let coordinator = fixture.coordinator(grants: FixedGrants(granted: [fixture.root]))
        coordinator.extract([archive])
        await coordinator.waitUntilIdle()
        let asks = fixture.presenter.events.filter { $0.hasPrefix("password") }
        // Wrong first, then right (or Cancel at the second prompt).
        #expect(asks == ["password Secret.7z retry=false", "password Secret.7z retry=true"])
        let output = fixture.root.appendingPathComponent("Secret", isDirectory: true)
        if completes {
            #expect(try String(contentsOf: output.appendingPathComponent("Secret.txt"), encoding: .utf8) == "secret")
        } else {
            #expect(!FileManager.default.fileExists(atPath: output.path), "No empty folder is left next to the archive")
        }
        #expect(!fixture.presenter.events.contains { $0.hasPrefix("failure") })
    }

    @Test("Existing items ask Replace or Keep; Cancel stops without an error; Cancel All drops waiting archives",
          arguments: ["keep", "replace", "cancel", "cancelAll"])
    func conflicts(decision: String) async throws {
        let fixture = try ExtractionFixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.zip(named: "Vega Demo.zip")
        let second = try await fixture.zip(named: "Second.zip")
        let output = fixture.root.appendingPathComponent("Vega Demo", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try Data("mine".utf8).write(to: output.appendingPathComponent("Readme.txt"))
        let coordinator = fixture.coordinator(grants: FixedGrants(granted: [fixture.root]))
        fixture.presenter.conflictDecision = switch decision {
        case "replace": .replace(applyToAll: true)
        case "cancel": .cancel
        default: .keep(applyToAll: true)
        }
        if decision == "cancelAll" { fixture.presenter.onConflict = { coordinator.cancelAll() } }
        coordinator.extract([archive, second])
        await coordinator.waitUntilIdle()
        #expect(fixture.presenter.events.contains("conflict Readme.txt"))
        let readme = try String(contentsOf: output.appendingPathComponent("Readme.txt"), encoding: .utf8)
        #expect(readme == (decision == "replace" ? "readme" : "mine"))
        let secondOutput = fixture.root.appendingPathComponent("Second", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: secondOutput.path) == (decision != "cancelAll"),
                "Cancel stops only this archive; Cancel All also drops the waiting one")
        #expect(FileManager.default.fileExists(atPath: output.path), "A folder that was already there stays")
        #expect(!fixture.presenter.events.contains { $0.hasPrefix("failure") })
    }

    @Test("A damaged archive reports a failure")
    func failure() async throws {
        let fixture = try ExtractionFixture()
        defer { fixture.cleanUp() }
        let archive = try await fixture.zip(named: "Broken.zip", payloadSize: 256 * 1024)
        // Damage the compressed data of the first entry, past its local header.
        let handle = try FileHandle(forUpdating: archive)
        try handle.seek(toOffset: 4096)
        try handle.write(contentsOf: Data(repeating: 0xA5, count: 2048))
        try handle.close()
        let coordinator = fixture.coordinator(grants: FixedGrants(granted: [fixture.root]))
        coordinator.extract([archive])
        await coordinator.waitUntilIdle()
        #expect(fixture.presenter.events.last == "failure Broken.zip", "\(fixture.presenter.events)")
        #expect(coordinator.isIdle)
    }

    @Test("The progress panel and the extraction alerts")
    func panelAndAlerts() throws {
        let english = Locale(identifier: "en")
        let parts = ArchiveWriteBackPanelPresenter.makePanel(title: "Extracting Archive", locale: english, target: nil, action: nil)
        defer { parts.panel.close() }
        #expect(parts.panel.title == "Extracting Archive")
        #expect(ArchiveExtractionPanelPresenter.progressText(archive: "Vega Demo.zip", locale: english)
            == "Extracting “Vega Demo.zip”…")
        let password = ArchiveExtractionPanelPresenter.makePasswordAlert(archive: "Secret.7z", retry: false, locale: english)
        #expect(password.alert.informativeText == "Enter the password of “Secret.7z” to extract it.")
        #expect(ArchiveExtractionPanelPresenter.makePasswordAlert(archive: "Secret.7z", retry: true, locale: english)
            .alert.informativeText == "Incorrect password. Try again.")
        let failure = ArchiveExtractionPanelPresenter.makeFailureAlert(
            archive: "Broken.zip", error: ArchiveEngineError.invalidPassword, locale: english)
        #expect(failure.messageText == "“Broken.zip” couldn’t be extracted.")
        let conflict = ArchiveConflictAlert.make(
            ArchiveConflict(path: "Readme.txt", destinationURL: URL(fileURLWithPath: "/Out/Readme.txt"), isDirectory: false),
            locale: english)
        #expect(conflict.alert.buttons.map(\.title) == ["Replace", "Keep", "Cancel"])
        #expect(ArchiveConflictAlert.decision(for: .alertSecondButtonReturn, applyToAll: true) == .keep(applyToAll: true))
        #expect(ArchiveConflictAlert.decision(for: .alertThirdButtonReturn, applyToAll: true) == .cancel)
    }

    // MARK: Snapshots

    @Test("Snapshot: the Settings section", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        ("dark", .darkAqua, .english),
        ("light-pt-BR", .aqua, .portugueseBrazil),
        ("dark-de", .darkAqua, .german),
    ])
    func settingsSectionSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) throws {
        let suite = "ZforgeTestSuite.FinderArchiveOpeningSnapshot-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        let section = VStack(alignment: .leading, spacing: 0) {
            FinderArchiveOpeningSettingsSection(preferences: preferences)
            Spacer(minLength: 0)
        }
        .padding(20)
        .environment(\.locale, language.locale)
        .background(Color(nsColor: .windowBackgroundColor))
        ZforgeSnapshot.assert(section, size: CGSize(width: SettingsLayout.detailWidth, height: 190),
                              appearance: appearance, named: "settings-\(name)")
    }

    @Test("Snapshot: the open-or-extract dialog", arguments: ["single", "several", "single-pt-BR"])
    func dialogSnapshot(kind: String) async throws {
        let alert = switch kind {
        case "several": FinderArchiveChoiceAlert.make(archiveNames: ["Vega Demo.zip", "Orion.7z", "Photos.tar.gz"],
                                                      locale: Locale(identifier: "en"))
        case "single-pt-BR": FinderArchiveChoiceAlert.make(archiveNames: ["Vega Demo.zip"], locale: Locale(identifier: "pt-BR"))
        default: FinderArchiveChoiceAlert.make(archiveNames: ["Vega Demo.zip"], locale: Locale(identifier: "en"))
        }
        #expect(alert.icon?.name() == NSImage.applicationIconName)
        try await ZforgeSnapshot.waitUntilApplicationIconRenders(alert.icon)
        alert.layout()
        let content = try #require(alert.window.contentView)
        ZforgeSnapshot.assert(content, appearance: .aqua, named: "dialog-\(kind)")
    }

    @Test("Snapshot: the extraction progress panel", arguments: ["light", "dark"])
    func progressPanelSnapshot(name: String) throws {
        let english = Locale(identifier: "en")
        let parts = ArchiveWriteBackPanelPresenter.makePanel(
            title: AppLocalization.string("Extracting Archive", locale: english), locale: english, target: nil, action: nil)
        defer { parts.panel.close() }
        parts.label.stringValue = ArchiveExtractionPanelPresenter.progressText(archive: "Vega Demo.zip", locale: english)
        ArchiveExtractionPanelPresenter.setProgress(0.4, on: parts.indicator)
        #expect(!parts.indicator.isIndeterminate)
        #expect(parts.indicator.doubleValue / parts.indicator.maxValue == 0.4)
        let appearance: NSAppearance.Name = name == "dark" ? .darkAqua : .aqua
        parts.panel.appearance = NSAppearance(named: appearance)
        parts.panel.setContentSize(NSSize(width: 420, height: 112))
        parts.panel.layoutIfNeeded()
        let frame = try #require(parts.panel.contentView?.superview)
        ZforgeSnapshot.assert(frame, appearance: appearance, named: "progress-panel-\(name)")
    }
}

// MARK: - Support

@MainActor
private final class Harness {
    let delegate = AppDelegate()
    let suite = "ZforgeTestSuite.FinderArchiveOpeningDelegate-\(UUID().uuidString)"
    let preferences: FileBrowserPreferences
    let byDefault = URL(fileURLWithPath: "/Files/Default.zip")
    let explicit = URL(fileURLWithPath: "/Files/Explicit.7z")
    var defaults: Set<URL>
    var answer: FinderArchiveChoiceAnswer?
    var askGate: AsyncGate?
    private(set) var asked: [[String]] = []
    private(set) var extracted: [[URL]] = []

    init(launched: Bool = true) throws {
        preferences = FileBrowserPreferences(defaults: try #require(UserDefaults(suiteName: suite)))
        if launched { delegate.launchDidFinish() }
        defaults = [byDefault]
        delegate.archiveOpening = FinderArchiveOpeningEnvironment(
            preferences: preferences,
            opensByDefault: { [unowned self] in defaults.contains($0) },
            ask: { [unowned self] names in
                asked.append(names)
                if let askGate { await askGate.enter() }
                askGate = nil
                return answer
            },
            extract: { [unowned self] in extracted.append($0) })
    }

    func cleanUp() {
        UserDefaults(suiteName: suite)?.removeTestSuite(named: suite)
    }
}

/// A browser window whose visibility the test sets, and that records being closed.
@MainActor
private final class RecordingWindow: NSWindow {
    private(set) var closed = false
    var reportsVisible = false
    var reportsMiniaturized = false
    override var isVisible: Bool { reportsVisible }
    override var isMiniaturized: Bool { reportsMiniaturized }

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled],
                   backing: .buffered, defer: true)
        isReleasedWhenClosed = false
    }

    override func close() {
        closed = true
        super.close()
    }
}

/// Holds a question open until the test answers it.
private actor AsyncGate {
    private var entered = false
    private var enteredWaiters: [CheckedContinuation<Void, Never>] = []
    private var opened = false
    private var openWaiters: [CheckedContinuation<Void, Never>] = []

    func enter() async {
        entered = true
        enteredWaiters.forEach { $0.resume() }
        enteredWaiters.removeAll()
        guard !opened else { return }
        await withCheckedContinuation { openWaiters.append($0) }
    }

    func waitUntilEntered() async {
        guard !entered else { return }
        await withCheckedContinuation { enteredWaiters.append($0) }
    }

    func open() {
        opened = true
        openWaiters.forEach { $0.resume() }
        openWaiters.removeAll()
    }
}

private actor FixedGrants: AccessGrantStoring {
    private var granted: [URL]
    private(set) var stored: [URL] = []
    init(granted: [URL]) { self.granted = granted.map(\.standardizedFileURL) }
    func hasGrant(for url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return granted.contains { path == $0.path || path.hasPrefix($0.path + "/") }
    }
    func storeGrant(for url: URL) {
        stored.append(url.standardizedFileURL)
        granted.append(url.standardizedFileURL)
    }
    func activateGrant(for url: URL) throws -> URL {
        guard hasGrant(for: url) else { throw BrowserError.permissionDenied(url) }
        return url
    }
    func removeGrant(for url: URL) {}
    func stopAll() {}
}

@MainActor
private final class RecordingPresenter: ArchiveExtractionPresenting {
    private(set) var events: [String] = []
    var accessAnswer: URL?
    var passwords: [String] = []
    var conflictDecision: ArchiveConflictDecision = .keep(applyToAll: true)
    var onConflict: (() -> Void)?

    func showProgress(archive: String, cancel: @escaping @MainActor () -> Void) { events.append("show \(archive)") }
    func updateProgress(_ fraction: Double?) {}
    func hideProgress() { events.append("hide") }
    func folderAccess(for folder: URL) async -> URL? {
        events.append("access \(folder.lastPathComponent)")
        return accessAnswer
    }
    func password(archive: String, retry: Bool) async -> String? {
        events.append("password \(archive) retry=\(retry)")
        return passwords.isEmpty ? nil : passwords.removeFirst()
    }
    func resolveConflict(_ conflict: ArchiveConflict) async -> ArchiveConflictDecision {
        events.append("conflict \(conflict.path)")
        onConflict?()
        return conflictDecision
    }
    func reportFailure(archive: String, error: any Error) async { events.append("failure \(archive)") }
}

@MainActor
private struct ExtractionFixture {
    let container: URL
    let root: URL
    let input: URL
    let presenter = RecordingPresenter()

    init() throws {
        container = FileManager.default.temporaryDirectory
            .appendingPathComponent("FinderArchiveExtraction-\(UUID().uuidString)", isDirectory: true)
        root = container.appendingPathComponent("Downloads", isDirectory: true)
        input = container.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
    }

    func coordinator(grants: any AccessGrantStoring) -> ArchiveExtractionCoordinator {
        ArchiveExtractionCoordinator(archives: ArchiveSessionClient(engine: NativeSevenZipArchiveEngine()),
            grants: grants, presenter: presenter)
    }

    /// A ZIP holding `Readme.txt` and `Folder/Inner.txt`; `payloadSize` makes `Readme.txt`
    /// that many pseudo-random bytes instead.
    func zip(named name: String, payloadSize: Int? = nil) async throws -> URL {
        let source = input.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let folder = source.appendingPathComponent("Folder", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var generator = SystemRandomNumberGenerator()
        let readme = payloadSize.map { Data((0..<$0).map { _ in UInt8.random(in: 0...255, using: &generator) }) }
            ?? Data("readme".utf8)
        try readme.write(to: source.appendingPathComponent("Readme.txt"))
        try Data("inner".utf8).write(to: folder.appendingPathComponent("Inner.txt"))
        let archive = root.appendingPathComponent(name)
        try await NativeSevenZipArchiveEngine().createArchive(
            from: [source.appendingPathComponent("Readme.txt"), folder], outputURL: archive,
            options: CompressionOptions(format: .zip), password: nil, progress: { _ in })
        return archive
    }

    func encrypted7z(named name: String, password: String) async throws -> URL {
        let payload = input.appendingPathComponent("Secret.txt")
        try Data("secret".utf8).write(to: payload)
        var options = CompressionOptions(format: .sevenZip)
        options.requiresPassword = true
        options.encryptFileNames = true
        let archive = root.appendingPathComponent(name)
        try await NativeSevenZipArchiveEngine().createArchive(from: [payload], outputURL: archive, options: options,
            password: password, progress: { _ in })
        return archive
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: container)
    }
}

private extension AppDelegate {
    /// Runs the blocks already queued on the main queue, such as the opener's first flush.
    func drainMainQueue() async {
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
    }
}
