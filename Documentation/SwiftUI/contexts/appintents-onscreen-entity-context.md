---
title: "Providing contextual cues to Apple Intelligence and Siri"
source_url: "https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/providing-contextual-cues-to-apple-intelligence-and-siri"
captured_at: "2026-10-11T09:58:46.164047+00:00"
source_sha256: "0b1e3fce975037899b3b1ad51314bd0a4f91050a55471d051983da5bbbe6f636"
source_etag: "\"d3df-65bb964a3bb8a\""
source_last_modified: "Fri, 18 Sep 2026 03:21:15 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Apple Intelligence discovery"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Providing contextual cues to Apple Intelligence and Siri

## Quick reference

- Role: Article
- Module: App Intents
- Relevance: Native macOS content discovery and context.
- Availability: iOS 18.2+, iPadOS 18.2+, Mac Catalyst 18.2+, macOS 15.2+, tvOS 18.2+, visionOS 2.2+, watchOS 11.2+, Xcode 16.2+

## Summary

Associate app entities with the views that display their content so the system can resolve contextual references. SwiftUI supports appEntityIdentifier and appEntityUIElements; AppKit supports responder annotations. A provider can return visible or selected entities with bounds and selection state. Multiple displayed entities need accurate view associations; a user activity is an alternative for a single displayed entity. Apply only semantically matching schemas.

## Practical implications

- Zforge must associate actual visible/selected content with entities consistently across its four browser modes. Do not substitute generic window text for entity context.
- Preserve displayed ordering, selection, view bounds and authorization rules when providing contextual targets. Test navigation and changing selection to prevent stale associations.
- Xcode 27 SDK: SwiftUI appEntityIdentifier and appEntityUIElements are available on macOS 15.4+. NSUserActivity annotations are available on macOS 15.2+. Both fit the macOS 26 deployment floor.
- Context publication does not add a compression/extraction schema or prove that Siri executes a free-form command.

## Content map

- Overview
- Apply a domain-specific schema to your custom type
- Support conversions between your app entities and equivalent system types
- Associate entities with the views in your interface
- Associate entities with other types of content

## Secondary links

- [AlarmKit](https://developer.apple.com/documentation/alarmkit) — expand on demand
- [AlarmManager.AlarmConfiguration](https://developer.apple.com/documentation/alarmkit/alarmmanager/alarmconfiguration) — expand on demand
- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains) — expand on demand
- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — expand on demand
- [AppEntityAnnotatable](https://developer.apple.com/documentation/appintents/appentityannotatable) — expand on demand
- [AppEntityUIElement](https://developer.apple.com/documentation/appintents/appentityuielement) — expand on demand
- [Apple Intelligence and Siri AI](https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai) — expand on demand
- [CALayer](https://developer.apple.com/documentation/quartzcore/calayer) — expand on demand
- [Core Transferable](https://developer.apple.com/documentation/coretransferable) — expand on demand
- [Defining app entities for your custom data types](https://developer.apple.com/documentation/appintents/defining-app-entities-for-your-custom-data-types) — expand on demand
- [Donations and discovery](https://developer.apple.com/documentation/appintents/donations-and-discovery) — expand on demand
- [IntentPerson](https://developer.apple.com/documentation/appintents/intentperson) — expand on demand
- [IntentValueRepresentation](https://developer.apple.com/documentation/appintents/intentvaluerepresentation) — expand on demand
- [MPNowPlayingInfoCenter](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter) — expand on demand
- [MPNowPlayingInfoPropertyAppEntityIdentifiers](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfopropertyappentityidentifiers) — expand on demand
- [Media Player](https://developer.apple.com/documentation/mediaplayer) — expand on demand
- [NSCollectionViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/nscollectionviewappintentsdatasource) — expand on demand
- [NSTableViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/nstableviewappintentsdatasource) — expand on demand
- [NSUserActivity](https://developer.apple.com/documentation/foundation/nsuseractivity) — expand on demand
- [PersonNameComponents](https://developer.apple.com/documentation/foundation/personnamecomponents) — expand on demand
- [PlaceDescriptor](https://developer.apple.com/documentation/geotoolbox/placedescriptor) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expand on demand
- [UICollectionViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/uicollectionviewappintentsdatasource) — expand on demand
- [UITableViewAppIntentsDataSource](https://developer.apple.com/documentation/appintents/uitableviewappintentsdatasource) — expand on demand
- [User Notifications](https://developer.apple.com/documentation/usernotifications) — expand on demand
- [appEntityIdentifier](https://developer.apple.com/documentation/appintents/appentityannotatable/appentityidentifier) — expand on demand
- [appEntityIdentifier](https://developer.apple.com/documentation/foundation/nsuseractivity/appentityidentifier) — expand on demand
- [appEntityIdentifier(_:)](swiftui-app-entity-identifier.md) — expand on demand
- [appEntityUIElementProvider](https://developer.apple.com/documentation/uikit/uiview/appentityuielementprovider) — expand on demand
- [appEntityUIElements(_:)](swiftui-app-entity-ui-elements.md) — expand on demand
- [nowPlayingInfo](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter/nowplayinginfo) — expand on demand
- [transferRepresentation](https://developer.apple.com/documentation/coretransferable/transferable/transferrepresentation) — expand on demand
- [userActivity](https://developer.apple.com/documentation/uikit/uiresponder/useractivity) — expand on demand
- [userActivity(_:element:_:)](https://developer.apple.com/documentation/swiftui/view/useractivity(_:element:_:)) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/providing-contextual-cues-to-apple-intelligence-and-siri).
- Captured: `2026-10-11T09:58:46.164047+00:00`.
- Payload SHA-256: `0b1e3fce975037899b3b1ad51314bd0a4f91050a55471d051983da5bbbe6f636`.
- Scope: one DocC JSON page. Secondary links are not traversed; image and code-block metadata are inventoried without downloading assets. SDK checks: Xcode 27 native macOS SDK.
