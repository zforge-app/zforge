import AppKit
import SnapshotTesting
import SwiftUI
import Testing
@testable import Zforge

/// Offscreen characterization of Icons thumbnails with the real fixture files, file system,
/// archive engine, preview service and browser views. The windows are never ordered on
/// screen, so these checks do not take over the display like XCUITest does.
@Suite("Icon preview grid", .serialized, .timeLimit(.minutes(2)))
@MainActor
struct IconPreviewGridTests {
    static let previewNames = ["Preview.png", "Preview.jpg", "Preview.pdf", "Preview.txt", "Preview.html", "Preview.mov"]
    static let fallbackNames = ["Unsupported.bin", "Empty Folder", "Sample.zip"]
    /// The fixture window is 1200 pt wide; the content excludes the sidebar's ideal width.
    static let regularContent = CGSize(width: 1200 - BrowserSidebarLayout.idealWidth, height: 660)
    /// The narrow Portuguese fixture window is 720 pt wide.
    static let narrowContent = CGSize(width: 720 - BrowserSidebarLayout.idealWidth, height: 660)

    @Test("Icons show content for supported files and archive entries and native icons otherwise")
    func defaultPreviewsIncludeSupportedFilesAndArchiveEntries() async throws {
        let fixture = try await IconPreviewGridFixture()
        defer { fixture.close() }
        #expect(fixture.preferences.showIconPreviews, "Icon previews are enabled when nothing was saved")
        #expect(!fixture.state.previewVisible, "The preview panel stays hidden")
        let host = fixture.host(size: Self.regularContent)
        defer { host.close() }

        let previews = try Self.previewNames.map(fixture.item)
        try await host.waitUntil("every supported file shows its content thumbnail") {
            previews.allSatisfy { host.loads.isShowingPreview($0.id) }
        }
        for name in Self.fallbackNames {
            let item = try fixture.item(name)
            // Unavailable content either has no representation or fails; both keep the fallback.
            let content = try? await fixture.state.iconPreview(for: item, pixelSize: 128)
            #expect(content == nil, "\(name) has no content thumbnail")
        }
        try await host.renderPass()
        for name in Self.fallbackNames {
            let id = try fixture.item(name).id
            #expect(host.loads.latest[id] == false, "\(name) shows its native icon")
            #expect(!host.loads.everShown.contains(id), "\(name) never shows a content thumbnail")
        }
        host.snapshot(named: "folder")

        await fixture.state.open(try fixture.item("Sample.zip"))
        #expect(fixture.state.items.map(\.name) == ["Preview.png"], "The archive replaces the folder contents")
        let entry = try fixture.item("Preview.png")
        #expect(entry.localURL == nil, "The thumbnail belongs to the archive entry, not the folder file")
        try await host.waitUntil("the archive entry shows its content thumbnail") {
            host.loads.isShowingPreview(entry.id)
        }
        host.snapshot(named: "archive-entry")
    }

    @Test("The icon preview setting updates the open grid and survives preference reload")
    func settingUpdatesTheOpenGridAndPersists() async throws {
        let fixture = try await IconPreviewGridFixture()
        defer { fixture.close() }
        let host = fixture.host(size: Self.regularContent)
        let previews = try Self.previewNames.map(fixture.item)
        let everything = try (Self.previewNames + Self.fallbackNames).map(fixture.item)
        try await host.waitUntil("previews load while the setting is enabled") {
            previews.allSatisfy { host.loads.isShowingPreview($0.id) }
        }

        // The Settings toggle is bound to this application preference.
        fixture.preferences.showIconPreviews = false
        try await host.waitUntil("every cell returns to its native icon") {
            everything.allSatisfy { host.loads.latest[$0.id] == false }
        }
        host.snapshot(named: "disabled")
        host.close()

        // A relaunch reads the saved choice into new preferences and a new window.
        let disabled = try await fixture.relaunch()
        #expect(!disabled.preferences.showIconPreviews)
        let disabledHost = disabled.host(size: Self.regularContent)
        try await disabledHost.waitUntil("every cell of the relaunched grid appears") {
            everything.allSatisfy { disabledHost.loads.latest[$0.id] != nil }
        }
        #expect(disabledHost.loads.everShown.isEmpty, "No content thumbnail appears after relaunch")
        disabled.preferences.showIconPreviews = true
        try await disabledHost.waitUntil("enabling previews again updates the open grid") {
            previews.allSatisfy { disabledHost.loads.isShowingPreview($0.id) }
        }
        disabledHost.close()

        let enabled = try await fixture.relaunch()
        #expect(enabled.preferences.showIconPreviews)
        let enabledHost = enabled.host(size: Self.regularContent)
        defer { enabledHost.close() }
        try await enabledHost.waitUntil("the restored choice loads previews after relaunch") {
            enabledHost.loads.isShowingPreview(previews[0].id)
        }
    }

