---
title: "Xcode library customization"
source_url: "https://developer.apple.com/documentation/swiftui/xcode-library-customization"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Xcode-library-customization"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "6c7025779b9c8dc32ade70873620d314978221ed902dcbfd581a35bb93643c95"
source_etag: "W/\"010402b104451d67e670a5cb66f6b3eb\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Tool support"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Xcode library customization

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: collectionGroup
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Expose custom views and modifiers in the Xcode library.

You can add your custom SwiftUI views and view modifiers to Xcode’s library. This allows anyone developing your app or adopting your framework to access them by clicking the Library button (+) in Xcode’s toolbar. You can select and drag the custom library items into code, just like you would for system-provided items. To add items to the library, create a structure that conforms to the LibraryContentProvider protocol and encapsulate any items you want to add as LibraryItem instances. Implement the views computed property to add library items containing views. Implement the modifiers(base:) method to add items containing view modifiers. Xcode harvests items from all of the library content providers in your project as you work, and makes them available to you in its library.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [LibraryContentProvider](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider) — A source of Xcode library and code completion content. _(Apple Developer; expandir sob demanda)_
- [LibraryItem](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryItem) — A single item to add to the Xcode library. _(Apple Developer; expandir sob demanda)_
- [views](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider/views) — The SwiftUI views that you want to add to the Xcode library. _(Apple Developer; expandir sob demanda)_
- [modifiers(base:)](https://developer.apple.com/documentation/DeveloperToolsSupport/LibraryContentProvider/modifiers(base:)) — Indicates a collection of SwiftUI view modifiers to add to the Xcode library. _(Apple Developer; expandir sob demanda)_

### Tool support

- [Previews in Xcode](swiftui-previews-in-xcode.md) — Generate dynamic, interactive previews of your custom views. _(contexto local)_
- [Performance analysis](swiftui-performance-analysis.md) — Measure and improve your app’s responsiveness. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/xcode-library-customization)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `6c7025779b9c8dc32ade70873620d314978221ed902dcbfd581a35bb93643c95`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
