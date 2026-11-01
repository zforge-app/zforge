import Foundation
import SystemConfiguration
import UniformTypeIdentifiers

/// The Mac shown as Finder's computer item: its user-visible computer name and a
/// symbol for its model family. Nothing here is hardcoded to one Mac.
nonisolated enum ComputerIdentity {
    /// The name set in System Settings ▸ General ▸ Sharing, read on each call so a
    /// renamed Mac is shown the next time the sidebar or a window refreshes.
    static func name(locale: Locale? = nil) -> String {
        if let name = SCDynamicStoreCopyComputerName(nil, nil) as String?, !name.isEmpty {
            return name
        }
        if let name = Host.current().localizedName, !name.isEmpty {
            return name
        }
        return AppLocalization.string("Computer", locale: locale)
    }

    /// Symbol for this Mac, resolved once from its model code.
    static let systemImage = systemImage(forModelCode: modelCode)

    /// Maps a hardware model code (for example `Mac17,3`) to an SF Symbol through
    /// the system's device-model type hierarchy, the same data Finder uses for its
    /// model icon. Modern model codes do not name the family, so the code itself is
    /// never parsed.
    static func systemImage(forModelCode code: String?) -> String {
        guard let code, let type = UTType(
            tag: code, tagClass: UTTagClass(rawValue: "com.apple.device-model-code"), conformingTo: nil
        ) else { return "desktopcomputer" }
        func conforms(_ identifier: String) -> Bool {
            type.identifier == identifier || type.supertypes.contains { $0.identifier == identifier }
        }
        if conforms("com.apple.mac.laptop") { return "laptopcomputer" }
        if conforms("com.apple.macmini") { return "macmini" }
        if conforms("com.apple.macstudio") { return "macstudio" }
        if conforms("com.apple.macpro") { return "macpro.gen3" }
        return "desktopcomputer"
    }

    private static var modelCode: String? {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else { return nil }
        return string(fromNullTerminated: buffer)
    }

    /// A sysctl string value: UTF-8 up to the first null byte.
    static func string(fromNullTerminated buffer: [CChar]) -> String {
        String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}

nonisolated protocol VolumeCataloging: Sendable {
    func volumes() async -> [SidebarVolume]
}

extension VolumeCatalogService: VolumeCataloging {}

/// Contents of the computer level (Go ▸ Computer and the sidebar computer item),
/// as in Finder's Computer window: every browsable mounted volume and Network.
/// Network is always listed: on current macOS it is a virtual node (there is no
/// `/Network` folder), browsed by `NetworkLevelCatalog`.
enum ComputerLevelCatalog {
    static func items(volumes: [SidebarVolume], locale: Locale? = nil) -> [BrowserItem] {
        volumes.map { item(url: $0.url, name: $0.name, type: .volume) } + [NetworkLevelCatalog.networkItem(locale: locale)]
    }

    private static func item(url: URL, name: String, type: UTType) -> BrowserItem {
        BrowserItem(
            id: BrowserItemID(rawValue: "file:\(url.standardizedFileURL.path)"),
            name: name,
            location: .fileSystem(url),
            isContainer: true,
            isDirectory: true,
            isPackage: false,
            isSymbolicLink: false,
            isHidden: false,
            isArchive: false,
            size: nil,
            packedSize: nil,
            creationDate: nil,
            modificationDate: nil,
            accessDate: nil,
            tags: [],
            contentTypeIdentifier: type.identifier,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
    }
}
