# Zforge — differences between requests, documentation and current status

Survey started in **2026-09-23**, with documental paths updated in **2026-09-24**. Comparison made by static workspace inspection, `AGENTS.md`, `Documentation/Requirements/UI-UX-GUIDE.md` and previous Zforge conversations. The source of truth for existing behavior is [`Documentation/Requirements/CURRENT-STATE.md`](Documentation/Requirements/CURRENT-STATE.md); this file holds problems, gaps and conflicts**outside** of it. “Request” does not mean completed implementation. A problem reported by capture is distinguished from a proven cause by code.

## Provenance of the conversations consulted

| Reference | Conversa local | Relevant themes |
| --- | --- | --- |
| C-01 | 2026-07-12, session `019f57f8-d04a-7ca0-a0f7-ddb0cba82cd9` | Initial direction, browser, four views, selection, previews, toolbar, archives. |
| C-02 | 2026-07-14, session `019f62c6-d43f-7b62-a17b-db76a2065fca` | List, toolbar, width/overflow and mode preview. |
| C-03 | 2026-07-16, session `019f6d28-b864-76e2-ad11-4200a0f6cfab` | Recents, Home, breadcrumb, overflow and sidebar menus. |
| C-04 | 2026-07-17, session `019f7311-e825-7ca1-be74-c32db5ad2049` | Clipboard, file operations, drag and drop, undo, shortcuts, location. |
| C-05 | 2026-07-22, session `019f8c16-383c-7481-9553-504297119de6` | Icons, compression/extraction, Columns, progress and preview. |
| C-06 | 2026-09-22, tarefa `01a0cb8a-3ed8-7483-ad2b-dd4bd8c8e365` | opening by the Finder; correction incorporated in commit `d23e1f7`. |
| C-07 | 2026-09-22, this tarefa `01a0cb78-741d-79b3-a28f-682b568067c5` | App icon, widths, zoom, Recents duplicates, menu matrix and tracking. |
| C-08 | 2026-07-16, session `019f6af6-e52b-7520-92d6-c28f3b103f6c` | Toolbar, title, focus and documentation decision SwiftUI local. |
| C-09 | 2026-07-16, session `019f6d4b-fbb1-7913-aa64-481bd88c05fa` | Creation of the local corpus SwiftUI and orientation in `AGENTS.md`. |

The identifiers allow you to locate the original request in the local history. The content of other conversations is not operational instruction by itself; the current decisions are the direct instructions of the user and the consolidated contract in the repository.

## Product divergences or regressions

### D-01 — Icon of application absent in execution by Xcode (solved; user confirmed)

- **Request:** create and use a new icon; the user reports that a previous icon does not appear (C-07).
- **New report:** After the first correction, the user reported that the icon did not appear in the build executed by Xcode. The build existing in DerivedData already contained `AppIcon.icns`, `Assets.car` and icon keys in the plist; Finder visually showed the icon in that bundle. Therefore, the absence of the resource in the bundle was not reproduced.
- **Resolution in code:** in addition to the ten PNG entries of [AppIcon.appiconset/Contents.json](Zforge/Assets.xcassets/AppIcon.appiconset/Contents.json), [Info.plist](Zforge/Info.plist) explicitly states `CFBundleIconFile` and `CFBundleIconName`, and [AppDelegate.swift](Zforge/AppDelegate.swift) assigns `AppIcon.icns` to `NSApplication.applicationIconImage` at startup. Finder also showed the icon on the new build. **Confirmation:** the user reported that the icon is OK. The exact cause of the original report has not been proven. [Task ZF-02](TASKS.md).

### D-02 — Resize of lost columns (corrected and exercised in app)

- **Request:** drag lines/divisions to change widths; the user informs that this has worked before (C-07).
- **New report:** after the first correction, the user reported that the drag did not work yet. The anterior loop had only 10 pt invisible and did not communicate the action with the cursor; the gesture required to hit a narrow stripe.
- **Resolution in code:** the handles of List and Columns use a `NSView` 20 pt with horizontal resizing cursor and native drag capture; the widths persist in the preferences, with minimum and maximum. The terminal area of Columns uses the adjustable preview width, initially 300 pt. In the previous build, the drag was manually exercised at List and Columns and moved the partitions. [Task ZF-03](TASKS.md).

### D-03 — Scale implemented, zoom shortcuts missing (solved; user confirmed)

- **Request:** `⌘+`/`⌘−` as in Finder (C-07). [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) also specifies `⌘=` as the equivalent of increasing, `⌘0` to 100% and 10% steps between 70% and 160%.
- **Resolution in code:** commands `⌘+`, `⌘=`, `⌘−` and `⌘0` change the scale persisted in steps 10%, within 70–160%, and appear in shortcut help. **Confirmation:** the user reported that the zoom is OK. [Task ZF-04](TASKS.md).

### D-04 — Recents shows working copies as repeated items (corrected)

- **Request/observation:** catches of 2026-09-22 and 2026-09-24 show `Archive.7z` repeated in Recents (C-07). The second regression was reproduced in the interface.
- **Cause identified in the flow:** the engine copies each archive open to `temporaryDirectory/Zforge/ArchiveSessions/<UUID>`. These copies have the name and date of the original, but new physical paths and identities; deduplication by path/inode did not exclude them. The origin of each specific catch line was not inspected, but the staging flow and the actual copying test reproduce this gap.
- **Resolution:** [RecentItemsService.swift](Zforge/Services/RecentItemsService.swift) ignores all `temporaryDirectory/Zforge` before counting the 250 results. [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) applies the same rule before publishing the list, even with another Recents provider. [ZforgeTemporaryStorage.swift](Zforge/Services/ZforgeTemporaryStorage.swift) shares the path with the engine. Files distinct originals with equal metadata remain separate. The unitary and UI suites have passed; the real Spotlight-corrected build showed a single `Archive.7z` input. [Task ZF-05](TASKS.md).

### D-05 — Secondary click menu does not follow the requested matrix (solved; user confirmed)

