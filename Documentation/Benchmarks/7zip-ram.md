# RAM total: Zforge + motor 7-Zip

Final execution in **2026-10-03**, macOS 27.0.1 arm64. **36 independent datesets**: two datasets × ZIP/7z × three integrations × three repetitions. All creations, listings, tests and extractions have concluded; SHA-256 checked in all files. Each execution had exactly one measurement window with the real `ContentView`, fixture UI and real `ArchiveServing` engine services. The app didn't load XCTest.

The total CLI includes **Zforge + `7zz`** in the same sample. Native variants include the whole process of Zforge with built-in engine or dylib. The sampler/controller stays out of this family and does not enter in total. Baseline and cleaning are measured with the same process as the app.

## Total peak physical footprint (MiB)

Median of three executions; in parentheses, minimum–maximum of the peaks sampled. `Physical footprint` is the memory attributed to the family of processes by macOS, not the RAM of the entire system.

| Carga | Formato | CLI | Static | Dynamic |
| --- | --- | ---: | ---: | ---: |
| 1 file 256 MiB | ZIP | 95.2 (95.1–95.3) | 94.1 (93.8–94.5) | 94.6 (94.1–94.7) |
| 1 file 256 MiB | 7Z | 737.2 (737.2–737.3) | 992.3 (991.9–992.4) | 992.5 (992.3–992.7) |
| 10.000 files of 4 KiB | ZIP | 107.4 (107.4–108.4) | 153.6 (150.7–153.7) | 155.1 (154.6–157.2) |
| 10.000 files of 4 KiB | 7Z | 492.2 (492.1–492.2) | 554.6 (554.0–555.1) | 555.1 (554.6–555.5) |

**Statics and dynamics were close**, with no significant difference of RAM demonstrated among them in this sample. Compare with CLI depends on the load: ZIP with a large file got close; native integrations used more memory in loads of many files and the accumulated peak of the pipeline 7z large. Do not assign these differences only to the type of linkage.

## Baseline and after closing sessions

Median `physical footprint` during the two seconds of baseline and for three seconds after closing the sessions. It's not leaking measurement of the entire life of the app.

| Carga / formato | Integration | Baseline (MiB) | After cleaning (MiB) |
| --- | --- | ---: | ---: |
| 1 file 256 MiB / ZIP | CLI | 55.7 | 55.7 |
| 1 file 256 MiB / ZIP | Static | 55.5 | 94.1 |
| 1 file 256 MiB / ZIP | Dynamic | 56.1 | 94.6 |
| 1 file 256 MiB / 7Z | CLI | 55.7 | 55.8 |
| 1 file 256 MiB / 7Z | Static | 55.9 | 992.3 |
| 1 file 256 MiB / 7Z | Dynamic | 56.0 | 992.5 |
| 10.000 files of 4 KiB / ZIP | CLI | 55.5 | 95.3 |
| 10.000 files of 4 KiB / ZIP | Static | 56.0 | 86.4 |
| 10.000 files of 4 KiB / ZIP | Dynamic | 55.8 | 87.8 |
| 10.000 files of 4 KiB / 7Z | CLI | 55.9 | 83.0 |
| 10.000 files of 4 KiB / 7Z | Static | 56.1 | 85.8 |
| 10.000 files of 4 KiB / 7Z | Dynamic | 55.9 | 86.0 |

### Where the difference in the big 7z appears

| Integration | Criar: pico | Testar: pico | Extrair: pico | After cleaning |
| --- | ---: | ---: | ---: | ---: |
| CLI | 737.2 | 314.2 | 314.2 | 55.8 |
| Static | 735.8 | 992.3 | 992.3 | 992.3 |
| Dynamic | 736.2 | 992.5 | 992.5 | 992.5 |

