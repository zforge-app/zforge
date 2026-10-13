---
title: "file"
source_url: "https://developer.apple.com/documentation/appintents/appschema/filesentity/file"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AppSchema/FilesEntity/file"
captured_at: "2026-10-11T15:17:51.245542+00:00"
source_sha256: "12d096efdeece5b7189285309e19e5ce9bdb4af7090510cf255cb90a02a1a5cd"
source_etag: "\"2976-659026142a8e9\""
source_last_modified: "Fri, 14 Aug 2026 14:10:16 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri routing diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# file

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Instance Property
- Module: App Intents
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
- Declaration: `var file: some AppSchemaEntity { get }`

## Summary

**Official summary:** An entity schema for a file.

To make your app’s content available to Apple Intelligence, conform your AppEntity to a schema that describes your content to the system. If your app’s functionality aligns with the domain and its content matches the schema, you can generate the properties and protocol conformance the schema requires for your app entity implementation with the Swift macro. To make your app work with Siri, see Apple Intelligence and Siri AI. The following example shows an app entity that conforms to the schema: The schema supports the following system experiences: Siri Shortcuts For more information about the App Intents framework and the experiences it supports, see Getting started with the App Intents framework.

## Content map

- Discussion

## Second-level links

### Overview and featured references

- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — An interface for making a custom type or app-specific concept discoverable by Apple Intelligence and experiences like Siri or the Shortcuts app. _(Apple Developer; expand on demand)_
- [Apple Intelligence and Siri AI](appintents-siri-ai.md) — Integrate your app with Apple Intelligence and bring it to Siri AI. _(local context)_
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework) — Make your app’s actions and content available to the rest of the system using the App Intents framework. _(Apple Developer; expand on demand)_

### Content and parameter types

- [AppSchema.FilesEntity](https://developer.apple.com/documentation/appintents/appschema/filesentity) — Identifies entity schemas in the files domain. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/appschema/filesentity/file)
- Captured: `2026-10-11T15:17:51.245542+00:00`
- Payload SHA-256: `12d096efdeece5b7189285309e19e5ce9bdb4af7090510cf255cb90a02a1a5cd`
- Scope: one on-demand primary page; secondary links remain unvisited. No asset is downloaded.

## Zforge routing distinction

The file **entity** schema explicitly lists Siri and Shortcuts as supported experiences. This differs from the Files domain action overview, which lists Shortcuts. A generic system.open intent can take any AppEntity, but compilation and Spotlight opening do not establish natural-language resolution of an unschematized archive entity. Validate file-entity adoption independently before changing production identifiers or permissions.
