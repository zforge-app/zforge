import AppKit
import SwiftUI

nonisolated enum BrowserToolbarLayout {
    nonisolated enum Stage: Equatable, Sendable {
        case unifiedOverflow
        case compactWithActionsOverflow
        case compactWithArchiveAction
        case expanded
    }

    /// The actions a toolbar menu adds above the shared item actions, because
    /// the stage moved their dedicated toolbar controls into that menu.
    struct OverflowMenuContents: Equatable {
        let includesViewSelector: Bool
        let includesArchiveAction: Bool
        let includesShareAction: Bool
        /// The search button joins the menu only when no toolbar space is left for it.
        var includesSearchAction = false
    }

    /// How much more toolbar width the expanded search field takes than its button.
    static let expandedSearchExtraWidth: CGFloat = 150

    /// The sidebar's trailing edge the stage widths below were set for: its 180 pt minimum.
    static let referenceSidebarTrailingEdge: CGFloat = 180
    /// Where the toolbar's leading items start with the sidebar collapsed: after the traffic lights.
    static let collapsedSidebarToolbarInset: CGFloat = 88

    /// The window width that leaves the toolbar the same room with the reference sidebar.
    ///
    /// The toolbar's room runs from the sidebar's trailing edge (with the sidebar collapsed, from
    /// the traffic lights) to the window's trailing edge, so a wider sidebar leaves less of it
    /// (ZF-88 follow-up, user screenshots 2026-11-19): with stages that followed the window width
    /// alone, a sidebar a few dozen points wider than its minimum made `NSToolbar` move the search
    /// button, More or the search field into its own overflow menu.
    static func referenceWindowWidth(windowWidth: CGFloat, sidebarTrailingEdge: CGFloat?) -> CGFloat {
        windowWidth - max(sidebarTrailingEdge ?? 0, collapsedSidebarToolbarInset) + referenceSidebarTrailingEdge
    }

    /// The stage for a window width and sidebar. While the search field is expanded the stage is
    /// chosen as if the window were narrower by the field's extra width, so controls move into the
    /// toolbar menu first: `NSToolbar` would otherwise move the field itself into its own
    /// overflow menu, where it cannot be typed into. Widths are those of a window with the
    /// reference sidebar (`referenceWindowWidth`).
    static func stage(for windowWidth: CGFloat, sidebarTrailingEdge: CGFloat? = referenceSidebarTrailingEdge,
                      searchFieldExpanded: Bool = false) -> Stage {
        let reference = referenceWindowWidth(windowWidth: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge)
        let width = searchFieldExpanded ? reference - expandedSearchExtraWidth : reference
        if width < 678 { return .unifiedOverflow }
        if width < 840 { return .compactWithActionsOverflow }
        if width < 900 { return .compactWithArchiveAction }
        return .expanded
    }

    /// The width (with the reference sidebar) from which the expanded stage also fits the search
    /// field at rest instead of its button (ZF-88). Measured on macOS 27 in the real browser
    /// window: 869 pt of toolbar room hold the navigation group, `NSToolbar`'s minimum of 160 pt
    /// for the title (longer titles are truncated to it) and its 12 pt spacing, the view selector,
    /// the action group and the 200 pt field. With less room `NSToolbar` compresses the field and
    /// then moves items into its own overflow menu.
    static let searchFieldAtRestMinimumWidth: CGFloat = 1_049

    /// With room to spare the search item is a field at rest instead of the magnifying-glass
    /// button, as in Finder (ZF-88): only while the field fits beside every control of the
    /// expanded stage, so it never pushes a control into a menu; the button returns as soon as
    /// it does not.
    static func searchFieldFitsAtRest(windowWidth: CGFloat, sidebarTrailingEdge: CGFloat?) -> Bool {
        referenceWindowWidth(windowWidth: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge)
            >= searchFieldAtRestMinimumWidth
    }

    /// The width (with the reference sidebar) below which the open search field only fits at its
    /// compact width in the smallest stage (416 pt of room measured on macOS 27 for 200 pt): only a
    /// sidebar dragged near its maximum leaves so little room.
    static let fullSearchFieldMinimumWidth: CGFloat = 596

    /// The width (with the reference sidebar) from which the smallest stage keeps the search button
    /// beside the double-chevron menu instead of moving it into that menu (ZF-88).
    /// 418 pt of room measured on macOS 27 (the button went into `NSToolbar`'s overflow at 416 pt).
    static let searchButtonInSmallestStageMinimumWidth: CGFloat = 598

    /// In the smallest stage the expanded field only fits without the toolbar title, so the
    /// title leaves the toolbar while the field is open (the field shows the query; the
    /// window keeps its title for the Window menu).
    static func hidesTitle(for windowWidth: CGFloat, sidebarTrailingEdge: CGFloat? = referenceSidebarTrailingEdge,
                           searchFieldExpanded: Bool) -> Bool {
        searchFieldExpanded
            && stage(for: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge, searchFieldExpanded: true) == .unifiedOverflow
    }

    /// All the toolbar takes from the window and sidebar widths: its stage with the search field
    /// closed and open, whether the field fits at rest, the search button in the smallest stage and
    /// the compact field for a sidebar near its maximum. The window keeps only this in its observed state, so resizing
    /// within a stage updates no view (D-110: the raw width in the browser's body re-evaluated the
    /// whole window at every point).
    nonisolated struct WidthClass: Equatable, Sendable {
        let stage: Stage
        let searchStage: Stage
        /// Whether the search item is a field even while no search is in use (ZF-88).
        let showsSearchFieldAtRest: Bool
        /// Whether the open search field takes its compact width (a sidebar near its maximum).
        let usesCompactSearchField: Bool
        /// Whether the search button stays in the toolbar in the smallest stage (ZF-88).
        let keepsSearchButtonInSmallestStage: Bool

        init(windowWidth: CGFloat, sidebarTrailingEdge: CGFloat? = BrowserToolbarLayout.referenceSidebarTrailingEdge) {
            stage = BrowserToolbarLayout.stage(for: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge)
            searchStage = BrowserToolbarLayout.stage(for: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge,
                                                     searchFieldExpanded: true)
            showsSearchFieldAtRest = BrowserToolbarLayout.searchFieldFitsAtRest(
                windowWidth: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge)
            let reference = BrowserToolbarLayout.referenceWindowWidth(
                windowWidth: windowWidth, sidebarTrailingEdge: sidebarTrailingEdge)
            usesCompactSearchField = reference < BrowserToolbarLayout.fullSearchFieldMinimumWidth
            keepsSearchButtonInSmallestStage = reference >= BrowserToolbarLayout.searchButtonInSmallestStageMinimumWidth
        }

        func stage(searchFieldExpanded: Bool) -> Stage { searchFieldExpanded ? searchStage : stage }

        func hidesTitle(searchFieldExpanded: Bool) -> Bool { searchFieldExpanded && searchStage == .unifiedOverflow }
    }
}

