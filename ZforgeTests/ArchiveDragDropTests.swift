import AppKit
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Zforge

/// Offscreen characterization of the drop decisions and state changes behind
/// archive and local drags. Each scenario drives the same entry points used by
/// the native drop destination and the SwiftUI drop delegate, without a window.
@Suite("Archive and local drag-and-drop semantics")
struct ArchiveDragDropTests {
    /// A drag that stays inside Zforge offers both operations; the destination
    /// decides between them (see `ArchiveDragSourceView.draggingSession`).
    private static let withinApplicationMask: NSDragOperation = [.copy, .move]

    @Test("Option-drag inside an archive asks before copying; cancel keeps everything, confirm reveals per mode with full history",
          arguments: BrowserViewMode.allCases)
    @MainActor
    func internalCopyKeepsHistoryAndAncestorColumns(mode: BrowserViewMode) async throws {
        try await withDragFixture(mode: mode, navigation: true) { state, root, archive in
            var requests: [FileBrowserState.ArchiveTransferConfirmation] = []
            var approve = false
            state.archiveTransferConfirmation = { requests.append($0); return approve }
            try await enter(["Sample.zip", "Inside", "Deep"], in: state)
            #expect(state.title == "Deep")
            let payload = try #require(state.items.first(where: { $0.name == "DeepPayload.txt" }))
            let leaf = try #require(state.items.first(where: { $0.name == "Leaf" }))
            let view = ArchiveDropDestinationView()
            view.address = try #require(leaf.location.archiveDropAddress)
            let before = try Data(contentsOf: archive)

            // Escape in the confirmation leaves the archive and the view untouched.
            #expect(await drop([payload], from: state, onto: view, option: true) == .copy)
            #expect(requests.count == 1)
            #expect(requests.first?.moving == false)
            #expect(requests.first?.itemCount == 1)
            #expect(requests.first?.destination == "Inside/Deep/Leaf")
            #expect(requests.first?.archiveURL.standardizedFileURL == archive.standardizedFileURL)
            // Required: a changed archive would make the next drop raise a modal conflict alert.
            try #require(try Data(contentsOf: archive) == before)
            #expect(state.error == nil)
            #expect(state.title == "Deep")
            #expect(visibleRows(named: "DeepPayload.txt", in: state) == 1)

            // Return confirms the copy.
            approve = true
            #expect(await drop([payload], from: state, onto: view, option: true) == .copy)
            #expect(requests.count == 2)
            #expect(requests.last?.moving == false)
            #expect(state.error == nil)
            #expect(try Data(contentsOf: archive) != before)
            #expect(state.title == (mode == .list ? "Deep" : "Leaf"))
            #expect(visibleRows(named: "DeepPayload.txt", in: state) == (mode == .icons || mode == .gallery ? 1 : 2))
            if mode == .columns {
                for (index, name) in ["Sample.zip", "Inside", "Deep", "Leaf", "DeepPayload.txt"].enumerated() {
                    #expect(index < state.pathComponents.count, "Missing column \(index)")
                    guard index < state.pathComponents.count else { continue }
                    let rows = state.sortedColumnItems(at: state.pathComponents[index].location)
                    #expect(rows.contains(where: { $0.name == name }), "Missing ancestor \(name) in column \(index)")
                }
            }
            let titles = mode == .list ? ["Inside", "Sample.zip", root.lastPathComponent]
                : ["Deep", "Inside", "Sample.zip", root.lastPathComponent]
            for title in titles {
                await state.goBack()
                #expect(state.title == title, "Back skipped \(title)")
                #expect(state.error == nil)
            }
            await state.goForward()
            #expect(state.title == "Sample.zip")
        }
    }

