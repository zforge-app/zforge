---
title: "Persistent storage"
source_url: "https://developer.apple.com/documentation/swiftui/persistent-storage"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Persistent-storage"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "e44ef095dadc5943ed06bca345a4d26c368a775700a4528bee817b1831fd15a0"
source_etag: "W/\"8538989f719fe916c21402757a99c3a6\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Data and storage"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Persistent storage

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Store data for use across sessions of your app.

The operating system provides ways to store data when your app closes, so that when people open your app again later, they can continue working without interruption. The mechanism that you use depends on factors like what and how much you need to store, whether you need serialized or random access to the data, and so on. You use the same kinds of storage in a SwiftUI app that you use in any other app. For example, you can access files on disk using the FileManager interface. However, SwiftUI also provides conveniences that make it easier to use certain kinds of persistent storage in a declarative environment. For example, you can use FetchRequest and FetchedResults to interact with a Core Data model.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [FileManager](https://developer.apple.com/documentation/Foundation/FileManager) — A convenient interface to the contents of the file system, and the primary means of interacting with it. _(Apple Developer; expand on demand)_
- [FetchRequest](https://developer.apple.com/documentation/swiftui/fetchrequest) — A property wrapper type that retrieves entities from a Core Data persistent store. _(Apple Developer; expand on demand)_
- [FetchedResults](https://developer.apple.com/documentation/swiftui/fetchedresults) — A collection of results retrieved from a Core Data store. _(Apple Developer; expand on demand)_

### Saving state across app launches

- [Restoring your app’s state with SwiftUI](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui) — Provide app continuity for users by preserving their current activities. _(Apple Developer; expand on demand)_
- [defaultAppStorage(_:)](https://developer.apple.com/documentation/swiftui/view/defaultappstorage(_:)) — The default store used by contained within the view. _(Apple Developer; expand on demand)_
- [AppStorage](https://developer.apple.com/documentation/swiftui/appstorage) — A property wrapper type that reflects a value from and invalidates a view on a change in value in that user default. _(Apple Developer; expand on demand)_
- [SceneStorage](https://developer.apple.com/documentation/swiftui/scenestorage) — A property wrapper type that reads and writes to persisted, per-scene storage. _(Apple Developer; expand on demand)_

### Accessing Core Data

- [Loading and displaying a large data feed](https://developer.apple.com/documentation/swiftui/loading-and-displaying-a-large-data-feed) — Consume data in the background, and lower memory use by batching imports and preventing duplicate records. _(Apple Developer; expand on demand)_
- [managedObjectContext](https://developer.apple.com/documentation/swiftui/environmentvalues/managedobjectcontext) — _Apple Developer; expand on demand_
- [SectionedFetchRequest](https://developer.apple.com/documentation/swiftui/sectionedfetchrequest) — A property wrapper type that retrieves entities, grouped into sections, from a Core Data persistent store. _(Apple Developer; expand on demand)_
- [SectionedFetchResults](https://developer.apple.com/documentation/swiftui/sectionedfetchresults) — A collection of results retrieved from a Core Data persistent store, grouped into sections. _(Apple Developer; expand on demand)_

### Data and storage

- [Model data](swiftui-model-data.md) — Manage the data that your app uses to drive its interface. _(local context)_
- [Environment values](swiftui-environment-values.md) — Share data throughout a view hierarchy using the environment. _(local context)_
- [Preferences](swiftui-preferences.md) — Indicate configuration preferences from views to their container views. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/persistent-storage)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `e44ef095dadc5943ed06bca345a4d26c368a775700a4528bee817b1831fd15a0`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
