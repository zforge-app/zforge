// ZF-25 complete ArchiveServing harness. Benchmark tooling only; compiled with the
// app's engine sources outside the app target, without UI, XCTest or App Sandbox.
import Darwin
import Foundation

/// The engine sources reference this UI constant through preferences; the value is irrelevant here.
enum BrowserLayoutMetrics { static let previewWidth: CGFloat = 300 }

nonisolated func memory() -> [String: UInt64] {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    var stats = malloc_statistics_t()
    malloc_zone_statistics(nil, &stats)
    return ["footprint": info.phys_footprint, "malloc_in_use": UInt64(stats.size_in_use),
            "malloc_allocated": UInt64(stats.size_allocated)]
}

nonisolated func emit(_ object: [String: Any]) {
    let data = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    FileHandle.standardOutput.write(data + Data([10]))
}

nonisolated func now() -> Double { Double(clock_gettime_nsec_np(CLOCK_UPTIME_RAW)) / 1e9 }

@main
struct EngineHarness {
    static func main() async throws {
        let arguments = CommandLine.arguments
        let engine = NativeSevenZipArchiveEngine()
        let replaceAll: ArchiveConflictResolver = { _ in .replace(applyToAll: true) }

        switch (arguments.count > 1 ? arguments[1] : "", arguments.count) {
        case ("extract", 6):
            // extract <archive> <work> <repetitions> <all|selected>: complete user-facing operation.
            let archive = URL(fileURLWithPath: arguments[2])
            let work = URL(fileURLWithPath: arguments[3])
            let selected = arguments[5] == "selected"
            for run in 0..<Int(arguments[4])! {
                let destination = work.appendingPathComponent("Output-\(run)")
                var start = now()
                let opened = try await engine.openArchive(at: archive, password: nil)
                let items = try await engine.items(at: opened.address)
                let list = now() - start
                start = now()
                if selected {
                    // Every other root item: the multi-selection Extract action of the browser.
                    let choice = items.sorted { $0.name < $1.name }.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
                    try await engine.extractItems(choice, to: destination, password: nil,
                        resolveConflict: replaceAll, progress: { _ in })
                } else {
                    try await engine.extractArchive(at: archive, to: destination, password: nil,
                        resolveConflict: replaceAll, progress: { _ in })
                }
                let extract = now() - start
                await engine.closeAllSessions()
                emit(["run": run, "open_list_s": list, "extract_s": extract, "root_items": items.count, "memory": memory()])
            }
        case ("memory", 5):
            // memory <input> <work> <cycles>: the RAM-benchmark pipeline repeated in one process.
            let input = URL(fileURLWithPath: arguments[2])
            let work = URL(fileURLWithPath: arguments[3])
            let options = CompressionOptions(format: .sevenZip, level: 5, method: .lzma2, dictionaryMB: 64,
                                             fastBytes: 32, solid: true, threads: 2)
            emit(["phase": "baseline", "memory": memory()])
            for cycle in 0..<Int(arguments[4])! {
                let archive = work.appendingPathComponent("Cycle-\(cycle).7z")
                let destination = work.appendingPathComponent("Output-\(cycle)")
                func phase(_ name: String, _ body: () async throws -> Void) async throws {
                    let start = now()
                    try await body()
                    emit(["cycle": cycle, "phase": name, "seconds": now() - start, "memory": memory()])
                }
                try await phase("create") {
                    try await engine.createArchive(from: [input], outputURL: archive, options: options,
                        password: nil, progress: { _ in })
                }
                try await phase("list") {
                    let opened = try await engine.openArchive(at: archive, password: nil)
                    guard try await !engine.items(at: opened.address).isEmpty else { throw ArchiveEngineError.itemNotFound }
                }
                try await phase("test") { try await engine.testArchive(at: archive, password: nil) }
                try await phase("extract") {
                    try await engine.extractArchive(at: archive, to: destination, password: nil,
                        resolveConflict: replaceAll, progress: { _ in })
                }
                try await phase("cleanup") { await engine.closeAllSessions() }
                try FileManager.default.removeItem(at: archive)
                try await phase("idle") { try await Task.sleep(for: .seconds(1)) }
            }
        default:
            FileHandle.standardError.write(Data("usage: engine extract|memory ...\n".utf8))
            exit(1)
        }
    }
}
