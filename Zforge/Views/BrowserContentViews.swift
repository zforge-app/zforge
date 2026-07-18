import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum BrowserMetrics {
    static let selectionColor = Color(nsColor: .selectedContentBackgroundColor)
    static let finderColumnWidth: CGFloat = 260
    static let iconGridItemWidth: CGFloat = 110
    static let iconGridSpacing: CGFloat = 24
    static let iconGridPadding: CGFloat = 16
    static let rowHeight: CGFloat = 24
    static let iconSize: CGFloat = 16
    static let horizontalInset: CGFloat = 8
    static let rowContentInset: CGFloat = 4
    static let columnContentInset: CGFloat = 6
    static let disclosureWidth: CGFloat = 18
    static let rowCornerRadius: CGFloat = 7
}

enum BrowserListLayout {
    static let minimumNameColumnWidth: CGFloat = 168
    static let modificationDateColumnWidth: CGFloat = 180
    static let sizeColumnWidth: CGFloat = 90
    static let kindColumnWidth: CGFloat = 150

    static func minimumTableWidth(scale: CGFloat) -> CGFloat {
        let columnWidth = minimumNameColumnWidth
            + modificationDateColumnWidth
            + sizeColumnWidth
            + kindColumnWidth
        let horizontalChrome = 2 * (BrowserMetrics.horizontalInset + BrowserMetrics.rowContentInset)
        return (columnWidth + horizontalChrome) * scale
    }

    static func tableWidth(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat = 0,
        scale: CGFloat
    ) -> CGFloat {
        let visibleWidth = max(availableWidth - max(obscuredTrailingWidth, 0), 0)
        return max(visibleWidth, minimumTableWidth(scale: scale))
    }

    static func scrollContentWidth(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat,
        scale: CGFloat
    ) -> CGFloat {
        tableWidth(
            availableWidth: availableWidth,
            obscuredTrailingWidth: obscuredTrailingWidth,
            scale: scale
        ) + max(obscuredTrailingWidth, 0)
    }

    static func requiresHorizontalScrolling(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat,
        scale: CGFloat
    ) -> Bool {
        scrollContentWidth(
            availableWidth: availableWidth,
            obscuredTrailingWidth: obscuredTrailingWidth,
            scale: scale
        ) > availableWidth
    }
}

struct BrowserContent: View {
    @Bindable var state: FileBrowserState
    let contentFocus: FocusState<Bool>.Binding
    @State private var contentWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch state.preferences.viewMode {
                case .icons:
                    contentWithOptionalPreview { IconBrowserView(state: state) }
                case .list:
                    listWithOptionalPreview
                case .columns: ColumnBrowserView(state: state)
                case .gallery: GalleryBrowserView(state: state)
                }
            }
            .onAppear { updateContentWidth(geometry.size.width) }
            .onChange(of: geometry.size.width) { _, width in updateContentWidth(width) }
            .onChange(of: state.previewVisible) { _, _ in updateContentWidth(geometry.size.width) }
            .onChange(of: state.preferences.viewMode) { _, _ in updateContentWidth(geometry.size.width) }
            .onChange(of: state.preferences.scale) { _, _ in updateContentWidth(geometry.size.width) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
        .accessibilityIdentifier("browser-mode-\(state.preferences.viewMode.rawValue)")
        .focusable()
        .focused(contentFocus)
        .focusEffectDisabled()
        .onMoveCommand(perform: handleMoveCommand)
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
            }
        }
    }

    private var listWithOptionalPreview: some View {
        let previewWidth = state.previewVisible
            ? BrowserLayoutMetrics.previewWidth * state.preferences.scale
            : 0

        return ZStack(alignment: .trailing) {
            ListBrowserView(
                state: state,
                obscuredTrailingWidth: previewWidth
            )

            if state.previewVisible {
                BrowserPreviewPane(state: state)
                    .background(.ultraThinMaterial)
                    .zIndex(1)
            }
        }
    }

    private func updateContentWidth(_ totalWidth: CGFloat) {
        let hasSidePreview = state.previewVisible
            && state.preferences.viewMode == .icons
        contentWidth = max(
            totalWidth - (hasSidePreview ? BrowserLayoutMetrics.previewWidth * state.preferences.scale : 0),
            1
        )
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        let extending = NSEvent.modifierFlags.contains(.shift)
        switch state.preferences.viewMode {
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
        let visibleItems = state.flattenedList().map(\.item)
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

            let items = state.preferences.sort.sorted(state.columnItems[activeLocation] ?? [])
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
            let items = state.preferences.sort.sorted(state.columnItems[activeLocation] ?? [])
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
        let items = state.preferences.sort.sorted(state.columnItems[location] ?? [])
        let selectedItem = state.columnSelections[location].flatMap { selectedID in
            items.first(where: { $0.id == selectedID })
        } ?? (selectsFirstItemWhenNeeded ? items.first : nil)

        guard !selectsFirstItemWhenNeeded || selectedItem != nil else { return }

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

    var body: some View {
        if state.previewItems.isEmpty {
            Color.clear
                .frame(width: BrowserLayoutMetrics.previewWidth * scale)
                .frame(maxHeight: .infinity)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.separator).frame(width: 1)
                }
        } else {
            SelectionOverview(
                state: state,
                items: state.previewItems,
                presentation: .column,
                scale: scale
            )
        }
    }
}

