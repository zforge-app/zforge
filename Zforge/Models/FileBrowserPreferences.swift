import Foundation
import SwiftUI

@MainActor
@Observable
final class FileBrowserPreferences {
    static let shared = FileBrowserPreferences(defaults: ZforgeDefaults.application)

    private enum Key {
        static let viewMode = "browser.viewMode"
        static let scale = "browser.scale"
        static let listColumnWidths = "browser.listColumnWidths"
        static let listColumns = "browser.listColumns"
        static let directoryListColumns = "browser.directoryListColumns"
        static let knownSidebarTags = "browser.knownSidebarTags"
        static let hiddenSidebarLocations = "browser.hiddenSidebarLocations"
        static let finderColumnWidth = "browser.finderColumnWidth"
        static let previewWidth = "browser.previewWidth"
        static let sortField = "browser.sortField"
        static let sortAscending = "browser.sortAscending"
        static let showHidden = "browser.showHidden"
        static let showIconPreviews = "browser.showIconPreviews"
        static let previewVisibleIcons = "browser.previewVisible.icons"
        static let previewVisibleList = "browser.previewVisible.list"
        static let previewVisibleColumns = "browser.previewVisible.columns"
        static let previewVisibleGallery = "browser.previewVisible.gallery"
        static let language = AppLanguagePreference.defaultsKey
        /// Removed with nested-archive navigation (D-73); deleted from stored preferences.
        static let removedArchiveNavigationKeys = ["archive.nestingLimit", "archive.rootSizeLimitBytes", "archive.rootSizeLimitGB"]
        static let previewSizeLimit = "archive.preview.sizeLimitBytes"
        static let thumbnailSizeLimit = "archive.preview.thumbnailLimitBytes"
        static let previewSolidArchives = "archive.preview.solidArchives"
        static let previewOnRemovableVolumes = "archive.preview.removableVolumes"
        static let removableVolumePreviewLimit = "archive.preview.removableLimitBytes"
        static let previewOnNetworkVolumes = "archive.preview.networkVolumes"
        static let networkVolumePreviewLimit = "archive.preview.networkLimitBytes"
        /// Whole decimal GB (1–5) saved before the limit became a byte count.
        static let defaultCompressionFormat = "archive.defaultCompressionFormat"
        static let compressionProfiles = "archive.compressionProfiles"
        static let defaultCompressionProfileID = "archive.defaultCompressionProfileID"
        static let settingsPane = "settings.selectedPane"
    }

    private let defaults: UserDefaults

