import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// Hosts the real `ColumnBrowserView` in an offscreen window (never ordered front)
/// and reads the laid-out AppKit views: every column and the column preview are
/// backed by their own vertical `NSScrollView` inside the horizontal one, and each
/// rendered row carries an `ArchiveDragSourceView` that knows its item.
///
/// Hosted widths stand for the browser window minus the sidebar's ideal width
/// (`BrowserSidebarLayout.idealWidth`, 220 pt): 1180 pt for a 1400 pt window and
/// 980 pt for a 1200 pt window.
@Suite("Column browser layout")
@MainActor
struct ColumnBrowserLayoutTests {
    @Test("A loading column never shows its parent's rows, then shows exactly its own result")
    func loadingColumnNeverDuplicatesParentRows() async throws {
        let gate = ColumnLoadGate()
        let fixture = try ColumnFixture(
            columnWidth: 260, contentWidth: 1_180,
            fileSystem: UIFixtureFileSystemService(itemsGate: { await gate.pass() }),
            archives: UIFixtureArchiveEngine(itemsGate: { await gate.pass() })
        )
        defer { fixture.close() }
        defer { Task { await gate.releaseAll() } }
        let state = fixture.state
        await state.navigateToSidebar(URL(fileURLWithPath: "/ZforgeFixtures/Downloads"), name: "Downloads")
        let rootLocation = state.location
        let rootNames = ["Another.txt", "Fixture Folder", "Sample.zip", "Welcome.txt"]
        let loadedRoot = try await fixture.settle { $0.rows.first.map(Set.init) == Set(rootNames) }
        #expect(loadedRoot.columns.count == 1)

        for (container, result, previous) in [
            ("Sample.zip", "Inside.txt", "FolderChild.txt"),
            ("Fixture Folder", "FolderChild.txt", "Inside.txt"),
            ("Sample.zip", "Inside.txt", "FolderChild.txt")
        ] {
            let item = try #require(state.sortedColumnItems(at: rootLocation).first { $0.name == container })
            let activation = state.activateColumnItem(item, in: rootLocation)
            // The gate holds the child's read, so the view is inspected in the
            // actual intermediate state rather than only after loading.
            await gate.waitForPendingLoad()
            let pending = try await fixture.settle { $0.columns.count == 2 }
            #expect(state.pathComponents.last?.name == container)
            #expect(pending.rows[1].isEmpty, "Loading \(container) rendered \(pending.rows[1]).")
            for name in rootNames + [previous, result] {
                #expect(!pending.rows[1].contains(name), "Loading \(container) duplicated \(name).")
            }
            #expect(pending.rows[0].contains("Welcome.txt"))

            await gate.releaseAll()
            await activation.value
            let loaded = try await fixture.settle { $0.columns.count == 2 && !$0.rows[1].isEmpty }
            #expect(loaded.rows[1] == [result], "\(container) rendered \(loaded.rows[1]).")
            #expect(Set(loaded.rows[0]) == Set(rootNames))
        }
    }

    @Test("Column preview recalculates its width for a new column depth")
    func previewRecalculatesWidthForNewDepth() async throws {
        let fixture = try ColumnFixture(columnWidth: 260, contentWidth: 1_180)
        defer { fixture.close() }
        let state = fixture.state
        await state.start()
        await state.navigateToSidebar(URL(fileURLWithPath: "/ZforgeFixtures/Downloads"), name: "Downloads")
        let rootLocation = state.location

        await fixture.activate("Welcome.txt", in: rootLocation)
        let root = try await fixture.settle { $0.preview != nil && $0.columns.count == 1 }
        let rootWidth = try #require(root.preview?.width)

        await fixture.activate("Sample.zip", in: rootLocation)
        let archiveLocation = state.location
        _ = try await fixture.settle { $0.columns.count == 2 && $0.rows[1] == ["Inside.txt"] }
        await fixture.activate("Inside.txt", in: archiveLocation)
        let nested = try await fixture.settle { $0.preview != nil && $0.columns.count == 2 }
        let nestedWidth = try #require(nested.preview?.width)

        #expect(rootWidth > nestedWidth)
        #expect(nestedWidth >= BrowserColumnsLayout.minimumPreviewWidth)
        // Each preview fills the space left beside its columns when it is loaded.
        #expect(abs(rootWidth - (1_180 - 260)) <= 1)
        #expect(abs(nestedWidth - (1_180 - 2 * 260)) <= 1)
    }

