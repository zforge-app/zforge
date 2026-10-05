---
title: "draggingSession(_:sourceOperationMaskFor:)"
source_url: "https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingSource/draggingSession(_:sourceOperationMaskFor:)"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "eac28bc9fe845f196da379b8565bcf23e88f74cbe3533368db68ebb284ae0d56"
source_etag: "\"3be4-659026e43247b\""
source_last_modified: "Fri, 14 Aug 2026 14:13:54 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# draggingSession(_:sourceOperationMaskFor:)

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS 10.7+
- Declaration: `@ MainActor   func   draggingSession ( _   session :  NSDraggingSession ,  sourceOperationMaskFor   context :  NSDraggingContext ) ->  NSDragOperation`

## Summary

The source shall inform AppKit of a set of operations accepted according to the context (within or outside the application). The method returns NSDragOperation; unknown contexts must receive an explicit policy.

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — Apple Developer; expand on demand.
- [NSDragOperation](https://developer.apple.com/documentation/appkit/nsdragoperation) — Apple Developer; expand on demand.
- [NSDraggingContext](https://developer.apple.com/documentation/appkit/nsdraggingcontext) — Apple Developer; expand on demand.
- [NSDraggingSession](https://developer.apple.com/documentation/appkit/nsdraggingsession) — Apple Developer; expand on demand.
- [NSDraggingSource](https://developer.apple.com/documentation/appkit/nsdraggingsource) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)).
- Captured: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `eac28bc9fe845f196da379b8565bcf23e88f74cbe3533368db68ebb284ae0d56`.
- Scope: one page; secondary links not covered.