struct IconBrowserView: View {
    @Bindable var state: FileBrowserState
    @State private var focusedScrollTask: Task<Void, Never>?

    private var scale: CGFloat { state.preferences.scale }
    private var itemWidth: CGFloat { BrowserMetrics.iconGridItemWidth * scale }
    private var itemSpacing: CGFloat { BrowserMetrics.iconGridSpacing * scale }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { state.clearSelection() }

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: itemWidth), spacing: itemSpacing)],
                            spacing: itemSpacing
                        ) {
                            ForEach(state.sortedItems) { item in
                                BrowserIconCell(
                                    item: item,
                                    isSelected: state.selection.contains(item.id),
                                    scale: scale
                                )
                                .id(item.id)
                                .finderClickGesture(
                                    onSingleClick: { state.select(item, modifiers: NSEvent.modifierFlags) },
                                    onDoubleClick: { Task { await state.open(item) } }
                                )
                                .contextMenu { BrowserItemActionsMenu(state: state, item: item) }
                            }
                        }
                        .padding(BrowserMetrics.iconGridPadding * scale)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: .topLeading
                    )
                }
                .onChange(of: state.focusedItemID) { _, itemID in
                    guard let itemID else { return }
                    scheduleFocusedScroll(to: itemID, proxy: scrollProxy)
                }
            }
        }
        .onDisappear {
            focusedScrollTask?.cancel()
            focusedScrollTask = nil
        }
    }

    private func scheduleFocusedScroll(to itemID: BrowserItemID, proxy: ScrollViewProxy) {
        focusedScrollTask?.cancel()
        focusedScrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, state.focusedItemID == itemID else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(itemID, anchor: .center)
            }
            focusedScrollTask = nil
        }
    }
}

private struct BrowserIconCell: View {
    let item: BrowserItem
    let isSelected: Bool
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 8 * scale) {
            FileIconView(item: item, size: 64 * scale)
                .frame(width: 84 * scale, height: 72 * scale)
                .background {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(isSelected ? Color.primary.opacity(0.12) : .clear)
                }

            Text(item.name)
                .font(.system(size: 13 * scale))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 5 * scale)
                .padding(.vertical, 2 * scale)
                .background {
                    RoundedRectangle(cornerRadius: 5 * scale)
                        .fill(isSelected ? BrowserMetrics.selectionColor : .clear)
                }
        }
        .frame(maxWidth: .infinity, minHeight: 90 * scale)
        .padding(8 * scale)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct ListBrowserView: View {
    @Bindable var state: FileBrowserState
    let obscuredTrailingWidth: CGFloat
    @State private var focusedScrollTask: Task<Void, Never>?

    private var scale: CGFloat { state.preferences.scale }

    var body: some View {
        GeometryReader { geometry in
            let tableWidth = BrowserListLayout.tableWidth(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale
            )
            let scrollContentWidth = BrowserListLayout.scrollContentWidth(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale
            )
            let usesEdgeToEdgeRows = BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale
            )

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    listTable(
                        width: tableWidth,
                        height: geometry.size.height,
                        usesEdgeToEdgeRows: usesEdgeToEdgeRows
                    )

                    Color.clear
                        .frame(width: obscuredTrailingWidth, height: 1)
                }
                .frame(
                    width: scrollContentWidth,
                    height: geometry.size.height,
                    alignment: .topLeading
                )
            }
        }
        .onDisappear {
            focusedScrollTask?.cancel()
            focusedScrollTask = nil
        }
    }

    private func listTable(
        width: CGFloat,
        height: CGFloat,
        usesEdgeToEdgeRows: Bool
    ) -> some View {
        VStack(spacing: 0) {
            ListHeader(state: state, scale: scale)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    BrowserListRows(
                        state: state,
                        scale: scale,
                        width: width,
                        minimumHeight: max(height - (28 * scale), 1),
                        usesEdgeToEdgeRows: usesEdgeToEdgeRows
                    )
                }
                .onChange(of: state.focusedItemID) { _, itemID in
                    guard let itemID else { return }
                    scheduleFocusedScroll(to: itemID, proxy: scrollProxy)
                }
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    private func scheduleFocusedScroll(to itemID: BrowserItemID, proxy: ScrollViewProxy) {
        focusedScrollTask?.cancel()
        focusedScrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, state.focusedItemID == itemID else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(itemID, anchor: .center)
            }
            focusedScrollTask = nil
        }
    }
}

