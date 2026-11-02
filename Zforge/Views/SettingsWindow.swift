import SwiftUI

/// The Settings window's fixed geometry (ZF-58). The detail column keeps the width the single
/// Settings form had (568 pt), so rows, captions and the size sliders keep their measured layout.
/// Sidebar titles wrap to a second line rather than truncate: the longest, Spanish “Previews in
/// Archives”, measures about 266 pt at the sidebar font.
enum SettingsLayout {
    static let sidebarWidth: CGFloat = 220
    static let detailWidth: CGFloat = 568
    static let height: CGFloat = 620
}

/// Which pane the Settings window shows and which profile page is open over it. Choosing a pane
/// remembers it and leaves the profile page; Duplicate Profile shows the copy in place of the
/// original; Delete Profile returns to the list.
@MainActor
@Observable
final class SettingsNavigation {
    let preferences: FileBrowserPreferences
    var path: [CompressionProfileRoute] = []

    init(preferences: FileBrowserPreferences) { self.preferences = preferences }

    var pane: SettingsPane { preferences.settingsPane }

    func choose(_ pane: SettingsPane) {
        guard pane != preferences.settingsPane else { return }
        preferences.settingsPane = pane
        path.removeAll()
    }

    func openProfile(_ id: UUID) { path.append(CompressionProfileRoute(id: id)) }
    func showProfile(_ id: UUID) { path = [CompressionProfileRoute(id: id)] }
    func closeProfile() { path.removeAll() }
}

/// Settings as in System Settings (ZF-58): a sidebar of panes in three groups and the chosen
/// pane on the right, which opens on the pane shown last. Compression's profiles open their
/// own page inside the pane, with the back button in the toolbar.
struct ZforgeSettingsView: View {
    @State private var preferences: FileBrowserPreferences
    @State private var navigation: SettingsNavigation

    init(preferences: FileBrowserPreferences = .shared) {
        _preferences = State(initialValue: preferences)
        _navigation = State(initialValue: SettingsNavigation(preferences: preferences))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: selection) {
                ForEach(SettingsPane.groups, id: \.self) { group in
                    Section {
                        ForEach(group) { pane in
                            SettingsSidebarRow(pane: pane).tag(pane)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: SettingsLayout.sidebarWidth, ideal: SettingsLayout.sidebarWidth, max: SettingsLayout.sidebarWidth)
            // SwiftUI alone leaves the sidebar narrower than its column width (D-75).
            .background {
                SidebarSplitConstraint(minimumWidth: SettingsLayout.sidebarWidth, maximumWidth: SettingsLayout.sidebarWidth)
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            NavigationStack(path: $navigation.path) {
                SettingsPaneView(pane: navigation.pane, preferences: preferences, openProfile: navigation.openProfile)
                    .navigationDestination(for: CompressionProfileRoute.self) { route in
                        CompressionProfileDetailView(
                            preferences: preferences, id: route.id,
                            show: navigation.showProfile, close: navigation.closeProfile
                        )
                        .id(route.id)
                    }
            }
            .navigationSplitViewColumnWidth(SettingsLayout.detailWidth)
        }
        .frame(width: SettingsLayout.sidebarWidth + SettingsLayout.detailWidth, height: SettingsLayout.height)
        .background { SettingsToolbarStyle() }
        .environment(\.locale, preferences.language.locale)
    }

    private var selection: Binding<SettingsPane?> {
        Binding(get: { navigation.pane }, set: { if let pane = $0 { navigation.choose(pane) } })
    }
}

/// The Settings scene gives its window AppKit's preference toolbar, which centres the toolbar
/// items under the title: a profile page's back button sat alone on a second row (D-75). As in
/// System Settings, the unified style puts the back button and the title in one row at the
/// detail column's leading edge.
private struct SettingsToolbarStyle: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsToolbarStyleView { SettingsToolbarStyleView() }
    func updateNSView(_ view: SettingsToolbarStyleView, context: Context) { view.applyStyle() }
}

final class SettingsToolbarStyleView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyStyle()
    }

    func applyStyle() {
        guard let window, window.toolbarStyle != .unified else { return }
        window.toolbarStyle = .unified
    }
}

