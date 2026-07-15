import AppKit
import SwiftUI

struct BrowserBreadcrumb: View {
    @Bindable var state: FileBrowserState

    private let endAnchorID = "breadcrumb-end"

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(state.pathComponents.enumerated()), id: \.element.id) { index, component in
                            if index > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            Button {
                                Task { await state.navigateExistingPath(to: component) }
                            } label: {
                                HStack(spacing: 5) {
                                    componentIcon(component)
                                    Text(component.name).lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(index == state.pathComponents.count - 1 ? .primary : .secondary)
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
                .onChange(of: state.pathComponents) {
                    scrollToEnd(proxy, animated: true)
                }
                .onChange(of: geometry.size.width) {
                    scrollToEnd(proxy, animated: false)
                }
            }
        }
        .frame(height: 34)
        .background(Color(nsColor: .underPageBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(endAnchorID, anchor: .trailing)
                }
            } else {
                proxy.scrollTo(endAnchorID, anchor: .trailing)
            }
        }
    }

    @ViewBuilder
    private func componentIcon(_ component: BrowserPathComponent) -> some View {
        switch component.location {
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
    @Binding var showingServerSheet: Bool
    let restoreContentFocus: () -> Void

    var body: some View {
        List {
            Section("Favorites") {
                ForEach(sidebar.favorites) { destination in
                    destinationRow(destination.name, destination.url, destination.systemImage)
                }
            }
            Section("Locations") {
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
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
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
