---
title: "searchInApp"
source_url: "https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AppSchema/SystemIntent/searchInApp"
captured_at: "2026-10-13T02:55:43+00:00"
source_sha256: "03640560fa1a15ccb46059fcbb56a9f8c85400c5a1d0a0af0d27e4edcaa2981f"
source_etag: "\"2bc7-65c09d157ec6b\""
source_last_modified: "Tue, 22 Sep 2026 03:18:16 GMT"
source_format: "application/json"
depth: 3
categories: ["On-demand Siri routing diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# searchInApp

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Instance Property
- Module: App Intents
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 27.0+, iPadOS 27.0+, Mac Catalyst 27.0+, macOS 27.0+, visionOS 27.0+
- Declaration: `var searchInApp: some AppSchemaIntent { get }`

## Summary

**Official summary:** An intent schema that navigates to search results.

Conform an `AppIntent` to the schema with `@AppIntent(schema: .system.searchInApp)`. Apple's example declares a `ShowInAppSearchResultsIntent` with `static var searchScopes: [StringSearchScope] = [.general]`, a `criteria: StringSearchCriteria` property and `perform()`. The schema supports Siri and Shortcuts. In the macOS 27 SDK it replaces the deprecated `.system.search` name (`ShowInAppSearchResultsIntent` schema) and exports the `SystemSearchInAppIntent` assistant schema.

## Zforge routing evidence

Native planner traces on macOS 27.0.1 show Siri's open flow trying, in order, an entity found on screen or by its own Spotlight app-entity search (system.open, “Tier 1”), then launching only the app (“Tier 2”). When the entity search returns nothing, requests such as “In Zforge, open the archive named …” call the app's searchInApp action, logging that no `system.searchInApp` or `system.search` schema is registered when the app lacks one. The schema itself only presents results; the observed planner does not chain an opening after it, so a follow-up such as “Open it” resolves the onscreen result. Strict language Swift 6 rejects a mutable `static var searchScopes` stored property; use a computed property. [Reproduction](../../Benchmarks/siri-routing-reproduction.md).

## Content map

- Discussion

## Second-level links

### Overview and featured references

- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — An interface you use to express app-specific actions and make them available to the rest of the system. _(Apple Developer; expand on demand)_
- [Apple Intelligence and Siri AI](appintents-siri-ai.md) — Integrate your app with Apple Intelligence and bring it to Siri AI. _(local context)_
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework) — Make your app’s actions and content available to the rest of the system using the App Intents framework. _(Apple Developer; expand on demand)_

### Actions

- [open](appintents-system-open-schema.md) — An intent schema that opens app content. _(local context)_
- [AppSchema.SystemIntent](https://developer.apple.com/documentation/appintents/appschema/systemintent) — Identifies intent schemas in the system domain. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp)
- Captured: `2026-10-13T02:55:43+00:00`
- Payload SHA-256: `03640560fa1a15ccb46059fcbb56a9f8c85400c5a1d0a0af0d27e4edcaa2981f`
- Scope: one on-demand primary page; secondary links remain unvisited. SDK check: Xcode 27 (27A266a), macOS 27 SDK `AppIntents.swiftinterface`.
