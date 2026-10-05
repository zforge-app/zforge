---
title: "Shapes"
source_url: "https://developer.apple.com/documentation/swiftui/shapes"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Shapes"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "d21f193fe5ecb8e3c06ac353b260f73e17d94cd5320503dad5b690781f4fb780"
source_etag: "W/\"b2243aac0f324529696687705ee02d26\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Shapes

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Trace and fill built-in and custom shapes with a color, gradient, or other pattern.

Draw shapes like circles and rectangles, as well as custom paths that define shapes of your own design. Apply styles that include environment-aware colors, rich gradients, and material effects to the foreground, background, and outline of your shapes. If you need the efficiency or flexibility of immediate mode drawing — for example, to create particle effects — use a Canvas view instead.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Canvas](https://developer.apple.com/documentation/swiftui/canvas) — A view type that supports immediate mode drawing. _(Apple Developer; expand on demand)_

### Creating rectangular shapes

- [Rectangle](https://developer.apple.com/documentation/swiftui/rectangle) — A rectangular shape aligned inside the frame of the view containing it. _(Apple Developer; expand on demand)_
- [RoundedRectangle](https://developer.apple.com/documentation/swiftui/roundedrectangle) — A rectangular shape with rounded corners, aligned inside the frame of the view containing it. _(Apple Developer; expand on demand)_
- [RoundedCornerStyle](https://developer.apple.com/documentation/swiftui/roundedcornerstyle) — Defines the shape of a rounded rectangle’s corners. _(Apple Developer; expand on demand)_
- [RoundedRectangularShape](https://developer.apple.com/documentation/swiftui/roundedrectangularshape) — A protocol of InsettableShape that describes a rounded rectangular shape. _(Apple Developer; expand on demand)_
- [RoundedRectangularShapeCorners](https://developer.apple.com/documentation/swiftui/roundedrectangularshapecorners) — A type describing the corner styles of a RoundedRectangularShape. _(Apple Developer; expand on demand)_
- [UnevenRoundedRectangle](https://developer.apple.com/documentation/swiftui/unevenroundedrectangle) — A rectangular shape with rounded corners with different values, aligned inside the frame of the view containing it. _(Apple Developer; expand on demand)_
- [RectangleCornerRadii](https://developer.apple.com/documentation/swiftui/rectanglecornerradii) — Describes the corner radius values of a rounded rectangle with uneven corners. _(Apple Developer; expand on demand)_
- [RectangleCornerInsets](https://developer.apple.com/documentation/swiftui/rectanglecornerinsets) — The inset sizes for the corners of a rectangle. _(Apple Developer; expand on demand)_
- [ConcentricRectangle](https://developer.apple.com/documentation/swiftui/concentricrectangle) — A shape whose corners you configure, individually or uniformly, to be squared, rounded, or concentric relative to a container shape’s corners. _(Apple Developer; expand on demand)_

### Creating circular shapes

- [Circle](https://developer.apple.com/documentation/swiftui/circle) — A circle centered on the frame of the view containing it. _(Apple Developer; expand on demand)_
- [Ellipse](https://developer.apple.com/documentation/swiftui/ellipse) — An ellipse aligned inside the frame of the view containing it. _(Apple Developer; expand on demand)_
- [Capsule](https://developer.apple.com/documentation/swiftui/capsule) — A capsule shape aligned inside the frame of the view containing it. _(Apple Developer; expand on demand)_

### Drawing custom shapes

- [Path](https://developer.apple.com/documentation/swiftui/path) — The outline of a 2D shape. _(Apple Developer; expand on demand)_

### Defining shape behavior

- [ShapeView](https://developer.apple.com/documentation/swiftui/shapeview) — A view that provides a shape that you can use for drawing operations. _(Apple Developer; expand on demand)_
- [Shape](https://developer.apple.com/documentation/swiftui/shape) — A 2D shape that you can use when drawing a view. _(Apple Developer; expand on demand)_
- [AnyShape](https://developer.apple.com/documentation/swiftui/anyshape) — A type-erased shape value. _(Apple Developer; expand on demand)_
- [ShapeRole](https://developer.apple.com/documentation/swiftui/shaperole) — Ways of styling a shape. _(Apple Developer; expand on demand)_
- [StrokeStyle](https://developer.apple.com/documentation/swiftui/strokestyle) — The characteristics of a stroke that traces a path. _(Apple Developer; expand on demand)_
- [StrokeShapeView](https://developer.apple.com/documentation/swiftui/strokeshapeview) — A shape provider that strokes its shape. _(Apple Developer; expand on demand)_
- [StrokeBorderShapeView](https://developer.apple.com/documentation/swiftui/strokebordershapeview) — A shape provider that strokes the border of its shape. _(Apple Developer; expand on demand)_
- [FillStyle](https://developer.apple.com/documentation/swiftui/fillstyle) — A style for rasterizing vector shapes. _(Apple Developer; expand on demand)_
- [FillShapeView](https://developer.apple.com/documentation/swiftui/fillshapeview) — A shape provider that fills its shape. _(Apple Developer; expand on demand)_

### Transforming a shape

- [ScaledShape](https://developer.apple.com/documentation/swiftui/scaledshape) — A shape with a scale transform applied to it. _(Apple Developer; expand on demand)_
- [RotatedShape](https://developer.apple.com/documentation/swiftui/rotatedshape) — A shape with a rotation transform applied to it. _(Apple Developer; expand on demand)_
- [OffsetShape](https://developer.apple.com/documentation/swiftui/offsetshape) — A shape with a translation offset transform applied to it. _(Apple Developer; expand on demand)_
- [TransformedShape](https://developer.apple.com/documentation/swiftui/transformedshape) — A shape with an affine transform applied to it. _(Apple Developer; expand on demand)_

### Setting a container shape

- [containerShape(_:)](https://developer.apple.com/documentation/swiftui/view/containershape(_:)) — Sets the container shape to use for any container relative shape or concentric rectangle within this view. _(Apple Developer; expand on demand)_
- [InsettableShape](https://developer.apple.com/documentation/swiftui/insettableshape) — A shape type that is able to inset itself to produce another shape. _(Apple Developer; expand on demand)_
- [ContainerRelativeShape](https://developer.apple.com/documentation/swiftui/containerrelativeshape) — A shape whose dimensions the system calculates from an inset version of the current container shape. _(Apple Developer; expand on demand)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(local context)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(local context)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(local context)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/shapes)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `d21f193fe5ecb8e3c06ac353b260f73e17d94cd5320503dad5b690781f4fb780`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