> **Correction 2026-10-23 (D-51, ZF-25):** the per-phase series shows the native process already holding 736.0 MiB at the *end* of creation; the test raises this retained level to 992.3 MiB. Retention therefore starts after creation, and the test adds to it. In-process repetition and `vmmap` attribute it to freed engine buffers kept by the system allocator ("Malloc Large (empty)"), stable across repetitions, with ≈ 262 KB of live heap: [7zip-adapter-optimization.md](7zip-adapter-optimization.md#or-11-memory-after-the-large-7z-pipeline). The numbers below are unchanged.

The isolated creation reached almost the same peak in the three variants. The difference in the pipeline native appears in the test step and remains after extraction/closing: about **992 MiB**, versus **56 MiB** in the CLI after their children have finished. This is a memory retention finding to investigate (OR-11). The test does not identify its cause: caches, allocator, object ownership or other hypotheses require profiling. It does not prove leakage, unlimited growth or performance of various operations within the same process.

## Total RSS Peak (MiB)

RSS added can count shared pages in more than one process; is kept separate from footprint.

| Carga | Formato | CLI | Static | Dynamic |
| --- | --- | ---: | ---: | ---: |
| 1 file 256 MiB | ZIP | 161.8 | 160.4 | 160.7 |
| 1 file 256 MiB | 7Z | 803.7 | 1058.5 | 1058.3 |
| 10.000 files of 4 KiB | ZIP | 190.9 | 236.6 | 238.0 |
| 10.000 files of 4 KiB | 7Z | 575.4 | 637.5 | 637.5 |

## Protocol, evidence and reproduction

- [Runner, temporary driver and sampler](../../BuildSupport/SevenZip/Benchmarks/RAM/README.md).
- [Individual results, events, phases and summaries](7zip-ram/results.json). [Full compressed series](7zip-ram/samples) preserves RSS, footprint, process count, parent metrics and presence of `7zz`; the directory contains a CSV.gz per case.
- Large load: 256 MiB, block 512 KiB xorshift64/seed 42 + 512 KiB of repeated zeros 256 times. Small load: 10.000 files of 4 KiB, pseudorandom half, half zeros. ZIP Deflate level 5/two threads/32 fast bytes; 7z LZMA2 level 5/64 MiB dictionary/two threads/32 fast bytes/solid.
- Refs finais: CLI `05d1720`; static `3586384`; dynamic `d0848d1`. Temporary snapshots only normalize the old platform and inject automation; the runner checks the implementation files against the refs. Sources upstream 26.02 are common. The driver/sampler hashes are on JSON.
- Artifacts locais: `/private/tmp/ZforgeFullRAM3`; log final `/private/tmp/zforge-full-ram-run.log`. Temporary releases signed, App Sandbox preserved, arm64/macOS minimum 26.0; this execution is not proof of runtime macOS 26.0 or public distribution.
- The test found D-21: the native walk by the ancestors since `/` failed in the container path. Correction opens the authorized destination root and walks only by descendants with `openat`/`O_NOFOLLOW`. The actual case passed, and both variants had **109 approved tests, zero failures/ignored** (`/private/tmp/ZforgeOutputRootStaticTests.xcresult` and `/private/tmp/ZforgeOutputRootTestsFixed.xcresult`). Previous attempts with failures instrumentation/extraction do not enter the 36 final measurements.

## Limitations

- Requested interval: 5 ms. Median of effective median intervals: **7,60 ms**; maior gap: **22,70 ms**. All creations/tests/extractions had samples; some listings of archive with a file and most cleanings were faster than sampling and are marked without isolated peak. Peaks smaller than the interval can escape.
- We do not add maximums of processes in different moments: each total comes from the same round of consultation. Queries to PIDs are sequential, so the total is a contemporary approach, not an atomic capture of the whole family.
- Measuring window is created explicitly with `ContentView` because the environment suppressed automatic opening. The visual fixture services shall fix the initial status; the listing is not published as thousands of lines in UI. Operations use the real engine, with staging, sessions and cleanup. Do not measure menus, gestures, thumbnails of 10.000 items, not all visual states of the product.
- Data preparation/hash and boot/loader are outside the baseline peak→ post-cleaning. Authorelease pools drain the preparation buffers. Filesystem cache is not emptied; datasets are regenerated in each process, and the order of variants rotates between repetitions.
- It does not measure all system consumption, WindowServer, shared services or global filesystem cache. Three repetitions allow characterizing this load, without establishing universal statistical significance.
