import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// The Network level of the computer level (Finder's Network window): file servers
/// discovered over Bonjour, opened through the system's connect flow.
@Suite("Network level")
@MainActor
struct NetworkLevelTests {
    @MainActor
    private struct Fixture {
        let root: URL
        let volume: URL
        let share: URL
        let defaults: UserDefaults
        let suite: String
        let browser: ControlledNetworkBrowser
        let mounter: StubNetworkMounter
        let state: FileBrowserState

        func tearDown() {
            state.close()
            defaults.removeTestSuite(named: suite)
            try? FileManager.default.removeItem(at: root)
        }

        func networkItem() throws -> BrowserItem {
            try #require(state.items.first { $0.location == .network })
        }
    }

    private static let english = Locale(identifier: "en")

    private func fixture(mountResult: StubNetworkMounter.Result? = nil) throws -> Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("NetworkLevel-\(UUID().uuidString)")
        let volume = root.appendingPathComponent("Macintosh HD", isDirectory: true)
        let share = root.appendingPathComponent("Media", isDirectory: true)
        for folder in [volume, share.appendingPathComponent("Movies")] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let suite = "ZforgeTestSuite.NetworkLevelTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let browser = ControlledNetworkBrowser()
        let mounter = StubNetworkMounter(result: mountResult ?? .mounted(share))
        let state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(), grants: GrantedAccess(),
            archives: NativeSevenZipArchiveEngine(),
            volumes: SingleVolumeCatalog(volume: SidebarVolume(url: volume, name: "Macintosh HD", kind: .internalDisk,
                                                                 isEjectable: false, isRemovable: false)),
            networkBrowser: browser, networkMounter: mounter
        )
        return Fixture(root: root, volume: volume, share: share, defaults: defaults, suite: suite,
                       browser: browser, mounter: mounter, state: state)
    }

    private static func server(_ name: String, _ services: Set<NetworkServer.Service> = [.smb]) -> NetworkServer {
        NetworkServer(name: name, domain: "local.", services: services)
    }

    /// Lets the window's discovery task consume what the controlled browser yielded. Bounded
    /// by turns of the main actor, not by time.
    private func settle(_ condition: () -> Bool, _ comment: Comment) async {
        for _ in 0..<1_000 where !condition() { await Task.yield() }
        #expect(condition(), comment)
    }

    private func openNetwork(_ fixture: Fixture) async throws {
        await fixture.state.navigateToComputer()
        await fixture.state.open(try fixture.networkItem())
        await settle({ fixture.browser.runs == 1 }, "Discovery starts with the Network level")
    }

    // MARK: Servers

    @Test("A server connects over SMB through its Bonjour address, AFP only when it offers nothing else")
    func serverAddress() {
        #expect(Self.server("Studio NAS").mountURL.absoluteString == "smb://Studio%20NAS._smb._tcp.local")
        #expect(Self.server("Old.Mac", [.afp]).mountURL.absoluteString == "afp://Old%2EMac._afpovertcp._tcp.local")
        #expect(Self.server("Both", [.afp, .smb]).preferredService == .smb)
    }

    @Test("Servers are read-only, non-expanding entries with the system file-server type")
    func serverItems() {
        let items = NetworkLevelCatalog.items(servers: [Self.server("Studio NAS")])
        let item = items[0]
        #expect(item.name == "Studio NAS")
        #expect(item.location == .networkServer(Self.server("Studio NAS").mountURL))
        #expect(item.contentTypeIdentifier == NetworkLevelCatalog.serverTypeIdentifier)
        #expect(!item.isContainer && !item.isNavigableContainer && !item.canExpandInlineInList)
        #expect(item.localURL == nil && item.isNetworkEntry && item.usesStaticIconPreview)
    }

    // MARK: Navigation

    @Test("Network opens below the computer level in every view mode, read-only and titled Network",
          arguments: BrowserViewMode.allCases)
    func opensNetworkLevel(mode: BrowserViewMode) async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = mode
        try await openNetwork(fixture)
        #expect(state.location == .network)
        #expect(state.title == "Network")
        #expect(state.pathComponents.map(\.location) == [.computer, .network])
        #expect(state.breadcrumbComponents.map(\.name) == [ComputerIdentity.name(locale: Self.english), "Network"])
        #expect(state.items.isEmpty)
        #expect(state.currentDirectoryURL == nil)
        #expect(state.fileOperationDestinationURL == nil)
        #expect(!state.canModifyCurrentDirectory)
        #expect(state.error == nil)
    }

    @Test("Go ▸ Network opens the level below the computer, and Enclosing Folder returns to it")
    func goMenuNetwork() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = .columns
        await state.navigateToSidebar(fixture.volume, name: "Macintosh HD")
        await state.navigateToNetwork()
        #expect(state.pathComponents.map(\.location) == [.computer, .network])
        #expect(state.sortedColumnItems(at: .computer).map(\.name) == ["Macintosh HD", "Network"])
        #expect(state.columnSelections[.computer] == NetworkLevelCatalog.networkItemID)
        await settle({ fixture.browser.runs == 1 }, "Go ▸ Network starts discovery")

        await state.goUp()
        #expect(state.location == .computer)
        await settle({ fixture.browser.terminations == 1 }, "Leaving the Network level stops discovery")
        await state.goBack()
        #expect(state.location == .network)
        await state.goBack()
        #expect(state.location == .fileSystem(fixture.volume))
    }

    @Test("Back and Forward stop and restart discovery with the level")
    func historyRestartsDiscovery() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        await state.goBack()
        #expect(state.location == .computer)
        await settle({ fixture.browser.terminations == 1 }, "Back stops discovery")
        await state.goForward()
        #expect(state.location == .network)
        await settle({ fixture.browser.runs == 2 }, "Forward starts a new discovery")
        #expect(fixture.browser.terminations == 1)
    }

    @Test("Columns show Network beside the computer column; opening a volume stops discovery")
    func columnsNetworkLevel() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = .columns
        await state.navigateToComputer()
        await state.activateColumnItem(try fixture.networkItem(), in: .computer).value
        #expect(state.pathComponents.map(\.location) == [.computer, .network])
        await settle({ fixture.browser.runs == 1 }, "The Network column starts discovery")
        fixture.browser.send(.servers([Self.server("Studio NAS")]))
        await settle({ state.sortedColumnItems(at: .network).map(\.name) == ["Studio NAS"] }, "Servers fill the column")

        let volume = try #require(state.sortedColumnItems(at: .computer).first { $0.name == "Macintosh HD" })
        await state.activateColumnItem(volume, in: .computer).value
        #expect(state.pathComponents.map(\.location) == [.computer, .fileSystem(fixture.volume)])
        await settle({ fixture.browser.terminations == 1 }, "Closing the Network column stops discovery")
    }

    // MARK: Discovery

    @Test("Servers appear and disappear live, keeping the selection of the ones that remain")
    func liveUpdates() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        fixture.browser.send(.servers([Self.server("Archive"), Self.server("Studio NAS")]))
        await settle({ state.sortedItems.map(\.name) == ["Archive", "Studio NAS"] }, "Both servers appear")

        let archive = try #require(state.items.first { $0.name == "Archive" })
        let studio = try #require(state.items.first { $0.name == "Studio NAS" })
        state.selection = [archive.id, studio.id]
        fixture.browser.send(.servers([Self.server("Studio NAS")]))
        await settle({ state.items.map(\.name) == ["Studio NAS"] }, "The departed server disappears")
        #expect(state.selection == [studio.id])

        fixture.browser.send(.servers([]))
        await settle({ state.items.isEmpty }, "The level empties")
        #expect(state.selection.isEmpty)
        #expect(!state.networkDiscoveryDenied)
    }

    @Test("Denied Local Network access is reported instead of servers")
    func deniedAccess() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        fixture.browser.send(.denied)
        await settle({ state.networkDiscoveryDenied }, "Denial is published")
        #expect(state.items.isEmpty)

        await state.goBack()
        #expect(!state.networkDiscoveryDenied)
    }

    @Test("Closing the window stops discovery")
    func closeStopsDiscovery() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        try await openNetwork(fixture)
        fixture.state.close()
        await settle({ fixture.browser.terminations == 1 }, "Closing stops discovery")
    }

    // MARK: Connecting

    @Test("Opening a server mounts its address and opens the mounted share")
    func openServerMountsAndNavigates() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        let server = Self.server("Studio NAS")
        fixture.browser.send(.servers([server]))
        await settle({ state.items.count == 1 }, "The server appears")

        await state.open(try #require(state.items.first))
        #expect(await fixture.mounter.requests == [server.mountURL])
        #expect(state.location == .fileSystem(fixture.share))
        #expect(state.items.map(\.name) == ["Movies"])
        await settle({ fixture.browser.terminations == 1 }, "Leaving for the share stops discovery")
        await state.goBack()
        #expect(state.location == .network)
    }

    @Test("A failed connection keeps the Network level and explains the failure")
    func failedConnection() async throws {
        let fixture = try fixture(mountResult: .failure)
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        fixture.browser.send(.servers([Self.server("Studio NAS")]))
        await settle({ state.items.count == 1 }, "The server appears")

        await state.open(try #require(state.items.first))
        #expect(state.location == .network)
        #expect(state.error == .unavailable("The server could not be opened."))
        fixture.browser.send(.servers([Self.server("Studio NAS"), Self.server("Archive")]))
        await settle({ state.items.count == 2 }, "Discovery keeps updating")
        #expect(state.error != nil, "A discovery update does not clear the shown error")
    }

    @Test("Leaving the Network level while connecting cancels the wait without navigating")
    func leavingCancelsConnection() async throws {
        let fixture = try fixture(mountResult: .pending)
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        fixture.browser.send(.servers([Self.server("Studio NAS")]))
        await settle({ state.items.count == 1 }, "The server appears")
        let server = try #require(state.items.first)

        let opening = Task { await state.open(server) }
        for _ in 0..<1_000 {
            if await !fixture.mounter.requests.isEmpty { break }
            await Task.yield()
        }
        #expect(await fixture.mounter.requests.count == 1)
        await state.navigateToComputer()
        await opening.value
        #expect(await fixture.mounter.cancellations == 1)
        #expect(state.location == .computer)
        #expect(state.error == nil)
    }

    // MARK: Add Remote

    /// Hosts the production Network bar in a window, as the browser window shows it.
    private static func withHostedBar<T>(_ state: FileBrowserState, _ body: (NSView) throws -> T) rethrows -> T {
        let size = CGSize(width: 480, height: 60)
        let host = NSHostingView(rootView: NetworkLevelBar(state: state).environment(\.locale, english))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        return try body(host)
    }

    @Test("Add Remote is shown above the Network level in every view mode, with or without servers",
          arguments: BrowserViewMode.allCases)
    func addRemoteInEveryMode(mode: BrowserViewMode) async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = mode
        await state.navigateToComputer()
        #expect(!NetworkLevelBar.isShown(for: state), "The computer level has no Add Remote")

        await state.open(try fixture.networkItem())
        await settle({ fixture.browser.runs == 1 }, "Discovery starts with the Network level")
        #expect(NetworkLevelBar.isShown(for: state), "Add Remote is shown before any server is found")
        let emptyHeight = Self.withHostedBar(state) { $0.fittingSize.height }
        #expect(emptyHeight > 0)

        fixture.browser.send(.servers([Self.server("Studio NAS")]))
        await settle({ state.items.count == 1 }, "The server appears")
        #expect(NetworkLevelBar.isShown(for: state))
        #expect(Self.withHostedBar(state) { $0.fittingSize.height } == emptyHeight,
                "The bar keeps its size as servers appear, so the content does not jump")

        fixture.browser.send(.servers([]))
        await settle({ state.items.isEmpty }, "The server disappears")
        #expect(NetworkLevelBar.isShown(for: state), "Add Remote stays after the last server leaves")

        fixture.browser.send(.denied)
        await settle({ state.networkDiscoveryDenied }, "Denial is published")
        #expect(NetworkLevelBar.isShown(for: state), "Add Remote connects by address even without Local Network access")

        await state.goUp()
        #expect(!NetworkLevelBar.isShown(for: state), "Leaving the Network level removes Add Remote")
    }

    @Test("Add Remote opens the window's connect-to-server sheet, the same entry point as Go ▸ Remote")
    func addRemoteOpensServerSheet() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        try await openNetwork(fixture)
        #expect(!state.showingServerConnection)

        // Offscreen hosting has no accessibility client to press the SwiftUI button; the bar's own
        // action is run here, and the real click is covered by the UI test listed in REGRESSION-COVERAGE.
        NetworkLevelBar(state: state).addRemote()
        #expect(state.showingServerConnection, "Pressing Add Remote presents the connect-to-server sheet")
        #expect(state.location == .network, "Opening the sheet keeps the Network level")

        state.showingServerConnection = false
        state.showServerConnection()
        #expect(state.showingServerConnection, "Go ▸ Remote uses the same entry point")
    }

    // MARK: Entry points without a sidebar item (user request, 2026-11-09)

    @Test("Go ▸ Network from a folder opens Computer › Network; Back and Forward keep working and Up returns to the computer")
    func goNetworkHistory() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        await state.navigateToSidebar(fixture.volume, name: "Macintosh HD")
        await state.navigateToNetwork()
        #expect(state.location == .network)
        #expect(state.pathComponents.map(\.location) == [.computer, .network])
        await settle({ fixture.browser.runs == 1 }, "Discovery starts with the level")

        await state.goBack()
        #expect(state.location != .network, "Back leaves the Network level")
        await state.goForward()
        #expect(state.location == .network, "Forward returns to it")

        await state.goUp()
        #expect(state.location == .computer)
    }

    // MARK: Appearance

    @Test("Network and server icons, the Add Remote bar and the denied state in light and dark",
          arguments: ZforgeSnapshot.appearances.map(\.name))
    func snapshot(appearanceName: String) throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == appearanceName })
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let entries = [NetworkLevelCatalog.networkItem(locale: Self.english)]
            + NetworkLevelCatalog.items(servers: [Self.server("Studio NAS")])
        let view = VStack(spacing: 0) {
            NetworkLevelBar(state: fixture.state)
            HStack(spacing: 20) {
                ForEach(entries) { item in
                    VStack(spacing: 6) {
                        FileIconView(item: item, size: 64)
                        Text(verbatim: item.name).font(.callout)
                    }
                    .frame(width: 96)
                }
                NetworkLocalAccessDeniedView().frame(width: 300)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background)
        .environment(\.locale, Self.english)
        ZforgeSnapshot.assert(view, size: CGSize(width: 620, height: 280), appearance: appearance.appearance,
                              named: "network-\(appearance.name)")
    }
}

