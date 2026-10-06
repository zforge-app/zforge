# Startup CPU and memory investigation — 2026-10-05

## Finding

The user reported high CPU and fluctuating high memory immediately after launch, without navigation or archive operations. Live sampling of the Xcode-launched Debug process identifies the recursive Finder tag scanner as the sustained background work. Its Foundation temporary objects also accumulated during enumeration. The initial investigation below is historical; the correction and its measured boundaries follow the acceptance criteria.

`FileBrowserState.start()` activates the Home grant and calls `FinderTagCatalog.refresh(searchScopes:)`. The catalog schedules `TaggedFileScanner.scan`, which visits priority user directories followed by the remaining authorized Home tree, including non-package Library trees and development directories. For every enumerated item, `ZforgeTemporaryStorage.contains` resolves and standardizes both the same temporary root and the candidate URL, then the scanner reads Finder tag extended attributes. The loop has no explicit autorelease pool. Its batch publication suspends only when tagged records exist, so an untagged subtree can run without that suspension for its entire enumeration.

## Live evidence

Environment: macOS 27.0.1 (26A434), arm64, Xcode Debug process with `-NSDocumentRevisionsDebugMode YES`, PID 30153. Working source reference: `866a55c`; the exact binary/source correspondence was not independently established. Launch time: 23:09:09 America/Recife.

- Around 37 seconds after launch: 79.7% CPU, RSS 2,255,312 KiB.
- Around 101 seconds after launch: 83.6% CPU, RSS 2,314,144 KiB.
- Five-second and later three-second samples both show the active cooperative worker in `TaggedFileScanner.scan`. The main thread mostly waits in the AppKit event loop.
- In the first sample, 1,479 of 3,090 worker samples pass through the temporary-storage check, including repeated path/symlink resolution. Other major paths are directory enumeration and `getxattr`. These are stack-sample proportions, not an exact CPU accounting breakdown.
- First memory map reports a 2.1 GiB peak physical footprint; the later heap/map reports 2.8 GiB peak. Current footprint changes rapidly: 1.0 GiB in the heap snapshot and 833.9 MiB in the following map. RSS, heap allocated bytes and footprint describe different quantities and snapshots.
- Later heap: 4,121,048 allocations / 800,757,436 allocated bytes. Major types include 828,216 `NSPathStore2` objects (168,783,600 bytes), 1,176,732 `CFString` objects (140,224,736 bytes), 207,184 `_FileCache` objects (66,298,880 bytes), and 68,628,480 bytes of autorelease-pool content. Earlier heap also contained about 99,445 NSURL objects. This supports transient Foundation retention rather than a thumbnail raster explanation for this occurrence.

Raw local evidence: `/private/tmp/zforge-startup-cpu-sample.txt`, `/private/tmp/zforge-startup-cpu-second.txt`, and `/private/tmp/zforge-startup-diagnosis/live-{heap,vmmap}.txt`. Raw reports remain local and can contain environment paths; they are not committed.

## Controlled causal comparison

Workload defined before the diagnostic variant: 30,000 empty untagged text files in 30 directories, one scanner invocation per fresh command-line process, three runs per variant. Extract the production `FinderTagMetadata`, `TaggedFileScanner` and temporary-storage implementation; replace the unrelated Home provider with a nonexistent fixture Home. There is no app UI, Spotlight, archive engine or thumbnail renderer. Compile with `xcrun swiftc -parse-as-library -module-cache-path` pointing inside the temporary diagnostic directory. Measure with `/usr/bin/time -l`. Run order was baseline/pool/cached root for the first two rounds and reversed for the third. Filesystem caches were not cleared.

The pool variant wraps `nextObject`, path checks and metadata reading in an `autoreleasepool` per item, with async batch publication outside it. The final diagnostic variant additionally computes the canonical temporary root once, retaining candidate symlink resolution. Neither variant is a production fix. The investigative criterion is to isolate whether temporary-object lifetime and repeated invariant path computation explain resource growth, while traversing the same fixture.

