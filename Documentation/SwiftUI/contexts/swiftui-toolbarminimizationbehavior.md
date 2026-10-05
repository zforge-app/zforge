---
title: "ToolbarMinimizationBehavior"
source_url: "https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/ToolbarMinimizationBehavior"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "3ebbaaf225b2015b886bb868609918fa3fa3cd7fb760a07e5e6ab44ed4d86ef5"
source_etag: "W/\"7ef6ee3d09d001fbf6eb5c65f17aadb8\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Structures"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# ToolbarMinimizationBehavior

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Structure
- Module: SwiftUI
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 27.0+ (beta), iPadOS 27.0+ (beta), Mac Catalyst 27.0+ (beta), macOS 27.0+ (beta), tvOS 27.0+ (beta), visionOS 27.0+ (beta), watchOS 27.0+ (beta)
- Declaration: `struct ToolbarMinimizationBehavior`

## Summary

**Official summary:** The minimization behavior of a toolbar.

Use this type with the toolbarMinimizationBehavior(_:for:) modifier to control how toolbars minimize in response to scrolling. On iOS, you can minimize the navigation bar using onScrollDown or onScrollUp:

## Content map

- Overview

## Second-level links

### Overview and featured references

- [toolbarMinimizationBehavior(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)) — Sets the minimize behavior for the specified bars. _(Apple Developer; expand on demand)_
- [onScrollDown](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior/onscrolldown) — Minimize when scrolling down. _(Apple Developer; expand on demand)_
- [onScrollUp](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior/onscrollup) — Minimize when scrolling up. _(Apple Developer; expand on demand)_

### Type Properties

- [automatic](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior/automatic) — The system determines the minimize behavior. By default, navigation bars on iOS will minimize when the view has a searchable using the toolbarPrincipal placement. _(Apple Developer; expand on demand)_
- [never](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior/never) — The toolbar cannot be minimized. _(Apple Developer; expand on demand)_

### Conforms To

- [Equatable](https://developer.apple.com/documentation/Swift/Equatable) — A type that can be compared for value equality. _(Apple Developer; expand on demand)_
- [Hashable](https://developer.apple.com/documentation/Swift/Hashable) — A type that can be hashed into a `Hasher` to produce an integer hash value. _(Apple Developer; expand on demand)_
- [Sendable](https://developer.apple.com/documentation/Swift/Sendable) — A thread-safe type whose values can be shared across arbitrary concurrent contexts without introducing a risk of data races. _(Apple Developer; expand on demand)_
- [SendableMetatype](https://developer.apple.com/documentation/Swift/SendableMetatype) — A type whose metatype can be shared across arbitrary isolation domains without introducing a risk of data races. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/toolbarminimizationbehavior)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `3ebbaaf225b2015b886bb868609918fa3fa3cd7fb760a07e5e6ab44ed4d86ef5`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
