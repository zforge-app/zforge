import AppKit
import Foundation
import Network
import UniformTypeIdentifiers
import os

/// A file server advertised over Bonjour on the local network, as Finder's Network
/// window lists it. A server advertising both SMB and AFP is a single entry.
nonisolated struct NetworkServer: Hashable, Sendable {
    enum Service: String, Hashable, Sendable, CaseIterable {
        case smb = "_smb._tcp"
        case afp = "_afpovertcp._tcp"

        var scheme: String {
            switch self {
            case .smb: "smb"
            case .afp: "afp"
            }
        }
    }

    let name: String
    let domain: String
    let services: Set<Service>

    /// SMB when advertised: Finder connects with it, and AFP is deprecated.
    var preferredService: Service { services.contains(.smb) ? .smb : .afp }

    /// The Bonjour address Finder connects to, e.g. `smb://Studio%20NAS._smb._tcp.local`.
    /// The service name is percent-encoded except for letters, digits, `-` and `_`, so a
    /// dot or space in the name cannot split the host.
    var mountURL: URL {
        let service = preferredService
        let domain = domain.hasSuffix(".") ? String(domain.dropLast()) : domain
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_")
        let host = name.addingPercentEncoding(withAllowedCharacters: allowed) ?? name
        // Only ASCII letters, digits and percent escapes remain, so the address always parses.
        return URL(string: "\(service.scheme)://\(host).\(service.rawValue).\(domain.isEmpty ? "local" : domain)")!
    }
}

nonisolated enum NetworkDiscoveryUpdate: Equatable, Sendable {
    /// Every server currently advertised, sorted by name.
    case servers([NetworkServer])
    /// Local Network privacy (System Settings ▸ Privacy & Security ▸ Local Network) blocks browsing.
    case denied
}

/// Live discovery of the servers shown in the Network level. Ending the iteration
/// (cancelling the consuming task) stops browsing.
nonisolated protocol NetworkServerBrowsing: Sendable {
    func updates() -> AsyncStream<NetworkDiscoveryUpdate>
}

/// Connects to a discovered server and returns the root of the share that was mounted.
nonisolated protocol NetworkServerMounting: Sendable {
    func mount(_ url: URL) async throws -> URL
}

nonisolated enum NetworkServerMountError: Error {
    case couldNotOpen
}

// MARK: - Network level contents

/// Contents of the Network level (Go ▸ Network and the Network item of the computer
/// level): the discovered servers, with the system network and file-server icons.
enum NetworkLevelCatalog {
    nonisolated static let networkTypeIdentifier = "com.apple.network-neighborhood"
    nonisolated static let serverTypeIdentifier = "com.apple.file-server"
    nonisolated static let networkItemID = BrowserItemID(rawValue: "network:")

    /// The Network entry of the computer level. Always present: Finder's Network is a
    /// virtual node, not a folder on disk.
    nonisolated static func networkItem(locale: Locale? = nil) -> BrowserItem {
        item(id: networkItemID, name: AppLocalization.string("Network", locale: locale), location: .network,
             isContainer: true, type: networkTypeIdentifier)
    }

    nonisolated static func items(servers: [NetworkServer]) -> [BrowserItem] {
        servers.map { server in
            let url = server.mountURL
            // Opening a server connects to it instead of listing it, so it is not a container:
            // a single click in Columns only selects it.
            return item(id: BrowserItemID(rawValue: "network-server:\(url.absoluteString)"), name: server.name,
                        location: .networkServer(url), isContainer: false, type: serverTypeIdentifier)
        }
    }

    /// The system icon of a Network level entry, or `nil` for any other item.
    @MainActor static func icon(for item: BrowserItem) -> NSImage? {
        guard item.isNetworkEntry, let identifier = item.contentTypeIdentifier else { return nil }
        return icon(forType: identifier)
    }

    @MainActor static var networkIcon: NSImage { icon(forType: networkTypeIdentifier) }

    @MainActor private static var icons: [String: NSImage] = [:]

    @MainActor private static func icon(forType identifier: String) -> NSImage {
        if let cached = icons[identifier] { return cached }
        let icon = UTType(identifier).map { NSWorkspace.shared.icon(for: $0) } ?? NSWorkspace.shared.icon(for: .folder)
        icons[identifier] = icon
        return icon
    }

