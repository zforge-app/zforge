# ZF-30 — plan de drag and drop de itens de archives

Updated **2026-10-04** by user instruction. **Implementation and regression tests performed.** evidence and validation limits recorded below and in the regression matrix.

The user accepted this version as a reasonable basis for commit. Bugs that you then report will be fixed with relevant tests and incorporated by amend to the functional commit; this does not change the validation limits recorded below.

## History observed

The user confirmed the deletion from the menu and the copy indicator that disappears when pressing Option. He reported that drag operations continue without occurring and that the representation uses a large icon, with animation from the top of the screen, unlike the drag of local items. Sent recordings and this report are references for the next validation; previous motor/receptor tests do not prove delivery by gesture real.

## Contract implemented

The rules below apply to items already contained in a archive. The context of destiny determines the meaning of Option; the indicator shall monitor destination and modifier changes throughout the gesture, and the operation shall capture both at drop.

| Source and destination | Without Option | With Option |
| --- | --- | --- |
| Inner item → real folder, other Zforge window, Finder or Desktop | Copy: extract at destination and preserve entry at archive; copy indicator | Move: extract at destination and remove the entry from archive; no copy indicator |
| Inner item → root or folder of own archive | Move the entry to the internal destination; no copy indicator | Copy the entry to the internal destination, preserving the origin; copy indicator |

Both operations within the same archive **modify the original compressed file**. Transfer between archives different remains a separate decision; It's not inferred from this rule. The existing flow of adding local files to a archive maintains your contract of confirmation and preservation of sources.

### Appearance and interaction

- To fully replicate the existing drag and drop outside archives in each mode: representation, dimensions, multiple selection formation, cursor position, start/cancell/conclusion animations, destination indicator and feedback.
- In List, drag the representation of the line as in the equivalent local item; do not replace the line with a large icon. Icons, Columns and Gallery use local behavior in their respective mode.
- The representation starts at the position of the item and follows the point of capture of the cursor, without appearing at the top of the screen or flying to it.
- Preserve selection, clicks, double click, menus, keyboard, disclosure, preview, zoom, scrolling and resize. Folders target and sidebar maintain their existing feedback.

### Confirmation and keyboard

- Before executing a move that changes the archive, explicitly warn that **the original compressed file will be modified**. This includes Option + drag out and drag without Option within the archive itself.
- The warning identifies archive, the amount of items and the destination; informs that entries will be removed from source after transfer. Offers native and located confirmation and cancellation.
- Approve with Return/Enter and cancel with Escape, without depending on the mouse. Tab/Shift+Tab and Space allow you to navigate and trigger the buttons through native controls.
- Capture the complete request before displaying the warning: source, destination and operation. Close dialog cannot discard an approved request or reinterpret Option after drop.
- Cancel the movement does not extract, does not change the destination and does not modify the archive. The copy out does not modify the archive. For the internal copy, preserve the confirmation of change already used by the addition of contents to archives.

### Result and integrity

- The extraction records exactly in the folder where the item was released, keeping its name and without recreating the internal ancestors. Empty folder area uses the folder displayed; folder line uses that folder; Columns use the destination column.
- folders include descendants. Multiple selection normalizes parent/descendant and does not duplicate the same entry.
- Solve name conflicts according to existing controls; items kept by decision of the user retain their origins.
- To move out, complete approved exports before removing entries. Failure/cancellation does not remove origins; report any copies already published in failure partial.
- To copy/move within the same archive, prepare the reorganization in a copy, validate and replace the original only after success. Do not record intermediate addition states followed by removal in the original.
- Refuse to move a folder to yourself or to your descendants. Moving to the source folder itself is an unaltered operation; copying in the same directory requires treating the destination name without silently deleting the source.
- Preserve current password protections, authorization, cancellation, paths, and obsolete session detection. Current writing is limited to ZIP/7z single volume root; do not expand support to formats/volumes/content nested by inference of this plan.
- After success, update only the changed archive. Migrate Back/Next to the new session, preserving valid paths and navigation order; repopulate all ancestral columns and their selections. Reveal another directory logs navigation to return to the previous folder. Discard destinies removed and retreat to the surviving ancestor if the current one disappears. Keep your browsing and the surviving directories expanded, open ancestors of the internal destination and reveal/select the result. Other trees keep their state. On the copy out, keep the original tree.
- The existing contextual/keyboard deletion continues with confirmation and updating of the tree.

