# Zforge — tracking of activities

## 21-language localization expansion — 2026-10-11 (implemented; UI acceptance blocked)

Implement the 21 user-approved localizations recorded in LOCALIZATION.md. Delivered: complete 415-key catalog in all 21 languages, persisted autonym-based language choices, regional/system matching, Chinese script selection, service bundle mapping, project declarations, readable English symbolic errors and grammatical variations for ten count/confirmation keys in five languages. Own drafts were completed before authorized Google/DeepL refinement; native terminology and critical warnings were reviewed. Exact-final focused tests pass 11 cases / 87 executions. Full regression executes 335 cases / 509 executions; the seven failing tag-persistence cases also reproduce with localization changes excluded in a temporary control. Native Settings/menu/relaunch acceptance is blocked before execution by macOS Enable UI Automation authentication. Exact results and verification gaps are recorded in REGRESSION-COVERAGE. The user authorized a local localization commit on 2026-10-11; unrelated concurrent changes are preserved outside its scope. No claim of independent native linguistic review or complete visual/accessibility polish.

Updated at **2026-10-07**. This list preserves the requests raised in this conversation. `Documentation/Requirements/CURRENT-STATE.md` describes the existing behavior; `Documentation/Requirements/OPEN-REQUIREMENTS.md` meets still open requirements; `DIVERGENCES.md` has gaps and conflicts. The user confirmed D-01, D-03, D-05 and D-06 as OK. Column drag and preview was exercised in the app; the remaining to-dos remain identified below.

| ID | Activity | State | Divergence |
| --- | --- | --- | --- |
| ZF-01 | Create guidance for agents, source of truth and record of divergences/tasks | Completed in this documentary review | D-07 a D-12 |
| ZF-02 | Create and apply new application icon | completed; user confirmed | D-01 |
| ZF-03 | Restore column resizing by drag | Implemented and exercised at List/Columns | D-02 |
| ZF-04 | Implement zoom by shortcuts `⌘+` and `⌘−` | completed; user confirmed | D-03 |
| ZF-05 | Fix repeated items in Recents | Completed: real identity and exclusion of internal staging, with unit tests and UI | D-04 |
| ZF-06 | Align secondary menu and `•••` button to contextual matrix of actions | Matrix completed and confirmed; main action of toolbar in Recents implemented in ZF-10, with actual execution still pending | D-05, D-06, D-12 |
| ZF-07 | Allow to drag preview splitter with 300 pt initials | Implemented and exercised in all four modes | D-08 |
| ZF-08 | Cover existing contracts and refactor architecture without changing behavior | completed; 80 unit tests and 11 cases of UI approved, with manual limits tracked | Prevention of regressions; does not resolve D-10 to D-13 automatically |
| ZF-09 | Centralize and index requirements to `Documentation/Requirements` | completed; documented sources of requirement, indices and continuous maintenance | Documentary organisation and regression prevention |
| ZF-10 | Solve OR-01 to OR-05: guide, language of sizes, operations in Recents, alignment of Columns and Finder integration | updated code and documentation; OR-02 and OR-03 still require visual/operational verification, and OR-04 was partially checked at ZF-11. OR-05 was already on commit `268e8c8` | D-10 a D-13, C-06 |
| ZF-11 | Rename connection action for Remote and correct initial indentation of Columns | Implementada; built signed, wide window with fixtures and drag of the preview splitter checked. Column and overflow divider remain in OR-04 | D-13 |
| ZF-12 | Fix preview of files `.html`/`.htm` that kept loading | Implemented with WebKit, JavaScript of the deactivated document and network entitlement; Approved local HTML/CSS tests, copy of report file rendered in signed test build, including after deactivation of scripts; distribution build not yet checked | D-14 |
| ZF-13 | Calculate the initial width of each preview by Columns by the available leftover | Implemented and confirmed by user; built, unit tests and UI approved | D-15 |
| ZF-14 | Keep terminal column alignment when switching between folder and file | Implementada; unit tests and UI approved for the catch scenario; manual visual fluidity still in OR-04 | D-16 |
| ZF-15 | Reduce the minimum preview by Columns and recalculate after scrolling manual to the left | Implementada; 85 approved unit tests and four UI affected tests; real visual check in OR-04 | D-17 |
| ZF-16 | Add Open with, Share, Copy and Alternations with Option to secondary click; New Tab and Switches to File Menu | implemented in the code and contracts; temporary copy build and fixture menus checked, including real second tab creation. Shared directory build and real operations pending for simultaneous changes in compression profiles | No divergence recorded |
| ZF-17 | Add advanced options and compaction profiles | Developed with build, unit tests and UI; manual validation of all conditional combinations still pending | D-19 records adjacent extension adjustment |
| ZF-18 | Add items to archive existing by menu and drop in navigation | Implemented for ZIP/7z single volume with confirmation, staging and replacement after validation; user-corrected and confirmed confirmation; restoration of the inline hierarchy, opening of the destination branch and selection of the new items implemented; validation recorded in REGRESSION-COVERAGE; refinement visual check pending | D-31; D-32; OR-07 |
| ZF-19 | Explore icon with Z, archive and metallurgy for macOS 27 | File `.icon` exported by user integrated in Debug and Release; build Debug compiled the icon. Visual inspection in Finder/Dock and variants still pending | D-18 |
| ZF-20 | Columns of List and global tags with live filter | Implemented; signed build, preferences, navigation and actual catalog in tests. Global click, column independent circles Tags and refresh-free update checked on the app; order drag and wide visual matrix pending | OR-09 |
| ZF-21 | Replace CLI `7zz` backend with native integration with 7-Zip static link | Backend and build implemented for arm64/macOS 26.0; verified native operations; external validation/UI and pending distribution | OR-10; no divergence recorded |
| ZF-22 | Migrate app and test targets for Swift 6 | Implemented; Debug/Release and 98 approved unit tests; UI locked on runner startup | Explicit isolation of menus, thumbnails and utilities |
| ZF-24 | Compare RAM total of Zforge and 7zz processes in real builds | 36 completed days, hashes conferred; sampler and registered series; D-21 corrected in both branches; retention in OR-11 | UI of fixture; does not prove leakage not all UI |
| ZF-25 | Investigating and optimizing performance and memory of native adapters | Round 2026-10-23 (user-authorized): profiled; three measured optimizations kept (bridge index table, cached containment resolution, set-based selection), one reverted; 10,000-entry extraction 2.2–2.4 × faster via `ArchiveServing`, bridge at CLI parity, multi-selection 8.1 × faster. Complete path still 1.18–1.35 × CLI (target not met); OR-11 retention identified as allocator-held free memory, not reduced. Full-app signed RAM rerun pending | OR-11 and OR-12; D-51; [benchmark](Documentation/Benchmarks/7zip-adapter-optimization.md) |
| ZF-26 | Set/create tags by context and toolbar and color folders | Implementada; signed build Debug, 114 unit tests and 3 of UI approved; wide visual check pending | D-23; OR-09 |
| ZF-27 | Fix new folders on sidebar | Implemented: contextual menu, drop targets and persistence; action of the selector preserved without link on the sidebar; build and approved tests, selector/menu/removal/reopening exercised on the app; user-confirmed functionality; alternative B applied to the indicator; visual check of the pending finish | Wide matrix and automation in REGRESSION-COVERAGE.md |
| ZF-28 | Refine drag feedback and directory selection on sidebar | Implemented: preserved symbols, target single, monochromatic selection; tests/build and actual selection conferred; gesture continuous and outstanding visual matrix | D-24 |

| ZF-29 | Use native directory with circular stamp of Zforge in internal directories of archives | V6 approved implemented with light/shadow masks, cache and position by size/content; internal folders with files use closed version with paper; build and 114 approved unit tests; rendering granted; wide visual matrix in OR-13; open folder applied to expanded internal lines and previews in List; corrected material from closed folder after visual rejection of ofld; rear lines and overlay of paper on the corrected closed edge; 6 approved icon tests; Quick selection failed in last suite and passed isolated | D-26; OR-13 |
| ZF-30 | Fix output and implement copy/movement within your own archive | Implemented with regression tests: source/representation shared with locations, keyboard confirmation, output copy default/Option move and internal reorganization move pattern/Option copy. Real gesture approved in all four modes, Finder and another window; 164 unit cases (189 executions) and eight cases UI approved, with a repeat by navigation of the test. Matrix visual broad pending. | [Current plan](Documentation/Requirements/ARCHIVE-DRAG-DROP-PLAN.md); D-33; OR-14; REGRESSION-COVERAGE |
| ZF-31 | Uniformize local directory icons with approved composition to archives, without stamp | Implemented in the four states, with expansion in List/preview and transition in drop; build and 7 approved icon tests; rendering 16–190 pt checked; visual matrix/expanding wide interaction | D-27; OR-13 |
| ZF-32 | Eliminate polling waiting in the quick selection test at Columns | Fixture synchronization implemented; historical 140 cases/420 executions passed. On 2026-10-05 the full suite timed out waiting for the first archive; the unchanged case passed in isolation. Investigation remains open. | D-28; REGRESSION-COVERAGE.md |
| ZF-33 | Open the ellipsis menu with secondary click on the empty slot | Implemented and integrated in 2026-10-04; signed build and 140 approved unit tests; gesture checked in all four modes; executable UI locked when starting automation | D-29 |
| ZF-34 | Keep individual view mode by window/tab | Implemented and integrated into the main in 2026-10-04; built Debug signed, 143 unit and 1 test UI with two approved windows; Settings pattern applied to future windows | D-30 |
| ZF-35 | Preserve history and columns after archive mutation | User-confirmed correction; history migrated along the way, reloaded ancestors, navigable reveal and path fallback removed. Regression reproduced before correction; 166 unit cases/229 executions and 3 cases UI approved, including gesture and Back in all four modes. Build assinada aprovada. | D-34; REGRESSION-COVERAGE |
| ZF-36 | Delete duplicate list flash when loading a column | Corrected: Each column uses only its own items. Temporal regression failed before and passed after; 166 unit cases/229 executions and five separate cases UI approved, catches of the inspected transition. Build assinada aprovada. | D-35; REGRESSION-COVERAGE |
| ZF-37 | Restore the view mode of the last closed browser window and remove unnecessary await diagnostics | Implemented: 172 unit cases/245 executions and 3 UI cases passed; strict Debug compilation has no source warnings; later integrated and main-reference UI checks failed the List relaunch expectation; investigation and remaining actual-use matrix in OR-15 | D-36; REGRESSION-COVERAGE |
| ZF-38 | Show content previews in Icons by default with a persistent Settings option | Implemented and integrated into main on 2026-10-05; feature tests and bounded visual/performance evidence recorded in REGRESSION-COVERAGE; extended matrix OR-16 and the adjacent intermittent tag-event test remain explicit | D-37 |
| ZF-39 | Add New Folder with Selection as the Option alternate in File | Implemented: `⌃⌥⌘N`, grouping, inline rename, and Undo/Redo. Integration with startup restoration and icon previews: 209/210 unit cases passed; the unchanged native tag-event case failed. All three new UI cases plus English Help and preview/selection passed after integration. The relaunch-mode failure also reproduces on main reference `fc69f1e` (D-36). Broad actual-use checks remain open. | OR-17; D-28; UI-UX-GUIDE; REGRESSION-COVERAGE |
| ZF-40 | Add Open immediately above Open with in the File menu | Implemented and integrated with main on 2026-10-05; 210 unit and six serial UI cases passed, including all three new Open cases and adjacent menus/focus. Signed Debug build and bounded visual inspection passed. Broader actual-use matrix remains OR-18; historical failed rounds are retained. | D-38; D-39; OR-18; REGRESSION-COVERAGE |

## ZF-41 — Correct high CPU and RAM immediately after launch

Implemented on 2026-10-05 while preserving tags: per-item temporary draining, cached exclusions, less untagged filesystem work, one cancellable worker, bounded batches and cooperative 20% CPU duty target. The process index and Spotlight query are reused; live events reconcile only affected files/subtrees with bounded coalescing and incremental tag counts. Overlap/cancellation characterization failed before the fix and passes afterward. Final 225 unit cases/302 executions and three tag UI cases passed; the 30,000-file harness reduces peak RSS about 87% and consumes 0.000306 CPU seconds in ten seconds after completion. Optimized Debug discovery measured 17.35% CPU and 110.1 MiB lifetime peak footprint. Full-Home idle, extended matrix and intermittent native event verification remain OR-19; local strict signature verification reports an untrusted development certificate. No persistent cross-launch index or hard OS quota is claimed. Evidence: [startup correction and limits](Documentation/Benchmarks/startup-tag-scan.md), D-40 and `REGRESSION-COVERAGE.md`.

**User validation, 2026-10-06:** considerable improvement and acceptable memory use confirmed. Remaining OR-19 verification is preserved.

**Requested comparison, 2026-10-06:** the isolated global-catalog-disabled variant and normal app execute four balanced Recents/List launches. Mean CPU is 18.279% enabled versus 0.091% disabled; mean physical footprint is 94.87 versus 91.49 MiB during age 15–40 s. Production feature remains enabled; no app source change or test-suite approval is claimed. [Results and limits](Documentation/Benchmarks/tag-discovery-ab.md).

## ZF-38 — Content previews in Icons

Requested on 2026-10-05: all previewable files should show content in Icons, enabled by default with a persistent Settings option. Implemented asynchronous grid thumbnails, native fallback, localized toggle, bounded cache/concurrency and safe archive materialization. Automated regression, actual interface inspection and performance evidence are recorded in `REGRESSION-COVERAGE.md`; remaining visual conditions stay explicitly pending. Related divergence: D-37.

## ZF-01 — Reference documentation and regression prevention

**Request:** use `AGENTS.md` to guide development, point to a versioned source of truth describing each implemented functionality, create a list of tasks and record separately inconsistencies with previous requests.

**Deliver at this stage:** `AGENTS.md` points to `Documentation/Requirements/CURRENT-STATE.md`, `DIVERGENCES.md` and this file; the functional state was mapped from the code, guide and previous conversations. The survey is static, without new execution of the app. **Continuous maintenance:** Any functional change needs to review the contract and the relevant divergences in the same change.

## ZF-02 — Zforge Icon

**Request:** create a new icon and use it in the application as the current one does not appear.

**Implemented and confirmed by the user:** new icon with PNG variants from 16 to 1024 px referenced by the asset catalog; `Info.plist` explicitly declares the name of the icon and `AppDelegate` assigns it to the application at startup. Finder showed the icon in the anterior bundle of DerivedData of Xcode and in the new built isolated.

**Later direction:** to ZF-19 deals with visual redesign; does not change the technical resolution of the display problem registered here.

## ZF-03 — Mouse adjustable widths

**Request:** drag the partitions to change widths. The user reported that the capacity existed and regressed.

**Implemented:** drag of partitions in List and Columns by native loops of 20 pt with resizing cursor, persisting global widths, limits and scale defined in `Documentation/Requirements/CURRENT-STATE.md`. The terminal area of the preview at Columns is adjustable by ZF-07. The previous build was manually exercised in both modes and the partitions moved.

## ZF-04 — Zoom in views

**Request:** `⌘+` increases and `⌘−` decreases the scale, as in Finder.

**Implemented and confirmed by the user:** `⌘+` and `⌘=` increase; `⌘−` diminui; `⌘0` restaura 100%. Global scale in steps of 10%, from 70 to 160%, in the four views. Toolbar remains un zoomed.

## ZF-05 — Recents without duplicatas

**Request:** the Recents tab must not repeat the same item. Capture 2026-09-22 shows `Archive.7z` repeated.

**Implemented and checked:** the List of Recents eliminates repetitions of the same canonical path or physical file when its identity is available and also discards repeated IDs after loading the items. The regression of 2026-09-24 showed that copies created by the engine itself in `temporaryDirectory/Zforge/ArchiveSessions` passed this rule because they had a new physical identity. All temporary storage of Zforge passed to be deleted in the Spotlight service and in the window state before apply the limit of 250. Files different user with the same name, size and date remain separate. Tests with actual copies check the published list and the four modes; a UI test uses the same setting with fixtures.

## ZF-06 — contextual matrix in both menus

**Request:** Secondary click and `•••` button from the toolbar must present the same actions applicable to the selection, preserving existing actions and enabled states.

| Selection | New options requested |
| --- | --- |
| A common file | Abrir; Comprimir; Custom Compression |
| A archive | Abrir; Extrair aqui; Extract to folder with archive name; Extrair; Validar |
| Several archives | File options archive **e**; “Extract to” lists output folder names separated by comma |
| Several items with at least one common file | Same options indicated for a common file |

**Implemented and confirmed by the user:** matrix and handler shared in both menus; three extraction destinations, validation with `7zz t`, custom compression with format panel/name/destination. Open multiple archives creates windows, validate/extract multiple processes in sequence. Items of Recents receive options according to type. The main action of the toolbar in Recents was enabled in ZF-10, with the default destination defined by the user; the actual execution still needs to be checked.

## ZF-07 — Adjustable preview width

**Request:** Keep 300 pt as initial width, allowing you to drag the splitter to resize the preview.

**Implemented:** a global preference shared by the four modes keeps the width between 180 and 800 pt; each preview splitter has a native loop of 20 pt and resizing cursor. In Columns, the next column that occupies the terminal area uses the same width and adjustment. The build of ZF-07 compiled and the gesture was exercised at List, Icons, Gallery and Columns. The alignment of the terminal area in wide windows was changed at ZF-10; There is no visual check of this change.

**Update in 2026-09-27:** the ZF-13 replaced the shared width and terminal area fixed only in Columns. This section records the historical status of ZF-07; overall preference continues at Icons, List and Gallery.

## ZF-08 — Characterisation coverage and refactoring architectural

**Objective:** reduce coupling, duplication and size of code units, preserving observable contracts of `Documentation/Requirements/CURRENT-STATE.md`. Apply Clean Code and SOLID where they produce useful borders; employ patterns only when they simplify a concrete dependency or flow. This task does not intentionally alter user experience or incorporate functional changes from D-10 to D-13.

### Map of opportunities in current code

| Area | Evidence and risk | Direction refactoring |
| --- | --- | --- |
| State of window | `FileBrowserState.swift` has ~3.150 lines and concentrates navigation, history, selection, hierarchy, Columns, preview, Quick Look, access security, local operations, archives, Clipboard and drop. There are many changeable fields, caches with own revisions and asynchronous tasks. | Split by cohesive responsibilities, keeping an observable coordinator by window. Extract internal models/collaborators for navigation and history, selection/hierarchy, preview and orchestration of operations; define explicit invariants for primary selection, active column, path and cache invalidation. Avoid creating protocols for structures that only need concrete types. |
| Asynchronous flows | `FileBrowserState` holds separate generations and `Task`s for refresh, preview, column activation and expansion; `NSWorkspace` callbacks, monitors and providers also update status. A delayed result can reintroduce previous selection/location data. | Centralise the cancellation and validity policy by operation/session; use typed identifiers or immutable snapshots when needed; maintain synchronous preview selection and invalidation update. Set property and termination of each task when browsing, closing window and canceling operation. |
| Actions and menus | The contextual matrix is `FileBrowserState`, the secondary click menu is `BrowserContentViews.swift` and the toolbar/overflow menu is `ContentView.swift`. There are additional presentations and enabled states on each surface. The main action of the toolbar has its own compression/extraction path. | Enter a typed description of available actions for a selection and location, consumed by menus, toolbar and shortcuts. Reuse an action executioner; maintain native SwiftUI/AppKit presentation in UI adapters. Treat D-12 as current behavior until specific functional decision. |
| Archives | `ArchiveEngine.swift` concentrates `ArchiveServing`, sessions, staging, policy of size/depth, extraction, conflict and materialization. The ZF-21 separated metadata/path politics in `ArchiveEntry` and native calls/cancellation in `NativeSevenZipBackend`. | Preserve `ArchiveServing` as engine boundary; separate session/staging record, materialization policy and flow of conflicts in testable units. Share validation/cancellation between operations without taking text from CLI to domain/UI. Keep password out of arguments/logs. |
| File system and permissions | `FileBrowserState` orchestra `FileSystemServing`, `FileOperationServing`, `AccessGrantStoring`, `RecentItemsServing`, `DirectoryMonitor`, `NSWorkspace` and `NSPasteboard`. The flow of authorization and return to original intent depends on internal state. | Encapsulate authorisation transitions and destination of operations in explicit types; maintain services replaceable by fixtures. Concentrate interaction with AppKit on the edges, preserving original URLs, bookmarks, undo and semantics of drag and drop. |
| Recents | `SpotlightRecentItemsService` metadata query and deduplicates by path/physical identity; `FileBrowserState` loads items and dedoubles IDs. The ceiling of 250 is valid after deduplication. | Extract normalization/identity to testable deterministic unit and leave `NSMetadataQuery` as an adaptor. Do not collapse different files by name/size/date; preserve order, filter and cancel the query. |
| Views and layout | `BrowserContentViews.swift` has ~1.670 lines and contains the four modes, headers/lines, layout, menus, focus, resize and drop. `ContentView.swift` has ~1.000 lines and brings together window composition, toolbar, panels, alerts and focus. `PreviewView.swift` tem ~740 linhas. | Separate files by mode/component and extract pure layout calculations, widths and scroll for small types. Share only presentation/gestures that have the same rule; preserve `@State` scope, view identity, persistent focus and life cycle of `QLPreviewView`. |
| Preferences, location and life cycle | `FileBrowserPreferences` combines persistence, limits and zoom; `ZforgeApp.swift` declares many commands; the opening by Finder crosses `AppDelegate` and `WindowGroup`. | Isolate validation and reading/writing of preferences without changing keys or existing values. Centralize command/shortcut settings when they reduce divergence with Help. Keep the same startup path to common window and file coming from Finder. Review visible strings in String Catalog during the touch of each area. |
| Testability | `ZforgeTests.swift` has ~1.550 lines and mix tests of various domains; `FileOperationServiceTests.swift` tem ~660. There are useful fixtures in `UIFixtureServices.swift`, but several AppKit/Spotlight paths are difficult to exercise deterministically. | Group test by contract and expand fixtures at existing borders. prefer pure/state rule tests to UI for combinatorial cases; use UI tests for gesture, menu, focus and window integration. Do not associate percentage of lines to regression protection. |