- **Request:** for a common file, Open/compress/compress custom; for a archive, Open/Extract here/Extract to folder of the same name/Extract/Validate; for several archives, add file and archive options, with names of output folders separated by comma; for selection with common files, use file options (C-07).
- **Resolution in code:** [BrowserItemActionsMenu](Zforge/Views/BrowserContentViews.swift) consults the shared matrix of [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) and preserves multiple selection in new operations. One archive offers three extraction and validation destinations by `7zz t`; several archives also offer compression. Previous options remain. Open multiple archives creates dedicated windows; multiple validation is sequential. **Confirmation:** the user reported that D-05 is OK. [Task ZF-06](TASKS.md).

### D-06 — Toolbar button `•••` does not offer the same contextual options (resolved; user confirmed)

- **Request:** The options of the D-05 matrix must also appear on the ellipsis button shown in the capture, preserving the existing behavior (C-07).
- **Resolution in code:** [showToolbarActionsMenu](Zforge/ContentView.swift) consumes the same matrix/handler of D-05, keeping Quick Look, Information, Tags (enabled for local selection from 2026-10-03), Rename, Duplicate and Share in the applicable overflow. **Confirmation:** the user reported that D-06 is OK. [Task ZF-06](TASKS.md).

## Divergences between old documents and current behaviour

### D-07 — The read-only milestone has become historical

- **Source:** the initial July 2026 plan specified a read-only browser (C-01 and the “Functional milestone: read-only browser” section of [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md)).
- **Later request/state:** C-04 and C-05 asked and received to create folder, rename, copy, move, aliases, Trash, permanent exclusion, compression and extraction. These operations exist in [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) and [FileOperationService.swift](Zforge/Services/FileOperationService.swift).
- **Documental resolution:** [AGENTS.md](AGENTS.md), [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) and [CURRENT-STATE.md](Documentation/Requirements/CURRENT-STATE.md) treat the cut read-only as past milestone. Do not remove access safeguards, password, sandbox and licenses that remain relevant.

### D-08 — Preview width Columns (reconciliated and enlarged)

- **Source:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) specified 420 pt in Columns, while later behavior used 300 pt in all modes.
- **Current user decision:** 300 pt remains the initial width, but the preview splitter must allow drag.
- **Resolution:** the guide and [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) now describe adjustable common width between 180 and 800 pt. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift) persiste a largura; Icons, List, Columns and Gallery share it. In Columns, the next column that replaces the preview uses and adjusts that same width. The gesture was exercised manually in all four modes. The horizontal alignment observed at Columns was recorded at D-13. [Task ZF-07](TASKS.md).
- **Updating in 2026-09-27:** the common rule for Columns was replaced by request D-15; Icons, List and Gallery continue with persistent preference. The previous paragraph records the status of ZF-07, not the current contract.

### D-09 — Left arrow at root level of List (reconciliated)

- **Source:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md), section 13, says “at the root level, go back to the previous directory”.
- **Later request/state:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) says root items do not react to left arrow. [moveListSelectionLeft](Zforge/State/FileBrowserState.swift) returns without action at the root level.
- **User confirmation:** the implemented behavior already works as expected. [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) was updated to say that the left arrow does not act at the root level. No change of code was necessary.

### D-10 — The UI/UX guide mixed current specification and prototype notes (reconciliated)

- **Source:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) still mentions `ExampleFiles` of the prototype and proposes architectural separations that Zforge already performs in part; it also describes `AppStorage` for language, while the code persists via `UserDefaults` in [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift).
- **State:** these lines do not represent, by themselves, a functional defect. These are old instructions or implementation details that can divert an agent from the current base.
- **Documental resolution:** the guide now describes the actual services, `FileBrowserPreferences`/`UserDefaults`, existing components and actual operations, preserving the applicable visual rules. `CURRENT-STATE.md` remains the current contract.

### D-11 — Unit of sizes and language of presentation (implemented; visual check pending)

- **Request:** limits of archive described as 1–5**GB**(C-01, now in `Documentation/Requirements/PRODUCT-REQUIREMENTS.md`) and visible strings/data consistent with the selected language (C-05, same document).
- **Research:** the [Apple](https://support.apple.com/en-us/102119) defines 1 GB of storage as 1.000.000.000 bytes and informs that the binary representation of GB was used by old systems. The [documentation of `ByteCountFormatter.CountStyle`](https://developer.apple.com/documentation/foundation/bytecountformatter/countstyle-swift.enum) describes `.file` as decimal in macOS and `.memory` as binary; in the local Foundation, `.file` displayed 1.000.000.000 bytes as “1 GB” and 1.073.741.824 bytes as “1,07 GB”.
- **Applied decision:** the simple label `GB` was maintained and the navigation limit of archives now uses 1.000.000.000 bytes per GB, including the standard value and ceiling of 5 GB. Independent security limits of materialisation continue on binary basis. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift), [BrowserModels.swift](Zforge/Models/BrowserModels.swift).
- **Correction in code:** The sizes of List, the abstract/preview and the big preview notice pass by `AppLocalization.byteCount`, with `ByteCountFormatStyle(style: .file, locale:)` and the chosen language. The SDK macOS 27.0 location declares the `locale` property of that API; the appearance in both languages still needs a visual check. The capture of the `ByteCountFormatter` page in the local corpus SwiftUI was pending because the previous attempt at direct access to `developer.apple.com` failed by DNS; o link oficial permanece externo.

### D-12 — contextual action of archive in Recents (implemented; visual check pending)

- **Request:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) defines, outside archive, extract if the selection contains only archives and compress when there is common file; the new matrix of C-07 menus does not exclude Recents.
- **User decision:** in Recents, the default destination is the actual folder where the object of the operation is. For batch extraction, each archive uses its own directory; for joint compression of different origins, the directory of the active item is used. Without active item, the first origin in order of path defines the destination.
- **Correction in code:** the main action also analyzes the selection in Recents; standard extraction, “Extract here”, “Extract...”, standard and custom compression use the rule above. The visual inspection and actual execution of these operations are still pending.

### D-13 — Horizontal alignment in Columns (corrected; column drag still requires visual check)

