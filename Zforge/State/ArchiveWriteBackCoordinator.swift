import AppKit
import Foundation

/// What to do when the outer archive changed since the inner archive was opened.
enum ArchiveWriteBackConflictChoice: Sendable, Equatable {
    case replaceAnyway
    case saveInnerArchiveAs
    case discardChanges
}

/// What to do after a write-back failed or was cancelled. The modified copy is kept.
enum ArchiveWriteBackFailureChoice: Sendable, Equatable {
    case tryAgain
    case saveInnerArchiveAs
}

/// The interface of write-backs: progress while the outer archive is rebuilt and the
/// questions they can raise. Its window may already be closed, so it is app-level.
@MainActor
protocol ArchiveWriteBackPresenting: AnyObject {
    func showProgress(inner: String, outer: String, cancel: @escaping @MainActor () -> Void)
    func hideProgress()
    func resolveConflict(inner: String, outer: String) async -> ArchiveWriteBackConflictChoice
    func resolveFailure(inner: String, outer: String, error: any Error) async -> ArchiveWriteBackFailureChoice
    /// Where to save the inner archive instead; nil when the user cancels.
    func saveDestination(inner: String) async -> URL?
    /// The outer archive's password; nil when the user cancels.
    func password(outer: String, retry: Bool) async -> String?
}

/// Writes modified inner archives back into their outer archives when their last window
/// closes (D-73): one at a time, in the order the engine releases them, which is from
/// the innermost archive up. Quitting waits for it.
@MainActor
final class ArchiveWriteBackCoordinator {
    static let shared = ArchiveWriteBackCoordinator(engine: .shared, presenter: ArchiveWriteBackPanelPresenter())

    let engine: NativeSevenZipArchiveEngine
    private let presenter: any ArchiveWriteBackPresenting
    private var queue: [UUID] = []
    private var running: Task<Void, Never>?
    private var current: Task<Void, Error>?
    private var observer: NSObjectProtocol?
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    init(engine: NativeSevenZipArchiveEngine, presenter: any ArchiveWriteBackPresenting) {
        self.engine = engine
        self.presenter = presenter
    }

    /// Starts handling the engine's write-back requests.
    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NativeSevenZipArchiveEngine.innerArchiveNeedsWriteBack, object: engine, queue: .main
        ) { [weak self] notification in
            guard let sessionID = notification.userInfo?["sessionID"] as? UUID else { return }
            Task { @MainActor in self?.enqueue(sessionID) }
        }
    }

    var isIdle: Bool { queue.isEmpty && running == nil }

    func enqueue(_ sessionID: UUID) {
        guard !queue.contains(sessionID) else { return }
        queue.append(sessionID)
        guard running == nil else { return }
        running = Task { [weak self] in await self?.drain() }
    }

    /// Waits until every pending write-back, including ones released meanwhile, is done.
    func finishPendingWriteBacks() async {
        for sessionID in await engine.pendingWriteBacks() { enqueue(sessionID) }
        guard !isIdle else { return }
        await withCheckedContinuation { idleWaiters.append($0) }
    }

    private func drain() async {
        while !queue.isEmpty {
            let sessionID = queue.removeFirst()
            await process(sessionID)
            // Writing an archive back may release the next one up the chain.
            for pending in await engine.pendingWriteBacks() where !queue.contains(pending) && pending != sessionID {
                queue.append(pending)
            }
        }
        running = nil
        let waiters = idleWaiters
        idleWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    private func process(_ sessionID: UUID) async {
        guard let names = await engine.writeBackDescription(sessionID) else { return }
        var replacing = false
        var password: String?
        var askedForPassword = false
        while true {
            presenter.showProgress(inner: names.inner, outer: names.outer) { [weak self] in self?.current?.cancel() }
            let attempt = Task { [engine, replacing, password] in
                try await engine.writeBack(sessionID, password: password, replacingChangedOuter: replacing)
            }
            current = attempt
            let outcome = await attempt.result
            current = nil
            presenter.hideProgress()
            switch outcome {
            case .success:
                return
            case let .failure(error) where error as? ArchiveEngineError == .archiveChanged:
                switch await presenter.resolveConflict(inner: names.inner, outer: names.outer) {
                case .replaceAnyway: replacing = true
                case .saveInnerArchiveAs: if await saveInnerArchive(sessionID, inner: names.inner) { return }
                case .discardChanges:
                    await engine.discardInnerArchive(sessionID)
                    return
                }
            case let .failure(error) where [.passwordRequired, .invalidPassword].contains(error as? ArchiveEngineError):
                if let supplied = await presenter.password(outer: names.outer, retry: askedForPassword) {
                    password = supplied
                    askedForPassword = true
                    continue
                }
                if await resolveFailure(sessionID, names: names, error: ArchiveEngineError.cancelled) { return }
            case let .failure(error):
                let reported: any Error = error is CancellationError ? ArchiveEngineError.cancelled : error
                if await resolveFailure(sessionID, names: names, error: reported) { return }
            }
        }
    }

    /// True when the session ended (saved elsewhere); false to try again.
    private func resolveFailure(_ sessionID: UUID, names: (inner: String, outer: String), error: any Error) async -> Bool {
        while true {
            switch await presenter.resolveFailure(inner: names.inner, outer: names.outer, error: error) {
            case .tryAgain: return false
            case .saveInnerArchiveAs: if await saveInnerArchive(sessionID, inner: names.inner) { return true }
            }
        }
    }

    private func saveInnerArchive(_ sessionID: UUID, inner: String) async -> Bool {
        guard let destination = await presenter.saveDestination(inner: inner) else { return false }
        do {
            try await engine.saveInnerArchive(sessionID, to: destination)
            return true
        } catch {
            return false
        }
    }
}

