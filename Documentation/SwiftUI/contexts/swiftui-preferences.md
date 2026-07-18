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

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Indicate configuration preferences from views to their container views.

Whereas you use the environment to configure the subviews of a view, you use preferences to send configuration information from subviews toward their container. However, unlike configuration information that flows down a view hierarchy from one container to many subviews, a single container needs to reconcile potentially conflicting preferences flowing up from its many subviews. When you use the PreferenceKey protocol to define a custom preference, you indicate how to merge preferences from multiple subviews. You can then set a value for the preference on a view using the preference(key:value:) view modifier. Many built-in modifiers, like navigationTitle(_:), rely on preferences to send configuration information to their container.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [PreferenceKey](https://developer.apple.com/documentation/swiftui/preferencekey) — A named value produced by a view. _(Apple Developer; expandir sob demanda)_
- [preference(key:value:)](https://developer.apple.com/documentation/swiftui/view/preference(key:value:)) — Sets a value for the given preference. _(Apple Developer; expandir sob demanda)_
- [navigationTitle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)) — Configures the view’s title for purposes of navigation, using a localized string resource. _(Apple Developer; expandir sob demanda)_

### Setting preferences

- [transformPreference(_:_:)](https://developer.apple.com/documentation/swiftui/view/transformpreference(_:_:)) — Applies a transformation to a preference value. _(Apple Developer; expandir sob demanda)_

### Setting preferences based on geometry

- [anchorPreference(key:value:transform:)](https://developer.apple.com/documentation/swiftui/view/anchorpreference(key:value:transform:)) — Sets a value for the specified preference key, the value is a function of a geometry value tied to the current coordinate space, allowing… _(Apple Developer; expandir sob demanda)_
- [transformAnchorPreference(key:value:transform:)](https://developer.apple.com/documentation/swiftui/view/transformanchorpreference(key:value:transform:)) — Sets a value for the specified preference key, the value is a function of the key’s current value and a geometry value tied to… _(Apple Developer; expandir sob demanda)_

### Responding to changes in preferences

- [onPreferenceChange(_:perform:)](https://developer.apple.com/documentation/swiftui/view/onpreferencechange(_:perform:)) — Adds an action to perform when the specified preference key’s value changes. _(Apple Developer; expandir sob demanda)_

### Generating backgrounds and overlays from preferences

- [backgroundPreferenceValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/backgroundpreferencevalue(_:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as the background of the original… _(Apple Developer; expandir sob demanda)_
- [backgroundPreferenceValue(_:alignment:_:)](https://developer.apple.com/documentation/swiftui/view/backgroundpreferencevalue(_:alignment:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as the background of the original… _(Apple Developer; expandir sob demanda)_
- [overlayPreferenceValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/overlaypreferencevalue(_:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as an overlay to the original… _(Apple Developer; expandir sob demanda)_
- [overlayPreferenceValue(_:alignment:_:)](https://developer.apple.com/documentation/swiftui/view/overlaypreferencevalue(_:alignment:_:)) — Reads the specified preference value from the view, using it to produce a second view that is applied as an overlay to the original… _(Apple Developer; expandir sob demanda)_

### Data and storage

- [Model data](swiftui-model-data.md) — Manage the data that your app uses to drive its interface. _(contexto local)_
- [Environment values](swiftui-environment-values.md) — Share data throughout a view hierarchy using the environment. _(contexto local)_
- [Persistent storage](swiftui-persistent-storage.md) — Store data for use across sessions of your app. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/preferences)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `97ffada5b1e882ee8f39f6221ea9e3f3e6e5ebb6ce40cedb043b158346747272`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
