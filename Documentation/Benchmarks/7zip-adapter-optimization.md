# ZF-25: native 7-Zip adapter performance and memory (OR-11, OR-12)

Round started 2026-10-23 on macOS 27.0.1 (26A434), Apple M5 (10 cores), 24 GiB, Apple Clang 21.0.0, Swift 6.4. Another agent was working on tag discovery in a separate worktree on the same host for the whole round (load average ≈ 2.3 before the first measurement), so every baseline/candidate comparison below is interleaved in the same time window with rotated order, and samples are reported with their spread.

## Workloads and acceptance criteria (written before any code change)

These definitions were recorded after an exploratory two-round smoke run of the harness and **before** any product change. They were not redefined after measuring.

### Layers

- **CLI**: official `Vendor/7zz` (`l -slt`, `t`, `x -y -o…`), one process per operation; its times include process start-up. The `tiny-store-zip` workload (one 4-byte file) records that fixed cost.
- **Bridge (static / dynamic)**: [`Adapter/bridge.mm`](../../BuildSupport/SevenZip/Benchmarks/Adapter/bridge.mm) calls `ZFSevenZipBridge` directly. Static links the bridge object and force-loads `libSevenZipCore.a`; dynamic loads the same bridge object and core from `libSevenZipNative.dylib`, built exactly like the historical dynamic variant. Directory creation and the index/destination arrays are built inside the extraction timer, mirroring the Swift contract (directories get an empty destination).
- **Complete `ArchiveServing`**: [`Adapter/engine.swift`](../../BuildSupport/SevenZip/Benchmarks/Adapter/engine.swift) compiles the app's own `NativeSevenZipArchiveEngine`, `NativeSevenZipBackend`, entry/policy/options sources with the app's Swift settings (Swift 6, default MainActor isolation, approachable-concurrency features, `-O -wmo`) and calls `extractArchive` (staging copy, listing, conflict scan, Swift preparation, native extraction, link pass) or `extractItems` for a multi-selection. It runs outside the App Sandbox and without UI.
- Baseline = `git archive` of HEAD `2ba9559` (bridge/Swift sources identical to the D-21 fix); candidate = this working tree. Both use one `libSevenZipCore.a` (26.02 sources, Release flags of `build.sh`) and the same harness binaries, so only the measured sources differ.

### Workloads

| Workload | Content | Archive (created once by the CLI) |
| --- | --- | --- |
| `small2k-store-zip` | 2,000 × 256 B, flat (the historical OR-12 load) | ZIP Store |
| `small10k-deflate-zip` | 10,000 × 4 KiB (2 KiB xorshift64 seed 42 + 2 KiB zeros), flat (the RAM-benchmark load) | ZIP Deflate level 5, fb 32, 2 threads |
| `tree10k-store-zip` | 100 folders × 100 files of 4 KiB | ZIP Store |
| `tree10k-solid-7z` | same tree | 7z LZMA2 level 5, 64 MiB dictionary, fb 32, solid, 2 threads |
| `large64-store-zip` | one 64 MiB file (0–255 sequence) | ZIP Store |
| `tiny-store-zip` | one 4-byte file | ZIP Store |
| `Large256` pipeline (OR-11) | one 256 MiB file (512 KiB xorshift64 + 512 KiB zeros, ×256) | created in-process: 7z LZMA2 level 5, 64 MiB dictionary, fb 32, solid, 2 threads |

Every extraction goes to a new directory and every extracted file is SHA-256-checked against the source manifest outside the timers. Each sample is a new process; order of backends rotates each round. Multi-selection extraction (`extractItems` with every other root item) is measured separately for the 10,000-entry workloads.

### Acceptance criteria

OR-12 (time):

