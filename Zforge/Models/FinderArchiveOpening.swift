import AppKit
import Foundation

/// What opening an archive from Finder does when Zforge is the default app for the
/// archive's type (ZF-78): ask each time, open it in a browser window, or extract it
/// into a folder named after it, next to it, showing only the progress.
nonisolated enum FinderArchiveOpeningChoice: String, CaseIterable, Identifiable, Sendable {
    case ask
    case open
    case extract

    static let defaultsKey = "finder.archiveOpening"

    var id: String { rawValue }

    var titleKey: String.LocalizationValue {
        switch self {
        case .ask: "Ask Each Time"
        case .open: "Open in Zforge"
        case .extract: "Extract"
        }
    }
}

/// Where the archives in one request from Finder go. Zforge cannot tell a double click
/// from Open With or a drop on its Dock icon (Finder sends the same event), so the
/// choice applies only to archives whose type Zforge opens by default; the others are
/// opened, as the user picked Zforge for them explicitly.
nonisolated struct FinderArchiveRouting: Equatable, Sendable {
    var open: [URL] = []
    var extract: [URL] = []
    var ask: [URL] = []

    static func route(_ urls: [URL], choice: FinderArchiveOpeningChoice,
                      opensByDefault: (URL) -> Bool) -> FinderArchiveRouting {
        var routing = FinderArchiveRouting()
        for url in urls {
            guard opensByDefault(url) else {
                routing.open.append(url)
                continue
            }
            switch choice {
            case .ask: routing.ask.append(url)
            case .open: routing.open.append(url)
            case .extract: routing.extract.append(url)
            }
        }
        return routing
    }
}

/// The answer to the open-or-extract question; `remember` is the dialog's checkbox.
nonisolated struct FinderArchiveChoiceAnswer: Equatable, Sendable {
    let choice: FinderArchiveOpeningChoice
    let remember: Bool
}

@MainActor
enum FinderArchiveDefaultApplication {
    /// Whether macOS opens `url` with Zforge by default. Builds share the bundle
    /// identifier, so the identifier is compared rather than the app's location.
    static func opensWithZforge(_ url: URL, workspace: NSWorkspace = .shared,
                                bundleIdentifier: String? = Bundle.main.bundleIdentifier) -> Bool {
        guard let bundleIdentifier,
              let application = workspace.urlForApplication(toOpen: url) else { return false }
        return Bundle(url: application)?.bundleIdentifier == bundleIdentifier
    }
}

/// The question asked when an archive opened from Finder has no default action yet.
@MainActor
enum FinderArchiveChoiceAlert {
    /// Open (Return), Extract, Cancel (Escape) and “Don’t ask again”.
    static func make(archiveNames: [String], locale: Locale?) -> NSAlert {
        let alert = NSAlert()
        if archiveNames.count == 1, let name = archiveNames.first {
            alert.messageText = AppLocalization.string("Open or extract “\(name)”?", locale: locale)
        } else {
            alert.messageText = AppLocalization.string("Open or extract these archives?", locale: locale)
        }
        let explanation = AppLocalization.string(
            "Extract creates a folder named after the archive, next to it. You can change this choice in Settings ▸ General.",
            locale: locale)
        let formatter = ListFormatter()
        formatter.locale = locale ?? AppLocalization.currentLocale
        let names = archiveNames.count > 1 ? (formatter.string(from: archiveNames) ?? "") + "\n\n" : ""
        alert.informativeText = names + explanation
        alert.addButton(withTitle: AppLocalization.string("Open", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Extract", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = AppLocalization.string("Don’t ask again", locale: locale)
        return alert
    }

    /// The answer for a response of `make`'s alert; nil for Cancel.
    static func answer(for response: NSApplication.ModalResponse, suppressed: Bool) -> FinderArchiveChoiceAnswer? {
        switch response {
        case .alertFirstButtonReturn: FinderArchiveChoiceAnswer(choice: .open, remember: suppressed)
        case .alertSecondButtonReturn: FinderArchiveChoiceAnswer(choice: .extract, remember: suppressed)
        default: nil
        }
    }
}

/// What `AppDelegate` uses to handle archives sent by Finder; tests replace it.
@MainActor
struct FinderArchiveOpeningEnvironment {
    var preferences: FileBrowserPreferences
    var opensByDefault: @MainActor (URL) -> Bool
    /// Asks whether to open or extract the named archives; nil when cancelled.
    var ask: @MainActor ([String]) async -> FinderArchiveChoiceAnswer?
    var extract: @MainActor ([URL]) -> Void

    static var live: FinderArchiveOpeningEnvironment {
        FinderArchiveOpeningEnvironment(
            preferences: .shared,
            opensByDefault: { FinderArchiveDefaultApplication.opensWithZforge($0) },
            ask: { names in
                let alert = FinderArchiveChoiceAlert.make(
                    archiveNames: names, locale: FileBrowserPreferences.shared.language.locale)
                NSApp.activate()
                let response = alert.runModal()
                return FinderArchiveChoiceAlert.answer(
                    for: response, suppressed: alert.suppressionButton?.state == .on)
            },
            extract: { ArchiveExtractionCoordinator.shared.extract($0) })
    }
}
