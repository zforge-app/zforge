---
title: "FileRepresentation"
source_url: "https://developer.apple.com/documentation/coretransferable/filerepresentation"
source_identifier: "doc://com.apple.CoreTransferable/documentation/CoreTransferable/FileRepresentation"
captured_at: "2026-10-04T22:10:19.050472+00:00"
source_sha256: "5e26a298d6c662bc828b8d3bc4750d25a1afa6defb0b7d4f64be04398ae21ed8"
source_etag: "\"46ed-659029bae6b26\""
source_last_modified: null
source_format: "application/json"
platforms: [{"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "iOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "iPadOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "Mac Catalyst", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "13.0", "name": "macOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "tvOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "1.0", "name": "visionOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "9.0", "name": "watchOS", "unavailable": false}]
authority: "Apple Developer"
confidence: "primary-source"
---

# FileRepresentation

## Summary

Transferable export provides a file and allows you to represent content per file. It does not equal the final destination of a promise NSFilePromiseProvider; the Zforge needs the exact URL provided by the receiver to confirm before writing and coordinating source removal.

## Declaration

```swift
struct FileRepresentation<Item> where Item : Transferable
```

## Content map

- declarations
- mentions
- content

## Secondary links

- [Choosing a transfer representation for a model type](https://developer.apple.com/documentation/coretransferable/choosing-a-transfer-representation-for-a-model-type) — expand on demand.
- [Core Transferable](https://developer.apple.com/documentation/coretransferable) — expand on demand.
- [ReceivedTransferredFile](https://developer.apple.com/documentation/coretransferable/receivedtransferredfile) — expand on demand.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — expand on demand.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — expand on demand.
- [SentTransferredFile](https://developer.apple.com/documentation/coretransferable/senttransferredfile) — expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand.
- [TransferRepresentation](https://developer.apple.com/documentation/coretransferable/transferrepresentation) — expand on demand.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expand on demand.
- [init(contentType:shouldAttemptToOpenInPlace:exporting:importing:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(contenttype:shouldattempttoopeninplace:exporting:importing:)) — expand on demand.
- [init(exportedContentType:shouldAllowToOpenInPlace:exporting:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(exportedcontenttype:shouldallowtoopeninplace:exporting:)) — expand on demand.
- [init(importedContentType:shouldAttemptToOpenInPlace:importing:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(importedcontenttype:shouldattempttoopeninplace:importing:)) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/coretransferable/filerepresentation).
- Capture of a page, without going through secondary links. SDK consulted: macOS 27.0, Xcode local.
