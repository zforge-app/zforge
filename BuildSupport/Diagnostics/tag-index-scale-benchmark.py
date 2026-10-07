#!/usr/bin/env python3
"""Measure production tag catalog and JSON storage on an isolated tagged fixture."""
import argparse
import hashlib
import json
import pathlib
import subprocess
import time
import datetime
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--fixture", required=True, type=pathlib.Path)
    parser.add_argument("--files", type=int, default=100_000)
    parser.add_argument("--tagged-files", type=int, default=10_000)
    parser.add_argument("--reopen-from", type=pathlib.Path, help="Reuse an existing correct checkpoint; measure only three cached reopens")
    parser.add_argument("--configuration", choices=["Debug", "Release"], default="Debug",
                        help="Release uses Swift -O whole-module optimization and Clang -Os")
    parser.add_argument("--source-ref", help="Read production sources from an existing Git commit without changing the checkout")
    parser.add_argument("--source-override", action="append", default=[],
                        help="Use a current production file in the reference build; record the explicit common contract repair")
    parser.add_argument("--harness-file", type=pathlib.Path, help="Compile a diagnostic harness with the same production-source recipe")
    parser.add_argument("--compile-only", action="store_true", help="Write build provenance and exit before executing the harness")
    args = parser.parse_args()
    if not 0 < args.tagged_files <= args.files:
        parser.error("Require 0 < --tagged-files <= --files")
    if not args.fixture.is_dir():
        parser.error("Fixture must already exist")
    repo = pathlib.Path(__file__).resolve().parents[2]
    source_commit = subprocess.check_output(["git", "rev-parse", "--verify", args.source_ref + "^{commit}"],
                                            cwd=repo, text=True).strip() if args.source_ref else None

    def source_bytes(path):
        if source_commit and path not in args.source_override:
            return subprocess.check_output(["git", "show", f"{source_commit}:{path}"], cwd=repo)
        return (repo / path).read_bytes()
    output = args.output
    output.mkdir(parents=True, exist_ok=True)
    if list(output.glob("index-*.json")):
        parser.error("Output already contains checkpoints; use a fresh directory")

    header = '''
#include <stdint.h>
#include "TagDirectoryReader.h"
typedef struct {
    uint64_t monotonic_ns, footprint_bytes, peak_footprint_bytes, rss_bytes;
    double cpu_seconds;
} ZFBenchmarkUsage;
int ZFBenchmarkReadUsage(ZFBenchmarkUsage *usage);
'''
    metrics = '''
#include "metrics.h"
#include <libproc.h>
#include <mach/mach_time.h>
#include <time.h>
#include <unistd.h>
int ZFBenchmarkReadUsage(ZFBenchmarkUsage *output) {
    struct rusage_info_v4 usage = {0};
    if (proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&usage)) return -1;
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    *output = (ZFBenchmarkUsage){
        .monotonic_ns = (uint64_t)now.tv_sec * 1000000000ULL + now.tv_nsec,
        .footprint_bytes = usage.ri_phys_footprint,
        .peak_footprint_bytes = usage.ri_lifetime_max_phys_footprint,
        .rss_bytes = usage.ri_resident_size,
        .cpu_seconds = (usage.ri_user_time + usage.ri_system_time)
            * (long double)timebase.numer / timebase.denom / 1e9
    };
    return 0;
}
'''
    # Only the model consumed by the unused observe method is stubbed. The
    # catalog, native journal, scanner, metadata and store are production source.
    model = '''
nonisolated struct BrowserItem: Sendable {
    let localURL: URL?
    let tags: [String]
    let tagColorIndexes: [String: Int]
}
'''
    harness = r'''
actor ScanProbe {
    private(set) var calls = 0
    func scanned() { calls += 1 }
}

struct Measurement: Codable {
    let phase: String
    let elapsed_seconds: Double
    let cpu_seconds: Double
    let cpu_percent: Double
    let footprint_start_bytes: UInt64
    let footprint_end_bytes: UInt64
    let lifetime_peak_footprint_bytes: UInt64
    let resident_end_bytes: UInt64
}

@main
@MainActor
struct Diagnostic {
    static func usage() -> ZFBenchmarkUsage {
        var result = ZFBenchmarkUsage()
        precondition(ZFBenchmarkReadUsage(&result) == 0, "Resource counters unavailable")
        return result
    }

    static func measure<T>(_ phase: String, body: () async throws -> T) async rethrows -> (T, Measurement) {
        let start = usage()
        let result = try await body()
        let end = usage()
        let elapsed = Double(end.monotonic_ns - start.monotonic_ns) / 1e9
        let cpu = end.cpu_seconds - start.cpu_seconds
        return (result, Measurement(phase: phase, elapsed_seconds: elapsed, cpu_seconds: cpu,
            cpu_percent: cpu / elapsed * 100, footprint_start_bytes: start.footprint_bytes,
            footprint_end_bytes: end.footprint_bytes,
            lifetime_peak_footprint_bytes: end.peak_footprint_bytes, resident_end_bytes: end.rss_bytes))
    }

    static func main() async throws {
        let phase = CommandLine.arguments[1]
        // refresh normalizes grants; use the same identity for the injected
        // policy and oracle (/private/tmp standardizes to /tmp on macOS).
        let root = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true).standardizedFileURL
        let temporaryBoundary = FileManager.default.temporaryDirectory.standardizedFileURL
        precondition(TagScanRoots.covers(temporaryBoundary.path, root.path),
            "Fixture must be inside the runtime temporary boundary used by production metadata reads")
        let checkpoint = URL(fileURLWithPath: CommandLine.arguments[3])
        let files = Int(CommandLine.arguments[4])!
        let tagged = Int(CommandLine.arguments[5])!
        let store = TagIndexStore(url: checkpoint)
        let expected = Dictionary(uniqueKeysWithValues: (0..<tagged).map { slot in
            let index = slot * files / tagged
            let path = root.appendingPathComponent(String(format: "folder-%03d/file-%06d.txt", index / 1000, index)).path
            return (path, ["Benchmark": 6])
        })
        var measurements: [Measurement] = []
        var scanCalls = 0
        var writtenIndex = checkpoint
        if phase == "cold" || phase == "reopen" {
            let probe = ScanProbe()
            let catalog = FinderTagCatalog(discoveryRoots: [root], scanner: { scopes, publish in
                await probe.scanned()
                _ = await TaggedFileScanner.scan(scopes, onBatch: publish)
            }, usesSpotlight: false, indexStore: store)
            defer { catalog.stop() }
            let (_, elapsed) = await measure(phase) {
                catalog.refresh(searchScopes: [root])
                await catalog.waitForIdle()
            }
            measurements.append(elapsed)
            scanCalls = await probe.calls
            precondition(scanCalls == (phase == "cold" ? 1 : 0), "Unexpected recursive discovery count: \(scanCalls) during \(phase)")
            let saved = await store.load()
            precondition(saved?.records == expected, "Catalog checkpoint differs from fixture oracle")
            precondition(saved?.complete == true, "Fixture checkpoint must be complete")
            precondition(catalog.itemURLs(tagged: "Benchmark").count == tagged, "Missing catalog results")
            if phase == "reopen" {
                let (_, idle) = try await measure("idle") {
                    try await Task.sleep(for: .seconds(10))
                }
                measurements.append(idle)
                precondition(catalog.isIdle, "Catalog did not remain drained")
                let idleCalls = await probe.calls
                precondition(idleCalls == 0, "Idle work restarted recursive discovery")
            }
        } else if phase == "load" {
            let (saved, elapsed) = await measure(phase) { await store.load() }
            measurements.append(elapsed)
            precondition(saved?.records == expected, "Loaded checkpoint differs from fixture oracle")
        } else {
            guard let saved = await store.load() else { fatalError("Missing baseline checkpoint") }
            precondition(saved.records == expected, "Baseline checkpoint differs from fixture oracle")
            var records = saved.records
            if phase == "rewrite_one_record" {
                let changed = expected.keys.sorted()[0]
                records[changed] = ["Benchmark": 6, "Updated Fixture": 4]
            }
            let snapshot = TagIndexSnapshot(scopes: saved.scopes, cursors: saved.cursors,
                records: records, deferredPaths: saved.deferredPaths)
            writtenIndex = checkpoint.deletingLastPathComponent()
                .appendingPathComponent(phase + "-" + checkpoint.lastPathComponent)
            let target = TagIndexStore(url: writtenIndex)
            // Prepare an existing checkpoint so both cases measure replacement.
            let prepared = await target.save(saved)
            precondition(prepared, "Initial storage fixture save failed")
            let (succeeded, elapsed) = await measure(phase) { await target.save(snapshot) }
            measurements.append(elapsed)
            precondition(succeeded, "Checkpoint replacement failed")
            let restored = await target.load()
            precondition(restored?.records == records, "Replacement lost or changed records")
        }
        let bytes = try FileManager.default.attributesOfItem(atPath: writtenIndex.path)[.size] as! NSNumber
        struct Output: Codable {
            let phase: String
            let verified_records: Int
            let recursive_scan_calls: Int
            let index_bytes: UInt64
            let fixture_root_utf8_bytes: Int
            let measurements: [Measurement]
        }
        let output = Output(phase: phase, verified_records: tagged, recursive_scan_calls: scanCalls,
            index_bytes: bytes.uint64Value, fixture_root_utf8_bytes: root.path.utf8.count, measurements: measurements)
        print(String(decoding: try JSONEncoder().encode(output), as: UTF8.self))
    }
}
'''
    source_files = [
        "Zforge/Services/FinderTagCatalog.swift", "Zforge/Services/TaggedFileScanner.swift",
        "Zforge/Services/TagIndexStore.swift", "Zforge/Services/TagJournal.swift",
        "Zforge/Services/UserDirectoryService.swift", "Zforge/Services/ZforgeTemporaryStorage.swift",
    ]
    if set(args.source_override) - set(source_files):
        parser.error("Source overrides must name one of the diagnostic's production Swift files")
    if args.harness_file:
        harness = args.harness_file.read_text()
    source = "\n".join(source_bytes(path).decode() for path in source_files) + model + harness
    hashes = {path: hashlib.sha256(source_bytes(path)).hexdigest() for path in source_files}
    native = output / "native"
    native.mkdir(exist_ok=True)
    for name in ["TagDirectoryReader.c", "TagDirectoryReader.h"]:
        data = source_bytes("Zforge/Native/" + name)
        (native / name).write_bytes(data)
        hashes["Zforge/Native/" + name] = hashlib.sha256(data).hexdigest()
    (output / "metrics.h").write_text(header)
    (output / "metrics.c").write_text(metrics)
    (output / "measure.swift").write_text(source)
    objects = []
    clang_flags = ["-Os", "-target", "arm64-apple-macos26.0"] if args.configuration == "Release" else ["-O0"]
    swift_flags = ["-O", "-whole-module-optimization", "-target", "arm64-apple-macos26.0",
                   "-default-isolation", "MainActor",
                   "-enable-upcoming-feature", "MemberImportVisibility",
                   "-enable-upcoming-feature", "InferIsolatedConformances",
                   "-enable-upcoming-feature", "NonisolatedNonsendingByDefault"] if args.configuration == "Release" else ["-Onone"]
    compile_commands = []
    for cfile in [native / "TagDirectoryReader.c", output / "metrics.c"]:
        obj = output / (cfile.stem + ".o")
        command = ["xcrun", "clang", *clang_flags, "-I", str(native), "-c", str(cfile), "-o", str(obj)]
        compile_commands.append(command)
        subprocess.run(command, check=True)
        objects.append(str(obj))
    command = ["xcrun", "swiftc", "-swift-version", "6", *swift_flags, "-parse-as-library",
        "-module-cache-path", str(output / "modules"), "-I", str(native),
        "-import-objc-header", str(output / "metrics.h"), str(output / "measure.swift"),
        *objects, "-o", str(output / "measure")]
    compile_commands.append(command)
    subprocess.run(command, check=True)
    provenance = dict(configuration=args.configuration, source_commit=source_commit,
        source_overrides=sorted(args.source_override),
        compile_commands=compile_commands, source_sha256=hashes,
        harness_sha256=hashlib.sha256(source.encode()).hexdigest(),
        diagnostic_harness_sha256=hashlib.sha256(harness.encode()).hexdigest(),
        benchmark_script_sha256=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),
        resource_helper_sha256=hashlib.sha256((header + metrics).encode()).hexdigest())
    (output / "build.json").write_text(json.dumps(provenance, indent=2) + "\n")
    if args.compile_only:
        return
    rows = []
    for repeat in range(1, 4):
        checkpoint = output / f"index-{repeat}.json"
        if args.reopen_from:
            shutil.copyfile(args.reopen_from, checkpoint)
        phases = ["reopen"] if args.reopen_from else ["cold", "reopen", "load", "save", "rewrite_one_record"]
        for phase in phases:
            wall_start, monotonic_start = time.time(), time.monotonic()
            run = subprocess.run([str(output / "measure"), phase, str(args.fixture.resolve()),
                str(checkpoint), str(args.files), str(args.tagged_files)],
                capture_output=True, text=True, timeout=600)
            (output / f"{phase}-{repeat}.log").write_text(run.stderr)
            if run.returncode:
                raise RuntimeError(f"{phase} repeat {repeat} failed: {run.stderr[-4000:]}")
            row = json.loads(run.stdout)
            row["repeat"] = repeat
            row["started_utc"] = datetime.datetime.fromtimestamp(wall_start, datetime.timezone.utc).isoformat()
            row["process_wall_seconds"] = time.time() - wall_start
            row["process_monotonic_seconds"] = time.monotonic() - monotonic_start
            row["wall_minus_monotonic_seconds"] = row["process_wall_seconds"] - row["process_monotonic_seconds"]
            rows.append(row)
            result = dict(provenance, files=args.files, tagged_files=args.tagged_files,
                reused_checkpoint=str(args.reopen_from) if args.reopen_from else None,
                measurements=rows)
            (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
            print(json.dumps(row), flush=True)


if __name__ == "__main__":
    main()