    @Test("Changing the icon preview setting preserves selection in every mode and with the preview panel")
    func settingPreservesSelectionInEveryModeAndPanelVisibility() async throws {
        let fixture = try await IconPreviewGridFixture()
        defer { fixture.close() }
        let state = fixture.state
        let host = fixture.host(size: Self.regularContent)
        defer { host.close() }
        let image = try fixture.item("Preview.png")
        state.select(image)
        try await host.waitUntil("the selected file shows its thumbnail") { host.loads.isShowingPreview(image.id) }
        #expect(state.selection == [image.id])
        #expect(state.previewItems.map(\.id) == [image.id], "Get Info describes the selected file")

        state.togglePreviewVisibility()
        #expect(state.previewVisible)
        try await host.renderPass()
        try await host.waitUntil("the thumbnail stays with the preview panel shown") { host.loads.isShowingPreview(image.id) }
        #expect(state.selection == [image.id])

        state.preferences.showIconPreviews = false
        try await host.waitUntil("the selected file returns to its native icon") { host.loads.latest[image.id] == false }
        #expect(state.selection == [image.id])

        for mode in [BrowserViewMode.list, .columns, .gallery, .icons] {
            host.loads.reset()
            state.viewMode = mode
            try await host.renderPass()
            #expect(state.selection == [image.id], "\(mode) keeps the selection")
            #expect(state.previewItems.map(\.id) == [image.id], "\(mode) keeps the Get Info target")
            #expect(!state.preferences.showIconPreviews, "\(mode) keeps the setting")
            #expect(host.loads.everShown.isEmpty, "\(mode) shows no icon content preview")
            if mode == .icons {
                try await host.waitUntil("Icons shows the native icon again") { host.loads.latest[image.id] == false }
            }
        }

        state.preferences.showIconPreviews = true
        try await host.waitUntil("enabling previews restores the thumbnail") { host.loads.isShowingPreview(image.id) }
        #expect(state.selection == [image.id])
        #expect(state.previewItems.map(\.id) == [image.id])
    }