    // Default for newly created windows; the active mode belongs to FileBrowserState.
    var viewMode: BrowserViewMode { didSet { defaults.set(viewMode.rawValue, forKey: Key.viewMode) } }
    var scale: CGFloat { didSet { defaults.set(scale, forKey: Key.scale) } }
    var listColumnWidths: [String: Double] {
        didSet { defaults.set(listColumnWidths, forKey: Key.listColumnWidths) }
    }
    private(set) var globalListColumns: [BrowserListColumn] {
        didSet { defaults.set(globalListColumns.map(\.rawValue), forKey: Key.listColumns) }
    }
    private(set) var directoryListColumns: [String: [String]] {
        didSet { defaults.set(directoryListColumns, forKey: Key.directoryListColumns) }
    }
    private(set) var knownSidebarTags: [String] {
        didSet { defaults.set(knownSidebarTags, forKey: Key.knownSidebarTags) }
    }
    /// Locations categories removed from the sidebar; shared by every window.
    private(set) var hiddenSidebarLocations: Set<SidebarLocationCategory> {
        didSet {
            defaults.set(hiddenSidebarLocations.map(\.rawValue).sorted(), forKey: Key.hiddenSidebarLocations)
        }
    }
    var finderColumnWidth: CGFloat {
        didSet { defaults.set(Double(finderColumnWidth), forKey: Key.finderColumnWidth) }
    }
    var previewWidth: CGFloat {
        didSet { defaults.set(Double(previewWidth), forKey: Key.previewWidth) }
    }
    var sort: BrowserSort {
        didSet {
            defaults.set(sort.field.rawValue, forKey: Key.sortField)
            defaults.set(sort.ascending, forKey: Key.sortAscending)
        }
    }
    var showHiddenFiles: Bool { didSet { defaults.set(showHiddenFiles, forKey: Key.showHidden) } }
    var showIconPreviews: Bool { didSet { defaults.set(showIconPreviews, forKey: Key.showIconPreviews) } }
    /// The Settings pane shown when the window opens: the last one chosen (ZF-58).
    var settingsPane: SettingsPane { didSet { defaults.set(settingsPane.rawValue, forKey: Key.settingsPane) } }
    /// Automatic previews of items inside archives up to this size (decimal bytes, D-73).
    var previewSizeLimit: Int64 {
        didSet {
            let clamped = Self.clamp(previewSizeLimit, ArchivePreviewLimits.previewRange)
            if clamped != previewSizeLimit { previewSizeLimit = clamped } else { defaults.set(previewSizeLimit, forKey: Key.previewSizeLimit) }
        }
    }
    /// Automatic thumbnails of items inside archives up to this size.
    var thumbnailSizeLimit: Int64 {
        didSet {
            let clamped = Self.clamp(thumbnailSizeLimit, ArchivePreviewLimits.thumbnailRange)
            if clamped != thumbnailSizeLimit { thumbnailSizeLimit = clamped } else { defaults.set(thumbnailSizeLimit, forKey: Key.thumbnailSizeLimit) }
        }
    }
    /// Automatic previews and thumbnails of items whose decoding starts at a solid block.
    var previewSolidArchives: Bool { didSet { defaults.set(previewSolidArchives, forKey: Key.previewSolidArchives) } }
    var previewOnRemovableVolumes: Bool {
        didSet { defaults.set(previewOnRemovableVolumes, forKey: Key.previewOnRemovableVolumes) }
    }
    var removableVolumePreviewLimit: Int64 {
        didSet {
            let clamped = Self.clamp(removableVolumePreviewLimit, ArchivePreviewLimits.previewRange)
            if clamped != removableVolumePreviewLimit { removableVolumePreviewLimit = clamped } else { defaults.set(removableVolumePreviewLimit, forKey: Key.removableVolumePreviewLimit) }
        }
    }
    var previewOnNetworkVolumes: Bool {
        didSet { defaults.set(previewOnNetworkVolumes, forKey: Key.previewOnNetworkVolumes) }
    }
    var networkVolumePreviewLimit: Int64 {
        didSet {
            let clamped = Self.clamp(networkVolumePreviewLimit, ArchivePreviewLimits.previewRange)
            if clamped != networkVolumePreviewLimit { networkVolumePreviewLimit = clamped } else { defaults.set(networkVolumePreviewLimit, forKey: Key.networkVolumePreviewLimit) }
        }
    }

    /// The archive preview settings as one value.
    var archivePreviewLimits: ArchivePreviewLimits {
        ArchivePreviewLimits(
            previewLimit: previewSizeLimit, thumbnailLimit: thumbnailSizeLimit,
            previewsSolidArchives: previewSolidArchives,
            previewsOnRemovableVolumes: previewOnRemovableVolumes, removableLimit: removableVolumePreviewLimit,
            previewsOnNetworkVolumes: previewOnNetworkVolumes, networkLimit: networkVolumePreviewLimit
        )
    }

