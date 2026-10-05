---
title: "init(size:flipped:drawingHandler:)"
source_url: "https://developer.apple.com/documentation/appkit/nsimage/init(size:flipped:drawinghandler:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSImage/init(size:flipped:drawingHandler:)"
captured_at: "2026-07-22T23:47:15Z"
source_sha256: "bedbe97d1088e42fbec356508312ac39e036285757dc0a3c46d5f728b23f58a5"
source_etag: "W/\"785f8cebc910c90c93b19d36acbaf1b6\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Drawing and graphics"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# init(size:flipped:drawingHandler:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: `NSImage` initializer whose representation redraws the content on demand.
- Module: AppKit.
- Relevance to Zforge: direta; allows composing the non-empty folder indicator without rasterizing it in fixed resolution.
- Availability: macOS.
- Declaration: `convenience init(size: NSSize, flipped: Bool, drawingHandler: @escaping (NSRect) -> Bool)`

## Summary

Apple guides use this boot to generate correct images in any resolution. The `NSImage` keeps a `NSCustomImageRep` with the drawing block and executes it only when the image needs to be drawn. If the pixel density or color space of the destination context changes, AppKit discards the corresponding cache and executes the block again; a standard screen transition to Retina is the explicit example of the documentation.

The rectangle provided to the block is measured in points. The block can be executed in the thread that draws the image, so the captured state needs to admit this use.

## Practical implications

- Not use `lockFocus()` to produce the composition, because it creates a rasterization dependent on the resolution of the context at that time.
- Describe sheet, clipping and new application of the folder face within `drawingHandler`, using the destination rectangle received.
- Keep `NSImage` returned by `NSWorkspace` as base layer; the AppKit selects the appropriate representation to the destination context when the block is executed.

## Content map

- Signature, point size and context orientation.
- Late execution and block requirements.
- Cache by pixel density and color space.
- Recommended use with vector content and rasterized images.

## Second-level links

### Representation and cache

- [NSCustomImageRep](https://developer.apple.com/documentation/appkit/nscustomimagerep) — _Apple Developer; expand on demand_
- [NSImage.cacheMode](https://developer.apple.com/documentation/appkit/nsimage/cachemode-swift.property) — _Apple Developer; expand on demand_
- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsimage/init(size:flipped:drawinghandler:))
- Captured: `2026-07-22T23:47:15Z`
- Payload SHA-256: `bedbe97d1088e42fbec356508312ac39e036285757dc0a3c46d5f728b23f58a5`
- Scope: one page; the above absolute links have not yet been covered.