    @Test("A preview replacing an expanded terminal column keeps its slot")
    func previewKeepsExpandedTerminalAlignment() async throws {
        let fixture = try ColumnFixture(columnWidth: 600, contentWidth: 980)
        defer { fixture.close() }
        let state = fixture.state
        await state.start()
        await state.navigateToSidebar(URL(fileURLWithPath: "/ZforgeFixtures/Downloads"), name: "Downloads")
        let rootLocation = state.location

        await fixture.activate("Welcome.txt", in: rootLocation)
        let initial = try await fixture.settle { $0.preview != nil && $0.columns.count == 1 }
        let initialPreview = try #require(initial.preview)

        await fixture.activate("Sample.zip", in: rootLocation)
        let expanded = try await fixture.settle {
            $0.preview == nil && $0.columns.count == 2 && $0.rows[1] == ["Inside.txt"]
        }
        let expandedFrame = expanded.columns[1]
        #expect(expandedFrame.width > initialPreview.width)

        await fixture.activate("Welcome.txt", in: rootLocation)
        let replaced = try await fixture.settle {
            $0.preview != nil && $0.columns.count == 1 && $0.isScrolledToTrailingEdge
        }
        let replacement = try #require(replaced.preview)
        #expect(abs(replacement.width - expandedFrame.width) <= 1)
        #expect(abs(replacement.minX - expandedFrame.minX) <= 1)
        #expect(abs(replacement.maxX - expandedFrame.maxX) <= 1)
        // The wide slot scrolls the root column partly out at the leading edge
        // while part of its rows stays visible.
        #expect(replaced.visible.minX > replaced.columns[0].minX)
        #expect(replaced.visible.minX < replaced.columns[0].maxX)
        // Sample.zip's label scrolls out, but its row still spans the column into
        // the visible area, so the visible part of the row remains its target.
        let sampleRow = try #require(replaced.rows[0].firstIndex(of: "Sample.zip").map { replaced.rowFrames[0][$0] })
        #expect(sampleRow.minX < replaced.visible.minX)
        #expect(sampleRow.maxX > replaced.visible.minX + 24)

        await fixture.activate("Sample.zip", in: rootLocation)
        let reopened = try await fixture.settle {
            $0.preview == nil && $0.columns.count == 2 && $0.rows[1] == ["Inside.txt"]
        }
        #expect(abs(reopened.columns[1].minX - expandedFrame.minX) <= 1)
        #expect(abs(reopened.columns[1].width - expandedFrame.width) <= 1)
    }
}

extension ColumnBrowserLayoutTests {
    /// The real-window failure of `testArchiveInternalCopyConfirmationKeepsHistoryAndAncestorColumns`
    /// (2026-11-01): while a folder's column loaded, the column before it kept the terminal width
    /// and the pending slot added another, so the columns briefly measured 1,721 pt instead of
    /// 1,120 pt. A scroll to the end in that moment stayed about 600 pt to the right once the
    /// columns fit again, and the active column sat under the sidebar.
    @Test("When a folder is opened, the columns never grow wider than they will be once its column shows")
    func openingAFolderDoesNotWidenTheColumns() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ColumnPending-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Sample/Inside/Deep"), withIntermediateDirectories: true)
        for path in ["Local.txt", "Sample/Target.txt", "Sample/Inside/Payload.txt", "Sample/Inside/Deep/DeepPayload.txt"] {
            try Data("x".utf8).write(to: root.appendingPathComponent(path))
        }
        defer { try? FileManager.default.removeItem(at: root) }
        let fixture = try ColumnFixture(columnWidth: 260, contentWidth: 1_120, fileSystem: FileSystemService())
        defer { fixture.close() }
        let state = fixture.state
        await state.navigateToSidebar(root, name: "Root")
        _ = try await fixture.settle { !$0.rows.isEmpty && $0.rows[0].contains("Sample") }
        var location = state.location
        for (name, next) in [("Sample", "Inside"), ("Inside", "Deep")] {
            let item = try #require(state.sortedColumnItems(at: location).first { $0.name == name })
            let activation = state.activateColumnItem(item, in: location)
            // The moment between the activation and the opening of the folder, laid out at once.
            let opening = try #require(fixture.layoutNow())
            #expect(opening.documentWidth <= opening.visible.width + 1,
                    "Opening \(name): columns of \(opening.documentWidth) pt in \(opening.visible.width) pt; \(opening)")
            await activation.value
            location = state.location
            let opened = try await fixture.settle { ($0.rows.last ?? []).contains(next) }
            #expect(opened.documentWidth <= opened.visible.width + 1)
            #expect(opened.isScrolledToTrailingEdge)
            #expect((opened.columns.last?.minX ?? -1) >= opened.visible.minX, "The active column is visible")
        }
    }
}

