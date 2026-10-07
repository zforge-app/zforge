// Compiled with baseline and current production sources by the shared recipe.
// The coordinator owns mutations and an independent xattr/traversal oracle.
nonisolated struct EquivalenceRequest: Decodable, Sendable {
    let operation: String
    var grants: [String] = []
    var markers: [String] = []
    var expected: [String: [String: Int]] = [:]
}

private actor EquivalenceProbe {
    var scans = 0
    var reads = 0
    var active = 0
    var maximumActive = 0
    func beginScan() -> Int {
        scans += 1; active += 1; maximumActive = max(maximumActive, active)
        return scans
    }
    func endScan() { active -= 1 }
    func read(_ count: Int) { reads += count }
    func counts() -> [String: Int] { ["scans": scans, "reads": reads, "maximum_active": maximumActive] }
}

private actor EquivalenceGate {
    private var arrived = false
    private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []
    private var release: CheckedContinuation<Void, Never>?
    func pause() async {
        arrived = true
        for waiter in arrivalWaiters { waiter.resume() }
        arrivalWaiters.removeAll()
        await withCheckedContinuation { release = $0 }
    }
    func wait() async {
        if !arrived { await withCheckedContinuation { arrivalWaiters.append($0) } }
    }
    func open() { release?.resume(); release = nil }
}