/// The pane chosen in the Settings sidebar.
struct SettingsPaneView: View {
    let pane: SettingsPane
    let preferences: FileBrowserPreferences
    let openProfile: (UUID) -> Void

    var body: some View {
        switch pane {
        case .general: GeneralSettingsPane(preferences: preferences)
        case .viewOptions: ViewOptionsSettingsPane(preferences: preferences)
        case .sidebar: SidebarSettingsPane(preferences: preferences)
        case .compression: CompressionSettingsPane(preferences: preferences, openProfile: openProfile)
        case .previews: PreviewsSettingsPane(preferences: preferences)
        case .automation: AutomationSettingsPane()
        }
    }
}

/// A pane's SF Symbol in its coloured rounded square, as System Settings draws its panes: a
/// vertical gradient, a faint light rim and a slight shadow under the symbol and the tile.
struct SettingsIconTile: View {
    let pane: SettingsPane
    let size: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        let colors = pane.tileColors
        ZStack {
            shape.fill(LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(.white.opacity(0.18), lineWidth: max(0.5, size / 40))
                .blendMode(.plusLighter)
            Image(systemName: pane.systemImage)
                .font(.system(size: size * 0.56, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: size / 40, y: size / 60)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: size / 80, y: size / 80)
        .accessibilityHidden(true)
    }
}

struct SettingsSidebarRow: View {
    @Environment(\.locale) private var locale
    let pane: SettingsPane

    var body: some View {
        Label {
            Text(verbatim: pane.title(locale: locale))
                .lineLimit(2)
        } icon: {
            SettingsIconTile(pane: pane, size: 20)
        }
        .help(Text(verbatim: AppLocalization.string(pane.descriptionKey, locale: locale)))
        .accessibilityHint(Text(verbatim: AppLocalization.string(pane.descriptionKey, locale: locale)))
        .accessibilityIdentifier("settings-pane-\(pane.rawValue)")
    }
}

/// A pane: its sections in a grouped form, under the window title that names the pane. No
/// header repeats the selected sidebar row (user request, 2026-11-02).
struct SettingsPaneForm<Content: View>: View {
    @Environment(\.locale) private var locale
    let pane: SettingsPane
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
        .navigationTitle(Text(verbatim: pane.title(locale: locale)))
    }
}

// MARK: - Panes

struct GeneralSettingsPane: View {
    @Bindable var preferences: FileBrowserPreferences

    var body: some View {
        SettingsPaneForm(pane: .general) {
            Section {
                Picker("Language", selection: $preferences.language) {
                    ForEach(AppLanguagePreference.allCases) { language in
                        Text(AppLocalization.string(language.titleKey, locale: preferences.language.locale))
                            .tag(language)
                    }
                }
                .accessibilityIdentifier("settings-language")
            }
            FinderExtensionSettingsSection()
        }
    }
}

/// Everything about how the browser shows folders: the view of new windows, hidden files,
/// icon previews and the default List columns.
struct ViewOptionsSettingsPane: View {
    @Bindable var preferences: FileBrowserPreferences
    @State private var draggedListColumn: BrowserListColumn?
    @State private var listColumnDragStartIndex = 0
    @State private var listColumnRowFrames: [BrowserListColumn: CGRect] = [:]

    var body: some View {
        SettingsPaneForm(pane: .viewOptions) {
            Section {
                Picker("Default View", selection: $preferences.viewMode) {
                    ForEach(BrowserViewMode.allCases) { mode in
                        Label(
                            AppLocalization.string(mode.titleKey, locale: preferences.language.locale),
                            systemImage: mode.systemImage
                        ).tag(mode)
                    }
                }
                .accessibilityIdentifier("settings-default-view")
                Toggle("Show hidden files", isOn: $preferences.showHiddenFiles)
                    .accessibilityIdentifier("settings-show-hidden-files")
                Toggle("Show previews in icon view", isOn: $preferences.showIconPreviews)
                    .accessibilityIdentifier("settings-show-icon-previews")
            }
            Section("List Columns") {
                Text("Choose the columns shown by default. Drag them to change their order. A folder can override this layout from a column header.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(preferences.globalListColumns) { column in
                    listColumnRow(column)
                }
                ForEach(hiddenListColumns) { column in
                    listColumnRow(column)
                }
            }
        }
    }