1. **C1 — bridge parity:** bridge extract-all (static and dynamic) median ≤ CLI `x` median for `small2k-store-zip`, `small10k-deflate-zip` and `tree10k-store-zip`.
2. **C2 — linear scaling:** bridge per-file extraction cost of the 10,000-file workloads ≤ 1.5 × the per-file cost of `small2k-store-zip`.
3. **C3 — complete path:** `ArchiveServing.extractArchive` median ≤ 1.25 × the CLI `x` median on the same three workloads (it also stages a copy of the archive, lists, scans conflicts and prepares directories).
4. **C4 — no regression:** for `large64-store-zip`, `tree10k-solid-7z` and all list/test operations, candidate median ≤ baseline median + max(5 %, baseline interquartile range).
5. **C5 — evidence of gain:** a change is kept only if its median is below the baseline minimum in the interleaved rounds, or if the median gain exceeds 3 × the baseline interquartile range. Changes are evaluated one at a time.

OR-11 (memory, `Large256` pipeline repeated three times in one process, bridge and `ArchiveServing`):

1. **M1 — no accumulated growth:** footprint after cleanup + 1 s idle of cycle 3 ≤ cycle 1 + 16 MiB.
2. **M2 — bounded retention:** footprint after cleanup + idle ≤ process baseline + 64 MiB; if not met, the retaining owner (live objects vs. allocator-held free memory vs. other) must be identified with evidence instead of being called a leak.
3. **M3 — no peak regression:** per-phase footprint not higher than baseline.

Correctness and security are not traded for time: authorized root, `O_NOFOLLOW` descriptor walk, byte limits, traversal/link protection, cancellation and the sandboxed app path keep their tests (see `REGRESSION-COVERAGE.md`).

## Outcome summary

- **OR-12:** the dominant cost was an O(n²) index lookup in the bridge (H1 confirmed by profiling). With it and two Swift-preparation fixes, extract-all of 10,000 entries dropped **2.2–2.4 ×** through `ArchiveServing` and **2.4–3.2 ×** in the bridge, and a 5,000-item multi-selection **8.1 ×**. Bridge extraction is now at CLI parity within noise (C1, C2 met); the complete path is still 1.18–1.35 × the CLI (C3 **not met**).
- **OR-11:** retention is allocator-held free memory (≈ 935 MiB of empty "Malloc Large" segments) left by 7-Zip's encoder/decoder buffers, bounded and reused across repetitions (M1, M3 met), **not** a leak and not reduced by this round (M2 **not met**).

## Baseline with current code (A/A control)

[`records/baseline-aa.jsonl`](7zip-adapter-optimization/records/baseline-aa.jsonl): five rotated rounds in which "baseline" and "candidate" were the **same** HEAD sources, measured before any change. The two copies differed by ≤ 1 % in every extraction median, which is the noise floor for this host when it is relatively quiet. Extraction medians in ms (min–max):

| Workload | CLI | Bridge static | Bridge dynamic | `ArchiveServing` |
| --- | ---: | ---: | ---: | ---: |
| `small2k-store-zip` | 116.6 (113.1–116.9) | 168.2 (162.4–170.1) | 167.6 (162.9–170.4) | 225.8 (222.5–231.0) |
| `small10k-deflate-zip` | 701.1 (700.9–713.8) | 2,045.6 (2,026.0–2,089.7) | 2,047.9 (2,024.8–2,049.8) | 2,307.9 (2,295.0–2,312.6) |
| `tree10k-store-zip` | 612.1 (605.8–643.5) | 1,968.2 (1,945.7–2,113.2) | 1,963.9 (1,934.7–2,265.6) | 2,256.6 (2,245.8–2,495.9) |
| `tree10k-solid-7z` | 926.4 (920.3–1,097.9) | 2,270.1 (2,250.0–2,295.3) | 2,267.7 (2,215.9–2,317.6) | 2,568.5 (2,527.0–2,596.8) |
| `large64-store-zip` | 18.9 (18.7–28.0) | 19.7 (15.1–22.2) | 18.8 (14.9–20.0) | 31.6 (29.0–48.0) |

