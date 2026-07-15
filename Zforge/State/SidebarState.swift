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
        let manager = FileManager.default
        let home = manager.homeDirectoryForCurrentUser
        return [
            SidebarDestination(name: String(localized: "Home"), url: home, systemImage: "house", kind: .favorite),
            destination("Desktop", .desktopDirectory, "menubar.dock.rectangle"),
            destination("Documents", .documentDirectory, "doc.on.doc"),
            destination("Downloads", .downloadsDirectory, "arrow.down.circle"),
            SidebarDestination(name: String(localized: "Applications"), url: URL(fileURLWithPath: "/Applications"), systemImage: "square.grid.2x2", kind: .favorite)
        ]
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

    private func destination(_ name: String.LocalizationValue, _ directory: FileManager.SearchPathDirectory, _ icon: String) -> SidebarDestination {
        let url = FileManager.default.urls(for: directory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return SidebarDestination(name: String(localized: name), url: url, systemImage: icon, kind: .favorite)
    }
}