/// The inputs of the browser toolbar's `WidthClass`: not observed by SwiftUI (ZF-88).
final class BrowserToolbarMetrics {
    var windowWidth: CGFloat = 1_100
    /// The sidebar's trailing edge from SwiftUI's geometry, used until AppKit can tell.
    var sidebarMaxX: CGFloat = BrowserToolbarLayout.referenceSidebarTrailingEdge
    weak var sidebarObserver: BrowserSidebarObserverView?

    /// Nil while the sidebar is collapsed: the toolbar then starts after the traffic lights.
    @MainActor var sidebarTrailingEdge: CGFloat? {
        if let edge = sidebarObserver?.sidebarTrailingEdge() { return edge }
        return sidebarMaxX
    }
}

extension BrowserToolbarLayout.WidthClass {
    /// The toolbar menu's additions for a stage: Search only while the toolbar has no room for
    /// the search button (ZF-88).
    func overflowMenuContents(for stage: BrowserToolbarLayout.Stage) -> BrowserToolbarLayout.OverflowMenuContents {
        var contents = stage.overflowMenuContents
        if keepsSearchButtonInSmallestStage { contents.includesSearchAction = false }
        return contents
    }
}

extension BrowserToolbarLayout.Stage {
    var overflowMenuContents: BrowserToolbarLayout.OverflowMenuContents {
        switch self {
        case .unifiedOverflow:
            .init(includesViewSelector: true, includesArchiveAction: true, includesShareAction: true,
                  includesSearchAction: true)
        case .compactWithActionsOverflow:
            .init(includesViewSelector: false, includesArchiveAction: true, includesShareAction: true)
        case .compactWithArchiveAction:
            .init(includesViewSelector: false, includesArchiveAction: false, includesShareAction: true)
        case .expanded:
            .init(includesViewSelector: false, includesArchiveAction: false, includesShareAction: false)
        }
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
    @State private var toolbarWidthClass: BrowserToolbarLayout.WidthClass?
    /// The latest window width and sidebar edge, kept outside SwiftUI's observation so they
    /// update no view; only a change of `toolbarWidthClass` does (D-110, ZF-88).
    @State private var toolbarMetrics = BrowserToolbarMetrics()
    @State private var toastDismissTask: Task<Void, Never>?
    @State private var focusRestoreTask: Task<Void, Never>?
    @State private var toolbarOverflowMenuPresented = false
    @FocusState private var browserFocus: BrowserFocusTarget?
    let tabSourceWindowNumber: Int?

    init(initialURL: URL? = nil, tabSourceWindowNumber: Int? = nil, automationAccess: BrowserOpeningAccess? = nil,
         archiveSearch: String? = nil, finderRequest: FinderMenuRequest? = nil) {
        _browser = State(initialValue: FileBrowserState(initialURL: initialURL, automationAccessLease: automationAccess?.take(),
            archiveSearch: archiveSearch, finderRequest: finderRequest))
        self.tabSourceWindowNumber = tabSourceWindowNumber
    }

    /// Hosts an existing browser state, so tests can lay out the real window offscreen.
    init(browser: FileBrowserState) {
        _browser = State(initialValue: browser)
        tabSourceWindowNumber = nil
    }

    var body: some View {
        browserLayout(widthClass: toolbarWidthClass ?? .init(windowWidth: Self.defaultWidth))
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                toolbarMetrics.windowWidth = width
                updateToolbarWidthClass()
            }
            .frame(minWidth: 640, minHeight: 460)
    }

