import Foundation
import Testing
@testable import Zforge

@Suite("Application localization")
@MainActor
struct LocalizationTests {
    private nonisolated var applicationBundle: Bundle { Bundle(for: AppDelegate.self) }
    private nonisolated var auditIsOnMainThread: Bool { Thread.isMainThread }

    @Test("Settings offers system default and exactly the 21 requested localizations")
    func requestedLanguages() {
        #expect(AppLanguagePreference.allCases.count == 22)
    }

    @Test("Service strings use the requested language even when the system uses another", arguments: [
        ("ja", "開く"), ("zh-Hans", "打开"), ("zh-Hant", "打開"),
        ("de", "Öffnen"), ("nl", "Open"), ("sv", "Öppna"),
        ("hi", "खोलें"), ("bn", "খুলুন")
    ])
    func localizedOpen(identifier: String, expected: String) {
        #expect(AppLocalization.string("Open", locale: Locale(identifier: identifier), bundle: applicationBundle) == expected)
    }

    @Test("English archive errors display a readable message rather than a symbolic key")
    func readableEnglishError() {
        #expect(AppLocalization.string("archive.invalid_password", locale: Locale(identifier: "en"), bundle: applicationBundle) == "The password is incorrect.")
    }

    @Test("System resolution skips unsupported languages and preserves preference order")
    func preferredLanguageOrder() {
        #expect(AppLanguagePreference.resolve(preferredLanguages: ["ar-SA", "bn-BD", "en-US"]) == .bengali)
        #expect(AppLanguagePreference.resolve(preferredLanguages: ["nl-BE", "ja-JP"]) == .dutch)
        #expect(AppLanguagePreference.resolve(preferredLanguages: ["pt-PT", "es-MX"]) == .portugueseBrazil)
        #expect(AppLanguagePreference.resolve(preferredLanguages: ["ar-SA", "he-IL"]) == .english)
        #expect(AppLanguagePreference.resolve(preferredLanguages: []) == .english)
    }

    @Test("Regional Chinese preferences keep the correct writing system", arguments: [
        ("zh", "zh-Hans"), ("zh-CN", "zh-Hans"), ("zh-SG", "zh-Hans"),
        ("zh-TW", "zh-Hant"), ("zh-HK", "zh-Hant"), ("zh-MO", "zh-Hant"),
        ("zh-Hans-TW", "zh-Hans"), ("zh-Hant-CN", "zh-Hant"), ("zh_Hant_HK", "zh-Hant")
    ])
    func chineseScript(identifier: String, expected: String) {
        #expect(AppLanguagePreference.resolve(preferredLanguages: [identifier]).localizationIdentifier == expected)
        let expectedOpen = expected == "zh-Hans" ? "打开" : "打開"
        #expect(AppLocalization.string("Open", locale: Locale(identifier: identifier), bundle: applicationBundle) == expectedOpen)
    }

    @Test("Every explicit language survives reopening preferences", arguments: AppLanguagePreference.allCases)
    func languagePersistence(language: AppLanguagePreference) throws {
        let suite = "ZforgeLocalization-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.language == .system)
        preferences.language = language
        #expect(FileBrowserPreferences(defaults: defaults).language == language)
        #expect(defaults.string(forKey: AppLanguagePreference.defaultsKey) == language.rawValue)
    }

