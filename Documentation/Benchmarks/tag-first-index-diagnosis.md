# First tag-index latency and Release logging — 2026-10-07

The user confirms that cache reuse works but reports a first indexing pass longer than ten minutes and asks whether the frequent journal messages explain the slowdown, whether they existed previously, and whether Release logs anything. This investigation changes diagnostics and evidence only; application code, the user's cache and existing test expectations remain unchanged.

## Findings from the actual application

The identifiable recent Debug execution (PID 63077) reports **456.464 s** for discovery and **456.506 s** for catalog readiness: 7 min 36 s. It inspects **452,492 items** and performs **445,366 metadata reads**, retaining three tagged records and one deferred scope. Only approximately **43 ms** separates the scan duration from readiness. The expensive interval is inside the scanner and its publication callbacks, rather than subsequent JSON storage or history/checkpoint preparation. This log documents this execution; it does not establish that every user-observed launch took exactly the same time.

The next process (PID 63205) restores the cache and becomes ready in **0.416 s**, reading just the one deferred item. The partial index correctly remains `complete=false`; an inaccessible item is retried without rescanning the whole accessible tree. Generation 4 requires one initial rebuild after the earlier correctness repairs, but valid later checkpoints reuse normally.

An earlier application instance already reports **576.543 s** (9 min 37 s) at 20:08 on 2026-10-06, with nearly the same workload (452,474 inspected / 445,348 metadata reads). This is historical application evidence, not an exact-source immutable-baseline comparison. Power logs show no sleep in either recorded scan window. The relevant Xcode builds took approximately 6.286 s before the recent cold run and 1.973 s before the cached run; a long compilation is not the explanation for these particular records.

The recent process's log sender UUID matches the current Debug dylib (`0F29D733-8AD6-3EC3-BF1B-8DCF022DD3CE`). Its LLVM profiling/coverage sections and actual compilation flags confirm coverage instrumentation. This establishes the configuration, but does not by itself attribute the slowdown to coverage.

## Measured work and cooperative pauses

The [raw scanner profile](../../BuildSupport/Diagnostics/TagDiscoveryColdProfile.swift) uses unchanged production sources, the visible real Home/Shared tree and the ordinary 128-item/8 ms work budget. It measures requested and actual suspension without journaling, Spotlight, persistence or UI. It reports aggregate counts and a record hash rather than private paths/tag names. All three initial profiles inspect exactly **452,581 items**, make **445,392 metadata reads**, discover three tagged records and retain one deferred scope; their complete record hashes match.

| Single process | Elapsed | CPU time | Actual suspension | Requested suspension |
| --- | ---: | ---: | ---: | ---: |
| Immutable `ceaf39c` scanner, Debug | 179.154 s | 30.565 s | 148.799 s | 120.817 s |
| Current scanner, Debug | 171.135 s | 29.118 s | 142.190 s | 115.174 s |
| Current scanner, Release | 197.894 s | 30.121 s | 163.818 s | 135.960 s |
| Current scanner, Debug + coverage | 182.628 s | 31.074 s | 151.804 s | 122.710 s |

The live tree gains four diagnostic/evidence files before the coverage profile: it inspects 452,585 items and makes 445,396 metadata reads. Its tagged-record hash remains identical. Existing file contents/tags are not mutated.

**Approximately 83% of elapsed traversal time is suspension.** In the Release profile, 34.076 s lies outside measured pauses, 135.960 s of suspension is requested, and actual suspension is 163.818 s. Scheduler/timer overshoot adds approximately 27.857 s across 4,382 pauses. The unchanged policy requests four times the measured wall work per slice to target 20% duty; it does not impose a hard process quota. With roughly 30 CPU seconds of work, a 20% one-core duty target alone implies roughly 150 elapsed seconds before additional costs. The real-tree 60-second target remains unmet.

The first pass still probes the tag xattr of nearly all inspected items, despite finding only three tagged records. The native no-xattrs shortcut skips only items confirmed to have no extended attributes of any kind; other metadata is not evidence of a Finder tag. The dominant proven work is the broad filesystem traversal/metadata probing, amplified by deliberate resource throttling and suspension scheduling. Faster cached restoration does not remove this first-pass workload.

No raw-scanner regression is reproduced against the immutable baseline. A [current catalog-only profile](../../BuildSupport/Diagnostics/TagDiscoveryCatalogProfile.swift), with journal/Spotlight/persistence/UI disabled, completes in **161.664 s**, consumes 29.924 CPU seconds, drains all work and publishes the same three-record hash. Thus the new background validation/publication does not reproduce the 456-second application interval in this isolation. The coverage control likewise does not reproduce that interval. These are one sample per configuration, in fixed order over a live, warm-cache tree with ordinary applications open; they are not randomized compiler/coverage experiments. In particular, the single Release sample is not evidence that Release makes first discovery faster or slower.

