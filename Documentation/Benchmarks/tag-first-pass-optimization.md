# First-pass tag discovery optimization — 2026-10-23/24

The user authorized an optimization round for D-41 (first-pass visible Home/Shared discovery), the remaining D-42 cold repetition and D-43 (cached 10,000-record catalog), advancing OR-19. Targets are unchanged from their original declarations and are not redefined after measurement.

## Workloads and acceptance criteria (declared before changes)

| Workload | Criterion | Origin |
| --- | --- | --- |
| W1 — real visible Home/Shared first pass, isolated production scanner (`TagDiscoveryColdProfile.swift`), production 128-item/8 ms budget and 20% duty | Complete in at most **60 s**; identical tagged-record hash, inspected and metadata-read counts versus baseline | D-41 |
| W2 — the same tree without pauses (a work-only variant of the cold profile, removed once production itself stopped pausing) | Attribution only: per-item CPU work; identical hash/counts | Profiling |
| W3 — production catalog path (journal, Spotlight, persistence, main-actor publication; UI excluded) over real Home/Shared (`TagDiscoveryAppPathProfile.swift`), cold then cached reopen; also signed with the App Sandbox | Cold at most 60 s; cached reopen below 5 s; ten idle seconds below 0.5% of one core | D-41 / D-42 proxy |
| W4 — 100,000-file fixture with 10,000 same-label tagged files, quiet cached reopen (`tag-index-scale-benchmark.py`) | Every reopen strictly below **2 s**; storage below 1.5 MiB; exact oracle; zero recursive scans | D-43 |
| Signed sandboxed application cold launch | First pass at most 60 s; peak footprint below 130 MiB | D-41 / D-42 (see limits) |

Resource contracts preserved: utility priority, one worker, 128-item/8 ms slices, 20% cooperative duty target of one core, bounded batches, cancellation, no post-completion worker, all visibility/package/temporary/symlink exclusions and authorization rules.

## Environment and measurement conditions

MacBook Air (Apple M5, 4 + 6 cores, 24 GiB), macOS 27.0.1 (26A434), Xcode 27.1 (27A9275). Real Home/Shared metadata is read only; no file, tag or application index is modified. All diagnostics use the shared Release recipe of `tag-index-scale-benchmark.py` (`-O -whole-module-optimization`, application concurrency features), fresh processes, `caffeinate -i` and warm filesystem caches. Baseline binaries compile `HEAD` (`6778795`) through `--source-ref HEAD`; candidates compile the working tree.

- **Shared-machine window (2026-10-23, 13:58–15:40 -03):** another agent concurrently compiled and benchmarked 7-Zip in a separate worktree. Variants were interleaved (A/B…, then reversed) to share contention. These samples are kept for the per-candidate attribution.
- **Quiet window (2026-10-24, from 12:15 -03):** the 7-Zip agent had finished; no other build/test/benchmark ran. Acceptance numbers come from this window.
- The laptop lid was closed on 2026-10-23 at 21:20; power logs show no sleep inside any retained sample. One in-flight app-path series (started 15:30 on 2026-10-23, three samples) was interrupted by the session ending and is discarded; it is fully re-run in the quiet window.

The real tree changed between earlier rounds and now: **555,622 inspected items / 549,312 metadata reads** (earlier rounds: about 452,500 / 445,400), four tagged records. Every sample of every variant reproduces the same tagged-record hash (`cea76582c9c9…`), inspected count and metadata-read count.

## Profiling findings

### Where the CPU goes (W2, unthrottled, Time Profiler)

Baseline 11.3 s of sampled CPU: **`getxattr` 68.3%**, `getattrlistbulk` 12.9%, **Foundation `isPackage` (`getattrlist` per directory) 11.9%**, directory `open` 4.5%; Swift/Foundation overhead below 3%. The catalog's main-actor publication path adds no visible CPU (0.19%) when the main actor is idle.

