# Global tag discovery enabled/disabled — 2026-10-06

## Result

Disabling the corrected global tag catalog reduces startup CPU almost to zero, with a small memory difference in the measured window. The experiment uses production source `57ded5f` and an isolated diagnostic snapshot. Application source in the working checkout remains unchanged, and the normal enabled bundle is left running afterward.

| Metric | Global catalog enabled | Global catalog disabled |
| --- | ---: | ---: |
| Mean CPU, percent of one core | 18.279% | 0.091% |
| Mean physical footprint | 94.87 MiB | 91.49 MiB |
| Highest recorded lifetime peak physical footprint | 107.74 MiB | 104.50 MiB |
| Mean of the two window maximum RSS values | 172.48 MiB | 161.66 MiB |

The measured CPU difference is approximately 18.19 percentage points (99.5% lower when disabled). Mean physical footprint differs by **3.38 MiB**, about **3.6%** of the enabled value. RSS is a separate metric and must not be substituted for physical footprint. The remaining cost of this feature in these startup windows is predominantly CPU while discovery runs; the comparison does not establish its final retained index size or full-Home completion time.

## Scope of disabling

Only the temporary snapshot's `FinderTagCatalog` is changed: a constant false diagnostic guard returns from `start`, `refresh` and `observe`. Consequently the global catalog does not recursively discover files, start its Spotlight query, monitor FSEvents, collect observed items or publish favorite/global tag names. Both disabled browser observations show `No tags` in the sidebar. Recents, native authorization, archives, local file metadata/tag reading, tag editing code and other app services remain unchanged. This isolates the global catalog responsible for startup scanning; it does not remove every tag-related xattr read from the application.

The exact four-line diagnostic change is preserved as a patch in [the results JSON](tag-discovery-ab-results.json). It is not a new product setting or permanent feature removal. The source snapshot and disabled build are under `/private/tmp/zforge-tags-ab-20261006`; the enabled app is the previously validated delivery build with the same production code.

## Workload and measurement method

One foreground browser in **Recents/List**, no selection or interactions during collection, existing Home authorization and the same user preferences/data. Close each app normally before the next launch; only one Zforge process is measured at a time. The diagnostic build completes before measurement, with no concurrent build or test runner introduced. Four cold-process launches run in **enabled / disabled / disabled / enabled** order to counter simple order/cache drift. Filesystem caches are warm and not flushed; real Home contents and other system work are not frozen.

Collect 180 samples at 250 ms per launch, approximately 45 seconds, using [app-resource-sampler.c](../../BuildSupport/Diagnostics/app-resource-sampler.c). It reads process CPU, RSS, footprint, process age and lifetime peak footprint through `proc_pid_rusage`. CPU/start ticks are converted using `mach_timebase_info`, 125/3 on this machine; CPU accounting uses the calibration established in [the startup investigation](startup-tag-scan.md). Lifetime peak accounting captures the process's earlier footprint peak even when instrumentation starts after the browser appears.

The intended analysis interval was age 10–40 seconds. The first native launch/instrumentation setup captured its first sample at age 12.44 seconds. Before comparing enabled/disabled values, the common analysis window was set to **15–40 seconds of process age**, without extrapolating missing early data. All four captures cover that window. CPU is the integrated delta of user + system CPU time divided by monotonic elapsed time between the first and last selected sample. The summary is the arithmetic mean of the two per-variant windows; the lifetime peak column is the largest process peak of the two repetitions.

| Launch | Variant | Window elapsed | CPU | Mean footprint | Window max RSS | Lifetime peak footprint |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | Enabled | 24.622 s | 17.258% | 94.82 MiB | 172.22 MiB | 107.41 MiB |
| 2 | Disabled | 24.628 s | 0.084% | 91.46 MiB | 161.13 MiB | 104.50 MiB |
| 3 | Disabled | 24.634 s | 0.097% | 91.52 MiB | 162.19 MiB | 104.25 MiB |
| 4 | Enabled | 24.852 s | 19.299% | 94.92 MiB | 172.73 MiB | 107.74 MiB |

The JSON preserves all **720 numeric samples**, process identifiers, selected window ages/counts, protocol, diagnostic patch and sampler SHA-256. Raw stack samples remain local because they can contain user/environment paths. Two enabled stack samples identify `TaggedFileScanner`; the disabled stack sample contains neither that scanner nor `FinderTagCatalog`. Native observations confirm the same screen and mode in all launches and the expected global-tag difference.

## Reproduction and limits

Create an isolated `git archive 57ded5f` snapshot, apply the preserved patch there, and build Debug with `xcodebuild` using a separate temporary derived-data directory. Keep the normal enabled build from the same source. Compile the sampler with `clang BuildSupport/Diagnostics/app-resource-sampler.c -o /private/tmp/zforge-app-resource-sampler`; launch one variant through the native app, then run `/private/tmp/zforge-app-resource-sampler <pid> 250 180 > <series.csv>`. Use the specified order, screen and process-age window. Never apply the disabling patch to production as part of this measurement.

Environment: macOS 27.0.1 arm64, Xcode/SDK 27.0, target macOS 26.0, Debug. The disabled build succeeds. Initial preparation failed because the host Python lacks `tarfile.extractall(filter=...)`; extraction was redone with the system tar before building. That failed preparation produced no comparison measurements.

These are four executed diagnostic launches, not application unit/UI test cases. No test suite, archive operation, Release measurement, scrolling/frame pacing, large-tag-count workload, external/network scope or full-Home completion/idle validation is claimed. The disabled app is already effectively idle in the selected interval; the enabled app is still discovering files. Two repetitions per condition establish the observed difference but not a statistical confidence interval or a long-session memory bound. OR-19 remains open for those independent checks.
