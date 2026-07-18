import AppKit
import SwiftUI

enum BrowserSidebarLayout {
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
        switch component.location {
        case .recents:
            Image(systemName: "clock")
                .frame(width: 16, height: 16)
        case let .fileSystem(url):
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 16, height: 16)
        case .archive:
            Image(systemName: "archivebox")
                .frame(width: 16, height: 16)
        }
    }
}

struct BrowserSidebar: View {
    @Bindable var browser: FileBrowserState
    @Bindable var sidebar: SidebarState
    let windowWidth: CGFloat
    @Binding var showingServerSheet: Bool
    let restoreContentFocus: () -> Void

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

            Section("Favorites") {
                ForEach(sidebar.favorites) { destination in
                    destinationRow(destination.name, destination.url, destination.systemImage)
                }
            }
            Section("Locations") {
                destinationRow(sidebar.userHome.name, sidebar.userHome.url, sidebar.userHome.systemImage)
                ForEach(sidebar.localVolumes) { volume in
                    destinationRow(volume.name, volume.url, volume.kind == .removable ? "externaldrive" : "internaldrive")
                }
            }
            Section("Shared") {
                ForEach(sidebar.networkVolumes) { volume in
                    destinationRow(volume.name, volume.url, "network")
                }
                Button {
                    showingServerSheet = true
                    restoreContentFocus()
                } label: {
                    Label("Connect to Server…", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
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
        .task { await sidebar.refresh() }
    }

    private func destinationRow(_ name: String, _ url: URL, _ icon: String) -> some View {
        Button {
            restoreContentFocus()
            Task { await browser.navigateToSidebar(url, name: name) }
        } label: {
            HStack {
                Label(name, systemImage: icon)
                Spacer()
                if browser.pendingAuthorizationURL == url {
                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ServerConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var sidebar: SidebarState
    let didMount: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Connect to Server", systemImage: "network")
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
