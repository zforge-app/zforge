import Foundation
import Testing
@testable import Zforge

@Suite("Archive materialization concurrency")
struct ArchiveMaterializationConcurrencyTests {
    @Test("Concurrent native materializations preserve both cached preview files")
    func concurrentMaterializationsPreserveCache() async throws {
        let checkpoint = MaterializationCheckpoint()
        let engine = NativeSevenZipArchiveEngine(materializationDidExtract: { item in
            await checkpoint.pauseFirstExtraction(of: item.id)
        })
        let fixture = try await makeFixture(engine: engine)
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let first = Task { try await engine.materialize(item: fixture.first, purpose: .preview, automaticLimit: 1_024) }
        await checkpoint.waitForExtraction(of: fixture.first.id)
        let second = Task { try await engine.materialize(item: fixture.second, purpose: .preview, automaticLimit: 1_024) }
        await checkpoint.waitForExtraction(of: fixture.second.id)

        await checkpoint.release(fixture.first.id)
        let firstURL = try await first.value
        await checkpoint.release(fixture.second.id)
        let secondURL = try await second.value

        let cachedFirstURL = try await engine.materialize(item: fixture.first, purpose: .preview, automaticLimit: 1_024)
        let cachedSecondURL = try await engine.materialize(item: fixture.second, purpose: .preview, automaticLimit: 1_024)
        #expect(cachedFirstURL == firstURL)
        #expect(cachedSecondURL == secondURL)
        #expect(try String(contentsOf: firstURL, encoding: .utf8) == "First preview content")
        #expect(try String(contentsOf: secondURL, encoding: .utf8) == "Second preview content")
        await engine.closeAllSessions()
    }

    @Test("Closing a session discards a completed extraction before cache publication")
    func closedSessionCannotBeRestoredByMaterialization() async throws {
        let checkpoint = MaterializationCheckpoint()
        let engine = NativeSevenZipArchiveEngine(materializationDidExtract: { item in
            await checkpoint.pauseFirstExtraction(of: item.id)
        })
        let fixture = try await makeFixture(engine: engine)
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let pending = Task { try await engine.materialize(item: fixture.first, purpose: .preview, automaticLimit: 1_024) }
        await checkpoint.waitForExtraction(of: fixture.first.id)
        await engine.closeSession(fixture.address.sessionID)
        await checkpoint.release(fixture.first.id)

        await #expect(throws: ArchiveEngineError.cancelled) {
            _ = try await pending.value
        }
        await #expect(throws: (any Error).self) {
            _ = try await engine.items(at: fixture.address)
        }
        let sessionDirectory = ZforgeTemporaryStorage.archiveSessionsRoot(fileManager: .default)
            .appendingPathComponent(fixture.address.sessionID.uuidString)
        #expect(!FileManager.default.fileExists(atPath: sessionDirectory.path))
        await engine.closeAllSessions()
    }

    private func makeFixture(engine: NativeSevenZipArchiveEngine) async throws -> MaterializationFixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MaterializationConcurrency-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let firstURL = root.appendingPathComponent("First.txt")
        let secondURL = root.appendingPathComponent("Second.txt")
        try Data("First preview content".utf8).write(to: firstURL)
        try Data("Second preview content".utf8).write(to: secondURL)
        let archiveURL = root.appendingPathComponent("PreviewFiles.zip")
        try await engine.createArchive(from: [firstURL, secondURL], outputURL: archiveURL, format: .zip, progress: { _ in })
        let opened = try await engine.openArchive(at: archiveURL, password: nil)
        let items = try await engine.items(at: opened.address)
        return MaterializationFixture(root: root, address: opened.address,
            first: try #require(items.first { $0.name == "First.txt" }),
            second: try #require(items.first { $0.name == "Second.txt" }))
    }
}

private struct MaterializationFixture: Sendable {
    let root: URL
    let address: ArchiveAddress
    let first: BrowserItem
    let second: BrowserItem
}

private actor MaterializationCheckpoint {
    private var extracted: Set<BrowserItemID> = []
    private var extractionWaiters: [BrowserItemID: [CheckedContinuation<Void, Never>]] = [:]
    private var releaseWaiters: [BrowserItemID: CheckedContinuation<Void, Never>] = [:]

    func pauseFirstExtraction(of id: BrowserItemID) async {
        guard extracted.insert(id).inserted else { return }
        await withCheckedContinuation { continuation in
            releaseWaiters[id] = continuation
            extractionWaiters.removeValue(forKey: id)?.forEach { $0.resume() }
        }
    }

    func waitForExtraction(of id: BrowserItemID) async {
        guard !extracted.contains(id) else { return }
        await withCheckedContinuation { extractionWaiters[id, default: []].append($0) }
    }

    func release(_ id: BrowserItemID) {
        releaseWaiters.removeValue(forKey: id)?.resume()
    }
}