private struct BrowserListRows: View {
    @Bindable var state: FileBrowserState
    let scale: CGFloat
    let width: CGFloat
    let minimumHeight: CGFloat
    let usesEdgeToEdgeRows: Bool

    private var horizontalMargin: CGFloat {
        usesEdgeToEdgeRows ? 0 : BrowserMetrics.horizontalInset * scale
    }

    private var rowAreaWidth: CGFloat {
        max(width - (horizontalMargin * 2), 1)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { state.clearSelection() }

            LazyVStack(spacing: 0) {
                ForEach(Array(state.flattenedList().enumerated()), id: \.element.id) { index, entry in
                    BrowserListRow(
                        state: state,
                        entry: entry,
                        index: index,
                        scale: scale,
                        usesEdgeToEdgeBackground: usesEdgeToEdgeRows
                    )
                    .id(entry.id)
                    .contextMenu { BrowserItemActionsMenu(state: state, item: entry.item) }
                }
            }
        }
        .frame(width: rowAreaWidth, alignment: .topLeading)
        .frame(minHeight: minimumHeight, alignment: .topLeading)
        .frame(width: width, alignment: .center)
    }
}

private struct ListHeader: View {
    @Bindable var state: FileBrowserState
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            headerButton("Name", field: .name, showsTrailingSeparator: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            headerButton("Date Modified", field: .modificationDate, showsTrailingSeparator: true)
                .frame(width: BrowserListLayout.modificationDateColumnWidth * scale, alignment: .leading)
            headerButton("Size", field: .size, showsTrailingSeparator: true)
                .frame(width: BrowserListLayout.sizeColumnWidth * scale, alignment: .leading)
            headerButton("Kind", field: .kind)
                .frame(width: BrowserListLayout.kindColumnWidth * scale, alignment: .leading)
        }
        .font(.system(size: 11 * scale, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(height: 28 * scale)
        .padding(
            .horizontal,
            (BrowserMetrics.horizontalInset + BrowserMetrics.rowContentInset) * scale
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.separator)
                .frame(height: 1)
        }
    }

