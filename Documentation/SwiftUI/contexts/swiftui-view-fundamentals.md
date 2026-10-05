---
title: "View fundamentals"
source_url: "https://developer.apple.com/documentation/swiftui/view-fundamentals"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View-fundamentals"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "4f32a275307f35d9a4d36fda2b528290e4cbb82ed08b3920d171382fc609b34a"
source_etag: "W/\"5bbbe83a1596e52816a31222702ed9a5\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# View fundamentals

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Define the visual elements of your app using a hierarchy of views.

Views are the building blocks that you use to declare your app’s user interface. Each view contains a description of what to display for a given state. Every bit of your app that’s visible to the user derives from the description in a view, and any type that conforms to the View protocol can act as a view in your app. Compose a custom view by combining built-in views that SwiftUI provides with other custom views that you create in your view’s body computed property. Configure views using the view modifiers that SwiftUI provides, or by defining your own view modifiers using the ViewModifier protocol and the modifier(_:) method.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(local context)_
- [body](https://developer.apple.com/documentation/swiftui/view/body-8kl5o) — The content and behavior of the view. _(Apple Developer; expand on demand)_
- [ViewModifier](https://developer.apple.com/documentation/swiftui/viewmodifier) — A modifier that you apply to a view or another view modifier, producing a different version of the original value. _(Apple Developer; expand on demand)_
- [modifier(_:)](https://developer.apple.com/documentation/swiftui/view/modifier(_:)) — Applies a modifier to a view and returns a new view. _(Apple Developer; expand on demand)_

### Creating a view

- [Declaring a custom view](https://developer.apple.com/documentation/swiftui/declaring-a-custom-view) — Define views and assemble them into a view hierarchy. _(Apple Developer; expand on demand)_
- [Wishlist: Planning travel in a SwiftUI app](swiftui-wishlist-planning-travel-in-a-swiftui-app.md) — Build a travel planning app that organizes trips into collections and tracks activity completion. _(local context)_
- [ContentBuilder](https://developer.apple.com/documentation/swiftui/contentbuilder) — A custom parameter attribute that constructs views and other content types from closures. _(Apple Developer; expand on demand)_
- [ViewBuilder](https://developer.apple.com/documentation/swiftui/viewbuilder) — A custom parameter attribute that constructs views from closures. _(Apple Developer; expand on demand)_

### Modifying a view

- [Configuring views](https://developer.apple.com/documentation/swiftui/configuring-views) — Adjust the characteristics of a view by applying view modifiers. _(Apple Developer; expand on demand)_
- [Reducing view modifier maintenance](https://developer.apple.com/documentation/swiftui/reducing-view-modifier-maintenance) — Bundle view modifiers that you regularly reuse into a custom view modifier. _(Apple Developer; expand on demand)_
- [EmptyModifier](https://developer.apple.com/documentation/swiftui/emptymodifier) — An empty, or identity, modifier, used during development to switch modifiers at compile time. _(Apple Developer; expand on demand)_
- [ModifiedContent](https://developer.apple.com/documentation/swiftui/modifiedcontent) — A value with a modifier applied to it. _(Apple Developer; expand on demand)_
- [EnvironmentalModifier](https://developer.apple.com/documentation/swiftui/environmentalmodifier) — A modifier that must resolve to a concrete modifier in an environment before use. _(Apple Developer; expand on demand)_
- [ManipulableModifier](https://developer.apple.com/documentation/swiftui/manipulablemodifier) — _Apple Developer; expand on demand_
- [ManipulableResponderModifier](https://developer.apple.com/documentation/swiftui/manipulablerespondermodifier) — _Apple Developer; expand on demand_
- [ManipulableTransformBindingModifier](https://developer.apple.com/documentation/swiftui/manipulabletransformbindingmodifier) — _Apple Developer; expand on demand_
- [ManipulationGeometryModifier](https://developer.apple.com/documentation/swiftui/manipulationgeometrymodifier) — _Apple Developer; expand on demand_
- [ManipulationGestureModifier](https://developer.apple.com/documentation/swiftui/manipulationgesturemodifier) — _Apple Developer; expand on demand_
- [ManipulationUsingGestureStateModifier](https://developer.apple.com/documentation/swiftui/manipulationusinggesturestatemodifier) — _Apple Developer; expand on demand_
- [Manipulable](https://developer.apple.com/documentation/swiftui/manipulable) — A namespace for various manipulable related types. _(Apple Developer; expand on demand)_

### Responding to view life cycle updates

- [onAppear(perform:)](https://developer.apple.com/documentation/swiftui/view/onappear(perform:)) — Adds an action to perform before this view appears. _(Apple Developer; expand on demand)_
- [onDisappear(perform:)](https://developer.apple.com/documentation/swiftui/view/ondisappear(perform:)) — Adds an action to perform after this view disappears. _(Apple Developer; expand on demand)_

### Assigning tasks

- [task(id:name:executorPreference:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(id:name:executorpreference:priority:file:line:_:)) — Adds a task to perform before this view appears or when a specified value changes. _(Apple Developer; expand on demand)_
- [task(id:name:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(id:name:priority:file:line:_:)) — Adds a task to perform before this view appears or when a specified value changes. _(Apple Developer; expand on demand)_
- [task(name:executorPreference:priority:file:line:action:)](https://developer.apple.com/documentation/swiftui/view/task(name:executorpreference:priority:file:line:action:)) — Adds an asynchronous task to perform before this view appears. _(Apple Developer; expand on demand)_
- [task(name:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(name:priority:file:line:_:)) — Adds an asynchronous task to perform before this view appears. _(Apple Developer; expand on demand)_

### Managing the view hierarchy

- [id(_:)](https://developer.apple.com/documentation/swiftui/view/id(_:)) — Binds a view’s identity to the given proxy value. _(Apple Developer; expand on demand)_
- [tag(_:includeOptional:)](https://developer.apple.com/documentation/swiftui/view/tag(_:includeoptional:)) — Sets the unique tag value of this view. _(Apple Developer; expand on demand)_
- [equatable()](https://developer.apple.com/documentation/swiftui/view/equatable()) — Prevents the view from updating its child view when its new value is the same as its old value. _(Apple Developer; expand on demand)_

### Supporting content types

- [EmptyContent](https://developer.apple.com/documentation/swiftui/emptycontent) — Content which contains nothing. _(Apple Developer; expand on demand)_
- [TupleContent](https://developer.apple.com/documentation/swiftui/tuplecontent) — Content created from a tuple of content to be treated as siblings. _(Apple Developer; expand on demand)_

### Supporting view types

- [AnyView](https://developer.apple.com/documentation/swiftui/anyview) — A type-erased view. _(Apple Developer; expand on demand)_
- [EmptyView](https://developer.apple.com/documentation/swiftui/emptyview) — A view that doesn’t contain any content. _(Apple Developer; expand on demand)_
- [EquatableView](https://developer.apple.com/documentation/swiftui/equatableview) — A view type that compares itself against its previous value and prevents its child updating if its new value is the same as its… _(Apple Developer; expand on demand)_
- [SubscriptionView](https://developer.apple.com/documentation/swiftui/subscriptionview) — A view that subscribes to a publisher with an action. _(Apple Developer; expand on demand)_
- [TupleView](https://developer.apple.com/documentation/swiftui/tupleview) — A View created from a swift tuple of View values. _(Apple Developer; expand on demand)_

### Views

- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(local context)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(local context)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(local context)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view-fundamentals)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `4f32a275307f35d9a4d36fda2b528290e4cbb82ed08b3920d171382fc609b34a`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
