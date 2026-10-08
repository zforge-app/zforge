---
title: "System and in-app search"
source_url: "https://developer.apple.com/documentation/appintents/app-schema-domain-system-and-in-app-search"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/app-schema-domain-system-and-in-app-search"
captured_at: "2026-10-08T02:56:08.083428+00:00"
source_sha256: "1b5ce59bfd410f49f82eb0d89041fdaeb156ebb72da994e0422ddbd43720be3f"
source_etag: "\"37ef-65c09d15b31e0\""
source_last_modified: "Tue, 22 Sep 2026 03:18:17 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# System and in-app search

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: App Intents
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** The system domain supports generic content access through Siri and Shortcuts.

The domain applies to apps that search or open content. Its open action supports Siri and Shortcuts and matches Zforge archive opening. Xcode 27 declares system.open on macOS 27; retain the existing generic actions for macOS 26. Compression and extraction do not match this schema.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [searchInApp](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp) — An intent schema that navigates to search results. _(Apple Developer; expand on demand)_
- [open](appintents-system-open-schema.md) — An intent schema that opens an item in the application. _(Apple Developer; expand on demand)_
- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai) — Integrate your app with Apple Intelligence and bring it to Siri AI. _(Apple Developer; expand on demand)_

### Actions

- [AppSchema.SystemIntent](https://developer.apple.com/documentation/appintents/appschema/systemintent) — Identifies intent schemas in the system domain. _(Apple Developer; expand on demand)_

### Primary domains

- [Audio](https://developer.apple.com/documentation/appintents/app-schema-domain-audio) — Make your audio app’s actions available to Apple Intelligence and Siri by adopting schemas for common audio playback actions. _(Apple Developer; expand on demand)_
- [Calendar](https://developer.apple.com/documentation/appintents/app-schema-domain-calendar) — Make your calendar app’s actions available to Apple Intelligence and Siri by adopting schemas for common calendar actions. _(Apple Developer; expand on demand)_
- [Camera](https://developer.apple.com/documentation/appintents/app-schema-domain-camera) — Make your camera app’s actions available to Apple Intelligence and Siri by adopting schemas for common camera actions. _(Apple Developer; expand on demand)_
- [Clock](https://developer.apple.com/documentation/appintents/app-schema-domain-clock) — Make your clock app’s actions available to Apple Intelligence and Siri by adopting schemas for common alarm and timer actions. _(Apple Developer; expand on demand)_
- [Mail](https://developer.apple.com/documentation/appintents/app-schema-domain-mail) — Make your email app’s actions available to Apple Intelligence and Siri by adopting schemas for common email actions. _(Apple Developer; expand on demand)_
- [Maps](https://developer.apple.com/documentation/appintents/app-schema-domain-maps) — Make your navigation app’s actions available to Apple Intelligence and Siri by adopting schemas for common navigation actions. _(Apple Developer; expand on demand)_
- [Messages](https://developer.apple.com/documentation/appintents/app-schema-domain-messages) — Make your messaging app’s actions available to Apple Intelligence and Siri by adopting schemas for common messaging actions. _(Apple Developer; expand on demand)_
- [Notes](https://developer.apple.com/documentation/appintents/app-schema-domain-notes) — Make your note-taking app’s actions available to Apple Intelligence and Siri by adopting schemas for common note actions. _(Apple Developer; expand on demand)_
- [Phone](https://developer.apple.com/documentation/appintents/app-schema-domain-phone) — Make your phone app’s actions available to Apple Intelligence and Siri by adopting schemas for calling actions. _(Apple Developer; expand on demand)_
- [Photos](https://developer.apple.com/documentation/appintents/app-schema-domain-photos) — Make your photo and video app’s actions available to Apple Intelligence and Siri by adopting schemas for common photo and video actions. _(Apple Developer; expand on demand)_
- [Reminders](https://developer.apple.com/documentation/appintents/app-schema-domain-reminders) — Make your reminder app’s actions available to Apple Intelligence and Siri by adopting schemas for common reminder actions. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/app-schema-domain-system-and-in-app-search)
- Captured: `2026-10-08T02:56:08.083428+00:00`
- Payload SHA-256: `1b5ce59bfd410f49f82eb0d89041fdaeb156ebb72da994e0422ddbd43720be3f`
- Scope: one on-demand primary page; secondary links remain unvisited.