// MARK: - Doubles

/// Discovery driven by the test: every `updates()` call is one run, ended by the consumer.
private nonisolated final class ControlledNetworkBrowser: NetworkServerBrowsing, @unchecked Sendable {
    // Accessed only from the main actor: the window's discovery task and the test.
    private var continuation: AsyncStream<NetworkDiscoveryUpdate>.Continuation?
    private(set) var runs = 0
    private(set) var terminations = 0

    func updates() -> AsyncStream<NetworkDiscoveryUpdate> {
        runs += 1
        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in self.terminations += 1 }
            }
        }
    }

    func send(_ update: NetworkDiscoveryUpdate) {
        continuation?.yield(update)
    }
}

private actor StubNetworkMounter: NetworkServerMounting {
    enum Result: Sendable {
        case mounted(URL)
        case failure
        /// Waits until the requesting task is cancelled.
        case pending
    }

    private let result: Result
    private(set) var requests: [URL] = []
    private(set) var cancellations = 0

    init(result: Result) { self.result = result }

    func mount(_ url: URL) async throws -> URL {
        requests.append(url)
        switch result {
        case let .mounted(share):
            return share
        case .failure:
            throw NetworkServerMountError.couldNotOpen
        case .pending:
            do {
                try await Task.sleep(for: .seconds(3_600))
            } catch {
                cancellations += 1
                throw error
            }
            throw CancellationError()
        }
    }
}

private nonisolated struct SingleVolumeCatalog: VolumeCataloging {
    let volume: SidebarVolume
    func volumes() async -> [SidebarVolume] { [volume] }
}

private actor GrantedAccess: AccessGrantStoring {
    func hasGrant(for url: URL) -> Bool { true }
    func storeGrant(for url: URL) throws {}
    func activateGrant(for url: URL) throws -> URL { url }
    func removeGrant(for url: URL) {}
    func stopAll() {}
}