    private static func clamp(_ value: Int64, _ range: ClosedRange<Int64>) -> Int64 {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private static func storedLimit(_ defaults: UserDefaults, _ key: String, default fallback: Int64,
                                    range: ClosedRange<Int64>) -> Int64 {
        guard let stored = (defaults.object(forKey: key) as? NSNumber)?.int64Value else { return fallback }
        return min(max(stored, range.lowerBound), range.upperBound)
    }
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
    /// What opening an archive from Finder does when Zforge opens its type by default (ZF-78).
    var finderArchiveOpening: FinderArchiveOpeningChoice {
        didSet { defaults.set(finderArchiveOpening.rawValue, forKey: FinderArchiveOpeningChoice.defaultsKey) }
    }
    var compressionProfiles: [CompressionProfile] {
        didSet {
            if let data = try? JSONEncoder().encode(compressionProfiles) {
                defaults.set(data, forKey: Key.compressionProfiles)
            }
        }
    }
    var defaultCompressionProfileID: UUID {
        didSet { defaults.set(defaultCompressionProfileID.uuidString, forKey: Key.defaultCompressionProfileID) }
    }
    @ObservationIgnored private var sessionPasswords: [UUID: String] = [:]

    var defaultCompressionProfile: CompressionProfile {
        compressionProfiles.first(where: { $0.id == defaultCompressionProfileID })
            ?? compressionProfiles[0]
    }

    // Preserve the old preference interface for existing callers and migration.
    var defaultCompressionFormat: ArchiveCompressionFormat {
        get { defaultCompressionProfile.options.format }
        set {
            var options = defaultCompressionProfile.options
            options.format = newValue
            updateCompressionProfile(defaultCompressionProfileID, options: options)
        }
    }

    func createCompressionProfile(name: String, options: CompressionOptions) -> UUID {
        let base = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = base.isEmpty ? AppLocalization.string("New Profile", locale: language.locale) : base
        var unique = candidate
        var suffix = 2
        while compressionProfiles.contains(where: { $0.name.localizedCaseInsensitiveCompare(unique) == .orderedSame }) {
            unique = "\(candidate) \(suffix)"
            suffix += 1
        }
        let profile = CompressionProfile(name: unique, options: options)
        compressionProfiles.append(profile)
        return profile.id
    }

    /// Settings ▸ Compression ▸ Add Profile: a new profile with the standard options, named
    /// “New Profile” (made unique), listed after the others.
    func addCompressionProfile() -> UUID {
        createCompressionProfile(name: "", options: CompressionOptions())
    }

    /// A copy of a profile named after it (“Name 2”), with its session password.
    func duplicateCompressionProfile(_ id: UUID) -> UUID? {
        guard let profile = compressionProfiles.first(where: { $0.id == id }) else { return nil }
        let copy = createCompressionProfile(name: profile.name, options: profile.options)
        setSessionPassword(sessionPassword(for: id), for: copy)
        return copy
    }

    func updateCompressionProfile(_ id: UUID, name: String? = nil, options: CompressionOptions? = nil) {
        guard let index = compressionProfiles.firstIndex(where: { $0.id == id }) else { return }
        var profile = compressionProfiles[index]
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { profile.name = trimmed }
        }
        if let options { profile.options = options.normalized() }
        compressionProfiles[index] = profile
        if id == defaultCompressionProfileID {
            defaults.set(profile.options.format.rawValue, forKey: Key.defaultCompressionFormat)
        }
    }

    func deleteCompressionProfile(_ id: UUID) {
        guard compressionProfiles.count > 1 else { return }
        compressionProfiles.removeAll(where: { $0.id == id })
        sessionPasswords.removeValue(forKey: id)
        if defaultCompressionProfileID == id {
            defaultCompressionProfileID = compressionProfiles[0].id
        }
    }

    func sessionPassword(for id: UUID) -> String {
        sessionPasswords[id] ?? ""
    }

    func setSessionPassword(_ password: String, for id: UUID) {
        if password.isEmpty { sessionPasswords.removeValue(forKey: id) }
        else { sessionPasswords[id] = password }
    }

    func zoomIn() { setZoomStep(Int((scale * 10).rounded()) + 1) }
    func zoomOut() { setZoomStep(Int((scale * 10).rounded()) - 1) }
    func resetZoom() { scale = 1 }

    func listColumnWidth(_ field: BrowserSortField) -> CGFloat {
        let fallback: CGFloat
        switch field {
        case .name: fallback = 168
        case .modificationDate, .creationDate, .lastOpenedDate, .dateAdded: fallback = 180
        case .size: fallback = 90
        case .kind: fallback = 150
        case .version: fallback = 100
        case .comments: fallback = 220
        case .tags: fallback = 160
        }
        return CGFloat(listColumnWidths[field.rawValue] ?? Double(fallback))
    }

    func width(forListColumn column: BrowserListColumn) -> CGFloat {
        if let field = column.sortField { return listColumnWidth(field) }
        return 160
    }

    func visibleListColumns(for location: BrowserLocation) -> [BrowserListColumn] {
        guard let key = Self.directoryKey(for: location), let stored = directoryListColumns[key] else {
            return globalListColumns
        }
        return Self.normalizedColumns(stored)
    }