With the current (post-D-21) code the gap on the historical 2,000-file load is **+44 %** (not the historical 32–35 %), and it grows to **2.5–3.2 ×** at 10,000 entries: per-file bridge cost went from 84 µs (2,000) to 205 µs (10,000), a superlinear signature. Listing and testing were already faster natively (no process start, no text output) and stay so. Static and dynamic remain indistinguishable.

## Profiling (Time Profiler, System Trace, vmmap)

Summaries are in [`profiles/`](7zip-adapter-optimization/profiles); traces were recorded with `xcrun xctrace record --template 'Time Profiler' --launch -- <harness> …` and aggregated with [`Adapter/profile.py`](../../BuildSupport/SevenZip/Benchmarks/Adapter/profile.py) (system calls: [`Adapter/syscalls.py`](../../BuildSupport/SevenZip/Benchmarks/Adapter/syscalls.py)).

1. **Baseline bridge, `small10k-deflate-zip`:** `-[NSArray indexOfObject:]` inside `ExtractCallback::GetStream` = **61 %** of all samples (NSNumber `isEqualToNumber:`/`compare:`/`CFNumberGetValue`). Every extracted item searched the whole index array: O(n²). File creation (`openat`) was 12.7 %, `SetOperationResult` (`fchmod`, `futimens`, `close`) 9.8 %, the Deflate codec ≈ 11 %. The complete path showed the same 56 % share.
2. **Complete path after fix 1, `tree10k-store-zip`:** native extraction 61 % (`openat` 30 %, metadata + close ≈ 21 %); Swift preparation in `NativeSevenZipBackend.extract` ≈ 20 %: `standardizedFileURL` 9 %, `resolvingSymlinksInPath` 7.8 % (an `lstat` per path component per entry), `appendingPathComponent` 4.7 % (stats the destination to infer a directory hint), `safePath` 4.4 %, per-record `deletingPathExtension` 2.6 %; `conflictFilesToReplace` 5.9 % (`localizedStandardCompare` sort + `fileExists`); listings ≈ 10 %.
3. **Multi-selection (`extractItems`, 5,000 of 10,000 root items):** `Sequence.contains(where:)` = **58 %**, split between `conflictFilesToReplace` (29 %) and `NativeSevenZipBackend.extract` (29 %), each allocating `path + "/"` for every entry × selected-path pair: O(entries × selected).
4. **System Trace, final bridge, `small2k-store-zip`** ([counts](7zip-adapter-optimization/profiles/final-bridge-small2k-syscalls.txt)): per extracted file exactly one `openat`, `write`, `fchmod`, `fsetattrlist` (`futimens`) and `close`, plus one `fstatat`/`mkdirat` from the harness's own directory preparation; `openat` (file creation, ≈ 28 µs/file in the kernel) dominates. A CLI System Trace capture hung at launch under the tracer and was killed, so no CLI syscall count was obtained; wall-time parity (below) is the comparison instead.

## Candidates (one at a time, interleaved A/B)

