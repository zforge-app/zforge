---
title: "getDrawingTransform(_:rect:rotate:preserveAspectRatio:)"
source_url: "https://developer.apple.com/documentation/coregraphics/cgpdfpage/getdrawingtransform(_:rect:rotate:preserveaspectratio:)"
source_identifier: "doc://com.apple.coregraphics/documentation/CoreGraphics/CGPDFPage/getDrawingTransform(_:rect:rotate:preserveAspectRatio:)"
captured_at: "2026-10-05T16:33:38.105322+00:00"
source_sha256: "98ef06d765b5e306e9bf8f0261e59bcea322b9917b525f25282ee7c64783e7a0"
source_etag: "\"6bfe-659023b04ab12\""
source_last_modified: "Fri, 14 Aug 2026 13:59:35 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Icon previews"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# getDrawingTransform(_:rect:rotate:preserveAspectRatio:)

## Quick reference

- Module: Core Graphics
- Availability recorded by the source: iOS 2.0, iPadOS 2.0, Mac Catalyst 13.1, macOS 10.3, tvOS , visionOS 1.0, watchOS 2.0.
- Zforge SDK verification: Xcode 27.0, macOS SDK 27.0, arm64; application target macOS 26.0.
- Declaration: `func getDrawingTransform(_ box: CGPDFBox, rect: CGRect, rotate: Int32, preserveAspectRatio: Bool) -> CGAffineTransform`

## Summary and practical implications

Obtain a transform for fitting a PDF page box into a destination rectangle. Zforge draws the first page into a bounded bitmap and retains the page aspect ratio and rotation.

## Content map

Declaration and discussion.

## Second-level links

- [Bool](https://developer.apple.com/documentation/swift/bool) — _Apple Developer; expand on demand_
- [CGAffineTransform](https://developer.apple.com/documentation/corefoundation/cgaffinetransform) — _Apple Developer; expand on demand_
- [CGPDFBox](https://developer.apple.com/documentation/coregraphics/cgpdfbox) — _Apple Developer; expand on demand_
- [CGPDFPage](https://developer.apple.com/documentation/coregraphics/cgpdfpage) — _Apple Developer; expand on demand_
- [CGRect](https://developer.apple.com/documentation/corefoundation/cgrect) — _Apple Developer; expand on demand_
- [Core Graphics](https://developer.apple.com/documentation/coregraphics) — _Apple Developer; expand on demand_
- [Int32](https://developer.apple.com/documentation/swift/int32) — _Apple Developer; expand on demand_
- [dictionary](https://developer.apple.com/documentation/coregraphics/cgpdfpage/dictionary) — _Apple Developer; expand on demand_
- [document](https://developer.apple.com/documentation/coregraphics/cgpdfpage/document) — _Apple Developer; expand on demand_
- [getBoxRect(_:)](https://developer.apple.com/documentation/coregraphics/cgpdfpage/getboxrect(_:)) — _Apple Developer; expand on demand_
- [getDrawingTransform(_:rect:rotate:preserveAspectRatio:)](https://developer.apple.com/documentation/coregraphics/cgpdfpage/getdrawingtransform(_:rect:rotate:preserveaspectratio:)) — _Apple Developer; expand on demand_
- [pageNumber](https://developer.apple.com/documentation/coregraphics/cgpdfpage/pagenumber) — _Apple Developer; expand on demand_
- [rotationAngle](https://developer.apple.com/documentation/coregraphics/cgpdfpage/rotationangle) — _Apple Developer; expand on demand_
- [true](https://developer.apple.com/documentation/swift/true) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/coregraphics/cgpdfpage/getdrawingtransform(_:rect:rotate:preserveaspectratio:))
- Captured: `2026-10-05T16:33:38.105322+00:00`
- Payload SHA-256: `98ef06d765b5e306e9bf8f0261e59bcea322b9917b525f25282ee7c64783e7a0`
- Scope: one page; secondary links were not traversed.
