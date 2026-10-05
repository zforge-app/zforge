---
title: "Preferences"
source_url: "https://developer.apple.com/documentation/swiftui/preferences"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Preferences"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "97ffada5b1e882ee8f39f6221ea9e3f3e6e5ebb6ce40cedb043b158346747272"
source_etag: "W/\"d302d54b860552a57a2babdaba7d154d\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Data and storage"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Preferences

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Indicate configuration preferences from views to their container views.

Whereas you use the environment to configure the subviews of a view, you use preferences to send configuration information from subviews toward their container. However, unlike configuration information that flows down a view hierarchy from one container to many subviews, a single container needs to reconcile potentially conflicting preferences flowing up from its many subviews. When you use the PreferenceKey protocol to define a custom preference, you indicate how to merge preferences from multiple subviews. You can then set a value for the preference on a view using the preference(key:value:) view modifier. Many built-in modifiers, like navigationTitle(_:), rely on preferences to send configuration information to their container.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [PreferenceKey](https://developer.apple.com/documentation/swiftui/preferencekey) — A named value produced by a view. _(Apple Developer; expand on demand)_
- [preference(key:value:)](https://developer.apple.com/documentation/swiftui/view/preference(key:value:)) — Sets a value for the given preference. _(Apple Developer; expand on demand)_
- [navigationTitle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)) — Configures the view’s title for purposes of navigation, using a localized string resource. _(Apple Developer; expand on demand)_

### Setting preferences

- [transformPreference(_:_:)](https://developer.apple.com/documentation/swiftui/view/transformpreference(_:_:)) — Applies a transformation to a preference value. _(Apple Developer; expand on demand)_

### Setting preferences based on geometry

- [anchorPreference(key:value:transform:)](https://developer.apple.com/documentation/swiftui/view/anchorpreference(key:value:transform:)) — Sets a value for the specified preference key, the value is a function of a geometry value tied to the current coordinate space, allowing… _(Apple Developer; expand on demand)_
- [transformAnchorPreference(key:value:transform:)](https://developer.apple.com/documentation/swiftui/view/transformanchorpreference(key:value:transform:)) — Sets a value for the specified preference key, the value is a function of the key’s current value and a geometry value tied to… _(Apple Developer; expand on demand)_

### Responding to changes in preferences

- [onPreferenceChange(_:perform:)](https://developer.apple.com/documentation/swiftui/view/onpreferencechange(_:perform:)) — Adds an action to perform when the specified preference key’s value changes. _(Apple Developer; expand on demand)_

### Generating backgrounds and overlays from preferences

- [backgroundPreferenceValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/backgroundpreferencevalue(_:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as the background of the original… _(Apple Developer; expand on demand)_
- [backgroundPreferenceValue(_:alignment:_:)](https://developer.apple.com/documentation/swiftui/view/backgroundpreferencevalue(_:alignment:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as the background of the original… _(Apple Developer; expand on demand)_
- [overlayPreferenceValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/overlaypreferencevalue(_:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as an overlay to the original… _(Apple Developer; expand on demand)_
- [overlayPreferenceValue(_:alignment:_:)](https://developer.apple.com/documentation/swiftui/view/overlaypreferencevalue(_:alignment:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as an overlay to the original… _(Apple Developer; expand on demand)_

### Data and storage

- [Model data](swiftui-model-data.md) — Manage the data that your app uses to drive its interface. _(local context)_
- [Environment values](swiftui-environment-values.md) — Share data throughout a view hierarchy using the environment. _(local context)_
- [Persistent storage](swiftui-persistent-storage.md) — Store data for use across sessions of your app. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/preferences)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `97ffada5b1e882ee8f39f6221ea9e3f3e6e5ebb6ce40cedb043b158346747272`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
