---
title: "Testing your App Intents code"
source_url: "https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code"
source_identifier: "doc://com.apple.AppIntentsTesting/documentation/AppIntentsTesting/testing-your-app-intents-code"
captured_at: "2026-10-11T20:50:41.282439+00:00"
source_sha256: "f746bba57822bebf2fe4f5c2c514243baff0c1ee7540c3eb2eb050ca59df4ac4"
source_etag: "\"955a-65b3b323e7ba2\""
source_last_modified: "Fri, 11 Sep 2026 20:47:44 GMT"
source_format: "application/json"
depth: 3
categories: ["On-demand Siri dispatch diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Testing your App Intents code

Context normalized for quick retrieval; the source and hash identify the captured page.

## Quick reference

- Role: Article
- Module: App Intents Testing
- Availability: the local Xcode 27 SDK exposes the testing API on macOS 27.0 and later, in the developer frameworks directory.
- Zforge relevance: distinguish authored query/perform unit tests from real out-of-process App Intents resolution and dispatch.

## Summary

Apple places these tests in a UI Testing target using the app's signing team. Launch the app, construct IntentDefinitions with its bundle identifier, look up definitions by type names, create an intent with parameters and await run(). The framework sends execution through the system infrastructure into the live app. Query entities by names or known identifiers, pass returned entities to actions, and inspect results. Spotlight queries and view annotations provide separate indexing/context checks. Test-only setup actions may be hidden and excluded from Release. This does not test spoken language recognition or prove Siri chose the intended action.

## SDK checks and practical implications

- Xcode 27 exposes `definitions.intents[...]`; the captured first-intent example uses singular `intent`, while a later chaining example and the SDK use plural. Follow compilation evidence.
- `AppEntityDefinition.entities(matching:)`, `entities(identifiers:)` and `makeReference(identifier:)` support resolution checks.
- `AnyAppIntent.run()` crosses the process boundary. A direct authored perform call does not provide the same evidence.
- Treat runner initialization failure or zero scenarios as unavailable evidence, not a pass. Preserve separate native spoken and Spotlight acceptance.

## Content map

- Test-target setup and first intent
- Entities, enumerations and chained actions
- Test-only setup and teardown
- Transferable round trips
- Spotlight indexing and visible/selected annotations

## Second-level links

- [App Intents Testing](https://developer.apple.com/documentation/appintentstesting) — _Apple Developer; expand on demand_
- [AnyAppEntity](https://developer.apple.com/documentation/appintentstesting/anyappentity) — _Apple Developer; expand on demand_
- [run()](https://developer.apple.com/documentation/appintentstesting/anyappintent/run()) — _Apple Developer; expand on demand_
- [AppEntityDefinition](https://developer.apple.com/documentation/appintentstesting/appentitydefinition) — _Apple Developer; expand on demand_
- [entities(matching:)](https://developer.apple.com/documentation/appintentstesting/appentitydefinition/entities(matching:)) — _Apple Developer; expand on demand_
- [makeReference(identifier:)](https://developer.apple.com/documentation/appintentstesting/appentitydefinition/makereference(identifier:)) — _Apple Developer; expand on demand_
- [spotlightQuery(_:)](https://developer.apple.com/documentation/appintentstesting/appentitydefinition/spotlightquery(_:)) — _Apple Developer; expand on demand_
- [viewAnnotations()](appintents-test-view-annotations.md) — _Apple Developer; expand on demand_
- [AppEnumDefinition](https://developer.apple.com/documentation/appintentstesting/appenumdefinition) — _Apple Developer; expand on demand_
- [makeCase(_:)](https://developer.apple.com/documentation/appintentstesting/appenumdefinition/makecase(_:)) — _Apple Developer; expand on demand_
- [AppIntentDefinition](https://developer.apple.com/documentation/appintentstesting/appintentdefinition) — _Apple Developer; expand on demand_
- [makeIntent](https://developer.apple.com/documentation/appintentstesting/appintentdefinition/makeintent) — _Apple Developer; expand on demand_
- [IntentDefinitions](https://developer.apple.com/documentation/appintentstesting/intentdefinitions) — _Apple Developer; expand on demand_
- [intents](https://developer.apple.com/documentation/appintentstesting/intentdefinitions/intents) — _Apple Developer; expand on demand_
- [ResolvedIntentResult](https://developer.apple.com/documentation/appintentstesting/resolvedintentresult) — _Apple Developer; expand on demand_
- [ViewAnnotation](https://developer.apple.com/documentation/appintentstesting/viewannotation) — _Apple Developer; expand on demand_
- [entity](https://developer.apple.com/documentation/appintentstesting/viewannotation/entity) — _Apple Developer; expand on demand_
- [isSelected](https://developer.apple.com/documentation/appintentstesting/viewannotation/isselected) — _Apple Developer; expand on demand_
- [App Intents](https://developer.apple.com/documentation/appintents) — _Apple Developer; expand on demand_
- [isDiscoverable](appintents-intent-discoverability.md) — _Apple Developer; expand on demand_
- [App entities](https://developer.apple.com/documentation/appintents/app-entities) — _Apple Developer; expand on demand_
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — _Apple Developer; expand on demand_
- [Technologies](https://developer.apple.com/documentation/technologies) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintentstesting/testing-your-app-intents-code)
- Captured: `2026-10-11T20:50:41.282439+00:00`
- Payload SHA-256: `f746bba57822bebf2fe4f5c2c514243baff0c1ee7540c3eb2eb050ca59df4ac4`
- Scope: one page; secondary references remain unvisited. No asset is downloaded.
