import SwiftUI

/// The Keyboard Shortcuts window: a sidebar of categories (with search) and the shortcuts of the
/// chosen category on the right, as System Settings lays out its panes.
struct KeyboardShortcutsView: View {
    @State private var preferences = FileBrowserPreferences.shared
    @State private var searchText = ""
    @State private var category: KeyboardShortcutCategory = .all

    init(
        preferences: FileBrowserPreferences = .shared,
        searchText: String = "",
        category: KeyboardShortcutCategory = .all
    ) {
        _preferences = State(initialValue: preferences)
        _searchText = State(initialValue: searchText)
        _category = State(initialValue: category)
    }

    private var locale: Locale { preferences.language.locale }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            KeyboardShortcutsSidebar(selection: $category)
                .navigationSplitViewColumnWidth(
                    min: KeyboardShortcutsLayout.sidebarWidth,
                    ideal: KeyboardShortcutsLayout.sidebarWidth,
                    max: KeyboardShortcutsLayout.sidebarWidth
                )
                // SwiftUI alone can leave a sidebar narrower than its column width (D-75).
                .background {
                    SidebarSplitConstraint(
                        minimumWidth: KeyboardShortcutsLayout.sidebarWidth,
                        maximumWidth: KeyboardShortcutsLayout.sidebarWidth
                    )
                }
                .toolbar(removing: .sidebarToggle)
        } detail: {
            KeyboardShortcutsDetail(category: category, searchText: searchText, locale: locale)
                .windowToolbar(title: Text(verbatim: category.title(locale: locale)))
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .frame(minWidth: KeyboardShortcutsLayout.minimumWidth, minHeight: KeyboardShortcutsLayout.minimumHeight)
        .unifiedWindowToolbarStyle()
        .environment(\.locale, locale)
    }
}

/// The window's geometry. The sidebar keeps a fixed width; the detail column takes the rest.
/// Sidebar rows (`SettingsLayout`) and the detail's margins, group, header and row metrics
/// (`SettingsMetrics`) are the Settings window's, so the two windows cannot drift apart.
enum KeyboardShortcutsLayout {
    static let sidebarWidth: CGFloat = 206
    static let minimumWidth: CGFloat = 600
    static let minimumHeight: CGFloat = 420
    static let defaultWidth: CGFloat = 780
    static let defaultHeight: CGFloat = 560
}

// MARK: - Sidebar

struct KeyboardShortcutsSidebar: View {
    @Binding var selection: KeyboardShortcutCategory

    var body: some View {
        List(selection: $selection) {
            KeyboardShortcutCategoryRow(category: .all)
                .tag(KeyboardShortcutCategory.all)
            Divider()
                .listRowSeparator(.hidden)
                .selectionDisabled()
            ForEach(KeyboardShortcutCatalog.sections) { section in
                KeyboardShortcutCategoryRow(category: .section(section.id))
                    .tag(KeyboardShortcutCategory.section(section.id))
            }
        }
        .environment(\.sidebarRowSize, .small)
        .accessibilityIdentifier("shortcut-categories")
    }
}

/// A category row: its tile, its title and, trailing in tertiary text, the number of shortcuts
/// in the catalog (not affected by search).
struct KeyboardShortcutCategoryRow: View {
    let category: KeyboardShortcutCategory

    var body: some View {
        HStack(spacing: 8) {
            SymbolTile(symbol: category.systemImage, colors: category.tileColors, size: 20)
            Text(LocalizedStringKey(category.titleKey))
                .font(.system(size: 13))
                .lineLimit(2)
            Spacer(minLength: 4)
            Text(category.itemCount, format: .number)
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
        }
        // The 20 pt tile sets the content height; the sidebar list adds 4 pt above and below
        // (28 pt rows), as in the Settings sidebar.
        .frame(maxWidth: .infinity, minHeight: SettingsLayout.sidebarContentHeight, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("shortcut-category-\(category.id)")
    }
}

// MARK: - Detail

struct KeyboardShortcutsDetail: View {
    let category: KeyboardShortcutCategory
    let searchText: String
    let locale: Locale

