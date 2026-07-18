---
title: "App organization"
source_url: "https://developer.apple.com/documentation/swiftui/app-organization"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/App-organization"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "12673edba76772f4f5bf8310829a52c7a36b02528a3644e2bdba3c43bb8456a0"
source_etag: "W/\"7ea07a75b6a4f46f69ef8c220a4fc02d\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App organization

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Define the entry point and top-level structure of your app.

Describe your app’s structure declaratively, much like you declare a view’s appearance. Create a type that conforms to the App protocol and use it to enumerate the Scenes that represent aspects of your app’s user interface. SwiftUI enables you to write code that works across all of Apple’s platforms. However, it also enables you to tailor your app to the specific capabilities of each platform. For example, if you need to respond to the callbacks that the system traditionally makes on a UIKit, AppKit, or WatchKit app’s delegate, define a delegate object and instantiate it in your app structure using an appropriate delegate adaptor property wrapper, like UIApplicationDelegateAdaptor. For platform-specific design guidance, see Getting started in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [App](swiftui-app.md) — A type that represents the structure and behavior of an app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [UIApplicationDelegateAdaptor](https://developer.apple.com/documentation/swiftui/uiapplicationdelegateadaptor) — A property wrapper type that you use to create a UIKit app delegate. _(Apple Developer; expandir sob demanda)_
- [Getting started](https://developer.apple.com/design/Human-Interface-Guidelines/getting-started) — Create an app or game that feels at home on every platform you support. _(Apple Developer; expandir sob demanda)_

### Creating an app

- [Destination Video](visionos-destination-video.md) — Leverage SwiftUI to build an immersive media experience in a multiplatform app. _(contexto local)_
- [Hello World](https://developer.apple.com/documentation/visionOS/World) — Use windows, volumes, and immersive spaces to teach people about the Earth. _(Apple Developer; expandir sob demanda)_
- [Backyard Birds: Building an app with SwiftData and widgets](https://developer.apple.com/documentation/swiftui/backyard-birds-sample) — Create an app with persistent data, interactive widgets, and an all new in-app purchase experience. _(Apple Developer; expandir sob demanda)_
- [Food Truck: Building a SwiftUI multiplatform app](https://developer.apple.com/documentation/swiftui/food-truck-building-a-swiftui-multiplatform-app) — Create a single codebase and app target for Mac, iPad, and iPhone. _(Apple Developer; expandir sob demanda)_
- [Fruta: Building a feature-rich app with SwiftUI](https://developer.apple.com/documentation/AppClip/fruta-building-a-feature-rich-app-with-swiftui) — Create a shared codebase to build a multiplatform app that offers widgets and an App Clip. _(Apple Developer; expandir sob demanda)_
- [Migrating to the SwiftUI life cycle](https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle) — Use a scene-based life cycle in SwiftUI while keeping your existing codebase. _(Apple Developer; expandir sob demanda)_

### Targeting iOS and iPadOS

- [UILaunchScreen](https://developer.apple.com/documentation/BundleResources/Information-Property-List/UILaunchScreen) — The user interface to show while an app launches. _(Apple Developer; expandir sob demanda)_
- [UILaunchScreens](https://developer.apple.com/documentation/BundleResources/Information-Property-List/UILaunchScreens) — The user interfaces to show while an app launches in response to different URL schemes. _(Apple Developer; expandir sob demanda)_

### Targeting macOS

- [NSApplicationDelegateAdaptor](https://developer.apple.com/documentation/swiftui/nsapplicationdelegateadaptor) — A property wrapper type that you use to create an AppKit app delegate. _(Apple Developer; expandir sob demanda)_

### Targeting watchOS

- [WKApplicationDelegateAdaptor](https://developer.apple.com/documentation/swiftui/wkapplicationdelegateadaptor) — A property wrapper that is used in to provide a delegate from WatchKit. _(Apple Developer; expandir sob demanda)_
- [WKExtensionDelegateAdaptor](https://developer.apple.com/documentation/swiftui/wkextensiondelegateadaptor) — A property wrapper type that you use to create a WatchKit extension delegate. _(Apple Developer; expandir sob demanda)_

### Targeting tvOS

- [Creating a tvOS media catalog app in SwiftUI](https://developer.apple.com/documentation/swiftui/creating-a-tvos-media-catalog-app-in-swiftui) — Build standard content lockups and rows of content shelves for your tvOS app. _(Apple Developer; expandir sob demanda)_

### Handling system recenter events

- [WorldRecenterPhase](https://developer.apple.com/documentation/swiftui/worldrecenterphase) — A type that represents information associated with a phase of a system recenter event. Values of this type are passed to the closure specified… _(Apple Developer; expandir sob demanda)_

### App structure

- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(contexto local)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(contexto local)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(contexto local)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(contexto local)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/app-organization)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `12673edba76772f4f5bf8310829a52c7a36b02528a3644e2bdba3c43bb8456a0`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
