import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// D-73 / ZF-55 stage 3: preview and thumbnail limits for items inside archives, the solid
/// archives and removable/network settings, opening progress and prompt cancellation.
@Suite("Archive preview limits (D-73)")
struct ArchivePreviewLimitTests {
    // MARK: Policy

    @Test("Volumes are classified as internal, removable (local, not internal) or network (not local)")
    func volumeClassification() {
        #expect(ArchiveVolumeKind.classify(isLocal: true, isInternal: true) == .internalDisk)
        #expect(ArchiveVolumeKind.classify(isLocal: true, isInternal: false) == .removable)
        #expect(ArchiveVolumeKind.classify(isLocal: false, isInternal: false) == .network)
        #expect(ArchiveVolumeKind.classify(isLocal: false, isInternal: nil) == .network)
        #expect(ArchiveVolumeKind.classify(isLocal: nil, isInternal: nil) == .internalDisk)
        #expect(ArchiveVolumeKind.of(FileManager.default.temporaryDirectory) == .internalDisk)
    }

    @Test("Items are measured by their size, or by their solid block; unknown sizes are never automatic")
    func measureAndDecisions() {
        let limits = ArchivePreviewLimits.defaults
        let mb: Int64 = 1_000_000
        #expect(ArchivePreviewLimits.measure(of: item(size: 3 * mb)) == 3 * mb)
        #expect(ArchivePreviewLimits.measure(of: item(size: 3 * mb, block: 900 * mb)) == 900 * mb)
        #expect(ArchivePreviewLimits.measure(of: item(size: 3 * mb, block: nil, solid: true)) == nil)

        // General limits on an internal disk: 512 MB previews, 8 MB thumbnails.
        #expect(limits.allowsAutomaticPreview(of: item(size: 512 * mb), on: .internalDisk))
        #expect(!limits.allowsAutomaticPreview(of: item(size: 512 * mb + 1), on: .internalDisk))
        #expect(limits.allowsAutomaticThumbnail(of: item(size: 8 * mb), on: .internalDisk))
        #expect(!limits.allowsAutomaticThumbnail(of: item(size: 8 * mb + 1), on: .internalDisk))
        #expect(!limits.allowsAutomaticPreview(of: item(size: nil), on: .internalDisk))
        // A small item in a large solid block is measured by the block.
        #expect(!limits.allowsAutomaticPreview(of: item(size: 1_000, block: 600 * mb), on: .internalDisk))
        #expect(limits.allowsAutomaticPreview(of: item(size: 1_000, block: 6 * mb), on: .internalDisk))

        // Removable and network volumes are off by default; their limit replaces the general one.
        for volume in [ArchiveVolumeKind.removable, .network] {
            #expect(!limits.allowsAutomaticPreview(of: item(size: 1_000), on: volume))
            #expect(!limits.allowsAutomaticThumbnail(of: item(size: 1_000), on: volume))
        }
        var enabled = limits
        enabled.previewsOnRemovableVolumes = true
        enabled.previewsOnNetworkVolumes = true
        enabled.networkLimit = 100 * mb
        #expect(enabled.allowsAutomaticPreview(of: item(size: 32 * mb), on: .removable))
        #expect(!enabled.allowsAutomaticPreview(of: item(size: 33 * mb), on: .removable))
        #expect(enabled.allowsAutomaticPreview(of: item(size: 100 * mb), on: .network))
        // Thumbnails there use the smaller of the thumbnail and volume limits.
        enabled.thumbnailLimit = 64 * mb
        #expect(enabled.thumbnailLimit(on: .removable) == 32 * mb)
        #expect(enabled.thumbnailLimit(on: .network) == 64 * mb)
        #expect(enabled.thumbnailLimit(on: .internalDisk) == 64 * mb)

        // The solid archives setting covers previews and thumbnails of items in solid blocks only.
        var noSolid = limits
        noSolid.previewsSolidArchives = false
        #expect(!noSolid.allowsAutomaticPreview(of: item(size: 1_000, block: 2_000), on: .internalDisk))
        #expect(!noSolid.allowsAutomaticThumbnail(of: item(size: 1_000, block: 2_000), on: .internalDisk))
        #expect(noSolid.allowsAutomaticPreview(of: item(size: 1_000), on: .internalDisk))

        // Files outside archives are not concerned.
        let local = BrowserItem(id: BrowserItemID(rawValue: "local"), name: "Local.bin",
            location: .fileSystem(URL(fileURLWithPath: "/tmp/Local.bin")), isContainer: false, isDirectory: false,
            isPackage: false, isSymbolicLink: false, isHidden: false, isArchive: false, size: 5_000_000_000,
            packedSize: nil, creationDate: nil, modificationDate: nil, accessDate: nil, tags: [],
            contentTypeIdentifier: nil, encrypted: false, checksum: nil, compressionMethod: nil)
        #expect(noSolid.allowsAutomaticPreview(of: local, on: .network))
    }