| # | Change | Hypothesis | Evidence | Decision |
| --- | --- | --- | --- | --- |
| 1 | `SevenZipBridge.mm`: archive-index → destination-position table built once (`std::vector`, first occurrence wins, indices outside the archive ignored as before) instead of `indexOfObject:` per callback | H1 **confirmed** | [`records/cand1.jsonl`](7zip-adapter-optimization/records/cand1.jsonl) ("candidate" = #1), 5 rounds: bridge 10k extraction 2,036 → 739 ms, 1,968 → 625 ms, 2,435 → 981 ms; candidate ranges do not overlap baseline ranges | Kept |
| 2a | `NativeSevenZipBackend`: resolve each parent directory once for the containment check (`ContainmentResolver`), resolving in full whenever the leaf itself is a symbolic link; hoist the fallback name out of the per-record loop (also in `list`) | H3 **confirmed** (Swift preparation) | [`records/c2a.jsonl`](7zip-adapter-optimization/records/c2a.jsonl), 7 rounds vs #1: `ArchiveServing` 994 → 897, 931 → 827, 1,240 → 1,138, 173 → 155 ms; candidate max below #1 min on all four | Kept |
| 3 | `ArchivePathSelection`, shared by `NativeSevenZipBackend.extract` and `conflictFilesToReplace`: `Set` lookup of the entry and of each prefix ending before a `/` scalar, each hit confirmed with the original `hasPrefix(selected + "/")` | H3 **confirmed** (selection) | [`records/sel-c3.jsonl`](7zip-adapter-optimization/records/sel-c3.jsonl), 6 rounds vs #2a: 5,000-of-10,000 selection 4,040 → 515 ms, 2k 230 → 88 ms; 50-folder tree selection unchanged (433 → 425 ms); 300,000 randomized adversarial cases (NFC/NFD, combining marks after `/`, prepend characters, empty components) equal to the original predicate | Kept |
| 4 | Directory hint for `appendingPathComponent` (avoid one `stat` per entry) | H2/H3 | [`records/c4.jsonl`](7zip-adapter-optimization/records/c4.jsonl) (contended, inconclusive) and [`c4b.jsonl`](7zip-adapter-optimization/records/c4b.jsonl) (9 rounds, paired): −2 to −16 ms (1–2 %), below criterion C5 | **Reverted** |

Not changed, with reasons: per-file `fchmod`/`futimens` (H2) are the minimum needed to apply archive metadata on the open descriptor after a successful item; creating files directly with the archive mode would apply `umask`, expose final permissions before content is complete and change failure semantics. The conflict-scan sort (≈ 4 %) and the second listing inside `extractArchive` (≈ 5 %) are measurable but small, and removing them changes prompt timing or the backend interface; they remain future candidates.

## Final comparison (baseline HEAD vs final working tree)

[`records/final-timing.jsonl`](7zip-adapter-optimization/records/final-timing.jsonl) and [`final-selected.jsonl`](7zip-adapter-optimization/records/final-selected.jsonl): 7 (selection: 6) rotated rounds, 2026-10-23 15:02–15:10. The concurrent agent raised the load average to 5.6 at the start of this window, so absolute times, including the CLI's, are higher and more variable than in the A/A run; baseline and final were interleaved in the same rounds. Summary: [`final-summary.json`](7zip-adapter-optimization/final-summary.json). Extraction median ms (min–max):

| Workload | CLI | Bridge static: baseline → final | Bridge dynamic: baseline → final | `ArchiveServing` extract-all: baseline → final | Multi-selection: baseline → final |
| --- | ---: | ---: | ---: | ---: | ---: |
| `small2k-store-zip` | 159.3 (120.1–178.5) | 206.2 (167.7–248.5) → **152.7** (115.6–189.8) | 211.6 → **159.7** | 275.9 (225.7–326.6) → **187.9** (155.0–229.4) | 281.5 (268.4–286.6) → **100.0** (96.2–102.7) |
| `small10k-deflate-zip` | 866.5 (717.6–1,112.6) | 2,360.3 (2,088.1–2,777.8) → **877.3** (814.8–1,071.7) | 2,343.1 → **888.0** | 2,649.6 (2,572.3–3,100.2) → **1,092.3** (899.9–1,314.5) | 4,759.9 (4,633.0–4,945.7) → **587.4** (572.5–601.3) |
| `tree10k-store-zip` | 788.3 (642.7–962.9) | 2,181.3 (1,954.6–2,687.0) → **692.0** (623.2–1,171.0) | 2,147.7 → **747.8** | 2,421.9 (2,277.8–2,809.8) → **1,060.3** (824.0–1,219.7) | 923.3 (886.0–961.6) → **483.7** (459.9–494.4) |
| `tree10k-solid-7z` | 1,010.9 (940.7–1,282.3) | 2,440.6 (2,285.5–2,970.2) → **1,008.0** (928.7–1,257.7) | 2,490.8 → **1,023.1** | 2,792.0 (2,644.4–3,340.9) → **1,274.7** (1,176.6–1,555.3) | — |
| `large64-store-zip` | 20.0 (17.6–34.2) | 16.5 → 17.3 | 16.2 → 15.6 | 32.6 → 32.2 | — |

`openArchive` + `items` also fell from 64–68 ms to 49–51 ms on the 10,000-entry archives (fallback name no longer recomputed per record). Lists and tests are unchanged within noise. A focused 9-round recheck of `large64-store-zip` ([`final-large64-summary.json`](7zip-adapter-optimization/final-large64-summary.json)) gives identical baseline/final list (0.18/0.18 ms), test (8.72/8.72 ms) and extraction (14.40/14.47 ms) medians; a 0.63 ms list median in the contended window was noise (the listing code is byte-identical).

### Criteria

- **C1 bridge parity — met within noise, not strictly in every cell.** Final window: static 152.7 vs 159.3 ms (2k) and 692.0 vs 788.3 ms (tree) met; 877.3 vs 866.5 ms (10k) +1.2 %; dynamic +0.3 % (2k), +2.5 % (10k), met on tree. Quieter #1 window: static 120.2 vs 126.9, 738.6 vs 791.8, 625.4 vs 624.8 ms. All differences are well inside the CLI's own interquartile range (37–210 ms).
- **C2 linear scaling — met.** Final bridge static: 76 µs/file (2k), 88 µs (10k flat, ratio 1.15), 69 µs (10k tree). Baseline: 103 → 236 µs (ratio 2.3).
- **C3 complete path ≤ 1.25 × CLI — not met.** Final window: 1.18 × (2k), 1.26 × (10k), 1.35 × (tree); quieter #3/#4 window: 1.32 ×, 1.26 ×, 1.28 ×. The remainder is staging the archive copy, two listings, the conflict scan and per-entry URL standardization. Recorded as is; the target was not redefined.
- **C4 no regression — met** (see the recheck above; the solid 7z tree also improved).
- **C5 — applied:** #1, #2a and #3 kept; #4 reverted.

## OR-11: memory after the large 7z pipeline

[`records/mem-final.jsonl`](7zip-adapter-optimization/records/mem-final.jsonl), summary [`memory-summary.json`](7zip-adapter-optimization/memory-summary.json): 3 processes × 3 in-process cycles of create → list → test → extract (→ close sessions for `ArchiveServing`) → 1 s idle, baseline and final, bridge and complete path, all hashes verified. Phase-end `phys_footprint` medians in MiB (spread across processes ≤ 0.7 MiB):

| Variant | Process start | Cycle 1 create | Cycle 1 test | Cycle 1 idle (after close) | Cycle 2 idle | Cycle 3 idle |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Bridge, baseline | 2.4 | 683.0 | 939.6 | 939.7 | 940.1 | 940.2 |
| Bridge, final | 2.4 | 683.0 | 939.6 | 939.6 | 939.8 | 940.1 |
| `ArchiveServing`, baseline | 2.0 | 683.7 | 940.2 | 940.4 | 940.5 | 940.5 |
| `ArchiveServing`, final | 1.9 | 683.5 | 940.1 | 940.3 | 940.8 | 940.9 |

- **Retention starts at creation**, not at the test: ≈ 683 MiB remain after the 7z LZMA2 encoder (64 MiB dictionary match finder) finishes, and the decoder's buffers add ≈ 257 MiB during the test. The 2026-10-03 RAM series shows the same: the static variant sat at 736.0 MiB at the end of creation and 992.3 MiB after the test (`7zip-ram/samples/Large-7z-0-static`). The earlier statement that "growth appears in the test" described the peak, not the start of retention (D-51).
- **Owner: the system allocator, not live objects.** With the process held after the pipeline ([`memory/`](7zip-adapter-optimization/memory), [`Adapter/hold-vmmap.sh`](../../BuildSupport/SevenZip/Benchmarks/Adapter/hold-vmmap.sh)), `vmmap` shows **`Malloc Large (empty)` = 935.5 MiB resident and dirty in 9 regions** (seven 128 MiB segments plus 98, 64 and 5 MiB); `footprint` attributes 935 MB to Malloc Large with 0 B reclaimable; `heap` finds only 1,716 live nodes (262 KB); `malloc_zone_statistics` reports ≈ 0.2 MiB in use. 7-Zip allocates these buffers with `posix_memalign`/`malloc` (`C/Alloc.c`, unpatched upstream) and frees them; the macOS 27 allocator keeps the freed large segments for reuse. `malloc_zone_pressure_relief(NULL, 0)` after every phase released **0 bytes** ([run](7zip-adapter-optimization/memory/bridge-baseline-pressure-relief.jsonl)).
- **M1 met** (cycle 3 − cycle 1 ≤ 0.6 MiB: segments are reused, nothing accumulates). **M3 met** (identical per phase). **M2 not met** (≈ 940 MiB vs a 2 MiB process baseline + 64 MiB). It is not a leak, and the code changes of this round neither cause nor reduce it.
- Not verified: whether the kernel reclaims these pages under real memory pressure (simulating pressure would have affected every process on the shared host), and the macOS 26.0 allocator. A remedy needs a decision outside this round: run large codec operations in a separate engine process, or change upstream allocation (the vendored sources are intentionally unpatched). No public allocator control that releases the segments was found.

## Reproduction

```sh
bash BuildSupport/SevenZip/build.sh /private/tmp/ZF25/SevenZipCore Release
# Baseline tree: git archive HEAD Zforge/Native Zforge/Services Zforge/Models, extracted with a Vendor symlink.
R=BuildSupport/SevenZip/Benchmarks/Adapter/run.py
L=/private/tmp/ZF25/SevenZipCore/libSevenZipCore.a
python3 $R build --name baseline --source /private/tmp/ZF25/src-baseline --static-library $L --output-dir /private/tmp/ZF25/builds
python3 $R build --name final --source . --static-library $L --output-dir /private/tmp/ZF25/builds
python3 $R datasets --output-dir /private/tmp/ZF25/data
python3 $R timing --datasets /private/tmp/ZF25/data --builds /private/tmp/ZF25/builds --output-dir <new> --rounds 7 --variants baseline final
python3 $R selected --datasets /private/tmp/ZF25/data --builds /private/tmp/ZF25/builds --output-dir <new> --rounds 6 \
  --variants baseline final --workloads small2k-store-zip small10k-deflate-zip tree10k-store-zip
python3 $R memory --datasets /private/tmp/ZF25/data --builds /private/tmp/ZF25/builds --output-dir <new> --rounds 3 --cycles 3 \
  --variants baseline final --kinds bridge-static engine-static
python3 $R summarize <records.jsonl>...   # python3 $R summarize-memory <records.jsonl>
```

## Limits

- Bridge and `ArchiveServing` harnesses run outside the App Sandbox and without UI. The sandboxed path is covered by the unit suites in the sandboxed test host (container temporary directory, the D-21 situation), not by these timings. No signed-app/UI extraction timing or full-app RAM run was repeated; the dynamic variant exists only as a harness build, built like the historical one.
- The host was shared with another agent throughout; the final window was more contended than the A/A window. Five to nine samples per cell characterize this host, not universal significance. Warm filesystem cache; outputs on the same APFS volume.
- Memory figures are phase-end `phys_footprint` samples, not continuous peaks (the 2026-10-03 sampler measured those); because the allocator keeps the freed segments, phase-end and high-water values coincide here.
