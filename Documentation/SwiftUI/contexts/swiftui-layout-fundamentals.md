---
title: "Layout fundamentals"
source_url: "https://developer.apple.com/documentation/swiftui/layout-fundamentals"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Layout-fundamentals"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "e74a5ee60e91347e162bbcf9a8ba6d346e036b39a9ca374a0bb63216b591e5ec"
source_etag: "W/\"2eca5a5d444e92c0b197c1605993cbea\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Layout fundamentals

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Arrange views inside built-in layout containers like stacks and grids.

Use layout containers to arrange the elements of your user interface. Stacks and grids update and adjust the positions of the subviews they contain in response to changes in content or interface dimensions. You can nest layout containers inside other layout containers to any depth to achieve complex layout effects. To fine-tune the position, alignment, and other elements of a layout that you build with layout container views, see Layout adjustments. To define custom layout containers, see Custom layout. For design guidance, see Layout in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(local context)_
- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(local context)_
- [Layout](hig-layout.md) — A consistent layout that adapts to various contexts makes your experience more approachable and helps people enjoy their favorite apps and games on all… _(Apple Developer; expand on demand)_

### Choosing a layout

- [Picking container views for your content](https://developer.apple.com/documentation/swiftui/picking-container-views-for-your-content) — Build flexible user interfaces by using stacks, grids, lists, and forms. _(Apple Developer; expand on demand)_

### Statically arranging views in one dimension

- [Building layouts with stack views](https://developer.apple.com/documentation/swiftui/building-layouts-with-stack-views) — Compose complex layouts from primitive container views. _(Apple Developer; expand on demand)_
- [HStack](https://developer.apple.com/documentation/swiftui/hstack) — A view that arranges its subviews in a horizontal line. _(Apple Developer; expand on demand)_
- [VStack](https://developer.apple.com/documentation/swiftui/vstack) — A view that arranges its subviews in a vertical line. _(Apple Developer; expand on demand)_

### Dynamically arranging views in one dimension

- [Grouping data with lazy stack views](https://developer.apple.com/documentation/swiftui/grouping-data-with-lazy-stack-views) — Split content into logical sections inside lazy stack views. _(Apple Developer; expand on demand)_
- [Creating performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks) — Display large numbers of repeated views efficiently with scroll views, stack views, and lazy stacks. _(Apple Developer; expand on demand)_
- [LazyHStack](https://developer.apple.com/documentation/swiftui/lazyhstack) — A view that arranges its children in a line that grows horizontally, creating items only as needed. _(Apple Developer; expand on demand)_
- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack) — A view that arranges its children in a line that grows vertically, creating items only as needed. _(Apple Developer; expand on demand)_
- [PinnedScrollableViews](https://developer.apple.com/documentation/swiftui/pinnedscrollableviews) — A set of view types that may be pinned to the bounds of a scroll view. _(Apple Developer; expand on demand)_

### Statically arranging views in two dimensions

- [Grid](https://developer.apple.com/documentation/swiftui/grid) — A container view that arranges other views in a two dimensional layout. _(Apple Developer; expand on demand)_
- [GridRow](https://developer.apple.com/documentation/swiftui/gridrow) — A horizontal row in a two dimensional grid container. _(Apple Developer; expand on demand)_
- [gridCellColumns(_:)](https://developer.apple.com/documentation/swiftui/view/gridcellcolumns(_:)) — Tells a view that acts as a cell in a grid to span the specified number of columns. _(Apple Developer; expand on demand)_
- [gridCellAnchor(_:)](https://developer.apple.com/documentation/swiftui/view/gridcellanchor(_:)) — Specifies a custom alignment anchor for a view that acts as a grid cell. _(Apple Developer; expand on demand)_
- [gridCellUnsizedAxes(_:)](https://developer.apple.com/documentation/swiftui/view/gridcellunsizedaxes(_:)) — Asks grid layouts not to offer the view extra size in the specified axes. _(Apple Developer; expand on demand)_
- [gridColumnAlignment(_:)](https://developer.apple.com/documentation/swiftui/view/gridcolumnalignment(_:)) — Overrides the default horizontal alignment of the grid column that the view appears in. _(Apple Developer; expand on demand)_

### Dynamically arranging views in two dimensions

- [LazyHGrid](https://developer.apple.com/documentation/swiftui/lazyhgrid) — A container view that arranges its child views in a grid that grows horizontally, creating items only as needed. _(Apple Developer; expand on demand)_
- [LazyVGrid](https://developer.apple.com/documentation/swiftui/lazyvgrid) — A container view that arranges its child views in a grid that grows vertically, creating items only as needed. _(Apple Developer; expand on demand)_
- [GridItem](https://developer.apple.com/documentation/swiftui/griditem) — A description of a row or a column in a lazy grid. _(Apple Developer; expand on demand)_

### Layering views

- [Adding a background to your view](https://developer.apple.com/documentation/swiftui/adding-a-background-to-your-view) — Compose a background behind your view and extend it beyond the safe area insets. _(Apple Developer; expand on demand)_
- [ZStack](https://developer.apple.com/documentation/swiftui/zstack) — A view that overlays its subviews, aligning them in both axes. _(Apple Developer; expand on demand)_
- [zIndex(_:)](https://developer.apple.com/documentation/swiftui/view/zindex(_:)) — Controls the display order of overlapping views. _(Apple Developer; expand on demand)_
- [background(alignment:content:)](https://developer.apple.com/documentation/swiftui/view/background(alignment:content:)) — Layers the views that you specify behind this view. _(Apple Developer; expand on demand)_
- [background(_:ignoresSafeAreaEdges:)](https://developer.apple.com/documentation/swiftui/view/background(_:ignoressafeareaedges:)) — Sets the view’s background to a style. _(Apple Developer; expand on demand)_
- [background(ignoresSafeAreaEdges:)](https://developer.apple.com/documentation/swiftui/view/background(ignoressafeareaedges:)) — Sets the view’s background to the default background style. _(Apple Developer; expand on demand)_
- [background(_:in:fillStyle:)](https://developer.apple.com/documentation/swiftui/view/background(_:in:fillstyle:)) — Sets the view’s background to an insettable shape filled with a style. _(Apple Developer; expand on demand)_
- [background(in:fillStyle:)](https://developer.apple.com/documentation/swiftui/view/background(in:fillstyle:)) — Sets the view’s background to an insettable shape filled with the default background style. _(Apple Developer; expand on demand)_
- [overlay(alignment:content:)](https://developer.apple.com/documentation/swiftui/view/overlay(alignment:content:)) — Layers the views that you specify in front of this view. _(Apple Developer; expand on demand)_
- [overlay(_:ignoresSafeAreaEdges:)](https://developer.apple.com/documentation/swiftui/view/overlay(_:ignoressafeareaedges:)) — Layers the specified style in front of this view. _(Apple Developer; expand on demand)_
- [overlay(_:in:fillStyle:)](https://developer.apple.com/documentation/swiftui/view/overlay(_:in:fillstyle:)) — Layers a shape that you specify in front of this view. _(Apple Developer; expand on demand)_
- [backgroundMaterial](https://developer.apple.com/documentation/swiftui/environmentvalues/backgroundmaterial) — The material underneath the current view. _(Apple Developer; expand on demand)_
- [containerBackground(_:for:)](https://developer.apple.com/documentation/swiftui/view/containerbackground(_:for:)) — Sets the container background of the enclosing container using a view. _(Apple Developer; expand on demand)_
- [containerBackground(for:alignment:content:)](https://developer.apple.com/documentation/swiftui/view/containerbackground(for:alignment:content:)) — Sets the container background of the enclosing container using a view. _(Apple Developer; expand on demand)_
- [ContainerBackgroundPlacement](https://developer.apple.com/documentation/swiftui/containerbackgroundplacement) — The placement of a container background. _(Apple Developer; expand on demand)_

### Automatically choosing the layout that fits

- [ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits) — A view that adapts to the available space by providing the first child view that fits. _(Apple Developer; expand on demand)_

### Separators

- [Spacer](https://developer.apple.com/documentation/swiftui/spacer) — A flexible space that expands along the major axis of its containing stack layout, or on both axes if not contained in a stack. _(Apple Developer; expand on demand)_
- [Divider](https://developer.apple.com/documentation/swiftui/divider) — A visual element that can be used to separate other content. _(Apple Developer; expand on demand)_

### View layout

- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(local context)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(local context)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(local context)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/layout-fundamentals)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `e74a5ee60e91347e162bbcf9a8ba6d346e036b39a9ca374a0bb63216b591e5ec`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