- **Contract:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) asks the active column to complete a preview width before the right edge.
- **Note:** in the manual execution of ZF-07, when there was only the active column and preview in a wide window, the terminal area kept the width adjusted, but ended before the window edge, leaving empty space on the right. The drag worked; the alignment of the set does not match the contract in all window sizes.
- **Regression observed by the user in 2026-09-24:** aligning the whole assembly to the right moved the first column away from the left edge; the capture shows a large void between the sidebar and the first column.
- **Correction in code:** when the set fits in the window, the first column absorbs the free width. It starts at the left edge, keeps the next column or adjacent preview and leaves the terminal area on the right edge. When it does not fit, it preserves the adjusted widths and horizontal scroll. A build signed with fixtures showed the result in wide window with folder/archive and file preview; the preview divider drag visually shifted the edge. The column splitter and overflow in narrow window are missing.
- **Updating in 2026-09-27:** the absorption rule by the first column was replaced by D-15. Each navigation column maintains its base width; the loaded preview uses the leftover to the right. The column splitter and overflow check continues in OR-04.

### D-14 — HTML preview stuck in loading (corrected and checked in test build)

- **Report of 2026-09-27:** When selecting `tempo.html` in Documents, Finder shows the static layout of the page, while Zforge remains in the built-in preview loading indicator. User captures demonstrate the difference; The exact internal cause of Quick Look has not been diagnosed.
- **Correction:** the simple selection hero forwards `.html` and `.htm` to `WKWebView.loadFileURL(_:allowingReadAccessTo:)`, giving access to the document folder to CSS and relative local resources. JavaScript of the document is disabled. The previous web view stops loading and is removed when the URL changes or the preview is disassembled; the other guys maintain their current paths. `com.apple.security.network.client` was added to the app sandbox to enable the startup of WebKit auxiliary processes and load external resources referenced by HTML.
- **Evidence:** `HTMLPreviewTests` passed loading HTML with relative CSS without running an inline script, exchanging file and rendering in the inspector's actual layout. In a signed test build without the entitlement of network, even minimal HTML left the area empty and logs showed closing WebKit processes; with entitlement, an exact copy of `tempo.html` displayed the static layout in Icons, List, Columns and Gallery. After deactivating scripts, the signed test final build displayed the same HTML in List and Gallery, and a proof file showed the initial text intact. Direct Finder Test: a local HTML with unique HTTP image caused local server request in both Gallery and Quick Look panel; a local HTML with inline script kept the initial text and did not request `fetch` in both previews. Distribution build has not yet been verified. [Task ZF-12](TASKS.md).

### D-15 — Fixed initial preview width Columns (corrected in code and under UI test)

- **Report of 2026-09-27:** The overall width persisted was loaded in new previews and reserved fixed space to the right, dislocating the columns to the left. Catches compare Zforge and Finder in shallow and deep paths.
- **User decision:** when loading each preview, use the width available to the right of the open columns, with a minimum of 320 pt and no maximum. A change in the available space before the next preview must change its initial width.
- **Correction:** Columns maintains navigation widths and only inserts the preview when eligible. Preview width is local to selection; the splitter adjusts only the current preview. The `SelectionOverview` ceases to impose global preference internally. Icons, List and Gallery preserve the shared width. `BrowserColumnsLayout` calculates the minimum and the remaining available. [Task ZF-13](TASKS.md).
- **Evidence:** the user confirmed that the problem was solved. Build Debug macOS aprovada; suite `ZforgeTests` approved; UI test with fixtures confirmed that the preview of `Welcome.txt` in the first column is wider than that of `Inside.txt` after opening `Sample.zip`, and that the second width respects 320 pt. There is no visual check with the capture files and narrow window divider drag.

### D-16 — Oscillation of the alignment between expanded column and preview (corrected in code and under UI test)

- **Report of 2026-09-27:** after correction D-15, browse from file to folder and return to file recalculated terminal width with each selection, moving the partition horizontally. The video and three capture sequence of Finder show the dynamic initial preview, the folder open to the right, and the next preview occupying the same track as the child column.
- **User decision:** When opening a folder/archive, the new column must be fully visible; when returning to a file from the previous column, the preview must occupy the same position and width. The dynamic calculation prior to expansion and the minimum of 320 pt remain.
- **Correction:** Columns records the levels that opened a child column, measures the terminal column by the final track and uses the same track for the next preview at that level. While opening the folder/archive or loading the file is pending, reserve the corresponding width without displaying obsolete content. The hidden preview preserves the base widths of the columns. [Task ZF-14](TASKS.md).
- **evidence:** `ZforgeTests` passed; UI test signed with `Welcome.txt → Sample.zip → Welcome.txt` confirmed width and both edges equal between the terminal column and the substitute preview. The previous UI dynamic width test also passed after change. There is still a lack of visual fluidity in quick navigation with the capture files and the gestures of the splitters.

### D-17 — Preview does not readjust after scrolling manual to the left (corrected in code and under UI test)

- **Report of 2026-09-27:** in the eight catches, the initial preview fits in the left-hand side; open a folder expands the terminal column and the next preview occupies this track. After manually scrolling to the left to display the entire column, the wide preview is cut as desired. Select another file, however, re-aligns the assembly to the right and keeps the width expanded, instead of adjusting the new preview to the visible leftover.
- **User decision:** reduce the minimum preview by Columns to 240 pt. The manual scrolling does not change the current preview; the next file selection recalculates its width and preserves the frame to the left. A selected folder/archive then expands the terminal column and aligns the set to the right.
- **Correction:** observe phase and distance from scrolling horizontal to differentiate manual displacement from scrolling programmatic. While the view is manually removed from the right edge, the next file selection again uses the available width and does not request scrolling terminal. The next directory restores this scrolling. The minimum is `BrowserColumnsLayout.minimumPreviewWidth`; Icons, List and Gallery retain their own width. [Task ZF-15](TASKS.md).
- **Evidence:** the final round passed with 85 unit tests and four tests of UI signed, including the previous two of Columns, the new cycle of scrolling and the one of Recents affected by fixture. The cycle covered a file → archive → file → scrolling horizontal manual → another file → archive, confirming the final geometries requested. The actual catches and the drag of the divider remain for visual inspection.

### D-18 — Integration of the finished metallurgy icon; open visual check

