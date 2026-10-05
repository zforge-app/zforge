---
title: "View groupings"
source_url: "https://developer.apple.com/documentation/swiftui/view-groupings"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View-groupings"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "a8b76666f73b615f6037888894eb7b6386f6563b588b7da9ba36bfd6ce8d989b"
source_etag: "W/\"b63836d1ca8f94ee94ca860fb400d382\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# View groupings

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Present views in different kinds of purpose-driven containers, like forms or control groups.

You can create groups of views that serve different purposes. For example, a Group construct treats the specified views as a unit without imposing any additional layout or appearance characteristics. A Form presents a group of elements with a platform-specific appearance that’s suitable for gathering input from people. For design guidance, see Layout in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Group](https://developer.apple.com/documentation/swiftui/group) — A type that collects multiple instances of a content type — like views, scenes, or commands — into a single unit. _(Apple Developer; expand on demand)_
- [Form](swiftui-form.md) — A container for grouping controls used for data entry, such as in settings or inspectors. _(Apple Developer; expand on demand)_
- [Layout](hig-layout.md) — A consistent layout that adapts to various contexts makes your experience more approachable and helps people enjoy their favorite apps and games on all… _(Apple Developer; expand on demand)_

### Grouping views into a container

- [Creating custom container views](https://developer.apple.com/documentation/swiftui/creating-custom-container-views) — Access individual subviews to compose flexible container views. _(Apple Developer; expand on demand)_
- [GroupElementsOfContent](https://developer.apple.com/documentation/swiftui/groupelementsofcontent) — Transforms the subviews of a given view into a resulting content view. _(Apple Developer; expand on demand)_
- [GroupSectionsOfContent](https://developer.apple.com/documentation/swiftui/groupsectionsofcontent) — Transforms the sections of a given view into a resulting content view. _(Apple Developer; expand on demand)_

### Organizing views into sections

- [Section](https://developer.apple.com/documentation/swiftui/section) — A container view that you can use to add hierarchy within certain views. _(Apple Developer; expand on demand)_
- [SectionCollection](https://developer.apple.com/documentation/swiftui/sectioncollection) — An opaque collection representing the sections of view. _(Apple Developer; expand on demand)_
- [SectionConfiguration](https://developer.apple.com/documentation/swiftui/sectionconfiguration) — Specifies the contents of a section. _(Apple Developer; expand on demand)_

### Iterating over dynamic data

- [ForEach](https://developer.apple.com/documentation/swiftui/foreach) — A structure that computes views on demand from an underlying collection of identified data. _(Apple Developer; expand on demand)_
- [ForEachSectionCollection](https://developer.apple.com/documentation/swiftui/foreachsectioncollection) — A collection which allows a view to be treated as a collection of its sections in a for each loop. _(Apple Developer; expand on demand)_
- [ForEachSubviewCollection](https://developer.apple.com/documentation/swiftui/foreachsubviewcollection) — A collection which allows a view to be treated as a collection of its subviews in a for each loop. _(Apple Developer; expand on demand)_
- [DynamicViewContent](https://developer.apple.com/documentation/swiftui/dynamicviewcontent) — A type of view that generates views from an underlying collection of data. _(Apple Developer; expand on demand)_

### Accessing a container’s subviews

- [Subview](https://developer.apple.com/documentation/swiftui/subview) — An opaque value representing a subview of another view. _(Apple Developer; expand on demand)_
- [SubviewsCollection](https://developer.apple.com/documentation/swiftui/subviewscollection) — An opaque collection representing the subviews of view. _(Apple Developer; expand on demand)_
- [SubviewsCollectionSlice](https://developer.apple.com/documentation/swiftui/subviewscollectionslice) — A slice of a SubviewsCollection. _(Apple Developer; expand on demand)_
- [containerValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/containervalue(_:_:)) — Sets a particular container value of a view. _(Apple Developer; expand on demand)_
- [ContainerValues](https://developer.apple.com/documentation/swiftui/containervalues) — A collection of container values associated with a given view. _(Apple Developer; expand on demand)_
- [ContainerValueKey](https://developer.apple.com/documentation/swiftui/containervaluekey) — A key for accessing container values. _(Apple Developer; expand on demand)_

### Grouping views into a box

- [GroupBox](https://developer.apple.com/documentation/swiftui/groupbox) — A stylized view, with an optional label, that visually collects a logical grouping of content. _(Apple Developer; expand on demand)_
- [groupBoxStyle(_:)](https://developer.apple.com/documentation/swiftui/view/groupboxstyle(_:)) — Sets the style for group boxes within this view. _(Apple Developer; expand on demand)_

### Grouping inputs

- [formStyle(_:)](https://developer.apple.com/documentation/swiftui/view/formstyle(_:)) — Sets the style for forms in a view hierarchy. _(Apple Developer; expand on demand)_
- [LabeledContent](https://developer.apple.com/documentation/swiftui/labeledcontent) — A container for attaching a label to a value-bearing view. _(Apple Developer; expand on demand)_
- [labeledContentStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labeledcontentstyle(_:)) — Sets a style for labeled content. _(Apple Developer; expand on demand)_

### Presenting a group of controls

- [ControlGroup](https://developer.apple.com/documentation/swiftui/controlgroup) — A container view that displays semantically-related controls in a visually-appropriate manner for the context _(Apple Developer; expand on demand)_
- [controlGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/controlgroupstyle(_:)) — Sets the style for control groups within this view. _(Apple Developer; expand on demand)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(local context)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(local context)_
- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(local context)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(local context)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(local context)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view-groupings)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `a8b76666f73b615f6037888894eb7b6386f6563b588b7da9ba36bfd6ce8d989b`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
