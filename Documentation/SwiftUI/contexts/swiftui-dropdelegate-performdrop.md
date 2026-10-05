---
title: "performDrop(info:)"
source_url: "https://developer.apple.com/documentation/swiftui/dropdelegate/performdrop(info:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/DropDelegate/performDrop(info:)"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "3db5711d2cafc098fb699efb050de5cb7f70d84885882445646c97fa52361934"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# performDrop(info:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Roll: mandatory method of `DropDelegate`
- Module: SwiftUI
- Relevance to Zforge: direct to consume URLs and perform copying, moving or creating aliases after a drop
- Availability: macOS 10.15+
- Declaration: `func performDrop(info: DropInfo) -> Bool`

## Summary

The method informs that the delegate can request the data of the item providers present in `DropInfo` and must return if accepted the drop. The incorporation of the data into the application model is the responsibility of the delegate.

Apple requires loading `NSItemProvider` within the scope of `performDrop(info:)`. The conclusion may occur later, but transferring the load call itself to another `Task` or actor is too late: for safety, the receiver may lose access to payload when the method returns.

## Practical implications

- Call `loadObject`, `loadDataRepresentation` or equivalent API before `performDrop(info:)` returns.
- Only the completion treatment and subsequent file operation must be asynchronous.
- Return `true` only when the drop has been accepted and the loads have been initiated.

## Content map

- Declaration
- Return value
- Discussion

## Second-level links

### Related types

- [DropInfo](https://developer.apple.com/documentation/swiftui/dropinfo) — current drop status and its providers item. _Apple Developer; expand on demand_
- [DropDelegate](https://developer.apple.com/documentation/swiftui/dropdelegate) — complete drop destination protocol. _Apple Developer; expand on demand_
- [NSItemProvider](foundation-nsitemprovider.md) — transport of URLs and file representations. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/dropdelegate/performdrop(info:))
- Captured: `2026-07-20T02:07:43Z`
- Payload SHA-256: `3db5711d2cafc098fb699efb050de5cb7f70d84885882445646c97fa52361934`
- Scope: one page; the above absolute links have not yet been covered.
