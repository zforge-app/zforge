import Foundation

/// Resolves user-visible strings using Zforge's language preference, including
/// strings produced by services and models outside the SwiftUI environment.
nonisolated enum AppLocalization {
    static var currentLocale: Locale {
        let rawValue = UserDefaults.standard.string(forKey: AppLanguagePreference.defaultsKey)
        let preference = AppLanguagePreference(rawValue: rawValue ?? "") ?? .system
        return preference.locale
    }

    static func string(
        _ key: String.LocalizationValue,
        locale: Locale? = nil,
        bundle: Bundle = .main
    ) -> String {
        let resolvedLocale = locale ?? currentLocale
        return String(
            localized: key,
            bundle: bundle.localizedBundle(for: resolvedLocale),
            locale: resolvedLocale
        )
    }

    static func byteCount(_ count: Int64, locale: Locale? = nil) -> String {
        count.formatted(ByteCountFormatStyle(style: .file, locale: locale ?? currentLocale))
    }
}

private extension Bundle {
    nonisolated func localizedBundle(for locale: Locale) -> Bundle {
        if let path = path(forResource: locale.identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }

        guard let languageCode = locale.language.languageCode?.identifier else {
            return self
        }

        let matchingLocalization = localizations.first {
            Locale(identifier: $0).language.languageCode?.identifier == languageCode
        }
        guard let matchingLocalization,
              let path = path(forResource: matchingLocalization, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return self
        }
        return bundle
    }
}
