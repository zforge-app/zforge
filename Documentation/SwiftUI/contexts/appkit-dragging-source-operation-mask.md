---
title: "draggingSourceOperationMask"
source_url: "https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsourceoperationmask"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingInfo/draggingSourceOperationMask"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "a719c5e7a53379626f3030d28497f24610e5d177c22a20610439bc257d0472b7"
source_etag: "\"73ea-659026d849472\""
source_last_modified: "Fri, 14 Aug 2026 14:13:42 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# draggingSourceOperationMask

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS; signature validated at SDK macOS 27.0. The capture does not inform the introduction version.
- Declaration: `@ MainActor   var   draggingSourceOperationMask :  NSDragOperation  {  get  }`

## Summary

The destination consults the mask announced by the origin. When modifiers are processed by the system, Option chooses copy, Command drive and the combination creates link. The source can disable this translation by ignoreModifierKeys(for:).

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — Apple Developer; expand on demand.
- [NSDragOperationNone](https://developer.apple.com/documentation/appkit/nsdragoperation/nsdragoperationnone) — Apple Developer; expand on demand.
- [NSDragOperation](https://developer.apple.com/documentation/appkit/nsdragoperation) — Apple Developer; expand on demand.
- [NSDraggingInfo](https://developer.apple.com/documentation/appkit/nsdragginginfo) — Apple Developer; expand on demand.
- [NSDraggingSource](https://developer.apple.com/documentation/appkit/nsdraggingsource) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [copy](https://developer.apple.com/documentation/appkit/nsdragoperation/copy) — Apple Developer; expand on demand.
- [draggingDestinationWindow](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingdestinationwindow) — Apple Developer; expand on demand.
- [draggingLocation](https://developer.apple.com/documentation/appkit/nsdragginginfo/dragginglocation) — Apple Developer; expand on demand.
- [draggingPasteboard](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingpasteboard) — Apple Developer; expand on demand.
- [draggingSequenceNumber](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsequencenumber) — Apple Developer; expand on demand.
- [draggingSession(_:sourceOperationMaskFor:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)) — Apple Developer; expand on demand.
- [draggingSource](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsource) — Apple Developer; expand on demand.
- [ignoreModifierKeys(for:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/ignoremodifierkeys(for:)) — Apple Developer; expand on demand.
- [link](https://developer.apple.com/documentation/appkit/nsdragoperation/link) — Apple Developer; expand on demand.
- [move](https://developer.apple.com/documentation/appkit/nsdragoperation/move) — Apple Developer; expand on demand.
- [namesOfPromisedFilesDropped(atDestination:)](https://developer.apple.com/documentation/appkit/nsdragginginfo/namesofpromisedfilesdropped(atdestination:)) — Apple Developer; expand on demand.
- [numberOfValidItemsForDrop](https://developer.apple.com/documentation/appkit/nsdragginginfo/numberofvaliditemsfordrop) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsourceoperationmask).
- Captured: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `a719c5e7a53379626f3030d28497f24610e5d177c22a20610439bc257d0472b7`.
- Scope: one page; secondary links not covered.
