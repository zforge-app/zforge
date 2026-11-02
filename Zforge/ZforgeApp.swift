import AppKit
import SwiftUI

struct FileBrowserStateFocusedKey: FocusedValueKey {
    typealias Value = FileBrowserState
}

extension FocusedValues {
    var fileBrowserState: FileBrowserState? {
        get { self[FileBrowserStateFocusedKey.self] }
        set { self[FileBrowserStateFocusedKey.self] = newValue }
    }
}

struct ZforgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var preferences = FileBrowserPreferences.shared

    var body: some Scene {
        WindowGroup(
            "Zforge",
            id: "browser",
            for: BrowserWindowRequest.self
        ) { request in
            BrowserWindowRoot(request: request, appDelegate: appDelegate)
        } defaultValue: {
            appDelegate.makeDefaultWindowRequest()
        }
        .defaultSize(width: defaultWindowWidth, height: 720)
        // The unit test host opens no browser window (RNF-Q08).
        .defaultLaunchBehavior(UnitTestHostPresentation.isQuietLaunch ? .suppressed : .automatic)
        .environment(\.locale, preferences.language.locale)
        .commands {
            BrowserCommands()
            KeyboardShortcutHelpCommands()
            if ProcessInfo.processInfo.arguments.contains("--ui-fixtures"),
               ProcessInfo.processInfo.arguments.contains("--ui-contextual-permission") {
                CommandMenu("Automation test") {
                    Button("Disconnect test client") { AutomationPermissionUIFixture.disconnect() }
                }
            }
        }

        Settings {
            ZforgeSettingsView()
        }
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }

        Window("Keyboard Shortcuts", id: "keyboard-shortcuts") {
            KeyboardShortcutsView()
        }
        .defaultSize(width: 720, height: 680)
        .windowResizability(.contentMinSize)
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }
    }

    private var defaultWindowWidth: CGFloat {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--ui-window-width"),
              arguments.indices.contains(flagIndex + 1),
              let width = Double(arguments[flagIndex + 1]) else {
            return 1100
        }
        return CGFloat(width)
    }
}

private struct BrowserWindowRoot: View {
    @Environment(\.openWindow) private var openWindow
    @Binding var request: BrowserWindowRequest
    let appDelegate: AppDelegate
    @State private var hasAppeared = false

    var body: some View {
        ContentView(
            initialURL: request.initialURL,
            tabSourceWindowNumber: request.tabSourceWindowNumber,
            automationAccess: request.automationAccess,
            archiveSearch: request.archiveSearch,
            finderRequest: request.finderRequest
        )
            .id(request.id)
            .onAppear {
                // A file can arrive after SwiftUI computes the default scene value.
                // In that case, use the first new window for the archive.
                if !hasAppeared && request.initialURL == nil && request.archiveSearch == nil && request.finderRequest == nil,
                   let pending = appDelegate.takeNextArchiveRequest() {
                    appDelegate.releaseLaunchWindow(request.id)
                    request = pending
                }
                hasAppeared = true
                AutomationPermissionUIFixture.startIfRequested()
                openPendingArchives()
            }
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.archiveURLsReceived)) { _ in
                // A request that launched Zforge replaces its untouched launch
                // window, so the launch shows one window instead of two.
                if let pending = appDelegate.takeRequest(forLaunchWindow: request.id) {
                    request = pending
                }
                openPendingArchives()
            }
            .onDisappear { appDelegate.releaseLaunchWindow(request.id) }
    }

    private func openPendingArchives() {
        for pending in appDelegate.takePendingArchiveRequests() {
            openWindow(id: "browser", value: pending)
        }
    }
}