    /// The width assumed until the first layout reports the window's.
    private static let defaultWidth: CGFloat = 1_100

    private func updateToolbarWidthClass() {
        let widthClass = BrowserToolbarLayout.WidthClass(
            windowWidth: toolbarMetrics.windowWidth, sidebarTrailingEdge: toolbarMetrics.sidebarTrailingEdge)
        if toolbarWidthClass != widthClass { toolbarWidthClass = widthClass }
    }

    @ViewBuilder
    private func browserLayout(widthClass: BrowserToolbarLayout.WidthClass) -> some View {
        NavigationSplitView {
            BrowserSidebar(
                browser: browser,
                sidebar: sidebar,
                restoreContentFocus: restoreContentFocus,
                dragSession: dragSession
            )
            .toolbar(removing: .sidebarToggle)
            .toolbar { browserNavigationToolbar }
            // The sidebar's trailing edge bounds the toolbar's room (ZF-88). SwiftUI reports it in the
            // window's first layout, before the window shows, so a sidebar restored wider than its
            // minimum never shows the stage of a narrower one.
            .onGeometryChange(for: CGFloat.self) { proxy in proxy.frame(in: .global).maxX } action: { maxX in
                toolbarMetrics.sidebarMaxX = maxX
                updateToolbarWidthClass()
            }
            .background {
                BrowserSidebarObserver(metrics: toolbarMetrics) { updateToolbarWidthClass() }
                    .frame(width: 0, height: 0)
            }
        } detail: {
            VStack(spacing: 0) {
                if browser.fileSearch != nil && browser.location == .recents {
                    BrowserSearchScopeBar(state: browser)
                }
                if NetworkLevelBar.isShown(for: browser) {
                    NetworkLevelBar(state: browser)
                }
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
            .toolbar {
                browserPrimaryToolbar(stage: widthClass.stage(searchFieldExpanded: browser.isSearchPresented),
                                      showsSearchFieldAtRest: widthClass.showsSearchFieldAtRest,
                                      isCompactSearchField: widthClass.usesCompactSearchField,
                                      keepsSearchButton: widthClass.keepsSearchButtonInSmallestStage)
            }
            .toolbar(removing: widthClass.hidesTitle(searchFieldExpanded: browser.isSearchPresented) ? .title : nil)
        }
        .environment(\.locale, browser.preferences.language.locale)
        .focusedSceneValue(\.fileBrowserState, browser)
        .background {
            Button(AppLocalization.string("New Folder with Selection", locale: browser.preferences.language.locale)) {
                browser.createNewFolderWithSelection()
            }
            .keyboardShortcut("n", modifiers: [.control, .option, .command])
            .disabled(!browser.canCreateFolderWithSelection)
            .hidden()
            .accessibilityHidden(true)
            .frame(width: 0, height: 0)
            BrowserWindowConfigurationView(
                representedURL: browser.currentDirectoryURL,
                tabSourceWindowNumber: tabSourceWindowNumber,
                browser: browser
            )
                .frame(width: 0, height: 0)
        }
        .task {
            browser.configureUndoManager(undoManager)
            await browser.start()
            restoreContentFocus()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { notification in
            guard let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            Task { await browser.leaveUnmountedVolume(volumeURL) }
        }
        .onAppear {
            browser.configureUndoManager(undoManager)
            browser.configureOpenWindowAction { url in
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(initialURL: url)
                )
            }
            browser.configureWindowCloseAction { [browser] in
                if let window = BrowserWindowLifecycle.shared.window(for: browser) { window.close() } else { browser.close() }
            }
            browser.configureOpenTabAction { [browser] url in
                let source = BrowserWindowLifecycle.shared.window(for: browser) ?? NSApp.keyWindow
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(initialURL: url, tabSourceWindowNumber: source?.windowNumber)
                )
            }
            applyUITestWindowWidthIfNeeded()
            restoreContentFocus()
        }
        .onChange(of: browser.viewMode) { previousViewMode, viewMode in
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
            ServerConnectionSheet(browser: browser)
                .environment(\.locale, browser.preferences.language.locale)
        }
        .sheet(item: Binding(get: { browser.tagEditingRequest }, set: { browser.tagEditingRequest = $0 }), onDismiss: restoreContentFocus) { request in
            FinderTagEditor(request: request, browser: browser)
                .environment(\.locale, browser.preferences.language.locale)
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
        ) { request in
            Button("Add to Archive") {
                Task { await browser.confirmArchiveAddition(request) }
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
            } else if browser.archiveOperationInProgress && browser.archiveOperationIsVisible {
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

    /// Every stage's items stay in the toolbar and a stage only hides the others (D-110): replacing
    /// the items made `NSToolbar` and SwiftUI rebuild the toolbar at each stage switch.
    @ToolbarContentBuilder
    private func browserPrimaryToolbar(stage: BrowserToolbarLayout.Stage,
                                       showsSearchFieldAtRest: Bool,
                                       isCompactSearchField: Bool,
                                       keepsSearchButton: Bool) -> some ToolbarContent {
        let isCompact = stage == .compactWithActionsOverflow || stage == .compactWithArchiveAction
        // The smallest stage keeps the search button while it fits beside the double-chevron menu (ZF-88).
        let showsSearch = stage != .unifiedOverflow || browser.isSearchPresented || keepsSearchButton
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(id: "view-mode-selector-compact", placement: .primaryAction) {
            ViewModeToolbarControl(selection: $browser.viewMode, usesCompactPresentation: true)
        }
        .hidden(!isCompact)
        ToolbarItem(id: "view-mode-selector-expanded", placement: .primaryAction) {
            ViewModeToolbarControl(selection: $browser.viewMode, usesCompactPresentation: false)
        }
        .hidden(stage != .expanded)
        ToolbarSpacer(.fixed, placement: .primaryAction)
            .hidden(stage == .unifiedOverflow)
        ToolbarItem(id: "archive-contextual-action-compact", placement: .primaryAction) {
            Button {
                performArchiveToolbarAction()
            } label: {
                ArchiveOperationIcon(symbol: browser.archiveToolbarAction.symbol)
            }
            .disabled(!browser.archiveToolbarAction.isEnabled)
            .focusable(false)
            .accessibilityIdentifier("archive-contextual-action")
            .help(browser.archiveToolbarAction.title)
            .accessibilityLabel(browser.archiveToolbarAction.title)
        }
        .hidden(stage != .compactWithArchiveAction)
        ToolbarSpacer(.fixed, placement: .primaryAction)
            .hidden(stage != .compactWithArchiveAction)
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                performArchiveToolbarAction()
            } label: {
                ArchiveOperationIcon(symbol: browser.archiveToolbarAction.symbol)
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
                browser.editTags()
            } label: {
                ToolbarActionIcon(kind: .tag)
            }
            .disabled(!browser.canEditTags)
            .focusable(false)
            .help("Edit Tags")
            .accessibilityLabel("Edit Tags")
            .accessibilityIdentifier("edit-tags-action")

            Button {
                showToolbarActionsMenu(for: .expanded)
            } label: {
                ToolbarActionIcon(kind: .more)
            }
            .help("More")
            .focusable(false)
            .accessibilityLabel("More")
            .accessibilityIdentifier("toolbar-more-menu")
        }
        .hidden(stage != .expanded)
        browserTrailingToolbar(stage: stage, showsSearch: showsSearch, showsSearchFieldAtRest: showsSearchFieldAtRest,
                               isCompactSearchField: isCompactSearchField)
    }

    /// The double-chevron menu in its own capsule (the expanded stage has More in its group
    /// instead), then the search item in its own capsule after a fixed space, as in Finder.
    @ToolbarContentBuilder
    private func browserTrailingToolbar(stage: BrowserToolbarLayout.Stage, showsSearch: Bool,
                                        showsSearchFieldAtRest: Bool,
                                        isCompactSearchField: Bool = false) -> some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .primaryAction)
            .hidden(stage != .expanded)
        ToolbarItem(id: "toolbar-overflow-menu", placement: .primaryAction) {
            Button {
                showToolbarActionsMenu(for: stage, tracksOverflowPresentation: true)
            } label: {
                ToolbarOverflowIcon(isActive: toolbarOverflowMenuPresented)
            }
            .focusable(false)
            .accessibilityIdentifier("toolbar-overflow-menu")
            .accessibilityValue(toolbarOverflowMenuPresented ? "Expanded" : "Collapsed")
            .help("More")
            .accessibilityLabel("More")
        }
        .hidden(stage == .expanded)
        ToolbarSpacer(.fixed, placement: .primaryAction)
            .hidden(stage == .expanded || !showsSearch)
        // The button and the field are separate items, one shown at a time (ZF-88): see
        // `BrowserToolbarSearchButton`.
        let showsField = browser.isSearchPresented || showsSearchFieldAtRest
        ToolbarItem(id: "toolbar-search", placement: .primaryAction) {
            BrowserToolbarSearchButton(state: browser)
        }
        .hidden(!showsSearch || showsField)
        ToolbarItem(id: "toolbar-search-field-item", placement: .primaryAction) {
            BrowserToolbarSearchField(state: browser, isCompact: isCompactSearchField,
                                      restoreContentFocus: restoreContentFocus)
        }
        .hidden(!showsField)
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
        for stage: BrowserToolbarLayout.Stage,
        tracksOverflowPresentation: Bool = false
    ) {
        let contents = (toolbarWidthClass ?? .init(windowWidth: Self.defaultWidth)).overflowMenuContents(for: stage)
        guard let event = NSApp.currentEvent,
              let contentView = event.window?.contentView else { return }

        let menu = BrowserActionsMenu.make(
            state: browser,
            menu: tracksOverflowPresentation
                ? TrackedToolbarMenu(
                    onOpen: { toolbarOverflowMenuPresented = true },
                    onClose: { toolbarOverflowMenuPresented = false }
                )
                : NSMenu(),
            includesViewSelector: contents.includesViewSelector,
            includesArchiveAction: contents.includesArchiveAction,
            includesShareAction: contents.includesShareAction,
            includesSearchAction: contents.includesSearchAction,
            showToast: showToast,
            restoreContentFocus: restoreContentFocus
        )

        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
        restoreContentFocus()
    }

    private func restoreContentFocus() {
        focusRestoreTask?.cancel()
        focusRestoreTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, browser.renamingItemID == nil, !browser.searchFieldHasFocus else { return }
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
            // This view's own window once registered; a new window is not always key yet.
            guard let window = BrowserWindowLifecycle.shared.window(for: browser)
                ?? NSApp.keyWindow ?? NSApp.windows.first else { return }
            let visibleFrame = NSScreen.main?.visibleFrame
            let height = min(window.contentView?.bounds.height ?? 720, (visibleFrame?.height ?? 820) - 100)
            window.setContentSize(NSSize(width: width, height: height))
            // Keep native cascading when visible so one fixture window cannot
            // cover another window's close control. Clamp only offscreen frames.
            if let visibleFrame {
                let isFirstWindow = !NSApp.windows.contains {
                    $0 !== window && $0.isVisible && $0.identifier?.rawValue.hasPrefix("browser") == true
                }
                window.setFrameOrigin(UITestWindowPlacement.origin(
                    for: window.frame.size, current: window.frame.origin, visibleFrame: visibleFrame,
                    isFirstWindow: isFirstWindow, arguments: arguments))
            }
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
            // Any other dismissal (Escape) cancels a pending connection like the Cancel button.
            set: { if !$0 { browser.cancelServerConnection() } else { browser.showingServerConnection = true } }
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
        let panel = UITestLaunchIsolation.openPanel()
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

nonisolated final class ClosureMenuItem: NSMenuItem {
    private let handler: @MainActor () -> Void

    @MainActor
    init(
        title: String,
        image: NSImage?,
        isEnabled: Bool,
        handler: @escaping @MainActor () -> Void
    ) {
        self.handler = handler
        super.init(title: title, action: #selector(performAction), keyEquivalent: "")
        target = self
        self.image = image
        self.isEnabled = isEnabled
    }

    @MainActor
    convenience init(title: String, systemImage: String, isEnabled: Bool, handler: @escaping @MainActor () -> Void) {
        self.init(title: title, image: NSImage(systemSymbolName: systemImage, accessibilityDescription: title),
                  isEnabled: isEnabled, handler: handler)
    }

    /// A selection action's item, with the same symbol as Finder's Zforge submenu.
    @MainActor
    convenience init(title: String, action: BrowserSelectionAction, isEnabled: Bool, handler: @escaping @MainActor () -> Void) {
        self.init(title: title, image: action.menuSymbol.flatMap { MenuSymbolImage.image(for: $0, accessibilityDescription: title) },
                  isEnabled: isEnabled, handler: handler)
    }

    @MainActor @objc private func performAction() {
        handler()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }
}

/// The toolbar's archive action: the menus' badged Compress or Extract Here symbol,
/// at the size of the toolbar's other symbols.
struct ArchiveOperationIcon: View {
    static let pointSize: CGFloat = 15

    let symbol: MenuSymbol

    var body: some View {
        Group {
            if let image = MenuSymbolImage.image(for: symbol, pointSize: Self.pointSize) {
                Image(nsImage: image)
            }
        }
        .frame(width: 25, height: 18)
        .accessibilityHidden(true)
    }
}

private struct ToolbarActionIcon: View {
    enum Kind {
        case share
        case tag
        case more
    }

    let kind: Kind

    var body: some View {
        Image(systemName: kind == .share ? "square.and.arrow.up" : kind == .tag ? "tag" : "ellipsis")
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

