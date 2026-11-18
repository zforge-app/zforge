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
        case .computer:
            Image(systemName: ComputerIdentity.systemImage)
                .frame(width: 16, height: 16)
        case .network, .networkServer:
            Image(nsImage: NetworkLevelCatalog.networkIcon)
                .resizable()
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
    let restoreContentFocus: () -> Void
    let dragSession: BrowserFileDragSession

    var body: some View {
        List {
            SidebarActionRow(title: "Recents", systemImage: "clock") {
                restoreContentFocus()
                Task { await browser.navigateToRecents() }
            }

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
                            SidebarItemMenuContent(menu: sidebarMenuActions.menu(for: destination.url, canRemoveFromSidebar: true))
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
                // Finder lists the computer first in Locations, before home and the volumes.
                if browser.preferences.isSidebarLocationVisible(.computer) {
                    SidebarComputerRow(browser: browser, computer: sidebar.computer,
                                       restoreContentFocus: restoreContentFocus)
                        .contextMenu { SidebarItemMenuContent(menu: sidebarMenuActions.computerMenu()) }
                }
                if browser.preferences.isSidebarLocationVisible(.home) {
                    destinationRow(sidebar.userHome.name, sidebar.userHome.url, sidebar.userHome.systemImage)
                        .contextMenu { locationMenu(sidebar.userHome.name, sidebar.userHome.url, kind: .home) }
                }
                ForEach(sidebar.localVolumes.filter(isVisible)) { volume in
                    destinationRow(volume.name, volume.url, volume.kind == .removable ? "externaldrive" : "internaldrive",
                                   isEjectable: volume.isEjectable)
                        .contextMenu { locationMenu(volume) }
                }
                // Network is not a sidebar item (user request, 2026-11-09): it stays in the computer
                // level and Go ▸ Network.
            } header: {
                Text("Locations")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .background { SidebarNativeDropFeedback(feedback: dropFeedback, owner: "favorites-end") }
                    .onDrop(of: [UTType.fileURL.identifier], delegate: SidebarFavoriteDropDelegate(
                        browser: browser, anchor: nil, feedback: dropFeedback, owner: "favorites-end"
                    ))
            }
            .environment(\.sidebarIconTint, .neutral)
            // Shared lists the mounted network volumes; connecting to a server is Network ▸ Add Remote.
            let sharedVolumes = sidebar.networkVolumes.filter(isVisible)
            if !sharedVolumes.isEmpty {
                Section("Shared") {
                    ForEach(sharedVolumes) { volume in
                        destinationRow(volume.name, volume.url, "network")
                            .contextMenu { locationMenu(volume) }
                    }
                }
                .environment(\.sidebarIconTint, .neutral)
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
                                SidebarTagDot(colorIndex: tag.colorIndex)
                            }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("sidebar-tag-\(tag.name)")
                        .sidebarLabelStyle(isAccent: browser.selectedSidebarTag == tag.name)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        // The maximum follows the window width in AppKit (`SidebarSplitConstraintView`), so a
        // resize does not re-evaluate the sidebar (D-110). SwiftUI gets no width-dependent limit.
        .navigationSplitViewColumnWidth(
            min: BrowserSidebarLayout.minimumWidth,
            ideal: BrowserSidebarLayout.idealWidth
        )
        .background {
            SidebarSplitConstraint(
                minimumWidth: BrowserSidebarLayout.minimumWidth,
                minimumDetailWidth: BrowserSidebarLayout.minimumDetailWidth
            )
        }
        .accessibilityIdentifier("browser-sidebar")
        .onModifierKeysChanged(mask: [.option, .command]) { _, modifiers in
            dragSession.modifiers = modifiers
        }
        .onDisappear { dropFeedback.clear() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didRenameVolumeNotification)) { note in
            guard let old = note.userInfo?[NSWorkspace.oldVolumeURLUserInfoKey] as? URL,
                  let new = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            Task { await browser.followRenamedVolume(from: old, to: new) }
        }
        .task { await sidebar.refresh() }
        .task { tagCatalog.start() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            tagCatalog.refresh()
            sidebar.refreshComputer()
        }
    }

    /// The shared sidebar item menu's commands for this window (see `SidebarItemMenu`).
    private var sidebarMenuActions: SidebarItemMenuActions {
        SidebarItemMenuActions(browser: browser, sidebar: sidebar, restoreContentFocus: restoreContentFocus)
    }

    private func isVisible(_ volume: SidebarVolume) -> Bool {
        browser.preferences.isSidebarLocationVisible(volume.locationKind.category)
    }

    private func locationMenu(_ volume: SidebarVolume) -> SidebarItemMenuContent {
        locationMenu(volume.name, volume.url, kind: volume.locationKind, canEject: volume.isEjectable)
    }

    private func locationMenu(_ name: String, _ url: URL, kind: SidebarLocationKind,
                              canEject: Bool = false) -> SidebarItemMenuContent {
        SidebarItemMenuContent(menu: sidebarMenuActions.locationMenu(
            name: name, url: url, kind: kind, canEject: canEject))
    }

    private func destinationRow(_ name: String, _ url: URL, _ icon: String, canInsert: Bool = false, nextFavorite: URL? = nil,
                                isEjectable: Bool = false) -> some View {
        SidebarDestinationRow(browser: browser, feedback: dropFeedback, name: name, url: url,
                              systemImage: icon, canInsert: canInsert, nextFavorite: nextFavorite,
                              restoreContentFocus: restoreContentFocus, dragSession: dragSession,
                              isEjectable: isEjectable)
    }
}