| Variant | Median elapsed | Median CPU time | Median peak RSS |
| --- | ---: | ---: | ---: |
| Production scanner | 1.557 s | 1.55 s | 89.94 MiB |
| Per-item autorelease pool | 1.362 s | 1.35 s | 11.50 MiB |
| Pool plus cached temporary root | 0.805 s | 0.80 s | 11.45 MiB |

All nine measured processes exited successfully. Per-item draining reduces peak RSS by approximately 87%; cached-root plus pool reduces CPU time by approximately 48% in this fixture. [Individual measurements](startup-tag-scan-results.json) preserve elapsed, CPU, RSS and footprint independently. Temporary source snapshots, fixture and complete time output are under `/private/tmp/zforge-startup-diagnosis`.

Initial sandboxed attempts were not comparable: `swiftc` could not write its default module cache, fixed by an explicit temporary cache; `time -l` could not read `kern.clockrate`, so those runs have no complete memory measurements and are excluded. The final nine measurements ran with authorized process-metric access.

## Initial diagnosis limits and required correction

The cause of the startup CPU and temporary RAM growth is established for the sampled occurrence. This does not prove a permanent leak, attribute all remaining idle memory, or close the independent native 7-Zip retention investigation OR-11. The command-line comparison is not a production Release benchmark or proof of full Home startup performance after a fix.

Implement and verify bounded temporary-object lifetimes, avoid repeated invariant filesystem work, and make scan cancellation reach its detached worker. Current `scanTask.cancel()` does not propagate automatically into `Task.detached`; checking cancellation inside the detached task alone does not establish shutdown cancellation. FSEvents may also queue overlapping recursive directory scans via the serial task chain; this amplification is a source-level risk, not measured as the trigger here.

Preserve discovery outside the current folder, package exclusion, authorized scopes, temporary-file exclusion, live updates and tag filtering. These requirements guided the correction below. The initial diagnostic-only round ran no automated application tests or production build and established no visual-flow approval. See ZF-41, D-40 and OR-19.


## Correction acceptance criteria — defined before implementation

Preserve global tags, exact tag filtering, editing, live file events and authorized access. Use one catalog worker, coalesce overlapping roots/pending rescans, and retain its index for repeated refreshes in the same process. Do not restart Spotlight on ordinary refresh. Keep per-item autorelease lifetimes and at most 128 records per published scan batch. Run filesystem discovery at utility priority in work slices of at most 8 ms between item boundaries, followed by four times the measured slice duration of cooperative suspension (20% duty target for one worker; slow individual syscalls and scheduling can exceed it). There must be no scan task, polling timer or scheduled wakeup after draining the work queue; live FSEvents/Spotlight notifications may start finite incremental work when metadata changes.

The initial 30,000-file fixture comparison must materially reduce peak RSS (target below 32 MiB in the isolated harness), repeated overlapping scopes must not republish the same files, cancellation must stop the detached worker, and unchanged refreshes must schedule zero new scans. Measure the real app during initial discovery and for at least ten seconds after completion; report CPU, footprint and main-actor response separately. A 20% duty target is not a hard operating-system CPU quota, and zero scanner work does not imply the entire application's CPU is mathematically zero. A fresh process still requires discovery to account for changes while the application was closed; cross-launch incremental indexing is not implemented by this correction.

## Delivered correction

`TaggedFileScanner` now drains Foundation temporaries per item, caches the canonical temporary root once per worker, and avoids resource-property and symlink-resolution work for untagged enumerated files. Tagged aliases still undergo the temporary-storage exclusion check, and packages remain atomic. A utility worker publishes at most 128 records and suspends after 128 inspected items or 8 ms of wall work, including empty checkpoints. It sleeps four times the measured work duration. Cancellation reaches the detached worker, including its suspension. This cooperatively limits active duty; it cannot preempt a filesystem syscall or impose an operating-system CPU/RAM quota.