private struct BrowserCommands: Commands {
    @FocusedValue(\.fileBrowserState) private var browser
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Zforge Window") {
                openWindow(id: "browser", value: BrowserWindowRequest())
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New tab") {
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(
                        tabSourceWindowNumber: NSApp.keyWindow?.windowNumber
                    )
                )
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(browser == nil)

            Button(AppLocalization.string("New Folder", locale: browser?.preferences.language.locale)) {
                browser?.createNewFolder()
            }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(browser?.canModifyCurrentDirectory != true)
                .modifierKeyAlternate(.option) {
                    Button(AppLocalization.string("New Folder with Selection", locale: browser?.preferences.language.locale)) {
                        browser?.createNewFolderWithSelection()
                    }
                        // The shortcut's Control modifier must not become part
                        // of AppKit's visibility condition for the Option alternate.
                        .keyboardShortcut(nil)
                        .disabled(browser?.canCreateFolderWithSelection != true)
                }
        }

        CommandGroup(after: .newItem) {
            Button(AppLocalization.string("Open", locale: browser?.preferences.language.locale)) {
                browser?.openSelection()
            }
            .disabled(browser?.canOpenSelection != true)

            Menu(AppLocalization.string("Open with", locale: browser?.preferences.language.locale)) {
                if let browser {
                    ForEach(browser.applicationsForOpening(browser.selectedItems), id: \.self) { application in
                        Button(FileManager.default.displayName(atPath: application.path)) {
                            browser.openWith(browser.selectedItems, application: application)
                        }
                    }
                    Divider()
                    Button("Other…") {
                        browser.chooseApplicationForOpening(browser.selectedItems)
                    }
                }
            }
            .disabled(browser?.canOpenSelectionWithApplication != true)
            .modifierKeyAlternate(.option) {
                Menu(AppLocalization.string("Always open with", locale: browser?.preferences.language.locale)) {
                    if let browser {
                        ForEach(browser.applicationsForOpening(browser.selectedItems), id: \.self) { application in
                            Button(FileManager.default.displayName(atPath: application.path)) {
                                browser.openWith(browser.selectedItems, application: application, always: true)
                            }
                        }
                        Divider()
                        Button("Other…") {
                            browser.chooseApplicationForOpening(browser.selectedItems, always: true)
                        }
                    }
                }
                .disabled(browser?.canAlwaysOpenSelectionWithApplication != true)
            }
            Divider()
            Button("Duplicate") { browser?.duplicateSelectedFiles() }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(browser?.hasLocalSelection != true)
            Button("Get Info") { browser?.showGetInfo() }
                .keyboardShortcut("i", modifiers: .command)
                .disabled(browser?.selectedItems.isEmpty != false)
            Button("Show Original") { browser?.showOriginal() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(browser?.canShowOriginal != true)
            Button("Make Alias") { browser?.makeAliasesForSelection() }
                .keyboardShortcut("a", modifiers: [.control, .command])
                .disabled(browser?.hasLocalSelection != true)
            Button("Rename") { browser?.beginRenamingSelectedItem() }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(browser?.canRenameSelection != true || browser?.searchFieldHasFocus == true)
            Divider()
            Button("Quick Look") { browser?.openQuickLook() }
                .keyboardShortcut("y", modifiers: .command)
                .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                .modifierKeyAlternate(.option) {
                    Button("Slideshow") { browser?.openQuickLook(slideshow: true) }
                        .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                }
            Divider()
            Button(browser?.canRemoveArchiveItems(browser?.selectedItems ?? []) == true ? "Remove from Archive…" : "Move to Trash") {
                if let browser, browser.canRemoveArchiveItems(browser.selectedItems) { browser.requestArchiveRemoval() }
                else { browser?.moveSelectionToTrash() }
            }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(browser?.hasLocalSelection != true && browser?.canRemoveArchiveItems(browser?.selectedItems ?? []) != true
                    || browser?.searchFieldHasFocus == true)
            Button("Delete Immediately…") { browser?.requestPermanentDeletion() }
                .keyboardShortcut(.delete, modifiers: [.option, .command])
                .disabled(browser?.hasLocalSelection != true || browser?.searchFieldHasFocus == true)
            Button("Eject") { browser?.ejectSelectedVolume() }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(browser?.canEjectSelection != true)
            Divider()
            Button("Find") { browser?.beginSearch() }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(browser == nil)
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                if NSApp.keyWindow?.firstResponder is NSTextView {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                } else if browser?.copySelectionToPasteboard() != true {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Paste") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: .command)
            .modifierKeyAlternate(.option) {
                Button("Move Items Here") { browser?.moveClipboardItemsHere() }
                    .disabled(browser?.canModifyCurrentDirectory != true)
            }

            Button("Paste and Match Style") {
                NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: [.option, .shift, .command])
        }

        CommandMenu("Go") {
            Button("Computer") { Task { await browser?.navigateToComputer() } }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            Button("Desktop") { Task { await browser?.navigateToDesktop() } }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button("Recents") { Task { await browser?.navigateToRecents() } }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            Button("Go to Folder…") { browser?.showingGoToFolder = true }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            Button("Home") { Task { await browser?.navigateToHome() } }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            Button("Network") { Task { await browser?.navigateToNetwork() } }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            Button("Downloads") { Task { await browser?.navigateToDownloads() } }
                .keyboardShortcut("l", modifiers: [.option, .command])
            Button("Documents") { Task { await browser?.navigateToDocuments() } }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button("Remote") { browser?.showServerConnection() }
                .keyboardShortcut("k", modifiers: .command)
            Button("Open Enclosing Folder in New Window") {
                if let parent = browser?.parentDirectoryURL {
                    openWindow(
                        id: "browser",
                        value: BrowserWindowRequest(initialURL: parent)
                    )
                }
            }
            .keyboardShortcut(.upArrow, modifiers: [.control, .command])
            .disabled(browser?.parentDirectoryURL == nil)
        }

        CommandGroup(after: .sidebar) {
            Button("Back") { Task { await browser?.goBack() } }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(browser?.canGoBack != true)
            Button("Forward") { Task { await browser?.goForward() } }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(browser?.canGoForward != true)
            Button("Enclosing Folder") { Task { await browser?.goUp() } }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button("Open") { Task { if let item = browser?.primarySelection { await browser?.open(item) } } }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Button("Icons") { browser?.viewMode = .icons }
                .keyboardShortcut("1", modifiers: .command)
            Button("List") { browser?.viewMode = .list }
                .keyboardShortcut("2", modifiers: .command)
            Button("Columns") { browser?.viewMode = .columns }
                .keyboardShortcut("3", modifiers: .command)
            Button("Gallery") { browser?.viewMode = .gallery }
                .keyboardShortcut("4", modifiers: .command)
            Divider()
            Button("Zoom In") { browser?.preferences.zoomIn() }
                .keyboardShortcut("=", modifiers: .command)
                .modifierKeyAlternate(.shift) {
                    Button("Zoom In") { browser?.preferences.zoomIn() }
                        .keyboardShortcut("+", modifiers: .command)
                }
            Button("Zoom Out") { browser?.preferences.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size") { browser?.preferences.resetZoom() }
                .keyboardShortcut("0", modifiers: .command)
            Divider()
            Button("Show Hidden Files") { browser?.toggleHiddenFiles() }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            Button(browser?.previewVisible == true ? "Hide Preview" : "Show Preview") {
                browser?.togglePreviewVisibility()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Quick Look") { browser?.openQuickLook() }
                .keyboardShortcut(.space, modifiers: [])
        }

    }
}

private struct KeyboardShortcutHelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Keyboard Shortcuts…") {
                openWindow(id: "keyboard-shortcuts")
            }
            .keyboardShortcut("/", modifiers: .command)
        }
    }
}

