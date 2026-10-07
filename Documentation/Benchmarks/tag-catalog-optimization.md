# ZF-42 — Incremental tag restoration and background visibility batches

Measured 2026-10-06 on macOS 27.0.1 arm64, Xcode/SDK 27.0. The user requests testing the first two [issue candidates](../Requirements/TAG-CATALOG-OPTIMIZATION-ISSUE.md). Production retains tags and atomic whole-snapshot JSON; no storage migration is delivered. The first two candidates are implemented and characterized. **The earlier unoptimized runs fail latency acceptance; the subsequent Release comparison passes all three isolated combined reopens.** Full application startup at 10,000 records remains unmeasured.

The subsequent user-authorized correctness review passes 76 differential checkpoints and the full affected regression suite, and repairs two defects shared by the original baseline. [The validation report](tag-catalog-equivalence.md) defines the reference adjustments and intended differences. Earlier sections and artifacts named "final" describe their respective historical source generation; exact-current Release measurements after these repairs are recorded below.

## Workload and acceptance

Use the existing 100,000-visible-file fixture with exactly 10,000 tagged files sharing one label, 100 tagged hidden descendants and 100 tagged package descendants. Checkpoints are isolated from the application store. Every accepted invocation asserts exact records/colors, completeness and recursive-scan counts against the independent fixture oracle. Cached runs wait for reconciled catalog readiness and ten idle seconds; early snapshot display is not readiness. Fixture-root prefix is 77 UTF-8 bytes. This is 10,000 tagged records, not 10,000 distinct label names.

The new acceptance requires every quiet valid-cache reopen below 2 s and settled persistent catalog size below 1,572,864 bytes (1.5 MiB). A single catalog uses one JSON file and no retained sidecar; independent benchmark repetitions/storage experiments are separate catalogs, not production sidecars. CPU/memory and authorization, exclusions, replay, recovery and cancellation contracts remain. Timed accepted runs do not overlap build/test runners, use warm filesystem caches and `caffeinate -i`, and retain monotonic/wall timing and source/helper hashes. Ordinary user applications remain open; this is not a controlled thermal/frequency study.

## Separate candidates and final combined result

| Three-run cached measure | Unchanged baseline | First-only prototype | Final combined version |
| --- | ---: | ---: | ---: |
| Median reconciled readiness | 15.110 s | 0.339 s | 2.150 s |
| Readiness range | 14.494–15.844 s | 0.327–0.357 s | 1.752–2.170 s |
| Median CPU time during readiness | 3.677 s | 0.294 s | 0.440 s |
| Median CPU, one core, during readiness | 24.33% | 86.83% | 20.83% |
| Maximum lifetime footprint observed at readiness | 29.17 MiB | 23.78 MiB | 24.97 MiB |
| Maximum lifetime footprint through verification/idle | 32.27 MiB | 31.55 MiB | 32.88 MiB |
| Median ten-second idle CPU | 0.003113% | 0.003490% | 0.002757% |
| Persistent index bytes | 1,320,326 | 1,320,326 | 1,320,326 |
| Recursive scan calls on reopen | 0 | 0 | 0 |

Final samples are **2.150401 / 2.170415 / 1.751871 s**. Median readiness is 85.77% lower (7.03x faster) and accumulated CPU is 88.02% lower than the new unchanged baseline. The final combined version is slower than the first-only prototype because it places filesystem visibility work off the main actor and cooperatively pauses, rather than concentrating an approximately 87%-CPU burst on the main actor. This is a measured tradeoff, not a claim that batching improves total latency by itself. The first-only prototype is also incomplete: it misses changes to a symbolic-link target outside the watched scope. The final implementation conservatively revalidates linked/unverifiable records.

**Acceptance:** one of three final quiet runs is below 2 s; two fail. The unchanged **1.259 MiB** index passes the size target for this fixed same-label workload. The separate earlier 10.377 s baseline used the same fixture but a different measurement window; it is historical, not substituted for the 15.110 s contemporary reference. Footprints belong to an isolated diagnostic process and include fixture-oracle/setup/verification allocations. They are not complete application memory; the slightly higher whole-process peak does not establish memory retention or a leak.

