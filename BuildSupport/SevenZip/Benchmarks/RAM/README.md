# RAM total of Zforge and its engine processes

This test compiles three temporary Release copies: anterior CLI (`5c2b960`), static branch and dynamic branch. Inject `driver.swift` only on these copies to start the same `ArchiveServing` calls within the application, including staging and cleaning. No instrumentation is added to the app distributed in the branches. It normalizes arm64 and minimum architecture macOS 26.0 on the CLI baseline.

The instrumentation creates a window of 1100 × 720 with the actual `ContentView` and the already existing fixture UI services, to maintain the initial visual status equal and avoid variable queries to Spotlight. The measured operations use the actual engine of each variant, not `UIFixtureArchiveEngine`. Launch Services starts the app; `AppDelegate` creates the measurement window in a signed build, without XCTest and without separate harness for the engine. Do not measure gestures, menu, preview or the entire interface status catalog.

## Loads and sampling

- A file of 256 MiB: deterministic block of 512 pseudorandom KiB (xorshift64, seed 42) + 512 KiB of zeros, repeated 256 times.
- 10.000 files of 4 KiB: pseudorandom half, half zeros, xorshift64 with seed 42.
- ZIP Deflate level 5, fast bytes 32, two threads; 7z LZMA2 level 5, dictionary 64 MiB, fast bytes 32, solid, two threads. Options pass through the contracts of the app itself.
- Preparation and reading of hashes use autoelease pools; There's a wait for drainage before the baseline. Three repetitions with a new app process for each load/format/variant: 36 Launches. Order of variants rotated by repetition. You don't download cache from the system.
- Window booted before baseline; baseline 2s, create, open/list, test, extract, close sessions and observe more 3s. Hashes SHA-256 and count of all extracted files are checked after the output of the app, out of the measured intervals.
- `sampler.c` runs out of the app process. Each 5 ms consultation `proc_pid_rusage` for RSS and `physical footprint`, traversing all descendants recursively. Totals are added within the same sample, instead of adding maximums of different moments. In the CLI variant, it requires observing at least app + child process.
- It records the use of the main process separately from the total, baseline, peaks per phase, peak between baseline and end of post-cleaning observation and memory after cleaning. Preparation, hashing and boot/loader stay out of this peak. Record effective intervals and number of samples. Phases without samples are explicitly marked; it is not attributed to them a nonexistent peak.

## Run

Requires macOS, Xcode, Python 3.9+, local signature configured in the design and reading of process metrics. The app itself creates a disposable folder in your tmp, generates and confers the loads to maintain access by the Sandbox App, and deletes only that folder when it is finished. The external controller does not read or write the container. The runner and sampler do not enter the bundle and their own use is not added to the total of the app.

```sh
python3 BuildSupport/SevenZip/Benchmarks/RAM/run.py \
  --output-dir /private/tmp/ZforgeRAMRun
```

To separate execution build: add `--build-only` in the first call, then `--reuse-builds` with the same directory. `--repetitions` and `--interval-ms` allow to vary the duration and frequency. `results.json` records phases and events; CSVs preserve the entire time series. Build and launch logs are in the output directory.

## Limitations

RSS added can count shared pages in more than one process. The sum of `physical footprint` represents the memory assigned to the process family and is presented separately; is not the whole RAM of the system nor does it indiscriminately include the global filesystem cache. Discreet Sampling may lose shorter peaks than your interval; the effective frequency and coverage must follow the conclusions. Retention after cleaning includes app and engine caches/allocator. It does not imply leakage without growth in repeated executions in the same process; this test uses new processes for independent comparison.

External reading uses `CLOCK_MONOTONIC` also on the controller; Python 3.9 of macOS uses another source in `time.monotonic`, which cannot be mixed with sampler timestamps. `proc_listchildpids` returns number of PIDs, not bytes; this was verified with a fork/son test before the final matrix. The runner requires observing the process called `7zz` in the CLI variant.

The test found and led to correction D-21: native extraction needs to start from the authorized root. Final comparisons use corrected revisions, recorded in `metadata.refs`; previous microbenchmark results remain historical.
