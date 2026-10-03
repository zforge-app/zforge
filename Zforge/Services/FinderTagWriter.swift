import Darwin
import Foundation

/// Applies only explicitly edited names, retaining each item's other Finder tags.
nonisolated enum FinderTagWriter {
    static func apply(additions: [String: Int], removals: Set<String>, to url: URL) throws {
        guard additions.keys.allSatisfy({ !$0.isEmpty && !$0.contains("\n") }) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let metadata = try read(at: url)
        var colors = metadata.colors
        var names = metadata.names.filter { !removals.contains($0) }
        for name in removals { colors.removeValue(forKey: name) }
        for name in additions.keys.sorted() {
            if !names.contains(name) { names.append(name) }
            let index = additions[name]!
            colors[name] = (1...7).contains(index) ? index : 0
        }
        let values = names.map { "\($0)\n\(colors[$0]!)" }
        let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
        try url.withUnsafeFileSystemRepresentation { path in
            guard let path else { throw CocoaError(.fileWriteInvalidFileName) }
            let result = data.withUnsafeBytes {
                setxattr(path, FinderTagMetadata.attribute, $0.baseAddress, data.count, 0, 0)
            }
            if result != 0 { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        }
    }

    private static func read(at url: URL) throws -> (names: [String], colors: [String: Int]) {
        try url.withUnsafeFileSystemRepresentation { path in
            guard let path else { throw CocoaError(.fileReadInvalidFileName) }
            let size = getxattr(path, FinderTagMetadata.attribute, nil, 0, 0, 0)
            if size < 0 {
                if errno == ENOATTR { return ([], [:]) }
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            var bytes = [UInt8](repeating: 0, count: size)
            let count = bytes.withUnsafeMutableBytes {
                getxattr(path, FinderTagMetadata.attribute, $0.baseAddress, size, 0, 0)
            }
            guard count >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
            let data = Data(bytes.prefix(count))
            // Refuse to overwrite unreadable metadata.
            guard let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String] else {
                throw CocoaError(.fileReadCorruptFile)
            }
            var names: [String] = []
            for value in values {
                let name = String(value.split(separator: "\n", maxSplits: 1).first ?? "")
                if !name.isEmpty, !names.contains(name) { names.append(name) }
            }
            return (names, FinderTagMetadata.colorIndexes(in: data))
        }
    }
}

struct TagEditingRequest: Identifiable {
    let id = UUID()
    let items: [BrowserItem]
}
