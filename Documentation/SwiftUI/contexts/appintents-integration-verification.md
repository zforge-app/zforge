---
title: "Verifying your App Intents implementation"
source_url: "https://developer.apple.com/documentation/appintents/verifying-your-app-intents-implementation"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/verifying-your-app-intents-implementation"
captured_at: "2026-10-11T15:17:51.245542+00:00"
source_sha256: "8053cbcde45975c7d7cf1e15d71f47005a9b8299e6bbafab5c283cf7f05a18d5"
source_etag: "\"4acc-65b3b3bd6e34a\""
source_last_modified: "Fri, 11 Sep 2026 20:50:25 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri routing diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Verifying your App Intents implementation

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Article
- Module: App Intents
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Confirm that your app intents work correctly, the system can understand your content, and that it can run your app’s actions.

To verify the behavior of your App Intents code and integrations with system experiences, perform the following tasks to test different aspects of your App Intents implementation: Write integration tests with the App Intents Testing framework for code-level verification of your app intents and entities. Check that app intents, their parameters, and their results appear correctly in the Shortcuts app. Search for your entities in Spotlight to verify that Apple Intelligence and Siri can discover the entities that your app intents need and the ones that represent contextual cues you provide to Apple Intelligence and Siri. Test the end-to-end Siri experience of App Shortcuts and app intents that conform to a schema in an App schema domains. The verification tasks above build on top of each other, and each step helps you catch different problems. For example: Integration tests confirm your implementation returns an expected result, but they can’t tell…

## Content map

- Overview
- Write integration tests with App Intents Testing
- Verify intents, entities, and intent results with the Shortcuts app
- Confirm that entities and App Shortcuts appear in Spotlight
- Validate the end-to-end experience with Siri

## Second-level links

### Overview and featured references

- [App Intents Testing](https://developer.apple.com/documentation/appintentstesting) — Test your app intents, entities, queries, and integration with system features like Siri or Spotlight. _(Apple Developer; expand on demand)_
- [App Shortcuts](appintents-app-shortcuts.md) — Improve the experience of using your app intents and entities in system experiences like Siri, Spotlight, and the Shortcuts app. _(local context)_
- [App schema domains](appintents-schema-domains.md) — Declare support for well-known actions and content by applying system-defined schemas to your app intents, app entities, and app enumerations. _(local context)_
- [SiriKit](https://developer.apple.com/documentation/sirikit) — Empower users to interact with their devices through voice, intelligent suggestions, and personalized workflows. _(Apple Developer; expand on demand)_
- [XCTest](https://developer.apple.com/documentation/xctest) — Create and run unit tests, performance tests, and UI tests for your Xcode project. _(Apple Developer; expand on demand)_
- [Swift Testing](https://developer.apple.com/documentation/testing) — Create and run tests for your Swift packages and Xcode projects. _(Apple Developer; expand on demand)_
- [Testing your App Intents code](appintents-testing-code.md) — Evaluate intents, entities, and queries, and verify your integration with system features like Spotlight and Siri. _(Apple Developer; expand on demand)_
- [Making app entities available in Spotlight](appintents-spotlight-entity-indexing.md) — Update your app entity types to support Spotlight indexing, and donate entities to make them findable in searches. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/verifying-your-app-intents-implementation)
- Captured: `2026-10-11T15:17:51.245542+00:00`
- Payload SHA-256: `8053cbcde45975c7d7cf1e15d71f47005a9b8299e6bbafab5c283cf7f05a18d5`
- Scope: one on-demand primary page; secondary links remain unvisited. No asset is downloaded.