    private func headerButton(
        _ title: LocalizedStringKey,
        field: BrowserSortField,
        leadingInset: CGFloat = BrowserMetrics.columnContentInset,
        showsTrailingSeparator: Bool = false
    ) -> some View {
        Button {
            state.setSort(field)
        } label: {
            HStack(spacing: 4 * scale) {
                Text(title)
                if state.preferences.sort.field == field {
                    Image(systemName: state.preferences.sort.ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8 * scale, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, leadingInset * scale)
            .padding(.trailing, BrowserMetrics.columnContentInset * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .overlay(alignment: .trailing) {
            if showsTrailingSeparator {
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1)
            }
        }
    }
}

private struct BrowserListRow: View {
    @Bindable var state: FileBrowserState
    let entry: VisibleBrowserItem
    let index: Int
    let scale: CGFloat
    let usesEdgeToEdgeBackground: Bool

    private var isSelected: Bool { state.selection.contains(entry.item.id) }
    private var horizontalContentInset: CGFloat {
        let inset = BrowserMetrics.rowContentInset
            + (usesEdgeToEdgeBackground ? BrowserMetrics.horizontalInset : 0)
        return inset * scale
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: CGFloat(entry.depth * 20) * scale)
                if entry.item.canExpandInlineInList {
                    Button {
                        Task { await state.toggleExpansion(entry.item) }
                    } label: {
                        Group {
                            if state.expandingItems.contains(entry.item.id) {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: entry.isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 11 * scale, weight: .semibold))
                            }
                        }
                        .frame(
                            width: BrowserMetrics.disclosureWidth * scale,
                            height: BrowserMetrics.rowHeight * scale
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                } else {
                    Color.clear.frame(width: BrowserMetrics.disclosureWidth * scale)
                }
            }

            HStack(spacing: 0) {
                Label {
                    Text(entry.item.name).lineLimit(1)
                } icon: {
                    FileIconView(item: entry.item, size: BrowserMetrics.iconSize * scale)
                }
                .tint(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(entry.item.formattedDate(entry.item.modificationDate, locale: .current))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(
                        width: BrowserListLayout.modificationDateColumnWidth * scale,
                        alignment: .leading
                    )

                Text(entry.item.formattedSize)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(width: BrowserListLayout.sizeColumnWidth * scale, alignment: .leading)

                Text(entry.item.displayKind)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(width: BrowserListLayout.kindColumnWidth * scale, alignment: .leading)
            }
            .contentShape(Rectangle())
            .finderClickGesture(
                onSingleClick: {
                    state.select(
                        entry.item,
                        modifiers: NSEvent.modifierFlags,
                        orderedItems: state.flattenedList().map(\.item)
                    )
                },
                onDoubleClick: { Task { await state.open(entry.item) } }
            )
        }
        .font(.system(size: 13 * scale))
        .frame(
            maxWidth: .infinity,
            minHeight: BrowserMetrics.rowHeight * scale,
            maxHeight: BrowserMetrics.rowHeight * scale,
            alignment: .leading
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .contentShape(Rectangle())
        .padding(.horizontal, horizontalContentInset)
        .background {
            RoundedRectangle(
                cornerRadius: usesEdgeToEdgeBackground
                    ? 0
                    : BrowserMetrics.rowCornerRadius * scale
            )
                .fill(
                    isSelected
                        ? BrowserMetrics.selectionColor
                        : (index.isMultiple(of: 2) ? .clear : Color.primary.opacity(0.06))
                )
        }
    }
}

struct ColumnBrowserView: View {
    @Bindable var state: FileBrowserState
    @State private var terminalScrollTask: Task<Void, Never>?

    private var scale: CGFloat { state.preferences.scale }
    private var previewWidth: CGFloat { BrowserLayoutMetrics.previewWidth * scale }

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

    var body: some View {
        ScrollViewReader { scrollProxy in
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(visibleComponents, id: \.element.id) { index, component in
                            FinderColumn(
                                state: state,
                                component: component,
                                items: state.preferences.sort.sorted(
                                    state.columnItems[component.location]
                                        ?? (component.location == state.location ? state.sortedItems : [])
                                ),
                                isActive: component.location == (state.activeColumnLocation ?? state.location),
                                selectedID: state.columnSelections[component.location],
                                scale: scale,
                                width: state.previewVisible && index == activeColumnIndex + 1
                                    ? previewWidth
                                    : BrowserMetrics.finderColumnWidth * scale
                            )
                            .id("column-\(index)")
                        }

                        if state.previewVisible && !hasNextColumn {
                            Group {
                                if !previewItems.isEmpty {
                                    SelectionOverview(
                                        state: state,
                                        items: previewItems,
                                        presentation: .column,
                                        scale: scale
                                    )
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(width: previewWidth)
                            .frame(maxHeight: .infinity)
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
                .onAppear { scheduleTerminalScroll(scrollProxy) }
                .onChange(of: state.pathComponents) { _, _ in
                    scheduleTerminalScroll(scrollProxy, animationDuration: 0.25)
                }
                .onChange(of: state.selection) { _, selection in
                    guard !selection.isEmpty else { return }
                    scheduleTerminalScroll(scrollProxy, animationDuration: 0.2)
                }
                .onChange(of: state.activeColumnLocation) { _, location in
                    guard location != nil else { return }
                    scheduleTerminalScroll(scrollProxy, animationDuration: 0.15)
                }
                .onChange(of: state.previewVisible) { _, _ in
                    scheduleTerminalScroll(scrollProxy, animationDuration: 0.2)
                }
                .onDisappear {
                    terminalScrollTask?.cancel()
                    terminalScrollTask = nil
                }
            }
        }
    }

    private func scheduleTerminalScroll(
        _ proxy: ScrollViewProxy,
        animationDuration: Double? = nil
    ) {
        terminalScrollTask?.cancel()
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

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    Color.clear.contentShape(Rectangle()).onTapGesture { state.clearSelection() }
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            let activeSelection = isActive && state.selection.contains(item.id)
                            HStack(spacing: 0) {
                                Label {
                                    Text(item.name).lineLimit(1)
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
                                    if !item.isNavigableContainer { Task { await state.open(item) } }
                                }
                            )
                            .contextMenu { BrowserItemActionsMenu(state: state, item: item) }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .topLeading)
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .trailing) { Divider() }
    }

    private func rowBackground(_ item: BrowserItem, activeSelection: Bool) -> Color {
        if activeSelection { return BrowserMetrics.selectionColor }
        if item.id == selectedID { return .gray.opacity(0.28) }
        return .clear
    }
}

struct GalleryBrowserView: View {
    @Bindable var state: FileBrowserState
    @State private var initialSelectionTask: Task<Void, Never>?
    @State private var thumbnailScrollTask: Task<Void, Never>?

    private var scale: CGFloat { state.preferences.scale }

    var body: some View {
        VStack(spacing: 0) {
            if state.previewItems.isEmpty {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { state.clearSelection() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SelectionOverview(
                    state: state,
                    items: state.previewItems,
                    presentation: .gallery,
                    scale: scale
                )
            }

            Divider()

            ScrollViewReader { scrollProxy in
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .leading) {
                            Color.clear.contentShape(Rectangle()).onTapGesture { state.clearSelection() }
                            LazyHStack(spacing: 8 * scale) {
                                ForEach(state.sortedItems) { item in
                                    let isSelected = state.selection.contains(item.id)
                                    VStack(spacing: 5 * scale) {
                                        FileIconView(item: item, size: 44 * scale)
                                        Text(item.name)
                                            .font(.system(size: 11 * scale))
                                            .lineLimit(1)
                                    }
                                    .frame(width: 96 * scale, height: 72 * scale)
                                    .contentShape(Rectangle())
                                    .background {
                                        RoundedRectangle(cornerRadius: 8 * scale)
                                            .fill(isSelected ? Color.primary.opacity(0.12) : .clear)
                                    }
                                    .id(item.id)
                                    .finderClickGesture(
                                        onSingleClick: { state.select(item, modifiers: NSEvent.modifierFlags) },
                                        onDoubleClick: { Task { await state.open(item) } }
                                    )
                                    .contextMenu { BrowserItemActionsMenu(state: state, item: item) }
                                }
                            }
                            .padding(10 * scale)
                        }
                        .frame(
                            minWidth: geometry.size.width,
                            minHeight: geometry.size.height,
                            alignment: .leading
                        )
                    }
                    .onChange(of: state.focusedItemID) { _, itemID in
                        guard let itemID else { return }
                        scheduleThumbnailScroll(to: itemID, proxy: scrollProxy)
                    }
                }
            }
            .frame(height: 96 * scale)
        }
        .task { scheduleInitialSelection() }
        .onChange(of: state.location) { _, _ in scheduleInitialSelection() }
        .onChange(of: state.sortedItems.map(\.id)) { _, _ in scheduleInitialSelection() }
        .onDisappear {
            initialSelectionTask?.cancel()
            thumbnailScrollTask?.cancel()
            initialSelectionTask = nil
            thumbnailScrollTask = nil
        }
    }

