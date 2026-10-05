---
title: "Supporting Drag and Drop Through File Promises"
source_url: "https://developer.apple.com/documentation/appkit/supporting-drag-and-drop-through-file-promises"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/supporting-drag-and-drop-through-file-promises"
captured_at: "2026-10-04T21:06:22.124690+00:00"
source_sha256: "ad5aea4873ea3fd5f914db6321f2c20104c4ee73964d5eddf097ed08f76a76d5"
source_etag: '"4b48-659026dbffe03"'
source_last_modified: "Fri, 14 Aug 2026 14:13:46 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Supporting Drag and Drop Through File Promises

## Summary

Official example macOS 10.15+/Xcode 13.3+: export content not yet materialized by NSFilePromiseProvider; receive promises before URLs. The receiver records NSFilePromiseReceiver.readableDraggedTypes, requests receivePromisedFiles in the chosen folder and processes the URL delivered to callback. The provider informs name, queue and writes in the exact URL requested, concluding only after writing. The background queue avoids blocking UI.

## Implications at Zforge

Do not deduce destination from the end point on the screen. Internal destinations receive virtual identity and call extraction with explicit folder; external destinations receive the promise and choose the URL. Remove from archive only after successful exports and accepted movement. Validate with actual drop and existence/content at destination, in addition to direct tests of the delegates.

## Mapa

- Image example configuration.
- Import of promises and URLs.
- Export with the three methods of the delegate.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit)
- [NSFilePromiseProvider](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider)
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate)
- [operationQueue(for:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/operationqueue(for:))
- [NSFilePromiseReceiver](https://developer.apple.com/documentation/appkit/nsfilepromisereceiver)
- [Documents, Data, and Pasteboard](https://developer.apple.com/documentation/appkit/documents-data-and-pasteboard)
- [Supporting Collection View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-collection-view-drag-and-drop-through-file-promises)
- [Supporting Table View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-table-view-drag-and-drop-through-file-promises)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Provenance

Source: [Apple Developer](https://developer.apple.com/documentation/appkit/supporting-drag-and-drop-through-file-promises); captura 2026-10-04T21:06:22.124690+00:00, SHA-256 `ad5aea4873ea3fd5f914db6321f2c20104c4ee73964d5eddf097ed08f76a76d5`. One page; secondary links not covered.
