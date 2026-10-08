---
title: "App Intents"
source_url: "https://developer.apple.com/documentation/appintents"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents"
captured_at: "2026-10-07T13:57:38.717629+00:00"
source_sha256: "37015077373f781363ca3a723d824d022a9e4f0d3672d2dc8e92f8e0c05a68ab"
source_etag: null
source_last_modified: "Fri, 11 Sep 2026 20:50:27 GMT"
source_format: "application/json"
depth: 0
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App Intents

## Quick reference

- Role: framework overview.
- Module: appintents.
- Relevance to Zforge: native macOS automation and optional intelligence integration.
- Framework availability: iOS 16.0, iPadOS 16.0, Mac Catalyst 16.0, macOS 13.0, tvOS 16.0, visionOS 1.0, watchOS 9.0. Individual symbols may require newer versions.

## Summary

Expose typed application actions and entities to system experiences including Siri, Spotlight, Shortcuts, and Apple Intelligence.

## Practical implications

Use this as the native system adapter for shared Zforge operations. MCP is a separate agent integration. Availability of a framework does not guarantee that every Siri AI feature is available on the minimum supported OS.

This overview is conceptual evidence; no Zforge integration or target-SDK compilation was performed in this capture.

## Content map

- Essentials
- App-specific content
- System integration
- Feature integration
- Testing
- Errors
- Deprecated
- Structures

## Second-level links

- [Action button](https://developer.apple.com/design/human-interface-guidelines/action-button) — expand on demand
- [ActivityKit](https://developer.apple.com/documentation/activitykit) — expand on demand
- [Adopting App Intents to support system experiences](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences) — expand on demand
- [App Intents Testing](https://developer.apple.com/documentation/appintentstesting) — expand on demand
- [App Intents updates](https://developer.apple.com/documentation/updates/appintents) — expand on demand
- [App Shortcuts](hig-app-shortcuts.md) — expand on demand
- [App Shortcuts](appintents-app-shortcuts.md) — expand on demand
- [App entities](https://developer.apple.com/documentation/appintents/app-entities) — expand on demand
- [App enums](https://developer.apple.com/documentation/appintents/app-enums) — expand on demand
- [App extension](https://developer.apple.com/documentation/appintents/app-extension) — expand on demand
- [App intents](appintents-app-intents.md) — expand on demand
- [App schema domains](appintents-schema-domains.md) — expand on demand
- [AppIntentError](https://developer.apple.com/documentation/appintents/appintenterror) — expand on demand
- [Apple Intelligence and Siri AI](appintents-siri-ai.md) — expand on demand
- [Common data types](https://developer.apple.com/documentation/appintents/common-data-types) — expand on demand
- [Controls](https://developer.apple.com/design/human-interface-guidelines/controls) — expand on demand
- [Controls](https://developer.apple.com/documentation/widgetkit/controls-collection) — expand on demand
- [CustomAppIntentErrorConvertible](https://developer.apple.com/documentation/appintents/customappintenterrorconvertible) — expand on demand
- [Deprecated symbols](https://developer.apple.com/documentation/appintents/deprecated-symbols) — expand on demand
- [Donations and discovery](https://developer.apple.com/documentation/appintents/donations-and-discovery) — expand on demand
- [EmptySnippetIntent](https://developer.apple.com/documentation/appintents/emptysnippetintent) — expand on demand
- [Focus](https://developer.apple.com/documentation/appintents/focus) — expand on demand
- [Getting started with the App Intents framework](https://developer.apple.com/documentation/appintents/getting-started-with-the-app-intents-framework) — expand on demand
- [Hardware interactions](https://developer.apple.com/documentation/appintents/hardware-interactions) — expand on demand
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines) — expand on demand
- [Siri](https://developer.apple.com/design/human-interface-guidelines/siri) — expand on demand
- [Spotlight integration](https://developer.apple.com/documentation/appintents/spotlight) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [Testing your App Intents code](https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code) — expand on demand
- [Verifying your App Intents implementation](https://developer.apple.com/documentation/appintents/verifying-your-app-intents-implementation) — expand on demand
- [Visual intelligence](https://developer.apple.com/documentation/appintents/visual-intelligence) — expand on demand
- [Visual presentation](https://developer.apple.com/documentation/appintents/visual-presentation) — expand on demand
- [WidgetKit](https://developer.apple.com/documentation/widgetkit) — expand on demand
- [Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets) — expand on demand
- [Widgets, Live Activities, and Controls](https://developer.apple.com/documentation/appintents/widgets-live-activities-and-controls) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents).
- Captured: `2026-10-07T13:57:38.717629+00:00`.
- Payload SHA-256: `37015077373f781363ca3a723d824d022a9e4f0d3672d2dc8e92f8e0c05a68ab`.
- Scope: one official DocC JSON page; secondary pages were not traversed.