/// A sidebar row that runs an action instead of showing a destination (Recents).
/// Its name uses `sidebarLabelStyle` like every other row, so all names gray out together.
struct SidebarActionRow: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title).sidebarLabelStyle()
            } icon: {
                Image(systemName: systemImage).sidebarIconStyle()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A sidebar tag dot: the tag color while the window is active; in an inactive window it turns
/// the same gray as every other sidebar icon (user request, 2026-10-30).
struct SidebarTagDot: View {
    /// Diameter of a sidebar tag dot; the context menu's quick tag circles share it.
    static let size: CGFloat = 12

    @Environment(\.appearsActive) private var appearsActive
    let colorIndex: Int

    var body: some View {
        FinderTagDot(colorIndex: colorIndex, size: Self.size,
                     monochrome: appearsActive ? nil : SidebarIconTint.Appearance.inactive.color)
    }
}

/// Tint role of a sidebar row icon, as in Finder: Recents and Favorites use the accent color,
/// while Locations and mounted volumes use a neutral gray. Every icon turns gray while the window is
/// inactive, and so do tag dots (`SidebarTagDot`).
enum SidebarIconTint: Equatable {
    case accent
    case neutral

    enum Appearance: Equatable {
        case accent
        case neutral
        case inactive
        case dropTarget
    }

    func appearance(appearsActive: Bool, isDropTarget: Bool) -> Appearance {
        if isDropTarget { return .dropTarget }
        guard appearsActive else { return .inactive }
        return self == .accent ? .accent : .neutral
    }
}

extension SidebarIconTint.Appearance {
    var color: Color {
        switch self {
        case .accent: Color.accentColor
        case .neutral: Color(nsColor: .secondaryLabelColor)
        case .inactive: Color(nsColor: .tertiaryLabelColor)
        case .dropTarget: Color.white
        }
    }
}

extension EnvironmentValues {
    @Entry var sidebarIconTint: SidebarIconTint = .accent
}

private struct SidebarIconStyle: ViewModifier {
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.sidebarIconTint) private var tint
    let isDropTarget: Bool

    func body(content: Content) -> some View {
        content.foregroundStyle(tint.appearance(appearsActive: appearsActive, isDropTarget: isDropTarget).color)
    }
}

extension View {
    func sidebarIconStyle(isDropTarget: Bool = false) -> some View {
        modifier(SidebarIconStyle(isDropTarget: isDropTarget))
    }

    /// Color of every sidebar row name, as in Finder: primary (or accent for a selected tag) while
    /// the window is active, gray in every section while it is inactive, white on a drop target.
    func sidebarLabelStyle(isDropTarget: Bool = false, isAccent: Bool = false) -> some View {
        modifier(SidebarLabelStyle(isDropTarget: isDropTarget, isAccent: isAccent))
    }
}

private struct SidebarLabelStyle: ViewModifier {
    @Environment(\.appearsActive) private var appearsActive
    let isDropTarget: Bool
    let isAccent: Bool

    func body(content: Content) -> some View {
        content.foregroundStyle(
            isDropTarget ? Color.white
                : !appearsActive ? Color(nsColor: .secondaryLabelColor)
                : isAccent ? Color.accentColor : Color.primary
        )
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
    var isEjectable = false
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
                        .sidebarIconStyle(isDropTarget: isDropTarget)
                }
                Spacer()
                if browser.pendingAuthorizationURL == url {
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                }
                if isEjectable {
                    // Reserves the overlaid eject button's slot.
                    Color.clear.frame(width: SidebarEjectButton.size, height: SidebarEjectButton.size)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sidebarLabelStyle(isDropTarget: isDropTarget)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .overlay(alignment: .trailing) {
            if isEjectable {
                SidebarEjectButton(browser: browser, name: name, url: url, isDropTarget: isDropTarget,
                                   restoreContentFocus: restoreContentFocus)
                    .padding(.trailing, 4)
            }
        }
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
