---
title: "Drawing and graphics"
source_url: "https://developer.apple.com/documentation/swiftui/drawing-and-graphics"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Drawing-and-graphics"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "15f4689eadb68cba1aeb6b75efaed84545dc03d51823dc5587ac4f32c93b1cf0"
source_etag: "W/\"06db444bb759a096e729637381773076\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Drawing and graphics

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Enhance your views with graphical effects and customized drawings.

You create rich, dynamic user interfaces with the built-in views and Shapes that SwiftUI provides. To enhance any view, you can apply many of the graphical effects typically associated with a graphics context, like setting colors, adding masks, and creating composites. When you need the flexibility of immediate mode drawing in a graphics context, use a Canvas view. This can be particularly helpful when you want to draw an extremely large number of dynamic shapes — for example, to create particle effects. For design guidance, see Materials and Color in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(local context)_
- [Canvas](https://developer.apple.com/documentation/swiftui/canvas) — A view type that supports immediate mode drawing. _(Apple Developer; expand on demand)_
- [Materials](https://developer.apple.com/design/Human-Interface-Guidelines/materials) — A material is a visual effect that creates a sense of depth, layering, and hierarchy between foreground and background elements. _(Apple Developer; expand on demand)_
- [Color](https://developer.apple.com/design/Human-Interface-Guidelines/color) — Judicious use of color can enhance communication, evoke your brand, provide visual continuity, communicate status and feedback, and help people understand information. _(Apple Developer; expand on demand)_

### Composing graphics effects

- [Composing advanced graphics effects with SwiftUI](https://developer.apple.com/documentation/swiftui/composing-advanced-graphics-effects-with-swiftui) — Create compelling visuals in your app by combining graphical effects. _(Apple Developer; expand on demand)_

### Immediate mode drawing

- [Add rich graphics to your SwiftUI app](https://developer.apple.com/documentation/swiftui/add-rich-graphics-to-your-swiftui-app) — Make your apps stand out by adding background materials, vibrancy, custom graphics, and animations. _(Apple Developer; expand on demand)_
- [GraphicsContext](https://developer.apple.com/documentation/swiftui/graphicscontext) — An immediate mode drawing destination, and its current state. _(Apple Developer; expand on demand)_

### Setting a color

- [tint(_:)](https://developer.apple.com/documentation/swiftui/view/tint(_:)) — Sets the tint color within this view. _(Apple Developer; expand on demand)_
- [Color](https://developer.apple.com/documentation/swiftui/color) — A representation of a color that adapts to a given context. _(Apple Developer; expand on demand)_

### Styling content

- [border(_:width:)](https://developer.apple.com/documentation/swiftui/view/border(_:width:)) — Adds a border to this view with the specified style and width. _(Apple Developer; expand on demand)_
- [foregroundStyle(_:)](https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:)) — Sets a view’s foreground elements to use a given style. _(Apple Developer; expand on demand)_
- [foregroundStyle(_:_:)](https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:_:)) — Sets the primary and secondary levels of the foreground style in the child view. _(Apple Developer; expand on demand)_
- [foregroundStyle(_:_:_:)](https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:_:_:)) — Sets the primary, secondary, and tertiary levels of the foreground style. _(Apple Developer; expand on demand)_
- [backgroundStyle(_:)](https://developer.apple.com/documentation/swiftui/view/backgroundstyle(_:)) — Sets the specified style to render backgrounds within the view. _(Apple Developer; expand on demand)_
- [backgroundStyle](https://developer.apple.com/documentation/swiftui/environmentvalues/backgroundstyle) — An optional style that overrides the default system background style when set. _(Apple Developer; expand on demand)_
- [ShapeStyle](https://developer.apple.com/documentation/swiftui/shapestyle) — A color or pattern to use when rendering a shape. _(Apple Developer; expand on demand)_
- [AnyShapeStyle](https://developer.apple.com/documentation/swiftui/anyshapestyle) — A type-erased ShapeStyle value. _(Apple Developer; expand on demand)_
- [Gradient](https://developer.apple.com/documentation/swiftui/gradient) — A color gradient represented as an array of color stops, each having a parametric location value. _(Apple Developer; expand on demand)_
- [MeshGradient](https://developer.apple.com/documentation/swiftui/meshgradient) — A two-dimensional gradient defined by a 2D grid of positioned colors. _(Apple Developer; expand on demand)_
- [AnyGradient](https://developer.apple.com/documentation/swiftui/anygradient) — A color gradient. _(Apple Developer; expand on demand)_
- [ShadowStyle](https://developer.apple.com/documentation/swiftui/shadowstyle) — A style to use when rendering shadows. _(Apple Developer; expand on demand)_
- [Glass](https://developer.apple.com/documentation/swiftui/glass) — A structure that defines the configuration of the Liquid Glass material. _(Apple Developer; expand on demand)_

### Transforming colors

- [brightness(_:)](https://developer.apple.com/documentation/swiftui/view/brightness(_:)) — Brightens this view by the specified amount. _(Apple Developer; expand on demand)_
- [contrast(_:)](https://developer.apple.com/documentation/swiftui/view/contrast(_:)) — Sets the contrast and separation between similar colors in this view. _(Apple Developer; expand on demand)_
- [colorInvert()](https://developer.apple.com/documentation/swiftui/view/colorinvert()) — Inverts the colors in this view. _(Apple Developer; expand on demand)_
- [colorMultiply(_:)](https://developer.apple.com/documentation/swiftui/view/colormultiply(_:)) — Adds a color multiplication effect to this view. _(Apple Developer; expand on demand)_
- [saturation(_:)](https://developer.apple.com/documentation/swiftui/view/saturation(_:)) — Adjusts the color saturation of this view. _(Apple Developer; expand on demand)_
- [grayscale(_:)](https://developer.apple.com/documentation/swiftui/view/grayscale(_:)) — Adds a grayscale effect to this view. _(Apple Developer; expand on demand)_
- [hueRotation(_:)](https://developer.apple.com/documentation/swiftui/view/huerotation(_:)) — Applies a hue rotation effect to this view. _(Apple Developer; expand on demand)_
- [luminanceToAlpha()](https://developer.apple.com/documentation/swiftui/view/luminancetoalpha()) — Adds a luminance to alpha effect to this view. _(Apple Developer; expand on demand)_
- [materialActiveAppearance(_:)](https://developer.apple.com/documentation/swiftui/view/materialactiveappearance(_:)) — Sets an explicit active appearance for materials in this view. _(Apple Developer; expand on demand)_
- [materialActiveAppearance](https://developer.apple.com/documentation/swiftui/environmentvalues/materialactiveappearance) — The behavior materials should use for their active state, defaulting to . _(Apple Developer; expand on demand)_
- [MaterialActiveAppearance](https://developer.apple.com/documentation/swiftui/materialactiveappearance) — The behavior for how materials appear active and inactive. _(Apple Developer; expand on demand)_

### Scaling, rotating, or transforming a view

- [scaledToFill()](https://developer.apple.com/documentation/swiftui/view/scaledtofill()) — Scales this view to fill its parent. _(Apple Developer; expand on demand)_
- [scaledToFit()](https://developer.apple.com/documentation/swiftui/view/scaledtofit()) — Scales this view to fit its parent. _(Apple Developer; expand on demand)_
- [scaleEffect(_:anchor:)](https://developer.apple.com/documentation/swiftui/view/scaleeffect(_:anchor:)) — Scales this view uniformly by the specified factor, relative to an anchor point. _(Apple Developer; expand on demand)_
- [scaleEffect(x:y:anchor:)](https://developer.apple.com/documentation/swiftui/view/scaleeffect(x:y:anchor:)) — Scales this view’s rendered output by the given horizontal and vertical amounts, relative to an anchor point. _(Apple Developer; expand on demand)_
- [scaleEffect(x:y:z:anchor:)](https://developer.apple.com/documentation/swiftui/view/scaleeffect(x:y:z:anchor:)) — Scales this view by the specified horizontal, vertical, and depth factors, relative to an anchor point. _(Apple Developer; expand on demand)_
- [aspectRatio(_:contentMode:)](https://developer.apple.com/documentation/swiftui/view/aspectratio(_:contentmode:)) — Constrains this view’s dimensions to the specified aspect ratio. _(Apple Developer; expand on demand)_
- [rotationEffect(_:anchor:)](https://developer.apple.com/documentation/swiftui/view/rotationeffect(_:anchor:)) — Rotates a view’s rendered output in two dimensions around the specified point. _(Apple Developer; expand on demand)_
- [rotation3DEffect(_:axis:anchor:anchorZ:perspective:)](https://developer.apple.com/documentation/swiftui/view/rotation3deffect(_:axis:anchor:anchorz:perspective:)) — Renders a view’s content as if it’s rotated in three dimensions around the specified axis. _(Apple Developer; expand on demand)_
- [perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:)](https://developer.apple.com/documentation/swiftui/view/perspectiverotationeffect(_:axis:anchor:anchorz:perspective:)) — Renders a view’s content as if it’s rotated in three dimensions around the specified axis. _(Apple Developer; expand on demand)_
- [rotation3DEffect(_:anchor:)](https://developer.apple.com/documentation/swiftui/view/rotation3deffect(_:anchor:)) — Rotates the view’s content by the specified 3D rotation value. _(Apple Developer; expand on demand)_
- [rotation3DEffect(_:axis:anchor:)](https://developer.apple.com/documentation/swiftui/view/rotation3deffect(_:axis:anchor:)) — Rotates the view’s content by an angle about an axis that you specify as a tuple of elements. _(Apple Developer; expand on demand)_
- [transformEffect(_:)](https://developer.apple.com/documentation/swiftui/view/transformeffect(_:)) — Applies an affine transformation to this view’s rendered output. _(Apple Developer; expand on demand)_
- [transform3DEffect(_:)](https://developer.apple.com/documentation/swiftui/view/transform3deffect(_:)) — Applies a 3D transformation to this view’s rendered output. _(Apple Developer; expand on demand)_
- [projectionEffect(_:)](https://developer.apple.com/documentation/swiftui/view/projectioneffect(_:)) — Applies a projection transformation to this view’s rendered output. _(Apple Developer; expand on demand)_
- [ProjectionTransform](https://developer.apple.com/documentation/swiftui/projectiontransform) — _Apple Developer; expand on demand_
- [ContentMode](https://developer.apple.com/documentation/swiftui/contentmode) — Constants that define how a view’s content fills the available space. _(Apple Developer; expand on demand)_

### Masking and clipping

- [mask(alignment:_:)](https://developer.apple.com/documentation/swiftui/view/mask(alignment:_:)) — Masks this view using the alpha channel of the given view. _(Apple Developer; expand on demand)_
- [clipped(antialiased:)](https://developer.apple.com/documentation/swiftui/view/clipped(antialiased:)) — Clips this view to its bounding rectangular frame. _(Apple Developer; expand on demand)_
- [clipShape(_:style:)](https://developer.apple.com/documentation/swiftui/view/clipshape(_:style:)) — Sets a clipping shape for this view. _(Apple Developer; expand on demand)_

### Applying blur and shadows

- [blur(radius:opaque:)](https://developer.apple.com/documentation/swiftui/view/blur(radius:opaque:)) — Applies a Gaussian blur to this view. _(Apple Developer; expand on demand)_
- [shadow(color:radius:x:y:)](https://developer.apple.com/documentation/swiftui/view/shadow(color:radius:x:y:)) — Adds a shadow to this view. _(Apple Developer; expand on demand)_
- [ColorMatrix](https://developer.apple.com/documentation/swiftui/colormatrix) — A matrix to use in an RGBA color transformation. _(Apple Developer; expand on demand)_

### Applying effects based on geometry

- [visualEffect(_:)](https://developer.apple.com/documentation/swiftui/view/visualeffect(_:)) — Applies effects to this view, while providing access to layout information through a geometry proxy. _(Apple Developer; expand on demand)_
- [visualEffect3D(_:)](https://developer.apple.com/documentation/swiftui/view/visualeffect3d(_:)) — Applies effects to this view, while providing access to layout information through a 3D geometry proxy. _(Apple Developer; expand on demand)_
- [VisualEffect](https://developer.apple.com/documentation/swiftui/visualeffect) — Visual Effects change the visual appearance of a view without changing its ancestors or descendents. _(Apple Developer; expand on demand)_
- [EmptyVisualEffect](https://developer.apple.com/documentation/swiftui/emptyvisualeffect) — The base visual effect that you apply additional effect to. _(Apple Developer; expand on demand)_

### Compositing views

- [blendMode(_:)](https://developer.apple.com/documentation/swiftui/view/blendmode(_:)) — Sets the blend mode for compositing this view with overlapping views. _(Apple Developer; expand on demand)_
- [compositingGroup()](https://developer.apple.com/documentation/swiftui/view/compositinggroup()) — Wraps this view in a compositing group. _(Apple Developer; expand on demand)_
- [drawingGroup(opaque:colorMode:)](https://developer.apple.com/documentation/swiftui/view/drawinggroup(opaque:colormode:)) — Composites this view’s contents into an offscreen image before final display. _(Apple Developer; expand on demand)_
- [BlendMode](https://developer.apple.com/documentation/swiftui/blendmode) — Modes for compositing a view with overlapping content. _(Apple Developer; expand on demand)_
- [ColorRenderingMode](https://developer.apple.com/documentation/swiftui/colorrenderingmode) — The set of possible working color spaces for color-compositing operations. _(Apple Developer; expand on demand)_
- [CompositorContent](https://developer.apple.com/documentation/swiftui/compositorcontent) — _Apple Developer; expand on demand_
- [CompositorContentBuilder](https://developer.apple.com/documentation/swiftui/compositorcontentbuilder) — A result builder for composing a collection of CompositorContent elements. _(Apple Developer; expand on demand)_
- [AnyCompositorContent](https://developer.apple.com/documentation/swiftui/anycompositorcontent) — Type erased compositor content. _(Apple Developer; expand on demand)_

### Measuring a view

- [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader) — A container view that defines its content as a function of its own size and coordinate space. _(Apple Developer; expand on demand)_
- [GeometryReader3D](https://developer.apple.com/documentation/swiftui/geometryreader3d) — A container view that defines its content as a function of its own size and coordinate space. _(Apple Developer; expand on demand)_
- [GeometryProxy](https://developer.apple.com/documentation/swiftui/geometryproxy) — A proxy for access to the size and coordinate space (for anchor resolution) of the container view. _(Apple Developer; expand on demand)_
- [GeometryProxy3D](https://developer.apple.com/documentation/swiftui/geometryproxy3d) — A proxy for access to the size and coordinate space of the container view. _(Apple Developer; expand on demand)_
- [coordinateSpace(_:)](https://developer.apple.com/documentation/swiftui/view/coordinatespace(_:)) — Assigns a name to the view’s coordinate space, so other code can operate on dimensions like points and sizes relative to the named space. _(Apple Developer; expand on demand)_
- [CoordinateSpace](https://developer.apple.com/documentation/swiftui/coordinatespace) — A resolved coordinate space created by the coordinate space protocol. _(Apple Developer; expand on demand)_
- [CoordinateSpaceProtocol](https://developer.apple.com/documentation/swiftui/coordinatespaceprotocol) — A frame of reference within the layout system. _(Apple Developer; expand on demand)_
- [PhysicalMetric](https://developer.apple.com/documentation/swiftui/physicalmetric) — Provides access to a value in points that corresponds to the specified physical measurement. _(Apple Developer; expand on demand)_
- [PhysicalMetricsConverter](https://developer.apple.com/documentation/swiftui/physicalmetricsconverter) — A physical metrics converter provides conversion between point values and their extent in 3D space, in the form of physical length measurements. _(Apple Developer; expand on demand)_

### Responding to a geometry change

- [onGeometryChange(for:of:action:)](https://developer.apple.com/documentation/swiftui/view/ongeometrychange(for:of:action:)) — Adds an action to be performed when a value, created from a geometry proxy, changes. _(Apple Developer; expand on demand)_

### Accessing Metal shaders

- [colorEffect(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/coloreffect(_:isenabled:)) — Returns a new view that applies to as a filter effect on the color of each pixel. _(Apple Developer; expand on demand)_
- [distortionEffect(_:maxSampleOffset:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/distortioneffect(_:maxsampleoffset:isenabled:)) — Returns a new view that applies to as a geometric distortion effect on the location of each pixel. _(Apple Developer; expand on demand)_
- [layerEffect(_:maxSampleOffset:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)) — Returns a new view that applies to as a filter on the raster layer created from . _(Apple Developer; expand on demand)_
- [Shader](https://developer.apple.com/documentation/swiftui/shader) — A reference to a function in a Metal shader library, along with its bound uniform argument values. _(Apple Developer; expand on demand)_
- [ShaderFunction](https://developer.apple.com/documentation/swiftui/shaderfunction) — A reference to a function in a Metal shader library. _(Apple Developer; expand on demand)_
- [ShaderLibrary](https://developer.apple.com/documentation/swiftui/shaderlibrary) — A Metal shader library. _(Apple Developer; expand on demand)_

### Accessing geometric constructs

- [Axis](https://developer.apple.com/documentation/swiftui/axis) — The horizontal or vertical dimension in a 2D coordinate system. _(Apple Developer; expand on demand)_
- [Angle](https://developer.apple.com/documentation/swiftui/angle) — A geometric angle whose value you access in either radians or degrees. _(Apple Developer; expand on demand)_
- [UnitPoint](https://developer.apple.com/documentation/swiftui/unitpoint) — A normalized 2D point in a view’s coordinate space. _(Apple Developer; expand on demand)_
- [UnitPoint3D](https://developer.apple.com/documentation/swiftui/unitpoint3d) — A normalized 3D point in a view’s coordinate space. _(Apple Developer; expand on demand)_
- [Anchor](https://developer.apple.com/documentation/swiftui/anchor) — An opaque value derived from an anchor source and a particular view. _(Apple Developer; expand on demand)_
- [DepthAlignmentID](https://developer.apple.com/documentation/swiftui/depthalignmentid) — _Apple Developer; expand on demand_
- [Alignment3D](https://developer.apple.com/documentation/swiftui/alignment3d) — An alignment in all three axes. _(Apple Developer; expand on demand)_
- [GeometryProxyCoordinateSpace3D](https://developer.apple.com/documentation/swiftui/geometryproxycoordinatespace3d) — A representation of a which can be used for based conversions. _(Apple Developer; expand on demand)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(local context)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(local context)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/drawing-and-graphics)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `15f4689eadb68cba1aeb6b75efaed84545dc03d51823dc5587ac4f32c93b1cf0`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