    private func scheduleInitialSelection() {
        initialSelectionTask?.cancel()
        initialSelectionTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            if state.selection.isEmpty, let first = state.sortedItems.first {
                state.select(first)
            }
            initialSelectionTask = nil
        }
    }

    private func scheduleThumbnailScroll(to itemID: BrowserItemID, proxy: ScrollViewProxy) {
        thumbnailScrollTask?.cancel()
        thumbnailScrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled,
                  state.focusedItemID == itemID else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(itemID, anchor: .center)
            }
            thumbnailScrollTask = nil
        }
    }
}

private struct BrowserItemActionsMenu: View {
    @Bindable var state: FileBrowserState
    let item: BrowserItem

    var body: some View {
        Button("Open", systemImage: "arrow.up.forward.app") { Task { await state.open(item) } }
        Button("Get Info", systemImage: "info.circle") {
            state.select(item)
            state.previewVisible = true
            state.updatePreview()
        }
        Button("Quick Look", systemImage: "eye") { state.select(item); state.openQuickLook() }
    }
}

private extension BrowserItem {
    var displayKind: String {
        if isDirectory { return String(localized: "Folder") }
        if isArchive { return String(localized: "Archive") }
        return contentType?.localizedDescription ?? String(localized: "Document")
    }
}

private extension View {
    func finderClickGesture(
        onSingleClick: @escaping () -> Void,
        onDoubleClick: @escaping () -> Void
    ) -> some View {
        gesture(
            TapGesture(count: 2)
                .exclusively(before: TapGesture(count: 1))
                .onEnded { gesture in
                    switch gesture {
                    case .first: onDoubleClick()
                    case .second: onSingleClick()
                    }
                },
            including: .gesture
        )
    }
}
