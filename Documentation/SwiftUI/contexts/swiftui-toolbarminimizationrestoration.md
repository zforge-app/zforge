---
title: "ToolbarMinimizationRestoration"
source_url: "https://developer.apple.com/documentation/swiftui/toolbarminimizationrestoration"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/ToolbarMinimizationRestoration"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "14d6d7461c34058c702ac7d92615e733e6e4996b9c73397530ec6bea3de2eb61"
source_etag: "W/\"c8c761e4b6bfc0973e3f8eb1717f0174\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Structures"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# ToolbarMinimizationRestoration

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Structure
- Module: SwiftUI
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 27.0+ (beta), iPadOS 27.0+ (beta), Mac Catalyst 27.0+ (beta), macOS 27.0+ (beta), tvOS 27.0+ (beta), visionOS 27.0+ (beta), watchOS 27.0+ (beta)
- Declaration: `struct ToolbarMinimizationRestoration`

## Summary

**Official summary:** The restoration behavior during toolbar minimization.

Use this type with the toolbarMinimizationRestoration(_:for:) modifier to control when a minimized toolbar restores. By default the toolbar restores when the user reverses scroll direction; with atScrollEdge, the toolbar instead restores only when the scroll view’s content reaches the scroll edge – appropriate for screens where the bar is mostly chrome that doesn’t need to follow the user.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [toolbarMinimizationRestoration(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationrestoration(_:for:)) — Sets the restoration behavior for the specified bars during minimization. _(Apple Developer; expand on demand)_
- [atScrollEdge](https://developer.apple.com/documentation/swiftui/toolbarminimizationrestoration/atscrolledge) — The toolbar restores only when the scroll view’s content reaches the scroll edge. _(Apple Developer; expand on demand)_

### Type Properties

- [automatic](https://developer.apple.com/documentation/swiftui/toolbarminimizationrestoration/automatic) — The system determines the restoration behavior. _(Apple Developer; expand on demand)_

### Conforms To

- [Equatable](https://developer.apple.com/documentation/Swift/Equatable) — A type that can be compared for value equality. _(Apple Developer; expand on demand)_
- [Hashable](https://developer.apple.com/documentation/Swift/Hashable) — A type that can be hashed into a `Hasher` to produce an integer hash value. _(Apple Developer; expand on demand)_
- [Sendable](https://developer.apple.com/documentation/Swift/Sendable) — A thread-safe type whose values can be shared across arbitrary concurrent contexts without introducing a risk of data races. _(Apple Developer; expand on demand)_
- [SendableMetatype](https://developer.apple.com/documentation/Swift/SendableMetatype) — A type whose metatype can be shared across arbitrary isolation domains without introducing a risk of data races. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/toolbarminimizationrestoration)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `14d6d7461c34058c702ac7d92615e733e6e4996b9c73397530ec6bea3de2eb61`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