### Coverage to create before changing each behavior

The inventory of `Documentation/Requirements/CURRENT-STATE.md` is the list of contracts; the existing tests must be maintained. For each extraction, record the previous scenario and a test that fails if it changes. Gaps identified by static inspection of sources of `ZforgeTests` and `ZforgeUITests`:

| Contract a proteger | Expected new coverage |
| --- | --- |
| Window and navigation | Common opening in Recents, file sent by Finder opening window dedicated by the same `WindowGroup`, grant authorization/cancellation/repetition, return to intention after authorization, breadcrumb, independent history by window, refresh preserving selection and symlink/alias without cycle. |
| Recents | Repeated Spotlight results along the same path, symlink and physical identity; separate files with the same name/size/date; order by use; a ceiling of 250 **single items**; no/hidden results; new query canceling the previous without publishing old answer. The current Recents test uses only two distinct URLs. |
| Selection and hierarchy | Simple selection, Command and Shift in flattened order, left/right keyboard in expanded folder and root item, expansion ZIP/7z and nesting limits, disposal of old branch in Columns and reconciliation by changing mode without new history. Complement cases with shipments that end out of order. |
| Four modes, zoom and widths | `⌘+`, `⌘=`, `⌘−`, `⌘0` and 70–160% limits at Icons, List, Columns and Gallery; Persisted width and actual drag of the dividers of List, Columns and preview in the four modes, including minimum/maximum, overflow and window resizing. Current tests cover some layout calculations, but not gestures/shortcuts. |
| Preview and Quick Look | Invalidize preview before loading another item, discard obsolete result, 10 MB automatic versus manual, files/folders/archives and multiple selection, URL change by recreating `QLPreviewView`, independent visibility by mode and focus after switching. Preserve existing order checks, layout and quick selection. |
| Contextual actions and toolbar | Complete matrix for file, archive, several archives and mixed selection; secondary menu and `•••`/overflow with the same options and states, multiple selection preserved in secondary click, multiple output titles, main action and breakpoints 678/840/900 pt, including current exception of Recents. Exercise real handler in addition to checking labels. |
| Motor of archive | Real output pixels of `7zz` for parser, special names, failures and warnings; formats, volumes, size/depth, password by stdin, staging, session materialization and cleaning, cancellation/progress, conflicts, creation, extraction and batch validation. There are ZIP tests, formats, password and nesting; there are no dedicated cases of parser/protocol and failures partial. |
| Files e drag and drop | Destination per row/column, copy/movement/alias as modifiers and volume, provideders initiated within `performDrop`, collisions, undo, Trash/permanent exclusion, confirmation and Clipboard with original URL. Part of the rules already have service/state test; complete the flows of UI and limits between AppKit/SwiftUI. |
| Preferences, language and icon | compatibility of keys persisted after refactoring, string language outside SwiftUI, zoom/width/preview and archive limits; inspection of the compiled bundle for `zforge_icon.icns`/`Assets.car` and opening check for Xcode/Finder. Confirm strings and control states in both languages. |

### Sequence and acceptance criteria

1. Register a traceable matrix `contrato de CURRENT-STATE.md → teste existente → lacuna → novo teste`, indicating what unit test is, integration `7zz`, UI or manual verification. Prioritize flows with recent regression: Recents, widths, zoom, menus, icon and opening by Finder.
2. Create the slice characterization coverage before refactoring it; use temporary files/fixtures and isolated defaults. For dependencies of macOS that do not allow reliable automation, document the limit and execute reproducible manual script on the actual path of opening.
3. Refactor in small slices, starting with pure rules/identity and actions; follow by selection/preview coordination, archive services, views and persistence. Each slice must preserve public API when possible, without silent migration of preferences or accidental visual change.
4. When running this task, run the affected tests and complete suite, build Debug and UI checks on the app by Xcode and Finder when pertinent. record pre-existing results, failures and any limitation; update `Documentation/Requirements/CURRENT-STATE.md` and `DIVERGENCES.md` only if the evidence/contract changes.

**Ready when:** responsibilities have clear borders and domain-oriented names, the identified duplication has been reduced without artificial abstractions, all contracts played are covered or have explicit manual verification and limitation, and the main flows behave as before in the four modes and the two opening routes.

**Result in 2026-09-23:** the matrix in `REGRESSION-COVERAGE.md` was created; identity of Recents, selection of actions, listing parser `7zz`, projection/cache of items and layout calculations received their own borders. The four modes were separated into individual Swift files. Old reloads cannot publish results on a newer query, including in the expanded hierarchy; refresh extraction and removal in Columns preserves the actual keys of the URLs. Compression shares an executable between menu and toolbar. The contracts played have explicit characterization or manual verification tests. The last round recorded 80 unit tests and 11 distinct cases of UI approved; gestures of splitter and Launch Services were checked on the interface. Limitations of macOS integration and unaltered functionalities gaps remain described in the matrix, without redefining the expected state of `Documentation/Requirements/CURRENT-STATE.md`.

## ZF-09 — Directory and requirements indices

**Request:** place the project requirements at `Documentation/Requirements`, create indices at `Documentation/AGENTS.md` and `Documentation/Requirements/AGENTS.md`, point at them at `AGENTS.md` of the root and keep the documentation updated at each agent interaction.

**Delivery:** the current state's source of truth and the UI/UX guide were moved to the requirements directory. The product, motor and distribution direction was preserved in `PRODUCT-REQUIREMENTS.md`, and open decisions were grouped in `OPEN-REQUIREMENTS.md`. The three `AGENTS.md` establish index, precedence and update routine. The old paths at the root are redirects to avoid losing already shared references.

## ZF-10 — Pendencies of the lifting

**Approach authorized in this interaction:** Solve the five to-dos listed in `OPEN-REQUIREMENTS.md`. The user-informed rule for the destination of operations in Recents corresponds to D-12; D-13 remains the alignment of the terminal area of Columns.

- OR-01/D-10: operating references to `ExampleFiles`, `AppStorage` and the proposed prototype architecture are removed; preserved the visual rules of the guide.
- OR-02/D-11: the sizes shown use `ByteCountFormatStyle` with the application locale; the configurable limit of archive remains in decimal GB.
- OR-03/D-12: the action of archive of toolbar works in Recents as the selection. Extracts use the actual directory of each archive; joint compression uses the directory of the active item, or the first source by path if there is no active item.
- OR-04/D-13: Columns align to the right edge when the set is smaller than the visible width, without changing the width preferences.
- OR-05/C-06: the Finder route → `WindowGroup` already integrates `main` into the commit `268e8c8`; there was no local change of this flow to integrate.

**Current limit:** compilation and code inspection do not replace visual language conferencing, gestures in Columns and execution of real operations in Recents. These points remain `OPEN-REQUIREMENTS.md` and `REGRESSION-COVERAGE.md` until validation in the app.

**Compilation:** `xcodebuild` Debug macOS without signature concluded with `BUILD SUCCEEDED` in 2026-09-24 using `/tmp/zforge-open-requirements-build`. The initial attempt on the sandbox failed due to unavailability of the macro `@Observable`; the repetition with access to the Xcode service compiled. No tests were performed in this interaction.

## ZF-13 — Preview width in Columns by selection

**Request:** Each preview starts with all available width to the right of the open columns at the time of loading, with a minimum of 320 pt and no maximum. A space change before the next selection must be reflected in the new preview.

**Implemented:** Before expanding a branch, Columns keeps the navigation columns at base width without booking fixed slot for preview. When loading an eligible item, calculate the width with the current geometry; the splitter changes only this selection. The next selection recalculates the width without consulting or changing the overall preference of other modes. The content of `SelectionOverview` receives the width proposed by the parent. The rule after expansion was refined in ZF-14.

**Validation:** build Debug macOS approved; suite `ZforgeTests` approved; UI test signed with fixtures passed in file of the first column and file of an internal column, confirming different width and minimum of 320 pt. Visual check with capture files and narrow window drag remain in OR-04.

**User confirmation:** The initial width problem has been solved. The ZF-14 refined the behavior after opening a child column.

## ZF-14 — End-range stable alignment at Columns

**Request:** After opening a folder/archive on the right, keep the new column fully visible. When selecting a file in the previous column, the preview must occupy the same range and width without the partition oscillating; preserve the dynamic width of the preview before this expansion.

**Implemented:** the terminal column fills the free width, with minimum base width and 320 pt when the preview is visible. The branch records that it has already opened a child column; later previews at the same level use the corresponding terminal range. An empty slot keeps geometry during asynchronous column opening or preview loading. Without visible preview, columns continue with base width.

**Validation:** `ZforgeTests` passed with 85 tests; `RefactoringCharacterizationTests.columnTerminalWidth` checks geometry. The two signed UI tests passed in `/private/tmp/ZforgeTerminalAlignmentFinal`: `testColumnPreviewKeepsExpandedTerminalAlignment` confirmed the same edges and width for expanded column and substitute preview in `Welcome.txt → Sample.zip → Welcome.txt`, in addition to reopening the column in the same position; `testColumnPreviewRecalculatesWidthForNewDepth` preserved the previous dynamic calculation. Fast visual navigation with capture files and manual drag continue in OR-04.

## ZF-15 — Minimum of 240 pt and recalculation after scrolling manual

**Request:** commit previous correction before these adjustments; reduce the minimum preview width by Columns from 320 to 240 pt. After navigating right aligned and scroll manually to the left, keep the current preview cut; in the next file selection, recalculate its width by the available leftover and keep the entire column visible. When opening another folder/archive, expand the terminal column and align to the right again.

**Implemented:** the correction ZF-14 was committed to `712e9fa` before the changes of this task. The minimum of Columns is 240 pt. The view observes the phase and geometry of the horizontal scrolling, preserves the width of the current preview during the manual scrolling and uses the width available in the next preview when the user has moved away from the right edge. Opening a directory restores terminal alignment. No overall preference of Icons, List or Gallery is changed.

**Validation:** the final round passed with 85 unit tests and four tests of UI signed in `/private/tmp/ZforgeColumnScrollFinal`: the two previous cases of Columns, the new complete cycle with `XCUIElement.scroll(byDeltaX:deltaY:)` and the case of Recents affected by fixture. The new test confirmed the permanence of the cut preview, the recalculation after selecting another file and the expansion of the column after selecting a archive. The visual check with the capture files continues in OR-04.

## ZF-17 — Advanced options and compaction profiles

**Request:** Provide password, dictionary and other advanced parameters in `Compress Custom…` and in the standard compaction preferences, with multiple profiles creation.

**Implemented:** profiles persist format, level, method, dictionary, quick bytes, solid mode, threads and applicable encryption options. Settings allows you to choose the default profile and create, update or delete profiles; the custom panel reuses the editor and allows changes only for the current operation. Toolbar and Compress menu use the default profile. Passwords never enter the profile or `UserDefaults`: they remain in memory in the session or are requested during the operation; the native engine receives them only by memory callbacks (the previous backend used stdin).

**Validation:** build Debug macOS and suite `ZforgeTests` approved, including real creation and validation of archives 7z and ZIP encrypted, persistence of passwordless profiles, format options, migration from initial name to Auto and use of default profile by quick action. Signed UI tests have passed to the editor's opening in Settings and in the `Compress Custom…` panel. Detailed visual check of conditional controls, creation/exclusion of profiles by UI and password flow of toolbar/menu are still in the coverage matrix.

**Implemented interface adjustment:** the [alternativa A](Documentation/Design/CompressionModal/ALTERNATIVES.md) was chosen and applied to the `Compress Custom…` panel. The accessory now uses two columns and adjusts its height to the visible controls; does not display name or actions of saving profile. The initial profile is called Auto, including after migrating the old Default/Default. `Protect with password` is left below `Solid archive`; when dialing, password and confirmation appear below the check in the left column and the panel grows; When they uncheck, they disappear and the panel shrinks. `Encrypt file names` remains on the right. Profile management remains only in Settings. Build Debug, suite `ZforgeTests` and `ZforgeUITests.testCustomCompressionShowsProfileOptions` passed; the UI test gives the growth and return of height, the position of the fields under check and `Encrypt file names` on the right. The alternation in 7z and ZIP was also visually checked on the signed build. All conditional combinations of format/method and password flow still need to be checked manually until archive is created.

**Adjoining observation:** when switching 7z to ZIP on the panel, the suggested name in `Save As` continues with `.7z`; separately correct and validate the update of the displayed extension, as [D-19](DIVERGENCES.md).

