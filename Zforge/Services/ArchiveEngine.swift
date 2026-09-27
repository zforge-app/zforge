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
    case nestedArchiveNotAllowed
    case cancelled

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
        case .nestedArchiveNotAllowed:
            AppLocalization.string("The nested archive navigation limit has been reached.")
        case .cancelled: AppLocalization.string("error.cancelled")
        }
    }
}

nonisolated enum ArchiveMaterializationPurpose: Sendable, Equatable {
    case preview
    case openExternally
    case nestedArchive
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
}

nonisolated protocol ArchiveServing: Sendable {
    func openArchive(
        at url: URL,
        password: String?,
        policy: ArchiveBrowsingPolicy
    ) async throws -> ArchiveOpenResult
    func items(at address: ArchiveAddress) async throws -> [BrowserItem]
    func openNestedArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult
    func materialize(
        item: BrowserItem,
        purpose: ArchiveMaterializationPurpose,
        automaticLimit: Int64?
    ) async throws -> URL
    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        format: ArchiveCompressionFormat,
        progress: @escaping ArchiveProgressHandler
    ) async throws
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
    func setPassword(_ password: String?, for sessionID: UUID) async
    func closeSession(_ sessionID: UUID) async
    func closeAllSessions() async
    func cancelAllOperations() async
    func cleanupStaleSessions() async
}

extension ArchiveServing {
    func testArchive(at url: URL, password: String?) async throws {
        throw ArchiveEngineError.helperUnavailable
    }

    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult {
        try await openArchive(at: url, password: password, policy: .standard)
    }

    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String] {
        [try await archiveRootURL(for: address).lastPathComponent]
    }
}

