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
        let start = ContinuousClock.now
        let result = try await query.matching("zip")
        let elapsed = start.duration(to: .now)
        #expect(result.count == 100)
        print("Archive discovery benchmark: children=10000; archives=100; elapsed=\(elapsed)")
        #expect(elapsed < .milliseconds(100))
        var before = rusage()
        getrusage(RUSAGE_SELF, &before)
        let snapshotStart = ContinuousClock.now
        let snapshot = try await query.snapshot()
        let snapshotTime = snapshotStart.duration(to: .now)
        var after = rusage()
        getrusage(RUSAGE_SELF, &after)
        let userSeconds = Double(after.ru_utime.tv_sec - before.ru_utime.tv_sec) + Double(after.ru_utime.tv_usec - before.ru_utime.tv_usec) / 1_000_000
        let systemSeconds = Double(after.ru_stime.tv_sec - before.ru_stime.tv_sec) + Double(after.ru_stime.tv_usec - before.ru_stime.tv_usec) / 1_000_000
        #expect(snapshot.count == 100)
        #expect(snapshotTime < .milliseconds(250))
        print("Archive snapshot benchmark: children=10000; archives=100; elapsed=\(snapshotTime); userCPU=\(userSeconds); systemCPU=\(systemSeconds); processPeakRSS=\(after.ru_maxrss)")
        if #available(macOS 27.0, *) {
            var fileBefore = rusage()
            getrusage(RUSAGE_SELF, &fileBefore)
            let fileStart = ContinuousClock.now
            let associations = try await ArchiveContextPreparation.shared.identifiers(for: snapshot)
            let fileTime = fileStart.duration(to: .now)
            var fileAfter = rusage()
            getrusage(RUSAGE_SELF, &fileAfter)
            #expect(associations.count == 100)
            #expect(fileTime < .milliseconds(250))
            let user = Double(fileAfter.ru_utime.tv_sec - fileBefore.ru_utime.tv_sec) + Double(fileAfter.ru_utime.tv_usec - fileBefore.ru_utime.tv_usec) / 1_000_000
            let system = Double(fileAfter.ru_stime.tv_sec - fileBefore.ru_stime.tv_sec) + Double(fileAfter.ru_stime.tv_usec - fileBefore.ru_stime.tv_usec) / 1_000_000
            let wireBytes = associations.values.reduce(0) { $0 + $1.identifier.utf8.count }
            print("Archive file association benchmark: archives=100; elapsed=\(fileTime); userCPU=\(user); systemCPU=\(system); processPeakRSS=\(fileAfter.ru_maxrss); wireBytes=\(wireBytes)")
        }
    }
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