## Release comparison — 2026-10-06

The user requests Release measurements before extending equivalence testing. The earlier diagnostic compilations use Swift's unoptimized default. The benchmark now supports `--configuration Release` and `--source-ref` to compile an existing baseline without changing the checkout. Release uses Swift `-O -whole-module-optimization`, the application's MainActor/default concurrency features, target `arm64-apple-macos26.0`, and native C `-Os`. It does not use `-Ounchecked`; all exact-result preconditions remain active. The full application builds successfully in Release and passes strict deep local signature verification. These separate build checks do not make the isolated executable a sandboxed application startup measurement.

Baseline source is commit `fd1bacc` (resolved in the artifact); every production source fingerprint exactly matches the previous unchanged baseline. Combined production fingerprints match the final implementation above. Both reuse the same correct seed, fixture and path prefix. Order is three baseline processes followed by three combined processes; no build/test or benchmark overlaps the timed runs. Filesystem caches are warm, `caffeinate -i` prevents idle sleep, and ordinary user applications remain open. This is not a randomized or thermally controlled experiment; differences from previous Debug windows cannot be attributed exclusively to compiler optimization.

| Three-run cached measure | Release baseline | Release combined |
| --- | ---: | ---: |
| Median reconciled readiness | 14.166 s | 0.683 s |
| All readiness samples | 19.220846 / 12.817559 / 14.166099 s | 0.711478 / 0.683182 / 0.648278 s |
| Median CPU time during readiness | 3.428 s | 0.179 s |
| Median CPU, one core, during readiness | 24.20% | 26.08% |
| Maximum lifetime footprint observed at readiness | 28.73 MiB | 24.36 MiB |
| Maximum lifetime footprint through verification/idle | 31.88 MiB | 30.81 MiB |
| Median idle CPU over at least ten seconds | 0.002502% | 0.002982% |
| Persistent index bytes | 1,320,326 | 1,320,326 |
| Recursive scan calls on reopen | 0 | 0 |

Release combined readiness is **95.18% lower (20.74x faster)** and accumulated CPU is **94.78% lower** than the contemporary Release baseline. All three combined runs meet strictly below 2 s; storage remains **1.259 MiB**, with no persistent catalog sidecars. Average CPU during this shorter preparation window is higher, not lower; the cooperative 20% worker duty is not a hard whole-process quota. All six invocations assert exact expected paths/tag names/colors, completeness, no recursive scan and a drained catalog after idle. Source/script/helper fingerprints, actual compiler commands, clocks and all samples are preserved in [Release baseline results](tag-catalog-optimization-release-baseline-results.json) and [Release combined results](tag-catalog-optimization-release-combined-results.json). These are six additional diagnostic invocations, not unit/UI test executions or a broader equivalence proof.

The observed expectation is about **0.65–0.71 s for isolated quiet valid-cache reconciliation** on this machine and same-label fixture. It is not launch-to-usable-window time, a guaranteed upper bound, cold indexing time or full application RAM. Complete sandboxed application measurements, high link density, distinct-label cardinality, cold Release traversal and long sessions remain open; ZF-42 is not closed.

Build evidence: `/private/tmp/zforge-zf42-release-performance-build.log` (`ENABLE_CODE_COVERAGE=NO CLANG_ENABLE_CODE_COVERAGE=NO`) and `/private/tmp/zforge-zf42-release-signature.log`. Actual Swift and C compile commands/response files contain no coverage instrumentation. The environment initially enables coverage; the first successful build is therefore not used as the performance configuration. An attempted `-enableCodeCoverage NO build` exits before compilation because Xcode supports that flag only for testing; the subsequent build-setting override succeeds. A settings query initially fails under restricted DerivedData access; the normal-access query succeeds. No production code or previous test expectations change in this Release round.

## Release acceptance after correctness repairs — 2026-10-06

