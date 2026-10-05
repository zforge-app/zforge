---
title: "NSPasteboardWriting"
source_url: "https://developer.apple.com/documentation/appkit/nspasteboardwriting"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSPasteboardWriting"
captured_at: "2026-10-04T13:01:09.738317+00:00"
source_sha256: "3bd28ec45e98fedfff1a63479b43e5dff117073ee21bc4c79d2f3124e3c10f7c"
source_etag: "\"850b-659026dadbf7d\""
source_last_modified: "Fri, 14 Aug 2026 14:13:45 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSPasteboardWriting

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS; signatures found in SDK macOS 27.0
- Declaration: `protocol   NSPasteboardWriting  :  NSObjectProtocol`

## Summary

A promise represents a future archive; the auxiliary identity of the item must be given immediately on the pasteboard, with writingOptions empty. The content remains a promise and your delegate writes in the URL provided when complying with the request. The provider must have fileType and delegate set before it is written on the pasteboard.

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [NSAttributedString](https://developer.apple.com/documentation/foundation/nsattributedstring) — Apple Developer; expand on demand.
- [NSColor](https://developer.apple.com/documentation/appkit/nscolor) — Apple Developer; expand on demand.
- [NSFilePromiseProvider](appkit-nsfile-promise-provider.md) — Apple Developer; expand on demand.
- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — Apple Developer; expand on demand.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expand on demand.
- [NSPasteboard.ContentsOptions](https://developer.apple.com/documentation/appkit/nspasteboard/contentsoptions) — Apple Developer; expand on demand.
- [NSPasteboard.WritingOptions](https://developer.apple.com/documentation/appkit/nspasteboard/writingoptions) — Apple Developer; expand on demand.
- [NSPasteboardItemDataProvider](https://developer.apple.com/documentation/appkit/nspasteboarditemdataprovider) — Apple Developer; expand on demand.
- [NSPasteboardItem](https://developer.apple.com/documentation/appkit/nspasteboarditem) — Apple Developer; expand on demand.
- [NSPasteboardReading](https://developer.apple.com/documentation/appkit/nspasteboardreading) — Apple Developer; expand on demand.
- [NSPasteboardTypeOwner](https://developer.apple.com/documentation/appkit/nspasteboardtypeowner) — Apple Developer; expand on demand.
- [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard) — Apple Developer; expand on demand.
- [NSSound](https://developer.apple.com/documentation/appkit/nssound) — Apple Developer; expand on demand.
- [NSString](https://developer.apple.com/documentation/foundation/nsstring) — Apple Developer; expand on demand.
- [NSTextStorage](https://developer.apple.com/documentation/appkit/nstextstorage) — Apple Developer; expand on demand.
- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — Apple Developer; expand on demand.
- [Pasteboard Writing Options](https://developer.apple.com/documentation/appkit/pasteboard-writing-options) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [pasteboardPropertyList(forType:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/pasteboardpropertylist(fortype:)) — Apple Developer; expand on demand.
- [writableTypes(for:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/writabletypes(for:)) — Apple Developer; expand on demand.
- [writeObjects(_:)](https://developer.apple.com/documentation/appkit/nspasteboard/writeobjects(_:)) — Apple Developer; expand on demand.
- [writingOptions(forType:pasteboard:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/writingoptions(fortype:pasteboard:)) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nspasteboardwriting).
- Captured: `2026-10-04T13:01:09.738317+00:00`; SHA-256: `3bd28ec45e98fedfff1a63479b43e5dff117073ee21bc4c79d2f3124e3c10f7c`.
- Scope: one page; secondary links not covered.
