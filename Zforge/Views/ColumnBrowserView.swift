import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ColumnBrowserView: View {
    @Bindable var state: FileBrowserState
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
    @State private var terminalScrollTask: Task<Void, Never>?
    @State private var previewSize: ColumnPreviewSize?
    @State private var expandedPreviewParents: Set<BrowserLocation> = []
    @State private var columnRootLocation: BrowserLocation?
    @State private var horizontalScrollPhase: ScrollPhase = .idle
    @State private var distanceFromTrailingEdge: CGFloat = 0
    @State private var userScrolledAwayFromTrailingEdge = false

    private var scale: CGFloat { state.preferences.scale }
    private var regularColumnWidth: CGFloat { state.preferences.finderColumnWidth * scale }

    private struct ColumnPreviewSize {
        let itemIDs: [BrowserItemID]
        let width: CGFloat
    }

    private var previewItems: [BrowserItem] {
        let selectedItems = state.previewItems
        guard !selectedItems.isEmpty else { return [] }
        if selectedItems.count > 1 { return selectedItems }
        guard !selectedItems[0].isNavigableContainer else { return [] }
        if selectedItems[0].usesStaticIconPreview { return selectedItems }
        guard state.previewURL != nil || state.previewRequiresManualLoad else { return [] }
        return selectedItems
    }

    private var activeColumnIndex: Int {
        state.pathComponents.firstIndex(where: {
            $0.location == (state.activeColumnLocation ?? state.location)
        }) ?? max(state.pathComponents.count - 1, 0)
    }

    private var visibleComponents: [(offset: Int, element: BrowserPathComponent)] {
        Array(state.pathComponents.enumerated().prefix(activeColumnIndex + 2))
    }

    private var hasNextColumn: Bool {
        activeColumnIndex + 1 < state.pathComponents.count
    }

    private var previewItemIDs: [BrowserItemID] {
        guard state.previewVisible && !hasNextColumn else { return [] }
        return previewItems.map(\.id)
    }

    private var isAwaitingTerminalColumn: Bool {
        guard state.previewVisible && !hasNextColumn,
              let pendingID = state.pendingColumnExpansionItemID,
              let activeLocation = state.activeColumnLocation ?? state.pathComponents.last?.location
        else { return false }
        return state.columnSelections[activeLocation] == pendingID
    }

    private var isAwaitingAnchoredPreview: Bool {
        guard state.previewVisible && !hasNextColumn && previewItemIDs.isEmpty,
              let activeLocation = state.activeColumnLocation ?? state.pathComponents.last?.location,
              expandedPreviewParents.contains(activeLocation),
              let item = state.primarySelection,
              !item.isNavigableContainer
        else { return false }
        return state.columnSelections[activeLocation] == item.id
    }

    private var shouldKeepUserScrollPosition: Bool {
        userScrolledAwayFromTrailingEdge
            && state.pendingColumnExpansionItemID == nil
            && state.primarySelection?.isNavigableContainer != true
    }

    private var isUserScrollPhase: Bool {
        horizontalScrollPhase == .tracking
            || horizontalScrollPhase == .interacting
            || horizontalScrollPhase == .decelerating
    }

    private func terminalColumnWidth(availableWidth: CGFloat, precedingCount: Int) -> CGFloat {
        BrowserColumnsLayout.terminalColumnWidth(
            availableWidth: availableWidth,
            precedingColumnCount: precedingCount,
            columnWidth: regularColumnWidth,
            minimumWidth: state.previewVisible ? BrowserColumnsLayout.minimumPreviewWidth : 0
        )
    }

    private func initialPreviewWidth(availableWidth: CGFloat) -> CGFloat {
        if !userScrolledAwayFromTrailingEdge,
           let parentLocation = visibleComponents.last?.element.location,
           expandedPreviewParents.contains(parentLocation) {
            return terminalColumnWidth(
                availableWidth: availableWidth,
                precedingCount: visibleComponents.count
            )
        }
        return BrowserColumnsLayout.initialPreviewWidth(
            availableWidth: availableWidth,
            columnCount: visibleComponents.count,
            columnWidth: regularColumnWidth
        )
    }

    private func previewWidth(availableWidth: CGFloat) -> CGFloat {
        if let previewSize, previewSize.itemIDs == previewItemIDs {
            return max(BrowserColumnsLayout.minimumPreviewWidth, previewSize.width * scale)
        }
        return initialPreviewWidth(availableWidth: availableWidth)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            GeometryReader { geometry in
                let currentPreviewWidth = previewWidth(availableWidth: geometry.size.width)
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(visibleComponents, id: \.element.id) { index, component in
                            FinderColumn(
                                state: state,
                                component: component,
                                items: state.columnItems[component.location] != nil
                                    ? state.sortedColumnItems(at: component.location)
                                    : (component.location == state.location ? state.sortedItems : []),
                                isActive: component.location == (state.activeColumnLocation ?? state.location),
                                selectedID: state.columnSelections[component.location],
                                scale: scale,
                                width: state.previewVisible && previewItemIDs.isEmpty
                                    && index == visibleComponents.count - 1
                                    && index > 0
                                    ? terminalColumnWidth(
                                        availableWidth: geometry.size.width,
                                        precedingCount: index
                                    )
                                    : regularColumnWidth,
                                contentFocus: contentFocus,
                                dragSession: dragSession
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("browser-column-\(index)")
                            .id("column-\(index)")
                        }

                        if isAwaitingTerminalColumn {
                            Color.clear
                                .frame(width: terminalColumnWidth(
                                    availableWidth: geometry.size.width,
                                    precedingCount: visibleComponents.count
                                ))
                                .id("column-pending-slot")
                        }

                        if isAwaitingAnchoredPreview {
                            Color.clear
                                .frame(width: initialPreviewWidth(availableWidth: geometry.size.width))
                                .id("preview-pending-slot")
                        }

                        if !previewItemIDs.isEmpty {
                            SelectionOverview(
                                state: state,
                                items: previewItems,
                                presentation: .column,
                                scale: scale
                            )
                            .frame(width: currentPreviewWidth)
                            .frame(maxHeight: .infinity)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("column-preview")
                            .overlay(alignment: .leading) {
                                Rectangle().fill(.separator).frame(width: 1)
                            }
                            .overlay(alignment: .leading) {
                                BrowserColumnResizeHandle(
                                    currentWidth: currentPreviewWidth / scale,
                                    scale: scale,
                                    direction: -1,
                                    isPreview: true
                                ) { width in
                                    previewSize = ColumnPreviewSize(
                                        itemIDs: previewItemIDs,
                                        width: max(
                                            width,
                                            BrowserColumnsLayout.minimumPreviewWidth / scale
                                        )
                                    )
                                }
                                .frame(width: 20 * scale)
                                .help("Drag to resize preview")
                            }
                            .id("column-terminal-slot")
                        }

                        Color.clear.frame(width: 1, height: 1).id("columns-end")
                    }
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height,
                        alignment: .topLeading
                    )
                    .background {
                        Color.clear.contentShape(Rectangle()).onTapGesture { state.clearSelection() }
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { scrollGeometry in
                    max(
                        0,
                        scrollGeometry.contentSize.width
                            - scrollGeometry.containerSize.width
                            - scrollGeometry.contentOffset.x
                    )
                } action: { _, distance in
                    distanceFromTrailingEdge = distance
                    if isUserScrollPhase {
                        userScrolledAwayFromTrailingEdge = distance > 2
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    horizontalScrollPhase = newPhase
                    if newPhase == .idle,
                       oldPhase == .tracking || oldPhase == .interacting || oldPhase == .decelerating {
                        userScrolledAwayFromTrailingEdge = distanceFromTrailingEdge > 2
                    }
                }
                .onAppear {
                    rememberExpandedColumns()
                    scheduleTerminalScroll(scrollProxy)
                }
                .onChange(of: state.pathComponents) { _, _ in
                    rememberExpandedColumns()
                    if !shouldKeepUserScrollPosition {
                        scheduleTerminalScroll(scrollProxy, animationDuration: 0.25)
                    }
                }
                .onChange(of: state.selection) { _, selection in
                    guard !selection.isEmpty else { return }
                    if !shouldKeepUserScrollPosition {
                        scheduleTerminalScroll(scrollProxy, animationDuration: 0.2)
                    }
                }
                .onChange(of: state.activeColumnLocation) { _, location in
                    guard location != nil else { return }
                    if !shouldKeepUserScrollPosition {
                        scheduleTerminalScroll(scrollProxy, animationDuration: 0.15)
                    }
                }
                .onChange(of: state.previewVisible) { _, _ in
                    scheduleTerminalScroll(scrollProxy, animationDuration: 0.2)
                }
                .onChange(of: previewItemIDs, initial: true) { _, itemIDs in
                    if itemIDs.isEmpty {
                        previewSize = nil
                    } else {
                        previewSize = ColumnPreviewSize(
                            itemIDs: itemIDs,
                            width: initialPreviewWidth(availableWidth: geometry.size.width) / scale
                        )
                        if !shouldKeepUserScrollPosition {
                            scheduleTerminalScroll(scrollProxy)
                        }
                    }
                }
                .onDisappear {
                    terminalScrollTask?.cancel()
                    terminalScrollTask = nil
                }
            }
        }
    }

    private func rememberExpandedColumns() {
        guard let rootLocation = state.pathComponents.first?.location else { return }
        if columnRootLocation != rootLocation {
            expandedPreviewParents.removeAll()
            columnRootLocation = rootLocation
            userScrolledAwayFromTrailingEdge = false
        }
        expandedPreviewParents.formUnion(state.pathComponents.dropLast().map(\.location))
    }

    private func scheduleTerminalScroll(
        _ proxy: ScrollViewProxy,
        animationDuration: Double? = nil
    ) {
        terminalScrollTask?.cancel()
        userScrolledAwayFromTrailingEdge = false
        terminalScrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            if let animationDuration {
                withAnimation(.easeOut(duration: animationDuration)) {
                    proxy.scrollTo("columns-end", anchor: .trailing)
                }
            } else {
                proxy.scrollTo("columns-end", anchor: .trailing)
            }
            terminalScrollTask = nil
        }
    }
}