    @Test("Video thumbnails show the play badge in Icons and on top of the selection stack")
    func videoThumbnailShowsPlayBadgeInIconsAndSelectionStack() async throws {
        let fixture = try await IconPreviewGridFixture()
        defer { fixture.close() }
        let state = fixture.state
        let movie = try fixture.item("Preview.mov")
        let image = try fixture.item("Preview.png")
        #expect(movie.showsVideoPlayBadge)
        #expect(!image.showsVideoPlayBadge)

        let cell = OffscreenHost(size: CGSize(width: 96, height: 96), appearance: .aqua) { [state] binding in
            IconPreviewView(item: movie, size: 64, enabled: true, state: state, isLoaded: binding)
        }
        defer { cell.close() }
        try await cell.waitUntil("the movie shows its content thumbnail") { cell.loads.isShowingPreview(movie.id) }
        cell.snapshot(named: "icons-movie")

        // The last selected item tops the stack, so select the movie last.
        state.select(image)
        state.select(movie, modifiers: [.command])
        state.preferences.setPreviewVisible(false, in: .gallery)
        state.viewMode = .gallery
        state.updatePreview()
        #expect(state.previewItems.map(\.id) == [movie.id, image.id], "The movie is on top of the stack")
        let stack = OffscreenHost(size: CGSize(width: 640, height: 420), appearance: .aqua) { [state] _ in
            SelectionOverview(state: state, items: state.previewItems, presentation: .gallery, scale: 1)
        }
        defer { stack.close() }
        try await stack.waitUntil("both stack layers show content thumbnails") {
            let thumbnails = stack.subviews(of: QuickLookThumbnailHostView.self)
            return thumbnails.count == 2 && thumbnails.allSatisfy(\.showsContentThumbnail)
        }
        stack.snapshot(named: "gallery-stack")
    }

    @Test("A narrow Portuguese grid keeps previews and multiple selection at both zoom limits")
    func portugueseNarrowGridKeepsPreviewsAndSelectionAtZoomLimits() async throws {
        let fixture = try await IconPreviewGridFixture(language: .portugueseBrazil)
        defer { fixture.close() }
        let state = fixture.state
        let locale = state.preferences.language.locale
        let host = fixture.host(size: Self.narrowContent, appearance: .darkAqua)
        defer { host.close() }
        let image = try fixture.item("Preview.png")
        let photo = try fixture.item("Preview.jpg")

        state.select(image)
        try await host.waitUntil("the selected file shows its thumbnail") { host.loads.isShowingPreview(image.id) }
        #expect(BrowserInfoWindowCoordinator.title(for: state.previewItems, locale: locale) == "Informações: Preview.png")

        for _ in 0..<3 { state.preferences.zoomOut() }
        #expect(state.preferences.scale == 0.7, "Three zoom-out steps reach the 70% minimum")
        try await host.renderPass()
        try await host.waitUntil("the thumbnail stays at the minimum zoom") { host.loads.isShowingPreview(image.id) }
        #expect(state.selection == [image.id])
        try await fixture.snapshotSettledGrid(size: Self.narrowContent, appearance: .darkAqua, named: "zoom-70")

        state.select(photo, modifiers: [.command])
        #expect(state.selection == [image.id, photo.id])
        try await host.waitUntil("both selected images show thumbnails") {
            host.loads.isShowingPreview(image.id) && host.loads.isShowingPreview(photo.id)
        }
        #expect(BrowserInfoWindowCoordinator.title(for: state.previewItems, locale: locale) == "Informações: 2 Itens")
        #expect(BrowserSelectionSummary(items: state.previewItems, locale: locale).title == "2 itens")
        try await fixture.snapshotSettledGrid(size: Self.narrowContent, appearance: .darkAqua, named: "zoom-70-two-selected")

        for _ in 0..<9 { state.preferences.zoomIn() }
        #expect(state.preferences.scale == 1.6, "Nine zoom-in steps reach the 160% maximum")
        try await host.renderPass()
        try await host.waitUntil("the thumbnails stay at the maximum zoom") {
            host.loads.isShowingPreview(image.id) && host.loads.isShowingPreview(photo.id)
        }
        #expect(state.selection == [image.id, photo.id])
        #expect(BrowserInfoWindowCoordinator.title(for: state.previewItems, locale: locale) == "Informações: 2 Itens")
        try await fixture.snapshotSettledGrid(size: Self.narrowContent, appearance: .darkAqua, named: "zoom-160-two-selected")

        #expect(AppLocalization.string("Show previews in icon view", locale: locale)
            == "Mostrar pré-visualizações na visão de ícones")
        #expect(state.preferences.showIconPreviews)
        state.preferences.showIconPreviews = false
        try await host.waitUntil("the grid returns to native icons") { host.loads.latest[image.id] == false }
        #expect(state.selection == [image.id, photo.id])
        #expect(BrowserInfoWindowCoordinator.title(for: state.previewItems, locale: locale) == "Informações: 2 Itens")
        #expect(BrowserSelectionSummary(items: state.previewItems, locale: locale).title == "2 itens")
    }
}

