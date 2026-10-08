---
title: "IntentFile.fileURL"
source_url: "https://developer.apple.com/documentation/appintents/intentfile/fileurl"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/IntentFile/fileURL"
captured_at: "2026-10-07T16:16:53.962746+00:00"
source_sha256: "806824378b1c99729d2250b95909a523e6e45a599f147a80132321bf012088ac"
source_etag: "\"24d2-6590261350c53\""
source_last_modified: "Fri, 14 Aug 2026 14:10:15 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand App Intents"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# IntentFile.fileURL

## Quick reference

- Module: App Intents.
- Availability: macOS 13.0, iOS/iPadOS/Mac Catalyst/tvOS 16.0, watchOS 9.0, visionOS.
- Declaration: `var fileURL: URL? { get }`.

## Summary

The optional property identifies a file stored on disk. When there is no disk file, its contents are available through data instead. Apple directs callers to bracket access to files originating elsewhere with security-scoped resource access.

## Zforge implications

Zforge requires local disk URLs inside explicit automation grants and rejects data-only inputs. Retain the provided operational URL and balance active bookmark leases. Native protected namespace handling is a separate runtime observation documented in [Protected file paths](foundation-protected-file-paths.md).

## Content map

- Property declaration.
- Discussion: scoped file access.

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [IntentFile](https://developer.apple.com/documentation/appintents/intentfile) — expand on demand
- [data](https://developer.apple.com/documentation/appintents/intentfile/data) — expand on demand
- [fileURL](https://developer.apple.com/documentation/appintents/intentfile/fileurl) — expand on demand
- [filename](https://developer.apple.com/documentation/appintents/intentfile/filename) — expand on demand
- [removedOnCompletion](https://developer.apple.com/documentation/appintents/intentfile/removedoncompletion) — expand on demand
- [type](https://developer.apple.com/documentation/appintents/intentfile/type) — expand on demand
- [URL](https://developer.apple.com/documentation/foundation/url) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/intentfile/fileurl).
- Capture: `2026-10-07T16:16:53.962746+00:00`; SHA-256: `806824378b1c99729d2250b95909a523e6e45a599f147a80132321bf012088ac`.
- Scope: one DocC JSON payload; secondary links are not traversed. Verified against Xcode 27's native macOS SDK.
