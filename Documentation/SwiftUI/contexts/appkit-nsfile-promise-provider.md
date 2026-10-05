---
title: "NSFilePromiseProvider"
source_url: "https://developer.apple.com/documentation/appkit/nsfilepromiseprovider"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSFilePromiseProvider"
captured_at: "2026-10-04T13:01:09.738317+00:00"
source_sha256: "b3d86ec60ab7decea9ce9c90d28d9d5681af05d16de9142f657c17f82e6b6d5c"
source_etag: "\"67a7-659026f05e728\""
source_last_modified: "Fri, 14 Aug 2026 14:14:07 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSFilePromiseProvider

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS; signatures found in SDK macOS 27.0
- Declaration: `class   NSFilePromiseProvider`

## Summary

A promise represents a future archive; the auxiliary identity of the item must be given immediately on the pasteboard, with writingOptions empty. The content remains a promise and your delegate writes in the URL provided when complying with the request. The provider must have fileType and delegate set before it is written on the pasteboard.

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [CVarArg](https://developer.apple.com/documentation/swift/cvararg) — Apple Developer; expand on demand.
- [CustomDebugStringConvertible](https://developer.apple.com/documentation/swift/customdebugstringconvertible) — Apple Developer; expand on demand.
- [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible) — Apple Developer; expand on demand.
- [Equatable](https://developer.apple.com/documentation/swift/equatable) — Apple Developer; expand on demand.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — Apple Developer; expand on demand.
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate) — Apple Developer; expand on demand.
- [NSFilePromiseReceiver](https://developer.apple.com/documentation/appkit/nsfilepromisereceiver) — Apple Developer; expand on demand.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expand on demand.
- [NSObject](https://developer.apple.com/documentation/objectivec/nsobject-swift.class) — Apple Developer; expand on demand.
- [NSPasteboardWriting](appkit-nspasteboard-writing.md) — Apple Developer; expand on demand.
- [Supporting Collection View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-collection-view-drag-and-drop-through-file-promises) — Apple Developer; expand on demand.
- [Supporting Drag and Drop Through File Promises](appkit-supporting-file-promises.md) — Apple Developer; expand on demand.
- [Supporting Table View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-table-view-drag-and-drop-through-file-promises) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [delegate](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/delegate) — Apple Developer; expand on demand.
- [fileType](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/filetype) — Apple Developer; expand on demand.
- [init()](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/init()) — Apple Developer; expand on demand.
- [init(fileType:delegate:)](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/init(filetype:delegate:)) — Apple Developer; expand on demand.
- [userInfo](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/userinfo) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider).
- Captured: `2026-10-04T13:01:09.738317+00:00`; SHA-256: `b3d86ec60ab7decea9ce9c90d28d9d5681af05d16de9142f657c17f82e6b6d5c`.
- Scope: one page; secondary links not covered.
