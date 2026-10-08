---
title: "App schema domains"
source_url: "https://developer.apple.com/documentation/appintents/app-schema-domains"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/app-schema-domains"
captured_at: "2026-10-07T15:14:41.817515+00:00"
source_sha256: "9076bc3da34611a8edff963a297bd1c088f412d28a92fcf6e6b0bbc3fa4872d8"
source_etag: null
source_last_modified: "Fri, 11 Sep 2026 20:50:26 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand App Intents"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App schema domains

## Quick reference

- Module: AppIntents.
- Platform: native system integration including macOS.
- Availability: conceptual page; validate individual symbols against the target SDK. Zforge builds with the macOS 27 SDK for macOS 26.

## Summary

System schemas describe the meaning and structure of intents, entities and enumerations. The AppIntent(schema:), AppEntity(schema:) and AppEnum(schema:) macros map declarations to schemas during compilation. Adopt a schema only when it matches the operation and required data contract.

## Practical implications

The local Xcode 27 macOS SDK Files domain offers openFile, moveFiles, createFolder, renameFile and deleteFiles; it has no compression or extraction action schema. The freshly captured Files page explicitly limits discovery to Shortcuts; the generic system.open schema supports content opening through Siri and Shortcuts on macOS 27. Keep compression and extraction as truthful custom intents rather than mapping them to an unrelated schema.

## Content map

- Overview

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [App schema base types](https://developer.apple.com/documentation/appintents/app-schema-base-types) — expand on demand
- [Assistant](https://developer.apple.com/documentation/appintents/app-schema-domain-assistant) — expand on demand
- [Audio](https://developer.apple.com/documentation/appintents/app-schema-domain-audio) — expand on demand
- [Books](https://developer.apple.com/documentation/appintents/app-schema-domain-books) — expand on demand
- [Browser](https://developer.apple.com/documentation/appintents/app-schema-domain-browser) — expand on demand
- [Calendar](https://developer.apple.com/documentation/appintents/app-schema-domain-calendar) — expand on demand
- [Camera](https://developer.apple.com/documentation/appintents/app-schema-domain-camera) — expand on demand
- [Clock](https://developer.apple.com/documentation/appintents/app-schema-domain-clock) — expand on demand
- [Files](appintents-files-domain.md) — expand on demand
- [Journaling](https://developer.apple.com/documentation/appintents/app-schema-domain-journaling) — expand on demand
- [Mail](https://developer.apple.com/documentation/appintents/app-schema-domain-mail) — expand on demand
- [Maps](https://developer.apple.com/documentation/appintents/app-schema-domain-maps) — expand on demand
- [Messages](https://developer.apple.com/documentation/appintents/app-schema-domain-messages) — expand on demand
- [Notes](https://developer.apple.com/documentation/appintents/app-schema-domain-notes) — expand on demand
- [Phone](https://developer.apple.com/documentation/appintents/app-schema-domain-phone) — expand on demand
- [Photos](https://developer.apple.com/documentation/appintents/app-schema-domain-photos) — expand on demand
- [Presentation](https://developer.apple.com/documentation/appintents/app-schema-domain-presentation) — expand on demand
- [Reader](https://developer.apple.com/documentation/appintents/app-schema-domain-reader) — expand on demand
- [Reminders](https://developer.apple.com/documentation/appintents/app-schema-domain-reminders) — expand on demand
- [Spreadsheet](https://developer.apple.com/documentation/appintents/app-schema-domain-spreadsheet) — expand on demand
- [System and in-app search](appintents-system-content-domain.md) — expand on demand
- [Visual intelligence](https://developer.apple.com/documentation/appintents/app-schema-domain-visual-intelligence) — expand on demand
- [Whiteboard](https://developer.apple.com/documentation/appintents/app-schema-domain-whiteboard) — expand on demand
- [Word processor](https://developer.apple.com/documentation/appintents/app-schema-domain-word-processor) — expand on demand
- [AppEntity(schema:)](https://developer.apple.com/documentation/appintents/appentity(schema:)) — expand on demand
- [AppEnum(schema:)](https://developer.apple.com/documentation/appintents/appenum(schema:)) — expand on demand
- [AppIntent(schema:)](https://developer.apple.com/documentation/appintents/appintent(schema:)) — expand on demand
- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai) — expand on demand
- [Donations and discovery](https://developer.apple.com/documentation/appintents/donations-and-discovery) — expand on demand
- [Making actions and content discoverable by Apple Intelligence](appintents-siri-discoverability.md) — expand on demand
- [Visual presentation](https://developer.apple.com/documentation/appintents/visual-presentation) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/app-schema-domains).
- Captured: `2026-10-07T15:14:41.817515+00:00`.
- Payload SHA-256: `9076bc3da34611a8edff963a297bd1c088f412d28a92fcf6e6b0bbc3fa4872d8`.
- Scope: one DocC JSON page; secondary links remain unvisited. Local SDK inspection complements schema availability.