struct ZforgeSettingsView: View {
    @State private var preferences = FileBrowserPreferences.shared
    @State private var compressionDraft = CompressionDraft(preferences: .shared)
    @State private var draggedListColumn: BrowserListColumn?
    @State private var listColumnDragStartIndex = 0
    @State private var listColumnRowFrames: [BrowserListColumn: CGRect] = [:]

    var body: some View {
        Form {
            Picker("Language", selection: $preferences.language) {
                ForEach(AppLanguagePreference.allCases) { language in
                    Text(AppLocalization.string(language.titleKey, locale: preferences.language.locale))
                        .tag(language)
                }
            }
            .accessibilityIdentifier("settings-language")
            Picker("Default View", selection: $preferences.viewMode) {
                ForEach(BrowserViewMode.allCases) { mode in
                    Label(
                        AppLocalization.string(mode.titleKey, locale: preferences.language.locale),
                        systemImage: mode.systemImage
                    ).tag(mode)
                }
            }
            Toggle("Show hidden files", isOn: $preferences.showHiddenFiles)
            Toggle("Show previews in icon view", isOn: $preferences.showIconPreviews)
                .accessibilityIdentifier("settings-show-icon-previews")

            AutomationSettingsSection()

            FinderExtensionSettingsSection()

            SidebarSettingsSection(preferences: preferences)

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

            CompressionSettingsSection(preferences: preferences, draft: compressionDraft)

            ArchiveNavigationSettingsSection(preferences: preferences)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 600, height: 760)
        .environment(\.locale, preferences.language.locale)
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

/// Where a dragged Settings column row lands: one place per row pitch travelled from
/// where the drag started, never before Name (index 0) or past the last visible column.
enum ListColumnReorder {
    static func targetIndex(from start: Int, translation: CGFloat, rowPitch: CGFloat, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let steps = rowPitch > 0 ? Int((translation / rowPitch).rounded()) : 0
        return min(max(start + steps, 1), count - 1)
    }
}

/// The Settings section that chooses the default compression profile and edits profiles.
/// The nesting depth uses a linear slider with a stop per value; the root size limit uses
/// a logarithmic one whose fine steps and held round values are defined by
/// `ArchiveSizeLimitSliderScale`.
struct ArchiveNavigationSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences

    private static let depthScale = LinearSettingsSliderScale(
        range: Int64(ArchiveBrowsingPolicy.nestingDepthRange.lowerBound)...Int64(ArchiveBrowsingPolicy.nestingDepthRange.upperBound)
    )
    private static let sizeScale = ArchiveSizeLimitSliderScale()

    var body: some View {
        let locale = preferences.language.locale
        Section("Archive Navigation") {
            VStack(alignment: .leading, spacing: 5) {
                LabeledContent("Maximum nesting depth") {
                    Text(preferences.archiveNestingLimit.formatted())
                        .monospacedDigit()
                }
                ScaleSlider(
                    scale: Self.depthScale,
                    value: Binding(
                        get: { Int64(preferences.archiveNestingLimit) },
                        set: { preferences.archiveNestingLimit = Int($0) }
                    ),
                    tickLabels: ArchiveBrowsingPolicy.nestingDepthRange.map { $0.formatted(.number.locale(locale)) },
                    accessibilityLabel: AppLocalization.string("Maximum nesting depth", locale: locale),
                    accessibilityIdentifier: "settings-archive-nesting-depth",
                    describe: { $0.formatted(.number.locale(locale)) }
                )
                Text("Limits how many compressed files can be opened inside one another. The root archive is not counted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 5) {
                LabeledContent("Root archive size limit") {
                    Text(AppLocalization.byteCount(preferences.archiveRootSizeLimit, locale: locale))
                        .monospacedDigit()
                }
                ScaleSlider(
                    scale: Self.sizeScale,
                    value: $preferences.archiveRootSizeLimit,
                    tickLabels: ArchiveSizeLimitSliderScale.doublings.map { AppLocalization.byteCount($0, locale: locale) },
                    accessibilityLabel: AppLocalization.string("Root archive size limit", locale: locale),
                    accessibilityIdentifier: "settings-archive-root-size-limit",
                    describe: { AppLocalization.byteCount($0, locale: locale) }
                )
                Text("Sub-archives are only navigable when the combined size of the root archive and its volumes is below this limit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CompressionSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences
    let draft: CompressionDraft

    var body: some View {
        Section("Compression") {
            Picker("Default compression profile", selection: $preferences.defaultCompressionProfileID) {
                ForEach(preferences.compressionProfiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
            }
            CompressionProfileEditor(draft: draft, preferences: preferences)
                .onChange(of: preferences.defaultCompressionProfileID) { _, id in
                    if let profile = preferences.compressionProfiles.first(where: { $0.id == id }) {
                        draft.load(profile, preferences: preferences)
                    }
                }
        }
    }
}