The user-authorized implementation passes the [broader differential gate](tag-catalog-equivalence.md). Performance is repeated on the exact accepted sources, including Unicode scope boundaries, physical journal mapping and index generation 4. The current-source fingerprints match both the accepted differential manifest and this worktree. A new complete 15-invocation current workload produces fresh generation-4 checkpoints; obsolete generation-3 seeds are deliberately not used for current cached timing.

The contemporary reference is baseline `fd1bacc` plus **the same explicit `TagJournal.swift` repair** used in functional comparisons. Its remaining production fingerprints match the immutable commit; its valid baseline-generation-3 seed is checked against the full fixture oracle. This reference preserves the old blanket metadata reread algorithm while giving both implementations a correctly functioning watcher. The previous immutable-baseline 14.166 s result above remains historical evidence, not the new comparator.

| Three-run quiet cached measure | Repaired baseline algorithm | Accepted combined implementation |
| --- | ---: | ---: |
| All readiness samples | 15.347398 / 12.945905 / 14.214156 s | 0.820065 / 0.857169 / 0.733745 s |
| Median reconciled readiness | 14.214 s | 0.820 s |
| Median accumulated CPU | 3.241 s | 0.183 s |
| Median preparation CPU, one core | 22.80% | 23.12% |
| Maximum lifetime footprint at readiness | 28.92 MiB | 22.92 MiB |
| Maximum lifetime footprint through verification/idle | 32.05 MiB | 29.03 MiB |
| Median CPU during at least ten idle seconds | 0.002653% | 0.002687% |
| Quiet persistent index bytes | 1,320,326 | 1,320,326 |
| Recursive scans per quiet reopen | 0 | 0 |

**Every accepted current reopen passes the strict below-2-second target**. Median readiness is approximately 17.3x faster (94.23% lower) and accumulated CPU approximately 94.35% lower than the repaired reference. Storage remains **1.259 MiB**, with no persistent catalog sidecars. Preparation CPU is a whole-process average, not a hard 20% cap. Drained idle work consumes approximately 0.00027 CPU seconds per ten-second interval rather than claiming literal zero CPU. Footprints are isolated-process measurements, not whole-application RAM.

The full current Release workload additionally returns exact records in all cold/storage phases:

| Current phase | All elapsed samples | Median |
| --- | --- | ---: |
| Full cold discovery | 43.016145 / 33.061583 / 35.223706 s | 35.224 s |
| JSON load | 17.498 / 18.278 / 18.173 ms | 18.173 ms |
| Complete JSON save | 12.339 / 12.934 / 13.345 ms | 12.934 ms |
| One-record whole-snapshot replacement | 14.936 / 15.607 / 15.611 ms | 15.607 ms |

Each cold process makes exactly one recursive scan; each reopen makes zero. Cold discovery's median CPU is 18.56% of one core and accumulated CPU 6.584 s. The one-record replacement fixture is 1,320,346 bytes (20 extra bytes), still below the ceiling. Independent replacement experiments are separate catalogs, not retained production sidecars. Transient simultaneous old/new atomic-replacement disk peak is not sampled by this diagnostic; no transient-size approval is claimed.

All **18 invocations** (15 current, 3 reference) pass exact path/tag/color, scan-count and drained/completeness assertions. Current workload completes before reference compilation begins; the reference then runs three sequential cached processes. All timing intervals follow compilation and run without concurrent build/test/benchmark activity, with warm filesystem caches and `caffeinate -i`. Ordinary applications remain open; order is not randomized or thermally controlled. Maximum wall/monotonic discrepancy is below 0.000016 s. [Current raw measurements and compiler/source manifests](tag-catalog-equivalence-release-catalog-results.json); [reference raw measurements and explicit source override](tag-catalog-equivalence-release-baseline-results.json).

Reproduce the current workload with a fresh output directory:

```sh
caffeinate -i python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py \
  --configuration Release --output /private/tmp/zforge-tag-accepted-new \
  --fixture "$TMPDIR/ZforgeTagScale-10000/fixture"
```

