import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct IconBrowserView: View {
    @Bindable var state: FileBrowserState
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
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
                                    state: state,
                                    item: item,
                                    isSelected: state.selection.contains(item.id),
                                    scale: scale,
                                    contentFocus: contentFocus
                                )
                                .id(item.id)
                                .finderClickGesture(
                                    onSingleClick: { state.select(item, modifiers: NSEvent.modifierFlags) },
                                    onDoubleClick: {
                                        let modifiers = NSEvent.modifierFlags
                                        Task { await state.openFromDoubleClick(item, modifiers: modifiers) }
                                    }
                                )
                                .browserDraggable(item: item, state: state)
                                .browserDirectoryDropTarget(
                                    state: state,
                                    item: item,
                                    dragSession: dragSession
                                )
                                .browserItemContextMenu(state: state, item: item)
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
    @Bindable var state: FileBrowserState
    let item: BrowserItem
    let isSelected: Bool
    let scale: CGFloat
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding

    var body: some View {
        VStack(spacing: 8 * scale) {
            FileIconView(item: item, size: 64 * scale)
                .browserItemEmphasis(item, isSelected: isSelected)
                .frame(width: 84 * scale, height: 72 * scale)
                .background {
                    RoundedRectangle(cornerRadius: 8 * scale)
                        .fill(isSelected ? Color.primary.opacity(0.12) : .clear)
                }

            BrowserItemNameView(
                state: state,
                item: item,
                lineLimit: 2,
                textAlignment: .center,
                contentFocus: contentFocus
            )
                .browserItemEmphasis(item, isSelected: isSelected)
                .font(.system(size: 13 * scale))
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
