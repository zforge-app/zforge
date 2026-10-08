# Zforge — tracking of activities

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
| ZF-10 | Solve OR-01 to OR-05: guide, language of sizes, operations in Recents, alignment of Columns and Finder integration | updated code and documentation; OR-02 and OR-03 still require visual/operational verification, and OR-04 was partially checked at ZF-11. OR-05 was already on commit `d23e1f7` | D-10 a D-13, C-06 |
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
| ZF-25 | Investigating and optimizing performance and memory of native adapters | Planned to request user; hypotheses recorded, without profiling or correction of performance | OR-11 and OR-12 |
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
| ZF-39 | Add New Folder with Selection as the Option alternate in File | Implemented: `⌃⌥⌘N`, grouping, inline rename, and Undo/Redo. Integration with startup restoration and icon previews: 209/210 unit cases passed; the unchanged native tag-event case failed. All three new UI cases plus English Help and preview/selection passed after integration. The relaunch-mode failure also reproduces on main reference `1eb4a42` (D-36). Broad actual-use checks remain open. | OR-17; D-28; UI-UX-GUIDE; REGRESSION-COVERAGE |
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
| Contextual actions and toolbar | Complete matrix for file, archive, several archives and mixed selection; secondary menu and `•••`/overflow with the same options and states, multiple selection preserved in secondary click, multiple output titles, main action and breakpoints 678/780/840/900 pt, including current exception of Recents. Exercise real handler in addition to checking labels. |
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
- OR-05/C-06: the Finder route → `WindowGroup` already integrates `main` into the commit `d23e1f7`; there was no local change of this flow to integrate.

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

**Implemented:** the correction ZF-14 was committed to `28af38e` before the changes of this task. The minimum of Columns is 240 pt. The view observes the phase and geometry of the horizontal scrolling, preserves the width of the current preview during the manual scrolling and uses the width available in the next preview when the user has moved away from the right edge. Opening a directory restores terminal alignment. No overall preference of Icons, List or Gallery is changed.

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

Delivered: atomic persistent index, per-scope streams/cursors, authorized staged restoration, preservation across separate grants/processes, offline changes and bounded deferred retries. Native directory batches reduce controlled median elapsed 16.14% with identical results. Fixed event-window starvation, inode visibility events, symlink stat fallback and hidden-ancestor probes. Final 244 unit cases/327 executions pass; cached native app readiness 0.746 s, idle CPU 0.168%, mean footprint 97.90 MiB, peak 113.25 MiB. Strict Debug signature passes. Intermediate first saved Home pass is 212.249 s with one deferred path; the 60 s cold target and sought 2x controlled speedup remain unmet (D-41). Exact-final cold Home/Shared repetition is pending. Current UI runner executes no scenarios; separate four-mode filter/editor-cancel checks do not close the broader matrix. Runtime QoS warning in an unchanged AppKit test fixture remains recorded. [Evidence and next algorithm constraints](Documentation/Benchmarks/durable-tag-index.md). Previous no-persistence notes describe earlier phases. The requested earlier changes were committed as `b23f4c8`, `3a33a02`, `8af9fcb`; this subsequent optimization is committed in the current interaction.

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

**User decision, 2026-10-07 — initial-index optimization remains pending (D-41 / OR-19):** retain this as future work after the diagnostic investigation. Next work must attribute the signed-application timing gap with a controlled cold A/B, then reduce traversal/metadata and suspension costs without sacrificing tags, visible Home/Shared boundaries, hidden-item exclusions, cache reuse, bounded resources or post-completion quiescence. The existing real-tree 60-second target remains unmet. No further implementation or measurement is performed for this recording request.

**Commit request, 2026-10-07:** the user authorizes committing the pending high-tag-count benchmark, accepted catalog implementation/tests/contracts and first-pass diagnostic evidence in separate responsibility-based commits. Commit preparation verifies the unchanged production fingerprints, existing executed regression counts, JSON/script integrity and staged diffs. No further functional optimization or new test execution is introduced; D-41 / OR-19 and full-application acceptance remain pending.

The high-tag-count benchmark is committed as `5332e49`; the accepted catalog implementation, corrections, tests and contracts are committed as `ff3bab2`. First-pass diagnostic harnesses, measurements and the explicit pending optimization are recorded in the separate documentation/diagnostic commit accompanying this entry.

### ZF-43 — MCP server and Apple Intelligence integration (implemented; actual system verification pending; 2026-10-07)

The bundled executable exposes eight MCP tools over stdio using official Swift SDK 0.12.0, with separate explicit automation folder grants, bounded jobs/listings, real ZIP/7z operations and connection-local cancellation. Four localized App Intents actions reuse the same operation services; Settings copies ready-to-use configuration and explains/opens the Mac Shortcuts setup. The user-approved picker-to-MCP ZIP/7z round-trip passes; four actions appear in the Mac editor after signed build 2 installation. Unsupported automatic Mac App Shortcuts were removed. A saved native integrity action completes after the protected-path authorization fix; the temporary grant is revoked. The custom Compactar com Zforge shortcut is saved with 7z and Ask Each Time inputs, but three actual Siri queries cannot find its name. The user subsequently personally validated the compression shortcut after authorizing an omitted folder. The standard Xcode Debug bundle was refreshed to signed build 2 with all four actions/eight tools and existing grants. Siri/Spotlight invocation and onscreen context remain separate acceptance checks. Final regression passes 276 cases / 368 executions, including both localized Settings and adjacent compression Settings UI cases. Foundation Models is outside scope. [Requirements and validation boundaries](Documentation/Requirements/AGENT-INTEGRATION-PLAN.md); [usage](Documentation/Requirements/AGENT-USAGE.md); OR-20. Executed tests, builds and pending system/resource checks are recorded in REGRESSION-COVERAGE. D-46 records the preexisting startup-fixture assertion reproduced on unchanged HEAD. No commit is requested or made.


