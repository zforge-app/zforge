import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum BrowserFocusTarget: Hashable {
    case content
    case rename(BrowserItemID)
}

struct BrowserContent: View {
    @Bindable var state: FileBrowserState
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
    @State private var contentWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch state.viewMode {
                case .icons:
                    contentWithOptionalPreview {
                        IconBrowserView(
                            state: state,
                            contentFocus: contentFocus,
                            dragSession: dragSession
                        )
                    }
                case .list:
                    listWithOptionalPreview
                case .columns:
                    ColumnBrowserView(
                        state: state,
                        contentFocus: contentFocus,
                        dragSession: dragSession
                    )
                case .gallery:
                    GalleryBrowserView(
                        state: state,
                        contentFocus: contentFocus,
                        dragSession: dragSession
                    )
                }
            }
            .onAppear { updateContentWidth(geometry.size.width) }
            .onChange(of: geometry.size.width) { _, width in updateContentWidth(width) }
            .onChange(of: state.previewVisible) { _, _ in updateContentWidth(geometry.size.width) }
            .onChange(of: state.viewMode) { _, _ in updateContentWidth(geometry.size.width) }
            .onChange(of: state.preferences.scale) { _, _ in updateContentWidth(geometry.size.width) }
            .onChange(of: state.preferences.previewWidth) { _, _ in updateContentWidth(geometry.size.width) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
        .accessibilityIdentifier("browser-mode-\(state.viewMode.rawValue)")
        .accessibilityValue(Double(state.preferences.scale).formatted(
            .percent.locale(state.preferences.language.locale)
        ))
        .focusable()
        .focused(contentFocus, equals: .content)
        .focusEffectDisabled()
        .onMoveCommand(perform: handleMoveCommand)
        .onCopyCommand { state.copyItemProviders() }
        .onPasteCommand(of: [.fileURL]) { providers in
            state.pasteItemProviders(providers)
        }
        .onModifierKeysChanged(mask: [.option, .command]) { _, modifiers in
            dragSession.modifiers = modifiers
        }
        .dragPreviewsFormation(state.viewMode.fileDragPreviewsFormation)
        .onDrop(
            of: [UTType.fileURL.identifier, ArchiveDragPolicy.type],
            delegate: BrowserFileDropDelegate(
                state: state,
                // The blank area represents the directory currently being
                // browsed, even when List has a focused expanded descendant.
                destinationURL: state.fileDropDestinationURL,
                dragSession: dragSession,
                archiveAddress: state.archiveDropAddress
            )
        )
        .overlay {
            if state.fileDropDestinationURL != nil || state.archiveDropAddress != nil {
                ArchiveDropDestination(directory: state.fileDropDestinationURL, address: state.archiveDropAddress)
                    .accessibilityHidden(true)
            }
        }
        .dropPreviewsFormation(state.viewMode.fileDragPreviewsFormation)
        .onChange(of: state.renamingItemURL) { _, url in
            if url == nil {
                contentFocus.wrappedValue = .content
            }
        }
        .overlay {
            if state.isLoading && state.items.isEmpty {
                ProgressView("Loading…")
                    .padding(22)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
        }
    }

    @ViewBuilder
    private func contentWithOptionalPreview<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            content()
            if state.previewVisible {
                BrowserPreviewPane(state: state)
                    .browserContextMenuExcludedArea(state: state)
            }
        }
    }

    private var listWithOptionalPreview: some View {
        let previewWidth = state.previewVisible
            ? state.preferences.previewWidth * state.preferences.scale
            : 0

        return ZStack(alignment: .trailing) {
            ListBrowserView(
                state: state,
                obscuredTrailingWidth: previewWidth,
                contentFocus: contentFocus,
                dragSession: dragSession
            )

            if state.previewVisible {
                BrowserPreviewPane(state: state)
                    .browserContextMenuExcludedArea(state: state)
                    .background(.ultraThinMaterial)
                    .zIndex(1)
            }
        }
    }

    private func updateContentWidth(_ totalWidth: CGFloat) {
        let hasSidePreview = state.previewVisible
            && state.viewMode == .icons
        contentWidth = max(
            totalWidth - (hasSidePreview ? state.preferences.previewWidth * state.preferences.scale : 0),
            1
        )
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        let extending = NSEvent.modifierFlags.contains(.shift)
        switch state.viewMode {
        case .icons:
            let scale = state.preferences.scale
            let itemWidth = BrowserMetrics.iconGridItemWidth * scale
            let spacing = BrowserMetrics.iconGridSpacing * scale
            let padding = BrowserMetrics.iconGridPadding * 2 * scale
            let availableWidth = max(contentWidth - padding, itemWidth)
            let columnCount = max(Int((availableWidth + spacing) / (itemWidth + spacing)), 1)
            let delta = switch direction {
            case .left: -1
            case .right: 1
            case .up: -columnCount
            case .down: columnCount
            @unknown default: 0
            }
            state.moveSelection(by: delta, extending: extending)
        case .list:
            handleListMoveCommand(direction, extending: extending)
        case .columns:
            handleColumnMoveCommand(direction, extending: extending)
        case .gallery:
            let delta = direction == .left || direction == .up ? -1 : 1
            state.moveSelection(by: delta, extending: extending)
        }
    }

    private func handleListMoveCommand(_ direction: MoveCommandDirection, extending: Bool) {
        let visibleItems = state.flattenedItems()
        switch direction {
        case .up, .down:
            state.moveSelection(
                by: direction == .up ? -1 : 1,
                extending: extending,
                orderedItems: visibleItems
            )
        case .right:
            guard let item = state.primarySelection,
                  item.canExpandInlineInList,
                  !state.expandedItems.contains(item.id) else { return }
            Task { await state.toggleExpansion(item) }
        case .left:
            Task { await state.moveListSelectionLeft() }
        @unknown default:
            break
        }
    }

    private func handleColumnMoveCommand(_ direction: MoveCommandDirection, extending: Bool) {
        let activeLocation = state.activeColumnLocation ?? state.location
        guard let activeIndex = state.pathComponents.firstIndex(where: { $0.location == activeLocation }) else { return }

        switch direction {
        case .left:
            guard activeIndex > 0 else { return }
            focusColumn(at: activeIndex - 1, selectsFirstItemWhenNeeded: false)
        case .right:
            if activeIndex + 1 < state.pathComponents.count {
                focusColumn(at: activeIndex + 1, selectsFirstItemWhenNeeded: true)
                return
            }

            let items = state.sortedColumnItems(at: activeLocation)
            guard let selectedID = state.columnSelections[activeLocation],
                  let selectedItem = items.first(where: { $0.id == selectedID }),
                  selectedItem.isNavigableContainer else { return }
            let activation = state.activateColumnItem(selectedItem, in: activeLocation)
            Task {
                await activation.value
                let nextIndex = activeIndex + 1
                guard nextIndex < state.pathComponents.count else { return }
                focusColumn(at: nextIndex, selectsFirstItemWhenNeeded: true)
            }
        case .up, .down:
            let items = state.sortedColumnItems(at: activeLocation)
            guard !items.isEmpty else { return }
            let selectedID = state.columnSelections[activeLocation]
            let currentIndex = selectedID.flatMap { id in items.firstIndex(where: { $0.id == id }) }
                ?? (direction == .down ? -1 : items.count)
            let nextIndex = min(max(currentIndex + (direction == .down ? 1 : -1), 0), items.count - 1)
            state.activateColumnItem(
                items[nextIndex],
                in: activeLocation,
                modifiers: extending ? [.shift] : []
            )
        @unknown default:
            break
        }
    }

    private func focusColumn(at index: Int, selectsFirstItemWhenNeeded: Bool) {
        guard state.pathComponents.indices.contains(index) else { return }
        let location = state.pathComponents[index].location
        if selectsFirstItemWhenNeeded {
            state.activateFirstItemInColumn(at: location)
            return
        }

        let items = state.sortedColumnItems(at: location)
        let selectedItem = state.columnSelections[location].flatMap { selectedID in
            items.first(where: { $0.id == selectedID })
        }

        if let selectedItem {
            state.columnSelections[location] = selectedItem.id
            state.select(selectedItem, orderedItems: items)
        }
        state.activeColumnLocation = location
    }
}