The final application Release build succeeds (`/private/tmp/zforge-zf42-equivalence-release-build.log`, coverage disabled), and strict deep signature verification passes. Actual functional execution is 257 unit cases / 348 executions plus three serial UI cases; 76 differential checkpoints pass. Generation 3 requires one full rebuild to repair possible omissions; subsequent valid generation-4 snapshots reuse normally. The controlled cold fixture is measured here, but exact-final real Home/Shared cold discovery and signed application's 10,000-record launch-to-usable/RAM/frame pacing remain unmeasured. The broader distinct-label/high-link-density, long-session, genuinely cold filesystem and macOS 26 limits remain; ZF-42 is open for full-application acceptance.

## Delivered algorithm and correctness boundaries

- Valid-history ordinary files no longer receive unconditional tag-xattr rereads on restoration. Their current visibility is still checked; metadata reads apply to historical/live changes and saved retries. Invalid identity, unavailable/lost history and dropped events retain conservative reconciliation.
- Symbolic links and multiply linked regular files are recognized during the existing leaf `lstat` and reread on reopen, because target/inode metadata may change outside watched paths. An unavailable leaf identity also receives a conservative metadata read; failed reads retain records and defer retry under the existing contract.
- A utility worker validates the incoming delivery using at most 512 ancestor-flag entries. It caches ancestors rather than consuming the cache with unique leaves; the 100-sibling test requires one probe each for the root and shared directory plus one per leaf. The cache is discarded after the finite delivery and cannot mask later visibility transitions.
- Canonical stored paths avoid repeated Foundation normalization; unusual aliases/relative components retain normalization before policy checks. POSIX separators are interpreted as UTF-8 bytes, so a combining mark at the beginning of a filename cannot merge with a slash as a Unicode grapheme and bypass an ancestor. Paths, tags and colors retain their identity.
- Validation retains utility priority, 128-item/8 ms slices and cooperative 20% duty. Cancellation discards partial results; catalog generation checks run after asynchronous boundaries. Main-actor merging/publishing occurs once per accepted delivery. Observations during startup enqueue later reads so asynchronous restoration cannot leave an edit overwritten by the old snapshot. No periodic discovery worker remains after completion.

## All measurements and rejected acceptance claims

- [Unchanged baseline: three reopens](tag-catalog-optimization-baseline-results.json).
- [First-only prototype: three reopens](tag-catalog-optimization-incremental-results.json). This is not the delivered linked-item-safe version.
- [Initial combined candidate: 15 cold/reopen/load/save/rewrite invocations](tag-catalog-optimization-batched-results.json). Cached times 1.595 / 2.638 / 2.528 s fail the latency target. Cold times 50.667 / 37.483 / 37.866 s and all storage phases preserve every expected record; this precedes final lifecycle/path refinements and is not an exact-final cold benchmark.
- [Normalize-once candidate: three reopens](tag-catalog-optimization-normalized-results.json), 1.819 / 1.836 / 0.834 s. All pass in that round, but this precedes the unavailable-identity/Unicode review and is not final acceptance.
- [Unavailable-identity review: three reopens](tag-catalog-optimization-reviewed-results.json). Retains the 2.099 s sample; it is not silently removed.
- [Canonical-path candidate: three reopens](tag-catalog-optimization-canonical-results.json), 1.827 / 1.783 / 1.761 s. Precedes the Unicode fix and is not final acceptance.
- [Overlapping experiment: three reopens](tag-catalog-optimization-overlap-results.json). Invalid for isolated comparison: it starts at 23:28:21 UTC while the joint Xcode run does not finish until about 23:28:35 UTC. Correctness assertions pass, but these durations are retained without using them as performance approval.
- [Exact-final isolated version: three reopens](tag-catalog-optimization-final-results.json). Starts only after the final Xcode process exits; every production/harness fingerprint is verified against current source.

There are 36 diagnostic invocations across these artifacts: 33 without build/test overlap and three in the explicitly invalid overlapping experiment. All exact-result checks pass; this does not turn failed latency criteria into passing criteria. The timing variation across intermediate rounds leaves limited margin and reinforces keeping the strict target open.