    @Test("A drag out of an archive without Option copies into a dropped folder from every mode",
          arguments: BrowserViewMode.allCases)
    @MainActor
    func externalCopyIntoDroppedFolder(mode: BrowserViewMode) async throws {
        try await withDragFixture(mode: mode) { state, root, archive in
            var requests: [FileBrowserState.ArchiveTransferConfirmation] = []
            state.archiveTransferConfirmation = { requests.append($0); return true }
            let payload = try await revealPayload(in: state)
            let dropped = root.appendingPathComponent("Dropped", isDirectory: true)
            let view = ArchiveDropDestinationView()
            view.directory = dropped
            let before = try Data(contentsOf: archive)
            #expect(await drop([payload], from: state, onto: view, option: false) == .copy)
            #expect(requests.isEmpty, "Copying out of an archive must not ask to modify it")
            #expect(state.error == nil)
            #expect(try Data(contentsOf: archive) == before)
            #expect(try String(contentsOf: dropped.appendingPathComponent("Payload.txt"), encoding: .utf8) == "payload")
            #expect(visibleRows(named: "Payload.txt", in: state) == 1)
            await state.navigateToSidebar(dropped, name: "Dropped")
            #expect(state.title == "Dropped")
            #expect(state.sortedItems.map(\.name) == ["Payload.txt"])
        }
    }

    @Test("Option-drag out of an archive asks before moving; cancel keeps everything, confirm moves")
    @MainActor
    func externalMoveConfirmationAndCancellation() async throws {
        try await withDragFixture(mode: .list) { state, root, archive in
            var requests: [FileBrowserState.ArchiveTransferConfirmation] = []
            var approve = false
            state.archiveTransferConfirmation = { requests.append($0); return approve }
            let payload = try await revealPayload(in: state)
            let dropped = root.appendingPathComponent("Dropped", isDirectory: true)
            let view = ArchiveDropDestinationView()
            view.directory = dropped
            let before = try Data(contentsOf: archive)

            #expect(await drop([payload], from: state, onto: view, option: true) == .move)
            #expect(requests.count == 1)
            #expect(requests.first?.moving == true)
            #expect(requests.first.map { URL(fileURLWithPath: $0.destination).standardizedFileURL } == dropped.standardizedFileURL)
            #expect(state.error == nil)
            // Required: an existing copy would make the next drop raise a modal conflict alert.
            try #require(try FileManager.default.contentsOfDirectory(atPath: dropped.path).isEmpty)
            #expect(try Data(contentsOf: archive) == before)
            #expect(archiveRows(named: "Payload.txt", in: state) == 1)
            let droppedItem = try #require(state.items.first(where: { $0.name == "Dropped" }))
            await state.toggleExpansion(droppedItem)
            #expect(visibleRows(named: "Payload.txt", in: state) == 1)

            approve = true
            let source = try await revealPayload(in: state)
            #expect(await drop([source], from: state, onto: view, option: true) == .move)
            #expect(requests.count == 2)
            #expect(requests.last?.moving == true)
            #expect(state.error == nil)
            #expect(try String(contentsOf: dropped.appendingPathComponent("Payload.txt"), encoding: .utf8) == "payload")
            #expect(try Data(contentsOf: archive) != before)
            #expect(archiveRows(named: "Payload.txt", in: state) == 0)
            #expect(archiveRows(named: "Survivor.txt", in: state) == 1)
            await state.navigateToSidebar(dropped, name: "Dropped")
            #expect(state.title == "Dropped")
            #expect(state.sortedItems.map(\.name) == ["Payload.txt"])
        }
    }

