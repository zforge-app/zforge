# ZF-43 / D-47 — Direct Siri archive discovery fails before App Intent dispatch

Status: **root cause identified in Siri's planner traces; two-step conversational opening implemented and natively verified on build 25 (2026-10-12/13); single-utterance opening remains blocked inside Siri's own app-entity search**. Recorded 2026-10-12 at the user's request; continued on `codex/apple-intelligence`. Related: ZF-43, OR-20, D-47.

## Root cause from planner traces — 2026-10-12

System logs of Siri's planner (`intelligenceflowd`, category `PlannerSupport`, and the search service `searchtoold`) were not part of the earlier comparisons. They show the same decision sequence for every recorded production and Probe request:

1. The `Open` tool succeeds through **Tier 1 (system.open schema)** only when it already has an entity. Every recorded Tier 1 success — Probe 17:20:22 and 17:42:48, and the new controls below — has `extractToolContext … onScreenEntities ≥ 1`: the entity came from the visible, annotated window, not from a query.
2. With `onScreenEntities: 0`, the planner runs `SearchTool agenticSearch`. Its app-entity branch (`isAppEntitySearch=1`) queries CoreSpotlight with filters including `(_kMDItemBundleID="com.apple.*" || _kMDItemAppEntitySchema=* || kMDItemFileProviderID=* || _kMDItemFileName=*)` and returns **0 items** for both Zforge and the Probe, although Spotlight's own UI finds the same donated entity. A read-back of the Probe's own index confirms the item carries `_kMDItemAppEntitySchema=files.file`, `_kMDItemAppEntityTypeIdentifier=ProbeEntity`, bundle ID and title, so the visible filter is satisfied; the remaining filters are redacted (`<private>`), and the semantic pipeline (`spotlightknowledged`) queues no work for these donations. The exclusion happens inside Apple's search service, before any app query — which is why no authored query or perform was ever retained.
3. When the entity search is empty, phrasings such as “In Zforge, open the archive named Vega Demo.zip” call the app's **SearchInApp** tool, which failed with `No search-in-app schema (system.searchInApp or system.search) registered for bundleId: io.libor.Zforge` (18:09:05). This is the source of “I can't search within Zforge”. Other phrasings fall back to Tier 2, which only launches the app (“opens only Zforge”), or to file-not-found.

Registration, availability annotations, the hidden compatibility schema, input modality and language are therefore not the deciding boundary for these requests. Named-index donation follows Apple's guidance and is not changed.

## Implemented resolution — build 25

