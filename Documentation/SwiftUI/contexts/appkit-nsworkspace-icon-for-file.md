---
title: "icon(forFile:)"
source_url: "https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfile:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSWorkspace/icon(forFile:)"
captured_at: "2026-07-22T23:47:15Z"
source_sha256: "20e1ae982edde88c9efefb3288a5a7dedc4360f692cf32fde6d9c03279e299f4"
source_etag: "W/\"794ad20386b359b938cbbf2b7e42a2cf\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# icon(forFile:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Scroll: `NSWorkspace` method that returns the icon associated with an existing path.
- Module: AppKit.
- Relevance to Zforge: direta; is the public source for local file icons and directories.
- Availability: macOS.
- Declaration: `func icon(forFile fullPath: String) -> NSImage`

## Summary

The method only receives the full path and returns the `NSImage` associated with the file. The returned image starts with a logical size of 32 by 32 and the call can be made safely in any thread. The API does not offer a public option, parameter or type to request visual variants based on the contents of a directory, such as the full folder state used internally by Finder.

## Practical implications

- Using `NSWorkspace.shared.icon(forFile:)` as a base preserves the icon, customizations and type recognized by the system.
- Unempted folder visual status cannot be requested by this API; `icon(for:)` returns the generic icon of a `UTType`, not a variant based on path content.
- Any additional Zforge indicator shall preserve the original `NSImage` high resolution representations and not replace the system file icon with `setIcon`.

## Content map

- Declaration and parameter of the complete path.
- Value returned.
- Initial size and security between threads.

## Second-level links

### Icons and images

- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — _Apple Developer; expand on demand_
- [icon(for:)](https://developer.apple.com/documentation/appkit/nsworkspace/icon(for:)) — _Apple Developer; expand on demand_
- [icon(forFiles:)](https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfiles:)) — _Apple Developer; expand on demand_
- [setIcon(_:forFile:options:)](https://developer.apple.com/documentation/appkit/nsworkspace/seticon(_:forfile:options:)) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfile:))
- Captured: `2026-07-22T23:47:15Z`
- Payload SHA-256: `20e1ae982edde88c9efefb3288a5a7dedc4360f692cf32fde6d9c03279e299f4`
- Scope: one page; the above absolute links have not yet been covered.