    private var hiddenListColumns: [BrowserListColumn] {
        BrowserListColumn.selectable.filter { !preferences.globalListColumns.contains($0) }
    }

    /// One column choice. Visible columns after Name are dragged by the handle on their
    /// leading edge; other rows keep its space so the titles stay aligned. The one-step
    /// moves are offered as accessibility actions.
    private func listColumnRow(_ column: BrowserListColumn) -> some View {
        let index = preferences.globalListColumns.firstIndex(of: column)
        let isMovable = (index ?? 0) > 0
        return HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(draggedListColumn == column ? .secondary : .tertiary)
                .frame(width: 16)
                .frame(maxHeight: .infinity)
                .opacity(isMovable ? 1 : 0)
                .contentShape(Rectangle())
                .help(isMovable ? Text("Drag to reorder") : Text(verbatim: ""))
                .pointerStyle(isMovable ? (draggedListColumn == column ? .grabActive : .grabIdle) : nil)
                .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .global)
                    .onChanged { dragListColumn(column, translation: $0.translation.height) }
                    .onEnded { _ in draggedListColumn = nil }, isEnabled: isMovable)
                .accessibilityHidden(true)
            Toggle(column.title(locale: preferences.language.locale), isOn: Binding(
                get: { preferences.globalListColumns.contains(column) },
                set: { isVisible in
                    var columns = preferences.globalListColumns
                    if isVisible && !columns.contains(column) { columns.append(column) }
                    if !isVisible { columns.removeAll { $0 == column } }
                    preferences.setGlobalListColumns(columns)
                }
            ))
            .disabled(column == .name)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            listColumnRowFrames[column] = frame
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings-list-column-" + column.rawValue)
        .accessibilityActions {
            if let index, index > 1 {
                Button("Move column left") { preferences.moveGlobalListColumn(column, by: -1) }
            }
            if let index, index > 0, index < preferences.globalListColumns.count - 1 {
                Button("Move column right") { preferences.moveGlobalListColumn(column, by: 1) }
            }
        }
    }

    /// Live reordering: while the handle is dragged, the column takes the place of each
    /// visible row the pointer passes over, so releasing only ends the gesture.
    private func dragListColumn(_ column: BrowserListColumn, translation: CGFloat) {
        let columns = preferences.globalListColumns
        if draggedListColumn != column {
            draggedListColumn = column
            listColumnDragStartIndex = columns.firstIndex(of: column) ?? 0
        }
        // Only the distance between rows is read from their frames: it holds even
        // when the Form has scrolled since they were measured.
        let tops = columns.compactMap { listColumnRowFrames[$0]?.minY }.sorted()
        guard let first = tops.first, let last = tops.last, tops.count > 1 else { return }
        let index = ListColumnReorder.targetIndex(
            from: listColumnDragStartIndex, translation: translation,
            rowPitch: (last - first) / CGFloat(tops.count - 1), count: columns.count
        )
        withAnimation(.easeOut(duration: 0.15)) {
            preferences.moveGlobalListColumn(column, onto: columns[index])
        }
    }
}

struct SidebarSettingsPane: View {
    let preferences: FileBrowserPreferences

    var body: some View {
        SettingsPaneForm(pane: .sidebar) {
            SidebarSettingsSection(preferences: preferences)
        }
    }
}

struct CompressionSettingsPane: View {
    let preferences: FileBrowserPreferences
    let openProfile: (UUID) -> Void

    var body: some View {
        SettingsPaneForm(pane: .compression) {
            CompressionSettingsSection(preferences: preferences, openProfile: openProfile)
        }
    }
}

struct PreviewsSettingsPane: View {
    let preferences: FileBrowserPreferences

    var body: some View {
        SettingsPaneForm(pane: .previews) {
            ArchivePreviewSettingsSection(preferences: preferences)
            if ScaleSliderUIFixtureSection.isRequested {
                ScaleSliderUIFixtureSection()
            }
        }
    }
}

struct AutomationSettingsPane: View {
    var body: some View {
        SettingsPaneForm(pane: .automation) {
            AutomationSettingsSection()
        }
    }
}
