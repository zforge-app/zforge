import AppKit
import SwiftUI
import Testing
@testable import Zforge

@Suite("Sidebar volume eject")
@MainActor
struct SidebarVolumeEjectTests {
    struct EjectabilityCase: Sendable, CustomTestStringConvertible {
        let name: String
        let root: Bool?, ejectable: Bool?, removable: Bool?, local: Bool?, internalDisk: Bool?
        let expected: Bool
        var testDescription: String { name }
    }

    @Test("Ejectability follows Finder: removable, ejectable, external and network volumes, never the boot or an internal disk",
          arguments: [
              EjectabilityCase(name: "boot volume", root: true, ejectable: false, removable: false, local: true, internalDisk: true, expected: false),
              EjectabilityCase(name: "USB flash drive", root: false, ejectable: true, removable: true, local: true, internalDisk: false, expected: true),
              EjectabilityCase(name: "external SSD", root: false, ejectable: false, removable: false, local: true, internalDisk: false, expected: true),
              EjectabilityCase(name: "disk image", root: false, ejectable: true, removable: false, local: true, internalDisk: nil, expected: true),
              EjectabilityCase(name: "network share", root: false, ejectable: nil, removable: nil, local: false, internalDisk: nil, expected: true),
              EjectabilityCase(name: "internal partition", root: false, ejectable: false, removable: false, local: true, internalDisk: true, expected: false),
              EjectabilityCase(name: "root that reports ejectable", root: true, ejectable: true, removable: true, local: true, internalDisk: false, expected: false)
          ])
    func ejectability(_ volume: EjectabilityCase) {
        #expect(SidebarVolume.isEjectable(isRootFileSystem: volume.root, isEjectable: volume.ejectable,
                                          isRemovable: volume.removable, isLocal: volume.local,
                                          isInternal: volume.internalDisk) == volume.expected)
    }

    @Test("The mounted boot volume is listed as not ejectable")
    func bootVolumeIsNotEjectable() async throws {
        let volumes = await VolumeCatalogService().volumes()
        let boot = try #require(volumes.first { $0.url.standardizedFileURL.path == "/" })
        #expect(!boot.isEjectable)
    }

    @Test("Busy failures are recognized directly and through underlying errors; other failures are not")
    func busyClassification() {
        let posixBusy = NSError(domain: NSPOSIXErrorDomain, code: Int(EBUSY))
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSUnderlyingErrorKey: posixBusy])
        #expect(VolumeEjection.isInUse(posixBusy))
        #expect(VolumeEjection.isInUse(wrapped))
        #expect(VolumeEjection.isInUse(NSError(domain: NSOSStatusErrorDomain, code: -47)))
        #expect(VolumeEjection.isInUse(NSError(domain: NSOSStatusErrorDomain, code: Int(Int32(bitPattern: 0xF8DA_0002)))))
        #expect(!VolumeEjection.isInUse(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))))
        #expect(!VolumeEjection.isInUse(NSError(domain: NSCocoaErrorDomain, code: Int(EBUSY))))
    }

    @Test("Only the volume itself and its descendants count as on the volume")
    func volumeMembership() {
        let volume = URL(fileURLWithPath: "/Volumes/Ventoy")
        #expect(FileBrowserState.url(volume, isOnVolume: volume))
        #expect(FileBrowserState.url(URL(fileURLWithPath: "/Volumes/Ventoy/ISO/Linux"), isOnVolume: volume))
        #expect(!FileBrowserState.url(URL(fileURLWithPath: "/Volumes/Ventoy 2"), isOnVolume: volume))
        #expect(!FileBrowserState.url(URL(fileURLWithPath: "/Volumes/VentoyData/File"), isOnVolume: volume))
        #expect(!FileBrowserState.url(URL(fileURLWithPath: "/Users"), isOnVolume: URL(fileURLWithPath: "/")))
    }

    @Test("Ejecting the volume being browsed ejects it once and leaves for the computer level without an alert")
    func ejectLeavesBrowsedVolume() async throws {
        try await withBrowser { state, volume in
            let inside = volume.appendingPathComponent("Folder", isDirectory: true)
            await state.navigateToSidebar(inside, name: "Folder")
            #expect(state.currentDirectoryURL?.standardizedFileURL == inside.standardizedFileURL)
            let ejector = RecordingEjector()
            state.volumeEjector = { await ejector.eject($0) }

            await state.ejectVolume(at: volume, name: "Ventoy")

            #expect(await ejector.ejected == [volume.standardizedFileURL])
            #expect(state.location == .computer)
            #expect(state.error == nil)
            #expect(state.ejectingVolumeURLs.isEmpty)
        }
    }

    @Test("Ejecting another volume keeps the current location")
    func ejectElsewhereKeepsLocation() async throws {
        try await withBrowser { state, volume in
            await state.navigateToSidebar(volume, name: "Ventoy")
            let other = URL(fileURLWithPath: volume.path + " 2", isDirectory: true)
            let ejector = RecordingEjector()
            state.volumeEjector = { await ejector.eject($0) }

            await state.ejectVolume(at: other, name: "Ventoy 2")

            #expect(await ejector.ejected == [other.standardizedFileURL])
            #expect(state.currentDirectoryURL?.standardizedFileURL == volume.standardizedFileURL)
            #expect(state.error == nil)
        }
    }

    @Test("A busy volume stays mounted and browsed, and the alert names it as in use")
    func busyEjectShowsAlert() async throws {
        try await withBrowser { state, volume in
            await state.navigateToSidebar(volume, name: "Ventoy")
            state.volumeEjector = { _ in throw NSError(domain: NSPOSIXErrorDomain, code: Int(EBUSY)) }

            await state.ejectVolume(at: volume, name: "Ventoy")

            let error = try #require(state.error)
            guard case let .ejectFailed(name, inUse, _) = error else {
                Issue.record("Expected an eject failure, got \(error)")
                return
            }
            #expect(name == "Ventoy")
            #expect(inUse)
            #expect(error.localizedDescription == "The disk “Ventoy” wasn’t ejected because one or more programs may be using it.")
            #expect(state.currentDirectoryURL?.standardizedFileURL == volume.standardizedFileURL)
            #expect(state.ejectingVolumeURLs.isEmpty)
        }
    }

    @Test("Other eject failures name the volume and keep the system's reason")
    func otherEjectFailure() async throws {
        try await withBrowser { state, volume in
            state.volumeEjector = { _ in
                throw NSError(domain: NSCocoaErrorDomain, code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "The device is not responding."])
            }

            await state.ejectVolume(at: volume, name: "Ventoy")

            #expect(state.error == .ejectFailed(volumeName: "Ventoy", inUse: false, detail: "The device is not responding."))
            #expect(state.error?.localizedDescription == "The disk “Ventoy” couldn’t be ejected. The device is not responding.")
        }
    }

    @Test("A repeated eject while one is in flight is ignored and the volume reports progress")
    func repeatedEjectIsIgnored() async throws {
        try await withBrowser { state, volume in
            let gate = EjectGate()
            state.volumeEjector = { await gate.eject($0) }

            let first = Task { await state.ejectVolume(at: volume, name: "Ventoy") }
            await gate.waitUntilStarted()
            #expect(state.ejectingVolumeURLs == [volume.standardizedFileURL])
            await state.ejectVolume(at: volume, name: "Ventoy")
            await gate.release()
            await first.value

            #expect(await gate.calls == 1)
            #expect(state.ejectingVolumeURLs.isEmpty)
        }
    }

    @Test("An unmount observed from outside the window leaves a location on that volume only")
    func externalUnmountLeavesVolume() async throws {
        try await withBrowser { state, volume in
            await state.navigateToSidebar(volume, name: "Ventoy")
            await state.leaveUnmountedVolume(URL(fileURLWithPath: volume.path + "Data"))
            #expect(state.currentDirectoryURL?.standardizedFileURL == volume.standardizedFileURL)
            await state.leaveUnmountedVolume(volume)
            #expect(state.location == .computer)
        }
    }

    @Test("The eject glyph sits at the trailing edge in light, dark and drop-target rows",
          arguments: ZforgeSnapshot.appearances.map(\.name))
    func ejectButtonSnapshot(_ appearanceName: String) async throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == appearanceName }).appearance
        try await withBrowser { state, volume in
            for isDropTarget in [false, true] {
                let row = HStack {
                    Label("Ventoy", systemImage: "externaldrive")
                    Spacer()
                    SidebarEjectButton(browser: state, name: "Ventoy", url: volume, isDropTarget: isDropTarget,
                                       restoreContentFocus: {})
                }
                .padding(.horizontal, 8)
                .foregroundStyle(isDropTarget ? Color.white : .primary)
                .background(isDropTarget ? Color.accentColor : Color(nsColor: .windowBackgroundColor))
                ZforgeSnapshot.assert(row, size: CGSize(width: 220, height: 32), appearance: appearance,
                                      named: "eject-\(isDropTarget ? "drop-target" : "idle")-\(appearanceName)")
            }
        }
    }

    // MARK: - Fixtures

    private func withBrowser(_ body: (FileBrowserState, URL) async throws -> Void) async throws {
        let volume = FileManager.default.temporaryDirectory
            .appendingPathComponent("EjectVolume-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: volume.appendingPathComponent("Folder"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: volume) }
        let suite = "ZforgeTestSuite.SidebarVolumeEject-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
                                     recentItems: EmptyRecents(), grants: UIFixtureAccessGrantStore(),
                                     archives: NativeSevenZipArchiveEngine())
        defer { state.close() }
        try await body(state, volume)
    }
}

private actor RecordingEjector {
    private(set) var ejected: [URL] = []
    func eject(_ url: URL) { ejected.append(url) }
}

/// Holds an eject in flight until the test releases it.
private actor EjectGate {
    private(set) var calls = 0
    private var started: CheckedContinuation<Void, Never>?
    private var hasStarted = false
    private var pending: CheckedContinuation<Void, Never>?

    func eject(_ url: URL) async {
        calls += 1
        hasStarted = true
        started?.resume()
        started = nil
        await withCheckedContinuation { pending = $0 }
    }

    func waitUntilStarted() async {
        guard !hasStarted else { return }
        await withCheckedContinuation { started = $0 }
    }

    func release() {
        pending?.resume()
        pending = nil
    }
}

private final class EmptyRecents: RecentItemsServing {
    func recentItemURLs() async -> [URL] { [] }
    func stop() {}
}
