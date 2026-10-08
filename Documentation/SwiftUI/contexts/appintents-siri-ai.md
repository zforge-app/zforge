---
title: "Apple Intelligence and Siri AI"
source_url: "https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/apple-intelligence-and-siri-ai"
captured_at: "2026-10-07T15:14:41.354928+00:00"
source_sha256: "2dc26a77b18ce11ce1cbb1fa8cccbc28f84b4e43f23fe8f422e21cf02116e6b3"
source_etag: null
source_last_modified: "Fri, 14 Aug 2026 14:10:22 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand App Intents"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Apple Intelligence and Siri AI

## Quick reference

- Module: AppIntents.
- Platform: native system integration including macOS.
- Availability: conceptual page; validate individual symbols against the target SDK. Zforge builds with the macOS 27 SDK for macOS 26.

## Summary

Apple Intelligence uses app intents, entities and enums to understand app actions and content. The framework describes additional integration through Spotlight entity indexing, transferable content, system schemas, associations between entities and visible content, and action/content donations. An entity association gives the system app-owned onscreen context; a generic action definition alone does not establish that context.

## Practical implications

Zforge publishes four generic file actions and a macOS 27 system.open action with on-demand archive entities. It does not publish indexed file entities or associations with browser rows. Do not claim that a conversational reference to the first files onscreen can be resolved.

## Content map

- Overview

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [Adopting App Intents to support system experiences](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences) — expand on demand
- [App schema domains](appintents-schema-domains.md) — expand on demand
- [App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts) — expand on demand
- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — expand on demand
- [Defining app entities for your custom data types](https://developer.apple.com/documentation/appintents/defining-app-entities-for-your-custom-data-types) — expand on demand
- [Donating your app’s data and actions to the system](https://developer.apple.com/documentation/appintents/donating-your-apps-data-and-actions-to-the-system) — expand on demand
- [Focus](https://developer.apple.com/documentation/appintents/focus) — expand on demand
- [Hardware interactions](https://developer.apple.com/documentation/appintents/hardware-interactions) — expand on demand
- [Integrating your calendar app with Apple Intelligence](https://developer.apple.com/documentation/appintents/integrating-your-calendar-app-with-apple-intelligence) — expand on demand
- [Integrating your messaging app with Apple Intelligence](https://developer.apple.com/documentation/appintents/integrating-your-messaging-app-with-apple-intelligence) — expand on demand
- [Integrating your music app with Apple Intelligence](https://developer.apple.com/documentation/appintents/integrating-your-music-app-with-apple-intelligence) — expand on demand
- [Integrating your photo app with Apple Intelligence](https://developer.apple.com/documentation/appintents/integrating-your-photo-app-with-apple-intelligence) — expand on demand
- [Making actions and content discoverable by Apple Intelligence](appintents-siri-discoverability.md) — expand on demand
- [Making app entities available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight) — expand on demand
- [NSCollectionViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/nscollectionviewappintentsdatasource) — expand on demand
- [NSTableViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/nstableviewappintentsdatasource) — expand on demand
- [Providing contextual cues to Apple Intelligence and Siri](https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri) — expand on demand
- [Spotlight integration](https://developer.apple.com/documentation/appintents/spotlight) — expand on demand
- [UICollectionViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/uicollectionviewappintentsdatasource) — expand on demand
- [UITableViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/uitableviewappintentsdatasource) — expand on demand
- [Visual intelligence](https://developer.apple.com/documentation/appintents/visual-intelligence) — expand on demand
- [Widgets, Live Activities, and Controls](https://developer.apple.com/documentation/appintents/widgets-live-activities-and-controls) — expand on demand
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai).
- Captured: `2026-10-07T15:14:41.354928+00:00`.
- Payload SHA-256: `2dc26a77b18ce11ce1cbb1fa8cccbc28f84b4e43f23fe8f422e21cf02116e6b3`.
- Scope: one DocC JSON page; secondary links remain unvisited. Local SDK inspection complements schema availability.
