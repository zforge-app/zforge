import AppKit
import Foundation
import Observation
import QuickLookUI

@MainActor
@Observable
final class FileBrowserState {
    private struct HistoryEntry {
        let components: [BrowserPathComponent]
        let location: BrowserLocation
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
    @ObservationIgnored private let grants: any AccessGrantStoring
    @ObservationIgnored private let archives: any ArchiveServing
    @ObservationIgnored private let monitor = DirectoryMonitor()
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?
    @ObservationIgnored private var backStack: [HistoryEntry] = []
    @ObservationIgnored private var forwardStack: [HistoryEntry] = []
    @ObservationIgnored private var confirmedLargeItems: Set<BrowserItemID> = []
    @ObservationIgnored private var inlineArchiveResults: [BrowserItemID: ArchiveOpenResult] = [:]
    @ObservationIgnored private let initialURL: URL?
    @ObservationIgnored private let quickLookPanel = QuickLookPanelCoordinator()

    var preferences: FileBrowserPreferences
    var location: BrowserLocation
    var pathComponents: [BrowserPathComponent] = []
    var items: [BrowserItem] = []
    var selection: Set<BrowserItemID> = []
    var selectionAnchor: BrowserItemID?
    var expandedItems: Set<BrowserItemID> = []
    var expandedChildren: [BrowserItemID: [BrowserItem]] = [:]
    var expandingItems: Set<BrowserItemID> = []
    var columnItems: [BrowserLocation: [BrowserItem]] = [:]
    var columnSelections: [BrowserLocation: BrowserItemID] = [:]
    var isLoading = false
    var error: BrowserError?
    var pendingAuthorizationURL: URL?
    var passwordOperation: PasswordOperation?
    var passwordError: String?
    var previewURL: URL?
    var previewRequiresManualLoad = false
    var pendingLargeOperation: LargeOperation?
    var archiveOperationInProgress = false
    var previewVisible: Bool {
        get { preferences.previewVisible(in: preferences.viewMode) }
        set { preferences.setPreviewVisible(newValue, in: preferences.viewMode) }
    }
    var focusedItemID: BrowserItemID?
    var activeColumnLocation: BrowserLocation?

    var sortedItems: [BrowserItem] {
        preferences.sort.sorted(items.filter { preferences.showHiddenFiles || !$0.isHidden })
    }

    var selectedItems: [BrowserItem] {
        let ids = selection
        return knownItems.filter { ids.contains($0.id) }
    }

    var primarySelection: BrowserItem? {
        if let focusedItemID, let item = knownItems.first(where: { $0.id == focusedItemID }) { return item }
        return selectedItems.first
    }

    var archiveToolbarAction: ArchiveToolbarAction {
        switch location {
        case .archive:
            return selection.isEmpty ? .unavailableInsideArchive : .extractSelected
        case .fileSystem:
            let selectedItems = selectedItems
            guard !selectedItems.isEmpty else { return .unavailableOutsideArchive }
            if selectedItems.contains(where: { !$0.isArchive }) { return .compress }
            return .extractAll
        }
    }

    var knownItems: [BrowserItem] {
        var values: [BrowserItemID: BrowserItem] = [:]
        for item in items { values[item.id] = item }
        for children in expandedChildren.values {
            for item in children { values[item.id] = item }
        }
        for children in columnItems.values {
            for item in children { values[item.id] = item }
        }
        return Array(values.values)
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var title: String { pathComponents.last?.name ?? String(localized: "Home") }

    convenience init(initialURL: URL? = nil) {
        if ProcessInfo.processInfo.arguments.contains("--ui-fixtures") {
            self.init(
                preferences: FileBrowserPreferences.shared,
                fileSystem: UIFixtureFileSystemService(),
                grants: UIFixtureAccessGrantStore(),
                archives: UIFixtureArchiveEngine(),
                initialURL: initialURL
            )
            return
        }
        self.init(
            preferences: FileBrowserPreferences.shared,
            fileSystem: FileSystemService(),
            grants: AccessGrantStore(),
            archives: SevenZipArchiveEngine(),
            initialURL: initialURL
        )
    }

    init(
        preferences: FileBrowserPreferences,
        fileSystem: any FileSystemServing,
        grants: any AccessGrantStoring,
        archives: any ArchiveServing,
        initialURL: URL? = nil
    ) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.preferences = preferences
        self.fileSystem = fileSystem
        self.grants = grants
        self.archives = archives
        self.initialURL = initialURL
        location = .fileSystem(home)
        pathComponents = [BrowserPathComponent(location: .fileSystem(home), name: String(localized: "Home"), isArchive: false)]
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
        let home = FileManager.default.homeDirectoryForCurrentUser
        if await grants.hasGrant(for: home) {
            do {
                _ = try await grants.activateGrant(for: home)
                await reload()
            } catch {
                await grants.removeGrant(for: home)
                pendingAuthorizationURL = home
            }
        } else {
            pendingAuthorizationURL = home
        }
    }

