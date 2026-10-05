---
title: "NSDraggingSource"
source_url: "https://developer.apple.com/documentation/appkit/nsdraggingsource"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingSource"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "9d51b11142080f08a75d66d1556b81b8e4a18722ae098638a2bea86a41f8c9f1"
source_etag: "\"6df4-659026d43a608\""
source_last_modified: "Fri, 14 Aug 2026 14:13:38 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSDraggingSource

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS; signature validated at SDK macOS 27.0. The capture does not inform the introduction version.
- Declaration: `protocol   NSDraggingSource  :  NSObjectProtocol`

## Summary

Protocol of the origin of a drag session in macOS. Defines which operations are allowed, the treatment of modifiers and callbacks of start, movement and end. The modern interface of the protocol has existed since macOS 10.7.

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [Drag and Drop](https://developer.apple.com/documentation/appkit/drag-and-drop) — Apple Developer; expand on demand.
- [NSCollectionView](https://developer.apple.com/documentation/appkit/nscollectionview) — Apple Developer; expand on demand.
- [NSDraggingImageComponent](https://developer.apple.com/documentation/appkit/nsdraggingimagecomponent) — Apple Developer; expand on demand.
- [NSDraggingItem](https://developer.apple.com/documentation/appkit/nsdraggingitem) — Apple Developer; expand on demand.
- [NSDraggingSession](https://developer.apple.com/documentation/appkit/nsdraggingsession) — Apple Developer; expand on demand.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expand on demand.
- [NSOutlineView](https://developer.apple.com/documentation/appkit/nsoutlineview) — Apple Developer; expand on demand.
- [NSTableView](https://developer.apple.com/documentation/appkit/nstableview) — Apple Developer; expand on demand.
- [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [draggingSession(_:endedAt:operation:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:endedat:operation:)) — Apple Developer; expand on demand.
- [draggingSession(_:movedTo:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:movedto:)) — Apple Developer; expand on demand.
- [draggingSession(_:sourceOperationMaskFor:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)) — Apple Developer; expand on demand.
- [draggingSession(_:willBeginAt:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:willbeginat:)) — Apple Developer; expand on demand.
- [ignoreModifierKeys(for:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/ignoremodifierkeys(for:)) — Apple Developer; expand on demand.
- [namesOfPromisedFilesDropped(atDestination:)](https://developer.apple.com/documentation/objectivec/nsobject-swift.class/namesofpromisedfilesdropped(atdestination:)) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdraggingsource).
- Captured: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `9d51b11142080f08a75d66d1556b81b8e4a18722ae098638a2bea86a41f8c9f1`.
- Scope: one page; secondary links not covered.