## Executed regression and preparation failures

- Unchanged tag baseline: 44 distinct unit cases / 50 executions, zero failures/skips.
- New quiet-cache characterization fails before the first change on `probe.reads.isEmpty`; the remaining existing cases pass. A first individual selector executes zero tests and is not counted as approval; the full class supplies the actual failure.
- Initial batch-test compilation fails because Swift Testing's macro treats the receiver of a mutating method as immutable. Evaluating the method into a local before asserting preserves the original scenarios and assertions; the next run passes 49 cases / 55 executions.
- The linked-target case fails in the prototype before selective linked-item rereads; afterward both symbolic/hard-link scenarios pass (50 cases / 57 executions).
- Unicode ancestor characterization fails before byte-based separator handling. Its hidden-ancestor/probe assertions pass afterward.
- A joint run fails the quiet-cache assertion because fixture metadata written before stream startup can arrive after its initial discovery checkpoint. The fixture now writes its final tag while the first native journal is running, explicitly waits for catalog observation and checkpoint drain, then performs the unchanged quiet reopening. All original result/no-scan/no-read assertions remain; no timeout, tolerance or scenario is relaxed. This is synchronization, not an expectation change.
- Final joint regression bundle `/private/tmp/zforge-zf42-final-regression.xcresult`: **253 distinct unit cases / 337 executions plus three UI cases**, **256 distinct / 340 executions total**, zero failures/skips. The three native UI tests cover the shared editor and context menus across Icons, List, Gallery and Columns. Complete 10,000-record startup/frame pacing and the broader visual/accessibility matrix are not covered by these UI cases.
- The unchanged FileOperationServiceTests fixture emits the already recorded runtime QoS priority-inversion warning. AppIntents metadata-extraction notices and AppKit/WebKit runner diagnostics are not new Swift compiler warnings; do not confuse them with a clean runtime log. Final strict deep Debug signature succeeds with normal certificate access; verification inside the restricted sandbox first reports an unavailable trust chain.
- Automatic permission review times out once before the initial combined benchmark starts; its permitted retry succeeds. Early result extraction while Xcode is still writing the joint bundle fails on missing Info.plist and is repeated only after process completion; the finalized result is valid.

## Reproduction and next decision

Prepare the dense fixture as in [durable-tag-index.md](durable-tag-index.md), then run the complete isolated catalog/storage workload:

```sh
caffeinate -i python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py --output /private/tmp/zforge-tag-final-new --fixture "$TMPDIR/ZforgeTagScale-10000/fixture"
```

For three fresh cached processes using an already verified index:

```sh
caffeinate -i python3 BuildSupport/Diagnostics/tag-index-scale-benchmark.py --output /private/tmp/zforge-tag-reopen-new --fixture "$TMPDIR/ZforgeTagScale-10000/fixture" --reopen-from /private/tmp/zforge-zf42-batched/index-1.json
```

Use a new output directory; do not overlap builds, tests or another benchmark. The script compiles current production sources, copies the correct seed into separate checkpoints and preserves the exact oracle and native journal behavior.

For Release, add `--configuration Release`. Add `--source-ref fd1bacc` only for the unchanged baseline; omit it for current working sources. Exact six-run artifacts use `/private/tmp/zforge-zf42-release-baseline` and `/private/tmp/zforge-zf42-release-combined`, with the same seed `/private/tmp/zforge-zf42-batched/index-1.json`. Retain separate output directories and run the two commands sequentially.

The final correct combined candidate provides substantially lower startup work and bounded background validation. Release isolated latency/storage criteria pass, while ZF-42's complete application acceptance remains open. Further work should profile visibility preparation, main-actor merge, scheduling pauses and historical-delivery latency separately before changing the storage backend or CPU-duty contract. Complete application measurements, high link density, 10,000 distinct label names, long sessions, cold Release and macOS 26 remain open. JSON storage is already below the size ceiling, and the initial phase measurements do not identify decoding as the dominant startup cost.
