import Foundation

nonisolated enum ArchiveEngineError: LocalizedError, Equatable {
    case helperUnavailable
    case passwordRequired
    case invalidPassword
    case invalidArchive(String)
    case commandFailed(code: Int32, message: String)
    case itemNotFound
    case unsafePath
    case insufficientSpace
    case sizeLimitExceeded
    case cancelled
    case updateUnsupported
    case multiVolumeUpdateUnsupported
    case archiveAsDestination
    case archiveChanged
    /// A read found the archive or one of its volumes changed since the session opened it.
    case archiveChangedSinceOpening
    case archiveIncludedInSources

    var errorDescription: String? {
        switch self {
        case .helperUnavailable: AppLocalization.string("archive.helper_unavailable")
        case .passwordRequired: AppLocalization.string("archive.password_required")
        case .invalidPassword: AppLocalization.string("archive.invalid_password")
        case let .invalidArchive(message): message
        case let .commandFailed(_, message): message
        case .itemNotFound: AppLocalization.string("archive.item_not_found")
        case .unsafePath: AppLocalization.string("archive.unsafe_path")
        case .insufficientSpace: AppLocalization.string("archive.insufficient_space")
        case .sizeLimitExceeded: AppLocalization.string("archive.size_limit")
        case .cancelled: AppLocalization.string("error.cancelled")
        case .updateUnsupported: AppLocalization.string("Only ZIP and 7z archives can be updated.")
        case .multiVolumeUpdateUnsupported: AppLocalization.string("Multi-volume archives cannot be updated.")
        case .archiveAsDestination: AppLocalization.string("The archive itself cannot be the extraction destination.")
        case .archiveChanged: AppLocalization.string("The archive changed since it was opened. Reopen it before removing items.")
        case .archiveChangedSinceOpening: AppLocalization.string("The archive changed since it was opened. Reopen it to continue.")
        case .archiveIncludedInSources: AppLocalization.string("The archive cannot be added to itself.")
        }
    }
}

nonisolated enum ArchiveMaterializationPurpose: Sendable, Equatable {
    case preview
    case openExternally
}

nonisolated enum ArchiveProgressPhase: Sendable, Equatable {
    case staging
    case compressing
    case extracting
}

nonisolated struct ArchiveProgress: Sendable, Equatable {
    let phase: ArchiveProgressPhase
    let fraction: Double?

    init(phase: ArchiveProgressPhase, fraction: Double? = nil) {
        self.phase = phase
        self.fraction = fraction
    }
}

typealias ArchiveProgressHandler = @Sendable (ArchiveProgress) -> Void

nonisolated struct ArchiveConflict: Sendable, Equatable {
    let path: String
    let destinationURL: URL
    let isDirectory: Bool
}

nonisolated enum ArchiveConflictDecision: Sendable, Equatable {
    case replace(applyToAll: Bool)
    case keep(applyToAll: Bool)
    case cancel
}

typealias ArchiveConflictResolver = @Sendable (ArchiveConflict) async -> ArchiveConflictDecision

nonisolated struct ArchiveOpenResult: Sendable {
    let address: ArchiveAddress
    let displayName: String
    /// Writes are refused: an archive opened from inside an archive that cannot be
    /// updated (RAR, compressed tar, ISO…, multi-volume), or a format that cannot be.
    var isReadOnly = false
    /// For an archive opened from inside another archive, the session it came from.
    var parentSessionID: UUID? = nil
    /// Increases each time the shared session's listing is replaced after a change.
    var revision = 0
}

nonisolated struct ArchiveReorganizationResult: Sendable {
    let paths: [String]
    let password: String?
}

nonisolated protocol ArchiveServing: Sendable {
    /// Opens, or joins, the shared session of the archive file (one per file identity).
    /// Each successful call holds one reference, released by `closeSession`.
    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult
    func items(at address: ArchiveAddress) async throws -> [BrowserItem]
    /// Materializes an archive stored inside an archive into its own writable copy and
    /// opens, or joins, its shared session (one per outer session and internal path).
    func openInnerArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult
    /// The current state of a session this caller holds, after a change written through it.
    func reopenSession(_ sessionID: UUID, at url: URL, password: String?) async throws -> ArchiveOpenResult
    func materialize(
        item: BrowserItem,
        purpose: ArchiveMaterializationPurpose,
        automaticLimit: Int64?
    ) async throws -> URL
    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws
    func addItems(
        from sourceURLs: [URL],
        to archiveURL: URL,
        internalPath: String,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws
    func exportItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws
    func exportPromisedItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws
    @discardableResult
    func removeItems(_ items: [BrowserItem], password: String?, progress: @escaping ArchiveProgressHandler) async throws -> String?
    func reorganizeItems(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool,
                         password: String?, resolveConflict: @escaping ArchiveConflictResolver,
                         progress: @escaping ArchiveProgressHandler) async throws -> ArchiveReorganizationResult
    func extractArchive(
        at url: URL,
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws
    func testArchive(at url: URL, password: String?) async throws
    func extractItems(
        _ items: [BrowserItem],
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws
    func recursiveSize(of item: BrowserItem) async throws -> Int64
    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String]
    func archiveRootURL(for address: ArchiveAddress) async throws -> URL
    /// The archive on disk that contains this one, through every inner archive.
    func outermostArchiveURL(for address: ArchiveAddress) async throws -> URL
    /// Change notifications of shared sessions are posted with this object (nil: none).
    nonisolated var sessionChangeSource: AnyObject? { get }
    /// Moves a held session reference to the window that adopts it.
    func relinquishSession(_ sessionID: UUID) async
    func adoptSession(_ sessionID: UUID) async
    func setPassword(_ password: String?, for sessionID: UUID) async
    func closeSession(_ sessionID: UUID) async
    func closeAllSessions() async
    func cancelAllOperations() async
    func cleanupStaleSessions() async
}

extension ArchiveServing {
    func exportPromisedItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        try await exportItem(item, to: url, password: password, progress: progress)
    }
    func exportItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        throw ArchiveEngineError.updateUnsupported
    }
    @discardableResult
    func removeItems(_ items: [BrowserItem], password: String?, progress: @escaping ArchiveProgressHandler) async throws -> String? {
        throw ArchiveEngineError.updateUnsupported
    }

    func reorganizeItems(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool,
                         password: String?, resolveConflict: @escaping ArchiveConflictResolver,
                         progress: @escaping ArchiveProgressHandler) async throws -> ArchiveReorganizationResult {
        throw ArchiveEngineError.updateUnsupported
    }

    func addItems(
        from sourceURLs: [URL],
        to archiveURL: URL,
        internalPath: String,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        throw ArchiveEngineError.updateUnsupported
    }

    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        format: ArchiveCompressionFormat,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        try await createArchive(
            from: sourceURLs, outputURL: outputURL,
            options: CompressionOptions(format: format), password: nil, progress: progress
        )
    }

    func testArchive(at url: URL, password: String?) async throws {
        throw ArchiveEngineError.helperUnavailable
    }

    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String] {
        [try await archiveRootURL(for: address).lastPathComponent]
    }

    func openInnerArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        throw ArchiveEngineError.updateUnsupported
    }

    func reopenSession(_ sessionID: UUID, at url: URL, password: String?) async throws -> ArchiveOpenResult {
        await closeSession(sessionID)
        return try await openArchive(at: url, password: password)
    }

    func outermostArchiveURL(for address: ArchiveAddress) async throws -> URL {
        try await archiveRootURL(for: address)
    }

    /// Change notifications of shared sessions are posted with this object (nil: none).
    nonisolated var sessionChangeSource: AnyObject? { nil }
    /// Moves a held session reference to a window that adopts it (no-op without tracking).
    func relinquishSession(_ sessionID: UUID) async {}
    func adoptSession(_ sessionID: UUID) async {}
}

