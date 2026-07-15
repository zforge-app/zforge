import AppKit
import SwiftUI

struct ContentView: View {
    @State private var browser: FileBrowserState
    @State private var sidebar = SidebarState()
    @State private var showingServerSheet = false
    @State private var authorizationPanelPresented = false
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?
    @FocusState private var contentIsFocused: Bool

    init(initialURL: URL? = nil) {
        _browser = State(initialValue: FileBrowserState(initialURL: initialURL))
    }

    var body: some View {
        GeometryReader { geometry in
            browserLayout(windowWidth: geometry.size.width)
        }
        .frame(minWidth: 678, minHeight: 460)
    }

    @ViewBuilder
    private func browserLayout(windowWidth: CGFloat) -> some View {
        NavigationSplitView {
            BrowserSidebar(
                browser: browser,
                sidebar: sidebar,
                showingServerSheet: $showingServerSheet,
                restoreContentFocus: restoreContentFocus
            )
        } detail: {
            VStack(spacing: 0) {
                if browser.pendingAuthorizationURL != nil && browser.items.isEmpty {
                    authorizationPlaceholder
                } else {
                    BrowserContent(state: browser, contentFocus: $contentIsFocused)
                }
                BrowserBreadcrumb(state: browser)
            }
            .background(Color(nsColor: .underPageBackgroundColor))
        }
        .navigationTitle(browser.title)
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .environment(\.locale, browser.preferences.language.locale)
        .toolbar { browserToolbar(windowWidth: windowWidth) }
        .focusedSceneValue(\.fileBrowserState, browser)
        .task {
            await browser.start()
            restoreContentFocus()
        }
        .onAppear { restoreContentFocus() }
        .onChange(of: browser.preferences.viewMode) { previousViewMode, viewMode in
            if viewMode == .columns {
                browser.prepareColumnView()
            } else if previousViewMode == .columns {
                browser.prepareStandardViewAfterColumns()
            }
            browser.updatePreview()
            restoreContentFocus()
        }
        .onChange(of: browser.previewVisible) { _, _ in restoreContentFocus() }
        .onChange(of: browser.location) { _, _ in restoreContentFocus() }
        .onChange(of: browser.isLoading) { _, isLoading in
            if !isLoading { restoreContentFocus() }
        }
        .onChange(of: browser.pendingAuthorizationURL) { _, url in
            if let url { presentAuthorizationPanel(for: url) }
        }
        .onDisappear {
            toastDismissTask?.cancel()
            browser.close()
        }
        .sheet(isPresented: $showingServerSheet, onDismiss: restoreContentFocus) {
            ServerConnectionSheet(sidebar: sidebar) { url in
                Task { await browser.navigateToSidebar(url, name: url.lastPathComponent) }
            }
        }
        .sheet(isPresented: passwordSheetBinding, onDismiss: restoreContentFocus) {
            ArchivePasswordSheet(state: browser)
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
        .overlay {
            if browser.archiveOperationInProgress {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Working with archive…")
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
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @ToolbarContentBuilder
    private func browserToolbar(windowWidth: CGFloat) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
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
        ToolbarItem(id: "view-mode-selector", placement: .primaryAction) {
            ViewModeToolbarControl(
                selection: $browser.preferences.viewMode,
                usesCompactPresentation: windowWidth < 780
            )
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(id: "browser-actions", placement: .primaryAction) {
            ControlGroup {
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
                .disabled(browser.selectedItems.filter { !$0.isContainer }.isEmpty)
                .focusable(false)
                .help("Share")
                .accessibilityLabel("Share")

                Button {
                    showMoreActionsMenu()
                } label: {
                    ToolbarActionIcon(kind: .more)
                }
                .help("More")
                .focusable(false)
                .accessibilityLabel("More")
            }
            .focusable(false)
        }
    }

    private func performArchiveToolbarAction() {
        let action = browser.archiveToolbarAction
        guard action.isEnabled else { return }
        showToast(action.feedbackMessage)
        restoreContentFocus()
    }

    private func showMoreActionsMenu() {
        guard let event = NSApp.currentEvent,
              let contentView = event.window?.contentView else { return }

        let locale = browser.preferences.language.locale
        let menu = NSMenu()
        func addItem(
            _ title: String.LocalizationValue,
            systemImage: String,
            isEnabled: Bool,
            handler: @escaping () -> Void
        ) {
            menu.addItem(
                ClosureMenuItem(
                    title: String(localized: title, locale: locale),
                    systemImage: systemImage,
                    isEnabled: isEnabled,
                    handler: handler
                )
            )
        }

        addItem("Open", systemImage: "arrow.up.forward.app", isEnabled: browser.primarySelection != nil) {
            Task { if let item = browser.primarySelection { await browser.open(item) } }
        }
        addItem("Quick Look", systemImage: "eye", isEnabled: browser.primarySelection != nil) {
            browser.openQuickLook()
        }
        addItem("Get Info", systemImage: "info.circle", isEnabled: browser.primarySelection != nil) {
            browser.previewVisible = true
            browser.updatePreview()
        }
        menu.addItem(.separator())
        addItem("Add Tag", systemImage: "tag", isEnabled: false) { }
        addItem("Rename", systemImage: "pencil", isEnabled: false) { }
        addItem("Duplicate", systemImage: "plus.square.on.square", isEnabled: false) { }

        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
        restoreContentFocus()
    }

    private func restoreContentFocus() {
        contentIsFocused = false
        DispatchQueue.main.async {
            contentIsFocused = true
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

    private var errorBinding: Binding<Bool> {
        Binding(get: { browser.error != nil }, set: { if !$0 { browser.error = nil } })
    }

    private var largeOperationBinding: Binding<Bool> {
        Binding(
            get: { browser.pendingLargeOperation != nil },
            set: { if !$0 { browser.pendingLargeOperation = nil } }
        )
    }

    private func presentAuthorizationPanel(for intendedURL: URL) {
        guard !authorizationPanelPresented else { return }
        authorizationPanelPresented = true
        let panel = NSOpenPanel()
        panel.title = String(localized: "Allow Zforge to Access This Folder")
        panel.message = String(localized: "Choose the requested folder or one of its parents.")
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
        ControlGroup {
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
            .focusable(false)
            .accessibilityIdentifier("view-mode-selector-compact")
            .accessibilityLabel("View")
        }
        .fixedSize(horizontal: true, vertical: false)
        .focusable(false)
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

private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        handler: @escaping () -> Void
    ) {
        self.handler = handler
        super.init(title: title, action: #selector(performAction), keyEquivalent: "")
        target = self
        image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        self.isEnabled = isEnabled
    }

    @objc private func performAction() {
        handler()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }
}

private extension ArchiveToolbarAction {
    var title: String {
        switch self {
        case .extractAll: String(localized: "Extract All")
        case .extractSelected, .unavailableInsideArchive: String(localized: "Extract Selected")
        case .compress, .unavailableOutsideArchive: String(localized: "Compress Selected")
        }
    }

    var feedbackMessage: String {
        switch self {
        case .extractAll: String(localized: "Extract all selected archives.")
        case .extractSelected: String(localized: "Extract selected items.")
        case .compress: String(localized: "Compress selected items.")
        case .unavailableInsideArchive, .unavailableOutsideArchive: title
        }
    }
}

private struct ArchiveOperationIcon: View {
    let isExtracting: Bool

    var body: some View {
        ZStack {
            Image(systemName: "archivebox")
                .font(.system(size: 15, weight: .regular))
            Image(systemName: isExtracting ? "arrow.up" : "arrow.down")
                .font(.system(size: 7, weight: .black))
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
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
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
