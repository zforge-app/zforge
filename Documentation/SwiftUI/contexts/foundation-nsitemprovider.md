---
title: "NSItemProvider"
source_url: "https://developer.apple.com/documentation/foundation/nsitemprovider"
source_identifier: "doc://com.apple.foundation/documentation/Foundation/NSItemProvider"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "d497a61d31294da0fbf6e42981f82efec2fe5be095e0d1842dbf32c7bb3c0d33"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSItemProvider

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Scroll: data transport class and files between processes
- Module: Foundation
- Relevance to Zforge: direct to drag and drop and copy/fold file URLs
- Availability: macOS 10.10+
- Declaration: `class NSItemProvider`

## Summary

`NSItemProvider` carries data or files in drag and drop, copy/paste and extensions. A provider may publish representations of files, data or objects and the consumer shall request a compatible representation.

`init(contentsOf:)` creates a provider supported by an existing file. `init(object:)` uses identifiers provided by an object that conforms to `NSItemProviderWriting`; `NSURL` is one of these types and publishes URL representations. `loadObject(ofClass:completionHandler:)` is the corresponding path to recover an object from a registered class.

## Practical implications

- For file operations, the provider and the consumer must agree on `public.file-url` or on the `NSURL` object contract.
- The completion of loading may occur later and outside the main queue; UI updates must return to mainqueue or `MainActor`.
- The specific time constraints of the drop are defined by `DropDelegate.performDrop(info:)`.

## Content map

- Creating an item provider
- Registering data, files and objects
- Loading representations
- Content types and visibility

## Second-level links

### Creation and consumption

- [init(object:)](https://developer.apple.com/documentation/foundation/nsitemprovider/init(object:)) — cria a provider a partir de `NSItemProviderWriting`. _Apple Developer; expand on demand_
- [init(contentsOf:)](https://developer.apple.com/documentation/foundation/nsitemprovider/init(contentsof:)) — provides content supported by a file. _Apple Developer; expand on demand_
- [loadObject(ofClass:completionHandler:)](https://developer.apple.com/documentation/foundation/nsitemprovider/loadobject(ofclass:completionhandler:)-6pysm) — asynchronously loads an object of the requested class. _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/foundation/nsitemprovider)
- Captured: `2026-07-20T02:07:43Z`
- Payload SHA-256: `d497a61d31294da0fbf6e42981f82efec2fe5be095e0d1842dbf32c7bb3c0d33`
- Scope: one page; the above absolute links have not yet been covered.
