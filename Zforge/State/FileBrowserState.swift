import AppKit
import Foundation
import Observation
import QuickLookUI
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class FileBrowserState {
    private enum AuthorizationPurpose {
        case navigate(name: String)
        case loadRecents
        case reveal(target: URL)
        case finderRequest(FinderMenuRequest)
        case openInNewTab
    }

    private struct HistoryEntry {
        let components: [BrowserPathComponent]
        let location: BrowserLocation
        let sidebarTag: String?
        var archiveSearch: String? = nil
        var fileSearch: BrowserFileSearch? = nil
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
        let supportsRedo: Bool
    }

    enum PasswordOperation {
        case openFile(URL)
        case openInnerArchive(BrowserItem)
        case expandInline(BrowserItem)
        case extractArchive(BrowserItem)
        case validateArchive(BrowserItem)
        case extractItems([BrowserItem], destinationURL: URL)

        var sessionID: UUID? {
            let item: BrowserItem?
            switch self {
            case let .openInnerArchive(value), let .extractArchive(value), let .validateArchive(value): item = value
            case let .extractItems(values, _): item = values.first
            case .openFile, .expandInline: item = nil
            }
            guard let item,
                  case let .archive(address) = item.location else { return nil }
            return address.sessionID
        }
    }

    private enum ExtractionDestination {
        case here
        case named
        case chosen(URL)
    }

    enum LargeOperation {
        case openInnerArchive(BrowserItem)
        case openExternally(BrowserItem)

        var item: BrowserItem {
            switch self {
            case let .openInnerArchive(item), let .openExternally(item): item
            }
        }
    }

    struct PermanentDeletionRequest: Equatable {
        let urls: [URL]

        var itemCount: Int { urls.count }
    }

    struct ArchiveAdditionRequest: Equatable {
        let sourceURLs: [URL]
        let archiveURL: URL
        let internalPath: String
    }

    struct ArchiveTransferConfirmation: Equatable {
        let archiveURL: URL
        let itemCount: Int
        let destination: String
        let moving: Bool
    }
    @ObservationIgnored var archiveTransferConfirmation: ((ArchiveTransferConfirmation) -> Bool)?

    func archiveTransferAlert(_ request: ArchiveTransferConfirmation) -> NSAlert {
        let locale = preferences.language.locale
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Modify the Original Archive?", locale: locale)
        alert.informativeText = String(format: AppLocalization.string(
            request.moving ? "Moving %lld item(s) to %@ will modify the original archive %@. The source entries will be removed only after the transfer succeeds."
                : "Copying %lld item(s) to %@ will modify the original archive %@. The source entries will be preserved.", locale: locale),
            Int64(request.itemCount), request.destination, request.archiveURL.lastPathComponent)
        alert.addButton(withTitle: AppLocalization.string(request.moving ? "Move" : "Copy", locale: locale)).keyEquivalent = "\r"
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale)).keyEquivalent = "\u{1b}"
        return alert
    }

    func confirmArchiveTransfer(_ items: [BrowserItem], destination: String, moving: Bool) async throws {
        guard let first = items.first, case let .archive(address) = first.location else { throw ArchiveEngineError.itemNotFound }
        let request = ArchiveTransferConfirmation(archiveURL: try await archives.archiveRootURL(for: address),
            itemCount: items.count, destination: destination, moving: moving)
        let approved = archiveTransferConfirmation?(request) ?? (archiveTransferAlert(request).runModal() == .alertFirstButtonReturn)
        guard approved else { throw ArchiveEngineError.cancelled }
    }

    func archiveAddress(for url: URL) -> ArchiveAddress? {
        if let result = inlineArchiveResults.first(where: { knownItemsByID[$0.key]?.localURL?.standardizedFileURL == url.standardizedFileURL })?.value {
            return result.address
        }
        return nil
    }

    func reorganizeArchiveItems(_ items: [BrowserItem], to destination: ArchiveAddress, moving: Bool) async throws {
        guard canReorganizeArchiveItems(items, to: destination), case let .archive(source) = items[0].location
        else { throw ArchiveEngineError.updateUnsupported }
        if moving, items.allSatisfy({ item in
            guard case let .archive(address) = item.location else { return false }
            return (address.internalPath as NSString).deletingLastPathComponent == destination.internalPath
        }) { return }
        try await confirmArchiveTransfer(items, destination: destination.internalPath.isEmpty ? "/" : destination.internalPath, moving: moving)
        archiveOperationInProgress = true
        defer { archiveOperationInProgress = false; archiveProgress = nil }
        let url = try await archives.archiveRootURL(for: source)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        var password: String?
        let result: ArchiveReorganizationResult
        while true {
            do {
                result = try await archives.reorganizeItems(items, to: destination, moving: moving, password: password,
                    resolveConflict: { [weak self] conflict in await self?.resolveArchiveConflict(conflict) ?? .cancel },
                    progress: archiveProgressHandler())
                break
            } catch ArchiveEngineError.passwordRequired {
                guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }; password = supplied
            } catch ArchiveEngineError.invalidPassword {
                guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }; password = supplied
            }
        }
        guard !result.paths.isEmpty else { return }
        try await refreshUpdatedArchive(ArchiveAdditionRequest(sourceURLs: result.paths.map { URL(fileURLWithPath: $0) },
            archiveURL: url, internalPath: destination.internalPath), password: result.password,
            navigation: .revealDestination)
    }

    @ObservationIgnored private let fileSystem: any FileSystemServing
    @ObservationIgnored private let fileOperations: any FileOperationServing
    @ObservationIgnored private let recentItems: any RecentItemsServing
    @ObservationIgnored private let taggedItems: any TaggedItemsServing
    @ObservationIgnored private var tagRefreshTask: Task<Void, Never>?
    @ObservationIgnored private let grants: any AccessGrantStoring
    @ObservationIgnored private let archives: any ArchiveServing
    @ObservationIgnored private let volumes: any VolumeCataloging
    @ObservationIgnored private let networkBrowser: any NetworkServerBrowsing
    @ObservationIgnored private let networkMounter: any NetworkServerMounting
    /// Runs while the path shows the Network level; cancelled when it leaves the path or the window closes.
    @ObservationIgnored private var networkDiscoveryTask: Task<Void, Never>?
    @ObservationIgnored private var networkConnectionTask: Task<Void, Never>?
    @ObservationIgnored private var networkServers: [NetworkServer] = []
    @ObservationIgnored private var volumeObservers: [NSObjectProtocol] = []
    @ObservationIgnored private let monitor = DirectoryMonitor()
    @ObservationIgnored private var expandedDirectoryMonitors: [BrowserItemID: DirectoryMonitor] = [:]
    @ObservationIgnored private var reloadGeneration: UInt64 = 0
    @ObservationIgnored private(set) var previewTask: Task<Void, Never>?
    @ObservationIgnored private var previewGeneration: UInt64 = 0
    @ObservationIgnored private var columnActivationTask: Task<Void, Never>?
    @ObservationIgnored private var columnActivationGeneration: UInt64 = 0
    @ObservationIgnored private var backStack: [HistoryEntry] = []
    @ObservationIgnored private var forwardStack: [HistoryEntry] = []
    @ObservationIgnored private var confirmedLargeItems: Set<BrowserItemID> = []
    @ObservationIgnored private var inlineArchiveResults: [BrowserItemID: ArchiveOpenResult] = [:]
    @ObservationIgnored private var pendingArchiveExtractionItems: [BrowserItem] = []
    @ObservationIgnored private var pendingArchiveExtractionIndex = 0
    @ObservationIgnored private var pendingExtractionDestination: ExtractionDestination = .named
    @ObservationIgnored private var pendingValidationItems: [BrowserItem] = []
    @ObservationIgnored private var pendingValidationIndex = 0
    @ObservationIgnored private let initialURL: URL?
    @ObservationIgnored private var initialAutomationAccessLease: AutomationAccessLease?
    /// Archives are read in place for the whole session (D-73): an archive opened with an
    /// automation grant keeps that grant until the window closes, not only while opening.
    @ObservationIgnored private var archiveSessionAccessLease: AutomationAccessLease?
    @ObservationIgnored private let initialArchiveSearch: String?
    @ObservationIgnored private var initialFinderRequest: FinderMenuRequest?
    @ObservationIgnored private let archiveSearch: any ArchiveSearching
    // Results stay readable, and archives opened from them stay extractable,
    // until the window closes. A refreshed search replaces the equivalent scope.
    @ObservationIgnored private var archiveSearchLease: AutomationAccessLease?
    @ObservationIgnored private let quickLookPanel = QuickLookPanelCoordinator()
    @ObservationIgnored private var pendingAuthorizationPurpose: AuthorizationPurpose?
    @ObservationIgnored private var openWindowHandler: ((URL?) -> Void)?
    @ObservationIgnored private var openTabHandler: ((URL) -> Void)?
    @ObservationIgnored private var openArchiveWindowHandler: ((BrowserWindowRequest) -> Void)?
    @ObservationIgnored private var windowCloseHandler: (() -> Void)?
    /// An inner archive opened by another window, shown when this window starts.
    @ObservationIgnored private var initialArchiveSession: ArchiveSessionHandoff?
    /// The session each inner archive session this window knows was opened from.
    @ObservationIgnored private(set) var archiveSessionParents: [UUID: UUID] = [:]
    /// The latest listing revision this window shows for each shared session it knows.
    @ObservationIgnored private var shownSessionRevisions: [UUID: Int] = [:]
    @ObservationIgnored private var pendingSessionChanges: [UUID: Int] = [:]
    @ObservationIgnored private var sessionChangeObserver: NSObjectProtocol?
    /// The update a change of a shared session started in this window (tests await it).
    @ObservationIgnored private(set) var sessionChangeTask: Task<Void, Never>?
    /// Releasing this window's sessions after it closes (quitting awaits it).
    @ObservationIgnored private(set) var closingTask: Task<Void, Never>?
    @ObservationIgnored private weak var undoManager: UndoManager?
    @ObservationIgnored private(set) var fileUndoTask: Task<Void, Never>?
    @ObservationIgnored private var isClosed = false
    @ObservationIgnored private let itemProjection = BrowserItemProjection()
    @ObservationIgnored private var recursiveExpansionGeneration: UInt64 = 0
    @ObservationIgnored private var activeFileTransferCount = 0

    var preferences: FileBrowserPreferences
    // Each window snapshots the default; changing its mode leaves other windows intact.
    var viewMode: BrowserViewMode
    var location: BrowserLocation {
        didSet { if location != .recents { selectedSidebarTag = nil; archiveSearchTerm = nil } }
    }
    var selectedSidebarTag: String?
    /// Archive name search shown in the virtual results list, for example after
    /// Siri asks Zforge to search. Shares the Recents virtual location with tags.
    private(set) var archiveSearchTerm: String?
    /// The toolbar search shown in the virtual results location. It stays set while
    /// Columns show a result's contents beside the results column.
    private(set) var fileSearch: BrowserFileSearch? {
        didSet {
            guard oldValue != nil, fileSearch == nil else { return }
            searchDebounceTask?.cancel()
            searchStreamTask?.cancel()
            if keepsSearchFieldOnExit {
                keepsSearchFieldOnExit = false
            } else {
                searchText = ""
                isSearchPresented = false
            }
        }
    }
    /// Whether the toolbar shows the expanded search field instead of its button.
    var isSearchPresented = false
    private(set) var searchText = ""
    private(set) var searchScope: BrowserSearchScope = .currentFolder
    /// Incremented to move focus into the toolbar field, for example by ⌘F.
    private(set) var searchFieldFocusRequest = 0
    /// Set by the toolbar field so content focus and single-key menu commands leave its text alone.
    var searchFieldHasFocus = false
    @ObservationIgnored private let searcher: any BrowserSearching
    @ObservationIgnored private let searchDebounce: @Sendable () async throws -> Void
    @ObservationIgnored private var searchDebounceTask: Task<Void, Never>?
    @ObservationIgnored private var searchStreamTask: Task<[BrowserItem], Error>?
    @ObservationIgnored private var searchOriginEntry: HistoryEntry?
    @ObservationIgnored private var keepsSearchFieldOnExit = false
    private var needsExtendedMetadata: Bool {
        let extended: Set<BrowserListColumn> = [.lastOpenedDate, .dateAdded, .version, .comments]
        let sortedByExtended = [BrowserSortField.lastOpenedDate, .dateAdded, .version, .comments]
            .contains(preferences.sort.field)
        return sortedByExtended || (viewMode == .list &&
            !extended.isDisjoint(with: preferences.visibleListColumns(for: location)))
    }
    var sidebarTags: [String] {
        var discovered = Set(preferences.knownSidebarTags + items.flatMap(\.tags)
            + expandedChildren.values.flatMap { $0.flatMap(\.tags) })
        if let selectedSidebarTag { discovered.insert(selectedSidebarTag) }
        return discovered.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
    var pathComponents: [BrowserPathComponent] = [] {
        didSet { synchronizeNetworkDiscovery() }
    }
    /// Local Network privacy blocks server discovery; the Network level's empty state explains it.
    private(set) var networkDiscoveryDenied = false
    var items: [BrowserItem] = [] {
        didSet { itemProjection.invalidateRoot() }
    }
    var selection: Set<BrowserItemID> = []
    private(set) var selectionOrder: [BrowserItemID] = []
    var selectionAnchor: BrowserItemID?
    var expandedItems: Set<BrowserItemID> = [] {
        didSet { itemProjection.invalidateExpansion() }
    }
    var expandedChildren: [BrowserItemID: [BrowserItem]] = [:] {
        didSet {
            itemProjection.invalidateExpandedChildren()
            let children = expandedChildren.values.flatMap { $0 }
            preferences.rememberSidebarTags(children.flatMap(\.tags))
            FinderTagCatalog.shared.observe(children)
        }
    }
    var expandingItems: Set<BrowserItemID> = []
    var columnItems: [BrowserLocation: [BrowserItem]] = [:] {
        didSet { itemProjection.invalidateColumns() }
    }
    var columnSelections: [BrowserLocation: BrowserItemID] = [:]
    var isLoading = false
    var error: BrowserError?
    /// Volumes with an eject in flight; their sidebar eject button shows progress and ignores clicks.
    var ejectingVolumeURLs: Set<URL> = []
    @ObservationIgnored var volumeEjector: @Sendable (URL) async throws -> Void = VolumeEjection.eject
    var pendingAuthorizationURL: URL?
    var passwordOperation: PasswordOperation? {
        didSet {
            if passwordOperation == nil { initialAutomationAccessLease = nil }
        }
    }
    var passwordError: String?
    var previewURL: URL?
    var previewRequiresManualLoad = false
    var previewURLs: [BrowserItemID: URL] = [:]
    var previewItemsRequiringManualLoad: Set<BrowserItemID> = []
    var pendingLargeOperation: LargeOperation?
    var pendingPermanentDeletion: PermanentDeletionRequest?
    var pendingArchiveAddition: ArchiveAdditionRequest?
    var fileOperationInProgress = false
    var fileOperationDescription = ""
    var archiveOperationInProgress = false {
        didSet {
            // Changes of shared sessions wait for this window's own operation to finish.
            if !archiveOperationInProgress {
                archiveOperationRevealTask?.cancel()
                archiveOperationRevealTask = nil
                archiveOperationIsVisible = true
                scheduleArchiveSessionChanges()
            }
        }
    }
    /// Whether the archive operation's progress and Cancel are shown. Opening an archive
    /// shows them only once it takes longer than `archiveOpeningRevealDelay`, so quick
    /// openings do not flash an overlay.
    private(set) var archiveOperationIsVisible = true
    @ObservationIgnored var archiveOpeningRevealDelay: Duration = .milliseconds(400)
    @ObservationIgnored private var archiveOperationRevealTask: Task<Void, Never>?
    /// The volume each shared session's archive (outermost on disk) is stored on.
    @ObservationIgnored private(set) var archiveVolumeKinds: [UUID: ArchiveVolumeKind] = [:]
    /// Classifies an archive's volume (tests substitute it).
    @ObservationIgnored var volumeClassifier: @Sendable (URL) -> ArchiveVolumeKind = { ArchiveVolumeKind.of($0) }
    /// Sessions whose archive cannot be written: inner archives of archives that cannot
    /// be updated (D-73).
    private(set) var readOnlyArchiveSessions: Set<UUID> = []
    var contextualFeedbackMessage: String?
    var archiveProgress: ArchiveProgress?
    var archiveOperationDescription = "Working with archive…"
    var showingGoToFolder = false
    var showingServerConnection = false
    var renamingItemURL: URL?
    var renameDraft = ""
    var renameInProgress = false
    var previewVisible: Bool {
        get { preferences.previewVisible(in: viewMode) }
        set { preferences.setPreviewVisible(newValue, in: viewMode) }
    }
    var focusedItemID: BrowserItemID?
    var activeColumnLocation: BrowserLocation?
    var pendingColumnExpansionItemID: BrowserItemID?

    var sortedItems: [BrowserItem] {
        itemProjection.sortedRootItems(
            items, sort: preferences.sort, showsHidden: preferences.showHiddenFiles
        )
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

    /// Inline expansion is a List presentation state, independent of selection and contents.
    func usesOpenFolderIcon(for item: BrowserItem) -> Bool {
        guard viewMode == .list, item.isDirectory, !item.isPackage else { return false }
        return expandedItems.contains(item.id)
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
        let selectedItems = selectedItems
        guard !selectedItems.isEmpty else {
            if case .archive = location { return .unavailableInsideArchive }
            return .unavailableOutsideArchive
        }

        let virtualItems = selectedItems.filter {
            if case .archive = $0.location { return true }
            return false
        }
        if !virtualItems.isEmpty {
            return virtualItems.count == selectedItems.count
                ? .extractSelected
                : .unavailableInsideArchive
        }

        guard selectedItems.allSatisfy({ $0.localURL != nil }) else {
            if case .archive = location { return .unavailableInsideArchive }
            return .unavailableOutsideArchive
        }
        if selectedItems.contains(where: { !$0.isArchive }) { return .compress }
        return .extractAll
    }

    func contextualActions(for selected: [BrowserItem]) -> [BrowserSelectionAction] {
        let actions = BrowserSelectionActionPolicy.actions(for: selected)
        return canRemoveArchiveItems(selected) ? actions + [.removeFromArchive] : actions
    }

    func contextualTitle(_ action: BrowserSelectionAction, items selected: [BrowserItem]) -> String {
        let locale = preferences.language.locale
        switch action {
        case .open: return AppLocalization.string("Open", locale: locale)
        case .compress: return AppLocalization.string("Compress", locale: locale)
        case .compressCustom: return AppLocalization.string("Compress Custom…", locale: locale)
        case .addToArchive: return AppLocalization.string("Add to Archive…", locale: locale)
        case .removeFromArchive: return AppLocalization.string("Remove from Archive…", locale: locale)
        case .extractHere: return AppLocalization.string("Extract Here", locale: locale)
        case .extractNamed:
            let names = selected.map { archiveExtractionDirectoryName(for: $0.name) }.joined(separator: ", ")
            return String(format: AppLocalization.string("Extract to \"%@\"", locale: locale), names)
        case .extractChoose: return AppLocalization.string("Extract…", locale: locale)
        case .validate: return AppLocalization.string("Validate", locale: locale)
        }
    }

    func performContextualAction(_ action: BrowserSelectionAction, items selected: [BrowserItem]) async -> String? {
        guard contextualActions(for: selected).contains(action), !archiveOperationInProgress else { return nil }
        switch action {
        case .open:
            if selected.count > 1, selected.allSatisfy(\.isArchive) {
                selected.compactMap(\.localURL).forEach { openWindowHandler?($0) }
            } else {
                for item in selected { await open(item) }
            }
            return nil
        case .removeFromArchive:
            requestArchiveRemoval(items: selected)
            return nil
        case .addToArchive:
            let sources = selected.compactMap(\.localURL)
            guard sources.count == selected.count else { return nil }
            let panel = UITestLaunchIsolation.openPanel()
            panel.title = AppLocalization.string("Choose an Archive", locale: preferences.language.locale)
            panel.prompt = AppLocalization.string("Choose", locale: preferences.language.locale)
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.directoryURL = archiveCreationDirectory(for: sources)
            guard panel.runModal() == .OK, let destination = panel.url else { return nil }
            requestArchiveAddition(sources, to: destination)
            return nil
        case .compress, .compressCustom:
            let sources = selected.compactMap(\.localURL)
            guard sources.count == selected.count,
                  let directory = archiveCreationDirectory(for: sources) else { return nil }
            let options: CompressionOptions
            let password: String?
            var outputURL: URL
            var tags: [String] = []
            var scopedDirectory: URL?
            if action == .compressCustom {
                let draft = CompressionDraft(preferences: preferences)
                let suggestedName = uniqueArchiveOutputURL(
                    for: sources, in: directory, format: draft.options.format
                ).lastPathComponent
                guard let selection = await CompressionSaveDialogSession.present(
                    draft: draft,
                    preferences: preferences,
                    name: suggestedName,
                    directory: directory
                ) else { return nil }
                options = draft.options.normalized()
                if options.requiresPassword {
                    password = draft.passwordIsValid ? draft.password : promptForCompressionPassword()
                    guard password?.isEmpty == false else { return nil }
                } else {
                    password = nil
                }
                let format = options.format
                let containsDirectory = sources.contains { isDirectory(at: $0) }
                let outputExtension = format.isStream && (sources.count != 1 || containsDirectory)
                    ? "tar.\(format.fileExtension)" : format.fileExtension
                let basename = archiveBaseName(selection.name)
                outputURL = selection.directory
                    .appendingPathComponent("\(basename).\(outputExtension)")
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    self.error = .unavailable(AppLocalization.string(
                        "An archive with that name already exists.", locale: preferences.language.locale
                    ))
                    return nil
                }
                tags = selection.tags
                scopedDirectory = selection.directory
            } else {
                let profile = preferences.defaultCompressionProfile
                options = profile.options
                if options.requiresPassword {
                    let cached = preferences.sessionPassword(for: profile.id)
                    password = cached.isEmpty ? promptForCompressionPassword() : cached
                    guard let password, !password.isEmpty else { return nil }
                    preferences.setSessionPassword(password, for: profile.id)
                } else {
                    password = nil
                }
                outputURL = uniqueArchiveOutputURL(for: sources, in: directory, format: options.format)
            }
            let scopedAccess = scopedDirectory?.startAccessingSecurityScopedResource() ?? false
            defer { if scopedAccess { scopedDirectory?.stopAccessingSecurityScopedResource() } }
            let result = await createArchive(
                from: sources, outputURL: outputURL, options: options, password: password,
                preservingColumnSelection: false
            )
            if result != nil && !tags.isEmpty {
                var values = URLResourceValues()
                values.tagNames = tags
                do {
                    try outputURL.setResourceValues(values)
                } catch {
                    return AppLocalization.string(
                        "Archive created, but tags could not be applied.",
                        locale: preferences.language.locale
                    )
                }
            }
            return result
        case .extractHere, .extractNamed, .extractChoose:
            if action == .extractChoose {
                let panel = UITestLaunchIsolation.openPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.canCreateDirectories = true
                if case .recents = location {
                    panel.directoryURL = preferredOperationSource(
                        among: selected.compactMap(\.localURL)
                    )?.deletingLastPathComponent()
                }
                panel.prompt = AppLocalization.string("Extract", locale: preferences.language.locale)
                guard panel.runModal() == .OK, let destination = panel.url else { return nil }
                pendingExtractionDestination = .chosen(destination)
            } else {
                pendingExtractionDestination = action == .extractHere ? .here : .named
            }
            pendingArchiveExtractionItems = selected
            pendingArchiveExtractionIndex = 0
            return await processNextArchiveExtraction(password: nil)
        case .validate:
            pendingValidationItems = selected
            pendingValidationIndex = 0
            return await processNextArchiveValidation(password: nil)
        }
    }

    func performArchiveToolbarAction() async -> String? {
        guard !archiveOperationInProgress else { return nil }
        switch archiveToolbarAction {
        case .compress:
            let sources = selectedItems.compactMap(\.localURL)
            guard sources.count == selectedItems.count, !sources.isEmpty else { return nil }
            guard let destinationDirectory = archiveCreationDirectory(for: sources) else { return nil }
            let profile = preferences.defaultCompressionProfile
            let options = profile.options
            let password: String?
            if options.requiresPassword {
                let cached = preferences.sessionPassword(for: profile.id)
                password = cached.isEmpty ? promptForCompressionPassword() : cached
                guard let password, !password.isEmpty else { return nil }
                preferences.setSessionPassword(password, for: profile.id)
            } else {
                password = nil
            }
            let outputURL = uniqueArchiveOutputURL(
                for: sources,
                in: destinationDirectory,
                format: options.format
            )
            return await createArchive(
                from: sources, outputURL: outputURL, options: options, password: password,
                preservingColumnSelection: true
            )
        case .extractAll:
            let externalArchives = selectedItems
            guard !externalArchives.isEmpty,
                  externalArchives.allSatisfy({
                      $0.isArchive && $0.localURL != nil
                  }) else { return nil }
            pendingExtractionDestination = .named
            pendingArchiveExtractionItems = externalArchives
            pendingArchiveExtractionIndex = 0
            return await processNextArchiveExtraction(password: nil)
        case .extractSelected:
            let virtualItems = selectedItems
            guard !virtualItems.isEmpty,
                  virtualItems.allSatisfy({
                      if case .archive = $0.location { return true }
                      return false
                  }) else { return nil }
            do {
                let address: ArchiveAddress
                if case let .archive(currentAddress) = location {
                    address = currentAddress
                } else if let selectedAddress = selectedItems.compactMap({ item -> ArchiveAddress? in
                    guard case let .archive(itemAddress) = item.location else { return nil }
                    return itemAddress
                }).first {
                    address = selectedAddress
                } else {
                    return nil
                }
                // An inner archive's copy is temporary: extract beside the archive on disk.
                let rootURL = try await archives.outermostArchiveURL(for: address)
                let hierarchy = try await archives.archiveHierarchy(for: address)
                guard !hierarchy.isEmpty else { return nil }
                let destination = hierarchy.reduce(
                    rootURL.deletingLastPathComponent()
                ) { partialDestination, archiveName in
                    partialDestination.appendingPathComponent(
                        archiveExtractionDirectoryName(for: archiveName),
                        isDirectory: true
                    )
                }
                return await executeInternalExtraction(
                    items: virtualItems,
                    destination: destination,
                    password: nil
                )
            } catch {
                self.error = mapError(error)
                return nil
            }
        case .unavailableInsideArchive, .unavailableOutsideArchive:
            return nil
        }
    }

    var knownItems: [BrowserItem] {
        Array(knownItemsByID.values)
    }

    func sortedColumnItems(at location: BrowserLocation) -> [BrowserItem] {
        itemProjection.sortedColumnItems(
            at: location, sourceItems: columnItems[location] ?? [], sort: preferences.sort
        )
    }

    private var knownItemsByID: [BrowserItemID: BrowserItem] {
        itemProjection.knownItems(
            roots: items, expandedChildren: expandedChildren, columns: columnItems
        )
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var currentDirectoryURL: URL? { location.fileSystemURL }
    /// Drops on the unoccupied list/content area always target the directory
    /// being browsed, independently of the focused row's contextual target.
    var fileDropDestinationURL: URL? { currentDirectoryURL }
    var archiveDropAddress: ArchiveAddress? { archiveDropAddress(for: location) }

    /// An archive folder accepts drops only when its session can be written: an archive
    /// opened from inside a read-only archive (RAR, compressed tar, ISO…) is read-only.
    func archiveDropAddress(for location: BrowserLocation) -> ArchiveAddress? {
        guard let address = location.archiveAddress, isArchiveSessionWritable(address.sessionID) else { return nil }
        return address
    }

    func isArchiveSessionWritable(_ sessionID: UUID) -> Bool { !readOnlyArchiveSessions.contains(sessionID) }
    var fileOperationDestinationURL: URL? {
        if viewMode == .columns,
           let activeColumnLocation {
            return activeColumnLocation.fileSystemURL?.standardizedFileURL
        }
        guard let currentDirectoryURL else { return nil }
        guard viewMode == .list, let focusedItemID else {
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
    var canCreateFolderWithSelection: Bool {
        guard !isClosed, !fileOperationInProgress, !archiveOperationInProgress,
              !renameInProgress, renamingItemURL == nil, !isLoading,
              let directory = fileOperationDestinationURL,
              hasLocalSelection else { return false }
        let parentPath = directory.standardizedFileURL.resolvingSymlinksInPath().path
        return selectedItems.allSatisfy {
            $0.localURL?.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath().path == parentPath
        }
    }
    var hasLocalSelection: Bool {
        !selectedItems.isEmpty && selectedItems.allSatisfy { $0.localURL != nil }
    }
    /// File ▸ Open availability.
    var canOpenSelection: Bool { !selectedItems.isEmpty && !archiveOperationInProgress }
    /// File ▸ Open with availability; containers are opened by Zforge itself.
    var canOpenSelectionWithApplication: Bool {
        !selectedItems.isEmpty && !selectedItems.contains(where: \.isContainer)
    }
    /// File ▸ Always open with availability; the association is saved per local file.
    var canAlwaysOpenSelectionWithApplication: Bool {
        hasLocalSelection && !selectedItems.contains(where: \.isContainer)
    }

    /// File ▸ Open: captures the complete selection before running the shared
    /// contextual Open asynchronously.
    @discardableResult
    func openSelection() -> Task<Void, Never> {
        let selected = selectedItems
        return Task { _ = await performContextualAction(.open, items: selected) }
    }
    var tagEditingRequest: TagEditingRequest?
    var canEditTags: Bool { hasLocalSelection && !archiveOperationInProgress }

    func editTags(items: [BrowserItem]? = nil) {
        let targets = items ?? selectedItems
        guard !targets.isEmpty, targets.allSatisfy({ $0.localURL != nil }),
              !archiveOperationInProgress else { return }
        tagEditingRequest = TagEditingRequest(items: targets)
    }

    func applyTags(additions: [String: Int], removals: Set<String>, items targets: [BrowserItem]) async -> String? {
        var failures: [String] = []
        var updated: [BrowserItem] = []
        for item in targets {
            guard let url = item.localURL else { continue }
            do {
                try await Task.detached(priority: .userInitiated) {
                    try FinderTagWriter.apply(additions: additions, removals: removals, to: url)
                }.value
                updated.append(try await fileSystem.item(at: url))
            } catch {
                failures.append("\(item.name): \(error.localizedDescription)")
            }
        }
        FinderTagCatalog.shared.observe(updated)
        await reload()
        return failures.isEmpty ? nil : failures.joined(separator: "\n")
    }

    var canRenameSelection: Bool {
        selectedItems.count == 1 && canRename(selectedItems[0])
    }
    /// Local items can be renamed except volume roots: the App Sandbox denies Disk Arbitration's
    /// rename authorization for volumes the user doesn't own, so Zforge doesn't rename volumes
    /// (OR-25, removed 2026-10-30), and a mount point is never moved.
    func canRename(_ item: BrowserItem) -> Bool {
        guard let url = item.localURL else { return false }
        return (try? url.resourceValues(forKeys: [.isVolumeKey]))?.isVolume != true
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
        if fileSearch != nil, location == .recents, let results = pathComponents.first,
           selectedItems.count == 1, let url = selectedItems[0].localURL {
            // As in Finder, the path bar shows where the selected result is.
            return [results] + fileSystemPathComponents(to: url.deletingLastPathComponent())
        }
        guard let first = pathComponents.first,
              case let .fileSystem(url) = first.location else {
            return pathComponents
        }
        return Array(fileSystemPathComponents(to: url).dropLast()) + pathComponents
    }

    var archiveDragFixtureDirectory: URL? {
        ProcessInfo.processInfo.arguments.contains("--ui-archive-drag-fixtures") ? initialURL : nil
    }

    convenience init(initialURL: URL? = nil, automationAccessLease: AutomationAccessLease? = nil, archiveSearch: String? = nil,
                     finderRequest: FinderMenuRequest? = nil, archiveSession: ArchiveSessionHandoff? = nil) {
        if ProcessInfo.processInfo.arguments.contains("--ui-finder-fixtures") {
            // Real files in Zforge's own temporary folder, revealed in Finder so a UI
            // test can choose the Zforge submenu there; windows opened from Finder
            // run their request against the same files.
            self.init(preferences: FileBrowserPreferences.shared, fileSystem: FileSystemService(),
                recentItems: UIFixtureRecentItemsService(), grants: UIFixtureAccessGrantStore(),
                archives: ArchiveSessionClient(),
                initialURL: finderRequest == nil && archiveSession == nil
                    ? ZforgeTemporaryStorage.root().appendingPathComponent("FinderFixture-" + UUID().uuidString) : nil,
                initialFinderRequest: finderRequest, initialArchiveSession: archiveSession)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-icon-preview-fixtures") {
            self.init(preferences: FileBrowserPreferences.shared, fileSystem: FileSystemService(),
                recentItems: UIFixtureRecentItemsService(), grants: UIFixtureAccessGrantStore(),
                archives: ArchiveSessionClient(),
                initialURL: archiveSession == nil
                    ? ZforgeTemporaryStorage.root().appendingPathComponent("IconPreviewFixture-" + UUID().uuidString) : nil,
                initialArchiveSession: archiveSession)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-archive-drag-fixtures") {
            self.init(preferences: FileBrowserPreferences.shared, fileSystem: FileSystemService(),
                recentItems: UIFixtureRecentItemsService(), grants: UIFixtureAccessGrantStore(),
                archives: ArchiveSessionClient(),
                // A window showing an inner archive (D-73) gets its session, not a new fixture.
                initialURL: archiveSession == nil
                    ? ZforgeTemporaryStorage.root().appendingPathComponent("ArchiveDragFixture-" + UUID().uuidString) : nil,
                initialArchiveSession: archiveSession)
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-fixtures") {
            let columnLoadDelay: Duration = ProcessInfo.processInfo.arguments.contains("--ui-column-load-delay")
                ? .seconds(4) : .zero
            self.init(
                preferences: FileBrowserPreferences.shared,
                fileSystem: UIFixtureFileSystemService(itemsDelay: columnLoadDelay),
                recentItems: UIFixtureRecentItemsService(),
                taggedItems: UIFixtureTaggedItemsService(),
                grants: UIFixtureAccessGrantStore(),
                archives: UIFixtureArchiveEngine(itemsDelay: columnLoadDelay),
                initialURL: initialURL,
                initialArchiveSession: archiveSession,
                searcher: UIFixtureSearchService()
            )
            return
        }
        self.init(
            preferences: FileBrowserPreferences.shared,
            fileSystem: FileSystemService(),
            recentItems: SpotlightRecentItemsService(),
            grants: AccessGrantStore(),
            archives: ArchiveSessionClient(),
            initialURL: initialURL,
            automationAccessLease: automationAccessLease,
            initialArchiveSearch: archiveSearch,
            initialFinderRequest: finderRequest,
            initialArchiveSession: archiveSession
        )
    }

    init(
        preferences: FileBrowserPreferences,
        fileSystem: any FileSystemServing,
        fileOperations: any FileOperationServing = FileOperationService(),
        recentItems: (any RecentItemsServing)? = nil,
        taggedItems: (any TaggedItemsServing)? = nil,
        grants: any AccessGrantStoring,
        archives: any ArchiveServing,
        initialURL: URL? = nil,
        automationAccessLease: AutomationAccessLease? = nil,
        archiveSearch: (any ArchiveSearching)? = nil,
        initialArchiveSearch: String? = nil,
        initialFinderRequest: FinderMenuRequest? = nil,
        initialArchiveSession: ArchiveSessionHandoff? = nil,
        volumes: (any VolumeCataloging)? = nil,
        networkBrowser: (any NetworkServerBrowsing)? = nil,
        networkMounter: (any NetworkServerMounting)? = nil,
        searcher: (any BrowserSearching)? = nil,
        searchDebounce: (@Sendable () async throws -> Void)? = nil
    ) {
        self.preferences = preferences
        self.searcher = searcher ?? BrowserSearchService(archives: archives)
        self.searchDebounce = searchDebounce ?? { try await Task.sleep(for: FileBrowserState.searchDebounceInterval) }
        self.volumes = volumes ?? VolumeCatalogService()
        self.networkBrowser = networkBrowser ?? BonjourNetworkServerBrowser()
        self.networkMounter = networkMounter ?? WorkspaceNetworkServerMounter()
        self.viewMode = preferences.viewMode
        self.fileSystem = fileSystem
        self.fileOperations = fileOperations
        self.recentItems = recentItems ?? SpotlightRecentItemsService()
        self.taggedItems = taggedItems ?? SpotlightTaggedItemsService()
        self.grants = grants
        self.archives = archives
        self.initialURL = initialURL
        initialAutomationAccessLease = automationAccessLease
        self.archiveSearch = archiveSearch ?? AuthorizedArchiveSearch()
        self.initialArchiveSearch = initialArchiveSearch
        self.initialFinderRequest = initialFinderRequest
        self.initialArchiveSession = initialArchiveSession
        location = .recents
        pathComponents = [
            BrowserPathComponent(
                location: .recents,
                name: AppLocalization.string("Recents", locale: preferences.language.locale),
                isArchive: false
            )
        ]
        let center = NSWorkspace.shared.notificationCenter
        volumeObservers = [
            NSWorkspace.didMountNotification,
            NSWorkspace.didUnmountNotification,
            NSWorkspace.didRenameVolumeNotification
        ].map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in await self?.refreshComputerLevel() }
            }
        }
        if let source = archives.sessionChangeSource {
            sessionChangeObserver = NotificationCenter.default.addObserver(
                forName: NativeSevenZipArchiveEngine.sessionDidChange, object: source, queue: .main
            ) { [weak self] notification in
                guard let sessionID = notification.userInfo?["sessionID"] as? UUID,
                      let revision = notification.userInfo?["revision"] as? Int else { return }
                Task { @MainActor in self?.archiveSessionDidChange(sessionID, revision: revision) }
            }
        }
        ArchiveWindowRegistry.shared.register(self)
    }

    func start() async {
        let openingAccess = initialAutomationAccessLease
        defer {
            if passwordOperation == nil { initialAutomationAccessLease = nil }
            withExtendedLifetime(openingAccess) {}
        }
        await archives.cleanupStaleSessions()
        if ProcessInfo.processInfo.arguments.contains("--ui-icon-preview-fixtures"), let initialURL {
            do {
                try await IconPreviewUIFixture.create(at: initialURL, archives: archives)
            } catch { self.error = mapError(error); return }
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-archive-drag-fixtures"), let initialURL {
            do {
                let inside = initialURL.appendingPathComponent("Inside", isDirectory: true)
                let target = initialURL.appendingPathComponent("Target", isDirectory: true)
                let dropped = initialURL.appendingPathComponent("Dropped", isDirectory: true)
                for directory in [inside, target, dropped] {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
                try Data("survivor".utf8).write(to: inside.appendingPathComponent("Survivor.txt"))
                if ProcessInfo.processInfo.arguments.contains("--ui-archive-navigation-fixtures") {
                    let deep = inside.appendingPathComponent("Deep", isDirectory: true)
                    let leaf = deep.appendingPathComponent("Leaf", isDirectory: true)
                    try FileManager.default.createDirectory(at: leaf, withIntermediateDirectories: true)
                    try Data("deep payload".utf8).write(to: deep.appendingPathComponent("DeepPayload.txt"))
                    try Data("keep".utf8).write(to: leaf.appendingPathComponent("Keep.txt"))
                }
                try Data("local".utf8).write(to: initialURL.appendingPathComponent("Local.txt"))
                var sources = [inside, target]
                if ProcessInfo.processInfo.arguments.contains("--ui-inner-archive-fixtures") {
                    // An archive stored inside Sample.zip, opened in its own window (D-73).
                    let payload = initialURL.appendingPathComponent("InnerPayload.txt")
                    try Data("inner payload".utf8).write(to: payload)
                    let inner = initialURL.appendingPathComponent("Inner.zip")
                    try await archives.createArchive(from: [payload], outputURL: inner, format: .zip, progress: { _ in })
                    try FileManager.default.removeItem(at: payload)
                    sources.append(inner)
                }
                try await archives.createArchive(from: sources, outputURL: initialURL.appendingPathComponent("Sample.zip"),
                    format: .zip, progress: { _ in })
                for source in sources { try FileManager.default.removeItem(at: source) }
            } catch { self.error = mapError(error); return }
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-finder-fixtures"), initialFinderRequest == nil, let initialURL {
            do {
                let payload = initialURL.appendingPathComponent("Payload", isDirectory: true)
                try FileManager.default.createDirectory(at: payload, withIntermediateDirectories: true)
                try Data("payload".utf8).write(to: payload.appendingPathComponent("Payload.txt"))
                let archive = initialURL.appendingPathComponent("Sample.zip")
                try await archives.createArchive(from: [payload], outputURL: archive, format: .zip, progress: { _ in })
                try FileManager.default.removeItem(at: payload)
                try Data("note".utf8).write(to: initialURL.appendingPathComponent("Note.txt"))
                NSWorkspace.shared.activateFileViewerSelecting([archive])
            } catch { self.error = mapError(error); return }
        }
        if let handoff = initialArchiveSession {
            initialArchiveSession = nil
            if let result = handoff.take() {
                await archives.adoptSession(result.address.sessionID)
                recordArchiveSession(result)
                if let outermost = try? await archives.outermostArchiveURL(for: result.address) {
                    recordArchiveVolume(result.address.sessionID, url: outermost)
                }
                await navigate(to: .archive(result.address), named: result.displayName, isArchive: true, resetPath: true)
            }
            return
        }
        if let finderRequest = initialFinderRequest {
            initialFinderRequest = nil
            await performFinderRequest(finderRequest)
            return
        }
        if let initialArchiveSearch {
            await showArchiveSearch(initialArchiveSearch)
            return
        }
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
                FinderTagCatalog.shared.refresh(searchScopes: await grants.metadataSearchScopes())
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
            FinderTagCatalog.shared.refresh(searchScopes: await grants.metadataSearchScopes())
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
            case let .finderRequest(request):
                await performFinderRequest(request)
            case .openInNewTab:
                openTabHandler?(intendedURL)
            case nil:
                let name = intendedURL.lastPathComponent
                await navigate(to: .fileSystem(intendedURL), named: name, resetPath: true)
            }
        } catch {
            self.error = mapError(error)
        }
    }

    /// Runs an action chosen in Finder's Zforge submenu through the same path as the
    /// browser's context menu, after showing its items selected in their folder.
    /// Each folder holding a selected item needs browser access first.
    func performFinderRequest(_ request: FinderMenuRequest) async {
        let urls = request.urls
        var folders: [URL] = []
        for folder in urls.map({ $0.deletingLastPathComponent().standardizedFileURL }) where !folders.contains(folder) {
            folders.append(folder)
        }
        guard request.isWellFormed, let first = folders.first else { return }
        for folder in folders where !(await grants.hasGrant(for: folder)) {
            requestAuthorization(for: folder, purpose: .finderRequest(request))
            return
        }
        do {
            for folder in folders { _ = try await grants.activateGrant(for: folder) }
            FinderTagCatalog.shared.refresh(searchScopes: await grants.metadataSearchScopes())
            var items: [BrowserItem] = []
            for url in urls { items.append(try await fileSystem.item(at: url)) }
            await navigate(to: .fileSystem(first), named: FileManager.default.displayName(atPath: first.path), resetPath: true)
            selectLocalItems(at: urls)
            // The selection may have changed between Finder's menu and this window.
            guard contextualActions(for: items).contains(request.action) else {
                error = .unavailable(AppLocalization.string(
                    "The requested item or operation is no longer available.", locale: preferences.language.locale
                ))
                return
            }
            contextualFeedbackMessage = await performContextualAction(request.action, items: items)
        } catch {
            self.error = mapError(error)
        }
    }

    /// Activates the stored grant for a sidebar destination, first importing a pinned
    /// folder's bookmark when no grant exists. Returns whether access is granted.
    private func activateSidebarGrant(for url: URL) async throws -> Bool {
        if !(await grants.hasGrant(for: url)),
           let bookmarked = PinnedFolderStore.shared.bookmarkedURL(for: url) {
            let started = bookmarked.startAccessingSecurityScopedResource()
            defer { if started { bookmarked.stopAccessingSecurityScopedResource() } }
            if started { try await grants.storeGrant(for: bookmarked) }
        }
        guard await grants.hasGrant(for: url) else { return false }
        _ = try await grants.activateGrant(for: url)
        return true
    }

    func navigateToSidebar(_ url: URL, name: String) async {
        do {
            if try await activateSidebarGrant(for: url) {
                FinderTagCatalog.shared.refresh(searchScopes: await grants.metadataSearchScopes())
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

    func navigateToTag(_ tag: String) async {
        await navigate(to: .recents, named: tag, resetPath: true, sidebarTag: tag)
    }

    /// Lists authorized archives whose names contain `term`. A single result is
    /// selected so that it is ready to open and is the focused onscreen entity.
    func showArchiveSearch(_ term: String) async {
        guard let term = AuthorizedArchiveSearch.normalizedTerm(term) else { return }
        await navigate(
            to: .recents,
            named: AppLocalization.string("Search: “\(term)”", locale: preferences.language.locale),
            resetPath: true,
            archiveSearch: term,
            systemImage: "magnifyingglass"
        )
        guard archiveSearchTerm == term, items.count == 1, let result = items.first else { return }
        select(result)
    }

    // MARK: - Toolbar search

    static let searchDebounceInterval: Duration = .milliseconds(250)

    /// The scopes the search bar offers: Current Folder only when the search
    /// began in a folder or archive, never in Recents, tags or Computer.
    var availableSearchScopes: [BrowserSearchScope] {
        BrowserFileSearch.supportsCurrentFolder(searchOriginComponents.last?.location)
            ? [.thisMac, .currentFolder] : [.thisMac]
    }

    /// The name of the folder the Current Folder scope searches.
    var currentFolderSearchName: String? {
        guard BrowserFileSearch.supportsCurrentFolder(searchOriginComponents.last?.location) else { return nil }
        return searchOriginComponents.last?.name
    }

    var searchResultsAreLimited: Bool {
        fileSearch != nil && location == .recents && items.count >= BrowserSearchService.maximumResultCount
    }

    private var searchOriginComponents: [BrowserPathComponent] {
        fileSearch?.origin ?? currentPathComponents
    }

    /// In Columns the active column, not the deepest one, is the current folder.
    private var currentPathComponents: [BrowserPathComponent] {
        guard let index = pathComponents.lastIndex(where: { $0.location == location }) else { return pathComponents }
        return Array(pathComponents.prefix(index + 1))
    }

    /// Expands the toolbar field and focuses it: the search button, ⌘F and Find.
    func beginSearch() {
        if !isSearchPresented, fileSearch == nil {
            searchScope = BrowserFileSearch.supportsCurrentFolder(location) ? .currentFolder : .thisMac
        }
        isSearchPresented = true
        focusSearchField()
    }

    /// Moves the keyboard focus into the expanded toolbar field, for example after Clear Search.
    func focusSearchField() {
        searchFieldFocusRequest &+= 1
    }

    /// Typing searches after a short pause; each keystroke cancels the pending search.
    func updateSearchText(_ text: String) {
        guard text != searchText else { return }
        searchText = text
        scheduleSearchText(after: searchDebounce)
    }

    /// Return searches immediately.
    func submitSearch() {
        scheduleSearchText(after: nil)
    }

    /// Applies the field's text once `wait` ends; a newer keystroke cancels the wait. Once
    /// applying begins the task is no longer the pending debounce: ending the search cancels
    /// the pending debounce, and must not cancel the reload of the listing it returns to
    /// (a cancelled reload of Recents or a tag listed nothing).
    private func scheduleSearchText(after wait: (@Sendable () async throws -> Void)?) {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            if let wait {
                do { try await wait() } catch { return }
            }
            guard !Task.isCancelled, let self else { return }
            self.searchDebounceTask = nil
            await self.applySearchText()
        }
    }

    /// Shows the results for the field's text and scope. Refining the query or
    /// scope replaces the results in place; Back returns to where the search began.
    func applySearchText() async {
        guard let query = BrowserFileSearch.normalizedQuery(searchText) else {
            await endFileSearch(keepingField: true)
            return
        }
        if fileSearch == nil {
            searchOriginEntry = HistoryEntry(components: pathComponents, location: location,
                sidebarTag: selectedSidebarTag, archiveSearch: archiveSearchTerm)
        }
        let origin = fileSearch?.origin ?? currentPathComponents
        let scope = BrowserFileSearch.supportsCurrentFolder(origin.last?.location) ? searchScope : .thisMac
        let search = BrowserFileSearch(query: query, scope: scope, origin: origin)
        guard search != fileSearch || location != .recents else { return }
        await navigate(
            to: .recents,
            named: AppLocalization.string("Searching “\(query)”", locale: preferences.language.locale),
            resetPath: true,
            recordsHistory: fileSearch == nil,
            fileSearch: search,
            systemImage: "magnifyingglass"
        )
    }

    func setSearchScope(_ scope: BrowserSearchScope) async {
        guard scope != searchScope else { return }
        searchScope = scope
        guard fileSearch != nil else { return }
        await applySearchText()
    }

    /// Escape: clears the text, returns to where the search began and collapses the field.
    func cancelSearch() async {
        searchDebounceTask?.cancel()
        await endFileSearch(keepingField: false)
    }

    /// Clicking away from an empty field collapses it back to the search button.
    func dismissSearchFieldIfIdle() {
        guard isSearchPresented, BrowserFileSearch.normalizedQuery(searchText) == nil else { return }
        searchDebounceTask?.cancel()
        if fileSearch != nil {
            Task { await endFileSearch(keepingField: false) }
        } else {
            searchText = ""
            isSearchPresented = false
        }
    }

    private func endFileSearch(keepingField: Bool) async {
        guard let search = fileSearch else {
            if !keepingField {
                searchText = ""
                isSearchPresented = false
            }
            return
        }
        let origin = searchOriginEntry ?? HistoryEntry(components: search.origin,
            location: search.originLocation ?? .recents, sidebarTag: nil)
        searchOriginEntry = nil
        if let last = backStack.last, last.fileSearch == nil, last.components == origin.components {
            backStack.removeLast()
        } else {
            pushHistory()
        }
        cancelRenaming()
        keepsSearchFieldOnExit = keepingField
        pathComponents = origin.components
        location = origin.location
        selectedSidebarTag = origin.sidebarTag
        archiveSearchTerm = origin.archiveSearch
        fileSearch = nil
        selection.removeAll()
        selectionOrder.removeAll()
        selectionAnchor = nil
        focusedItemID = nil
        activeColumnLocation = origin.location
        await reload()
    }

    /// Back and Forward show a search with its text in the expanded field.
    private func restoreFileSearch(_ search: BrowserFileSearch?) {
        guard let search else {
            fileSearch = nil
            return
        }
        fileSearch = search
        searchText = search.query
        searchScope = search.scope
        searchOriginEntry = nil
        isSearchPresented = true
    }

    /// Streams results into the list as they arrive. A newer reload or the
    /// window closing cancels the query, and its late batches are discarded.
    private func streamFileSearch(_ search: BrowserFileSearch, generation: UInt64) async throws -> [BrowserItem] {
        let target: BrowserSearchTarget
        switch (search.scope, search.originLocation) {
        case let (.currentFolder, .fileSystem(url)?): target = .folder(url)
        case let (.currentFolder, .archive(address)?): target = .archive(address)
        default: target = .thisMac(scopes: await grants.metadataSearchScopes())
        }
        guard generation == reloadGeneration else { return [] }
        let stream = searcher.results(for: BrowserSearchRequest(
            query: search.query, target: target, showsHiddenFiles: preferences.showHiddenFiles))
        items = []
        columnItems[.recents] = []
        let task = Task { [weak self] () throws -> [BrowserItem] in
            var results: [BrowserItem] = []
            var seen: Set<BrowserItemID> = []
            for try await batch in stream {
                guard let self, generation == self.reloadGeneration else { break }
                var found: [BrowserItem] = []
                var urls: [URL] = []
                for match in batch {
                    switch match {
                    case let .item(item): found.append(item)
                    case let .file(url): urls.append(url)
                    }
                }
                if !urls.isEmpty { found += await self.loadRecentItems(at: urls, includeDirectories: true) }
                guard generation == self.reloadGeneration, !Task.isCancelled else { break }
                found = found.filter {
                    (self.preferences.showHiddenFiles || !$0.isHidden) && seen.insert($0.id).inserted
                }
                guard !found.isEmpty else { continue }
                results += found
                self.items = results
                self.columnItems[.recents] = self.preferences.sort.sorted(results)
            }
            return results
        }
        searchStreamTask = task
        return try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
    }

    /// The path after opening a result, so the path bar and Enclosing Folder
    /// lead to where it actually is rather than back to the results.
    private func searchResultPath(
        to destination: BrowserPathComponent,
        from search: BrowserFileSearch,
        searchResultURL: URL?
    ) -> [BrowserPathComponent] {
        guard case let .archive(address) = destination.location else { return [destination] }
        if let searchResultURL {
            let parent = searchResultURL.deletingLastPathComponent().standardizedFileURL
            return [BrowserPathComponent(location: .fileSystem(parent),
                name: FileManager.default.displayName(atPath: parent.path), isArchive: false), destination]
        }
        guard case let .archive(origin)? = search.originLocation,
              origin.sessionID == address.sessionID, origin.archiveID == address.archiveID,
              origin.internalPath.isEmpty || address.internalPath.hasPrefix(origin.internalPath + "/") else {
            return search.origin + [destination]
        }
        let relative = origin.internalPath.isEmpty
            ? address.internalPath : String(address.internalPath.dropFirst(origin.internalPath.count + 1))
        var components = search.origin
        var current = origin
        for name in relative.split(separator: "/").dropLast().map(String.init) {
            current = current.appending(name)
            components.append(BrowserPathComponent(location: .archive(current), name: name, isArchive: false))
        }
        return components + [destination]
    }

    /// A volume renamed by Finder or Disk Utility gets a new mount point; a window showing it
    /// follows to the same folder. Zforge itself never renames volumes (OR-25).
    func followRenamedVolume(from oldURL: URL, to newURL: URL) async {
        let oldPath = oldURL.standardizedFileURL.path
        let newPath = newURL.standardizedFileURL.path
        guard oldPath != newPath, oldPath != "/",
              let current = currentDirectoryURL?.standardizedFileURL.path,
              current == oldPath || current.hasPrefix(oldPath + "/") else { return }
        let target = URL(fileURLWithPath: newPath + current.dropFirst(oldPath.count), isDirectory: true)
        await navigateToSidebar(target, name: FileManager.default.displayName(atPath: target.path))
    }

    func refreshTagResults() {
        guard selectedSidebarTag != nil else { return }
        tagRefreshTask?.cancel()
        tagRefreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self, !Task.isCancelled, selectedSidebarTag != nil else { return }
            await reload()
        }
    }

    /// Finder's computer level (Go ▸ Computer and the sidebar computer item): the
    /// mounted volumes and Network, titled with the Mac's current name.
    func navigateToComputer() async {
        await navigate(to: .computer, named: ComputerIdentity.name(locale: preferences.language.locale), resetPath: true)
    }

    /// Mounting, unmounting or renaming a volume refreshes a visible computer level.
    func refreshComputerLevel() async {
        guard !isClosed, pathComponents.contains(where: { $0.location == .computer }) else { return }
        if location == .computer {
            await reload(preservingColumnSelection: true)
        } else {
            await reloadColumnItems(at: .computer)
        }
    }

    /// A volume opened or expanded from the computer level needs the same grant as its
    /// sidebar row; folders inside it inherit that grant. Returns `false` after asking
    /// for access, which then opens the volume.
    private func activateComputerLevelAccess(for item: BrowserItem) async throws -> Bool {
        guard case let .fileSystem(url) = item.location,
              columnItems[.computer]?.contains(where: { $0.id == item.id }) == true else { return true }
        guard await grants.hasGrant(for: url) else {
            requestAuthorization(for: url, purpose: .navigate(name: item.name))
            return false
        }
        _ = try await grants.activateGrant(for: url)
        return true
    }

    private func computerLevelItems() async -> [BrowserItem] {
        ComputerLevelCatalog.items(
            volumes: await volumes.volumes(),
            locale: preferences.language.locale
        )
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

    /// Go ▸ Network: the Network level below the computer level, as in Finder, so the path
    /// bar reads “Computer name › Network” and Enclosing Folder returns to the computer.
    func navigateToNetwork() async {
        let locale = preferences.language.locale
        let computer = BrowserPathComponent(location: .computer, name: ComputerIdentity.name(locale: locale), isArchive: false)
        await navigate(to: .network, named: AppLocalization.string("Network", locale: locale), resetPath: true,
                       parentComponents: [computer])
        guard location == .network else { return }
        columnSelections[.computer] = NetworkLevelCatalog.networkItemID
    }

    /// Starts discovery when the path shows the Network level (also as a column) and stops it,
    /// with any pending server connection, when the level leaves the path or the window closes.
    private func synchronizeNetworkDiscovery() {
        let showsNetwork = !isClosed && pathComponents.contains { $0.location == .network }
        if showsNetwork {
            guard networkDiscoveryTask == nil else { return }
            networkDiscoveryTask = Task { [weak self, networkBrowser] in
                for await update in networkBrowser.updates() {
                    guard let self, !Task.isCancelled else { return }
                    self.applyNetworkDiscovery(update)
                }
            }
        } else {
            networkDiscoveryTask?.cancel()
            networkDiscoveryTask = nil
            networkConnectionTask?.cancel()
            networkConnectionTask = nil
            networkServers = []
            networkDiscoveryDenied = false
        }
    }

    /// Publishes a discovery update live, keeping the selection of servers that remain. It
    /// replaces the items in place instead of reloading, so a shown error is not cleared.
    private func applyNetworkDiscovery(_ update: NetworkDiscoveryUpdate) {
        switch update {
        case let .servers(servers):
            networkServers = servers
            networkDiscoveryDenied = false
        case .denied:
            networkServers = []
            networkDiscoveryDenied = true
        }
        let loaded = NetworkLevelCatalog.items(servers: networkServers)
        columnItems[.network] = preferences.sort.sorted(loaded)
        guard location == .network else { return }
        items = loaded
        let remaining = Set(loaded.map(\.id))
        selection.formIntersection(remaining)
        selectionOrder.removeAll { !selection.contains($0) }
        if let selectionAnchor, !remaining.contains(selectionAnchor) { self.selectionAnchor = nil }
        if let focusedItemID, !remaining.contains(focusedItemID) { self.focusedItemID = nil }
        updatePreview()
    }

    /// Opening a server of the Network level connects through the system's flow (the same as
    /// Shared ▸ Remote) and, once its share is mounted, opens the share. A newer request, leaving
    /// the Network level or closing the window cancels the wait without navigating.
    private func openNetworkServer(_ url: URL) async {
        networkConnectionTask?.cancel()
        let task = Task { [weak self, networkMounter] in
            do {
                let share = try await networkMounter.mount(url)
                guard let self, !Task.isCancelled, !self.isClosed else { return }
                self.networkConnectionTask = nil
                await self.navigateToSidebar(share, name: FileManager.default.displayName(atPath: share.path))
            } catch {
                guard let self, !Task.isCancelled, !(error is CancellationError) else { return }
                self.networkConnectionTask = nil
                self.error = .unavailable(
                    AppLocalization.string("The server could not be opened.", locale: self.preferences.language.locale)
                )
            }
        }
        networkConnectionTask = task
        await task.value
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

    func configureOpenTabAction(_ action: @escaping (URL) -> Void) {
        openTabHandler = action
    }

    /// Opens a window for a request built here, such as an inner archive's window.
    func configureOpenArchiveWindowAction(_ action: @escaping (BrowserWindowRequest) -> Void) {
        openArchiveWindowHandler = action
    }

    /// Closes this browser's window (used to close inner archive windows first).
    func configureWindowCloseAction(_ action: @escaping () -> Void) {
        windowCloseHandler = action
    }

    var isClosedForRegistry: Bool { isClosed }

    func closeWindow() {
        if let windowCloseHandler { windowCloseHandler() } else { close() }
    }

    /// Sessions this window holds; a window that only knows them treats them as held.
    var heldArchiveSessionIDs: Set<UUID> {
        if let client = archives as? ArchiveSessionClient { return Set(client.heldSessions.keys) }
        return Set(shownSessionRevisions.keys)
    }

    /// Materializes an archive stored inside the current archive and shows it, as a root
    /// archive, in a new window that shares its session (D-73).
    func openInnerArchiveWindow(_ item: BrowserItem, password: String? = nil) async {
        guard item.opensAsInnerArchive else { return }
        if let size = item.size, size > 1_073_741_824, !confirmedLargeItems.contains(item.id) {
            pendingLargeOperation = .openInnerArchive(item)
            return
        }
        beginArchiveOpening(named: item.name)
        defer {
            archiveOperationInProgress = false
            archiveProgress = nil
        }
        do {
            let result = try await archives.openInnerArchive(item: item, password: password)
            let sessionID = result.address.sessionID
            guard !Task.isCancelled, !isClosed else {
                await archives.closeSession(sessionID)
                return
            }
            passwordOperation = nil
            passwordError = nil
            // Only the window showing the inner archive follows its changes; this one keeps
            // the relationship so that closing it closes the inner window first.
            if let parent = result.parentSessionID { archiveSessionParents[sessionID] = parent }
            // The new window takes this window's reference; unclaimed, it is released.
            await archives.relinquishSession(sessionID)
            let archives = self.archives
            let handoff = ArchiveSessionHandoff(result: result) {
                await archives.adoptSession(sessionID)
                await archives.closeSession(sessionID)
            }
            openArchiveWindowHandler?(BrowserWindowRequest(archiveSession: handoff))
        } catch ArchiveEngineError.passwordRequired {
            guard !Task.isCancelled else { return }
            passwordOperation = .openInnerArchive(item)
        } catch ArchiveEngineError.invalidPassword {
            guard !Task.isCancelled else { return }
            passwordError = AppLocalization.string("Incorrect password. Try again.", locale: preferences.language.locale)
            passwordOperation = .openInnerArchive(item)
        } catch ArchiveEngineError.cancelled {
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            self.error = mapError(error)
        }
    }

    /// Starts an opening whose progress appears only if it takes a while (D-73).
    private func beginArchiveOpening(named name: String) {
        beginDelayedArchiveOperation(AppLocalization.string("Opening “\(name)”…", locale: preferences.language.locale))
    }

    /// An archive operation whose progress and Cancel appear only if it takes a while.
    private func beginDelayedArchiveOperation(_ description: String) {
        archiveOperationDescription = description
        archiveProgress = nil
        archiveOperationIsVisible = false
        archiveOperationInProgress = true
        let delay = archiveOpeningRevealDelay
        archiveOperationRevealTask?.cancel()
        archiveOperationRevealTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, self.archiveOperationInProgress else { return }
            self.archiveOperationIsVisible = true
        }
    }

    /// The volume kind of the archive holding an item inside an archive.
    func archiveVolumeKind(of item: BrowserItem) -> ArchiveVolumeKind {
        guard case let .archive(address) = item.location else { return .internalDisk }
        return archiveVolumeKinds[address.sessionID] ?? .internalDisk
    }

    private func recordArchiveVolume(_ sessionID: UUID, url: URL) {
        archiveVolumeKinds[sessionID] = volumeClassifier(url)
    }

    private func recordArchiveSession(_ result: ArchiveOpenResult) {
        let sessionID = result.address.sessionID
        if result.isReadOnly { readOnlyArchiveSessions.insert(sessionID) } else { readOnlyArchiveSessions.remove(sessionID) }
        if let parent = result.parentSessionID { archiveSessionParents[sessionID] = parent }
        shownSessionRevisions[sessionID] = max(shownSessionRevisions[sessionID] ?? 0, result.revision)
    }

    // MARK: Shared sessions

    /// Another window (or this one) changed a shared session: show the new listing,
    /// keeping this window's location and selection while they still exist.
    private func archiveSessionDidChange(_ sessionID: UUID, revision: Int) {
        guard !isClosed, let shown = shownSessionRevisions[sessionID], shown < revision else { return }
        pendingSessionChanges[sessionID] = max(pendingSessionChanges[sessionID] ?? 0, revision)
        scheduleArchiveSessionChanges()
    }

    private func scheduleArchiveSessionChanges() {
        guard !pendingSessionChanges.isEmpty, !archiveOperationInProgress, !isClosed else { return }
        let previous = sessionChangeTask
        sessionChangeTask = Task { [weak self] in
            await previous?.value
            await self?.applyPendingSessionChanges()
        }
    }

    private func applyPendingSessionChanges() async {
        let changes = pendingSessionChanges
        pendingSessionChanges.removeAll()
        for (sessionID, revision) in changes {
            guard !isClosed, let shown = shownSessionRevisions[sessionID], shown < revision else { continue }
            shownSessionRevisions[sessionID] = revision
            await applyArchiveSessionChange(sessionID)
        }
    }

    private func archiveFolderExists(_ address: ArchiveAddress) async -> Bool {
        let path = address.internalPath
        guard !path.isEmpty else { return true }
        let parent = (path as NSString).deletingLastPathComponent
        let name = (path as NSString).lastPathComponent
        let rows = (try? await archives.items(at: ArchiveAddress(
            sessionID: address.sessionID, archiveID: address.archiveID, internalPath: parent))) ?? []
        return rows.contains { $0.isDirectory && $0.name == name }
    }

    private func applyArchiveSessionChange(_ sessionID: UUID) async {
        // A folder that no longer exists gives way to its nearest surviving ancestor.
        if case let .archive(address) = location, address.sessionID == sessionID {
            var path = address.internalPath
            while !path.isEmpty {
                let candidate = ArchiveAddress(sessionID: sessionID, archiveID: address.archiveID, internalPath: path)
                if await archiveFolderExists(candidate) { break }
                path = (path as NSString).deletingLastPathComponent
            }
            if path != address.internalPath {
                let target = BrowserLocation.archive(
                    ArchiveAddress(sessionID: sessionID, archiveID: address.archiveID, internalPath: path))
                if let index = pathComponents.firstIndex(where: { $0.location == target }) {
                    pathComponents = Array(pathComponents.prefix(through: index))
                }
                location = target
                activeColumnLocation = target
            }
        }
        // Columns and disclosed folders of this session show its new contents.
        for key in columnItems.keys {
            guard case let .archive(address) = key, address.sessionID == sessionID else { continue }
            if await archiveFolderExists(address), let rows = try? await archives.items(at: address) {
                columnItems[key] = preferences.sort.sorted(rows)
            } else {
                columnItems.removeValue(forKey: key)
                columnSelections.removeValue(forKey: key)
            }
        }
        for (itemID, result) in inlineArchiveResults where result.address.sessionID == sessionID {
            if let rows = try? await archives.items(at: result.address) {
                let previous = expandedChildren[itemID] ?? []
                expandedChildren[itemID] = preferences.sort.sorted(rows)
                purgeRemovedHierarchies(previous: previous, current: rows)
            }
        }
        for item in knownItems where item.isDirectory && expandedItems.contains(item.id) {
            guard case let .archive(address) = item.location, address.sessionID == sessionID else { continue }
            if await archiveFolderExists(address), let rows = try? await archives.items(at: address) {
                let previous = expandedChildren[item.id] ?? []
                expandedChildren[item.id] = preferences.sort.sorted(rows)
                purgeRemovedHierarchies(previous: previous, current: rows)
            }
        }
        await reload(preservingColumnSelection: true)
    }

    /// Sidebar "Open in New Tab": opens a browser tab at the destination in this
    /// window, asking for access first when no grant covers it.
    func openSidebarDestinationInNewTab(_ url: URL) async {
        do {
            if try await activateSidebarGrant(for: url) {
                openTabHandler?(url)
            } else {
                requestAuthorization(for: url, purpose: .openInNewTab)
            }
        } catch {
            self.error = mapError(error)
        }
    }

    /// Sidebar "Show in Enclosing Folder": shows the parent folder in this browser
    /// with the destination selected, like Finder does in its own window.
    func showInEnclosingFolder(_ url: URL) async {
        let target = url.standardizedFileURL
        let parent = target.deletingLastPathComponent()
        guard target.path != "/" else { return }
        do {
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

    /// Sidebar "Get Info": the same info window as for browser items.
    func showGetInfo(forSidebarDestination url: URL) async {
        do {
            _ = try await activateSidebarGrant(for: url)
            let item = try await fileSystem.item(at: url)
            BrowserInfoWindowCoordinator.shared.present(
                items: [item],
                locale: preferences.language.locale,
                fileSystem: fileSystem,
                archives: archives
            )
        } catch {
            self.error = mapError(error)
        }
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
            locale: preferences.language.locale,
            fileSystem: fileSystem,
            archives: archives
        )
    }

    func recursiveSize(of item: BrowserItem) async throws -> Int64 {
        if let url = item.localURL {
            return try await fileSystem.recursiveSize(at: url)
        }
        return try await archives.recursiveSize(of: item)
    }

    func open(
        _ item: BrowserItem,
        recordsHistory: Bool = true,
        clearsSelection: Bool = true
    ) async {
        if case let .networkServer(url) = item.location {
            await openNetworkServer(url)
        } else if item.isContainer {
            await openContainer(item, recordsHistory: recordsHistory, clearsSelection: clearsSelection)
        } else if item.canNavigateAsArchive {
            await openArchive(item, recordsHistory: recordsHistory, clearsSelection: clearsSelection)
        } else if item.opensAsInnerArchive {
            await openInnerArchiveWindow(item)
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
        case .recents, .computer, .networkServer:
            return
        case .network:
            await navigate(to: .network, named: item.name, recordsHistory: recordsHistory, clearsSelection: clearsSelection)
        case let .fileSystem(url):
            do {
                guard try await activateComputerLevelAccess(for: item) else { return }
                let resolved = try await fileSystem.resolveNavigationURL(url)
                guard !Task.isCancelled else { return }
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
                guard !Task.isCancelled else { return }
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
        if item.opensAsInnerArchive {
            await openInnerArchiveWindow(item, password: password)
            return
        }
        let openingAccess = initialAutomationAccessLease
        defer {
            if passwordOperation == nil { initialAutomationAccessLease = nil }
            withExtendedLifetime(openingAccess) {}
        }
        beginArchiveOpening(named: item.name)
        defer {
            archiveOperationInProgress = false
            archiveProgress = nil
        }
        do {
            let result: ArchiveOpenResult
            switch item.location {
            case .recents, .computer, .network, .networkServer:
                return
            case let .fileSystem(url):
                if let inlineResult = inlineArchiveResults[item.id] {
                    result = inlineResult
                } else {
                    result = try await archives.openArchive(at: url, password: password)
                }
                recordArchiveVolume(result.address.sessionID, url: url)
            case .archive:
                return
            }
            recordArchiveSession(result)
            guard !Task.isCancelled else {
                if case .fileSystem = item.location {
                    await archives.closeSession(result.address.sessionID)
                }
                return
            }
            if case .fileSystem = item.location, let openingAccess { archiveSessionAccessLease = openingAccess }
            passwordOperation = nil
            passwordError = nil
            await navigate(
                to: .archive(result.address),
                named: result.displayName,
                isArchive: true,
                recordsHistory: recordsHistory,
                clearsSelection: clearsSelection,
                searchResultURL: item.localURL
            )
        } catch ArchiveEngineError.passwordRequired {
            guard !Task.isCancelled else { return }
            passwordOperation = item.localURL.map(PasswordOperation.openFile) ?? .openInnerArchive(item)
        } catch ArchiveEngineError.invalidPassword {
            guard !Task.isCancelled else { return }
            passwordError = AppLocalization.string(
                "Incorrect password. Try again.",
                locale: preferences.language.locale
            )
            passwordOperation = item.localURL.map(PasswordOperation.openFile) ?? .openInnerArchive(item)
        } catch ArchiveEngineError.cancelled {
            // Cancelled from the progress overlay: nothing opened, nothing to report.
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            self.error = mapError(error)
        }
    }

    func submitPassword(_ password: String) async {
        guard let operation = passwordOperation else { return }
        let openingAccess = initialAutomationAccessLease
        defer { withExtendedLifetime(openingAccess) {} }
        switch operation {
        case let .openFile(url):
            do {
                let item = try await fileSystem.item(at: url)
                guard !isClosed, !Task.isCancelled, passwordOperation != nil else { return }
                await openArchive(item, password: password)
            } catch {
                self.error = mapError(error)
            }
        case let .openInnerArchive(item):
            await openInnerArchiveWindow(item, password: password)
        case let .expandInline(item):
            await toggleExpansion(item, password: password)
        case .extractArchive:
            passwordOperation = nil
            contextualFeedbackMessage = await processNextArchiveExtraction(password: password)
        case .validateArchive:
            passwordOperation = nil
            contextualFeedbackMessage = await processNextArchiveValidation(password: password)
        case let .extractItems(items, destinationURL):
            passwordOperation = nil
            _ = await executeInternalExtraction(
                items: items,
                destination: destinationURL,
                password: password
            )
        }
    }

    func confirmLargeOperation() async {
        guard let operation = pendingLargeOperation else { return }
        let item = operation.item
        confirmedLargeItems.insert(item.id)
        pendingLargeOperation = nil
        switch operation {
        case .openInnerArchive: await openInnerArchiveWindow(item)
        case .openExternally: await openExternally(item)
        }
    }

    func cancelArchiveOperation() {
        Task { await archives.cancelAllOperations() }
    }

    func requestArchiveAddition(
        _ sourceURLs: [URL],
        to archiveURL: URL,
        internalPath: String = ""
    ) {
        guard !sourceURLs.isEmpty else { return }
        guard ArchiveFormatRegistry.supportsUpdating(archiveURL.lastPathComponent) else {
            error = .unavailable(AppLocalization.string(
                "Only ZIP and 7z archives can be updated.", locale: preferences.language.locale
            ))
            return
        }
        pendingArchiveAddition = ArchiveAdditionRequest(
            sourceURLs: sourceURLs, archiveURL: archiveURL,
            internalPath: internalPath
        )
    }

    func requestArchiveAddition(_ sourceURLs: [URL], to address: ArchiveAddress) async {
        guard isArchiveSessionWritable(address.sessionID) else {
            error = .unavailable(AppLocalization.string(
                "This archive is read-only because the archive that contains it cannot be updated.",
                locale: preferences.language.locale
            ))
            return
        }
        do {
            let url = try await archives.archiveRootURL(for: address)
            requestArchiveAddition(
                sourceURLs, to: url, internalPath: address.internalPath
            )
        } catch {
            self.error = mapError(error)
        }
    }

    func confirmArchiveAddition(_ request: ArchiveAdditionRequest) async {
        // Dialog dismissal can clear the presentation binding before this task starts.
        // Use the request captured by the confirmation action instead of that binding.
        guard !archiveOperationInProgress else { return }
        pendingArchiveAddition = nil
        let result = await runArchiveOperation(
            description: AppLocalization.string("Adding to archive…", locale: preferences.language.locale)
        ) {
            let scopedURLs = request.sourceURLs + [request.archiveURL]
            let activeScopes = scopedURLs.filter { $0.startAccessingSecurityScopedResource() }
            defer { activeScopes.forEach { $0.stopAccessingSecurityScopedResource() } }
            var password: String?
            while true {
                do {
                    try await self.archives.addItems(
                        from: request.sourceURLs, to: request.archiveURL,
                        internalPath: request.internalPath, password: password,
                        progress: self.archiveProgressHandler()
                    )
                    break
                } catch ArchiveEngineError.passwordRequired {
                    guard let supplied = self.promptForArchiveUpdatePassword() else {
                        throw ArchiveEngineError.cancelled
                    }
                    password = supplied
                } catch ArchiveEngineError.invalidPassword {
                    guard let supplied = self.promptForArchiveUpdatePassword() else {
                        throw ArchiveEngineError.cancelled
                    }
                    password = supplied
                }
            }
            try await self.refreshUpdatedArchive(request, password: password, navigation: .preserveCurrentDirectory)
            return AppLocalization.string(
                "Items added to archive successfully.", locale: self.preferences.language.locale
            )
        }
        contextualFeedbackMessage = result
    }

    private enum ArchiveRefreshNavigation { case preserveCurrentDirectory, revealDestination }

    private func refreshUpdatedArchive(_ request: ArchiveAdditionRequest, password: String?, navigation: ArchiveRefreshNavigation) async throws {
    let currentArchiveURL: URL?
    if case let .archive(address) = self.location {
        currentArchiveURL = try? await self.archives.archiveRootURL(for: address)
    } else {
        currentArchiveURL = nil
    }
    // Session IDs change after rewriting. Keep disclosure state by internal
    // path, and invalidate only the archive that was actually updated.
    let currentExpandedPaths: Set<String>
    if case let .archive(address) = self.location {
        currentExpandedPaths = self.expandedArchivePaths(in: address.sessionID)
    } else {
        currentExpandedPaths = []
    }
    let matchingInlineResults = self.inlineArchiveResults.filter { itemID, _ in
        self.knownItemsByID[itemID]?.localURL?.standardizedFileURL
            == request.archiveURL.standardizedFileURL
    }
    var inlineExpandedPaths: [BrowserItemID: Set<String>] = [:]
    for (itemID, result) in matchingInlineResults {
        if self.expandedItems.contains(itemID) {
            inlineExpandedPaths[itemID] = self.expandedArchivePaths(in: result.address.sessionID)
        }
        let hierarchyIDs = self.cachedHierarchyIDs(rootedAt: itemID)
        let sessions = self.inlineArchiveResults.filter { hierarchyIDs.contains($0.key) }
        self.purgeCachedHierarchies(rootedAt: [itemID])
        for session in sessions.values {
            if case let .archive(currentAddress) = self.location,
               currentAddress.sessionID == session.address.sessionID { continue }
            await self.archives.closeSession(session.address.sessionID)
        }
    }
    let refreshedSessionID: UUID?
    if case let .archive(address) = self.location,
       currentArchiveURL?.standardizedFileURL == request.archiveURL.standardizedFileURL {
        refreshedSessionID = address.sessionID
    } else {
        refreshedSessionID = nil
    }
    if let sessionID = refreshedSessionID,
       case let .archive(currentAddress) = self.location,
       currentAddress.sessionID == sessionID {
        // The shared session is updated in place: every window keeps valid addresses.
        let opened = try await self.archives.reopenSession(sessionID, at: request.archiveURL, password: password)
        self.recordArchiveSession(opened)
        let requestedPath: String
        if navigation == .preserveCurrentDirectory { requestedPath = currentAddress.internalPath }
        else if viewMode == .list {
            let original = currentAddress.internalPath.split(separator: "/")
            let destination = request.internalPath.split(separator: "/")
            requestedPath = zip(original, destination).prefix { $0 == $1 }.map { String($0.0) }.joined(separator: "/")
        } else { requestedPath = request.internalPath }
        try await self.restoreUpdatedArchiveNavigation(
            from: currentAddress, to: opened, requestedPath: requestedPath,
            revealsDestination: navigation == .revealDestination
        )
        self.clearSelection()
        self.expandedItems.removeAll()
        self.expandedChildren.removeAll()
        await self.reload()
    } else {
        await self.reload()
    }
    if self.viewMode == .list {
        if refreshedSessionID != nil {
            await self.restoreArchiveExpansion(
                in: self.items, paths: currentExpandedPaths,
                destinationPath: request.internalPath, password: password
            )
        }
        for (itemID, paths) in inlineExpandedPaths {
            guard let archiveItem = self.knownItemsByID[itemID] else { continue }
            await self.toggleExpansionImpl(archiveItem, password: password)
            await self.restoreArchiveExpansion(
                in: self.expandedChildren[itemID] ?? [], paths: paths,
                destinationPath: request.internalPath, password: password
            )
        }
        if refreshedSessionID != nil || !inlineExpandedPaths.isEmpty {
            let addedPaths = Set(request.sourceURLs.map {
                [request.internalPath, $0.lastPathComponent].filter { !$0.isEmpty }.joined(separator: "/")
            })
            var sessionIDs = Set(inlineExpandedPaths.keys.compactMap {
                self.inlineArchiveResults[$0]?.address.sessionID
            })
            if refreshedSessionID != nil, case let .archive(address) = self.location {
                sessionIDs.insert(address.sessionID)
            }
            let addedItems = self.flattenedItems().filter {
                guard case let .archive(address) = $0.location else { return false }
                return sessionIDs.contains(address.sessionID) && addedPaths.contains(address.internalPath)
            }
            for (index, item) in addedItems.enumerated() {
                self.select(item, modifiers: index == 0 ? [] : .command, orderedItems: self.flattenedItems())
            }
        }
    }
    if viewMode != .list, refreshedSessionID != nil {
        let names = Set(request.sourceURLs.map(\.lastPathComponent))
        for (index, item) in items.filter({ names.contains($0.name) }).enumerated() {
            select(item, modifiers: index == 0 ? [] : .command)
        }
    }
    }

    private func restoreUpdatedArchiveNavigation(
        from oldAddress: ArchiveAddress, to opened: ArchiveOpenResult,
        requestedPath: String, revealsDestination: Bool
    ) async throws {
        // The archive keeps its logical paths but receives new session/item IDs.
        // Rebase surviving history, and enumerate each ancestor for Columns.
        let root = BrowserPathComponent(location: .archive(opened.address), name: opened.displayName, isArchive: true)
        var paths: [String: [BrowserPathComponent]] = ["": [root]]
        var refreshedColumns: [BrowserLocation: [BrowserItem]] = [:]
        func components(for path: String) async throws -> [BrowserPathComponent]? {
            if let cached = paths[path] { return cached }
            var cursor = opened.address
            var result = [root]
            for name in path.split(separator: "/").map(String.init) {
                let key = BrowserLocation.archive(cursor)
                let rows: [BrowserItem]
                if let cached = refreshedColumns[key] { rows = cached }
                else {
                    rows = try await archives.items(at: cursor)
                    refreshedColumns[key] = preferences.sort.sorted(rows)
                }
                guard let directory = rows.first(where: { $0.isDirectory && $0.name == name }),
                      case let .archive(address) = directory.location else { return nil }
                cursor = address
                result.append(BrowserPathComponent(location: .archive(cursor), name: name, isArchive: false))
                paths[cursor.internalPath] = result
            }
            return result
        }
        func rebased(_ entry: HistoryEntry) async throws -> HistoryEntry? {
            guard let index = entry.components.firstIndex(where: {
                if case let .archive(address) = $0.location { return address.sessionID == oldAddress.sessionID }
                return false
            }) else { return entry }
            guard case let .archive(address) = entry.location,
                  address.sessionID == oldAddress.sessionID,
                  address.archiveID == oldAddress.archiveID,
                  let branch = try await components(for: address.internalPath),
                  let destination = branch.last else { return nil }
            return HistoryEntry(components: Array(entry.components.prefix(index)) + branch,
                location: destination.location, sidebarTag: entry.sidebarTag, archiveSearch: entry.archiveSearch,
                fileSearch: entry.fileSearch)
        }
        let previous = HistoryEntry(components: pathComponents, location: location, sidebarTag: selectedSidebarTag,
            archiveSearch: archiveSearchTerm, fileSearch: fileSearch)
        let previousRebased = try await rebased(previous)
        var refreshedBack: [HistoryEntry] = []
        var refreshedForward: [HistoryEntry] = []
        for entry in backStack { if let entry = try await rebased(entry) { refreshedBack.append(entry) } }
        for entry in forwardStack { if let entry = try await rebased(entry) { refreshedForward.append(entry) } }
        var survivingPath = requestedPath
        while try await components(for: survivingPath) == nil {
            survivingPath = survivingPath.split(separator: "/").dropLast().joined(separator: "/")
        }
        let branch = paths[survivingPath] ?? [root]
        let parentIndex = previous.components.firstIndex(where: {
            if case let .archive(address) = $0.location { return address.sessionID == oldAddress.sessionID }
            return false
        }) ?? previous.components.count
        pathComponents = Array(previous.components.prefix(parentIndex)) + branch
        location = branch.last?.location ?? root.location
        if revealsDestination, let previousRebased, previousRebased.location != location {
            // Revealing another directory is actual navigation; Back returns to
            // the directory shown before the operation, using the fresh session.
            refreshedBack.append(previousRebased)
            refreshedForward.removeAll()
        } else if survivingPath != requestedPath {
            while refreshedBack.last?.location == location { refreshedBack.removeLast() }
        }
        backStack = refreshedBack
        forwardStack = refreshedForward
        activeColumnLocation = location
        pendingColumnExpansionItemID = nil
        columnItems = columnItems.filter {
            if case let .archive(address) = $0.key { return address.sessionID != oldAddress.sessionID }
            return true
        }
        columnSelections = columnSelections.filter {
            if case let .archive(address) = $0.key { return address.sessionID != oldAddress.sessionID }
            return true
        }
        columnItems.merge(refreshedColumns) { _, fresh in fresh }
        for component in pathComponents {
            if case let .archive(address) = component.location {
                columnItems[component.location] = preferences.sort.sorted(try await archives.items(at: address))
            } else if case .fileSystem = component.location {
                await reloadColumnItems(at: component.location)
            }
        }
        for (parent, child) in zip(pathComponents, pathComponents.dropFirst()) {
            columnSelections[parent.location] = columnItems[parent.location]?.first(where: {
                $0.location == child.location || ($0.canNavigateAsArchive && $0.name == child.name)
            })?.id
        }
    }

    private func expandedArchivePaths(in sessionID: UUID) -> Set<String> {
        Set(knownItems.compactMap { item in
            guard expandedItems.contains(item.id),
                  case let .archive(address) = item.location,
                  address.sessionID == sessionID else { return nil }
            return address.internalPath
        })
    }

    private func restoreArchiveExpansion(
        in candidates: [BrowserItem], paths: Set<String>,
        destinationPath: String, password: String?
    ) async {
        for item in candidates where item.isDirectory {
            guard case let .archive(address) = item.location else { continue }
            let path = address.internalPath
            let revealsDestination = destinationPath == path || destinationPath.hasPrefix(path + "/")
            guard paths.contains(path) || revealsDestination else { continue }
            if !expandedItems.contains(item.id) {
                await toggleExpansionImpl(item, password: password)
            }
            await restoreArchiveExpansion(
                in: expandedChildren[item.id] ?? [], paths: paths,
                destinationPath: destinationPath, password: password
            )
        }
    }

    private func promptForArchiveUpdatePassword() -> String? {
        let locale = preferences.language.locale
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Archive Password", locale: locale)
        alert.informativeText = AppLocalization.string(
            "Enter the password to update this archive.", locale: locale
        )
        alert.addButton(withTitle: AppLocalization.string("Continue", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn, !field.stringValue.isEmpty else {
            return nil
        }
        return field.stringValue
    }

    private func runArchiveOperation(
        description: String,
        operation: @escaping () async throws -> String
    ) async -> String? {
        archiveOperationDescription = description
        archiveOperationInProgress = true
        archiveProgress = nil
        defer {
            archiveOperationInProgress = false
            archiveProgress = nil
        }
        do {
            return try await operation()
        } catch ArchiveEngineError.cancelled {
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            self.error = mapError(error)
            return nil
        }
    }

    private func createArchive(
        from sources: [URL],
        outputURL: URL,
        options: CompressionOptions,
        password: String?,
        preservingColumnSelection: Bool
    ) async -> String? {
        await runArchiveOperation(
            description: AppLocalization.string(
                "Compressing selected items…", locale: preferences.language.locale
            )
        ) {
            try await self.archives.createArchive(
                from: sources, outputURL: outputURL, options: options, password: password,
                progress: self.archiveProgressHandler()
            )
            if preservingColumnSelection && self.viewMode == .columns {
                await self.reload(
                    preservingColumnSelection: true,
                    refreshingColumnLocations: [
                        .fileSystem(outputURL.deletingLastPathComponent().standardizedFileURL)
                    ]
                )
            } else {
                await self.reload()
            }
            return AppLocalization.string(
                "Archive created successfully.", locale: self.preferences.language.locale
            )
        }
    }

    private func promptForCompressionPassword() -> String? {
        let locale = preferences.language.locale
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Password for Compression", locale: locale)
        alert.informativeText = AppLocalization.string(
            "Enter and confirm a password. It remains in memory for this session.", locale: locale
        )
        alert.addButton(withTitle: AppLocalization.string("Continue", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 32, width: 300, height: 24))
        passwordField.placeholderString = AppLocalization.string("Password", locale: locale)
        let confirmationField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        confirmationField.placeholderString = AppLocalization.string("Confirm password", locale: locale)
        let fields = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 56))
        fields.addSubview(passwordField)
        fields.addSubview(confirmationField)
        alert.accessoryView = fields
        while alert.runModal() == .alertFirstButtonReturn {
            let value = passwordField.stringValue
            if !value.isEmpty && value == confirmationField.stringValue { return value }
            NSSound.beep()
        }
        return nil
    }

    private func processNextArchiveExtraction(password: String?) async -> String? {
        guard !pendingArchiveExtractionItems.isEmpty else { return nil }
        archiveOperationDescription = AppLocalization.string(
            "Extracting archives…",
            locale: preferences.language.locale
        )
        archiveOperationInProgress = true
        archiveProgress = nil

        while pendingArchiveExtractionIndex < pendingArchiveExtractionItems.count {
            let item = pendingArchiveExtractionItems[pendingArchiveExtractionIndex]
            guard let sourceURL = item.localURL else {
                pendingArchiveExtractionIndex += 1
                continue
            }
            let destination = extractionDestination(for: sourceURL)
            do {
                try await archives.extractArchive(
                    at: sourceURL,
                    to: destination,
                    password: password,
                    resolveConflict: archiveConflictResolver(),
                    progress: archiveProgressHandler()
                )
                pendingArchiveExtractionIndex += 1
            } catch ArchiveEngineError.passwordRequired {
                passwordOperation = .extractArchive(item)
                passwordError = nil
                archiveOperationInProgress = false
                archiveProgress = nil
                return nil
            } catch ArchiveEngineError.invalidPassword {
                passwordOperation = .extractArchive(item)
                passwordError = AppLocalization.string(
                    "Incorrect password. Try again.",
                    locale: preferences.language.locale
                )
                archiveOperationInProgress = false
                archiveProgress = nil
                return nil
            } catch {
                self.error = mapError(error)
                archiveOperationInProgress = false
                archiveProgress = nil
                return nil
            }
        }

        let extractionDestinations = pendingArchiveExtractionItems.compactMap { item -> URL? in
            guard let sourceURL = item.localURL else { return nil }
            return extractionDestination(for: sourceURL)
        }
        pendingArchiveExtractionItems.removeAll()
        pendingArchiveExtractionIndex = 0
        archiveOperationInProgress = false
        archiveProgress = nil
        await refreshAfterArchiveExtraction(to: extractionDestinations)
        return AppLocalization.string(
            "Archives extracted successfully.",
            locale: preferences.language.locale
        )
    }

    private func extractionDestination(for sourceURL: URL) -> URL {
        switch pendingExtractionDestination {
        case .here: sourceURL.deletingLastPathComponent()
        case .named:
            sourceURL.deletingLastPathComponent().appendingPathComponent(
                archiveExtractionDirectoryName(for: sourceURL.lastPathComponent),
                isDirectory: true
            )
        case let .chosen(url): url
        }
    }

    private func processNextArchiveValidation(password: String?) async -> String? {
        guard !pendingValidationItems.isEmpty else { return nil }
        archiveOperationDescription = AppLocalization.string("Validating archives…", locale: preferences.language.locale)
        archiveOperationInProgress = true
        defer { archiveOperationInProgress = false }
        while pendingValidationIndex < pendingValidationItems.count {
            let item = pendingValidationItems[pendingValidationIndex]
            guard let url = item.localURL else {
                pendingValidationIndex += 1
                continue
            }
            do {
                try await archives.testArchive(at: url, password: password)
                pendingValidationIndex += 1
            } catch ArchiveEngineError.passwordRequired {
                passwordOperation = .validateArchive(item)
                passwordError = nil
                return nil
            } catch ArchiveEngineError.invalidPassword {
                passwordOperation = .validateArchive(item)
                passwordError = AppLocalization.string("Incorrect password. Try again.", locale: preferences.language.locale)
                return nil
            } catch {
                self.error = mapError(error)
                pendingValidationItems.removeAll()
                pendingValidationIndex = 0
                return nil
            }
        }
        pendingValidationItems.removeAll()
        pendingValidationIndex = 0
        return AppLocalization.string("Archives validated successfully.", locale: preferences.language.locale)
    }

    private func executeInternalExtraction(
        items: [BrowserItem],
        destination: URL,
        password: String?
    ) async -> String? {
        archiveOperationDescription = AppLocalization.string(
            "Extracting selected items…",
            locale: preferences.language.locale
        )
        archiveOperationInProgress = true
        archiveProgress = nil
        do {
            try await archives.extractItems(
                items,
                to: destination,
                password: password,
                resolveConflict: archiveConflictResolver(),
                progress: archiveProgressHandler()
            )
            archiveOperationInProgress = false
            archiveProgress = nil
            await refreshAfterArchiveExtraction(to: [destination])
            return AppLocalization.string(
                "Selected items extracted successfully.",
                locale: preferences.language.locale
            )
        } catch ArchiveEngineError.passwordRequired {
            passwordOperation = .extractItems(items, destinationURL: destination)
            passwordError = nil
            archiveOperationInProgress = false
            archiveProgress = nil
            return nil
        } catch ArchiveEngineError.invalidPassword {
            passwordOperation = .extractItems(items, destinationURL: destination)
            passwordError = AppLocalization.string(
                "Incorrect password. Try again.",
                locale: preferences.language.locale
            )
            archiveOperationInProgress = false
            archiveProgress = nil
            return nil
        } catch {
            self.error = mapError(error)
            archiveOperationInProgress = false
            archiveProgress = nil
            return nil
        }
    }

    private func refreshAfterArchiveExtraction(to destinationDirectories: [URL]) async {
        guard viewMode == .columns else {
            await reload()
            return
        }

        let loadedFileSystemLocations = Set(
            pathComponents.compactMap { component -> URL? in
                guard case let .fileSystem(url) = component.location else { return nil }
                return url
            } + columnItems.keys.compactMap { location -> URL? in
                guard case let .fileSystem(url) = location else { return nil }
                return url
            }
        )
        var affectedColumnLocations = Set<BrowserLocation>()
        for destinationDirectory in destinationDirectories {
            let destination = destinationDirectory.standardizedFileURL
            affectedColumnLocations.insert(.fileSystem(destination))
            affectedColumnLocations.insert(
                .fileSystem(destination.deletingLastPathComponent().standardizedFileURL)
            )
            for loadedLocation in loadedFileSystemLocations
            where isSameOrDescendant(destination, of: loadedLocation) {
                affectedColumnLocations.insert(.fileSystem(loadedLocation))
            }
        }
        await reload(
            preservingColumnSelection: true,
            refreshingColumnLocations: affectedColumnLocations
        )
    }

    private func archiveProgressHandler() -> ArchiveProgressHandler {
        { [weak self] progress in
            Task { @MainActor [weak self] in
                self?.archiveProgress = progress
            }
        }
    }

    private func archiveConflictResolver() -> ArchiveConflictResolver {
        { [weak self] conflict in
            guard let state = self else { return .cancel }
            return await MainActor.run {
                state.resolveArchiveConflict(conflict)
            }
        }
    }

    private func resolveArchiveConflict(_ conflict: ArchiveConflict) -> ArchiveConflictDecision {
        let locale = preferences.language.locale
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Replace existing item?", locale: locale)
        alert.informativeText = conflict.destinationURL.path
        alert.addButton(withTitle: AppLocalization.string("Replace", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Keep", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))

        let applyToAll = NSButton(
            checkboxWithTitle: AppLocalization.string("Apply this decision to all conflicts", locale: locale),
            target: nil,
            action: nil
        )
        alert.accessoryView = applyToAll

        let response = alert.runModal()
        let applies = applyToAll.state == .on
        switch response {
        case .alertFirstButtonReturn: return .replace(applyToAll: applies)
        case .alertSecondButtonReturn: return .keep(applyToAll: applies)
        default: return .cancel
        }
    }

    private func uniqueArchiveOutputURL(
        for sourceURLs: [URL],
        in directory: URL,
        format: ArchiveCompressionFormat
    ) -> URL {
        let baseName = sourceURLs.count == 1
            ? sourceURLs[0].deletingPathExtension().lastPathComponent
            : "Archive"
        let containsDirectory = sourceURLs.contains { isDirectory(at: $0) }
        let usesTar = format.isStream && (sourceURLs.count != 1 || containsDirectory)
        let extensionName = usesTar
            ? "tar.\(format.fileExtension)"
            : format.fileExtension

        var candidate = directory.appendingPathComponent("\(baseName).\(extensionName)")
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(index).\(extensionName)")
            index += 1
        }
        return candidate
    }

    private func archiveBaseName(_ name: String) -> String {
        ArchiveNaming.baseName(name)
    }

    private func archiveExtractionDirectoryName(for archiveName: String) -> String {
        ArchiveNaming.extractionDirectoryName(
            for: archiveName, fallback: AppLocalization.string("Archive", locale: preferences.language.locale)
        )
    }

    private func isDirectory(at url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func archiveCreationDirectory(for sourceURLs: [URL]) -> URL? {
        guard let firstSource = sourceURLs.first else { return nil }
        let firstParent = firstSource.deletingLastPathComponent().standardizedFileURL
        let allSourcesShareParent = sourceURLs.dropFirst().allSatisfy {
            $0.deletingLastPathComponent().standardizedFileURL.path == firstParent.path
        }
        guard allSourcesShareParent else {
            if case .recents = location {
                return preferredOperationSource(among: sourceURLs)?
                    .deletingLastPathComponent().standardizedFileURL
            }
            return fileOperationDestinationURL ?? location.fileSystemURL
        }
        return firstParent
    }

    private func preferredOperationSource(among sourceURLs: [URL]) -> URL? {
        guard !sourceURLs.isEmpty else { return nil }
        if let focusedItemID,
           let focusedURL = knownItemsByID[focusedItemID]?.localURL,
           sourceURLs.contains(where: { $0.standardizedFileURL == focusedURL.standardizedFileURL }) {
            return focusedURL
        }
        return sourceURLs.min { $0.standardizedFileURL.path < $1.standardizedFileURL.path }
    }

    func goBack() async {
        guard let entry = backStack.popLast() else { return }
        forwardStack.append(HistoryEntry(components: pathComponents, location: location, sidebarTag: selectedSidebarTag,
            archiveSearch: archiveSearchTerm, fileSearch: fileSearch))
        pathComponents = entry.components
        location = entry.location
        selectedSidebarTag = entry.sidebarTag
        archiveSearchTerm = entry.archiveSearch
        restoreFileSearch(entry.fileSearch)
        activeColumnLocation = entry.location
        await reload()
    }

    func goForward() async {
        guard let entry = forwardStack.popLast() else { return }
        backStack.append(HistoryEntry(components: pathComponents, location: location, sidebarTag: selectedSidebarTag,
            archiveSearch: archiveSearchTerm, fileSearch: fileSearch))
        pathComponents = entry.components
        location = entry.location
        selectedSidebarTag = entry.sidebarTag
        archiveSearchTerm = entry.archiveSearch
        restoreFileSearch(entry.fileSearch)
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
        if component.location != .recents { selectedSidebarTag = nil; archiveSearchTerm = nil }
        if pathComponents.first?.location != .recents { fileSearch = nil }
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
        reloadGeneration &+= 1
        searchStreamTask?.cancel()
        let generation = reloadGeneration
        let currentLocation = location
        var validSelection = selection
        var cursorSnapshot = hierarchyCursorSnapshot()
        let previousRootItems = items
        isLoading = true
        error = nil
        defer {
            if generation == reloadGeneration { isLoading = false }
        }
        do {
            let loaded: [BrowserItem]
            switch currentLocation {
            case .recents:
                if let fileSearch {
                    loaded = try await streamFileSearch(fileSearch, generation: generation)
                    guard generation == reloadGeneration, currentLocation == location else { return }
                    // Results stream in while the user may already select one.
                    validSelection = selection
                    cursorSnapshot = hierarchyCursorSnapshot()
                } else if let archiveSearchTerm {
                    let results = try await archiveSearch.search(archiveSearchTerm)
                    guard generation == reloadGeneration, currentLocation == location else { return }
                    archiveSearchLease = results.lease
                    loaded = await loadRecentItems(at: results.urls)
                } else if let selectedSidebarTag {
                    let urls = await taggedItems.itemURLs(tagged: selectedSidebarTag)
                    loaded = await loadRecentItems(at: urls, includeDirectories: true).filter { item in
                        item.tags.contains {
                            $0.localizedCaseInsensitiveCompare(selectedSidebarTag) == .orderedSame
                        }
                    }
                } else {
                    let urls = await recentItems.recentItemURLs()
                    loaded = await loadRecentItems(at: urls)
                }
            case .computer:
                loaded = await computerLevelItems()
            case .network:
                loaded = NetworkLevelCatalog.items(servers: networkServers)
            case .networkServer:
                loaded = []
            case let .fileSystem(url):
                loaded = try await fileSystem.items(
                    in: url, showHidden: preferences.showHiddenFiles,
                    includeExtendedMetadata: needsExtendedMetadata
                )
            case let .archive(address):
                loaded = try await archives.items(at: address)
            }
            guard generation == reloadGeneration, currentLocation == location else { return }
            items = loaded
            preferences.rememberSidebarTags(loaded.flatMap(\.tags))
            FinderTagCatalog.shared.observe(loaded)
            purgeRemovedHierarchies(previous: previousRootItems, current: loaded)
            columnItems[currentLocation] = preferences.sort.sorted(loaded)
            for columnLocation in refreshingColumnLocations where columnLocation != currentLocation {
                await reloadColumnItems(at: columnLocation)
                guard generation == reloadGeneration else { return }
            }
            await refreshExpandedFileSystemHierarchy(expectedReloadGeneration: generation)
            guard generation == reloadGeneration else { return }
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
            guard generation == reloadGeneration else { return }
            if viewMode == .columns,
               case let .fileSystem(currentURL) = currentLocation,
               !FileManager.default.fileExists(atPath: currentURL.path) {
                await refreshColumnsAfterRemovingLocalItems([currentURL])
                return
            }
            self.error = mapError(error)
            items = []
            stopExpandedDirectoryMonitors()
        }
    }

    func refreshExpandedHierarchy() async {
        let generation = reloadGeneration
        let cursorSnapshot = hierarchyCursorSnapshot()
        await refreshExpandedFileSystemHierarchy(expectedReloadGeneration: generation)
        guard generation == reloadGeneration else { return }
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
                if self.viewMode == .columns {
                    await self.refreshColumnsAfterRemovingLocalItems(Array(newURLs.keys))
                } else {
                    await self.reload()
                }
            }
        }
    }

    func ejectSelectedVolume() {
        guard let volumeURL = ejectableVolumeURL else { return }
        Task { await ejectVolume(at: volumeURL) }
    }

    /// The single eject entry point shared by File ▸ Eject, the sidebar eject button and the
    /// sidebar Eject menu item. Ejects off the main actor; a repeated request for a volume already
    /// ejecting is ignored. Failure publishes a localized alert and keeps the current location;
    /// success leaves a location on the volume (see `leaveUnmountedVolume(_:)`). The sidebar row
    /// disappears through `SidebarState`'s unmount observer.
    func ejectVolume(at volumeURL: URL, name: String? = nil) async {
        let volume = volumeURL.standardizedFileURL
        guard ejectingVolumeURLs.insert(volume).inserted else { return }
        defer { ejectingVolumeURLs.remove(volume) }
        let volumeName = name ?? FileManager.default.displayName(atPath: volume.path)
        do {
            try await volumeEjector(volume)
        } catch {
            self.error = .ejectFailed(
                volumeName: volumeName,
                inUse: VolumeEjection.isInUse(error),
                detail: error.localizedDescription
            )
            return
        }
        await leaveUnmountedVolume(volume)
    }

    /// Moves a window browsing a folder or an archive on an unmounted volume to the computer
    /// level, which lists the remaining volumes and needs no folder authorization. Called after
    /// Zforge's own eject and for every `NSWorkspace.didUnmountNotification` (Finder, Disk Utility,
    /// another window).
    func leaveUnmountedVolume(_ volumeURL: URL) async {
        let currentURL: URL?
        switch location {
        case .recents, .computer, .network, .networkServer: currentURL = nil
        case let .fileSystem(url): currentURL = url
        case let .archive(address): currentURL = try? await archives.archiveRootURL(for: address)
        }
        guard let currentURL, Self.url(currentURL, isOnVolume: volumeURL) else { return }
        await navigateToComputer()
    }

    nonisolated static func url(_ url: URL, isOnVolume volumeURL: URL) -> Bool {
        let volumePath = volumeURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard volumePath != "/" else { return false }
        return path == volumePath || path.hasPrefix(volumePath.hasSuffix("/") ? volumePath : volumePath + "/")
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

    @discardableResult
    func createNewFolderWithSelection() -> Task<Void, Never>? {
        guard canCreateFolderWithSelection, let directory = fileOperationDestinationURL else { return nil }
        let sources = selectedLocalURLs
        let startingLocation = location
        let startingPath = pathComponents
        let startingColumn = activeColumnLocation
        let startingMode = viewMode
        let locale = preferences.language.locale
        activeFileTransferCount += 1
        fileOperationInProgress = true
        fileOperationDescription = AppLocalization.string("Creating folder with selection…", locale: locale)
        return Task {
            defer {
                activeFileTransferCount -= 1
                if activeFileTransferCount == 0 {
                    fileOperationInProgress = false
                    fileOperationDescription = ""
                }
            }
            do {
                let folder = try await fileOperations.createFolder(containing: sources, in: directory, locale: locale)
                guard !isClosed else { return }
                registerSelectionFolderUndo(folder, grouped: false)
                // Complete the filesystem operation in its captured destination,
                // but only publish selection/rename into the original browsing context.
                guard location == startingLocation, pathComponents == startingPath,
                      activeColumnLocation == startingColumn, viewMode == startingMode else { return }
                if viewMode == .columns {
                    await refreshColumnsAfterRemovingLocalItems(sources)
                } else {
                    await reload()
                }
                guard !isClosed, viewMode == startingMode,
                      fileOperationDestinationURL?.standardizedFileURL == directory.standardizedFileURL else { return }
                if startingMode != .columns {
                    guard location == startingLocation, pathComponents == startingPath,
                          activeColumnLocation == startingColumn else { return }
                }
                renamingItemURL = folder.folderURL.standardizedFileURL
                renameDraft = folder.folderURL.lastPathComponent
                synchronizeRenamingSelection()
            } catch {
                guard !isClosed else { return }
                // Recovery can change a visible hierarchy even when the action
                // failed. Refresh before assigning the error, since reload clears it.
                if location == startingLocation {
                    if viewMode == .columns { await refreshColumnsAfterRemovingLocalItems(sources.filter {
                        !FileManager.default.fileExists(atPath: $0.path)
                    }) } else { await reload() }
                }
                self.error = mapError(error)
            }
        }
    }

    func beginRenamingSelectedItem() {
        guard canRenameSelection, let item = primarySelection else { return }
        beginRenaming(item)
    }

    func beginRenaming(_ item: BrowserItem) {
        guard canRename(item), let itemURL = item.localURL else { return }
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
        let openedSourceURL = pathComponents.first(where: {
            $0.location.fileSystemURL?.standardizedFileURL.path
                == sourceURL.standardizedFileURL.path
        })?.location.fileSystemURL ?? sourceURL
        let openedColumnParentLocation: BrowserLocation? = {
            guard viewMode == .columns,
                  let sourceIndex = pathComponents.firstIndex(where: {
                      $0.location.fileSystemURL?.standardizedFileURL.path
                          == sourceURL.standardizedFileURL.path
                  }),
                  sourceIndex > 0 else {
                return nil
            }
            return pathComponents[sourceIndex - 1].location
        }()
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
                    actionName: AppLocalization.string("Rename", locale: preferences.language.locale),
                    supportsRedo: true
                )
                renamingItemURL = nil
                renameDraft = ""
                await refreshAfterRename(
                    from: openedSourceURL,
                    to: renamedURL,
                    openedColumnParentLocation: openedColumnParentLocation
                )
            } catch {
                self.error = mapError(error)
            }
        }
    }

    private func refreshAfterRename(
        from sourceURL: URL,
        to renamedURL: URL,
        openedColumnParentLocation: BrowserLocation?
    ) async {
        guard viewMode == .columns else {
            await reload()
            selectLocalItem(at: renamedURL)
            return
        }

        let source = sourceURL.standardizedFileURL
        let renamed = renamedURL.standardizedFileURL
        let parentLocation = BrowserLocation.fileSystem(
            renamed.deletingLastPathComponent().standardizedFileURL
        )

        if let openedColumnParentLocation,
           let parentIndex = pathComponents.firstIndex(where: {
               $0.location == openedColumnParentLocation
           }) {
            pathComponents = Array(pathComponents.prefix(parentIndex + 1))
            columnItems = columnItems.filter { columnLocation, _ in
                guard let columnURL = columnLocation.fileSystemURL else { return true }
                return !isSameOrDescendant(columnURL, of: source)
            }
            columnSelections = columnSelections.filter { columnLocation, _ in
                guard let columnURL = columnLocation.fileSystemURL else { return true }
                return !isSameOrDescendant(columnURL, of: source)
            }
            columnSelections.removeValue(forKey: openedColumnParentLocation)
            location = openedColumnParentLocation
            activeColumnLocation = openedColumnParentLocation
            items = columnItems[openedColumnParentLocation] ?? []
            selection.removeAll()
            selectionOrder.removeAll()
            selectionAnchor = nil
            focusedItemID = nil
            updatePreview()

            await reload(
                refreshingColumnLocations: [openedColumnParentLocation]
            )
            guard let renamedItem = columnItems[openedColumnParentLocation]?.first(where: {
                $0.localURL?.standardizedFileURL.path == renamed.path
            }) else { return }
            await activateColumnItem(
                renamedItem,
                in: openedColumnParentLocation,
                recordsHistory: false
            ).value
            return
        }

        await reload(
            preservingColumnSelection: true,
            refreshingColumnLocations: [parentLocation]
        )
        guard let renamedItem = columnItems[parentLocation]?.first(where: {
            $0.localURL?.standardizedFileURL.path == renamed.path
        }) else { return }
        columnSelections[parentLocation] = renamedItem.id
        activeColumnLocation = parentLocation
        select(
            renamedItem,
            orderedItems: sortedColumnItems(at: parentLocation)
        )
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
                if self.viewMode == .columns, !newURLs.isEmpty {
                    await self.refreshColumnsAfterRemovingLocalItems(Array(newURLs.keys))
                } else {
                    await self.reload()
                }
            }
        }
    }

    func requestPermanentDeletion() {
        guard hasLocalSelection, !fileOperationInProgress else { return }
        let urls = selectedLocalURLs
        guard !urls.isEmpty else { return }
        pendingPermanentDeletion = PermanentDeletionRequest(urls: urls)
    }

    func confirmPermanentDeletion() {
        guard let request = pendingPermanentDeletion,
              !fileOperationInProgress else { return }
        pendingPermanentDeletion = nil
        fileOperationInProgress = true
        fileOperationDescription = AppLocalization.string(
            "Deleting items…",
            locale: preferences.language.locale
        )

        Task {
            var operationError: Error?
            do {
                try await fileOperations.removeItems(at: request.urls)
            } catch {
                operationError = error
            }

            if viewMode == .columns {
                await refreshColumnsAfterRemovingLocalItems(request.urls)
            } else {
                await reload()
            }

            fileOperationInProgress = false
            fileOperationDescription = ""
            if let operationError {
                self.error = mapError(operationError)
            }
        }
    }

    var dragSelectionURLs: [URL] {
        selectedLocalURLs
    }

    @discardableResult
    func performArchiveItemDrop(providers: [NSItemProvider], to directory: URL, moving: Bool) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: ArchiveDragPolicy.type) { data, _ in
                guard let data, let token = String(data: data, encoding: .utf8) else { return }
                Task { @MainActor in ArchiveDragTransfer.active[token]?.drop(to: directory, moving: moving) }
            }
        }
        return true
    }

    @discardableResult
    func performArchiveItemDrop(providers: [NSItemProvider], to address: ArchiveAddress, moving: Bool) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: ArchiveDragPolicy.type) { data, _ in
                guard let data, let token = String(data: data, encoding: .utf8) else { return }
                Task { @MainActor in ArchiveDragTransfer.active[token]?.drop(to: address, moving: moving) }
            }
        }
        return true
    }

    func archiveDragItems(startingWith item: BrowserItem) -> [BrowserItem] {
        guard case let .archive(address) = item.location else { return [] }
        let candidates = selectedItems
        if !selection.contains(item.id) || !candidates.allSatisfy({ candidate in
            guard case let .archive(other) = candidate.location else { return false }
            return other.sessionID == address.sessionID && other.archiveID == address.archiveID
        }) { select(item) }
        return selectedItems.filter { candidate in
            guard case let .archive(other) = candidate.location else { return false }
            return !selectedItems.contains { parent in
                guard parent.isDirectory, parent.id != candidate.id,
                      case let .archive(parentAddress) = parent.location else { return false }
                return other.internalPath.hasPrefix(parentAddress.internalPath + "/")
            }
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func canRemoveArchiveItems(_ items: [BrowserItem]) -> Bool {
        guard !items.isEmpty, !archiveOperationInProgress,
              case let .archive(first) = items[0].location, isArchiveSessionWritable(first.sessionID),
              items.allSatisfy({
                  guard case let .archive(address) = $0.location else { return false }
                  return address.sessionID == first.sessionID && address.archiveID == first.archiveID
              }) else { return false }
        let rootName = pathComponents.first(where: {
            guard case let .archive(address) = $0.location else { return false }
            return address.sessionID == first.sessionID
        })?.name ?? inlineArchiveResults.first(where: {
            $0.value.address.sessionID == first.sessionID
        }).flatMap { knownItemsByID[$0.key]?.name }
        return rootName.map(ArchiveFormatRegistry.supportsUpdating) ?? false
    }

    func canReorganizeArchiveItems(_ items: [BrowserItem], to destination: ArchiveAddress) -> Bool {
        guard canRemoveArchiveItems(items) else { return false }
        return items.allSatisfy { item in
            guard case let .archive(source) = item.location,
                  source.sessionID == destination.sessionID, source.archiveID == destination.archiveID else { return false }
            return !item.isDirectory || (destination.internalPath != source.internalPath
                && !destination.internalPath.hasPrefix(source.internalPath + "/"))
        }
    }

    func reportArchiveDragError(_ error: Error) {
        guard (error as? ArchiveEngineError) != .cancelled, !(error is CancellationError) else { return }
        self.error = mapError(error)
    }

    func transferArchiveItems(_ items: [BrowserItem], to destinations: [URL],
                              moving: Bool, resolveConflicts: Bool, confirmed: Bool = false, promised: Bool = false) async throws {
        guard !archiveOperationInProgress, items.count == destinations.count,
              let first = items.first, case let .archive(address) = first.location else {
            throw ArchiveEngineError.itemNotFound
        }
        if moving, !canRemoveArchiveItems(items) { throw ArchiveEngineError.updateUnsupported }
        if moving, !confirmed {
            try await confirmArchiveTransfer(items, destination: destinations.first?.deletingLastPathComponent().path ?? "", moving: true)
        }
        archiveOperationInProgress = true
        archiveOperationDescription = AppLocalization.string(moving ? "Moving out of archive…" : "Extracting items…", locale: preferences.language.locale)
        defer { archiveOperationInProgress = false; archiveProgress = nil }
        let archiveURL = try await archives.archiveRootURL(for: address)
        let scope = archiveURL.startAccessingSecurityScopedResource()
        defer { if scope { archiveURL.stopAccessingSecurityScopedResource() } }
        var exported: [BrowserItem] = []
        var password: String?
        var repeatedDecision: ArchiveConflictDecision?
        for (item, destination) in zip(items, destinations) {
            let resolvedDestination = destination.standardizedFileURL.resolvingSymlinksInPath()
            let resolvedArchive = archiveURL.standardizedFileURL.resolvingSymlinksInPath()
            guard resolvedDestination != resolvedArchive,
                  !resolvedArchive.path.hasPrefix(resolvedDestination.path + "/") else {
                throw ArchiveEngineError.archiveAsDestination
            }
            var backup: URL?
            let destinationScope = destination.startAccessingSecurityScopedResource()
            defer { if destinationScope { destination.stopAccessingSecurityScopedResource() } }
            if resolveConflicts, FileManager.default.fileExists(atPath: destination.path) {
                let decision = repeatedDecision ?? resolveArchiveConflict(ArchiveConflict(
                    path: item.name, destinationURL: destination, isDirectory: item.isDirectory
                ))
                switch decision {
                case let .keep(all): if all { repeatedDecision = decision }; continue
                case .cancel: throw ArchiveEngineError.cancelled
                case let .replace(all):
                    if all { repeatedDecision = decision }
                    let saved = destination.deletingLastPathComponent().appendingPathComponent(".zforge-export-backup-\(UUID().uuidString)")
                    try FileManager.default.moveItem(at: destination, to: saved)
                    backup = saved
                }
            }
            do {
                while true {
                    do {
                        if promised {
                            try await archives.exportPromisedItem(item, to: destination, password: password, progress: archiveProgressHandler())
                        } else {
                            try await archives.exportItem(item, to: destination, password: password, progress: archiveProgressHandler())
                        }
                        break
                    } catch ArchiveEngineError.passwordRequired {
                        guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }
                        password = supplied
                    } catch ArchiveEngineError.invalidPassword {
                        guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }
                        password = supplied
                    }
                }
                if let backup { try FileManager.default.removeItem(at: backup) }
                exported.append(item)
            } catch {
                if let backup, !FileManager.default.fileExists(atPath: destination.path) {
                    try? FileManager.default.moveItem(at: backup, to: destination)
                }
                self.error = mapError(error)
                throw error
            }
        }
        if moving, !exported.isEmpty {
            do {
                let updatedPassword = try await removeArchiveItems(exported, password: password)
                try await refreshUpdatedArchive(ArchiveAdditionRequest(sourceURLs: [], archiveURL: archiveURL, internalPath: ""), password: updatedPassword, navigation: .preserveCurrentDirectory)
            } catch { self.error = mapError(error); throw error }
        }
        contextualFeedbackMessage = AppLocalization.string(moving ? "Items moved out of archive successfully." : "Items extracted successfully.", locale: preferences.language.locale)
    }

    func finishPromisedArchiveMove(_ items: [BrowserItem]) async throws {
        guard canRemoveArchiveItems(items), let first = items.first,
              case let .archive(address) = first.location else { throw ArchiveEngineError.updateUnsupported }
        archiveOperationInProgress = true
        archiveOperationDescription = AppLocalization.string("Moving out of archive…", locale: preferences.language.locale)
        defer { archiveOperationInProgress = false; archiveProgress = nil }
        let url = try await archives.archiveRootURL(for: address)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let password = try await removeArchiveItems(items, password: nil)
        try await refreshUpdatedArchive(ArchiveAdditionRequest(sourceURLs: [], archiveURL: url, internalPath: ""), password: password, navigation: .preserveCurrentDirectory)
        contextualFeedbackMessage = AppLocalization.string("Items moved out of archive successfully.", locale: preferences.language.locale)
    }

    private func removeArchiveItems(_ items: [BrowserItem], password: String?) async throws -> String? {
        var password = password
        while true {
            do { return try await archives.removeItems(items, password: password, progress: archiveProgressHandler()) }
            catch ArchiveEngineError.passwordRequired {
                guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }
                password = supplied
            } catch ArchiveEngineError.invalidPassword {
                guard let supplied = promptForArchiveUpdatePassword() else { throw ArchiveEngineError.cancelled }
                password = supplied
            }
        }
    }

    func requestArchiveRemoval(items: [BrowserItem]? = nil) {
        let items = items ?? selectedItems
        guard canRemoveArchiveItems(items) else { return }
        let locale = preferences.language.locale
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Remove from Archive?", locale: locale)
        alert.informativeText = AppLocalization.string("The selected items will be permanently removed from the archive.", locale: locale)
        alert.addButton(withTitle: AppLocalization.string("Remove", locale: locale))
        alert.addButton(withTitle: AppLocalization.string("Cancel", locale: locale))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await deleteArchiveItems(items) }
    }

    func deleteArchiveItems(_ items: [BrowserItem]) async {
        guard canRemoveArchiveItems(items), let first = items.first,
              case let .archive(address) = first.location else { return }
        contextualFeedbackMessage = await runArchiveOperation(description: AppLocalization.string("Removing from archive…", locale: preferences.language.locale)) {
            let url = try await self.archives.archiveRootURL(for: address)
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let password = try await self.removeArchiveItems(items, password: nil)
            try await self.refreshUpdatedArchive(ArchiveAdditionRequest(sourceURLs: [], archiveURL: url, internalPath: ""), password: password, navigation: .preserveCurrentDirectory)
            return AppLocalization.string("Items removed from archive successfully.", locale: self.preferences.language.locale)
        }
    }

    func prepareDragPayload(_ draggedURLs: [URL]) -> [URL] {
        guard draggedURLs.count == 1,
              let draggedURL = draggedURLs.first?.standardizedFileURL,
              let item = knownItemsByID.values.first(where: {
                  $0.localURL?.standardizedFileURL == draggedURL
              }),
              !selection.contains(item.id) else {
            return draggedURLs
        }
        select(item)
        return draggedURLs
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

    @discardableResult
    func copySelectionPathnamesToPasteboard(_ pasteboard: NSPasteboard = .general) -> Bool {
        guard hasLocalSelection else { return false }
        pasteboard.clearContents()
        return pasteboard.setString(
            selectedLocalURLs.map(\.path).joined(separator: "\n"),
            forType: .string
        )
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

    func chooseFoldersForSidebar() {
        let panel = UITestLaunchIsolation.openPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = AppLocalization.string("Add to Sidebar")
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor in await self?.pinFolders(urls) }
        }
    }

    func pinFolders(_ urls: [URL], before anchor: URL? = nil) async {
        do {
            try PinnedFolderStore.shared.pin(urls, before: anchor)
            for source in urls {
                let url = source.standardizedFileURL.resolvingSymlinksInPath()
                guard !(await grants.hasGrant(for: url)) else { continue }
                let started = source.startAccessingSecurityScopedResource()
                defer { if started { source.stopAccessingSecurityScopedResource() } }
                try await grants.storeGrant(for: url)
            }
        } catch {
            self.error = mapError(error)
        }
    }

    @discardableResult
    func performPinDrop(providers: [NSItemProvider], before anchor: URL?) -> Bool {
        guard !providers.isEmpty else { return false }
        let collector = BrowserDroppedFileURLCollector(count: providers.count) { [weak self] urls, failures in
            guard let self else { return }
            guard failures == 0, !urls.isEmpty else {
                self.error = .unavailable(AppLocalization.string("The dropped file URLs could not be loaded."))
                return
            }
            Task { await self.pinFolders(urls, before: anchor) }
        }
        // Start loading in the drop callback while its providers are accessible.
        for (index, provider) in providers.enumerated() {
            provider.loadObject(ofClass: NSURL.self) { object, error in
                let url = (object as? NSURL).map { $0 as URL }
                Task { @MainActor in collector.receive(url, error: error, at: index) }
            }
        }
        return true
    }

    @discardableResult
    func performArchiveDrop(
        providers: [NSItemProvider],
        to archiveURL: URL?,
        address: ArchiveAddress?
    ) -> Bool {
        guard !providers.isEmpty, archiveURL != nil || address != nil else { return false }
        let collector = BrowserDroppedFileURLCollector(count: providers.count) { [weak self] urls, failures in
            guard let self else { return }
            guard failures == 0, !urls.isEmpty else {
                self.error = .unavailable(AppLocalization.string(
                    "The dropped file URLs could not be loaded.", locale: self.preferences.language.locale
                ))
                return
            }
            if let address {
                Task { await self.requestArchiveAddition(urls, to: address) }
            } else if let archiveURL {
                self.requestArchiveAddition(urls, to: archiveURL)
            }
        }
        for (index, provider) in providers.enumerated() {
            provider.loadObject(ofClass: NSURL.self) { object, error in
                let url = (object as? NSURL).map { $0 as URL }
                Task { @MainActor in collector.receive(url, error: error, at: index) }
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
        let previousField = preferences.sort.field
        if preferences.sort.field == field {
            preferences.sort.ascending.toggle()
        } else {
            preferences.sort = BrowserSort(field: field, ascending: true)
        }
        if previousField != field,
           [.lastOpenedDate, .dateAdded, .version, .comments].contains(field) {
            Task { await reload() }
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

    /// Removes deleted filesystem branches from the Columns state before a
    /// refresh. When the selected container is open in the next column,
    /// `location` points at that container while `activeColumnLocation` still
    /// points at its parent. Reloading first would therefore try to enumerate
    /// a path that no longer exists and surface a misleading error.
    func refreshColumnsAfterRemovingLocalItems(_ urls: [URL]) async {
        guard viewMode == .columns, !urls.isEmpty else {
            await reload()
            return
        }

        let removedURLs = urls.map(\.standardizedFileURL)
        var archiveAddressesBySession: [UUID: ArchiveAddress] = [:]
        for component in pathComponents {
            if case let .archive(address) = component.location {
                archiveAddressesBySession[address.sessionID] = address
            }
        }
        for columnLocation in columnItems.keys {
            if case let .archive(address) = columnLocation {
                archiveAddressesBySession[address.sessionID] = address
            }
        }
        var removedArchiveRoots: [UUID: URL] = [:]
        for (sessionID, address) in archiveAddressesBySession {
            guard let rootURL = try? await archives.archiveRootURL(for: address),
                  removedURLs.contains(where: { isSameOrDescendant(rootURL, of: $0) }) else {
                continue
            }
            removedArchiveRoots[sessionID] = rootURL.standardizedFileURL
        }
        let cachedItems = items + columnItems.values.flatMap { $0 }
        let removedItemIDs = Set(
            cachedItems.compactMap { item -> BrowserItemID? in
                guard let itemURL = item.localURL,
                      removedURLs.contains(where: { isSameOrDescendant(itemURL, of: $0) }) else {
                    return nil
                }
                return item.id
            }
        )
        let staleColumnLocations = Set(
            columnItems.keys.filter { columnLocation in
                switch columnLocation {
                case let .fileSystem(columnURL):
                    return removedURLs.contains(where: { isSameOrDescendant(columnURL, of: $0) })
                case let .archive(address):
                    return removedArchiveRoots[address.sessionID] != nil
                case .recents, .computer, .network, .networkServer:
                    return false
                }
            }
        )

        columnItems = columnItems.filter { !staleColumnLocations.contains($0.key) }
        columnSelections = columnSelections.filter {
            !staleColumnLocations.contains($0.key) && !removedItemIDs.contains($0.value)
        }
        selection.subtract(removedItemIDs)
        selectionOrder.removeAll { removedItemIDs.contains($0) }
        if let selectionAnchor, removedItemIDs.contains(selectionAnchor) {
            self.selectionAnchor = nil
        }
        if let focusedItemID, removedItemIDs.contains(focusedItemID) {
            self.focusedItemID = nil
        }
        purgeCachedHierarchies(rootedAt: removedItemIDs)

        let firstRemovedPathIndex = pathComponents.firstIndex { component in
            switch component.location {
            case let .fileSystem(componentURL):
                return removedURLs.contains(where: { isSameOrDescendant(componentURL, of: $0) })
            case let .archive(address):
                return removedArchiveRoots[address.sessionID] != nil
            case .recents, .computer, .network, .networkServer:
                return false
            }
        }

        let targetLocation: BrowserLocation
        if let firstRemovedPathIndex,
           firstRemovedPathIndex > 0 {
            let retainedComponents = Array(pathComponents.prefix(firstRemovedPathIndex))
            pathComponents = retainedComponents
            targetLocation = retainedComponents.last?.location ?? location
        } else if let currentURL = location.fileSystemURL,
                  removedURLs.contains(where: { isSameOrDescendant(currentURL, of: $0) }) {
            let parentURL = currentURL.deletingLastPathComponent().standardizedFileURL
            targetLocation = .fileSystem(parentURL)
            pathComponents = [
                BrowserPathComponent(
                    location: targetLocation,
                    name: parentURL.lastPathComponent,
                    isArchive: false
                )
            ]
            columnItems.removeAll()
            columnSelections.removeAll()
        } else if case let .archive(currentAddress) = location,
                  let rootURL = removedArchiveRoots[currentAddress.sessionID] {
            let parentURL = rootURL.deletingLastPathComponent().standardizedFileURL
            targetLocation = .fileSystem(parentURL)
            pathComponents = [
                BrowserPathComponent(
                    location: targetLocation,
                    name: parentURL.lastPathComponent,
                    isArchive: false
                )
            ]
            columnItems.removeAll()
            columnSelections.removeAll()
        } else {
            targetLocation = location
        }

        for sessionID in removedArchiveRoots.keys {
            await archives.closeSession(sessionID)
        }
        location = targetLocation
        activeColumnLocation = targetLocation
        items = columnItems[targetLocation] ?? []
        updatePreview()
        var affectedColumnLocations = Set<BrowserLocation>(removedURLs.map {
            .fileSystem($0.deletingLastPathComponent().standardizedFileURL)
        })
        affectedColumnLocations.insert(targetLocation)
        await reload(
            preservingColumnSelection: true,
            refreshingColumnLocations: affectedColumnLocations
        )
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
        columnActivationGeneration &+= 1
        let activationGeneration = columnActivationGeneration
        let previousActivationTask = columnActivationTask
        previousActivationTask?.cancel()

        let parentItems = sortedColumnItems(at: parentLocation)
        columnSelections[parentLocation] = item.id
        activeColumnLocation = parentLocation
        select(item, modifiers: modifiers, orderedItems: parentItems)

        let retainedComponents = Array(pathComponents.prefix(parentIndex + 1))
        let opensBranch = !modifiers.contains(.command)
            && !modifiers.contains(.shift)
            && item.isNavigableContainer
        pendingColumnExpansionItemID = opensBranch ? item.id : nil
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

        let activationTask = Task { [weak self] in
            if let previousActivationTask {
                await previousActivationTask.value
            }
            guard let self,
                  !Task.isCancelled,
                  activationGeneration == self.columnActivationGeneration,
                  self.activeColumnLocation == parentLocation,
                  self.columnSelections[parentLocation] == item.id else {
                return
            }
            defer {
                if activationGeneration == self.columnActivationGeneration {
                    self.columnActivationTask = nil
                    self.pendingColumnExpansionItemID = nil
                }
            }
            guard opensBranch else { return }
            await self.open(item, recordsHistory: false, clearsSelection: false)
        }
        columnActivationTask = activationTask
        return activationTask
    }

    @discardableResult
    func activateFirstItemInColumn(
        at location: BrowserLocation
    ) -> Task<Void, Never> {
        guard let firstItem = sortedColumnItems(at: location).first else {
            return Task {}
        }
        return activateColumnItem(firstItem, in: location)
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
        do {
            guard try await activateComputerLevelAccess(for: item) else { return }
        } catch {
            self.error = mapError(error)
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
                    case .recents, .computer, .network, .networkServer:
                        return
                    case let .fileSystem(url):
                        result = try await archives.openArchive(at: url, password: password)
                        recordArchiveVolume(result.address.sessionID, url: url)
                    case .archive:
                        return
                    }
                    recordArchiveSession(result)
                    inlineArchiveResults[item.id] = result
                }
                children = try await archives.items(at: result.address)
                passwordOperation = nil
                passwordError = nil
            } else {
                switch item.location {
                case .recents, .computer, .network, .networkServer:
                    return
                case let .fileSystem(url):
                    children = try await fileSystem.items(
                        in: url, showHidden: preferences.showHiddenFiles,
                        includeExtendedMetadata: needsExtendedMetadata
                    )
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
        itemProjection.flattenedList(
            sortedRoots: sortedItems, expandedIDs: expandedItems,
            expandedChildren: expandedChildren, sort: preferences.sort,
            showsHidden: preferences.showHiddenFiles
        )
    }

    func flattenedItems() -> [BrowserItem] {
        itemProjection.flattenedItems(
            sortedRoots: sortedItems, expandedIDs: expandedItems,
            expandedChildren: expandedChildren, sort: preferences.sort,
            showsHidden: preferences.showHiddenFiles
        )
    }

    func iconPreview(for item: BrowserItem, pixelSize: Int) async throws -> CGImage? {
        try await IconPreviewService.shared.image(for: item, pixelSize: pixelSize, archives: archives,
            limits: preferences.archivePreviewLimits, volume: archiveVolumeKind(of: item))
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
        guard previewVisible || viewMode == .gallery else { return }
        let previewableItems = selectedItems.filter { !$0.usesStaticIconPreview }
        guard !previewableItems.isEmpty else { return }

        var itemsToMaterialize: [BrowserItem] = []
        // D-73: a single selection is previewed under the preview limits; the stack of a
        // multiple selection shows thumbnails under the thumbnail limits.
        let limits = preferences.archivePreviewLimits
        let showsThumbnails = previewableItems.count > 1
        for item in previewableItems {
            if let localURL = item.localURL {
                previewURLs[item.id] = localURL
            } else if !manual, !(showsThumbnails
                ? limits.allowsAutomaticThumbnail(of: item, on: archiveVolumeKind(of: item))
                : limits.allowsAutomaticPreview(of: item, on: archiveVolumeKind(of: item))) {
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
                    // The limits were applied above, with the solid-block measure.
                    let url = try await archives.materialize(item: item, purpose: .preview, automaticLimit: nil)
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
            // An explicit Quick Look loads archive items whatever their size, with progress
            // and Cancel when it takes a while (D-73).
            let readsArchive = chosenItems.contains { $0.localURL == nil } && !archiveOperationInProgress
            if readsArchive {
                beginDelayedArchiveOperation(AppLocalization.string("Loading…", locale: preferences.language.locale))
            }
            defer {
                if readsArchive {
                    archiveOperationInProgress = false
                    archiveProgress = nil
                }
            }
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
            } catch ArchiveEngineError.cancelled {
            } catch is CancellationError {
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

    func applicationsForOpening(_ items: [BrowserItem]) -> [URL] {
        guard !items.isEmpty, items.allSatisfy({ !$0.isContainer }) else { return [] }
        let workspace = NSWorkspace.shared
        let candidates = items.map { item -> [URL] in
            if let url = item.localURL {
                return workspace.urlsForApplications(toOpen: url)
            }
            guard let type = item.contentType else { return [] }
            return workspace.urlsForApplications(toOpen: type)
        }
        guard let first = candidates.first else { return [] }
        let common = candidates.dropFirst().map { Set($0.map(\.standardizedFileURL)) }
        return first.filter { application in
            common.allSatisfy { $0.contains(application.standardizedFileURL) }
        }
    }

    func openWith(_ items: [BrowserItem], application: URL, always: Bool = false) {
        guard !items.isEmpty, items.allSatisfy({ !$0.isContainer }) else { return }
        Task {
            do {
                if always {
                    guard items.allSatisfy({ $0.localURL != nil }) else { return }
                    for url in items.compactMap(\.localURL) {
                        try await setDefaultApplication(application, for: url)
                    }
                }

                var urls: [URL] = []
                for item in items {
                    if let url = item.localURL {
                        urls.append(url)
                    } else {
                        urls.append(try await archives.materialize(
                            item: item,
                            purpose: .openExternally,
                            automaticLimit: nil
                        ))
                    }
                }
                NSWorkspace.shared.open(
                    urls,
                    withApplicationAt: application,
                    configuration: NSWorkspace.OpenConfiguration()
                ) { _, openError in
                    if let openError {
                        Task { @MainActor in self.error = self.mapError(openError) }
                    }
                }
            } catch {
                self.error = mapError(error)
            }
        }
    }

    func chooseApplicationForOpening(_ items: [BrowserItem], always: Bool = false) {
        guard !items.isEmpty, items.allSatisfy({ !$0.isContainer }),
              !always || items.allSatisfy({ $0.localURL != nil }) else { return }
        let panel = UITestLaunchIsolation.openPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let application = panel.url else { return }
            Task { @MainActor in
                self?.openWith(items, application: application, always: always)
            }
        }
    }

    private func setDefaultApplication(_ application: URL, for file: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.setDefaultApplication(at: application, toOpenFileAt: file) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func close() {
        guard !isClosed else { return }
        // Inner archive windows close first, innermost first, so their write-backs run in order.
        ArchiveWindowRegistry.shared.windowWillClose(self)
        if let sessionChangeObserver { NotificationCenter.default.removeObserver(sessionChangeObserver) }
        sessionChangeObserver = nil
        initialArchiveSession = nil
        initialAutomationAccessLease = nil
        archiveSessionAccessLease = nil
        archiveSearchLease = nil
        searchDebounceTask?.cancel()
        searchStreamTask?.cancel()
        isClosed = true
        undoManager?.removeAllActions(withTarget: self)
        volumeObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        volumeObservers.removeAll()
        monitor.stop()
        stopExpandedDirectoryMonitors()
        recentItems.stop()
        taggedItems.stop()
        tagRefreshTask?.cancel()
        previewTask?.cancel()
        previewTask = nil
        reloadGeneration &+= 1
        columnActivationTask?.cancel()
        columnActivationTask = nil
        pendingColumnExpansionItemID = nil
        synchronizeNetworkDiscovery()
        let archives = self.archives
        let grants = self.grants
        closingTask = Task {
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
        archiveOperationDescription = AppLocalization.string(
            "Loading…",
            locale: preferences.language.locale
        )
        archiveProgress = nil
        archiveOperationInProgress = true
        defer {
            archiveOperationInProgress = false
            archiveProgress = nil
        }
        do {
            let url: URL
            switch item.location {
            case .recents, .computer, .network, .networkServer:
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
        clearsSelection: Bool = true,
        sidebarTag: String? = nil,
        archiveSearch: String? = nil,
        fileSearch: BrowserFileSearch? = nil,
        searchResultURL: URL? = nil,
        systemImage: String? = nil,
        parentComponents: [BrowserPathComponent] = []
    ) async {
        cancelRenaming()
        if recordsHistory { pushHistory() }
        let previousSearch = self.fileSearch
        // Columns keep the results column while a result's contents are shown beside it.
        let keepsSearchColumn = previousSearch != nil && !resetPath && !clearsSelection
        self.location = location
        selectedSidebarTag = sidebarTag
        archiveSearchTerm = archiveSearch
        self.fileSearch = keepsSearchColumn ? previousSearch : fileSearch
        if resetPath {
            pendingColumnExpansionItemID = nil
            pathComponents = parentComponents
                + [BrowserPathComponent(location: location, name: name, isArchive: isArchive, systemImage: systemImage)]
            columnItems.removeAll()
            columnSelections.removeAll()
        } else if let previousSearch, !keepsSearchColumn {
            pathComponents = searchResultPath(
                to: BrowserPathComponent(location: location, name: name, isArchive: isArchive),
                from: previousSearch, searchResultURL: searchResultURL)
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
        await reload(preservingColumnSelection: !clearsSelection,
                     refreshingColumnLocations: Set(parentComponents.map(\.location)))
    }

    private func pushHistory() {
        backStack.append(HistoryEntry(components: pathComponents, location: location, sidebarTag: selectedSidebarTag,
            archiveSearch: archiveSearchTerm, fileSearch: fileSearch))
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

    private func refreshExpandedFileSystemHierarchy(expectedReloadGeneration: UInt64) async {
        guard expectedReloadGeneration == reloadGeneration else { return }

        func refresh(_ candidates: [BrowserItem]) async {
            for item in candidates where expandedItems.contains(item.id) {
                guard expectedReloadGeneration == reloadGeneration else { return }
                var children = expandedChildren[item.id] ?? []

                if item.isDirectory,
                   case let .fileSystem(url) = item.location,
                   FileManager.default.fileExists(atPath: url.path) {
                    do {
                        let loaded = try await fileSystem.items(
                            in: url,
                            showHidden: preferences.showHiddenFiles,
                            includeExtendedMetadata: needsExtendedMetadata
                        )
                        guard expectedReloadGeneration == reloadGeneration else { return }
                        guard expandedItems.contains(item.id) else { continue }
                        let previousChildren = children
                        children = preferences.sort.sorted(loaded)
                        expandedChildren[item.id] = children
                        purgeRemovedHierarchies(previous: previousChildren, current: children)
                    } catch {
                        guard expectedReloadGeneration == reloadGeneration else { return }
                        self.error = mapError(error)
                        continue
                    }
                }

                await refresh(children)
            }
        }

        await refresh(items)
        guard expectedReloadGeneration == reloadGeneration else { return }

        // Reachability is taken from the tree as it is now, after the last
        // suspension: an expansion that other work completed while a listing
        // above was awaited (the refresh after an archive update, the user's
        // disclosure) is reachable and stays (D-90).
        var reachableExpandedItems: Set<BrowserItemID> = []
        var pending = items
        while let item = pending.popLast() {
            guard expandedItems.contains(item.id), reachableExpandedItems.insert(item.id).inserted else { continue }
            pending.append(contentsOf: expandedChildren[item.id] ?? [])
        }
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
                showHidden: preferences.showHiddenFiles,
                includeExtendedMetadata: needsExtendedMetadata
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

    private func loadRecentItems(at urls: [URL], includeDirectories: Bool = false) async -> [BrowserItem] {
        var loaded: [BrowserItem] = []
        var seenIDs: Set<BrowserItemID> = []
        loaded.reserveCapacity(urls.count)
        for url in urls {
            guard !Task.isCancelled else { break }
            guard !ZforgeTemporaryStorage.contains(url) else { continue }
            if let item = try? await fileSystem.item(at: url, includeExtendedMetadata: needsExtendedMetadata),
               (includeDirectories || !item.isDirectory),
               preferences.showHiddenFiles || !item.isHidden {
                guard seenIDs.insert(item.id).inserted else { continue }
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
            && (previewVisible || viewMode == .gallery)
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
                forKeys: SidebarVolume.ejectabilityKeys.union([.volumeURLKey])
            ), SidebarVolume.isEjectable(values),
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
        activeFileTransferCount += 1
        fileOperationInProgress = true
        fileOperationDescription = fileTransferDescription(for: operation)
        defer {
            activeFileTransferCount -= 1
            if activeFileTransferCount == 0 {
                fileOperationInProgress = false
                fileOperationDescription = ""
            }
        }

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
            if viewMode == .columns {
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

    private func fileTransferDescription(
        for operation: BrowserFileTransferOperation
    ) -> String {
        switch operation {
        case .copy:
            AppLocalization.string(
                "Copying items…",
                locale: preferences.language.locale
            )
        case .move:
            AppLocalization.string(
                "Moving items…",
                locale: preferences.language.locale
            )
        case .alias:
            AppLocalization.string(
                "Creating aliases…",
                locale: preferences.language.locale
            )
        case .automatic:
            AppLocalization.string(
                "Transferring items…",
                locale: preferences.language.locale
            )
        }
    }

    private func reloadColumnItems(at location: BrowserLocation) async {
        if location == .computer {
            columnItems[.computer] = preferences.sort.sorted(await computerLevelItems())
            return
        }
        if location == .network {
            columnItems[.network] = preferences.sort.sorted(NetworkLevelCatalog.items(servers: networkServers))
            return
        }
        guard case let .fileSystem(url) = location else { return }
        do {
            let loaded = try await fileSystem.items(
                in: url,
                showHidden: preferences.showHiddenFiles,
                includeExtendedMetadata: needsExtendedMetadata
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

    private func isSameOrDescendant(_ candidate: URL, of ancestor: URL) -> Bool {
        let candidatePath = stableFilePath(candidate)
        let ancestorPath = stableFilePath(ancestor)
        guard candidatePath != ancestorPath else { return true }
        let prefix = ancestorPath.hasSuffix("/") ? ancestorPath : ancestorPath + "/"
        return candidatePath.hasPrefix(prefix)
    }

    /// Resolve symlinks through the nearest existing parent, since removal
    /// callbacks also compare paths whose final item no longer exists.
    private func stableFilePath(_ url: URL) -> String {
        var existingURL = url.standardizedFileURL
        var missingComponents: [String] = []
        while !FileManager.default.fileExists(atPath: existingURL.path),
              existingURL.path != "/" {
            missingComponents.append(existingURL.lastPathComponent)
            existingURL.deleteLastPathComponent()
        }
        var resolved = existingURL.resolvingSymlinksInPath().standardizedFileURL
        for component in missingComponents.reversed() {
            resolved.appendPathComponent(component)
        }
        return resolved.standardizedFileURL.path
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
        actionName: String,
        supportsRedo: Bool = false
    ) {
        guard !removals.isEmpty || !moves.isEmpty, let undoManager else { return }
        let record = FileUndoRecord(
            removals: removals.map(\.standardizedFileURL),
            moves: moves,
            actionName: actionName,
            supportsRedo: supportsRedo
        )
        undoManager.registerUndo(withTarget: self) { state in
            state.performUndo(record)
        }
        undoManager.setActionName(actionName)
    }

    private func performUndo(_ record: FileUndoRecord) {
        if record.supportsRedo, record.removals.isEmpty, !record.moves.isEmpty {
            registerUndo(moving: record.moves.reversed().map {
                BrowserExactFileMove(sourceURL: $0.destinationURL, destinationURL: $0.sourceURL)
            }, actionName: record.actionName, supportsRedo: true)
        }
        enqueueFileUndo {
            do {
                try await self.fileOperations.moveItems(record.moves)
                try await self.fileOperations.removeItems(at: record.removals)
                await self.reload()
            } catch {
                self.error = self.mapError(error)
            }
        }
    }

    private func registerSelectionFolderUndo(_ folder: BrowserSelectionFolder, grouped: Bool) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { state in
            // UndoManager requires the inverse synchronously inside its callback;
            // registering it after async filesystem work would erase the Redo stack.
            state.registerSelectionFolderUndo(folder, grouped: !grouped)
            state.enqueueFileUndo {
                do {
                    try await state.fileOperations.setSelectionFolder(folder, grouped: grouped)
                    state.cancelRenaming()
                    let removed = grouped ? folder.moves.map(\.sourceURL) : [folder.folderURL]
                    if state.viewMode == .columns { await state.refreshColumnsAfterRemovingLocalItems(removed) }
                    else { await state.reload() }
                    state.selectLocalItems(at: grouped ? [folder.folderURL] : folder.moves.map(\.sourceURL))
                } catch { state.error = state.mapError(error) }
            }
        }
        undoManager.setActionName(AppLocalization.string("New Folder with Selection", locale: preferences.language.locale))
    }

    private func enqueueFileUndo(_ operation: @escaping @MainActor () async -> Void) {
        let previous = fileUndoTask
        activeFileTransferCount += 1
        fileOperationInProgress = true
        fileUndoTask = Task {
            await previous?.value
            defer {
                activeFileTransferCount -= 1
                if activeFileTransferCount == 0 {
                    fileOperationInProgress = false
                    fileOperationDescription = ""
                }
            }
            await operation()
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
        viewMode == .list ? flattenedItems() : sortedItems
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
