---
title: "Custom layout"
source_url: "https://developer.apple.com/documentation/swiftui/custom-layout"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Custom-layout"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "b77128410b57c786a71045ec2c4d39d45192a8c09a89f77986de2acee99926b8"
source_etag: "W/\"32c3d990a656c5a4289d08bf593df2e2\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Custom layout

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Place views in custom arrangements and create animated transitions between layout types.

You can create complex view layouts using the built-in layout containers and layout view modifiers that SwiftUI provides. However, if you need behavior that you can’t achieve with the built-in layout tools, create a custom layout container type using the Layout protocol. A container that you define asks for the sizes of all its subviews, and then indicates where to place the subviews within its own bounds. You can also create animated transitions among layout types that conform to the Layout procotol, including both built-in and custom layouts. For design guidance, see Layout in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Layout](https://developer.apple.com/documentation/swiftui/layout) — A type that defines the geometry of a collection of views. _(Apple Developer; expand on demand)_
- [Layout](hig-layout.md) — A consistent layout that adapts to various contexts makes your experience more approachable and helps people enjoy their favorite apps and games on all… _(Apple Developer; expand on demand)_

### Creating a custom layout container

- [Composing custom layouts with SwiftUI](https://developer.apple.com/documentation/swiftui/composing-custom-layouts-with-swiftui) — Arrange views in your app’s interface using layout tools that SwiftUI provides. _(Apple Developer; expand on demand)_
- [LayoutSubview](https://developer.apple.com/documentation/swiftui/layoutsubview) — A proxy that represents one subview of a layout. _(Apple Developer; expand on demand)_
- [LayoutSubviews](https://developer.apple.com/documentation/swiftui/layoutsubviews) — A collection of proxy values that represent the subviews of a layout view. _(Apple Developer; expand on demand)_

### Configuring a custom layout

- [LayoutProperties](https://developer.apple.com/documentation/swiftui/layoutproperties) — Layout-specific properties of a layout container. _(Apple Developer; expand on demand)_
- [ProposedViewSize](https://developer.apple.com/documentation/swiftui/proposedviewsize) — A proposal for the size of a view. _(Apple Developer; expand on demand)_
- [ViewSpacing](https://developer.apple.com/documentation/swiftui/viewspacing) — A collection of the geometric spacing preferences of a view. _(Apple Developer; expand on demand)_

### Associating values with views in a custom layout

- [layoutValue(key:value:)](https://developer.apple.com/documentation/swiftui/view/layoutvalue(key:value:)) — Associates a value with a custom layout property. _(Apple Developer; expand on demand)_
- [LayoutValueKey](https://developer.apple.com/documentation/swiftui/layoutvaluekey) — A key for accessing a layout value of a layout container’s subviews. _(Apple Developer; expand on demand)_

### Transitioning between layout types

- [AnyLayout](https://developer.apple.com/documentation/swiftui/anylayout) — A type-erased instance of the layout protocol. _(Apple Developer; expand on demand)_
- [HStackLayout](https://developer.apple.com/documentation/swiftui/hstacklayout) — A horizontal container that you can use in conditional layouts. _(Apple Developer; expand on demand)_
- [VStackLayout](https://developer.apple.com/documentation/swiftui/vstacklayout) — A vertical container that you can use in conditional layouts. _(Apple Developer; expand on demand)_
- [ZStackLayout](https://developer.apple.com/documentation/swiftui/zstacklayout) — An overlaying container that you can use in conditional layouts. _(Apple Developer; expand on demand)_
- [GridLayout](https://developer.apple.com/documentation/swiftui/gridlayout) — A grid that you can use in conditional layouts. _(Apple Developer; expand on demand)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(local context)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(local context)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(local context)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(local context)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(local context)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/custom-layout)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `b77128410b57c786a71045ec2c4d39d45192a8c09a89f77986de2acee99926b8`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
