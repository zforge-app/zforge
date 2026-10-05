---
title: "filePromiseProvider(_:writePromiseTo:completionHandler:)"
source_url: "https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:writepromiseto:completionhandler:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSFilePromiseProviderDelegate/filePromiseProvider(_:writePromiseTo:completionHandler:)"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "c5770fc257a31b7d790669c9af7bec260632eaf52264f5df47a337839bd130d6"
source_etag: "\"5da7-659026dc59565\""
source_last_modified: "Fri, 14 Aug 2026 14:13:46 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# filePromiseProvider(_:writePromiseTo:completionHandler:)

## Quick reference

- Module: AppKit; Native drag API of macOS.
- Availability: macOS 10.12+
- Declaration: `nonisolated   func   filePromiseProvider ( _   filePromiseProvider :  NSFilePromiseProvider ,  writePromiseTo   url :  URL ,  completionHandler :  @escaping  @Sendable  ((any  Error )?) ->  Void ) nonisolated   func   filePromiseProvider ( _   filePromiseProvider :  NSFilePromiseProvider ,  writePromiseTo   url :  URL )  async   throws`

## Summary

The file compromise delegate receives the exact URL in which to publish the content when the system requests to keep the promise. Writing runs in the operation which is indicated by the delegate; the conclusion must be called after writing. The coordination of archives shall accompany the publication.

## Practical implications no Zforge

Virtual origin uses file promises and determines the allowed operation. The product rule requires standard copying and handling with Option; to ignore the automatic translation of AppKit and apply modifiers the rule explicitly in the origin and in the internal destination. Promises write only in the provided URL and remove archive entries only after successful publication. SDK macOS 27.0 declares the writing of nonisolated promises and allows you to choose the main operation queen; maintain coordination of UI in MainActor.

## Content map

- Declaration, operations/modifiers or writing of promises.
- References of related types and methods.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [Error](https://developer.apple.com/documentation/swift/error) — Apple Developer; expand on demand.
- [NSError](https://developer.apple.com/documentation/foundation/nserror) — Apple Developer; expand on demand.
- [NSFileCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator) — Apple Developer; expand on demand.
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate) — Apple Developer; expand on demand.
- [NSFilePromiseProvider](appkit-nsfile-promise-provider.md) — Apple Developer; expand on demand.
- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — Apple Developer; expand on demand.
- [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [URL](https://developer.apple.com/documentation/foundation/url) — Apple Developer; expand on demand.
- [Void](https://developer.apple.com/documentation/swift/void) — Apple Developer; expand on demand.
- [filePromiseProvider(_:fileNameForType:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:filenamefortype:)) — Apple Developer; expand on demand.
- [operationQueue(for:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/operationqueue(for:)) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:writepromiseto:completionhandler:)).
- Captured: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `c5770fc257a31b7d790669c9af7bec260632eaf52264f5df47a337839bd130d6`.
- Scope: one page; secondary links not covered.

### Coordination in Zforge

The publication of a promise does not await the final callback of the origin. Receivers may request files in sequence; complete each writing before attending the next. The removal of origins awaits all publications and the final movement operation. The additional token is given immediately, with empty writing options; the content maintains the promise policy of AppKit.

External movements confirm the change of the original before the first publication. Cancel rejects all promises without recording. Writings are serialized; the completion of each one does not await ended, but removal requires confirmation, final acceptance of movement and success of all. Tests also freeze after fulfilling partial promises and failure.

The URL of the promise can only upload sandbox authorization to the final file. Creating sibling staging next to her failed with NSCocoaErrorDomain 513 in real integration with Finder. Extract/validate in app staging and publish in authorized URL; do not infer access to the parent folder. Already authorized internal destinations maintain publication by neighboring staging/rename.