@main @MainActor
struct EquivalenceWorker {
    static func main() async throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true).standardizedFileURL
        let scopes = ["A", "B"].map { root.appendingPathComponent($0, isDirectory: true) }
        let store = TagIndexStore(url: URL(fileURLWithPath: CommandLine.arguments[2]))
        var catalog: FinderTagCatalog?
        var grants: [URL] = []
        var probe = EquivalenceProbe()
        var fence: TagJournal?
        var fencePaths: Set<String> = []
        var fenceRecursivePaths: Set<String> = []
        defer { catalog?.stop(); fence?.stop() }

        func makeCatalog() -> FinderTagCatalog {
            let work = probe
            return FinderTagCatalog(discoveryRoots: scopes, scanner: { roots, publish in
                _ = await work.beginScan()
                _ = await TaggedFileScanner.scan(roots, onBatch: publish)
                await work.endScan()
            }, reader: { urls in
                await work.read(urls.count)
                return await TaggedFileScanner.read(urls)
            }, usesSpotlight: false, indexStore: store)
        }

        func persistedGrantedRecords() async -> [String: [String: Int]]? {
            guard let saved = await store.load() else { return nil }
            return saved.records.filter { path, _ in grants.contains { TagScanRoots.covers($0.path, path) } }
        }

        while let line = await Task.detached(operation: { readLine() }).value {
            let request = try JSONDecoder().decode(EquivalenceRequest.self, from: Data(line.utf8))
            var scanned: [String: [String: Int]]?
            switch request.operation {
            case "start":
                catalog?.stop()
                probe = EquivalenceProbe()
                grants = request.grants.map { root.appendingPathComponent($0, isDirectory: true) }
                catalog = makeCatalog()
                catalog!.refresh(searchScopes: grants)
                await catalog!.waitForIdle()
            case "grant":
                let additions = request.grants.map { root.appendingPathComponent($0, isDirectory: true) }
                grants += additions
                catalog!.refresh(searchScopes: additions)
                await catalog!.waitForIdle()
            case "stop":
                catalog?.stop()
                await catalog?.waitForIdle()
                catalog = nil
            case "fence_start":
                fencePaths.removeAll(); fenceRecursivePaths.removeAll()
                fence = TagJournal(onChanges: { changes in
                    fencePaths.formUnion(changes.map(\.path))
                    fenceRecursivePaths.formUnion(changes.filter(\.requiresRecursiveScan).map(\.path))
                }, onHistory: {})
                guard let description = TagJournal.describe(scopes) else { fatalError("Journal description unavailable") }
                fence!.start(description, since: [:])
                precondition(fence!.available, "Native journal fence unavailable")
                await fence!.waitForHistory()
                // History predating the coordinator's next mutation cannot
                // satisfy the live fence. FSEvents may coalesce its marker into
                // a subsequent recursive ancestor event rather than a leaf.
                fencePaths.removeAll(); fenceRecursivePaths.removeAll()
            case "fence_finish":
                let paths = Set(request.markers.map { root.appendingPathComponent($0).path })
                func receivedMarkers() -> Bool {
                    paths.allSatisfy { path in fencePaths.contains(path)
                        || fenceRecursivePaths.contains { TagScanRoots.covers($0, path) } }
                }
                let deadline = ContinuousClock.now.advanced(by: .seconds(8))
                while !receivedMarkers(), ContinuousClock.now < deadline {
                    try await Task.sleep(for: .milliseconds(10))
                }
                if !receivedMarkers() {
                    let diagnostic = try JSONSerialization.data(withJSONObject: [
                        "expected_fence_paths": paths.sorted(), "received_fence_paths": fencePaths.sorted(),
                        "scope_paths": scopes.map(\.path), "recursive_fence_paths": fenceRecursivePaths.sorted()
                    ], options: [.sortedKeys])
                    FileHandle.standardError.write(diagnostic + Data([10]))
                }
                precondition(receivedMarkers(), "Native offline mutation fence failed")
                fence!.stop(); fence = nil
            case "sync":
                // Live notification delivery is asynchronous. This condition
                // fence is never used to retry a completed start/readiness result.
                let expected = Dictionary(uniqueKeysWithValues: request.expected.map {
                    (root.appendingPathComponent($0.key).path, $0.value)
                })
                let deadline = ContinuousClock.now.advanced(by: .seconds(8))
                while await persistedGrantedRecords() != expected, ContinuousClock.now < deadline {
                    try await Task.sleep(for: .milliseconds(10))
                }
                await catalog!.waitForIdle()
            case "scan":
                actor Results {
                    var records: [String: [String: Int]] = [:]
                    func add(_ batch: [String: [String: Int]]) { records.merge(batch) { _, new in new } }
                }
                let result = Results()
                let outcome = await TaggedFileScanner.scanResult(grants) { await result.add($0) }
                precondition(outcome.complete, "Independent production rescan must complete")
                scanned = await result.records
            case "dropped":
                catalog!.filesChanged(scopes.map { TagFileChange(path: $0.path,
                    flags: FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) })
                await catalog!.waitForIdle()
            case "cancel_restart":
                catalog?.stop(); await catalog?.waitForIdle()
                let work = EquivalenceProbe()
                let gate = EquivalenceGate()
                probe = work
                grants = scopes
                catalog = FinderTagCatalog(discoveryRoots: scopes, scanner: { roots, publish in
                    let invocation = await work.beginScan()
                    if invocation == 1 {
                        await gate.pause()
                        await publish([root.appendingPathComponent("A/canceled.txt").path: ["EQ Stale": 6]])
                    } else { _ = await TaggedFileScanner.scan(roots, onBatch: publish) }
                    await work.endScan()
                }, monitorsFiles: false, usesSpotlight: false)
                catalog!.refresh(searchScopes: scopes)
                await gate.wait()
                catalog!.stop()
                catalog!.refresh(searchScopes: scopes)
                await gate.open()
                await catalog!.waitForIdle()
                precondition(catalog!.itemURLs(tagged: "EQ Stale").isEmpty, "Canceled worker published stale results")
            default: fatalError("Unknown equivalence operation")
            }

            func relative(_ path: String) -> String {
                precondition(path.hasPrefix(root.path + "/"), "Catalog escaped fixture boundary")
                return String(path.dropFirst(root.path.count + 1))
            }
            var published: [String: [String]] = [:]
            var colors: [String: Int] = [:]
            if let catalog {
                for tag in catalog.tags where tag.name.hasPrefix("EQ ") {
                    let paths = catalog.itemURLs(tagged: tag.name).map { relative($0.path) }
                    if !paths.isEmpty { published[tag.name] = paths.sorted(); colors[tag.name] = tag.colorIndex }
                }
            }
            let snapshot = await store.load()
            let records = await persistedGrantedRecords().map {
                Dictionary(uniqueKeysWithValues: $0.map { (relative($0.key), $0.value) })
            }
            let scan = scanned.map { Dictionary(uniqueKeysWithValues: $0.map { (relative($0.key), $0.value) }) }
            struct Response: Encodable {
                let operation: String
                let records: [String: [String: Int]]?
                let published: [String: [String]]
                let colors: [String: Int]
                let scan: [String: [String: Int]]?
                let complete: Bool?
                let idle: Bool
                let counts: [String: Int]
                let saved_scopes: Int?
            }
            let response = Response(operation: request.operation, records: records, published: published,
                colors: colors, scan: scan, complete: snapshot?.complete, idle: catalog?.isIdle ?? true,
                counts: await probe.counts(), saved_scopes: snapshot?.scopes.count)
            let data = try JSONEncoder().encode(response)
            FileHandle.standardOutput.write(data + Data([10]))
        }
    }
}