`FinderTagCatalog` maintains one finite worker, a minimal set of pending subtrees, and bounded metadata-read batches. Repeated refreshes and descendant authorized scopes reuse the current process index and live Spotlight query. File/directory xattr changes read individual metadata; newly created/moved directories and lost events reconcile subtrees. Event details merge by path, with overflow after 512 paths reconciled at the smallest common affected subtree per authorized scope. Previously indexed metadata is checked after reconciliation so deleted files and cleared tags disappear even after lost events. Live reads interleave initial discovery. Spotlight updates read added/changed/removed results; only its initial completion reads the complete result list. Tag-name/color reference counts update incrementally rather than recounting all indexed files for each batch.

After the queue drains, its task is released: there is no scanner polling timer or scheduled periodic rescan. Native notifications can trigger finite new work. The tagged-file index is intentionally retained; memory still scales with actual tagged records. An absolute application memory ceiling and a persistent cross-launch index are not delivered. A new process performs initial discovery, while navigation, additional windows and unchanged refreshes in the same process do not repeat it.

## Reproducible corrected measurements

Run `python3 BuildSupport/Diagnostics/tag-scan-benchmark.py --output /private/tmp/<new-directory>` from a local macOS checkout with process-metric access. The script extracts the historical scanner at `866a55c`, compiles it and the current production scanner with an explicit temporary module cache, generates 30,000 empty untagged files, rotates baseline/corrected order for three runs each, and measures ten seconds after the corrected scanner returns. Every measured process exited successfully. The versioned JSON preserves the original nine causal measurements, intermediate corrected measurements, and both final-source comparisons; source hashes identify the final implementation.

| Final comparison without a unit runner | Median elapsed | Median CPU time | Median peak RSS | Median peak footprint |
| --- | ---: | ---: | ---: | ---: |
| Historical scanner | 1.310 s | 1.30 s | 93.38 MiB | 84.56 MiB |
| Corrected scanner | 6.857 s | 1.24 s | 11.91 MiB | 3.05 MiB |

Peak RSS falls approximately 87%, below the defined 32 MiB criterion. Average CPU duty during the corrected runs is approximately 18%, compared with nearly one whole core in the historical scanner. Total CPU time falls only about 5% in this comparison; the much larger reduction in instantaneous CPU comes from suspension. Elapsed discovery deliberately increases to protect responsiveness. The corrected harness consumes 0.000306 CPU seconds over the ten seconds after return (approximately 0.0031% of one core), consistent with no continuing scan work.

This comparison ran without a unit runner or build, but the separately launched real application was still discovering Home. Filesystem caches were not cleared. Another final-source round overlapping unit work recorded corrected elapsed times of 2.523–7.160 s and CPU times of 0.43–1.16 s. Those results are retained; the more favorable medians are not generalized as a guaranteed reduction in total CPU. This is a controlled scanner workload, not Release startup or a full UI throughput measurement.

An additional exact-source run after the incremental-reader identity correction records corrected RSS of 11.94–12.38 MiB and **0.000206 CPU seconds over ten seconds after return** (0.0021% of one core). Its production build overlaps the initial phase and real Home discovery remains active; corrected elapsed times vary from 3.544 to 7.420 s. These measurements confirm the resource/termination boundary while preserving the load-related variation. The JSON distinguishes the measured discovery build's hashes from the delivered source hashes.

The optimized-discovery Debug bundle was built separately and launched without fixtures (PID 35295), before the subsequent identity-only correction to incremental symlink reads. Its discovery algorithm is identical to the final source; these counters describe that measured build. A 160-sample, 250 ms series over 40.343 s of actual Home discovery measured **17.35% mean CPU**, **171.77 MiB maximum RSS**, and **98.05 MiB maximum physical footprint**. A two-second stack sample identifies the corrected scanner and an AppKit main thread waiting in its event loop; its lifetime peak physical footprint is **110.1 MiB**. The original occurrence reached 79.7–83.6% CPU and 2.8 GiB peak footprint. These are different launches and sampling windows, not a controlled application-wide percentage-reduction benchmark.