    func setGlobalListColumns(_ columns: [BrowserListColumn]) {
        globalListColumns = Self.normalizedColumns(columns.map(\.rawValue))
    }

    /// While a Settings row is dragged over another visible column, the dragged column
    /// takes that column's place. Name and hidden columns are never targets.
    func moveGlobalListColumn(_ column: BrowserListColumn, onto target: BrowserListColumn) {
        guard column != target,
              let from = globalListColumns.firstIndex(of: column), from > 0,
              let to = globalListColumns.firstIndex(of: target), to > 0 else { return }
        var columns = globalListColumns
        columns.remove(at: from)
        columns.insert(column, at: to)
        setGlobalListColumns(columns)
    }

    /// Moves one default List column one step left (-1) or right (+1), never before Name.
    func moveGlobalListColumn(_ column: BrowserListColumn, by offset: Int) {
        var columns = globalListColumns
        guard let index = columns.firstIndex(of: column), index > 0,
              columns.indices.contains(index + offset), index + offset > 0 else { return }
        columns.swapAt(index, index + offset)
        setGlobalListColumns(columns)
    }

    func setListColumns(_ columns: [BrowserListColumn], for location: BrowserLocation) {
        guard let key = Self.directoryKey(for: location) else { return }
        directoryListColumns[key] = Self.normalizedColumns(columns.map(\.rawValue)).map(\.rawValue)
    }

    func resetListColumns(for location: BrowserLocation) {
        guard let key = Self.directoryKey(for: location) else { return }
        directoryListColumns.removeValue(forKey: key)
    }

    func hasListColumnOverride(for location: BrowserLocation) -> Bool {
        guard let key = Self.directoryKey(for: location) else { return false }
        return directoryListColumns[key] != nil
    }

    func isSidebarLocationVisible(_ category: SidebarLocationCategory) -> Bool {
        !hiddenSidebarLocations.contains(category)
    }

    func setSidebarLocation(_ category: SidebarLocationCategory, visible: Bool) {
        if visible { hiddenSidebarLocations.remove(category) } else { hiddenSidebarLocations.insert(category) }
    }

    func rememberSidebarTags(_ names: [String]) {
        let names = Set(knownSidebarTags + names.filter { !$0.isEmpty })
        let sorted = names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        if sorted != knownSidebarTags { knownSidebarTags = sorted }
    }

    private static func directoryKey(for location: BrowserLocation) -> String? {
        guard case let .fileSystem(url) = location else { return nil }
        return url.standardizedFileURL.resolvingSymlinksInPath().path
    }

    private static func normalizedColumns(_ rawValues: [String]) -> [BrowserListColumn] {
        var seen: Set<BrowserListColumn> = [.name]
        return [.name] + rawValues.compactMap(BrowserListColumn.init(rawValue:)).filter {
            BrowserListColumn.selectable.contains($0) && seen.insert($0).inserted
        }
    }

    func setListColumnWidth(_ width: CGFloat, for field: BrowserSortField) {
        let minimum: CGFloat = field == .name ? 168 : 60
        listColumnWidths[field.rawValue] = Double(min(max(width, minimum), 800))
    }

    func setFinderColumnWidth(_ width: CGFloat) {
        finderColumnWidth = min(max(width, 180), 800)
    }

    func setPreviewWidth(_ width: CGFloat) {
        previewWidth = min(max(width, 180), 800)
    }