private struct BrowserPreviewPane: View {
    @Bindable var state: FileBrowserState

    private var scale: CGFloat { state.preferences.scale }
    private var width: CGFloat { state.preferences.previewWidth * scale }

    var body: some View {
        Group {
            if state.previewItems.isEmpty {
                Color.clear
            } else {
                SelectionOverview(
                    state: state,
                    items: state.previewItems,
                    presentation: .column,
                    scale: scale
                )
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .leading) {
            Rectangle().fill(.separator).frame(width: 1)
        }
        .overlay(alignment: .leading) {
            BrowserColumnResizeHandle(
                currentWidth: state.preferences.previewWidth,
                scale: scale,
                direction: -1,
                isPreview: true
            ) { state.preferences.setPreviewWidth($0) }
            .frame(width: 20 * scale)
            .help("Drag to resize preview")
        }
    }
}

struct BrowserItemNameView: View {
    @Bindable var state: FileBrowserState
    let item: BrowserItem
    var lineLimit = 1
    var textAlignment: TextAlignment = .leading
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding

    var body: some View {
        Group {
            if state.renamingItemID == item.id {
                TextField("Rename", text: $state.renameDraft)
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .multilineTextAlignment(textAlignment)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color(nsColor: .textBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.tint, lineWidth: 1)
                    }
                    .focused(contentFocus, equals: .rename(item.id))
                    .disabled(state.renameInProgress)
                    .accessibilityIdentifier("rename-field-\(item.id.rawValue)")
                    .onSubmit { state.commitRename() }
                    .onExitCommand { state.cancelRenaming() }
                    .task(id: state.renamingItemURL) {
                        guard state.renamingItemID == item.id else { return }
                        await focusAndSelectName()
                    }
            } else {
                Text(item.name)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(textAlignment)
            }
        }
    }