- **Later request:** the icon must gather a Z, reference to the role of archiver and reference to metallurgy, in visual language compatible with macOS 27. The user rejected the first comparison sheet of 16 alternatives.
- **State current:** file [`Zforge/zforge_icon.icon`](Zforge/zforge_icon.icon/icon.json), exported by the user in Icon Composer, was integrated into Debug and Release. The signed build Debug generated `zforge_icon.icns` and `Assets.car`, and the previous extracted from `.icns` shows the pressed Z. Finder/Dock inspection and light, dark and mono appearances are still open. The notes below preserve the chronology prior to integration. [ZF-19](TASKS.md), [OR-06](Documentation/Requirements/OPEN-REQUIREMENTS.md).
- **Later refinement:** the user indicated useful elements in 02, 03, 04, 06, 07, 12 and 15, in addition to 16 for the zipper direction. Two new comparison sheets of 16 alternatives ([anvil and hammer](Documentation/Design/Zforge-icon-concepts-anvil-hammer-16.png) and [Diagonal zipper with orange](Documentation/Design/Zforge-icon-concepts-diagonal-zipper-16.png)) and [a press study](Documentation/Design/Zforge-icon-concept-press-07.png) were generated for 07. The final choice remains pending.
- **The following explanation:** four comparison sheets of 16 variations were generated from the numbers chosen by the user: [anvil/hammer](Documentation/Design/Zforge-icon-refinement-anvil-02-04-08.png), [zipper](Documentation/Design/Zforge-icon-refinement-zipper-01-03-12-14-16.png), [press](Documentation/Design/Zforge-icon-refinement-press-16.png) and [graphic emblem](Documentation/Design/Zforge-icon-refinement-graphic-03-04-10.png). The “fourth image” was interpreted as [this comparison sheet](Documentation/Design/Zforge-icon-source-graphic-fourth-16.png), displayed fourth in the previous round, with graphical and three-dimensional approaches. No app asset has been replaced.
- **Latest selection:** the user chose 02 of the comparison sheet of anvil/ hammer, 07/09/15 of the press and 01/02/09/12 of the emblems. Two new comparison sheets of 16 alternatives record [a close synthesis](Documentation/Design/Zforge-icon-synthesis-selected-close-16.png) and [a synthesis with new arrangements](Documentation/Design/Zforge-icon-synthesis-selected-hybrid-16.png). The decision of the final asset remains open.
- **Refined method of exploration:** the user reported that comparison sheets results in inferior quality and asked for individual images. They were generated [16 separate candidates](Documentation/Design/IconCandidates/README.md), without new comparison sheet. The candidate 07 was refined only in the palette, keeping the first version preserved in `Drafts`. The icon used by the app has not yet been replaced.
- **New physical references:** the user pointed inconsistencies in previous presses and provided a hydraulic press photograph and an image of colored office folders. The [candidate 17](Documentation/Design/IconCandidates/17-hydraulic-press-folders-z.png) shows piston and platens aligned, with folders lying and supported between them and a Z in the upper indent, but its structure in H was rejected; the asset installed remains the previous.
- **Correction of the press style:** the user rejected the H structure of the candidate 17 and reiterated that each round must bring only one well-worked image. The [candidate 18](Documentation/Design/IconCandidates/18-hydraulic-cylinder-folders-z.png) uses yellow and black cylinder, central piston and circular discs aligned with the folders, following the photograph. The user confirmed this direction; no app asset has been replaced.
- **Stylization:** the user confirmed that candidate 18 follows the desired direction and asked for an apt version to function as an icon. [candidate 19](Documentation/Design/IconCandidates/19-stylized-hydraulic-cylinder-folders-z.png) preserves the mechanism and reduces visual complexity; the user later indicated adjustments of edges, Z and background. The installed icon has not changed.
- **Edge refinement, Z and background:** the user asked the top and base to reach the edges of the image, that the Z had three-dimensionality of the future layer, and rejected the green background of the candidate 19. [candidate 20](Documentation/Design/IconCandidates/20-press-edge-to-edge-raised-z.png) applies these PNG changes with confirmed alpha; there is still no layered file or approval to replace the app asset.
- **Material correction:** in candidate 20, the user identified folders with rubber appearance and inappropriate shape to the perspective, as well as unrealistic metal on both discs. The [candidate 21](Documentation/Design/IconCandidates/21-cardstock-folders-machined-steel.png) remakes the folders as folded card with tabs and paper edges and reinforces the finish of machined steel. Awaits evaluation; the app asset has not changed.
- **New references of folders:** two images of color folders were provided without textual instruction. The [candidate 22](Documentation/Design/IconCandidates/22-folder-reference-refinement.png) interprets them as a reference of covers, tabs and internal roles, keeping the stack lying between the disks. The direction was replaced by the subsequent request of a cabinet; the app asset has not changed.
- **Armary in place of folders:** After seeing references from other archivers, the user asked to replace the stack with a file cabinet. The [candidate 23](Documentation/Design/IconCandidates/23-hydraulic-press-filing-cabinet.png) uses a two drawer cabinet between the disks; the user then requested higher height and new position of the Z. It does not replace the app asset.
- **High and position of Z:** the user asked to increase the cabinet of candidate 23, climb the top of the press and move the Z out of the cylinder. The [candidate 24](Documentation/Design/IconCandidates/24-tall-filing-cabinet-z-on-platen.png) uses three drawers, high press and Z on the front face of the upper platen. Awaits evaluation; the app asset has not changed.
- **Return to Z pressed:** the user discarded the cabinet as an object between the discs and ordered Z itself to be pressed. The [candidate 25](Documentation/Design/IconCandidates/25-pressed-metal-z.png) explores a metal Z between the platens; remains pending evaluation and does not change the installed asset.
- **Cut on Icon Composer:** user capture showed that candidate 25 was cut into the composition. The [candidate 26](Documentation/Design/IconCandidates/26-pressed-z-icon-composer-framing.png) removes the view, shortens the top and maintains transparent margins. The result still depends on check at Icon Composer; the installed asset has not changed.
- **Base to the edge:** the user marked the empty margin under the base in an intermediate version. The [candidate 27](Documentation/Design/IconCandidates/27-pressed-z-extended-base.png) extends the lower metal to the edge of the image; still needs a check at Icon Composer and does not change the asset installed.
- **Legibility and mono mode:** three captures of Icon Composer show the detailed composition in light, dark and mono modes. The user asked for less visual pollution and a mono version of itself. The [candidate 28 colorido](Documentation/Design/IconCandidates/28-simplified-press-z-color.png) simplifies the press and the Z; a [mono version](Documentation/Design/IconCandidates/28-simplified-press-z-mono.png) usa geometria branca plana. Both were seen in a miniature of 64 px, but not yet checked in the Icon Composer; the installed asset has not changed.
- **Adjustment of the edges and center:** the user marked in the color version of candidate 28 the smooth cover above the stripes, the margin below the base and the low Z. The [candidate 29](Documentation/Design/IconCandidates/29-simplified-press-z-edge-crop.png) makes the striped cylinder and the base reach the edges and climbs the pressing zone; evaluation in Icon Composer pending, no change in the asset installed.
- **More remote view:** on the candidate 29, the user asked to move the camera away. The [candidate 30](Documentation/Design/IconCandidates/30-simplified-press-z-distant.png) reduces the apparent scale of the platens and Z, increasing the lateral margins without losing the vertical continuity of the cylinder and base; evaluation in Icon Composer pending, no change in the asset installed.
- **Layer separation:** the user requested two or three layers that preserve the composition of candidate 30. The [plan](Documentation/Design/IconCandidates/31-layer-plan.md) defines three pieces in the base order, Z and head. The extraction by ImageGen changed the scale and position of the parts, so there are no PNGs aligned; the installed asset has not changed.
- **Later export and integration:** the user provided a `.icon` mounted on Icon Composer, with three images in two groups, and requested its application to Zforge. The file was placed at the root of target, the build settings and the plist started pointing to `zforge_icon`, and the manual attribution of the old `AppIcon.icns` was removed at startup. The bundle test was updated; the visual result in use still needs to be observed.

