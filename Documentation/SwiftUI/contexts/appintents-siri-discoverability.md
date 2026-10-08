---
title: "Making actions and content discoverable by Apple Intelligence"
source_url: "https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/making-actions-and-content-discoverable-by-apple-intelligence"
captured_at: "2026-10-08T02:48:57.990711+00:00"
source_sha256: "32eddaf8bf67e73d0a0a14fc05ee3f9cabe9ab47d567527f6825b1b87168ee9c"
source_etag: "\"88db-6590261350c53\""
source_last_modified: "Fri, 14 Aug 2026 14:10:15 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Making actions and content discoverable by Apple Intelligence

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Article
- Module: App Intents
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Siri integration requires matching schemas from relevant domains.

Use schemas only when the action and content match the defined purpose. Some domains require a complete related action set; Xcode validates those requirements. Generic app intent metadata alone does not establish Siri execution.

## Content map

- Overview
- Choose one or more domains for your app
- Support a schema by creating a new type
- Add schema conformance to an existing type
- Migrate existing intents to schemas
- Help the system discover your content

## Second-level links

### Overview and featured references

- [Calendar](https://developer.apple.com/documentation/appintents/app-schema-domain-calendar) — Make your calendar app’s actions available to Apple Intelligence and Siri by adopting schemas for common calendar actions. _(Apple Developer; expand on demand)_
- [Messages](https://developer.apple.com/documentation/appintents/app-schema-domain-messages) — Make your messaging app’s actions available to Apple Intelligence and Siri by adopting schemas for common messaging actions. _(Apple Developer; expand on demand)_
- [App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains) — Declare support for well-known actions and content by applying system-defined schemas to your app intents, app entities, and app enumerations. _(Apple Developer; expand on demand)_
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework) — Make your app’s actions and content available to the rest of the system using the App Intents framework. _(Apple Developer; expand on demand)_
- [Notes](https://developer.apple.com/documentation/appintents/app-schema-domain-notes) — Make your note-taking app’s actions available to Apple Intelligence and Siri by adopting schemas for common note actions. _(Apple Developer; expand on demand)_
- [Photos](https://developer.apple.com/documentation/appintents/app-schema-domain-photos) — Make your photo and video app’s actions available to Apple Intelligence and Siri by adopting schemas for common photo and video actions. _(Apple Developer; expand on demand)_
- [Mail](https://developer.apple.com/documentation/appintents/app-schema-domain-mail) — Make your email app’s actions available to Apple Intelligence and Siri by adopting schemas for common email actions. _(Apple Developer; expand on demand)_
- [Clock](https://developer.apple.com/documentation/appintents/app-schema-domain-clock) — Make your clock app’s actions available to Apple Intelligence and Siri by adopting schemas for common alarm and timer actions. _(Apple Developer; expand on demand)_
- [openAsset](https://developer.apple.com/documentation/appintents/appschema/photosintent/openasset) — An intent schema that opens the app to a photo. _(Apple Developer; expand on demand)_
- [AppEntity(schema:)](https://developer.apple.com/documentation/appintents/appentity(schema:)) — A Swift macro you use to make sure your app entity conforms to a schema. _(Apple Developer; expand on demand)_
- [AppIntent(schema:)](https://developer.apple.com/documentation/appintents/appintent(schema:)) — A Swift macro you use to make sure your app intent conforms to an schema. _(Apple Developer; expand on demand)_
- [AppEnum(schema:)](https://developer.apple.com/documentation/appintents/appenum(schema:)) — A Swift macro you use to make sure your app enum conforms to a schema. _(Apple Developer; expand on demand)_
- [isAssistantOnly](https://developer.apple.com/documentation/appintents/assistantschemaintent/isassistantonly) — _Apple Developer; expand on demand_
- [Donations and discovery](https://developer.apple.com/documentation/appintents/donations-and-discovery) — Donate your app’s intents and entities to the system to help it identify trends and predict future behaviors. _(Apple Developer; expand on demand)_
- [Providing contextual cues to Apple Intelligence and Siri](https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri) — Annotate your interface with app entities to offer contextual information about your app’s onscreen content. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence)
- Captured: `2026-10-08T02:48:57.990711+00:00`
- Payload SHA-256: `32eddaf8bf67e73d0a0a14fc05ee3f9cabe9ab47d567527f6825b1b87168ee9c`
- Scope: one on-demand primary page; secondary links remain unvisited.