    private var sections: [KeyboardShortcutSection] {
        KeyboardShortcutCatalog.sections(in: category, matching: searchText, locale: locale)
    }

    var body: some View {
        let sections = sections
        Group {
            if sections.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                SettingsPaneColumn {
                    ForEach(sections) { section in
                        KeyboardShortcutGroup(section: section, showsHeader: category == .all)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One section as a Settings group: a header above it in All Shortcuts only, a row per shortcut.
struct KeyboardShortcutGroup: View {
    let section: KeyboardShortcutSection
    let showsHeader: Bool

    var body: some View {
        SettingsGroup(header: showsHeader ? Text(LocalizedStringKey(section.title)) : nil) {
            ForEach(section.items) { item in
                SettingsRow(
                    title: Text(LocalizedStringKey(item.action))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(Text(LocalizedStringKey(item.action)))
                ) {
                    ShortcutKeysView(input: item.input)
                }
            }
        }
    }
}

// MARK: - Categories

/// What the sidebar selects: every section, or one.
enum KeyboardShortcutCategory: Hashable, Identifiable {
    case all
    case section(String)

    var id: String {
        switch self {
        case .all: "all"
        case .section(let id): id
        }
    }

    /// The String Catalog key of the category's name.
    var titleKey: String {
        switch self {
        case .all: "All Shortcuts"
        case .section(let id): KeyboardShortcutCatalog.sections.first { $0.id == id }?.title ?? id
        }
    }

    func title(locale: Locale) -> String {
        AppLocalization.string(String.LocalizationValue(titleKey), locale: locale)
    }

    var systemImage: String {
        switch self {
        case .all: "keyboard"
        case .section(let id): KeyboardShortcutCatalog.sections.first { $0.id == id }?.systemImage ?? "keyboard"
        }
    }

    /// The number of shortcuts the catalog lists under the category.
    var itemCount: Int {
        KeyboardShortcutCatalog.sections(in: self, matching: "", locale: .current).reduce(0) { $0 + $1.items.count }
    }

    /// The tile's system colour, as the Settings tiles use (ZF-62): one per category.
    var tileColor: Color {
        switch id {
        case "files": .blue
        case "go": .purple
        case "navigation": .green
        case "view": .orange
        case "preview": .teal
        case "help": .gray
        case "mouse": .red
        default: Color(nsColor: .systemGray).mix(with: .black, by: 0.35)
        }
    }

    /// Top and bottom colours of the tile: the system colour, lightened a little at the top.
    var tileColors: (top: Color, bottom: Color) {
        (tileColor.mix(with: .white, by: 0.18), tileColor)
    }
}

extension KeyboardShortcutCatalog {
    /// The sections of a category whose shortcuts match the query: every section for All
    /// Shortcuts, otherwise only the chosen one. Search never changes the category.
    static func sections(
        in category: KeyboardShortcutCategory,
        matching searchText: String,
        locale: Locale
    ) -> [KeyboardShortcutSection] {
        let matching = sections(matching: searchText, locale: locale)
        switch category {
        case .all: return matching
        case .section(let id): return matching.filter { $0.id == id }
        }
    }
}

struct KeyboardShortcutSection: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let items: [KeyboardShortcutItem]

    func withItems(_ items: [KeyboardShortcutItem]) -> KeyboardShortcutSection {
        KeyboardShortcutSection(id: id, title: title, systemImage: systemImage, items: items)
    }
}

struct KeyboardShortcutItem: Identifiable {
    let id: String
    let action: String
    let input: String
}

enum KeyboardShortcutCatalog {
    static let sections: [KeyboardShortcutSection] = [
        section("files", "Files and Items", "doc.on.doc", [
            ("Undo", "⌘Z"),
            ("New Zforge Window", "⌘N"),
            ("New Tab", "⌘T"),
            ("New Folder", "⇧⌘N"),
            ("New Folder with Selection", "⌃⌥⌘N"),
            ("Duplicate", "⌘D"),
            ("Get Info", "⌘I"),
            ("Show Original", "⌘R"),
            ("Make Alias", "⌃⌘A"),
            ("Rename", "Return"),
            ("Copy", "⌘C"),
            ("Paste", "⌘V"),
            ("Move Items Here", "⌥⌘V"),
            ("Move to Trash / Remove from Archive", "⌘⌫"),
            ("Delete Immediately…", "⌥⌘⌫"),
            ("Eject", "⌘E"),
            ("Find", "⌘F")
        ]),
        section("go", "Go", "arrow.triangle.turn.up.right.diamond", [
            ("Computer", "⇧⌘C"),
            ("Desktop", "⇧⌘D"),
            ("Recents", "⇧⌘F"),
            ("Go to Folder…", "⇧⌘G"),
            ("Home", "⇧⌘H"),
            ("Network", "⇧⌘K"),
            ("Downloads", "⌥⌘L"),
            ("Documents", "⇧⌘O"),
            ("Remote", "⌘K"),
            ("Open Enclosing Folder in New Window", "⌃⌘↑")
        ]),
        section("navigation", "Navigation", "arrow.left.arrow.right", [
            ("Back", "⌘["),
            ("Forward", "⌘]"),
            ("Enclosing Folder", "⌘↑"),
            ("Open", "⌘↓")
        ]),
        section("view", "View", "rectangle.3.group", [
            ("Icons", "⌘1"),
            ("List", "⌘2"),
            ("Columns", "⌘3"),
            ("Gallery", "⌘4"),
            ("Zoom In", "⌘+|⌘="),
            ("Zoom Out", "⌘−"),
            ("Actual Size", "⌘0"),
            ("Show or Hide Tab Bar", "⇧⌘T"),
            ("Show Hidden Files", "⇧⌘."),
            ("Show or Hide Preview", "⇧⌘P")
        ]),
        section("preview", "Preview", "eye", [
            ("Quick Look", "Space|⌘Y"),
            ("Slideshow", "⌥⌘Y")
        ]),
        section("help", "Help", "questionmark.circle", [
            ("Keyboard Shortcuts…", "⌘/")
        ]),
        section("mouse", "Mouse and Drag", "cursorarrow.motionlines", [
            ("Open a folder in a separate window", "⌘ + double-click"),
            ("Move to another volume", "⌘ + drag"),
            ("Copy an item", "⌥ + drag"),
            ("Make an alias", "⌥⌘ + drag"),
            ("Expand or collapse the entire hierarchy", "⌥ + click disclosure"),
            ("Show the folders that contain the current folder", "⌘ + click window title")
        ])
    ]

    /// Sections whose action, section title, or shortcut (including spelled-out
    /// modifier names) match the query in the app language, ignoring case,
    /// diacritics, and width. An empty query returns every section.
    static func sections(matching searchText: String, locale: Locale) -> [KeyboardShortcutSection] {
        func normalized(_ value: String) -> String {
            value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: locale)
        }
        let query = normalized(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !query.isEmpty else { return sections }

        return sections.compactMap { section in
            let matchingItems = section.items.filter { item in
                let localizedAction = AppLocalization.string(
                    String.LocalizationValue(item.action),
                    locale: locale
                )
                let localizedSection = AppLocalization.string(
                    String.LocalizationValue(section.title),
                    locale: locale
                )
                let shortcutAliases = item.input
                    .replacingOccurrences(of: "⌃", with: " control ctrl ")
                    .replacingOccurrences(of: "⌥", with: " option alt ")
                    .replacingOccurrences(of: "⇧", with: " shift ")
                    .replacingOccurrences(of: "⌘", with: " command cmd ")

                return [localizedAction, localizedSection, item.input, shortcutAliases]
                    .contains { normalized($0).contains(query) }
            }
            guard !matchingItems.isEmpty else { return nil }
            return section.withItems(matchingItems)
        }
    }

    private static func section(
        _ id: String,
        _ title: String,
        _ systemImage: String,
        _ items: [(String, String)]
    ) -> KeyboardShortcutSection {
        KeyboardShortcutSection(
            id: id,
            title: title,
            systemImage: systemImage,
            items: items.enumerated().map {
                KeyboardShortcutItem(id: "\(id)-\($0.offset)", action: $0.element.0, input: $0.element.1)
            }
        )
    }
}
