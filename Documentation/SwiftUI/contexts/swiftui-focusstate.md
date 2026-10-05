---
title: "FocusState"
source_url: "https://developer.apple.com/documentation/swiftui/focusstate"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/FocusState"
captured_at: "2026-07-19T00:24:22+00:00"
source_sha256: "1c22c2f51ca851696edd2494294a6af7cfb7ff4de6b0ecbb92ad0b94876082d6"
source_etag: "W/\"f3760b7b8936f022ed3abf9a929a9548\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# FocusState

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Structure and property wrapper
- Module: SwiftUI
- Relevance to Zforge: direct to distinguish the persistent focus of the browser area from the temporary focus of the name editor.
- Availability: macOS 12.0 or later; also available on the other platforms SwiftUI indicated by Apple.
- Declaration: `@frozen @propertyWrapper struct FocusState<Value> where Value: Hashable`

## Summary

`FocusState` maintains a value that accompanies the focus position on the scene. Associate views by `focused(_:equals:)` allows representing distinct destinations with a single optional value and `Hashable`; assign this value programmatically moves the focus to the corresponding view.

Apple points out that ambiguous bindings produce indistinguishable candidates. In hierarchies with a focusable container and an internal field, two independent Boolean states also have different semantics: the container Boolean may indicate both that it received focus and that it contains a focused descendant. A single typed state, with separate cases for container and field, offers granular control and unambiguous destinations.

## Practical implications

- Model the persistent browser area and each inline editor as different cases from a single optional `FocusState`.
- Use `focused(_:equals:)` in container and `TextField`, programmatically assigning the case of the item to be renamed.
- Do not reuse the same focus value in two views simultaneously; SwiftUI can choose a candidate and issue warning in runtime.
- Use `nil` to represent total absence of focus and explicitly restore the content case when editing is finished.

## Content map

- Overview
- Avoid ambiguous focus bindings
- Nest focusable views
- Creating a focus state
- Inspecting the focus state

## Second-level links

### Related APIs

- [focused(_:equals:)](https://developer.apple.com/documentation/swiftui/view/focused(_:equals:)) — associates a view to a specific focus state value. _Apple Developer; expand on demand_
- [focused(_:)](https://developer.apple.com/documentation/swiftui/view/focused(_:)) — associates a view to a boolean state that may also indicate contained focus. _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/focusstate)
- Captured: `2026-07-19T00:24:22+00:00`
- Payload SHA-256: `1c22c2f51ca851696edd2494294a6af7cfb7ff4de6b0ecbb92ad0b94876082d6`
- Scope: an official page expanded on demand; the above absolute links have not yet been covered.