**Unresolved attribution:** the exact difference between the signed application under Xcode (456 s) and the isolated processes (162–198 s) has not been apportioned among sandboxed filesystem access, debugger/runtime configuration, competing application work, notifications and filesystem/cache conditions. Do not claim that coverage, logs, the latest algorithm or any one of those factors explains the entire difference. A controlled signed-application cold A/B with scan work, publication wait and requested/actual suspension counters remains necessary before approving a fix for that gap.

## Logging existed previously and is present in Release

`git log -S 'Tag journal batch'` identifies **`ceaf39c`**, the prior durable-index commit, as the introduction of these messages. The current optimization/correctness round did not add them. `TagJournal.receive` uses `Logger.debug` without `#if DEBUG`, so that call remains in Release. The signed Release binary contains its format string, and a Release executable compiled from the same production journal emits the actual messages when debug collection is enabled.

The [logging profile](../../BuildSupport/Diagnostics/TagDiscoveryLoggingProfile.swift) delivers 1,000 synthetic metadata-event batches through production `TagJournal.receive`, with no catalog/filesystem work:

- Normal runtime: `debug_enabled=false`; all 1,000 deliveries take **1.250 ms**.
- With a filtered live `log stream --level debug` observer: `debug_enabled=true`; all 1,000 deliveries take **15.370 ms**. The observer captures exactly **1,000 journal debug messages and one final notice**.
- `OS_ACTIVITY_DT_MODE=YES` alone does not enable debug in the attempted control; this result is retained rather than reported as enabled logging.

This isolates journal processing and the log backend, not rendering/retention of Xcode's console. It provides no evidence that these messages account for minutes of traversal, and raw discovery remains slow without any journal logging. Console-rendering overhead is not separately measured.

**Release is not silent:** completion, restore, checkpoint and ready notices plus error diagnostics remain. The earlier actual Release catalog executable has persisted completion/checkpoint/readiness notices in Unified Logging; strings inspection separately confirms these calls in the full signed Release binary. Batch-level debug is normally disabled in the tested unobserved runtime but can be enabled by collection/configuration. Do not equate the `debug` severity with the Debug build configuration or promise that Release can never emit it.

## What the journal lines mean

`history_done=false` describes whether **that batch** carries the HistoryDone marker; it is not the global index's completion state. The Xcode console explicitly shows `history_done=true` before the 0.416-second cached readiness, followed by ordinary live batches with `false`. `relevant`/`recursive` counts are produced before the catalog's hidden/scope filtering and coalescing; they are not counts of completed scans. The captured recent batches have no loss events, and the observed post-completion window contains no repeated whole-Home completion. Native file activity can still deliver messages after a worker drains.

The console also contains `MDB_MAP_FULL` and a FileIDTree I/O diagnostic after cached readiness. Zforge's tag store is atomic JSON and does not use LMDB; these messages do not identify a tag-index storage failure. Their framework origin and possible effect on the cold application gap are unverified and must not be assigned as the cause without a trace.

## Evidence, reproduction and validation boundary

[All five profiles, source/compiler manifests, real application aggregates, logging counts and power/build evidence](tag-first-index-diagnosis-results.json). The immutable raw reference has no source override; current manifests match the accepted production source fingerprints. Temporary checkpoints and user tags are not altered. No new unit/UI cases execute in this diagnostic interaction, and earlier regression counts remain prior evidence.

Compile only with the shared production recipe, then invoke the resulting profile **once**; these harnesses profile real Home/Shared rather than the scale fixture:

```sh
python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py \
  --configuration Release --compile-only --fixture "$TMPDIR" \
  --harness-file BuildSupport/Diagnostics/TagDiscoveryColdProfile.swift \
  --output /private/tmp/zforge-cold-profile-new
caffeinate -i /private/tmp/zforge-cold-profile-new/measure
```

Use `--source-ref ceaf39c --configuration Debug` for the raw reference and the catalog/logging harness paths above for those separate controls. The coverage control adds Swift `-profile-generate -profile-coverage-mapping` and Clang `-fprofile-instr-generate -fcoverage-mapping`; its actual commands are recorded in the numeric artifact. Direct profile outputs contain counts/hashes only. The first custom harness compilation fails because an actor attempted to return non-Sendable `[String: Any]`; returning encoded `Data` corrects diagnostic isolation without changing production behavior. The Xcode accessibility query unexpectedly blocks for 1,288 seconds; the coverage process finishes independently in 182.628 seconds and the query delay is not treated as scanner time.

D-41/OR-19 remain open for real first-pass latency and complete application attribution. The next optimization must reduce uncached metadata/traversal work or unnecessary suspension while preserving tag correctness and the declared resource contract. Removing messages alone is not supported as a latency fix by this evidence.
