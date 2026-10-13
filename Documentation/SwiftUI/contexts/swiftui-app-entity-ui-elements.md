---
title: "appEntityUIElements(_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/appentityuielements(_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/appEntityUIElements(_:)"
captured_at: "2026-10-11T21:45:42.073511+00:00"
source_sha256: "3908f83fa502a33da272d6d6bebd9a2a176fb95b2758b826d113d3c2f31ed3da"
source_etag: '"4d46-65b79169fcae0"'
source_last_modified: "Mon, 14 Sep 2026 22:38:09 GMT"
source_format: "application/json"
depth: 3
categories: ["On-demand native context diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# appEntityUIElements(_:)

## Quick reference

- Module: AppIntents
- Availability: iOS 18.4+, iPadOS 18.4+, Mac Catalyst 18.4+, macOS 15.4+, tvOS 18.4+, visionOS 2.4+, watchOS 11.4+
- Declaration: `nonisolated func appEntityUIElements(_ provider: @escaping @MainActor (AppEntityUIElementsContext) -> [AppEntityUIElement]) -> some View`

## Summary

A provider supplies wrappers, bounds and selection state for custom drawn content. Standard SwiftUI views use appEntityIdentifier. The closure can filter visible and selected requests; return ordering does not imply visual order. Use actual view geometry and retain the shared cached entity identity.

## Secondary references

- [App Intents](https://developer.apple.com/documentation/appintents) — primary reference; expand on demand.
- [AppEntityUIElement](https://developer.apple.com/documentation/appintents/appentityuielement) — primary reference; expand on demand.
- [AppEntityUIElementsContext](https://developer.apple.com/documentation/appintents/appentityuielementscontext) — primary reference; expand on demand.
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — primary reference; expand on demand.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — primary reference; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — primary reference; expand on demand.
- [View](https://developer.apple.com/documentation/swiftui/view) — primary reference; expand on demand.
- [appEntityIdentifier(_:)](swiftui-app-entity-identifier.md) — primary reference; expand on demand.
- [appEntityIdentifier(forSelectionType:identifier:)](https://developer.apple.com/documentation/swiftui/view/appentityidentifier(forselectiontype:identifier:)) — primary reference; expand on demand.
- [onAppIntentExecution(_:perform:)](https://developer.apple.com/documentation/swiftui/view/onappintentexecution(_:perform:)) — primary reference; expand on demand.
- [shortcutsLinkStyle(_:)](https://developer.apple.com/documentation/swiftui/view/shortcutslinkstyle(_:)) — primary reference; expand on demand.
- [siriTipViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/siritipviewstyle(_:)) — primary reference; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/appentityuielements(_:))
- Captured: `2026-10-11T21:45:42.073511+00:00`
- Payload SHA-256: `3908f83fa502a33da272d6d6bebd9a2a176fb95b2758b826d113d3c2f31ed3da`
- Scope: one directly consulted page; secondary links remain unvisited. No assets are downloaded.
