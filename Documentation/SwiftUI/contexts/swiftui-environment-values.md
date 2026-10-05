---
title: "Environment values"
source_url: "https://developer.apple.com/documentation/swiftui/environment-values"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Environment-values"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "abcf87d898fb7a72e59f01a26acf43a018fc955d37a36a176a292ca1ab2007dc"
source_etag: "W/\"834d1bc0ffb073f3b3801d3ee14ee7fa\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Data and storage"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Environment values

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Share data throughout a view hierarchy using the environment.

Views in SwiftUI can react to configuration information that they read from the environment using an Environment property wrapper. A view inherits its environment from its container view, subject to explicit changes from an environment(_:_:) view modifier, or by implicit changes from one of the many modifiers that operate on environment values. As a result, you can configure a entire hierarchy of views by modifying the environment of the group’s container. You can find many built-in environment values in the EnvironmentValues structure. You can also create a custom EnvironmentValues property by defining a new property in an extension to the environment values structure and applying the Entry() macro to the variable declaration.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Environment](https://developer.apple.com/documentation/swiftui/environment) — A property wrapper that reads a value from a view’s environment. _(Apple Developer; expand on demand)_
- [environment(_:_:)](https://developer.apple.com/documentation/swiftui/view/environment(_:_:)) — Sets the environment value of the specified key path to the given value. _(Apple Developer; expand on demand)_
- [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues) — A collection of environment values propagated through a view hierarchy. _(Apple Developer; expand on demand)_
- [Entry()](https://developer.apple.com/documentation/swiftui/entry()) — Creates an environment values, transaction, container values, or focused values entry. _(Apple Developer; expand on demand)_

### Creating custom environment values

- [EnvironmentKey](https://developer.apple.com/documentation/swiftui/environmentkey) — A key for accessing values in the environment. _(Apple Developer; expand on demand)_

### Modifying the environment of a view

- [environment(_:)](https://developer.apple.com/documentation/swiftui/view/environment(_:)) — Places an observable object in the view’s environment. _(Apple Developer; expand on demand)_
- [transformEnvironment(_:transform:)](https://developer.apple.com/documentation/swiftui/view/transformenvironment(_:transform:)) — Transforms the environment value of the specified key path with the given function. _(Apple Developer; expand on demand)_

### Modifying the environment of a scene

- [environment(_:)](https://developer.apple.com/documentation/swiftui/scene/environment(_:)) — Places an observable object in the scene’s environment. _(Apple Developer; expand on demand)_
- [environment(_:_:)](https://developer.apple.com/documentation/swiftui/scene/environment(_:_:)) — Sets the environment value of the specified key path to the given value. _(Apple Developer; expand on demand)_
- [transformEnvironment(_:transform:)](https://developer.apple.com/documentation/swiftui/scene/transformenvironment(_:transform:)) — Transforms the environment value of the specified key path with the given function. _(Apple Developer; expand on demand)_

### Data and storage

- [Model data](swiftui-model-data.md) — Manage the data that your app uses to drive its interface. _(local context)_
- [Preferences](swiftui-preferences.md) — Indicate configuration preferences from views to their container views. _(local context)_
- [Persistent storage](swiftui-persistent-storage.md) — Store data for use across sessions of your app. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/environment-values)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `abcf87d898fb7a72e59f01a26acf43a018fc955d37a36a176a292ca1ab2007dc`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
