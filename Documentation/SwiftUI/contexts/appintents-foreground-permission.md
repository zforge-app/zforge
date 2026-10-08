---
title: "continueInForeground(_:alwaysConfirm:)"
source_url: "https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/AppIntent/continueInForeground(_:alwaysConfirm:)"
captured_at: "2026-10-08T01:33:30.969341+00:00"
source_sha256: "1c661a564a6eed5ea3723b1c61eca70a3832017f0e5470d80bf746761e302c0c"
source_etag: "\"40a7-65b3b3ba24187\""
source_last_modified: "Fri, 11 Sep 2026 20:50:21 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand automation permission"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# continueInForeground(_:alwaysConfirm:)

## Summary

Background actions can request foreground continuation when their supported modes include dynamic foreground. Check currentMode.canContinueInForeground before continuing. Zforge only foregrounds when a folder grant is missing.

## Availability and validation

iOS 26.0; iPadOS 26.0; Mac Catalyst 26.0; macOS 26.0; tvOS 26.0; visionOS 26.0; watchOS 26.0


Validated against the macOS 27 SDK; Zforge deploys to macOS 26. API compilation does not establish successful native foreground or panel presentation.

## Declaration

```swift
func continueInForeground(_ dialog: IntentDialog? = nil, alwaysConfirm: Bool = true) async throws
```

## Content map

- declarations
- parameters
- mentions
- content

## Secondary links

- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — expand on demand
- [continueInForeground(_:alwaysConfirm:)](https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)) — expand on demand
- [needsToContinueInForegroundError(_:alwaysConfirm:)](https://developer.apple.com/documentation/appintents/appintent/needstocontinueinforegrounderror(_:alwaysconfirm:)) — expand on demand
- [perform()](https://developer.apple.com/documentation/appintents/appintent/perform()) — expand on demand
- [supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes) — expand on demand
- [systemContext](https://developer.apple.com/documentation/appintents/appintent/systemcontext) — expand on demand
- [notAllowed](https://developer.apple.com/documentation/appintents/appintenterror/unrecoverable/notallowed) — expand on demand
- [Configuring the runtime behavior of your app intents](appintents-runtime-behavior.md) — expand on demand
- [IntentDialog](https://developer.apple.com/documentation/appintents/intentdialog) — expand on demand
- [IntentModes](https://developer.apple.com/documentation/appintents/intentmodes) — expand on demand
- [ProgressReportingIntent](https://developer.apple.com/documentation/appintents/progressreportingintent) — expand on demand
- [Bool](https://developer.apple.com/documentation/swift/bool) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)).
- Captured: `2026-10-08T01:33:30.969341+00:00`.
- Payload SHA-256: `1c661a564a6eed5ea3723b1c61eca70a3832017f0e5470d80bf746761e302c0c`.
- Scope: one DocC JSON page; secondary links remain unvisited.
