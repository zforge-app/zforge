# Icon content preview measurements — 2026-10-05

## Workload and acceptance criteria

The reproducible workload requests 256 px previews for 200 real local files: 50 PNG and 50 JPEG images at 2560×1600, 50 three-page PDFs, and 50 text documents bounded to 32 KiB. Source encoding runs outside the main actor and precedes measurement. The disabled preference is the baseline for additional preview work; it does not measure file enumeration, native icon drawing or the entire grid.

Resource acceptance criteria are four service requests at most, two native decoders, one HTML renderer, a 256 px maximum cached raster dimension, and a 256-entry/16 MiB cache. A warm visible area of 32 files must require no new rendering. Tests enforce service concurrency, raster bounds and reuse; dedicated loading tests exercise cache eviction and cancellation. Latency, CPU, process RSS and main-actor response are reported rather than hidden behind machine-dependent test timeouts.

## Isolated executed measurement

Environment: arm64 MacBook Air, macOS 27.0.1 (26A434), Xcode 27.0/macOS SDK 27.0, Debug ad-hoc signed test host. The validation copy uses `io.libor.Zforge.IconPreviewValidation` to avoid collision with other running Zforge builds; production project identifiers are unchanged. Result bundle: `/tmp/zforge-icon-preview-measured.xcresult`, one executed test, passed, zero failures or skips. Raw measurements: [icon-previews-results.json](icon-previews-results.json).

| Measurement | Result |
| --- | ---: |
| Disabled, 200 files | 0.262 ms; 0 renders; 0.000267 CPU s |
| Cold, 200 files | 337.492 ms; 200 renders; 0.636171 CPU s |
| Warm, 32 files | 0.183 ms; 0 additional renders; 0.000185 CPU s |
| Maximum concurrent service requests | 4 |
| Largest raster dimension / allocation | 256 px / 202,752 bytes |
| Main-actor ping, p95 / maximum | 0.0845 / 0.4006 ms; 184 samples |
| Process RSS before / after cold work | 204.80 / 220.95 MiB |
| Process peak RSS | 235.61 MiB |

The main-actor ping uses a detached sampler with a 1 ms sampling cadence, not sleeps to synchronize assertions. CPU/RSS include the test host and native framework allocations; the RSS increase is not a leak diagnosis or an exact cache size. Earlier measurements taken during the full concurrent suite included unrelated archive-test memory and cannot describe thumbnail memory in isolation.

## Reproduction and limits

Run `IconPreviewPerformanceTests` alone with `xcodebuild test`, a macOS destination, a unique result bundle and a local signing identity. Export its `icon-preview-benchmark.json` attachment using `xcresulttool export attachments`. The test creates and removes controlled temporary files and uses the real renderer/service. Full unit and UI results are recorded in [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

This measures service work with an empty application preview cache and repeated cached requests. It is not a cold filesystem-cache benchmark, scrolling frame-rate measurement, production Release measurement, or evidence for Office/video providers, remote resources, huge folders, encrypted/solid archives, or long-session memory. Those workloads require separate actual-use checks.