    @Test("Preview preferences have their defaults, clamp their ranges and persist")
    @MainActor
    func preferences() throws {
        let suite = "ZforgeTestSuite.ArchivePreviewLimits-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        #expect(preferences.archivePreviewLimits == .defaults)
        #expect(preferences.previewSizeLimit == 512_000_000 && preferences.thumbnailSizeLimit == 8_000_000)
        #expect(preferences.previewSolidArchives)
        #expect(!preferences.previewOnRemovableVolumes && !preferences.previewOnNetworkVolumes)
        #expect(preferences.removableVolumePreviewLimit == 32_000_000 && preferences.networkVolumePreviewLimit == 32_000_000)

        preferences.previewSizeLimit = 5_000_000_000
        preferences.thumbnailSizeLimit = 1
        preferences.removableVolumePreviewLimit = 768_000_000
        preferences.networkVolumePreviewLimit = 1
        preferences.previewSolidArchives = false
        preferences.previewOnRemovableVolumes = true
        #expect(preferences.previewSizeLimit == 2_000_000_000)
        #expect(preferences.thumbnailSizeLimit == 4_000_000)
        #expect(preferences.networkVolumePreviewLimit == 32_000_000)
        let reloaded = FileBrowserPreferences(defaults: defaults)
        #expect(reloaded.previewSizeLimit == 2_000_000_000)
        #expect(reloaded.thumbnailSizeLimit == 4_000_000)
        #expect(reloaded.removableVolumePreviewLimit == 768_000_000)
        #expect(!reloaded.previewSolidArchives)
        #expect(reloaded.previewOnRemovableVolumes && !reloaded.previewOnNetworkVolumes)
    }

    // MARK: Slider scales

    @Test("The preview and thumbnail sliders keep the logarithmic track: equal doublings, 1/32 steps, held round values",
          arguments: [("preview", ArchiveSizeLimitSliderScale.preview), ("thumbnail", ArchiveSizeLimitSliderScale.thumbnail)])
    func presetScales(name: String, scale: ArchiveSizeLimitSliderScale) {
        let doublings = scale.doublingValues
        #expect(scale.range == (name == "preview" ? ArchivePreviewLimits.previewRange : ArchivePreviewLimits.thumbnailRange))
        #expect(scale.tickCount == doublings.count)
        for (index, doubling) in doublings.enumerated() {
            #expect(abs(scale.position(for: doubling) - Double(index) / Double(doublings.count - 1)) < 1e-9, "\(doubling)")
            #expect(scale.isRoundValue(doubling))
        }
        #expect(scale.isRoundValue(doublings[0] + doublings[0] / 2))
        #expect(scale.value(after: doublings[0]) == doublings[0] + doublings[0] / 32)
        #expect(scale.roundValue(after: doublings[0]) == doublings[0] + doublings[0] / 2)
        var steps = [scale.range.lowerBound]
        while steps.last! < scale.range.upperBound { steps.append(scale.value(after: steps.last!)) }
        var dragged: [Int64] = []
        for sample in 0...40_000 {
            let value = scale.value(at: Double(sample) / 40_000)
            if dragged.last != value { dragged.append(value) }
        }
        #expect(dragged == steps, "Dragging reaches every step in order")
        for round in scale.roundValueList {
            let center = scale.position(for: round)
            #expect(scale.value(at: center + scale.holdWidth * 0.9) == round, "\(round)")
        }
    }

