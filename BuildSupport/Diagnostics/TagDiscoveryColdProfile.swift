import CryptoKit

private actor ColdCounters {
    var requestedPause = 0.0
    var actualPause = 0.0
    var pauseCalls = 0
    var publishCalls = 0
    var publishSeconds = 0.0
    var records: [String: [String: Int]] = [:]
    func paused(requested: Duration, actual: Duration) {
        requestedPause += Self.seconds(requested)
        actualPause += Self.seconds(actual)
        pauseCalls += 1
    }
    func published(_ batch: TaggedFileScanner.Batch) {
        let start = ContinuousClock.now
        records.merge(batch) { _, new in new }
        publishCalls += 1
        publishSeconds += Self.seconds(start.duration(to: .now))
    }
    nonisolated static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
    func report() throws -> Data {
        let encoded = try JSONSerialization.data(withJSONObject: records, options: [.sortedKeys])
        let report: [String: Any] = ["pause_requested_seconds": requestedPause, "pause_actual_seconds": actualPause,
            "pause_calls": pauseCalls, "publish_calls": publishCalls,
            "publish_seconds": publishSeconds, "tagged_records": records.count,
            "record_sha256": SHA256.hash(data: encoded).map { String(format: "%02x", $0) }.joined()]
        return try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
    }
}

@main @MainActor
struct ColdProfile {
    static func main() async throws {
        let stats = ColdCounters()
        var budget = TaggedFileScanner.Budget()
        budget.pause = { duration in
            let start = ContinuousClock.now
            try await Task.sleep(for: duration)
            await stats.paused(requested: duration, actual: start.duration(to: .now))
        }
        let start = ContinuousClock.now
        var before = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&before) == 0)
        let result = await TaggedFileScanner.scanResult(TagDiscoveryPolicy.standardRoots, budget: budget) {
            await stats.published($0)
        }
        var after = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&after) == 0)
        let encoded = try await stats.report()
        var report = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        report["elapsed_seconds"] = ColdCounters.seconds(start.duration(to: .now))
        report["cpu_seconds"] = after.cpu_seconds - before.cpu_seconds
        report["peak_footprint_bytes"] = after.peak_footprint_bytes
        report["inspected"] = result.inspected
        report["metadata_reads"] = result.metadataReads
        report["deferred_count"] = result.deferred.count
        report["interrupted"] = result.interrupted
        let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
        FileHandle.standardOutput.write(data + Data([10]))
    }
}
