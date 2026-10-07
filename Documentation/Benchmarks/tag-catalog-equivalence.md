# ZF-42 — Differential correctness and accepted implementation

On 2026-10-06, the user authorizes implementation after broader correctness validation. The incremental restoration plus bounded background visibility implementation passes the finite differential matrix below and the full affected regression suite. The review also finds and corrects two preexisting discovery defects. This is evidence for the characterized contracts, not a universal proof of equivalence or complete application performance approval.

## Reference, independent oracle and intended differences

The original baseline is Git commit `fd1baccaf9841b63cea1288c78c051445f17749a`. Both original baseline and initial combined code omit a visible filename beginning with a combining mark when its parent is the discovery root. Both also fail offline reconciliation when the device-relative watcher receives a logical system/directory alias instead of its physical path. These are contract violations; preserving them would invalidate correctness acceptance.

The accepted differential reference keeps the baseline catalog, scanner, persistence and native traversal algorithms, with **one explicit common repair: current `TagJournal.swift`**. Both builds therefore monitor physical paths correctly. The reference still has the independently characterized Unicode scope-boundary defect. Exactly `A/\u0301accent.txt` is recorded as the known reference omission: the current catalog must include it, and every other published path, tag, color and persisted record must match. No arbitrary difference is tolerated. Both raw production rescans must match the entire oracle, including that Unicode filename, because the original omission occurs in catalog scope filtering rather than raw traversal.

[The coordinator](../../BuildSupport/Diagnostics/tag-catalog-equivalence.py) computes expectations through independent POSIX traversal, hidden flags and binary-plist xattr decoding. It imports no production scanner or visibility policy. The two [native workers](../../BuildSupport/Diagnostics/TagCatalogEquivalence.swift) use actual production catalog, persistence, FSEvents and file metadata sources under Release compilation. Paths and fixture metadata are controlled; application/user storage is untouched. Source commits, explicit overrides, all eight production-source hashes, compiler commands, harness hashes and reused binary provenance are in [the complete results](tag-catalog-equivalence-results.json).

## Executed matrix

**76 checkpoints pass: 152 native catalog comparisons and 152 fresh production rescans.** Every current checkpoint must match the complete independent oracle. Checks cover published per-tag paths, aggregate colors, drained work, persistence and completeness; the deliberately canceled worker additionally must publish no stale record and must serialize retirement before restart. Cancellation's in-memory fixture does not claim a new persisted checkpoint.

- Cold completion and quiet cached reuse, with zero recursive scans for the quiet case.
- Symbolic and hard links with target edits and cleared tags outside monitored lexical scopes, without recursive fallback.
- Offline edits, moving across roots, deletion, clearing tags, new files, new directories and tagged folders.
- Dot-hidden and `UF_HIDDEN` items/ancestors, hide/unhide transitions and a hidden directory becoming visible; package metadata with excluded package contents, long names, newline and Unicode filenames, multiple labels and colors.
- Live tag edits/removal, root visibility changes and injected dropped-history reconciliation.
- Separate grants, additional grants and stopping/reopening between grants. Unauthorized sibling and external scopes remain excluded.
- Invalid schema, replaced inode, invalid journal identity, future/missing cursors, corrupt JSON and obsolete generation-3 caches. Staged migration additionally verifies that rebuilding one granted scope cannot silently upgrade ungranted obsolete data into a reusable generation-4 checkpoint.
- Four deterministic mutation seeds (`7`, `19`, `43`, `101`), each with 12 steps alternating offline/live delivery: 10 tag assignments, 6 clears, 5 deletions, 12 moves and 15 visibility operations. Missing-source move/delete steps are intentional boundary cases and remain recorded.
- Controlled cancellation during a paused scanner, immediate restart and deliberate stale publication by the retired scanner: two scan calls, maximum one active scanner, no stale result.

Offline fixture writes use an independent native notification fence before startup; completed startup is checked immediately after `waitForIdle`, without polling for a corrected result. Live updates use a bounded condition fence because native delivery is asynchronous. No retry or timeout increase is used to hide a failed case. Native notifications may coalesce a marker into a recursive ancestor event; the fence accepts that documented event meaning after clearing prior history.

## Reproduced defects and delivered corrections