    @Test("The preview slider reads its ticks in decimal megabytes and gigabytes")
    func presetTicks() {
        let locale = Locale(identifier: "en_US")
        #expect(ArchiveSizeLimitSliderScale.preview.doublingValues.map { AppLocalization.byteCount($0, locale: locale) }
            == ["32 MB", "64 MB", "128 MB", "256 MB", "512 MB", "1 GB", "2 GB"])
        #expect(ArchiveSizeLimitSliderScale.thumbnail.doublingValues.map { AppLocalization.byteCount($0, locale: locale) }
            == ["4 MB", "8 MB", "16 MB", "32 MB", "64 MB"])
    }

    // MARK: Browser state

    @Test("A single selection follows the preview limits, a multiple selection the thumbnail limits")
    @MainActor
    func selectionUsesPreviewOrThumbnailLimits() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.cleanUp() }
        let state = try await fixture.browser()
        defer { state.close() }
        let medium = try #require(state.items.first { $0.name == "Medium.bin" })
        let small = try #require(state.items.first { $0.name == "Small.txt" })

        state.select(medium)
        await state.previewTask?.value
        #expect(state.previewURLs[medium.id] != nil, "9 MB is under the 512 MB preview limit")

        state.select(small, modifiers: .command)
        await state.previewTask?.value
        #expect(state.previewItemsRequiringManualLoad == [medium.id], "9 MB is over the 8 MB thumbnail limit")
        #expect(state.previewURLs[small.id] != nil)
    }

    @Test("Archives on removable and network volumes preview automatically only when enabled; the manual load remains",
          arguments: [ArchiveVolumeKind.removable, .network])
    @MainActor
    func volumeSettings(volume: ArchiveVolumeKind) async throws {
        let fixture = try await Fixture.make()
        defer { fixture.cleanUp() }
        let state = try await fixture.browser(volume: volume)
        defer { state.close() }
        let small = try #require(state.items.first { $0.name == "Small.txt" })
        state.select(small)
        await state.previewTask?.value
        #expect(state.previewItemsRequiringManualLoad == [small.id])
        #expect(state.previewURLs[small.id] == nil)
        #expect(try await state.iconPreview(for: small, pixelSize: 128) == nil)
        #expect(fixture.meter.bytesRead == 0, "Nothing was read for the automatic preview or thumbnail")

        state.updatePreview(manual: true)
        await state.previewTask?.value
        #expect(state.previewURLs[small.id] != nil, "The manual load action still works")

        if volume == .removable { state.preferences.previewOnRemovableVolumes = true } else { state.preferences.previewOnNetworkVolumes = true }
        state.updatePreview()
        await state.previewTask?.value
        #expect(state.previewItemsRequiringManualLoad.isEmpty)
        #expect(state.previewURLs[small.id] != nil)
    }

    @Test("Items in solid blocks preview automatically only with Preview solid archives")
    @MainActor
    func solidArchivesSetting() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.cleanUp() }
        let state = try await fixture.browser(archive: fixture.solid)
        defer { state.close() }
        let first = try #require(state.items.first { $0.name == "First.txt" })
        #expect(first.solidBlock != nil)
        state.preferences.previewSolidArchives = false
        state.select(first)
        await state.previewTask?.value
        #expect(state.previewItemsRequiringManualLoad == [first.id])
        #expect(try await state.iconPreview(for: first, pixelSize: 128) == nil)
        state.preferences.previewSolidArchives = true
        state.updatePreview()
        await state.previewTask?.value
        #expect(state.previewURLs[first.id] != nil)
    }

    @Test("Grid thumbnails follow the thumbnail limit with the same measure")
    @MainActor
    func gridThumbnails() async throws {
        var rendered: [String] = []
        let service = IconPreviewService { item, _, _ in rendered.append(item.name); return nil }
        let archives = UIFixtureArchiveEngine()
        var limits = ArchivePreviewLimits.defaults
        _ = try await service.image(for: item(size: 9_000_000), pixelSize: 128, archives: archives, limits: limits)
        _ = try await service.image(for: item(size: 1_000, block: 9_000_000, name: "Solid.txt"), pixelSize: 128, archives: archives, limits: limits)
        _ = try await service.image(for: item(size: 1_000, name: "Removable.txt"), pixelSize: 128, archives: archives,
            limits: limits, volume: .removable)
        #expect(rendered.isEmpty)
        limits.thumbnailLimit = 16_000_000
        _ = try await service.image(for: item(size: 9_000_000, name: "Raised.txt"), pixelSize: 128, archives: archives, limits: limits)
        #expect(rendered == ["Raised.txt"])
    }

    // MARK: Opening progress and cancellation

    @Test("Opening shows progress and Cancel only after a delay, and Cancel opens nothing")
    @MainActor
    func openingProgressAndCancel() async throws {
        let engine = GatedOpeningEngine()
        let suite = "ZforgeTestSuite.ArchiveOpening-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: engine)
        defer { state.close() }
        let archive = BrowserItem(id: BrowserItemID(rawValue: "slow"), name: "Slow.tar.gz",
            location: .fileSystem(URL(fileURLWithPath: "/tmp/Slow.tar.gz")), isContainer: false, isDirectory: false,
            isPackage: false, isSymbolicLink: false, isHidden: false, isArchive: true, size: 1, packedSize: nil,
            creationDate: nil, modificationDate: nil, accessDate: nil, tags: [], contentTypeIdentifier: nil,
            encrypted: false, checksum: nil, compressionMethod: nil)
        let location = state.location

        state.archiveOpeningRevealDelay = .seconds(3_600)
        let quick = Task { await state.openArchive(archive) }
        await engine.waitUntilOpening()
        #expect(state.archiveOperationInProgress)
        #expect(!state.archiveOperationIsVisible, "Not shown before the delay")
        state.cancelArchiveOperation()
        await quick.value

        state.archiveOpeningRevealDelay = .zero
        let slow = Task { await state.openArchive(archive) }
        await engine.waitUntilOpening()
        for _ in 0..<1_000 where !state.archiveOperationIsVisible { await Task.yield() }
        #expect(state.archiveOperationIsVisible)
        #expect(state.archiveOperationDescription == "Opening “Slow.tar.gz”…")
        state.cancelArchiveOperation()
        await slow.value
        #expect(!state.archiveOperationInProgress)
        #expect(state.error == nil, "Cancelling is not an error")
        #expect(state.location == location, "Nothing was opened")
    }

    @Test("Cancelling an opening that reads a whole stream reaches the bridge and leaves no session")
    @MainActor
    func cancelStreamOpening() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.cleanUp() }
        let archive = fixture.root.appendingPathComponent("Stream.tar.gz")
        try await NativeSevenZipArchiveEngine().createArchive(from: [fixture.medium], outputURL: archive,
            options: CompressionOptions(format: .gzip, level: 1), password: nil, progress: { _ in })
        let gate = ReadGate()
        fixture.meter.onRead = { _ in gate.holdFirstRead() }
        let client = ArchiveSessionClient(engine: fixture.engine)
        let opening = Task { try await client.openArchive(at: archive, password: nil) }
        await gate.waitUntilHeld()
        await client.cancelAllOperations()
        gate.release()
        await #expect(throws: (any Error).self) { _ = try await opening.value }
        #expect(fixture.meter.cancelledOperations == 1, "The bridge saw the cancellation")
        #expect(await fixture.engine.sessionReferences().isEmpty)
    }

    @Test("A fast selection change cancels the previous preview's native read")
    @MainActor
    func fastSelectionCancelsRead() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.cleanUp() }
        let state = try await fixture.browser()
        defer { state.close() }
        let medium = try #require(state.items.first { $0.name == "Medium.bin" })
        let small = try #require(state.items.first { $0.name == "Small.txt" })
        let gate = ReadGate()
        fixture.meter.reset()
        fixture.meter.onRead = { _ in gate.holdFirstRead() }
        state.select(medium)
        await gate.waitUntilHeld()
        let interrupted = state.previewTask
        state.select(small)
        gate.release()
        await interrupted?.value
        await state.previewTask?.value
        #expect(fixture.meter.cancelledOperations >= 1, "The read of the first preview was cancelled in the bridge")
        #expect(state.previewURLs[medium.id] == nil)
        #expect(state.previewURLs[small.id] != nil)
        #expect(state.error == nil)
    }

    // MARK: Snapshots

    @Test("Settings: Previews in Archives", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        ("dark", NSAppearance.Name.darkAqua, AppLanguagePreference.english),
        ("light-de", NSAppearance.Name.aqua, AppLanguagePreference.german),
        ("dark-de", NSAppearance.Name.darkAqua, AppLanguagePreference.german),
    ])
    @MainActor
    func settingsSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) throws {
        let suite = "ZforgeTestSuite.ArchivePreviewSettings-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        preferences.previewOnRemovableVolumes = true
        preferences.previewOnNetworkVolumes = true
        preferences.networkVolumePreviewLimit = 128_000_000
        let settingsBody = String(reflecting: ZforgeSettingsView.Body.self)
        #expect(settingsBody.contains("ArchivePreviewSettingsSection"))
        let section = Form { ArchivePreviewSettingsSection(preferences: preferences) }
            .formStyle(.grouped)
            .environment(\.locale, language.locale)
        let size = CGSize(width: 568, height: 530)
        let host = NSHostingView(rootView: section.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let sliders = previewSliders(in: host)
        #expect(Set(sliders.compactMap { $0.slider.accessibilityIdentifier() }) == [
            "settings-preview-size-limit", "settings-thumbnail-size-limit",
            "settings-preview-removable-limit", "settings-preview-network-limit",
        ])
        let network = try #require(sliders.first { $0.slider.accessibilityIdentifier() == "settings-preview-network-limit" })
        #expect(network.value == 128_000_000)
        ZforgeSnapshot.assert(host, appearance: appearance, named: "previews-in-archives-\(name)")
        network.step(forward: true, toRoundValue: true)
        #expect(preferences.networkVolumePreviewLimit == 192_000_000, "The slider writes the preference")
    }

    @Test("Write-back progress panel", arguments: ZforgeSnapshot.appearances.map(\.name))
    @MainActor
    func writeBackPanelSnapshot(name: String) throws {
        let appearance = try #require(ZforgeSnapshot.appearances.first { $0.name == name }).appearance
        let locale = Locale(identifier: "en")
        let parts = ArchiveWriteBackPanelPresenter.makePanel(locale: locale, target: nil, action: nil)
        defer { parts.panel.close() }
        #expect(parts.panel.title == "Saving Inner Archive")
        parts.label.stringValue = ArchiveWriteBackPanelPresenter.progressText(inner: "Inner.zip", outer: "Outer.7z", locale: locale)
        #expect(parts.label.stringValue == "Writing “Inner.zip” back into “Outer.7z”…")
        parts.panel.appearance = NSAppearance(named: appearance)
        parts.panel.setContentSize(NSSize(width: 420, height: 112))
        parts.panel.layoutIfNeeded()
        // The whole panel, title bar included.
        let frame = try #require(parts.panel.contentView?.superview)
        ZforgeSnapshot.assert(frame, appearance: appearance, named: "write-back-panel-\(name)")
    }

    @Test("Write-back alerts", arguments: ["conflict", "failure", "password"])
    @MainActor
    func writeBackAlertSnapshots(kind: String) throws {
        let locale = Locale(identifier: "en")
        let alert: NSAlert
        switch kind {
        case "conflict":
            alert = ArchiveWriteBackPanelPresenter.makeConflictAlert(inner: "Inner.zip", outer: "Outer.7z", locale: locale)
            #expect(alert.buttons.map(\.title) == ["Replace Anyway", "Save Inner Archive As…", "Discard Changes"])
        case "failure":
            alert = ArchiveWriteBackPanelPresenter.makeFailureAlert(inner: "Inner.zip", outer: "Outer.7z",
                error: ArchiveEngineError.cancelled, locale: locale)
            #expect(alert.buttons.map(\.title) == ["Try Again", "Save Inner Archive As…"])
        default:
            alert = ArchiveWriteBackPanelPresenter.makePasswordAlert(outer: "Outer.7z", retry: false, locale: locale).alert
            #expect(alert.buttons.map(\.title) == ["OK", "Cancel"])
        }
        alert.layout()
        let content = try #require(alert.window.contentView)
        ZforgeSnapshot.assert(content, appearance: .aqua, named: "write-back-\(kind)")
    }

    // MARK: Support

    private func item(size: Int64?, block: Int64? = nil, solid: Bool = false, name: String = "Item.txt") -> BrowserItem {
        var item = BrowserItem(id: BrowserItemID(rawValue: name), name: name,
            location: .archive(ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: name)),
            isContainer: false, isDirectory: false, isPackage: false, isSymbolicLink: false, isHidden: false,
            isArchive: false, size: size, packedSize: nil, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: [], contentTypeIdentifier: nil, encrypted: false, checksum: nil, compressionMethod: nil)
        if block != nil || solid { item.solidBlock = ArchiveSolidBlock(packedSize: block) }
        return item
    }
}

