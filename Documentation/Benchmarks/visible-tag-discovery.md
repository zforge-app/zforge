# Visible Home/Shared tag discovery — 2026-10-06

## Workload and acceptance

Apply the user's explicit discovery policy: only current-user Home and `/Users/Shared`, excluding leading-dot items, `UF_HIDDEN` items and hidden ancestors. This is a Zforge product decision based on the user's observation, not an assertion that Apple documents an identical universal Finder rule.

Before measurement, set an initial acceptance target of 60 seconds for complete discovery of the real visible tree and less than 0.5% of one core during ten seconds after completion. Preserve the cooperative 20% duty target, bounded batches, package exclusion, cancellation and session reuse. Do not redefine acceptance after observing results.

The scanner harness extracts production metadata/scanner/temporary-storage/Home-provider code and publishes batches into aggregate counters without retaining file paths or tag names. Three fresh processes, real existing Home/Shared data, warm caches, no concurrent build/test/Zforge process, `/usr/bin/time -l` for CPU time and memory, and `getrusage` for the ten-second idle window. No cache flush, reindex request or file mutation is performed. Permission failures follow the existing scanner's skip behavior. This unsandboxed harness reaches data available to the terminal and is distinct from the signed sandboxed application.

The initial exploratory run overlapped a failing test run and the previous app and was interrupted without a completed result; it is excluded. Earlier test/build failures are retained in regression evidence. The clean measured scanner snapshot precedes the final canonical-scope escape guard; that guard changes grant/priority-root eligibility, not ordinary enumeration of these standard roots; all five actual priority roots were verified not to be symlinks. The generated diagnostic source SHA-256 is retained with the measurements. Whole-app validation uses the final delivered source separately.

## Scanner results

| Run | Completion | CPU time including idle | Peak RSS | Peak physical footprint | CPU seconds in ten idle seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 135.45 s | 19.79 s | 16.00 MiB | 3.69 MiB | 0.000344 |
| 2 | 149.23 s | 27.03 s | 16.03 MiB | 3.72 MiB | 0.000261 |
| 3 | 165.37 s | 30.31 s | 15.98 MiB | 3.67 MiB | 0.000417 |

All three completed runs discover three tagged records. Median completion is **149.23 seconds** (2 min 29 s); the range is 135.45–165.37 seconds. Idle CPU is 0.00261–0.00417% of one core. [Individual results and source fingerprint](visible-tag-discovery-results.json). Batch counts vary because checkpoints are triggered by both inspected-item count and elapsed slice duration; they are not exact file counts. The visible real tree is not frozen between runs.

**The 60-second completion target fails.** The post-completion CPU target passes in these observations. Scope pruning alone is insufficient to approve startup latency on this machine; every fresh process still performs a recursive traversal of visible files. A persistent incremental index is not implemented.

The earlier enabled/disabled comparison measured only startup age 15–40 seconds; it supplies context for the cause, not a directly comparable full-tree baseline or a measured latency speedup. CLI footprint values do not represent the entire app or its retained index.

## Reproduction and limits

Run `python3 BuildSupport/Diagnostics/visible-tag-discovery-benchmark.py --output /private/tmp/zforge-visible-tag-repeat` from the checkout, without another Zforge process or build/test runner. The script compiles the checkout's scanner using a temporary module cache and runs three captures, each followed by ten idle seconds. Native real-app measurements use `app-resource-sampler.c` and the aggregate `TagDiscovery` completion diagnostic.

Environment: macOS 27.0.1 arm64, Xcode/SDK 27.0, Debug app; the standalone scanner uses the Swift compiler's default optimization. These observations do not establish a universal completion limit, cold-cache behavior, Release performance, all sandboxed Shared permissions, long-session/high-tag-count memory, or macOS 26 runtime approval.

## Final sandboxed application

One final Debug app launch in **Recents/List**, no selection/interactions or concurrent build/test/Zforge process. Native observation confirms the screen/mode and preserved tag sidebar. A one-second stack sample during the extended capture identifies `TaggedFileScanner.discover` and metadata reads as the continuing worker. That raw stack and native observations remain temporary because they can contain personal paths/content.

The aggregate completion notice reports **288.424 seconds (4 min 48 s)** across two attempted scopes. This actual-app result is slower than the unsandboxed scanner harness; different execution/sandbox environments prevent attributing the difference to one cause without further measurement. Both fail the 60-second target. The scope count does not establish complete read access to every Shared item.

| App metric | Observed result |
| --- | ---: |
| CPU during process age 15–280 s | 17.638% of one core |
| CPU after completion, process age 300–332 s | 0.041% of one core |
| Mean physical footprint during discovery | 97.32 MiB |
| Mean physical footprint after completion | 97.36 MiB |
| Recorded lifetime peak physical footprint | 109.49 MiB |

Collect 400 samples at 500 ms (200 seconds), then extend by 180 samples (90 seconds) because the initial capture ends while the worker is still active. The two segments have a setup gap: cumulative CPU endpoint accounting includes that time; footprint means include observed samples only. The completion notice precedes the idle interval, which spans approximately 31.95 seconds. The app remains open afterward. [All 580 numeric samples, source fingerprints, windows and limits](visible-tag-discovery-app-results.json).

The final full unit suite passes **227 distinct cases / 304 executions**, with zero failures/skips. Three UI tests pass, covering local tag editing/context menus in List, Icons, Gallery and Columns. This does not close broader visual/accessibility, long-session or Shared authorization checks. The app's near-zero idle CPU is measured, not a promise of literal zero for every native notification or user interaction. Every fresh process still scans its eligible tree; durable cross-launch reuse remains unimplemented.
