---
title: "Xcode library customization"
source_url: "https://developer.apple.com/documentation/swiftui/xcode-library-customization"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Xcode-library-customization"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "6c7025779b9c8dc32ade70873620d314978221ed902dcbfd581a35bb93643c95"
source_etag: "W/\"010402b104451d67e670a5cb66f6b3eb\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Tool support"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Xcode library customization

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: collectionGroup
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Expose custom views and modifiers in the Xcode library.

You can add your custom SwiftUI views and view modifiers to Xcode’s library. This allows anyone developing your app or adopting your framework to access them by clicking the Library button (+) in Xcode’s toolbar. You can select and drag the custom library items into code, just like you would for system-provided items. To add items to the library, create a structure that conforms to the LibraryContentProvider protocol and encapsulate any items you want to add as LibraryItem instances. Implement the views computed property to add library items containing views. Implement the modifiers(base:) method to add items containing view modifiers. Xcode harvests items from all of the library content providers in your project as you work, and makes them available to you in its library.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [LibraryContentProvider](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider) — A source of Xcode library and code completion content. _(Apple Developer; expand on demand)_
- [LibraryItem](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryItem) — A single item to add to the Xcode library. _(Apple Developer; expand on demand)_
- [views](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider/views) — The SwiftUI views that you want to add to the Xcode library. _(Apple Developer; expand on demand)_
- [modifiers(base:)](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider/modifiers(base:)) — Indicates a collection of SwiftUI view modifiers to add to the Xcode library. _(Apple Developer; expand on demand)_

### Tool support

- [Previews in Xcode](swiftui-previews-in-xcode.md) — Generate dynamic, interactive previews of your custom views. _(local context)_
- [Performance analysis](swiftui-performance-analysis.md) — Measure and improve your app’s responsiveness. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/xcode-library-customization)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `6c7025779b9c8dc32ade70873620d314978221ed902dcbfd581a35bb93643c95`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