### ZF-43 follow-up — Contextual folder permission (2026-10-07; implemented and verified within the recorded matrix)

Both MCP and Shortcuts request missing folder access through a localized native picker. All required scopes precede archive work; explicit consent persists and the same invocation resumes. Cancellation, scope mismatch, foreground unavailability and disconnection cannot create output. Coalescing and independently cancellable waiters are bounded within each process. Tests cover actual archive continuation, grant persistence/reporting, existing grants, minimal directory scopes, root-path refusal, mismatch, cancellation/retry and concurrency. Actual stdio cancellation and consent/listing/ZIP/7z round-trips pass on the synthetic approved folder. Final regression passes 286 cases / 378 executions with zero failures/skips. Installed native Shortcuts integrity cancellation, same-invocation consent/resumption and reuse pass. Unit/UI and release evidence are recorded separately in REGRESSION-COVERAGE. Existing user-created grants remain intact.


### ZF-43 — Consolidate redundant automation grants (2026-10-07)

The user approves replacing covered child grants when a parent is authorized and avoiding redundant additions under an existing parent. The shared store implements physical-boundary consolidation, validation before one persistence commit, legacy redundancy cleanup, independent outside-symlink permissions, active lease retention and post-consolidation capacity checks. Revoking the remaining parent does not restore children. Eight new automated scenarios cover the contract; initial failures and final evidence are recorded in REGRESSION-COVERAGE. Final regression passes 294 cases / 386 executions with zero failures/skips. Signed Release build 6 is installed. Actual native Settings child → parent → child-again → revocation sequence passes using only the approved synthetic root; the three original user grants remain. Broader OR-20 checks remain separate. No commit is requested or made.


**ZF-43 commit request and Siri continuation, 2026-10-07:** the user authorizes committing the pending native/MCP integration, contextual consent, grant consolidation and associated contracts/evidence. Separate primary API reference captures from the cohesive functional implementation. Preparation verifies the final source/test fingerprints, recorded 294-case / 386-execution result, JSON/script integrity and staged diffs. No new test execution is claimed by re-reading evidence. Siri remains unresolved under D-47 / OR-20 and is the next active investigation.

### ZF-43 commit and Siri schema continuation — 2026-10-08

The preceding work is committed as `d273684` (native API corpus) and `0c72561` (MCP/native actions, contextual consent and grant consolidation with synchronized contracts). No push is performed. Subsequent implementation adds a macOS 27 system.open archive entity action, shared URL opening, bounded authorized name/path discovery, thirteen behavioral cases and localized metadata. Final unit regression: 304 cases / 396 executions, zero failures/skips. The final rehydration UI runner failed before scenarios; isolated UI status is recorded separately. Signed Release build 9 is prepared, with the previous build preserved for rollback. Actual new-action discovery/execution and Siri results are tracked separately; Current Date control refusal shows an independent conversational shortcut-routing problem. ZF-43 / OR-20 remain open for actual Siri/Spotlight/onscreen and broader resource/platform acceptance.


**Siri retry with user available for approval:** build-9 asynchronous copy failure is corrected by one-use scoped window handoff and password-lifecycle ownership. Sixteen action/entity/lifecycle contracts pass; complete build-12 unit regression passes 307 cases / 405 executions, zero failures/skips (final encrypted window-close argument recorded in REGRESSION-COVERAGE). Installed native build 10 passes cold/repeated opening, missing-folder cancellation/consent/continuation and all-mode content continuity. Fresh conversational Siri still refuses the verified saved shortcut and full-path/action request before invocation, so no approval prompt appears. Signed build 11 is installed with corrected English/pt-BR Settings guidance; System Default is restored and the synthetic grant revoked. No personal permission or shortcut is changed. The primary schema corpus is committed as c20d43b; the functional schema/lease slice includes synchronized code, contracts, localization and executed evidence. D-47 / OR-20 remain open; D-48 records the preexisting already-open Settings list refresh gap.

Final password-retry closure characterization fails on prematurely released access before its fix; the local retry lease and post-resolution closed/dismissed/cancelled guard correct it. Exact-final build 12 regression passes 307 cases / 405 executions with zero failures/skips and is installed with rollback preserved. Native evidence remains distinguished from unit results in REGRESSION-COVERAGE.

Exact-final build-12 native contextual opening passes on the approved synthetic fixture. A fresh Siri named-archive/app/folder request refuses direct opening before archive invocation or consent; system routing remains pending. Synthetic access is revoked. This completed implementation slice is committed independently of the two API corpus changes; Siri acceptance is not declared complete.
