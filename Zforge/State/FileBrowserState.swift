import AppKit
import Foundation
import Observation
import QuickLookUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class FileBrowserState {
    private enum AuthorizationPurpose {
        case navigate(name: String)
        case loadRecents
        case reveal(target: URL)
    }

    private struct HistoryEntry {
        let components: [BrowserPathComponent]
        let location: BrowserLocation
    }

    private struct HierarchyCursorSnapshot {
        let orderedIDs: [BrowserItemID]
        let focusedID: BrowserItemID?

        var focusedIndex: Int? {
            guard let focusedID else { return nil }
            return orderedIDs.firstIndex(of: focusedID)
        }
    }

    private struct FileUndoRecord {
        let removals: [URL]
        let moves: [BrowserExactFileMove]
        let actionName: String
    }

    enum PasswordOperation {
        case openFile(URL)
        case openNested(BrowserItem)
        case expandInline(BrowserItem)

        var sessionID: UUID? {
            guard case let .openNested(item) = self,
                  case let .archive(address) = item.location else { return nil }
            return address.sessionID
        }
    }

    enum LargeOperation {
        case openNested(BrowserItem)
        case openExternally(BrowserItem)

        var item: BrowserItem {
            switch self {
            case let .openNested(item), let .openExternally(item): item
            }
        }
    }

    @ObservationIgnored private let fileSystem: any FileSystemServing
    @ObservationIgnored private let fileOperations: any FileOperationServing
    @ObservationIgnored private let recentItems: any RecentItemsServing
    @ObservationIgnored private let grants: any AccessGrantStoring
    @ObservationIgnored private let archives: any ArchiveServing
    @ObservationIgnored private let monitor = DirectoryMonitor()
    @ObservationIgnored private var expandedDirectoryMonitors: [BrowserItemID: DirectoryMonitor] = [:]
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?
    @ObservationIgnored private var previewGeneration: UInt64 = 0
    @ObservationIgnored private var backStack: [HistoryEntry] = []
    @ObservationIgnored private var forwardStack: [HistoryEntry] = []
    @ObservationIgnored private var confirmedLargeItems: Set<BrowserItemID> = []
    @ObservationIgnored private var inlineArchiveResults: [BrowserItemID: ArchiveOpenResult] = [:]
    @ObservationIgnored private let initialURL: URL?
    @ObservationIgnored private let quickLookPanel = QuickLookPanelCoordinator()
    @ObservationIgnored private var pendingAuthorizationPurpose: AuthorizationPurpose?
    @ObservationIgnored private var openWindowHandler: ((URL?) -> Void)?
    @ObservationIgnored private weak var undoManager: UndoManager?
    @ObservationIgnored private var rootItemsRevision: UInt64 = 0
    @ObservationIgnored private var hierarchyRevision: UInt64 = 0
    @ObservationIgnored private var knownItemsRevision: UInt64 = 0
    @ObservationIgnored private var columnItemsRevision: UInt64 = 0
    @ObservationIgnored private var recursiveExpansionGeneration: UInt64 = 0
    @ObservationIgnored private var sortedItemsCache: (
        revision: UInt64,
        sort: BrowserSort,
        showsHidden: Bool,
        items: [BrowserItem]
    )?
    @ObservationIgnored private var knownItemsCache: (
        revision: UInt64,
        itemsByID: [BrowserItemID: BrowserItem]
    )?
    @ObservationIgnored private var flattenedListCache: (
        revision: UInt64,
        sort: BrowserSort,
        showsHidden: Bool,
        entries: [VisibleBrowserItem],
        orderedItems: [BrowserItem]
    )?
    @ObservationIgnored private var sortedColumnItemsCache: [
        BrowserLocation: (revision: UInt64, sort: BrowserSort, items: [BrowserItem])
    ] = [:]

    var preferences: FileBrowserPreferences
    var location: BrowserLocation
    var pathComponents: [BrowserPathComponent] = []
    var items: [BrowserItem] = [] {
        didSet {
            rootItemsRevision &+= 1
            hierarchyRevision &+= 1
            knownItemsRevision &+= 1
        }
    }
    var selection: Set<BrowserItemID> = []
    private(set) var selectionOrder: [BrowserItemID] = []
    var selectionAnchor: BrowserItemID?
    var expandedItems: Set<BrowserItemID> = [] {
        didSet { hierarchyRevision &+= 1 }
    }
    var expandedChildren: [BrowserItemID: [BrowserItem]] = [:] {
        didSet {
            hierarchyRevision &+= 1
            knownItemsRevision &+= 1
        }
    }
    var expandingItems: Set<BrowserItemID> = []
    var columnItems: [BrowserLocation: [BrowserItem]] = [:] {
        didSet {
            columnItemsRevision &+= 1
            knownItemsRevision &+= 1
        }
    }
    var columnSelections: [BrowserLocation: BrowserItemID] = [:]
    var isLoading = false
    var error: BrowserError?
    var pendingAuthorizationURL: URL?
    var passwordOperation: PasswordOperation?
    var passwordError: String?
    var previewURL: URL?
    var previewRequiresManualLoad = false
    var previewURLs: [BrowserItemID: URL] = [:]
    var previewItemsRequiringManualLoad: Set<BrowserItemID> = []
    var pendingLargeOperation: LargeOperation?
    var archiveOperationInProgress = false
    var showingGoToFolder = false
    var showingServerConnection = false
    var renamingItemURL: URL?
    var renameDraft = ""
    var renameInProgress = false
    var previewVisible: Bool {
        get { preferences.previewVisible(in: preferences.viewMode) }
        set { preferences.setPreviewVisible(newValue, in: preferences.viewMode) }
    }
    var focusedItemID: BrowserItemID?
    var activeColumnLocation: BrowserLocation?

    var sortedItems: [BrowserItem] {
        let sourceItems = items
        let sort = preferences.sort
        let showsHidden = preferences.showHiddenFiles
        if let cache = sortedItemsCache,
           cache.revision == rootItemsRevision,
           cache.sort == sort,
           cache.showsHidden == showsHidden {
            return cache.items
        }
        let result = sort.sorted(sourceItems.filter { showsHidden || !$0.isHidden })
        sortedItemsCache = (rootItemsRevision, sort, showsHidden, result)
        return result
    }

    var selectedItems: [BrowserItem] {
        selection.compactMap { knownItemsByID[$0] }
    }

    /// Selected items ordered for presentation, with the most recently selected item first.
    var previewItems: [BrowserItem] {
        let selectedByID = Dictionary(uniqueKeysWithValues: selectedItems.map { ($0.id, $0) })
        var result = selectionOrder.reversed().compactMap { selectedByID[$0] }
        let orderedIDs = Set(result.map(\.id))
        var remaining = selectedItems.filter { !orderedIDs.contains($0.id) }
        if let focusedItemID,
           let focusedIndex = remaining.firstIndex(where: { $0.id == focusedItemID }) {
            result.append(remaining.remove(at: focusedIndex))
        }
        result.append(contentsOf: remaining)
        return result
    }

    var primarySelection: BrowserItem? {
        if let focusedItemID,
           selection.contains(focusedItemID),
           let item = knownItemsByID[focusedItemID] {
            return item
        }
        return previewItems.first
    }

    func previewURL(for item: BrowserItem) -> URL? {
        guard !item.usesStaticIconPreview else { return nil }
        return previewURLs[item.id] ?? (primarySelection?.id == item.id ? previewURL : nil)
    }

    func previewRequiresManualLoad(for item: BrowserItem) -> Bool {
        previewItemsRequiringManualLoad.contains(item.id)
            || (primarySelection?.id == item.id && previewRequiresManualLoad)
    }

    var archiveToolbarAction: ArchiveToolbarAction {
        switch location {
        case .archive:
            return selection.isEmpty ? .unavailableInsideArchive : .extractSelected
        case .recents, .fileSystem:
            let selectedItems = selectedItems
            guard !selectedItems.isEmpty else { return .unavailableOutsideArchive }
            if selectedItems.contains(where: { !$0.isArchive }) { return .compress }
            return .extractAll
        }
    }

    var knownItems: [BrowserItem] {
        Array(knownItemsByID.values)
    }

    func sortedColumnItems(at location: BrowserLocation) -> [BrowserItem] {
        let sourceItems = columnItems[location] ?? []
        let sort = preferences.sort
        if let cached = sortedColumnItemsCache[location],
           cached.revision == columnItemsRevision,
           cached.sort == sort {
            return cached.items
        }
        let result = sort.sorted(sourceItems)
        sortedColumnItemsCache[location] = (columnItemsRevision, sort, result)
        return result
    }

    private var knownItemsByID: [BrowserItemID: BrowserItem] {
        let rootItems = items
        let expandedChildren = expandedChildren
        let columnItems = columnItems
        if let cache = knownItemsCache, cache.revision == knownItemsRevision {
            return cache.itemsByID
        }
        var values: [BrowserItemID: BrowserItem] = [:]
        for item in rootItems { values[item.id] = item }
        for children in expandedChildren.values {
            for item in children { values[item.id] = item }
        }
        for children in columnItems.values {
            for item in children { values[item.id] = item }
        }
        knownItemsCache = (knownItemsRevision, values)
        return values
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var currentDirectoryURL: URL? { location.fileSystemURL }
    /// Drops on the unoccupied list/content area always target the directory
    /// being browsed, independently of the focused row's contextual target.
    var fileDropDestinationURL: URL? { currentDirectoryURL }
    var fileOperationDestinationURL: URL? {
        guard let currentDirectoryURL else { return nil }
        guard preferences.viewMode == .list, let focusedItemID else {
            return currentDirectoryURL
        }
        let visibleEntries = flattenedList()
        guard let focusedIndex = visibleEntries.firstIndex(where: { $0.id == focusedItemID }) else {
            return currentDirectoryURL
        }

        let focusedDepth = visibleEntries[focusedIndex].depth
        guard focusedDepth > 0,
              let parent = visibleEntries[..<focusedIndex].reversed().first(where: {
                  $0.depth == focusedDepth - 1
              })?.item,
              parent.isDirectory,
              let parentURL = parent.localURL else {
            return currentDirectoryURL
        }
        return parentURL.standardizedFileURL
    }
    var parentDirectoryURL: URL? {
        guard let currentDirectoryURL else { return nil }
        let parent = currentDirectoryURL.deletingLastPathComponent().standardizedFileURL
        return parent.path == currentDirectoryURL.standardizedFileURL.path ? nil : parent
    }
    var canModifyCurrentDirectory: Bool { fileOperationDestinationURL != nil }
    var hasLocalSelection: Bool {
        !selectedItems.isEmpty && selectedItems.allSatisfy { $0.localURL != nil }
    }
    var canRenameSelection: Bool {
        selectedItems.count == 1 && selectedItems[0].localURL != nil
    }
    var renamingItemID: BrowserItemID? {
        guard let renamingPath = renamingItemURL?.standardizedFileURL.path else { return nil }
        return knownItemsByID.values.first(where: {
            $0.localURL?.standardizedFileURL.path == renamingPath
        })?.id
    }
    var canShowOriginal: Bool {
        guard selectedItems.count == 1, let url = selectedItems.first?.localURL else { return false }
        return (try? url.resourceValues(forKeys: [.isAliasFileKey]).isAliasFile) == true
    }
    var canEjectSelection: Bool { ejectableVolumeURL != nil }
    var title: String { pathComponents.last?.name ?? AppLocalization.string("Recents", locale: preferences.language.locale) }
    var breadcrumbComponents: [BrowserPathComponent] {
        guard let first = pathComponents.first,
              case let .fileSystem(url) = first.location else {
            return pathComponents
        }
        return Array(fileSystemPathComponents(to: url).dropLast()) + pathComponents
    }

    convenience init(initialURL: URL? = nil) {
        if ProcessInfo.processInfo.arguments.contains("--ui-fixtures") {
            self.init(
                preferences: FileBrowserPreferences.shared,
                fileSystem: UIFixtureFileSystemService(),
                recentItems: UIFixtureRecentItemsService(),
                grants: UIFixtureAccessGrantStore(),
                archives: UIFixtureArchiveEngine(),
                initialURL: initialURL
            )
            return
        }
        self.init(
            preferences: FileBrowserPreferences.shared,
            fileSystem: FileSystemService(),
            recentItems: SpotlightRecentItemsService(),
            grants: AccessGrantStore(),
            archives: SevenZipArchiveEngine(),
            initialURL: initialURL
        )
    }

    init(
        preferences: FileBrowserPreferences,
        fileSystem: any FileSystemServing,
        fileOperations: any FileOperationServing = FileOperationService(),
        recentItems: (any RecentItemsServing)? = nil,
        grants: any AccessGrantStoring,
        archives: any ArchiveServing,
        initialURL: URL? = nil
    ) {
        self.preferences = preferences
        self.fileSystem = fileSystem
        self.fileOperations = fileOperations
        self.recentItems = recentItems ?? SpotlightRecentItemsService()
        self.grants = grants
        self.archives = archives
        self.initialURL = initialURL
        location = .recents
        pathComponents = [
            BrowserPathComponent(
                location: .recents,
                name: AppLocalization.string("Recents", locale: preferences.language.locale),
                isArchive: false
            )
        ]
    }

    func start() async {
        await archives.cleanupStaleSessions()
        if let initialURL {
            do {
                let item = try await fileSystem.item(at: initialURL)
                if item.isArchive {
                    await openArchive(item)
                } else if item.isContainer {
                    await navigate(to: .fileSystem(initialURL), named: item.name, resetPath: true)
                }
                return
            } catch {
                self.error = mapError(error)
            }
        }
        let home = UserDirectoryService.homeURL
        if await grants.hasGrant(for: home) {
            do {
                _ = try await grants.activateGrant(for: home)
                await reload()
            } catch {
                await grants.removeGrant(for: home)
                requestAuthorization(for: home, purpose: .loadRecents)
            }
        } else {
            requestAuthorization(for: home, purpose: .loadRecents)
        }
    }

    func authorize(_ selectedURL: URL, intendedURL: URL) async {
        do {
            try await grants.storeGrant(for: selectedURL)
            _ = try await grants.activateGrant(for: intendedURL)
            pendingAuthorizationURL = nil
            let purpose = pendingAuthorizationPurpose
            pendingAuthorizationPurpose = nil
            switch purpose {
            case .loadRecents:
                await reload()
            case let .navigate(name):
                await navigate(to: .fileSystem(intendedURL), named: name, resetPath: true)
            case let .reveal(target):
                await reveal(target)
            case nil:
                let name = intendedURL.lastPathComponent
                await navigate(to: .fileSystem(intendedURL), named: name, resetPath: true)
            }
        } catch {
            self.error = mapError(error)
        }
    }

    func navigateToSidebar(_ url: URL, name: String) async {
        do {
            if await grants.hasGrant(for: url) {
                _ = try await grants.activateGrant(for: url)
                await navigate(to: .fileSystem(url), named: name, resetPath: true)
            } else {
                requestAuthorization(for: url, purpose: .navigate(name: name))
            }
        } catch {
            self.error = mapError(error)
        }
    }

    func navigateToRecents() async {
        await navigate(
            to: .recents,
            named: AppLocalization.string("Recents", locale: preferences.language.locale),
            resetPath: true
        )
    }

    func navigateToComputer() async {
        let root = URL(fileURLWithPath: "/", isDirectory: true)
        await navigateToSidebar(root, name: AppLocalization.string("Computer", locale: preferences.language.locale))
    }

    func navigateToDesktop() async {
        await navigateToSidebar(
            UserDirectoryService.desktopURL,
            name: AppLocalization.string("Desktop", locale: preferences.language.locale)
        )
    }

    func navigateToHome() async {
        let home = UserDirectoryService.homeURL
        await navigateToSidebar(home, name: home.lastPathComponent)
    }

    func navigateToNetwork() async {
        let network = URL(fileURLWithPath: "/Network", isDirectory: true)
        await navigateToSidebar(network, name: AppLocalization.string("Network", locale: preferences.language.locale))
    }

    func navigateToDownloads() async {
        await navigateToSidebar(
            UserDirectoryService.downloadsURL,
            name: AppLocalization.string("Downloads", locale: preferences.language.locale)
        )
    }

    func navigateToDocuments() async {
        await navigateToSidebar(
            UserDirectoryService.documentsURL,
            name: AppLocalization.string("Documents", locale: preferences.language.locale)
        )
    }

    @discardableResult
    func navigateToFolder(path: String) async -> Bool {
        let url = UserDirectoryService.url(forUserEnteredPath: path)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
           !isDirectory.boolValue {
            error = .unavailable(AppLocalization.string("The path is not a folder.", locale: preferences.language.locale))
            return false
        }

        guard await grants.hasGrant(for: url) else {
            let displayName = FileManager.default.displayName(atPath: url.path)
            requestAuthorization(
                for: url,
                purpose: .navigate(name: displayName.isEmpty ? url.lastPathComponent : displayName)
            )
            return true
        }

        do {
            let item = try await fileSystem.item(at: url)
            guard item.isContainer else {
                error = .unavailable(AppLocalization.string("The path is not a folder.", locale: preferences.language.locale))
                return false
            }
            await navigateToSidebar(url, name: item.name)
            return true
        } catch {
            self.error = mapError(error)
            return false
        }
    }

    func configureOpenWindowAction(_ action: @escaping (URL?) -> Void) {
        openWindowHandler = action
    }

    func openInNewWindow(_ item: BrowserItem) {
        guard item.isContainer, let url = item.localURL else { return }
        openWindowHandler?(url)
    }

    func openParentInNewWindow() {
        guard let parentDirectoryURL else { return }
        openWindowHandler?(parentDirectoryURL)
    }

    func showGetInfo() {
        BrowserInfoWindowCoordinator.shared.present(
            items: previewItems,
            locale: preferences.language.locale
        )
    }

    func open(
        _ item: BrowserItem,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        if item.isContainer {
            await openContainer(item, recordsHistory: recordsHistory, clearsSelection: clearsSelection)
        } else if item.canNavigateAsArchive {
            await openArchive(item, recordsHistory: recordsHistory, clearsSelection: clearsSelection)
        } else {
            await openExternally(item)
        }
    }

    func openFromDoubleClick(
        _ item: BrowserItem,
        modifiers: NSEvent.ModifierFlags
    ) async {
        if modifiers.contains(.command), item.isContainer, item.localURL != nil {
            openInNewWindow(item)
            return
        }
        await open(item)
    }

    func openContainer(
        _ item: BrowserItem,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        switch item.location {
        case .recents:
            return
        case let .fileSystem(url):
            do {
                let resolved = try await fileSystem.resolveNavigationURL(url)
                let key = resolved.standardizedFileURL.path
                let ancestorPaths = Set(pathComponents.compactMap { component -> String? in
                    guard case let .fileSystem(ancestorURL) = component.location else { return nil }
                    return ancestorURL.resolvingSymlinksInPath().standardizedFileURL.path
                })
                guard !ancestorPaths.contains(key) else {
                    error = .unavailable(
                        AppLocalization.string(
                            "A symbolic-link cycle was prevented.",
                            locale: preferences.language.locale
                        )
                    )
                    return
                }
                await navigate(
                    to: .fileSystem(resolved),
                    named: item.name,
                    recordsHistory: recordsHistory,
                    clearsSelection: clearsSelection
                )
            } catch {
                self.error = mapError(error)
            }
        case let .archive(address):
            await navigate(
                to: .archive(address),
                named: item.name,
                recordsHistory: recordsHistory,
                clearsSelection: clearsSelection
            )
        }
    }

    func openArchive(
        _ item: BrowserItem,
        password: String? = nil,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        if case .archive = item.location,
           let size = item.size,
           size > 1_073_741_824,
           !confirmedLargeItems.contains(item.id) {
            pendingLargeOperation = .openNested(item)
            return
        }
        archiveOperationInProgress = true
        defer { archiveOperationInProgress = false }
        do {
            let result: ArchiveOpenResult
            switch item.location {
            case .recents:
                return
            case let .fileSystem(url):
                if let inlineResult = inlineArchiveResults[item.id] {
                    result = inlineResult
                } else {
                    result = try await archives.openArchive(
                        at: url,
                        password: password,
                        policy: preferences.archiveBrowsingPolicy
                    )
                }
            case .archive:
                result = try await archives.openNestedArchive(item: item, password: password)
            }
            passwordOperation = nil
            passwordError = nil
            await navigate(
                to: .archive(result.address),
                named: result.displayName,
                isArchive: true,
                recordsHistory: recordsHistory,
                clearsSelection: clearsSelection
            )
        } catch ArchiveEngineError.passwordRequired {
            passwordOperation = item.localURL.map(PasswordOperation.openFile) ?? .openNested(item)
        } catch ArchiveEngineError.invalidPassword {
            passwordError = AppLocalization.string(
                "Incorrect password. Try again.",
                locale: preferences.language.locale
            )
            passwordOperation = item.localURL.map(PasswordOperation.openFile) ?? .openNested(item)
        } catch {
            self.error = mapError(error)
        }
    }

    func submitPassword(_ password: String) async {
        guard let operation = passwordOperation else { return }
        switch operation {
        case let .openFile(url):
            do {
                let item = try await fileSystem.item(at: url)
                await openArchive(item, password: password)
            } catch {
                self.error = mapError(error)
            }
        case let .openNested(item):
            if let sessionID = operation.sessionID { await archives.setPassword(password, for: sessionID) }
            await openArchive(item, password: password)
        case let .expandInline(item):
            await toggleExpansion(item, password: password)
        }
    }

    func confirmLargeOperation() async {
        guard let operation = pendingLargeOperation else { return }
        let item = operation.item
        confirmedLargeItems.insert(item.id)
        pendingLargeOperation = nil
        switch operation {
        case .openNested: await openArchive(item)
        case .openExternally: await openExternally(item)
        }
    }

    func cancelArchiveOperation() {
        Task { await archives.cancelAllOperations() }
    }

    func goBack() async {
        guard let entry = backStack.popLast() else { return }
        forwardStack.append(HistoryEntry(components: pathComponents, location: location))
        pathComponents = entry.components
        location = entry.location
        activeColumnLocation = entry.location
        await reload()
    }

    func goForward() async {
        guard let entry = forwardStack.popLast() else { return }
        backStack.append(HistoryEntry(components: pathComponents, location: location))
        pathComponents = entry.components
        location = entry.location
        activeColumnLocation = entry.location
        await reload()
    }

    func goUp() async {
        guard pathComponents.count > 1 else { return }
        let target = pathComponents[pathComponents.count - 2]
        await navigateExistingPath(to: target)
    }

    func navigateExistingPath(to component: BrowserPathComponent) async {
        guard let index = pathComponents.firstIndex(where: { $0.id == component.id }) else { return }
        pushHistory()
        pathComponents = Array(pathComponents.prefix(index + 1))
        location = component.location
        activeColumnLocation = component.location
        await reload()
    }

    func navigateBreadcrumb(to component: BrowserPathComponent) async {
        if pathComponents.contains(where: { $0.id == component.id }) {
            await navigateExistingPath(to: component)
            return
        }

        guard case let .fileSystem(url) = component.location else { return }
        do {
            if await grants.hasGrant(for: url) {
                _ = try await grants.activateGrant(for: url)
                await navigate(
                    to: component.location,
                    named: component.name,
                    resetPath: true
                )
            } else {
                requestAuthorization(for: url, purpose: .navigate(name: component.name))
            }
        } catch {
            self.error = mapError(error)
        }
    }

    func reload(
        preservingColumnSelection: Bool = false,
        refreshingColumnLocations: Set<BrowserLocation> = []
    ) async {
        refreshTask?.cancel()
        let currentLocation = location
        let validSelection = selection
        let cursorSnapshot = hierarchyCursorSnapshot()
        let previousRootItems = items
        isLoading = true
        error = nil
        do {
            let loaded: [BrowserItem]
            switch currentLocation {
            case .recents:
                let urls = await recentItems.recentItemURLs()
                loaded = await loadRecentItems(at: urls)
            case let .fileSystem(url):
                loaded = try await fileSystem.items(in: url, showHidden: preferences.showHiddenFiles)
            case let .archive(address):
                loaded = try await archives.items(at: address)
            }
            guard currentLocation == location else { return }
            items = loaded
            purgeRemovedHierarchies(previous: previousRootItems, current: loaded)
            columnItems[currentLocation] = preferences.sort.sorted(loaded)
            for columnLocation in refreshingColumnLocations where columnLocation != currentLocation {
                await reloadColumnItems(at: columnLocation)
            }
            await refreshExpandedFileSystemHierarchy()
            let validSelectionIDs = preservingColumnSelection
                ? Set(knownItems.map(\.id))
                : Set(flattenedItems().map(\.id))
            selection = validSelection.intersection(validSelectionIDs)
            selectionOrder.removeAll { !selection.contains($0) }
            reconcileHierarchyCursor(
                from: cursorSnapshot,
                validSelectionIDs: validSelectionIDs
            )
            configureMonitor()
            synchronizeExpandedDirectoryMonitors()
            updatePreview()
            synchronizeRenamingSelection()
        } catch {
            self.error = mapError(error)
            items = []
            stopExpandedDirectoryMonitors()
        }
        isLoading = false
    }

    func refreshExpandedHierarchy() async {
        let cursorSnapshot = hierarchyCursorSnapshot()
        await refreshExpandedFileSystemHierarchy()
        let validSelectionIDs = Set(flattenedItems().map(\.id))
        selection.formIntersection(validSelectionIDs)
        selectionOrder.removeAll { !selection.contains($0) }
        reconcileHierarchyCursor(
            from: cursorSnapshot,
            validSelectionIDs: validSelectionIDs
        )
        synchronizeExpandedDirectoryMonitors()
        updatePreview()
    }

    func toggleHiddenFiles() {
        preferences.showHiddenFiles.toggle()
        Task { await reload() }
    }

    func togglePreviewVisibility() {
        previewVisible.toggle()
        updatePreview()
    }

    func duplicateSelectedFiles() {
        guard hasLocalSelection else { return }
        let urls = selectedLocalURLs
        NSWorkspace.shared.duplicate(urls) { [weak self] newURLs, operationError in
            Task { @MainActor in
                guard let self else { return }
                let duplicatedURLs = Array(newURLs.values)
                if !duplicatedURLs.isEmpty {
                    self.registerUndo(
                        removing: duplicatedURLs,
                        actionName: AppLocalization.string(
                            "Duplicate",
                            locale: self.preferences.language.locale
                        )
                    )
                }
                if let operationError {
                    self.error = self.mapError(operationError)
                }
                await self.reload()
            }
        }
    }

    func ejectSelectedVolume() {
        guard let volumeURL = ejectableVolumeURL else { return }
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volumeURL)
            Task { await navigateToComputer() }
        } catch {
            self.error = mapError(error)
        }
    }

    func createNewFolder() {
        guard let directory = fileOperationDestinationURL else { return }
        let locale = preferences.language.locale
        Task {
            do {
                let createdURL = try await fileOperations.createFolder(
                    in: directory,
                    locale: locale
                )
                registerUndo(
                    removing: [createdURL],
                    actionName: AppLocalization.string("New Folder", locale: preferences.language.locale)
                )
                renamingItemURL = createdURL.standardizedFileURL
                renameDraft = createdURL.lastPathComponent
                await reload()
                synchronizeRenamingSelection()
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func beginRenamingSelectedItem() {
        guard canRenameSelection, let item = primarySelection else { return }
        beginRenaming(item)
    }

    func beginRenaming(_ item: BrowserItem) {
        guard let itemURL = item.localURL else { return }
        if selection != [item.id] {
            select(item)
        }
        renameDraft = item.name
        renamingItemURL = itemURL.standardizedFileURL
    }

    func cancelRenaming() {
        guard !renameInProgress else { return }
        renamingItemURL = nil
        renameDraft = ""
    }

    func commitRename() {
        guard !renameInProgress,
              let sourceURL = renamingItemURL else {
            cancelRenaming()
            return
        }
        let currentName = knownItemsByID.values.first(where: {
            $0.localURL?.standardizedFileURL.path == sourceURL.standardizedFileURL.path
        })?.name ?? sourceURL.lastPathComponent
        guard renameDraft != currentName else {
            cancelRenaming()
            return
        }

        let requestedName = renameDraft
        renameInProgress = true
        Task {
            defer { renameInProgress = false }
            do {
                let renamedURL = try await fileOperations.rename(sourceURL, to: requestedName)
                registerUndo(
                    moving: [
                        BrowserExactFileMove(
                            sourceURL: renamedURL,
                            destinationURL: sourceURL
                        )
                    ],
                    actionName: AppLocalization.string("Rename", locale: preferences.language.locale)
                )
                renamingItemURL = nil
                renameDraft = ""
                await reload()
                selectLocalItem(at: renamedURL)
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func makeAliasesForSelection() {
        guard hasLocalSelection else { return }
        let urls = selectedLocalURLs
        Task {
            do {
                let created: [URL]
                if let destination = fileOperationDestinationURL {
                    created = try await fileOperations.createAliases(for: urls, in: destination)
                } else {
                    let grouped = Dictionary(grouping: urls) {
                        $0.deletingLastPathComponent().standardizedFileURL
                    }
                    var aliases: [URL] = []
                    for (destination, sourceURLs) in grouped {
                        aliases += try await fileOperations.createAliases(
                            for: sourceURLs,
                            in: destination
                        )
                    }
                    created = aliases
                }
                registerUndo(
                    removing: created,
                    actionName: AppLocalization.string("Make Alias", locale: preferences.language.locale)
                )
                await reload()
                selectLocalItems(at: created)
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func showOriginal() {
        guard selectedItems.count == 1, let aliasURL = selectedItems[0].localURL else { return }
        Task {
            do {
                guard let target = try await fileOperations.aliasTarget(for: aliasURL) else { return }
                let parent = target.deletingLastPathComponent()
                if await grants.hasGrant(for: parent) {
                    _ = try await grants.activateGrant(for: parent)
                    await reveal(target)
                } else {
                    requestAuthorization(for: parent, purpose: .reveal(target: target))
                }
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func moveClipboardItemsHere() {
        moveItemsHere(pasteboardFileURLs)
    }

    func moveItemsHere(_ urls: [URL]) {
        guard let destination = fileOperationDestinationURL else { return }
        guard !urls.isEmpty else { return }
        Task {
            await transfer(urls, to: destination, operation: .move)
        }
    }

    func moveSelectionToTrash() {
        guard hasLocalSelection else { return }
        let urls = selectedLocalURLs
        NSWorkspace.shared.recycle(urls) { [weak self] newURLs, operationError in
            Task { @MainActor in
                guard let self else { return }
                let restoreMoves = newURLs.map { originalURL, trashURL in
                    BrowserExactFileMove(
                        sourceURL: trashURL,
                        destinationURL: originalURL
                    )
                }
                if !restoreMoves.isEmpty {
                    self.registerUndo(
                        moving: restoreMoves,
                        actionName: AppLocalization.string(
                            "Move to Trash",
                            locale: self.preferences.language.locale
                        )
                    )
                }
                if let operationError {
                    self.error = self.mapError(operationError)
                }
                await self.reload()
            }
        }
    }

    func itemProvider(for item: BrowserItem) -> NSItemProvider? {
        guard let url = item.localURL else { return nil }
        if !selection.contains(item.id) {
            select(item)
        }
        return NSItemProvider(object: url as NSURL)
    }

    func copyItemProviders() -> [NSItemProvider] {
        selectedLocalURLs.map { NSItemProvider(object: $0 as NSURL) }
    }

    @discardableResult
    func copySelectionToPasteboard(_ pasteboard: NSPasteboard = .general) -> Bool {
        guard hasLocalSelection else { return false }
        pasteboard.clearContents()
        return pasteboard.writeObjects(selectedLocalURLs.map { $0 as NSURL })
    }

    func pasteItemProviders(_ providers: [NSItemProvider]) {
        guard let destination = fileOperationDestinationURL else { return }
        transferItemProviders(providers, to: destination, operation: .copy)
    }

    @discardableResult
    func performDrop(
        providers: [NSItemProvider],
        to destination: URL,
        operation: BrowserFileTransferOperation
    ) -> Bool {
        guard !providers.isEmpty else { return false }
        let destination = destination.standardizedFileURL

        let collector = BrowserDroppedFileURLCollector(count: providers.count) { [weak self] urls, failures in
            guard let self else { return }
            guard failures == 0, !urls.isEmpty else {
                self.error = .unavailable(
                    AppLocalization.string(
                        "The dropped file URLs could not be loaded.",
                        locale: self.preferences.language.locale
                    )
                )
                return
            }
            Task {
                await self.transfer(urls, to: destination, operation: operation)
            }
        }

        for (index, provider) in providers.enumerated() {
            provider.loadObject(ofClass: NSURL.self) { object, error in
                let url = (object as? NSURL).map { $0 as URL }
                Task { @MainActor in
                    collector.receive(url, error: error, at: index)
                }
            }
        }
        return true
    }

    private func transferItemProviders(
        _ providers: [NSItemProvider],
        to destination: URL,
        operation: BrowserFileTransferOperation
    ) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await fileURL(from: provider) {
                    urls.append(url)
                }
            }
            guard !urls.isEmpty else { return }
            await transfer(urls, to: destination, operation: operation)
        }
    }

    func setSort(_ field: BrowserSortField) {
        if preferences.sort.field == field {
            preferences.sort.ascending.toggle()
        } else {
            preferences.sort = BrowserSort(field: field, ascending: true)
        }
    }

    func select(
        _ item: BrowserItem,
        modifiers: NSEvent.ModifierFlags = [],
        orderedItems: [BrowserItem]? = nil
    ) {
        if let renamingItemID, renamingItemID != item.id {
            cancelRenaming()
        }
        let ordered = orderedItems ?? sortedItems
        var selectionActivity: [BrowserItemID] = []
        if modifiers.contains(.shift), let anchor = selectionAnchor,
           let anchorIndex = ordered.firstIndex(where: { $0.id == anchor }),
           let itemIndex = ordered.firstIndex(where: { $0.id == item.id }) {
            let range = min(anchorIndex, itemIndex)...max(anchorIndex, itemIndex)
            let rangeSelection = Set(ordered[range].map(\.id))
            selectionActivity = anchorIndex <= itemIndex
                ? Array(ordered[anchorIndex...itemIndex].map(\.id))
                : Array(ordered[itemIndex...anchorIndex].reversed().map(\.id))
            if modifiers.contains(.command) {
                selection.formUnion(rangeSelection)
            } else {
                selection = rangeSelection
            }
        } else if modifiers.contains(.command) {
            if selection.contains(item.id) {
                selection.remove(item.id)
            } else {
                selection.insert(item.id)
                selectionActivity = [item.id]
            }
            selectionAnchor = item.id
        } else {
            selection = [item.id]
            selectionActivity = [item.id]
            selectionAnchor = item.id
        }
        updateSelectionOrder(activity: selectionActivity)
        focusedItemID = item.id
        updatePreview()
    }

    func clearSelection() {
        cancelRenaming()
        selection.removeAll()
        selectionOrder.removeAll()
        focusedItemID = nil
        previewGeneration &+= 1
        previewTask?.cancel()
        previewTask = nil
        previewURL = nil
        previewRequiresManualLoad = false
        previewURLs.removeAll()
        previewItemsRequiringManualLoad.removeAll()
    }

    @discardableResult
    func prepareColumnView() -> Task<Void, Never> {
        let currentItems = sortedItems
        columnItems[location] = currentItems

        let selectedItem = focusedItemID.flatMap { focusedID in
            currentItems.first(where: { $0.id == focusedID })
        } ?? currentItems.first(where: { selection.contains($0.id) })

        guard let selectedItem else { return Task {} }
        return activateColumnItem(
            selectedItem,
            in: location,
            recordsHistory: false
        )
    }

    @discardableResult
    func prepareStandardViewAfterColumns() -> Task<Void, Never> {
        guard let activeColumnLocation,
              activeColumnLocation != location,
              let activeIndex = pathComponents.firstIndex(where: {
                  $0.location == activeColumnLocation
              }) else { return Task {} }

        pathComponents = Array(pathComponents.prefix(activeIndex + 1))
        location = activeColumnLocation
        items = columnItems[activeColumnLocation] ?? []
        let retainedLocations = Set(pathComponents.map(\.location))
        columnSelections = columnSelections.filter { retainedLocations.contains($0.key) }
        stopExpandedDirectoryMonitors()
        expandedItems.removeAll()
        expandedChildren.removeAll()
        configureMonitor()
        updatePreview()

        return Task { [weak self] in
            guard let self else { return }
            await self.reload()
        }
    }

    @discardableResult
    func activateColumnItem(
        _ item: BrowserItem,
        in parentLocation: BrowserLocation,
        modifiers: NSEvent.ModifierFlags = [],
        recordsHistory: Bool = true
    ) -> Task<Void, Never> {
        guard let parentIndex = pathComponents.firstIndex(where: { $0.location == parentLocation }) else {
            return Task {}
        }
        let parentItems = sortedColumnItems(at: parentLocation)
        columnSelections[parentLocation] = item.id
        activeColumnLocation = parentLocation
        select(item, modifiers: modifiers, orderedItems: parentItems)

        let retainedComponents = Array(pathComponents.prefix(parentIndex + 1))
        let opensBranch = !modifiers.contains(.command)
            && !modifiers.contains(.shift)
            && item.isNavigableContainer
        if recordsHistory && (retainedComponents != pathComponents || opensBranch) {
            pushHistory()
        }

        pathComponents = retainedComponents
        location = parentLocation
        items = columnItems[parentLocation] ?? []
        let retainedLocations = Set(retainedComponents.map(\.location))
        columnSelections = columnSelections.filter { retainedLocations.contains($0.key) }
        stopExpandedDirectoryMonitors()
        expandedItems.removeAll()
        expandedChildren.removeAll()
        configureMonitor()

        return Task { [weak self] in
            guard opensBranch, let self else { return }
            await self.open(item, recordsHistory: false, clearsSelection: false)
        }
    }

    func moveSelection(
        by delta: Int,
        extending: Bool = false,
        orderedItems: [BrowserItem]? = nil
    ) {
        let ordered = orderedItems ?? sortedItems
        guard !ordered.isEmpty else { return }
        let current = focusedItemID.flatMap { id in ordered.firstIndex(where: { $0.id == id }) } ?? (delta > 0 ? -1 : ordered.count)
        let index = min(max(current + delta, 0), ordered.count - 1)
        select(
            ordered[index],
            modifiers: extending ? [.shift] : [],
            orderedItems: ordered
        )
    }

    func moveListSelectionLeft() async {
        let visibleEntries = flattenedList()
        guard let selectedItem = primarySelection,
              let selectedIndex = visibleEntries.firstIndex(where: { $0.id == selectedItem.id }) else { return }

        if selectedItem.canExpandInlineInList, expandedItems.contains(selectedItem.id) {
            await toggleExpansion(selectedItem)
            return
        }

        let selectedDepth = visibleEntries[selectedIndex].depth
        guard selectedDepth > 0,
              let parentEntry = visibleEntries[..<selectedIndex].reversed().first(where: {
                  $0.depth == selectedDepth - 1
              }) else { return }

        select(parentEntry.item, orderedItems: flattenedItems())
    }

    func toggleExpansion(_ item: BrowserItem, password: String? = nil) async {
        recursiveExpansionGeneration &+= 1
        await toggleExpansionImpl(item, password: password)
    }

    func toggleAllDescendants(of item: BrowserItem) async {
        guard item.canExpandInlineInList else { return }
        recursiveExpansionGeneration &+= 1
        let generation = recursiveExpansionGeneration
        if expandedItems.contains(item.id) {
            collapseAllDescendants(of: item)
        } else {
            await expandAllDescendants(of: item, generation: generation)
        }
    }

    func expandAllDescendants(of item: BrowserItem) async {
        recursiveExpansionGeneration &+= 1
        await expandAllDescendants(
            of: item,
            generation: recursiveExpansionGeneration
        )
    }

    private func toggleExpansionImpl(_ item: BrowserItem, password: String? = nil) async {
        guard item.canExpandInlineInList else { return }
        if expandedItems.contains(item.id) {
            expandedItems.remove(item.id)
            stopExpandedDirectoryMonitors(in: cachedHierarchyIDs(rootedAt: item.id))
            return
        }
        expandedItems.insert(item.id)
        let refreshesFromFileSystem: Bool = {
            guard item.isDirectory, case let .fileSystem(url) = item.location else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }()
        if (expandedChildren[item.id] != nil && !refreshesFromFileSystem)
            || expandingItems.contains(item.id) {
            synchronizeExpandedDirectoryMonitors()
            return
        }
        expandingItems.insert(item.id)
        defer { expandingItems.remove(item.id) }
        do {
            let children: [BrowserItem]
            if item.isArchive {
                let result: ArchiveOpenResult
                if let existing = inlineArchiveResults[item.id] {
                    result = existing
                } else {
                    switch item.location {
                    case .recents:
                        return
                    case let .fileSystem(url):
                        result = try await archives.openArchive(
                            at: url,
                            password: password,
                            policy: preferences.archiveBrowsingPolicy
                        )
                    case .archive:
                        result = try await archives.openNestedArchive(item: item, password: password)
                    }
                    inlineArchiveResults[item.id] = result
                }
                children = try await archives.items(at: result.address)
                passwordOperation = nil
                passwordError = nil
            } else {
                switch item.location {
                case .recents:
                    return
                case let .fileSystem(url):
                    children = try await fileSystem.items(in: url, showHidden: preferences.showHiddenFiles)
                case let .archive(address):
                    children = try await archives.items(at: address)
                }
            }
            let previousChildren = expandedChildren[item.id] ?? []
            expandedChildren[item.id] = preferences.sort.sorted(children)
            purgeRemovedHierarchies(previous: previousChildren, current: children)
            synchronizeExpandedDirectoryMonitors()
        } catch ArchiveEngineError.passwordRequired {
            passwordOperation = .expandInline(item)
            passwordError = nil
            expandedItems.remove(item.id)
            synchronizeExpandedDirectoryMonitors()
        } catch ArchiveEngineError.invalidPassword {
            passwordOperation = .expandInline(item)
            passwordError = AppLocalization.string(
                "Incorrect password. Try again.",
                locale: preferences.language.locale
            )
            expandedItems.remove(item.id)
            synchronizeExpandedDirectoryMonitors()
        } catch {
            self.error = mapError(error)
            expandedItems.remove(item.id)
            synchronizeExpandedDirectoryMonitors()
        }
    }

    private func expandAllDescendants(
        of item: BrowserItem,
        generation: UInt64
    ) async {
        guard generation == recursiveExpansionGeneration,
              item.canExpandInlineInList else { return }
        if !expandedItems.contains(item.id) {
            await toggleExpansionImpl(item)
        }
        guard generation == recursiveExpansionGeneration,
              expandedItems.contains(item.id),
              let children = expandedChildren[item.id] else { return }
        for child in children where child.canExpandInlineInList {
            await expandAllDescendants(of: child, generation: generation)
        }
    }

    private func collapseAllDescendants(of item: BrowserItem) {
        var identifiers: Set<BrowserItemID> = [item.id]
        var pending = [item.id]
        while let identifier = pending.popLast() {
            for child in expandedChildren[identifier] ?? [] where child.canExpandInlineInList {
                if identifiers.insert(child.id).inserted {
                    pending.append(child.id)
                }
            }
        }
        expandedItems.subtract(identifiers)
        stopExpandedDirectoryMonitors(in: identifiers)
    }

    func flattenedList() -> [VisibleBrowserItem] {
        let rootItems = sortedItems
        let expandedItems = expandedItems
        let expandedChildren = expandedChildren
        let sort = preferences.sort
        let showsHidden = preferences.showHiddenFiles
        if let cache = flattenedListCache,
           cache.revision == hierarchyRevision,
           cache.sort == sort,
           cache.showsHidden == showsHidden {
            return cache.entries
        }

        var result: [VisibleBrowserItem] = []
        func append(_ children: [BrowserItem], depth: Int, alreadySorted: Bool = false) {
            let visibleChildren = children.filter { showsHidden || !$0.isHidden }
            let orderedChildren = alreadySorted ? visibleChildren : sort.sorted(visibleChildren)
            for child in orderedChildren {
                result.append(
                    VisibleBrowserItem(
                        item: child,
                        depth: depth,
                        isExpanded: expandedItems.contains(child.id),
                        rowIndex: result.count
                    )
                )
                if expandedItems.contains(child.id), let nested = expandedChildren[child.id] {
                    append(nested, depth: depth + 1)
                }
            }
        }
        append(rootItems, depth: 0, alreadySorted: true)
        flattenedListCache = (hierarchyRevision, sort, showsHidden, result, result.map(\.item))
        return result
    }

    func flattenedItems() -> [BrowserItem] {
        _ = flattenedList()
        return flattenedListCache?.orderedItems ?? []
    }

    func updatePreview(manual: Bool = false) {
        previewGeneration &+= 1
        let generation = previewGeneration
        previewTask?.cancel()
        previewTask = nil
        previewURL = nil
        previewRequiresManualLoad = false
        previewURLs.removeAll()
        previewItemsRequiringManualLoad.removeAll()
        guard previewVisible || preferences.viewMode == .gallery else { return }
        let previewableItems = selectedItems.filter { !$0.usesStaticIconPreview }
        guard !previewableItems.isEmpty else { return }

        var itemsToMaterialize: [BrowserItem] = []
        for item in previewableItems {
            if let localURL = item.localURL {
                previewURLs[item.id] = localURL
            } else if !manual,
                      let size = item.size,
                      size > 10 * 1_024 * 1_024 {
                previewItemsRequiringManualLoad.insert(item.id)
            } else {
                itemsToMaterialize.append(item)
            }
        }
        synchronizePrimaryPreviewState()
        guard !itemsToMaterialize.isEmpty else { return }

        previewTask = Task { [weak self] in
            guard let self else { return }
            if !manual {
                do {
                    try await Task.sleep(for: .milliseconds(80))
                } catch {
                    return
                }
            }
            for item in itemsToMaterialize {
                guard isPreviewRequestCurrent(itemID: item.id, generation: generation) else { continue }
                do {
                    let url = try await archives.materialize(
                        item: item,
                        purpose: .preview,
                        automaticLimit: manual ? nil : 10 * 1_024 * 1_024
                    )
                    guard isPreviewRequestCurrent(itemID: item.id, generation: generation) else { continue }
                    previewURLs[item.id] = url
                    synchronizePrimaryPreviewState()
                } catch BrowserError.previewTooLarge {
                    guard isPreviewRequestCurrent(itemID: item.id, generation: generation) else { continue }
                    previewItemsRequiringManualLoad.insert(item.id)
                    synchronizePrimaryPreviewState()
                } catch {
                    guard !Task.isCancelled,
                          isPreviewRequestCurrent(itemID: item.id, generation: generation) else { continue }
                    self.error = mapError(error)
                }
            }
            guard generation == previewGeneration else { return }
            previewTask = nil
        }
    }

    func openQuickLook(slideshow: Bool = false) {
        Task {
            let chosenItems = previewItems.filter { !$0.isContainer }
            let selectionSnapshot = selection
            guard !chosenItems.isEmpty else { return }
            do {
                var urls: [URL] = []
                for item in chosenItems {
                    guard selection.contains(item.id) else { continue }
                    if let localURL = item.localURL {
                        urls.append(localURL)
                    } else {
                        urls.append(
                            try await archives.materialize(
                                item: item,
                                purpose: .preview,
                                automaticLimit: nil
                            )
                        )
                    }
                }
                guard !urls.isEmpty, selection == selectionSnapshot else { return }
                previewURL = urls.first
                quickLookPanel.present(urls, slideshow: slideshow)
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func shareItems() {
        let chosenItems = selectedItems
        Task {
            do {
                var urls: [URL] = []
                for item in chosenItems where !item.isContainer {
                    if let localURL = item.localURL {
                        urls.append(localURL)
                    } else {
                        urls.append(try await archives.materialize(item: item, purpose: .openExternally, automaticLimit: nil))
                    }
                }
                guard !urls.isEmpty else { return }
                NSSharingServicePicker(items: urls).show(
                    relativeTo: .zero,
                    of: NSApp.keyWindow?.contentView ?? NSView(),
                    preferredEdge: .minY
                )
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func close() {
        undoManager?.removeAllActions(withTarget: self)
        monitor.stop()
        stopExpandedDirectoryMonitors()
        recentItems.stop()
        previewTask?.cancel()
        previewTask = nil
        refreshTask?.cancel()
        Task {
            await archives.cancelAllOperations()
            await archives.closeAllSessions()
            await grants.stopAll()
        }
    }

    private func openExternally(_ item: BrowserItem) async {
        if case .archive = item.location,
           let size = item.size,
           size > 1_073_741_824,
           !confirmedLargeItems.contains(item.id) {
            pendingLargeOperation = .openExternally(item)
            return
        }
        archiveOperationInProgress = true
        defer { archiveOperationInProgress = false }
        do {
            let url: URL
            switch item.location {
            case .recents:
                return
            case let .fileSystem(local): url = local
            case .archive:
                url = try await archives.materialize(item: item, purpose: .openExternally, automaticLimit: nil)
            }
            NSWorkspace.shared.open(url)
        } catch {
            self.error = mapError(error)
        }
    }

    private func navigate(
        to location: BrowserLocation,
        named name: String,
        isArchive: Bool = false,
        resetPath: Bool = false,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        cancelRenaming()
        if recordsHistory { pushHistory() }
        self.location = location
        if resetPath {
            pathComponents = [BrowserPathComponent(location: location, name: name, isArchive: isArchive)]
            columnItems.removeAll()
            columnSelections.removeAll()
        } else {
            pathComponents.append(BrowserPathComponent(location: location, name: name, isArchive: isArchive))
        }
        if clearsSelection {
            selection.removeAll()
            selectionOrder.removeAll()
            selectionAnchor = nil
            focusedItemID = nil
            activeColumnLocation = location
        }
        stopExpandedDirectoryMonitors()
        expandedItems.removeAll()
        expandedChildren.removeAll()
        await reload(preservingColumnSelection: !clearsSelection)
    }

    private func pushHistory() {
        backStack.append(HistoryEntry(components: pathComponents, location: location))
        forwardStack.removeAll()
    }

    private func updateSelectionOrder(activity: [BrowserItemID]) {
        selectionOrder.removeAll { !selection.contains($0) || activity.contains($0) }
        selectionOrder.append(contentsOf: activity.filter { selection.contains($0) })
    }

    private func hierarchyCursorSnapshot() -> HierarchyCursorSnapshot {
        HierarchyCursorSnapshot(
            orderedIDs: flattenedItems().map(\.id),
            focusedID: focusedItemID
        )
    }

    private func reconcileHierarchyCursor(
        from snapshot: HierarchyCursorSnapshot,
        validSelectionIDs: Set<BrowserItemID>
    ) {
        if let focusedID = snapshot.focusedID,
           validSelectionIDs.contains(focusedID),
           selection.contains(focusedID) {
            self.focusedItemID = focusedID
            if let selectionAnchor, !validSelectionIDs.contains(selectionAnchor) {
                self.selectionAnchor = focusedID
            }
            return
        }

        let visibleItems = flattenedItems()
        guard let previousIndex = snapshot.focusedIndex,
              !visibleItems.isEmpty else {
            focusedItemID = nil
            selectionAnchor = nil
            return
        }

        let replacement = visibleItems[min(previousIndex, visibleItems.count - 1)]
        selection = [replacement.id]
        selectionOrder = [replacement.id]
        selectionAnchor = replacement.id
        focusedItemID = replacement.id
    }

    private func refreshExpandedFileSystemHierarchy() async {
        var reachableExpandedItems: Set<BrowserItemID> = []

        func refresh(_ candidates: [BrowserItem]) async {
            for item in candidates where expandedItems.contains(item.id) {
                reachableExpandedItems.insert(item.id)
                var children = expandedChildren[item.id] ?? []

                if item.isDirectory,
                   case let .fileSystem(url) = item.location,
                   FileManager.default.fileExists(atPath: url.path) {
                    do {
                        let loaded = try await fileSystem.items(
                            in: url,
                            showHidden: preferences.showHiddenFiles
                        )
                        guard expandedItems.contains(item.id) else { continue }
                        let previousChildren = children
                        children = preferences.sort.sorted(loaded)
                        expandedChildren[item.id] = children
                        purgeRemovedHierarchies(previous: previousChildren, current: children)
                    } catch {
                        self.error = mapError(error)
                        continue
                    }
                }

                await refresh(children)
            }
        }

        await refresh(items)

        let unreachableItems = expandedItems.subtracting(reachableExpandedItems)
        guard !unreachableItems.isEmpty else { return }
        expandedItems.subtract(unreachableItems)
        stopExpandedDirectoryMonitors(in: unreachableItems)
        for itemID in unreachableItems {
            expandedChildren.removeValue(forKey: itemID)
            inlineArchiveResults.removeValue(forKey: itemID)
        }
    }

    private func purgeRemovedHierarchies(
        previous: [BrowserItem],
        current: [BrowserItem]
    ) {
        let currentIDs = Set(current.map(\.id))
        let removedIDs = Set(previous.lazy.map(\.id)).subtracting(currentIDs)
        purgeCachedHierarchies(rootedAt: removedIDs)
    }

    private func purgeCachedHierarchies(rootedAt rootIDs: Set<BrowserItemID>) {
        guard !rootIDs.isEmpty else { return }
        var pending = Array(rootIDs)
        var hierarchyIDs = rootIDs
        while let itemID = pending.popLast() {
            for child in expandedChildren[itemID] ?? [] where hierarchyIDs.insert(child.id).inserted {
                pending.append(child.id)
            }
        }

        expandedItems.subtract(hierarchyIDs)
        expandingItems.subtract(hierarchyIDs)
        stopExpandedDirectoryMonitors(in: hierarchyIDs)
        for itemID in hierarchyIDs {
            expandedChildren.removeValue(forKey: itemID)
            inlineArchiveResults.removeValue(forKey: itemID)
        }
    }

    private func cachedHierarchyIDs(rootedAt rootID: BrowserItemID) -> Set<BrowserItemID> {
        var result: Set<BrowserItemID> = [rootID]
        var pending = [rootID]
        while let itemID = pending.popLast() {
            for child in expandedChildren[itemID] ?? [] where result.insert(child.id).inserted {
                pending.append(child.id)
            }
        }
        return result
    }

    private func configureMonitor() {
        guard case let .fileSystem(url) = location else {
            monitor.stop()
            return
        }
        monitor.watch(url) { [weak self] in
            guard let self else { return }
            Task { await self.reload() }
        }
    }

    private func synchronizeExpandedDirectoryMonitors() {
        let expandedDirectories = flattenedItems().filter { item in
            guard expandedItems.contains(item.id), item.isDirectory else { return false }
            guard case let .fileSystem(url) = item.location else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }
        let expectedIDs = Set(expandedDirectories.map(\.id))
        stopExpandedDirectoryMonitors(
            in: Set(expandedDirectoryMonitors.keys).subtracting(expectedIDs)
        )

        for item in expandedDirectories where expandedDirectoryMonitors[item.id] == nil {
            guard case let .fileSystem(url) = item.location else { continue }
            let directoryMonitor = DirectoryMonitor()
            directoryMonitor.watch(url) { [weak self] in
                guard let self else { return }
                Task {
                    await self.refreshExpandedDirectory(
                        itemID: item.id,
                        expectedURL: url
                    )
                }
            }
            expandedDirectoryMonitors[item.id] = directoryMonitor
        }
    }

    private func refreshExpandedDirectory(
        itemID: BrowserItemID,
        expectedURL: URL
    ) async {
        guard expandedItems.contains(itemID),
              let item = knownItemsByID[itemID],
              item.isDirectory,
              case let .fileSystem(url) = item.location,
              url.standardizedFileURL.path == expectedURL.standardizedFileURL.path else { return }

        let cursorSnapshot = hierarchyCursorSnapshot()
        do {
            let loaded = try await fileSystem.items(
                in: url,
                showHidden: preferences.showHiddenFiles
            )
            guard expandedItems.contains(itemID) else { return }
            let previousChildren = expandedChildren[itemID] ?? []
            let children = preferences.sort.sorted(loaded)
            expandedChildren[itemID] = children
            purgeRemovedHierarchies(previous: previousChildren, current: children)

            let validSelectionIDs = Set(flattenedItems().map(\.id))
            selection.formIntersection(validSelectionIDs)
            selectionOrder.removeAll { !selection.contains($0) }
            reconcileHierarchyCursor(
                from: cursorSnapshot,
                validSelectionIDs: validSelectionIDs
            )
            synchronizeExpandedDirectoryMonitors()
            updatePreview()
        } catch {
            if !FileManager.default.fileExists(atPath: url.path) {
                purgeCachedHierarchies(rootedAt: [itemID])
                let validSelectionIDs = Set(flattenedItems().map(\.id))
                selection.formIntersection(validSelectionIDs)
                reconcileHierarchyCursor(
                    from: cursorSnapshot,
                    validSelectionIDs: validSelectionIDs
                )
                synchronizeExpandedDirectoryMonitors()
                updatePreview()
            } else {
                self.error = mapError(error)
            }
        }
    }

    private func stopExpandedDirectoryMonitors(in itemIDs: Set<BrowserItemID>) {
        for itemID in itemIDs {
            expandedDirectoryMonitors.removeValue(forKey: itemID)?.stop()
        }
    }

    private func stopExpandedDirectoryMonitors() {
        for directoryMonitor in expandedDirectoryMonitors.values {
            directoryMonitor.stop()
        }
        expandedDirectoryMonitors.removeAll()
    }

    private func loadRecentItems(at urls: [URL]) async -> [BrowserItem] {
        var loaded: [BrowserItem] = []
        loaded.reserveCapacity(urls.count)
        for url in urls {
            guard !Task.isCancelled else { break }
            if let item = try? await fileSystem.item(at: url),
               !item.isDirectory,
               preferences.showHiddenFiles || !item.isHidden {
                loaded.append(item)
            }
        }
        return loaded
    }

    private func fileSystemPathComponents(to url: URL) -> [BrowserPathComponent] {
        var urls: [URL] = []
        var current = url.standardizedFileURL
        while true {
            urls.append(current)
            let parent = current.deletingLastPathComponent().standardizedFileURL
            guard parent.path != current.path else { break }
            current = parent
        }

        return urls.reversed().map { componentURL in
            let name: String
            if componentURL.path == "/" {
                name = (try? componentURL.resourceValues(forKeys: [.volumeNameKey]).volumeName)
                    ?? FileManager.default.displayName(atPath: componentURL.path)
            } else {
                name = FileManager.default.displayName(atPath: componentURL.path)
            }
            return BrowserPathComponent(
                location: .fileSystem(componentURL),
                name: name,
                isArchive: false
            )
        }
    }

    private func isPreviewRequestCurrent(itemID: BrowserItemID, generation: UInt64) -> Bool {
        !Task.isCancelled
            && generation == previewGeneration
            && selection.contains(itemID)
            && knownItems.first(where: { $0.id == itemID })?.usesStaticIconPreview == false
            && (previewVisible || preferences.viewMode == .gallery)
    }

    private func synchronizePrimaryPreviewState() {
        guard let primarySelection else {
            previewURL = nil
            previewRequiresManualLoad = false
            return
        }
        previewURL = previewURLs[primarySelection.id]
        previewRequiresManualLoad = previewItemsRequiringManualLoad.contains(primarySelection.id)
    }

    private var selectedLocalURLs: [URL] {
        previewItems.compactMap(\.localURL)
    }

    private var pasteboardFileURLs: [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        return NSPasteboard.general.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) as? [URL] ?? []
    }

    private var ejectableVolumeURL: URL? {
        let candidates: [URL]
        if selectedLocalURLs.isEmpty {
            candidates = currentDirectoryURL.map { [$0] } ?? []
        } else {
            candidates = selectedLocalURLs
        }

        for candidate in candidates {
            guard let values = try? candidate.resourceValues(
                forKeys: [.volumeURLKey, .volumeIsEjectableKey]
            ), values.volumeIsEjectable == true,
                  let volume = values.volume?.standardizedFileURL,
                  candidate.standardizedFileURL == volume else { continue }
            return volume
        }
        return nil
    }

    private func transfer(
        _ urls: [URL],
        to destination: URL,
        operation: BrowserFileTransferOperation
    ) async {
        do {
            let resultingURLs = try await fileOperations.transfer(
                urls,
                to: destination,
                operation: operation
            )
            registerTransferUndo(
                sourceURLs: urls,
                resultingURLs: resultingURLs,
                operation: operation
            )
            if preferences.viewMode == .columns {
                var affectedColumnLocations = Set<BrowserLocation>(urls.map {
                    .fileSystem($0.deletingLastPathComponent().standardizedFileURL)
                })
                affectedColumnLocations.insert(.fileSystem(destination))
                await reload(refreshingColumnLocations: affectedColumnLocations)
            } else {
                await reload()
            }
            selectLocalItems(at: resultingURLs)
        } catch {
            self.error = mapError(error)
        }
    }

    private func reloadColumnItems(at location: BrowserLocation) async {
        guard case let .fileSystem(url) = location else { return }
        do {
            let loaded = try await fileSystem.items(
                in: url,
                showHidden: preferences.showHiddenFiles
            )
            columnItems[location] = preferences.sort.sorted(loaded)
        } catch {
            if !FileManager.default.fileExists(atPath: url.path) {
                columnItems.removeValue(forKey: location)
            } else {
                self.error = mapError(error)
            }
        }
    }

    func configureUndoManager(_ undoManager: UndoManager?) {
        guard self.undoManager !== undoManager else { return }
        self.undoManager?.removeAllActions(withTarget: self)
        self.undoManager = undoManager
    }

    private func registerTransferUndo(
        sourceURLs: [URL],
        resultingURLs: [URL],
        operation: BrowserFileTransferOperation
    ) {
        var removals: [URL] = []
        var moves: [BrowserExactFileMove] = []

        for (sourceURL, resultingURL) in zip(sourceURLs, resultingURLs) {
            let source = sourceURL.standardizedFileURL
            let result = resultingURL.standardizedFileURL
            guard source != result else { continue }
            if FileManager.default.fileExists(atPath: source.path) {
                removals.append(result)
            } else {
                moves.append(
                    BrowserExactFileMove(
                        sourceURL: result,
                        destinationURL: source
                    )
                )
            }
        }

        let actionName: String = switch operation {
        case .copy:
            AppLocalization.string("Copy", locale: preferences.language.locale)
        case .alias:
            AppLocalization.string("Make Alias", locale: preferences.language.locale)
        case .move:
            AppLocalization.string("Move", locale: preferences.language.locale)
        case .automatic:
            moves.isEmpty
                ? AppLocalization.string("Copy", locale: preferences.language.locale)
                : AppLocalization.string("Move", locale: preferences.language.locale)
        }
        registerUndo(removing: removals, moving: moves, actionName: actionName)
    }

    private func registerUndo(
        removing removals: [URL] = [],
        moving moves: [BrowserExactFileMove] = [],
        actionName: String
    ) {
        guard !removals.isEmpty || !moves.isEmpty, let undoManager else { return }
        let record = FileUndoRecord(
            removals: removals.map(\.standardizedFileURL),
            moves: moves,
            actionName: actionName
        )
        undoManager.registerUndo(withTarget: self) { state in
            state.performUndo(record)
        }
        undoManager.setActionName(actionName)
    }

    private func performUndo(_ record: FileUndoRecord) {
        Task {
            do {
                try await fileOperations.moveItems(record.moves)
                try await fileOperations.removeItems(at: record.removals)
                await reload()
            } catch {
                self.error = mapError(error)
            }
        }
    }

    private func reveal(_ target: URL) async {
        let parent = target.deletingLastPathComponent().standardizedFileURL
        let parentName = FileManager.default.displayName(atPath: parent.path)
        await navigate(
            to: .fileSystem(parent),
            named: parentName,
            resetPath: true
        )
        selectLocalItem(at: target)
    }

    private func selectLocalItem(at url: URL) {
        let targetPath = url.standardizedFileURL.path
        let orderedItems = visibleItemsForSelection()
        guard let item = orderedItems.first(where: {
            $0.localURL?.standardizedFileURL.path == targetPath
        }) else { return }
        select(item, orderedItems: orderedItems)
    }

    private func synchronizeRenamingSelection() {
        let orderedItems = visibleItemsForSelection()
        guard let renamingPath = renamingItemURL?.standardizedFileURL.path,
              let item = orderedItems.first(where: {
                  $0.localURL?.standardizedFileURL.path == renamingPath
              }) else { return }
        if selection != [item.id] || focusedItemID != item.id {
            select(item, orderedItems: orderedItems)
        }
    }

    private func selectLocalItems(at urls: [URL]) {
        let paths = Set(urls.map { $0.standardizedFileURL.path })
        let orderedItems = visibleItemsForSelection()
        let matchingItems = orderedItems.filter {
            guard let url = $0.localURL else { return false }
            return paths.contains(url.standardizedFileURL.path)
        }
        guard let first = matchingItems.first else { return }
        select(first, orderedItems: orderedItems)
        for item in matchingItems.dropFirst() {
            select(item, modifiers: [.command], orderedItems: orderedItems)
        }
    }

    private func visibleItemsForSelection() -> [BrowserItem] {
        preferences.viewMode == .list ? flattenedItems() : sortedItems
    }

    private func fileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: NSURL.self) { object, _ in
                continuation.resume(returning: (object as? NSURL).map { $0 as URL })
            }
        }
    }

    private func mapError(_ error: Error) -> BrowserError {
        if let error = error as? BrowserError { return error }
        if let error = error as? ArchiveEngineError { return .archive(error.localizedDescription) }
        if error is CancellationError { return .cancelled }
        return .unavailable(error.localizedDescription)
    }

    private func requestAuthorization(for url: URL, purpose: AuthorizationPurpose) {
        pendingAuthorizationPurpose = purpose
        pendingAuthorizationURL = url
    }
}

@MainActor
private final class BrowserDroppedFileURLCollector {
    private var urls: [URL?]
    private var remaining: Int
    private var failures = 0
    private let completion: ([URL], Int) -> Void

    init(count: Int, completion: @escaping ([URL], Int) -> Void) {
        urls = Array(repeating: nil, count: count)
        remaining = count
        self.completion = completion
    }

    func receive(_ url: URL?, error: Error?, at index: Int) {
        guard remaining > 0, urls.indices.contains(index) else { return }
        urls[index] = url
        if url == nil || error != nil {
            failures += 1
        }
        remaining -= 1
        guard remaining == 0 else { return }
        completion(urls.compactMap { $0 }, failures)
    }
}
