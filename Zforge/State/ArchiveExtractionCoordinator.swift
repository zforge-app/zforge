import AppKit
import Foundation

/// The interface of an extraction that runs without a browser window (ZF-78): a progress
/// panel and the questions an extraction can raise. Everything is app-level.
@MainActor
protocol ArchiveExtractionPresenting: AnyObject, Sendable {
    func showProgress(archive: String, cancel: @escaping @MainActor () -> Void)
    /// The completed fraction, or nil while it is unknown.
    func updateProgress(_ fraction: Double?)
    func hideProgress()
    /// A folder chosen by the user to grant access to `folder` (it or a parent); nil when cancelled.
    func folderAccess(for folder: URL) async -> URL?
    /// The archive's password; nil when the user cancels.
    func password(archive: String, retry: Bool) async -> String?
    func resolveConflict(_ conflict: ArchiveConflict) async -> ArchiveConflictDecision
    func reportFailure(archive: String, error: any Error) async
}

/// Extracts archives opened from Finder into a folder named after each archive, next to
/// it, with no browser window: one archive at a time, showing only the progress. The
/// folder needs a grant, as in the browser; passwords and conflicts are asked in alerts.
@MainActor
final class ArchiveExtractionCoordinator {
    static let shared = ArchiveExtractionCoordinator(
        archives: ArchiveSessionClient(engine: .shared), grants: AccessGrantStore(),
        presenter: ArchiveExtractionPanelPresenter())

    private let archives: any ArchiveServing
    private let grants: any AccessGrantStoring
    private let presenter: any ArchiveExtractionPresenting
    private var queue: [URL] = []
    private var running: Task<Void, Never>?
    private var current: Task<Void, Error>?
    private var cancelsQueue = false
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    init(archives: any ArchiveServing, grants: any AccessGrantStoring, presenter: any ArchiveExtractionPresenting) {
        self.archives = archives
        self.grants = grants
        self.presenter = presenter
    }

    var isIdle: Bool { queue.isEmpty && running == nil }

    func extract(_ urls: [URL]) {
        queue.append(contentsOf: urls.map(\.standardizedFileURL).filter { !queue.contains($0) })
        guard running == nil, !queue.isEmpty else { return }
        cancelsQueue = false
        running = Task { [weak self] in await self?.drain() }
    }

    /// Cancels the running extraction and drops the waiting ones (quitting Zforge).
    func cancelAll() {
        cancelsQueue = true
        queue.removeAll()
        current?.cancel()
    }

    func waitUntilIdle() async {
        guard !isIdle else { return }
        await withCheckedContinuation { idleWaiters.append($0) }
    }

    private func drain() async {
        while !queue.isEmpty, !cancelsQueue {
            await process(queue.removeFirst())
        }
        await grants.stopAll()
        running = nil
        let waiters = idleWaiters
        idleWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    private func process(_ archive: URL) async {
        let name = archive.lastPathComponent
        let folder = archive.deletingLastPathComponent()
        guard await prepareAccess(to: folder, archive: name) else { return }
        let destination = folder.appendingPathComponent(
            ArchiveNaming.extractionDirectoryName(for: name, fallback: AppLocalization.string(
                "Archive", locale: FileBrowserPreferences.shared.language.locale)),
            isDirectory: true)
        // The engine creates the folder first; one left empty by a cancelled or failed
        // extraction is removed unless it was already there.
        let destinationExisted = FileManager.default.fileExists(atPath: destination.path)
        defer { if !destinationExisted { Self.removeIfEmpty(destination) } }
        var password: String?
        var askedForPassword = false
        while !cancelsQueue {
            let attempt = Task { [archives, presenter, password] in
                try await archives.extractArchive(
                    at: archive, to: destination, password: password,
                    resolveConflict: { conflict in await presenter.resolveConflict(conflict) },
                    progress: { progress in
                        Task { @MainActor in presenter.updateProgress(progress.fraction) }
                    })
            }
            current = attempt
            presenter.showProgress(archive: name) { [weak self] in self?.current?.cancel() }
            let outcome = await attempt.result
            current = nil
            presenter.hideProgress()
            switch outcome {
            case .success:
                return
            case let .failure(error) where [.passwordRequired, .invalidPassword].contains(error as? ArchiveEngineError):
                guard !cancelsQueue,
                      let supplied = await presenter.password(archive: name, retry: askedForPassword) else { return }
                password = supplied
                askedForPassword = true
            case let .failure(error):
                if error is CancellationError || error as? ArchiveEngineError == .cancelled || cancelsQueue { return }
                await presenter.reportFailure(archive: name, error: error)
                return
            }
        }
    }

    private static func removeIfEmpty(_ folder: URL) {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: folder.path), contents.isEmpty else { return }
        try? FileManager.default.removeItem(at: folder)
    }

    /// The archive's folder needs a grant, as when the browser shows it; without one the
    /// user chooses the folder (or a parent) in the same panel the browser uses.
    private func prepareAccess(to folder: URL, archive: String) async -> Bool {
        if await grants.hasGrant(for: folder), (try? await grants.activateGrant(for: folder)) != nil { return true }
        guard !cancelsQueue, let chosen = await presenter.folderAccess(for: folder) else { return false }
        do {
            try await grants.storeGrant(for: chosen)
            _ = try await grants.activateGrant(for: folder)
            return true
        } catch {
            await presenter.reportFailure(archive: archive, error: error)
            return false
        }
    }
}