1. **Unicode boundary (D-44).** Swift grapheme prefix comparison combines a slash with a filename's initial combining mark. The new boundary check uses the POSIX separator byte, with a canonical-equivalence fallback for differently encoded root names. Sibling exclusions and original path identity remain. Before correction, `/private/tmp/zforge-zf42-unicode-before.xcresult` fails two new tests (eight issues); the unchanged remaining tag cases pass.
2. **Physical journal mapping (D-45).** `TagJournal.describe` resolves the physical POSIX path before deriving the device-relative watch path. Saved authorization identity and published events retain their logical spelling. Failed physical resolution enters existing conservative fallback. The native alias test fails before correction in `/private/tmp/zforge-zf42-alias-before.xcresult`; a native probe confirms the logical `/var` spelling produces `RootChanged` while `/private/var` receives actual file events.
3. **One-time repair of existing indexes.** Generation advances from 3 to 4 without changing the JSON record layout. Earlier snapshots may contain omissions or cursors advanced by a broken alias watcher. They must rebuild once; later valid generation-4 launches reuse their checkpoint. The obsolete-generation characterization fails before the bump in `/private/tmp/zforge-zf42-generation-before.xcresult`. Separate grants cannot preserve obsolete ungranted scopes as current data.

Initial diagnostic infrastructure failures are retained under `/private/tmp/zforge-zf42-equivalence-{1,2,3}`: Python's macOS build lacks xattr methods, and the first fence assumed leaf delivery rather than recursive coalescing. The coordinator uses direct POSIX xattr calls and an event-semantics fence. Original cold Unicode and offline alias failures remain in `equivalence-4/results.json` and `equivalence-6/results.json`; they are not accepted runs. The initial 72-checkpoint run predates the generation bump; the later 73-checkpoint run adds obsolete recovery; the accepted 76-checkpoint artifact also covers staged obsolete migration. Source hashes prevent reuse of binaries after production/harness changes.

## Regression and build evidence

The final `/private/tmp/zforge-zf42-equivalence-regression.xcresult` passes **257 distinct unit cases / 348 unit executions and three serial UI cases**, or **260 distinct cases / 351 executions total**, with zero failures or skips. The four new unit cases cover eight scope-boundary parameters, actual cold/cached Unicode discovery, native directory-alias monitoring and obsolete-cache invalidation. Existing expectations are not deleted, loosened or disabled. [Before/after test summaries](tag-catalog-equivalence-test-results.json) preserve the failures above and the final actual counts.

The unchanged UI cases are `testTagEditorIsSharedByToolbarAndContextMenu`, `testIconModeTagContextMenuPreservesSelection` and `testTagContextMenuInGalleryAndColumns`. They exercise bounded tag editor/menu flows across Icons, List, Columns and Gallery; they do not establish every visual/accessibility condition. The unchanged `FileOperationServiceTests` priority-inversion runtime warning remains recorded separately from passing functional results.

The final application Release build succeeds with coverage disabled; strict deep signature verification succeeds. Host: arm64 MacBook Air, macOS 27.0.1, SDK/Xcode 27.0, deployment target macOS 26.0. Build/signature success is separate from executed functional and performance evidence.

## Reproduction and remaining boundaries

```sh
caffeinate -i python3 BuildSupport/Diagnostics/tag-catalog-equivalence.py \
  --output /private/tmp/zforge-zf42-equivalence-new
```

Use a fresh output name; native FSEvents access is required. The diagnostic records all outcomes before assertions and keeps fixture/checkpoints separate from production storage. `--reuse-builds` is permitted only after manifest verification of reference, overrides, source and harness fingerprints.

The accepted matrix includes actual filesystem events and injected recovery conditions on the host's filesystem. It does not simulate a torn atomic write, real journal pruning/ID wrapping, process termination at every I/O instruction, every permission/volume condition or arbitrary adversarial concurrency. Existing unit recovery/deferred-access contracts complement it. Full signed application startup/RAM/frame pacing at 10,000 records, 10,000 distinct labels, high link density, long sessions, truly cold filesystem caches and macOS 26 runtime remain open. Exact-final Release workload measurements are recorded in [the optimization report](tag-catalog-optimization.md).

**Exact-final performance:** all three accepted Release reopens finish below 2 s at 0.820065 / 0.857169 / 0.733745 s; index remains 1.259 MiB. The full controlled cold fixture is additionally measured at a median 35.224 s. These results use the same accepted production fingerprints; full-app and real-Home cold conditions remain unmeasured. [All 18 invocations and reference definition](tag-catalog-optimization.md#release-acceptance-after-correctness-repairs--2026-10-06).
