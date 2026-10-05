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
    private var columns: [BrowserListColumn] {
        state.preferences.visibleListColumns(for: state.location)
    }
    private var columnWidths: [CGFloat] {
        columns.map { state.preferences.width(forListColumn: $0) }
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
        .onChange(of: columns) { oldColumns, newColumns in
            let extended: Set<BrowserListColumn> = [.lastOpenedDate, .dateAdded, .version, .comments]
            if extended.isDisjoint(with: oldColumns) && !extended.isDisjoint(with: newColumns) {
                Task { await state.reload() }
            }
        }
    }

    private func listTable(
        width: CGFloat,
        height: CGFloat,
        usesEdgeToEdgeRows: Bool
    ) -> some View {
        let fixedWidths = columns.dropFirst().reduce(CGFloat.zero) {
            $0 + state.preferences.width(forListColumn: $1) * scale
        }
        let automaticNameWidth = max(
            width - fixedWidths - 2 * (BrowserMetrics.horizontalInset + BrowserMetrics.rowContentInset) * scale,
            BrowserListLayout.minimumNameColumnWidth * scale
        )
        let nameWidth = state.preferences.listColumnWidths[BrowserSortField.name.rawValue] == nil
            ? automaticNameWidth
            : state.preferences.listColumnWidth(.name) * scale
        return VStack(spacing: 0) {
            ListHeader(state: state, scale: scale, nameWidth: nameWidth, columns: columns)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical) {
                    BrowserListRows(
                        state: state,
                        scale: scale,
                        nameWidth: nameWidth,
                        columns: columns,
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
    let columns: [BrowserListColumn]
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
                .browserBackgroundContextMenu(state: state)

            LazyVStack(spacing: 0) {
                ForEach(state.flattenedList()) { entry in
                    BrowserListRow(
                        state: state,
                        entry: entry,
                        index: entry.rowIndex,
                        scale: scale,
                        nameWidth: nameWidth,
                        columns: columns,
                        usesEdgeToEdgeBackground: usesEdgeToEdgeRows,
                        contentFocus: contentFocus,
                        dragSession: dragSession
                    )
                    .id(entry.id)
                    .browserItemContextMenu(state: state, item: entry.item)
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
    let columns: [BrowserListColumn]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                headerButton(column, showsTrailingSeparator: column != columns.last)
                    .frame(
                        width: column == .name
                            ? nameWidth
                            : state.preferences.width(forListColumn: column) * scale,
                        alignment: .leading
                    )
                    .onDrag {
                        NSItemProvider(object: column.rawValue as NSString)
                    }
                    .onDrop(of: [.plainText], isTargeted: nil) { providers in
                        guard column != .name, let provider = providers.first else { return false }
                        _ = provider.loadObject(ofClass: NSString.self) { value, _ in
                            guard let raw = value as? String,
                                  let source = BrowserListColumn(rawValue: raw),
                                  source != .name, source != column else { return }
                            Task { @MainActor in
                                var reordered = state.preferences.visibleListColumns(for: state.location)
                                guard let from = reordered.firstIndex(of: source),
                                      let to = reordered.firstIndex(of: column) else { return }
                                reordered.remove(at: from)
                                reordered.insert(source, at: to)
                                setColumns(reordered)
                            }
                        }
                        return true
                    }
            }
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

    private func headerButton(_ column: BrowserListColumn, showsTrailingSeparator: Bool) -> some View {
        Button {
            if let field = column.sortField { state.setSort(field) }
        } label: {
            HStack(spacing: 4 * scale) {
                Text(column.title(locale: state.preferences.language.locale))
                if state.preferences.sort.field == column.sortField {
                    Image(systemName: state.preferences.sort.ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8 * scale, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, BrowserMetrics.columnContentInset * scale)
            .padding(.trailing, BrowserMetrics.columnContentInset * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .contextMenu {
            ForEach(BrowserListColumn.allCases.filter { $0 != .name }) { candidate in
                Toggle(candidate.title(locale: state.preferences.language.locale), isOn: Binding(
                    get: { columns.contains(candidate) },
                    set: { isVisible in
                        var visible = state.preferences.visibleListColumns(for: state.location)
                        if isVisible && !visible.contains(candidate) { visible.append(candidate) }
                        if !isVisible { visible.removeAll { $0 == candidate } }
                        setColumns(visible)
                    }
                ))
                .disabled(!BrowserListColumn.selectable.contains(candidate))
            }
            Divider()
            Button("Restore defaults") {
                state.preferences.resetListColumns(for: state.location)
            }
            .disabled(!state.preferences.hasListColumnOverride(for: state.location))
        }
        .overlay(alignment: .trailing) {
            if showsTrailingSeparator {
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1)
            }
        }
        .overlay(alignment: .trailing) {
            if showsTrailingSeparator, let field = column.sortField {
                BrowserColumnResizeHandle(
                    currentWidth: column == .name
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

    private func setColumns(_ columns: [BrowserListColumn]) {
        if state.location.fileSystemURL != nil {
            state.preferences.setListColumns(columns, for: state.location)
        } else {
            state.preferences.setGlobalListColumns(columns)
        }
    }
}

private struct BrowserListRow: View {
    @Bindable var state: FileBrowserState
    let entry: VisibleBrowserItem
    let index: Int
    let scale: CGFloat
    let nameWidth: CGFloat
    let columns: [BrowserListColumn]
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
                HStack(spacing: 4 * scale) {
                    Label {
                        BrowserItemNameView(
                            state: state,
                            item: entry.item,
                            contentFocus: contentFocus
                        )
                    } icon: {
                        FileIconView(item: entry.item, size: BrowserMetrics.iconSize * scale, isExpanded: entry.isExpanded)
                    }
                    .tint(isSelected ? .white : .primary)
                    .lineLimit(1)
                    Spacer(minLength: 2 * scale)
                    if !entry.item.tags.isEmpty {
                        FinderTagDots(
                            tags: entry.item.tags,
                            colorIndexes: entry.item.tagColorIndexes,
                            dotSize: 8 * scale
                        )
                        .padding(.trailing, 8 * scale)
                    }
                }
                .frame(
                    width: max(
                        nameWidth - (CGFloat(entry.depth * 20) + BrowserMetrics.disclosureWidth) * scale,
                        1
                    ),
                    alignment: .leading
                )

                ForEach(columns.filter { $0 != .name }) { column in
                    Text(value(for: column))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
                        .padding(.leading, BrowserMetrics.columnContentInset * scale)
                        .frame(
                            width: state.preferences.width(forListColumn: column) * scale,
                            alignment: .leading
                        )
                }
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
        .browserDraggable(item: entry.item, state: state)
        .browserDirectoryDropTarget(
            state: state,
            item: entry.item,
            dragSession: dragSession
        )
    }

    private func value(for column: BrowserListColumn) -> String {
        let item = entry.item
        let locale = state.preferences.language.locale
        return switch column {
        case .name: item.name
        case .modificationDate: item.formattedDate(item.modificationDate, locale: locale)
        case .creationDate: item.formattedDate(item.creationDate, locale: locale)
        case .lastOpenedDate:
            item.formattedDate(item.extendedMetadata.lastOpenedDate, locale: locale)
        case .dateAdded: item.formattedDate(item.extendedMetadata.dateAdded, locale: locale)
        case .size: item.formattedSize(locale: locale)
        case .kind: item.displayKind
        case .lastModifiedBy, .sharedBy: "—"
        case .version: item.extendedMetadata.version ?? "—"
        case .comments: item.extendedMetadata.comments ?? "—"
        case .tags: item.tags.isEmpty ? "—" : item.tags.joined(separator: ", ")
        }
    }
}
