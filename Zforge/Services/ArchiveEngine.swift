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
    func setPassword(_ password: String?, for sessionID: UUID) async
    func closeSession(_ sessionID: UUID) async
    func closeAllSessions() async
    func cancelAllOperations() async
    func cleanupStaleSessions() async
}

extension ArchiveServing {
    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult {
        try await openArchive(at: url, password: password, policy: .standard)
    }
}

actor SevenZipArchiveEngine: ArchiveServing {
    private struct Entry: Sendable {
        let path: String
        let isDirectory: Bool
        let size: Int64?
        let packedSize: Int64?
        let modified: Date?
        let created: Date?
        let accessed: Date?
        let encrypted: Bool
        let checksum: String?
        let method: String?
        let attributes: String?
    }

    private struct ArchiveRecord: Sendable {
        let id: UUID
        let fileURL: URL
        let displayName: String
        let entries: [String: Entry]
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
        sessionsRoot = fileManager.temporaryDirectory
            .appendingPathComponent("Zforge", isDirectory: true)
            .appendingPathComponent("ArchiveSessions", isDirectory: true)
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
            let archive = try await listArchive(at: stagedURL, displayName: url.lastPathComponent, password: password)
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

    func openNestedArchive(item: BrowserItem, password: String?) async throws -> ArchiveOpenResult {
        guard case let .archive(address) = item.location else { throw ArchiveEngineError.itemNotFound }
        guard address.canOpenNestedArchive else { throw ArchiveEngineError.nestedArchiveNotAllowed }
        let url = try await materialize(item: item, purpose: .nestedArchive, automaticLimit: nil)
        let archive = try await listArchive(at: url, displayName: item.name, password: password)
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

        let result = try await processRunner.run(
            arguments: extractionArguments(archive: archive.fileURL, path: address.internalPath),
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

    private func listArchive(at url: URL, displayName: String, password: String?) async throws -> ArchiveRecord {
        let result = try await processRunner.run(
            arguments: listingArguments(archive: url),
            password: password,
            standardOutputURL: nil,
            workingDirectory: url.deletingLastPathComponent()
        )
        try validate(result, passwordWasProvided: password != nil)
        let output = String(decoding: result.stdout, as: UTF8.self)
        let entries = try parseListing(output)
        guard !entries.isEmpty else {
            throw ArchiveEngineError.invalidArchive(AppLocalization.string("archive.empty_or_unsupported"))
        }
        return ArchiveRecord(id: UUID(), fileURL: url, displayName: displayName, entries: entries)
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

    private func parseListing(_ output: String) throws -> [String: Entry] {
        var records: [[String: String]] = []
        var current: [String: String] = [:]
        for line in output.components(separatedBy: .newlines) {
            if line.isEmpty {
                if !current.isEmpty { records.append(current); current = [:] }
                continue
            }
            guard let range = line.range(of: " = ") else { continue }
            current[String(line[..<range.lowerBound])] = String(line[range.upperBound...])
        }
        if !current.isEmpty { records.append(current) }

        var entries: [String: Entry] = [:]
        for record in records {
            guard let rawPath = record["Path"], record["Type"] == nil else { continue }
            let path = try safeArchivePath(rawPath)
            guard !path.isEmpty else { continue }
            let isDirectory = record["Folder"] == "+" || record["Attributes"]?.first == "D" || rawPath.hasSuffix("/")
            entries[path] = Entry(
                path: path,
                isDirectory: isDirectory,
                size: Int64(record["Size"] ?? ""),
                packedSize: Int64(record["Packed Size"] ?? ""),
                modified: parseDate(record["Modified"]),
                created: parseDate(record["Created"]),
                accessed: parseDate(record["Accessed"]),
                encrypted: record["Encrypted"] == "+",
                checksum: record["CRC"],
                method: record["Method"],
                attributes: record["Attributes"]
            )
        }

        for path in Array(entries.keys) {
            let components = path.split(separator: "/").map(String.init)
            guard components.count > 1 else { continue }
            for count in 1..<components.count {
                let parent = components.prefix(count).joined(separator: "/")
                if entries[parent] == nil {
                    entries[parent] = Entry(
                        path: parent,
                        isDirectory: true,
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
            }
        }
        return entries
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

    private func extractionArguments(archive: URL, path: String) -> [String] {
        ["x", "-so", "-sccUTF-8", "-bso0", "-bse2", "-bsp0", "-spd", "-y", archive.path, "--", path]
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
        let value = normalized(raw.replacingOccurrences(of: "\\", with: "/"))
        guard !value.hasPrefix("/"), !value.split(separator: "/").contains("..") else {
            throw ArchiveEngineError.unsafePath
        }
        return value
    }

    private func normalized(_ path: String) -> String {
        path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: String(value.prefix(19)))
    }

    private func sanitizedFileName(_ name: String) -> String {
        let value = name.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\0", with: "_")
        return value.isEmpty ? "Archive Item" : value
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
