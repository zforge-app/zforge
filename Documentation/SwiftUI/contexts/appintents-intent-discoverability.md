---
title: "isDiscoverable"
source_url: "https://developer.apple.com/documentation/appintents/appintent/isdiscoverable"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AppIntent/isDiscoverable"
captured_at: "2026-10-12T18:39:17.659382+00:00"
source_sha256: "be1a8a758352c88098ed224467d6e5649268729e552cde9f28447e2972ab7f9c"
source_etag: "\"2701-6590261383182\""
source_last_modified: "Fri, 14 Aug 2026 14:10:16 GMT"
source_format: "application/json"
depth: 3
categories: ["On-demand Siri metadata diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# isDiscoverable

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Type Property
- Module: App Intents
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, tvOS 17.0+, visionOS, watchOS 10.0+
- Declaration: `static var isDiscoverable: Bool { get }`

## Summary

**Official summary:** Controls whether system experiences can discover and invoke an app intent.

The default is true. Apple includes Siri, Spotlight and Shortcuts among the system experiences affected. With false, invocation remains available from the app interface or widgets, while system experiences cannot access the intent. App Shortcuts require true. For Zforge, hiding a compatibility action is not established as a supported saved-shortcut migration. A second exported assistant schema is visible in metadata despite the discoverability flag, but metadata presence alone does not prove the cause of Siri routing failure. Preserve the saved action contract and validate actual system invocation independently.

## Content map

- Discussion

## Second-level links

### Configuring the metadata

- [title](https://developer.apple.com/documentation/appintents/appintent/title) — A short, localized, human-readable string that conveys the app intent’s action. _(Apple Developer; expand on demand)_
- [description](https://developer.apple.com/documentation/appintents/appintent/description) — A localized string that describes what the app intent does. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/appintent/isdiscoverable)
- Captured: `2026-10-12T18:39:17.659382+00:00`
- Payload SHA-256: `be1a8a758352c88098ed224467d6e5649268729e552cde9f28447e2972ab7f9c`
- Scope: one on-demand official API page; the absolute links above have not yet been traversed.
