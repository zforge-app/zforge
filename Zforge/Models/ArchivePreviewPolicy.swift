import Foundation

/// Where an archive is stored, for the preview limits of its items (D-73).
nonisolated enum ArchiveVolumeKind: Sendable, Equatable {
    /// An internal disk of this Mac.
    case internalDisk
    /// A local volume that is not internal: USB flash drive, external disk, memory card.
    case removable
    /// A volume that is not local: SMB, AFP, NFS, WebDAV.
    case network

    static func classify(isLocal: Bool?, isInternal: Bool?) -> Self {
        if isLocal == false { return .network }
        return isInternal == false ? .removable : .internalDisk
    }

    /// The kind of the volume holding `url` (an internal disk when it cannot be read).
    static func of(_ url: URL) -> Self {
        let values = try? url.resourceValues(forKeys: [.volumeIsLocalKey, .volumeIsInternalKey])
        return classify(isLocal: values?.volumeIsLocal, isInternal: values?.volumeIsInternal)
    }
}

/// The automatic preview and thumbnail limits for items inside archives (D-73). Explicit
/// actions (Quick Look, Open, the manual load action) are not limited; files outside
/// archives are not concerned.
nonisolated struct ArchivePreviewLimits: Sendable, Equatable {
    static let previewRange: ClosedRange<Int64> = 32_000_000...2_000_000_000
    static let thumbnailRange: ClosedRange<Int64> = 4_000_000...64_000_000
    static let defaults = ArchivePreviewLimits(
        previewLimit: 512_000_000, thumbnailLimit: 8_000_000, previewsSolidArchives: true,
        previewsOnRemovableVolumes: false, removableLimit: 32_000_000,
        previewsOnNetworkVolumes: false, networkLimit: 32_000_000
    )

    var previewLimit: Int64
    var thumbnailLimit: Int64
    var previewsSolidArchives: Bool
    var previewsOnRemovableVolumes: Bool
    var removableLimit: Int64
    var previewsOnNetworkVolumes: Bool
    var networkLimit: Int64

    /// What an automatic preview or thumbnail of the item costs to read: the item itself,
    /// or the compressed block it is decoded from (the whole archive for compressed tar and
    /// single-file streams). Nil when unknown.
    static func measure(of item: BrowserItem) -> Int64? {
        if let block = item.solidBlock { return block.packedSize }
        return item.size
    }

    /// The preview limit on this volume; nil when automatic previews are off there.
    func previewLimit(on volume: ArchiveVolumeKind) -> Int64? {
        switch volume {
        case .internalDisk: previewLimit
        case .removable: previewsOnRemovableVolumes ? removableLimit : nil
        case .network: previewsOnNetworkVolumes ? networkLimit : nil
        }
    }

    /// The thumbnail limit on this volume: the thumbnail limit, never above the volume's.
    func thumbnailLimit(on volume: ArchiveVolumeKind) -> Int64? {
        guard let volumeLimit = previewLimit(on: volume) else { return nil }
        return volume == .internalDisk ? thumbnailLimit : min(thumbnailLimit, volumeLimit)
    }

    func allowsAutomaticPreview(of item: BrowserItem, on volume: ArchiveVolumeKind) -> Bool {
        allows(item, limit: previewLimit(on: volume))
    }

    func allowsAutomaticThumbnail(of item: BrowserItem, on volume: ArchiveVolumeKind) -> Bool {
        allows(item, limit: thumbnailLimit(on: volume))
    }

    private func allows(_ item: BrowserItem, limit: Int64?) -> Bool {
        guard case .archive = item.location else { return true }
        guard let limit, previewsSolidArchives || item.solidBlock == nil,
              let measure = Self.measure(of: item) else { return false }
        return measure <= limit
    }
}
