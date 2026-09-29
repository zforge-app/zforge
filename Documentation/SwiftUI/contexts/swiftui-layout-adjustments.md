---
title: "Layout adjustments"
source_url: "https://developer.apple.com/documentation/swiftui/layout-adjustments"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Layout-adjustments"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "10f86c0be772ec2da5ee404117c41b45b2777f81038dc78b68de35fa8fb2aee6"
source_etag: "W/\"7938a7ff1ef48aab3160adf03e4614a8\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Layout adjustments

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Make fine adjustments to alignment, spacing, padding, and other layout parameters.

Layout containers like stacks and grids provide a great starting point for arranging views in your app’s user interface. When you need to make fine adjustments, use layout view modifiers. You can adjust or constrain the size, position, and alignment of a view. You can also add padding around a view, and indicate how the view interacts with system-defined safe areas. To get started with a basic layout, see Layout fundamentals. For design guidance, see Layout in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(contexto local)_
- [Layout](hig-layout.md) — A consistent layout that adapts to various contexts makes your experience more approachable and helps people enjoy their favorite apps and games on all… _(Apple Developer; expandir sob demanda)_

### Fine-tuning a layout

- [Laying out a simple view](https://developer.apple.com/documentation/swiftui/laying-out-a-simple-view) — Create a view layout by adjusting the size of views. _(Apple Developer; expandir sob demanda)_
- [Inspecting view layout](https://developer.apple.com/documentation/swiftui/inspecting-view-layout) — Determine the position and extent of a view using Xcode previews or by adding temporary borders. _(Apple Developer; expandir sob demanda)_

### Adding padding around a view

- [padding(_:)](https://developer.apple.com/documentation/swiftui/view/padding(_:)) — Adds a different padding amount to each edge of this view. _(Apple Developer; expandir sob demanda)_
- [padding(_:_:)](https://developer.apple.com/documentation/swiftui/view/padding(_:_:)) — Adds an equal padding amount to specific edges of this view. _(Apple Developer; expandir sob demanda)_
- [padding3D(_:)](https://developer.apple.com/documentation/swiftui/view/padding3d(_:)) — Pads this view using the edge insets you specify. _(Apple Developer; expandir sob demanda)_
- [padding3D(_:_:)](https://developer.apple.com/documentation/swiftui/view/padding3d(_:_:)) — Pads this view using the edge insets you specify. _(Apple Developer; expandir sob demanda)_
- [scenePadding(_:)](https://developer.apple.com/documentation/swiftui/view/scenepadding(_:)) — Adds padding to the specified edges of this view using an amount that’s appropriate for the current scene. _(Apple Developer; expandir sob demanda)_
- [scenePadding(_:edges:)](https://developer.apple.com/documentation/swiftui/view/scenepadding(_:edges:)) — Adds a specified kind of padding to the specified edges of this view using an amount that’s appropriate for the current scene. _(Apple Developer; expandir sob demanda)_
- [ScenePadding](https://developer.apple.com/documentation/swiftui/scenepadding) — The padding used to space a view from its containing scene. _(Apple Developer; expandir sob demanda)_

### Influencing a view’s size

- [frame(width:height:alignment:)](https://developer.apple.com/documentation/swiftui/view/frame(width:height:alignment:)) — Positions this view within an invisible frame with the specified size. _(Apple Developer; expandir sob demanda)_
- [frame(depth:alignment:)](https://developer.apple.com/documentation/swiftui/view/frame(depth:alignment:)) — Positions this view within an invisible frame with the specified depth. _(Apple Developer; expandir sob demanda)_
- [frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)](https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:)) — Positions this view within an invisible frame having the specified size constraints. _(Apple Developer; expandir sob demanda)_
- [frame(minDepth:idealDepth:maxDepth:alignment:)](https://developer.apple.com/documentation/swiftui/view/frame(mindepth:idealdepth:maxdepth:alignment:)) — Positions this view within an invisible frame having the specified depth constraints. _(Apple Developer; expandir sob demanda)_
- [containerRelativeFrame(_:alignment:)](https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:)) — Positions this view within an invisible frame with a size relative to the nearest container. _(Apple Developer; expandir sob demanda)_
- [containerRelativeFrame(_:alignment:_:)](https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:_:)) — Positions this view within an invisible frame with a size relative to the nearest container. _(Apple Developer; expandir sob demanda)_
- [containerRelativeFrame(_:count:span:spacing:alignment:)](https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:count:span:spacing:alignment:)) — Positions this view within an invisible frame with a size relative to the nearest container. _(Apple Developer; expandir sob demanda)_
- [fixedSize()](https://developer.apple.com/documentation/swiftui/view/fixedsize()) — Fixes this view at its ideal size. _(Apple Developer; expandir sob demanda)_
- [fixedSize(horizontal:vertical:)](https://developer.apple.com/documentation/swiftui/view/fixedsize(horizontal:vertical:)) — Fixes this view at its ideal size in the specified dimensions. _(Apple Developer; expandir sob demanda)_
- [layoutPriority(_:)](https://developer.apple.com/documentation/swiftui/view/layoutpriority(_:)) — Sets the priority by which a parent layout should apportion space to this child. _(Apple Developer; expandir sob demanda)_

### Adjusting a view’s position

- [Making fine adjustments to a view’s position](https://developer.apple.com/documentation/swiftui/making-fine-adjustments-to-a-view-s-position) — Shift the position of a view by applying the offset or position modifier. _(Apple Developer; expandir sob demanda)_
- [position(_:)](https://developer.apple.com/documentation/swiftui/view/position(_:)) — Positions the center of this view at the specified point in its parent’s coordinate space. _(Apple Developer; expandir sob demanda)_
- [position(x:y:)](https://developer.apple.com/documentation/swiftui/view/position(x:y:)) — Positions the center of this view at the specified coordinates in its parent’s coordinate space. _(Apple Developer; expandir sob demanda)_
- [offset(_:)](https://developer.apple.com/documentation/swiftui/view/offset(_:)) — Offset this view by the horizontal and vertical amount specified in the offset parameter. _(Apple Developer; expandir sob demanda)_
- [offset(x:y:)](https://developer.apple.com/documentation/swiftui/view/offset(x:y:)) — Offset this view by the specified horizontal and vertical distances. _(Apple Developer; expandir sob demanda)_
- [offset(z:)](https://developer.apple.com/documentation/swiftui/view/offset(z:)) — Brings a view forward in Z by the provided distance in points. _(Apple Developer; expandir sob demanda)_

### Aligning views

- [Aligning views within a stack](https://developer.apple.com/documentation/swiftui/aligning-views-within-a-stack) — Position views inside a stack using alignment guides. _(Apple Developer; expandir sob demanda)_
- [Aligning views across stacks](https://developer.apple.com/documentation/swiftui/aligning-views-across-stacks) — Create a custom alignment and use it to align views across multiple stacks. _(Apple Developer; expandir sob demanda)_
- [alignmentGuide(_:computeValue:)](https://developer.apple.com/documentation/swiftui/view/alignmentguide(_:computevalue:)) — Sets the view’s horizontal alignment. _(Apple Developer; expandir sob demanda)_
- [Alignment](https://developer.apple.com/documentation/swiftui/alignment) — An alignment in both axes. _(Apple Developer; expandir sob demanda)_
- [HorizontalAlignment](https://developer.apple.com/documentation/swiftui/horizontalalignment) — An alignment position along the horizontal axis. _(Apple Developer; expandir sob demanda)_
- [VerticalAlignment](https://developer.apple.com/documentation/swiftui/verticalalignment) — An alignment position along the vertical axis. _(Apple Developer; expandir sob demanda)_
- [DepthAlignment](https://developer.apple.com/documentation/swiftui/depthalignment) — An alignment position along the depth axis. _(Apple Developer; expandir sob demanda)_
- [AlignmentID](https://developer.apple.com/documentation/swiftui/alignmentid) — A type that you use to create custom alignment guides. _(Apple Developer; expandir sob demanda)_
- [ViewDimensions](https://developer.apple.com/documentation/swiftui/viewdimensions) — A view’s size and alignment guides in its own coordinate space. _(Apple Developer; expandir sob demanda)_
- [ViewDimensions3D](https://developer.apple.com/documentation/swiftui/viewdimensions3d) — A view’s 3D size and alignment guides in its own coordinate space. _(Apple Developer; expandir sob demanda)_
- [SpatialContainer](https://developer.apple.com/documentation/swiftui/spatialcontainer) — A layout container that aligns overlapping content in 3D space. _(Apple Developer; expandir sob demanda)_

### Setting margins

- [contentMargins(_:for:)](https://developer.apple.com/documentation/swiftui/view/contentmargins(_:for:)) — Configures the content margin for a provided placement. _(Apple Developer; expandir sob demanda)_
- [contentMargins(_:_:for:)](https://developer.apple.com/documentation/swiftui/view/contentmargins(_:_:for:)) — Configures the content margin for a provided placement. _(Apple Developer; expandir sob demanda)_
- [ContentMarginPlacement](https://developer.apple.com/documentation/swiftui/contentmarginplacement) — The placement of margins. _(Apple Developer; expandir sob demanda)_

### Staying in the safe areas

- [ignoresSafeArea(_:edges:)](https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:)) — Expands the safe area of a view. _(Apple Developer; expandir sob demanda)_
- [ignoresSafeArea(_:edges:alignment:)](https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:alignment:)) — Expands the safe area of a view aligning content within the new bounds using the provided alignment. _(Apple Developer; expandir sob demanda)_
- [safeAreaInset(edge:alignment:spacing:content:)](https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)) — Shows the specified content beside the modified view. _(Apple Developer; expandir sob demanda)_
- [safeAreaPadding(_:)](https://developer.apple.com/documentation/swiftui/view/safeareapadding(_:)) — Adds the provided insets into the safe area of this view. _(Apple Developer; expandir sob demanda)_
- [safeAreaPadding(_:_:)](https://developer.apple.com/documentation/swiftui/view/safeareapadding(_:_:)) — Adds the provided insets into the safe area of this view. _(Apple Developer; expandir sob demanda)_
- [SafeAreaRegions](https://developer.apple.com/documentation/swiftui/safearearegions) — A set of symbolic safe area regions. _(Apple Developer; expandir sob demanda)_

### Setting a layout direction

- [layoutDirectionBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/layoutdirectionbehavior(_:)) — Sets the behavior of this view for different layout directions. _(Apple Developer; expandir sob demanda)_
- [LayoutDirectionBehavior](https://developer.apple.com/documentation/swiftui/layoutdirectionbehavior) — A description of what should happen when the layout direction changes. _(Apple Developer; expandir sob demanda)_
- [layoutDirection](https://developer.apple.com/documentation/swiftui/environmentvalues/layoutdirection) — The layout direction associated with the current environment. _(Apple Developer; expandir sob demanda)_
- [LayoutDirection](https://developer.apple.com/documentation/swiftui/layoutdirection) — A direction in which SwiftUI can lay out content. _(Apple Developer; expandir sob demanda)_
- [LayoutRotationUnaryLayout](https://developer.apple.com/documentation/swiftui/layoutrotationunarylayout) — _Apple Developer; expandir sob demanda_

### Reacting to interface characteristics

- [isLuminanceReduced](https://developer.apple.com/documentation/swiftui/environmentvalues/isluminancereduced) — A Boolean value that indicates whether the display or environment currently requires reduced luminance. _(Apple Developer; expandir sob demanda)_
- [displayScale](https://developer.apple.com/documentation/swiftui/environmentvalues/displayscale) — The display scale of this environment. _(Apple Developer; expandir sob demanda)_
- [pixelLength](https://developer.apple.com/documentation/swiftui/environmentvalues/pixellength) — The size of a pixel on the screen. _(Apple Developer; expandir sob demanda)_
- [horizontalSizeClass](https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass) — The horizontal size class of this environment. _(Apple Developer; expandir sob demanda)_
- [verticalSizeClass](https://developer.apple.com/documentation/swiftui/environmentvalues/verticalsizeclass) — The vertical size class of this environment. _(Apple Developer; expandir sob demanda)_
- [UserInterfaceSizeClass](https://developer.apple.com/documentation/swiftui/userinterfacesizeclass) — A set of values that indicate the visual size available to the view. _(Apple Developer; expandir sob demanda)_

### Accessing edges, regions, and layouts

- [Edge](https://developer.apple.com/documentation/swiftui/edge) — An enumeration to indicate one edge of a rectangle. _(Apple Developer; expandir sob demanda)_
- [Edge3D](https://developer.apple.com/documentation/swiftui/edge3d) — An edge or face of a 3D volume. _(Apple Developer; expandir sob demanda)_
- [HorizontalEdge](https://developer.apple.com/documentation/swiftui/horizontaledge) — An edge on the horizontal axis. _(Apple Developer; expandir sob demanda)_
- [VerticalEdge](https://developer.apple.com/documentation/swiftui/verticaledge) — An edge on the vertical axis. _(Apple Developer; expandir sob demanda)_
- [EdgeInsets](https://developer.apple.com/documentation/swiftui/edgeinsets) — The inset distances for the sides of a rectangle. _(Apple Developer; expandir sob demanda)_
- [EdgeInsets3D](https://developer.apple.com/documentation/swiftui/edgeinsets3d) — The inset distances for the faces of a 3D volume. _(Apple Developer; expandir sob demanda)_

### View layout

- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(contexto local)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(contexto local)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(contexto local)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(contexto local)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/layout-adjustments)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `10f86c0be772ec2da5ee404117c41b45b2777f81038dc78b68de35fa8fb2aee6`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
