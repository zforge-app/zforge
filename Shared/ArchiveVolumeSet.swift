import Foundation

// Shared by the app and its Finder extension (ZF-83): every volume of a split archive stands
// for the whole set, so the app, the engine, the Finder menu and the intents must agree on
// which files form a set and which one opens it.

/// How a split archive names its volumes.
nonisolated enum ArchiveVolumeScheme: String, Sendable, Hashable, Codable {
    /// `name.7z.001`, `name.7z.002`…: byte slices of one 7z archive.
    case sevenZipNumbered
    /// `name.zip.001`, `name.zip.002`…: byte slices of one ZIP archive.
    case zipNumbered
    /// WinZip-style `name.z01`, `name.z02`… with `name.zip` last (disk numbers inside the ZIP).
    case zipSpanned
    /// `name.part1.rar`, `name.part2.rar`…
    case rarParts
    /// `name.rar`, then `name.r00`, `name.r01`…
    case rarLegacy

    /// Whether the volumes are byte slices of one archive that the engine reads as one stream.
    var isNumbered: Bool { self == .sevenZipNumbered || self == .zipNumbered }

    /// The extension of a whole archive of the set's format, whose icon every volume shows (D-104).
    var formatExtension: String {
        switch self {
        case .sevenZipNumbered: "7z"
        case .zipNumbered, .zipSpanned: "zip"
        case .rarParts, .rarLegacy: "rar"
        }
    }
}