extension ColumnBrowserLayoutTests {
    /// The user's recording of 2026-11-17: moving through the files of an archive in Columns,
    /// each preview left for the moment its file was read from the archive, the column beside
    /// it widened into the space, and the preview then pushed it back. Where the column had
    /// already opened a branch, the reserved slot was added to the widened column, so the
    /// columns also scrolled sideways.
    @Test("While an archive file's preview loads, the columns keep the layout it will have")
    func loadingArchivePreviewKeepsTheLayout() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ColumnPreviewLoad-\(UUID().uuidString)", isDirectory: true)
        let payload = root.appendingPathComponent("Payload", isDirectory: true)
        let shown = root.appendingPathComponent("Shown", isDirectory: true)
        try FileManager.default.createDirectory(at: payload.appendingPathComponent("Folder"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: shown, withIntermediateDirectories: true)
        for path in ["Folder/Deep.txt", "A.txt", "B.txt"] {
            try Data("Preview of \(path)".utf8).write(to: payload.appendingPathComponent(path))
        }
        defer { try? FileManager.default.removeItem(at: root) }
        try await NativeSevenZipArchiveEngine().createArchive(
            from: ["Folder", "A.txt", "B.txt"].map { payload.appendingPathComponent($0) },
            outputURL: shown.appendingPathComponent("Archive.zip"), format: .zip, progress: { _ in })
        let engine = NativeSevenZipArchiveEngine()
        defer { Task { await engine.closeAllSessions() } }
        let fixture = try ColumnFixture(columnWidth: 260, contentWidth: 1_120, fileSystem: FileSystemService(), archives: engine)
        defer { fixture.close() }
        let state = fixture.state
        await state.navigateToSidebar(shown, name: "Shown")
        _ = try await fixture.settle { $0.rows.first == ["Archive.zip"] }
        await fixture.activate("Archive.zip", in: state.location)
        let archiveLocation = state.location
        _ = try await fixture.settle { $0.columns.count == 2 && Set($0.rows[1]) == ["Folder", "A.txt", "B.txt"] }

        // A.txt before the archive's column opened a branch, then B.txt and A.txt after Folder did:
        // from a branch to a file, and from a file to a file.
        for (name, opensFolderFirst) in [("A.txt", false), ("B.txt", true), ("A.txt", false)] {
            if opensFolderFirst {
                await fixture.activate("Folder", in: archiveLocation)
                _ = try await fixture.settle { $0.columns.count == 3 && $0.rows[2] == ["Deep.txt"] }
            }
            let item = try #require(state.sortedColumnItems(at: archiveLocation).first { $0.name == name })
            state.activateColumnItem(item, in: archiveLocation)
            // The moment after the selection, before the archive is read, laid out at once.
            let loading = try #require(fixture.layoutNow())
            #expect(loading.preview == nil, "\(name)'s preview is still loading")
            let loaded = try await fixture.settle { $0.preview != nil && $0.columns.count == 2 && $0.isScrolledToTrailingEdge }
            #expect(abs(loading.columns[1].width - loaded.columns[1].width) <= 1,
                    "Loading \(name): the archive's column measured \(loading.columns[1].width) pt, then \(loaded.columns[1].width) pt")
            #expect(abs(loading.documentWidth - loaded.documentWidth) <= 1,
                    "Loading \(name): the columns measured \(loading.documentWidth) pt, then \(loaded.documentWidth) pt; \(loading)")
        }
    }
}

/// A browser state plus the real column view hosted offscreen.
@MainActor
private final class ColumnFixture {
    let state: FileBrowserState
    private let defaultsName = "ZforgeTestSuite.ColumnBrowserLayout-\(UUID().uuidString)"
    private let window: NSWindow
    private let host: NSView

    init(
        columnWidth: CGFloat, contentWidth: CGFloat,
        fileSystem: any FileSystemServing = UIFixtureFileSystemService(),
        archives: any ArchiveServing = UIFixtureArchiveEngine()
    ) throws {
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.viewMode = .columns
        preferences.language = .english
        preferences.scale = 1
        preferences.setFinderColumnWidth(columnWidth)
        preferences.setPreviewVisible(true, in: .columns)
        state = FileBrowserState(
            preferences: preferences, fileSystem: fileSystem,
            recentItems: UIFixtureRecentItemsService(includesArchiveSessionCopies: false),
            taggedItems: UIFixtureTaggedItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: archives
        )
        host = NSHostingView(rootView: ColumnBrowserHarness(state: state))
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentWidth, height: 600),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = host
    }

    func close() {
        state.close()
        window.close()
        UserDefaults.standard.removeTestSuite(named: defaultsName)
    }

    /// Lays the view out now, without yielding, and reads it.
    func layoutNow() -> ColumnLayoutSnapshot? {
        host.layoutSubtreeIfNeeded()
        return ColumnLayoutSnapshot(host: host)
    }

    func activate(_ name: String, in location: BrowserLocation) async {
        guard let item = state.sortedColumnItems(at: location).first(where: { $0.name == name }) else {
            Issue.record("\(name) is not listed in \(location).")
            return
        }
        await state.activateColumnItem(item, in: location).value
    }

    /// Lays the view out until `condition` holds on two consecutive passes, so
    /// a frame read mid-update or mid-scroll is never reported as the result.
    func settle(
        timeout: Duration = .seconds(5),
        until condition: (ColumnLayoutSnapshot) -> Bool
    ) async throws -> ColumnLayoutSnapshot {
        let deadline = ContinuousClock.now + timeout
        var previous: ColumnLayoutSnapshot?
        var latest: ColumnLayoutSnapshot?
        while ContinuousClock.now < deadline {
            host.layoutSubtreeIfNeeded()
            let current = ColumnLayoutSnapshot(host: host)
            if let current, condition(current) {
                if current == previous { return current }
                previous = current
            } else {
                previous = nil
            }
            latest = current
            try await Task.sleep(for: .milliseconds(10))
        }
        throw ColumnLayoutTimeout(lastLayout: String(describing: latest))
    }
}