    @MainActor
    private func focusAndSelectName() async {
        await Task.yield()
        let target = BrowserFocusTarget.rename(item.id)
        contentFocus.wrappedValue = target
        await Task.yield()
        guard contentFocus.wrappedValue == target else { return }
        (NSApp.keyWindow?.firstResponder as? NSTextView)?.selectAll(nil)
    }
}

extension BrowserItem {
    var displayKind: String {
        if isDirectory { return AppLocalization.string("Folder") }
        if isArchive { return AppLocalization.string("Archive") }
        return contentType?.localizedDescription ?? AppLocalization.string("Document")
    }
}

struct BrowserFileDropDelegate: DropDelegate {
    let state: FileBrowserState
    let destinationURL: URL?
    let dragSession: BrowserFileDragSession
    var archiveDestinationURL: URL? = nil
    var archiveAddress: ArchiveAddress? = nil
    var onTargetedChange: (Bool) -> Void = { _ in }

    func validateDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]) { return destinationURL != nil || archiveAddress != nil || archiveDestinationURL.flatMap({ state.archiveAddress(for: $0) }) != nil }
        return (destinationURL != nil || archiveDestinationURL != nil || archiveAddress != nil)
            && info.hasItemsConforming(to: [UTType.fileURL.identifier])
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]) {
            let operation = ArchiveDragPolicy.operation(option: NSEvent.modifierFlags.contains(.option), insideArchive: destinationURL == nil)
            return DropProposal(operation: operation == .move ? .move : .copy)
        }
        return DropProposal(operation: archiveDestinationURL != nil || archiveAddress != nil
            ? .copy : BrowserFileDropProposalResolver.operation(for: transferOperation))
    }

    func dropEntered(info: DropInfo) {
        guard validateDrop(info: info) else { return }
        onTargetedChange(true)
    }

    func dropExited(info: DropInfo) {
        onTargetedChange(false)
    }

    func performDrop(info: DropInfo) -> Bool {
        onTargetedChange(false)
        guard validateDrop(info: info) else { return false }
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]), destinationURL == nil,
           let address = archiveAddress ?? archiveDestinationURL.flatMap({ state.archiveAddress(for: $0) }) {
            return state.performArchiveItemDrop(providers: info.itemProviders(for: [ArchiveDragPolicy.type]),
                to: address, moving: !NSEvent.modifierFlags.contains(.option))
        }
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]), let destinationURL {
            let providers = info.itemProviders(for: [ArchiveDragPolicy.type])
            let moving = NSEvent.modifierFlags.contains(.option)
            return state.performArchiveItemDrop(providers: providers, to: destinationURL, moving: moving)
        }
        let providers = info.itemProviders(for: [UTType.fileURL.identifier])
        if archiveDestinationURL != nil || archiveAddress != nil {
            return state.performArchiveDrop(
                providers: providers, to: archiveDestinationURL, address: archiveAddress
            )
        }
        guard let destinationURL else { return false }
        let operation = transferOperation
        return state.performDrop(
            providers: providers,
            to: destinationURL,
            operation: operation
        )
    }

    private var transferOperation: BrowserFileTransferOperation {
        BrowserFileDropOperationResolver.operation(forNativeFlags: NSEvent.modifierFlags)
    }
}

