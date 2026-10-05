# Seal Zforge — plan debossing

Decision of 2026-10-03: the user approved the form of study `zforge-stamp-v3-original-mono.png`. The desired treatment goes from embossing to **debossing**, as compressed material into the folder. The physical reference is `reference-debossing-paper.png`. This decision is planned: the current composer still uses the simplified form and two passages of color.

## Current technique and limitation

`ArchiveFolderIconComposer.compose` draws the native folder, then a dislocated light copy and a dark blue copy of the vector form. It is a simple hint of relief, with filling and fixed colors. does not represent depth, internal edges, occlusion or surface continuity; does not use the approved study v3.

## Proposed improvement

1. Preserve v3 as a form reference. Derive a neutral drawing of geometry/deepness of the press, Z and circle, without carrying the reflections of steel or painting the material as metal. A simple opaque silhouette would lose internal details of the piston and discs; maintain structural contours and depth levels.
2. Construct a mask of the pressed area and a soft height map, with the surface intact at zero and the mark below it. Round/chained edge, shallow bottom, coherent depth and also lowered ring. To represent the three-dimensional form of the reference by shallow levels in printing, not by an applied metal part.
3. Derive the direction of the surfaces from this map and illuminate them with light compatible with the folder, initially upper left. For the cavity, the upper/left inner edge tends to darken and the lower/right edge to receive light; That depends on the local profile. Add soft internal shadow/occlusion in encounters and corners, without external shadow of floating object.
4. Modify the luminosity of the original folder pixels instead of covering them with fixed or white blue. maintain the existing gradient, colour and texture; subtly reduce the texture at the bottom of the brand to suggest compression. The whole effect is limited to the frontal face.
5. Parametrizar depth, transition width, intensity and direction of light. Adjust to points/pixels of the final size: smaller visual depth in large previews; minimal edges readable in 16–32 pt and texture suppression/fine bands that cause noise. Preserve compact centralization and approved positions.
6. First generate a single large preview of the printing in the folder and compare it to the physical reference. After refinement, check the six sizes and the three folder states. apply the same surface transformation to the stamp in the open folder; the lighting must not be an independent image glued on top.
7. Integrate the approved composition with status/size/appearance cache. Check Core Image or alternate renderer on the app with sandbox, light/dark theme, four modes, selection, previews and zoom. Do not assume that an isolated rendering confirms these flows.

## Visual criteria

- The approved form remains recognizable and does not become a generic press.
- The stamp looks like a depression in the same material in the briefcase.
- No gray plate, independent metallic brightness, plated blue filler, halo or outer shadow.
- Inner light and shadow are visible, with moderate depth and without destroying legibility in 16 pt.
- The existing studies remain preserved; revision PNGs do not require a file per size on the product.

## Evidence of study visual

The user's request generated the [v4 preview](folder-debossing-v4.png) of the large folder. It is a visual reference obtained by ImageGen, without integration or implementation of the proposed renderer. The first generation was refined so that the press and the Z were also cavities. Next steps depend on the refinement visual of this reference; matrix of sizes/states and validation of the composer remain pending.

## Driving refinement — volume preference

After comparing the previous ones, the user preferred the composition with higher internal volume, despite recognizing the v4 as more literal debossing. For the continuation, preserve the physicality, blue and circular cavity of the first preview; not flatten Z and the disks to impose pure debossing. The upper cylinder shall continue to the upper inner edge of the circle. [Study v5](folder-pressed-relief-v5.png) created with this correction; Not yet integrated. The most recent visual preference prevails where to conflict with previous downgrading criteria in all ways.

Refining v6: Cut the cylinder through the inner opening and draw the complete circular contour on the press. The extension may not cover the track or interrupt the circle line. Prior `folder-pressed-relief-v6.png`; Still no integration.

## Authorised final implementation

The v6 was approved and integrated with light-neutral masks and shadow derived from a single approved raster reference. This technique preserves its illumination and forms directly on the native folder. The height/normal map and dynamic lighting described above remained proposed; they are not necessary for the approved fixed composition and were not implemented. Regressions and limits in `REGRESSION-COVERAGE.md`, ZF-29 and OR-13.