A read-only C microbenchmark over 60,000 real items shows why: a direct `getxattr` of the tag attribute costs **about 11 µs whether or not it exists** (the same for an unrelated missing name or for present `com.apple.provenance`), while `listxattr` costs **about 1.7 µs** and `lstat` 1.2 µs. Because protected `com.apple.provenance` is present on nearly every item, the existing `EF_NO_XATTRS` hint skips only about 1% of reads. Package checks: an oracle over all 55,731 visible Home/Shared directories finds 28 packages and **no** extensionless directory without the Finder bundle bit classified as a package; a fixture probe confirms LaunchServices classifies packages by extension or bundle bit (an `Info.plist` alone does not).

After both changes (W2), sampled CPU is 5.3 s: `listxattr` 54%, `getattrlistbulk` 24%, directory `open` 17%. These remaining calls are required per item/directory.

### Why roughly 80% of elapsed time is suspension

1. **The suspension is the declared 20% duty cycle.** Each slice pauses four times its measured work; elapsed is therefore about five times the work, independent of scheduler efficiency.
2. **Timer overshoot added 14–25 s per run.** `Task.sleep` overshoots by about 5–6 ms per pause regardless of priority (utility/medium/high) or explicit tolerance (`nil`, 1 ms, 0) in a separate probe. Over 4,300–5,800 pauses, baseline actual suspension exceeds requests by 20–43 s.
3. **Wall-time accounting multiplied non-CPU time.** The baseline measured slice work by wall clock, so blocked I/O, preemption and contention were also multiplied by four.
4. **Duty cycling keeps the utility worker on slowly clocked cores.** The same work costs about 6–7 CPU-seconds unthrottled but **14–19 CPU-seconds when throttled on a quiet machine** (and 9–10 s when the machine was busy with other work). Throttled CPU time therefore rises 2–3x, and the 4x pause scales with it. This is why the quiet window is slower than the contended window for the same binary. Thermal/DVFS state is not controlled; the effect is an observation, not a guaranteed platform rule.

Not supported by evidence: cooperative-pool starvation, actor-hop cost, per-item async overhead or Release logging (unchanged, see [first-index diagnosis](tag-first-index-diagnosis.md)). Sandboxing adds little: the App Sandbox–signed W2 measures 14.900 s baseline / 7.103 s candidate median versus 14.115 / 6.339 s unsandboxed (three interleaved runs each, identical hashes). This uses read-only temporary exceptions, an approximation of bookmark-scoped access.

## Changes, one candidate at a time (shared-machine window, interleaved, three runs each, W1)

| Stage | Change | Median elapsed | Median CPU | Kept |
| --- | --- | ---: | ---: | --- |
| Baseline `HEAD` | — | 212.497 s (184.723–273.846) | 35.501 s | — |
| C1 | `listxattr` prefilter before `getxattr` | 137.418 s (114.323–142.822) | 20.961 s | yes |
| C2 | + bulk Finder-info package pre-check | 121.528 s (107.707–122.079) | 18.169 s | yes |
| C3 | + bounded pause-overshoot credit (wall work) | 78.205 s (76.289–92.545) | 15.925 s | yes |
| C4 | + thread-CPU duty accounting | 75.955 s (46.123–76.043) | 15.057 s | yes |

Unthrottled W2 isolates C1/C2: C1 lowers median CPU from 10.917 to 6.373 s (−42%) and C2 from 9.541 to 7.318 s (−23%) in their own interleaved pairs. C4 is close to C3 on a warm, unsandboxed tree because CPU and wall work nearly coincide there; it removes multiplication of blocked I/O and preemption, which the earlier signed-application runs could not separate. A further change (C5) skips the visibility worker for empty interleaving checkpoints; it has no effect on W1 and is a pure no-op removal on the catalog path.

**Rejected diagnostic:** 512-item/32 ms slices (a contract change) measure 68.174 s versus 76.070 s for the delivered 128/8 ms budget (quiet, three interleaved pairs). The ~10% difference does not justify changing the slice contract; it is not adopted.

## Delivered implementation

