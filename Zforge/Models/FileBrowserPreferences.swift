import Foundation
import SwiftUI

@MainActor
@Observable
final class FileBrowserPreferences {
    static let shared = FileBrowserPreferences(defaults: applicationDefaults)

    private static var applicationDefaults: UserDefaults {
        let process = ProcessInfo.processInfo
        if process.arguments.contains("--ui-icon-preview-fixtures"),
           let suite = process.environment["ZFORGE_UI_PREFERENCES_SUITE"],
           let defaults = UserDefaults(suiteName: suite) {
            return defaults
        }
        return .standard
    }

    private enum Key {
        static let viewMode = "browser.viewMode"
        static let scale = "browser.scale"
        static let listColumnWidths = "browser.listColumnWidths"
        static let listColumns = "browser.listColumns"
        static let directoryListColumns = "browser.directoryListColumns"
        static let knownSidebarTags = "browser.knownSidebarTags"
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
        static let archiveNestingLimit = "archive.nestingLimit"
        static let archiveRootSizeLimitGB = "archive.rootSizeLimitGB"
        static let defaultCompressionFormat = "archive.defaultCompressionFormat"
        static let compressionProfiles = "archive.compressionProfiles"
        static let defaultCompressionProfileID = "archive.defaultCompressionProfileID"
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

    var archiveBrowsingPolicy: ArchiveBrowsingPolicy {
        ArchiveBrowsingPolicy(
            maximumNestedArchiveDepth: archiveNestingLimit,
            rootSizeLimit: Int64(archiveRootSizeLimitGB) * 1_000_000_000
        )
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

    init(defaults: UserDefaults = .standard) {
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
