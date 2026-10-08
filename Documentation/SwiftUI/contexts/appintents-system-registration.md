---
title: "Accelerating app interactions with App Intents"
source_url: "https://developer.apple.com/documentation/appintents/acceleratingappinteractionswithappintents"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AcceleratingAppInteractionsWithAppIntents"
captured_at: "2026-10-07T15:14:40.797444+00:00"
source_sha256: "2627d9eca8bb532467445734df58afaabe6c6eceecd3738a0a3f9585bde989c9"
source_etag: null
source_last_modified: "Fri, 11 Sep 2026 20:50:23 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand App Intents"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Accelerating app interactions with App Intents

## Quick reference

- Module: AppIntents.
- Platform: native system integration including macOS.
- Availability: conceptual page; validate individual symbols against the target SDK. Zforge builds with the macOS 27 SDK for macOS 26.

## Summary

The sample registers its App Shortcuts by calling updateAppShortcutParameters() from the SwiftUI App initializer. An AppShortcut combines an intent, invocation phrases and presentation metadata; the system can match semantically similar phrases. Entity queries supply stable app content to Shortcuts, while IndexedEntity and Spotlight associate searchable content with app entities. Registration, content discovery and actual invocation are separate validation boundaries.

## Practical implications

The sample describes general App Shortcuts registration. Native macOS support is constrained by the [platform-specific HIG](hig-app-shortcuts.md): use custom Shortcuts built from App Intents. Do not infer native Mac automatic phrase support from this sample.

## Content map

- Overview
- Identify common actions
- Create App Shortcuts
- Design custom responses
- Add parameters to an intent
- Provide the app’s data through queries
- Enable Find intents
- Contribute entities to Spotlight
- Integrate universal links

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [App intent types](https://developer.apple.com/documentation/appintents/app-intent-types) — expand on demand
- [App intents](https://developer.apple.com/documentation/appintents/app-intents) — expand on demand
- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — expand on demand
- [defaultQuery](https://developer.apple.com/documentation/appintents/appentity/defaultquery-4khg7) — expand on demand
- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — expand on demand
- [perform()](https://developer.apple.com/documentation/appintents/appintent/perform()) — expand on demand
- [AppShortcut](https://developer.apple.com/documentation/appintents/appshortcut) — expand on demand
- [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider) — expand on demand
- [updateAppShortcutParameters()](https://developer.apple.com/documentation/appintents/appshortcutsprovider/updateappshortcutparameters()) — expand on demand
- [Configuring the runtime behavior of your app intents](appintents-runtime-behavior.md) — expand on demand
- [Creating your first app intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent) — expand on demand
- [EntityProperty](https://developer.apple.com/documentation/appintents/entityproperty) — expand on demand
- [EntityPropertyQuery](https://developer.apple.com/documentation/appintents/entitypropertyquery) — expand on demand
- [EntityQuery](https://developer.apple.com/documentation/appintents/entityquery) — expand on demand
- [suggestedEntities()](https://developer.apple.com/documentation/appintents/entityquery/suggestedentities()) — expand on demand
- [EntityStringQuery](https://developer.apple.com/documentation/appintents/entitystringquery) — expand on demand
- [entities(matching:)](https://developer.apple.com/documentation/appintents/entitystringquery/entities(matching:)) — expand on demand
- [EnumerableEntityQuery](https://developer.apple.com/documentation/appintents/enumerableentityquery) — expand on demand
- [allEntities()](https://developer.apple.com/documentation/appintents/enumerableentityquery/allentities()) — expand on demand
- [IndexedEntity](https://developer.apple.com/documentation/appintents/indexedentity) — expand on demand
- [IntentParameter](https://developer.apple.com/documentation/appintents/intentparameter) — expand on demand
- [needsDisambiguationError(among:dialog:)](https://developer.apple.com/documentation/appintents/intentparameter/needsdisambiguationerror(among:dialog:)) — expand on demand
- [OpenIntent](https://developer.apple.com/documentation/appintents/openintent) — expand on demand
- [ProvidesDialog](https://developer.apple.com/documentation/appintents/providesdialog) — expand on demand
- [ShowsSnippetView](https://developer.apple.com/documentation/appintents/showssnippetview) — expand on demand
- [SiriTipView](https://developer.apple.com/documentation/appintents/siritipview) — expand on demand
- [URLRepresentableEntity](https://developer.apple.com/documentation/appintents/urlrepresentableentity) — expand on demand
- [URLRepresentableIntent](https://developer.apple.com/documentation/appintents/urlrepresentableintent) — expand on demand
- [associateAppEntity(_:priority:)](https://developer.apple.com/documentation/corespotlight/cssearchableitem/associateappentity(_:priority:)-736lx) — expand on demand
- [CSSearchableItemAttributeSet](https://developer.apple.com/documentation/corespotlight/cssearchableitemattributeset) — expand on demand
- [Soup Chef with App Intents: Migrating custom intents](https://developer.apple.com/documentation/sirikit/soup-chef-with-app-intents-migrating-custom-intents) — expand on demand
- [Identifiable](https://developer.apple.com/documentation/swift/identifiable) — expand on demand
- [String](https://developer.apple.com/documentation/swift/string) — expand on demand
- [App](https://developer.apple.com/documentation/swiftui/app) — expand on demand
- [init()](https://developer.apple.com/documentation/swiftui/app/init()) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/acceleratingappinteractionswithappintents).
- Captured: `2026-10-07T15:14:40.797444+00:00`.
- Payload SHA-256: `2627d9eca8bb532467445734df58afaabe6c6eceecd3738a0a3f9585bde989c9`.
- Scope: one DocC JSON page; secondary links remain unvisited. Local SDK inspection complements schema availability.
