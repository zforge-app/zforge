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

## Requested 10,000-tagged-file workload — 2026-10-06

The user requests a high-tag-count benchmark and the serialized index size. Keep the preceding 100,000-visible-file fanout but tag exactly 10,000 evenly distributed files, all carrying the same Benchmark label; hidden/package tagged descendants remain excluded. Compare three balanced Foundation/native pairs and require exact complete record equality against an independent fixture oracle. Add three fresh-process catalog discovery/reopen pairs using an isolated checkpoint, plus load/save and single-record whole-checkpoint rewrite measurements. Record elapsed/process CPU, calibrated physical footprint, peak memory, checkpoint bytes and ten idle seconds. Compilation and fixture generation must finish before measured runs. Existing cold <=60 s, cached <=5 s and idle <0.5% targets remain; standalone memory is separate from full-app footprint, and no numerical storage-size target is invented. Production code and the user's index remain unchanged. This exercises 10,000 tagged files sharing one label, not 10,000 distinct label names or a full UI workload.

### Final awake scanner comparison

[All six runs](durable-tag-index-10000-scanner-results.json) pass the same exact 10,000-file/tag oracle, exclude hidden/package descendants, and have identical result hashes. Order is Foundation/native, native/Foundation, Foundation/native. The final run uses the unchanged fixture inside the runtime temporary boundary, standardizes logical root identity and obtains its physical alias with POSIX realpath. Wall-versus-monotonic process elapsed differs by less than 0.002 s in every sample; no sleep-contaminated sample is selected. All compilation completes before timed runs; no unit/UI runner or other benchmark overlaps. The ordinary app remains open and filesystem caches are not cleared.

| Median | Foundation from 8af9fcb | Current native |
| --- | ---: | ---: |
| Scanner elapsed | 34.917 s | 29.732 s |
| Whole-process CPU time | 6.68 s | 5.68 s |
| Peak RSS | 23.547 MiB | 23.703 MiB |
| Peak physical footprint | 14.797 MiB | 15.344 MiB |

Elapsed is **14.85% lower (1.174x)**; CPU time is 14.97% lower. Dense-fixture temporary/index memory is slightly higher in the native standalone variant; no memory-reduction claim is made for this comparison. Scanner elapsed excludes final report generation, while external whole-process CPU/memory includes it. The earlier ten-tag sparse benchmark used a different root prefix, source/report normalization and machine window; differences between sparse and dense results are not a controlled attribution solely to tag density. The sought 2x scanner improvement remains unmet.

### Catalog and JSON results

[All fifteen fresh-process results](durable-tag-index-10000-catalog-results.json) retain the production Swift/C source fingerprints, compiled diagnostic/source hashes, per-run clocks, resources, exact record counts and index sizes. Three cold/reopen pairs plus three runs of each storage operation all pass their exact fixture oracle. Every cold process makes one recursive scan; every cached process makes **zero** recursive scans and restores the same 10,000 records. The fixture has one common Benchmark label on all 10,000 eligible files.

| Stage | Median elapsed | Median process CPU time | Median CPU, one core | Maximum lifetime peak footprint at timed-stage end |
| --- | ---: | ---: | ---: | ---: |
| Cold catalog discovery/checkpoint | 30.391 s | 6.638 s | 21.842% | 21.86 MiB |
| Cached catalog reopen | 10.377 s | 2.612 s | 25.176% | 26.83 MiB |
| JSON load/decode | 18.973 ms | 18.994 ms | 100.112% | 13.77 MiB |
| Complete checkpoint replacement | 13.268 ms | 11.810 ms | 89.647% | 21.95 MiB |
| Replacement after one changed record | 13.308 ms | 11.830 ms | 89.168% | 20.80 MiB |

Cold elapsed ranges 28.569–33.182 s; reopen ranges 9.185–11.157 s. Each reopen includes a separate ten-second idle measurement: median idle CPU **0.002347%**, maximum observed process lifetime footprint **29.91 MiB** after result verification. Storage CPU percentages describe millisecond bursts, not sustained background activity. Phase CPU/elapsed excludes setup and correctness checks; lifetime memory includes unmeasured setup and the independent in-memory oracle. These are isolated diagnostic processes containing the actual catalog, journal, scanner and store, **not full Zforge UI memory or startup measurements**. Spotlight is disabled. An unused BrowserItem model is stubbed, and a scanner wrapper counts calls while invoking the production scanner; the default production metadata reader performs cached revalidation. No application source is changed.

