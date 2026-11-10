import AppIntents
import Foundation
import Darwin
import Testing
@testable import Zforge

@Suite("Archive discovery performance", .serialized)
struct ArchiveDiscoveryPerformanceTests {
    @Test("A bounded 10000-child workload discovers 100 archives without recursive traversal")
    func mixedDirectChildren() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ArchiveDiscovery-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for index in 0..<10_000 {
            try Data().write(to: root.appendingPathComponent("Fixture-\(index)." + (index < 100 ? "zip" : "txt")))
        }
        let query = AutomationArchiveEntities(access: PerformanceArchiveAccess(root: root))
        // The limits apply to the work each operation does: the instructions its jobs retire,
        // at the reference rate of 10 per nanosecond (`WorkMeter`). Wall-clock and CPU time in
        // the shared unit plan measure waiting for the processor and grow with load, so they
        // are printed for the record only (ZF-68, D-86). The feature target for name discovery
        // is 100 ms; the test accepts a mean of up to 150 ms over three runs (user decision,
        // 2026-10-28), and each run must still find every archive.
        let meter = WorkMeter()
        var runs: [WorkMeter.Measurement] = []
        for _ in 0..<3 {
            let (result, run) = try await meter.measure { try await query.matching("zip") }
            runs.append(run)
            #expect(result.count == 100)
        }
        let mean = runs.map(\.work).reduce(.zero, +) / runs.count
        print("Archive discovery benchmark: children=10000; archives=100; work=\(runs.map(\.work)); mean=\(mean); instructions=\(runs.map(\.instructions)); cpu=\(runs.map(\.cpu)); wall=\(runs.map(\.wall)); target=100 ms")
        #expect(mean <= .milliseconds(150))
        let (snapshot, snapshotRun) = try await meter.measure { try await query.snapshot() }
        #expect(snapshot.count == 100)
        #expect(snapshotRun.work < .milliseconds(250))
        print("Archive snapshot benchmark: children=10000; archives=100; work=\(snapshotRun.work); instructions=\(snapshotRun.instructions); cpu=\(snapshotRun.cpu); wall=\(snapshotRun.wall); jobs=\(snapshotRun.jobs)")
        if #available(macOS 27.0, *) {
            let (associations, fileRun) = try await meter.measure {
                try await ArchiveContextPreparation.shared.identifiers(for: snapshot)
            }
            #expect(associations.count == 100)
            #expect(fileRun.work < .milliseconds(250))
            let wireBytes = associations.values.reduce(0) { $0 + $1.identifier.utf8.count }
            print("Archive file association benchmark: archives=100; work=\(fileRun.work); instructions=\(fileRun.instructions); cpu=\(fileRun.cpu); wall=\(fileRun.wall); jobs=\(fileRun.jobs); wireBytes=\(wireBytes); processPeakRSS=\(peakResidentBytes())")
        }
    }
}

/// Whole test host, not this workload alone; recorded for the memory trend only.
private func peakResidentBytes() -> Int {
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    return usage.ru_maxrss
}

private actor PerformanceArchiveAccess: AutomationAuthorizing {
    let root: URL
    init(root: URL) { self.root = root }
    func authorizedFolders() -> [String] { [root.path] }
    func authorize(_ urls: [URL]) throws -> AutomationAccessLease {
        guard urls.allSatisfy({ AutomationGrantStore.contains(root: root.path, path: $0.resolvingSymlinksInPath().path) }) else {
            throw AutomationError.authorizationRequired
        }
        return AutomationAccessLease()
    }
}
