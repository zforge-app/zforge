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
    /// The volume can be ejected or unmounted by the user, as Finder offers: removable media,
    /// ejectable media (USB drives, disk images), external disks and network volumes. The boot
    /// volume and internal disks are never ejectable. Drives the sidebar eject button and the
    /// sidebar Eject menu item; eject through `FileBrowserState.ejectVolume(at:name:)`.
    let isEjectable: Bool
    /// The media is physically removable (`volumeIsRemovableKey`), e.g. a USB flash drive or SD card.
    let isRemovable: Bool
    /// The volume mounted at `/` (Macintosh HD); the sidebar never offers to eject it.
    var isRootFileSystem = false

    var id: URL { url }

    /// The sidebar row symbol: a network globe for shares, an external drive for removable and
    /// ejectable media, an internal drive otherwise.
    var sidebarSymbol: String {
        switch kind {
        case .network: "network"
        case .removable: "externaldrive"
        case .internalDisk: "internaldrive"
        }
    }

    /// Resource keys that `isEjectable(_:)` reads.
    nonisolated static let ejectabilityKeys: Set<URLResourceKey> = [
        .volumeIsLocalKey,
        .volumeIsInternalKey,
        .volumeIsRemovableKey,
        .volumeIsEjectableKey,
        .volumeIsRootFileSystemKey
    ]

    /// The single ejectability policy shared by the sidebar and the File ▸ Eject command.
    nonisolated static func isEjectable(_ values: URLResourceValues) -> Bool {
        isEjectable(isRootFileSystem: values.volumeIsRootFileSystem, isEjectable: values.volumeIsEjectable,
                    isRemovable: values.volumeIsRemovable, isLocal: values.volumeIsLocal,
                    isInternal: values.volumeIsInternal)
    }

    nonisolated static func isEjectable(isRootFileSystem: Bool?, isEjectable: Bool?, isRemovable: Bool?,
                                        isLocal: Bool?, isInternal: Bool?) -> Bool {
        guard isRootFileSystem != true else { return false }
        return isEjectable == true || isRemovable == true || isLocal == false || isInternal == false
    }
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
                isEjectable: SidebarVolume.isEjectable(values),
                isRemovable: values.volumeIsRemovable == true,
                isRootFileSystem: values.volumeIsRootFileSystem == true
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

/// Unmount-and-eject backend for `FileBrowserState.ejectVolume(at:name:)`.
nonisolated enum VolumeEjection {
    /// `NSWorkspace.unmountAndEjectDevice(at:)` blocks until Disk Arbitration answers (seconds for
    /// a slow or busy drive), so it runs on a detached task instead of the main actor.
    static func eject(_ volumeURL: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volumeURL)
        }.value
    }

    /// Whether an eject failure means a process still holds the volume (open files or a working
    /// directory), including Disk Arbitration's busy status wrapped in an underlying error.
    static func isInUse(_ error: Error) -> Bool {
        let busyCodes: Set<Int> = [
            Int(EBUSY),
            -47, // fBsyErr
            Int(Int32(bitPattern: 0xF8DA_0002)) // kDAReturnBusy
        ]
        var current: NSError? = error as NSError
        while let error = current {
            if [NSPOSIXErrorDomain, NSOSStatusErrorDomain].contains(error.domain) || error.domain.hasPrefix("DA"),
               busyCodes.contains(error.code) {
                return true
            }
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return false
    }
}