/// `Plain.zip` (stored: `Small.txt` and a 9 MB `Medium.bin`, over the 8 MB thumbnail limit and
/// under the 512 MB preview limit) and `Solid.7z` (solid text files).
@MainActor
private final class Fixture {
    let root: URL
    let plain: URL
    let solid: URL
    let medium: URL
    let meter = ArchiveSourceReadMeter()
    let engine: NativeSevenZipArchiveEngine
    private var suites: [String] = []
    private var browsers: [FileBrowserState] = []

    private init(root: URL, plain: URL, solid: URL, medium: URL) {
        self.root = root; self.plain = plain; self.solid = solid; self.medium = medium
        engine = NativeSevenZipArchiveEngine(sourceReadMeter: meter)
    }

    static func make() async throws -> Fixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PreviewLimits-\(UUID().uuidString)")
        let input = root.appendingPathComponent("Input", isDirectory: true)
        try FileManager.default.createDirectory(at: input, withIntermediateDirectories: true)
        let small = input.appendingPathComponent("Small.txt")
        try Data("small".utf8).write(to: small)
        let medium = input.appendingPathComponent("Medium.bin")
        var generator = SystemRandomNumberGenerator()
        var data = Data(count: 9_000_000)
        data.withUnsafeMutableBytes { raw in
            let words = raw.bindMemory(to: UInt64.self)
            for index in words.indices { words[index] = generator.next() }
        }
        try data.write(to: medium)
        let plain = root.appendingPathComponent("Plain.zip")
        try await NativeSevenZipArchiveEngine().createArchive(from: [small, medium], outputURL: plain,
            options: CompressionOptions(format: .zip, level: 0), password: nil, progress: { _ in })
        let texts = try ["First.txt", "Second.txt"].map { name -> URL in
            let url = input.appendingPathComponent(name)
            try Data(String(repeating: "\(name) ", count: 300).utf8).write(to: url)
            return url
        }
        let solid = root.appendingPathComponent("Solid.7z")
        try await NativeSevenZipArchiveEngine().createArchive(from: texts, outputURL: solid,
            options: CompressionOptions(format: .sevenZip), password: nil, progress: { _ in })
        return Fixture(root: root, plain: plain, solid: solid, medium: medium)
    }

    func cleanUp() {
        browsers.forEach { $0.close() }
        for suite in suites { UserDefaults(suiteName: suite)?.removeTestSuite(named: suite) }
        try? FileManager.default.removeItem(at: root)
    }

    /// A Gallery browser inside the archive, its archive on `volume`.
    func browser(archive: URL? = nil, volume: ArchiveVolumeKind = .internalDisk) async throws -> FileBrowserState {
        let suite = "ZforgeTestSuite.ArchivePreviewBrowser-\(UUID().uuidString)"
        suites.append(suite)
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .gallery
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: ArchiveSessionClient(engine: engine))
        browsers.append(state)
        state.volumeClassifier = { _ in volume }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        let name = (archive ?? plain).lastPathComponent
        await state.openArchive(try #require(state.items.first { $0.name == name }))
        meter.reset()
        return state
    }
}

