import AppKit
import SwiftUI

enum BrowserToolbarLayout {
    enum Stage: Equatable {
        case unifiedOverflow
        case compactWithActionsOverflow
        case compactWithArchiveAction
        case expanded
    }

    static func stage(for windowWidth: CGFloat) -> Stage {
        if windowWidth < 678 { return .unifiedOverflow }
        if windowWidth < 840 { return .compactWithActionsOverflow }
        if windowWidth < 900 { return .compactWithArchiveAction }
        return .expanded
    }
}

nonisolated enum PermanentDeletionConfirmationChoice: Hashable {
    case cancel
    case delete
}

nonisolated enum PermanentDeletionConfirmationDirection {
    case left
    case right
    case up
    case down
}

nonisolated enum PermanentDeletionConfirmationNavigation {
    nonisolated static func nextChoice(
        after currentChoice: PermanentDeletionConfirmationChoice?,
        moving direction: PermanentDeletionConfirmationDirection
    ) -> PermanentDeletionConfirmationChoice {
        guard currentChoice != nil else { return .cancel }

        switch direction {
        case .left, .up:
            return .cancel
        case .right, .down:
            return .delete
        }
    }
}

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.undoManager) private var undoManager
    @State private var browser: FileBrowserState
    @State private var sidebar = SidebarState()
    @State private var dragSession = BrowserFileDragSession()
    @State private var authorizationPanelPresented = false
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?
    @State private var focusRestoreTask: Task<Void, Never>?
    @State private var toolbarOverflowMenuPresented = false
    @FocusState private var browserFocus: BrowserFocusTarget?
    let tabSourceWindowNumber: Int?

    init(initialURL: URL? = nil, tabSourceWindowNumber: Int? = nil) {
        _browser = State(initialValue: FileBrowserState(initialURL: initialURL))
        self.tabSourceWindowNumber = tabSourceWindowNumber
    }

    var body: some View {
        GeometryReader { geometry in
            browserLayout(windowWidth: geometry.size.width)
        }
        .frame(minWidth: 640, minHeight: 460)
    }

    @ViewBuilder
    private func browserLayout(windowWidth: CGFloat) -> some View {
        NavigationSplitView {
            BrowserSidebar(
                browser: browser,
                sidebar: sidebar,
                windowWidth: windowWidth,
                showingServerSheet: serverSheetBinding,
                restoreContentFocus: restoreContentFocus,
                dragSession: dragSession
            )
            .toolbar(removing: .sidebarToggle)
            .toolbar { browserNavigationToolbar }
        } detail: {
            VStack(spacing: 0) {
                if browser.pendingAuthorizationURL != nil && browser.items.isEmpty {
                    authorizationPlaceholder
                } else {
                    BrowserContent(
                        state: browser,
                        contentFocus: $browserFocus,
                        dragSession: dragSession
                    )
                }
                BrowserBreadcrumb(state: browser)
            }
            .background(Color(nsColor: .underPageBackgroundColor))
            .navigationTitle(browser.title)
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .toolbar { browserPrimaryToolbar(windowWidth: windowWidth) }
        }
        .environment(\.locale, browser.preferences.language.locale)
        .focusedSceneValue(\.fileBrowserState, browser)
        .background {
            BrowserWindowConfigurationView(
                representedURL: browser.currentDirectoryURL,
                tabSourceWindowNumber: tabSourceWindowNumber
            )
                .frame(width: 0, height: 0)
        }
        .task {
            browser.configureUndoManager(undoManager)
            await browser.start()
            restoreContentFocus()
        }
        .onAppear {
            browser.configureUndoManager(undoManager)
            browser.configureOpenWindowAction { url in
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(initialURL: url)
                )
            }
            applyUITestWindowWidthIfNeeded()
            restoreContentFocus()
        }
        .onChange(of: browser.preferences.viewMode) { previousViewMode, viewMode in
            if viewMode == .columns {
                browser.prepareColumnView()
            } else if previousViewMode == .columns {
                browser.prepareStandardViewAfterColumns()
            }
            if viewMode == .list,
               browser.preferences.visibleListColumns(for: browser.location).contains(where: {
                   [.lastOpenedDate, .dateAdded, .version, .comments].contains($0)
               }) {
                Task { await browser.reload() }
            }
            browser.updatePreview()
            restoreContentFocus()
        }
        .onChange(of: browser.previewVisible) { _, _ in restoreContentFocus() }
        .onChange(of: browser.location) { _, _ in restoreContentFocus() }
        .onChange(of: FinderTagCatalog.shared.revision) { _, _ in browser.refreshTagResults() }
        .onChange(of: browser.isLoading) { _, isLoading in
            if !isLoading { restoreContentFocus() }
        }
        .onChange(of: browser.contextualFeedbackMessage) { _, message in
            if let message {
                showToast(message)
                browser.contextualFeedbackMessage = nil
            }
        }
        .onChange(of: browser.pendingAuthorizationURL) { _, url in
            if let url { presentAuthorizationPanel(for: url) }
        }
        .onDisappear {
            toastDismissTask?.cancel()
            focusRestoreTask?.cancel()
            browser.close()
        }
        .sheet(isPresented: serverSheetBinding, onDismiss: restoreContentFocus) {
            ServerConnectionSheet(sidebar: sidebar) { url in
                Task { await browser.navigateToSidebar(url, name: url.lastPathComponent) }
            }
        }
        .sheet(isPresented: goToFolderBinding, onDismiss: restoreContentFocus) {
            GoToFolderSheet(browser: browser)
        }
        .sheet(isPresented: passwordSheetBinding, onDismiss: restoreContentFocus) {
            ArchivePasswordSheet(state: browser)
        }
        .sheet(isPresented: permanentDeletionBinding, onDismiss: restoreContentFocus) {
            if let request = browser.pendingPermanentDeletion {
                PermanentDeletionConfirmationSheet(
                    itemCount: request.itemCount,
                    confirm: browser.confirmPermanentDeletion,
                    cancel: { browser.pendingPermanentDeletion = nil }
                )
                .presentationSizing(.fitted)
            }
        }
        .alert("Zforge", isPresented: errorBinding, presenting: browser.error) { _ in
            Button("OK") {
                browser.error = nil
                restoreContentFocus()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .confirmationDialog(
            "Large Archive Item",
            isPresented: largeOperationBinding,
            titleVisibility: .visible,
            presenting: browser.pendingLargeOperation
        ) { _ in
            Button("Continue") {
                Task { await browser.confirmLargeOperation() }
                restoreContentFocus()
            }
            Button("Cancel", role: .cancel) {
                browser.pendingLargeOperation = nil
                restoreContentFocus()
            }
        } message: { operation in
            Text("Extracting \(operation.item.name) may require more than 1 GB of temporary disk space.")
        }
        .confirmationDialog(
            "Modify Archive?",
            isPresented: archiveAdditionBinding,
            titleVisibility: .visible,
            presenting: browser.pendingArchiveAddition
        ) { _ in
            Button("Add to Archive") {
                Task { await browser.confirmArchiveAddition() }
                restoreContentFocus()
            }
            Button("Cancel", role: .cancel) {
                browser.pendingArchiveAddition = nil
                restoreContentFocus()
            }
        } message: { request in
            let count = request.sourceURLs.count
            let template: String.LocalizationValue = count == 1
                ? "Add %lld item to %@? The archive will be modified."
                : "Add %lld items to %@? The archive will be modified."
            Text(String(format: AppLocalization.string(
                template,
                locale: browser.preferences.language.locale
            ), Int64(count), request.archiveURL.lastPathComponent))
        }
        .overlay {
            if browser.fileOperationInProgress {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(browser.fileOperationDescription)
                }
                .padding(22)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                .accessibilityIdentifier("file-operation-progress")
            } else if browser.archiveOperationInProgress {
                VStack(spacing: 12) {
                    if let fraction = browser.archiveProgress?.fraction {
                        ProgressView(value: fraction)
                            .frame(width: 180)
                    } else {
                        ProgressView()
                    }
                    Text(browser.archiveOperationDescription)
                    Button("Cancel") { browser.cancelArchiveOperation() }
                }
                .padding(22)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.top, 12)
                    .accessibilityIdentifier("browser-toast")
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ToolbarContentBuilder
    private var browserNavigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: 8) {
                Button {
                    NSApp.sendAction(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        to: nil,
                        from: nil
                    )
                    restoreContentFocus()
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .focusable(false)
                .help("Toggle Sidebar")
                .accessibilityLabel("Toggle Sidebar")

                ControlGroup {
                    Button { Task { await browser.goBack() } } label: { Image(systemName: "chevron.left") }
                        .disabled(!browser.canGoBack)
                        .focusable(false)
                        .help("Back")
                    Button { Task { await browser.goForward() } } label: { Image(systemName: "chevron.right") }
                        .disabled(!browser.canGoForward)
                        .focusable(false)
                        .help("Forward")
                }
                .id("browser-navigation")
                .focusable(false)
            }
            .focusable(false)
        }
    }

    @ToolbarContentBuilder
    private func browserPrimaryToolbar(windowWidth: CGFloat) -> some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .primaryAction)
        switch BrowserToolbarLayout.stage(for: windowWidth) {
        case .unifiedOverflow:
            ToolbarItem(id: "toolbar-overflow-menu-unified", placement: .primaryAction) {
                Button {
                    showToolbarActionsMenu(
                        includesViewSelector: true,
                        includesArchiveAction: true,
                        includesShareAction: true,
                        tracksOverflowPresentation: true
                    )
                } label: {
                    ToolbarOverflowIcon(isActive: toolbarOverflowMenuPresented)
                }
                .focusable(false)
                .accessibilityIdentifier("toolbar-overflow-menu")
                .accessibilityValue(toolbarOverflowMenuPresented ? "Expanded" : "Collapsed")
                .help("More")
                .accessibilityLabel("More")
            }
        case .compactWithActionsOverflow:
            ToolbarItem(id: "view-mode-selector-compact-actions", placement: .primaryAction) {
                ViewModeToolbarControl(
                    selection: $browser.preferences.viewMode,
                    usesCompactPresentation: true
                )
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(id: "toolbar-overflow-menu-compact-actions", placement: .primaryAction) {
                Button {
                    showToolbarActionsMenu(
                        includesViewSelector: false,
                        includesArchiveAction: true,
                        includesShareAction: true,
                        tracksOverflowPresentation: true
                    )
                } label: {
                    ToolbarOverflowIcon(isActive: toolbarOverflowMenuPresented)
                }
                .focusable(false)
                .accessibilityIdentifier("toolbar-overflow-menu")
                .accessibilityValue(toolbarOverflowMenuPresented ? "Expanded" : "Collapsed")
                .help("More")
                .accessibilityLabel("More")
            }
        case .compactWithArchiveAction:
            ToolbarItem(id: "view-mode-selector-compact-archive", placement: .primaryAction) {
                ViewModeToolbarControl(
                    selection: $browser.preferences.viewMode,
                    usesCompactPresentation: true
                )
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(id: "archive-contextual-action-compact", placement: .primaryAction) {
                Button {
                    performArchiveToolbarAction()
                } label: {
                    ArchiveOperationIcon(isExtracting: browser.archiveToolbarAction.usesExtractionIcon)
                }
                .disabled(!browser.archiveToolbarAction.isEnabled)
                .focusable(false)
                .accessibilityIdentifier("archive-contextual-action")
                .help(browser.archiveToolbarAction.title)
                .accessibilityLabel(browser.archiveToolbarAction.title)
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(id: "toolbar-overflow-menu-compact-archive", placement: .primaryAction) {
                Button {
                    showToolbarActionsMenu(
                        includesViewSelector: false,
                        includesArchiveAction: false,
                        includesShareAction: true,
                        tracksOverflowPresentation: true
                    )
                } label: {
                    ToolbarOverflowIcon(isActive: toolbarOverflowMenuPresented)
                }
                .focusable(false)
                .accessibilityIdentifier("toolbar-overflow-menu")
                .accessibilityValue(toolbarOverflowMenuPresented ? "Expanded" : "Collapsed")
                .help("More")
                .accessibilityLabel("More")
            }
        case .expanded:
            ToolbarItem(id: "view-mode-selector-expanded", placement: .primaryAction) {
                ViewModeToolbarControl(
                    selection: $browser.preferences.viewMode,
                    usesCompactPresentation: false
                )
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    performArchiveToolbarAction()
                } label: {
                    ArchiveOperationIcon(isExtracting: browser.archiveToolbarAction.usesExtractionIcon)
                }
                .disabled(!browser.archiveToolbarAction.isEnabled)
                .focusable(false)
                .accessibilityIdentifier("archive-contextual-action")
                .help(browser.archiveToolbarAction.title)
                .accessibilityLabel(browser.archiveToolbarAction.title)

                Button {
                    browser.shareItems()
                } label: {
                    ToolbarActionIcon(kind: .share)
                }
                .disabled(!canShareSelection)
                .focusable(false)
                .help("Share")
                .accessibilityLabel("Share")

                Button {
                    showToolbarActionsMenu(
                        includesViewSelector: false,
                        includesArchiveAction: false,
                        includesShareAction: false
                    )
                } label: {
                    ToolbarActionIcon(kind: .more)
                }
                .help("More")
                .focusable(false)
                .accessibilityLabel("More")
                .accessibilityIdentifier("toolbar-more-menu")
            }
        }
    }

    private var canShareSelection: Bool {
        browser.selectedItems.contains { !$0.isContainer }
    }

    private func performArchiveToolbarAction() {
        let action = browser.archiveToolbarAction
        guard action.isEnabled else { return }
        Task {
            if let message = await browser.performArchiveToolbarAction() {
                showToast(message)
            }
            restoreContentFocus()
        }
    }

    private func showToolbarActionsMenu(
        includesViewSelector: Bool,
        includesArchiveAction: Bool,
        includesShareAction: Bool,
        tracksOverflowPresentation: Bool = false
    ) {
        guard let event = NSApp.currentEvent,
              let contentView = event.window?.contentView else { return }

        let locale = browser.preferences.language.locale
        let menu: NSMenu = tracksOverflowPresentation
            ? TrackedToolbarMenu(
                onOpen: { toolbarOverflowMenuPresented = true },
                onClose: { toolbarOverflowMenuPresented = false }
            )
            : NSMenu()
        func addItem(
            _ title: String.LocalizationValue,
            systemImage: String,
            isEnabled: Bool,
            handler: @escaping @MainActor () -> Void
        ) {
            menu.addItem(
                ClosureMenuItem(
                    title: AppLocalization.string(title, locale: locale),
                    systemImage: systemImage,
                    isEnabled: isEnabled,
                    handler: handler
                )
            )
        }

        if includesViewSelector {
            let viewItem = NSMenuItem(
                title: AppLocalization.string("View", locale: locale),
                action: nil,
                keyEquivalent: ""
            )
            viewItem.image = NSImage(
                systemSymbolName: browser.preferences.viewMode.systemImage,
                accessibilityDescription: viewItem.title
            )
            let viewMenu = NSMenu(title: viewItem.title)
            for mode in BrowserViewMode.allCases {
                let modeItem = ClosureMenuItem(
                    title: mode.title(locale: locale),
                    systemImage: mode.systemImage,
                    isEnabled: true
                ) {
                    browser.preferences.viewMode = mode
                }
                modeItem.state = mode == browser.preferences.viewMode ? .on : .off
                viewMenu.addItem(modeItem)
            }
            viewItem.submenu = viewMenu
            menu.addItem(viewItem)
            menu.addItem(.separator())
        }

        if includesArchiveAction && browser.selectedItems.isEmpty {
            let archiveAction = browser.archiveToolbarAction
            menu.addItem(
                ClosureMenuItem(
                    title: archiveAction.title(locale: locale),
                    systemImage: "archivebox",
                    isEnabled: archiveAction.isEnabled,
                    handler: performArchiveToolbarAction
                )
            )
        }
        if includesShareAction {
            addItem("Share", systemImage: "square.and.arrow.up", isEnabled: canShareSelection) {
                browser.shareItems()
            }
        }
        if (includesArchiveAction && browser.selectedItems.isEmpty) || includesShareAction {
            menu.addItem(.separator())
        }

        let selected = browser.selectedItems
        addItem("Open", systemImage: "arrow.up.forward.app", isEnabled: !selected.isEmpty) {
            Task { _ = await browser.performContextualAction(.open, items: selected) }
        }
        for action in browser.contextualActions(for: selected) where action != .open {
            menu.addItem(
                ClosureMenuItem(
                    title: browser.contextualTitle(action, items: selected),
                    systemImage: action.systemImage,
                    isEnabled: !browser.archiveOperationInProgress
                ) {
                    Task {
                        if let message = await browser.performContextualAction(action, items: selected) {
                            showToast(message)
                        }
                        restoreContentFocus()
                    }
                }
            )
        }
        addItem("Quick Look", systemImage: "eye", isEnabled: browser.primarySelection != nil) {
            browser.openQuickLook()
        }
        addItem("Get Info", systemImage: "info.circle", isEnabled: browser.primarySelection != nil) {
            browser.showGetInfo()
        }
        menu.addItem(.separator())
        addItem("Add Tag", systemImage: "tag", isEnabled: false) { }
        addItem("Rename", systemImage: "pencil", isEnabled: browser.canRenameSelection) {
            browser.beginRenamingSelectedItem()
        }
        addItem("Duplicate", systemImage: "plus.square.on.square", isEnabled: browser.hasLocalSelection) {
            browser.duplicateSelectedFiles()
        }

        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
        restoreContentFocus()
    }

    private func restoreContentFocus() {
        focusRestoreTask?.cancel()
        focusRestoreTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, browser.renamingItemID == nil else { return }
            if browserFocus != .content {
                browserFocus = .content
            }
            focusRestoreTask = nil
        }
    }

    private func applyUITestWindowWidthIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--ui-window-width"),
              arguments.indices.contains(flagIndex + 1),
              let width = Double(arguments[flagIndex + 1]) else { return }

        Task { @MainActor in
            await Task.yield()
            guard let window = NSApp.keyWindow ?? NSApp.windows.first else { return }
            window.setContentSize(NSSize(width: width, height: window.contentView?.bounds.height ?? 720))
        }
    }

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.18)) {
            toastMessage = message
        }
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.18)) {
                toastMessage = nil
            }
        }
    }

    private var authorizationPlaceholder: some View {
        ContentUnavailableView {
            Label("Folder Access Required", systemImage: "folder.badge.questionmark")
        } description: {
            Text("Zforge needs your permission to browse this location. Access is remembered securely for future windows.")
        } actions: {
            Button("Choose Folder…") {
                if let url = browser.pendingAuthorizationURL { presentAuthorizationPanel(for: url) }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var passwordSheetBinding: Binding<Bool> {
        Binding(
            get: { browser.passwordOperation != nil },
            set: { if !$0 { browser.passwordOperation = nil; browser.passwordError = nil } }
        )
    }

    private var serverSheetBinding: Binding<Bool> {
        Binding(
            get: { browser.showingServerConnection },
            set: { browser.showingServerConnection = $0 }
        )
    }

    private var goToFolderBinding: Binding<Bool> {
        Binding(
            get: { browser.showingGoToFolder },
            set: { browser.showingGoToFolder = $0 }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { browser.error != nil }, set: { if !$0 { browser.error = nil } })
    }

    private var largeOperationBinding: Binding<Bool> {
        Binding(
            get: { browser.pendingLargeOperation != nil },
            set: { if !$0 { browser.pendingLargeOperation = nil } }
        )
    }

    private var permanentDeletionBinding: Binding<Bool> {
        Binding(
            get: { browser.pendingPermanentDeletion != nil },
            set: { if !$0 { browser.pendingPermanentDeletion = nil } }
        )
    }

    private var archiveAdditionBinding: Binding<Bool> {
        Binding(
            get: { browser.pendingArchiveAddition != nil },
            set: { if !$0 { browser.pendingArchiveAddition = nil } }
        )
    }

    private func presentAuthorizationPanel(for intendedURL: URL) {
        guard !authorizationPanelPresented else { return }
        authorizationPanelPresented = true
        let panel = NSOpenPanel()
        panel.title = AppLocalization.string(
            "Allow Zforge to Access This Folder",
            locale: browser.preferences.language.locale
        )
        panel.message = AppLocalization.string(
            "Choose the requested folder or one of its parents.",
            locale: browser.preferences.language.locale
        )
        panel.directoryURL = intendedURL
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.begin { response in
            authorizationPanelPresented = false
            guard response == .OK, let selectedURL = panel.url else { return }
            Task { await browser.authorize(selectedURL, intendedURL: intendedURL) }
        }
    }
}

private struct ViewModeToolbarControl: View {
    @Environment(\.locale) private var locale

    @Binding var selection: BrowserViewMode
    let usesCompactPresentation: Bool

    var body: some View {
        Group {
            if usesCompactPresentation {
                compactMenu
            } else {
                Picker("View", selection: $selection) {
                    ForEach(BrowserViewMode.allCases) { mode in
                        Label(mode.title(locale: locale), systemImage: mode.systemImage)
                            .tag(mode)
                            .accessibilityIdentifier("view-mode-\(mode.rawValue)")
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize(horizontal: true, vertical: false)
                .focusable(false)
            }
        }
        .help("View Options")
    }

    private var compactMenu: some View {
        Button {
            ViewModeMenuPresenter.show(selected: selection, locale: locale) { mode in
                selection = mode
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: selection.systemImage)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 42, minHeight: 28)
            .padding(.horizontal, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .focusable(false)
        .accessibilityIdentifier("view-mode-selector-compact")
        .accessibilityLabel("View")
        .fixedSize(horizontal: true, vertical: false)
    }
}

private enum ViewModeMenuPresenter {
    static func show(
        selected: BrowserViewMode,
        locale: Locale,
        onSelect: @escaping (BrowserViewMode) -> Void
    ) {
        guard let event = NSApp.currentEvent,
              let contentView = event.window?.contentView else { return }

        let menu = NSMenu()
        for mode in BrowserViewMode.allCases {
            let item = ClosureMenuItem(
                title: mode.title(locale: locale),
                systemImage: mode.systemImage,
                isEnabled: true
            ) {
                onSelect(mode)
            }
            item.state = mode == selected ? .on : .off
            menu.addItem(item)
        }
        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
    }
}

nonisolated private final class TrackedToolbarMenu: NSMenu, NSMenuDelegate {
    private let onOpen: @MainActor () -> Void
    private let onClose: @MainActor () -> Void

    @MainActor
    init(onOpen: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) {
        self.onOpen = onOpen
        self.onClose = onClose
        super.init(title: "")
        delegate = self
    }

    @MainActor
    func menuWillOpen(_ menu: NSMenu) {
        onOpen()
    }

    @MainActor
    func menuDidClose(_ menu: NSMenu) {
        onClose()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }
}

nonisolated private final class ClosureMenuItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    @MainActor
    init(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        handler: @escaping @MainActor () -> Void
    ) {
        self.handler = handler
        super.init(title: title, action: #selector(performAction), keyEquivalent: "")
        target = self
        image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        self.isEnabled = isEnabled
    }

    @MainActor @objc private func performAction() {
        handler()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }
}

private extension ArchiveToolbarAction {
    var titleKey: String.LocalizationValue {
        switch self {
        case .extractAll: "Extract All"
        case .extractSelected, .unavailableInsideArchive: "Extract Selected"
        case .compress, .unavailableOutsideArchive: "Compress Selected"
        }
    }

    var title: String {
        AppLocalization.string(titleKey)
    }

    func title(locale: Locale) -> String {
        AppLocalization.string(titleKey, locale: locale)
    }

    var feedbackMessage: String {
        switch self {
        case .extractAll: AppLocalization.string("Extract all selected archives.")
        case .extractSelected: AppLocalization.string("Extract selected items.")
        case .compress: AppLocalization.string("Compress selected items.")
        case .unavailableInsideArchive, .unavailableOutsideArchive: title
        }
    }
}

private struct ArchiveOperationIcon: View {
    let isExtracting: Bool

    var body: some View {
        ZStack {
            Image(systemName: "archivebox")
                .font(.system(size: 14, weight: .regular))
            Image(systemName: isExtracting ? "arrow.up" : "arrow.down")
                .font(.system(size: 6, weight: .black))
                .offset(y: -1)
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

private struct ToolbarActionIcon: View {
    enum Kind {
        case share
        case more
    }

    let kind: Kind

    var body: some View {
        Image(systemName: kind == .share ? "square.and.arrow.up" : "ellipsis")
            .font(.system(size: 15, weight: .regular))
            .frame(width: 25, height: 18)
            .accessibilityHidden(true)
    }
}

private struct ToolbarOverflowIcon: View {
    let isActive: Bool

    var body: some View {
        Image(systemName: "chevron.right.2")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
    }
}

struct PermanentDeletionConfirmationSheet: View {
    let itemCount: Int
    let confirm: () -> Void
    let cancel: () -> Void

    @State private var selectedChoice: PermanentDeletionConfirmationChoice?
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Delete Immediately?")
                .font(.headline)

            if itemCount == 1 {
                Text("The selected item will be deleted immediately. This action cannot be undone.")
            } else {
                Text("The selected items will be deleted immediately. This action cannot be undone.")
            }

            HStack(spacing: 8) {
                Button("Cancel", role: .cancel, action: cancel)
                    .focusable(false)
                    .buttonStyle(PermanentDeletionConfirmationButtonStyle())
                    .permanentDeletionKeyboardSelection(selectedChoice == .cancel)
                Button("Delete", role: .destructive, action: confirm)
                    .focusable(false)
                    .buttonStyle(PermanentDeletionConfirmationButtonStyle(isDestructive: true))
                    .permanentDeletionKeyboardSelection(selectedChoice == .delete)
            }
        }
        .padding(20)
        .frame(width: 280)
        .focusable()
        .focusEffectDisabled()
        .focused($hasKeyboardFocus)
        .onKeyPress(
            keys: [.leftArrow, .rightArrow, .upArrow, .downArrow, .return, .escape]
        ) { keyPress in
            handleKeyPress(keyPress)
        }
        .task {
            await Task.yield()
            hasKeyboardFocus = true
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        if keyPress.key == .escape {
            cancel()
            return .handled
        }

        if keyPress.key == .return {
            switch selectedChoice {
            case .cancel:
                cancel()
            case .delete:
                confirm()
            case nil:
                break
            }
            return .handled
        }

        guard let direction = direction(for: keyPress.key) else { return .ignored }
        selectedChoice = PermanentDeletionConfirmationNavigation.nextChoice(
            after: selectedChoice,
            moving: direction
        )
        return .handled
    }

    private func direction(
        for key: KeyEquivalent
    ) -> PermanentDeletionConfirmationDirection? {
        switch key {
        case .leftArrow:
            .left
        case .rightArrow:
            .right
        case .upArrow:
            .up
        case .downArrow:
            .down
        default:
            nil
        }
    }
}

private struct PermanentDeletionConfirmationButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isDestructive ? Color.red : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(
                        isDestructive
                            ? Color.red.opacity(configuration.isPressed ? 0.28 : 0.18)
                            : Color.primary.opacity(configuration.isPressed ? 0.16 : 0.09)
                    )
            }
            .contentShape(Capsule())
    }
}

private extension View {
    @ViewBuilder
    func permanentDeletionKeyboardSelection(_ isSelected: Bool) -> some View {
        overlay {
            if isSelected {
                Capsule()
                    .stroke(Color.accentColor, lineWidth: 3)
                    .padding(-3)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct ArchivePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: FileBrowserState
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Encrypted Archive", systemImage: "lock.fill")
                .font(.title2.weight(.semibold))
            Text("Enter the password to browse this archive. It stays in memory only for this window.")
                .foregroundStyle(.secondary)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submit() }
            if let passwordError = state.passwordError {
                Text(passwordError).foregroundStyle(.red).font(.caption)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Unlock") { submit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(password.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func submit() {
        Task { await state.submitPassword(password) }
    }
}
