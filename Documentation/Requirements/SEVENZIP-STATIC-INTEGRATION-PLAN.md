# ZF-21 — plan static integration of 7-Zip

Data: **2026-10-02**. State: **backend and build implemented in 2026-10-03; external validation and outstanding distribution**. Static linkage was chosen by the user. The user refined the scope for arm64 exclusively and macOS minimum 26.0; x86_64 stays out of support. This plan adopts execution in the app process for the first implementation. The current state continues at [CURRENT-STATE.md](CURRENT-STATE.md), §6; the screening is [TASKS.md](../../TASKS.md#zf-21--native-7-zip-engine-compiled-with-zforge) and [OR-10](OPEN-REQUIREMENTS.md).

## Expected result

The Zforge build compiles the official source code from 7-Zip to arm64 and incorporates the engine to the main executable. The final product performs operations by native calls, without `7zz`, textual output parsing or dynamic engine library. The embedded code is covered by the signature of the executable Zforge. XPC service can be evaluated in a future change; It is not part of this implementation.

```mermaid
flowchart LR
    UI[UI e FileBrowserState] --> Contract[ArchiveServing]
    Contract --> Engine[NativeSevenZipArchiveEngine]
    Engine --> Bridge[SevenZipBridge — Objective-C++]
    Bridge --> Core[SevenZipCore — static C/C++]
```

All these components perform in the Zforge process. Synchronous engine calls stay in workers outside the main thread. the logical isolation of the engine remains in modules and contracts; the app process also assumes the impact of failures native fatals.

## Proposed organisation

| Local | Liability |
| --- | --- |
| `Vendor/7zip/` | Snapshot of official sources and licenses, no local brother checkout files. |
| `Vendor/7zip-provenance.json` | Full version, revision, origin, snapshot checksum and build configuration. |
| `Vendor/7zip-patches/` | Minimal patches separated, with motive and application instruction. |
| `BuildSupport/SevenZip/` | Source manifest, configuration, and incremental build scripts. |
| Target `SevenZipCore` | C/C++ static library with multiformat formats and codecs. |
| `Zforge/Native/SevenZipBridge.h` and `.mm` | Swift-compatible Objective-C interface; Ownership, conversions and callbacks stay in the adapter. |
| `Zforge/Services/NativeSevenZipArchiveEngine.swift` | Implementation of `ArchiveServing`, integration of sessions/policies, execution and cancellation. |
| `ZforgeTests/Fixtures/Archives/` | Small versioned fixtures and reproducible generators for larger scenarios. |

The above names were proposed in plan. The implementation uses the `Build SevenZipCore`, `ArchiveEntry.swift`, `NativeSevenZipBackend.swift` and `NativeSevenZipArchiveEngine` phase in `ArchiveEngine.swift`. `libSevenZipCore.a` is an intermediate build product and is not copied to `.app`. Engine objects, dependencies and temporary files are `$(TARGET_TEMP_DIR)/SevenZip`; the phase declares the final library as output and Debug/Release link that same path. The Xcode script sandbox remains enabled. Public adapter heads do not expose C++ types, 7-Zip interface pointers or CLI syntax to UI.

## 1. Characterize the current backend and prepare migration

- Invent all operations of `ArchiveServing`, fields of `BrowserItem`, session cycle and contracts of §6 of `CURRENT-STATE.md`.
- Register existing tests that actually run `SevenZipArchiveEngine`, distinguishing them from fixtures of UI and textual parser tests.
- Extract only the parts needed to share sessions, navigation/materialization policies and conflicts between backends. Decouple `Entry` structure of `SevenZipListingParser` and separate normalization of CLI reading paths.
- Separate `CompressionOptions` and persistent profiles of translation `commandArguments`: CLI backend keeps its translator; native wins a property translator.
- Keep CLI backend as explicit test reference during migration. No automatic fallback in production shall hide an operation not yet ported or repeat a writing operation after failure.

**Verifiable output:** matrix `operation → contract → test → gap`, with current suite executed and count recorded. Refactorings preliminary tests must be passed before receiving the native engine.

## 2. Embed the sources and build the static library

- Initially use the local version **26.02**, review `f9d78aff31a5f2521ae7ddbdc97c4a8855808959`, to compare with the engine version in use. Version update will be a tracked decision, avoiding mixing backend change with upstream behavior change.
- sell corresponding sources and licenses; build must work from a clone of Zforge without `../7zip`, without external installation and without download during build.
- Derive the multiformat manifest from `CPP/7zip/Bundles/Format7zF/Arc_gcc.mak`, including the required codecs, handlers, and C/C++ dependencies. The official recipe is shared: adaptation to `.a` file is part of this step.
- Delete console entrypoints and discover external plugins. Audit settings, codec logging, booters, and global state changes before incorporating sources into the app process.
- Generate products separated by architecture/configuration in build directories; to align deployment target and SDK with the app. Preserve multithreading and use C/assembly implementations compatible with each architecture.
- Integrate dependencies, inputs and outputs in Xcode for a reproducible incremental build without generating objects within the supplier's sources.
- Ensure that the linker includes objects that record formats/codecs by booters. assess `-force_load` restricted to the engine library or an explicit retention strategy; not apply `-all_load` globally without need.

**Verifiable output:** library and minimum executable linked statically in Debug and Release, with format inventory/reading/writing expected. Check the result with dead stripping enabled. The only supported destination is Apple Silicon (arm64), with macOS minimum 26.0.

## 3. Implementar a fronteira Swift / Objective-C++ / 7-Zip

- Expose opening/closing, properties, selective extraction, testing, creation and updating with typed results, controlled handles and IDs per operation/entry.
- Implement input/output streams, opening/volume callbacks, `IArchiveExtractCallback`, `IArchiveUpdateCallback`, `IProgress`, `ICryptoGetTextPassword` and `ICryptoGetTextPassword2`, depending on the operation.
- Contain C++ exceptions in the adapter; manage interfaces with RII and balance references, buffers and strings. Do not allow exceptions or pointers without Ownership crossing the Swift border.
- Translate `HRESULT` and results per entry for domain errors/notices. Success of the general call does not prove success of all items. Distinguishing missing password, invalid password and corruption when handler provides evidence; do not infer wrong password from any encrypted error.
- Keep password only in memory by session/operation authorized time, without logs, profiles or persistence; release temporary copies controlled by the adapter.
- Serialize use of each instance `IInArchive`, according to the restriction of the official code. Adopt worker by session/operation and token of thread-safe cancellation, including in stream/progress callbacks. A single Swift actor doesn't turn the C++ call into a cancelable.
- Avoid main thread blockages and waiting cycles between native callbacks and asynchronous resolvers. Choose to resolve conflicts in the Swift layer before writing and deliver a plan of destinations to the adapter.
- Limit frequency of progress notifications without blocking callbacks that check cancellation; close a session during work in progress must cancel/wait safely before releasing your handsles.

**Verifiable output:** Small proof of listing, extraction and test of ZIP/7z real, including password, cancellation, failure per entry and closing. Check ownership with memory diagnostic tools in directed cases.

## 4. Port reading, navigation, extraction and validation

- Implement signature/property recognition and opening of related volumes, not only by extension. Fixtures must cover ZIP/7z, RAR read-only, TAR, streams and samples from other recognized groups.
- Convert properties directly to current models, synthesize virtual directories and preserve Unicode names, dates, unknown sizes and match between visible path and engine index. Characterize duplicate names and names with separators/new lines before defining their projection.
- Implement test with `IInArchive::Extract` in test mode and aggregate results per item. Validate sequential multiple selection according to the current contract.
- Port complete/selective extraction and materialization for preview, external opening and nesting. Selecting archive solid may require decoding previous data; do not promise cost proportional only to the selected item.
- Apply path validation and real containment in the destination, including links and components that could redirect writing out of the authorized folder. Reuse conflict decisions and byte limits effectively produced.
- Preserve depth/size limits, session cleaning, materialization read-only, quarantine and protection against publishing obsolete results in the four views.
- Initially keep session staging/cache to maintain current contracts while validating the backend. Removing copies of the source due to I/O requires a proper step, because it changes the relationship between session and external changes of archive. **Done in ZF-55 stage 1 (2026-11-02, D-73):** archives and volumes are read in place through counting `CInFileStream` wrappers; a per-session file fingerprint replaces byte comparison; compressed tar is read through `IArchiveOpenSeq` fed by the outer stream handler on a worker (bounded in-memory pipe, no temporary `.tar`); writes go once into a hidden file beside the original; the bridge exposes solid-block metadata per entry.

**Verifiable output:** reading, extraction, password, nesting, limits, volumes and conflicts performed against the backend native. Compare content and metadata with the CLI reference when applicable.

## 5. Port creation and update

- Map format, method, level, dictionary, quick bytes, solid, threads and encryption for `ISetProperties` and native callbacks. Validate the properties accepted by each handler; do not transpose CLI switches without checking their meaning in the API.
- Implement creation of 7z, ZIP, TAR, XZ, BZIP2, GZIP and WIM. Preserve the TAR layer when streams receive multiple entries/folders, free output names, tags, and already persisted profiles.
- Implement `UpdateItems` to add ZIP/7z single volume: combine existing and new inputs, read authorized streams and write a temporary output. Update archive does not imply writing in the original instead.
- Preserve confirmation, rejection of self-inclusion/volumes/tailed, output validation, replacement of the original only after success and refresh of the open session.
- Cancellation, wrong password, lack of space and failures input/output must preserve the original archive and clear temporarys verifiably. The authorisation shall remain active throughout the operation and the replacement.

**Verifiable output:** round trips of all output formats; criptografia ZIP/7z; update with preserved old entries, including internal folder; original preserved byte a byte in failure scenarios and cancellation.

## 6. Integrate and validate in the app

- Select the backend native in the production composition after completing parity. Migrate integration tests so that they run this backend, with versioned fixtures; CLI binary can be used only as a development reference tool as long as necessary.
- Remove from the bundle the copy phase of `Vendor/7zz`, the discovery of helper and environment overrides of the production backend. Remove runner/parser/CLI translators when no production flow depends on them; Reuse your safety tests on the independent components.
- Validate in signed build the actual stream of permissions, sources/destinations in different folders, related volumes and restart with bookmarks. Access to the same process requires active authorisation; does not grant general access to the filesystem.
- Check Icons, List, Columns, Gallery, multiple selection, menus/toolbar/keyboard, Finder, Recents, preview, drop update and password/conflict/cancellation dialogues.
- Measure opening/listing, extraction and compression with large and many small files: time, maximum memory, temporary space, cancellation and responsiveness. Register hardware, build Release, options, cold/hot cache and staging to interpret comparison; do not require identical byte to byte compressed files when metadata differ.

**Verifiable output:** Features operate on the built signed with the native engine and actual test count recorded. `otool -L`, inventory of bundle and map/linking symbols confirm the absence of dynamic dependency of 7-Zip and the presence of the engine in the executable. Performance comparisons are measured evidence, not presumed condition of static linkage.

## 7. Prepare distribution and conclude contracts

- Run build Release arm64, validate signature/Hardened Runtime and prepare corresponding source, patches, licenses, and reprint/relink instructions. Check reproduction in clean checkout and that an engine modification can be incorporated into a local build.
- Check the distribution of the site with Developer ID, notation and ticket when there is authorized release identity/access. Run in Apple Silicon; the minimum deployment target of the app and engine is macOS 26.0.
- Prepare the Mac App Store variant as required, including Sandbox and review of LGPL/unRAR conditions. Local build and site notation do not confirm acceptance in the store.
- Update `CURRENT-STATE.md` after implementation, reflect the actual evidence in `REGRESSION-COVERAGE.md`, complete ZF-21 only for the validated scope and keep distribution pending in OR-10. Record concrete divergences in `DIVERGENCES.md` if they arise.

**Verifiable output:** the delivered app contains the static engine and operates without executable/external library of 7-Zip. Gates dependent on unavailable credentials, revision or hardware are explicitly pending; no distribution is registered completed only because the local build passed.

## Marks for revision

1. **Proven static build:** reproducible sources, handlers preserved in Release and minimal bridge functioning.
2. **Full reading:** navigate, extract, test and materialize with password, cancellation and limits.
3. **Complete writing:** create all supported formats and update ZIP/7z with preservation of the original.
4. **Production backup:** real integration into the app, verified regressions and withdrawal of `7zz` from bundle.
5. **Distribution:** signature and verified license/relinking materials; external channels only with their specific evidence.

Each milestone must result in a reviewable change of consistent responsibility. The first implementation work is the step 1 followed by the static test of the step 2; the risks linker/recorder and bridge are solved before carrying the entire functional surface.

## Initial evidence of planning in 2026-10-02

- Workspace inspection in 2026-10-02: `ArchiveServing`, `SevenZipArchiveEngine`, `SevenZipProcessRunner`, `SevenZipListingParser`, `CompressionOptions`, `AccessGrantStore`, archives tests and Xcode embedding configuration.
- Sources local officers 26.02: `Format7zF/Arc_gcc.mak`, `Common/RegisterArc.h`, `Common/RegisterCodec.h`, `Archive/IArchive.h` and `IPassword.h`. Record macros use booters; `IArchive.h` prohibits simultaneous calls in the same instance of `IInArchive`.
- The initial stage produced a plan and documentary decisions. She did not perform build, benchmarks, native operation tests, notation or validation of the bridge.

## Execution in 2026-10-03

- Official vendored sources without patches; `.a` arm64 incorporated by `-force_load` restricted. minimum macOS 26.0; no x86_64 dependency.
- Tipped bridge, workers, cancellation, properties, results per item, volume streams, writing/update and implemented permissions/links. UI preserves `ArchiveServing` and its policies.
- Reference CLI: 98 approved tests. Tests passed against the backend native; Final count and artifacts are `REGRESSION-COVERAGE.md`.
- Runner/parser/CLI translator removed; helper is not copied to the app. `Vendor/7zz` remains only as a development reference to generate/compare fixtures, without use by the product.
- Update 2026-11-10 (ZF-74): the reference `7zz` is no longer tracked; `Scripts/fetch-7zz.py` downloads the release that matches the vendored sources. Engine updates follow `Scripts/update-7zip.py` (PRODUCT-REQUIREMENTS, *Engine updates*); the snapshot is 26.06.
- Recompilation and relinking of modified copy of proven engine; instructions in `BuildSupport/SevenZip/README.md`.
- Tests of UI failed to activate the application (Running Background). Runtime macOS 26.0, external access/bookmarks, expanded reading matrix and distribution channels remain in OR-10. Do not publish or mark notation/store completed on the basis of this local build.
