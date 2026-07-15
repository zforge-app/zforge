import AppKit
import Foundation

struct SidebarVolume: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case internalDisk
        case removable
        case network
    }

    let url: URL
    let name: String
    let kind: Kind
    let ejectable: Bool

    var id: URL { url }
}

actor VolumeCatalogService {
    private let keys: Set<URLResourceKey> = [
        .volumeLocalizedNameKey,
        .volumeIsBrowsableKey,
        .volumeIsLocalKey,
        .volumeIsInternalKey,
        .volumeIsRemovableKey,
        .volumeIsEjectableKey,
        .volumeIsRootFileSystemKey
    ]

    func volumes() -> [SidebarVolume] {
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(keys),
            options: [.skipHiddenVolumes]
        ) ?? []

        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: keys),
                  values.volumeIsBrowsable != false else { return nil }
            let kind: SidebarVolume.Kind
            if values.volumeIsLocal == false {
                kind = .network
            } else if values.volumeIsRemovable == true || values.volumeIsEjectable == true {
                kind = .removable
            } else {
                kind = .internalDisk
            }
            return SidebarVolume(
                url: url,
                name: values.volumeLocalizedName ?? url.lastPathComponent,
                kind: kind,
                ejectable: values.volumeIsEjectable ?? false
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
