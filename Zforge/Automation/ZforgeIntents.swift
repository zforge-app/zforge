import AppIntents
import AppKit
import OSLog
import UniformTypeIdentifiers

nonisolated enum ZforgeIntentFormat: String, AppEnum {
    case zip, sevenZip
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Archive Format" }
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] { [.zip: "ZIP", .sevenZip: "7z"] }
    var format: ArchiveCompressionFormat { self == .zip ? .zip : .sevenZip }
}

nonisolated enum AutomationIntentRunner {
    static func path(_ file: IntentFile) throws -> String {
        guard let url = file.fileURL, url.isFileURL else { throw AutomationError.invalidArguments }
        return url.path
    }

    static func complete(_ job: AutomationOperation, operations: AutomationOperations = .shared) async throws -> AutomationOperation {
        let result = try await withTaskCancellationHandler {
            try await operations.wait(job.id)
        } onCancel: {
            Task { _ = try? await operations.cancel(job.id) }
        }
        try Task.checkCancellation()
        guard result.state == .succeeded else {
            if result.state == .cancelled { throw CancellationError() }
            throw AutomationIntentFailure()
        }
        return result
    }
}

nonisolated struct AutomationIntentFailure: LocalizedError {
    var errorDescription: String? { AppLocalization.string("The automation operation failed. Check the path, permissions and archive password.") }
}

extension AppIntent {
    fileprivate func continueForFolderPermission() async throws {
        let logger = Logger(subsystem: "io.libor.Zforge", category: "Automation")
        guard systemContext.currentMode != .foreground else {
            logger.info("Folder permission request is already in the foreground.")
            return
        }
        guard systemContext.currentMode.canContinueInForeground else { throw AutomationError.authorizationRequired }
        logger.info("Folder permission request is awaiting foreground continuation.")
        try await continueInForeground("Zforge needs your permission to access a folder.", alwaysConfirm: false)
        logger.info("Folder permission foreground continuation completed.")
    }
}

struct CompressZforgeFilesIntent: AppIntent {
    static var title: LocalizedStringResource { "Compress Files" }
    static var description: IntentDescription { "Create a new ZIP or 7z archive. Authorize source and destination folders when requested." }
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared

    @Parameter(title: "Files") var files: [IntentFile]
    @Parameter(title: "Destination Folder", supportedContentTypes: [.folder]) var destinationFolder: IntentFile
    @Parameter(title: "Archive Name") var archiveName: String
    @Parameter(title: "Archive Format", default: .zip) var format: ZforgeIntentFormat
    static var parameterSummary: some ParameterSummary {
        Summary("Compress \(\.$files) as \(\.$archiveName) in \(\.$destinationFolder)") { \.$format }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let destination = try AutomationPath.newChild(in: URL(fileURLWithPath: AutomationIntentRunner.path(destinationFolder)), name: archiveName)
        let urls = try files.map { try AutomationPath.url(AutomationIntentRunner.path($0)) } + [destination]
        guard (1...256).contains(files.count) else { throw AutomationError.invalidArguments }
        let permission = try await permissions.authorize(urls) {
            try await self.continueForFolderPermission()
        }
        defer { withExtendedLifetime(permission) {} }
        let job = try await AutomationOperations.shared.compress(sources: files.map(AutomationIntentRunner.path), destination: destination.path, format: format.format)
        _ = try await AutomationIntentRunner.complete(job)
        return .result(value: IntentFile(fileURL: destination))
    }
}

struct ExtractZforgeArchiveIntent: AppIntent {
    static var title: LocalizedStringResource { "Extract Archive" }
    static var description: IntentDescription { "Extract an archive into a new folder. Authorize source and destination folders when requested." }
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared

    @Parameter(title: "Archive") var archive: IntentFile
    @Parameter(title: "Destination Folder", supportedContentTypes: [.folder]) var destinationFolder: IntentFile
    @Parameter(title: "New Folder Name") var folderName: String
    @Parameter(title: "Password") var password: String?
    static var parameterSummary: some ParameterSummary {
        Summary("Extract \(\.$archive) to \(\.$folderName) in \(\.$destinationFolder)") { \.$password }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let destination = try AutomationPath.newChild(in: URL(fileURLWithPath: AutomationIntentRunner.path(destinationFolder)), name: folderName)
        let permission = try await permissions.authorize([AutomationPath.url(AutomationIntentRunner.path(archive)), destination]) {
            try await self.continueForFolderPermission()
        }
        defer { withExtendedLifetime(permission) {} }
        let job = try await AutomationOperations.shared.extract(archive: AutomationIntentRunner.path(archive), destination: destination.path, password: password)
        _ = try await AutomationIntentRunner.complete(job)
        return .result(value: IntentFile(fileURL: destination, type: .folder))
    }
}

struct TestZforgeArchiveIntent: AppIntent {
    static var title: LocalizedStringResource { "Test Archive Integrity" }
    static var description: IntentDescription { "Check an archive for errors using Zforge's native 7-Zip engine." }
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared
    @Parameter(title: "Archive") var archive: IntentFile
    @Parameter(title: "Password") var password: String?
    static var parameterSummary: some ParameterSummary { Summary("Test \(\.$archive)") { \.$password } }