### D-19 — Extension displayed when changing the format in the custom panel (open)

- **Note in 2026-09-28:** in the test build with fixtures, changing the panel format `Compress Custom…` from 7z to ZIP updated the controls and height, but field `Save As` continued to show `Welcome.7z`. The code calculates the final extension from the format chosen after the panel, so the observed divergence is between the displayed name and the destination that the code intends to create; the real creation was not carried out at this check.
- **Next step:** update the suggested name in the panel by changing format without discarding a user-edited name, and validate the URL created for simple formats and TAR layer streams.

## Points not yet classified as divergence

- The correction of the window opened by the Finder in C-06 integrates the commit `d23e1f7` of the branch `main`; the build and manual opening were reported in that conversation, but not repeated in this review.
- Old conversations include many preview bugs, sidebar, drag and drop and Columns. the current code contains mechanisms addressed to them; this static review did not reproduce each scenario. Future execution failure must generate specific divergence with playback step, version and evidence.
- Distribution Direction (MIT for original code, 7-Zip under your licenses, free version on the site and paid on the Mac App Store) is a [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) goal, not a ready delivery. Final signature, notation, corresponding source obligations and legal review were not audited in this documental task.

### D-20 — Build and global tag filter after reversal

**Corrected in code and exercised in the app in 2026-10-02.** Incomplete reversal kept users of the API of columns removed in `ContentView`; the definitions and consumers were recovered together. The search for tags depended exclusively on a Spotlight query that returned zero on the signed build sandbox. The catalogue now combines Spotlight with actual reading in second plan of authorized directories and FSEvents; the filter validates current tags, including folders, and individual reading removes the resource cache from the URL. The entire sidebar line receives the click. Actual filter was checked, discovered outside the current folder and refreshed; coverage and remaining limits are in `REGRESSION-COVERAGE.md` and OR-09.

### D-21 — Native extract in the app container with sandbox

**Corrected in 2026-10-03 during the preparation of the benchmark of RAM.** The instrumented build Release created, listed and tested ZIP, but failed to extract a file of 256 MiB in the app's own tmp. The bridge opened the absolute components since `/`; this path by the ancestors of fate failed in the path of the container. The correction receives the authorized destination root, opens its descriptor directly and only travels the descendants with `openat`/`O_NOFOLLOW`, preserving the protection of paths. The real case passed after correction and checked SHA-256. 109 tests of the dynamic variant passed, including refusal of output outside the root. This does not prove PowerBox/external bookmarks not all states of UI; the complete matrix of RAM will be recorded separately.


### D-22 — Static build blocked by Xcode script sandbox

**Corrected in project in 2026-10-03.** The user's report was played in DerivedData Xcode standard: `Build SevenZipCore` failed to create `SevenZip/Debug` with `Operation not permitted`. The profile generated allowed only the literal paths declared in `DERIVED_FILE_DIR`, without authorising their descendants; an explicit list of objects still blocked the temporary files of `libtool`. The phase now uses `TARGET_TEMP_DIR/SevenZip`, under the temporary area that the profile recursively authorizes, declares the final library as output and keeps the linkage paths synchronized in Debug/Release. `ENABLE_USER_SCRIPT_SANDBOXING` remains enabled; there was no change of backend or permissions of the app. Evidence of build in `REGRESSION-COVERAGE.md`; ZF-21.

### D-23 — Reading-only tags

** Corrected and confirmed by the user in 2026-10-03; 116 unit tests and 6 of UI approved in refinement final, wide pending visual matrix.** request adds definition/creation of tags by the context menu and icon between Share and ellipsis, in addition to the color of folders. The shared sheet edits local Finder metadata, preserves unedited tags of each item and updates catalog/filter. The first version adopted the first color tag in the order of the name; the refinement below uses the color of the front in the inverted stack. The evidence performed is `REGRESSION-COVERAGE.md`.

#### Refining of D-23 requested after user test

The first version only offered the item that opened the sheet, stacked circles from left to right and collected the entire folder (including paper). The refinement implements fast line of seven tags, check/hover +/x and Edit Tags with symbol, stack from right to left and choice of color from front. The recoloring starts to operate only on the blue material, keeping paper and neutral details; rasterization uses 512 px to not expand a logical representation of 32 pt. Coverage and limits in `REGRESSION-COVERAGE.md`.
### D-24 — Inconstant drag feedback and sidebar replaced icon

Report of 2026-10-03, with recordings of Zforge and Finder and capture of the monochromatic selection. The sidebar alternated between the native bottom of List and the custom contour; destinies exchanged their symbols for open folder. It also did not represent the current directory with its own highlight.