**Visual refinement:** after misalignment capture, [three studies of composition](Documentation/Design/CompressionModal/ALTERNATIVES.md#appraisal-refinement) was generated to `Compress Custom…`, with `Save As` wide, alternatives to `Tags`/`Where` and uniform selectors; there is also a password enabled state. The user then asked for an item per line at the top, with wider controls, and the profile selector to the right edge.

**Research of refinement:** the user combined `Tags`/`Where` equals studyA with labels above studyB selectors. Official Apple orientation on layout, pop-up buttons and text fields accepts this label position; the `Form` macOS native commonly uses side labels. The documented `NSSavePanel` API does not offer repositioning your native fields. Therefore, the final composition uses a unique SwiftUI sheet with a native folder selector (`NSOpenPanel`).

**Implemented refinement:** The format labels, level, method, dictionary, quick bytes and threads are above the respective selectors, with a uniform width of 260 pt on a sheet of 580 pt. `Save As`, `Tags` and `Where` occupy three lines with wide controls; the profile selector reaches the right of the grid of options. Height follows password and confirmation below `Protect with password`; `Encrypt file names` continues to the right. Build Debug aprovada; the UI test measured the geometry, password expansion and opening of the native folder selector. In the following refinement, the four leaf areas went to use side margin of 20 pt, with columns derived from the useful width; the build and a signed UI test passed, checking the left and right edges in the compact states and with password. The actual creation flow with folder/tags and the final visual review are still in OR-08.

## ZF-22 — Swift language mode 6

**Request:** Raise the application's language mode to Swift 6.

**Implementation:** `SWIFT_VERSION = 6.0` in Debug and Release for app, unit tests and UI. Adjusted menu isolation AppKit, Quick Look image transfer to `MainActor` and metadata/layout utilities without status UI. Evidence in `REGRESSION-COVERAGE.md`.

## ZF-21 — native 7-Zip engine compiled with Zforge

**Build correction in 2026-10-03 (D-22):** static phase and linker use `TARGET_TEMP_DIR/SevenZip`, allowing libtool objects/dependencies/temporaries with script sandbox enabled in DerivedData standard. Validation of this correction in `REGRESSION-COVERAGE.md`.

**Request:** replace the use of `Vendor/7zz`/`Process` by direct integration with the source code of 7-Zip. The delivered product must contain the engine in the bundle of Zforge, with full signature of the app and its nested components.

**State:** backend implementado. `NativeSevenZipArchiveEngine` preserves `ArchiveServing`, sessions and policies, uses typed metadata and executes `NativeSevenZipBackend`/Objective-C++ bridge in workers. The official 7-Zip 26.02 is compiled statically for arm64, with macOS minimum 26.0; scripts maintain the Xcode sandbox and do not depend on external checkout. Runner, parser, CLI translators and `7zz` embedding were removed. Operations and evidence in [REGRESSION-COVERAGE.md](REGRESSION-COVERAGE.md); UI, external access and release in OR-10. [Detailed plan](Documentation/Requirements/SEVENZIP-STATIC-INTEGRATION-PLAN.md).

**Steps and completion criteria:** fix an accurate review of the source code and sell it reproducibly with licenses and patches; compile the multiformat module as a static library for arm64 and exercise listing, extraction and testing in a minimum adapter; prove access to authorized files, related volumes, password, cancellation and progress by the native border; port creation and update of ZIP/7z, preserving staging, conflicts and substitution only after validation; change the production composition to the backend native and remove the `7zz` from the bundle only after the regression matrix passes; check signature of the executable incorporating the engine and any nested executables, Sandbox, build Release arm64 and signed/notarized distribution on each applicable channel. Publish the corresponding source and the recap/relinking materials required by LGPL and review the distribution conditions, especially Mac App Store, before launch.

**Tracked Marks:**

- [x] Characterize current contracts and separate models/politics from the CLI protocol.
- [x] Vendorize the official review and prove the static build arm64, including records of formats/codecs in Release.
- [x] Implement the bridge typed with ownership, callbacks, password, cancellation and workers.
- [x] Port reading, test, extraction, materialization, volumes and nesting with limits and safety of paths.
- [x] Port creation and transactional update preserving all current formats and options.
- [x] Integrate the backend native into the production composition, migrate tests and remove `7zz` from the bundle.
- [ ] Validate signature, Sandbox, applicable distribution and recompilation/relinking of the corresponding source.

**Historical evidence of planning in 2026-10-02:** The inspection of the official review 26.02 found records of formats/codecs by static initializers, which require explicit retention in linking and checking in Release. `IArchive.h` prohibits simultaneous use of the same instance of `IInArchive` by different threads; the adaptor shall serialise operations per session. No build, suite or engine benchmark native was executed at this stage.

**Limit of completion of ZF-21:** migration of the backend does not prove all upstream formats, all visual flow or public distribution. OR-10 maintains checks requiring active graphical session, external authorizations, runtime macOS 26.0 and release credentials/channel.

## Comparison requested after ZF-21 — 2026-10-03

Static implementation is compromised in this branch `feat/7zz-static-linking`. The dynamic variant was implemented and validated in `feat/7zz-dinamic-linking`, and the [same benchmark for CLI/static/dynamic](Documentation/Benchmarks/7zip-linking.md) is versioned in both branches. Git does not accept `:` in the name; was used `/`. The static alternative remains the backend of this branch. The dynamic variant does not automatically change the choice of distribution.

## ZF-24 — RAM total app and engine

**Request:** replace the comparison of RSS of harnesses by measuring the actual process of Zforge plus its processes `7zz`.

**Executed:** Snapshots Release instrumented only in temporary directories, window with `ContentView` real/visual fixture services, staging and actual engine calls; two loads × ZIP/7z × three variants × three repetitions, total of 36 classes with SHA-256 correct. External sampler sums up the process family per cycle, records RSS/physical footprint, baseline and post-cleaning. [Report and method](Documentation/Benchmarks/7zip-ram.md).

**Found:** D-21 prevented native extraction in the container and was corrected in both branches with authorized root/descriptors; 109 tests passed in each variant. The difference of RAM static/dynamics was small, but the pipeline 7z large native arrived and remained close to 992 MiB after closing sessions, against ~56 MiB after the CLI finished its children. Investigate retention in OR-11; The test doesn't conclude a leak. OR-10 preserves runtime macOS 26.0, PowerBox/external bookmarks and distribution.


## ZF-25 — Future optimizations of native adapters

**Request (2026-10-03):** document the to-dos for future recovery. This activity does not change the implemented behavior or initiate an optimization round.

**Evidence:** [benchmark inicial](Documentation/Benchmarks/7zip-linking.md) and [RAM of the full app](Documentation/Benchmarks/7zip-ram.md). The advantage of CLI was observed in the extraction of many small files; It's not a general superiority. The proximity between static and dynamic points to the investigation of the shared path, but does not identify the cause. The initial times precede correction D-21; repeat with both current versions before assigning gains to a change.

### Hypothesis to be measured

1. `SevenZipBridge.mm`, extraction callback: `indices indexOfObject:@(index)` does linear search by input; extract all can accumulate O(n²). Compare access by map or direct index, preserving partial selection, order and association to the destination.
2. I/O and metadata by file: safe opening by descriptors, directory cache, writing, permissions and dates. Measure time and system calls; preserve authorized root, `O_NOFOLLOW`, byte limits and protection against traversal/links.
3. Property queries and allocations/copies Foundation on the Objective-C++ bridge; also investigate repeated listings in the Swift preparation of extraction. The initial benchmark does not include the complete Swift path, so do not assign your times to the Swift crossing without another experiment.
4. OR-11: memory retention after large 7z test. Separate lifetime/ownership from COM interfaces, ARC objects, codec buffers, caches and allocator; Do not declare leak without evidence.

### Resumption and conclusion protocol

- Use Time Profiler for CPU, Allocations/VM Tracker for memory and counting of system calls when pertinent; separate preparation, callbacks, codec, I/O and cleaning.
- Compare CLI, isolated native bridge and complete operation via `ArchiveServing`, with explicit inputs, options, cache, staging and destination protection. Change one candidate at a time.
- Repeat operations in the same process to distinguish stable retention from accumulated growth; record memory after each phase and after closing sessions, without adding independent peaks of processes.
- Reexecise the time suite and RAM total Zforge + children in static and dynamic variants; check hashes and record samples/variability, not just a median.
- Complete only with measured gain and verified pertinent regressions: partial selection, Unicode, conflicts, cancellation, corrupted files, links/traversal and actual extraction in the sandbox. Do not remove security guarantees to get gain.

### Round 2026-10-23 — status: optimizations delivered, targets partially met, items open

Explicitly authorized by the user. Workloads and acceptance criteria were written before any code change; method, all samples and limits are in [7zip-adapter-optimization.md](Documentation/Benchmarks/7zip-adapter-optimization.md). Another agent worked on the same host throughout; baseline and candidates were interleaved in the same windows.

- **Re-baseline (current code, after D-21):** native bridge extraction was +44 % over the CLI at 2,000 files and 2.5–3.2 × at 10,000 entries, scaling superlinearly. An A/A control bounded run-to-run medians at ≤ 1 %.
- **Hypothesis 1 confirmed:** `indexOfObject:` was 61 % of profile samples; replaced by a position table built once (kept).
- **Hypothesis 2 — no adapter excess found:** per file the bridge issues exactly `openat`, `write`, `fchmod`, `futimens`, `close`; kernel file creation dominates. A directory-hint candidate gained only 1–2 % and was reverted. Metadata calls were kept for correctness.
- **Hypothesis 3 confirmed for the Swift path:** cached parent resolution for the containment check (kept) and a set-based selection matcher replacing O(entries × selected) scans in the backend and conflict scan (kept). The second listing and conflict sort remain (≈ 5 % and ≈ 4 %).
- **Hypothesis 4 (OR-11):** retention starts after 7z creation (≈ 683 MiB) and reaches ≈ 940 MiB after the test; `vmmap` shows it as empty "Malloc Large" segments held by the system allocator (live heap ≈ 262 KB), reused without growth across three in-process cycles. Not a leak; not reduced.
- **Criteria:** C1 bridge parity met within noise; C2 linear scaling met; **C3 complete path ≤ 1.25 × CLI not met** (1.18–1.35 ×); C4 no regression met; M1/M3 met; **M2 bounded retention not met**.
- **Tests:** new partial-selection mapping (ZIP/7z, 451 files), destination file-link and selection-semantics tests pass on the candidate. The behavioral ones also pass on unchanged HEAD. Full unit suite: 366 tests, 359 passed, 7 failed; these are the preexisting D-49 `TagCatalogTests` failures, reproduced identically on unchanged HEAD.
- **Open:** complete-path overhead (staging copy, double listing, conflict scan, URL standardization); OR-11 remedy (separate engine process or allocator decision); signed full-app RAM rerun and macOS 26.0 runtime; CLI system-call count (System Trace capture of `7zz` hung under the tracer).

### ZF-26 — Set/create tags and color folders

**Implemented in 2026-10-03; built and tests approved.** Edit tags per context menu, toolbar between Share and ellipsis and overflow, with name/color creation and multiple editing that preserves unedited tags. Recolor folders in all modes, previews and drop. Real recording in files/folders and preservation of multiple selection have unit tests; sheet per toolbar/context and overflow in 650/860 pt have approved UI tests. Check still Real Finder, location, themes, multiple visual selection and all modes/breakpoints; evidence in `REGRESSION-COVERAGE.md`.

ZF-26 refinement in 2026-10-03: seven interactive circles in the first line of menus, Edit Tags with icon in the second, hover +/x and check. Inverted pile and front tag color; preservation of the order of metadata and selective recoloring with white paper and native representation of 512 px. Menus of the four modes use passive bridge AppKit to insert the custom line; Handlers and alternants Option preserved. Validation: 116 unit and 6 cases of UI approved (122 in total); context in the four modes, applied state, hover with x, compaction menus and overflow. Rendering of seven colors with white paper inspected. Limitations in `REGRESSION-COVERAGE.md`.

Final confirmation of ZF-26 by the user in 2026-10-03: “Everything is OK”; authorized integration into the main and commits of the refined version. Broad matrix tendencies remain in OR-09.

## ZF-27 — Sidebar folders

Request of 2026-10-03, with reference recording showing insertion between bookmarks and removal. Implementation uses observable global store, bookmarks, canonical deduplication, multiple pin and removal without changing files. Initial bookmarks preserve your icons/location and can be removed. The contextual menu is shared by the four modes; the destination body keeps the file transfer.

Validation: build Debug signed with Xcode/SDK macOS 27; full suite of 114 tests approved before the additional supplier test; then, the 6 tests of `PinnedFolderTests` passed in the final version. Selector native, menu inclusion in Icons, navigation/reopening and removal exercised in build. Attempts to drag via automation did not produce a confirmable inclusion; do not declare visual validation of this gesture. Manual drag between inputs, Finder external drag, multiple simultaneous windows, all modes/languages/themes, keyboard and external volumes access remain.

**User return in 2026-10-03:** OK functionality. Requires studies visuals of the insertion indicator: thinner line, slightly more left start and more refined finish. Chosen alternative B and applied: line 1 pt, circle leaked 5 pt and beginning 8 pt to the left. Area of drop and spacing preserved; check the finish during drag pending.

## ZF-28 — Feedback and sidebar selection

In 2026-10-03, the user provided two recordings and a Finder capture: maintain original icons, stabilize the target drag and highlight the current directory in a monochromatic way. Applied in the same sidebar flow used by the four views. The first implementation solved targets by one delegate per line (replaced in the review below); the feedback native superimposed is disabled only in the sidebar table. Content views symbols continue with their previous behavior. Selection of the current actual folder conferred on Downloads; matrix and gesture continuous pending. 119 approved unit tests; details and boundaries in the matrix.

**Historical note — review of 2026-10-03, recording 18:56, reverted to 19:47:** the user played highlight retained in Applications, misaligned line and absence/instability at the end. replaced by line delegates by sidebar delegate, with zones and indicator derived from the same positions; Final slot and empty list covered, including false end protection during scroll. Additional cleaning by native position/button. Removed “Add Folder...” and the selector without another entry point. Build and new coverage recorded in `REGRESSION-COVERAGE.md`; automation did not confirm the continuous gesture.

**Review 19:47 — previous round reversed:** the user reported that the pin per drag stopped working and that drop in the directory itself created copy. Removed global delegate, geometry/preference model and global watcher; restored handlers by favorite/header, with patterning/coherent limits, lower insertion in the last favorite and cleaning by owner/position/button. No link “Add Folder...” has been reintroduced. Explicit payload of original URL and canonical no-op for automatic drag/move in the folder itself; Option/paste/Duplicate preserved. Pin per menu checked on UI with Beta, followed by removal only from the reference. Execution of tests and visual limits in the matrix; do not treat previous confirmation of functionality as validation of this review.

**Refining 20:11:** User confirms resolved functional part and shows cut-off indicator. Removed overlays SwiftUI beyond the cell; B indicator now painted in a transparent NSView above the clip view, with anchor per cell and scroll update. Handler and preserved drop zones. Built Debug signed and 5 approved specific tests; new test mounts table/cell with clipping and verifies external layer, upper/lower edges, cleaning and zero testing hit. Visual check during drag of the new build remains pending.

**Refining 20:22:** user shows partial overlay of the Downloads highlight over the line and asks to bend the thickness. Line changed from 1 to 2 pt, with preserved length and circle. Overlay now has its own backing layer and zPosition above the sister layers, recalculated with each anchor update. Extended test adds a high highlight after indicator and checks the promotion; 5 sidebar and signed build tests approved. reopened application; finish during real drag of this review not confirmed by automation.

**Circle refinement in 2026-10-03:** User confirms line improvement and asks for a proportional circle. Increased external diameter from 5 to 8 pt, contour from 1 to 2 pt; vertical center, left beginning and right end preserved. Visual check of the new size during pending drag.

**Adjustment requested in 2026-10-03:** circle of the enlarged indicator to 12 pt of external diameter; contour and line kept at 2 pt. Vertical center and horizontal boundaries preserved.

**Choose final in 2026-10-03:** by request of the user, circle returns to 8 pt of external diameter, with contour and line 2 pt. The study of 12 pt is historical.

**Final validation of ZF-27/ZF-28 for commit in 2026-10-03:** build Debug and 122 approved unit tests, with confirmed count in xcresult. Current contracts synchronised with the circle of 8 pt; wide visual matrix and final real gesture remain pending.

**Main integration in 2026-10-03:** ZF-27/ZF-28 merged with tag editing (ZF-26); pin command adapted to the current menu native, with coexistence test. Build and 130 approved units. Sidebar identifiers renumbered to avoid collision: ZF-27/ZF-28 and D-24/D-25.

## ZF-33 — Action menu on empty slot

**Request in 2026-10-03:** secondary click on empty space must open the same menu as the `…` button (record 22:18:43).

**Implementation:** Constructor `BrowserActionsMenu` shared with the toolbar and native monitors of the empty areas of the four modes. preserves the selection; item menus have priority regardless of the order of monitors. Overflow preserves its responsive additions. Validation in `REGRESSION-COVERAGE.md`.

**Integration in 2026-10-04:** Renumbered correction for ZF-33/D-29 to preserve the IDs used by the main in the Columns test. signed build and 140 units approved in the integrated state; UI limits preserved in `REGRESSION-COVERAGE.md`.


## Integration of archives into main — 2026-10-05

ZF-18/ZF-30/ZF-35/ZF-36 integrated with ZF-33/ZF-34: individual window mode preserved in drag and refresh, background menus and preserved item. Main maintained IDs and conflicting IDs of archives renumbered to ZF-35/ZF-36 and D-31–D-35. Integrated final validation: 169 unit cases/232 executions and ten different cases UI approved, including history in all four modes, transitory state of Columns, gestures locations/of archive, keyboard confirmation, menus in all four modes and independence between two windows. Build Debug and signature verified; failures of the initial rounds, setup/selectors adjustments and limits are recorded in `REGRESSION-COVERAGE.md`. Wide visual finishing and runtime macOS 26 preserved.

### ZF-41 scope refinement — 2026-10-06

Apply the user's observed Finder rules: global discovery is restricted to visible Home/Shared items across fallback, observations and Spotlight, with hidden-only notifications excluded from new work. Local tag editing/reading stays available. New exclusion characterization fails before the change and passes afterward; explicit scope and hide/unhide coverage added. The initial real-tree completion measurement is 135.45 s, above the declared 60 s target, with 0.000344 CPU seconds in ten post-completion seconds. Completion latency remains an optimization item; no persistent cross-launch index is implemented.

Final scope evidence, 2026-10-06: standalone median completion 149.23 s (three runs), final sandboxed app discovery 288.424 s; app CPU falls from 17.638% to 0.041%, mean footprint stays 97.32/97.36 MiB, peak 109.49 MiB. Final 227 unit cases/304 executions and three tag UI cases pass. The predeclared 60-second completion target remains failed; latency optimization, durable cross-launch reuse and extended OR-19 checks remain pending. See the visible-tag-discovery benchmark.

### ZF-41 durable-index optimization — 2026-10-06 (implemented; first-pass latency and extended verification open)

The user requests cross-launch reuse and faster first discovery. Diagnosis: completed scopes and records exist only in memory, and FSEvents starts at `sinceNow`, so every new process repeats the visible tree scan. Implement an atomic, versioned tagged-record index with per-volume journal identity and per-scope cursors, restore only after authorization, replay changes made while closed, and reconcile when history or scope identity is invalid. Interrupted discovery must not be persisted as complete. Keep local editing, hidden/package exclusions, bounded work and post-completion quiescence.

Pre-change acceptance: baseline sandboxed Debug completion is 288.424 s, active CPU 17.638%, idle CPU 0.041%, peak footprint 109.49 MiB. First discovery retains the 60 s target. A quiet cached reopen should finish within 5 s; post-completion CPU remains below 0.5% of one core. Compare the old/new scanner on the same controlled 100,000-file tree and real visible Home/Shared; require identical tagged results and seek at least 2x lower controlled latency without uncontrolled memory growth (app peak target below 130 MiB). These are targets until measured. Cache replay must cover offline creation, edits, rename, deletion, hidden changes and invalidated history.

The first durable-index real-app run exposes inaccessible items: enumeration returns after 213.779 s with `complete=false`, preventing a whole-index checkpoint. Refine the persistence requirement: after an uninterrupted traversal, save known records plus explicit deferred paths; retry only deferred paths and replayed changes on reopen. Never label this partial state complete. Cancellation still cannot checkpoint an unfinished traversal. This prevents a small inaccessible subset from forcing repeated Home scans.

Delivered: atomic persistent index, per-scope streams/cursors, authorized staged restoration, preservation across separate grants/processes, offline changes and bounded deferred retries. Native directory batches reduce controlled median elapsed 16.14% with identical results. Fixed event-window starvation, inode visibility events, symlink stat fallback and hidden-ancestor probes. Final 244 unit cases/327 executions pass; cached native app readiness 0.746 s, idle CPU 0.168%, mean footprint 97.90 MiB, peak 113.25 MiB. Strict Debug signature passes. Intermediate first saved Home pass is 212.249 s with one deferred path; the 60 s cold target and sought 2x controlled speedup remain unmet (D-41). Exact-final cold Home/Shared repetition is pending. Current UI runner executes no scenarios; separate four-mode filter/editor-cancel checks do not close the broader matrix. Runtime QoS warning in an unchanged AppKit test fixture remains recorded. [Evidence and next algorithm constraints](Documentation/Benchmarks/durable-tag-index.md). Previous no-persistence notes describe earlier phases. The requested earlier changes were committed as `f6f308c`, `a8a6960`, `3aa216a`; this subsequent optimization is committed in the current interaction.

**User validation of durable reuse, 2026-10-06:** the user reports substantial improvement and requests committing the delivered changes. This qualitative acceptance complements the recorded measurements; first-pass latency and extended OR-19 verification remain open.

### ZF-41 high-tag-count benchmark — 2026-10-06 (measured; cached-latency optimization remains open)

Add a reproducible 100,000-file scenario with exactly 10,000 eligible tagged files. Measure native/reference discovery, durable catalog reopen, checkpoint load/save, a one-record rewrite, CPU/physical footprint/idle and the JSON byte size. Preserve exact-result assertions and keep checkpoints outside the production application store. Report all three repetitions and validation boundaries; existing latency/resource targets remain unchanged.

The 10,000-record catalog/store scenario passes all fifteen fresh-process invocations. Median cold readiness 30.391 s, cached readiness 10.377 s with zero full scans, JSON 1,320,326 bytes, load/save/one-record replacement 18.973/13.268/13.308 ms and idle CPU 0.002347%. D-43 records the failed 5 s reopen target. Production behavior and application index remain unchanged; the final awake scanner comparison passes all six exact-result runs and reduces median elapsed 14.85% (34.917 → 29.732 s), below the sought 2x. The numeric artifacts retain original sleep-affected samples and provenance.

### ZF-42 — Optimize durable tag catalog structure and reopening (open; 2026-10-06)

The user sets a new acceptance target: fully reconciled valid-cache reopening below 2 s with 10,000 tagged records, retaining total settled catalog storage below 1.5 MiB. The current same-label benchmark is 10.377 s and 1.259 MiB. Investigate unconditional cached-record rereads first, bounded batch visibility/publication second, compact scope-relative/interned storage and transactional delta alternatives afterward. No backend is selected and no implementation is delivered. [Issue, candidates, sources and acceptance matrix](Documentation/Requirements/TAG-CATALOG-OPTIMIZATION-ISSUE.md). Full-app and distinct-label evidence remain separate pending checks.

**ZF-42 execution, 2026-10-06:** test the first two candidates separately and together against the same prepared 100,000-file/10,000-tagged-file fixture. Remove unconditional ordinary-file metadata rereads when history is valid; share bounded ancestor flags and normalize paths once in a background validation worker. Preserve conservative rereads for symbolic/hard links and unverifiable identities. The first-only prototype is faster but concentrates main-actor CPU and misses an external linked-target change; the combined version preserves correctness and cooperative duty. Whole-snapshot JSON remains. [Per-stage evidence and remaining application acceptance](Documentation/Benchmarks/tag-catalog-optimization.md). Do not close ZF-42 based solely on the isolated benchmark.

ZF-42 final evidence: contemporary cached median 15.110 → 2.150 s; final samples 2.150401 / 2.170415 / 1.751871 s, all exact 10,000-record assertions pass. Strict latency remains open (two failures), index remains 1,320,326 bytes and meets the size criterion. Final 253 unit cases / 337 executions plus three UI cases pass; runtime QoS warning in unchanged fixture retained. Prototype failures, overlapping measurements and fixture synchronization are documented. No commit or complete-application startup approval in this interaction.

**ZF-42 Release round, 2026-10-06:** before extending equivalence tests, compare the exact baseline and combined production sources under application Release optimization/concurrency settings. Six isolated fresh processes pass all oracle/scan/idle checks; combined reopens take 0.711478 / 0.683182 / 0.648278 s, median 0.683 s versus baseline 14.166 s. Isolated latency and 1.259 MiB storage pass; signed full Release build passes. Application launch-to-usable timing at scale, cold Release and broader equivalence remain pending, so ZF-42 stays open. No production changes, new unit/UI executions or commit in this round. [Raw data and boundaries](Documentation/Benchmarks/tag-catalog-optimization.md#release-comparison--2026-10-06).

**ZF-42 user-authorized correctness gate and implementation, 2026-10-06:** the combined optimization passes 76 differential checkpoints and final 257 unit cases / 348 executions plus three serial UI cases. Independent expectations identify preexisting Unicode scope-boundary and physical journal-alias defects; both are corrected with failing-before/passing-after tests. The accepted functional reference explicitly shares the journal repair and records its sole known Unicode omission. Index generation 4 rebuilds potentially incomplete older catalogs once, including staged grants; later valid caches reuse normally. Final Release build/signature pass. [Detailed evidence and finite proof boundaries](Documentation/Benchmarks/tag-catalog-equivalence.md). Implementation is accepted within characterized contracts; ZF-42 remains open for full-app acceptance, distinct-label/high-link-density and extended OR-19 checks. No commit is requested or made in this interaction.

**ZF-42 exact-current Release acceptance:** median cached readiness 0.820 s (all samples 0.820065 / 0.857169 / 0.733745 s), versus repaired reference 14.214 s; storage 1.259 MiB. All 18 benchmark invocations pass, including complete controlled cold discovery (median 35.224 s). Isolated criteria are satisfied after correctness repairs; whole-app acceptance and extended OR-19 remain open. [All samples and limits](Documentation/Benchmarks/tag-catalog-optimization.md#release-acceptance-after-correctness-repairs--2026-10-06).

**ZF-41 / ZF-42 first-pass diagnosis, 2026-10-07:** cache reuse is confirmed by the user; the recorded cold Debug scan is 456.464 s and cached restart 0.416 s. Five aggregate-only real-tree traversal/catalog/coverage profiles and three logging invocations identify broad metadata probing plus approximately 83% suspension as the proven isolated latency costs. The immutable/current raw scanner outputs and counts match; no raw regression is reproduced. Existing batch logs remain in Release and cost 15.370 ms for 1,000 observed synthetic deliveries. The exact signed Debug-versus-isolated timing gap remains unassigned and requires a controlled full-app cold A/B; this diagnostic is not a delivered cold-latency fix. Production/cache/test expectations are unchanged, no new unit/UI run or commit. [Evidence and next acceptance boundary](Documentation/Benchmarks/tag-first-index-diagnosis.md).

**ZF-41 / ZF-42 optimization round, 2026-10-23/24 (implemented; D-41 still open):** user-authorized. Six candidates measured one at a time with interleaved fresh processes; all kept: `listxattr` prefilter, bulk Finder-info package pre-check, bounded pause-overshoot credit, thread-CPU duty accounting, no visibility worker for empty checkpoints, contiguous scope-prefix and allocation-free component checks. A longer-slice budget was measured (about 10%) and rejected as a contract change. Quiet isolated real-tree first pass 177.733 → 88.895 s median with the exact final source (identical records); sandboxed catalog-path proxy 192.465 → 99.516 s; cached 10,000-record reopens below 2 s in every Debug (median 1.582 s) and Release (0.298 s) sample. Remaining: signed-application cold and 10,000-record timings (protected container index), D-52 tag UI host dependency.

**User decision, 2026-10-24 — CPU duty cycle removed (implemented, uncommitted):** "now that we've mostly solved the cost of the operation, remove the CPU usage limit." The scanner, incremental reader and visibility validator keep 128-item/8 ms slices, batch publication, utility priority and cancellation, but only yield at slice boundaries. Real Home/Shared first pass 86.161 → **5.418 s** isolated, sandboxed catalog path 99.021 → **5.345 s** (identical records); the 60 s target passes in these workloads. Cost: about 99% of one core (peak 1-s window 100.5%) for about 5 s, no main-thread stall over 50 ms, thermal state nominal. 10,000-record reopen medians 0.191 s Debug / 0.146 s Release. TagCatalogTests 62/90, full unit 367/557 and 76 differential checkpoints pass. Signed-application acceptance still pending.

**Concurrent traversal experiment, 2026-10-24 (measured; rejected by the user; code removed):** multi-worker rejected by the user; the default and only mode is one worker. Historical record (after removal, the final one-worker source passes 62/90 tag tests and 76 equivalence checkpoints unlocked; see REGRESSION-COVERAGE): `Budget.workers` selects a shared directory work stack; `FinderTagCatalog(scanBudget:)` passes it through. Thermally settled sweep: isolated 5.065 s (1), 3.908 s (2), **2.576 s (4)**, 2.821 s (8), 2.675 s (10); CPU-seconds 5.0 → 10.1 → 20.0; identical results for every count; no main-actor stall. Recommended default: keep one worker. New tests cover parity with one worker on an uneven tree (2/4/8 workers, five repetitions, Foundation fallback), cancellation and catalog checkpointing. While the screen was locked, the seven D-49 contracts and the new catalog test failed because protected checkpoints cannot be reopened (root cause recorded in D-49). Unlocked reruns of the tag tests, full suite, equivalence checkpoints and D-43 reopens are pending (REGRESSION-COVERAGE). [Evidence](Documentation/Benchmarks/tag-first-pass-optimization.md#concurrent-traversal-experiment--2026-10-24-historical-rejected-and-removed). Tests and differential results are in REGRESSION-COVERAGE. Uncommitted. [Evidence](Documentation/Benchmarks/tag-first-pass-optimization.md).

**User decision, 2026-10-07 — initial-index optimization remains pending (D-41 / OR-19):** retain this as future work after the diagnostic investigation. Next work must attribute the signed-application timing gap with a controlled cold A/B, then reduce traversal/metadata and suspension costs without sacrificing tags, visible Home/Shared boundaries, hidden-item exclusions, cache reuse, bounded resources or post-completion quiescence. The existing real-tree 60-second target remains unmet. No further implementation or measurement is performed for this recording request.

**Commit request, 2026-10-07:** the user authorizes committing the pending high-tag-count benchmark, accepted catalog implementation/tests/contracts and first-pass diagnostic evidence in separate responsibility-based commits. Commit preparation verifies the unchanged production fingerprints, existing executed regression counts, JSON/script integrity and staged diffs. No further functional optimization or new test execution is introduced; D-41 / OR-19 and full-application acceptance remain pending.

The high-tag-count benchmark is committed as `c29ff8a`; the accepted catalog implementation, corrections, tests and contracts are committed as `646aee2`. First-pass diagnostic harnesses, measurements and the explicit pending optimization are recorded in the separate documentation/diagnostic commit accompanying this entry.

### ZF-43 — MCP server and Apple Intelligence integration (implemented; actual system verification pending; 2026-10-07)

The bundled executable exposes eight MCP tools over stdio using official Swift SDK 0.12.0, with separate explicit automation folder grants, bounded jobs/listings, real ZIP/7z operations and connection-local cancellation. Four localized App Intents actions reuse the same operation services; Settings copies ready-to-use configuration and explains/opens the Mac Shortcuts setup. The user-approved picker-to-MCP ZIP/7z round-trip passes; four actions appear in the Mac editor after signed build 2 installation. Unsupported automatic Mac App Shortcuts were removed. A saved native integrity action completes after the protected-path authorization fix; the temporary grant is revoked. The custom Compactar com Zforge shortcut is saved with 7z and Ask Each Time inputs, but three actual Siri queries cannot find its name. The user subsequently personally validated the compression shortcut after authorizing an omitted folder. The standard Xcode Debug bundle was refreshed to signed build 2 with all four actions/eight tools and existing grants. Siri/Spotlight invocation and onscreen context remain separate acceptance checks. Final regression passes 276 cases / 368 executions, including both localized Settings and adjacent compression Settings UI cases. Foundation Models is outside scope. [Requirements and validation boundaries](Documentation/Requirements/AGENT-INTEGRATION-PLAN.md); [usage](Documentation/Requirements/AGENT-USAGE.md); OR-20. Executed tests, builds and pending system/resource checks are recorded in REGRESSION-COVERAGE. D-46 records the preexisting startup-fixture assertion reproduced on unchanged HEAD. No commit is requested or made.


### ZF-43 follow-up — Contextual folder permission (2026-10-07; implemented and verified within the recorded matrix)

Both MCP and Shortcuts request missing folder access through a localized native picker. All required scopes precede archive work; explicit consent persists and the same invocation resumes. Cancellation, scope mismatch, foreground unavailability and disconnection cannot create output. Coalescing and independently cancellable waiters are bounded within each process. Tests cover actual archive continuation, grant persistence/reporting, existing grants, minimal directory scopes, root-path refusal, mismatch, cancellation/retry and concurrency. Actual stdio cancellation and consent/listing/ZIP/7z round-trips pass on the synthetic approved folder. Final regression passes 286 cases / 378 executions with zero failures/skips. Installed native Shortcuts integrity cancellation, same-invocation consent/resumption and reuse pass. Unit/UI and release evidence are recorded separately in REGRESSION-COVERAGE. Existing user-created grants remain intact.


### ZF-43 — Consolidate redundant automation grants (2026-10-07)

The user approves replacing covered child grants when a parent is authorized and avoiding redundant additions under an existing parent. The shared store implements physical-boundary consolidation, validation before one persistence commit, legacy redundancy cleanup, independent outside-symlink permissions, active lease retention and post-consolidation capacity checks. Revoking the remaining parent does not restore children. Eight new automated scenarios cover the contract; initial failures and final evidence are recorded in REGRESSION-COVERAGE. Final regression passes 294 cases / 386 executions with zero failures/skips. Signed Release build 6 is installed. Actual native Settings child → parent → child-again → revocation sequence passes using only the approved synthetic root; the three original user grants remain. Broader OR-20 checks remain separate. No commit is requested or made.


**ZF-43 commit request and Siri continuation, 2026-10-07:** the user authorizes committing the pending native/MCP integration, contextual consent, grant consolidation and associated contracts/evidence. Separate primary API reference captures from the cohesive functional implementation. Preparation verifies the final source/test fingerprints, recorded 294-case / 386-execution result, JSON/script integrity and staged diffs. No new test execution is claimed by re-reading evidence. Siri remains unresolved under D-47 / OR-20 and is the next active investigation.

### ZF-43 commit and Siri schema continuation — 2026-10-08

The preceding work is committed as `333ff18` (native API corpus) and `66eee37` (MCP/native actions, contextual consent and grant consolidation with synchronized contracts). No push is performed. Subsequent implementation adds a macOS 27 system.open archive entity action, shared URL opening, bounded authorized name/path discovery, thirteen behavioral cases and localized metadata. Final unit regression: 304 cases / 396 executions, zero failures/skips. The final rehydration UI runner failed before scenarios; isolated UI status is recorded separately. Signed Release build 9 is prepared, with the previous build preserved for rollback. Actual new-action discovery/execution and Siri results are tracked separately; Current Date control refusal shows an independent conversational shortcut-routing problem. ZF-43 / OR-20 remain open for actual Siri/Spotlight/onscreen and broader resource/platform acceptance.


**Siri retry with user available for approval:** build-9 asynchronous copy failure is corrected by one-use scoped window handoff and password-lifecycle ownership. Sixteen action/entity/lifecycle contracts pass; complete build-12 unit regression passes 307 cases / 405 executions, zero failures/skips (final encrypted window-close argument recorded in REGRESSION-COVERAGE). Installed native build 10 passes cold/repeated opening, missing-folder cancellation/consent/continuation and all-mode content continuity. Fresh conversational Siri still refuses the verified saved shortcut and full-path/action request before invocation, so no approval prompt appears. Signed build 11 is installed with corrected English/pt-BR Settings guidance; System Default is restored and the synthetic grant revoked. No personal permission or shortcut is changed. The primary schema corpus is committed as f7e8b67; the functional schema/lease slice includes synchronized code, contracts, localization and executed evidence. D-47 / OR-20 remain open; D-48 records the preexisting already-open Settings list refresh gap.

Final password-retry closure characterization fails on prematurely released access before its fix; the local retry lease and post-resolution closed/dismissed/cancelled guard correct it. Exact-final build 12 regression passes 307 cases / 405 executions with zero failures/skips and is installed with rollback preserved. Native evidence remains distinguished from unit results in REGRESSION-COVERAGE.

Exact-final build-12 native contextual opening passes on the approved synthetic fixture. A fresh Siri named-archive/app/folder request refuses direct opening before archive invocation or consent; system routing remains pending. Synthetic access is revoked. This completed implementation slice is committed independently of the two API corpus changes; Siri acceptance is not declared complete.

**Voice control and Apple Intelligence scope follow-up, 2026-10-11:** the user reports successful spoken Clock Check and saved Zforge Siri Open Archive invocation, and clarifies that shortcuts already worked and continue to work. Stop treating repeated saved-name tests as the next discovery gate. The next implementation milestone is explicit authorized archive-entity Spotlight indexing and direct opening, followed by onscreen context; [scope, acceptance and platform boundaries](Documentation/Requirements/AGENT-INTEGRATION-PLAN.md#next-apple-intelligence-implementation-milestone--2026-10-11). Earlier typed refusals remain separate results. No implementation or automated-test result is added; ZF-43 / OR-20 remain open for direct schema discovery, Spotlight, onscreen targets and broader acceptance. Free-form compression/extraction remains a separate public-schema gap in the checked SDK.

**ZF-43 entity milestone, October 11:** bounded explicit archive indexing, lifecycle cleanup/reindexing, versioned Spotlight opening, all-mode archive context, directory-alias association and persisted-change Settings refresh are implemented. Signed build 14 is installed with builds 12/13 retained for rollback. New index/performance contracts pass; name discovery is 49 ms, snapshot 51 ms and native initial 100-entity donation 150 ms. The actual build-14 MCP ZIP/7z round-trip passes. The complete final unit run has seven tag persistence failures reproduced on unchanged `2d25d0d` (D-49); the Automation UI runner executes no scenarios because automation-mode initialization times out. These limits block full regression/polish approval. The user reports successful build-13 Spotlight opening, while direct English Siri name resolution still fails; build-14 contextual typed execution is inconclusive. The minimal control is specifically authorized and executed: baseline Spotlight opening is confirmed by the corrected user report, native UI and identifier/perform trace; direct typed nominal/contextual requests refuse. File-entity variants extend the local reproduction without establishing a production fix. Preserve parallel localization work; isolated integration results do not approve it. ZF-43 / OR-20 / D-47 remain open for direct Siri/context and broader platform/UI conditions. D-48 native concurrent refresh remains pending. No new commit or push is requested.

**ZF-43 independent control follow-up, October 11:** baseline Intent Probe Spotlight opening is user-corrected and natively confirmed. The bundled file-schema voice comparison activates the app but its screenshot and logs show no perform. A transport test reproduces diagnostic identifier equality rejection, and URL-based resolution passes five contracts / seven executions without relaxing expectations. Signed sandbox-only Release build 2 is installed; typed direct resolution still refuses before the installed query. The corrected spoken route returns one entity for each of five installed-process identifier queries but still does not perform. System action dispatch and a separately tested production file-entity migration remain the next gates. This diagnostic fix does not change Zforge source or close D-47 / OR-20.

**Requested file-identity refinement:** the separate diagnostic now returns the received FileEntityIdentifier after validating its fixture URL. The additional exact-identity contract fails before and passes after that change (six contracts / eight executions). Release build 3 compiles without warnings, is installed with strict signing and sandbox-only entitlements, and starts with No OpenIntent has run plus a completed synthetic index. Two out-of-process tests against installed Release build 3 now pass: name resolution and Spotlight-index retrieval each execute OpenIntent and change the visible window status. Their process-specific perform traces occur at 18:03:41.706 and 18:03:46.463. Final unit regression passes six contracts / eight executions. Native Spotlight result selection and Siri language recognition remain separate acceptance gates. Any production file-entity migration must preserve transported identity without treating it as an automation grant; live authorization remains mandatory.

**Build-3 spoken control accepted:** the user reports The OpenIntent ran after the requested fresh English Siri utterance Open Lyra Control.zip in Intent Probe. Own Routing diagnostics correlate an identifier query/return and perform at 18:14:18.886 (PID 40699). Proceed with a modern files.file adapter for Zforge, preserving its existing path-based discovery/authorization, bounded index lifecycle, physical alias mapping, macOS 26 entity/action and saved String-target action compatibility. The modern index and onscreen associations must use the same transported file identity. File identifiers and explicit-path drafts never confer automation grants. Production acceptance remains pending until delivered tests and the installed Zforge Siri flow pass.

**ZF-43 production file adapter checkpoint, 2026-10-12:** signed build 22 is installed. The files.file adapter preserves transported identity and current folder consent; file publication caches donated identities and refreshes same-path replacements. Cached physical-resource hints repair directory-presentation context without row-level disk access. Full regression passes 352 cases / 528 executions. Installed name and Spotlight action dispatch and actual MCP ZIP/7z round-trips pass. Selected onscreen annotations remain an explicit failed native gate despite visible selection and correct authored provider state; the standard-association/trait experiment is reverted. A native List control also fails annotation retrieval, without proving a platform cause. Fresh English Siri opening is requested on the installed app and remains pending. OR-20 / D-47 and the recorded D-49 intermittency remain open. No new commit/push or personal grant change. [Exact production evidence](Documentation/Benchmarks/archive-file-schema-results.json).

**Build-22 conversational result, 2026-10-12:** the user reports refusal/file-not-found for the requested fresh English Open Orion Demo.zip in Zforge comparison. Native Siri inspection confirms the exact request and response: I couldn’t find the file “Orion Demo.zip” on your Mac. Please make sure the name is correct and try again. The retained authored interval contains successful two-archive publication at 07:37:21.836 (PID 48112), but no name/identifier query or perform; missing info-level events alone are not a unique-cause proof. Direct Siri opening remains failed, separately from the passing installed system dispatch and MCP tests. The next comparison audits overlapping legacy/new assistant metadata and the control’s entity discovery contract. No permission or global cache reset is introduced.

**Location and modality comparison, 2026-10-12:** an exclusively created 179-byte Vega Demo.zip copy is placed in the preexisting authorized Documents root; the original temporary fixture and all personal grants remain. A native installed-build-22 scenario passes name and Spotlight retrieval/opening twice and reveals Readme.txt. Fresh typed English requests by name and explicit path both receive file-not-found, without a subsequent retained authored action event. The equivalent typed Lyra Control request also fails in the control that previously passed by voice. This does not prove that the temporary directory is irrelevant to spoken routing, that the typed and spoken entry points are equivalent, or that a metadata difference causes the production refusal. The preferred bundle path is still /Applications/Zforge.app. Build 23 adds retained path-free query/suggestion diagnostics for the next spoken comparison; no discovery expectation is changed.

**Installed diagnostic build 23, 2026-10-12:** the update changes only retained, path-free query/suggestion diagnostics; lookup, intentionally empty suggestions, published identity, schemas, permissions and opening remain unchanged. The affected suites pass 49 distinct cases / 57 executions with zero failures/skips in /tmp/ZforgeSiriDiagnostics23.xcresult. Signed Release compiles without warnings, verifies strict signing and is installed with build 22 retained. The installed Documents scenario passes one case and both name/Spotlight executions in /tmp/ZforgeSiriDocuments23.xcresult, showing Readme.txt; authored query/return counts are retained and both return one entity. Full build-22 regression remains the 352-case / 528-execution baseline, not a relabeled build-23 run.

The preparation baseline for the fresh spoken Vega/Probe comparison is captured after the user unlocks the Mac. At 18:30 UTC on 2026-10-12, installed Zforge build 23 is running as PID 48770 with Recents visible; installed Probe build 4 is running as PID 50812 and shows No OpenIntent has run and The synthetic entity is indexed. The owned Documents fixture matches its recorded 179-byte SHA-256. No automatic opening is invoked during preparation. The requested fresh, separate English voice sessions are Open Vega Demo.zip in Zforge and Open Lyra Control.zip in Intent Probe. Their subsequent outcomes are recorded below. The baseline is retained in /tmp/ZforgeSiriVoice23-baseline.json; preparation alone establishes no action invocation. No folder grant, app-registration record, privacy setting or global cache is changed.

**ZF-43 checkpoint — 2026-10-12:** correct ZIP and extensionless voice requests still fail production build 23; Probe build 4 executes its action. The retained production interval contains no query/perform. Probe build 5 is an opt-in comparison with an extra hidden String-target open schema: 9 unit contracts / 11 executions and two installed system dispatch scenarios pass; its fresh spoken comparison remains pending. No production lookup, schema, permission or browser behavior changes in this checkpoint. Direct Siri opening, selected onscreen acceptance and actual saved compatibility-action invocation remain open. [Reproduction and next gate](Documentation/Benchmarks/siri-routing-reproduction.md).
**Simpler spoken fixture — 2026-10-12:** at the user's request, the diagnostic fixture is renamed to Test Archive.zip and the current voice phrase is Open Test Archive in Intent Probe, omitting the extension. Installed Probe build 6 retains both build-5 actions and the same 22 ZIP bytes. The refined naming contract fails before the rename (6 distinct cases / 8 executions, one failed case) and passes afterward with all 9 contracts / 11 executions. Two installed name/Spotlight dispatch cases pass; the new title is visible and the previous name returns no exposed Spotlight entity. Existing scenario assertions are preserved, with explicit new-name/retired-name checks. Fresh manual PID 54337 shows No OpenIntent has run and indexed status. Build-5 voice acceptance is superseded by the requested pronunciation change, not recorded as a success or unique-cause failure. The renamed fixture starts a new spoken baseline; its outcome was pending at this checkpoint and is updated in the recovery record below. Production Zforge behavior and its unresolved Siri/selection gates are not changed. [Detailed results](Documentation/Benchmarks/siri-routing-reproduction.md).

**Siri recovery checkpoint — 2026-10-12:** the user reports that Siri works again after changing its language and restarting. Installed Intent Probe build 6, already open, executes the modern action: native AX shows Test Archive.zip / The OpenIntent ran. / The synthetic entity is indexed., and its own Routing log records identifier results count=1 followed by Probe open action invoked at 17:20:23.048 local time (PID 2139), after the 17:11:48 boot. No automatic dispatch test is run in this interval. Both modern and hidden compatibility actions remain in this build, narrowing the hypothesis: the extra hidden action alone does not universally prevent Siri execution. The exact successful utterance and current Siri language are not independently captured; cold-start execution is not established. The language change and restart do not isolate a sole recovery cause. Production build 23 is prepared on Recents at 20:25:28 UTC (PID 2329), with the surviving 179-byte Documents fixture Vega Demo.zip unchanged. A fresh English voice comparison, Open Vega Demo in Zforge, must actually reveal Readme.txt. Production voice acceptance, selected onscreen annotations and saved String-target compatibility invocation remain open. The earlier production refusals remain historical evidence. [Recovery details](Documentation/Benchmarks/siri-routing-reproduction.md).

**Fresh typed Siri comparison — 2026-10-12:** the assistant tests native Siri in separate fresh English conversations, with installed Zforge build 23 (PID 2329) and Probe build 6 (PID 2139). Open Vega Demo in Zforge produces no observed assistant response or archive opening; this conversational result is inconclusive and is not a pass. Open Vega Demo.zip in Zforge explicitly receives I couldn't find the file "Vega Demo.zip" on your Mac. Please check the name and try again. The 179-byte Documents fixture exists and its recorded SHA-256 matches. Zforge remains on Recents, without Readme.txt or any authored ArchiveDiscovery query/perform in the captured 17:40:30–17:43:20 local interval. Open Test Archive in Intent Probe initially exposes only the request. The subsequent fresh full-name request, Open Test Archive.zip in Intent Probe, succeeds: seven identifier query/return pairs count=1 precede a new modern perform at 17:42:48.480. Its already-set window marker alone is not counted as new execution. This establishes typed control dispatch and a current production refusal before an authored query, without identifying a unique cause. These are four manual native Siri requests, not newly executed automated tests. Spoken production, selected annotations and saved compatibility invocation remain separate gates. [Detailed evidence](Documentation/Benchmarks/siri-routing-reproduction.md).

**Availability and registration control — 2026-10-12:** explicit macOS 27 declarations are compared in opt-in Probe build 7. The new metadata characterization fails before the declarations (10 cases / 12 executions; one failed case, three issues), then all 10 / 12 pass; existing assertions remain. Three serial installed-system cases pass, including production build-23 Documents name/Spotlight opening with Readme.txt. Probe 7 nevertheless receives a fresh typed file-not-found refusal before a query/perform. Restored build 6 also refuses, and newer build 8 restores accepted wildcard metadata but still refuses both the original and app-first phrases. Build 8 passes 10 / 12 unit checks and two installed dispatch cases. Therefore availability is not isolated as a cause, and successful native execution does not establish stable Siri routing. A read-only audit finds three temporary app registrations created by this run; the Debug test host has internal name Intent Probe but identifier io.libor.ZforgeIntentProbe.TestHost. Wrong-bundle selection is a hypothesis, not demonstrated causation. Automatic approval rejects unregistering the three temporary targets because it mutates the global Launch Services database, even for narrow paths; nothing is unregistered and no indirect cleanup/reset is attempted. The user subsequently approves the exact targets, but automatic approval rejects the operation again because the policy prohibits global registration mutation even with approval. No registration changes occur; independent tests continue. Production remains build 23; selected annotations and saved compatibility invocation remain open. [Detailed results](Documentation/Benchmarks/siri-routing-reproduction.md).

**Authorized registration comparison blocked; independent requests — 2026-10-12:** the user approves all three exact temporary targets, but automatic approval rejects the same unregistration command before execution because global Launch Services mutation remains prohibited even with authorization. No registration is changed, no workaround is attempted, and approval is not requested again. Two independent fresh English typed requests still fail: Open the archive shown in Intent Probe identifies Test Archive.zip in its response but does not execute; In Zforge, open the archive named Vega Demo.zip reports it cannot search within Zforge or find the file. Installed Probe 8 (PID 6787) remains at No OpenIntent has run.; installed Zforge 23 (PID 6836) remains on Recents, with neither Vega Demo.zip contents nor Readme.txt. Own routing traces retain one publication for each app and no query/perform in the captured interval. The contextual filename response does not establish a successful entity annotation or action binding. These are two manual requests; no automated count or production behavior is changed. Registration causation, production Siri, selected-context and saved compatibility acceptance remain unresolved. [Details](Documentation/Benchmarks/siri-routing-reproduction.md).

**ZF-43 issue recorded — 2026-10-12:** [Direct Siri archive discovery fails before App Intent dispatch](Documentation/Requirements/SIRI-DISCOVERY-ISSUE.md) is open under ZF-43 / OR-20 / D-47. It consolidates reproduction, passing native/Spotlight controls, intermittent Probe routing, unconfirmed hypotheses, the blocked registration comparison and closure criteria. Recording the issue adds no new execution result and does not close the integration gates.

**Delivery split requested — 2026-10-12:** the user requests a validated MCP-only `main` and preserves native Apple integration, including its initial shortcut actions, modern file entity/index/context development, diagnostics and unresolved tests, on `codex/apple-intelligence` for future continuation. This branch retains the full implementation and historical evidence; its unresolved acceptance gates remain open. Shared MCP operations, contextual permissions and grant consolidation remain deliverable. No user grants or unrelated localization work are discarded. The issue records the continuation branch.
### ZF-26 follow-up — Quick tag hover and tag name label (2026-10-26)

**Implemented; unit and UI tests approved.** User-reported bug: sweeping the mouse quickly over the quick-tag circles left several showing + because per-circle tracking areas lost their exit events. Hover now belongs to `FinderTagQuickRowView`, which resolves the circle under the pointer on every enter/move/exit. New request: while a circle is hovered the Edit Tags item shows the tag name (tooltips removed). UI fixtures now use an isolated tag catalog, so the tag UI tests no longer depend on the Mac's own Finder tags. Divergence D-53; also addresses D-52. Evidence in `REGRESSION-COVERAGE.md`; Portuguese, light theme and a manual fast-sweep check remain pending.

### ZF-43 — Siri in-app archive search (implemented on `codex/apple-intelligence`; 2026-10-13)

- [x] Identify the Siri routing boundary from planner traces (`intelligenceflowd`, `searchtoold`) and confirm it with Probe controls.
- [x] Add the macOS 27 Search Archives action (`system.searchInApp`) and a `Search: “term”` results window over authorized direct archives, with onscreen annotations, single-result selection, empty/error states, history and restoration.
- [x] Localize five new strings in all 21 languages; add unit coverage; capture the searchInApp API page in the local corpus.
- [x] Native typed Siri on installed build 25: search, “Open it” with Readme.txt, and “Search for … in Zforge”.
- [x] A request that launches Zforge reuses the untouched launch window, so the launch shows one window; with a window already open, one new window opens (build 26).
- [ ] Spoken Siri acceptance; four-mode/language/size/theme/accessibility visual matrix of the results window; UI-test automation of the window.
- [ ] Single-utterance opening (blocked by Siri's app-entity search; revisit on later macOS releases or report to Apple with a sysdiagnose).
- [x] Resolve the two `TagCatalogTests` failures: a machine-dependent quick-tag test and redundant replay of deferred retry scopes; full unit regression 362/362.
- [ ] Reconcile the branch with MCP-only `main` before integration.


## MCP-only delivery / Apple continuation — 2026-10-12

The user requests that `main` deliver only the validated MCP and preserves native Apple integration on `codex/apple-intelligence` (`0196bd8`). [The issue](Documentation/Requirements/SIRI-DISCOVERY-ISSUE.md) records this continuation branch. Initial Shortcuts actions, later entity/index/context implementation, diagnostic fixtures and native-only tests remain there for future work. Historical native records above do not describe a shipped mainline feature after this split; Siri/selected-context/compatibility acceptance remains open on the branch.

MCP transport, eight tools, operations, contextual consent, grant consolidation and their tests remain. The original relevant baseline passes 34 distinct cases / 35 executions. Two App Intents-only cases and SiriArchiveIntentTests are preserved with the deferred code; they are not weakened or counted as MCP passing coverage. The Settings UI contract deliberately changes from native shortcut setup to its absence at the user's request, retaining localized configuration-copy and permission/cancellation scenarios. Unrelated 21-language localization, ordinary browser behavior and the generic password-cancellation guard are preserved.

Delivery verification: signed Release build **24** is installed and passes strict deep signature validation plus the unmodified actual stdio smoke (eight tools, typed errors, denied access, clean stderr/exit). All **33 affected automation cases / 34 executions** and both serial English/Brazilian Portuguese UI cases pass. The full unit run is **301 cases / 469 executions, one failure**; an immutable archive of original `main` (`dbb5e48`) reproduces the same tag-menu assertion in **318 cases / 492 executions**. This preexisting failure remains unresolved; the full suite is not green. No tests are relaxed. [Recorded evidence](Documentation/Benchmarks/mcp-only-delivery-results.json).

## Apple integration merged into main — 2026-10-13

At the user's request, `codex/apple-intelligence` is merged into `main`, superseding the 2026-10-12 MCP-only delivery split. `main` again contains the native shortcut actions, archive-entity discovery/indexing, onscreen context and the macOS 27 Search Archives action with a single launch window (build 26). The MCP-only records above are historical. The code tree equals the branch head, whose full unit regression passed 362/362. Open acceptance gates are unchanged: spoken Siri, selected-context annotations and saved String-target compatibility invocation remain unverified; see [the issue](Documentation/Requirements/SIRI-DISCOVERY-ISSUE.md).

### ZF-44 — Finder shortcut-menu integration (OR-21; 2026-10-27)

**Implemented; unit and Finder UI tests approved; broader visual matrix pending.** The user asked which Zforge actions could join Finder's shortcut menu, decided that nothing should sit beside Finder's native archive items at the top level, and asked for implementation. Delivered: the `ZforgeFinderExtension` Finder Sync extension with one Zforge submenu offering the browser's action matrix, an app-group request inbox woken by `zforge-finder://requests`, execution in a browser window through the context menu's own handlers (authorization per folder, passwords, conflicts and progress unchanged), Settings > Finder status, and D-54 (missing Add to Archive symbol). Follow-ups the same day: the user's symbol set with theme-painted Finder copies (D-55), and Open's `arrow.up.forward.app` symbol. Contract: [CURRENT-STATE](Documentation/Requirements/CURRENT-STATE.md#finder-zforge-submenu--2026-10-27-zf-44-or-21); evidence: [REGRESSION-COVERAGE](REGRESSION-COVERAGE.md). Pending items stay in OR-21.

### ZF-45 — Offscreen test layers and per-change test selection (RNF-Q08; 2026-10-27)

**Implemented; Unit plan approved; the 22 remaining UI tests compile but have not run yet.** The user found UI tests too slow and disliked XCUITest taking over the screen, rejected a VM, and asked to minimize XCUITest and to run per change only what it can affect. Delivered:
- **Test plans:** `TestPlans/Unit.xctestplan` (scheme default, offscreen), `UI-Smoke` (5 representative interaction tests) and `UI-Full`, in a shared `Zforge` scheme.
- **Selection:** `Scripts/affected-tests.py` always runs the full `Unit` plan and only the UI tests mapped in `TestPlans/ui-impact.json`. Unmapped source paths select `UI-Smoke` and must be mapped in the same change. `--check` validates the map.
- **Snapshots:** swift-snapshot-testing 1.19.7 for the unit target, with `ZforgeSnapshot` and references under `ZforgeSnapshots/`.
- **Migration:** XCUITest went from 48 tests to 22. Each removed assertion now runs offscreen, or in a kept UI test reduced to one representative mode. The detail per test is in [REGRESSION-COVERAGE](REGRESSION-COVERAGE.md).
- **Rules:** `AGENTS.md` (Test layers and selection) and RNF-Q08.

Pending: one run of the kept UI tests, scheduled with the user because it takes over the screen; D-56.

### ZF-46 — Archive action symbol parity (D-59; 2026-10-27)

**Implemented; Unit plan and snapshots approved; UI run and in-app visual check pending.** The user found the toolbar's archive action icon ugly and chose, from a sheet of alternatives, `archivebox` with an arrow badge, also for the context menu.
- `MenuSymbol.compress` / `.extract` (`Shared/BrowserSelectionAction.swift`) serve Compress, Extract Here, the toolbar button (`ArchiveOperationIcon`, via `ArchiveToolbarAction.symbol`) and the overflow menu's archive item. Compress Custom… and Add to Archive… use `archivebox` with their gear and plus badges. The Finder submenu follows through the shared symbols.
- `MenuSymbolImage.image(for:pointSize:)` draws the badged symbol at the toolbar's 15 pt.

Pending: the mapped UI tests (they take over the screen) and a look at the real toolbar in both themes, enabled and disabled.

### ZF-47 — Archive navigation limits as sliders (2026-10-29)

**Implemented; Unit plan, offscreen slider tests and snapshots pass; real-drag UI test and in-app check pending.** The user chose sliders for both Archive Navigation limits from an interactive sketch and widened the root size limit to 256 MB–16 GB.
- `ArchiveSizeLimitSliderScale` and `LinearSettingsSliderScale` (`Zforge/Models/SettingsSliderScales.swift`) define positions, steps and round values; `ScaleSlider` (`Zforge/Views/ScaleSlider.swift`) is the shared native slider with tick labels, held round values, haptics, keyboard and accessibility; `ArchiveNavigationSettingsSection` hosts both.
- The preference is now `archiveRootSizeLimit` in decimal bytes (`archive.rootSizeLimitBytes`), migrating the former whole-GB key; `ArchiveBrowsingPolicy` owns both ranges.

Pending: `SettingsUITests.testArchiveSizeLimitSliderHoldsRoundValuesWhileDragging` and the other mapped UI tests (blocked: a Debug Zforge held by Xcode's debugger could not be terminated), and a look at the sliders in the running app (drag feel, haptics on a Force Touch trackpad, both themes, VoiceOver).

2026-11-01 (D-62): the real-drag UI test failed on `c127bca` because its 8 pt drag expected 1.06 GB where the specified scale gives 1.03 GB at the real 510 pt width; the app was correct. Test corrected to a slow 10 pt drag plus a drag back, expectations kept; offscreen `SettingsSliderTests.dragDistancesAtSettingsWidth`. The UI test now passes (REGRESSION-COVERAGE). Still pending: the look and feel in the running app (haptics on a Force Touch trackpad, both themes, VoiceOver).

### ZF-48 — Sidebar icon tint like Finder (2026-10-29)

**Implemented; offscreen tests added; Unit plan, snapshot review and in-app check pending (see REGRESSION-COVERAGE).** The user compared the sidebar with Finder: Locations icons must be light gray rather than accent, and every icon must turn gray in an inactive window, as the Remote icon already did.
- `SidebarIconTint` (accent/neutral role) and the shared `sidebarIconStyle` modifier (`Zforge/Views/BrowserNavigationViews.swift`) read the native `appearsActive` environment. The Locations section sets the neutral role once, so rows added to it inherit it; mounted network volumes are neutral too. Recents and Remote use the same style, so all icons match when inactive. Tag dots keep their color while active and turn gray in an inactive window (user request, 2026-10-30). 2026-10-30: every row name uses the shared `sidebarLabelStyle` and turns gray in an inactive window, as in Finder (Recents and Remote through `SidebarActionRow`).

### ZF-49 — Sidebar item menu with Finder parity (Favorites; 2026-10-29)

**Implemented; offscreen tests added; Unit plan, mapped UI tests and in-app check pending (see REGRESSION-COVERAGE).** The user asked for Finder's Favorites context menu: Open in New Tab, Show in Enclosing Folder │ Remove from Sidebar │ Get Info, Add to Dock. Add to Dock was then removed at the user's request (OR-22, resolved 2026-10-29).
- `SidebarItemMenu` (`Zforge/Views/SidebarItemMenu.swift`) is the shared model (groups, ids, titles, symbols, enablement, actions) rendered by `SidebarItemMenuContent` in `.contextMenu` and by `nsMenu()` for tests; `SidebarItemMenuActions` runs the commands for a window. Locations reuses it and inserts its volume groups.
- `FileBrowserState.openSidebarDestinationInNewTab(_:)`, `showInEnclosingFolder(_:)` and `showGetInfo(forSidebarDestination:)`; the tab opener is configured per window in `ContentView` and attaches to the window that owns the sidebar (`BrowserWindowLifecycle.window(for:)`).
- Add to Dock is not offered: impossible under the App Sandbox, removed at the user's request (OR-22, resolved). Recents has no menu: it is a virtual location without a folder URL.

Pending: real right-click presentation and Open in New Tab tab attachment in the running app (light/dark, a long language such as German).


### ZF-50 — Inline eject button for ejectable volumes in Locations (2026-10-29)

**Implemented; offscreen tests added (results in REGRESSION-COVERAGE); mapped UI tests and in-app check pending.** The user's “Ventoy” USB drive had no ⏏ button in the sidebar, unlike Finder.
- `SidebarVolume.isEjectable` / `isRemovable` (`Zforge/Services/VolumeService.swift`) with one ejectability policy (`SidebarVolume.isEjectable(_:)`) shared by the sidebar and File ▸ Eject; `VolumeEjection` ejects on a detached task and classifies busy failures (verified: a held file on a disk image throws `NSOSStatusErrorDomain` −47).
- `FileBrowserState.ejectVolume(at:name:)` is the single eject handler (button, File ▸ Eject, sidebar Eject menu item): in-flight tracking (`ejectingVolumeURLs`), `BrowserError.ejectFailed` alerts, and `leaveUnmountedVolume(_:)` moves windows on the unmounted volume to the computer level, also for unmounts observed from outside (`ContentView`).
- `SidebarEjectButton` (`Zforge/Views/SidebarEjectButton.swift`) is overlaid at the row's trailing edge in a reserved 20 pt slot.

Pending: the inline button for Shared network volumes; ejecting while browsing inside an archive stored on the volume may fail as busy if the archive engine still holds the file (not measured); in-app check with a real removable drive (light/dark, inactive window, long language, selected row).

### ZF-51 — Context menu for sidebar Locations items (2026-10-29)

**Implemented; offscreen tests added (results in REGRESSION-COVERAGE); mapped UI tests and in-app check pending.** Right-clicking a Locations item (home, Macintosh HD, “Ventoy”) opened no menu; the user asked for the Favorites options plus Finder's volume items.
- `SidebarItemMenu.location` and `SidebarItemMenuActions.locationMenu` / `computerMenu` (`Zforge/Views/SidebarLocationMenu.swift`) reuse ZF-49's shared menu and insert Eject (ZF-50's `ejectVolume(at:name:)`); `SidebarLocationMenu.commands(for:canEject:)` holds the per-kind rules; `SidebarVolume.locationKind`, plus `isRootFileSystem` in `VolumeService`.
- ~~Rename~~ (removed 2026-10-30 at the user's request, OR-25 resolved: the App Sandbox denies Disk Arbitration's `system.volume.removable.rename` authorization, so renaming “Ventoy”, mounted by root, failed with “You don’t have permission to rename “Ventoy”.”; the rename code below, `VolumeRenamer.swift` and its strings were deleted, volume roots can no longer start the content rename (`FileBrowserState.canRename(_:)`), and only `followRenamedVolume(from:to:)` remains, for volumes renamed by Finder or Disk Utility): `SidebarState.renamingVolumeURL` / `volumeRenameDraft`, inline `SidebarVolumeNameField`, `FileBrowserState.renameVolume(at:from:to:)` (Disk Arbitration's `DADiskRename` through the injected `VolumeRenaming` / `DiskArbitrationVolumeRenamer` after activating the grant covering the volume, the access panel when there is none, and localized messages per dissenter status — fix of the user's 2026-10-30 report that renaming “Ventoy” failed with “You don’t have permission to save the file “Ventoy” in the folder “Volumes”.”) and `followRenamedVolume(from:to:)` on `NSWorkspace.didRenameVolumeNotification`.
- Erase Disk… is not offered: first delivered as opening Disk Utility, then removed at the user's request (2026-10-30) because the App Sandbox blocks erasing (OR-23, resolved).
- Remove from Sidebar hides a Finder category: `FileBrowserPreferences.hiddenSidebarLocations` (`SidebarLocationCategory`), Settings ▸ Sidebar (`SidebarSettingsSection`) re-enables it; the computer row (ZF-52) and the Locations/Shared rows honor it.

Pending: in-app right-click on a real removable drive, the boot volume and a network share (light/dark, a long language); following a mount point renamed in Finder or Disk Utility in the app; an in-app check that Rename is disabled for volume roots at the computer level; comparison with Finder's menus for the boot volume, network shares and the computer item; Open in New Tab / Get Info for the computer item.

### ZF-52 — Computer item in sidebar Locations and the computer level (2026-10-29)

**Implemented; offscreen tests added; results and pending checks in REGRESSION-COVERAGE.** The user reversed the earlier decision that Zforge did not need Finder's computer shortcut: Locations now starts with the computer item (the Mac's system name, e.g. “MacBook Air de Felipe”), which opens Finder's computer level (mounted volumes and Network). Contract in CURRENT-STATE §2 and the UI-UX-GUIDE sidebar section.
- `ComputerIdentity` (`Zforge/Services/ComputerIdentity.swift`): system computer name and model-family symbol from the device-model type hierarchy; `VolumeCataloging` (injectable volume source) and `ComputerLevelCatalog` (volume and Network items).
- `BrowserLocation.computer` handled by every location switch; `FileBrowserState.navigateToComputer()` (Go ▸ Computer, `⇧⌘C`, previously `/`), `refreshComputerLevel()` on mount/unmount/rename, and the volume access check for open and List expansion.
- `SidebarComputer` (`SidebarState.computer`, kind `SidebarLocationKind.computer`) and `SidebarComputerRow`; visibility uses the `computer` category of Settings ▸ Sidebar (ZF-49 follow-up for Locations menus), shown by default.

Pending: in-app check of the row and the computer level in the four modes (light/dark, a long language, narrow sidebar), real mount/unmount while the level is visible, and the mapped UI tests. Not done: disabling Duplicate/Compress/Move to Trash for volume roots at the computer level (the system currently rejects them with its error), and a Finder-like proxy icon for the computer window.

**Follow-up — Network at the computer level and the Network level (2026-10-30, user request “Também não tem o Network”). Implemented; offscreen tests added; results in REGRESSION-COVERAGE.** Network was never listed because the catalog required a `/Network` folder, which macOS 26 does not have.
- [x] Network always listed at the computer level with the system network icon; the `/Network` assumption and `VolumeCataloging.networkURL()` removed (contract change recorded in CURRENT-STATE and `ComputerLocationTests`).
- [x] `BrowserLocation.network` (level) and `.networkServer(URL)` (server item) in every location switch; Go ▸ Network (`⇧⌘K`) opens `Computer › Network`.
- [x] Bonjour discovery (`NetworkDiscovery.swift`: `NetworkServerBrowsing`, `BonjourNetworkServerBrowser`), live and cancelled with the level or the window; empty and access-denied states (`NetworkLevelViews.swift`); `NSBonjourServices` and localized `NSLocalNetworkUsageDescription` (`InfoPlist.xcstrings`).
- [x] Opening a server mounts through the system connect flow (`NetworkServerMounting`, `WorkspaceNetworkServerMounter`) and opens the share.
- [ ] In-app check with a real SMB server (discovery, Local Network prompt, denial, mount, four modes, light/dark, a long language); gaps in OPEN-REQUIREMENTS “Network level gaps”.

**Follow-up — Add Remote in Network and Network in Locations (2026-10-30, user request). Implemented; offscreen tests added; results in REGRESSION-COVERAGE.** The user removed the “No Servers Found” notice and spinner, moved the sidebar's Shared ▸ Remote row into the Network level as **Add Remote**, and asked for Network in sidebar Locations while keeping it at the computer level.
- [x] `NetworkLevelBar` (top of the Network level in every mode, independent of the server list) with **Add Remote…** → `FileBrowserState.showServerConnection()`, shared with Go ▸ Remote (`⌘K`) and the single sheet in `ContentView`. Empty state and spinner removed; “Local Network Access Is Off” kept (`NetworkLocalAccessDeniedView`).
- [x] Sidebar: Remote row removed; Shared header hidden without mounted shares; `SidebarActionRow` kept for Recents.
- [x] Sidebar Locations ▸ Network (`SidebarNetworkRow`, shared `SidebarVirtualLocationRow` with the computer row) after the volumes; `SidebarLocationCategory.network` with its Settings ▸ Sidebar toggle; menu `SidebarItemMenuActions.networkMenu()` (Remove from Sidebar only). **Superseded by ZF-63 (2026-11-09): removed from the sidebar.**
- [ ] In-app check of the bar in the four modes (light/dark, a long language, narrow width), the sheet from Add Remote, the sidebar row's highlight/inactive gray, and the mapped UI tests.

### ZF-53 — Toolbar search with Finder parity (2026-10-30, OR-24)

**Implemented; offscreen tests added; results and pending checks in REGRESSION-COVERAGE.** The user asked for search in the toolbar with the magnifying glass to the right of the archive/Share/Tags/More group.
- [x] `toolbar-search` item after the action group in its own capsule; `⌘F` File ▸ Find; overflow **Search** below 678 pt; inline field with debounce, Return, clear, Escape and click-away collapse (`BrowserSearchViews.swift`).
- [x] Scopes This Mac (Spotlight `NSMetadataQuery` in authorized roots) and Current Folder (recursive folder walk or open-archive listing), streamed in batches, cancelled by new queries, reloads and window close (`BrowserSearchService.swift`).
- [x] Virtual results location `Searching “query”` in the four modes with history, path bar of the selected result, opening results at their real path (`FileBrowserState`).
- [x] Nine String Catalog keys translated into all 21 languages; `Find ⌘F` in the shortcut help.
- [x] The open field stays in the toolbar at every supported width (D-66, 2026-11-01; preexisting): search-aware stages and no toolbar title in the smallest stage. Offscreen: `BrowserWindowLayoutTests.searchFieldFitsAtEveryWidth` (640–1,200 pt), `ToolbarLayoutTests.expandedSearchStages`.
- [x] Clearing the search from Recents or a tag lists that place again (D-64, 2026-11-01; preexisting): the reload no longer runs in the cancelled debounce task. Offscreen: `BrowserSearchStateTests.leavingSearchRestoresOriginListing` (5 origins × 3 exits), `BrowserWindowLayoutTests.deletingSearchTextRestoresRecents` (four modes).
- [x] ⌘F focus (D-61, 2026-11-01): the field never took keyboard focus because SwiftUI focus does not reach toolbar items; `ToolbarSearchTextField` takes the first responder itself, Escape returns focus to the content. Offscreen: `BrowserWindowLayoutTests.findFocusesToolbarSearchField`, `emptySearchFieldCollapsesOnFocusLoss`.
- [x] Visual review of the field (2026-11-01, offscreen captures of the real window; REGRESSION-COVERAGE “Search field visual review”): four modes, light/dark, German, 640–1,200 pt, accessibility label and keyboard focus, Reduce Motion. Found and fixed D-66. Still unreviewed: a real VoiceOver session and the Liquid Glass look on screen (offscreen captures draw no sidebar material).
- [ ] OR-24 gaps: This Mac beyond authorized folders, content matching and tokens, live result updates, restoration.

### ZF-54 — UI test isolation from saved preferences (2026-11-01, D-63)

**Implemented; offscreen tests added; results in REGRESSION-COVERAGE.** `testCompactToolbarMenusOpenFromTheirToolbarButtons` failed after `testBlankAreaUsesMoreMenuInEveryView` because fixture launches without a named suite shared the user's `UserDefaults.standard`.
- [x] `FileBrowserPreferences.applicationDefaults(arguments:environment:)`: private `ZforgeUIFixturePreferences` suite cleared at each fixture launch; named suites and ordinary launches unchanged (`UIFixturePreferencesIsolationTests`).
- [x] Audit (2026-11-01, read-only, results in REGRESSION-COVERAGE “Preferences audit”): the user's `browser.viewMode` is now `list` (not `gallery`); the original value is unknown. Test traces found in the user's domain: fixture window frames, test tag names in `browser.knownSidebarTags`, a `/tmp/ZforgeAutomationSmoke-20261007` automation folder; 35,555 leftover unit-test suite files in the container.
- [x] Isolation completed (2026-11-01, user decision): any `--ui-` argument marks a UI test launch (drag and Finder fixture launches were missed); `ZforgeDefaults.application` serves `FileBrowserPreferences.shared`, `PinnedFolderStore.shared`, `AutomationGrantStore.shared` and `AppLocalization.currentLocale`; `UITestLaunchIsolation` turns frame autosave off in every window and sidebar split view and gives open panels a `ZforgeUITest` identifier. Offscreen: `UIFixturePreferencesIsolationTests`, `UITestLaunchIsolationTests`. Real-window confirmation (2026-11-01, 19 UI tests): no fixture frame keys reappeared; panel state under `ZforgeUITest` identifiers.
- [x] Unit test host isolated (2026-11-01, D-68): own private suite, no window autosave, no user grants; tests never touch `.standard`.
- [x] Test suites named `ZforgeTestSuite.…`, emptied at the end of each test and swept once per run, so at most one run's files remain (2026-11-01, D-68); snapshot recording through attachments (`Scripts/export-snapshots.py`).
- [ ] The user decides what to restore (list in REGRESSION-COVERAGE); nothing was changed by the agent.


### ZF-55 — In-place archive reading, nested-archive removal and preview limits (2026-11-01, D-73)

**Implementation requested by the user on 2026-11-02.** Contract: OPEN-REQUIREMENTS “In-place archive reading, nested-archive removal and preview limits (D-73)”. Steps proposed:
- [x] Characterize the affected contracts and tests (opening, staging, materialization, nesting, extraction, validation, add/remove/reorganize, preview limits, Settings) and record the baseline run. *Stage 1 (2026-11-02): opening, staging, materialization, extraction, validation and add/remove/reorganize, baseline `Unit` 597 tests with 1 preexisting failure; stage 2: nesting and its settings; stage 3: the 10 MiB preview limit, thumbnails and Settings.* Performance acceptance is structural, not timed (user, 2026-11-02: no execution-time measurements based on archive size in tests): tests assert that opening and browsing create no copy of the archive or its volumes, that bytes read from the source while listing stay bounded by the index (instrumented stream), that previews and thumbnails respect the limits and the solid-block rule, and that extraction, validation and writes use no temporary copy of the archive.
- [x] Read in place with a file fingerprint; parent-to-children index; streaming compressed tar; one-pass write next to the original; no copies for extraction and validation. *Stage 1, 2026-11-02; also direct export and solid-block metadata (exposed only). Evidence: REGRESSION-COVERAGE “In-place archive reading — ZF-55 stage 1”.*
- [x] Remove nested navigation and its settings; open an inner archive in a new window with a shared session and write-back on the last close. *Stage 2, 2026-11-02; evidence: REGRESSION-COVERAGE “Inner archive windows and shared sessions — ZF-55 stage 2”.*
- [x] Preview/thumbnail limits, the solid-archives checkbox and removable/remote settings with the generalized logarithmic slider; localization of every new string. *Stage 3, 2026-11-02; evidence: REGRESSION-COVERAGE “Preview limits and opening progress — ZF-55 stage 3”.*
- [ ] Synchronize CURRENT-STATE, PRODUCT-REQUIREMENTS, REGRESSION-COVERAGE and D-73; run `Scripts/affected-tests.py --run`. *Done for stages 1 to 3 (2026-11-02).* Pending outside the implementation: checks on real removable and network volumes and a visual review of the real windows (see D-73).

### ZF-59 — Keyboard Shortcuts window redesign: sidebar, grouped rows and key caps (2026-11-09)

**Implemented; unit tests and snapshots pass; the real window (sidebar material, title bar, search placement) has not been looked at yet. Results in REGRESSION-COVERAGE “Keyboard Shortcuts window redesign — ZF-59”.** User request: the window's spacing, margins and iconography were unsatisfying; approved mockup “option A · Sidebar” (search and category sidebar, All Shortcuts, grouped containers, individual key caps).
- [x] `NavigationSplitView` of 780 × 560 pt (minimum 600 × 420), 206 pt sidebar with search, All Shortcuts, a separator and one row per section with a coloured tile (shared `SymbolTile`, also used by Settings) and a catalog-total count; detail titled by the selected category, 20 pt margins, section headers only in All Shortcuts, 32 pt rows with inset hairlines (`KeyboardShortcutsView.swift`, `SymbolTile.swift`).
- [x] Key caps parsed from the existing shortcut strings (`ShortcutNotation`): one cap per glyph, wider word-key caps, “or” between alternatives, pointer gestures as secondary text, localized spoken form for VoiceOver (`ShortcutKeyCaps.swift`).
- [x] 12 new strings in all 21 languages (the four gesture words are taken from the existing `⌘ + drag`-style translations).
- [x] Catalog data and the search contract unchanged; `KeyboardShortcutCatalog.sections(in:matching:locale:)` adds the category filter.
- [x] Follow-up after the user's first real run (2026-11-09): compact 32 pt title bar with a small grey title, larger sidebar rows and text. Fixed with the toolbar extracted from Settings into `WindowToolbar.swift` (`windowToolbar(title:)`, `unifiedWindowToolbarStyle()`, shared by both windows), Settings sidebar row metrics and system-colour tiles, and the detail rebuilt on `SettingsPaneColumn`/`SettingsGroup`/`SettingsRow`; title-bar geometry and row-metric tests in `KeyboardShortcutsWindowTests`. Real-window confirmation by the user pending.
- [ ] Look at the real window in the user's build: sidebar material and selection, search field in the sidebar, window title per category, light/dark, reduced motion, increased contrast, VoiceOver reading of rows and key caps, Dynamic Type/text size. The offscreen snapshots cannot draw `NavigationSplitView`'s sidebar (see REGRESSION-COVERAGE).
- [ ] Native-speaker review of the 12 new translations (modifier names follow Apple's keyboard terms where known; several languages keep the English key names).
- [x] Investigate the intermittent unit-host crash (corrected by ZF-64, D-81) seen while running the full `Unit` plan in this work (see REGRESSION-COVERAGE and D-76).

### ZF-62 — Settings window polish: title bar, flat sidebar, spacing, system colours (2026-11-09, D-80)

**Implemented; unit tests and offscreen snapshots pass; real window not reviewed (see below).** User request: spacing inconsistencies, meaningless sidebar groups, a compact title bar with a small grey title beside the browser's toolbar, and unwanted icon colours; mockup approved with system colours (`settings-mock.html`, “cores do sistema”, both themes). Ids chosen high (ZF-62, D-80) because another agent redesigns Keyboard Shortcuts in parallel and may take the next ids.
- [x] Title bar: 52 pt unified toolbar and the pane title in the toolbar title style (15 pt semibold, label colour) leading-aligned with the content margin, traffic lights centred; measured against the browser window offscreen. `SettingsToolbarAnchor` gives the window a toolbar item because SwiftUI makes the toolbar only then.
- [x] Sidebar: flat list (removed `SettingsPane.groups`), uniform 28 pt rows, 13 pt titles, 20 pt tiles, 8 pt gap; titles checked to fit two lines in every language.
- [x] Detail: `SettingsLayoutComponents.swift` (margins 20, groups 20 apart, header 13 semibold, footers 11 secondary below the group, 36 pt rows, 12 pt padding, small switches); List Columns, Sidebar, Finder and Automation explanations moved to footers; drag-handle alignment kept.
- [x] Tiles: macOS system colours with a subtle top lightening (`SettingsPane.tileColor`).
- [x] Tests and docs: D-80 (changed expectations), REGRESSION-COVERAGE “Settings polish — ZF-62”, CURRENT-STATE, UI-UX-GUIDE.
- [ ] Look at the real window (title bar toolbar anchor, 220 pt sidebar rows, profile page back button beside the title, light and dark) in the user's build; the offscreen run could not show the glass sidebar or run the Settings UI tests (see REGRESSION-COVERAGE).
- [ ] A profile page (`CompressionProfileDetailView`) still uses a grouped `Form`: its fields are shared with the compression dialog; bring it to the same group layout.
- [ ] VoiceOver pass over the new switch rows (title is the switch's label) and the Compression profile rows (NavigationLink with plain style).

### ZF-68 — Deterministic `Unit` plan: four load-dependent failures (2026-11-09, D-86–D-89)

**Corrected in the tests; results in REGRESSION-COVERAGE “Deterministic Unit plan — ZF-68”.** The four tests pass in every full run with the fix; two other full-plan-only failures (ZF-69) still prevent two consecutive clean runs. Requested: make the full `Unit` plan deterministic by fixing the causes of its four recurring failures, without retries, longer timeouts, looser tolerances or skipped tests.
- [x] `ArchiveDiscoveryPerformanceTests` (D-86): no product regression (path unchanged since the October baseline; association does not wait for the main thread); wall-clock and CPU time measure load. The gates now measure retired instructions on a private executor (`WorkMeter`), same workload and limits.
- [x] “Rapid column archive selection…” (D-87, D-28): fixture watchdogs counted main-actor stalls; event-driven waits. “failed” was the fixture's timeout, not a product outcome.
- [x] “File events update tags…” (D-88): initial discovery waits for `waitForIdle()`; live stages count their hang guard in polls.
- [x] “Write-back alerts” snapshots (D-89): IconServices placeholder captured; the test waits until the application icon renders. Reference unchanged.
- [x] Requirements: AGENT-INTEGRATION-PLAN measurement gate; RNF-Q08 rule on clocks in tests.

### ZF-92 — Fix the wording and behavior gaps found while writing the wiki (2026-11-20, D-116)

User request (2026-11-20, in Portuguese): fix the D-116 items, with a test that fails first for each fix; reproduce Validate stopping at the first failure and propose a behavior; propose a design for reviewing and revoking folder access; update the wiki only after the merge into `main`. Results in REGRESSION-COVERAGE “Wiki review findings — ZF-92”.
- [x] Menu titles in title case: New Tab, Open With, Always Open With, Copy Pathname, Restore Defaults (catalog keys renamed, 21 translations kept).
- [x] Load Preview placeholder says why, with the preview limit set in Settings (`ArchiveManualPreviewReason`).
- [x] Password sheet names the action (browse, extract, validate, open, preview, share).
- [x] Settings ▸ General footer: Open With and a Dock drop follow the choice for types that open with Zforge; CURRENT-STATE synchronized.
- [x] `ArchiveNaming.baseName` strips every `.tar.<compression>` the format registry recognizes (`Backup.tar.zst` → `Backup`).
- [x] Content-only encryption: Open, Open With, Quick Look, Share and Load Preview ask for the password; 7z AES wrong passwords reported as incorrect passwords.
- [x] Cancelling a batch extraction or validation is not an error.
- [x] `Zforge/SevenZipHelper.entitlements` removed (unused).
- [x] Validate with several archives tests every archive and lists the invalid ones with their reasons (OR-26, decided by the user 2026-11-21).
- [x] Review and revoke folder access — declined by the user 2026-11-21; not implemented (OR-27).
- [x] The 31 selected UI tests: run 2026-11-21 — 20/20 offscreen and 10/11 real passed; `FinderExtensionUITests` then passed after its menu-item lookup was narrowed (the failure was the lookup's cost in a large Finder accessibility tree, not the elected extension; REGRESSION-COVERAGE).
- [x] Real-window look of the password sheet's new texts, the preview placeholder and the Validate report in German (2026-11-21; REGRESSION-COVERAGE).
- [x] D-117: each engine failure names its cause (validation report, error alerts, extraction, opening, compression), 15 reasons in 21 languages; Base64 no longer probed for other extensions (2026-11-22, user request).
- [ ] D-117: Extract Here cancelled at the password sheet leaves an empty file — fix pending the user's go-ahead.
- [ ] Wiki pages updated after the merge into `main`.

### ZF-91 — Friends pre-release 0.1.0 beta 2 (2026-11-20, D-102)

User request (2026-11-20, in Portuguese): “precisamos fazer um novo release”. Version chosen by the user: `0.1.0`, build 28, tag `v0.1.0-beta.2`; same channel and accepted deviation as ZF-84 (D-102). New since beta 1: the toolbar search field at rest and the toolbar following the sidebar's room (ZF-88, D-112, D-113), the 400 pt content minimum, and safer browser drags (ZF-90, D-114, D-115).
- [x] `feat/expand-search-field` merged into `release/v0.1.0-beta.2` (from `main` `ebf4e9e`); `CURRENT_PROJECT_VERSION` 27 → 28 for the app and the Finder extension (`MARKETING_VERSION` stays 0.1.0; test targets unchanged).
- [x] `Scripts/update-7zip.py --status` (vendored 26.06 = upstream 26.06), `--verify` OK, `Scripts/update-notices.py --check` OK, `Scripts/affected-tests.py --check` (32 UI tests, 24 rules, 0 problems).
- [x] Full `Unit` plan 831/831 and the offscreen part of `UI-Full` 20/20 on the release state (2026-11-20).
- [x] The 12 `offscreen.realOnly` UI tests in the real mode (announced to the user): 12/12 passed on the second invocation; the first ran no test (shell quoting of the filters). UI-Full 32/32.
- [x] `main` fast-forwarded to the release branch (`3803416`); annotated tag `v0.1.0-beta.2` on it (2026-11-20).
- [x] Release archive from a clean clone of the tag, no warnings: signature, designated requirement, entitlements, 0.1.0 (28), `arm64` checked; `Zforge-0.1.0-beta.2.zip`, 9,550,877 bytes, SHA-256 `03b260b0075ef745519812bd9bf3f0ec0bfbe5d676411e370089c5788b1a1528`. Kept outside the repository with the `.xcarchive` and the release notes, beside beta 1.
- [x] `main` and the tag pushed (user request, 2026-11-20); GitHub pre-release “Zforge 0.1.0 beta 2” published: https://github.com/zforge-app/zforge/releases/tag/v0.1.0-beta.2, marked pre-release and not latest, notes as beta 1's with a “What's new since beta 1” section; the uploaded zip downloaded back through the API has the same SHA-256.
- [ ] Not repeated from ZF-84: the manual real-window pass by an agent; the user checked ZF-88 and ZF-90 in the real window on Debug builds.

### ZF-90 — Sidebar divider over Columns rows; drops a folder cannot take (2026-11-19, D-114, D-115)

User report (2026-11-19, in Portuguese, recording and screenshot): pressing the sidebar divider over a Columns row dragged the file; dropping a folder on itself showed an error. Numbering note: ZF-89 is the line counter in the parallel `feat/zforge-code-line-counter` worktree.
- [x] Item drags refuse presses the window routes to the split view's divider; offscreen unit test (four modes) and offscreen UI test, both shown failing without the correction.
- [x] Finder's drop refusals (item on itself, folder into its own folders, move into its own folder) while hovering and on drop, silently; unit tests reproduced the error first.
- [x] Drag images clipped to the item's own shape in all four modes (user screenshot: grey strips beside a Columns row).
- [x] Real drag-and-drop check in the window, by the user (2026-11-19/20): after the divider and drop corrections “Ótimo, mais um ajuste” (the drag image), and after the drag image correction “perfeito, commita”.

### ZF-88 — Toolbar search field at rest in wide windows (2026-11-19)

User request (2026-11-19, in Portuguese): the magnifying glass should expand into a text field when there is room to spare; it was always only the icon. Contract: CURRENT-STATE and UI-UX-GUIDE “Toolbar search” (field at rest).
- [x] From 1,050 pt (the open field keeps the expanded stage) the search item is the field at rest; below, the button. No focus taken on appearing; click, Tab, its magnifying glass, ⌘F and Find put it in use; Escape and clicking away return it to rest.
- [x] No transition at the window's first layout (the assumed 1,100 pt width), so narrower windows open with the button.
- [x] Tests: thresholds, activation, rest snapshots (light/dark), real-window offscreen width/focus and click/Escape cases; the ⌘F UI test moved to 960 pt, the widest width that still shows the button (justified in REGRESSION-COVERAGE).
- [ ] Real-window visual review (four modes, light/dark, a long language, VoiceOver, Reduce Motion, resizing across 1,050 pt).
- [x] Follow-up to the user's recording (2026-11-19): button and field as separate toolbar items, no SwiftUI transition, magnifying glass inset 10 pt; overlap/structure test; snapshots re-recorded.
- [x] Clean full `Unit` run: it first stopped twice in `IconPreviewServiceTests` under high load (the unchanged sources stopped the same way); the final state passed 831/831 (REGRESSION-COVERAGE).
- [ ] D-112, NSToolbar's 0.2 s appear animation at stage switches: waiting on the user's choice.
- [x] Second follow-up (user recording and screenshots, 2026-11-19): the field at rest only where it fits beside every control, and every stage following the toolbar's room (window minus sidebar) so `NSToolbar`'s own overflow menu never appears (D-113); sweep tests across sidebar widths.
- [x] Real-window diagnosis (2026-11-19): the restored sidebar's width was never reported; fixed and verified by scripted resizing of the real window; content minimum raised to 400 pt (user request); focus fixes found by the tests.
- [x] The user's check in the real window (resizing and dragging the sidebar), 2026-11-19: “OK, isso resolveu os problemas da toolbar”.
- [x] Runs: Unit 820/820, 9 offscreen UI tests and 2 of 3 real UI tests passed. The real Finder question test failed twice because a WhatsApp window covering the screen interrupted XCTest (that flow has no toolbar). It still needs a clean real run.

### ZF-87 — Connect to servers inside Zforge and eject shares from Shared (2026-11-18, D-111)

User report (2026-11-18, in Portuguese): connecting to an SMB server opened Finder instead of Zforge, the Remote sheet stayed open, Cancel left the share connected, and Shared had no eject button.
- [x] Sandbox check: sandboxed probe against the user's SMB server; NetFS may mount under `/Volumes` when no mount path is passed.
- [x] Mount with NetFS (`NetFSNetworkServerMounter`) for the Remote sheet and the Network level; no Finder window.
- [x] Remote sheet: “Connecting…” progress, closes and opens the share on success, failures in the sheet, Cancel/Escape cancels the mount, bare server names connect over SMB.
- [x] Inline ⏏ on Shared rows (one `volumeRow(_:)` for Locations and Shared).
- [x] Tests: `NetworkLevelTests` (sheet flow, address parsing, share matching, network row); requirements synchronized.
- [x] User run in the app (2026-11-18): the Debug build of this branch, against the user's SMB server, with the steps to eject the share with the new ⏏, reconnect through the Remote sheet and Cancel during the system sign-in dialog; the user confirmed (“perfeito”). Not confirmed separately: the share-selection dialog, a Network-level server, dark mode and a long language.

### ZF-86 — Window resize stutter at toolbar stage changes (corrected 2026-11-18, D-110; stage switches above the 50 ms target)

User report with a recording (2026-11-18, in Portuguese): “Olha como está travando ao alterar a largura da janela quando os ícones da action bar mudam.” Blocks 0.1.0. Workload, criteria, baseline and results: D-110.
- [x] Baseline measured; causes identified (width in the window's body; toolbar item replacement at stage switches).
- [x] Step 1: width out of the body (`WidthClass`, sidebar maximum in AppKit). Steps without a switch about 45–55 % faster in median; switches unchanged.
- [x] Approach chosen by the user after trying a Release build (2026-11-18): all stages' items stay in the toolbar and a stage hides the others; implemented; toolbar layout tests adapted to presented items (justified in D-110) and a new item-identity guard.
- [x] Temporary measurement harness removed (kept outside the repository); workload in D-110.
- [x] Release measurement: waived by the user (2026-11-18) — the target is meant to hold in the Debug workload already; the test target does not link in Release.
- [ ] Bring every stage switch under 50 ms in the D-110 Debug workload: 900 pt is 78–139 ms, 678 pt 42–88 ms, 840 pt 34–58 ms. Does not block 0.1.0; the user asked to record it and improve it later (2026-11-18). Remaining cost: `NSToolbarView` layout (glass tiling) and the content's layout.

### ZF-85 — New Folder in the browser's context menus (2026-11-18, D-105)

User request (2026-11-18, in Portuguese, while testing Columns): “I noticed we didn't add the feature of creating folders to Zforge's context menu, add it.” Placement decided from the contract and Finder (no open choice left): Finder's blank-area shortcut menu and its Action menu start with New Folder, and its item menus have none; Zforge's blank-area menu is by contract the `•••` menu, so New Folder goes first in that shared menu (`BrowserActionsMenu`), which also feeds the toolbar overflow. Creating folders inside archives does not exist in the contract, so New Folder is disabled there, as File ▸ New Folder is. The Finder extension's Zforge submenu is not concerned (Finder has its own New Folder).
- [x] Failing tests first: `BrowserMenuParityTests.newFolderLeadsSharedMenus`, `.newFolderIsLocalized`, the changed `blankAreaMenuMatchesMoreMenu` (D-105) and `FolderWithSelectionFlowTests.contextMenuNewFolder` failed with New Folder missing; they pass with it.
- [x] Implementation: `BrowserActionsMenu` adds New Folder (`folder.badge.plus`, existing “New Folder” String Catalog key, 21 languages) and a separator before Open; it calls `createNewFolder()` with `canModifyCurrentDirectory`, the File ▸ New Folder handler and enablement.
- [x] Requirements: CURRENT-STATE §7 and §8, UI-UX-GUIDE (overflow and blank-area menu).
- [x] Real right-click popup: `testBlankAreaUsesMoreMenuInEveryView` asserts New Folder is the first entry (offscreen run).
- [ ] Real-window visual review of the menus (symbol, separator) in light/dark and a long language; New Folder chosen from a real right-click in a real folder.
- [ ] Not done (outside this request): New Folder with Selection as an Option alternate or a multiple-selection entry in these menus, as Finder's Action menu offers.

### ZF-84 — Friends pre-release without notarization (planned 2026-11-18, D-102)

User decision (2026-11-18, in Portuguese): not yet in the Apple Developer Program; publish a pre-release for a few friends to test. Contract: PRODUCT-REQUIREMENTS “Model distribution” (friends pre-release); accepted deviation D-102.
- [x] Channel (user decision, 2026-11-18): the user will make the repository public when it is ready; the pre-release is a GitHub pre-release of that public repository, whose tag is the corresponding source.
- [ ] Before making the repository public: review the history once more. Scan of 2026-11-18: no tracked file contains a local home path, no secret-like assignment, no blob over 20 MB; commit authors include a personal email besides GitHub noreply addresses (the user considers it already public).
- [ ] Decide where testers report problems (GitHub issues once public).
- [x] Version (user decision, 2026-11-18): `0.1.0`, tag `v0.1.0-beta.1`. `MARKETING_VERSION` 0.0.1 → 0.1.0 and `CURRENT_PROJECT_VERSION` 26 → 27 for the app and the Finder extension (test targets unchanged).
- [x] 2026-11-18: `Scripts/update-7zip.py --status` (vendored 26.06 = upstream 26.06), `--verify` OK, `Scripts/update-notices.py --check` OK, `Scripts/affected-tests.py --check` (31 UI tests, 24 rules, 0 problems).
- [x] 2026-11-18, staged state: `Scripts/check-warnings.py` no warnings; full `Unit` plan 797/797; offscreen part of `UI-Full` 18/19 (ZF-73 intermittent failure). Results in REGRESSION-COVERAGE.
- [x] The 12 `offscreen.realOnly` UI tests in real mode: 12/12 passed on 2026-11-18 (second attempt; the first did not start, Automation Mode authentication timed out).
- [x] Manual real-window pass of the candidate (2026-11-18, GPT 6.2 Sol with computer use; REGRESSION-COVERAGE): no blocker; two cosmetic defects D-103 and D-104; ZF-82 and the ZF-80 write-back panel not checked.
- [x] D-103 and D-104 corrected (2026-11-18): tests first, full `Unit` plan 800/800, offscreen UI 19/19, warning gate clean; D-104 measured faster than the previous path. D-103 shows “—” for a missing date (display being confirmed by the user).
- [x] The 12 `realOnly` UI tests in real mode on the final state (2026-11-18): 11 passed; the Finder submenu test failed for the D-67 environment cause (the user's `/Applications/Zforge.app` extension elected), see REGRESSION-COVERAGE.
- [x] Hold for the window resize stutter (user, 2026-11-18) lifted: ZF-86 corrected and approved by the user the same day; no publication yet (the repository is still private).
- [x] ZF-82 ⌘⌫ in Columns checked by the user in the real window (2026-11-18): all scenarios as expected.
- Spun off: New Folder in Zforge's context menus (user request during this check, 2026-11-18) — separate thread, ZF-85.
- [x] Candidate Release archive checked 2026-11-18 (REGRESSION-COVERAGE); build it again from the tagged commit and repeat the checks.
- [x] Local annotated tag `v0.1.0-beta.1` on `c078ffa` (2026-11-18; `main` with ZF-85, ZF-86 and ZF-87); not pushed.
- [x] Final Release archive of the `Zforge` scheme from a clean checkout of the tag, signed with Apple Development (2026-11-18): `codesign --verify --deep --strict` valid, entitlements as expected for the app and the Finder extension, `arm64`, 0.1.0 (27), Acknowledgments bundled (REGRESSION-COVERAGE).
- [x] Packaged with `ditto -c -k --keepParent`: `Zforge-0.1.0-beta.1.zip`, 9,534,037 bytes, SHA-256 `c3fa25709a57d03b8d32b93950c8387fec35f7e0b6ae0cc2a3f302b0e45fef40`; the unzipped copy satisfies its designated requirement. Kept outside the repository with the `.xcarchive` (dSYMs) and the release notes.
- [x] `main` pushed (user request, 2026-11-18), then the tag; GitHub pre-release “Zforge 0.1.0 beta 1” published the same day (user request, repository still private): https://github.com/zforge-app/zforge/releases/tag/v0.1.0-beta.1, marked pre-release and not latest, notes as drafted with the SHA-256 and the known limitations updated for ZF-87; the uploaded `Zforge-0.1.0-beta.1.zip` was downloaded back through the API and its SHA-256 matches.
- [ ] Make the repository public (user, later); until then testers need access to the repository to download.
- [ ] Install test on another Mac from a browser download (quarantine): Open Anyway, Home grant, Finder extension, open/extract/compress, Shortcuts, MCP after approval.
- [x] README “Install a pre-release” section and version note (2026-11-18).
- [ ] Annotated tag on the exact commit; release notes as required by PRODUCT-REQUIREMENTS.
- [ ] Record the published version in CURRENT-STATE.
- [ ] Before the first Developer ID build: test whether pre-release grants survive the change of designated requirement (D-102).


### ZF-83 — Split archives with the features of whole archives (implemented 2026-11-17, D-101; real-window review pending)

User request (2026-11-17, in Portuguese): “let's handle split archives and give them the same features we give whole ones.” Contract and stages: OPEN-REQUIREMENTS “Split archives with the features of whole archives (ZF-83, D-101)”. Defects found while planning: D-101. User decisions (2026-11-17): every volume stays visible and acts on the whole set; WinZip-style `.zip` + `.zNN` sets stay read-only; creating split archives is the last stage; RAR fixtures are made with RARLAB's `rar`, installed temporarily.
- [x] Stage 0 — characterization: fixtures for the four schemes (`.7z.NNN`, `.zip.NNN`, Info-ZIP `spanned.zip` + `.z01`/`.z02`, RARLAB `parts.partN.rar` and the same set renamed `legacy.rar`/`.r00`/`.r01`, since RAR 7 no longer writes legacy names); reading from the first volume passed for all five before any change; the stage 1 behaviours failed on `main` (12 issues, REGRESSION-COVERAGE).
- [x] Stage 1 — set identity (`Shared/ArchiveVolumeSet.swift`) and complete reading from any volume: open, browse, preview, export, extract, validate once per set; folder named after the set; total size; missing-volume error; early refusal of drops on read-only sets; Finder, Dock, Intents, Spotlight, MCP.
- [x] Stage 2 — inline List expansion of split 7z/ZIP sets (measured: same latency as whole archives); split sets stored inside archives entered from any volume, all volumes copied.
- [x] Stage 3 — editing `.7z.NNN`/`.zip.NNN` sets (add, drop, remove, reorganize, move out) with 7-Zip's `CMultiOutStream` and a journaled volume swap (`ArchiveVolumeReplacement`) undone on failure and recovered after a crash; archives inside split sets are written back into them.
- [x] Stage 4 — write-back of `.NNN` sets stored inside archives (volumes added or dropped in the outer archive).
- [x] Stage 5 — creating split 7z/ZIP archives (Split into volumes in Compress Custom… and profiles, MCP `compress` `volume_size`).
- [ ] Real-window review: List triangle on volumes, Get Info/preview total size, drop highlight on a volume row, Split into volumes in Compress Custom… and Settings (light/dark, a long language), the missing-volume alert.
- [ ] Native-speaker review of the 7 new strings (21 languages).
- [ ] Not planned (user decision 2026-11-17): writing spanned `.zip` + `.zNN` sets; RAR is never written.

### ZF-82 — Columns select the following item after a deletion (2026-11-17, D-100)

User request (2026-11-17, in Portuguese): after deleting a file with ⌘⌫ in Columns no item stays selected; it should behave like the other views, selecting the item that followed the deleted one.
- [x] Reproduced offscreen first: `ColumnDeletionSelectionTests` failed in 7 of its 8 scenarios (empty selection after the deletion).
- [x] Fix: `refreshColumnsAfterRemovingLocalItems(_:movesCursorFromRemovedItems:)` records the focused item's column and position before the removal and, after the refresh, selects the item now at that position (`activateColumnItem`, no history entry); an emptied column leaves its folder selected in the previous column. Turned on by Move to Trash, Delete Immediately and an open folder found gone on reload; moves, grouping, duplication and their Undo keep their own selection (the first version applied it to every caller and broke two New Folder with Selection tests in Columns, caught by the full `Unit` plan).
- [x] Requirements: UI-UX-GUIDE “Column view”, CURRENT-STATE “Update” and “Columns”.
- [x] Real-window check of ⌘⌫ in Columns: done by the user on the 0.1.0 (27) Release candidate, 2026-11-18 (ZF-84) — every scenario as expected (REGRESSION-COVERAGE “Friends pre-release 0.1.0”).

### ZF-81 — Columns preview slot held while an archive file's preview loads (2026-11-17, D-99)

User report (2026-11-17, in Portuguese, with a recording): navigating inside an archive, the preview column expanded and retracted again.
- [x] Reproduced offscreen first: `ColumnBrowserLayoutTests.loadingArchivePreviewKeepsTheLayout` failed (wider column; wider, scrolled columns after a branch had opened).
- [x] Fix: preview-loading state in `FileBrowserState`; `ColumnBrowserView` holds the preview slot while it loads and keeps the column beside it at its base width.
- [ ] Real-window check of fast keyboard navigation through archive files (the user's scenario).

### ZF-80 — Nested archive navigation without a depth limit, edited in place (2026-11-16, D-98)

User request (2026-11-16, in Portuguese): bring back opening archives inside archives, without a nesting limit, since the preview limits already bound what is read. Decisions (user, same day): editing in place; an archive's copy is discarded when its root archive closes; in Columns entering by selection is implicit (the reason nesting had been removed in D-73 was that it could not stay implicit), within the preview limit, “consistent with the user seeing a preview of the compressed files”; a modified inner archive is written into its parent when it closes, the parent into its own when it closes, up to the root; the “inner archive in a new window” flow is removed.
- [x] Engine: inner sessions no longer hold their outer session; a root session closes with every copy made from it once nothing in its tree is shown or pending; closing an inner archive requests its write-back after the archives opened from it (`settle`); the write-back keeps the copy, marks the containing archive modified and lets it be written when it closes; an entry removed (or replaced while unmodified) ends its inner session (`sessionsDidEnd`); a moved entry keeps it; a replaced entry of a modified copy is a write-back conflict; returning to a copy whose write-back is due joins it (`modificationCount`).
- [x] State: in-place entry in the four modes; one reference per shown inner archive (`innerArchiveHolds`), released innermost first; Columns implicit entry within the preview limit and 1 GiB, explicit with Right Arrow, Return, double click; List inline expansion, collapse closes, expand-all skips nested archives; large-item confirmation and password resume in the right column; history purge and window exit when a session ends; inline nested extraction keeps its boundary (fixed during this work, test reproduced it first).
- [x] Removed: new-window handoff (`ArchiveSessionHandoff`, `BrowserWindowRequest.archiveSession`, `configureOpenArchiveWindowAction`), the window-ordering registry (quitting still closes windows and waits).
- [x] Tests: `NestedArchiveTests` (replaces `InnerArchiveWindowTests`, 26 tests); `ZforgeTests` nested expectations restored (recognition, Columns extraction through three nested archives, List inline nested expansion, inner session naming); UI test `testClickInnerArchiveInColumnsShowsItsContents` replaces `testDoubleClickInnerArchiveOpensItInNewWindow`.
- [x] No new strings.
- [ ] Real-window visual review of the four modes inside nested archives, the write-back panel during navigation, and VoiceOver.
- [ ] UI tests selected by the change: 19 offscreen (need an unlocked session; it was locked) and 11 real-only (take over the screen), including the new `testClickInnerArchiveInColumnsShowsItsContents` — not run yet (REGRESSION-COVERAGE).

### ZF-79 — Tag editor sheet appearance (2026-11-11, D-97)

User request, with a screenshot of the sheet in dark mode: “O diálogo de edição de tags está muito feio, melhore a aparência dele.” The sheet keeps its behavior (apply/remove existing tags, create a tag, Cancel/Apply); its presentation changes.
- [x] Tag list in a rounded card that is as tall as its tags up to eight rows; a longer list ends on half a row and scrolls. Rows are 28 pt, highlight under the pointer, and show the state at the trailing edge: accent check on every target, dash on some, nothing on none. Empty list shows “No tags”.
- [x] New tag: name field, eight color swatches (no color, struck through, then Finder's menu order) in place of the pop-up, Add. A created tag is scrolled into view.
- [x] Progress indicator next to the buttons while applying.
- [x] Draft logic extracted from the view to `FinderTagDraft`, unchanged in behavior; the editor takes the catalog tags as a parameter.
- [x] Tests: `FinderTagEditorTests` (draft, layout, sheet size in five languages, six snapshots); `testTagEditorIsSharedByToolbarAndContextMenu` unchanged.
- [x] No new strings (“No tags” and the color names already existed).
- [x] The user checked the sheet in a Debug build of this change on 2026-11-11 (“OK, bem melhor”) and authorized integration into `main`. VoiceOver over the swatches was not reported as checked.

### ZF-78 — Open or extract an archive opened from Finder (2026-11-10, D-96)

User request: when Zforge is the default app and an archive is double-clicked in Finder, ask whether to extract or open it, with a checkbox to make the choice the default, and add the setting to Settings. Decisions (user, same day): only where Zforge is the default app for the type; Extract into a folder named after the archive, next to it; no browser window while extracting, only the progress; the dialog every time until a default is saved.
- [x] Choice, routing by default app, preference `finder.archiveOpening` and Settings ▸ General ▸ Archives Opened from Finder.
- [x] Dialog (Open / Extract / Cancel, Don’t ask again), asked one at a time.
- [x] Windowless extraction: progress panel, folder access, password, conflicts (shared alert), failure, cancellation, empty-folder cleanup, quit waits.
- [x] SwiftUI opens no window for files and URLs (D-96); the app opens one when no browser window takes the request.
- [x] Tests: `FinderArchiveOpeningTests` (unit and snapshots), real-only UI test `testArchiveOpenedFromFinderAsksAndExtractsWithoutWindow`; ZF-77's UI test pinned to Open; isolation argument `--ui-finder-archive-opening`.
- [x] 13 new strings and the General pane description in the 21 languages (own drafts).
- [ ] Native review of the translations.
- [ ] The user checks a Finder double click with Zforge set as the default app for ZIP (the UI test uses ARJ, which Zforge already opens by default on this Mac).
- [ ] Observed, not changed: a non-archive file with an archive extension (a text file named `.zip`) opens and extracts as a one-item archive (engine behavior).

### ZF-77 — An archive opened from Finder: one window, archive as the window root (2026-11-10, D-95)

User report (installed build 26): opening a ZIP from Finder with Zforge closed showed the archive window exactly over a second, Recents window; in Columns the archive's contents were in the second column, after an empty Recents column. Reproduced with the current code (cold launches of a Debug build), so not only the installed build.
- [x] One window: the launch window's offer is no longer ended by SwiftUI's transient `onDisappear` during launch (`ZforgeApp.swift`).
- [x] Window root: the folder, archive (also after its password) or inner archive a window is opened for is its only path component and first column, with no history behind it (`FileBrowserState.openArchive(_:asWindowRoot:)`).
- [x] Tests: `InitialWindowLocationTests` (offscreen), Back assertion in `InnerArchiveWindowTests`, real-only UI test `testArchiveThatLaunchesZforgeOpensInOneWindowAsColumnsRoot` (LaunchServices launch); all fail on the previous code and pass with the fix.
- [x] Requirements: CURRENT-STATE (Common Window, File sent by Finder, One window per request); D-95; REGRESSION-COVERAGE.
- [x] Release build of the fix (uncommitted working tree on `fix/zip-finder-window-root`, still build 26) installed in `/Applications` on 2026-11-10 at the user's request, replacing the 2026-10-13 build; opened with a ZIP through LaunchServices it showed one window, the archive in the first column, Back disabled.
- [ ] The user checks a Finder double click with the installed build.
- [x] Observed: the launch window showed Recents for a fraction of a second before the file that launched Zforge replaced it. Resolved by ZF-78/D-96: a file that launches Zforge no longer creates a launch window.

### ZF-76 — Repository hygiene before publication: `.gitignore` (2026-11-10)

- [x] `.gitignore` (macOS, Xcode per-user state, build products and results, SwiftPM, Python caches); the three tracked `xcuserdata` files are no longer tracked (the files stay in each checkout).
- [x] Secret scan of the full history (2026-11-10): gitleaks 8.30.1 (release asset, checksum verified) over every ref, 398 commits, 84 MB: 3 findings, all false positives (SHA-256 file hashes keyed by `AutomationAccess.swift` in three benchmark result files). No key, certificate, provisioning profile, `.env` or token file in any commit.
- [x] Home path: the absolute home folder path replaced by `~` in the six documentation files that recorded it (user request, 2026-11-10); past commits keep it.
- [x] Author email (user decision, 2026-11-15): the history of every Zforge branch was rewritten (`git filter-branch`, metadata and this file's text) so the 189 commits carry the user's GitHub no-reply address as author and committer; contents, dates and messages are otherwise unchanged. Every commit identifier changed: the commit identifiers cited in the documentation and diagnostic scripts were updated to the new ones; identifiers inside past commit messages, and the script SHA-256 values recorded in earlier benchmark results, keep their original values. Local Codex/T3 checkpoint refs still point to the old history and are never pushed. The repository's `user.email` is set to the no-reply address. `zforge-xcuitest-sim` was rewritten the same way on 2026-11-16 (24 commits; the tool commit identifiers cited here were updated) and published as private `zforge-app/zforge-xcuitest-sim`. `zforge-website` (14 commits) still carries the personal address and needs the same rewrite before it is published. The Apple team ID in the project needs no action (public in every signed build).
- [x] Repeat secret scan after the rewrite: not run (user decision, 2026-11-15).

### ZF-75 — License notices and the Acknowledgments window (2026-11-10, D-93)

Requested: resolve the license gaps found by ZF-74 before publication. The user left the window's placement and the copyright holder to the recommendation: a menu item below About Zforge (the standard About panel cannot hold a button) and the author's name.
- [x] `LICENSE` (MIT, Copyright (c) 2026 Felipe Liborio).
- [x] `Scripts/update-notices.py` (+ `--check`) writes the notices of Zforge, 7-Zip and the four linked packages and `Acknowledgments.json`; refuses checkouts not at the pinned revision and unclassified pins. `Scripts/update-7zip.py` refreshes and `--verify` checks the 7-Zip notices. `Vendor/7-Zip-License.txt` (console package license) removed.
- [x] Acknowledgments window and Zforge ▸ Acknowledgments…; strings in the 21 languages (own drafts).
- [x] Tests: script tests, `AcknowledgmentsTests` (bundle contents, 7-Zip texts and versions against the vendored release and `Package.resolved`, toolbar title, 7-Zip page snapshot light/dark), UI test `testAcknowledgmentsOpenFromTheAppMenu`.
- [x] Translation review (2026-11-10): the title and menu item follow Apple's macOS translations of “Acknowledgments” (LOCALIZATION.md); the note was corrected in es, pl, da and sv.
- [ ] Real-window review of the window (VoiceOver, languages, widths); native-speaker review of the note.

### ZF-74 — 7-Zip engine update process and update to 26.06 (2026-11-10)

Requested: adopt the recommended way to keep 7-Zip current (vendored sources, an import script, updates committed on their own, `7zz` out of Git and its history), write the script and update the engine. Policy in PRODUCT-REQUIREMENTS, *Engine updates*.
- [x] `Scripts/update-7zip.py`: imports a release tag byte for byte (upstream export attributes overridden: 26.03 added `*.dsp text eol=crlf`), stamps the files with the import time so cached engine objects rebuild, applies listed patches, regenerates `inputs.xcfilelist`, records provenance and the reference `7zz` asset, reports files, license changes and upstream history; `--verify`, `--status`, `--latest`. Script tests in `Scripts/tests/test_update_7zip.py`.
- [x] `Scripts/fetch-7zz.py`: downloads the matching macOS `7zz`, verifies checksum and reported version, caches it; benchmark scripts use it. `Vendor/7zz` removed from the tree and the project.
- [x] Engine 26.02 → 26.06 (`d3296e3`): 214 upstream files changed, no file added or removed, license files unchanged; fixes vulnerabilities in 26.03–26.06 (CVE-2026-58052 among them). 26.06 removed `CMultiStream`: the bridge reads numbered volumes through its own `VolumeStream`.
- [x] `Vendor/7zz` stays in the past history; only untracked (user decision, 2026-11-10).
- [x] Validation: Unit plan 703/703; 5/5 offscreen and 5/6 real UI tests (REGRESSION-COVERAGE “7-Zip engine update to 26.06”).
- [x] `testArchivePromisesPublishIntoFinderBeforeRemovingOriginal` failed intermittently at `:691`: the move was decided from the modifier state at the promise request. Corrected (D-94): the operation chosen at the drop decides; unit case `externalMoveFollowsTheDrop` failed before the fix.
- [x] No 26.02 versus 26.06 benchmark comparison (user decision, 2026-11-10).
- [x] Bundle the source license notices (D-93): done in ZF-75.
- [ ] Scheduled upstream check (`--status`) once the repository is on GitHub.

### ZF-73 — Intermittent offscreen failure of the compact toolbar menus UI test (open, 2026-11-10)

`ZforgeUITests.testCompactToolbarMenusOpenFromTheirToolbarButtons` fails intermittently offscreen at `ZforgeUITests.swift:952`: right after the overflow button's click, its value still reads “Collapsed”. Every occurrence ran in the same lane right after `testBlankAreaUsesMoreMenuInEveryView`, the pair whose earlier shared-preferences cause was corrected by ZF-54 (D-63).

- Occurrences: `zf66-full-1` (2026-11-09, ZF-66); the ZF-67 run of 2026-11-10; `affected-20261110-111216` (2026-11-10, ZF-72 merge validation, branch `0108594`). None of these changes touched the test or the browser toolbar.
- Occurrence of 2026-11-18 (ZF-84 release validation, `affected-20261118-143321`, `ZforgeUITests.swift:1119` after the file grew): same “Collapsed” value, but in a lane where it followed `SettingsUITests.testListColumnsReorderByDragging`, so the pairing with `testBlankAreaUsesMoreMenuInEveryView` is not required.
- Occurrence of 2026-11-18 (ZF-84, final `main` with ZF-87, `affected-20261118-204341`, `ZforgeUITests.swift:1121`): “Collapsed” again, again in the lane right after `SettingsUITests.testListColumnsReorderByDragging` (the second recorded occurrence right after that test). Run alone right after (`affected-20261118-204925`): passed.
- Passes: alone and as that pair on the same build (ZF-67 re-run); 18/18 offscreen set of 2026-11-10 (`affected-20261110-100133`). No real-mode failure recorded.
- [ ] Reproduce deterministically (for example, run the pair repeatedly in one lane and capture the app's toolbar state and the event timeline at the click), and decide whether the click reaches the button before it is ready (app or test synchronization) or the offscreen tool delivers it differently (tool limit). Do not retry or lengthen timeouts to hide it.
- [ ] Fix the cause with a failing case first, then record the result here and in REGRESSION-COVERAGE.

### ZF-72 — Real Option-drag UI test hangs in its drop on macOS 27.2 (corrected in the test 2026-11-10, D-92)

- [x] Run `testLocalDragsOptionCopyAndConfirmAdditionToArchive` in the real mode (user approved, 2026-11-10): fails at `:603` on `main` (2 runs) and on `0f575ac` (1 run), which passed on 2026-11-02 under 27.1.
- [x] Decide whether a real user drag onto an archive row hangs too: no — the user's manual drag in List view on 27.2 showed the confirmation and added the file (2026-11-10). Only XCTest's synthesized drag hangs.
- [x] Find why the synthesized drag does not end: XCTest 27.2 posts the move and the release within 1.6 ms, and the release reaches the app before AppKit's dragging session starts (88 ms after the pickup); the session never gets a release (probe logging and an event tap in a real run, D-92).
- [x] Adapt the gesture: `dragAndDrop(onto:)` (`ZforgeUITests/DragGestures.swift`) presses, moves, pauses 1.0 s over the target and releases; used by every UI test drag that starts a Zforge dragging session. Assertions and timeouts unchanged. The test passed 2/2 in the real mode on the final build.
- [x] Other real-only drag tests, run once each: `testArchiveDragCopiesIntoSidebarFolder`, `testArchiveCopyIntoAnotherZforgeWindow` and `testArchiveInternalCopyConfirmationKeepsHistoryAndAncestorColumns` passed.
- [ ] `testArchivePromisesPublishIntoFinderBeforeRemovingOriginal` failed at `:676`, before its first drop: Finder opened the fixture folder in Column view with the folder's column outside the window (x = 2104 in a window at 377–1297), and the title drag did not move Finder. Make the arrangement independent of the user's Finder view and title bar layout (for example, pick the scroll view inside the window frame or set the Finder window's view), then run it once in the real mode.
- [ ] Not reproduced, worth a manual check: a person who releases within about 0.1 s of the pickup (a flick) could leave the same session waiting for a release under 27.2.

### ZF-70 — A reload collapsed inline expansions completed while it waited (2026-11-10, D-90)

**Corrected in the app; results in REGRESSION-COVERAGE “Reload and sidebar determinism — ZF-70, ZF-71”.** Found through the full-plan failure of “Option-drag out of an archive…” (ZF-69). After moving items out of an inline-expanded archive, the directory monitor's reload could collapse the archive the post-move refresh had just reopened; any archive or folder expanded inline while a reload waited for a folder listing could collapse the same way.
- [x] Reproduce: probe with slowed listings 9/20 failures at `:134`, each with the monitor's reload pruning `Sample.zip`; deterministic gated-file-system reproduction (`ReloadExpansionRaceTests`, two cases failing before the fix).
- [x] Fix: `refreshExpandedFileSystemHierarchy` computes reachability over the tree as it is after its last listing wait; unreachable expansions are still forgotten (characterized).
- [x] CURRENT-STATE “Hierarchy of List”.
- [x] Offscreen UI tests mapped to `FileBrowserState.swift` (5): passed 5/5 on 2026-11-10, after two consecutive full `Unit` runs with 699/699 passed (session unlocked).
- [x] Real-mode `testLocalDragsOptionCopyAndConfirmAdditionToArchive` (mapped to the same file): run 2026-11-10, fails the same way on `0f575ac`, before this change, so not caused by it (D-92, ZF-72).
- [ ] Seen in the code, not reproduced: `reload()` restores the selection it captured when it started (non-search locations), so a selection made while it waits for a listing may be replaced. Confirm with a gated reproduction and decide.

### ZF-71 — Shortcuts sidebar row test waited for width, not for re-measured rows (2026-11-10, D-91)

**Corrected in the test; results in REGRESSION-COVERAGE “Reload and sidebar determinism — ZF-70, ZF-71”.**
- [x] Reproduce: with the poll's sleep replaced by `Task.yield()` (no display cycle between polls), the unchanged wait read `[40, 24, 40, 28, 40, 28, 28, 28, 40]` in 4/10 runs.
- [x] Cause: the widening pass leaves the sidebar's hosting view needing a constraint update; the fixture's content-view layout did not run it.
- [x] Fix: the wait lays out the whole window and requires no pending constraint update or layout along the table's ancestors. The 28 pt assertion is unchanged. 50/50 with the same injection.

### ZF-69 — Follow-ups found by ZF-68 (open, 2026-11-09)

- [ ] `BrowserWindowLayoutTests` (`.serialized`, D-71) holds the main actor for seconds per case under load and starved other suites for 10–16 s; look for a way to lay out less per case or yield, without losing a width or assertion.
- [ ] The test host logs `mdb_txn_commit error: MDB_MAP_FULL` about 50 times per full run on the main thread (an LMDB store inside a system framework of the sandboxed host, possibly IconServices' cache); identify the store and whether it slows icon rendering (D-89).
- [x] `ArchiveDragDropTests` “Option-drag out of an archive…” fails in about half the full `Unit` runs: **product bug**, corrected under ZF-70 (D-90). A reload pruned inline expansions that the post-move refresh completed while the reload waited for a folder listing.
- [x] `KeyboardShortcutsWindowTests` “Sidebar rows… 28 pt rows” fails in some full runs: test synchronization, corrected under ZF-71 (D-91). The rows wait for a constraint update that the content-view layout pass does not run.
- [ ] At load ≈ 200 the D-71 one-minute limits in `IconPreviewServiceTests` are exceeded again and testmanagerd ends the unresponsive host once per run; same main-actor saturation as the item above on `BrowserWindowLayoutTests`.
- [ ] With load noise gone (D-86), the user may decide to hold the name-query mean to the 100 ms feature target instead of the 150 ms allowance of 2026-10-28.

### ZF-64 — Unit test host crash after macOS 27.2 (2026-11-09, D-81)

**Corrected; results in REGRESSION-COVERAGE “Unit test host crash — ZF-64”.** Every full `Unit` run crashed the test host once (`objc_release` of a freed `NSWindow` in a main-actor job's autorelease pool) and reported the tests still running as failed.
- [x] Symbolicate the 18 crash reports; reproduce with zombies and malloc scribbling in a copy of the `.xctestrun`; narrow it to `PreviewSelectionOrderTests` + `HTMLPreviewTests`.
- [x] Cause: test windows left at `isReleasedWhenClosed = true` and closed, so they were released twice. `TestWindow.make` (test support) creates windows owned only by their Swift references; the four affected tests use it.
- [x] Reproduction and guard: `TestWindowLifetimeTests` (deterministic, no crash): the default releases on close; a test window does not, and is freed once.
- [x] RNF-Q08 states the rule for windows that unit tests create.

### ZF-66 — Offscreen UI tests on Xcode 27.2 / macOS 27.2 (2026-11-09, D-76, D-84)

**Corrected in the offscreen tool; results in REGRESSION-COVERAGE “Offscreen UI tests on Xcode 27.2 — ZF-66”.** Every offscreen UI test failed with “Running Background” after the macOS/Xcode 27.2 update.
- [x] Reproduce with one test (`testKeyboardShortcutHelpOpensAndFilters`) and find the cause: the tool's launch hooks were never installed because Xcode 27.2 removed `XCUILaunchServicesMonitor` (D-84).
- [x] Follow the three further 27.2 changes the fix exposed (runner `CGS_REQUIRE_INIT` abort, alert sheets behind an `_NSGlassEffectWindow` ordering proxy, pending tracking areas of menu item views).
- [x] Tool fix on `zforge-xcuitest-sim` branch `fix/xcode-27.2-launch-hooks` (`7f1f329`, not pushed); the tool's own tests pass (29).
- [x] Offscreen set (18 tests): 18/18 on `0f575ac`, 16/18 on `main`; screen guard clean.
- [ ] Merge the tool branch into the tool's `main` (the shared build in `~/Library/Caches/dev.xcuitestsim/build` is already built from the branch).
- [ ] Re-run the tool's sample app and its negative controls (`Scripts/run-sample-regressions.sh`) on 27.2.
- [ ] Repeat the real-versus-simulated equivalence (ZF-56) on Xcode 27.2; it needs real runs, which take over the screen.
- [ ] Intermittent offscreen failure of `testCompactToolbarMenusOpenFromTheirToolbarButtons`: moved to ZF-73.

### ZF-67 — Settings UI tests failing offscreen after the ZF-62 pane rewrite (corrected 2026-11-10, D-85; real review of the downward drag open)

- [x] Run `testSettingsToggleUpdatesTheOpenGridAndKeepsSelection` and `testListColumnsReorderByDragging` in the real mode (2026-11-10, `cdff0c4`): the toggle test passes (tool limit); the reorder test fails real too, Kind moves one place instead of two (Zforge regression of ZF-62).
- [x] Fix the List Columns drag reorder in Zforge, with the failing case first (2026-11-10, branch `fix/settings-list-column-drag`, merged into `main`): `SettingsRows` keyed its rows by position, so the first live move rebuilt the dragged row and ended its gesture (D-85). Rows are now keyed by their own identity, and the List Columns group lists visible and hidden columns in one `ForEach`. New offscreen tests `ListColumnDragTests` and `SettingsRowsIdentityTests` (failed before, pass after); the real-mode `testListColumnsReorderByDragging` passes. Results: REGRESSION-COVERAGE “List Columns drag regression — ZF-67”.
- [ ] Real review of the downward drag and of the drag's fluidity in the user's build: the real-mode UI test covers the upward drag only, and the downward direction is covered offscreen (row identity) and by `ListColumnOrderTests` (translation), not by a real gesture.
- [x] Fix the tool's hit test of SwiftUI switches so the toggle test passes offscreen (2026-11-10, `zforge-xcuitest-sim` `509ba38`, merged into the tool's `main`): without Automation Mode the agent hit-tested outside any accessibility request, so SwiftUI's hosting view answered with its AppKit `PlatformSwitch` instead of the Toggle's `CheckBox` node; the agent now marks the runner as the requesting client during the hit test, as the accessibility server does (tool note `Notes/swiftui-switch-hit-test-2026-11-10.md`).

### ZF-65 — Follow-ups found by ZF-64 (open, 2026-11-09)

- [ ] `AutomationPermissionUIFixture`: set `isReleasedWhenClosed = false` on its closable window (same pattern as D-81, reachable only in the UI fixture), then run its two real-only `AutomationUITests` (they take over the screen).
- [x] (Superseded by ZF-62, which re-recorded them as part of the approved Settings redesign.) D-82: review the five dark-appearance Settings snapshots that no longer match under macOS 27.2 (slider and switch knobs) and, if the user approves, re-record them.

### ZF-58 — Settings in two columns, as System Settings (2026-11-02)

**Implemented; unit, offscreen and real UI tests pass; results in REGRESSION-COVERAGE “Settings in two columns — ZF-58”.** User request: the Settings menu had become too long; split it into two columns like System Settings. Mockups approved in the conversation (View Options instead of List Columns, with Default View; the Finder extension in General; Compression profiles as a list that opens each profile).
- [x] Sidebar of six panes in three groups, remembered pane, fixed 220 + 568 pt layout, unified toolbar (`SettingsWindow.swift`, `SettingsPane.swift`).
- [x] Compression profile list with summaries and Default badge; Add Profile; profile page saved as you edit; Duplicate and Delete with confirmation (`CompressionProfileSettings.swift`, D-74).
- [x] 12 new strings in all 21 languages.
- [x] D-75 defects found in real runs and corrected (sidebar width reset by SwiftUI, preference toolbar, empty name field).
- [x] User review in the user's build (2026-11-02): profile rows without icons; no pane header (the window title names the pane, the description moved to the sidebar row's help tag); sidebar tiles refined (fixed gradients, semibold white symbols, clearer symbols).
- [ ] Second look at the refined tiles in the user's build (General `gear`, View Options `eye.fill`, Previews `rectangle.and.text.magnifyingglass` chosen by the user from rendered alternatives); if they still do not work, remove the tiles (user decision, 2026-11-02).
- [ ] VoiceOver pass over the sidebar (rows and their description hints) and profile rows; reduced-motion and increased-contrast review of the window; native-speaker review of the new translations.

### ZF-57 — Block commits with build warnings (2026-11-02, RNF-Q07)

**Implemented; results in REGRESSION-COVERAGE “Warning commit gate — ZF-57”.** The user saw two warnings in Xcode (`ComputerIdentity.swift` `String(cString:)`, `IconPreviewView.swift` closure in `@Entry`) and asked for commits with warnings to be blocked. Both were already fixed in `16d0ccc`; a clean build of `29ee38a` reports 0 warnings, so Xcode was showing diagnostics from an older build.
- [x] `Scripts/check-warnings.py` builds the git index (not the working tree) in an incremental private copy (`<git dir>/zforge-warning-gate`) and blocks on any warning or error; third-party package warnings are listed only; documentation-only commits skip the build (`--hook`).
- [x] `.githooks/pre-commit` and `.githooks/pre-merge-commit`; `core.hooksPath` set in the clone's shared config.
- [x] A cached build never hides a warning: files named by a warning are marked changed; a warning without a location discards the build products.
- [x] Script tests: `python3 -m unittest discover -s Scripts/tests`.

### ZF-56 — UI tests offscreen by default (2026-11-01, RNF-Q08)

**Implemented; equivalence recorded for the 16 simulable UI tests; results in REGRESSION-COVERAGE “UI tests offscreen by default”.** The user asked to run the existing XCUITests without taking over the screen, without a VM or a second macOS user; the sibling tool `zforge-xcuitest-sim` does it.
- [x] `Scripts/affected-tests.py --run` runs the selected UI tests offscreen in parallel lanes (`--lanes`, default 3; longest first from `offscreen.durations`) and the `offscreen.realOnly` tests real afterwards; `--ui-mode auto|offscreen|real`; without the tool every UI test runs real. Script tests: `python3 -m unittest discover -s Scripts/tests`.
- [x] `TestPlans/ui-impact.json` `offscreen` section: 10 real-only tests with reasons (Finder, drag and drop through the window server, out-of-process sandboxed open panels) and durations for the 16 others; `--check` requires every UI test in exactly one of them.
- [x] Equivalence on one build (`888896d` plus uncommitted tag-row changes): 16/16 outcomes match between real and offscreen; activity trees identical for 8 tests (including ⌘F search and the size-limit slider) and differing only in launch steps for 7.
- [x] No repeat on a quiet machine (2026-11-02, user decision: run time does not matter, only that UI runs stop taking over the screen).
- [x] Linked worktrees find the tool (2026-11-02): from `~/.t3/worktrees/Zforge/<id>` the script looked only for `../zforge-xcuitest-sim`, missed it, and in `auto` mode ran every selected UI test real. It now also looks next to the main checkout (`git rev-parse --git-common-dir`); `ZFORGE_XCUISIM` still overrides. Script tests cover worktree, main checkout, precedence, override and the not-found report.
- [x] Simulated apps no longer take the user's keyboard (2026-11-02): menu tracking made each lane copy the window server's key thief (WindowServer log `key thief updated … (Zforge)`, about 30 per minute), so keys typed in another app went to the invisible copy. The tool's agent now keeps `CPSStealKeyFocus*` in-process (`zforge-xcuitest-sim/Notes/keyboard-focus-2026-11-02.md`).
- [x] Quiet unit test host (2026-11-02): the `Unit` plan's host no longer opens a browser window and a folder-access open panel on screen, and stays out of the Dock (`UnitTestHostPresentation`, `UnitTestHostPresentationTests`); the rename-focus harness window in `FileOperationServiceTests` stays off-screen.
- [x] Offscreen builds no longer fail when Finder starts the fresh build's Finder extension (2026-11-02): `affected-tests.py` reported all 14 selected UI tests as failed without running them; the tool's `strip` now ends system-started extension processes of its own builds (`zforge-xcuitest-sim/Notes/copy-hygiene-2026-11-01.md`).
- [x] Each checkout builds offscreen into its own directory (`builds/zforge-affected-<checkout>`, 2026-11-02); before, concurrent threads shared `zforge-affected-tests` and could test each other's code. Builds of removed worktrees stay until deleted (about 1 GB each).
- [x] `testFileOpenNavigatesSelectedFolderAndArchiveInColumnsMode` synchronized (2026-11-02): after the Open with check it closes the menu with Escape and waits until no menu bar item is selected before File ▸ Open, as its List-mode sibling does; it failed 3/3 offscreen once automatic screenshots stopped slowing each step. Real-mode confirmation pending (it takes over the screen).
- [ ] Explain the one `Unable to monitor event loop` (`testViewModeIsPerWindowAndLastClosedWindowRestoresIt`) in runs without Automation Mode.
- [x] Offscreen runs without Automation Mode (2026-11-02): `affected-tests.py` runs the lanes with the tool's `XCUISIM_NO_AUTOMATION_MODE=1` (direct port to XCTest's in-app engine); 16/16 simulable tests with Automation Mode off for the whole run (`--automation-mode` goes back).
- [x] Offscreen runs do not capture the real screen (2026-11-02): `SystemAttachmentLifetime` is `keepNever` in runs without Automation Mode (XCTest's automatic screenshots were taken from the real screen).
- [ ] Investigate the real-mode `Not hittable` File ▸ Open item (zero-size frame) in `testFileOpenNavigatesSelectedFolderAndArchiveInColumnsMode`, recovered only by XCTest's own action retry.
- [x] The user's own app switches no longer close a simulated app's open menus (2026-11-02): AppKit's `_applicationDidSwitch` (LaunchServices frontmost notification) dismissed them, so `testBlankAreaUsesMoreMenuInEveryView` failed offscreen whenever the user switched apps with a menu open. The tool's agent skips that one dismissal (`zforge-xcuitest-sim/Notes/menus-app-switch-2026-11-02.md`).
- [ ] Explain the intermittent launch without a browser window (`launchWithBrowserWindow`, `ZforgeUITests.swift:448`: no window after launch and none after File ▸ New Zforge Window within 8 s), seen offscreen with and without Automation Mode after ZF-55 (also in the ZF-55 merge run).

### ZF-63 — Remove Network from the sidebar (2026-11-09, user request)

**Implemented; offscreen tests added; results in REGRESSION-COVERAGE.** Network stays in the computer level and Go ▸ Network (`⇧⌘K`).
- [x] `SidebarNetworkRow`, `SidebarItemMenuActions.networkMenu()`, `SidebarLocationCategory.network` and the Settings ▸ Sidebar Network toggle removed; a stored `network` hidden-category value is ignored.
- [x] Tests: `SidebarLocationMenuTests` (no category, legacy value ignored, Go ▸ Network still opens `Computer › Network`), `NetworkLevelTests.goNetworkHistory`; sidebar-row tests and snapshots removed with the row.
- [ ] In-app check: sidebar without Network in light/dark, Settings ▸ Sidebar, Go ▸ Network, Network from the computer level in the four modes.