/// The real icon preview fixture in a temporary folder, browsed with isolated preferences.
@MainActor
final class IconPreviewGridFixture {
    let directory: URL
    let defaultsName: String
    let defaults: UserDefaults
    let preferences: FileBrowserPreferences
    let archives: NativeSevenZipArchiveEngine
    let state: FileBrowserState
    private var relaunched: [FileBrowserState] = []
    private let ownsFiles: Bool

    init(language: AppLanguagePreference = .english) async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IconPreviewGrid-\(UUID().uuidString)", isDirectory: true)
        defaultsName = "IconPreviewGrid-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: defaultsName))
        preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .icons
        preferences.scale = 1
        preferences.language = language
        preferences.setPreviewVisible(false, in: .icons)
        archives = NativeSevenZipArchiveEngine()
        ownsFiles = true
        try await IconPreviewUIFixture.create(at: directory, archives: archives)
        state = Self.browse(preferences: preferences, archives: archives)
        await state.navigateToSidebar(directory, name: directory.lastPathComponent)
    }

    private init(relaunching original: IconPreviewGridFixture) async {
        directory = original.directory
        defaultsName = original.defaultsName
        defaults = original.defaults
        preferences = FileBrowserPreferences(defaults: original.defaults)
        archives = original.archives
        ownsFiles = false
        state = Self.browse(preferences: preferences, archives: archives)
        await state.navigateToSidebar(directory, name: directory.lastPathComponent)
    }

    /// New preferences and browser state read from the same saved defaults, as after a relaunch.
    func relaunch() async throws -> IconPreviewGridFixture {
        let fixture = await IconPreviewGridFixture(relaunching: self)
        relaunched.append(fixture.state)
        return fixture
    }

    private static func browse(preferences: FileBrowserPreferences,
                               archives: NativeSevenZipArchiveEngine) -> FileBrowserState {
        FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: archives)
    }

    func host(size: CGSize, appearance: NSAppearance.Name = .aqua) -> OffscreenHost {
        OffscreenHost(size: size, appearance: appearance) { [state] _ in
            HostedBrowserContent(state: state)
        }
    }

    func item(_ name: String) throws -> BrowserItem {
        try #require(state.items.first { $0.name == name }, "\(name) is listed")
    }

    /// Snapshots the current grid in a fresh window once every visible content thumbnail has
    /// loaded at the current zoom, so a raster retained from the previous zoom never appears.
    func snapshotSettledGrid(size: CGSize, appearance: NSAppearance.Name, named name: String,
                             fileID: StaticString = #fileID, filePath: StaticString = #filePath,
                             testName: String = #function, line: UInt = #line, column: UInt = #column) async throws {
        let previews = try IconPreviewGridTests.previewNames.map(item)
        let selected = previews.filter { state.selection.contains($0.id) }
        let host = host(size: size, appearance: appearance)
        defer { host.close() }
        try await host.waitUntil("every visible content thumbnail loads") {
            selected.allSatisfy { host.loads.isShowingPreview($0.id) }
                && previews.allSatisfy { host.loads.latest[$0.id] != false }
        }
        host.snapshot(named: name, fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    func close() {
        state.close()
        relaunched.forEach { $0.close() }
        guard ownsFiles else { return }
        defaults.removePersistentDomain(forName: defaultsName)
        try? FileManager.default.removeItem(at: directory)
    }
}

private struct HostedBrowserContent: View {
    let state: FileBrowserState
    @State private var dragSession = BrowserFileDragSession()
    @FocusState private var focus: BrowserFocusTarget?

    var body: some View {
        BrowserContent(state: state, contentFocus: $focus, dragSession: dragSession)
            .environment(\.locale, state.preferences.language.locale)
    }
}

/// Which Icons cells show content thumbnails, as reported by the cells themselves.
@MainActor
final class IconPreviewLoadRecorder {
    private(set) var latest: [BrowserItemID: Bool] = [:]
    private(set) var everShown: Set<BrowserItemID> = []

    func record(_ id: BrowserItemID, _ isShowingPreview: Bool) {
        latest[id] = isShowingPreview
        if isShowingPreview { everShown.insert(id) }
    }

    func isShowingPreview(_ id: BrowserItemID) -> Bool { latest[id] == true }

    func reset() {
        latest.removeAll()
        everShown.removeAll()
    }
}

/// Hosts a SwiftUI view in a window that is never ordered on screen and never becomes key.
@MainActor
final class OffscreenHost {
    let window: NSWindow
    let view: NSView
    let loads = IconPreviewLoadRecorder()
    private let appearance: NSAppearance.Name

    init<Content: View>(size: CGSize, appearance: NSAppearance.Name,
                        @ViewBuilder content: (Binding<Bool>) -> Content) {
        self.appearance = appearance
        window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        let recorder = loads
        let root = content(.constant(false))
            .frame(width: size.width, height: size.height)
            .environment(\.iconPreviewLoadObserver) { id, isShowingPreview in
                recorder.record(id, isShowingPreview)
            }
        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: size)
        hosting.appearance = NSAppearance(named: appearance)
        window.contentView = hosting
        view = hosting
        view.layoutSubtreeIfNeeded()
    }

    /// Lets the main run loop process pending SwiftUI updates, then lays out and draws.
    func renderPass() async throws {
        for _ in 0..<2 {
            await withCheckedContinuation { continuation in
                DispatchQueue.main.async { continuation.resume() }
            }
            view.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }
    }

    /// Awaits an observable condition, failing with its description when it never holds.
    func waitUntil(_ description: String, timeout: Duration = .seconds(30),
                   sourceLocation: SourceLocation = #_sourceLocation,
                   _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting until \(description)", sourceLocation: sourceLocation)
                throw CancellationError()
            }
            view.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        try await renderPass()
    }

    func subviews<Match: NSView>(of type: Match.Type) -> [Match] {
        var found: [Match] = []
        func visit(_ view: NSView) {
            if let match = view as? Match { found.append(match) }
            view.subviews.forEach(visit)
        }
        visit(view)
        return found
    }

    /// Compares the hosted view with its reference in `ZforgeSnapshots/IconPreviewGridTests/`.
    /// The sandboxed test host cannot write into the project, so a missing reference is
    /// attached to the result bundle instead, for review and export.
    func snapshot(named name: String, fileID: StaticString = #fileID, filePath: StaticString = #filePath,
                  testName: String = #function, line: UInt = #line, column: UInt = #column) {
        let file = URL(fileURLWithPath: "\(filePath)")
        let fileName = "\(sanitized(testName)).\(sanitized(name)).png"
        let reference = file.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ZforgeSnapshots", isDirectory: true)
            .appendingPathComponent(file.deletingPathExtension().lastPathComponent, isDirectory: true)
            .appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: reference.path) {
            view.appearance = NSAppearance(named: appearance)
            view.layoutSubtreeIfNeeded()
            let strategy = Snapshotting<NSView, NSImage>.image
            strategy.snapshot(view).run { image in
                Attachment.record(strategy.diffing.toData(image), named: fileName,
                    sourceLocation: SourceLocation(fileID: "\(fileID)", filePath: "\(filePath)",
                                                   line: Int(line), column: Int(column)))
            }
        }
        ZforgeSnapshot.assert(view, appearance: appearance, named: name,
                              fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    private func sanitized(_ text: String) -> String {
        text.replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
    }

    func close() {
        window.contentView = nil
        window.close()
    }
}