    @Test("Internal List drag moves without Option and copies with Option, revealing expanded destinations")
    @MainActor
    func internalMoveThenOptionCopyRevealExpandedDestination() async throws {
        try await withDragFixture(mode: .list) { state, _, archive in
            var requests: [FileBrowserState.ArchiveTransferConfirmation] = []
            state.archiveTransferConfirmation = { requests.append($0); return true }
            let payload = try await revealPayload(in: state)
            let archiveItem = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            let target = try #require(state.expandedChildren[archiveItem.id]?.first(where: { $0.name == "Target" }))
            let view = ArchiveDropDestinationView()
            view.address = try #require(target.location.archiveDropAddress)
            #expect(await drop([payload], from: state, onto: view, option: false) == .move)
            #expect(requests.count == 1)
            #expect(requests.last?.moving == true)
            #expect(requests.last?.destination == "Target")
            #expect(state.error == nil)
            #expect(archiveRows(named: "Payload.txt", in: state) == 1)
            let refreshedArchive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            #expect(state.expandedItems.contains(refreshedArchive.id))
            let movedTarget = try #require(state.expandedChildren[refreshedArchive.id]?.first(where: { $0.name == "Target" }))
            let survivingInside = try #require(state.expandedChildren[refreshedArchive.id]?.first(where: { $0.name == "Inside" }))
            #expect(state.expandedItems.contains(movedTarget.id))
            #expect(state.expandedItems.contains(survivingInside.id))
            // Required: a surviving source would make the next drop raise a modal conflict alert.
            try #require(state.expandedChildren[survivingInside.id]?.contains(where: { $0.name == "Payload.txt" }) == false)
            let moved = try #require(state.expandedChildren[movedTarget.id]?.first(where: { $0.name == "Payload.txt" }))
            let before = try Data(contentsOf: archive)

            let copyView = ArchiveDropDestinationView()
            copyView.address = try #require(survivingInside.location.archiveDropAddress)
            #expect(await drop([moved], from: state, onto: copyView, option: true) == .copy)
            #expect(requests.count == 2)
            #expect(requests.last?.moving == false)
            #expect(requests.last?.destination == "Inside")
            #expect(state.error == nil)
            #expect(try Data(contentsOf: archive) != before)
            #expect(archiveRows(named: "Payload.txt", in: state) == 2)
        }
    }

