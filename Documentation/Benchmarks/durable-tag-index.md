# Durable tag index and bounded startup work

Measured on 2026-10-06, macOS 27.0.1 arm64, Xcode/SDK 27.0, Debug app. Production tags remain enabled. The preceding scope baseline is commit `8af9fcb`; its sandboxed app took 288.424 seconds to discover visible Home/Shared. Earlier scope and enabled/disabled comparisons remain in [visible-tag-discovery.md](visible-tag-discovery.md) and [tag-discovery-ab.md](tag-discovery-ab.md).

## Problem and delivered behavior

The previous completed-scope set and tagged records lived only in memory. Every process started FSEvents at `sinceNow` and traversed Home again. The new atomic application-support checkpoint stores tagged records, explicit deferred paths, scope paths/inodes, volume journal UUIDs and per-scope processed cursors. Restore follows authorization; offline events update affected files/subtrees. Invalid storage, replaced scopes or lost history require conservative reconciliation. An uninterrupted partial traversal is reusable without claiming complete access: reopen retries its deferred paths, rather than all accessible files. Cancellation cannot checkpoint unfinished discovery.

Actual app investigation also exposed failures missed by a single-root fixture. SDK 27 requires exactly one path for each device-relative FSEvents stream; passing Home and Shared together made stream startup fail. Independent streams and cursors now cover both scopes, including staged grants and quitting between grants. Early checkpoints preserve disjoint ungranted scope data without publishing it. A fixed 350 ms event window prevents continuous visible events or ignored hidden noise from starving reconciliation and checkpointing. Inode metadata events reconcile directory visibility changes. Hidden ancestry is checked from the root down, with a bounded 512-entry cache shared only within one synchronous event batch; descendants below a hidden ancestor are never probed.

Native traversal batches names, object types, hidden flags and optional xattr-presence flags in 32 KiB per active directory. `EF_NO_XATTRS` skips metadata only when definitively returned; missing flags and symlinks remain conservative. Packages, hidden items, authorization boundaries, cancellation and Foundation fallback remain. One utility worker retains the 128-item/8 ms work budget and 20% cooperative duty target. It retires after draining; no periodic scanner runs after completion. This is cooperative scheduling and bounded temporary storage, not a hard OS quota or a bound on the number of genuinely tagged records.

## Acceptance declared before changes

First discovery: at most 60 s. Quiet cached reopen: at most 5 s. Post-completion app CPU: below 0.5% of one core. Measured app lifetime peak footprint: below 130 MiB. The controlled 100,000-file comparison seeks at least 2x lower latency and requires identical tagged results. Original targets remain unchanged when measurements fail.

## Final source: actual app cached reopen

[Numeric series, aggregate markers and source fingerprints](durable-tag-index-app-results.json) identify the exact delivered Swift/C sources. Both Home and Shared restore; three known tagged records are revalidated, and one inaccessible saved path is retried. The index remains explicitly incomplete. No full-tree rescan occurs.

| Measure | Final cached launch |
| --- | ---: |
| Catalog ready duration | 0.746 s |
| Process age at ready | 1.422 s |
| Idle interval, process age | 10.235–35.069 s |
| Idle CPU, one core | 0.168% |
| Mean idle physical footprint | 97.90 MiB |
| Lifetime peak physical footprint | 113.25 MiB |
| Idle samples | 99 |

The 0–5 s startup window measures 28.653% CPU; launch/render activity briefly remains even though indexing finishes early. No UI interaction occurs during resource capture. Later log markers outside the numeric capture belong to subsequent manual checks, and do not extend the measured window. This single final launch meets cached readiness, idle CPU and peak-footprint targets; it does not establish universal launch or long-session bounds.

## First pass: intermediate source and remaining latency

[The first saved native pass](durable-tag-index-cold-results.json) finishes traversal in **212.249 s**, inspecting 452,464 items and attempting 445,338 metadata reads. One inaccessible item remains deferred, and three tagged records are saved. Ready duration is 212.281 s. Only Home was authorized in this launch; Shared arrived in a later process. The sampled active interval is age 100.891–130.603 s: 19.765% CPU, mean footprint 87.37 MiB. Idle age 255.954–280.847 s measures 0.038% CPU and 87.44 MiB; lifetime peak is 113.88 MiB.

This pass precedes the final event-window, inode-visibility, stat-fallback and hidden-ancestor fixes; its source fingerprints are retained. No exact-final-source cold Home/Shared repetition is claimed. Instrumentation began the idle capture 37.938 s after the requested post-ready start; it cannot establish resources throughout that unsampled gap. The different scope, source revision and sampling windows prevent treating 288.424 → 212.249 s as a controlled app speedup. The original **60 s first-pass target remains unmet** (D-41).

