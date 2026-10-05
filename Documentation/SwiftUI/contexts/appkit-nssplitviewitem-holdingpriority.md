---
title: "holdingPriority"
source_url: "https://developer.apple.com/documentation/appkit/nssplitviewitem/holdingpriority"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSSplitViewItem/holdingPriority"
captured_at: "2026-07-18T02:53:50Z"
source_sha256: "2276dea0b847f56c1cd227abe1725e8068e3923357404412ddde003074fe9892"
source_etag: "W/\"2ee660e156163d2824d880da353925ee\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# holdingPriority

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Scroll: instance property of `NSSplitViewItem`
- Module: AppKit
- Relevance to Zforge: direta; controls which panel preserves its width during the resizing of a split view in macOS.
- Availability: macOS 10.10+
- Declaration: `var holdingPriority: NSLayoutConstraint.Priority { get set }`

## Summary

Sets the priority with which an item keeps its thickness: width in a vertical split view or height in a horizontal. The item with the lowest priority is the first to receive the variation in size when the split view grows or shrinks. The pattern is `defaultLow`.

## Practical implications

- A sidebar that must maintain absolute width needs a higher priority than the content panel that must absorb the window variation.
- The priority governs automatic resizing; it does not fix the divider nor prevents the user to manually resize the item.
- In Zforge, apply the property at `NSSplitViewItem` managed by `NSSplitViewController`, preserving the limits `minimumThickness` and `maximumThickness`.
- Signature and availability confirmed also in SDK macOS 26.5 of the local Xcode.

## Content map

- Declaration
- Discussion
- Auto Layout related APIs

## Second-level links

### Types and related properties

- [NSSplitViewItem](https://developer.apple.com/documentation/appkit/nssplitviewitem) — _Apple Developer; expand on demand_
- [NSLayoutConstraint.Priority](https://developer.apple.com/documentation/appkit/nslayoutconstraint/priority-swift.struct) — _Apple Developer; expand on demand_
- [defaultLow](https://developer.apple.com/documentation/appkit/nslayoutconstraint/priority-swift.struct/defaultlow) — _Apple Developer; expand on demand_
- [automaticallyAdjustsSafeAreaInsets](https://developer.apple.com/documentation/appkit/nssplitviewitem/automaticallyadjustssafeareainsets) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nssplitviewitem/holdingpriority)
- Captured: `2026-07-18T02:53:50Z`
- Payload SHA-256: `2276dea0b847f56c1cd227abe1725e8068e3923357404412ddde003074fe9892`
- Scope: one page; the above absolute links have not yet been covered.