    @Test("A drag from one window's archive copies into a folder shown by another window")
    @MainActor
    func copyIntoAnotherWindow() async throws {
        try await withDragFixture(mode: .list) { state, root, archive in
            var requests: [FileBrowserState.ArchiveTransferConfirmation] = []
            state.archiveTransferConfirmation = { requests.append($0); return true }
            let payload = try await revealPayload(in: state)
            let suite = "ZforgeTestSuite.ArchiveDragOtherWindow-\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removeTestSuite(named: suite) }
            let preferences = FileBrowserPreferences(defaults: defaults)
            preferences.language = .english; preferences.viewMode = .list
            let other = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
                grants: UIFixtureAccessGrantStore(), archives: NativeSevenZipArchiveEngine())
            defer { other.close() }
            await other.navigateToSidebar(root, name: root.lastPathComponent)
            let droppedItem = try #require(other.items.first(where: { $0.name == "Dropped" }))
            let view = ArchiveDropDestinationView()
            view.directory = try #require(droppedItem.localURL)
            let before = try Data(contentsOf: archive)
            #expect(await drop([payload], from: state, onto: view, option: false) == .copy)
            #expect(requests.isEmpty)
            #expect(state.error == nil)
            #expect(other.error == nil)
            #expect(try Data(contentsOf: archive) == before)
            #expect(visibleRows(named: "Payload.txt", in: state) == 1)
            await other.open(droppedItem)
            #expect(other.title == "Dropped")
            #expect(other.sortedItems.map(\.name) == ["Payload.txt"])
            let copied = root.appendingPathComponent("Dropped/Payload.txt")
            #expect(try String(contentsOf: copied, encoding: .utf8) == "payload")
        }
    }

    @Test("A local drag without modifiers moves into a folder; Option copies it", arguments: [false, true])
    @MainActor
    func localDragMoveAndOptionCopy(copying: Bool) async throws {
        try await withDragFixture(mode: .list) { state, root, _ in
            let local = try #require(state.items.first(where: { $0.name == "Local.txt" }))
            let source = root.appendingPathComponent("Local.txt")
            let dropped = root.appendingPathComponent("Dropped", isDirectory: true)
            let destination = dropped.appendingPathComponent("Local.txt")
            // The delegate reads the live modifier flags of the drop.
            let operation = BrowserFileDropOperationResolver.operation(forNativeFlags: copying ? [.option] : [])
            #expect(operation == (copying ? .copy : .automatic))
            #expect(state.performDrop(providers: [try #require(state.itemProvider(for: local))], to: dropped, operation: operation))
            // The transfer starts asynchronously and reports completion by
            // clearing its progress flag after the destination exists.
            try await waitUntil { FileManager.default.fileExists(atPath: destination.path) && !state.fileOperationInProgress }
            #expect(state.error == nil)
            #expect(try String(contentsOf: destination, encoding: .utf8) == "local")
            #expect(FileManager.default.fileExists(atPath: source.path) == copying)
            let droppedItem = try #require(state.items.first(where: { $0.name == "Dropped" }))
            await state.toggleExpansion(droppedItem)
            #expect(visibleRows(named: "Local.txt", in: state) == (copying ? 2 : 1))
            await state.open(droppedItem)
            #expect(state.title == "Dropped")
            #expect(state.sortedItems.map(\.name) == ["Local.txt"])
        }
    }

    @Test("A local file dropped on an archive waits for confirmation, then adds it and keeps the source")
    @MainActor
    func localDropIntoArchiveRequiresConfirmation() async throws {
        try await withDragFixture(mode: .list) { state, root, archive in
            let local = try #require(state.items.first(where: { $0.name == "Local.txt" }))
            let source = root.appendingPathComponent("Local.txt")
            let before = try Data(contentsOf: archive)
            #expect(state.performArchiveDrop(providers: [try #require(state.itemProvider(for: local))], to: archive, address: nil))
            try await waitUntil { state.pendingArchiveAddition != nil }
            let request = try #require(state.pendingArchiveAddition)
            #expect(request.sourceURLs.map(\.standardizedFileURL) == [source.standardizedFileURL])
            #expect(request.archiveURL.standardizedFileURL == archive.standardizedFileURL)
            #expect(request.internalPath.isEmpty)
            #expect(try Data(contentsOf: archive) == before)
            // The dialog clears its binding before running the confirmed request.
            state.pendingArchiveAddition = nil
            await state.confirmArchiveAddition(request)
            #expect(state.error == nil)
            #expect(try Data(contentsOf: archive) != before)
            #expect(try String(contentsOf: source, encoding: .utf8) == "local")
            let archiveItem = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            if !state.expandedItems.contains(archiveItem.id) { await state.toggleExpansion(archiveItem) }
            #expect(visibleRows(named: "Local.txt", in: state) == 2)
            #expect(archiveRows(named: "Local.txt", in: state) == 1)
        }
    }

    // MARK: - Drop driving

    /// Performs a virtual drag the way AppKit drives the native destination:
    /// the pasteboard carries the transfer identity, the destination decides
    /// the operation, performs it, and the session then ends with that result.
    @MainActor
    private func drop(_ items: [BrowserItem], from state: FileBrowserState, onto view: ArchiveDropDestinationView,
                      option: Bool) async -> NSDragOperation {
        let transfer = ArchiveDragTransfer(state: state, items: items, optionPressed: { option })
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let providers = items.enumerated().map { index, item in
            let delegate = ArchivePromiseDelegate(transfer: transfer, index: index, name: item.name)
            transfer.delegates.append(delegate)
            return ArchiveDragPromise(type: item.isDirectory ? UTType.folder.identifier : UTType.data.identifier,
                delegate: delegate, token: transfer.token)
        }
        #expect(board.writeObjects(providers))
        #expect(view.transfer(from: board) === transfer)
        let operation = view.operation(for: view.transfer(from: board), option: option, sourceMask: Self.withinApplicationMask)
        let performed = view.perform(pasteboard: board, operation: operation)
        #expect(performed == !operation.isEmpty)
        transfer.ended(performed ? operation : [])
        await transfer.waitForCompletion()
        #expect(ArchiveDragTransfer.active[transfer.token] == nil)
        return operation
    }

    // MARK: - Presentation

    /// Rows named `name` that the current view mode presents.
    @MainActor
    private func visibleRows(named name: String, in state: FileBrowserState) -> Int {
        visibleItems(in: state).filter { $0.name == name }.count
    }

    /// Visible rows named `name` that are archive entries rather than local files.
    @MainActor
    private func archiveRows(named name: String, in state: FileBrowserState) -> Int {
        visibleItems(in: state).filter { item in
            guard item.name == name, case .archive = item.location else { return false }
            return true
        }.count
    }

    @MainActor
    private func visibleItems(in state: FileBrowserState) -> [BrowserItem] {
        switch state.viewMode {
        case .list:
            return state.flattenedList().map(\.item)
        case .columns:
            // Mirrors ColumnBrowserView: columns through the one after the active column.
            let active = state.pathComponents.firstIndex(where: {
                $0.location == (state.activeColumnLocation ?? state.location)
            }) ?? max(state.pathComponents.count - 1, 0)
            return state.pathComponents.prefix(active + 2).flatMap { state.sortedColumnItems(at: $0.location) }
        case .icons, .gallery:
            return state.sortedItems
        }
    }

    // MARK: - Navigation

    @MainActor
    private func enter(_ names: [String], in state: FileBrowserState) async throws {
        for name in names {
            let item = try #require(state.items.first(where: { $0.name == name }))
            if state.viewMode == .columns { await state.activateColumnItem(item, in: state.location).value }
            else { await state.open(item) }
        }
    }

    /// Shows Sample.zip/Inside/Payload.txt: List discloses the archive inline,
    /// the other modes navigate into it.
    @MainActor
    private func revealPayload(in state: FileBrowserState) async throws -> BrowserItem {
        guard state.viewMode == .list else {
            try await enter(["Sample.zip", "Inside"], in: state)
            return try #require(state.items.first(where: { $0.name == "Payload.txt" }))
        }
        let archive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
        if !state.expandedItems.contains(archive.id) { await state.toggleExpansion(archive) }
        let inside = try #require(state.expandedChildren[archive.id]?.first(where: { $0.name == "Inside" }))
        if !state.expandedItems.contains(inside.id) { await state.toggleExpansion(inside) }
        return try #require(state.expandedChildren[inside.id]?.first(where: { $0.name == "Payload.txt" }))
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<500 where !condition() { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }

    // MARK: - Fixture

    /// The same tree as the `--ui-archive-drag-fixtures` launch argument:
    /// Dropped/, Local.txt and Sample.zip containing Inside/{Payload,Survivor}.txt
    /// and Target/; the navigation variant adds Inside/Deep/{DeepPayload.txt, Leaf/Keep.txt}.
    @MainActor
    private func withDragFixture(mode: BrowserViewMode, navigation: Bool = false,
                                 body: (FileBrowserState, URL, URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ArchiveDragDrop-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let staging = root.appendingPathComponent(".staging", isDirectory: true)
        let inside = staging.appendingPathComponent("Inside", isDirectory: true)
        let target = staging.appendingPathComponent("Target", isDirectory: true)
        for directory in [inside, target, root.appendingPathComponent("Dropped", isDirectory: true)] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
        try Data("survivor".utf8).write(to: inside.appendingPathComponent("Survivor.txt"))
        if navigation {
            let leaf = inside.appendingPathComponent("Deep/Leaf", isDirectory: true)
            try FileManager.default.createDirectory(at: leaf, withIntermediateDirectories: true)
            try Data("deep payload".utf8).write(to: inside.appendingPathComponent("Deep/DeepPayload.txt"))
            try Data("keep".utf8).write(to: leaf.appendingPathComponent("Keep.txt"))
        }
        try Data("local".utf8).write(to: root.appendingPathComponent("Local.txt"))
        let archive = root.appendingPathComponent("Sample.zip")
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [inside, target], outputURL: archive, format: .zip, progress: { _ in })
        try FileManager.default.removeItem(at: staging)
        let suite = "ZforgeTestSuite.ArchiveDragDrop-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = mode
        let state = FileBrowserState(preferences: preferences, fileSystem: FileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: engine)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        #expect(state.viewMode == mode)
        try await body(state, root, archive)
    }
}
