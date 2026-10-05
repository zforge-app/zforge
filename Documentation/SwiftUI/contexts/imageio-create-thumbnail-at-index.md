---
title: "CGImageSourceCreateThumbnailAtIndex(_:_:_:)"
source_url: "https://developer.apple.com/documentation/imageio/cgimagesourcecreatethumbnailatindex(_:_:_:)"
source_identifier: "doc://com.apple.imageio/documentation/ImageIO/CGImageSourceCreateThumbnailAtIndex(_:_:_:)"
captured_at: "2026-10-05T16:33:37.254423+00:00"
source_sha256: "6f64e587fb2efdf41f122cd94f3805a82cf1a27863718b650501b96f1c118daf"
source_etag: "\"5b38-659028487ea62\""
source_last_modified: "Fri, 14 Aug 2026 14:20:08 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Icon previews"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# CGImageSourceCreateThumbnailAtIndex(_:_:_:)

## Quick reference

- Module: Image I/O
- Availability recorded by the source: iOS 4.0, iPadOS 4.0, Mac Catalyst 13.1, macOS 10.4, tvOS 9.0, visionOS 1.0, watchOS 2.0.
- Zforge SDK verification: Xcode 27.0, macOS SDK 27.0, arm64; application target macOS 26.0.
- Declaration: `func CGImageSourceCreateThumbnailAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage?`

## Summary and practical implications

Create a thumbnail directly from an image source and an options dictionary. Zforge requests a maximum pixel dimension and orientation transform, instead of decoding an unrestricted display image.

## Content map

Declaration and discussion.

## Second-level links

- [CFDictionary](https://developer.apple.com/documentation/corefoundation/cfdictionary) — _Apple Developer; expand on demand_
- [CGImageRelease](https://developer.apple.com/documentation/coregraphics/cgimagerelease) — _Apple Developer; expand on demand_
- [CGImageSourceCreateImageAtIndex(_:_:_:)](https://developer.apple.com/documentation/imageio/cgimagesourcecreateimageatindex(_:_:_:)) — _Apple Developer; expand on demand_
- [CGImageSourceCreateThumbnailAtIndex(_:_:_:)](https://developer.apple.com/documentation/imageio/cgimagesourcecreatethumbnailatindex(_:_:_:)) — _Apple Developer; expand on demand_
- [CGImageSourceGetPrimaryImageIndex(_:)](https://developer.apple.com/documentation/imageio/cgimagesourcegetprimaryimageindex(_:)) — _Apple Developer; expand on demand_
- [CGImageSource](https://developer.apple.com/documentation/imageio/cgimagesource) — _Apple Developer; expand on demand_
- [CGImage](https://developer.apple.com/documentation/coregraphics/cgimage) — _Apple Developer; expand on demand_
- [Image I/O](https://developer.apple.com/documentation/imageio) — _Apple Developer; expand on demand_
- [Int](https://developer.apple.com/documentation/swift/int) — _Apple Developer; expand on demand_
- [kCGImageSourceCreateThumbnailFromImageAlways](https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailfromimagealways) — _Apple Developer; expand on demand_
- [kCGImageSourceCreateThumbnailFromImageIfAbsent](https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailfromimageifabsent) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/imageio/cgimagesourcecreatethumbnailatindex(_:_:_:))
- Captured: `2026-10-05T16:33:37.254423+00:00`
- Payload SHA-256: `6f64e587fb2efdf41f122cd94f3805a82cf1a27863718b650501b96f1c118daf`
- Scope: one page; secondary links were not traversed.