- `FinderTagMetadata.readColorIndexes` first lists attribute names (following symlinks, like the existing read). Only a successful complete listing that omits `com.apple.metadata:_kMDItemUserTags` is treated as definitive absence; listing errors and lists larger than 4 KiB fall back to the unchanged direct read and error semantics. Applies to traversal, incremental reads and restored-record revalidation.
- `TagDirectoryReader` also requests `ATTR_CMN_FNDRINFO` in the same bulk call. A directory skips the Foundation package lookup only when its name has no `.` and its returned Finder info lacks the bundle bit; missing Finder info, fallback enumeration and every other directory keep the existing lookup.
- *(Superseded the same day by the user's removal of the duty cycle; see below.)* `TaggedFileScanner.CooperativeDuty` replaced three copies of the pause logic. Slices still end at 128 items or 8 ms of wall time; the pause is four times the slice's **thread CPU time** (falling back to wall time for an implausible reading), and timer/scheduler overshoot beyond a request is credited against later requests, **bounded to 50 ms** so a long external suspension cannot permit a burst. Cancellation semantics are unchanged.
- `visibilityResult` returns immediately for an empty batch.

## Acceptance results (quiet window)

### W1 — isolated real Home/Shared first pass

| Three interleaved runs | Baseline `HEAD` | Final |
| --- | ---: | ---: |
| Elapsed samples | 242.048 / 217.669 / 199.609 s | 97.447 / 93.452 / 90.501 s |
| Median elapsed | **217.669 s** | **93.452 s** (2.33x faster) |
| Median process CPU | 36.370 s | 19.031 s |
| Median requested / actual suspension | 153.512 / 179.242 s | 62.209 / 74.720 s |
| Pauses | 5,004–5,737 | 4,355–4,452 |
| Peak physical footprint | 3.89–4.66 MiB | 4.02–4.09 MiB |

The final column precedes the path-helper change (C6). A later quiet series of that binary measures 86.648 / 69.646 / 76.070 s (median 76.070 s). **Exact final source** (all six changes), interleaved again with baseline: **88.895 / 100.004 / 83.562 s (median 88.895 s)** versus baseline 177.733 / 168.806 / 208.334 s (median 177.733 s); median CPU 18.159 vs 30.492 s; identical hash with 555,630 items / 549,332 reads (the live tree gained eight items); peak footprint 4.06–4.14 MiB vs 3.83–4.00 MiB.

**With the cap, the 60-second target still fails** on this tree at the 20% duty contract. Arithmetic: elapsed ≈ 5 × throttled CPU work; with 14–19 throttled CPU-seconds the floor is 70–95 s. Meeting 60 s requires either a duty-cycle/budget product decision or further per-item work reductions; the remaining per-item calls are all required by the current contract.

### W3 — production catalog path over real Home/Shared

Fresh processes, cold (diagnostic checkpoint removed) then cached reopen of that checkpoint, interleaved base/final, three repetitions. The App Sandbox variants use read-only Home/Shared temporary exceptions and a read-write exception for a diagnostic checkpoint directory; when launched directly from a shell they cannot reread the production-protected checkpoint in a later process (`NSFileReadNoPermissionError`), so only their cold phase is used.

| Measure | Baseline `HEAD` | Final (before the path-helper change) |
| --- | ---: | ---: |
| Sandboxed cold readiness | 203.572 / 192.465 / 170.568 s (median 192.465) | 99.516 / 90.322 / 104.190 s (median **99.516**) |
| Sandboxed cold CPU (median) | 34.793 s | 20.581 s |
| Unsandboxed cold readiness | 197.797 / 204.770 / 200.162 s (median 200.162) | 100.919 / 95.016 / 92.649 s (median **95.016**) |
| Unsandboxed cached reopen | 0.054 / 0.055 / 0.056 s | 0.050 / 0.048 / 0.048 s |
| CPU in ten idle seconds after readiness | 0.005–0.011 s | 0.005–0.031 s (at most 0.31% of one core) |
| Lifetime peak physical footprint | 5.03–5.28 MiB | 5.02–5.30 MiB |
| Checkpoint | 4 records, 4 deferred, 773 bytes | 4 records, 3 deferred, 715 bytes |

**Exact final source:** sandboxed cold 85.187 / 83.737 s (CPU 17.6 / 17.3 s); unsandboxed cold 88.014 / 62.919 s, reopen 0.052 / 0.047 s, idle 0.004 s CPU per ten seconds; peak 5.06–5.39 MiB; same checkpoint shape and record hash.

All 24 processes publish the identical record hash. Cold catalog readiness tracks W1 within a few seconds, so journal history delivery, Spotlight, persistence and main-actor publication add little in this headless path. Cached reopen and idle CPU pass their criteria; the 60 s first pass fails.

**Deferred-item difference (intended and characterized):** a read-only probe finds four visible items whose direct tag read fails with `EPERM` while `listxattr` succeeds — privacy-protected directories, including one Photos library package. Their attribute-name lists contain no tag name. The baseline deferred the package's tag read and retried it on every launch; the final code treats the successful complete listing as definitive absence, so one fewer path is deferred. Directories whose contents cannot be enumerated are still deferred exactly as before. A protected item whose names are listed but whose tag value is unreadable would still take the direct read and stay deferred. No fixture can reproduce privacy protection with a tag; this boundary is recorded rather than claimed as proven for every protection mechanism.

### W4 — D-43 cached 10,000-record reopen

Fixture: 100,000 visible files, 10,000 same-label tagged files, 100 tagged hidden and 100 tagged package descendants, generated with the layout of `tag-scanner-comparison.py` under the runtime temporary directory (normalized root 76 UTF-8 bytes, one byte shorter than the 2026-10-06 fixture, hence 10,000 fewer index bytes). The seed checkpoint comes from a complete final Release workload: cold discovery **17.079 / 17.714 / 16.285 s**, reopen 0.488 / 0.520 / 0.499 s, load 18.2 ms, save 12.9 ms, one-record replacement 16.3 ms, index **1,310,324 bytes (1.250 MiB)**.

Profiling the Debug reopen showed 60% of samples in visibility validation, dominated by generic `-Onone` path helpers (`TagScanRoots.covers` byte-prefix iteration, component splitting in `normalizedPath`) rather than `lstat` (11.5%). A sixth change (C6) compares the scope prefix with one contiguous `memcmp` (keeping the canonical-Unicode fallback) and detects empty/`.`/`..` components in one byte pass without allocating. Interleaved direct reopens (four each) show Debug 2.599 → **1.306 s** median and Release 0.393 → 0.326 s.

Final acceptance, `tag-index-scale-benchmark.py --reopen-from`, two interleaved invocations of three fresh processes per variant:

| Six quiet cached reopens | Baseline Debug | Final Debug | Baseline Release | Final Release |
| --- | --- | --- | --- | --- |
| Readiness samples (s) | 3.443, 2.079, 3.302, 3.183, 3.565, 3.356 | 1.739, 1.589, 1.575, 1.677, 1.162, 1.217 | 0.899, 0.801, 0.661, 1.175, 0.768, 0.893 | 0.283, 0.312, 0.261, 0.281, 0.482, 0.436 |
| Median / maximum | 3.329 / 3.565 s | **1.582 / 1.739 s** | 0.847 / 1.175 s | **0.298 / 0.482 s** |
| Median readiness CPU | 0.731 s | 0.415 s | 0.220 s | 0.115 s |
| Median idle CPU, one core | 0.00280% | 0.00276% | 0.00344% | 0.00342% |
| Maximum lifetime footprint | 32.91 MiB | 33.33 MiB | 30.91 MiB | 30.33 MiB |

Every process verifies all 10,000 records against the fixture oracle and makes zero recursive scans. **Every final reopen, Debug and Release, is below 2 s**; storage stays 1.250 MiB, below 1.5 MiB. This is isolated-catalog evidence: the signed application's launch-to-usable time at 10,000 records is still unmeasured.

### Signed sandboxed application (not measured)

The application's index lives in its own container, which macOS App Data protection denies to other processes (`Operation not permitted`, also with the agent sandbox disabled). A cold signed-app run therefore needs the user to quit Zforge and remove `~/Library/Containers/io.libor.Zforge/Data/Library/Application Support/Zforge/VisibleTagIndex-v1.json` (or to grant access), followed by one launch. A bench-identifier app cannot reproduce it either, because global discovery requires the user's security-scoped Home bookmark. Launching a diagnostic bundle through LaunchServices made it responsible for its own privacy access and blocked on a Documents/Desktop consent request; it was terminated after ten minutes without a result, and any consent prompt shown for “TagDiscoveryBench” should be declined. The W3 sandboxed proxy is the closest available evidence; it is not a signed-application measurement.

## User decision: CPU duty cycle removed — 2026-10-24

After reviewing the results above, the user changed the requirement: "now that we've mostly solved the cost of the operation, remove the CPU usage limit and run the test again." The 60 s target is unchanged. `CooperativeDuty` is replaced by `WorkSlice`: the scanner, incremental reader and visibility validator still end a slice after 128 items or 8 ms of wall time, publish bounded batches (letting incremental reads interleave) and observe cancellation, but the boundary only calls `Task.yield()`; nothing sleeps. Priority stays utility. The cold profile now records slice yields instead of pauses (`yield_calls`, `yield_seconds`).

Same protocol: quiet machine, fresh processes, capped final (exact previous source, `TaggedFileScanner.swift` `50c4a608…`) interleaved with the uncapped build (`45d37557…`), three runs each. All 30 cold/reopen processes below publish the same record hash with 555,630 inspected items, 549,332 metadata reads and 3 deferred paths.

| Workload (median, all samples) | Capped final | No CPU cap |
| --- | --- | --- |
| W1 isolated first pass | 86.161 s (88.381, 86.161, 79.211) | **5.418 s** (5.989, 5.418, 4.967) |
| W1 process CPU | 16.691 s | 5.364 s |
| W3 sandboxed cold | 99.021 s (62.137, 99.021, 105.431) | **5.345 s** (5.591, 5.112, 5.345) |
| W3 unsandboxed cold | 96.290 s (103.632, 96.290, 82.640) | **5.355 s** (5.210, 5.481, 5.355) |
| W3 cached reopen | 0.048 s | 0.044 s (0.043–0.046) |
| CPU in ten idle seconds after readiness | 0.002–0.023 s | 0.002–0.009 s (≤0.09% of one core) |
| W4 Debug 10,000-record reopen (4 interleaved) | 1.069 s (1.228, 0.703, 0.935, 1.203) | **0.191 s** (0.190, 0.192, 0.192, 0.187) |
| W4 Release 10,000-record reopen | 0.294 s (0.262, 0.268, 0.319, 0.358) | **0.146 s** (0.151, 0.248, 0.142, 0.142) |

**The 60 s D-41 target passes** in the isolated and catalog-path workloads, by an order of magnitude. Every W4 reopen keeps the exact 10,000-record oracle, zero rescans and 1,310,324 bytes. The removed CPU cost matches the unthrottled work measured earlier: about 5 CPU-seconds once the cores are no longer duty-cycled at low clocks.

**Cost of removing the cap (W3, both sandbox modes, six runs per variant):**

| Measure | Capped | No cap |
| --- | --- | --- |
| Mean process CPU during readiness | 20.7–21.4% of one core | **98.5–99.1% of one core** |
| Peak one-second CPU window | 21.5–22.3% | 100.4–100.5% |
| Duration of that load | 62–105 s | 5.1–5.6 s |
| Main-actor heartbeat (16 ms) lateness p50 / p99 | 1.1–2.0 / 4.1 ms | 4.0 / 4.1 ms |
| Maximum lateness; stalls over 50 / 250 ms | 6.4–91.8 ms; 2 / 0 in one run | 4.07–4.09 ms; 0 / 0 |
| `ProcessInfo.thermalState` maximum | nominal (0) | nominal (0) |
| Lifetime peak footprint | 5.28–5.70 MiB | 4.99–5.20 MiB |

On this 10-core machine, discovery saturates one core (about 10% of total capacity) for about 5 seconds instead of 20% of one core for about a minute and a half. The heartbeat measures main-actor scheduling while catalog publication runs. The capped baseline's one 91.8 ms maximum is an isolated outlier; the uncapped runs never exceed 4.1 ms. CPU frequency could not be read without elevated privileges; thermal state stayed nominal and is the only thermal evidence. Limits: the headless proxy has no SwiftUI rendering, so frame pacing and interaction latency in the real app during a cold pass are unmeasured; one utility-priority core is in use for those seconds, and on a smaller or busier machine contention could be more visible.

## Concurrent traversal experiment — 2026-10-24 (historical; rejected and removed)

**User decision, 2026-10-24: multi-worker rejected; the default and only mode is one worker.** The implementation described below, its `ZF_TAG_WORKERS` benchmark switch, `FinderTagCatalog(scanBudget:)` and its three tests are removed. The restored scanner and catalog sources are byte-identical to the one-worker build measured before the experiment. These measurements remain as a historical result.

Requested by the user as an experiment, to keep only with a clear measured gain. `TaggedFileScanner.Budget.workers` (default **1**) selects the traversal. One worker runs the unchanged depth-first path (now sharing its per-entry and seed helpers). More workers share one directory stack: the coordinator inspects the seeds (priority folders, then Home) in order, and each worker repeatedly takes a directory, enumerates it, offers newly found subdirectories to the stack before every slice yield, and returns its directory when done. Idle workers wait on continuations, which are released when work arrives, when the stack and all workers are empty, or on cancellation. Each worker keeps the 128-item/8 ms slices, publishes its own bounded batches (at most 128 records) and stops publishing once it observes cancellation. Deferred paths merge under one lock through the existing `TagScanRoots` coalescing, and the counts are summed. Exclusions, visibility, package and link rules are the same per-entry code. Workers run at utility priority. The worker count is set only through `FinderTagCatalog(scanBudget:)` or, for benchmarks, `ZF_TAG_WORKERS`; production keeps one worker.

### Measurement conditions

Interleaved fresh processes (1, 2, 4, 8, 10 workers, order reversed on even repetitions), three repetitions; 10 is the core count (4 performance + 6 efficiency). A first sweep ran back-to-back and drove the fanless MacBook Air to `ProcessInfo.thermalState` *fair* for most samples; it is retained only as thermally confounded evidence. The accepted sweep waits before every sample until the thermal state is nominal and then idles 20 s (`cooldown` helper; one wait took 204 s). The live tree changed by a few items between some repetitions (555,635 → 555,639 inspected); adjacent runs with different worker counts always agree, and the record hash never changes. Later, an unrelated Godot workload saturated three cores and the screen locked; samples after that point are excluded, as stated below.

### Results

Isolated real Home/Shared scan (W1, cooled, load average about 2):

| Workers | Elapsed samples (s) | Median | Speed-up | Median CPU-s | Mean CPU | Peak footprint |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 4.939, 5.065, 5.349 | **5.065 s** | 1.00x | 5.02 | 99% | 3.80 MiB |
| 2 | 3.908, 3.948, 3.556 | 3.908 s | 1.30x | 7.75 | 198% | 3.94 MiB |
| 4 | 2.576, 3.037, 2.381 | **2.576 s** | 1.97x | 10.06 | 391% | 4.30 MiB |
| 8 | 2.443, 2.965, 2.821 | 2.821 s | 1.80x | 17.26 | 707% | 4.94 MiB |
| 10 | 2.764, 2.675, 2.579 | 2.675 s | 1.89x | 20.03 | 777% | 5.17 MiB |

Sandboxed catalog path, cold (W3, cooled):

| Workers | Elapsed samples (s) | Median | Median CPU-s | Mean / peak 1-s CPU | Main-actor lateness p50 / p99 / max | Thermal max |
| ---: | --- | ---: | ---: | --- | --- | --- |
| 1 | 5.136, 5.060, 5.581 | **5.136 s** | 5.06 | 99% / 100% | 8.02 / 8.06 / 8.12 ms | nominal |
| 2 | 3.978, 3.586, 5.227 | 3.978 s | 7.79 | 196% / 200% | 3.03 / 8.06 / 8.16 ms | nominal |
| 4 | 2.589, 2.213, 2.298 | **2.298 s** | 8.91 | 388% / 397% | 5.68 / 8.08 / 8.10 ms | fair in one run |
| 8 | 2.660, 2.794, 2.968 | 2.794 s | 19.96 | 722% / 746% | 1.51 / 7.99 / 8.30 ms | nominal |
| 10 | 2.940, 2.774, 3.108 | 2.940 s | 22.15 | 799% / 859% | 1.90 / 9.02 / 9.34 ms | nominal |

No run of any worker count had a main-actor stall over 50 ms. In this window the heartbeat baseline is about 8 ms rather than the 4 ms seen earlier, plausibly because of timer coalescing (the screen was locked during part of it); compare rows only within this window. Every run publishes the identical record hash (`cea76582c9c9…`) and 3 deferred paths.

The thermally confounded unsandboxed sweep (uncooled, *fair* thermal state) gave cold medians of 12.686 s (1 worker; samples 4.994 / 14.080 / 12.686), 4.699 s (2), 4.627 s (4), 3.348 s (8) and 3.022 s (10), with cached reopens of 0.041–0.094 s for every count. These numbers show how strongly a hot fanless machine distorts timing and are not used for the decision.

**Where it stops helping:** four workers give the best result (about 2x). Beyond four, elapsed time stops improving or gets worse while CPU time keeps rising (10 → 17–22 CPU-seconds). Per-item cost grows with contention in kernel path lookup and attribute calls. Even two workers spend 1.5x the CPU for a 1.3x speed-up.

The D-43 reopens and unsandboxed runs that were blocked by the locked session were later repeated on the final one-worker source (see the final verification section).

### Recommendation and decision status

**Recommended default: keep one worker** (unchanged in code). The single-worker pass already takes about 5 s, more than ten times under the 60 s target. It runs once per index generation and uses one core at utility priority with the least total CPU and energy. Four workers would save about 2.5 s at the cost of about 2x CPU-seconds, four saturated cores and observed thermal pressure on this fanless machine. On Macs with fewer efficiency cores (for example 4 + 4) utility work would compete directly with the user's foreground work. The concurrent path stays available, opt-in and tested (`Budget.workers`, `FinderTagCatalog(scanBudget:)`). If the user prefers the faster pass, `min(4, ProcessInfo.processInfo.activeProcessorCount / 2)` would be the measured choice. Whether to keep the opt-in code or remove it is a user decision; removing it means dropping the concurrent function and its three tests.

## Final verification of the delivered one-worker source — 2026-10-24

Decisions applied: multi-worker rejected (code removed); index protection kept (D-49). The final `TaggedFileScanner.swift` and `FinderTagCatalog.swift` are byte-identical (`45d37557…`, `731e8838…`) to the uncapped one-worker build measured in "User decision: CPU duty cycle removed". **Those quiet-window measurements are the clean acceptance evidence for the final source:** isolated first pass median 5.418 s, sandboxed catalog path 5.345 s, unsandboxed 5.355 s, cached reopen 0.044 s, at most 0.09% idle CPU, D-43 Debug 0.191 s / Release 0.146 s.

The repeat runs requested after the decisions used `caffeinate -dimsu` and an unlocked-session guard before and after every sample. The guard never found the session locked. A clean repeat was not possible: another workload ran headless Godot jobs on 2–6 cores almost continuously, and `ProcessInfo.thermalState` stayed *fair*. A cool-down gate waited more than 20 minutes without reaching a nominal state. One earlier attempt was stopped after its samples overlapped Godot bursts of up to 5.9 cores; those samples are discarded (`results-final4.jsonl`). The final runs were therefore taken under that load. Every sample is flagged contaminated (unrelated CPU 201–234% during each) and serves only as a functional and robustness check, not as acceptance timing:

| Under unrelated load (3 runs each) | Samples | Median |
| --- | --- | ---: |
| Isolated first pass | 8.744 / 6.485 / 6.418 s | 6.485 s |
| Sandboxed catalog path, cold | 7.093 / 6.757 / 7.213 s | 7.093 s |
| Unsandboxed catalog path, cold | 7.163 / 7.092 / 7.954 s | 7.163 s |
| Unsandboxed cached reopen | 0.067 / 0.040 / 0.042 s | 0.042 s |
| D-43 Debug reopen (10,000 records) | 0.604 / 0.388 / 0.369 s | 0.388 s |
| D-43 Release reopen | 0.318 / 0.306 / 0.308 s | 0.308 s |

Even under this load every target holds: first pass far below 60 s, reopen below 5 s, D-43 below 2 s with exact 10,000-record oracles, zero rescans and 1,310,324 bytes. Idle CPU over ten seconds is 0.002–0.016 s. Main-actor lateness is p99 8.1 ms and at most 9.6 ms, with no stall over 50 ms. All runs keep the same record hash, 555,817 inspected items / 549,519 metadata reads (the live tree grew) and 3 deferred paths.



Run from copies under `/private/tmp` (a test host started from `~/Documents` can block on a Documents privacy consent):

- TagCatalogTests: unchanged `HEAD` 57 distinct / 71 executions pass; candidate **62 / 90 pass**. The first candidate run failed only in a new test's fixture (`ENAMETOOLONG`: attribute names over 127 bytes); the fixture now uses 120-byte names with the same assertions.
- Full unit suite: **367 distinct / 557 executions; 366 / 556 pass**. The only failure, `ArchiveDiscoveryPerformanceTests.mixedDirectChildren` (136.58 ms vs 100 ms), is a known full-suite timing sensitivity outside the changed code; it passes in isolation on baseline and candidate.
- Serial tag UI cases: 1 pass, 2 fail — identically on unchanged `HEAD` (host Finder tags crowd the fixture's quick tag; D-52).
- Differential equivalence (`tag-catalog-equivalence.py`, accepted 2026-10-06 reference): **76 checkpoints / 152 catalog comparisons pass**.
- Every performance sample verifies the record hash and counts; W4 verifies the full 10,000-record oracle.

Details, result bundles and the investigated `FileOperationServiceTests` QoS warning are in [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

## Reproduction

All harnesses compile with the production recipe and print counts/hashes only:

```sh
python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py --configuration Release --compile-only \
  --fixture "$TMPDIR" --harness-file BuildSupport/Diagnostics/TagDiscoveryColdProfile.swift \
  --output /private/tmp/zforge-first-pass-final          # add --source-ref <commit> for a baseline
caffeinate -i /private/tmp/zforge-first-pass-final/measure
```

Use `TagDiscoveryAppPathProfile.swift cold|reopen [checkpoint-path]` for the catalog path; it also reports main-actor heartbeat lateness, per-second process CPU and maximum thermal state during readiness. (The earlier work-only profile is removed: production no longer pauses.) For a sandboxed variant, wrap the binary in a bundle with `CFBundleIdentifier` and sign it with `com.apple.security.app-sandbox` plus read-only temporary exceptions for `/` (home-relative) and `/Users/Shared/`; run the executable directly from a terminal that already has file access, never through `open`. Attach Time Profiler with `xctrace record --attach <pid>` to a process launched from that terminal; `xctrace --launch` makes the profile responsible for privacy access and blocks on Home folders. W4 uses `tag-index-scale-benchmark.py --reopen-from <checkpoint> --configuration Debug|Release`.

Raw samples: [tag-first-pass-optimization-results.json](tag-first-pass-optimization-results.json).

Tests after removing the cap (from `/private/tmp` copies): TagCatalogTests **62 distinct / 90 executions pass**; full unit suite **367 / 557 pass, zero failures/skips**; differential equivalence **76 checkpoints / 152 comparisons pass** (`/private/tmp/zf41r/equivalence-nocap`). The test change required by the decision is recorded in REGRESSION-COVERAGE.