    func authorize(_ selectedURL: URL, intendedURL: URL) async {
        do {
            try await grants.storeGrant(for: selectedURL)
            _ = try await grants.activateGrant(for: intendedURL)
            pendingAuthorizationURL = nil
            await navigate(to: .fileSystem(intendedURL), named: intendedURL == FileManager.default.homeDirectoryForCurrentUser ? String(localized: "Home") : intendedURL.lastPathComponent, resetPath: true)
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
                pendingAuthorizationURL = url
            }
        } catch {
            self.error = mapError(error)
        }
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

    func openContainer(
        _ item: BrowserItem,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        switch item.location {
        case let .fileSystem(url):
            do {
                let resolved = try await fileSystem.resolveNavigationURL(url)
                let key = resolved.standardizedFileURL.path
                let ancestorPaths = Set(pathComponents.compactMap { component -> String? in
                    guard case let .fileSystem(ancestorURL) = component.location else { return nil }
                    return ancestorURL.resolvingSymlinksInPath().standardizedFileURL.path
                })
                guard !ancestorPaths.contains(key) else {
                    error = .unavailable(String(localized: "A symbolic-link cycle was prevented."))
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
            passwordError = String(localized: "Incorrect password. Try again.")
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

    func reload(preservingColumnSelection: Bool = false) async {
        refreshTask?.cancel()
        let currentLocation = location
        let validSelection = selection
        isLoading = true
        error = nil
        do {
            let loaded: [BrowserItem]
            switch currentLocation {
            case let .fileSystem(url):
                loaded = try await fileSystem.items(in: url, showHidden: preferences.showHiddenFiles)
            case let .archive(address):
                loaded = try await archives.items(at: address)
            }
            guard currentLocation == location else { return }
            items = loaded
            columnItems[currentLocation] = preferences.sort.sorted(loaded)
            let validSelectionIDs = preservingColumnSelection
                ? Set(knownItems.map(\.id))
                : Set(loaded.map(\.id))
            selection = validSelection.intersection(validSelectionIDs)
            if let focusedItemID, !selection.contains(focusedItemID) { self.focusedItemID = nil }
            configureMonitor()
            updatePreview()
        } catch {
            self.error = mapError(error)
            items = []
        }
        isLoading = false
    }

    func toggleHiddenFiles() {
        preferences.showHiddenFiles.toggle()
        Task { await reload() }
    }

    func togglePreviewVisibility() {
        previewVisible.toggle()
        updatePreview()
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
        let ordered = orderedItems ?? sortedItems
        if modifiers.contains(.shift), let anchor = selectionAnchor,
           let anchorIndex = ordered.firstIndex(where: { $0.id == anchor }),
           let itemIndex = ordered.firstIndex(where: { $0.id == item.id }) {
            let range = min(anchorIndex, itemIndex)...max(anchorIndex, itemIndex)
            let rangeSelection = Set(ordered[range].map(\.id))
            if modifiers.contains(.command) {
                selection.formUnion(rangeSelection)
            } else {
                selection = rangeSelection
            }
        } else if modifiers.contains(.command) {
            if selection.contains(item.id) { selection.remove(item.id) } else { selection.insert(item.id) }
            selectionAnchor = item.id
        } else {
            selection = [item.id]
            selectionAnchor = item.id
        }
        focusedItemID = item.id
        updatePreview()
    }

    func clearSelection() {
        selection.removeAll()
        focusedItemID = nil
        previewTask?.cancel()
        previewTask = nil
        previewURL = nil
        previewRequiresManualLoad = false
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
        let parentItems = preferences.sort.sorted(columnItems[parentLocation] ?? [])
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

        select(parentEntry.item, orderedItems: visibleEntries.map(\.item))
    }

    func toggleExpansion(_ item: BrowserItem, password: String? = nil) async {
        guard item.canExpandInlineInList else { return }
        if expandedItems.contains(item.id) {
            expandedItems.remove(item.id)
            return
        }
        expandedItems.insert(item.id)
        if expandedChildren[item.id] != nil || expandingItems.contains(item.id) { return }
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
                case let .fileSystem(url):
                    children = try await fileSystem.items(in: url, showHidden: preferences.showHiddenFiles)
                case let .archive(address):
                    children = try await archives.items(at: address)
                }
            }
            expandedChildren[item.id] = preferences.sort.sorted(children)
        } catch ArchiveEngineError.passwordRequired {
            passwordOperation = .expandInline(item)
            passwordError = nil
            expandedItems.remove(item.id)
        } catch ArchiveEngineError.invalidPassword {
            passwordOperation = .expandInline(item)
            passwordError = String(localized: "Incorrect password. Try again.")
            expandedItems.remove(item.id)
        } catch {
            self.error = mapError(error)
            expandedItems.remove(item.id)
        }
    }

    func flattenedList() -> [VisibleBrowserItem] {
        var result: [VisibleBrowserItem] = []
        func append(_ children: [BrowserItem], depth: Int) {
            let visibleChildren = children.filter { preferences.showHiddenFiles || !$0.isHidden }
            for child in preferences.sort.sorted(visibleChildren) {
                result.append(VisibleBrowserItem(item: child, depth: depth, isExpanded: expandedItems.contains(child.id)))
                if expandedItems.contains(child.id), let nested = expandedChildren[child.id] {
                    append(nested, depth: depth + 1)
                }
            }
        }
        append(sortedItems, depth: 0)
        return result
    }

    func updatePreview(manual: Bool = false) {
        previewTask?.cancel()
        previewTask = nil
        previewURL = nil
        previewRequiresManualLoad = false
        guard previewVisible || preferences.viewMode == .gallery else { return }
        guard let item = primarySelection,
              !item.isContainer,
              !item.isArchive else { return }
        if let localURL = item.localURL {
            previewURL = localURL
            return
        }
        if !manual, let size = item.size, size > 10 * 1_024 * 1_024 {
            previewRequiresManualLoad = true
            return
        }
        previewTask = Task {
            do {
                let url = try await archives.materialize(
                    item: item,
                    purpose: .preview,
                    automaticLimit: manual ? nil : 10 * 1_024 * 1_024
                )
                guard !Task.isCancelled,
                      primarySelection?.id == item.id,
                      primarySelection?.isContainer == false else { return }
                previewTask = nil
                previewURL = url
            } catch BrowserError.previewTooLarge {
                guard !Task.isCancelled, primarySelection?.id == item.id else { return }
                previewTask = nil
                previewRequiresManualLoad = true
            } catch {
                guard !Task.isCancelled, primarySelection?.id == item.id else { return }
                previewTask = nil
                self.error = mapError(error)
            }
        }
    }

    func openQuickLook() {
        Task {
            if let previewURL {
                quickLookPanel.present([previewURL])
                return
            }
            guard let item = primarySelection, !item.isContainer else { return }
            do {
                let url: URL
                if let localURL = item.localURL {
                    url = localURL
                } else {
                    url = try await archives.materialize(item: item, purpose: .preview, automaticLimit: nil)
                }
                previewURL = url
                quickLookPanel.present([url])
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
        monitor.stop()
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
            selectionAnchor = nil
            focusedItemID = nil
            activeColumnLocation = location
        }
        expandedItems.removeAll()
        expandedChildren.removeAll()
        await reload(preservingColumnSelection: !clearsSelection)
    }

    private func pushHistory() {
        backStack.append(HistoryEntry(components: pathComponents, location: location))
        forwardStack.removeAll()
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

    private func mapError(_ error: Error) -> BrowserError {
        if let error = error as? BrowserError { return error }
        if let error = error as? ArchiveEngineError { return .archive(error.localizedDescription) }
        if error is CancellationError { return .cancelled }
        return .unavailable(error.localizedDescription)
    }
}