/// Holds the first native read on its thread until released, so a read is in flight.
private final class ReadGate: @unchecked Sendable {
    private let lock = NSLock()
    private var held = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let semaphore = DispatchSemaphore(value: 0)

    func holdFirstRead() {
        let first = lock.withLock { () -> Bool in
            guard !held else { return false }
            held = true
            return true
        }
        guard first else { return }
        let waiting = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            defer { waiters.removeAll() }
            return waiters
        }
        waiting.forEach { $0.resume() }
        semaphore.wait()
    }

    func waitUntilHeld() async {
        await withCheckedContinuation { continuation in
            let already = lock.withLock { () -> Bool in
                if held { return true }
                waiters.append(continuation)
                return false
            }
            if already { continuation.resume() }
        }
    }

    func release() { semaphore.signal() }
}

/// An engine whose opening waits until it is cancelled.
private actor GatedOpeningEngine: ArchiveServing {
    private var opening: CheckedContinuation<Void, Error>?
    private var openingWaiters: [CheckedContinuation<Void, Never>] = []

    func waitUntilOpening() async {
        if opening != nil { return }
        await withCheckedContinuation { openingWaiters.append($0) }
    }

    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult {
        try await withCheckedThrowingContinuation { continuation in
            opening = continuation
            openingWaiters.forEach { $0.resume() }
            openingWaiters.removeAll()
        }
        throw ArchiveEngineError.cancelled
    }

    func cancelAllOperations() async {
        opening?.resume(throwing: ArchiveEngineError.cancelled)
        opening = nil
    }

    func items(at address: ArchiveAddress) async throws -> [BrowserItem] { [] }
    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?) async throws -> URL {
        throw ArchiveEngineError.itemNotFound
    }
    func createArchive(from sourceURLs: [URL], outputURL: URL, options: CompressionOptions, password: String?,
                       progress: @escaping ArchiveProgressHandler) async throws {}
    func extractArchive(at url: URL, to destinationURL: URL, password: String?,
                        resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {}
    func extractItems(_ items: [BrowserItem], to destinationURL: URL, password: String?,
                      resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {}
    func recursiveSize(of item: BrowserItem) async throws -> Int64 { 0 }
    func archiveRootURL(for address: ArchiveAddress) async throws -> URL { throw ArchiveEngineError.itemNotFound }
    func setPassword(_ password: String?, for sessionID: UUID) async {}
    func closeSession(_ sessionID: UUID) async {}
    func closeAllSessions() async {}
    func cleanupStaleSessions() async {}
}

@MainActor
private func previewSliders(in view: NSView) -> [ScaleSliderView] {
    (view as? ScaleSliderView).map { [$0] } ?? view.subviews.flatMap { previewSliders(in: $0) }
}