**Reproductions 18:56 and 19:47:** the first revision retained a highlight and failed the finishing/end of the list; the second, with global delegate, regressed the pin and was reverted to request of the user. In this third review, the handlers return by item, with upper/lower edges, monochrome selection, stable symbols and native cleaning by owner. Remove only the visible entry “Add Folder...”. Pin via menu was exercised with disposable reference; pin with actual URL payload was run in test. The stability of the continuous gesture has not yet been confirmed by automation; D-24 remains with pending visual check.

### D-25 — Automatic drag in the folder itself creates copy

Save 19:47 shows copy of PDF with suffix after extension. Corrected in code: export the original URL as `public.file-url`, and check the canonical equality of the parent directory before the operation inference by volume. Automatic/move to the same parent return the originals without creating files. Option/paste/Duplicate continuam copiando. Test with approved file/folder and alternative URLs/symlink; provide bytes loaded by NSURL and pin in approved original destination. The video demonstrates the previous playback; was not treated as execution of the corrected build.

**Return 20:11:** User confirms that the functional part has been resolved (pin and copy regression), but the indicator is cut. The overlay of each cell drew half the circle out of its limits. Adjusted only the drawing: native layer above the clip view, anchored to the cell, without hit testing; handlers per item preserved. Test of the approved native hierarchy and build; completion of the new build during gesture not yet checked by automation.

**Visual refinement 20:22 (D-24):** Video confirms clipping improvement, but highlight of the current folder still covered part of the line. Corrected composition: indicator's own backing layer with zPosition superior to sister layers, including after late creation of highlight. Thickness of the line passes to 2 pt by request of the user. Test of the approved hierarchy/composition; check during the actual drag of the new build remains pending.

**Circle refinement in 2026-10-03:** User confirms line improvement and asks for a proportional circle. Increased external diameter from 5 to 8 pt, contour from 1 to 2 pt; vertical center, left beginning and right end preserved. Visual check of the new size during pending drag.

**Adjustment requested in 2026-10-03:** circle of the enlarged indicator to 12 pt of external diameter; contour and line kept at 2 pt. Vertical center and horizontal boundaries preserved.

**Choose final in 2026-10-03:** by request of the user, circle returns to 8 pt of external diameter, with contour and line 2 pt. The study of 12 pt is historical.

### D-26 — Inner folder with different shape and colour of the native folder

- **User report and decision:** directories within archives must remain distinct, but preserve the system folder. The difference must be a circular stamp of Zforge in relief, lower right in large and centralized size when small.
- **Correction:** `FileIconView` uses the native folder for directories `.archive`, with monochromatic vector stamp of press/Z identity. The compact limit is 32 pt, applied to the size displayed after zooming. Local folders maintain cache, content composition and drop transition.
- **evidence:** build and approved unit suite; AppKit isolated rendering between 16 and 190 pt. The visual matrix in the app remains in OR-13; ZF-29 and `REGRESSION-COVERAGE.md`.
- **Required refinement:** higher stamp, higher in 48pt and lower in large previews; base with fewer tracks. Implemented in the composer and exported three states and a single stamp in `Documentation/Design/ArchiveFolderStamp`. The states with files/open are studies for revision; do not change the determination of content or the drop of virtual directories.
- **Later decision:** form v3 approved; the user considered the previous composition similar to an overlapping image and asked for physicality with light/shadow and **debossing**, as pressed folder. Planned improvement in `Documentation/Design/ArchiveFolderStamp/DEBOSSING-PLAN.md`; Not yet implemented.
- **Authorized and implemented integration:** v6 applied to the shared component via `ArchiveFolderRelief`, single source of light/shadow neutral masks. Replaces simplified geometry and keeps the native folder. Continuous circle cut the press. Build, 110 unit tests and isolated rendering conferred; fixed reference lighting without dynamic height/light renderer. Wide visual matrix remains in OR-13.
- **Pass with files:** the user rejected the open version of study and requested the closed folder with paper for internal directories containing files in all modes. Implemented with `archiveDirectoryContainsFiles` calculated from the listing once; descending/hidden/zero bytes files count, empty subfolders alone do not. Broad paper strip behind the native face, preserved v6 stamp. API of rejected open folder removed; local folders have not been changed.

- **New study requested:** folder opened during receiving by drag, following new native reference. Visual creation only at this stage; the user will decide when use. Do not automatically reintroduce the old rejected open version or replace the closed state with files.

- **Later entry authorized:** open proposal v7 approved. Apply open folder with stamp only to expanded internal directories in List, in the preview line and hero. Collapse restores closed folder; other ways do not inherit the opening. Implemented over the native icon opened `ofld`, keeping the seal by masks. Drag and drop of items within archives recorded as pending in OR-14/ZF-30; addition of existing local files does not replace that requirement.

- **Visual regression reported in the integrated open version:** `ofld` presented different texture/color, base with tracks and corners inconsistent with the closed folder. Fixed to use the same material in the closed folder: rounded face and rastered seal together and tilted with bilinear sampling, preserved rear panel, file-conditioned paper and contact shadow. The expansion rule hasn't changed.

- **Later point correction:** the two rounded leftovers of the closed face that leaked behind the paper in the open version were removed. The bottom begins to draw only the top native and extend an intact strip of the rear panel, avoiding reuse of the closed face in that region. Slanted face, stamp, expansion rules, and states of preserved content.

- **Correction of the interpretation of selection and perspective:** the user asked to remove lines, do not cut leaks on the rear panel. The raster edition with clippings was discarded and did not reach the app. Removed the gray outline of the paper in the open version; the base now preserves the original width of the panel, while only the top of the face widens by being closer to the observer.

- **Backlines still visible:** the removal of stroke from paper did not resolve the lines indicated in blue. The extended bitmap range was replaced by a continuous gradient sampled from the material native by column; the colour of the outer shadow does not participate in the sampling and the rear corner remains rounded. Perspective and stamp preserved.

- **Full closed folder:** the user approved the open correction and pointed paper on the external edge in the closed version. The horizontal clipping of the face restoration ended below its upper edge. Replaced by the rounded cut of the full face, making the native edge cover the paper. Seal, material, states of content and open folder preserved.