/// The alert asking whether an extracted item replaces an existing one; shared by the
/// browser and windowless extraction.
@MainActor
enum ArchiveConflictAlert {
    static func make(_ conflict: ArchiveConflict, locale: Locale?) -> (alert: NSAlert, applyToAll: NSButton) {
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Replace existing item?", locale: locale)
        alert.informativeText = conflict.destinationURL.path
        alert.addButton(withTitle: AppLocalization.string("Replace", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Keep", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        let applyToAll = NSButton(
            checkboxWithTitle: AppLocalization.string("Apply this decision to all conflicts", locale: locale),
            target: nil, action: nil)
        alert.accessoryView = applyToAll
        return (alert, applyToAll)
    }

    static func decision(for response: NSApplication.ModalResponse, applyToAll: Bool) -> ArchiveConflictDecision {
        switch response {
        case .alertFirstButtonReturn: .replace(applyToAll: applyToAll)
        case .alertSecondButtonReturn: .keep(applyToAll: applyToAll)
        default: .cancel
        }
    }

    static func run(_ conflict: ArchiveConflict, locale: Locale?) -> ArchiveConflictDecision {
        let (alert, applyToAll) = make(conflict, locale: locale)
        let response = alert.runModal()
        return decision(for: response, applyToAll: applyToAll.state == .on)
    }
}

/// App-level progress panel and alerts for windowless extraction.
@MainActor
final class ArchiveExtractionPanelPresenter: ArchiveExtractionPresenting {
    private var panel: NSPanel?
    private var label: NSTextField?
    private var indicator: NSProgressIndicator?
    private var cancelAction: (@MainActor () -> Void)?

    private var locale: Locale? { FileBrowserPreferences.shared.language.locale }

    func showProgress(archive: String, cancel: @escaping @MainActor () -> Void) {
        cancelAction = cancel
        if panel == nil {
            let parts = ArchiveWriteBackPanelPresenter.makePanel(
                title: AppLocalization.string("Extracting Archive", locale: locale),
                locale: locale, target: self, action: #selector(cancelExtraction))
            (panel, label, indicator) = (parts.panel, parts.label, parts.indicator)
        }
        label?.stringValue = Self.progressText(archive: archive, locale: locale)
        updateProgress(nil)
        panel?.center()
        NSApp.activate()
        panel?.makeKeyAndOrderFront(nil)
    }

    func updateProgress(_ fraction: Double?) {
        guard let indicator else { return }
        Self.setProgress(fraction, on: indicator)
    }

    /// A known fraction fills the bar; an unknown one animates it.
    static func setProgress(_ fraction: Double?, on indicator: NSProgressIndicator) {
        if let fraction {
            indicator.stopAnimation(nil)
            indicator.isIndeterminate = false
            indicator.minValue = 0
            indicator.maxValue = 1
            indicator.doubleValue = min(max(fraction, 0), 1)
        } else {
            indicator.isIndeterminate = true
            indicator.startAnimation(nil)
        }
    }

    func hideProgress() {
        indicator?.stopAnimation(nil)
        panel?.orderOut(nil)
        cancelAction = nil
    }

    static func progressText(archive: String, locale: Locale?) -> String {
        AppLocalization.string("Extracting “\(archive)”…", locale: locale)
    }

    @objc private func cancelExtraction() {
        cancelAction?()
    }

    func folderAccess(for folder: URL) async -> URL? {
        let panel = UITestLaunchIsolation.openPanel()
        panel.title = AppLocalization.string("Allow Zforge to Access This Folder", locale: locale)
        panel.message = AppLocalization.string("Choose the requested folder or one of its parents.", locale: locale)
        panel.directoryURL = folder
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        NSApp.activate()
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func makePasswordAlert(archive: String, retry: Bool, locale: Locale?) -> (alert: NSAlert, field: NSSecureTextField) {
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Archive Password", locale: locale)
        alert.informativeText = retry
            ? AppLocalization.string("Incorrect password. Try again.", locale: locale)
            : AppLocalization.string("Enter the password of “\(archive)” to extract it.", locale: locale)
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = field
        alert.addButton(withTitle: AppLocalization.string("OK", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        alert.window.initialFirstResponder = field
        return (alert, field)
    }

    func password(archive: String, retry: Bool) async -> String? {
        let (alert, field) = Self.makePasswordAlert(archive: archive, retry: retry, locale: locale)
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty else { return nil }
        return field.stringValue
    }

    func resolveConflict(_ conflict: ArchiveConflict) async -> ArchiveConflictDecision {
        ArchiveConflictAlert.run(conflict, locale: locale)
    }

    static func makeFailureAlert(archive: String, error: any Error, locale: Locale?) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AppLocalization.string("“\(archive)” couldn’t be extracted.", locale: locale)
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: AppLocalization.string("OK", locale: locale))
        return alert
    }

    func reportFailure(archive: String, error: any Error) async {
        NSApp.activate()
        Self.makeFailureAlert(archive: archive, error: error, locale: locale).runModal()
    }
}