/// Identity and version of the files a session reads in place: the archive and its volumes.
/// Compared before reads and writes instead of the archive's bytes (D-73).
nonisolated struct ArchiveSourceFingerprint: Sendable, Equatable {
    struct File: Sendable, Equatable {
        let volumeIdentifier: UInt64
        let fileIdentifier: UInt64
        let size: Int64
        let modifiedSeconds: Int
        let modifiedNanoseconds: Int
    }

    let files: [File]

    /// Throws when a file cannot be examined (removed, unmounted or inaccessible).
    static func capture(_ urls: [URL]) throws -> Self {
        Self(files: try urls.map { url in
            var status = stat()
            guard stat(url.path, &status) == 0 else { throw ArchiveEngineError.itemNotFound }
            return File(volumeIdentifier: UInt64(UInt32(bitPattern: status.st_dev)),
                fileIdentifier: UInt64(status.st_ino), size: Int64(status.st_size),
                modifiedSeconds: Int(status.st_mtimespec.tv_sec), modifiedNanoseconds: Int(status.st_mtimespec.tv_nsec))
        })
    }

    /// Whether the files still have this identity and version.
    func matches(_ urls: [URL]) -> Bool { (try? Self.capture(urls)) == self }
}

actor NativeSevenZipArchiveEngine: ArchiveServing {
    private typealias Entry = ArchiveEntry

    /// The engine every browser window shares, so that windows showing the same archive
    /// share one session (D-73).
    static let shared = NativeSevenZipArchiveEngine()

    /// Posted (object: the engine) after a session's listing is replaced in place. User
    /// info: `sessionID` (UUID) and `revision` (Int).
    nonisolated static let sessionDidChange = Notification.Name("ZforgeArchiveSessionDidChange")
    /// Posted (object: the engine) when the last reference to a modified inner archive is
    /// released: its outer archive must be rebuilt (`writeBack`), or the changes saved or
    /// discarded. User info: `sessionID` (UUID).
    nonisolated static let innerArchiveNeedsWriteBack = Notification.Name("ZforgeInnerArchiveNeedsWriteBack")

    private struct ArchiveRecord: Sendable {
        let id: UUID
        /// Read in place: the authorized original for a root archive, the session's own
        /// writable copy for an archive opened from inside another one.
        let fileURL: URL
        /// The archive and its related volumes, covered by `fingerprint`.
        let sources: [URL]
        let fingerprint: ArchiveSourceFingerprint
        /// Identity of `fileURL` itself, which identifies the shared session.
        let identity: ArchiveSourceFingerprint.File
        let displayName: String
        let entries: [String: Entry]
        /// Parent path to child entry paths, built once (`ArchiveEntry.childIndex`).
        let children: [String: [String]]
        let directoriesContainingFiles: Set<String>
        let isRawStream: Bool
        /// Compressed tar read sequentially: reads stop after the last selected entry.
        let isSequential: Bool
        /// Listing needed the password (encrypted names): joining the session needs it too.
        let listingNeedsPassword: Bool
    }

    /// Where an inner archive comes from: its outer session and its path there.
    private struct InnerOrigin: Sendable, Hashable {
        let sessionID: UUID
        let internalPath: String
    }

    private struct Session: Sendable {
        let id: UUID
        let originalURL: URL
        /// Holds materialized items (and an inner archive's own copy); created on demand.
        let directoryURL: URL
        var password: String?
        var archive: ArchiveRecord
        var materialized: [String: URL]
        /// Windows and inner sessions holding the session; it closes at zero.
        var references = 1
        var revision = 0
        let origin: InnerOrigin?
        let isReadOnly: Bool
        /// An inner archive written since it was opened, to be written back into its outer one.
        var isModified = false
        var awaitingWriteBack = false
        /// Native reads of this session are registered under this URL so closing it cancels them.
        var readScope: URL { directoryURL.appendingPathComponent("Reads", isDirectory: true) }
        var archives: [UUID: ArchiveRecord] { [archive.id: archive] }

        func result() -> ArchiveOpenResult {
            ArchiveOpenResult(
                address: ArchiveAddress(sessionID: id, archiveID: archive.id, internalPath: ""),
                displayName: archive.displayName, isReadOnly: isReadOnly,
                parentSessionID: origin?.sessionID, revision: revision
            )
        }
    }

    private let fileManager: FileManager
    private let nativeBackend: NativeSevenZipBackend
    private let sessionsRoot: URL
    private let materializationDidExtract: (@Sendable (BrowserItem) async -> Void)?
    private var sessions: [UUID: Session] = [:]

    init(
        fileManager: FileManager = .default,
        sourceReadMeter: ArchiveSourceReadMeter? = nil,
        materializationDidExtract: (@Sendable (BrowserItem) async -> Void)? = nil
    ) {
        self.fileManager = fileManager
        self.nativeBackend = NativeSevenZipBackend(readMeter: sourceReadMeter)
        self.materializationDidExtract = materializationDidExtract
        sessionsRoot = ZforgeTemporaryStorage.archiveSessionsRoot(fileManager: fileManager)
    }

    nonisolated var sessionChangeSource: AnyObject? { self }

    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult {
        if let existing = try await joinSession(forFileAt: url, password: password) { return existing }
        let sessionID = UUID()
        let sessionDirectory = sessionsRoot.appendingPathComponent(sessionID.uuidString, isDirectory: true)
        // The authorized original and its volumes are listed in place; nothing is copied.
        let archive = try await listArchive(
            at: url,
            sources: relatedVolumeURLs(for: url),
            displayName: url.lastPathComponent,
            password: password,
            cancellationScope: sessionDirectory.appendingPathComponent("Reads", isDirectory: true)
        )
        // Another opening of the same file may have finished while this one listed.
        if let existing = try await joinSession(forFileAt: url, password: password) { return existing }
        let session = Session(
            id: sessionID, originalURL: url, directoryURL: sessionDirectory, password: password,
            archive: archive, materialized: [:], origin: nil,
            isReadOnly: !isUpdatableArchiveFile(url)
        )
        sessions[sessionID] = session
        return session.result()
    }

    /// Joins the open session of this file (same volume and file identifier), if any.
    private func joinSession(forFileAt url: URL, password: String?) async throws -> ArchiveOpenResult? {
        guard let identity = try? ArchiveSourceFingerprint.capture([url]).files.first,
              let existing = sessions.values.first(where: {
                  $0.origin == nil && !$0.awaitingWriteBack && $0.archive.identity == identity
              }) else { return nil }
        let id = existing.id
        // Encrypted names stay protected: joining needs the password the listing needed.
        if existing.archive.listingNeedsPassword {
            guard let password else { throw ArchiveEngineError.passwordRequired }
            guard password == existing.password else { throw ArchiveEngineError.invalidPassword }
        }
        sessions[id]?.references += 1
        if let password { sessions[id]?.password = password }
        do {
            try await relistIfChanged(id)
        } catch {
            await closeSession(id)
            throw error
        }
        return sessions[id]?.result()
    }

    func openInnerArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        guard item.opensAsInnerArchive, case let .archive(address) = item.location,
              let outer = sessions[address.sessionID], outer.archive.id == address.archiveID,
              let entry = outer.archive.entries[address.internalPath], !entry.isDirectory else {
            throw ArchiveEngineError.itemNotFound
        }
        let origin = InnerOrigin(sessionID: address.sessionID, internalPath: address.internalPath)
        if let existing = try joinInnerSession(origin, password: password) { return existing }
        try ensureUnchanged(outer.archive)

        let sessionID = UUID()
        let sessionDirectory = sessionsRoot.appendingPathComponent(sessionID.uuidString, isDirectory: true)
        // The inner archive's own writable copy belongs to its session, not to the outer window.
        let copyDirectory = sessionDirectory.appendingPathComponent("Archive", isDirectory: true)
        let copy = copyDirectory.appendingPathComponent(sanitizedFileName(item.name))
        let expectedSize = entry.size
        let hardLimit: Int64 = if let expectedSize {
            expectedSize > Int64.max - 1_048_576 ? Int64.max : expectedSize + 1_048_576
        } else {
            1_073_741_824
        }
        do {
            try fileManager.createDirectory(at: copyDirectory, withIntermediateDirectories: true)
            try ensureAvailableSpace(for: expectedSize ?? hardLimit, at: copyDirectory)
            let paths = outer.archive.isRawStream ? [] : [address.internalPath]
            // An encrypted outer archive may not have a known password yet: the one given now
            // unlocks it (and is kept in its session) as well as the inner archive.
            let outerPassword = outer.password ?? password
            try await nativeBackend.extract(at: outer.archive.fileURL, password: outerPassword,
                paths: paths, destination: copyDirectory, outputFile: copy, byteLimit: UInt64(hardLimit),
                lastIndex: lastNativeIndex(in: outer.archive, selecting: paths), cancellationScope: outer.readScope)
            try ensureUnchanged(outer.archive)
            if outer.password == nil, let outerPassword { sessions[origin.sessionID]?.password = outerPassword }
            // Writable whatever the stored permissions: it is edited and written back.
            let permissions = ((try fileManager.attributesOfItem(atPath: copy.path)[.posixPermissions]) as? NSNumber)?.intValue ?? 0
            try fileManager.setAttributes([.posixPermissions: permissions | 0o600], ofItemAtPath: copy.path)
            let archive = try await listArchive(
                at: copy, sources: [copy],
                displayName: outer.archive.displayName + " › " + item.name,
                password: password,
                cancellationScope: sessionDirectory.appendingPathComponent("Reads", isDirectory: true)
            )
            if let existing = try joinInnerSession(origin, password: password) {
                try? fileManager.removeItem(at: sessionDirectory)
                return existing
            }
            guard sessions[origin.sessionID] != nil else { throw ArchiveEngineError.cancelled }
            // The inner session keeps its outer session open until it is written back.
            sessions[origin.sessionID]?.references += 1
            let parentReadOnly = sessions[origin.sessionID]?.isReadOnly ?? true
            let session = Session(
                id: sessionID, originalURL: copy, directoryURL: sessionDirectory, password: password,
                archive: archive, materialized: [:], origin: origin,
                isReadOnly: parentReadOnly || !ArchiveFormatRegistry.supportsUpdating(item.name)
            )
            sessions[sessionID] = session
            return session.result()
        } catch {
            try? fileManager.removeItem(at: sessionDirectory)
            throw error
        }
    }

    private func joinInnerSession(_ origin: InnerOrigin, password: String?) throws -> ArchiveOpenResult? {
        guard let existing = sessions.values.first(where: { $0.origin == origin && !$0.awaitingWriteBack }) else {
            return nil
        }
        let id = existing.id
        if existing.archive.listingNeedsPassword {
            guard let password else { throw ArchiveEngineError.passwordRequired }
            guard password == existing.password else { throw ArchiveEngineError.invalidPassword }
        }
        sessions[id]?.references += 1
        if let password { sessions[id]?.password = password }
        return sessions[id]?.result()
    }

    func reopenSession(_ sessionID: UUID, at url: URL, password: String?) async throws -> ArchiveOpenResult {
        guard sessions[sessionID] != nil else { return try await openArchive(at: url, password: password) }
        if let password { sessions[sessionID]?.password = password }
        try await relistIfChanged(sessionID)
        guard let session = sessions[sessionID] else { throw ArchiveEngineError.itemNotFound }
        return session.result()
    }

    /// Adds a reference to an open session (a window attaching to it).
    func retainSession(_ sessionID: UUID) throws {
        guard sessions[sessionID] != nil else { throw ArchiveEngineError.itemNotFound }
        sessions[sessionID]?.references += 1
    }

    /// Whether the archive file can be rewritten: a single-volume ZIP or 7z.
    private func isUpdatableArchiveFile(_ url: URL) -> Bool {
        guard ArchiveFormatRegistry.supportsUpdating(url.lastPathComponent) else { return false }
        return (try? rejectMultiVolumeZip(url.standardizedFileURL.resolvingSymlinksInPath())) != nil
    }

    /// Replaces the session's listing with the archive's current one, keeping its session
    /// and archive identifiers so every window's addresses stay valid, and tells them.
    private func relist(_ sessionID: UUID, markingModified: Bool) async throws {
        guard let session = sessions[sessionID] else { return }
        let old = session.archive
        let archive = try await listArchive(
            at: old.fileURL, sources: old.sources, displayName: old.displayName,
            password: session.password, archiveID: old.id, cancellationScope: session.readScope
        )
        guard var current = sessions[sessionID] else { return }
        current.archive = archive
        current.materialized = [:]
        current.revision += 1
        if markingModified && current.origin != nil { current.isModified = true }
        sessions[sessionID] = current
        NotificationCenter.default.post(name: Self.sessionDidChange, object: self,
            userInfo: ["sessionID": sessionID, "revision": current.revision])
    }

    private func relistIfChanged(_ sessionID: UUID) async throws {
        guard let session = sessions[sessionID], !session.archive.fingerprint.matches(session.archive.sources) else { return }
        try await relist(sessionID, markingModified: false)
    }

    func items(at address: ArchiveAddress) throws -> [BrowserItem] {
        guard let session = sessions[address.sessionID],
              let archive = session.archives[address.archiveID] else {
            throw ArchiveEngineError.invalidArchive(AppLocalization.string("archive.session_closed"))
        }

        let parent = normalized(address.internalPath)
        return (archive.children[parent] ?? []).compactMap { path in
            guard let entry = archive.entries[path] else { return nil }
            let childName = path.lastIndex(of: "/").map { String(path[path.index(after: $0)...]) } ?? path
            let childPath = parent.isEmpty ? childName : "\(parent)/\(childName)"
            let childAddress = ArchiveAddress(sessionID: address.sessionID, archiveID: address.archiveID, internalPath: childPath)
            let isArchive = !entry.isDirectory && ArchiveFormatRegistry.recognizes(childName)
            var item = BrowserItem(
                id: BrowserItemID(rawValue: "archive:\(address.sessionID):\(address.archiveID):\(childPath)"),
                name: childName,
                location: .archive(childAddress),
                isContainer: entry.isDirectory,
                isDirectory: entry.isDirectory,
                isPackage: false,
                isSymbolicLink: entry.attributes?.contains("l") == true,
                isHidden: childName.hasPrefix("."),
                isArchive: isArchive,
                size: entry.size,
                packedSize: entry.packedSize,
                creationDate: entry.created,
                modificationDate: entry.modified,
                accessDate: entry.accessed,
                tags: [],
                contentTypeIdentifier: nil,
                encrypted: entry.encrypted,
                checksum: entry.checksum,
                compressionMethod: entry.method,
                archiveDirectoryContainsFiles: entry.isDirectory && archive.directoriesContainingFiles.contains(childPath)
            )
            item.solidBlock = entry.solidBlock
            return item
        }
    }

    func recursiveSize(of item: BrowserItem) throws -> Int64 {
        guard case let .archive(address) = item.location,
              let session = sessions[address.sessionID],
              let archive = session.archives[address.archiveID] else {
            throw ArchiveEngineError.itemNotFound
        }

        let path = normalized(address.internalPath)
        let prefix = path.isEmpty ? "" : "\(path)/"
        return archive.entries.values.reduce(into: Int64(0)) { total, entry in
            guard !entry.isDirectory, entry.path.hasPrefix(prefix) else { return }
            total += entry.size ?? 0
        }
    }

    func materialize(
        item: BrowserItem,
        purpose: ArchiveMaterializationPurpose,
        automaticLimit: Int64?
    ) async throws -> URL {
        guard case let .archive(address) = item.location,
              let session = sessions[address.sessionID],
              let archive = session.archives[address.archiveID] else {
            throw ArchiveEngineError.itemNotFound
        }
        guard !item.isDirectory else { throw ArchiveEngineError.itemNotFound }

        if let automaticLimit, let size = item.size, size > automaticLimit {
            throw BrowserError.previewTooLarge(size)
        }

        let cacheKey = "\(address.archiveID):\(address.internalPath):\(purpose)"
        if let existing = session.materialized[cacheKey], fileManager.fileExists(atPath: existing.path) {
            return existing
        }
        try ensureUnchanged(archive)

        let expectedSize = item.size
        let hardLimit: Int64 = if let expectedSize {
            expectedSize > Int64.max - 1_048_576 ? Int64.max : expectedSize + 1_048_576
        } else {
            1_073_741_824
        }

        // The session directory holds only materialized items; it exists from the first one.
        let purposeDirectory = session.directoryURL
            .appendingPathComponent(purposeDirectoryName(purpose), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: purposeDirectory, withIntermediateDirectories: true)
        do {
            try ensureAvailableSpace(for: expectedSize ?? hardLimit, at: purposeDirectory)
        } catch {
            try? fileManager.removeItem(at: purposeDirectory)
            throw error
        }
        let safeName = sanitizedFileName(item.name)
        let outputURL = purposeDirectory.appendingPathComponent(safeName)
        let paths = archive.isRawStream ? [] : [address.internalPath]

        do {
            try await nativeBackend.extract(at: archive.fileURL, password: session.password,
                paths: paths, destination: purposeDirectory,
                outputFile: outputURL, byteLimit: UInt64(hardLimit),
                lastIndex: lastNativeIndex(in: archive, selecting: paths), cancellationScope: session.readScope)
            // Output read while the original changed is discarded, never published.
            try ensureUnchanged(archive)
        } catch {
            try? fileManager.removeItem(at: purposeDirectory)
            throw error
        }

        guard !Task.isCancelled, sessions[address.sessionID]?.archives[address.archiveID] != nil else {
            try? fileManager.removeItem(at: purposeDirectory)
            throw ArchiveEngineError.cancelled
        }

        let attributes = try fileManager.attributesOfItem(atPath: outputURL.path)
        if let written = (attributes[.size] as? NSNumber)?.int64Value, written > hardLimit {
            try? fileManager.removeItem(at: outputURL)
            throw ArchiveEngineError.sizeLimitExceeded
        }

        if purpose == .openExternally {
            try? fileManager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: outputURL.path)
            var outermost = session
            while let origin = outermost.origin, let outer = sessions[origin.sessionID] { outermost = outer }
            propagateQuarantine(from: outermost.originalURL, to: outputURL)
        }

        // A supplied checkpoint lets integration tests coordinate completed native extractions.
        if let materializationDidExtract { await materializationDidExtract(item) }

        // Extraction suspends this actor. Merge into the live session so another
        // materialization or nested archive cannot be overwritten by its snapshot.
        guard !Task.isCancelled,
              var currentSession = sessions[address.sessionID],
              currentSession.archives[address.archiveID] != nil else {
            try? fileManager.removeItem(at: purposeDirectory)
            throw ArchiveEngineError.cancelled
        }
        currentSession.materialized[cacheKey] = outputURL
        sessions[address.sessionID] = currentSession
        return outputURL
    }

    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        guard !sourceURLs.isEmpty else { throw ArchiveEngineError.itemNotFound }
        let options = options.normalized()
        let format = options.format
        _ = try options.nativeProperties(password: password)

        let operationDirectory = sessionsRoot
            .appendingPathComponent("Operations", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let inputDirectory = operationDirectory.appendingPathComponent("Input", isDirectory: true)
        try fileManager.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: operationDirectory) }

        progress(ArchiveProgress(phase: .staging, fraction: 0))
        var stagedNames: [String] = []
        for (index, sourceURL) in sourceURLs.enumerated() {
            let baseName = sourceURL.lastPathComponent.isEmpty ? "Item (index + 1)" : sourceURL.lastPathComponent
            let stagedName = uniqueStagedName(baseName, in: stagedNames)
            try fileManager.copyItem(
                at: sourceURL,
                to: inputDirectory.appendingPathComponent(stagedName)
            )
            stagedNames.append(stagedName)
            progress(ArchiveProgress(
                phase: .staging,
                fraction: Double(index + 1) / Double(sourceURLs.count)
            ))
        }

        let stagedOutput = operationDirectory.appendingPathComponent(outputURL.lastPathComponent)
        if format.isStream && (sourceURLs.count != 1 || isDirectory(at: sourceURLs[0])) {
            let tarURL = operationDirectory.appendingPathComponent("Payload.tar")
            try await runCreate(
                outputURL: tarURL,
                options: CompressionOptions(format: .tar),
                password: nil,
                sourceNames: stagedNames,
                workingDirectory: inputDirectory
            )
            progress(ArchiveProgress(phase: .compressing, fraction: 0.5))
            try await runCreate(
                outputURL: stagedOutput,
                options: options,
                password: password,
                sourceNames: [tarURL.lastPathComponent],
                workingDirectory: operationDirectory
            )
        } else {
            try await runCreate(
                outputURL: stagedOutput,
                options: options,
                password: password,
                sourceNames: stagedNames,
                workingDirectory: inputDirectory
            )
        }

        try Task.checkCancellation()
        progress(ArchiveProgress(phase: .compressing, fraction: 1))
        try fileManager.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: stagedOutput, to: outputURL)
    }

    func addItems(
        from sourceURLs: [URL],
        to archiveURL: URL,
        internalPath: String,
        password: String?,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        guard !sourceURLs.isEmpty else { throw ArchiveEngineError.itemNotFound }
        guard ArchiveFormatRegistry.supportsUpdating(archiveURL.lastPathComponent) else {
            throw ArchiveEngineError.updateUnsupported
        }
        let archive = archiveURL.standardizedFileURL.resolvingSymlinksInPath()
        guard ArchiveFormatRegistry.supportsUpdating(archive.lastPathComponent) else {
            throw ArchiveEngineError.updateUnsupported
        }
        try rejectMultiVolumeZip(archive)
        guard fileManager.fileExists(atPath: archive.path) else { throw ArchiveEngineError.itemNotFound }
        guard !sourceURLs.contains(where: {
            $0.standardizedFileURL.resolvingSymlinksInPath() == archive
                || (isDirectory(at: $0) && archive.path.hasPrefix(
                    $0.standardizedFileURL.resolvingSymlinksInPath().path + "/"
                ))
        }) else { throw ArchiveEngineError.archiveIncludedInSources }

        let pathComponents = internalPath.split(separator: "/").map(String.init)
        guard pathComponents.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("\\") }) else {
            throw ArchiveEngineError.unsafePath
        }
        // Sources are read in place under unique names; nothing is copied.
        let fingerprint = try ArchiveSourceFingerprint.capture([archive])
        // Every open session of this file shows the addition (and an inner one is marked modified).
        let affected = sessions.values.filter { $0.archive.identity == fingerprint.files[0] }
        guard !affected.contains(where: \.isReadOnly) else { throw ArchiveEngineError.updateUnsupported }
        progress(ArchiveProgress(phase: .staging, fraction: 0))
        var names: [String] = []
        for sourceURL in sourceURLs { names.append(uniqueStagedName(sourceURL.lastPathComponent, in: names)) }
        let sources = zip(sourceURLs, names).map { source, name in
            NativeSevenZipBackend.WriteSource(url: source, archivePath: (pathComponents + [name]).joined(separator: "/"))
        }
        progress(ArchiveProgress(phase: .staging, fraction: 1))
        try await rewriteArchive(archive, expecting: fingerprint, password: password, sources: sources, excluding: [])
        for session in affected {
            if let password { sessions[session.id]?.password = password }
            try await relist(session.id, markingModified: true)
        }
        progress(ArchiveProgress(phase: .compressing, fraction: 1))
    }

    func exportItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        try await publishItem(item, to: url, password: password, promised: false, progress: progress)
    }

    func exportPromisedItem(_ item: BrowserItem, to url: URL, password: String?, progress: @escaping ArchiveProgressHandler) async throws {
        try await publishItem(item, to: url, password: password, promised: true, progress: progress)
    }

    /// Extracts the item straight onto the destination's volume. Ordinary destinations get a
    /// hidden sibling that is moved into place only after extraction and validation succeed;
    /// file promises write only the exact URL AppKit granted (never its parent or a sibling).
    private func publishItem(_ item: BrowserItem, to url: URL, password: String?, promised: Bool,
                             progress: @escaping ArchiveProgressHandler) async throws {
        guard case let .archive(address) = item.location,
              let session = sessions[address.sessionID],
              let archive = session.archives[address.archiveID],
              let entry = archive.entries[address.internalPath] else { throw ArchiveEngineError.itemNotFound }
        let path = try safeArchivePath(address.internalPath)
        let active = url.startAccessingSecurityScopedResource()
        defer { if active { url.stopAccessingSecurityScopedResource() } }
        // A link is never published as a file, and destinations are never overwritten.
        if !item.isDirectory && entry.attributes?.contains("l") == true { throw ArchiveEngineError.unsafePath }
        if promised && fileManager.fileExists(atPath: url.path) { throw CocoaError(.fileWriteFileExists) }
        try ensureUnchanged(archive)
        progress(ArchiveProgress(phase: .extracting, fraction: 0))
        let output = promised ? url : url.deletingLastPathComponent()
            .appendingPathComponent(".zforge-publish-\(UUID().uuidString)", isDirectory: item.isDirectory)
        var published = false
        defer { if !published { try? fileManager.removeItem(at: output) } }
        let effectivePassword = password ?? session.password
        let lastIndex = lastNativeIndex(in: archive, selecting: [path])
        if item.isDirectory {
            try fileManager.createDirectory(at: output, withIntermediateDirectories: false)
            try await nativeBackend.extract(at: archive.fileURL, password: effectivePassword,
                paths: [path], destination: output, base: path, lastIndex: lastIndex,
                cancellationScope: session.readScope)
            try Task.checkCancellation()
            let root = output.standardizedFileURL.resolvingSymlinksInPath()
            let candidates = (fileManager.enumerator(at: output, includingPropertiesForKeys: [.isSymbolicLinkKey])?
                .allObjects as? [URL]) ?? []
            for candidate in candidates where try candidate.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true {
                guard candidate.resolvingSymlinksInPath().standardizedFileURL.path.hasPrefix(root.path + "/") else {
                    throw ArchiveEngineError.unsafePath
                }
            }
        } else {
            // For a promise the output is the granted URL itself; the bridge opens exactly it.
            let destination = promised ? url : url.deletingLastPathComponent()
            try await nativeBackend.extract(at: archive.fileURL, password: effectivePassword,
                paths: [path], destination: destination, outputFile: output, lastIndex: lastIndex,
                cancellationScope: session.readScope)
            try Task.checkCancellation()
        }
        try ensureUnchanged(archive)
        if !promised {
            try Task.checkCancellation()
            try fileManager.moveItem(at: output, to: url)
        }
        published = true
        if let password { sessions[address.sessionID]?.password = password }
        progress(ArchiveProgress(phase: .extracting, fraction: 1))
    }

    @discardableResult
    func removeItems(_ items: [BrowserItem], password: String?, progress: @escaping ArchiveProgressHandler) async throws -> String? {
        guard let first = items.first, case let .archive(address) = first.location,
              let session = sessions[address.sessionID], !session.isReadOnly else {
            throw ArchiveEngineError.updateUnsupported
        }
        let archive = session.originalURL.standardizedFileURL.resolvingSymlinksInPath()
        guard ArchiveFormatRegistry.supportsUpdating(archive.lastPathComponent) else { throw ArchiveEngineError.updateUnsupported }
        try rejectMultiVolumeZip(archive)
        guard let record = session.archives[address.archiveID], record.fingerprint.matches(record.sources) else {
            throw ArchiveEngineError.archiveChanged
        }
        let paths = try items.map { item -> String in
            guard case let .archive(other) = item.location,
                  other.sessionID == address.sessionID, other.archiveID == address.archiveID,
                  session.archives[address.archiveID]?.entries[other.internalPath] != nil else { throw ArchiveEngineError.itemNotFound }
            let path = try safeArchivePath(other.internalPath)
            guard !path.isEmpty else { throw ArchiveEngineError.unsafePath }
            return path
        }
        let effectivePassword = password ?? session.password
        progress(ArchiveProgress(phase: .compressing, fraction: 0))
        try await rewriteArchive(archive, expecting: record.fingerprint, password: effectivePassword,
            sources: [], excluding: paths)
        if let password { sessions[address.sessionID]?.password = password }
        try await relist(address.sessionID, markingModified: true)
        progress(ArchiveProgress(phase: .compressing, fraction: 1))
        return effectivePassword
    }

    func reorganizeItems(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool,
                         password: String?, resolveConflict: @escaping ArchiveConflictResolver,
                         progress: @escaping ArchiveProgressHandler) async throws -> ArchiveReorganizationResult {
        do {
            return try await reorganize(items, to: destination, moving: moving, password: password,
                resolveConflict: resolveConflict, progress: progress)
        } catch ArchiveEngineError.archiveChangedSinceOpening {
            // Reading the moved items found the archive changed: report it as a write conflict.
            throw ArchiveEngineError.archiveChanged
        }
    }

    private func reorganize(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool,
                            password: String?, resolveConflict: @escaping ArchiveConflictResolver,
                            progress: @escaping ArchiveProgressHandler) async throws -> ArchiveReorganizationResult {
        guard !items.isEmpty,
              let session = sessions[destination.sessionID],
              let record = session.archives[destination.archiveID] else { throw ArchiveEngineError.itemNotFound }
        guard !session.isReadOnly else { throw ArchiveEngineError.updateUnsupported }
        let archive = session.originalURL.standardizedFileURL.resolvingSymlinksInPath()
        guard ArchiveFormatRegistry.supportsUpdating(archive.lastPathComponent) else { throw ArchiveEngineError.updateUnsupported }
        try rejectMultiVolumeZip(archive)
        guard record.fingerprint.matches(record.sources) else { throw ArchiveEngineError.archiveChanged }
        let target = destination.internalPath.isEmpty ? "" : try safeArchivePath(destination.internalPath)
        if !target.isEmpty {
            guard try self.items(at: ArchiveAddress(sessionID: destination.sessionID,
                archiveID: destination.archiveID, internalPath: (target as NSString).deletingLastPathComponent))
                .contains(where: { $0.isDirectory && $0.name == (target as NSString).lastPathComponent }) else {
                throw ArchiveEngineError.itemNotFound
            }
        }
        let sources = try items.map { item -> String in
            guard case let .archive(address) = item.location, address.sessionID == destination.sessionID,
                  address.archiveID == destination.archiveID,
                  record.entries[address.internalPath] != nil else { throw ArchiveEngineError.itemNotFound }
            let path = try safeArchivePath(address.internalPath)
            guard !path.isEmpty, !item.isDirectory || (target != path && !target.hasPrefix(path + "/")) else {
                throw ArchiveEngineError.unsafePath
            }
            return path
        }
        // Normalize parent/descendant selections here as well as in the UI.
        let roots = zip(items, sources).filter { item, path in
            !zip(items, sources).contains { parent, parentPath in
                parent.isDirectory && parentPath != path && path.hasPrefix(parentPath + "/")
            }
        }
        // Only the transferred items are staged; the archive itself is read in place.
        let operation = sessionsRoot.appendingPathComponent("Operations/\(UUID().uuidString)", isDirectory: true)
        let input = operation.appendingPathComponent("Input", isDirectory: true)
        try fileManager.createDirectory(at: input, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: operation) }
        var occupied = try self.items(at: destination).map(\.name)
        var stagedNames: Set<String> = []
        var paths: [String] = []
        var exclusions: [String] = []
        var repeated: ArchiveConflictDecision?
        let effectivePassword = password ?? session.password
        for (item, source) in roots {
            var name = item.name
            var path = [target, name].filter { !$0.isEmpty }.joined(separator: "/")
            if moving && path == source { continue }
            if path == source || stagedNames.contains(name) { name = uniqueStagedName(name, in: occupied); path = [target, name].filter { !$0.isEmpty }.joined(separator: "/") }
            else if occupied.contains(name) {
                // Never replace an ancestor that contains any selected source.
                guard !sources.contains(where: { $0 == path || $0.hasPrefix(path + "/") }) else { throw ArchiveEngineError.unsafePath }
                let decision: ArchiveConflictDecision
                if let repeated { decision = repeated }
                else { decision = await resolveConflict(ArchiveConflict(path: path, destinationURL: archive.appendingPathComponent(path), isDirectory: item.isDirectory)) }
                switch decision {
                case .cancel: throw ArchiveEngineError.cancelled
                case let .keep(all): if all { repeated = decision }; continue
                case let .replace(all): if all { repeated = decision }; exclusions.append(path)
                }
            }
            let staged = input.appendingPathComponent(path)
            try fileManager.createDirectory(at: staged.deletingLastPathComponent(), withIntermediateDirectories: true)
            try await exportItem(item, to: staged, password: effectivePassword, progress: progress)
            occupied.append(name); stagedNames.insert(name); paths.append(path)
            if moving { exclusions.append(source) }
        }
        guard !paths.isEmpty else { return ArchiveReorganizationResult(paths: [], password: effectivePassword) }
        try Task.checkCancellation()
        try await rewriteArchive(archive, expecting: record.fingerprint, password: effectivePassword,
            sources: paths.map { NativeSevenZipBackend.WriteSource(url: input.appendingPathComponent($0), archivePath: $0) },
            excluding: exclusions)
        if let password { sessions[destination.sessionID]?.password = password }
        try await relist(destination.sessionID, markingModified: true)
        return ArchiveReorganizationResult(paths: paths, password: effectivePassword)
    }

    /// One pass: the native writer reads the original in place and writes the updated archive
    /// once into a hidden file beside it, which is validated and then atomically replaces the
    /// original. Nothing is copied; a change of the original (fingerprint) aborts before the
    /// write and again before the replacement.
    private func rewriteArchive(_ archive: URL, expecting fingerprint: ArchiveSourceFingerprint, password: String?,
                                sources: [NativeSevenZipBackend.WriteSource], excluding: [String]) async throws {
        let format: ArchiveCompressionFormat = archive.pathExtension.lowercased() == "zip" ? .zip : .sevenZip
        let updated = archive.deletingLastPathComponent()
            .appendingPathComponent(".zforge-update-\(UUID().uuidString)-\(archive.lastPathComponent)")
        defer { try? fileManager.removeItem(at: updated) }
        guard fingerprint.matches([archive]) else { throw ArchiveEngineError.archiveChanged }
        try await nativeBackend.write(to: updated, updating: archive, options: CompressionOptions(format: format),
            password: password, sources: sources, excludingPaths: excluding)
        try await nativeBackend.test(at: updated, password: password)
        try Task.checkCancellation()
        guard fingerprint.matches([archive]) else { throw ArchiveEngineError.archiveChanged }
        _ = try fileManager.replaceItemAt(archive, withItemAt: updated)
    }

    private func rejectMultiVolumeZip(_ archive: URL) throws {
        guard archive.pathExtension.lowercased() == "zip" else { return }
        let volumeName = archive.deletingPathExtension().lastPathComponent.lowercased() + ".z01"
        guard !(try fileManager.contentsOfDirectory(atPath: archive.deletingLastPathComponent().path))
            .contains(where: { $0.lowercased() == volumeName }) else { throw ArchiveEngineError.multiVolumeUpdateUnsupported }
    }

    func testArchive(at url: URL, password: String?) async throws {
        // Reads the archive and its volumes in place.
        try await nativeBackend.test(at: url, password: password)
    }

    func extractArchive(
        at url: URL,
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        // Reads the archive and its volumes in place; the listing and the extraction must see
        // the same files.
        progress(ArchiveProgress(phase: .staging, fraction: 0))
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        let archive = try await listArchive(
            at: url,
            sources: relatedVolumeURLs(for: url),
            displayName: url.lastPathComponent,
            password: password
        )
        progress(ArchiveProgress(phase: .staging, fraction: 1))
        let replacements = try await conflictFilesToReplace(
            entries: archive.entries,
            selectedPaths: [],
            destinationURL: destinationURL,
            resolveConflict: resolveConflict
        )
        for replacement in replacements {
            try fileManager.removeItem(at: replacement)
        }

        try ensureUnchanged(archive)
        progress(ArchiveProgress(phase: .extracting, fraction: 0))
        try await nativeBackend.extract(at: url, password: password,
            paths: [], destination: destinationURL)

        progress(ArchiveProgress(phase: .extracting, fraction: 1))
    }

    func extractItems(
        _ items: [BrowserItem],
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        guard !items.isEmpty,
              case let .archive(firstAddress) = items[0].location,
              let session = sessions[firstAddress.sessionID],
              let archive = session.archives[firstAddress.archiveID] else {
            throw ArchiveEngineError.itemNotFound
        }

        let paths = try items.map { item -> String in
            guard case let .archive(address) = item.location,
                  address.sessionID == firstAddress.sessionID,
                  address.archiveID == firstAddress.archiveID else {
                throw ArchiveEngineError.itemNotFound
            }
            return try safeArchivePath(address.internalPath)
        }
        try ensureUnchanged(archive)
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        let replacements = try await conflictFilesToReplace(
            entries: archive.entries,
            selectedPaths: paths,
            destinationURL: destinationURL,
            resolveConflict: resolveConflict
        )
        for replacement in replacements {
            try fileManager.removeItem(at: replacement)
        }
        progress(ArchiveProgress(phase: .extracting, fraction: 0))
        let effectivePassword = password ?? session.password
        let selection = archive.isRawStream ? [] : paths
        try ensureUnchanged(archive)
        try await nativeBackend.extract(at: archive.fileURL, password: effectivePassword,
            paths: selection, destination: destinationURL,
            lastIndex: lastNativeIndex(in: archive, selecting: selection), cancellationScope: session.readScope)
        try ensureUnchanged(archive)

        if let password {
            self.sessions[firstAddress.sessionID]?.password = password
        }
        progress(ArchiveProgress(phase: .extracting, fraction: 1))
    }

    func archiveRootURL(for address: ArchiveAddress) async throws -> URL {
        guard let session = sessions[address.sessionID] else {
            throw ArchiveEngineError.itemNotFound
        }
        return session.originalURL
    }

    /// The names from the outermost archive on disk to this one.
    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String] {
        var names: [String] = []
        var current = sessions[address.sessionID]
        guard current != nil else { throw ArchiveEngineError.itemNotFound }
        while let session = current {
            names.append(session.origin.map { URL(fileURLWithPath: $0.internalPath).lastPathComponent }
                ?? session.originalURL.lastPathComponent)
            current = session.origin.flatMap { sessions[$0.sessionID] }
        }
        return names.reversed()
    }

    func outermostArchiveURL(for address: ArchiveAddress) async throws -> URL {
        guard var session = sessions[address.sessionID] else { throw ArchiveEngineError.itemNotFound }
        while let origin = session.origin, let outer = sessions[origin.sessionID] { session = outer }
        return session.originalURL
    }

    func setPassword(_ password: String?, for sessionID: UUID) {
        guard var session = sessions[sessionID] else { return }
        session.password = password
        sessions[sessionID] = session
    }

    /// Releases one reference. At zero the session closes, unless it is an inner archive
    /// that was modified: then it waits for `writeBack`, `saveInnerArchive` or
    /// `discardInnerArchive`, and its outer session stays open until then.
    func closeSession(_ sessionID: UUID) async {
        guard var session = sessions[sessionID] else { return }
        session.references -= 1
        guard session.references <= 0 else { sessions[sessionID] = session; return }
        if session.origin != nil && session.isModified {
            guard !session.awaitingWriteBack else { return }
            session.awaitingWriteBack = true
            sessions[sessionID] = session
            NotificationCenter.default.post(name: Self.innerArchiveNeedsWriteBack, object: self,
                userInfo: ["sessionID": sessionID])
            return
        }
        await finishSession(sessionID)
    }

    /// Removes the session and its files, then releases its outer session.
    private func finishSession(_ sessionID: UUID) async {
        guard let session = sessions.removeValue(forKey: sessionID) else { return }
        await nativeBackend.cancelOperations(in: session.directoryURL)
        try? fileManager.removeItem(at: session.directoryURL)
        if let origin = session.origin { await closeSession(origin.sessionID) }
    }

    /// Inner archives waiting for their outer archive to be rebuilt.
    func pendingWriteBacks() -> [UUID] {
        sessions.values.filter(\.awaitingWriteBack).map(\.id)
    }

    /// Names shown while writing back: the inner archive and the archive it goes into.
    func writeBackDescription(_ sessionID: UUID) -> (inner: String, outer: String)? {
        guard let session = sessions[sessionID], let origin = session.origin,
              let outer = sessions[origin.sessionID] else { return nil }
        return (URL(fileURLWithPath: origin.internalPath).lastPathComponent, outer.archive.displayName)
    }

    /// Rebuilds the outer archive with the modified inner archive replacing its entry, in
    /// one pass beside the original, validated before the atomic replacement. Throws
    /// `archiveChanged` when the outer archive changed since it was read, unless
    /// `replacingChangedOuter`; on any failure the modified copy is kept for another attempt.
    func writeBack(_ sessionID: UUID, password: String? = nil, replacingChangedOuter: Bool = false) async throws {
        try Task.checkCancellation()
        guard let session = sessions[sessionID], session.awaitingWriteBack, let origin = session.origin,
              let outer = sessions[origin.sessionID] else { throw ArchiveEngineError.itemNotFound }
        guard !outer.isReadOnly else { throw ArchiveEngineError.updateUnsupported }
        let target = outer.originalURL.standardizedFileURL.resolvingSymlinksInPath()
        let expected = replacingChangedOuter
            ? try ArchiveSourceFingerprint.capture([target])
            : outer.archive.fingerprint
        guard expected.matches([target]) else { throw ArchiveEngineError.archiveChanged }
        let effectivePassword = password ?? outer.password
        try await rewriteArchive(target, expecting: expected, password: effectivePassword,
            sources: [NativeSevenZipBackend.WriteSource(url: session.originalURL, archivePath: origin.internalPath)],
            excluding: [])
        if let password { sessions[origin.sessionID]?.password = password }
        try? await relist(origin.sessionID, markingModified: true)
        await finishSession(sessionID)
    }

    /// Saves the modified inner archive elsewhere instead and ends its session.
    func saveInnerArchive(_ sessionID: UUID, to destination: URL) async throws {
        guard let session = sessions[sessionID], session.awaitingWriteBack else { throw ArchiveEngineError.itemNotFound }
        try fileManager.copyItem(at: session.originalURL, to: destination)
        await finishSession(sessionID)
    }

    /// Drops the inner archive's changes and ends its session.
    func discardInnerArchive(_ sessionID: UUID) async {
        guard sessions[sessionID]?.awaitingWriteBack == true else { return }
        await finishSession(sessionID)
    }

    /// Open sessions and their references (diagnostics and tests).
    func sessionReferences() -> [UUID: Int] {
        sessions.mapValues(\.references)
    }

    func closeAllSessions() async {
        let closing = Array(sessions.values)
        sessions.removeAll()
        for session in closing {
            await nativeBackend.cancelOperations(in: session.directoryURL)
            try? fileManager.removeItem(at: session.directoryURL)
        }
    }

    func cancelAllOperations() {
        nativeBackend.cancelAll()
    }

    func cleanupStaleSessions() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: sessionsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let cutoff = Date().addingTimeInterval(-86_400)
        // Windows share this engine: a session still open is never stale.
        let live = Set(sessions.keys.map(\.uuidString))
        for url in urls where !live.contains(url.lastPathComponent) {
            let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            if date == nil || date! < cutoff {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func listArchive(
        at url: URL,
        sources: [URL],
        displayName: String,
        password: String?,
        archiveID: UUID? = nil,
        cancellationScope: URL? = nil
    ) async throws -> ArchiveRecord {
        let fingerprint = try ArchiveSourceFingerprint.capture(sources)
        let identity = try ArchiveSourceFingerprint.capture([url]).files[0]
        var (entries, listingNeedsPassword) = try await nativeBackend.listing(
            at: url, password: password, cancellationScope: cancellationScope)
        // The listing describes these files only if they did not change while it was read.
        guard fingerprint.matches(sources) else { throw ArchiveEngineError.archiveChangedSinceOpening }

        let isRawStream = entries.isEmpty && isStreamURL(url)
        if isRawStream {
            let path = rawStreamOutputName(for: displayName)
            var entry = Entry(
                path: path,
                isDirectory: false,
                size: nil,
                packedSize: nil,
                modified: nil,
                created: nil,
                accessed: nil,
                encrypted: false,
                checksum: nil,
                method: nil,
                attributes: nil
            )
            entry.solidBlock = ArchiveSolidBlock(packedSize: fingerprint.files.reduce(0) { $0 + $1.size })
            entries[path] = entry
        }
        return ArchiveRecord(
            id: archiveID ?? UUID(),
            fileURL: url,
            sources: sources,
            fingerprint: fingerprint,
            identity: identity,
            displayName: displayName,
            entries: entries,
            children: Entry.childIndex(of: entries),
            directoriesContainingFiles: Entry.directoriesContainingFiles(in: entries),
            isRawStream: isRawStream,
            isSequential: ZFSevenZipBridge.isCompressedTarPath(url.path),
            listingNeedsPassword: listingNeedsPassword
        )
    }

    private func ensureUnchanged(_ archive: ArchiveRecord) throws {
        guard archive.fingerprint.matches(archive.sources) else { throw ArchiveEngineError.archiveChangedSinceOpening }
    }

    /// The last native index a sequential read needs for the selected paths (nil reads to the
    /// end). Duplicate paths keep their last occurrence, so the bound never stops too early.
    private func lastNativeIndex(in archive: ArchiveRecord, selecting paths: [String]) -> UInt32? {
        guard archive.isSequential, !paths.isEmpty else { return nil }
        let selection = ArchivePathSelection(paths)
        var last: UInt32?
        for entry in archive.entries.values where selection.contains(entry.path) {
            // A synthesized parent has no index: its descendants carry the bound.
            guard let index = entry.nativeIndex else { continue }
            last = max(last ?? 0, index)
        }
        return last
    }

    private func totalArchiveSize(at url: URL) -> Int64? {
        var total: Int64 = 0
        for volumeURL in relatedVolumeURLs(for: url) {
            guard let fileSize = try? volumeURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                return nil
            }
            let (newTotal, overflow) = total.addingReportingOverflow(Int64(fileSize))
            guard !overflow else { return nil }
            total = newTotal
        }
        return total
    }

    /// The archive and the sibling volumes the native handlers read with it.
    private func relatedVolumeURLs(for url: URL) -> [URL] {
        let folder = url.deletingLastPathComponent()
        let name = url.lastPathComponent.lowercased()
        guard let siblings = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return [url]
        }
        func matching(_ pattern: String) -> [URL] {
            let matches = siblings.filter {
                $0.lastPathComponent.lowercased().range(of: pattern, options: .regularExpression) != nil
            }
            guard matches.contains(where: { $0.lastPathComponent.lowercased() == name }) else { return [url] }
            return matches.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
        if let range = name.range(of: #"\.(7z|zip)\.\d{3}$"#, options: .regularExpression) {
            let prefix = NSRegularExpression.escapedPattern(for: String(name[..<range.lowerBound]))
            let kind = name[range].dropFirst().prefix { $0 != "." }
            return matching("^" + prefix + "\\." + kind + #"\.\d{3}$"#)
        }
        if let range = name.range(of: #"\.part\d+\.rar$"#, options: .regularExpression) {
            let prefix = NSRegularExpression.escapedPattern(for: String(name[..<range.lowerBound]))
            return matching("^" + prefix + #"\.part\d+\.rar$"#)
        }
        if name.hasSuffix(".rar") || name.range(of: #"\.r\d{2}$"#, options: .regularExpression) != nil {
            let prefix = name.replacingOccurrences(of: #"\.(rar|r\d{2})$"#, with: "", options: .regularExpression)
            return matching("^" + NSRegularExpression.escapedPattern(for: prefix) + #"\.(rar|r\d{2})$"#)
        }
        if name.hasSuffix(".zip") {
            let prefix = NSRegularExpression.escapedPattern(for: String(name.dropLast(4)))
            return matching("^" + prefix + #"\.(zip|z\d{2})$"#)
        }
        return [url]
    }

    private func runCreate(
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        sourceNames: [String],
        workingDirectory: URL
    ) async throws {
        try await nativeBackend.write(to: outputURL, options: options, password: password,
            names: sourceNames, directory: workingDirectory)
    }

    private func isStreamURL(_ url: URL) -> Bool {
        ["gz", "gzip", "bz2", "bzip2", "xz"].contains(url.pathExtension.lowercased())
    }

    private func rawStreamOutputName(for displayName: String) -> String {
        let lowercased = displayName.lowercased()
        for suffix in [".bzip2", ".bzip", ".bz2", ".gzip", ".gz", ".xz"] {
            if lowercased.hasSuffix(suffix) {
                return String(displayName.dropLast(suffix.count))
            }
        }
        return URL(fileURLWithPath: displayName).deletingPathExtension().lastPathComponent
    }

    private func conflictFilesToReplace(
        entries: [String: Entry],
        selectedPaths: [String],
        destinationURL: URL,
        resolveConflict: @escaping ArchiveConflictResolver
    ) async throws -> [URL] {
        let selected = selectedPaths.compactMap { try? safeArchivePath($0) }
        let selection = ArchivePathSelection(selected)
        let relevantEntries = entries.values
            .filter { entry in selected.isEmpty || selection.contains(entry.path) }
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

        var replacements: [URL] = []
        var applyToAll: ArchiveConflictDecision?
        for entry in relevantEntries where !entry.isDirectory {
            let destination = destinationURL.appendingPathComponent(entry.path)
            guard fileManager.fileExists(atPath: destination.path) else { continue }

            let decision: ArchiveConflictDecision
            if let applyToAll {
                decision = applyToAll
            } else {
                decision = await resolveConflict(ArchiveConflict(
                    path: entry.path,
                    destinationURL: destination,
                    isDirectory: false
                ))
                switch decision {
                case .replace(applyToAll: true), .keep(applyToAll: true):
                    applyToAll = decision
                case .replace, .keep, .cancel:
                    break
                }
            }

            switch decision {
            case .replace:
                replacements.append(destination)
            case .keep:
                continue
            case .cancel:
                throw ArchiveEngineError.cancelled
            }
        }
        return replacements
    }

    private func safeArchivePath(_ raw: String) throws -> String {
        try ArchivePathPolicy.safePath(raw)
    }

    private func normalized(_ path: String) -> String {
        ArchivePathPolicy.normalized(path)
    }

    private func sanitizedFileName(_ name: String) -> String {
        let value = name.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\0", with: "_")
        return value.isEmpty ? "Archive Item" : value
    }

    private func isDirectory(at url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func uniqueStagedName(_ name: String, in existing: [String]) -> String {
        guard existing.contains(name) else { return name }
        let extensionName = URL(fileURLWithPath: name).pathExtension
        let stem = extensionName.isEmpty
            ? name
            : URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        var index = 2
        while true {
            let candidate = extensionName.isEmpty
                ? "\(stem) \(index)"
                : "\(stem) \(index).\(extensionName)"
            if !existing.contains(candidate) { return candidate }
            index += 1
        }
    }

    private func purposeDirectoryName(_ purpose: ArchiveMaterializationPurpose) -> String {
        switch purpose {
        case .preview: "Previews"
        case .openExternally: "Opened"
        }
    }

    private func ensureAvailableSpace(for bytes: Int64, at url: URL) throws {
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let available = values.volumeAvailableCapacityForImportantUsage else { return }
        guard available > 536_870_912 && bytes < available - 536_870_912 else { throw ArchiveEngineError.insufficientSpace }
    }

    private func propagateQuarantine(from source: URL, to destination: URL) {
        guard let sourceValues = try? source.resourceValues(forKeys: [.quarantinePropertiesKey]),
              let properties = sourceValues.quarantineProperties else { return }
        var destinationValues = URLResourceValues()
        destinationValues.quarantineProperties = properties
        var destination = destination
        try? destination.setResourceValues(destinationValues)
    }

}
