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
        // A split archive inside an archive is measured by all of its volumes (ZF-83).
        if let setMeasure = item.archiveSetMeasure { return setMeasure }
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

/// Why an item inside an archive waits for Load Preview instead of being previewed (D-116).
nonisolated enum ArchiveManualPreviewReason: Sendable, Equatable {
    /// Automatic previews are off for archives on this volume (removable or network).
    case previewsOff(ArchiveVolumeKind)
    /// Preview solid archives is off and the item shares a solid block.
    case solidArchivesOff
    /// The item's size, or the block it is read from, is unknown.
    case unknownSize
    /// Reading the item costs more than `limit`; `readsMoreThanItem` when the measure is its
    /// solid block or split set rather than the item itself.
    case overLimit(Int64, readsMoreThanItem: Bool)
}

nonisolated extension ArchivePreviewLimits {
    /// Why the single-selection preview of `item` is not automatic; nil when it is.
    func manualPreviewReason(of item: BrowserItem, on volume: ArchiveVolumeKind) -> ArchiveManualPreviewReason? {
        guard case .archive = item.location else { return nil }
        guard let limit = previewLimit(on: volume) else { return .previewsOff(volume) }
        guard previewsSolidArchives || item.solidBlock == nil else { return .solidArchivesOff }
        guard let measure = Self.measure(of: item) else { return .unknownSize }
        guard measure > limit else { return nil }
        return .overLimit(limit, readsMoreThanItem: item.archiveSetMeasure != nil || item.solidBlock != nil)
    }

    /// The text under “Preview not loaded”.
    static func manualPreviewExplanation(_ reason: ArchiveManualPreviewReason?, locale: Locale?) -> String {
        switch reason {
        case let .overLimit(limit, readsMoreThanItem):
            let size = AppLocalization.byteCount(limit, locale: locale)
            return readsMoreThanItem
                ? AppLocalization.string("Previewing this item reads more than the \(size) preview limit set in Settings.", locale: locale)
                : AppLocalization.string("This item is larger than the \(size) preview limit set in Settings.", locale: locale)
        case .previewsOff(.removable):
            return AppLocalization.string("Previews of items in archives on removable drives are off in Settings.", locale: locale)
        case .previewsOff(.network):
            return AppLocalization.string("Previews of items in archives on network volumes are off in Settings.", locale: locale)
        case .solidArchivesOff:
            return AppLocalization.string("Previews of items in solid archives are off in Settings.", locale: locale)
        case .unknownSize:
            return AppLocalization.string("The size of this item is unknown, so it is not previewed automatically.", locale: locale)
        case .previewsOff(.internalDisk), nil:
            return AppLocalization.string("This item is not previewed automatically.", locale: locale)
        }
    }
}
