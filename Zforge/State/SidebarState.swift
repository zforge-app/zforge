import AppKit
import Foundation
import Observation

struct SidebarDestination: Identifiable, Hashable {
    enum Kind: Hashable { case favorite, local, removable, network }

    let name: String
    let url: URL
    let systemImage: String
    let kind: Kind
    var id: String { url.standardizedFileURL.path }
}

@MainActor
@Observable
final class SidebarState {
    @ObservationIgnored private let volumeService = VolumeCatalogService()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    var volumes: [SidebarVolume] = []
    var isConnecting = false
    var serverAddress = "smb://"
    var serverError: String?

    var favorites: [SidebarDestination] {
        return [
            destination("Desktop", UserDirectoryService.desktopURL, "menubar.dock.rectangle"),
            destination("Documents", UserDirectoryService.documentsURL, "doc.on.doc"),
            destination("Downloads", UserDirectoryService.downloadsURL, "arrow.down.circle"),
            SidebarDestination(name: String(localized: "Applications"), url: URL(fileURLWithPath: "/Applications"), systemImage: "square.grid.2x2", kind: .favorite)
        ]
    }

    var userHome: SidebarDestination {
        let url = UserDirectoryService.homeURL
        return SidebarDestination(
            name: url.lastPathComponent,
            url: url,
            systemImage: "house",
            kind: .local
        )
    }

    var localVolumes: [SidebarVolume] { volumes.filter { $0.kind != .network } }
    var networkVolumes: [SidebarVolume] { volumes.filter { $0.kind == .network } }

    init() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.didMountNotification,
            NSWorkspace.didUnmountNotification,
            NSWorkspace.didRenameVolumeNotification
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in await self?.refresh() }
            }
        }
    }

    func refresh() async {
        volumes = await volumeService.volumes()
    }

    func connectToServer() async -> URL? {
        serverError = nil
        guard let url = URL(string: serverAddress), ["smb", "afp", "nfs"].contains(url.scheme?.lowercased() ?? "") else {
            serverError = String(localized: "Use an smb://, afp://, or nfs:// address.")
            return nil
        }
        isConnecting = true
        let opened = NSWorkspace.shared.open(url)
        if !opened { serverError = String(localized: "The server could not be opened.") }
        try? await Task.sleep(for: .seconds(1))
        await refresh()
        isConnecting = false
        return networkVolumes.first?.url
    }

    private func destination(_ name: String.LocalizationValue, _ url: URL, _ icon: String) -> SidebarDestination {
        return SidebarDestination(name: String(localized: name), url: url, systemImage: icon, kind: .favorite)
    }
}
