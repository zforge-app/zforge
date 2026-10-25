import CryptoKit

// Application-path profile over the real visible Home/Shared tree: production
// catalog with native journal, Spotlight query, persistence and main-actor
// publication, as the app constructs them (UI excluded). Sign it with the App
// Sandbox to approximate sandboxed filesystem costs; the checkpoint then lives in
// the diagnostic's own container. Arguments: `cold` removes that diagnostic
// checkpoint first, `reopen` reuses it; an optional path overrides its location.
// During readiness a main-actor heartbeat (16 ms) records lateness and a sampler
// records per-second process CPU and thermal state. Output contains counts,
// timings and hashes only.
nonisolated private final class ResponsivenessProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var lateness: [Double] = []
    private var cpuPercents: [Double] = []
    private var thermal = 0
    private var running = true
    var isRunning: Bool { lock.withLock { running } }
    func stop() { lock.withLock { running = false } }
    func late(_ milliseconds: Double) { lock.withLock { lateness.append(milliseconds) } }
    func sample(cpuPercent: Double, thermalState: Int) {
        lock.withLock { cpuPercents.append(cpuPercent); thermal = max(thermal, thermalState) }
    }
    func report() -> [String: Any] {
        lock.withLock {
            let sorted = lateness.sorted()
            func percentile(_ p: Double) -> Double { sorted.isEmpty ? 0 : sorted[min(sorted.count - 1, Int(Double(sorted.count) * p))] }
            return ["main_heartbeats": sorted.count, "main_lateness_p50_ms": percentile(0.5),
                    "main_lateness_p99_ms": percentile(0.99), "main_lateness_max_ms": sorted.last ?? 0,
                    "main_stalls_over_50ms": sorted.filter { $0 > 50 }.count,
                    "main_stalls_over_250ms": sorted.filter { $0 > 250 }.count,
                    "cpu_percent_peak_1s": cpuPercents.max() ?? 0, "cpu_percent_samples_1s": cpuPercents,
                    "thermal_state_max": thermal]
        }
    }
}

@main @MainActor
struct AppPathProfile {
    static func main() async throws {
        let phase = CommandLine.arguments.dropFirst().first ?? "cold"
        // An optional second argument places the checkpoint outside the
        // container (sandboxed runs need a matching read-write exception).
        let index = CommandLine.arguments.count > 2 ? URL(fileURLWithPath: CommandLine.arguments[2])
            : FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ZforgeDiagnostic/VisibleTagIndex-profile.json")
        if phase == "cold" { try? FileManager.default.removeItem(at: index) }
        let store = TagIndexStore(url: index)
        // The production scanner is not wrapped: its deferred paths must reach
        // the checkpoint exactly as in the application.
        let catalog = FinderTagCatalog(indexStore: store)
        defer { catalog.stop() }
        var before = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&before) == 0)
        let probe = ResponsivenessProbe()
        let heartbeat = Task { @MainActor in
            while probe.isRunning {
                let beat = ContinuousClock.now
                try? await Task.sleep(for: .milliseconds(16))
                let actual = beat.duration(to: .now)
                probe.late(Double(actual.components.attoseconds) / 1e15 + Double(actual.components.seconds) * 1000 - 16)
            }
        }
        let sampler = Task.detached(priority: .userInitiated) {
            var previous = ZFBenchmarkUsage()
            precondition(ZFBenchmarkReadUsage(&previous) == 0)
            while probe.isRunning {
                try? await Task.sleep(for: .seconds(1))
                var current = ZFBenchmarkUsage()
                precondition(ZFBenchmarkReadUsage(&current) == 0)
                let wall = Double(current.monotonic_ns - previous.monotonic_ns) / 1e9
                probe.sample(cpuPercent: (current.cpu_seconds - previous.cpu_seconds) / wall * 100,
                             thermalState: ProcessInfo.processInfo.thermalState.rawValue)
                previous = current
            }
        }
        let start = ContinuousClock.now
        catalog.refresh(searchScopes: TagDiscoveryPolicy.standardRoots)
        await catalog.waitForIdle()
        let elapsed = start.duration(to: .now)
        probe.stop()
        await heartbeat.value
        await sampler.value
        var ready = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&ready) == 0)
        try await Task.sleep(for: .seconds(10))
        var idle = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&idle) == 0)
        var records: [String: [String: Int]] = [:]
        for tag in catalog.tags {
            for url in catalog.itemURLs(tagged: tag.name) { records[url.path] = FinderTagMetadata.colorIndexes(at: url) }
        }
        let saved = await store.load()
        var loadError = "none"
        if saved == nil {
            do { _ = try JSONDecoder().decode(TagIndexSnapshot.self, from: try Data(contentsOf: index)) }
            catch { loadError = String(describing: error) }
        }
        let encoded = try JSONSerialization.data(withJSONObject: records, options: [.sortedKeys])
        func seconds(_ duration: Duration) -> Double {
            Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        }
        var report: [String: Any] = ["phase": phase, "ready_seconds": seconds(elapsed),
            "ready_cpu_seconds": ready.cpu_seconds - before.cpu_seconds,
            "idle_cpu_seconds_10s": idle.cpu_seconds - ready.cpu_seconds,
            "idle_after_wait": catalog.isIdle,
            "peak_footprint_bytes": idle.peak_footprint_bytes, "footprint_bytes": idle.footprint_bytes,
            "tagged_records": records.count,
            "record_sha256": SHA256.hash(data: encoded).map { String(format: "%02x", $0) }.joined(),
            "checkpoint_load_error": loadError, "checkpoint_records": saved?.records.count ?? -1, "checkpoint_complete": saved?.complete ?? false,
            "checkpoint_deferred": saved?.deferredPaths.count ?? -1,
            "checkpoint_bytes": (try? FileManager.default.attributesOfItem(atPath: index.path)[.size] as? Int) ?? -1]
        report.merge(probe.report()) { current, _ in current }
        report["cpu_percent_mean_ready"] = (ready.cpu_seconds - before.cpu_seconds) / seconds(elapsed) * 100
        FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) + Data([10]))
    }
}