/// What a file name says about its place in a split archive.
nonisolated struct ArchiveVolumeName: Sendable, Hashable {
    let scheme: ArchiveVolumeScheme
    /// The name before the volume suffix, in its original case (`Backup` for `Backup.7z.002`).
    let stem: String
    /// Position in reading order: 1 for the first numbered volume, `part1` and `.z01`; 0 for a
    /// legacy `.rar`, whose `.r00` is 1; `Int.max` for the `.zip` that ends a spanned set.
    let number: Int
    /// Digits written in the number (`001` → 3, `part01` → 2), kept when naming siblings.
    let digits: Int
    /// The text between the stem and the number, in its original case (`7z`, `zip`, `part`,
    /// `z`, `r`), and the trailing `rar` of a `partN.rar` name.
    let marker: String
    let trailer: String

    /// Whether this volume is the one the set is opened from.
    var opensSet: Bool {
        switch scheme {
        case .sevenZipNumbered, .zipNumbered, .rarParts: number == 1
        case .zipSpanned: number == Int.max
        case .rarLegacy: number == 0
        }
    }

    /// Parses a volume name. A plain `name.zip` or `name.rar` is a split set's last or first
    /// volume only when its `.z01` or `.r00` sibling exists, which the name alone cannot say:
    /// `firstSiblingExists` answers it (it is asked only for those two names).
    static func parse(_ name: String, firstSiblingExists: ((String) -> Bool)? = nil) -> ArchiveVolumeName? {
        // Cheap rejection first: names are classified for every row of every listing.
        let ext = (name as NSString).pathExtension.lowercased()
        guard let lead = ext.first else { return nil }
        let digitsAfterLead = ext.dropFirst().allSatisfy(\.isNumber) && ext.count >= 3
        guard ext.allSatisfy(\.isNumber) || ext == "rar" || ext == "zip"
                || ((lead == "z" || lead == "r") && digitsAfterLead) else { return nil }
        if ext == "zip" && firstSiblingExists == nil { return nil }
        let ns = name as NSString
        let full = NSRange(location: 0, length: ns.length)
        func groups(_ regex: NSRegularExpression) -> [String]? {
            guard let match = regex.firstMatch(in: name, range: full) else { return nil }
            return (1..<match.numberOfRanges).map { ns.substring(with: match.range(at: $0)) }
        }
        if let parts = groups(Self.numbered), let number = Int(parts[2]), number > 0 {
            let scheme: ArchiveVolumeScheme = parts[1].lowercased() == "7z" ? .sevenZipNumbered : .zipNumbered
            return ArchiveVolumeName(scheme: scheme, stem: parts[0], number: number, digits: parts[2].count,
                                     marker: parts[1], trailer: "")
        }
        if let parts = groups(Self.rarPart), let number = Int(parts[2]), number > 0 {
            return ArchiveVolumeName(scheme: .rarParts, stem: parts[0], number: number, digits: parts[2].count,
                                     marker: parts[1], trailer: parts[3])
        }
        if let parts = groups(Self.spannedMember), let number = Int(parts[2]), number > 0 {
            return ArchiveVolumeName(scheme: .zipSpanned, stem: parts[0], number: number, digits: parts[2].count,
                                     marker: parts[1], trailer: "")
        }
        if let parts = groups(Self.legacyMember), let number = Int(parts[2]) {
            return ArchiveVolumeName(scheme: .rarLegacy, stem: parts[0], number: number + 1, digits: parts[2].count,
                                     marker: parts[1], trailer: "")
        }
        guard let firstSiblingExists, let parts = groups(Self.plainLast) else { return nil }
        let isZip = parts[1].lowercased() == "zip"
        let marker = isZip ? (parts[1].first == "Z" ? "Z" : "z") : (parts[1].first == "R" ? "R" : "r")
        let sibling = parts[0] + "." + marker + (isZip ? "01" : "00")
        guard firstSiblingExists(sibling) else { return nil }
        return ArchiveVolumeName(scheme: isZip ? .zipSpanned : .rarLegacy, stem: parts[0],
                                 number: isZip ? Int.max : 0, digits: 2, marker: marker, trailer: "")
    }

    /// Parses `url`'s name, looking for the `.z01`/`.r00` sibling of a plain `.zip`/`.rar`
    /// with one `stat` (the volume's file system decides the case match).
    static func parse(_ url: URL) -> ArchiveVolumeName? {
        let folder = url.deletingLastPathComponent()
        return parse(url.lastPathComponent) { sibling in
            FileManager.default.fileExists(atPath: folder.appendingPathComponent(sibling).path)
        }
    }

    /// The name of volume `number` of this volume's set, written like this one.
    func siblingName(number: Int) -> String {
        switch scheme {
        case .sevenZipNumbered, .zipNumbered:
            return stem + "." + marker + "." + Self.padded(number, digits)
        case .rarParts:
            return stem + "." + marker + Self.padded(number, digits) + "." + trailer
        case .zipSpanned:
            if number == Int.max { return stem + "." + (marker == "Z" ? "ZIP" : "zip") }
            return stem + "." + marker + Self.padded(number, max(digits, 2))
        case .rarLegacy:
            if number == 0 { return stem + "." + (marker == "R" ? "RAR" : "rar") }
            return stem + "." + marker + Self.padded(number - 1, max(digits, 2))
        }
    }

    /// The name of the volume this set is opened from.
    var openingName: String {
        switch scheme {
        case .sevenZipNumbered, .zipNumbered, .rarParts: siblingName(number: 1)
        case .zipSpanned: siblingName(number: Int.max)
        case .rarLegacy: siblingName(number: 0)
        }
    }

    /// Whether `other` belongs to the same set (same scheme and stem, ignoring case).
    func isSibling(of other: ArchiveVolumeName) -> Bool {
        scheme == other.scheme && stem.lowercased() == other.stem.lowercased()
    }

    private static func padded(_ number: Int, _ digits: Int) -> String {
        let text = String(number)
        return text.count >= digits ? text : String(repeating: "0", count: digits - text.count) + text
    }

    private static func regex(_ pattern: String) -> NSRegularExpression {
        // The patterns are literals: a failure is a programming error caught by every test.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private static let numbered = regex(#"^(.+)\.(7z|zip)\.(\d{3,})$"#)
    private static let rarPart = regex(#"^(.+)\.(part)(\d+)\.(rar)$"#)
    private static let spannedMember = regex(#"^(.+)\.(z)(\d{2,})$"#)
    private static let legacyMember = regex(#"^(.+)\.(r)(\d{2,})$"#)
    private static let plainLast = regex(#"^(.+)\.(zip|rar)$"#)
}

/// The volumes of one split archive found in a folder.
nonisolated struct ArchiveVolumeSet: Sendable, Hashable {
    let scheme: ArchiveVolumeScheme
    let folder: URL
    /// The volumes present, in reading order.
    let members: [URL]
    /// The volume the set is opened from (it may be missing).
    let opening: URL
    /// Names of the volumes missing before the last one present, the opening volume included.
    let missing: [String]
    /// The name a volume added after the last present one would have.
    let successorName: String?

    var stem: String { ArchiveVolumeName.parse(opening.lastPathComponent)?.stem
        ?? opening.deletingPathExtension().lastPathComponent }

    /// The set `url` belongs to, from the names in its folder; `nil` for a whole archive.
    static func resolve(_ url: URL, fileManager: FileManager = .default) -> ArchiveVolumeSet? {
        let folder = url.deletingLastPathComponent()
        guard let siblings = try? fileManager.contentsOfDirectory(atPath: folder.path) else { return nil }
        return resolve(name: url.lastPathComponent, folder: folder, siblings: siblings)
    }

    /// The set the file `name` belongs to among `siblings` (names in `folder`, `name` included).
    static func resolve(name: String, folder: URL, siblings: [String]) -> ArchiveVolumeSet? {
        let lowercasedSiblings = Set(siblings.map { $0.lowercased() })
        guard let volume = ArchiveVolumeName.parse(name, firstSiblingExists: { lowercasedSiblings.contains($0.lowercased()) })
        else { return nil }
        var found: [Int: String] = [:]
        for sibling in siblings {
            guard let parsed = ArchiveVolumeName.parse(sibling, firstSiblingExists: { _ in true }),
                  parsed.isSibling(of: volume) else { continue }
            // A plain `.zip`/`.rar` counts only for the scheme that ends or starts with it.
            if parsed.number == Int.max || parsed.number == 0 {
                guard parsed.scheme == volume.scheme else { continue }
            }
            if found[parsed.number] == nil { found[parsed.number] = sibling }
        }
        found[volume.number] = name
        let numbers = found.keys.sorted()
        let template = found[numbers.last { $0 != Int.max } ?? volume.number]
            .flatMap { ArchiveVolumeName.parse($0, firstSiblingExists: { _ in true }) } ?? volume
        var missing: [String] = []
        let expected: [Int]
        switch volume.scheme {
        case .sevenZipNumbered, .zipNumbered, .rarParts:
            expected = Array(1...(numbers.last ?? 1))
        case .zipSpanned:
            let lastMember = numbers.last { $0 != Int.max } ?? 0
            expected = (lastMember > 0 ? Array(1...lastMember) : []) + [Int.max]
        case .rarLegacy:
            expected = Array(0...(numbers.last ?? 0))
        }
        for number in expected where found[number] == nil {
            missing.append(template.siblingName(number: number))
        }
        let opening = found[ArchiveVolumeName.openingNumber(volume.scheme)] ?? template.openingName
        let lastNumbered = numbers.last { $0 != Int.max } ?? 0
        let successor: String? = switch volume.scheme {
        case .sevenZipNumbered, .zipNumbered, .rarParts, .rarLegacy: template.siblingName(number: (numbers.last ?? 0) + 1)
        case .zipSpanned: template.siblingName(number: lastNumbered + 1)
        }
        return ArchiveVolumeSet(
            scheme: volume.scheme, folder: folder,
            members: numbers.compactMap { found[$0] }.map { folder.appendingPathComponent($0) },
            opening: folder.appendingPathComponent(opening), missing: missing, successorName: successor
        )
    }
}

nonisolated extension ArchiveVolumeName {
    /// A key shared by every volume of one split archive (its folder and opening volume),
    /// or the file's own path for a whole archive.
    static func setKey(for url: URL) -> String {
        guard let volume = parse(url) else { return url.standardizedFileURL.path }
        return url.deletingLastPathComponent().standardizedFileURL.path + "/" + volume.openingName.lowercased()
    }

    /// The URLs with one volume per split archive, the first one given (ZF-83).
    static func onePerSet(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { seen.insert(setKey(for: $0)).inserted }
    }

    static func openingNumber(_ scheme: ArchiveVolumeScheme) -> Int {
        switch scheme {
        case .sevenZipNumbered, .zipNumbered, .rarParts: 1
        case .zipSpanned: Int.max
        case .rarLegacy: 0
        }
    }
}
