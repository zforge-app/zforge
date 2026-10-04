import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct GalleryBrowserView: View {
    @Bindable var state: FileBrowserState
    let contentFocus: FocusState<BrowserFocusTarget?>.Binding
    let dragSession: BrowserFileDragSession
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
                                        BrowserItemNameView(
                                            state: state,
                                            item: item,
                                            contentFocus: contentFocus
                                        )
                                            .font(.system(size: 11 * scale))
                                    }
                                    .browserItemEmphasis(item, isSelected: isSelected)
                                    .frame(width: 96 * scale, height: 72 * scale)
                                    .contentShape(Rectangle())
                                    .background {
                                        RoundedRectangle(cornerRadius: 8 * scale)
                                            .fill(isSelected ? Color.primary.opacity(0.12) : .clear)
                                    }
                                    .id(item.id)
                                    .finderClickGesture(
                                        onSingleClick: { state.select(item, modifiers: NSEvent.modifierFlags) },
                                        onDoubleClick: {
                                            let modifiers = NSEvent.modifierFlags
                                            Task { await state.openFromDoubleClick(item, modifiers: modifiers) }
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
