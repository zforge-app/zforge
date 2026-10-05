# Zforge internal directory seal

Refinamento v2, 2026-10-03. Separate PNGs have transparent background. `folder-states-v2.png` compares common folder, with files and open with files in six sizes; `zforge-stamp-v2.png` is the stamp itself for review. The states with files/open are studies and do not change the identification of internal folder contents in the browser. The main icon of the app remains the existing Icon Composer file.

Reproducible rendering from the project root with macOS graphics services available:

```sh
swiftc -module-cache-path /private/tmp/zforge-stamp-module-cache Zforge/Views/ArchiveFolderIconComposer.swift Documentation/Design/ArchiveFolderStamp/Render.swift -o /private/tmp/zforge-stamp-v2
/private/tmp/zforge-stamp-v2 Documentation/Design/ArchiveFolderStamp
```

## Study v3 — form based on the original mono

The user asked to separate study from folder and embossesing and to approximate the stamp from the original icon in mono appearance. [Reference provided](reference-original-mono.png) and [novo study avulso](zforge-stamp-v3-original-mono.png). The new shape preserves cylinder with diagonal strips, narrow piston, wide cylindrical discs and thick Z, inside a circle. The study raster has more pronounced metallic relief; it was not applied to the vector composer or the app. Version v2 and folder files have been preserved.

The form v3 was approved by the user. The following treatment must simulate **debossing**, with depression, light and shadows inside the folder material. [Technical plan and criteria](DEBOSSING-PLAN.md); [physical reference](reference-debossing-paper.png). The composer implemented has not yet received this technique.

## Previa v4 — debossing in folder

[Long preview](folder-debossing-v4.png) generated with ImageGen from the v2 folder, approved v3 form and pressed paper reference. The first generation still had high parts; the refinement lowered Z and press components, with internal shadows and light on the lower edges. This is a visual raster proposal for review, not the output of the app composer or proof of implementation of the height map. Still no check in small sizes, states with files/open or real interface. The previous versions remain preserved.

## Refining v5 — preferred volume and cylinder up to circle

The user visually preferred the first volumetric composition in the folder (`folder-preferred-volume-reference.png`), although the v4 represented more literal debossing. The new direction preserves this volume, light and shadow, with the circular cavity integrated into the folder. [Study v5](folder-pressed-relief-v5.png): the upper cylinder with strips was extended to the upper inner edge of the circle, without empty space above and without exceeding the mark. This preference prevails over the strictly downgraded reading of all components of v4. Raster study not yet integrated; previous references and versions preserved.

## Refining v6 — Continuous circle on the press

The user corrected the superior encounter: the circle must cut the press and keep its entire line visible. [Study v6](folder-pressed-relief-v6.png) restores the continuous internal arc on the cylinder. The cylinder reaches the opening, but is cut into it, without covering the strip of the circle. Raster study for review, without integration; v5 preservada.

## Authorised integration — v6

The user approved the v6 and asked for implementation. Source production: `Zforge/Assets.xcassets/ArchiveFolderRelief.imageset/approved-relief.png`. `ArchiveFolderIconComposer.Relief` isolates the stamp and derives light/shadow neutral masks by comparing their luminosity to the intact gradient on the sides. This preserves the approved form and illumination on the material native, without painting the blue background or maintaining a PNG by size. The calculation occurs once and the composition is curtailed by track. Fixed reference lighting; There is no dynamic height/light map.

[Rendering of implementation](implemented-relief-states.png) checked in the six sizes and three states. To reproduce outside the bundle, pass the reference path as the renderer's second argument:

```sh
/private/tmp/zforge-stamp-implemented /private/tmp/ZforgeApprovedReliefPreview Zforge/Assets.xcassets/ArchiveFolderRelief.imageset/approved-relief.png
```

The previous studies and the main icon of the app have been preserved.

## File closed folder — implementation

The user rejected the open version of study. The composer now has only closed states: [with files](closed-folder-with-files-implemented.png) and [comparison with/without files in six sizes](closed-folders-implemented-states.png). The paper strip follows the closed folder reference, behind the native face, with the v6 stamp preserved. `Render.swift` was updated for these two states; the file `implemented-relief-states.png` and the previous comparison sheets remain historical records, including the rejected open version.

