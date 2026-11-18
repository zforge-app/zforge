import AppKit
import Foundation
import NetFS
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

nonisolated enum NetworkServerMountError: Error, Equatable {
    case couldNotOpen
    /// NetFS refused the mount: a POSIX error (positive) or an `OSStatus` (negative).
    case failed(status: Int32)
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

/// Mounts with NetFS inside Zforge, so connecting never opens a Finder window. The system's
/// NetAuth agent shows its own sign-in and share-selection dialogs. With no mount path,
/// NetAuthSysAgent lets a sandboxed caller mount under `/Volumes`, as Finder does; a custom
/// mount path outside the app container would need Full Disk Access. Cancelling the requesting
/// task cancels the pending mount request and closes those dialogs.
nonisolated struct NetFSNetworkServerMounter: NetworkServerMounting {
    func mount(_ url: URL) async throws -> URL {
        if let mounted = MountedNetworkShares.share(of: url) { return mounted }
        let request = NetFSMountRequest(url: url)
        let outcome = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in request.start(continuation) }
        } onCancel: {
            request.cancel()
        }
        switch outcome {
        case let .mounted(paths):
            guard let path = paths.first else { throw NetworkServerMountError.couldNotOpen }
            return MountedNetworkShares.location(in: URL(fileURLWithPath: path, isDirectory: true), for: url)
        case .alreadyMounted:
            // The share is mounted under another address of the server (e.g. Bonjour name vs IP).
            guard let mounted = MountedNetworkShares.share(of: url) else { throw NetworkServerMountError.couldNotOpen }
            return mounted
        case .cancelled:
            throw CancellationError()
        case let .failed(status):
            throw NetworkServerMountError.failed(status: status)
        }
    }
}

/// One `NetFSMountURLAsync` request. NetFS never calls the completion block of a cancelled request,
/// so `cancel()` resumes the waiting task itself; whichever of the two finishes first wins.
private nonisolated final class NetFSMountRequest: @unchecked Sendable {
    enum Outcome: Sendable {
        case mounted([String])
        case alreadyMounted
        case cancelled
        case failed(Int32)
    }

    /// `userCanceledErr`: the user closed the system sign-in or share dialog.
    private static let userCancelled: Int32 = -128
    private static let queue = DispatchQueue(label: "io.libor.Zforge.network-mount")

    private let url: URL
    private let lock = NSLock()
    private var requestID: AsyncRequestID?
    private var isCancelled = false
    private var continuation: CheckedContinuation<Outcome, Never>?

    init(url: URL) { self.url = url }

    func start(_ continuation: CheckedContinuation<Outcome, Never>) {
        lock.lock()
        guard !isCancelled else {
            lock.unlock()
            continuation.resume(returning: .cancelled)
            return
        }
        self.continuation = continuation
        lock.unlock()

        let openOptions = NSMutableDictionary()
        openOptions[kNAUIOptionKey] = kNAUIOptionAllowUI
        var id: AsyncRequestID?
        let status = NetFSMountURLAsync(url as CFURL, nil, nil, nil, openOptions, nil, &id, Self.queue) { [self] status, _, mountpoints in
            finish(Self.outcome(status: status, mountpoints: mountpoints))
        }
        guard status == 0 else {
            finish(Self.outcome(status: status, mountpoints: nil))
            return
        }
        lock.lock()
        requestID = id
        let cancelNow = isCancelled
        lock.unlock()
        if cancelNow, let id { _ = NetFSMountURLCancel(id) }
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let id = requestID
        lock.unlock()
        if let id { _ = NetFSMountURLCancel(id) }
        finish(.cancelled)
    }

    private func finish(_ outcome: Outcome) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: outcome)
    }

    private static func outcome(status: Int32, mountpoints: CFArray?) -> Outcome {
        switch status {
        case 0: .mounted((mountpoints as? [String]) ?? [])
        case EEXIST: .alreadyMounted
        case userCancelled, ECANCELED: .cancelled
        default: .failed(status)
        }
    }
}

/// Finds mounted network shares by the address they were mounted from (`volumeURLForRemounting`).
nonisolated enum MountedNetworkShares {
    /// The mounted share of `url`'s server: the same host and, when the address names a share, that
    /// share (hosts and share names compare case-insensitively). An address without a share matches
    /// any mounted share of the host.
    static func share(of url: URL) -> URL? {
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeURLForRemountingKey], options: [.skipHiddenVolumes]
        ) ?? []
        return volumes.lazy.compactMap { volume -> URL? in
            guard let remount = try? volume.resourceValues(forKeys: [.volumeURLForRemountingKey]).volumeURLForRemounting,
                  matches(remount, address: url) else { return nil }
            return location(in: volume, for: url)
        }.first
    }

    static func matches(_ remount: URL, address: URL) -> Bool {
        guard let host = address.host(percentEncoded: false)?.lowercased(), !host.isEmpty,
              remount.host(percentEncoded: false)?.lowercased() == host else { return false }
        guard let share = shareName(of: address) else { return true }
        return shareName(of: remount)?.lowercased() == share.lowercased()
    }

    /// The folder to open in a mounted share: the share root, or the folder below it that the
    /// address names (`smb://server/share/Projects`) when it exists.
    static func location(in mountPoint: URL, for address: URL) -> URL {
        let components = pathComponents(of: address).dropFirst()
        guard !components.isEmpty else { return mountPoint }
        let folder = components.reduce(mountPoint) { $0.appendingPathComponent($1, isDirectory: true) }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) && isDirectory.boolValue
            ? folder : mountPoint
    }

    private static func shareName(of url: URL) -> String? { pathComponents(of: url).first }

    private static func pathComponents(of url: URL) -> [String] {
        url.path(percentEncoded: false).split(separator: "/").map(String.init)
    }
}

/// Parses what the user typed in the Remote sheet, as Finder's Connect to Server does: an
/// `smb://`, `afp://` or `nfs://` address with a server, or a bare server name or IP address
/// (optionally followed by a share path), which connects over SMB.
nonisolated enum ServerAddress {
    static let schemes: Set<String> = ["smb", "afp", "nfs"]

    static func url(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let address = trimmed.contains("://") ? trimmed : "smb://\(trimmed)"
        guard let url = URL(string: address), let scheme = url.scheme?.lowercased(), schemes.contains(scheme),
              let host = url.host(percentEncoded: false), !host.isEmpty else { return nil }
        return url
    }
}