## Final source: controlled algorithm comparison

[All six runs and exact tagged results](durable-tag-index-scanner-results.json) compare the Foundation scanner from `8af9fcb` with current native traversal. Both compile against the same current metadata reader. The fixture contains 100,000 visible files in 100 directories, ten tagged files, 100 tagged hidden descendants and 100 tagged package descendants. Results exclude hidden/package descendants and match exactly in every run. Order is Foundation/native, native/Foundation, Foundation/native; caches are not cleared. No build/unit runner overlaps these timed runs; the app remains open. These are standalone diagnostic invocations, not application test cases.

| Median | Foundation | Native |
| --- | ---: | ---: |
| Elapsed | 28.259 s | 23.698 s |
| CPU time | 5.19 s | 4.32 s |
| Peak RSS | 12.375 MiB | 12.016 MiB |
| Peak physical footprint | 3.407 MiB | 3.407 MiB |

Native elapsed is **16.14% lower (1.192x)**; CPU time is 16.76% lower. The sought 2x improvement fails. A separate deterministic hidden-ancestor regression bounds probes to two and forbids descendant probes; the old filter made five probes. That contract check is not a whole-app benchmark.

Protected `com.apple.provenance` is present on almost every real inspected item even when user attributes are absent. Removing it in a fixture returned success without removing the protected attribute. Consequently, xattr-presence hints eliminate little real metadata work: this pass still reads metadata for 98.4% of items. Further first-pass gains require measuring alternatives to those individual reads, such as bounded parallel metadata work, while preserving authorization, tag completeness, memory and CPU budgets. Extra policy exclusions require a separate product decision. Persistent reuse provides the main measured improvement for repeated launches.

## Reproduction and validation boundaries

Run the controlled comparison with a new output directory; `--fixture` reuses a prepared identical tree:

```sh
python3 BuildSupport/Diagnostics/tag-scanner-comparison.py --output /private/tmp/zforge-tag-comparison --files 100000
```

`BuildSupport/Diagnostics/visible-tag-discovery-benchmark.py` retains the real-tree scanner workload. `BuildSupport/Diagnostics/tag-index-app-results.py` consumes the calibrated `resource-sampler.c` CSV and unified-log JSON, maps Darwin monotonic timestamps to process age, and fails analysis when no ready marker exists:

```sh
python3 BuildSupport/Diagnostics/tag-index-app-results.py --capture cached:/private/tmp/cached.csv:/private/tmp/cached-log.json:PID --source-hashes /private/tmp/source-hashes.json --output /private/tmp/cached-results.json
```

The final full unit bundle `Test-Zforge-2026.10.06_10-08-00--0300.xcresult` under `/private/tmp/zforge-durable-index/Logs/Test/` passes **244 distinct cases / 327 executions**, zero failures/skips. Its test tree supplies parameter execution counts. Current coverage includes cached reopen, two native roots, staged grants/quit, offline edits/moves/additions/deletions/visibility, deferred retries, cancellation, invalid cache/history, sibling-stream loss, event starvation, native attribute layouts, symlink fallback, packages and existing editing/navigation. Intended pre-fix failures and intermediate failures remain recorded in REGRESSION-COVERAGE. The bundle also retains a runtime QoS warning in the unchanged `FileOperationServiceTests` AppKit teardown fixture; the file matches the baseline hash, but this does not prove the warning existed in that earlier run. The earlier 09:42 build warned about an unused scanner task completion Bool in the cancellation test; explicit discard preserves its actions/assertions. The final 10:08 verification has no source compiler warnings/errors; the AppIntents metadata notice remains a separate tool diagnostic. Strict deep signature verification passes.

The current UI runner failed before executing its three scenarios (`Timed out while enabling automation mode`): zero passed scenarios and one runner initialization failure. Separately, native manual/AX checks confirm a real tag filter and its existing item in Icons, List, Columns and Gallery, enabled Edit Tags, and opening/cancelling the editor without mutation. A dark List state was visually inspected, and Recents/List was restored afterward. No complete editing, multiple-selection, width/zoom/theme/language/accessibility matrix, Release, macOS 26 runtime, long-session/high-tag-count or Shared-denial coverage is claimed. Versioned measurement artifacts contain aggregates and normalized controlled fixture names, not private file paths or actual tag names.