Zforge adds a macOS 27 `@AppIntent(schema: .system.searchInApp)` action, **Search Archives** (`SearchZforgeArchivesIntent`). It opens a results window, `Search: “term”`, listing the direct archives in allowed automation folders whose names contain the term, in all four view modes, with the existing onscreen entity annotations. A single result is selected. The follow-up “Open it” then resolves the onscreen archive through Tier 1 and the existing `OpenZforgeFileContentIntent`, which still validates the target and live consent. Search terms never authorize paths. [Behavior](CURRENT-STATE.md#siri-in-app-archive-search--2026-10-13); [evidence](../Benchmarks/siri-routing-reproduction.md#planner-traces-and-in-app-search--2026-10-12-to-2026-10-13).

## Remaining limit

A single utterance such as “Open Vega Demo.zip in Zforge” still depends on Siri's app-entity search returning the donated entity, which it currently does not for Zforge or the minimal Probe. No public API or documented requirement explains the exclusion; record it as an Apple-side boundary, revisit on later macOS releases, and consider a Feedback Assistant report with a sysdiagnose captured immediately after a refusal.

## Continuation branch and delivery decision

- **Development branch:** `codex/apple-intelligence`.
- **Branch source:** `main` at `2b35eb9`, with the complete current Apple Intelligence implementation, tests, diagnostic variants and evidence preserved before the MCP-only delivery split.
- **Delivery decision, 2026-10-12:** deliver the validated MCP on `main`; keep App Intents, native archive-entity discovery/indexing, onscreen context and Siri diagnosis on this branch for future continuation. The original native shortcut actions are part of the deferred Apple integration too.
- Shared filesystem/archive operations, contextual MCP folder consent and redundant-grant consolidation remain in the MCP delivery. Existing folder grants and unrelated 21-language localization work must be preserved.
- This issue remains open. Deferring the branch does not establish Siri, selected-context or saved-compatibility acceptance. Reconcile future branch integration against the MCP-only `main` contract; do not reintroduce deferred features without their recorded acceptance work.

## Original problem and impact

Siri refuses direct requests to open an indexed, authorized archive in Zforge, reporting that it cannot search inside the app or cannot find the file. The captured failing intervals contain no authored entity query or open-action invocation from the installed application. Opening only the app does not satisfy the requested behavior.

The archive is discoverable through Spotlight and opens through native system dispatch, revealing its contents. Saved-shortcut invocation has separate user-reported success. These passing surfaces do not establish direct conversational Siri acceptance.

The minimal Intent Probe has accepted voice and typed executions, but later requests also fail in that control. The evidence does not establish a defect unique to Zforge, a voice-only requirement, or a specific Apple defect.

## Environment and prerequisites

- macOS 27.0.1, build 26A434; Xcode 27, build 27A266a, macOS 27 SDK.
- Signed installed Zforge build 23; deployment floor macOS 26.0. The modern `files.file` / `system.open` integration requires macOS 27.
- Latest diagnostic: installed Intent Probe build 8, with one bundled synthetic ZIP and modern/hidden compatibility opening actions.
- English requests in fresh native Siri conversations. Record effective language and app state for future comparisons; do not assume they stayed unchanged after user-driven language changes/restarts.
- Synthetic `Vega Demo.zip` directly inside an already-authorized Documents root, containing `Readme.txt`: 179 bytes, SHA-256 `2d61fb60522979437018014b296ef2d75f5ed0ba8917a6146f92c7d9620e2082`.
- The app has published its archive entity. No additional grant is required for this reproduction; MCP enablement is not a Siri integration requirement.

## Reproduction

1. Launch installed Zforge with the fixture and existing automation grant available. Leave it on Recents; do not pre-open the archive.
2. Confirm indexing independently. Keep automatic dispatch outside the subsequent Siri observation interval.
3. In a new native Siri conversation, type `Open Vega Demo.zip in Zforge`.
4. Inspect the response, Zforge window and authored `ArchiveDiscovery` query/perform events.
5. In another fresh conversation, type `In Zforge, open the archive named Vega Demo.zip`.

**Expected:** Siri resolves the authorized entity and executes `OpenZforgeFileContentIntent`; Zforge opens `Vega Demo.zip` with `Readme.txt` visible. Execution still validates the target and live authorization.

**Observed:** the first request receives `I couldn't find the file "Vega Demo.zip" on your Mac. Please check the name and try again.` The explicit request receives `I can’t search within Zforge, and I couldn’t find a file named Vega Demo.zip on your device.` Zforge remains on Recents, without archive contents or an authored query/perform. Correctly transcribed spoken requests previously failed too; extension misrecognition does not explain every failure.

One extensionless typed request retained only the request, without a response or opening. Its conversational outcome is **inconclusive**, not a pass or a confirmed refusal.

## Confirmed evidence and limits

| Check | Result | Boundary |
| --- | --- | --- |
| Installed Zforge 23 name/Spotlight system dispatch | Passed; both openings reveal `Readme.txt`, reconfirmed on 2026-10-12 | Current resolution, indexing and system execution work independently of Siri routing |
| Probe 6 voice after user language change/restart | Modern perform and marker confirmed | Already-open acceptance; no unique recovery cause or cold-start acceptance |
| Probe 6 typed full-name request | Seven identifier results and new perform at 17:42:48.480 local | Typed Siri can execute App Intents; later success is not guaranteed |
| Probe 7 explicit macOS 27 declarations | 10 unit cases / 12 executions and three native cases pass; Siri refuses | Availability is a tested hypothesis, not an isolated cause |
| Restored Probe 6 / newer wildcard Probe 8 | Both refuse; build 8 passes 10 unit cases / 12 executions and two native cases | Rollback does not isolate availability as the cause |
| Contextual Probe request | Response names `Test Archive.zip` without that name in the prompt; action does not run | Identifying displayed content does not establish entity annotation or action binding |

Production build 22's full regression baseline is 352 distinct cases / 528 executions; build 23's affected suites are 49 / 57. These are historical runs, not executions performed when recording this issue. Known selected-annotation failures and saved String-target compatibility invocation remain separate unresolved gates; no assertion is relaxed or counted as passing here.

## Hypotheses and blocked comparison

A read-only audit finds temporary diagnostic applications registered alongside the installed Probe. The Debug test host has a distinct TestHost bundle ID/display name but internal product name `Intent Probe`. Wrong-bundle selection is plausible but **not demonstrated by retained Siri traces**. Older absent registration records also do not establish causation.

The user authorizes unregistering exactly three temporary diagnostic bundles. Automatic approval rejects the command before execution, including after explicit authorization, because it prohibits global Launch Services database mutation. No registration changes or indirect cleanup/reset occur. This blocks that specific comparison; it does not prove cleanup would fix Siri.

Treat hidden compatibility actions, content types, availability, indexing timing, input mode and system state as separate variables. Do not change production schemas, permissions or test expectations solely to fit an unconfirmed hypothesis.

## Investigation and closure criteria

- Establish a reproducible comparison with recorded build, effective language, app state, indexed fixture and fresh conversation. Correlate queries, performs and contents; exclude automatic dispatch and unrelated test-host processes.
- Identify the responsible boundary before choosing a fix. Preserve transported file identity, the macOS 26 route, live consent, revocation/deletion cleanup and bounded authorized discovery.
- Reproduce the identified failure in meaningful automated coverage where testable; demonstrate failure before the fix and success afterward without weakening contracts.
- Verify typed and spoken direct opening separately, including already-open/app-closed states and repeated invocation. Require `Readme.txt`, not activation or a conversational acknowledgement.
- Re-run affected resolution, publication lifecycle and installed Spotlight/opening regression coverage. Keep selected-context and saved-compatibility acceptance separate.
- Synchronize current state, OR-20, D-47, tasks and regression evidence before closing.

## References

- [Detailed reproduction and diagnostic history](../Benchmarks/siri-routing-reproduction.md).
- [Structured results, metadata and source fingerprints](../Benchmarks/archive-file-schema-results.json).
- [Integration contract](AGENT-INTEGRATION-PLAN.md).
- [Minimal control and preserved variants](../../BuildSupport/Automation/IntentProbe/README.md).
- Production: `Zforge/Automation/ZforgeFileArchiveEntity.swift`, `ZforgeIntents.swift`, `ArchiveSpotlightIndex.swift`, `ArchiveFilePublication.swift`.
- Installed harness: `BuildSupport/Automation/IntentProbe/ProbeSystemTests/ZforgeDispatchTests.swift`.

Raw logs/result bundles are temporary; some pre-restart artifacts are absent. Verify artifact availability and fresh execution independently of historical counts. External reports must exclude security-scoped bookmark payloads, personal file contents and unrelated Siri history.
