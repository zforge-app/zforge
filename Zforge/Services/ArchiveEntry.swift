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
    /// Position in the native listing; nil for parents synthesized from paths.
    var nativeIndex: UInt32? = nil
    /// Set when the entry shares a solid block with other files (decoding starts before it).
    var solidBlock: ArchiveSolidBlock? = nil
}

/// A block whose decoding must start at its beginning: a 7z folder, a CAB folder, a RAR
/// solid run or a WIM/ESD solid resource holding several files, a compressed tar or a
/// single-file compressed stream (the whole archive).
nonisolated struct ArchiveSolidBlock: Sendable, Hashable {
    /// Compressed size of the block, when the handler reports one.
    let packedSize: Int64?
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

/// Selected archive items: a path matches when it is a selected item or one of its descendants.
/// Equivalent to `selected.contains { path == $0 || path.hasPrefix($0 + "/") }`, in time
/// proportional to the path depth rather than to the number of selected items.
nonisolated struct ArchivePathSelection {
    private let paths: Set<String>

    init(_ paths: [String]) { self.paths = Set(paths) }

    func contains(_ path: String) -> Bool {
        if paths.contains(path) { return true }
        // A matching prefix always ends right before a "/" scalar; confirm each candidate
        // with the original predicate so String comparison semantics stay identical.
        for index in path.utf8.indices where path.utf8[index] == UInt8(ascii: "/") {
            let prefix = String(decoding: path.utf8[..<index], as: UTF8.self)
            if let match = paths.firstIndex(of: prefix), path.hasPrefix(paths[match] + "/") { return true }
        }
        return false
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


extension ArchiveEntry {
    /// Parent path to the paths of its immediate children, built once per listing so that
    /// listing a folder costs its children rather than every entry. A path is a child of
    /// `parent` exactly when it is `parent + "/" + name` (or `name` at the root) for a single
    /// component `name`; normalized folder paths therefore find the same children as scanning
    /// every entry did.
    nonisolated static func childIndex(of entries: [String: Self]) -> [String: [String]] {
        var children: [String: [String]] = [:]
        for path in entries.keys where !path.isEmpty {
            if let separator = path.lastIndex(of: "/") {
                let name = path[path.index(after: separator)...]
                guard !name.isEmpty else { continue }
                children[String(path[..<separator]), default: []].append(path)
            } else {
                children["", default: []].append(path)
            }
        }
        return children
    }
}

extension ArchiveEntry {
    /// Built once per listing. Explicit empty directories do not imply files.
    nonisolated static func directoriesContainingFiles(in entries: [String: Self]) -> Set<String> {
        var directories: Set<String> = []
        for entry in entries.values where !entry.isDirectory {
            var components = entry.path.split(separator: "/")
            components.removeLast()
            while !components.isEmpty {
                directories.insert(components.joined(separator: "/"))
                components.removeLast()
            }
        }
        return directories
    }
}