The process sampler converts `proc_pid_rusage` CPU accounting through `mach_timebase_info` (125/3 on this machine); a local spin calibration against `getrusage` confirms the conversion. RSS and physical footprint remain separate metrics. Raw time series and samples stay under `/private/tmp/zforge-startup-diagnosis`, without publishing private file paths. Earlier corrected-build observations and an unsuccessful debugger attempt are not evidence of final full-Home completion.

A later 80-sample series around ten minutes into the measured discovery build records 17.04% mean CPU over 20.073 s, maximum RSS 159.08 MiB and maximum footprint 97.91 MiB. The last stack sample still contains discovery, with lifetime peak footprint unchanged at 110.1 MiB. This bounds resource stability to that interval rather than establishing full completion or indefinite-session memory. On 2026-10-06, the measured process was quit normally and the exact delivered bundle was opened through CUA without fixture arguments; its Recents browser was visible. That new process begins its own initial discovery, as specified.

## Functional and interface evidence

The pre-change ten tag cases passed. Two added characterization cases then failed for the expected reasons: duplicate discovery for overlapping roots and cancellation not reaching the detached worker. Both pass after the fix. The final complete unit result executes **225 cases / 302 executions**, all passed, zero skipped. Fifteen new tag cases cover bounded batches/yields, empty-tree interleaving, cancellation, stop/restart serialization, repeated refreshes, subtree coalescing, overflow across scopes, smallest affected ancestors, lost-event reconciliation, temporary/package exclusions, incremental reference counts and Spotlight deltas. A later review also preserved original symlink-path identity during incremental reads: a dedicated case failed with the canonical target as the record key, then passed after the correction. A standalone historical-source check confirmed the previous identity contract. Full-suite failures and preparation changes are retained in `REGRESSION-COVERAGE.md`.

Three existing tag UI cases passed, covering List editor/toolbar/context/cancellation, Icons context/selection, and Gallery/Columns applied quick-tag state. Their setup conditionally uses the existing New Zforge Window command when macOS launches the fixture app without a browser; no interaction expectations or deadlines were weakened. Exported List screenshots show seven quick-tag circles, applied checkmark and hover removal feedback. This establishes those states in English/dark appearance at 1100 pt, not the full visual/accessibility matrix.

In the earlier corrected real build, two disposable tagged files in different local directories appeared under one sidebar tag during initial discovery. Clearing one file's tag changed the visible result from two items to one without navigation; fixture deletion removed the remaining result. The live one-item state was visually inspected. The fixtures were removed afterward. This complements automated coverage; it does not quantify frame pacing or MainActor latency.

## Remaining verification

The exact delivered Debug source compiles successfully (`/private/tmp/zforge-tag-efficiency-delivery.log`) without Swift source warnings; the AppIntents processor reports its usual missing-dependency notice. `codesign --verify --deep --strict` returns `CSSMERR_TP_NOT_TRUSTED` for the local development signature, both in the measured discovery build and the delivery build. Successful compilation does not establish signing trust or distribution readiness.

The final full-Home scan remains active at the latest completion check; a second 11.938 s series measures 8.82% CPU and the stack still contains the scanner. This is not an idle measurement. The ten-second post-completion criterion is verified in the controlled harness and catalog drain tests; **full-Home completion and subsequent real-app idle counters remain pending**. Long-session/high-tag-count memory, external/network scopes, a Release run, frame pacing and the full widths/themes/languages/zoom/accessibility/macOS 26 matrix remain OR-19. The independent OR-11 archive retention investigation and earlier intermittent native event observation are not closed by these results.

## User acceptance — 2026-10-06

On 2026-10-06, the user confirmed a considerable improvement and acceptable memory use. This is qualitative actual-use acceptance; it does not establish full-Home completion/idle or close the remaining OR-19 matrix.
