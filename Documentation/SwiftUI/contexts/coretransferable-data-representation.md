---
title: "DataRepresentation"
source_url: "https://developer.apple.com/documentation/coretransferable/datarepresentation"
source_identifier: "doc://com.apple.CoreTransferable/documentation/CoreTransferable/DataRepresentation"
captured_at: "2026-10-03T22:58:36.198078+00:00"
source_sha256: "6ddeba931f6c773c91010a27a3f1e6106dc38e31cd728eb3754c0f414f35290a"
source_etag: "\"4455-659029bad3bff\""
source_last_modified: "Fri, 14 Aug 2026 14:26:36 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Drag and drop"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# DataRepresentation

## Quick reference

- `struct DataRepresentation<Item> where Item: Transferable` declares a byte representation identified by a UTType.
- The `init(exportedContentType:exporting:)` variant offers export only; asynchronous closure returns `Data`.
- API compiled against SDK macOS 27.0; available since macOS 13.

## Application in Zforge

The file drag exports `public.file-url` as bytes of the original absolute URL. Destination reads the location using `NSURL`/`NSItemProvider`, without turning the URL into a promised file. This format choice is from the app; the page describes the generic API, does not prove the cause of a specific regression. Check the URL decoded with the real provider and gestures in the app.

## Mapa

- Overview: bytes as interoperable format; combination of representations.
- Initializers: import/export, export and import only.

## Secondary links

- [Choosing a transfer representation for a model type](https://developer.apple.com/documentation/coretransferable/choosing-a-transfer-representation-for-a-model-type) — not consulted in this catch.
- [CodableRepresentation](https://developer.apple.com/documentation/coretransferable/codablerepresentation) — not consulted in this catch.
- [Core Transferable](https://developer.apple.com/documentation/coretransferable) — not consulted in this catch.
- [DataRepresentation](https://developer.apple.com/documentation/coretransferable/datarepresentation) — not consulted in this catch.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — not consulted in this catch.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — not consulted in this catch.
- [Technologies](https://developer.apple.com/documentation/technologies) — not consulted in this catch.
- [TransferRepresentation](https://developer.apple.com/documentation/coretransferable/transferrepresentation) — not consulted in this catch.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — not consulted in this catch.
- [init(contentType:exporting:importing:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(contenttype:exporting:importing:)) — not consulted in this catch.
- [init(exportedContentType:exporting:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(exportedcontenttype:exporting:)) — not consulted in this catch.
- [init(importedContentType:importing:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(importedcontenttype:importing:)) — not consulted in this catch.

## Provenance

- Capture of an Apple page; SHA-256 `6ddeba931f6c773c91010a27a3f1e6106dc38e31cd728eb3754c0f414f35290a`; `2026-10-03T22:58:36.198078+00:00`.