`archiveDirectoryContainsFiles` is provided by the engine listing for all views and previews; the classification includes any descending file, including hidden/zero bytes, but not empty subfolders alone. There is no extraction to determine the icon.

## New study folder opened in drag

Request 2026-10-03: create only the folder icon opened as target receiving during drag, with blue material and approved seal. The native reference shows the front face tilted forward and paper inside. This study is separated from the closed folder with already integrated files and the old rejected open proposal. Application and moment of use depend on later instruction from the user.

[Proposal v7](open-folder-drop-study-v7.png), generated with ImageGen integrated: single image with transparency, inclined front and enlarged at the top, visible documents, internal shadows and circular press/Z stamp on the lower right face. visually checked as study; without integration, changes in the composer, build or new tests.

Prompt specification: transform the approved closed folder to target open by drag receipt using the native reference; preserve blue/material, seal shape and continuous circle, tilt the front face subtly, show paper and shadow inside, apply coherent perspective to the seal, smooth gradients, transparent bottom, without text/UI or variants in the same image.

## Expanded folder integration

The v7 was approved for the internal directory line expanded in List and the respective preview hero (including multiple selection). Production uses `NSWorkspace` with OSType `ofld`, paper conditioning at `archiveDirectoryContainsFiles` and stamp v6 masks; does not use full v7 PNG. Cache distinguishes scale, files and expansion. The other modes keep folder closed. Drag and drop of internal items was not implemented and is included in OR-14/ZF-30.

## Correction of open folder material

The user rejected the implementation `ofld` by texture/color, base and inconsistent corners. The corrected version uses only the same closed native folder; cut its rounded face, apply the stamp and tilt the two together by bilinear resampling at 1024 px, with contact shadows. Do not use the PNG of study as an entire icon. The old render is preserved as `open-folder-ofld-historical.png`; [novo render](open-folder-implemented.png) and [comparison](folder-expanded-implemented-states.png).

Later refinement: the two leftovers of the closed face are removed next to the paper. The rear layer uses only the top native and an extension of the intact track of the rear panel. Previous export was preserved as `open-folder-before-side-cleanup.png`; the `open-folder-implemented.png` path contains the current export.

## Prospect with preserved base and non-continuous paper

User refinement: remove the lines next to the paper without cutting the rear panel. The ImageGen edition that leaked was not integrated. The composer removes the stroke from the paper in the open version and keeps the base at the width of the original folder; only the top of the face moves out. Previous export preserved in `open-folder-before-perspective-fix.png`; `open-folder-implemented.png` is the composer's current output.

## Lines on the rear panel

The user confirmed the perspective, but still pointed out lines in the blue next to the paper. The extension of a bitmap band was replaced by a continuous gradient rasterized with native colors, preserving alpha and rounded corner and excluding the external shade of the color sampling. `open-folder-before-rear-lines-fix.png` preserves the previous surrender; current export in `open-folder-implemented.png`.

## Closed folder: paper behind the edge

After approval of the refinement open, the user pointed out that the paper covered the top edge of the closed folder full. The horizontal cut below the border was replaced by the rounded cut of the full native face. The new export in `closed-folder-with-files-implemented.png` keeps the paper band behind the edge and the stamp. Previous yield preserved in `closed-folder-before-lip-fix.png`.

## Empty open folder — separate export

The user's request, [open version without paper](open-empty-folder-implemented.png) exported by the same composer (`isOpen: true`, `containsFiles: false`), preserving perspective, material, shadow and seal. This state already existed in the composer/cache and in the tests; at this stage was created only the separate export for review, without changing the behavior of the app. `Render.swift` starts exporting that additional file.

Empty open folder refinement: removed left step and residual rectangular gradient. The panel uses colors of the rear material above the closed face, continuous interpolation and smooth transition with the top native. Previous export preserved in `open-empty-folder-before-panel-fix.png`; `open-empty-folder-implemented.png` contains the corrected version. The panel is shared with the full open folder.