- **Empty open pass:** Export revealed step on left edge and residual rectangular gradient, hidden by paper in full state. The column sampling still reached the closed face. Replaced by samples exclusively from intact rear material, with smooth transition from the top native and alpha antialias at the edge. continuous empty panel; face/stamp/perspective preserved.

### D-27 — Local directories use the design prior to archives fixes

- **Request 2026-10-03:** reuse approved icons for internal directories by removing the compression indicator.
- **Implemented correction:** Shared composition for common local directories, in closed/open and empty/content states, without stamp masks. Withdrawal of the ancient local composer and the `ofld` resource; paper behind the edge, base and rear panel follow the refined geometry. Expansion in List update line and preview; Local drop saves the transition. Files/packages continue with system-specific icons; local content detection keeps any child direct.
- **Verification:** rendering and tests recorded in `REGRESSION-COVERAGE.md`; wide check of modes and drop interaction continues in OR-13.

### D-28 — Quick selection test in Columns failure intermittently in the suite

- **Previous evidence:** `rapidColumnArchiveSelectionPublishesOnlyCurrentArchive` failed `firstStarted` in the integrated suite (135 approved/1 failure) and passed isolated. There is no proven functional regression nor cause of established scheduling.
- **Test correction:** Repeated consultation with pauses of 1 ms; Wait for explicit signal from the simulated engine. First loading is suspended until cancellation, without automatic completion after 2s; second doesn't use artificial delay. Timeout of 10s detects real locking and failure fatal in preparation closes the scenario. Early signs are remembered; continuations and watchdogs are removed on signal, cancellation, timeout or closure.
- **Scope:** only fixture/tests and documented coverage; no modified production handler. Repeated verification at `REGRESSION-COVERAGE.md`; ZF-32.
- **Reopened verification, 2026-10-05:** the ZF-39 full unit run executed 182 cases (248 executions including parameterized cases): 181 passed and this case failed with `.timedOut("started:First.zip")`. The unchanged case subsequently executed once and passed in isolation. The previous synchronization fix and historical passing repetitions do not establish the cause of this new timeout or approve the failed full run. No timeout, expectation, or production Columns handler was changed to hide it. Investigation remains pending; evidence is recorded under ZF-39 in `REGRESSION-COVERAGE.md`.

### D-29 — Secondary click on empty space does not open the ellipsis menu (corrected; one-off check in the four modes)

- **Report:** recording 2026-10-03 at 22:18:43, at Icons, shows the empty area without the expected menu.
- **Identified cause:** Native bridge installed only in the cells of the items; funds had only the gesture primary to clean selection.
- **Implemented correction:** shared action menu with the `•••` button; background bridge in empty areas of the four modes with priority of item menus. Executed evidence and limits in `REGRESSION-COVERAGE.md`.

### D-30 — Swap display in a window changes all (corrected; validation in REGRESSSION-COVERAGE)

- **Report:** User provided recording `Screen Recording 2026-10-04 at 20.51.06.mov` and asked for window independence.
- **Cause:** active mode resided in the singleton `FileBrowserPreferences.shared`, observed by all windows.
- **Correction:** `FileBrowserState.viewMode` is initialized by the persistent pattern and starts to guide presentation, toolbar, menus, shortcuts, selection, metadata, preview, drop and reconciliation of Columns only in that window/tab. Settings keeps the default mode for future instances.
- **Evidence and limits:** ZF-34; tests and interface check recorded in `REGRESSION-COVERAGE.md`.

### D-31 — Confirm drop addition does not start updating archive

- **User playback in 2026-10-04:** recording shows local file loose in an expanded internal folder of ZIP in List; “Modify Archive?” appears, but respond Add does not produce visible update.
- **Causes in code:** the setter of `archiveAdditionBinding` cleans `pendingArchiveAddition` when closing the dialog. The `Task` created by the button only then consulted this state, found `nil` and returned without calling the engine. The menu/picker shared the same handler.
- **Implemented correction:** The action closure uses request of `presenting` and passes it explicitly to `confirmArchiveAddition(_:)`. The task does not depend on the presentation status; preserved the concurrent operation lock, cancellation, password, staging, copy of the origins and refresh of sessions.
- **Evidence and limit:** approved unit suite; four cases with real ZIP/7z, root/internal folder, simulate the already cleaned binding and confer extracted content, intact origin, unwritten cancellation and new session/breadcrumb. Attempted UI failed before opening the dialog in the automated gesture without validating the click or visual correction. OR-07 is still open. Results in `REGRESSION-COVERAGE.md`.

### D-32 — Successful addition collects the hierarchy of archive

- **User refinement in 2026-10-04:** confirmed that the addition works after D-31, but the inside that was being viewed closes. He asked to reopen the updated archive and expand the hierarchy to show the addition transparently.
- **Implemented correction:** In List, register expanded internal paths before invalidating the session; purge the changed archive tree, reopen on the same line and restore disclosures with the new IDs. Expand the path to the destination and select all the items added. The same restoration/reveal applies to the open root. Unchanged Archives keep their sessions and expansions.
- **Limitations:** the restoration covers archive root directories, without automatically expanding archives nested not all descendants. In other ways, refresh is maintained to the existing root; the new selection/reveal of the tree is appropriate to List. Cancellation/writing error does not execute restoration. Tests and visual check pending at `REGRESSION-COVERAGE.md`/OR-07.

### D-33 — Internal items cannot be dragged out or excluded

- **Request of 2026-10-04:** copy/extract by default; Option moves out by recreating archive without the items. Show copy indicator in the first case and remove it in the second.
- **Implemented:** source AppKit common to the four modes, virtual identity in the internal destinations and file external promises. Explicit policy ignores the default translation of Option in virtual origin. Exports end before validated native removal. Exclusion shares contextual/overflow matrix, File menu and confirmation by `⌘Delete`. Renewed trees reuse ZF-18; other archives keep sessions.
- **Limitations:** written only in ZIP/7z single volume root; copy for nested read/content formats. Reorganization within/between archives planned. Real tests cover engine/coordination; gesture/badge/Option/Finder continue in OR-14.

