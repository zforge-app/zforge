# Separation into layers of candidate 30

This plan records the previous attempt to separate PNG from candidate 30. The user then exported [zforge_icon.icon](../../../Zforge/zforge_icon.icon/icon.json) with own layers, already selected as the app icon.

Source: [`30-simplified-press-z-distant.png`](30-simplified-press-z-distant.png), transparent PNG of 1254 × 1254 px.

## Stack order

1. **Bottom base — bottom.** Circular disc of steel; his upper face receives the shadow and contact of the piece. The cylindrical wall continues to the lower edge.
2. **Metallic Z — medium.** A single continuous piece, with orange relief and shine concentrated on the upper and lower contact lines. It needs to preserve the scale and position of the origin composition.
3. **Press head — front.** Yellow and black cylinder, piston and movable steel disc; the cylinder goes to the top edge. The disc must hide the encounter with the top face of the Z.

Each layer shall be a PNG RGBA with the same canvas of 1254 × 1254 px and common origin at (0, 0). The coloured background and rounded cutout seen in the previous Icon Composer do not integrate any of the three layers.

## State of extraction

The attempts to isolate the pieces with ImageGen changed their scale and position, even using candidate 30 as a reference. These outputs were not registered as usable layers. The parts need to be extracted by preserving the pixels and checking the overlap before delivering the PNGs.
