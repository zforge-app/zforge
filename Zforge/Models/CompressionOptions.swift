import Foundation

nonisolated enum CompressionMethod: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case lzma2
    case lzma
    case deflate
    case deflate64
    case bzip2
    case copy

    var id: Self { self }

    var titleKey: String.LocalizationValue {
        switch self {
        case .automatic: "Automatic"
        case .lzma2: "LZMA2"
        case .lzma: "LZMA"
        case .deflate: "Deflate"
        case .deflate64: "Deflate64"
        case .bzip2: "BZip2"
        case .copy: "Store"
        }
    }

    var switchValue: String? {
        switch self {
        case .automatic: nil
        case .lzma2: "LZMA2"
        case .lzma: "LZMA"
        case .deflate: "Deflate"
        case .deflate64: "Deflate64"
        case .bzip2: "BZip2"
        case .copy: "Copy"
        }
    }
}

nonisolated enum ZIPEncryption: String, CaseIterable, Codable, Identifiable, Sendable {
    case aes256
    case zipCrypto

    var id: Self { self }
    var titleKey: String.LocalizationValue { self == .aes256 ? "AES-256" : "ZipCrypto" }
    var switchValue: String { self == .aes256 ? "AES256" : "ZipCrypto" }
}

/// A profile contains no secret. The password is supplied for one operation or held only in memory.
nonisolated struct CompressionOptions: Codable, Equatable, Sendable {
    var format: ArchiveCompressionFormat = .zip
    var level: Int = 5
    var method: CompressionMethod = .automatic
    var dictionaryMB: Int? = nil
    var fastBytes: Int? = nil
    var solid: Bool = true
    var threads: Int? = nil
    var requiresPassword: Bool = false
    var encryptFileNames: Bool = true
    var zipEncryption: ZIPEncryption = .aes256

    static let dictionaryChoices = [1, 2, 4, 8, 16, 32, 64, 128, 256]
    static let fastBytesChoices = [32, 64, 128, 273]
    static let levelChoices = [0, 1, 3, 5, 7, 9]

    var availableMethods: [CompressionMethod] {
        switch format {
        case .sevenZip: [.automatic, .lzma2, .lzma, .bzip2, .copy]
        case .zip: [.automatic, .deflate, .deflate64, .bzip2, .copy]
        case .tar, .xz, .bzip2, .gzip, .wim: [.automatic]
        }
    }

    var supportsLevel: Bool { format != .tar && format != .wim }
    var supportsDictionary: Bool {
        format == .xz || (format == .sevenZip && [.automatic, .lzma, .lzma2].contains(method))
    }
    var supportsFastBytes: Bool {
        (format == .sevenZip && [.automatic, .lzma, .lzma2].contains(method))
            || (format == .zip && [.automatic, .deflate, .deflate64].contains(method))
    }
    var supportsThreads: Bool { [.sevenZip, .zip, .xz].contains(format) }
    var supportsPassword: Bool { format == .sevenZip || format == .zip }

    func normalized() -> Self {
        var result = self
        result.level = Self.levelChoices.contains(level) ? level : 5
        if !availableMethods.contains(method) { result.method = .automatic }
        if !result.supportsDictionary || !Self.dictionaryChoices.contains(dictionaryMB ?? 0) {
            result.dictionaryMB = nil
        }
        if !result.supportsFastBytes || !Self.fastBytesChoices.contains(fastBytes ?? 0) {
            result.fastBytes = nil
        }
        if !result.supportsThreads || !(1...32).contains(threads ?? 0) { result.threads = nil }
        if !result.supportsPassword {
            result.requiresPassword = false
            result.encryptFileNames = false
        }
        return result
    }

    /// The level names shown by the profile editors, by 7-Zip level.
    static func levelTitleKey(_ level: Int) -> String.LocalizationValue {
        switch level {
        case 0: "Store"
        case 1: "Fastest"
        case 3: "Fast"
        case 7: "Maximum"
        case 9: "Ultra"
        default: "Normal"
        }
    }

    /// The line under a profile's name in Settings ▸ Compression: format, then the level and
    /// method the format offers, then solid mode and password protection when they apply
    /// (“7z · Normal · LZMA2 · Solid · Password”).
    func summary(locale: Locale) -> String {
        let options = normalized()
        var parts = [options.format.title(locale: locale)]
        if options.supportsLevel { parts.append(AppLocalization.string(Self.levelTitleKey(options.level), locale: locale)) }
        if options.availableMethods.count > 1 && options.method != .automatic {
            parts.append(AppLocalization.string(options.method.titleKey, locale: locale))
        }
        if options.format == .sevenZip && options.solid { parts.append(AppLocalization.string("Solid", locale: locale)) }
        if options.requiresPassword { parts.append(AppLocalization.string("Password", locale: locale)) }
        return parts.joined(separator: " · ")
    }
}

nonisolated struct CompressionProfile: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var options: CompressionOptions

    init(id: UUID = UUID(), name: String, options: CompressionOptions) {
        self.id = id
        self.name = name
        self.options = options.normalized()
    }
}

extension ArchiveCompressionFormat {
    nonisolated var nativeHandlerName: String {
        switch self {
        case .sevenZip: "7z"
        case .zip: "zip"
        case .tar: "tar"
        case .xz: "xz"
        case .bzip2: "bzip2"
        case .gzip: "gzip"
        case .wim: "wim"
        }
    }
}

extension CompressionOptions {
    /// Native ISetProperties values, independent of CLI argument spelling.
    nonisolated func nativeProperties(password: String?) throws -> [String: NSObject] {
        let value = normalized()
        if value.requiresPassword && password?.isEmpty != false { throw ArchiveEngineError.passwordRequired }
        var properties: [String: NSObject] = [:]
        if value.supportsLevel { properties["x"] = NSNumber(value: value.level) }
        if let method = value.method.switchValue { properties[value.format == .sevenZip ? "0" : "m"] = method as NSString }
        if let dictionary = value.dictionaryMB { properties["d"] = "\(dictionary)m" as NSString }
        if let fastBytes = value.fastBytes { properties["fb"] = NSNumber(value: fastBytes) }
        if value.format == .sevenZip { properties["s"] = NSNumber(value: value.solid) }
        if let threads = value.threads { properties["mt"] = NSNumber(value: threads) }
        if value.requiresPassword {
            if value.format == .sevenZip { properties["he"] = NSNumber(value: value.encryptFileNames) }
            if value.format == .zip { properties["em"] = value.zipEncryption.switchValue as NSString }
        }
        return properties
    }
}
