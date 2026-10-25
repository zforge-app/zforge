import CryptoKit

private actor ColdCounters {
    var yieldCalls = 0
    var yieldSeconds = 0.0
    var publishCalls = 0
    var publishSeconds = 0.0
    var records: [String: [String: Int]] = [:]
    func yielded(_ actual: Duration) {
        yieldSeconds += Self.seconds(actual)
        yieldCalls += 1
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
        let report: [String: Any] = ["yield_seconds": yieldSeconds, "yield_calls": yieldCalls, "publish_calls": publishCalls,
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
        budget.yieldSlice = {
            // Production slice boundary (yield + cancellation), timed for attribution.
            let start = ContinuousClock.now
            await Task.yield()
            try Task.checkCancellation()
            await stats.yielded(start.duration(to: .now))
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