@MainActor
final class BrowserFileDragSession {
    var modifiers: EventModifiers = []
}

nonisolated enum BrowserFileDropOperationResolver {
    static func operation(forNativeFlags flags: NSEvent.ModifierFlags) -> BrowserFileTransferOperation {
        if flags.contains([.option, .command]) { return .alias }
        if flags.contains(.option) { return .copy }
        if flags.contains(.command) { return .move }
        return .automatic
    }
    static func operation(for modifiers: EventModifiers) -> BrowserFileTransferOperation {
        if modifiers.contains([.option, .command]) { return .alias }
        if modifiers.contains(.option) { return .copy }
        if modifiers.contains(.command) { return .move }
        return .automatic
    }
}

nonisolated enum BrowserFileDropProposalResolver {
    static func operation(
        for transferOperation: BrowserFileTransferOperation
    ) -> DropOperation {
        switch transferOperation {
        case .copy: .copy
        case .move: .move
        case .alias: .alias
        // FileOperationService resolves automatic to move on the same volume
        // and copy across volumes. The default drag proposal must not advertise
        // a copy before an explicit copy operation has been requested.
        case .automatic: .move
        }
    }
}

/// Export the location, not a promised file whose URL can point to a temporary copy.
nonisolated struct BrowserDraggedFile: Transferable {
    let url: URL
    var fileURLData: Data { Data(url.absoluteString.utf8) }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .fileURL) { item in item.fileURLData }
    }
}


