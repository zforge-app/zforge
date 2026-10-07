import Foundation

/// Only completed, authorized indexes qualify for cross-process reuse.
nonisolated struct TagIndexSnapshot: Codable, Sendable {
    // Earlier checkpoints can omit Unicode-boundary items or advance cursors
    // through an alias stream that never watched the physical directory. One
    // rebuild is required; subsequent version-4 checkpoints remain reusable.
    static let currentVersion = 4
    var version = currentVersion
    let scopes: [TagJournal.Scope]
    let cursors: [String: UInt64]
    let records: TaggedFileScanner.Batch
    var deferredPaths: [String] = []
    var complete: Bool { deferredPaths.isEmpty }

    func matches(_ current: [TagJournal.Scope]) -> Bool {
        version == Self.currentVersion && current.allSatisfy { scopes.contains($0) }
            && current.allSatisfy { scope in
                guard let cursor = cursors[scope.path] else { return false }
                return cursor > 0 && cursor < UInt64.max
            }
    }
}

/// Encoding and disk access are serialized away from the main actor. An atomic
/// replacement leaves the previous complete checkpoint intact if interrupted.
actor TagIndexStore {
    static let standard = TagIndexStore(url: FileManager.default.urls(for: .applicationSupportDirectory,
        in: .userDomainMask)[0].appendingPathComponent("Zforge/VisibleTagIndex-v1.json"))
    let url: URL
    init(url: URL) { self.url = url }

    func load() -> TagIndexSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TagIndexSnapshot.self, from: data)
    }

    @discardableResult
    func save(_ snapshot: TagIndexSnapshot) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            return true
        } catch { return false }
    }
}
