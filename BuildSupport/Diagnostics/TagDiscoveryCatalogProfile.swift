import CryptoKit

@main @MainActor
struct CatalogProfile {
    static func main() async throws {
        let catalog = FinderTagCatalog(monitorsFiles: false, usesSpotlight: false)
        defer { catalog.stop() }
        var before = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&before) == 0)
        let start = ContinuousClock.now
        catalog.refresh(searchScopes: TagDiscoveryPolicy.standardRoots)
        await catalog.waitForIdle()
        let elapsed = start.duration(to: .now)
        var after = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&after) == 0)
        var records: [String: [String: Int]] = [:]
        for tag in catalog.tags {
            for url in catalog.itemURLs(tagged: tag.name) {
                records[url.path] = FinderTagMetadata.colorIndexes(at: url)
            }
        }
        let encoded = try JSONSerialization.data(withJSONObject: records, options: [.sortedKeys])
        let report: [String: Any] = ["elapsed_seconds": Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18,
            "cpu_seconds": after.cpu_seconds - before.cpu_seconds, "peak_footprint_bytes": after.peak_footprint_bytes,
            "record_sha256": SHA256.hash(data: encoded).map { String(format: "%02x", $0) }.joined(),
            "tagged_records": records.count, "idle": catalog.isIdle,
            "monitoring": false, "spotlight": false, "persistence": false]
        FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) + Data([10]))
    }
}
