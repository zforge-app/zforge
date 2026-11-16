# 7-Zip: CLI, static and dynamic linkage

> **Superseded for adapter costs (2026-10-23, ZF-25):** these times predate D-21. Re-measured with current code, native extraction of the 2,000-file load was +44 % over the CLI, and 2.5–3.2 × at 10,000 entries, because of an O(n²) bridge lookup. After the ZF-25 fixes, bridge extraction is at CLI parity. See [7zip-adapter-optimization.md](7zip-adapter-optimization.md). The linkage conclusion (static ≈ dynamic) still holds there.

Execution in 2026-10-03. Branches requested: `feat/7zz-static-linking` and `feat/7zz-dinamic-linking`; Git does not allow `:` in the name. Static reference: `0261322`, on official sources 26.02 (`c90da4d`). The dynamic variant maintains the same bridge and policies, but incorporates `libSevenZipNative.dylib` in `Contents/Frameworks`, signed by `CodeSignOnCopy`. Dynamic implementation does not automatically change the choice of product distribution.

## Method and reproduction

Same core suite of the previous round: ZIP Store (`x=0` / `-mx=0`), create, list, test and extract. Deterministic data: a file of 64 MiB (sequence 0–255 repeated) and 2.000 files of 256 B (same sequence). Three repetitions, heated cache, order CLI/static/repetition rotated dynamics. Hashes SHA-256 from the extracted files checked out of the timers: all coincided in all 18 executions.

Host macOS 27.0.1 arm64; Apple Clang 21.0.0, SDK 27.0; native O2, minimum macOS 26.0. The CLI is the official `Vendor/7zz`. Review, torque/bridge hashes, individual measurements, RSS and medians are [7zip-linking-results.json](7zip-linking-results.json). The results of this execution replace the comparison of two variants for current comparison, keeping that round as historical evidence.

- [Harness Objective-C++](../../BuildSupport/SevenZip/Benchmarks/native.mm) common to both integrations.
- [Runner Python](../../BuildSupport/SevenZip/Benchmarks/run.py) compiles both harnesses, generates data and compares it with CLI. It does not require external Python libraries.
- Compile static release in the corresponding branch and preserve its `.a` in DerivedData separate. Compile Dynamic Release in the other branch and preserve the signed dylib of the bundle. Paths are passed explicitly to the runner, allowing it to run on both branches.

```sh
python3 BuildSupport/SevenZip/Benchmarks/run.py \
  --static-library /private/tmp/ZforgeNativeRelease/Build/Intermediates.noindex/Zforge.build/Release/Zforge.build/DerivedSources/SevenZip/libSevenZipCore.a \
  --dynamic-library /private/tmp/ZforgeDynamicRelease/Build/Products/Release/Zforge.app/Contents/Frameworks/libSevenZipNative.dylib \
  --output-dir /private/tmp/ZforgeThreeWayBenchmarkRepeat
```

The output directory needs to be new. Registered execution artifacts: `/private/tmp/ZforgeThreeWayBenchmark`, log `/private/tmp/zforge-three-way-benchmark.log`. Every extraction is done in separate output directories.

## Median in milliseconds

| Data | Integration | Criar | Listar | Testar | Extrair |
| --- | --- | ---: | ---: | ---: | ---: |
| 64 MiB / 1 file | CLI | 26,075 | 3,411 | 11,225 | 25,324 |
| 64 MiB / 1 file | Static | 23,463 | 0,500 | 8,735 | 26,374 |
| 64 MiB / 1 file | Dynamic | 24,244 | 0,527 | 8,712 | 22,779 |
| 256 B / 2.000 files | CLI | 29,769 | 8,122 | 7,289 | 121,475 |
| 256 B / 2.000 files | Static | 22,370 | 2,009 | 4,070 | 160,208 |
| 256 B / 2.000 files | Dynamic | 22,479 | 2,051 | 4,124 | 163,565 |

Static and dynamic had close times in operations with many files: dynamic/static difference of approximately +0,5% in creation, +2,1% in listing, +1,3% in test and +2,1% in extraction. With only three samples, small differences do not establish superiority or a reliable estimate of the penalty caused by the linkage. In small files, native extraction was approximately 32% (static) and 35% (dynamic) above CLI. The native path also imposes its destination checks and metadata; the difference does not isolate the linker effect.

## Limitations of the interpretation

- It does not include staging Swift, UI, sandbox, reading compressed with other methods, cold cache or complete operation of Zforge. Both natives use the same bridge; in the static it is compiled in the harness, in the dynamic comes from the dylib of the app.
- Native phase times begin after process and loader start. The CLI includes the initialization of a command process and discards the text listing process at `/dev/null`, without measuring the old Swift parser. Therefore, the advantage of listing is a comparison of this protocol, not of isolated linkage.
- `process_total_s` records the entire process of native harnesses, including loader and source assembly. The first execution was much slower (static ~435 ms, dynamic ~538 ms on the big dataset), while the following were ~55–66 ms. This is neither app launch benchmark nor proof of the isolated cost of dylib. Do not assign these outliers only to linking.
- RSS native is the cumulative peak of the four-operation process; RSS CLI is measured by process/operation. They do not represent full application memory consumption.
- Absolute times of creation/listing of small files varied greatly from the previous round. State of the filesystem/cache and hash checks outside the timers may change the conditions of the next phases; only compare the three variants of this round, without inferring a code gain since the previous measurement.
- Dynamic debug: 108 tests approved, 0 failures, 0 ignored in `/private/tmp/ZforgeDynamicTests.xcresult`. Compiled dynamic release; `otool` confirmed `@rpath/libSevenZipNative.dylib`, dylib arm64 with `minos 26.0`, and `codesign --verify --deep --strict` validated app and library with Apple Development signature. The static version has the same 108 tests and release tests in the regression matrix. UI, runtime macOS 26.0 and public distribution remain pending.
