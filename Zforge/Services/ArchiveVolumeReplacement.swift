import Darwin
import Foundation

/// Replaces the volumes of a split archive with a new set written beside them (ZF-83 stage 3).
///
/// No file system replaces several files atomically. The new volumes are written and validated
/// in a hidden staging folder in the set's folder (same volume), a journal recording every
/// file's identity is written there, and each volume is then swapped into place
/// (`renamex_np(RENAME_SWAP)`, or two renames where the file system cannot swap); the old
/// volumes end in the staging folder until the last swap. A failure undoes the swaps already
/// made. A crash leaves the journal: the next time the set is opened, read or written,
/// `recover(in:)` puts the old set back unless the journal says the replacement had completed.
/// Another app may see a mixed set for the instant of the swaps; Zforge never reads one, since
/// the set's fingerprint refuses it.
nonisolated struct ArchiveVolumeReplacement {
    struct Journal: Codable, Equatable {
        struct Volume: Codable, Equatable {
            /// Name in the set's folder.
            let name: String
            /// File identifiers of the old volume (nil for a volume the new set adds) and of
            /// the new one (nil for an old volume the new set drops).
            let oldFile: UInt64?
            let newFile: UInt64?
        }
        var volumes: [Volume]
        var completed: Bool
    }

    static let stagingPrefix = ".zforge-volumes-"
    static let journalName = "journal.json"

    let folder: URL
    let staging: URL
    /// The current volumes, in reading order.
    let old: [URL]
    /// The new volumes, in the staging folder, in reading order.
    let new: [URL]
    /// The names the new volumes take in the folder: the old names where they replace one,
    /// then names written like the old ones.
    let names: [String]

    /// Test hook: called before each step of the swap with its index; throwing stops there,
    /// as a failure would.
    var beforeStep: ((Int) throws -> Void)? = nil
    /// Test hook: called after the journal is written and before the swaps, so that a crash
    /// can be simulated by throwing `SimulatedCrash` (nothing is undone then).
    var simulatesCrash: ((Int) -> Bool)? = nil

    struct SimulatedCrash: Error {}

    init(folder: URL, staging: URL, old: [URL], new: [URL]) throws {
        self.folder = folder
        self.staging = staging
        self.old = old
        self.new = new
        guard let template = old.lazy.compactMap({ ArchiveVolumeName.parse($0.lastPathComponent, firstSiblingExists: { _ in true }) }).first
        else { throw ArchiveEngineError.updateUnsupported }
        names = new.indices.map { index in
            index < old.count ? old[index].lastPathComponent : template.siblingName(number: index + 1)
        }
    }

    /// Swaps the new volumes into place, keeping the old file metadata a replacement keeps
    /// (permissions, creation date, Finder tags). Removes the staging folder on success.
    func commit(fileManager: FileManager = .default) throws {
        for (index, url) in new.enumerated() {
            try Self.copyMetadata(from: old[min(index, old.count - 1)], to: url)
        }
        var journal = Journal(volumes: [], completed: false)
        let count = max(old.count, new.count)
        for index in 0..<count {
            journal.volumes.append(.init(
                name: index < new.count ? names[index] : old[index].lastPathComponent,
                oldFile: index < old.count ? try Self.fileIdentifier(old[index]) : nil,
                newFile: index < new.count ? try Self.fileIdentifier(new[index]) : nil))
        }
        try Self.write(journal, to: staging)
        var done = 0
        do {
            for index in 0..<count {
                try beforeStep?(index)
                if simulatesCrash?(index) == true { throw SimulatedCrash() }
                let target = folder.appendingPathComponent(journal.volumes[index].name)
                if index < new.count && index < old.count {
                    try Self.swap(new[index], target, parking: staging.appendingPathComponent("old-\(index)"))
                } else if index < new.count {
                    try Self.rename(new[index], to: target, exclusive: true)
                } else {
                    try Self.rename(target, to: staging.appendingPathComponent("old-\(index)"), exclusive: true)
                }
                done = index + 1
            }
        } catch is SimulatedCrash {
            throw SimulatedCrash()
        } catch {
            Self.undo(journal, in: folder, staging: staging, upTo: done)
            throw error
        }
        journal.completed = true
        try? Self.write(journal, to: staging)
        try? fileManager.removeItem(at: staging)
    }

    /// Finishes or undoes interrupted replacements in `folder` (their staging folders).
    static func recover(in folder: URL, fileManager: FileManager = .default) {
        guard let names = try? fileManager.contentsOfDirectory(atPath: folder.path) else { return }
        for name in names where name.hasPrefix(stagingPrefix) {
            let staging = folder.appendingPathComponent(name)
            guard let data = try? Data(contentsOf: staging.appendingPathComponent(journalName)),
                  let journal = try? JSONDecoder().decode(Journal.self, from: data) else {
                // A write that never reached its swaps: only new, unpublished files.
                if isStale(staging) { try? fileManager.removeItem(at: staging) }
                continue
            }
            if !journal.completed { undo(journal, in: folder, staging: staging, upTo: journal.volumes.count) }
            try? fileManager.removeItem(at: staging)
        }
    }

    /// Puts the old volumes of the first `count` steps back, by file identity, so that it is
    /// right whichever step was interrupted.
    private static func undo(_ journal: Journal, in folder: URL, staging: URL, upTo count: Int) {
        let parked = (try? FileManager.default.contentsOfDirectory(at: staging, includingPropertiesForKeys: nil)) ?? []
        func parkedFile(_ identifier: UInt64?) -> URL? {
            guard let identifier else { return nil }
            return parked.first { (try? fileIdentifier($0)) == identifier }
        }
        for (index, volume) in journal.volumes.enumerated().prefix(count).reversed() {
            let target = folder.appendingPathComponent(volume.name)
            let current = try? fileIdentifier(target)
            if let newFile = volume.newFile, current == newFile {
                if let old = parkedFile(volume.oldFile) {
                    try? swap(old, target, parking: staging.appendingPathComponent("undone-\(index)"))
                } else {
                    try? rename(target, to: staging.appendingPathComponent("undone-\(index)"), exclusive: true)
                }
            } else if current == nil, let old = parkedFile(volume.oldFile) {
                try? rename(old, to: target, exclusive: true)
            }
        }
    }

    private static func isStale(_ staging: URL) -> Bool {
        guard let modified = try? staging.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        else { return true }
        return modified < Date(timeIntervalSinceNow: -24 * 3600)
    }

    private static func write(_ journal: Journal, to staging: URL) throws {
        let data = try JSONEncoder().encode(journal)
        try data.write(to: staging.appendingPathComponent(journalName), options: .atomic)
        // The journal must be on disk before any volume moves.
        let handle = try FileHandle(forReadingFrom: staging.appendingPathComponent(journalName))
        _ = fcntl(handle.fileDescriptor, F_FULLFSYNC)
        try handle.close()
    }

    static func fileIdentifier(_ url: URL) throws -> UInt64 {
        var status = stat()
        guard lstat(url.path, &status) == 0 else { throw ArchiveEngineError.itemNotFound }
        return UInt64(status.st_ino)
    }

    /// Puts `replacement` at `target`, the old `target` going to `parking`.
    private static func swap(_ replacement: URL, _ target: URL, parking: URL) throws {
        if renamex_np(replacement.path, target.path, UInt32(RENAME_SWAP)) == 0 {
            // The old file now has the replacement's name in the staging folder.
            try rename(replacement, to: parking, exclusive: true)
            return
        }
        guard errno == ENOTSUP || errno == EINVAL else { throw posixError(errno) }
        try rename(target, to: parking, exclusive: true)
        do {
            try rename(replacement, to: target, exclusive: true)
        } catch {
            try? rename(parking, to: target, exclusive: true)
            throw error
        }
    }

    private static func rename(_ source: URL, to destination: URL, exclusive: Bool) throws {
        let flags = exclusive ? UInt32(RENAME_EXCL) : 0
        guard renamex_np(source.path, destination.path, flags) == 0 else { throw posixError(errno) }
    }

    private static func posixError(_ code: Int32) -> Error {
        code == ENOSPC ? ArchiveEngineError.insufficientSpace
            : NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }

    private static func copyMetadata(from source: URL, to destination: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
        var kept: [FileAttributeKey: Any] = [:]
        if let permissions = attributes[.posixPermissions] { kept[.posixPermissions] = permissions }
        if let created = attributes[.creationDate] { kept[.creationDate] = created }
        if !kept.isEmpty { try FileManager.default.setAttributes(kept, ofItemAtPath: destination.path) }
        if let tags = try source.resourceValues(forKeys: [.tagNamesKey]).tagNames, !tags.isEmpty {
            try (destination as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
        }
    }
}