Every initial index contains **1,320,326 bytes (1.259 MiB)**. The same JSON is replaced even for one changed entry; adding a second label to that one entry produces **1,320,346 bytes**. Paths are absolute, so size depends on their lengths: this fixture's normalized root is 77 UTF-8 bytes. The synthetic checkpoints remain at `/private/tmp/zforge-tag-index-scale-10000-final/index-1.json` through `index-3.json`; the production application checkpoint is untouched.

At 10,000 same-label records, full JSON load/save is measured in roughly 13–20 ms. Cached catalog readiness still takes about ten seconds. The code revalidates every cached tagged item and applies visibility checks plus journal/checkpoint preparation, so the gap identifies work beyond storage as the main observed startup cost. This is an inference from the measured stages, not a per-function profiler attribution. Incremental storage remains relevant at larger scales or higher checkpoint frequency, but these measurements do not justify treating JSON as the current dominant bottleneck. The controlled cold scenario finishes below 60 s, while **every reopen exceeds the existing 5 s target** (D-43). Neither the real Home first-pass latency gap nor full-app high-tag-count memory/interaction verification is closed.

### Preparation failures and measurement integrity

The first sandboxed scanner run cannot obtain the `/usr/bin/time` kern.clockrate metric and yields no accepted comparison. A later six-run comparison returns identical records, but native repeat 3 reports 624.943 s and only 5.73 CPU seconds. The power log records Clamshell Sleep at 10:38:00 -03:00 for 595 s inside that run. [All original samples remain](durable-tag-index-10000-scanner-sleep-results.json); no duration is corrected or sample silently removed. A final awake comparison uses temporary `caffeinate -i` plus per-run wall/monotonic clocks; every final delta is below 0.002 s. Sleep-affected data stays historical rather than being used as algorithm latency.

Initial catalog setup passes `/private/tmp` as an injected policy root while refresh standardizes it to `/tmp`, producing zero scans. Normalizing the fixture identity preserves the required one/zero scan assertions. A cold pass then succeeds, but default incremental reads reject the system-temporary ancestry outside the runtime temporary boundary and the reopen loses its expected records. Moving only the generated fixture under the same FileManager temporary boundary used by the existing tests fixes preparation; exact path/tag checks remain unchanged. Scanner report normalization also accounts for the old Foundation variant's physical root and the native variant's logical root; only those two known aliases are accepted, with the physical prefix obtained through POSIX realpath (Foundation itself shortens the alias), followed by exact independent relative-path/tag equality. A small all-tagged fixture passes six runs before the final large comparison; a separate small sparse-default fixture verifies the retained original count and exclusions. Preparation failures are not classified as product approval or production regressions.

Reproduction, using a fresh scanner output (the first command generates the fixture):

```sh
python3 BuildSupport/Diagnostics/tag-scanner-comparison.py --output "$TMPDIR/ZforgeTagScale" --files 100000 --tagged-files 10000
caffeinate -i python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py --output /private/tmp/zforge-index-scale --fixture "$TMPDIR/ZforgeTagScale/fixture" --files 100000 --tagged-files 10000
```

For comparison captures, wrap the scanner command in `caffeinate -i` as well. Explicit fixture reuse is supported by `--fixture`; generated fixtures must start empty so stale tags cannot alter density. The sparse default remains ten tagged files per 100,000 total files. All output names and fixture content are English. Large tagged result maps are verified exactly and published as counts/hashes instead of repeating thousands of filenames. No new unit/UI suite execution is claimed: these are diagnostic invocations, and the production code remains at `fd1bacc`.

## ZF-42 follow-up

The requested first two catalog candidates are implemented and compared in [tag-catalog-optimization.md](tag-catalog-optimization.md). Ordinary cached metadata rereads are avoided when history is valid, with conservative linked/unverifiable exceptions and bounded background visibility validation. Contemporary isolated median cached readiness changes from 15.110 to 2.150 s; the exact-final below-2-second criterion still fails in two of three samples. JSON remains 1.259 MiB. Historical measurements above are retained; the follow-up provides current fingerprints, all prototype failures and final regression/UI counts.

## ZF-42 follow-up correctness acceptance — 2026-10-06

The incremental restore/background visibility implementation now passes 76 independent-oracle differential checkpoints, 257 unit cases / 348 executions and three serial UI cases. Two baseline defects are repaired: leading-combining scope boundaries and physical journal mapping for logical directory aliases. Index generation 4 rebuilds potentially incomplete older checkpoints once, with staged-grant migration covered; later valid caches reuse normally. This refines the implementation/evidence above without replacing historical measurements or closing D-41's real-Home first-pass target. [Reference adjustments, executed failures/results and remaining boundaries](tag-catalog-equivalence.md); [exact-final Release performance](tag-catalog-optimization.md).
