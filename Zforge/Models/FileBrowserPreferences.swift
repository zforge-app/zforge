import Foundation
import SwiftUI

@MainActor
@Observable
final class FileBrowserPreferences {
    static let shared = FileBrowserPreferences()

    private enum Key {
        static let viewMode = "browser.viewMode"
        static let scale = "browser.scale"
        static let sortField = "browser.sortField"
        static let sortAscending = "browser.sortAscending"
        static let showHidden = "browser.showHidden"
        static let previewVisibleIcons = "browser.previewVisible.icons"
        static let previewVisibleList = "browser.previewVisible.list"
        static let previewVisibleColumns = "browser.previewVisible.columns"
        static let previewVisibleGallery = "browser.previewVisible.gallery"
        static let language = AppLanguagePreference.defaultsKey
        static let archiveNestingLimit = "archive.nestingLimit"
        static let archiveRootSizeLimitGB = "archive.rootSizeLimitGB"
        static let defaultCompressionFormat = "archive.defaultCompressionFormat"
    }

    private let defaults: UserDefaults

    var viewMode: BrowserViewMode { didSet { defaults.set(viewMode.rawValue, forKey: Key.viewMode) } }
    var scale: CGFloat { didSet { defaults.set(scale, forKey: Key.scale) } }
    var sort: BrowserSort {
        didSet {
            defaults.set(sort.field.rawValue, forKey: Key.sortField)
            defaults.set(sort.ascending, forKey: Key.sortAscending)
        }
    }
    var showHiddenFiles: Bool { didSet { defaults.set(showHiddenFiles, forKey: Key.showHidden) } }
    private var previewVisibleIcons: Bool {
        didSet { defaults.set(previewVisibleIcons, forKey: Key.previewVisibleIcons) }
    }
    private var previewVisibleList: Bool {
        didSet { defaults.set(previewVisibleList, forKey: Key.previewVisibleList) }
    }
    private var previewVisibleColumns: Bool {
        didSet { defaults.set(previewVisibleColumns, forKey: Key.previewVisibleColumns) }
    }
    private var previewVisibleGallery: Bool {
        didSet { defaults.set(previewVisibleGallery, forKey: Key.previewVisibleGallery) }
    }
    var language: AppLanguagePreference { didSet { defaults.set(language.rawValue, forKey: Key.language) } }
    var archiveNestingLimit: Int {
        didSet {
            let clamped = min(max(archiveNestingLimit, 1), 10)
            if archiveNestingLimit != clamped {
                archiveNestingLimit = clamped
            } else {
                defaults.set(archiveNestingLimit, forKey: Key.archiveNestingLimit)
            }
        }
    }
    var archiveRootSizeLimitGB: Int {
        didSet {
            let clamped = min(max(archiveRootSizeLimitGB, 1), 5)
            if archiveRootSizeLimitGB != clamped {
                archiveRootSizeLimitGB = clamped
            } else {
                defaults.set(archiveRootSizeLimitGB, forKey: Key.archiveRootSizeLimitGB)
            }
        }
    }
    var defaultCompressionFormat: ArchiveCompressionFormat {
        didSet { defaults.set(defaultCompressionFormat.rawValue, forKey: Key.defaultCompressionFormat) }
    }

    var archiveBrowsingPolicy: ArchiveBrowsingPolicy {
        ArchiveBrowsingPolicy(
            maximumNestedArchiveDepth: archiveNestingLimit,
            rootSizeLimit: Int64(archiveRootSizeLimitGB) * 1_073_741_824
        )
    }

    func previewVisible(in viewMode: BrowserViewMode) -> Bool {
        switch viewMode {
        case .icons: previewVisibleIcons
        case .list: previewVisibleList
        case .columns: previewVisibleColumns
        case .gallery: previewVisibleGallery
        }
    }

    func setPreviewVisible(_ isVisible: Bool, in viewMode: BrowserViewMode) {
        switch viewMode {
        case .icons: previewVisibleIcons = isVisible
        case .list: previewVisibleList = isVisible
        case .columns: previewVisibleColumns = isVisible
        case .gallery: previewVisibleGallery = isVisible
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        viewMode = BrowserViewMode(rawValue: defaults.string(forKey: Key.viewMode) ?? "") ?? .icons
        let storedScale = defaults.double(forKey: Key.scale)
        scale = storedScale == 0 ? 1 : min(max(storedScale, 0.7), 1.6)
        let field = BrowserSortField(rawValue: defaults.string(forKey: Key.sortField) ?? "") ?? .name
        sort = BrowserSort(
            field: field,
            ascending: defaults.object(forKey: Key.sortAscending) == nil
                ? true
                : defaults.bool(forKey: Key.sortAscending)
        )
        showHiddenFiles = defaults.bool(forKey: Key.showHidden)
        previewVisibleIcons = Self.storedPreviewVisibility(
            defaults: defaults,
            key: Key.previewVisibleIcons
        )
        previewVisibleList = Self.storedPreviewVisibility(
            defaults: defaults,
            key: Key.previewVisibleList
        )
        previewVisibleColumns = Self.storedPreviewVisibility(
            defaults: defaults,
            key: Key.previewVisibleColumns
        )
        previewVisibleGallery = Self.storedPreviewVisibility(
            defaults: defaults,
            key: Key.previewVisibleGallery
        )
        language = AppLanguagePreference(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system
        archiveNestingLimit = defaults.object(forKey: Key.archiveNestingLimit) == nil
            ? 5
            : min(max(defaults.integer(forKey: Key.archiveNestingLimit), 1), 10)
        archiveRootSizeLimitGB = defaults.object(forKey: Key.archiveRootSizeLimitGB) == nil
            ? 1
            : min(max(defaults.integer(forKey: Key.archiveRootSizeLimitGB), 1), 5)
        defaultCompressionFormat = ArchiveCompressionFormat(
            rawValue: defaults.string(forKey: Key.defaultCompressionFormat) ?? ""
        ) ?? .zip

        if let argumentIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--ui-view-mode"),
           ProcessInfo.processInfo.arguments.indices.contains(argumentIndex + 1),
           let fixtureMode = BrowserViewMode(rawValue: ProcessInfo.processInfo.arguments[argumentIndex + 1]) {
            viewMode = fixtureMode
        }
    }

    private static func storedPreviewVisibility(defaults: UserDefaults, key: String) -> Bool {
        defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }
}

nonisolated enum AppLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case english
    case portugueseBrazil

    static let defaultsKey = "appLanguagePreference"

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .system:
            for identifier in Locale.preferredLanguages {
                switch Locale(identifier: identifier).language.languageCode?.identifier {
                case "pt": return Locale(identifier: "pt-BR")
                case "en": return Locale(identifier: "en")
                default: continue
                }
            }
            return Locale(identifier: "en")
        case .english: return Locale(identifier: "en")
        case .portugueseBrazil: return Locale(identifier: "pt-BR")
        }
    }
}
