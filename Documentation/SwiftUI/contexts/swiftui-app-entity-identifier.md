---
title: "appEntityIdentifier(_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/appentityidentifier(_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/appEntityIdentifier(_:)"
captured_at: "2026-10-11T21:45:42.073511+00:00"
source_sha256: "0784e0292f529cfa88efda69b53a3e4c6224878774d6a7b11380cc45093dec48"
source_etag: '"3c40-65b7916b33bea"'
source_last_modified: "Mon, 14 Sep 2026 22:38:10 GMT"
source_format: "application/json"
depth: 3
categories: ["On-demand native context diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# appEntityIdentifier(_:)

## Quick reference

- Module: AppIntents
- Availability: iOS 18.4+, iPadOS 18.4+, Mac Catalyst 18.4+, macOS 15.4+, tvOS 18.4+, visionOS 2.4+, watchOS 11.4+
- Declaration: `nonisolated func appEntityIdentifier(_ identifier: EntityIdentifier?) -> some View`

## Summary

A standard SwiftUI view can expose one app entity by attaching its qualified identifier. Setting the association to nil removes it. Repeated modifiers on one view use the innermost association. This supplies native view annotations without enumerating or bookmarking files during layout.

## Secondary references

- [App Intents](https://developer.apple.com/documentation/appintents) — primary reference; expand on demand.
- [EntityIdentifier](https://developer.apple.com/documentation/appintents/entityidentifier) — primary reference; expand on demand.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — primary reference; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — primary reference; expand on demand.
- [View](https://developer.apple.com/documentation/swiftui/view) — primary reference; expand on demand.
- [appEntityIdentifier(forSelectionType:identifier:)](https://developer.apple.com/documentation/swiftui/view/appentityidentifier(forselectiontype:identifier:)) — primary reference; expand on demand.
- [appEntityUIElements(_:)](swiftui-app-entity-ui-elements.md) — primary reference; expand on demand.
- [onAppIntentExecution(_:perform:)](https://developer.apple.com/documentation/swiftui/view/onappintentexecution(_:perform:)) — primary reference; expand on demand.
- [shortcutsLinkStyle(_:)](https://developer.apple.com/documentation/swiftui/view/shortcutslinkstyle(_:)) — primary reference; expand on demand.
- [siriTipViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/siritipviewstyle(_:)) — primary reference; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/appentityidentifier(_:))
- Captured: `2026-10-11T21:45:42.073511+00:00`
- Payload SHA-256: `0784e0292f529cfa88efda69b53a3e4c6224878774d6a7b11380cc45093dec48`
- Scope: one directly consulted page; secondary links remain unvisited. No assets are downloaded.