extension View {
    func browserDraggable(item: BrowserItem, state: FileBrowserState) -> some View {
        Group {
            if item.localURL != nil {
                background { ArchiveDragSource(state: state, item: item).accessibilityHidden(true) }
            } else if case .archive = item.location {
                background { ArchiveDragSource(state: state, item: item).accessibilityHidden(true) }
            } else { self }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("browser-item-" + item.name)
    }

    @ViewBuilder
    func browserDirectoryDropTarget(
        state: FileBrowserState,
        item: BrowserItem,
        dragSession: BrowserFileDragSession
    ) -> some View {
        if item.isDirectory, let destinationURL = item.localURL {
            browserFileDropTarget(
                state: state,
                destinationURL: destinationURL,
                dragSession: dragSession
            )
        } else if item.isArchive, let archiveURL = item.localURL,
                  ArchiveFormatRegistry.supportsUpdating(item.name) {
            modifier(BrowserArchiveDropTargetModifier(
                state: state, archiveURL: archiveURL, address: nil,
                dragSession: dragSession
            ))
        } else if item.isDirectory, case let .archive(address) = item.location,
                  address.nestedArchiveDepth == 0 {
            modifier(BrowserArchiveDropTargetModifier(
                state: state, archiveURL: nil, address: address,
                dragSession: dragSession
            ))
        } else {
            self
        }
    }

    @ViewBuilder
    func browserColumnRootDropTarget(
        state: FileBrowserState,
        location: BrowserLocation,
        dragSession: BrowserFileDragSession,
        isTargeted: Binding<Bool>
    ) -> some View {
        if location.fileSystemURL != nil || location.archiveDropAddress != nil {
            onDrop(
                of: [UTType.fileURL.identifier, ArchiveDragPolicy.type],
                delegate: BrowserFileDropDelegate(
                    state: state,
                    destinationURL: location.fileSystemURL,
                    dragSession: dragSession,
                    archiveAddress: location.archiveDropAddress,
                    onTargetedChange: { targeted in
                        isTargeted.wrappedValue = targeted
                    }
                )
            )
            .overlay {
                ArchiveDropDestination(directory: location.fileSystemURL, address: location.archiveDropAddress,
                    onTargetedChange: { isTargeted.wrappedValue = $0 }).accessibilityHidden(true)
            }
            .dropPreviewsFormation(state.viewMode.fileDragPreviewsFormation)
        } else {
            self
        }
    }

    func browserFileDropTarget(
        state: FileBrowserState,
        destinationURL: URL,
        dragSession: BrowserFileDragSession
    ) -> some View {
        modifier(
            BrowserFileDropTargetModifier(
                state: state,
                destinationURL: destinationURL,
                dragSession: dragSession
            )
        )
    }

    func finderClickGesture(
        onSingleClick: @escaping (NSEvent.ModifierFlags) -> Void,
        onDoubleClick: @escaping (NSEvent.ModifierFlags) -> Void
    ) -> some View {
        modifier(FinderClickGestureModifier(onSingleClick: onSingleClick, onDoubleClick: onDoubleClick))
    }
}

private struct BrowserArchiveDropTargetModifier: ViewModifier {
    let state: FileBrowserState
    let archiveURL: URL?
    let address: ArchiveAddress?
    let dragSession: BrowserFileDragSession
    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.fileURL.identifier, ArchiveDragPolicy.type], delegate: BrowserFileDropDelegate(
                state: state, destinationURL: nil, dragSession: dragSession,
                archiveDestinationURL: archiveURL, archiveAddress: address,
                onTargetedChange: { isTargeted = $0 }
            ))
            .overlay { if isTargeted { BrowserFileDropHighlight() } }
            .overlay {
                if let target = address ?? archiveURL.flatMap({ state.archiveAddress(for: $0) }) {
                    ArchiveDropDestination(address: target, onTargetedChange: { isTargeted = $0 }).accessibilityHidden(true)
                }
            }
            .onDisappear { isTargeted = false }
    }
}

private struct BrowserFileDropTargetModifier: ViewModifier {
    let state: FileBrowserState
    let destinationURL: URL
    let dragSession: BrowserFileDragSession
    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .environment(\.browserDropTargetURL, isTargeted ? destinationURL : nil)
            .onDrop(
                of: [UTType.fileURL.identifier, ArchiveDragPolicy.type],
                delegate: BrowserFileDropDelegate(
                    state: state,
                    destinationURL: destinationURL,
                    dragSession: dragSession,
                    onTargetedChange: { targeted in
                        isTargeted = targeted
                    }
                )
            )
            .dropPreviewsFormation(state.viewMode.fileDragPreviewsFormation)
            .overlay {
                if isTargeted {
                    BrowserFileDropHighlight()
                }
            }
            .overlay {
                ArchiveDropDestination(directory: destinationURL, onTargetedChange: { isTargeted = $0 })
                    .accessibilityHidden(true)
            }
            .animation(.easeOut(duration: 0.12), value: isTargeted)
            .onDisappear { isTargeted = false }
    }
}

private extension BrowserViewMode {
    var fileDragPreviewsFormation: DragDropPreviewsFormation {
        switch self {
        case .list, .columns:
            .list
        case .icons, .gallery:
            .default
        }
    }
}

struct BrowserFileDropHighlight: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.14))
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
}