- **User return at this stage:** Delete from the menu works; drag out has no effect. Removal confirmed in use, no confirmation of drag output.
- **Correction of gesture/payload:** substitute monitor by synchronous mouseDragged recognition in the window host; maintain identity by initialising the provider by the designated initialiser; publish token as an immediate given, not as a promise. Fulfill promises individually without waiting for the final callback, keeping removal conditioned to the success of all and acceptance of movement. Synthetic gesture has not yet validated delivery: source started in CUA, but ended with empty operation. Validation and limits in REGRESSION-COVERAGE.

- **D-33, delivery at the still reported destination missing:** user reiterated that drag does not extract in the folder where it released. Added NSDraggingDestination receivers for internal app folders, virtual type declaration in bundle and session associated with recognizator in macOS 27 (fallback per event in 26). The receiver reads the identity directly and publishes it in the drop folder, keeping the transfer after the final callback. Tests check content/destination and copy/move; two attempts of UI did not start by automation timeout and CUA started the source without proving delivery. Divergence remains open for gesture physical/Finder/indicator, without declaring output by drag completed.

### D-33 — Return and scope refined in 2026-10-04

- **Confirmed by the user:** contextual exclusion and badge of copy that disappears with Option. This overcomes the pending confirmation of these two behaviors in the exercised build, without proving the operation.
- **Reported failures:** drag does not extract/move; preview uses large icon instead of local mode representation and is born at the top of the screen before reaching the cursor. Evidence reported with recordings `Screen Recording 2026-10-04 at 18.19.47.mov` and `...18.22.35.mov`; this documentary update does not affirm a new inspection of the videos.
- **Specified additional requirement:** All presentation replicates local drag; moves warn that the original archive will be modified and allow Return/Enter to approve and Escape to cancel. Within the archive itself, without Option moves and Option copies, re-recording the archive in both cases. The previous pending decision about reorganization within the same archive has been superseded by this contract; between archives different remains separate.
- **State:** [plan updated](Documentation/Requirements/ARCHIVE-DRAG-DROP-PLAN.md); implementation/correction and end-to-end validation pending. No change of code in this interaction.

### D-33 — execution of plan and frozen regression in 2026-10-04

- Source end shared by locals/interns uses cell/line snapshot with frame in the session host, without fixed icon/zero position. Local monitor captures mouseDragged and respects disclosure/visible area. Receivers choose the most specific destination, including column/folder/sidebar, by geometry.
- Output to Zforge folders proven by gesture real in all four modes. External Movement Return/Escape and internal reorganization without option move/with option copy executed in UI, with destination expansion. Real tests of protected ZIP/7z freeze integrity, conflicts, cycles, cancellation, concurrent change and refresh in all modes.
- Finder Diagnosis: The promise provides authorization for the final URL without authorising sibling staging in the directory. The extraction/validation continues in its own staging and external publication writes only in this URL; Indoor destinations maintain staging/neighbouring renaming. Removal still requires all publications and final acceptance of movement. Final results and limits in REGRESSION-COVERAGE/OR-14.
- The attempts with recognizor and `press(forDuration:thenDragTo:)` above are historical. Current gesture tests use `click(forDuration:thenDragTo:)`, which emits mouse events in macOS.

- **Final result:** output by gesture in Zforge folders in the four modes, Finder and another approved window. Move/copy internally and confirm Return/Escape approved. 164 unit cases/189 executions have passed; eight cases UI passed with a repetition of the navigation test. D-33 functionally resolved in the executed matrix; OR-14 retains wide visual finishing/Desktop/exchange of option in flight, without reopening internal requirements already implemented.

### D-34 — Mutation of archive erases historical and emptys ancestral columns (solved; user confirmed)

- **User evidence in 2026-10-04:** videos of 22:02 (Icons) and 22:09 (List) and capture of Columns. Inspection of the tables confirms completed internal copy, premature return to Downloads and still operating breadcrumbs; the image shows empty ancestral columns. It applies to all four modes.
- **Cause:** `refreshUpdatedArchive` removed all Back/Next entries with the old session, recreated only the Breadcrumbs and cleaned `columnItems`/`columnSelections`, reloading only the final destination.
- **Implemented correction:** Migrate valid history by path to the new IDs, discard only invalidated removed/ringed destinations, log browsing by revealing another folder and repopulate the ancestors/selections of the columns. Addition saves the current folder; directory removed backs up the surviving parent without a duplicate stop in Back. Others archives maintain their state.
- **Check:** new tests reproduced 26 executions with failure before correction; later focused round approved 24 cases/63 executions. Approved extended validation: 166 unit cases/229 executions and 3 cases UI, including gesture and Back/Next in all four modes. Two failures initials of UI by absence of window were resolved in the setup and repeated with approval. D-34 resolved in the executed matrix; evidence in REGRESSION-COVERAGE. Embed by amend to the functional commit as instructed by the user.


### D-35 — child column blinks with a copy of the parent list (corrected; approved time regression)

- **Report/inspection in 2026-10-04:** user confirms D-34 solved and provides recording of 22:53:59 (6,23s). Charts with each 1/30s show the list of Duplicate Downloads in the archive column in the selection exchanges at approximately 2,57s, 3,53s and 4,23s; each occurrence lasts about one frame.
- **Replayed cause:** the navigation publishes the child location before the asynchronous reading of its items. When there is still no `columnItems` of destination, `ColumnBrowserView` used `sortedItems`, which still contains the parent list. The UI controlled delay test failed exactly by `Welcome.txt` appearing in the `Sample.zip` column before loading its contents.
- **Implemented correction:** render only `sortedColumnItems(at:)` of each location. A column without its own cache waits without lines; caches/selections from previous columns and layout/preview rules continue in the same stream.
- **Check:** Time regression of UI approved in archive → folder → archive, with pending/loaded catches inspected. 166 unit cases/229 executions and five different UI cases approved in the final rounds, including navigation after mutation in all four modes and three preview/layout cases. Corrected and repeated test setup and co-ordinated failures; evidence/limits in REGRESSION-COVERAGE. Build assinada aprovada. ZF-36, incorporated by amend as request user.


**Main integration in 2026-10-05:** D-31–D-35 coexist with D-29/D-30 without IDs colliding. Refresh/drag follow window mode; Shared menus preserved. History in the four modes, absence of duplicate lines in the pending column and adjacent flows passed in the integrated matrix, recorded in `REGRESSION-COVERAGE.md`. Visual limits of OR-14 and runtime macOS 26 remain open.
