---
title: "open"
source_url: "https://developer.apple.com/documentation/appintents/appschema/systemintent/open"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AppSchema/SystemIntent/open"
captured_at: "2026-10-08T02:56:08.083428+00:00"
source_sha256: "d4193ec4c9f5b2698f9df1d1ac0cf1cf36c715bedfd0df17ced2ffdaac68042a"
source_etag: "\"2b26-65c09d157ec6b\""
source_last_modified: "Tue, 22 Sep 2026 03:18:16 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# open

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Instance Property
- Module: App Intents
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, visionOS 27.0+
- Declaration: `var open: some AppSchemaIntent { get }`

## Summary

**Official summary:** The system.open schema opens app content through an AppEntity target.

The domain applies to apps that search or open content. Its open action supports Siri and Shortcuts and matches Zforge archive opening. Xcode 27 declares system.open on macOS 27; retain the existing generic actions for macOS 26. Compression and extraction do not match this schema.

## Content map

- Discussion

## Second-level links

### Overview and featured references

- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — An interface you use to express app-specific actions and make them available to the rest of the system. _(Apple Developer; expand on demand)_
- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai) — Integrate your app with Apple Intelligence and bring it to Siri AI. _(Apple Developer; expand on demand)_
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework) — Make your app’s actions and content available to the rest of the system using the App Intents framework. _(Apple Developer; expand on demand)_

### Actions

- [searchInApp](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp) — An intent schema that navigates to search results. _(Apple Developer; expand on demand)_
- [AppSchema.SystemIntent](https://developer.apple.com/documentation/appintents/appschema/systemintent) — Identifies intent schemas in the system domain. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/appschema/systemintent/open)
- Captured: `2026-10-08T02:56:08.083428+00:00`
- Payload SHA-256: `d4193ec4c9f5b2698f9df1d1ac0cf1cf36c715bedfd0df17ced2ffdaac68042a`
- Scope: one on-demand primary page; secondary links remain unvisited.
