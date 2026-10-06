---
title: "CTFramesetterCreateFrame(_:_:_:_:)"
source_url: "https://developer.apple.com/documentation/coretext/ctframesettercreateframe(_:_:_:_:)"
source_identifier: "doc://com.apple.coretext/documentation/CoreText/CTFramesetterCreateFrame(_:_:_:_:)"
captured_at: "2026-10-05T16:33:38.931507+00:00"
source_sha256: "78ce6031e8f838b04a1cc982423f20b565dc9a3a3dde3eb715fc1c24141729e5"
source_etag: "\"4ebc-659024d1c8bf8\""
source_last_modified: "Fri, 14 Aug 2026 14:04:38 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Icon previews"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# CTFramesetterCreateFrame(_:_:_:_:)

## Quick reference

- Module: Core Text
- Availability recorded by the source: iOS 3.2, iPadOS 3.2, Mac Catalyst 13.1, macOS 10.5, tvOS 9.0, visionOS 1.0, watchOS 2.0.
- Zforge SDK verification: Xcode 27.0, macOS SDK 27.0, arm64; application target macOS 26.0.
- Declaration: `func CTFramesetterCreateFrame(_ framesetter: CTFramesetter, _ stringRange: CFRange, _ path: CGPath, _ frameAttributes: CFDictionary?) -> CTFrame`

## Summary and practical implications

Create a layout frame from attributed text and a path. Zforge reads only the existing preview buffer, lays it out in a small page bitmap, and keeps text rendering outside the main actor.

## Content map

Declaration and discussion.

## Second-level links

- [CFDictionary](https://developer.apple.com/documentation/corefoundation/cfdictionary) — _Apple Developer; expand on demand_
- [CFRange](https://developer.apple.com/documentation/corefoundation/cfrange) — _Apple Developer; expand on demand_
- [CGPath](https://developer.apple.com/documentation/coregraphics/cgpath) — _Apple Developer; expand on demand_
- [CTFrame](https://developer.apple.com/documentation/coretext/ctframe) — _Apple Developer; expand on demand_
- [CTFramesetterCreateFrame(_:_:_:_:)](https://developer.apple.com/documentation/coretext/ctframesettercreateframe(_:_:_:_:)) — _Apple Developer; expand on demand_
- [CTFramesetterGetTypesetter(_:)](https://developer.apple.com/documentation/coretext/ctframesettergettypesetter(_:)) — _Apple Developer; expand on demand_
- [CTFramesetter](https://developer.apple.com/documentation/coretext/ctframesetter) — _Apple Developer; expand on demand_
- [Core Text](https://developer.apple.com/documentation/coretext) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/coretext/ctframesettercreateframe(_:_:_:_:))
- Captured: `2026-10-05T16:33:38.931507+00:00`
- Payload SHA-256: `78ce6031e8f838b04a1cc982423f20b565dc9a3a3dde3eb715fc1c24141729e5`
- Scope: one page; secondary links were not traversed.
