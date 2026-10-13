import AppKit
import SwiftUI
import UniformTypeIdentifiers

nonisolated enum BrowserSidebarLayout {
    static let minimumWidth: CGFloat = 180
    static let idealWidth: CGFloat = 220
    static let minimumDetailWidth: CGFloat = 360

    static func maximumWidth(for windowWidth: CGFloat) -> CGFloat {
        max(minimumWidth, windowWidth - minimumDetailWidth)
    }
}

struct BrowserBreadcrumb: View {
    @Bindable var state: FileBrowserState
    @State private var scrollTask: Task<Void, Never>?

    private let endAnchorID = "breadcrumb-end"

    var body: some View {
        let components = state.breadcrumbComponents
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(components.enumerated()), id: \.element.id) { index, component in
                            if index > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            Button {
                                Task { await state.navigateBreadcrumb(to: component) }
                            } label: {
                                HStack(spacing: 5) {
                                    componentIcon(component)
                                    Text(component.name).lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(index == components.count - 1 ? .primary : .secondary)
                        }

                        Color.clear
                            .frame(width: 12, height: 1)

                        Color.clear
                            .frame(width: 1, height: 1)
                            .id(endAnchorID)
                    }
                    .padding(.horizontal, 12)
                    .frame(minWidth: geometry.size.width, minHeight: 34, alignment: .leading)
                }
                .onAppear {
                    scrollToEnd(proxy, animated: false)
                }
                .onChange(of: state.breadcrumbComponents) {
                    scrollToEnd(proxy, animated: true)
                }
                .onChange(of: geometry.size.width) {
                    scrollToEnd(proxy, animated: false)
                }
                .onDisappear {
                    scrollTask?.cancel()
                    scrollTask = nil
                }
            }
        }
        .frame(height: 34)
        .background(Color(nsColor: .underPageBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, animated: Bool) {
        scrollTask?.cancel()
        scrollTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(endAnchorID, anchor: .trailing)
                }
            } else {
                proxy.scrollTo(endAnchorID, anchor: .trailing)
            }
            scrollTask = nil
        }
    }

    @ViewBuilder
    private func componentIcon(_ component: BrowserPathComponent) -> some View {
        if let systemImage = component.systemImage {
            Image(systemName: systemImage)
                .frame(width: 16, height: 16)
        } else {
            locationIcon(component)
        }
    }

    @ViewBuilder
    private func locationIcon(_ component: BrowserPathComponent) -> some View {
        switch component.location {
        case .recents:
            Image(systemName: "clock")
                .frame(width: 16, height: 16)
        case let .fileSystem(url):
            Image(nsImage: FileIconCache.shared.icon(for: url))
                .resizable()
                .frame(width: 16, height: 16)
        case .archive:
            Image(systemName: "archivebox")
                .frame(width: 16, height: 16)
        }
    }
}

struct BrowserSidebar: View {
    @State private var tagCatalog = FinderTagCatalog.shared
    @State private var dropFeedback = SidebarDropFeedback()
    @Bindable var browser: FileBrowserState
    @Bindable var sidebar: SidebarState
    let windowWidth: CGFloat
    @Binding var showingServerSheet: Bool
    let restoreContentFocus: () -> Void
    let dragSession: BrowserFileDragSession

