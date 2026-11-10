import Foundation
import Testing
@testable import Zforge

/// A reload (the directory monitor's, or the one after an archive update) keeps
/// the List's inline expansions that other work completed while the reload was
/// waiting for a folder listing. Each case holds the reload at an exact point
/// with a gated file system, so the interleaving is the same on every run
/// (ZF-70, D-90).
@Suite("Reload keeps inline expansions completed while it waited")
@MainActor
struct ReloadExpansionRaceTests {
    @Test("An archive expanded inline while a reload waits for an expanded folder stays expanded")
    func archiveExpandedDuringReloadStaysExpanded() async throws {
        try await withFixture { state, fileSystem, dropped in
            let archive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            #expect(!state.expandedItems.contains(archive.id))

            // The reload lists the root, passes the collapsed archive and waits in Dropped.
            await fileSystem.holdNextListing(of: dropped)
            let reload = Task { await state.reload() }
            await fileSystem.waitUntilHeld()

            await state.toggleExpansion(archive)
            #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip", "Inside"])

            await fileSystem.release()
            await reload.value
            #expect(state.error == nil)
            #expect(state.expandedItems.contains(archive.id), "The reload collapsed the archive expanded meanwhile")
            #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip", "Inside"])
        }
    }

    @Test("A folder inside an inline archive expanded while a reload waits stays expanded with its rows")
    func archiveFolderExpandedDuringReloadStaysExpanded() async throws {
        try await withFixture { state, fileSystem, dropped in
            let archive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            await state.toggleExpansion(archive)
            let inside = try #require(state.expandedChildren[archive.id]?.first(where: { $0.name == "Inside" }))

            // The reload passes the expanded archive and its collapsed Inside, then waits in Dropped.
            await fileSystem.holdNextListing(of: dropped)
            let reload = Task { await state.reload() }
            await fileSystem.waitUntilHeld()

            await state.toggleExpansion(inside)
            #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip", "Inside", "Payload.txt", "Survivor.txt"])

            await fileSystem.release()
            await reload.value
            #expect(state.error == nil)
            #expect(state.expandedItems.contains(inside.id), "The reload collapsed the archive folder expanded meanwhile")
            #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip", "Inside", "Payload.txt", "Survivor.txt"])
        }
    }

    @Test("A reload still forgets expansions whose parent was collapsed")
    func reloadForgetsExpansionsBelowCollapsedParents() async throws {
        try await withFixture { state, _, _ in
            let archive = try #require(state.items.first(where: { $0.name == "Sample.zip" }))
            await state.toggleExpansion(archive)
            let inside = try #require(state.expandedChildren[archive.id]?.first(where: { $0.name == "Inside" }))
            await state.toggleExpansion(inside)
            await state.toggleExpansion(archive)
            #expect(state.expandedItems.contains(inside.id))

            await state.reload()
            #expect(!state.expandedItems.contains(archive.id))
            #expect(!state.expandedItems.contains(inside.id))
            #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip"])
        }
    }

    // MARK: - Fixture

    private func rows(in state: FileBrowserState) -> [String] {
        state.flattenedList().map(\.item.name)
    }

    /// Root: Dropped/Kept.txt (expanded inline) and Sample.zip with
    /// Inside/{Payload,Survivor}.txt, in List mode.
    private func withFixture(_ body: (FileBrowserState, GatedFileSystem, URL) async throws -> Void) async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReloadExpansionRace-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let staging = root.appendingPathComponent(".staging", isDirectory: true)
        let inside = staging.appendingPathComponent("Inside", isDirectory: true)
        let dropped = root.appendingPathComponent("Dropped", isDirectory: true)
        for directory in [inside, dropped] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try Data("payload".utf8).write(to: inside.appendingPathComponent("Payload.txt"))
        try Data("survivor".utf8).write(to: inside.appendingPathComponent("Survivor.txt"))
        try Data("kept".utf8).write(to: dropped.appendingPathComponent("Kept.txt"))
        let engine = NativeSevenZipArchiveEngine()
        try await engine.createArchive(from: [inside], outputURL: root.appendingPathComponent("Sample.zip"),
                                       format: .zip, progress: { _ in })
        try FileManager.default.removeItem(at: staging)

        let suite = "ZforgeTestSuite.ReloadExpansionRace-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
        let fileSystem = GatedFileSystem(root: root)
        let state = FileBrowserState(preferences: preferences, fileSystem: fileSystem,
                                     grants: UIFixtureAccessGrantStore(), archives: engine)
        defer { state.close() }
        await state.navigateToSidebar(root, name: root.lastPathComponent)
        #expect(state.error == nil)
        let droppedItem = try #require(state.items.first(where: { $0.name == "Dropped" }))
        await state.toggleExpansion(droppedItem)
        #expect(rows(in: state) == ["Dropped", "Kept.txt", "Sample.zip"])
        try await body(state, fileSystem, dropped)
    }
}

/// The real file system, with the root listed archive first (the order APFS
/// returns for this fixture, which a reload walks) and a one-shot hold on the
/// next listing of a chosen folder.
private actor GatedFileSystem: FileSystemServing {
    private let base = FileSystemService()
    private let root: URL
    private var heldDirectory: URL?
    private var held: CheckedContinuation<Void, Never>?
    private var heldWaiter: CheckedContinuation<Void, Never>?
    private var isHeld = false

    init(root: URL) { self.root = root.standardizedFileURL }

    func holdNextListing(of directory: URL) { heldDirectory = directory.standardizedFileURL }

    func waitUntilHeld() async {
        guard !isHeld else { return }
        await withCheckedContinuation { heldWaiter = $0 }
    }

    func release() {
        isHeld = false
        held?.resume()
        held = nil
    }

    func items(in directory: URL, showHidden: Bool) async throws -> [BrowserItem] {
        try await items(in: directory, showHidden: showHidden, includeExtendedMetadata: true)
    }

    func items(in directory: URL, showHidden: Bool, includeExtendedMetadata: Bool) async throws -> [BrowserItem] {
        let listed = try await base.items(in: directory, showHidden: showHidden,
                                          includeExtendedMetadata: includeExtendedMetadata)
        if directory.standardizedFileURL == heldDirectory {
            heldDirectory = nil
            isHeld = true
            heldWaiter?.resume()
            heldWaiter = nil
            await withCheckedContinuation { held = $0 }
        }
        guard directory.standardizedFileURL == root else { return listed }
        return listed.sorted { $0.isArchive != $1.isArchive ? $0.isArchive : $0.name < $1.name }
    }

    func item(at url: URL) async throws -> BrowserItem { try await base.item(at: url) }
    func item(at url: URL, includeExtendedMetadata: Bool) async throws -> BrowserItem {
        try await base.item(at: url, includeExtendedMetadata: includeExtendedMetadata)
    }
    func recursiveSize(at url: URL) async throws -> Int64 { try await base.recursiveSize(at: url) }
    func resolveNavigationURL(_ url: URL) async throws -> URL { try await base.resolveNavigationURL(url) }
}