actor SevenZipArchiveEngine: ArchiveServing {
    private typealias Entry = SevenZipListingParser.Entry

    private struct ArchiveRecord: Sendable {
        let id: UUID
        let fileURL: URL
        let displayName: String
        let parentArchiveID: UUID?
        let entries: [String: Entry]
        let isRawStream: Bool
    }

    private struct Session: Sendable {
        let id: UUID
        let originalURL: URL
        let directoryURL: URL
        var password: String?
        var archives: [UUID: ArchiveRecord]
        var materialized: [String: URL]
    }

    private let fileManager: FileManager
    private let processRunner: SevenZipProcessRunner
    private let sessionsRoot: URL
    private var sessions: [UUID: Session] = [:]

    init(fileManager: FileManager = .default, helperURL: URL? = nil) {
        self.fileManager = fileManager
        self.processRunner = SevenZipProcessRunner(helperURL: helperURL ?? Self.locateHelper())
        sessionsRoot = ZforgeTemporaryStorage.archiveSessionsRoot(fileManager: fileManager)
    }

    func openArchive(
        at url: URL,
        password: String?,
        policy: ArchiveBrowsingPolicy
    ) async throws -> ArchiveOpenResult {
        let sessionID = UUID()
        let sessionDirectory = sessionsRoot.appendingPathComponent(sessionID.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)

        do {
            let allowsNestedArchives = policy.allowsNestedArchives(forOutermostSize: totalArchiveSize(at: url))
            let stagedURL = try stageArchiveAndVolumes(at: url, in: sessionDirectory)
            let browsableURL = try await archiveURLForBrowsing(
                stagedURL,
                in: sessionDirectory,
                password: password
            )
            let archive = try await listArchive(
                at: browsableURL,
                displayName: url.lastPathComponent,
                password: password
            )
            sessions[sessionID] = Session(
                id: sessionID,
                originalURL: url,
                directoryURL: sessionDirectory,
                password: password,
                archives: [archive.id: archive],
                materialized: [:]
            )
            return ArchiveOpenResult(
                address: ArchiveAddress(
                    sessionID: sessionID,
                    archiveID: archive.id,
                    internalPath: "",
                    allowsNestedArchives: allowsNestedArchives,
                    nestedArchiveDepth: 0,
                    maximumNestedArchiveDepth: policy.maximumNestedArchiveDepth
                ),
                displayName: archive.displayName
            )
        } catch {
            try? fileManager.removeItem(at: sessionDirectory)
            throw error
        }
    }

    func items(at address: ArchiveAddress) throws -> [BrowserItem] {
        guard let session = sessions[address.sessionID],
              let archive = session.archives[address.archiveID] else {
            throw ArchiveEngineError.invalidArchive(AppLocalization.string("archive.session_closed"))
        }

        let parent = normalized(address.internalPath)
        return archive.entries.values.compactMap { entry in
            guard immediateChildName(path: entry.path, parent: parent) != nil else { return nil }
            guard let childName = immediateChildName(path: entry.path, parent: parent) else { return nil }
            let childPath = parent.isEmpty ? childName : "\(parent)/\(childName)"
            guard entry.path == childPath || entry.path == childPath + "/" else { return nil }
            let childAddress = ArchiveAddress(
                sessionID: address.sessionID,
                archiveID: address.archiveID,
                internalPath: childPath,
                allowsNestedArchives: address.allowsNestedArchives,
                nestedArchiveDepth: address.nestedArchiveDepth,
                maximumNestedArchiveDepth: address.maximumNestedArchiveDepth
            )
            let isArchive = !entry.isDirectory && ArchiveFormatRegistry.recognizes(childName)
            return BrowserItem(
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
                compressionMethod: entry.method
            )
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

    func openNestedArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        guard case let .archive(address) = item.location else { throw ArchiveEngineError.itemNotFound }
        guard address.canOpenNestedArchive else { throw ArchiveEngineError.nestedArchiveNotAllowed }
        let url = try await materialize(item: item, purpose: .nestedArchive, automaticLimit: nil)
        let archive = try await listArchive(
            at: url,
            displayName: item.name,
            password: password,
            parentArchiveID: address.archiveID
        )
        guard var session = sessions[address.sessionID] else { throw ArchiveEngineError.itemNotFound }
        session.archives[archive.id] = archive
        if let password { session.password = password }
        sessions[address.sessionID] = session
        return ArchiveOpenResult(
            address: ArchiveAddress(
                sessionID: address.sessionID,
                archiveID: archive.id,
                internalPath: "",
                allowsNestedArchives: address.allowsNestedArchives,
                nestedArchiveDepth: address.nestedArchiveDepth + 1,
                maximumNestedArchiveDepth: address.maximumNestedArchiveDepth
            ),
            displayName: item.name
        )
    }

    func materialize(
        item: BrowserItem,
        purpose: ArchiveMaterializationPurpose,
        automaticLimit: Int64?
    ) async throws -> URL {
        guard case let .archive(address) = item.location,
              var session = sessions[address.sessionID],
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

        let expectedSize = item.size
        let hardLimit: Int64 = if let expectedSize {
            expectedSize + 1_048_576
        } else {
            1_073_741_824
        }
        try ensureAvailableSpace(for: expectedSize ?? hardLimit, at: session.directoryURL)

        let purposeDirectory = session.directoryURL
            .appendingPathComponent(purposeDirectoryName(purpose), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: purposeDirectory, withIntermediateDirectories: true)
        let safeName = sanitizedFileName(item.name)
        let outputURL = purposeDirectory.appendingPathComponent(safeName)

        let arguments = archive.isRawStream
            ? ["x", "-so", "-sccUTF-8", "-bso0", "-bse2", "-bsp0", "-spd", "-y", archive.fileURL.path]
            : materializationExtractionArguments(
                archive: archive.fileURL,
                path: address.internalPath
            )
        let result = try await processRunner.run(
            arguments: arguments,
            password: session.password,
            standardOutputURL: outputURL,
            workingDirectory: session.directoryURL,
            hardOutputLimit: hardLimit
        )
        try validate(result, passwordWasProvided: session.password != nil)

        let attributes = try fileManager.attributesOfItem(atPath: outputURL.path)
        if let written = (attributes[.size] as? NSNumber)?.int64Value, written > hardLimit {
            try? fileManager.removeItem(at: outputURL)
            throw ArchiveEngineError.sizeLimitExceeded
        }

        if purpose == .openExternally {
            try? fileManager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: outputURL.path)
            propagateQuarantine(from: session.originalURL, to: outputURL)
        }

        session.materialized[cacheKey] = outputURL
        sessions[address.sessionID] = session
        return outputURL
    }

    func createArchive(
        from sourceURLs: [URL],
        outputURL: URL,
        format: ArchiveCompressionFormat,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        guard !sourceURLs.isEmpty else { throw ArchiveEngineError.itemNotFound }

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
                format: .tar,
                sourceNames: stagedNames,
                workingDirectory: inputDirectory
            )
            progress(ArchiveProgress(phase: .compressing, fraction: 0.5))
            try await runCreate(
                outputURL: stagedOutput,
                format: format,
                sourceNames: [tarURL.lastPathComponent],
                workingDirectory: operationDirectory
            )
        } else {
            try await runCreate(
                outputURL: stagedOutput,
                format: format,
                sourceNames: stagedNames,
                workingDirectory: inputDirectory
            )
        }

        progress(ArchiveProgress(phase: .compressing, fraction: 1))
        try fileManager.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: stagedOutput, to: outputURL)
    }

    func testArchive(at url: URL, password: String?) async throws {
        let operationDirectory = sessionsRoot
            .appendingPathComponent("Operations", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: operationDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: operationDirectory) }
        let stagedURL = try stageArchiveAndVolumes(at: url, in: operationDirectory)
        let result = try await processRunner.run(
            arguments: ["t", "-sccUTF-8", "-bso1", "-bse2", "-bsp0", "-spd", "-y", stagedURL.path],
            password: password,
            standardOutputURL: nil,
            workingDirectory: operationDirectory
        )
        try validate(result, passwordWasProvided: password != nil)
        if result.code != 0 {
            let output = String(decoding: result.stdout + result.stderr, as: UTF8.self)
            throw ArchiveEngineError.commandFailed(
                code: result.code,
                message: output.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }

    func extractArchive(
        at url: URL,
        to destinationURL: URL,
        password: String?,
        resolveConflict: @escaping ArchiveConflictResolver,
        progress: @escaping ArchiveProgressHandler
    ) async throws {
        let operationDirectory = sessionsRoot
            .appendingPathComponent("Operations", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: operationDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: operationDirectory) }

        progress(ArchiveProgress(phase: .staging, fraction: 0))
        let stagedURL = try stageArchiveAndVolumes(at: url, in: operationDirectory)
        let extractionArchive = try await archiveURLForBrowsing(
            stagedURL,
            in: operationDirectory,
            password: password
        )
        progress(ArchiveProgress(phase: .staging, fraction: 1))
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        let archive = try await listArchive(
            at: extractionArchive,
            displayName: url.lastPathComponent,
            password: password
        )
        let replacements = try await conflictFilesToReplace(
            entries: archive.entries,
            selectedPaths: [],
            destinationURL: destinationURL,
            resolveConflict: resolveConflict
        )
        for replacement in replacements {
            try fileManager.removeItem(at: replacement)
        }

        progress(ArchiveProgress(phase: .extracting, fraction: 0))
        let result = try await processRunner.run(
            arguments: extractionArguments(
                archive: extractionArchive,
                destination: destinationURL,
                paths: []
            ),
            password: password,
            standardOutputURL: nil,
            workingDirectory: operationDirectory
        )
        try validate(result, passwordWasProvided: password != nil)
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
        let result = try await processRunner.run(
            arguments: extractionArguments(
                archive: archive.fileURL,
                destination: destinationURL,
                paths: archive.isRawStream ? [] : paths
            ),
            password: effectivePassword,
            standardOutputURL: nil,
            workingDirectory: session.directoryURL
        )
        try validate(result, passwordWasProvided: effectivePassword != nil)
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

    func archiveHierarchy(for address: ArchiveAddress) async throws -> [String] {
        guard let session = sessions[address.sessionID] else {
            throw ArchiveEngineError.itemNotFound
        }

        var names: [String] = []
        var currentArchiveID: UUID? = address.archiveID
        var visitedArchiveIDs = Set<UUID>()
        while let archiveID = currentArchiveID {
            guard visitedArchiveIDs.insert(archiveID).inserted,
                  let archive = session.archives[archiveID] else {
                throw ArchiveEngineError.itemNotFound
            }
            names.append(archive.displayName)
            currentArchiveID = archive.parentArchiveID
        }
        return Array(names.reversed())
    }

    func setPassword(_ password: String?, for sessionID: UUID) {
        guard var session = sessions[sessionID] else { return }
        session.password = password
        sessions[sessionID] = session
    }

    func closeSession(_ sessionID: UUID) {
        guard let session = sessions.removeValue(forKey: sessionID) else { return }
        try? fileManager.removeItem(at: session.directoryURL)
    }

    func closeAllSessions() {
        for session in sessions.values {
            try? fileManager.removeItem(at: session.directoryURL)
        }
        sessions.removeAll()
    }

    func cancelAllOperations() {
        processRunner.cancelAll()
    }

    func cleanupStaleSessions() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: sessionsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let cutoff = Date().addingTimeInterval(-86_400)
        for url in urls {
            let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            if date == nil || date! < cutoff {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func listArchive(
        at url: URL,
        displayName: String,
        password: String?,
        parentArchiveID: UUID? = nil
    ) async throws -> ArchiveRecord {
        let result = try await processRunner.run(
            arguments: listingArguments(archive: url),
            password: password,
            standardOutputURL: nil,
            workingDirectory: url.deletingLastPathComponent()
        )
        try validate(result, passwordWasProvided: password != nil)
        let output = String(decoding: result.stdout, as: UTF8.self)
        var entries = try SevenZipListingParser.parse(output)
        let isRawStream = entries.isEmpty && isStreamURL(url)
        if isRawStream {
            let path = rawStreamOutputName(for: displayName)
            entries[path] = Entry(
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
        }
        guard !entries.isEmpty else {
            throw ArchiveEngineError.invalidArchive(AppLocalization.string("archive.empty_or_unsupported"))
        }
        return ArchiveRecord(
            id: UUID(),
            fileURL: url,
            displayName: displayName,
            parentArchiveID: parentArchiveID,
            entries: entries,
            isRawStream: isRawStream
        )
    }

    private func validate(_ result: SevenZipCommandResult, passwordWasProvided: Bool) throws {
        guard result.code != 0 && result.code != 1 else { return }
        let combined = String(decoding: result.stdout + result.stderr, as: UTF8.self)
        let lower = combined.lowercased()
        if lower.contains("enter password") || lower.contains("encrypted archive") || lower.contains("wrong password") {
            throw passwordWasProvided ? ArchiveEngineError.invalidPassword : ArchiveEngineError.passwordRequired
        }
        if result.code == 255 { throw ArchiveEngineError.cancelled }
        throw ArchiveEngineError.commandFailed(code: result.code, message: combined.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func stageArchiveAndVolumes(at url: URL, in directory: URL) throws -> URL {
        let related = relatedVolumeURLs(for: url)
        for source in related {
            let destination = directory.appendingPathComponent(source.lastPathComponent)
            try fileManager.copyItem(at: source, to: destination)
        }
        return directory.appendingPathComponent(url.lastPathComponent)
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

    private func relatedVolumeURLs(for url: URL) -> [URL] {
        let folder = url.deletingLastPathComponent()
        let name = url.lastPathComponent.lowercased()
        guard let siblings = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else {
            return [url]
        }
        if let range = name.range(of: #"\.(7z|zip)\.\d{3}$"#, options: .regularExpression) {
            let prefix = String(name[..<range.lowerBound])
            return siblings.filter { $0.lastPathComponent.lowercased().hasPrefix(prefix + ".") }
        }
        if name.hasSuffix(".rar") || name.range(of: #"\.r\d{2}$"#, options: .regularExpression) != nil {
            let prefix = name.replacingOccurrences(of: #"\.(rar|r\d{2})$"#, with: "", options: .regularExpression)
            let matches = siblings.filter {
                $0.lastPathComponent.lowercased().range(
                    of: "^" + NSRegularExpression.escapedPattern(for: prefix) + #"\.(rar|r\d{2})$"#,
                    options: .regularExpression
                ) != nil
            }
            return matches.isEmpty ? [url] : matches
        }
        return [url]
    }

    private func listingArguments(archive: URL) -> [String] {
        ["l", "-slt", "-ba", "-sccUTF-8", "-bso1", "-bse2", "-bsp0", archive.path]
    }

    private func runCreate(
        outputURL: URL,
        format: ArchiveCompressionFormat,
        sourceNames: [String],
        workingDirectory: URL
    ) async throws {
        let result = try await processRunner.run(
            arguments: [
                "a",
                format.sevenZipTypeSwitch,
                "-sccUTF-8",
                "-bso1",
                "-bse2",
                "-bsp0",
                "-y",
                outputURL.path,
                "--"
            ] + sourceNames,
            password: nil,
            standardOutputURL: nil,
            workingDirectory: workingDirectory
        )
        try validate(result, passwordWasProvided: false)
    }

    private func extractionArguments(
        archive: URL,
        destination: URL,
        paths: [String]
    ) -> [String] {
        [
            "x",
            "-sccUTF-8",
            "-bso0",
            "-bse2",
            "-bsp0",
            "-spd",
            "-aos",
            "-y",
            "-o\(destination.path)",
            archive.path,
            "--"
        ] + paths
    }

    private func archiveURLForBrowsing(
        _ url: URL,
        in operationDirectory: URL,
        password: String?
    ) async throws -> URL {
        guard isTarStreamURL(url) else { return url }

        let payloadDirectory = operationDirectory.appendingPathComponent(
            "StreamPayload",
            isDirectory: true
        )
        try fileManager.createDirectory(at: payloadDirectory, withIntermediateDirectories: true)
        let result = try await processRunner.run(
            arguments: [
                "x", "-sccUTF-8", "-bso0", "-bse2", "-bsp0", "-spd", "-aos", "-y",
                "-o\(payloadDirectory.path)", url.path
            ],
            password: password,
            standardOutputURL: nil,
            workingDirectory: operationDirectory
        )
        try validate(result, passwordWasProvided: password != nil)

        let payloads = try fileManager.contentsOfDirectory(
            at: payloadDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ).filter {
            (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
                && $0.pathExtension.lowercased() == "tar"
        }
        guard let payload = payloads.first else {
            throw ArchiveEngineError.invalidArchive(AppLocalization.string("archive.empty_or_unsupported"))
        }
        return payload
    }

    private func isTarStreamURL(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        return [".tar.gz", ".tar.bz2", ".tar.xz", ".tgz", ".tbz", ".tbz2", ".txz"].contains {
            name.hasSuffix($0)
        }
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

    private func materializationExtractionArguments(archive: URL, path: String) -> [String] {
        ["x", "-so", "-sccUTF-8", "-bso0", "-bse2", "-bsp0", "-spd", "-y", archive.path, "--", path]
    }

    private func conflictFilesToReplace(
        entries: [String: Entry],
        selectedPaths: [String],
        destinationURL: URL,
        resolveConflict: @escaping ArchiveConflictResolver
    ) async throws -> [URL] {
        let selected = selectedPaths.compactMap { try? safeArchivePath($0) }
        let relevantEntries = entries.values
            .filter { entry in
                selected.isEmpty || selected.contains { path in
                    entry.path == path || entry.path.hasPrefix(path + "/")
                }
            }
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

    private func immediateChildName(path: String, parent: String) -> String? {
        if parent.isEmpty {
            guard !path.isEmpty else { return nil }
            return String(path.split(separator: "/", maxSplits: 1).first ?? "")
        }
        let prefix = parent + "/"
        guard path.hasPrefix(prefix) else { return nil }
        let remainder = String(path.dropFirst(prefix.count))
        guard !remainder.isEmpty else { return nil }
        return String(remainder.split(separator: "/", maxSplits: 1).first ?? "")
    }

    private func safeArchivePath(_ raw: String) throws -> String {
        try SevenZipListingParser.safePath(raw)
    }

    private func normalized(_ path: String) -> String {
        SevenZipListingParser.normalized(path)
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
        case .nestedArchive: "Nested"
        }
    }

    private func ensureAvailableSpace(for bytes: Int64, at url: URL) throws {
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let available = values.volumeAvailableCapacityForImportantUsage else { return }
        guard available > bytes + 536_870_912 else { throw ArchiveEngineError.insufficientSpace }
    }

    private func propagateQuarantine(from source: URL, to destination: URL) {
        guard let sourceValues = try? source.resourceValues(forKeys: [.quarantinePropertiesKey]),
              let properties = sourceValues.quarantineProperties else { return }
        var destinationValues = URLResourceValues()
        destinationValues.quarantineProperties = properties
        var destination = destination
        try? destination.setResourceValues(destinationValues)
    }

    private nonisolated static func locateHelper() -> URL? {
        if let override = ProcessInfo.processInfo.environment["ZFORGE_7ZZ_PATH"] {
            return URL(fileURLWithPath: override)
        }
        if let bundled = Bundle.main.url(forAuxiliaryExecutable: "7zz") {
            return bundled
        }
        #if DEBUG
        let development = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("7z2602-mac/7zz")
        if FileManager.default.fileExists(atPath: development.path) { return development }
        #endif
        return nil
    }
}