    var body: some View {
        List {
            Button {
                restoreContentFocus()
                Task { await browser.navigateToRecents() }
            } label: {
                Label("Recents", systemImage: "clock")
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Section {
                if let directory = browser.archiveDragFixtureDirectory {
                    destinationRow("Dropped", directory.appendingPathComponent("Dropped"), "folder", canInsert: false, nextFavorite: nil)
                        .accessibilityIdentifier("sidebar-fixture-drop")
                        .accessibilityValue(directory.appendingPathComponent("Dropped").path)
                }
                ForEach(sidebar.favorites) { destination in
                    destinationRow(destination.name, destination.url, destination.systemImage, canInsert: true,
                                   nextFavorite: sidebar.favorites.drop(while: { $0.id != destination.id }).dropFirst().first?.url)
                        .contextMenu {
                            Button("Remove from Sidebar", systemImage: "pin.slash") {
                                sidebar.pinnedFolders.remove(destination.url)
                                restoreContentFocus()
                            }
                        }
                        .accessibilityIdentifier("sidebar-favorite-\(destination.id)")
                }
            } header: {
                Text("Favorites")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background {
                        SidebarNativeDropFeedback(feedback: dropFeedback, owner: "favorites-header",
                            insertionEdge: sidebar.favorites.isEmpty && dropFeedback.target == .insertion(nil) ? .bottom : nil,
                            insertionOffset: 5)
                    }
                    .onDrop(of: [UTType.fileURL.identifier], delegate: SidebarFavoriteDropDelegate(
                        browser: browser, anchor: sidebar.favorites.first?.url,
                        feedback: dropFeedback, owner: "favorites-header"
                    ))
            }
            Section {
                destinationRow(sidebar.userHome.name, sidebar.userHome.url, sidebar.userHome.systemImage)
                ForEach(sidebar.localVolumes) { volume in
                    destinationRow(volume.name, volume.url, volume.kind == .removable ? "externaldrive" : "internaldrive")
                }
            } header: {
                Text("Locations")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background { SidebarNativeDropFeedback(feedback: dropFeedback, owner: "favorites-end") }
                    .onDrop(of: [UTType.fileURL.identifier], delegate: SidebarFavoriteDropDelegate(
                        browser: browser, anchor: nil, feedback: dropFeedback, owner: "favorites-end"
                    ))
            }
            Section("Shared") {
                ForEach(sidebar.networkVolumes) { volume in
                    destinationRow(volume.name, volume.url, "network")
                }
                Button {
                    showingServerSheet = true
                    restoreContentFocus()
                } label: {
                    Label("Remote", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
            }
            Section("Tags") {
                if tagCatalog.tags.isEmpty {
                    Text("No tags")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tagCatalog.tags) { tag in
                        Button {
                            restoreContentFocus()
                            Task { await browser.navigateToTag(tag.name) }
                        } label: {
                            Label {
                                Text(tag.name)
                            } icon: {
                                FinderTagDot(colorIndex: tag.colorIndex, size: 12)
                            }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("sidebar-tag-\(tag.name)")
                        .foregroundStyle(browser.selectedSidebarTag == tag.name ? Color.accentColor : .primary)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(
            min: BrowserSidebarLayout.minimumWidth,
            ideal: BrowserSidebarLayout.idealWidth,
            max: BrowserSidebarLayout.maximumWidth(for: windowWidth)
        )
        .background {
            SidebarSplitConstraint(
                minimumWidth: BrowserSidebarLayout.minimumWidth,
                maximumWidth: BrowserSidebarLayout.maximumWidth(for: windowWidth)
            )
        }
        .accessibilityIdentifier("browser-sidebar")
        .onModifierKeysChanged(mask: [.option, .command]) { _, modifiers in
            dragSession.modifiers = modifiers
        }
        .onDisappear { dropFeedback.clear() }
        .task { await sidebar.refresh() }
        .task { tagCatalog.start() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            tagCatalog.refresh()
        }
    }

    private func destinationRow(_ name: String, _ url: URL, _ icon: String, canInsert: Bool = false, nextFavorite: URL? = nil) -> some View {
        SidebarDestinationRow(browser: browser, feedback: dropFeedback, name: name, url: url,
                              systemImage: icon, canInsert: canInsert, nextFavorite: nextFavorite,
                              restoreContentFocus: restoreContentFocus, dragSession: dragSession)
    }
}

private struct SidebarDestinationRow: View {
    @Bindable var browser: FileBrowserState
    @Bindable var feedback: SidebarDropFeedback
    let name: String
    let url: URL
    let systemImage: String
    let canInsert: Bool
    let nextFavorite: URL?
    let restoreContentFocus: () -> Void
    let dragSession: BrowserFileDragSession
    @State private var rowHeight: CGFloat = 32

    private var owner: String { "\(canInsert ? "favorite" : "destination"):\(url.standardizedFileURL.path)" }

    private var isDropTarget: Bool { feedback.owner == owner && feedback.target == .folder(url) }
    private var isCurrent: Bool {
        SidebarDropFeedback.isCurrentDirectory(url, current: browser.currentDirectoryURL)
    }

    var body: some View {
        Button {
            restoreContentFocus()
            Task { await browser.navigateToSidebar(url, name: name) }
        } label: {
            HStack {
                Label {
                    Text(name).fontWeight(isCurrent || isDropTarget ? .semibold : .regular)
                } icon: {
                    Image(systemName: systemImage)
                        .resizable().scaledToFit().frame(width: 16, height: 16)
                        .foregroundStyle(isDropTarget ? Color.white : Color.accentColor)
                }
                Spacer()
                if browser.pendingAuthorizationURL == url {
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDropTarget ? Color.white : .primary)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTarget ? Color.accentColor : isCurrent
                      ? Color(nsColor: .unemphasizedSelectedContentBackgroundColor) : .clear)
                .padding(.horizontal, 10)
        )
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .background {
            SidebarNativeDropFeedback(feedback: feedback, owner: owner, insertionEdge:
                canInsert && feedback.target == .insertion(url) ? .top
                : canInsert && nextFavorite == nil && feedback.target == .insertion(nil) ? .bottom : nil)
                .allowsHitTesting(false)
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear { rowHeight = geometry.size.height }
                    .onChange(of: geometry.size.height) { _, height in rowHeight = height }
            }
        }
        .onDrop(of: [UTType.fileURL.identifier, ArchiveDragPolicy.type], delegate: SidebarRowDropDelegate(
            browser: browser, url: url, canInsert: canInsert, nextFavorite: nextFavorite,
            rowHeight: rowHeight, feedback: feedback, owner: owner, dragSession: dragSession
        ))
        .overlay {
            ArchiveDropDestination(directory: url, onTargetedChange: { targeted in
                if targeted { feedback.update(owner: owner, target: .folder(url)) }
                else { feedback.leave(owner: owner) }
            }).accessibilityHidden(true)
        }
        .onDisappear { feedback.leave(owner: owner) }

    }
}

private struct SidebarRowDropDelegate: DropDelegate {
    let browser: FileBrowserState
    let url: URL
    let canInsert: Bool
    let nextFavorite: URL?
    let rowHeight: CGFloat
    let feedback: SidebarDropFeedback
    let owner: String
    let dragSession: BrowserFileDragSession

    func validateDrop(info: DropInfo) -> Bool { info.hasItemsConforming(to: [UTType.fileURL.identifier, ArchiveDragPolicy.type]) }
    private func target(_ info: DropInfo) -> SidebarDropFeedback.Target {
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]) { return .folder(url) }
        return SidebarDropFeedback.rowTarget(url: url, canInsert: canInsert, nextFavorite: nextFavorite,
                                      height: rowHeight, y: info.location.y)
    }
    private func update(_ info: DropInfo) {
        guard validateDrop(info: info) else { feedback.leave(owner: owner); return }
        feedback.update(owner: owner, target: target(info))
    }
    func dropEntered(info: DropInfo) { update(info) }
    func dropExited(info: DropInfo) { feedback.leave(owner: owner) }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { feedback.leave(owner: owner); return DropProposal(operation: .cancel) }
        update(info)
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]) {
            return DropProposal(operation: NSEvent.modifierFlags.contains(.option) ? .move : .copy)
        }
        if case .insertion = target(info) { return DropProposal(operation: .copy) }
        return DropProposal(operation: BrowserFileDropProposalResolver.operation(
            for: BrowserFileDropOperationResolver.operation(forNativeFlags: NSEvent.modifierFlags)
        ))
    }
    func performDrop(info: DropInfo) -> Bool {
        feedback.leave(owner: owner)
        guard validateDrop(info: info) else { return false }
        if info.hasItemsConforming(to: [ArchiveDragPolicy.type]) {
            return browser.performArchiveItemDrop(providers: info.itemProviders(for: [ArchiveDragPolicy.type]),
                to: url, moving: NSEvent.modifierFlags.contains(.option))
        }
        let providers = info.itemProviders(for: [UTType.fileURL.identifier])
        switch target(info) {
        case let .insertion(anchor): return browser.performPinDrop(providers: providers, before: anchor)
        case let .folder(destination):
            return browser.performDrop(providers: providers, to: destination,
                operation: BrowserFileDropOperationResolver.operation(forNativeFlags: NSEvent.modifierFlags))
        }
    }
}

private struct SidebarFavoriteDropDelegate: DropDelegate {
    let browser: FileBrowserState
    let anchor: URL?
    let feedback: SidebarDropFeedback
    let owner: String
    func validateDrop(info: DropInfo) -> Bool { info.hasItemsConforming(to: [UTType.fileURL.identifier]) }
    func dropEntered(info: DropInfo) {
        if validateDrop(info: info) { feedback.update(owner: owner, target: .insertion(anchor)) }
    }
    func dropExited(info: DropInfo) { feedback.leave(owner: owner) }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard validateDrop(info: info) else { feedback.leave(owner: owner); return DropProposal(operation: .cancel) }
        dropEntered(info: info)
        return DropProposal(operation: .copy)
    }
    func performDrop(info: DropInfo) -> Bool {
        feedback.leave(owner: owner)
        guard validateDrop(info: info) else { return false }
        return browser.performPinDrop(providers: info.itemProviders(for: [UTType.fileURL.identifier]), before: anchor)
    }
}

struct ServerConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var sidebar: SidebarState
    let didMount: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Remote", systemImage: "network")
                .font(.title2.weight(.semibold))
            Text("Enter an SMB, AFP, or NFS address.")
                .foregroundStyle(.secondary)
            TextField("smb://server/share", text: $sidebar.serverAddress)
                .textFieldStyle(.roundedBorder)
                .onSubmit { connect() }
            if let error = sidebar.serverError {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Connect") { connect() }
                    .buttonStyle(.borderedProminent)
                    .disabled(sidebar.isConnecting)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private func connect() {
        Task {
            if let url = await sidebar.connectToServer() {
                didMount(url)
                dismiss()
            }
        }
    }
}
