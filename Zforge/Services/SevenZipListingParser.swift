import Foundation

/// The textual `7zz -slt` protocol is isolated from archive sessions and UI.
nonisolated enum SevenZipListingParser {
    struct Entry: Sendable {
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

    static func parse(_ output: String) throws -> [String: Entry] {
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
            let path = try safePath(rawPath)
            guard !path.isEmpty else { continue }
            let isDirectory = record["Folder"] == "+"
                || record["Attributes"]?.first == "D"
                || rawPath.hasSuffix("/")
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
                        path: parent, isDirectory: true, size: nil, packedSize: nil,
                        modified: nil, created: nil, accessed: nil, encrypted: false,
                        checksum: nil, method: nil, attributes: nil
                    )
                }
            }
        }
        return entries
    }

    static func safePath(_ raw: String) throws -> String {
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

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: String(value.prefix(19)))
    }
}