    @Test("Legacy saved preferences remain compatible and corrupt values fall back to system")
    func legacyPreferences() throws {
        let suite = "ZforgeLocalizationLegacy-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for (raw, expected) in [("english", AppLanguagePreference.english), ("portugueseBrazil", .portugueseBrazil), ("invalid", .system)] {
            defaults.set(raw, forKey: AppLanguagePreference.defaultsKey)
            #expect(FileBrowserPreferences(defaults: defaults).language == expected)
        }
    }

    @Test("All 21 localizations are bundled and preserve format arguments and intent parameters")
    @concurrent
    nonisolated func bundledCatalogCoverage() async throws {
        #expect(!auditIsOnMainThread, "The resource audit must not run on the main thread")
        let expectedIdentifiers: Set<String> = ["en", "pt-BR", "zh-Hans", "zh-Hant", "ja", "de", "fr", "es", "ko", "it", "ru", "pl", "uk", "tr", "th", "da", "cs", "nl", "sv", "hi", "bn"]
        #expect(Set(AppLanguagePreference.supportedLanguages.compactMap(\.localizationIdentifier)) == expectedIdentifiers)
        let english = try strings(identifier: "en")
        #expect(english.count >= 394, "The full application catalog must be bundled")
        let tokenPattern = #"\$\{[^}]+\}|%(?:\d+\$)?(?:lld|ld|d|@)"#
        let regex = try NSRegularExpression(pattern: tokenPattern)
        func orderedTokens(_ value: String) -> [String] {
            regex.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap {
                Range($0.range, in: value).map { String(value[$0]) }
            }
        }
        var issues: [String] = []
        for identifier in expectedIdentifiers {
            let localized = try strings(identifier: identifier)
            #expect(Set(localized.keys) == Set(english.keys), "Missing catalog keys in \(identifier)")
            for (key, source) in english {
                guard let values = localized[key], let sourceValue = source.first else {
                    issues.append("Missing \(key) or its source variants in \(identifier)")
                    continue
                }
                let sourceTokens = orderedTokens(sourceValue)
                if values.isEmpty { issues.append("Missing variants in \(identifier): \(key)") }
                for value in values {
                    let valueTokens = orderedTokens(value)
                    if value.isEmpty && !sourceValue.isEmpty { issues.append("Empty translation in \(identifier): \(key)") }
                    if valueTokens.sorted() != sourceTokens.sorted() { issues.append("Changed arguments in \(identifier): \(key)") }
                    if valueTokens.filter({ $0.hasPrefix("%") }) != sourceTokens.filter({ $0.hasPrefix("%") }) {
                        issues.append("Reordered positional arguments in \(identifier): \(key)")
                    }
                    if value.contains("ZXQ") { issues.append("Unresolved translation marker in \(identifier): \(key)") }
                }
            }
        }
        #expect(issues.isEmpty, "Catalog violations: \(issues.joined(separator: "; "))")
    }

    @Test("Selection counts use the language's plural rules", arguments: [
        ("ru", 2, "2 документа"), ("ru", 5, "5 документов"), ("ru", 21, "21 документ"),
        ("pl", 2, "2 dokumenty"), ("pl", 5, "5 dokumentów"), ("pl", 21, "21 dokumentów"),
        ("uk", 2, "2 документи"), ("uk", 5, "5 документів"), ("uk", 21, "21 документ"),
        ("cs", 2, "2 dokumenty"), ("cs", 5, "5 dokumentů"), ("cs", 21, "21 dokumentů")
    ])
    func selectionCount(identifier: String, count: Int, expected: String) {
        #expect(AppLocalization.string("\(Int64(count)) documents", locale: Locale(identifier: identifier), bundle: applicationBundle) == expected)
    }

    @Test("Pluralized archive confirmations retain count, destination and original archive", arguments: ["ru", "pl", "uk", "cs", "da"], [2, 5])
    func archiveConfirmation(identifier: String, count: Int) {
        let destination = "Target.zip"
        let original = "Original.7z"
        let locale = Locale(identifier: identifier)
        let copy = AppLocalization.string("Copying \(Int64(count)) item(s) to \(destination) will modify the original archive \(original). The source entries will be preserved.", locale: locale, bundle: applicationBundle)
        let move = AppLocalization.string("Moving \(Int64(count)) item(s) to \(destination) will modify the original archive \(original). The source entries will be removed only after the transfer succeeds.", locale: locale, bundle: applicationBundle)
        for message in [copy, move] {
            #expect(message.contains(String(count)))
            #expect(message.contains(destination))
            #expect(message.contains(original))
            #expect(!message.contains("%"))
            #expect(!message.contains("Copying") && !message.contains("Moving"))
            if let destinationRange = message.range(of: destination), let originalRange = message.range(of: original) {
                #expect(destinationRange.lowerBound < originalRange.lowerBound)
            }
        }
    }

    @Test("Interpolated service errors preserve the user's file name across languages", arguments: AppLanguagePreference.supportedLanguages)
    func interpolatedError(language: AppLanguagePreference) {
        let fileName = "Fixture Ω.zip"
        let message = AppLocalization.string("error.permission \(fileName)", locale: language.locale, bundle: applicationBundle)
        #expect(message.contains(fileName))
        #expect(!message.contains("error.permission"))
    }

    private nonisolated func strings(identifier: String) throws -> [String: [String]] {
        let url = try #require(applicationBundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: "\(identifier).lproj"))
        let data = try Data(contentsOf: url)
        let scalar = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])
        var result = scalar.mapValues { [$0] }
        if let pluralURL = applicationBundle.url(forResource: "Localizable", withExtension: "stringsdict", subdirectory: "\(identifier).lproj") {
            let pluralData = try Data(contentsOf: pluralURL)
            let plurals = try #require(PropertyListSerialization.propertyList(from: pluralData, format: nil) as? [String: [String: Any]])
            let categories = ["zero", "one", "two", "few", "many", "other"]
            for (key, format) in plurals {
                var variants: [String] = []
                for value in format.values {
                    if let rules = value as? [String: Any] {
                        variants += categories.compactMap { rules[$0] as? String }
                    }
                }
                #expect(!variants.isEmpty, "No plural variants for \(identifier): \(key)")
                result[key] = variants
            }
        }
        return result
    }
}