private struct ColumnLayoutTimeout: Error, CustomStringConvertible {
    let lastLayout: String
    var description: String { "The column layout never reached the expected state; last layout: \(lastLayout)." }
}

private struct ColumnBrowserHarness: View {
    let state: FileBrowserState
    @FocusState private var focus: BrowserFocusTarget?
    @State private var dragSession = BrowserFileDragSession()

    var body: some View {
        ColumnBrowserView(state: state, contentFocus: $focus, dragSession: dragSession)
    }
}

/// Frames in the horizontal scroll view's document coordinates.
@MainActor
private struct ColumnLayoutSnapshot: Equatable, CustomStringConvertible {
    let columns: [CGRect]
    let preview: CGRect?
    let visible: CGRect
    let documentWidth: CGFloat
    /// Item names rendered by each column, top to bottom.
    let rows: [[String]]
    /// The interactive row frames of each column, matching `rows`.
    let rowFrames: [[CGRect]]

    var isScrolledToTrailingEdge: Bool { abs(visible.maxX - documentWidth) <= 1 }

    nonisolated var description: String {
        "columns: \(columns), preview: \(String(describing: preview)), visible: \(visible), rows: \(rows)"
    }

    init?(host: NSView) {
        guard let outer = Self.descendants(of: host).lazy.compactMap({ $0 as? NSScrollView }).first,
              let document = outer.documentView else { return nil }
        let views = Self.descendants(of: document)
        let slots = views.compactMap { $0 as? NSScrollView }
            .filter { $0.superview?.enclosingScrollView === outer }
            .map { (view: $0, frame: document.convert($0.bounds, from: $0)) }
        let previewHandle = views
            .compactMap { $0 as? BrowserColumnResizeHandle.ResizeView }
            .first { $0.direction < 0 }
            .map { document.convert($0.bounds, from: $0) }
        let previewSlot = previewHandle.flatMap { handle in
            slots.first { abs($0.frame.minX - handle.minX) < 0.5 }
        }
        let columnSlots = slots.filter { $0.view !== previewSlot?.view }.sorted { $0.frame.minX < $1.frame.minX }
        columns = columnSlots.map(\.frame)
        preview = previewSlot?.frame
        visible = outer.contentView.bounds
        documentWidth = document.frame.width
        let renderedRows = columnSlots.map { slot in
            var seen: Set<BrowserItemID> = []
            return Self.descendants(of: slot.view)
                .compactMap { $0 as? ArchiveDragSourceView }
                .compactMap { view -> (y: CGFloat, item: BrowserItem, frame: CGRect)? in
                    guard let item = view.item else { return nil }
                    return (view.convert(view.bounds, to: nil).midY, item, document.convert(view.bounds, from: view))
                }
                .sorted { $0.y > $1.y }
                .filter { seen.insert($0.item.id).inserted }
        }
        rows = renderedRows.map { $0.map(\.item.name) }
        rowFrames = renderedRows.map { $0.map(\.frame) }
    }

    private static func descendants(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}

/// Holds fixture reads until the test releases them.
private actor ColumnLoadGate {
    private var pending: [CheckedContinuation<Void, Never>] = []
    private var observers: [CheckedContinuation<Void, Never>] = []

    func pass() async {
        await withCheckedContinuation { continuation in
            pending.append(continuation)
            let waiting = observers
            observers.removeAll()
            waiting.forEach { $0.resume() }
        }
    }

    func waitForPendingLoad() async {
        guard pending.isEmpty else { return }
        await withCheckedContinuation { observers.append($0) }
    }

    func releaseAll() {
        let released = pending
        pending.removeAll()
        released.forEach { $0.resume() }
    }
}
