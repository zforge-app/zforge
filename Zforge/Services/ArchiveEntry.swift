import Foundation

/// Backend-independent metadata used by archive sessions.
nonisolated struct ArchiveEntry: Sendable {
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

/// Shared path rules; native and CLI metadata use the same projection.
nonisolated enum ArchivePathPolicy {
    static func safePath(_ raw: String) throws -> String {
        guard !raw.utf8.contains(0) else { throw ArchiveEngineError.unsafePath }
        let separatorsNormalized = raw.replacingOccurrences(of: "\\", with: "/")
        guard !separatorsNormalized.hasPrefix("/"),
              !separatorsNormalized.split(separator: "/").contains("..") else {
            throw ArchiveEngineError.unsafePath
        }
        return normalized(separatorsNormalized)
    }

    static func normalized(_ path: String) -> String {
        path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

}

extension ArchiveEntry {
    nonisolated static func withParents(_ original: [String: Self]) -> [String: Self] {
        var entries = original
        for path in original.keys {
            let components = path.split(separator: "/")
            guard components.count > 1 else { continue }
            for count in 1..<components.count {
                let parent = components.prefix(count).joined(separator: "/")
                if entries[parent] == nil {
                    entries[parent] = Self(path: parent, isDirectory: true, size: nil, packedSize: nil,
                        modified: nil, created: nil, accessed: nil, encrypted: false,
                        checksum: nil, method: nil, attributes: nil)
                }
            }
        }
        return entries
    }
}
