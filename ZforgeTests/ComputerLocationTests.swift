import AppKit
import Foundation
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Zforge

/// The sidebar computer item and the computer level it opens (Go ▸ Computer):
/// mounted volumes and Network, as in Finder's Computer window.
@Suite("Computer item and computer level")
@MainActor
struct ComputerLocationTests {
    @MainActor
    private struct Fixture {
        let root: URL
        let volumeA: URL
        let volumeB: URL
        let defaults: UserDefaults
        let suite: String
        let volumes: StubVolumeCatalog
        let grants: StubComputerGrants
        let state: FileBrowserState

        func tearDown() {
            state.close()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: root)
        }
    }

    private func fixture(granted: Bool = true) throws -> Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ComputerLevel-\(UUID().uuidString)")
        let volumeA = root.appendingPathComponent("Volume A", isDirectory: true)
        let volumeB = root.appendingPathComponent("Volume B", isDirectory: true)
        for folder in [volumeA.appendingPathComponent("Inside"), volumeB] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let suite = "ComputerLocationTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let volumes = StubVolumeCatalog(
            volumes: [Self.volume(volumeA, "Macintosh HD"), Self.volume(volumeB, "Backup", kind: .removable)]
        )
        let grants = StubComputerGrants(granted: granted)
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults), fileSystem: FileSystemService(),
            grants: grants, archives: NativeSevenZipArchiveEngine(), volumes: volumes,
            networkBrowser: StubNetworkBrowser()
        )
        return Fixture(root: root, volumeA: volumeA, volumeB: volumeB, defaults: defaults, suite: suite,
                       volumes: volumes, grants: grants, state: state)
    }

    private static func volume(_ url: URL, _ name: String, kind: SidebarVolume.Kind = .internalDisk) -> SidebarVolume {
        SidebarVolume(url: url, name: name, kind: kind, isEjectable: kind == .removable, isRemovable: kind == .removable)
    }

    // MARK: Identity

    @Test("The item is titled with the Mac's current system name, not a fixed string")
    func followsSystemComputerName() throws {
        let systemName = try #require(Host.current().localizedName)
        #expect(ComputerIdentity.name() == systemName)
        #expect(SidebarComputer.current().name == systemName)
        #expect(SidebarComputer.current().kind == .computer)
    }

    @Test("The symbol follows the model family from the system's device types", arguments: [
        ("Mac17,3", "laptopcomputer"),        // MacBook Air (2026), a modern code without a family name
        ("MacBookPro18,1", "laptopcomputer"),
        ("Mac16,1", "laptopcomputer"),
        ("Mac14,3", "macmini"),
        ("Mac14,13", "macstudio"),
        ("iMac21,1", "desktopcomputer"),
        ("Unknown9,9", "desktopcomputer")
    ])
    func symbolFollowsModelFamily(code: String, symbol: String) {
        #expect(ComputerIdentity.systemImage(forModelCode: code) == symbol)
    }

    @Test("Without a model code the generic computer symbol is used")
    func missingModelUsesGenericSymbol() {
        #expect(ComputerIdentity.systemImage(forModelCode: nil) == "desktopcomputer")
        #expect(NSImage(systemSymbolName: ComputerIdentity.systemImage, accessibilityDescription: nil) != nil)
    }

    // MARK: Visibility preference

    @Test("The model code is read as UTF-8 up to its null terminator")
    func modelCodeDecoding() {
        func buffer(_ bytes: [UInt8]) -> [CChar] { bytes.map { CChar(bitPattern: $0) } }
        #expect(ComputerIdentity.string(fromNullTerminated: buffer(Array("Mac16,13".utf8) + [0])) == "Mac16,13")
        // sysctl reports the size with the terminator; anything after it is ignored.
        #expect(ComputerIdentity.string(fromNullTerminated: buffer(Array("Mac15,3".utf8) + [0, 0x41])) == "Mac15,3")
        #expect(ComputerIdentity.string(fromNullTerminated: buffer(Array("Mäc".utf8) + [0])) == "Mäc")
        #expect(ComputerIdentity.string(fromNullTerminated: buffer([0])).isEmpty)
        #expect(ComputerIdentity.string(fromNullTerminated: []).isEmpty)
    }

    @Test("The computer item is shown by default and its Settings choice persists")
    func visibilityPreferencePersists() throws {
        let suite = "ComputerVisibility-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.isSidebarLocationVisible(.computer))
        preferences.setSidebarLocation(.computer, visible: false)
        #expect(!FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.computer))
        #expect(FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.home))
        preferences.setSidebarLocation(.computer, visible: true)
        #expect(FileBrowserPreferences(defaults: defaults).isSidebarLocationVisible(.computer))
    }

    // MARK: Catalog

    // Contract change (user request, 2026-10-30, “Também não tem o Network”): Network is a
    // virtual node on current macOS, so it is always listed instead of only when a
    // `/Network` folder exists.
    @Test("The computer level lists every volume as a container, then the virtual Network")
    func catalogListsVolumesThenNetwork() {
        let a = URL(fileURLWithPath: "/", isDirectory: true)
        let b = URL(fileURLWithPath: "/Volumes/Backup", isDirectory: true)
        let items = ComputerLevelCatalog.items(
            volumes: [Self.volume(a, "Macintosh HD"), Self.volume(b, "Backup", kind: .removable)],
            locale: Locale(identifier: "en")
        )
        #expect(items.map(\.name) == ["Macintosh HD", "Backup", "Network"])
        #expect(items.map(\.localURL) == [a, b, nil])
        #expect(items.map(\.location) == [.fileSystem(a), .fileSystem(b), .network])
        #expect(items.allSatisfy { $0.isContainer && $0.isNavigableContainer && !$0.isArchive && !$0.isHidden })
        #expect(items[0].id == BrowserItemID(rawValue: "file:/"))
        #expect(items[0].contentType == .volume)
        #expect(items[2].contentTypeIdentifier == "com.apple.network-neighborhood")
        #expect(!items[2].canExpandInlineInList)
        #expect(items[2].usesStaticIconPreview)
        #expect(ComputerLevelCatalog.items(volumes: []).map(\.location) == [.network])
    }

    @Test("Network is localized in every supported language", arguments: ["en", "de", "ja", "pt-BR"])
    func networkItemIsLocalized(language: String) {
        let locale = Locale(identifier: language)
        let network = ComputerLevelCatalog.items(volumes: [], locale: locale)
        #expect(network.map(\.name) == [AppLocalization.string("Network", locale: locale)])
    }

    // MARK: Navigation

    @Test("Go ▸ Computer shows the volumes titled with the Mac's name in every view mode",
          arguments: BrowserViewMode.allCases)
    func navigatesToComputerLevel(mode: BrowserViewMode) async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = mode
        await state.navigateToComputer()
        #expect(state.location == .computer)
        #expect(state.title == ComputerIdentity.name(locale: state.preferences.language.locale))
        #expect(state.pathComponents.map(\.location) == [.computer])
        #expect(state.breadcrumbComponents.map(\.location) == [.computer])
        #expect(Set(state.items.map(\.name)) == ["Macintosh HD", "Backup", "Network"])
        #expect(state.sortedColumnItems(at: .computer).map(\.name) == ["Backup", "Macintosh HD", "Network"])
        #expect(state.currentDirectoryURL == nil)
        #expect(state.fileOperationDestinationURL == nil)
        #expect(!state.canModifyCurrentDirectory)
        #expect(state.error == nil)
    }

    @Test("A volume opens below the computer level and history returns to it")
    func opensVolumeAndReturns() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        await state.navigateToComputer()
        let volume = try #require(state.items.first { $0.name == "Macintosh HD" })
        await state.open(volume)
        #expect(state.location == .fileSystem(fixture.volumeA))
        #expect(state.pathComponents.map(\.location) == [.computer, .fileSystem(fixture.volumeA)])
        #expect(state.breadcrumbComponents.first?.location == .computer)
        #expect(state.items.map(\.name) == ["Inside"])
        #expect(await fixture.grants.activated.contains(fixture.volumeA))

        await state.goUp()
        #expect(state.location == .computer)
        await state.goForward()
        #expect(state.location == .computer)
        await state.goBack()
        #expect(state.location == .fileSystem(fixture.volumeA))
        await state.goForward()
        #expect(state.location == .computer)
    }

    @Test("Columns open a volume beside the computer column and keep it as the root")
    func columnsKeepComputerRoot() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = .columns
        await state.navigateToComputer()
        let volume = try #require(state.sortedColumnItems(at: .computer).first { $0.name == "Macintosh HD" })
        await state.activateColumnItem(volume, in: .computer).value
        #expect(state.pathComponents.map(\.location) == [.computer, .fileSystem(fixture.volumeA)])
        #expect(state.columnSelections[.computer] == volume.id)
        #expect(state.sortedColumnItems(at: .fileSystem(fixture.volumeA)).map(\.name) == ["Inside"])
    }

    @Test("A volume without access asks for authorization and stays on the computer level")
    func ungrantedVolumeRequestsAuthorization() async throws {
        let fixture = try fixture(granted: false)
        defer { fixture.tearDown() }
        let state = fixture.state
        await state.navigateToComputer()
        let volume = try #require(state.items.first { $0.name == "Backup" })
        await state.open(volume)
        #expect(state.pendingAuthorizationURL == fixture.volumeB)
        #expect(state.location == .computer)
        #expect(await fixture.grants.activated.isEmpty)
    }

    @Test("Inline List expansion of a volume uses the same authorization")
    func listExpansionRequiresGrant() async throws {
        let fixture = try fixture(granted: false)
        defer { fixture.tearDown() }
        let state = fixture.state
        state.viewMode = .list
        await state.navigateToComputer()
        let volume = try #require(state.items.first { $0.name == "Macintosh HD" })
        await state.toggleExpansion(volume)
        #expect(state.pendingAuthorizationURL == fixture.volumeA)
        #expect(!state.expandedItems.contains(volume.id))
    }

    @Test("Mounting and unmounting refresh the computer level, also as the root column")
    func mountChangesRefresh() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        await state.navigateToComputer()
        #expect(state.items.map(\.name).sorted() == ["Backup", "Macintosh HD", "Network"])

        await fixture.volumes.set([Self.volume(fixture.volumeA, "Macintosh HD")])
        await state.refreshComputerLevel()
        #expect(state.items.map(\.name) == ["Macintosh HD", "Network"])

        state.viewMode = .columns
        let volume = try #require(state.items.first { $0.name == "Macintosh HD" })
        await state.activateColumnItem(volume, in: .computer).value
        await fixture.volumes.set([Self.volume(fixture.volumeA, "Macintosh HD"),
                                   Self.volume(fixture.volumeB, "Backup", kind: .removable)])
        await state.refreshComputerLevel()
        #expect(state.location == .fileSystem(fixture.volumeA))
        #expect(state.sortedColumnItems(at: .computer).map(\.name) == ["Backup", "Macintosh HD", "Network"])
    }

    @Test("Leaving the computer level ignores later mount events")
    func mountEventsOutsideComputerLevelAreIgnored() async throws {
        let fixture = try fixture()
        defer { fixture.tearDown() }
        let state = fixture.state
        await state.navigateToSidebar(fixture.volumeA, name: "Macintosh HD")
        let before = await fixture.volumes.requests
        await state.refreshComputerLevel()
        #expect(await fixture.volumes.requests == before)
        #expect(state.location == .fileSystem(fixture.volumeA))
    }

    // MARK: Appearance

    @Test("The computer row matches the Locations rows in light and dark",
          arguments: ZforgeSnapshot.appearances.map(\.name))
    func rowSnapshot(appearanceName: String) throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == appearanceName })
        let fixture = try fixture()
        defer { fixture.tearDown() }
        fixture.state.location = .computer
        let computer = SidebarComputer(name: "Studio Mac", systemImage: "laptopcomputer")
        // A sidebar List draws only inside a window, as in the sidebar icon tint snapshots.
        let size = CGSize(width: 220, height: 120)
        let host = NSHostingView(rootView: List {
            Section("Locations") {
                SidebarComputerRow(browser: fixture.state, computer: computer, restoreContentFocus: {})
                Label {
                    Text(verbatim: "felipe")
                } icon: {
                    Image(systemName: "house").resizable().scaledToFit().frame(width: 16, height: 16).sidebarIconStyle()
                }
                // The insets and padding of the real Locations destination rows.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .environment(\.sidebarIconTint, .neutral)
        }
        .listStyle(.sidebar)
        .environment(\.appearsActive, true)
        .frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        ZforgeSnapshot.assert(host, appearance: appearance.appearance, named: "current-\(appearance.name)")
    }
}

private actor StubVolumeCatalog: VolumeCataloging {
    private var current: [SidebarVolume]
    private(set) var requests = 0

    init(volumes: [SidebarVolume]) {
        current = volumes
    }

    func set(_ volumes: [SidebarVolume]) { current = volumes }
    func volumes() -> [SidebarVolume] {
        requests += 1
        return current
    }
}

/// Discovery that never reports a server, so these tests never browse the real network.
private struct StubNetworkBrowser: NetworkServerBrowsing {
    func updates() -> AsyncStream<NetworkDiscoveryUpdate> { AsyncStream { _ in } }
}

private actor StubComputerGrants: AccessGrantStoring {
    let granted: Bool
    private(set) var activated: [URL] = []

    init(granted: Bool) { self.granted = granted }

    func hasGrant(for url: URL) -> Bool { granted }
    func storeGrant(for url: URL) throws {}
    func activateGrant(for url: URL) throws -> URL {
        activated.append(url)
        return url
    }
    func removeGrant(for url: URL) {}
    func stopAll() {}
}