## Execution steps

1. **Characterize local drag in each mode and diagnose delivery.** Compare local/internal items side by side with test files. Follow source, accepted from destination, request confirmed, extraction and recorded result. Do not consider beginning of gesture or badge as proof of operation.
2. **Share presentation and resolution of the operation.** Reuse local visual behavior; separate virtual identity from appearance. Solve copy/movement by the current destination and option context, capturing the decision upon release.
3. **Implement request and confirmation.** Cover approval/cancellation only by keyboard, retention of request and absence of writing when canceling. Keep confirmation of change while copying in.
4. **Complete exit and internal reorganization.** Fix recording in the actual destination and remove after success; add copy/movement within the same archive with validated replacement, conflicts and cycle protection.
5. **Renew vision and validate from end to end.** Check content in destination and archive, expanded state and visual parity in all four modes. Update contracts with executed evidence; conservar limites pendentes explicitamente.

## Acceptance criteria

- Copy and move out proven by gesture real and content existing in the destination, including Finder/Desktop and another Zforge window.
- Internal copy and movement proved by the reopened content of archive, with the correct inversion of Option and preservation of the origin in the copy.
- Confirmation explains modification of the original; Return approves and Escape cancels without writing, both on exit by movement and internal reorganization.
- Presentation equivalent to the local item in List, Icons, Columns and Gallery, including multiple selection, badge, change of option/destination and start/cancellation without jumping from the top.
- Folders, conflicts, password, failures, cancellation, obsolete session and invalid destinations preserve the integrity of origins.
- Refresh reveals the result and preserves hierarchy, navigation, coherent selection and other archives open.

Tracking: [ZF-30](../../TASKS.md), [D-33](../../DIVERGENCES.md), [OR-14](OPEN-REQUIREMENTS.md) and [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

## Execution of plan

- Source native shared between locations and interns, with real line/cell snapshot, mode formation and coordinates in the session host. Immediate virtual identity and file promises; native destinations route to the most specific visible target.
- Confirmation of the original before any writing in internal movements and copies; request complete retained. Validated single internal update, external publication in the exact URL authorized by AppKit after own staging/validation and conditional removal the success of all promises.
- Refresh conserves surviving navigation, reveals destination/selection and restores expansion of List. Sources locals maintain original NSURL and native semantics of Option.
- `ArchiveMutationTests` freezes policy by context, ZIP/7z protected, bytes of origin/destination, folders, conflicts, cancellation, concurrent change, sequential publications and refresh in all four modes. `ZforgeUITests` uses `click(forDuration:thenDragTo:)` for gesture macOS real; `press` did not produce mouseDragged in previous attempts.
- Initial evidence approved: external copy in all four modes and internal reorganization in `/tmp/zforge-plan-ui-internal.xcresult`; External movement Return/Escape in `/tmp/zforge-plan-ui-final.xcresult`; integrity/refresh in `/tmp/zforge-plan-expanded2.xcresult`. Final round, Finder, local flows and visual limits in [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

Final validation: 164 unit cases/189 executions and eight cases of UI approved, including Finder and another window. The first round of UI had a failure in the navigation for inspection after confirming; this step was stabilized and the case repeated with approval. Wide visual check and Desktop separate remain in OR-14, according to regression matrix.

### Navigation correction after mutation — D-34

The recordings of 22:02 and 22:09 show that the writing ends, but Back comes out of archive; the capture of Columns shows empty ancestors while the breadcrumbs conserve the levels. The refresh completely removed the history entries from the old session and cleaned the data from the columns without renumbering the ancestors. The restoration now migrates valid paths to the new session, reconstructs data/selections from each column and records the reveal of another directory as navigation. The addition also saves the current internal folder. New tests feature deep history, destinies removed, fallback and reorganization; evidence performed in the regression matrix.
