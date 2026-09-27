import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ListBrowserView: View {
    @Bindable var state: FileBrowserState
    let obscuredTrailingWidth: CGFloat
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
    @State private var focusedScrollTask: Task<Void, Never>?

    private var scale: CGFloat { state.preferences.scale }
    private var columnWidths: [CGFloat] {
        BrowserSortField.allCases.map { state.preferences.listColumnWidth($0) }
    }

    var body: some View {
        GeometryReader { geometry in
            let tableWidth = BrowserListLayout.tableWidth(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale,
                columnWidths: columnWidths
            )
            let scrollContentWidth = BrowserListLayout.scrollContentWidth(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale,
                columnWidths: columnWidths
            )
            let usesEdgeToEdgeRows = BrowserListLayout.requiresHorizontalScrolling(
                availableWidth: geometry.size.width,
                obscuredTrailingWidth: obscuredTrailingWidth,
                scale: scale,
                columnWidths: columnWidths
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
        let fixedWidths = BrowserSortField.allCases.dropFirst().reduce(CGFloat.zero) {
            $0 + state.preferences.listColumnWidth($1) * scale
        }
        let automaticNameWidth = max(
            width - fixedWidths - 2 * (BrowserMetrics.horizontalInset + BrowserMetrics.rowContentInset) * scale,
            BrowserListLayout.minimumNameColumnWidth * scale
        )
        let nameWidth = state.preferences.listColumnWidths[BrowserSortField.name.rawValue] == nil
            ? automaticNameWidth
            : state.preferences.listColumnWidth(.name) * scale
        return VStack(spacing: 0) {
            ListHeader(state: state, scale: scale, nameWidth: nameWidth)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    BrowserListRows(
                        state: state,
                        scale: scale,
                        nameWidth: nameWidth,
                        width: width,
                        minimumHeight: max(height - (28 * scale), 1),
                        usesEdgeToEdgeRows: usesEdgeToEdgeRows,
                        contentFocus: contentFocus,
                        dragSession: dragSession
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
    let nameWidth: CGFloat
    let width: CGFloat
    let minimumHeight: CGFloat
    let usesEdgeToEdgeRows: Bool
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession

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
                ForEach(state.flattenedList()) { entry in
                    BrowserListRow(
                        state: state,
                        entry: entry,
                        index: entry.rowIndex,
                        scale: scale,
                        nameWidth: nameWidth,
                        usesEdgeToEdgeBackground: usesEdgeToEdgeRows,
                        contentFocus: contentFocus,
                        dragSession: dragSession
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
    let nameWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            headerButton("Name", field: .name, showsTrailingSeparator: true)
                .frame(width: nameWidth, alignment: .leading)
            headerButton("Date Modified", field: .modificationDate, showsTrailingSeparator: true)
                .frame(width: state.preferences.listColumnWidth(.modificationDate) * scale, alignment: .leading)
            headerButton("Size", field: .size, showsTrailingSeparator: true)
                .frame(width: state.preferences.listColumnWidth(.size) * scale, alignment: .leading)
            headerButton("Kind", field: .kind)
                .frame(width: state.preferences.listColumnWidth(.kind) * scale, alignment: .leading)
            Spacer(minLength: 0)
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
        .overlay(alignment: .trailing) {
            if showsTrailingSeparator {
                BrowserColumnResizeHandle(
                    currentWidth: field == .name
                        ? nameWidth / scale
                        : state.preferences.listColumnWidth(field),
                    scale: scale
                ) { width in
                    state.preferences.setListColumnWidth(width, for: field)
                }
                .frame(width: 20 * scale)
                .help("Drag to resize column")
            }
        }
    }
}

private struct BrowserListRow: View {
    @Bindable var state: FileBrowserState
    let entry: VisibleBrowserItem
    let index: Int
    let scale: CGFloat
    let nameWidth: CGFloat
    let usesEdgeToEdgeBackground: Bool
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession

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
                        let expandsAll = NSEvent.modifierFlags.contains(.option)
                        Task {
                            if expandsAll {
                                await state.toggleAllDescendants(of: entry.item)
                            } else {
                                await state.toggleExpansion(entry.item)
                            }
                        }
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
                    BrowserItemNameView(
                        state: state,
                        item: entry.item,
                        contentFocus: contentFocus
                    )
                } icon: {
                    FileIconView(item: entry.item, size: BrowserMetrics.iconSize * scale)
                }
                .tint(isSelected ? .white : .primary)
                .frame(
                    width: max(
                        nameWidth - (CGFloat(entry.depth * 20) + BrowserMetrics.disclosureWidth) * scale,
                        1
                    ),
                    alignment: .leading
                )

                Text(
                    entry.item.formattedDate(
                        entry.item.modificationDate,
                        locale: state.preferences.language.locale
                    )
                )
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(
                        width: state.preferences.listColumnWidth(.modificationDate) * scale,
                        alignment: .leading
                    )

                Text(entry.item.formattedSize(locale: state.preferences.language.locale))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(width: state.preferences.listColumnWidth(.size) * scale, alignment: .leading)

                Text(entry.item.displayKind)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                    .padding(.leading, BrowserMetrics.columnContentInset * scale)
                    .frame(width: state.preferences.listColumnWidth(.kind) * scale, alignment: .leading)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .finderClickGesture(
                onSingleClick: {
                    state.select(
                        entry.item,
                        modifiers: NSEvent.modifierFlags,
                        orderedItems: state.flattenedItems()
                    )
                },
                onDoubleClick: {
                    let modifiers = NSEvent.modifierFlags
                    Task { await state.openFromDoubleClick(entry.item, modifiers: modifiers) }
                }
            )
        }
        .browserItemEmphasis(entry.item, isSelected: isSelected)
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
        .browserDraggable(item: entry.item)
        .browserDirectoryDropTarget(
            state: state,
            item: entry.item,
            dragSession: dragSession
        )
    }
}