    private func setZoomStep(_ step: Int) {
        scale = CGFloat(min(max(step, 7), 16)) / 10
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

    init(defaults: UserDefaults = ZforgeDefaults.application) {
        self.defaults = defaults
        viewMode = BrowserViewMode(rawValue: defaults.string(forKey: Key.viewMode) ?? "") ?? .icons
        let storedScale = defaults.double(forKey: Key.scale)
        scale = storedScale == 0 ? 1 : min(max(storedScale, 0.7), 1.6)
        listColumnWidths = defaults.dictionary(forKey: Key.listColumnWidths) as? [String: Double] ?? [:]
        globalListColumns = Self.normalizedColumns(
            defaults.stringArray(forKey: Key.listColumns) ?? BrowserListColumn.defaultVisible.map(\.rawValue)
        )
        directoryListColumns = defaults.dictionary(forKey: Key.directoryListColumns) as? [String: [String]] ?? [:]
        knownSidebarTags = defaults.stringArray(forKey: Key.knownSidebarTags) ?? []
        hiddenSidebarLocations = Set((defaults.stringArray(forKey: Key.hiddenSidebarLocations) ?? [])
            .compactMap(SidebarLocationCategory.init(rawValue:)))
        let storedFinderWidth = defaults.double(forKey: Key.finderColumnWidth)
        finderColumnWidth = storedFinderWidth == 0 ? 260 : min(max(storedFinderWidth, 180), 800)
        let storedPreviewWidth = defaults.double(forKey: Key.previewWidth)
        previewWidth = storedPreviewWidth == 0
            ? BrowserLayoutMetrics.previewWidth
            : min(max(storedPreviewWidth, 180), 800)
        let field = BrowserSortField(rawValue: defaults.string(forKey: Key.sortField) ?? "") ?? .name
        sort = BrowserSort(
            field: field,
            ascending: defaults.object(forKey: Key.sortAscending) == nil
                ? true
                : defaults.bool(forKey: Key.sortAscending)
        )
        showHiddenFiles = defaults.bool(forKey: Key.showHidden)
        showIconPreviews = defaults.object(forKey: Key.showIconPreviews) == nil
            ? true
            : defaults.bool(forKey: Key.showIconPreviews)
        settingsPane = defaults.string(forKey: Key.settingsPane).flatMap(SettingsPane.init(rawValue:)) ?? .general
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
        finderArchiveOpening = FinderArchiveOpeningChoice(
            rawValue: defaults.string(forKey: FinderArchiveOpeningChoice.defaultsKey) ?? "") ?? .ask
        // Nested-archive navigation and its depth/root-size limits were removed (D-73).
        Key.removedArchiveNavigationKeys.forEach(defaults.removeObject(forKey:))
        let limits = ArchivePreviewLimits.defaults
        previewSizeLimit = Self.storedLimit(defaults, Key.previewSizeLimit, default: limits.previewLimit,
            range: ArchivePreviewLimits.previewRange)
        thumbnailSizeLimit = Self.storedLimit(defaults, Key.thumbnailSizeLimit, default: limits.thumbnailLimit,
            range: ArchivePreviewLimits.thumbnailRange)
        previewSolidArchives = defaults.object(forKey: Key.previewSolidArchives) == nil
            ? limits.previewsSolidArchives : defaults.bool(forKey: Key.previewSolidArchives)
        previewOnRemovableVolumes = defaults.bool(forKey: Key.previewOnRemovableVolumes)
        removableVolumePreviewLimit = Self.storedLimit(defaults, Key.removableVolumePreviewLimit,
            default: limits.removableLimit, range: ArchivePreviewLimits.previewRange)
        previewOnNetworkVolumes = defaults.bool(forKey: Key.previewOnNetworkVolumes)
        networkVolumePreviewLimit = Self.storedLimit(defaults, Key.networkVolumePreviewLimit,
            default: limits.networkLimit, range: ArchivePreviewLimits.previewRange)
        let legacyFormat = ArchiveCompressionFormat(
            rawValue: defaults.string(forKey: Key.defaultCompressionFormat) ?? ""
        ) ?? .zip
        let storedProfiles = defaults.data(forKey: Key.compressionProfiles)
            .flatMap { try? JSONDecoder().decode([CompressionProfile].self, from: $0) } ?? []
        let profileLocale = (AppLanguagePreference(
            rawValue: defaults.string(forKey: Key.language) ?? ""
        ) ?? .system).locale
        let defaultProfileName = AppLocalization.string("Auto", locale: profileLocale)
        var initialProfiles = storedProfiles.isEmpty
            ? [CompressionProfile(name: defaultProfileName, options: CompressionOptions(format: legacyFormat))]
            : storedProfiles.map { CompressionProfile(id: $0.id, name: $0.name, options: $0.options) }
        let oldDefaultNames = ["Default", AppLocalization.string("Default", locale: Locale(identifier: "pt-BR"))]
        if !storedProfiles.isEmpty, oldDefaultNames.contains(initialProfiles[0].name) {
            initialProfiles[0].name = defaultProfileName
            if let data = try? JSONEncoder().encode(initialProfiles) {
                defaults.set(data, forKey: Key.compressionProfiles)
            }
        }
        let storedID = UUID(uuidString: defaults.string(forKey: Key.defaultCompressionProfileID) ?? "")
        compressionProfiles = initialProfiles
        defaultCompressionProfileID = initialProfiles.contains(where: { $0.id == storedID })
            ? storedID! : initialProfiles[0].id

        if let argumentIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--ui-view-mode"),
           ProcessInfo.processInfo.arguments.indices.contains(argumentIndex + 1),
           let fixtureMode = BrowserViewMode(rawValue: ProcessInfo.processInfo.arguments[argumentIndex + 1]) {
            viewMode = fixtureMode
        }
        // UI tests choose what opening an archive from Finder does (ZF-78); `--ui-` launches
        // keep their preferences in a private suite.
        if let argumentIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--ui-finder-archive-opening"),
           ProcessInfo.processInfo.arguments.indices.contains(argumentIndex + 1),
           let choice = FinderArchiveOpeningChoice(rawValue: ProcessInfo.processInfo.arguments[argumentIndex + 1]) {
            finderArchiveOpening = choice
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
    case chineseSimplified
    case chineseTraditional
    case japanese
    case german
    case french
    case spanish
    case korean
    case italian
    case russian
    case polish
    case ukrainian
    case turkish
    case thai
    case danish
    case czech
    case dutch
    case swedish
    case hindi
    case bengali

    static let defaultsKey = "appLanguagePreference"

    var id: Self { self }

    static var supportedLanguages: [Self] { allCases.filter { $0 != .system } }

    /// Autonyms remain recognizable even when the current interface language is unfamiliar.
    var titleKey: String.LocalizationValue {
        switch self {
        case .system: "System Default"
        case .english: "English"
        case .portugueseBrazil: "Português (Brasil)"
        case .chineseSimplified: "简体中文"
        case .chineseTraditional: "繁體中文"
        case .japanese: "日本語"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        case .korean: "한국어"
        case .italian: "Italiano"
        case .russian: "Русский"
        case .polish: "Polski"
        case .ukrainian: "Українська"
        case .turkish: "Türkçe"
        case .thai: "ไทย"
        case .danish: "Dansk"
        case .czech: "Čeština"
        case .dutch: "Nederlands"
        case .swedish: "Svenska"
        case .hindi: "हिन्दी"
        case .bengali: "বাংলা"
        }
    }

    var localizationIdentifier: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .portugueseBrazil: "pt-BR"
        case .chineseSimplified: "zh-Hans"
        case .chineseTraditional: "zh-Hant"
        case .japanese: "ja"
        case .german: "de"
        case .french: "fr"
        case .spanish: "es"
        case .korean: "ko"
        case .italian: "it"
        case .russian: "ru"
        case .polish: "pl"
        case .ukrainian: "uk"
        case .turkish: "tr"
        case .thai: "th"
        case .danish: "da"
        case .czech: "cs"
        case .dutch: "nl"
        case .swedish: "sv"
        case .hindi: "hi"
        case .bengali: "bn"
        }
    }

    var locale: Locale {
        let resolved = self == .system ? Self.resolve(preferredLanguages: Locale.preferredLanguages) : self
        return Locale(identifier: resolved.localizationIdentifier ?? "en")
    }

    static func resolve(preferredLanguages: [String]) -> Self {
        preferredLanguages.lazy.compactMap { supportedPreference(for: $0) }.first ?? .english
    }

    /// Match regional variants to the shipped translation without crossing Chinese scripts.
    static func supportedPreference(for identifier: String) -> Self? {
        let language = Locale(identifier: identifier).language
        guard let code = language.languageCode?.identifier else { return nil }
        switch code {
        case "pt": return .portugueseBrazil
        case "zh":
            return language.script?.identifier == "Hant" ? .chineseTraditional : .chineseSimplified
        default:
            return supportedLanguages.first { $0.localizationIdentifier == code }
        }
    }
}
