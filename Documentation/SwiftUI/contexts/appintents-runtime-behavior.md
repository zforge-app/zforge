---
title: "Configuring the runtime behavior of your app intents"
source_url: "https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/configuring-the-runtime-behavior-of-your-app-intents"
captured_at: "2026-10-08T01:33:31.369109+00:00"
source_sha256: "19210fa629dd0d8d6fb53cf3c10e0268aefd9861e4e252db5020ff3dc3e4c94d"
source_etag: "\"95cd-65bb964ada882\""
source_last_modified: "Fri, 18 Sep 2026 03:21:16 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand automation permission"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Configuring the runtime behavior of your app intents

## Summary

IntentModes specifies background, foreground and dynamic foreground execution. The system execution context determines whether an invocation can continue in the foreground; unsupported contexts must fail without starting archive work.

## Availability and validation

Validated against the macOS 27 SDK; Zforge deploys to macOS 26. API compilation does not establish successful native foreground or panel presentation.

## Content map

- content

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [Accelerating app interactions with App Intents](https://developer.apple.com/documentation/appintents/acceleratingappinteractionswithappintents) — expand on demand
- [App intent types](https://developer.apple.com/documentation/appintents/app-intent-types) — expand on demand
- [App intents](https://developer.apple.com/documentation/appintents/app-intents) — expand on demand
- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — expand on demand
- [allowedExecutionTargets](https://developer.apple.com/documentation/appintents/appintent/allowedexecutiontargets) — expand on demand
- [continueInForeground(_:alwaysConfirm:)](https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)) — expand on demand
- [perform()](https://developer.apple.com/documentation/appintents/appintent/perform()) — expand on demand
- [supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes) — expand on demand
- [systemContext](https://developer.apple.com/documentation/appintents/appintent/systemcontext) — expand on demand
- [AppIntentsPackage](https://developer.apple.com/documentation/appintents/appintentspackage) — expand on demand
- [includedPackages](https://developer.apple.com/documentation/appintents/appintentspackage/includedpackages) — expand on demand
- [Creating your first app intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent) — expand on demand
- [Directing app intents to your app’s scenes](https://developer.apple.com/documentation/appintents/directing-app-intents-to-your-apps-scenes) — expand on demand
- [LiveActivityIntent](https://developer.apple.com/documentation/appintents/liveactivityintent) — expand on demand
- [OpenIntent](https://developer.apple.com/documentation/appintents/openintent) — expand on demand
- [PlayVideoIntent](https://developer.apple.com/documentation/appintents/playvideointent) — expand on demand
- [ShowInAppSearchResultsIntent](https://developer.apple.com/documentation/appintents/showinappsearchresultsintent) — expand on demand
- [StartWorkoutIntent](https://developer.apple.com/documentation/appintents/startworkoutintent) — expand on demand
- [TargetContentProvidingIntent](https://developer.apple.com/documentation/appintents/targetcontentprovidingintent) — expand on demand
- [UISceneAppIntent](https://developer.apple.com/documentation/appintents/uisceneappintent) — expand on demand
- [URLRepresentableEntity](https://developer.apple.com/documentation/appintents/urlrepresentableentity) — expand on demand
- [URLRepresentableIntent](https://developer.apple.com/documentation/appintents/urlrepresentableintent) — expand on demand
- [Soup Chef with App Intents: Migrating custom intents](https://developer.apple.com/documentation/sirikit/soup-chef-with-app-intents-migrating-custom-intents) — expand on demand
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [Allowing apps and websites to link to your content](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content) — expand on demand
- [Distributing binary frameworks as Swift packages](https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-swift-packages) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents).
- Captured: `2026-10-08T01:33:31.369109+00:00`.
- Payload SHA-256: `19210fa629dd0d8d6fb53cf3c10e0268aefd9861e4e252db5020ff3dc3e4c94d`.
- Scope: one DocC JSON page; secondary links remain unvisited.