private struct FinderColumn: View {
    @Bindable var state: FileBrowserState
    let component: BrowserPathComponent
    let items: [BrowserItem]
    let isActive: Bool
    let selectedID: BrowserItemID?
    let scale: CGFloat
    let width: CGFloat
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
    @State private var isRootDropTargeted = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            let activeSelection = isActive && state.selection.contains(item.id)
                            HStack(spacing: 0) {
                                Label {
                                    BrowserItemNameView(
                                        state: state,
                                        item: item,
                                        contentFocus: contentFocus
                                    )
                                } icon: {
                                    FileIconView(item: item, size: BrowserMetrics.iconSize * scale)
                                }
                                Spacer(minLength: 4)
                                if item.isNavigableContainer {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11 * scale, weight: .semibold))
                                        .frame(width: BrowserMetrics.disclosureWidth * scale)
                                }
                            }
                            .browserItemEmphasis(
                                item,
                                isSelected: activeSelection || item.id == selectedID
                            )
                            .frame(
                                maxWidth: .infinity,
                                minHeight: BrowserMetrics.rowHeight * scale,
                                maxHeight: BrowserMetrics.rowHeight * scale,
                                alignment: .leading
                            )
                            .contentShape(Rectangle())
                            .font(.system(size: 13 * scale))
                            .foregroundStyle(activeSelection ? .white : .primary)
                            .padding(.horizontal, BrowserMetrics.rowContentInset * scale)
                            .background {
                                RoundedRectangle(cornerRadius: BrowserMetrics.rowCornerRadius * scale)
                                    .fill(rowBackground(item, activeSelection: activeSelection))
                            }
                            .padding(.horizontal, BrowserMetrics.horizontalInset * scale)
                            .finderClickGesture(
                                onSingleClick: {
                                    state.activateColumnItem(
                                        item,
                                        in: component.location,
                                        modifiers: NSEvent.modifierFlags
                                    )
                                },
                                onDoubleClick: {
                                    let modifiers = NSEvent.modifierFlags
                                    if modifiers.contains(.command), item.isContainer, item.localURL != nil {
                                        state.openInNewWindow(item)
                                    } else if !item.isNavigableContainer {
                                        Task { await state.open(item) }
                                    }
                                }
                            )
                            .browserDraggable(item: item)
                            .browserDirectoryDropTarget(
                                state: state,
                                item: item,
                                dragSession: dragSession
                            )
                            .browserItemContextMenu(state: state, item: item)
                        }
                    }

                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: columnRootDropAreaHeight(in: geometry.size.height))
                        .contentShape(Rectangle())
                        .onTapGesture { state.clearSelection() }
                        .browserColumnRootDropTarget(
                            state: state,
                            location: component.location,
                            dragSession: dragSession,
                            isTargeted: $isRootDropTargeted
                        )
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .topLeading)
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay {
            if isRootDropTargeted {
                BrowserFileDropHighlight()
            }
        }
        .overlay(alignment: .trailing) { Divider() }
        .overlay(alignment: .trailing) {
            BrowserColumnResizeHandle(
                currentWidth: state.preferences.finderColumnWidth,
                scale: scale
            ) { width in
                state.preferences.setFinderColumnWidth(width)
            }
                .frame(width: 20 * scale)
                .help("Drag to resize column")
        }
        .animation(.easeOut(duration: 0.12), value: isRootDropTargeted)
        .onDisappear { isRootDropTargeted = false }
    }

    private func rowBackground(_ item: BrowserItem, activeSelection: Bool) -> Color {
        if activeSelection { return BrowserMetrics.selectionColor }
        if item.id == selectedID { return .gray.opacity(0.28) }
        return .clear
    }

    private func columnRootDropAreaHeight(in visibleHeight: CGFloat) -> CGFloat {
        let rowsHeight = CGFloat(items.count) * BrowserMetrics.rowHeight * scale
        return max(visibleHeight - rowsHeight, 0)
    }
}
