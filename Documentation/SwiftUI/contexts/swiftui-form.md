---
title: "Form"
source_url: "https://developer.apple.com/documentation/swiftui/form"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Form"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "3776ceb73e7400e3f65833673a3aea06e47de6e192e86fb0f706e910f6864f98"
source_etag: "\"41aa-659025e844438\""
source_last_modified: "Fri, 14 Aug 2026 14:09:30 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Form

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Structure
- Module: SwiftUI
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- Declaration: `nonisolated struct Form<Content> where Content : View`

## Summary

**Official summary:** A container for grouping controls used for data entry, such as in settings or inspectors.

SwiftUI applies platform-appropriate styling to views contained inside a form, to group them together. Form-specific styling applies to things like buttons, toggles, labels, lists, and more. Keep in mind that these stylings may be platform-specific. For example, forms appear as grouped lists on iOS, and as aligned vertical stacks on macOS. The following example shows a simple data entry form on iOS, grouped into two sections. The supporting types ( and ) and state variables (, , , and ) are omitted for simplicity. On macOS, a similar form renders as a vertical stack. To adhere to macOS platform conventions, this version doesn’t use sections, and uses colons at the end of its labels. It also sets the picker to use the inline style, which produces radio buttons on macOS.

## Practical implications

- The macOS Form has vertical stack appearance aligned and uses its own conventions; it does not establish a general prohibition on labels above controls in a custom accessory.
- A label VStack and Picker composition allows the proposed density, provided that use native controls and associate the label for accessibility.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [inline](https://developer.apple.com/documentation/swiftui/pickerstyle/inline) — A where each option is displayed inline with other views in the current container. _(Apple Developer; expand on demand)_

### Creating a form

- [init(content:)](https://developer.apple.com/documentation/swiftui/form/init(content:)) — Creates a form with the provided content. _(Apple Developer; expand on demand)_

### Creating a form from a configuration

- [init(_:)](https://developer.apple.com/documentation/swiftui/form/init(_:)) — Creates a form based on a form style configuration. _(Apple Developer; expand on demand)_

### Grouping inputs

- [formStyle(_:)](https://developer.apple.com/documentation/swiftui/view/formstyle(_:)) — Sets the style for forms in a view hierarchy. _(Apple Developer; expand on demand)_
- [LabeledContent](https://developer.apple.com/documentation/swiftui/labeledcontent) — A container for attaching a label to a value-bearing view. _(Apple Developer; expand on demand)_
- [labeledContentStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labeledcontentstyle(_:)) — Sets a style for labeled content. _(Apple Developer; expand on demand)_

### Conforms To

- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/form)
- Captured: `2026-09-28T23:25:02+00:00`
- Payload SHA-256: `3776ceb73e7400e3f65833673a3aea06e47de6e192e86fb0f706e910f6864f98`
- Scope: expansion on demand of a page; absolute links above have not yet been covered.