/// App-level progress panel and alerts for write-backs.
@MainActor
final class ArchiveWriteBackPanelPresenter: ArchiveWriteBackPresenting {
    private var panel: NSPanel?
    private var label: NSTextField?
    private var indicator: NSProgressIndicator?
    private var cancelAction: (@MainActor () -> Void)?

    private var locale: Locale? { FileBrowserPreferences.shared.language.locale }

    func showProgress(inner: String, outer: String, cancel: @escaping @MainActor () -> Void) {
        cancelAction = cancel
        if panel == nil {
            let parts = Self.makePanel(locale: locale, target: self, action: #selector(cancelWriteBack))
            (panel, label, indicator) = (parts.panel, parts.label, parts.indicator)
        }
        label?.stringValue = Self.progressText(inner: inner, outer: outer, locale: locale)
        indicator?.startAnimation(nil)
        panel?.center()
        panel?.orderFront(nil)
    }

    func hideProgress() {
        indicator?.stopAnimation(nil)
        panel?.orderOut(nil)
        cancelAction = nil
    }

    static func progressText(inner: String, outer: String, locale: Locale?) -> String {
        AppLocalization.string("Writing “\(inner)” back into “\(outer)”…", locale: locale)
    }

    /// The utility panel: the sentence, an indeterminate bar and Cancel (Escape).
    static func makePanel(locale: Locale?, target: AnyObject?, action: Selector?)
        -> (panel: NSPanel, label: NSTextField, indicator: NSProgressIndicator) {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 112),
            styleMask: [.titled, .utilityWindow], backing: .buffered, defer: false)
        panel.title = AppLocalization.string("Saving Inner Archive", locale: locale)
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        let label = NSTextField(wrappingLabelWithString: "")
        let indicator = NSProgressIndicator()
        indicator.isIndeterminate = true
        indicator.style = .bar
        let cancel = NSButton(title: AppLocalization.string("Cancel", locale: locale), target: target, action: action)
        cancel.keyEquivalent = "\u{1b}"
        let content = NSView()
        for view in [label, indicator, cancel] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            indicator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            indicator.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            cancel.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 12),
            cancel.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            cancel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        panel.contentView = content
        return (panel, label, indicator)
    }

    @objc private func cancelWriteBack() {
        cancelAction?()
    }

    static func makeConflictAlert(inner: String, outer: String, locale: Locale?) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("“\(outer)” changed since “\(inner)” was opened from it.", locale: locale)
        alert.informativeText = AppLocalization.string(
            "Writing the inner archive back would replace those changes. You can save the inner archive separately or discard its changes.",
            locale: locale)
        alert.addButton(withTitle: AppLocalization.string("Replace Anyway", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Save Inner Archive As…", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Discard Changes", locale: locale))
        return alert
    }

    static func makeFailureAlert(inner: String, outer: String, error: any Error, locale: Locale?) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AppLocalization.string("“\(inner)” couldn’t be written back into “\(outer)”.", locale: locale)
        alert.informativeText = error.localizedDescription + "\n\n"
            + AppLocalization.string("The modified inner archive is kept.", locale: locale)
        alert.addButton(withTitle: AppLocalization.string("Try Again", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Save Inner Archive As…", locale: locale))
        return alert
    }

    static func makePasswordAlert(outer: String, retry: Bool, locale: Locale?) -> (alert: NSAlert, field: NSSecureTextField) {
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Archive Password", locale: locale)
        alert.informativeText = retry
            ? AppLocalization.string("Incorrect password. Try again.", locale: locale)
            : AppLocalization.string("Enter the password of “\(outer)” to write the inner archive back.", locale: locale)
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: AppLocalization.string("OK", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        alert.window.initialFirstResponder = field
        return (alert, field)
    }

    func resolveConflict(inner: String, outer: String) async -> ArchiveWriteBackConflictChoice {
        switch Self.makeConflictAlert(inner: inner, outer: outer, locale: locale).runModal() {
        case .alertFirstButtonReturn: return .replaceAnyway
        case .alertSecondButtonReturn: return .saveInnerArchiveAs
        default: return .discardChanges
        }
    }

    func resolveFailure(inner: String, outer: String, error: any Error) async -> ArchiveWriteBackFailureChoice {
        Self.makeFailureAlert(inner: inner, outer: outer, error: error, locale: locale).runModal() == .alertFirstButtonReturn
            ? .tryAgain : .saveInnerArchiveAs
    }

    func saveDestination(inner: String) async -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = inner
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    func password(outer: String, retry: Bool) async -> String? {
        let (alert, field) = Self.makePasswordAlert(outer: outer, retry: retry, locale: locale)
        guard alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty else { return nil }
        return field.stringValue
    }
}
