---
title: "Making app entities available in Spotlight"
source_url: "https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/making-app-entities-available-in-spotlight"
captured_at: "2026-10-11T09:58:46.164047+00:00"
source_sha256: "af0a34cfe558f44f1cc8c179b113249d0469abd5930fbaf05a4f28f22bf6eb64"
source_etag: "\"b739-65b3b3ba24187\""
source_last_modified: "Fri, 11 Sep 2026 20:50:21 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Apple Intelligence discovery"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Making app entities available in Spotlight

## Quick reference

- Role: Article
- Module: App Intents
- Relevance: Native macOS content discovery and context.
- Availability: Article; validate individual symbols against the target SDK.

## Summary

Conforming an AppEntity to IndexedEntity enables explicit Spotlight indexing. Donate entities through a named CSSearchableIndex; conformance alone does not populate an index. Spotlight derives attributes from display representations and indexed properties, updating an existing entry when an identifier is reused. Provide an OpenIntent for opening search results and handle reindexing requests through the supported query or index delegate APIs.

## Practical implications

- Zforge has an archive AppEntity and OpenIntent but no explicit entity index. Add a named index over authorized archive metadata as the next implementation milestone.
- Define identity, rename/deletion, revocation cleanup and reindexing before publication. Indexed metadata never replaces file-access authorization.
- Xcode 27 SDK: IndexedEntity and indexAppEntities are available on macOS 15; IndexedEntityQuery is macOS 27+. Preserve the macOS 26 floor through an appropriate reindexing path.
- Index presence helps discovery; actual Spotlight and direct Siri execution require distinct native tests.

## Content map

- Overview
- Add support for indexing your entity types
- Specify which properties of your entity to index
- Add app entities directly to your Spotlight index
- Modify your existing Spotlight code to include entities
- Add support for reindexing your app entities
- Provide app intents to open your entites from search results

## Secondary links

- [Adding your app’s content to Spotlight indexes](https://developer.apple.com/documentation/corespotlight/adding-your-app-s-content-to-spotlight-indexes) — expand on demand
- [Adopting App Intents to support system experiences](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences) — expand on demand
- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [App entities](https://developer.apple.com/documentation/appintents/app-entities) — expand on demand
- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — expand on demand
- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai) — expand on demand
- [CSSearchableIndex](https://developer.apple.com/documentation/corespotlight/cssearchableindex) — expand on demand
- [CSSearchableIndexDelegate](https://developer.apple.com/documentation/corespotlight/cssearchableindexdelegate) — expand on demand
- [CSSearchableIndexDescription](https://developer.apple.com/documentation/corespotlight/cssearchableindexdescription) — expand on demand
- [CSSearchableItem](https://developer.apple.com/documentation/corespotlight/cssearchableitem) — expand on demand
- [CSSearchableItemAttributeSet](https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset) — expand on demand
- [Defining app entities for your custom data types](https://developer.apple.com/documentation/appintents/defining-app-entities-for-your-custom-data-types) — expand on demand
- [DisplayRepresentable](https://developer.apple.com/documentation/appintents/displayrepresentable) — expand on demand
- [Donations and discovery](https://developer.apple.com/documentation/appintents/donations-and-discovery) — expand on demand
- [IndexedEntity](https://developer.apple.com/documentation/appintents/indexedentity) — expand on demand
- [IndexedEntityQuery](https://developer.apple.com/documentation/appintents/indexedentityquery) — expand on demand
- [OpenIntent](https://developer.apple.com/documentation/appintents/openintent) — expand on demand
- [Regenerating your app’s indexes on demand](https://developer.apple.com/documentation/corespotlight/regenerating-your-app-s-indexes-on-demand) — expand on demand
- [ShowInAppSearchResultsIntent](https://developer.apple.com/documentation/appintents/showinappsearchresultsintent) — expand on demand
- [Spotlight integration](https://developer.apple.com/documentation/appintents/spotlight) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [associateAppEntity(_:priority:)](https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset/associateappentity(_:priority:)) — expand on demand
- [attributeSet](https://developer.apple.com/documentation/appintents/indexedentity/attributeset) — expand on demand
- [contentDescription](https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset/contentdescription) — expand on demand
- [displayRepresentation](https://developer.apple.com/documentation/appintents/instancedisplayrepresentable/displayrepresentation) — expand on demand
- [indexAppEntities(_:priority:)](https://developer.apple.com/documentation/corespotlight/cssearchableindex/indexappentities(_:priority:)) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight).
- Captured: `2026-10-11T09:58:46.164047+00:00`.
- Payload SHA-256: `af0a34cfe558f44f1cc8c179b113249d0469abd5930fbaf05a4f28f22bf6eb64`.
- Scope: one DocC JSON page. Secondary links are not traversed; image and code-block metadata are inventoried without downloading assets. SDK checks: Xcode 27 native macOS SDK.