    nonisolated private static func item(
        id: BrowserItemID, name: String, location: BrowserLocation, isContainer: Bool, type: String
    ) -> BrowserItem {
        BrowserItem(
            id: id,
            name: name,
            location: location,
            isContainer: isContainer,
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
            contentTypeIdentifier: type,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
    }
}

nonisolated extension BrowserItem {
    /// The Network item and the discovered servers: virtual, read-only entries without a file.
    var isNetworkEntry: Bool {
        switch location {
        case .network, .networkServer: true
        case .recents, .computer, .fileSystem, .archive: false
        }
    }
}

// MARK: - Bonjour discovery

/// Browses `_smb._tcp` and `_afpovertcp._tcp` in the local domain with `NWBrowser`.
/// Needs `NSBonjourServices` and `NSLocalNetworkUsageDescription` in Info.plist; the
/// first browse shows the system Local Network prompt.
nonisolated struct BonjourNetworkServerBrowser: NetworkServerBrowsing {
    func updates() -> AsyncStream<NetworkDiscoveryUpdate> {
        AsyncStream { continuation in
            let session = BonjourBrowseSession(continuation: continuation)
            continuation.onTermination = { _ in session.cancel() }
            session.start()
        }
    }
}

/// One discovery run. All mutable state is confined to `queue`, where `NWBrowser`
/// delivers its callbacks.
private nonisolated final class BonjourBrowseSession: @unchecked Sendable {
    private struct ServiceKey: Hashable {
        let name: String
        let domain: String
    }

    private static let logger = Logger(subsystem: "io.libor.Zforge", category: "NetworkDiscovery")
    /// `kDNSServiceErr_PolicyDenied`: Local Network access was refused.
    private static let policyDenied: Int32 = -65570

    private let queue = DispatchQueue(label: "io.libor.Zforge.network-discovery")
    private let continuation: AsyncStream<NetworkDiscoveryUpdate>.Continuation
    private var browsers: [NWBrowser] = []
    private var results: [NetworkServer.Service: Set<ServiceKey>] = [:]
    private var isCancelled = false

    init(continuation: AsyncStream<NetworkDiscoveryUpdate>.Continuation) {
        self.continuation = continuation
    }

    func start() {
        queue.async { [self] in
            guard !isCancelled else { return }
            for service in NetworkServer.Service.allCases {
                let browser = NWBrowser(for: .bonjour(type: service.rawValue, domain: "local."), using: .tcp)
                browser.browseResultsChangedHandler = { [weak self] results, _ in
                    self?.update(service, results: results)
                }
                browser.stateUpdateHandler = { [weak self] state in
                    self?.handle(state, service: service)
                }
                browser.start(queue: queue)
                browsers.append(browser)
            }
        }
    }

    func cancel() {
        queue.async { [self] in
            isCancelled = true
            browsers.forEach { $0.cancel() }
            browsers.removeAll()
        }
    }

    private func update(_ service: NetworkServer.Service, results: Set<NWBrowser.Result>) {
        guard !isCancelled else { return }
        self.results[service] = Set(results.compactMap { result in
            guard case let .service(name, _, domain, _) = result.endpoint else { return nil }
            return ServiceKey(name: name, domain: domain)
        })
        continuation.yield(.servers(merged()))
    }

    private func handle(_ state: NWBrowser.State, service: NetworkServer.Service) {
        switch state {
        case let .waiting(error), let .failed(error):
            if case let .dns(code) = error, Int32(code) == Self.policyDenied {
                Self.logger.notice("Local Network access denied while browsing \(service.rawValue, privacy: .public)")
                continuation.yield(.denied)
            } else {
                Self.logger.error("Browsing \(service.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
        default:
            break
        }
    }

    /// One server per service name and domain, whichever protocols it advertises.
    private func merged() -> [NetworkServer] {
        var services: [ServiceKey: Set<NetworkServer.Service>] = [:]
        var names: [ServiceKey: ServiceKey] = [:]
        for (service, keys) in results {
            for key in keys {
                let folded = ServiceKey(name: key.name.lowercased(), domain: key.domain.lowercased())
                services[folded, default: []].insert(service)
                names[folded] = names[folded] ?? key
            }
        }
        return services.compactMap { folded, protocols in
            names[folded].map { NetworkServer(name: $0.name, domain: $0.domain, services: protocols) }
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Mounting

/// Mounts through the system's connect flow, the same one as the Shared ▸ Remote sheet:
/// `NSWorkspace.open` hands the address to the system, which authenticates, lets the
/// user pick a share and mounts it. Zforge then waits for the network volume's mount
/// notification; the wait ends when the requesting task is cancelled.
nonisolated struct WorkspaceNetworkServerMounter: NetworkServerMounting {
    func mount(_ url: URL) async throws -> URL {
        if let mounted = Self.mountedShare(of: url) { return mounted }
        let (mounts, continuation) = AsyncStream.makeStream(of: URL.self)
        let center = NSWorkspace.shared.notificationCenter
        let observer = center.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: nil) { note in
            if let volume = note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL { continuation.yield(volume) }
        }
        defer {
            center.removeObserver(observer)
            continuation.finish()
        }
        guard await MainActor.run(body: { NSWorkspace.shared.open(url) }) else {
            throw NetworkServerMountError.couldNotOpen
        }
        for await volume in mounts where Self.isNetworkVolume(volume) {
            return volume
        }
        throw CancellationError()
    }

    /// A share of this server that is already mounted, matched by the remount address's host.
    private static func mountedShare(of url: URL) -> URL? {
        guard let host = url.host(percentEncoded: false)?.lowercased() else { return nil }
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeURLForRemountingKey], options: [.skipHiddenVolumes]
        ) ?? []
        return volumes.first { volume in
            let remount = try? volume.resourceValues(forKeys: [.volumeURLForRemountingKey]).volumeURLForRemounting
            return remount?.host(percentEncoded: false)?.lowercased() == host
        }
    }

    private static func isNetworkVolume(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.volumeIsLocalKey]))?.volumeIsLocal == false
    }
}
