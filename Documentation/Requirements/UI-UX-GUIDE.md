# File manager UI/UX guide for macOS

This document defines the visual hierarchy, interactions and responsiveness of Zforge. Decisions taken of `UIDemo` were incorporated as rules of application. For the current implemented behavior, [`CURRENT-STATE.md`](CURRENT-STATE.md) prevails; known conflicts are in [`../../DIVERGENCES.md`](../../DIVERGENCES.md).

Before implementing or correcting an interface, see this guide. When a decision changes intentionally, update the document along with the code.

## 1. Product direction

- The application must appear native to macOS without trying to reproduce the Finder pixel by pixel.
- Finder is the main reference for navigation, selection, keyboard, views and density of the interface.
- Current SwiftUI and macOS APIs must be preferred.
- AppKit can be used alone when SwiftUI does not offer sufficient control or alter essential behaviors.
- Liquid Glass must strengthen hierarchy and grouping, mainly in toolbar and navigation surfaces. It must not be applied as an ornament throughout the interface.
- Legibility, predictability, accessibility and behavior native have priority over visual effects.
- System colors and icons must be used whenever possible to respect user's theme, contrast and preferences.

### Compulsory polishing of experience

Guideline of 2026-10-04, linked to [requirements RNF-Q01 to RNF-Q06](PRODUCT-REQUIREMENTS.md#quality-polishing-and-regression-prevention): seek a **“Wow effect”** for the quality of use. **“Design is how it works”** exige avaliar o fluxo inteiro; the guideline is not a statement that all current surfaces have already received this validation.

- Icons, colors and shapes must communicate action, type and state with consistency between modes, menus, toolbar and preview. Nomenclature and translations must be clear, natural and consistent, including tooltips, errors and accessibility labels in String Catalog.
- Positioning, sorting, sizes and spacings must follow the task hierarchy, with stable alignment, adequate interaction areas and legibility in the supported widths and scales. Check long texts, supported languages, light/dark themes, enhanced contrast and highlight color.
- Gestures, mouse and keyboard must produce the specified results and unequivocal feedback, preserving selection and focus according to the contract. Review normal, hover, selected, disabled, loading, error and cancellation states when applicable.
- Animations and transitions must explain the state change, maintain continuity and respond to quick or interrupted actions. Do not admit undue jumps, clippings, flicker or obsolete content return. Respect reduction of movement and avoid effects that delay action or harm accessibility.
- Check sequence, geometry and behavior by representative tests and check the finish on the running interface. record conditions, result and limits; approval of a final geometry does not prove fluidity during the transition. Apply the regression checklist of this guide to the affected surfaces and adjacent flows.

### Application icon

The [zforge_icon.icon](../../Zforge/zforge_icon.icon/icon.json) file, exported by the user in Icon Composer, is the currently selected source for the app. The studies below record the evolution of the visual direction; references to pending integration or approval describe the state of each round, before the current export. Legibility and appearance variants still need to be checked on the app installed.

- The current identity combines a **readable Z** compressed by a hydraulic press, connecting archives with metallurgy. The Z and the press action must remain readable in reduced size.
- The composition must work in the icon language of macOS 27 and in the appearances of Icon Composer. The comparison sheet in [`../Design/Zforge-icon-concepts-16-metallurgy.png`](../Design/Zforge-icon-concepts-16-metallurgy.png) was an initial study, not the selected source.
- From the metallurgy comparison sheet, the user pointed usable elements in **02, 03, 04, 06, 07, 12 and 15**; included **16** as additional reference for the zipper. Requested refinements: [16 studies of anvil and hammer](../Design/Zforge-icon-concepts-anvil-hammer-16.png) from 03/12; [16 studies of diagonal zipper with orange accents](../Design/Zforge-icon-concepts-diagonal-zipper-16.png) from 02/06/16; and [a study with press](../Design/Zforge-icon-concept-press-07.png) from 07. They are conceptual alternatives; the final selection is still open.
- In the next round, the user selected **02/04/08 from [first comparison sheet displayed](../Design/Zforge-icon-source-anvil-first-16.png)**, **01/03/12/14/16 from [second comparison sheet](../Design/Zforge-icon-source-zipper-second-16.png)**, **the study from the press** and **03/04/10 from [fourth comparison sheet displayed](../Design/Zforge-icon-source-graphic-fourth-16.png)** (a graphic treatment plan and industrial emblem). Four new comparison sheets of 16 variations were generated each: [anvil and hammer](../Design/Zforge-icon-refinement-anvil-02-04-08.png), [Diagonal zipper](../Design/Zforge-icon-refinement-zipper-01-03-12-14-16.png), [press](../Design/Zforge-icon-refinement-press-16.png) and [graphic emblems](../Design/Zforge-icon-refinement-graphic-03-04-10.png). None of these studies still defines the final icon.
- Most recent selection: **02 of the comparison sheet of anvil/ hammer**, **07/09/15 of the comparison sheet of the press** and **01/02/09/12 of the comparison sheet of graphic emblem**. The characteristics were combined in two new comparison sheets 16: [summary close to references](../Design/Zforge-icon-synthesis-selected-close-16.png) and [synthesis with new arrangements](../Design/Zforge-icon-synthesis-selected-hybrid-16.png). Both are studies for choice and refinement later.
- The user refined the method of exploration: **to generate each alternative as an individual image**, because the comparison sheets reduce the perceived quality. They were created [16 independent candidates](../Design/IconCandidates/README.md) from the selected characteristics, without mounting a new comparison sheet. The final choice remains open.
- Among the individual candidates, the user indicated **02, 10, 09, 11 and 12** as options with potential, but declared dissatisfaction with the results in general. These numbers are references to a possible next step, not a final choice.
- In the following operation, use as a visual reference a real hydraulic press and office folders of various colors. The art must include **hydraulic press, multicolored folders and Z** and preserve an intelligible physical relationship between cylinder, piston, mobile platen, folders and base. The user rejected the H-shaped structure of [candidate 17](../Design/IconCandidates/17-hydraulic-press-folders-z.png): the correct direction is a **cylindrical** press, with circular metal discs and yellow-and-black safety paint, as in the supplied photograph. Generate **one image at a time** and focus quality on it. The [candidate 18](../Design/IconCandidates/18-hydraulic-cylinder-folders-z.png) exploits this correction; the final choice remains open.
- The user confirmed the direction of candidate 18 and requested a stylized version that works as an application icon. The [candidate 19](../Design/IconCandidates/19-stylized-hydraulic-cylinder-folders-z.png) maintains the physical arrangement and simplifies surfaces and contours for reading in reduced size. Final approval and app integration remain pending.
- In the refinement of candidate 19, the user asked that the top of the cylinder reach the upper edge, the base reach the lower edge, the Z present volume as the future independent layer and the green background be replaced. The [candidate 20](../Design/IconCandidates/20-press-edge-to-edge-raised-z.png) uses cutting on the edges, Z in relief and transparent background; it's still a unique raster image for evaluation.
- In the following refinement, folders shall show folded **card/paper** material and shape consistent with the perspective, including thin covers, creases, tabs and leaf edges; must not look like rubber or solid blocks. The piston and circular discs must look like **machined steel**, with convincing thickness and reflections. [candidate 21](../Design/IconCandidates/21-cardstock-folders-machined-steel.png) explores these adjustments; remains pending evaluation.
- Two additional images provided by the user show colored office folders with staggered tabs, flat covers and internal papers. The [candidate 22](../Design/IconCandidates/22-folder-reference-refinement.png) uses these characteristics as a visual reference, keeping the folders lying between the press discs. This direction was replaced by the subsequent request of a filing cabinet.
- After evaluating references from other applications of archives, the user asked **a file cabinet instead of folders**. The [candidate 23](../Design/IconCandidates/23-hydraulic-press-filing-cabinet.png) explores a compact cabinet of two drawers between the discs, preserving the cylindrical press and the Z. The final choice remains open.
- For the next refinement, the user asked for**higher cabinet**, with the top set of the press moved up and the Z transferred to another location because the cylinder loses space. The [candidate 24](../Design/IconCandidates/24-tall-filing-cabinet-z-on-platen.png) has three drawers and Z in relief on the mobile platen; the final choice remains open.
- The user returned to the idea of **Z being pressed**, without closet. The [candidate 25](../Design/IconCandidates/25-pressed-metal-z.png) places a single metallic Z between the cylindrical press discs, in contact with both; remains a study raster, without final approval.
- The previous candidate 25 in the Icon Composer overcut the composition. The [candidate 26](../Design/IconCandidates/26-pressed-z-icon-composer-framing.png) removes the frame, reduces the height of the top and leaves transparent margins to keep press and Z within the useful area; the fitting in Icon Composer still needs to be checked by the user.
- For [candidate 27](../Design/IconCandidates/27-pressed-z-extended-base.png), the user pointed the empty margin under the base in an intermediate version of the frame. The lower metal base now extends to the edge of the image, keeping the Z between the platens; the evaluation in Icon Composer remains pending.
- Priors of Icon Composer showed excess details and loss of Z legibility, especially in small sizes and mono presentation. The [candidate 28 colorido](../Design/IconCandidates/28-simplified-press-z-color.png) reduces short cylinder composition with safety paint, two platens and dominant Z, without sparks. The [mono version](../Design/IconCandidates/28-simplified-press-z-mono.png) uses a corresponding flat white silhouette, with [SVG source](../Design/IconCandidates/28-simplified-press-z-mono.svg). The evaluation on Icon Composer is still pending.
- In the refinement color version, the user asked the striped cylinder to advance to the upper edge, that the metal base reach the lower edge and that the assembly rises to center vertically the Z. The [candidate 29](../Design/IconCandidates/29-simplified-press-z-edge-crop.png) applies these clippings and displacement; the mono version of candidate 28 remains unchanged in this round.
- The user requested a color version further away from the camera. The [candidate 30](../Design/IconCandidates/30-simplified-press-z-distant.png) reduces the apparent scale of the Z and platens, leaving more lateral space, while the striped cylinder continues at the upper edge and the metallic base at the lower edge. The mono version remains that of candidate 28; Icon Composer docking is still pending.
- The user asked to separate candidate 30 into two or three coherent layers for the Icon Composer. The [plan of three layers](../Design/IconCandidates/31-layer-plan.md) defines base at the bottom, Z in the middle and head of the press in front, all in the same canvas and without including the rounded background of the front. Insulation attempts per generation changed scale and position; There are still no layers lined up delivered.
- Later, the user exported his/her own `zforge_icon.icon` in Icon Composer, with three images in two groups and appearance variants, and requested its use in the application. The exported file is now the source of the Debug and Release icon; the visual comparison with the previous Composer remains pending.

## 2. Main window structure

The window uses `NavigationSplitView` with:

- sidebar to the left;
- main content on the right;
- toolbar integrated into the window title;
- path bar in the footer of the content.

### Sidebar

- Use `List` with `.listStyle(.sidebar)`.
- Keep Recents as the first line, without section or category header, using the `clock` symbol and opening the corresponding virtual list in the browser.
- Each common window opens initially at Recents. When there is no bookmark for Home yet, request this authorization at the opening because it limits the scope of the Spotlight query; cancellation keeps the explanation and action to try again.
- The computer item comes first in Locations, as in Finder (2026-10-29): titled with the Mac's system computer name (never hardcoded, refreshed when the name changes), with the model-family SF Symbol (`laptopcomputer`, `macmini`, `macstudio`, `macpro.gen3` or `desktopcomputer`) in the Locations neutral tint, highlighted while the window shows the computer level, and not a drop target. It opens the computer level: the mounted volumes and Network as items in all four modes, titled with the computer name in the window title and path bar; volumes opened from it keep the computer as the first path component, and `⌘↑` from a volume opened there returns to it. Settings ▸ Sidebar shows or hides it; it is shown by default.
- The actual directory of the user account appears as the first entry of Locations after the computer item, identified by the folder name (e.g. `felipe`) instead of the generic label “Home”. Not use as destination the Home directory redirected to the Sandbox App container.
- In “Go to Folder”, `~` and paths started by `~/` are expanded from this same actual directory of the account, never by Home redirected from the Sandbox App.
- Bookmarks Desktop, Documents and Downloads point to the corresponding folders within the actual directory of the user account. The search APIs redirected by the Sandbox App must not make these entries point to `Library/Containers/.../Data`.
- Favorites lets you fix new real folders by “Add to Sidebar” in the contextual menu shared by the four modes, or by drop in the header, between the entries and after the last favorite. The sidebar does not display “Add Folder...”. The header inserts at the beginning, the ranges enter before the next entry and the final space adds to the end. Fixing does not transfer content; the destination body keeps copy/movement/alias. “Remove from Sidebar” removes only the reference.
- Fix accepts multiple selection consisting only of folders, rejects files, packages and virtual content of archives, avoids duplicates and persists the order between sessions/windows. “Remove from Sidebar” removes only the reference. The body of each destination keeps the flow of copying/moving already implemented files. The user confirmed the operation in 2026-10-03; the limits of automation remain in the regression matrix.
- Sidebar item context menus follow Finder's order and grouping. Favorites: Open in New Tab, Show in Enclosing Folder │ Remove from Sidebar │ Get Info. Finder's Add to Dock is omitted: the App Sandbox cannot add Dock items, and the user chose removal over a permanently disabled item (OR-22). Build every sidebar section's menu from the shared `SidebarItemMenu` model and insert section-specific groups (for example volume actions) instead of writing a parallel menu, so titles, symbols, order and enablement never diverge. Show in Enclosing Folder acts in the same window, like Finder; Open in New Tab adds a tab to that window. Do not offer a command Zforge can never perform; a command that is only temporarily unavailable stays visible but disabled rather than failing silently.
- Locations and Shared items extend the shared menu with Finder's volume groups: Open in New Tab, Show in Enclosing Folder │ Eject “Name” │ Remove from Sidebar │ Get Info; Finder's Erase Disk… and Rename “Name” are omitted because the App Sandbox cannot erase (OR-23) or rename volumes the user doesn't own (OR-25). Show only what Finder offers for the item kind: no Eject for the boot volume or fixed internal volumes. Volume titles carry the volume name in curly quotes. Volume roots are never renamed from the content views either: every Rename entry point (File menu and Return, More menu, item context menu) is disabled for them in all four modes, while a volume renamed in Finder or Disk Utility is followed. Remove from Sidebar on a Locations item hides its Finder category (computer, home, Hard disks, External disks, Connected servers), and Settings ▸ Sidebar turns it back on, as in Finder.
- **Visual refinement chosen in 2026-10-03 — alternative B, thickness refined in 20:22:** line accent of `2 pt`, circle leaked of `8 pt` with contour of `2 pt`, starting `8 pt` to the left of the content. Draw at the full limit of the lines in a visual layer above the native cells, without cutting the circle/line and without intercepting clicks or drops; follow scroll. The indicator backing layer must remain above the highlight layers, including after native updates. Use zeroed native vertical inserts and equivalent padding inside the button, preserving height. The first/last `5 pt` of each favorite represents insertion; The body represents transference. The bottom edge of the last bookmark and the Locations header allow you to add to the end. Empty bookmarks accept pin in header. Keep handlers per item; do not replace with a global destination in List.
- The sidebar maintains the original symbols during drag; Never trade them for open folder. The transfer target receives a rounded solid accent background, with text and white symbol, without switching to contour. The current real folder, when represented in the sidebar, receives discrete monochrome background (`unemphasizedSelectedContentBackgroundColor`) and semibold name, as in the reference capture; drag has priority and the selection returns on exit. The bottom maintains horizontal margin of 10 pt.
- Sidebar icons follow Finder: Recents and Favorites are tinted with the accent color; Locations and mounted volumes use a neutral gray (`secondaryLabelColor`), legible in light and dark themes. When the window is inactive, every sidebar icon turns gray (`tertiaryLabelColor`), like Finder's inactive icons, and every row name turns gray (`secondaryLabelColor`) together, as in Finder; no section may keep white names while another grays out. Apply the shared `sidebarLabelStyle` to every row name. Tag dots keep their color while the window is active and turn the same inactive gray as the icons when it is not (`SidebarTagDot`). Use the native `appearsActive` environment, not window observers, and apply one shared icon style so equivalent rows never diverge.
- The computer level always lists Network (system network icon), sorted with the volumes. Network (also Go ▸ Network, `⇧⌘K`) is a read-only level titled `Computer name › Network` that lists the file servers found on the local network, each with the system file-server icon, updating live without moving the selection of servers that remain. **Add Remote…** sits in a bar at the top of the level, like the button row of Finder's Network window, in every view mode: a standard push button with the `plus` symbol, leading-aligned, with a help tag, the trailing ellipsis because it opens a sheet that asks for an address, and the same entry point as Go ▸ Remote (`⌘K`). Placement rationale: a persistent bar does not depend on the server list, so the button never moves, appears or disappears as servers come and go and the content below never jumps; a centered button only for the empty list would have to relocate when the first server appears, and Columns has no single empty area for it. With no server the level is empty below the bar, without a notice or a spinner (user request, 2026-10-30). When Local Network access is denied and no server is known, a `ContentUnavailableView` says so and offers **Open Privacy Settings**; it is kept because it explains the empty level and leads to the fix, while the bar's Add Remote keeps working. The sidebar has no Remote row; Shared hides its header while it has no mounted share, and Network is the last Locations row (after the volumes), drawn like the computer row (neutral gray symbol, highlighted only while the Network level is current, no drops, only Remove from Sidebar in its menu). A single click selects a server (also in Columns); opening it starts the system's connect flow and, once a share is mounted, shows the share. Leaving the level stops the search and abandons a pending connection without navigating later.
- Ejectable volumes in Locations show Finder's inline ⏏ button at the trailing edge of the row: secondary gray, stronger on hover/press, gray in an inactive window, white on a drop target, with a localized “Eject “Name”” tooltip and accessibility label. Reserve its slot so long names truncate before it, and keep the hit area at least 20 pt square. While ejecting, a small spinner replaces the glyph and further clicks are ignored. Ejecting never blocks the main thread; a failure (for example a busy disk) uses the window's standard alert and leaves the location unchanged; a window browsing the ejected volume moves to the computer level. Every eject surface (button, File ▸ Eject, sidebar menu) calls the same handler.
- The transient highlight disappears when leaving the destination or release the drag; cleaning also accompanies native position/button of active destination. Callbacks from previous owners cannot clean a new target. Disable only the native sidebar table feedback, preserving tables and content handlers.
- The Tag section is at the end of the sidebar and displays the global catalog of the authorized files and bookmarks of Finder, regardless of the current folder. Its circles measure 12 pt ( 4 pt reduction), with real color or contour for colorless tags. The entire line accepts click and opens the corresponding global filter, including marked folders. Tag changes update the sidebar and the filter automatically opened; the initial discovery is progressive. Back/advance preserves the filter.
- For file system locations, breadcrumb always shows the complete path from volume, for example `Macintosh HD > Users > felipe`, even when browsing started with an intermediate sidebar input. These visual ancestors must not create empty levels in the visualization at Columns.
- The surface shall continue visually at the top of the window, without cutting between sidebar and titlebar.
- Use system material, currently `.ultraThinMaterial`, respecting safe areas.
- Minimum width: `180 pt`.
- Largura ideal: `220 pt`.
- Maximum width: current window width minus `360 pt`, always preserving this minimum width for the main content.
- `navigationSplitViewColumnWidth(min:ideal:max:)` expresses preferred widths and, in isolation, does not prevent the divider from exceeding the maximum in macOS. Keep this modifier for layout SwiftUI and apply the same ceiling at `NSSplitViewItem.maximumThickness`, which also restricts manual resizing.
- Resizing the window does not change the width chosen for the sidebar. When the window gets too narrow, limit sidebar only as long as necessary and restore its previous width as soon as there is space again.
- If the sidebar is automatically hidden, it must reappear when there is space.
- If the user hides it manually, this choice must be preserved.

### Main surface

- Use the same color for all views.
- The current reference is `NSColor.underPageBackgroundColor`.
- Toolbar, list, columns, icons and gallery must not display arbitrary hue changes.
- Keep the automatic background of `windowToolbar` hidden, preventing the scroll edge effect from changing its tonality by switching views or resizing the window.
- Separaters must be discreet and used only when clarifying the structure.

## 3. Window responsiveness

Current limits are based on actual grid dimensions at 100% zoom.

| Decision | Current value |
| --- | ---: |
| Grid cell width | `110 pt` |
| Cell spacing | `24 pt` |
| Side grid padding | `16 pt` |
| Minimum Window Width | `544 pt` |
| Automatic sidebar concealment | `678 pt` |

The minimum width equals four cells:

```text
4 × 110 + 3 × 24 + 2 × 16 = 544 pt
```

The window uses `.windowResizability(.contentMinSize)` to make macOS respect the minimum content size.

### Regras

- At minimum width, four icons must fit with the hidden sidebar and zoom in 100%.
- The decision to hide the sidebar considers the full width of the window, not just the content area.
- Responsive changes must take place in stages, taking advantage of the space released by each compaction.
- Avoid compacting multiple groups simultaneously if the first compression already releases enough space.

## 4. Toolbar

The display mode is individual by window/tab. The complete, compact and overflow selectors, menus and shortcuts `⌘1`–`⌘4` act only in the corresponding window. Each new window starts in the persisted startup mode (Icons in the absence of a preference). Changing a window mode does not change other open windows or immediately overwrite the startup mode. The last browser window/tab closed saves its current mode for the next window and application launch, regardless of which window changed mode most recently. Closing Settings, Info, or shortcut help, switching tabs, and replacing scene content must not overwrite it. Normal Quit with windows still open saves the frontmost remaining browser mode. “Default View” in Settings changes the startup preference for future windows until a later browser close or Quit updates it.

### Structure

The toolbar shall contain:

1. button to switch sidebar;
2. back and forward buttons;
3. title native with the current directory name;
4. display type selector;
5. group shares of archive, share and additional menu;
6. additional action menu.

Breadcrumb must not occupy the toolbar. The attempt to use it as `ToolbarItem` damaged the calculation of overflow, responsiveness, and reading of the title.

### Back, forward and title

- The arrows maintain a real history of paths.
- Back and forward must be disabled when there is no destination.
- The title uses `navigationTitle`, with inline presentation, and only shows the name of the current directory.
- The visual order on the left is always: sidebar button, back/forward capsule and title. In macOS, independent items `.navigation` can be reordered by the system; to preserve this sequence, remove the automatic `.sidebarToggle` and gather the equivalent button and the `ControlGroup` of the arrows, in this order, within a single `ToolbarItem` applied to the sidebar column. The button sends `NSSplitViewController.toggleSidebar(_:)` by responding to the chain, reproducing the native action without observing geometry.
- The title and items on the right belong to the detail column toolbar. This separation prevents the `NavigationSplitView` from moving the arrows to the action section while preserving `navigationTitle` native.
- Historical navigation and selection of files are different states.

### View Selector

The selector has three presentations:

- complete: four segments with icons;
- compact: current mode icon accompanied by vertical chevrons;
- overflow: submenu `View` inside the double chevron menu.

In the overflow menu:

- `View` opens a submenu native;
- the submenu shows icon and name of each view;
- mark the current view;
- allow you to choose icons, list, columns or gallery.

Between `678` and `899 pt`, the selector uses its own compact capsule, with the current mode icon and vertical chevrons. Below `678 pt`, the selector enters the overflow and becomes the submenu `View`. By reducing the window from the full presentation, compact the selector before hiding the contextual action of archive and do not return to the segmented presentation in smaller widths.

### Action group

The File menu places **Open** immediately above **Open with**, using the contextual opening behavior for the focused window's selection. Keep it visible but disabled without a selected target or while an archive operation is running. Use the existing localized label (**Abrir** in Brazilian Portuguese).

In the expanded presentation, group remains with four actions:

1. contextual action of archive;
2. Share;
3. Tags (`tag`), to edit local selection;
4. ellipsis for additional actions.

The four actions share a single native capsule, separated from the display selector capsule. Each label preserves a visual range of `25 pt` to keep the padding regular between the symbols.
They must be declared as native items of a `ToolbarItemGroup`, delimited from the selector by a fixed `ToolbarSpacer`. Do not involve the set in an adaptive `ControlGroup` within a single `ToolbarItem`: after going through the overflow, this composition can return to the toolbar while preserving the compact spacing.

In Recents, contextual action is enabled according to selection. The extraction uses by default the actual folder of each archive, and the joint compression saves the archive in the folder of the active item. The explicit choice of destination in the panels remains available.

When the group of actions does not fit, a double chevron button reproduces the native overflow indicator of the toolbar. Between `840` and `899 pt`, the contextual action of archive remains visible in its own capsule and the menu begins with Share; below `840 pt`, the archive action also enters the menu. Open, Quick Look, Get Info, Edit Tags, Rename and Duplicate remain always expanded at the main level of this menu. Unlike Finder, this content does not become a submenu `Action`. Below `678 pt`, the submenu `View` is added at the beginning. The actions use the same handlers and enabled states of the expanded presentation; do not delegate this behavior to the automatic overflow of `NSToolbar`.

In the empty space of the item area, the secondary click and Control-click open the menu of the `•••` expanded button, preserving the current selection and the enabled states. Without selection, keep actions visible and disabled. Apply to the four modes; the cell's own menu has priority. Preserve the primary click that cleans selection, previews and layout controls.

In the secondary click of an item, offer Open with, Share and Copy without losing multiple selection when the item already belongs to it. Open with is a submenu of compatible apps, with Other... for manual choice; with Option vira Always open with for arquivos locais. Copy turns Copy pathname with Option, copying text instead of file references. Quick Look vira Slideshow with Option. In the File menu, New tab uses `⌘T` and Open with/Always open with and Quick Look/Slideshow follow the same native alternation. Disable actions without target valid and locate all new labels.

In the File menu, holding Option replaces **New Folder** with **New Folder with Selection** in the same position. The original empty-folder shortcut remains `⇧⌘N`; the selection command has the explicit shortcut `⌃⌥⌘N`. Group eligible selected local items into a uniquely named folder in their common parent, select that folder, and immediately focus inline rename in all four modes. Disable the selection command for empty selection, virtual archive items, items from different parents, loading, an active rename editor, or an operation already in progress. Preserve item contents and names; failures must restore moved items without overwriting other content. Undo restores the items and removes only the empty grouping folder; Redo groups them again. Escape cancels the rename editor while keeping the completed grouping operation. Implementation and evidence are tracked as ZF-39.

The double chevron uses secondary color while the menu is closed and only assumes the primary color during the actual presentation cycle of `NSMenu`, returning to the secondary state at `menuDidClose`. When archive or overflow appear as isolated buttons, their labels use a square area of `18 pt` and smaller symbols than the expanded group, preserving a circular background instead of oval.

### Breakpoints from toolbar

| Window width | View Selector | Actions |
| --- | --- | --- |
| `≥ 900 pt` | completo | four actions |
| `840–899 pt` | compact capsule | archive visible; too much on double chevron |
| `678–839 pt` | compact capsule | expanded in the double chevron menu |
| `< 678 pt` | submenu in double chevron menu | expanded in the same menu |

These values are calibration parameters. If icon sizes, title or actions change, measure again before changing them.

### Toolbar search (ZF-53, 2026-10-30)

Finder parity: a magnifying-glass item trails the toolbar, to the right of the archive/Share/Tags/More group, in its own capsule after a fixed `ToolbarSpacer` (one `ToolbarItem`, identifier `toolbar-search`). The button, File ▸ **Find** (`⌘F`, after Eject, as in Finder) and the overflow menu's **Search** expand it into a `200 pt` inline field with a magnifying glass, a **Search** placeholder and a clear button; the field takes keyboard focus. The expansion is an opacity/scale transition (`snappy`, 0.22 s) and is instantaneous with Reduce Motion.

- Typing searches after a `250 ms` pause; Return searches at once. Each keystroke cancels the pending search; a new query or scope stops the running one.
- The first query opens a virtual results location titled **Searching “query”** (magnifying-glass breadcrumb) and records one history entry, so Back returns to where the search began. Refining the query or scope replaces the results without adding history.
- A scope bar above the results, **Search: This Mac | “Folder”**, chooses the scope (native segmented picker, folder name in the app language's quotation marks). Current Folder is the default when the search starts in a folder or archive folder (deviation from Finder, whose default is This Mac: under the App Sandbox This Mac only covers authorized folders, and inside an archive the archive is the meaningful scope). Recents, tags and Computer only offer This Mac. The bar shows a small progress indicator while results arrive and notes when only the first 1,000 results are listed.
- Results use all four view modes, sorting, selection, preview, context menus and Open of the Recents virtual listing. With one result selected, the path bar shows the folders that contain it. Opening a folder or archive result leaves the search: the path becomes the item's real location, the field collapses and clears, and Back returns to the results with their text in the field. In Columns, a folder result's contents open beside the results column, which stays.
- Escape clears the text, returns to where the search began and collapses the field. Clearing the text returns there, with that place's listing, but keeps the field open while it has focus; clicking away from an empty field collapses it. Navigating elsewhere (sidebar, Go menu) collapses and clears it.
- While the field has focus, Return, `⌘⌫` and `⌥⌘⌫` edit text instead of renaming or deleting items, and content focus is not restored over it when loading finishes.
- Keyboard focus (2026-11-01, D-61): `⌘F`, the button and the overflow **Search** put the insertion point in the field, so typing goes straight into it; `⌘F` while the field has focus keeps it there. Escape gives the keyboard focus back to the browser content (where it was before the field took it), so the arrow keys move the selection again. The field is an AppKit text field (`ToolbarSearchTextField`) because SwiftUI's focus system does not reach toolbar items (see §5).
- No results: the native `ContentUnavailableView.search` for the query.
- Narrow windows: from `678 pt` the search button stays in the toolbar in every stage; below `678 pt` it moves into the double-chevron menu as **Search** (with the `⌘F` hint, after the View submenu), and the field appears in the toolbar only while a search is in use.
- The open field always keeps its 200 pt and stays in the toolbar at every supported width (640 pt and up; D-66, 2026-11-01). While it is open the stage is chosen as if the window were 150 pt narrower, so the view selector, archive action and other controls move into the double-chevron menu before `NSToolbar` would move the field into its own overflow menu, where it cannot be typed into: expanded from 1,050 pt, compact with the archive action from 990 pt, compact with the actions menu from 828 pt, and the smallest stage below. In the smallest stage the title leaves the toolbar while the field is open (the field shows the query; the window keeps its title for the Window menu). The toolbar regains its normal stage when the field collapses. Limit: stages follow the window width, measured with the sidebar at its minimum width; a sidebar dragged much wider leaves less room.

## 5. Lessons on toolbar in SwiftUI

These restrictions must be considered before attempting to correct the toolbar:

- The `NSToolbar` can send a `ToolbarItem` to the overflow without first proposing a smaller width to the content. Therefore, `ViewThatFits` inside the toolbar may never receive the opportunity to compact.
- A `Menu` placed directly into the toolbar can normalize the label to a single icon, discarding padding, HStacks and additional symbols.
- `.secondaryAction` does not mean “overflow only”. The macOS can promote these actions back to the toolbar when there is space.
- An adaptive `ControlGroup` inside a single `ToolbarItem` can conserve its compact appearance after exiting the overflow.
- For deterministic responsiveness, prefer explicit breakpoints based on window width and change the control hierarchy before overflow.
- For compact buttons with their own visual composition, use a `Button` SwiftUI common.
- Conditional presentations of toolbar use their own identifiers per stage; do not reuse the same `ToolbarItem` between different hierarchies, because AppKit can conserve the native capsule while temporarily discarding its SwiftUI content during resizing.
- For menus that need icons, marked states, sections or plan predictable content, a small bridge to `NSMenu` is acceptable.
- A SwiftUI `TextField` inside a `ToolbarItem` is hosted outside the window's SwiftUI focus system (measured on macOS 27, 2026-11-01): `@FocusState` requests are ignored, the focus value never reflects AppKit focus, and `onExitCommand` never fires. A toolbar text field that must take focus programmatically or handle Escape uses an AppKit field that takes the first responder itself and reports focus, text, Return and Escape (`ToolbarSearchTextField`, D-61). The window's own SwiftUI focus value does not see the field take focus either, so returning focus must restore the previous AppKit responder.
- Not use `.id(windowWidth)` to force reconstruction during each resizing pixel; this masks the problem and causes excessive layout work.

### Window tabs

- Use the native system of `NSWindow` tabs, sharing a `tabbingIdentifier` between common browser windows and keeping `tabbingMode = .automatic`.
- The View menu uses only the native Show Tab Bar/Hide Tab Bar command of macOS, with `Shift + Command + T`; do not add a second command to the same action.
- The tab bar belongs to the window frame, not to the SwiftUI content. Therefore, it crosses the entire width of the window above the sidebar, content and preview; must not be cut by the inspector's internal split.
- The URL of the current directory must be assigned to `representedURL`, allowing AppKit to display the directory hierarchy by clicking on the title of the Command window.
- Local reference: [NSWindow](../SwiftUI/contexts/appkit-nswindow.md).

## 6. Pathbar on footer

Breadcrumb is in the bottom corner of the content, in a persistent bar with discrete top separator.

### Regras

- Show at most the last three levels of the hierarchy.
- If there are previous levels, start with `… ›`.
- Names of ancestral directories with more than 10 characters display the first seven characters plus `...`.
- The current directory keeps the full name as long as there is space.
- Each component is clickable and navigates directly to that directory.
- When not even the reduced presentation fits, show only the current directory as a menu.
- The compact menu must list the full path and allow you to navigate to any ancestor.
- Use real directory icons for each component.

## 7. Model of common interaction

The four views share the same fundamental rules:

- simple click selects;
- double click opens;
- secondary click selects the item and opens the context menu;
- clicking on an empty area undoes the entire selection;
- the clickable area shall cover the entire cell or line, using `contentShape` when necessary;
- internal buttons, such as disclosure arrows, perform their action without depending on the click on text or icon;
- changing the display type must not leave the focus stuck in the toolbar;
- the current selection must remain consistent when exchanging visualization whenever the item is still valid.
- When hidden files are visible, mitigate icon, name and metadata for `55%` opacity in the four views. For a selected occult, use `72%` to preserve legibility; the selection background remains with full opacity.
- `Return` starts inline renaming when there is exactly one local item selected; `Return` confirms and `Escape` cancels while field is active.
- A folder created by `Shift + Command + N` is selected and immediately enters the same inline renaming mode.
- `Command + Z` uses the `UndoManager` of the active window to undo the last completed file operation. Create folder, rename, copy, move, create aliases, duplicate and move to Trash record its inverse only after success; navigation and selection do not enter this history.
- Browser items do not use `Command + X`: `Command + C` is the only action that puts them on the Clipboard, `Command + V` always copies them and `Option + Command + V` moves them.
- `Command + C` publishes the original `NSURL` directly in `NSPasteboard`, using `clearContents()` and `writeObjects(_:)`, not representations materialized by `NSItemProvider`. Thus, `Option + Command + V` delivers to `FileManager.moveItem` the actual origin, moves the items to the destination and removes them from the previous location.
- In the Edit menu, Move Items Here is the native Paste alternative using `modifierKeyAlternate(.option)`. The drive validates Clipboard URLs when running and calls the `.move` file service operation.
- The source of drag from local files announces support for copying, moving and aliases inside and outside the application. During drag, `Option` copy force, `Command` movement force and `Option + Command` creates aliases; the operation is resolved from a reference state updated by SwiftUI and shared with `DropDelegate` throughout the session.
- Drop an item in the folder itself without modifier does not duplicate the item, even when URLs use symlinks or different directory marking. The drag payload must store the original location. Option continues requesting copy; the pin drop adds only one reference.
- Folders in the four views and folder destinations in the sidebar accept drops and remain highlighted while the cursor is on the target valid. In the content views, the highlight uses the semantic color of accent of the system, with translucent filling and contour, and disappears in `dropExited` or before running the drop. In the four content views, while a folder is target, its icon transitions by `0,18 s` to the native open folder icon and returns to the original icon on exit. The sidebar is an exception: it maintains its symbol and uses the solid feedback described in the Sidebar section. In the sidebar, the content of the destination maintains internal padding of `4 pt` horizontally and `8 pt` vertically, with neutral native vertical inserts to preserve height and align drop zones.
- “Add to Archive...” appears in the contextual actions of local items and opens a panel to choose archive. A archive ZIP or 7z visible and internal folders of the archive root accept drops with destination highlighting; in this flow of addition of local items, the operation is always copying. Before modifying the archive chosen or target drop, a dialog identifies the destination and quantity of items and offers Add or Cancel. Add must perform the request confirmed even when closing the dialog clears the presentation state before the asynchronous task; Cancel/dispensing does not change archive. After success within an open archive, save the current surviving folder and the previous breadcrumb to archive. Renew the Back/Next history without jumping levels or leaving archive prematurely; repopulate all ancestral columns and their selections with the addresses of the new session. In List, reopen the archive that was expanded inline, restore its expanded directories by internal path and open the ancestors of the destination; select the new items to show the result without requiring manual expansion. Preserve the trees and sessions of the others archives.
- **Internal items out:** without modifier, extract by copying and display native copy indicator; Option extracts and removes from archive, using `.move` without the indicator. Ignore automatic translation of AppKit modifiers in virtual origin and apply policy explicitly. Internal destinations refer to current modifiers in update/drop; Local files keep Option = copy.
- The virtual source starts the session in the `mouseDragged` dispatch, keeping clicks and menus SwiftUI. The internal token is given immediately on the pasteboard; only the content is a promise. Each promise can be fulfilled before the final callback of the source and before the receiver requests the next file. The removal depends on all successful publications and the final operation `.move`; cancellation preserves archive.
- File promises write in the provided URL without recreating the internal ancestors. All exports shall be terminated before removal; failure, cancellation or sustained conflict preserves origins. Written only in ZIP/7z single volume root; nested read/content formats allow copying. Renew the session/tree changed, keeping trees from others archives.
- “Remove from Archive...” in the contextual/overflow matrix, File menu and `⌘Delete` for compatible internal selection uses permanent removal confirmation, without Trash/Undo. Cancel does not change archive; folders include descendants and remove the last item keeps a archive empty navigable.
- `performDrop(info:)` starts loading all `NSItemProvider` before returning. The conclusions may arrive later and then trigger the asynchronous transfer, but the actual loading call must not be postponed to a `Task`, because the system restricts access to payload to the initial drop scope.
- Local reference: [modifierKeyAlternate(_:_:)](../SwiftUI/contexts/swiftui-modifier-key-alternate.md).

### Multiple selection

- Common click replaces selection.
- `Command` + click add or remove an item individually.
- `Shift` + click selects the interval between anchor and new item.
- `Shift` + arrows expands the selection by keyboard.
- The application keeps separately:
  - active item;
  - set of selected items;
  - anchor of the selection by interval.

### Selection color

- Use `NSColor.selectedContentBackgroundColor` as a reference.
- Do not fix an overly saturated custom blue.
- The selection must respect the theme and highlight color of the user.
- In the icon view, follow Finder: discreet highlight on the icon and blue concentrated on the label, avoiding a large blue block in the whole cell.
- In column view, the selection of the active column uses the selection color; the hierarchy opened in previous columns uses discrete gray.

## 8. Icon preview

- Show content thumbnails by default for files that have a preview; expose `Show previews in icon view` in Settings, persist either choice and apply it immediately to open windows. This preference is independent of inspector visibility and only changes Icons cells.
- Keep the current file's thumbnail visible during zoom while a new raster loads, clear content on item revision, and discard obsolete results. Preserve the name as the accessible label and announce selection without duplicating decorative image labels. Capture mouse-down modifiers before the single/double-click delay; Command/Shift release must not change the intended selection in any mode.
- Fit content into the existing icon area without cropping, preserve selection/hidden-file appearance and the complete cell hitbox, and keep the native icon visible while loading or when no representation is available. Folders and archives retain their established icons.
- Load asynchronously for visible cells; bound raster dimensions, concurrency and cache. Cancel obsolete work on navigation, mode changes, zoom and preference changes without presenting background preview errors as modal dialogs. Preserve focus, selection, scrolling and cell geometry when a thumbnail arrives.
- Use bounded image decoding, the first PDF page, the 1 KiB text preview, static HTML with document scripts disabled, and native Quick Look content representations for other formats. Internal files use the existing preview session and automatic limit; unknown-size/oversized items retain their icon and explicit inspector preview action. Enabled grid thumbnails remain independent when the inspector is hidden.
- Video files (types conforming to `public.movie`) show a decorative play badge centered on their content thumbnail so they read as playable media: a white `play.fill` glyph in a translucent dark circle with a thin white ring, about 36% of the thumbnail's shorter side (16–56 pt), darker under Increase Contrast. It appears only over a loaded content thumbnail — never over the native fallback icon — in Icons cells and the Gallery/inspector multiple-selection stack. It is not hit-testable and is hidden from accessibility; the name remains the label. Audio files, animated images, folders and archives do not show it.

- Usar `LazyVGrid` adaptativa.
- Base cell: `110 pt`.
- Base spacing: `24 pt`.
- Padding externo: `16 pt`.
- Base icon: `64 pt`, within a visual area of `84 × 72 pt`.
- Name up to two lines, centralized.
- The whole cell is the hitbox.
- Keyboard navigation follows the actual number of visible columns.
- When selecting by keyboard, scroll automatically to keep the item visible.

## 9. List View

### Structure

Columns initially displayed:

- Nome;
- date of modification;
- Size;
- Tipo.

Secondary click on any header opens Finder column options. Nome fica fixo; Date of Creation, Last Opening, Adding Date, Version, Comments and Tags can be activated. Modified by and Shared by are unavailable without collaboration data. Dragging the other headers changes the order by directory. Settings controls global visibility and order: each column has a switch, and the visible columns after Name are reordered by dragging the `line.3.horizontal` handle on the leading edge of their rows, with an open-hand pointer that closes while dragging: the row moves live, one place for each row the pointer travels, and releasing only ends the gesture (user request, 2026-10-27); Name and hidden columns keep an empty space of the same width so all titles stay aligned. Name stays first and cannot be moved; hidden columns follow the visible ones. Moving one place left or right remains available as accessibility actions. The local menu ends with a horizontal line and **Restore defaults**(**Restore default**), removing the folder replacement. The initial pattern of four columns is preserved. Tag circles measure 8 pt at 100% and are to the right of the name regardless of the Tag column.

Headers are clickable:

- first click orders upward;
- new click on the same field reverses the direction;
- the field active shows chevron up or down.

### Linhas

| Metric | Valor base |
| --- | ---: |
| Line height | `24 pt` |
| Icon | `16 pt` |
| Horizontal Area Inset | `8 pt` |
| Internal Line Inset | `4 pt` |
| Area of disclosure arrow | `18 pt` |
| Corner radius | `7 pt` |
| Minimum width of column Name | `168 pt` |
| Minimum table width | `612 pt` |

- No use dividing lines between items.
- Toggle funds for easy reading: one transparent line and another with `Color.primary.opacity(0.06)`.
- The light and dark bands must be exactly the same height.
- The zebra must fill in the hitbox without vertical intervals.
- The name shall start at the same position regardless of the visual width of the symbol.
- Header and lines form a single horizontal surface and preserve exactly the same alignment during scrolling.
- The header keeps a visible bottom edge separating it from the vertical files and splitters between your cells. All titles use internal inset of `6 pt` in relation to dividers. In Change Date, Size and Type, the values use the same insert and remain aligned to the respective titles; the content of the first column lines maintains its original alignment. The splitters do not change the widths of the columns or restrict the clickable area used for sorting.
- The table must never reduce the Name column below `168 pt` to try to fit in the window. Below the minimum width of `612 pt` on a scale of 100%, it conserves the widths of the columns and starts rolling horizontally.
- Without preview, the surface of List occupies the entire main area and the excess content continues to the right, accessible by scrolling horizontal.
- With preview, the useful width of the table is the width of the main area minus the adjustable width of the panel to the right (default `300 pt`). As long as this useful width is smaller than the minimum `612 pt`, the table preserves its columns, overflows behind the translucent panel and the scrolling area includes a final clearance equal to the preview width.
- As soon as the minimum table covers whole next to the preview, no column remains hidden. The Name column only begins to grow beyond `168 pt` using the space that remains after accommodating all the other columns and the panel.
- As long as the table requires scrolling horizontal, the alternate and selection backgrounds of the lines are left without side margin and without rounded corners, so that the visible edge does not appear different from the covered edge. Textual content maintains the same alignment with header. When the table fits back whole, they return the `8 pt` margin and the `7 pt` radius corner.
- Minimum table width, column widths, and preview clearance follow the visual scale of the window.

### Hierarquia

- Folders display chevron on the right when collected and down when expanded.
- Click directly on chevron expands or collects.
- `Option` + click the chevron alternates the entire hierarchy: expand recursively when the root item is collected and, when it is already expanded, collects the root item and all expanded descendants.
- Children use indentation of `20 pt` per level.
- Expand must not open the folder as current directory.
- Create, copy, move, and alias commands use the directory containing the active line as a destination. A line at the root level belongs to the current directory; a visible child line belongs to the expanded folder immediately above it. The selected folder never becomes the destination just because it is selected.
- Expanded folders observe changes in their own directory and update their children without requiring to collect, navigate to another location or reopen the folder.
- When the active item ceases to exist during an update, the cursor occupies the same position in the flattened order, thus selecting the next item; if there is no item in this position, select the last remaining item.
- With many items, sorting, flattening of the hierarchy and querying icons must be reused as long as their entries do not change. Selection and layout updates cannot repeat `O(n log n)` orders or new queries to `NSWorkspace` for each visible line.

## 10. Column view

- Each column has a base width of `260 pt`.
- The first column begins at the left edge of the content area and retains the base width; the leftover to the right belongs to the space available for a preview that will be loaded.
- Lines use the same metrics as the list view.
- Columns have discrete vertical separators.
- Selecting a folder creates the next column.
- During loading the next column, preserve the lines/selection of the source column and display only data belonging to the destination location. Without own data loaded, the new column remains without rows; never use the previous global list as fallback or duplicate it by a frame. The rule applies to real folders, archives and branch alternation.
- Selecting an item in a previous column eliminates all later columns that are no longer part of the path.
- The item selected in the active column remains blue even after a folder opens the next column; the loading of children cannot clean this selection or lower it to gray.
- Selections preserved in inactive columns receive gray highlight.
- When leaving Columns to Icons, List or Gallery, if the active item has opened a child column, the new view returns to the location of the active column and keeps this item selected. The change does not enter the item or create an entry in the history.
- When adding a column or preview beyond the visible width, scroll horizontally to the end.
- Before expanding a folder/archive in that branch, each loaded preview uses the free width to the right of the visible columns, respecting the minimum of 240 pt. A manual splitter change is only valid for the current preview.
- When expanding a folder/archive, fully display the new column on the right. It fills the remaining space, respecting at least the base width and 240 pt when the preview is visible. While the new column loads, its placeholder takes that terminal width and the column before it already has the base width, so the columns never grow wider than they will be once the new column shows (D-69, 2026-11-01). While the view is aligned to the right, the file preview in the previous column replaces this column in the same position and width.
- If the user scrolls horizontally to the left, save the width of the current preview even when part of it is outside the window. When selecting another file, recalculate the width of the new preview by the left to the right of the visible column and preserve the position of scrolling to the left; when opening a folder/archive, re-show the terminal column whole and align to the right.
- When returning to a previous column with the keyboard, the folder that originated the next column must be selected.
- Selecting a file creates a preview panel, not an empty directory column.

### Column preview

- Initial width before branch expansion, or after scrolling manual to the left: space available to the right of the open columns at the time of loading, with a minimum of `240 pt` and no maximum. After expansion, next previews at that level occupy the range of the terminal column while navigation remains aligned to the right. The splitter allows manual adjustment only of the current preview.
- Display file preview, name, type, size, dates and tags.
- For multiple items, display aggregated summary.
- Use Quick Look for real content when available.
- Warnings of internal Quick Look extensions that do not prevent preview must not be confused with application errors.

## 11. Gallery view

- Main area dedicated to preview.
- Horizontal range of items in the footer, with base height `96 pt`.
- Each thumbnail occupies approximately `96 × 72 pt`.
- The selected thumbnail gets discrete highlight.
- Clicking on the empty space of the main area or the bottom range undoes the selection.
- When there is no selection, leave the main area empty; do not show “empty folder”.
- Metadata is in an inspector on the right, with an initial width of `300 pt`, adjustable by the splitter with the mouse and shared with the previews of Icons and List.
- The inspector must exist for both simple and multiple selection.

## 12. Preview and multiple selection

- Preview visibility is independently persisted for Icons, List, Columns and Gallery. By changing mode or reopening the application, restore the last state used in that mode without overwriting the others.

### Simple Selection

- Folder: use real system icon in large size.
- File: use Quick Look when possible.
- For `.html` and `.htm`, render the local document in the preview with the layout, CSS and static features related to the file, as in Finder; the selection exchange discards the previous page. Static local content appears without waiting for remote features. Images, CSS and remote sources referenced by the file can be requested, as in Finder; do not execute JavaScript of document.
- Display name, type, size, dates and tags.

### Multiple selection

- Show up to five icons in hero.
- Base icon size: `200 pt`.
- Create an informal stack with small rotations and offsets.
- Sort the stack by selection's recency: the last selected item always appears at the top.
- The effect must remember loose papers, no extreme angles.
- Use discrete shadow to separate layers.
- Show amount of items, composition between documents and folders, total size, date range and aggregate tags.
- In the compact inspector, use at most three small icons stacked.

## 13. Keyboard navigation

### Global commands

- `Command + ↑`: return to parent directory.
- `Command + ↓`: open the selected item.
- `Command + +` or `Command + =`: increase scale.
- `Command + -`: diminuir escala.
- `Command + 0`: restore scale to 100%.

The current scale ranges from 70% to 160%, in steps of 10%.

### Icons

- Left/right: previous or next item on the line.
- Up/down: same visual column on the previous line or next.
- The calculation shall be use the actual amount of columns in the grid.

### List

- Up/down: move between visible lines.
- Right: expand the selected folder.
- Left: collect expanded folder; if already collected, select the visible parent. At the root level, there's no action.

### Columns

- Up/down: move between active column items.
- Left/right: move between columns.
- Right on folder: open next column.
- Left: return by keeping selected the folder that originated the next column.

### Gallery

- Left/right run the item range.
- The selected thumbnail must scroll to the visible area.

## 14. Icons and real data

- Use `NSWorkspace.shared.icon(forFile:)` to get the same system icons.
- Do not paint folders and documents with an arbitrary blue when there is real icon available.
- Directories within archives preserve the native folder and receive the approved **v6 stamp**, with circular cavity and internal volume of the press/Z. The belt and the entire circle line are continuous over the cylinder, which reaches the opening without overtaking it. The shape, light and shadow use the approved reference, by neutral masks that modulate the folder material; do not copy the blue background or replace the folder with a full image. The current lighting is fixed; dynamic height/light map was a previous proposal, not the technique implemented.
- Up to and including 32 pt, centralize the stamp on the face; above that, use the right lower face. Adjust by size after zoom: 48% diameter in compact, 38% up to 48 pt, 34% below 128 pt and 30% in large previews, with higher approved positioning. A single resource feeds all scales.
- Common local folders reuse the refined native composition of internal folders by removing only the compression stamp. Keep the four states (open/closed, empty/with content), material, edge on paper and approved perspective; use the composition shared in the four modes, previews and Information. In List, expansion opens line and preview; Recollection closes. Other modes do not inherit previous expansion. Preserve the open transition in the local drop and the detection of any direct child (including hidden and subfolders). Files and packages keep their system-specific icons.
- Internal folders containing files use a **closed** folder, with a wide strip of paper and rounded corners behind the native face, following the user's reference. The paper must be behind the entire rounded upper edge of the face: restore the full cut of the native face above the paper without interrupting it with horizontal cut below the edge. The approved stamp remains on the face. Detect files by the actual archive metadata, including descendants, hidden and zero bytes; do not infer by aggregate size. Empty folders or only empty subfolders keep the version paperless. The old open version of study was rejected and removed from the composer; the rule below defines the new approved open folder. Apply the same state at List, Columns, Icons, Gallery and previews. History, references and [plan](../Design/ArchiveFolderStamp/DEBOSSING-PLAN.md) preserved in `../Design/ArchiveFolderStamp`; v6 was authorized and integrated.
- **Approved and integrated open folder:** in List, the expansion of an internal directory changes its icon and the hero of the preview for the open version of the same native folder with approved stamp; apply also to multiple selection heroes. Collect restores closed folder, with paper only when there are files. Selection does not equal expansion. The composition must preserve color, gradient and rounded corners of the closed folder, tilt face and stamp together and have contact shadow; the area behind the paper shall show only the rear panel, without rounded leftovers of the closed face on both sides and without horizontal lines/bands next to the paper; use continuous gradient of the rear material to that region, sampled only above the closed face; the empty version must have continuous panel, without silhouette/gradient residual paper and without step on the left edge; remove the grey outline of the paper, without cutting/empty; maintain the width of the original base and extend only the upper edge of the face that advances to the observer; not use the old feature `ofld`, whose texture and base were rejected by the user. The other three modes keep the state closed. The new proposal v7 replaces only the old open folder idea; the previous open study remains rejected. Drag and drop of archives internal items is still pending, without new drag behavior in this integration.

- Use `URLResourceValues` for size, dates and tags.
- Separate file system reading, navigation status and visual composition.
- The views use actual file service items, Recents or archives engine. Development Fixtures do not define the content shown to the user.

## 15. Location

### Shortcut Reference

- The Help menu contains `Keyboard Shortcuts…` (`Command + /`), which opens a unique auxiliary window of the application.
- The window is a two-column split view (ZF-59), 780 × 560 pt by default: a 206 pt sidebar with the search field, an **All Shortcuts** row, a separator and one row per category (a 20 pt colour tile with a white SF Symbol, the title, and the number of shortcuts in tertiary text), and a detail column whose title is the selected category. All Shortcuts is selected on open.
- The detail uses 20 pt side margins. All Shortcuts shows every category under a small secondary header above an inset grouped container; one category shows only its container, without the header. Rows are at least 32 pt tall with 10 pt padding; the action is leading and truncates with an ellipsis, and hairline separators are inset to the text.
- Search lives in the sidebar and filters actions, categories and representations of shortcuts inside the selected category (or all), without concealing the grouping of results; no match shows the system “No Results” view. Sidebar counts stay the totals.
- Each key is its own small cap (system font, not monospaced) using the native glyphs of macOS (`⌃`, `⌥`, `⇧`, `⌘`); a word key (Return, Space) is one wider cap. When a single action accepts more than one equivalent combination, such as Quick Look with `Space` or `Command + Y`, it occupies a single line and the combinations are separated by a tertiary “or”. Pointer shortcuts show the modifier caps followed by the gesture (drag, double-click, click disclosure, click window title) as secondary text, never inside a cap.
- The window follows light and dark appearance, text size and every app language without clipping (long sidebar titles use a second line; long actions truncate with the full text in the help tag), and VoiceOver reads each shortcut in the app language, for example “Shift Command N”. The reference must remain synchronized with the shortcuts actually recorded in the application menus and handlers.

Supported languages: the 21 localizations in [LOCALIZATION.md](LOCALIZATION.md) are implemented in the catalog. Settings lists stable language autonyms so users can recover from an unfamiliar interface. System Default remains first; existing saved choices remain compatible. Chinese regional matching preserves the explicit or inferred script. Full interface acceptance and evidence remain separate in REGRESSION-COVERAGE.

Language rules:

- The default preference is the system language.
- Walk `Locale.preferredLanguages` until you find a supported language.
- Map any variant of Portuguese to `pt-BR` while it is the only Portuguese translation.
- Map English to `en`.
- If no language can be mapped, use English.
- Allow manual choice in Settings.
- Continue the choice at `UserDefaults` by means of `FileBrowserPreferences`.
- Inject the selected `Locale` into the SwiftUI environment.
- Keep texts in String Catalog (`Localizable.xcstrings`).
- Dates, sizes and plurals must respect the active locale.

## 16. Accessibility and focus

- Every button just with icon needs accessibility label and help.
- Dislosure arrows must announce expand or collect.
- Toolbar controls must not permanently capture the focus of the content.
- After exchanging preview or performing a toolbar action, return focus to the file browser.
- During fast navigation, coalesce focus restoration, rolling and preview loadings; before publishing a pending preview, confirm that the item is still the primary selection.
- Use semantic system colors for light, dark, enhanced contrast and highlight color themes.
- Do not depend only on color to indicate direction of sorting, expansion or type of control.
- Hitboxes must be bigger than visual drawing whenever necessary.

## 17. Share feedback

- Completed actions can use a temporary warning at the top of the content.
- The feedback must be short, animated and disappear automatically.
- Context and toolbar menus must call the same action model.
- A disabled action must remain visible when it helps the user understand its availability.
- The archive commands perform real operations and preserve the same visual hierarchy in the menus and toolbar.
- *(Historical: the Archive Navigation section and its two sliders were removed with nested-archive navigation in D-73, 2026-11-02; the slider behavior below is kept for the preview limits of a later ZF-55 stage and is exercised through a UI test fixture.)* In Settings, Archive Navigation sets both limits with native sliders (2026-10-29). The title row shows the current value at its trailing end; the slider spans the row so its steps stay at least about 2 pt apart; a short secondary label sits centred under each tick mark as drawn (on macOS 26 the marks and knob centre are inset by half the knob, unlike `rectOfTickMark(at:)`) and is kept inside the slider at both ends; the size slider also shows unlabelled marks, identical to the native ones, at the midpoint round values; the explanatory caption follows. Depth stops on each whole value. The root size slider is logarithmic with a tick mark per doubling, fine steps, and held round values (each doubling and its midpoint) that never hide the adjacent steps; dragging onto a round value gives haptic alignment feedback. While dragging, the knob follows the pointer's travel since the press (AppKit's proposal, measured on macOS 27): it is drawn on a round value inside its hold, and a slow drag of many small movements leaves the hold and continues with the very next step. At the Settings width (510 pt) a doubling is about 66 pt and the first step after a doubling about 2.9 pt (D-62, 2026-11-01). Arrows move one step, Option+arrow to the next round value, Home/End to the ends; VoiceOver reads the formatted value. Values and labels use the selected language's number format.
- In Settings ▸ Compression (ZF-58: a list of profiles, each opening its own page; see “Settings window in two columns”), the default profile is chosen and profiles are created, edited, duplicated and deleted. `Compress Custom…` allows you to choose a profile and adjust options only for the current operation; creation and saving of profiles are exclusively in Settings. The compaction sheet uses Save As, Tags and Where in separate lines with wide controls; the profile selector extends to the right edge of the grid. Where opens a folder selector native. Height follows visible content without field profile name or actions to save profile. The [alternativa A](../Design/CompressionModal/ALTERNATIVES.md) defines a compact grid of two columns, with `Protect with password` on the left just below `Solid archive`; by marking the protection, the secure password and confirmation fields appear below the check in the left column, and the panel grows to keep them fully visible. When unchecking, the panel shrinks; `Encrypt file names` remains in the right column. Display only controls accepted by the selected format and method: level, method, dictionary, fast bytes, solid, threads, password, encrypted names in 7z and type of encryption ZIP. Passwords are confirmed in field secure and remain only in memory in this session; a profile that requires password requests it again when there is no memory value. Quick compression uses the default profile, including the four views and Recents.
- After evaluating the grid, the user decided to keep Save As, Tags and Where on their own lines and expand the three controls. The own sheet replaces the narrow top of `NSSavePanel`; [the previous studies](../Design/CompressionModal/ALTERNATIVES.md#appraisal-refinement) remain as a history of exploration. The destination continues to be chosen by the native macOS selector.
- In the implemented sheet, header, upper area, grid of options and footer share the same side margin of 20 pt. `Tags` and `Where` are the same width; `Save As` follows this width and the right limits of these controls, the profile selector, the right column and Save are aligned. The options selectors have labels above and uniform width controls per column. The [Apple sources want](../Design/CompressionModal/ALTERNATIVES.md#direction-after-consultation-of-apple-guidelines) confirmed that superior labels are compatible with the principles of alignment, association and adaptation, although the `Form` macOS standard has side labels. Preserve native controls, focus order, VoiceOver, location, spacing and vertical expansion of the password. The own sheet maintains the folder choice by `NSOpenPanel` and saves tags in archive created; check these flows in archive real, in addition to visual review in supported languages.

## 18. Existing organisation

`FileBrowserState` coordinates navigation, selection, operations and window preview; `FileSystemService` and the other services isolate access to files and archives. `ContentView` composes window and toolbar. Sidebar, preview and each of the four modes have their own views, while shared components and metrics reside in common files. All views project the same state by window; do not duplicate selection or navigation when evolving one of them. The source for code points and evidence limits is [`CURRENT-STATE.md`](CURRENT-STATE.md).

## 19. Regression checklist

Before considering a completed visual change, check:

### Window and toolbar

- slowly resize from maximum width to minimum and return;
- confirm the order of the two breakpoints of the toolbar;
- confirm that no control returns with corrupted spacing;
- open all menus in full and compact presentation;
- check very long directory titles;
- test open sidebar, hide automatically and hide manually.

### Content

- test empty directory, few items and many items;
- test long names and varied extensions;
- test simple click, double, secondary and empty area;
- test simple selection, `Command`, `Shift` and keyboard selection;
- switch between the four views with active selection;
- navigate deeply and return to previous levels.

### Appearance and accessibility

- light and dark theme;
- distinguishing colour other than blue;
- Portuguese and English;
- zoom 70%, 100% and 160%;
- keyboard focus after interacting with toolbar;
- accessibility labels and controls tooltips by icon.

## 20. Criteria for new decisions

When a doubt of UI/UX arises:

1. observe the current behavior of Finder and equivalent native applications;
2. identify whether the behavior comes from SwiftUI, `NSToolbar`, AppKit or our layout;
3. prefer system semantic API when it produces desired behavior;
4. do not depend on automatic behavior that has already proved unstable during resize or overflow;
5. where necessary, create explicit and deterministic adaptation;
6. maintain the bridge AppKit small, isolated and replaceable;
7. test the complete sequence of states, not just the final static appearance;
8. record in this document the decision and the reason.

### Tag Editing — 2026-10-03

The context menu and icon between Share and ellipsis open the same localized editing sheet. Show integral/partial status of tags in multiple selection, existing catalog and creation by name/color, with Cancel and Apply. Preserve unedited tags for each item. The stack of circles advances from right to left and the first color tag on the left (last color in metadata) defines the color of the folder in the four modes, previews and drop; packages and files keep their icons. Check the new width of group in the toolbar transitions before declaring full visual validation.

#### Menu refinement and folder material — 2026-10-03

The context tag and ellipsis/overflow section has two lines: seven first names of the catalog in circles (without showing the others), followed by Edit Tags with `tag` symbol. Check indicates application for all targets; hover shows x on applied and + on not applied. Partial selection uses dash and hover +, applying to everyone when clicking. Quick click records immediately; Edit Tags keeps opening the sheet. Hover belongs to the whole row, not to each circle, so a fast sweep never leaves a stale + or x. While a circle is hovered, the second line replaces Edit Tags with the tag name, as Finder does; circles carry no tooltip, which would cover that line. The name persists over the gaps between circles and Edit Tags returns when leaving the row. The custom line AppKit maintains status and accessibility names; the complete editor remains available as a conventional keyboard item.

Tag circles in List preserve the order of visually inverted metadata, with the circle on the left covering part of the neighbor on the right. The folder adopts the first color of this stack, ignoring colorless tags. Recollection must replace only the hue of the blue material, preserve luminosity, shadows, white paper and neutral details, and render native representations in preview resolution before pixel change. Not apply a uniform layer on the compound folder. System icons continue to be obtained by public APIs without private Finder resources.

### Output reception of archive — refinement of 2026-10-04

Release in the real folder must publish the file in this folder with its name, not just accept gesture or select the item. Native receivers in folders/free area/sidebar receive the virtual identity directly and provide the destination URL to the extraction. Do not wait for the conversion of the promise to URL before choosing this destination. Hit testing native is limited to gesture active, preserving clicks after drop while export ends. The session per event begins during mouseDragged in the common host to frames of all items, in macOS 26/27. The source and its representation are shared with local items. Delivery by gesture real in Zforge folders in all four modes is executed; external/visual coverage detailed in the regression matrix.

### ZF-30 — interaction contract implemented in 2026-10-04

The [plan current](ARCHIVE-DRAG-DROP-PLAN.md) magnifies the ZF-30 for reorganization within the archive itself. The user confirmed the badge on exit, but reported no effect operations and visual divergence. The rules below were implemented with motor/state tests and gestures real of UI; the limits of visual and external check remain explicit in REGRESSSION-COVERAGE.

- The entire drag presentation replicates the equivalent local item in the current mode: line in List, representation/form formation in the other three dimensions, capture point, start/conclusion/cancellation, feedback from target and multiple selection. Eliminate the large icon by replacing the line and jump from the top.
- Internal item out: without option copy/extrait with badge; Option moves/extracts and removes origin without badge. Internal item for root or folder of own archive: without Option moves; Option copies with badge. Destination and modifier update the indicator during gesture and are captured on release.
- Before movements that modify archive, native warning identifies the original, items and destination and informs that the original compressed file will be modified. Return/Enter approves, Escape cancels, Tab/Shift+Tab and Space allow you to operate the mouseless controls. This covers Option + output and internal movement without Option. Cancellation prior to execution does not save to any destination. Internal copy keeps the change confirmation used when adding content.
- Internal copy/movement regulated their own archive in a validated way, deal with conflicts, prevent cycles and keep origin in copies. After success, maintain surviving hierarchy, reveal the inner destiny and preserve other trees. Transfer between different archives remains outside that decision.

### Navigation after mutation of archive — D-34, 2026-10-04

Addition, exclusion, exit by movement and internal reorganization share the restoration of navigation. Breadcrumbs, Back/Next and Columns must point to the same renewed session: preserve the history order and its surviving directories, discarding only removed paths or invalidated nested sessions. Revealing another directory is navigation and allows you to return to the displayed location before operation. If the directory displayed disappears, back to the nearest surviving ancestor without creating a duplicate stop. Reload items from each ancestor of columns, including the actual folder containing archive, and select the entry that opens the next level. Preserve the restoration of disclosures/selection of the result in List and the status of the others archives.

### Archives inside archives — D-73, ZF-55 stage 2, 2026-11-02

- An archive inside an archive looks and behaves like an ordinary file in the four modes (its file icon, no disclosure triangle, chevron or column). Double click and File ▸ Open show it in a **new window**; the window it came from keeps its location, selection and scroll.
- The new window's title and path bar read `outer archive › inner archive` as a single first component (`a › b › c` for deeper chains) and never show the temporary folder; the components below it are the inner archive's folders as usual.
- An inner window whose outer archive cannot be updated is read-only: write actions (Remove from Archive, Add to Archive, internal moves and copies, drops on its folders) are disabled, as for any read-only archive.
- Closing a modified inner window closes it immediately. Writing it back into the outer archive shows a small app-level utility panel, “Saving Inner Archive”, with the sentence “Writing “inner” back into “outer”…”, an indeterminate bar and Cancel (Escape). Questions use standard alerts: outer archive changed — Replace Anyway (default) / Save Inner Archive As… / Discard Changes; failure or cancellation — Try Again (default) / Save Inner Archive As…, explaining that the modified inner archive is kept; a missing outer password asks in a secure field. Save Inner Archive As… uses the standard save panel with the inner archive's name. Quitting waits behind the same panel.

### Settings window in two columns — ZF-58, 2026-11-02; polished by ZF-62, 2026-11-09

User request (2026-11-02): the single Settings form had grown too long; Settings follows System Settings with a sidebar of panes and the chosen pane beside it. The user approved the mockup with View Options (rather than Appearance, which on macOS names theme and accent colour), the Finder extension inside General, and profiles listed in Compression with their own page.

- **Window:** fixed 788 × 620 pt, not resizable; a 220 pt sidebar and a 568 pt detail column (the former form's width, so the size sliders keep the measured steps of D-62). Unified toolbar, the same as the browser window's: 52 pt high with the traffic lights centred in it and the pane's title in the toolbar title style (15 pt semibold, primary label colour) leading-aligned with the 20 pt content margin; a profile page shows the back button beside its title at the detail column's leading edge. The window has the toolbar through an empty toolbar item because SwiftUI makes it only for a window with an item (ZF-62; before it, a 32 pt title bar with the small grey 13 pt window title). No sidebar toggle; the sidebar cannot collapse.
- **Sidebar (ZF-62):** one flat list without group gaps, in the order General, View Options, Sidebar, Compression, Previews in Archives, Automation (the three ZF-58 groups were removed: the gaps meant nothing). Uniform 28 pt rows, 13 pt regular titles, a 20 pt rounded tile (corner radius 24 %) with the SF Symbol in white semibold at 56 % of the tile, 8 pt between tile and title, the standard selection. Tile colours are the macOS system colours, so they adapt to the appearance, with a faint top lightening (18 % toward white): gray `gear` (General), blue `eye.fill` (View Options), teal `sidebar.left` (Sidebar), orange `doc.zipper` (Compression), green `rectangle.and.text.magnifyingglass` (Previews in Archives), indigo `wand.and.sparkles` (Automation). Titles wrap to a second line instead of truncating (every language fits two lines in 140 pt); the row's help tag (and VoiceOver hint) is the pane's one-line description. No search field. Choosing a pane closes any open profile page; Settings reopens on the pane chosen last.
- **Detail spacing (ZF-62):** 20 pt side margins; 20 pt between groups; a group's header is 13 pt semibold, 8 pt above it; its explanation is an 11 pt secondary footer 6 pt below it, never its first row; rows are at least 36 pt with 12 pt of inner padding and a hairline between them; switches are small; the group is a 10 pt rounded rectangle in a faint fill with a hairline rim. Toggle and pop-up rows have the title at the leading edge and the control at the trailing edge. In List Columns every row keeps the 16 pt handle slot (empty for Name and hidden columns) so the titles align, and Name's switch is disabled.
- **No pane header:** a pane starts with its first section; the window title names it (user request, 2026-11-02: the 44 pt tile, title and sentence that opened each pane repeated the selected sidebar row). A section never repeats the pane's title.
- **General:** Language; Finder (explanation, extension status, Finder Extensions…). **View Options:** Default View, Show hidden files, Show previews in icon view; List Columns with its caption and draggable rows. **Sidebar:** the Locations/Shared toggles under their caption. **Previews in Archives** and **Automation:** their sections as before, without the repeated title.
- **Compression:** the Default compression profile picker; **Profiles** lists every profile as a navigation row without an icon (removed at the user's request, 2026-11-02; name; Default badge in the accent colour; secondary summary “format · level · method · Solid · Password” naming only what applies, the automatic method omitted); **Add Profile** under the list creates and opens “New Profile”. A profile page shows Profile name, the options the format accepts, the password and confirmation fields when protected (with the session-only note), then Duplicate Profile and Delete Profile (destructive, disabled for the last profile). Changes are saved as they are made, as in System Settings; Delete Profile confirms with “Delete “Name”?” — “Archives created with this profile are not affected.” — and Cancel keeps the profile.
- **Verify:** sidebar and toolbar only in a real run (the glass sidebar is drawn by the window server; offscreen snapshots cover the detail panes); every pane in light and dark, English plus a long language (German, Portuguese), VoiceOver reading of the rows and their hints, keyboard selection in the sidebar, and pane switching while a profile page is open.

### Previews in Archives and opening progress — D-73, ZF-55 stage 3, 2026-11-02

- Settings ▸ **Previews in Archives** follows the Settings section layout: each limit is a row with its title and current value at the trailing end, the logarithmic size slider spanning the row (labels under each doubling, unlabelled marks at the midpoints, held round values with haptics) and a secondary caption; **Preview solid archives** is a switch with the affected formats and the solid-block rule below in caption font; **Preview on removable drives** and **Preview on network volumes** are switches that reveal their own size-limit row, animated, when on. Values use decimal MB/GB as in Finder and the language's number format.
- An item over its limit keeps its icon and the manual load action; nothing changes for files outside archives.
- Opening an archive (and an explicit Quick Look of archive items) shows the usual glass overlay — indeterminate indicator, “Opening “name”…” (or “Loading…”), Cancel — only when it takes longer than 0.4 s, so quick openings never flash it. Cancel returns to where the window was, without an error.

## Automation setup — ZF-43, 2026-10-07

Settings contains an Automation pane (ZF-58; formerly a section) with a plain-language explanation of read/write scope, the empty state, an allowed-folder list, Remove for each grant, Allow Folder through the native directory picker, and Copy MCP Configuration with copied feedback. Paths truncate in the middle and remain available in tooltips; removal accessibility labels identify their folder. Picker cancellation preserves grants. English and Brazilian Portuguese settings flows have executed UI coverage; broader themes, VoiceOver/reduced motion and long allowed-folder lists remain pending in OR-20. Native system-action titles, descriptions and summaries use the String Catalog. Localized guidance explains saved custom shortcuts for Siri/Spotlight and the current onscreen-reference limit; Open Shortcuts uses native AppKit application lookup/opening. Automatic App Shortcuts phrases are not a native macOS feature. Existing four-mode browser UI and selection semantics are retained.


### Contextual automation authorization — 2026-10-07

A missing automation scope opens a native folder picker at that requested folder, with localized title, action and explanation that consent persists read/write access for future local agent and shortcut requests. Confirm only the requested physical folder; selecting a different/broader folder must not authorize the action. Shortcuts requests dynamic foreground continuation when needed; supported background requests remain silent. Cancel stops the invocation without archive output. All required scopes precede archive work. Queue/coalescing limits apply within each process; independent stdio clients may each present a picker. Settings remains available for advance setup and revocation. Actual UI/system evidence and remaining accessibility conditions are tracked in REGRESSION-COVERAGE.


### Automation permission list consolidation — 2026-10-07

After successful folder authorization, show the usable covering parent once and remove redundant descendants from the automation list. Adding an already covered child or equivalent physical alias produces no extra row. Preserve independent outside symlink targets and unavailable entries whose coverage cannot be established. Consolidation must not interrupt active operations. Removing the displayed parent blocks future access to covered descendants; former child permissions do not silently return. Settings and contextual permission share this policy.

### Archive entity opening — 2026-10-08

The macOS 27 Open Archive action exposes a localized archive picker backed by bounded on-demand authorized name queries and explicit path candidates. Discovery must not display a consent panel, silently authorize roots, recurse through folders or read archive contents. Actual opening uses the shared foreground exact-folder consent and existing URL-opening experience. Cancellation and revoked/missing targets must not open a stale selection. Native editor/selector/run and actual Siri routing are separate acceptance checks; the broader language, accessibility, display-size and resource matrix remains pending.


**Automation opening handoff, 2026-10-08:** foreground archive actions transfer their active folder scope through the live window request into initial browser loading. They do not relaunch the already foreground app or create an unrelated Recents window for each archive. Password prompting and incorrect-password retries retain the opening scope until loading completes, the prompt is dismissed, or its window closes. Saved window restoration never restores a live permission lease. Native acceptance and infrastructure limits remain separately recorded in REGRESSION-COVERAGE.

### Archive metadata discovery and context — 2026-10-11

Automation Settings explains that names of direct archives in allowed folders are shared with Spotlight and Siri, with conditional Siri availability and saved shortcuts for compression/extraction. Successful grant changes refresh an already-open list, including changes made through contextual permission or another local MCP process. Index failures show localized unavailable/retry feedback without implying that folder access was revoked.

Eligible archive cells associate their current bounds and selection with the same canonical entity used by Spotlight across Icons, List, Columns and Gallery. Preserve visible ordering, focus and the current mode's selection semantics; inactive Columns trail highlights are not selected entities. Directory aliases must retain the association. Unauthorized/unindexed targets, folders, ordinary files and archive members receive no archive association. Scope changes clear stale context during reconciliation. These invisible annotations do not change gestures or create a new selection model. Actual Siri consumption and the full native language, size, theme and accessibility matrix require separate evidence.


**Modern file-context representation, 2026-10-11:** on macOS 27, native archive discovery and onscreen annotations share the published `files.file` identity. Existing saved String-target actions continue to execute but are omitted from new action discovery; Open Archive presents the modern file target. Preserve exact-folder contextual authorization and the existing foreground opening handoff. macOS 26 retains its previous legacy archive representation. Annotation lookup uses precomputed associations, with no bookmark generation or filesystem work during layout. Actual Siri interpretation remains a separate native acceptance gate.

**Current onscreen association boundary, 2026-10-12:** the shared provider queries current active selection and the latest published association when the system requests context. It maps directory presentations using cached resource identity, with no filesystem/bookmark work during layout or annotation requests. Preserve existing browser accessibility traits and gestures; the experimental trait override is reverted. Columns trails remain visible and unselected when their location is inactive. The selected-annotation system acceptance gate is unresolved despite correct visible selection and provider state, and must not be described as fully verified.

**Siri archive search results, 2026-10-13:** on macOS 27, Siri's Search Archives action (`system.searchInApp`) opens one browser window for the search. When the request launches Zforge, the search replaces the untouched window opened at launch, so only one window appears; when Zforge already shows a window, the search opens beside it and never replaces it. Its title and single breadcrumb are the localized `Search: “term”` with the `magnifyingglass` symbol. The list reuses the Recents virtual listing in all four modes: direct, visible archives in allowed automation folders whose names contain the term, with the usual sorting, preview, context menus, drag and Open. Exactly one result is selected so its preview appears and it becomes the selected onscreen entity; several results start unselected. No results show a native unavailable-content view, **No Archives Found**, explaining that no archive directly inside the allowed folders contains the term; failures use the existing error presentation. Back/Forward restore the search; choosing Recents, a tag or a folder leaves it. Restored windows repeat the search under current grants and never restore a permission lease. A follow-up “Open it” in Siri opens the onscreen archive with the existing foreground handoff.