    func perform() async throws -> some IntentResult {
        let permission = try await permissions.authorize([AutomationPath.url(AutomationIntentRunner.path(archive))]) {
            try await self.continueForFolderPermission()
        }
        defer { withExtendedLifetime(permission) {} }
        let job = try await AutomationOperations.shared.test(archive: AutomationIntentRunner.path(archive), password: password)
        _ = try await AutomationIntentRunner.complete(job)
        return .result()
    }
}

struct OpenZforgeArchiveIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Archive in Zforge" }
    static var description: IntentDescription { "Open an authorized archive in a Zforge browser window." }
    static var supportedModes: IntentModes { .foreground }
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared
    @Parameter(title: "Archive") var archive: IntentFile
    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$archive) in Zforge") }

    @MainActor func perform() async throws -> some IntentResult {
        let url = try AutomationPath.url(AutomationIntentRunner.path(archive))
        let lease = try await permissions.authorize([url], foreground: {})
        defer { withExtendedLifetime(lease) {} }
        guard ArchiveFormatRegistry.recognizes(url.lastPathComponent), FileManager.default.fileExists(atPath: url.path) else {
            throw AutomationError.invalidArguments
        }
        try await AutomationArchiveOpening.open(url, lease: lease)
        return .result()
    }
}

/// Retained for saved shortcuts whose target uses the original path entity.
/// New discovery uses the file-schema action below.
@available(macOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenZforgeContentIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Archive" }
    static var description: IntentDescription { "Open an authorized Zforge archive by name or absolute path." }
    static var supportedModes: IntentModes { .foreground }
    static var isDiscoverable: Bool { false }
    @Parameter(title: "Archive") var target: ZforgeArchiveEntity
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared
    var opener: @MainActor @Sendable (URL, AutomationAccessLease) async throws -> Void = { url, lease in
        try await AutomationArchiveOpening.open(url, lease: lease)
    }
    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$target) in Zforge") }

    @MainActor func perform() async throws -> some IntentResult {
        try await AutomationArchiveOpening.openEntity(target, permissions: permissions, opener: opener)
        return .result()
    }
}

/// The file entity schema describes archive content to Siri; system.open
/// describes the opening action. Archive mutation has no matching public schema.
@available(macOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenZforgeFileContentIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Archive" }
    static var description: IntentDescription { "Open an authorized Zforge archive by name or absolute path." }
    static var supportedModes: IntentModes { .foreground }
    @Parameter(title: "Archive") var target: ZforgeFileArchiveEntity
    var permissions: any AutomationPermissionRequesting = ContextualAutomationAccess.shared
    var opener: @MainActor @Sendable (URL, AutomationAccessLease) async throws -> Void = { url, lease in
        try await AutomationArchiveOpening.open(url, lease: lease)
    }
    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$target) in Zforge") }

    @MainActor func perform() async throws -> some IntentResult {
        // Rehydrate the actual reference, rather than trusting a stale embedded
        // path. The shared action rechecks live consent and regular-file status.
        let url = try await ZforgeFileArchiveEntity.url(for: target.id)
        try await AutomationArchiveOpening.openEntity(ZforgeArchiveEntity(url: url), permissions: permissions, opener: opener)
        return .result()
    }
}

/// Spotlight needs an entity-based OpenIntent at the macOS 26 floor too.
/// macOS 27 replaces this action with the assistant system-open schema above.
@available(macOS, introduced: 26.0, obsoleted: 27.0)
struct OpenZforgeIndexedArchiveIntent: OpenIntent {
    static var title: LocalizedStringResource { "Open Archive" }
    static var description: IntentDescription { "Open an authorized Zforge archive by name or absolute path." }
    static var supportedModes: IntentModes { .foreground }
    @Parameter(title: "Archive") var target: ZforgeLegacyArchiveEntity
    static var parameterSummary: some ParameterSummary { Summary("Open \(\.$target) in Zforge") }
    @MainActor func perform() async throws -> some IntentResult {
        try await AutomationArchiveOpening.openEntity(target.archive, permissions: ContextualAutomationAccess.shared) { url, lease in
            try await AutomationArchiveOpening.open(url, lease: lease)
        }
        return .result()
    }
}

nonisolated enum AutomationArchiveOpening {
    @MainActor static func openEntity(_ entity: ZforgeArchiveEntity, permissions: any AutomationPermissionRequesting,
                                     opener: @MainActor @Sendable (URL, AutomationAccessLease) async throws -> Void) async throws {
        let url = try AutomationPath.url(entity.id)
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Entity archive open action invoked.")
        let lease = try await permissions.authorize([url], foreground: {})
        defer { withExtendedLifetime(lease) {} }
        guard ArchiveFormatRegistry.recognizes(url.lastPathComponent),
              try AutomationPath.resolvedForAccess(url).resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
            throw AutomationError.invalidArguments
        }
        try await opener(url, lease)
    }
    @MainActor static func open(_ url: URL, lease: AutomationAccessLease, delegate: AppDelegate? = AppDelegate.current) async throws {
        if let delegate {
            // Foreground intents already activate the app. Opening it again
            // through Launch Services creates an unrelated default window.
            delegate.receiveAutomationArchive(url, lease: lease)
            return
        }
        defer { withExtendedLifetime(lease) {} }
        let configuration = NSWorkspace.OpenConfiguration()
        _ = try await NSWorkspace.shared.open([url], withApplicationAt: Bundle.main.bundleURL, configuration: configuration)
    }
}
