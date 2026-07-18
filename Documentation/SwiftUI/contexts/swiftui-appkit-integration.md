---
title: "AppKit integration"
source_url: "https://developer.apple.com/documentation/swiftui/appkit-integration"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/AppKit-integration"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "10a53535b11cd0a1fce1deeb51ac5d2bd2e893e8b03197f3bc73f3d05db7c206"
source_etag: "W/\"08620d12aee7e65ac60f36d128eb0a84\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# AppKit integration

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.

## Síntese

**Resumo oficial:** Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app.

Integrate SwiftUI with your app’s existing content using hosting controllers to add SwiftUI views into AppKit interfaces. A hosting controller wraps a set of SwiftUI views in a form that you can then add to your storyboard-based app. You can also add AppKit views and view controllers to your SwiftUI interfaces. A representable object wraps the designated view or view controller, and facilitates communication between the wrapped object and your SwiftUI views. For design guidance, see Designing for macOS in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Designing for macOS](https://developer.apple.com/design/Human-Interface-Guidelines/designing-for-macos) — People rely on the power, spaciousness, and flexibility of a Mac as they perform in-depth productivity tasks, view media or content, and play games… _(Apple Developer; expandir sob demanda)_

### Displaying SwiftUI views in AppKit

- [Unifying your app’s animations](https://developer.apple.com/documentation/swiftui/unifying-your-app-s-animations) — Create a consistent UI animation experience across SwiftUI, UIKit, and AppKit. _(Apple Developer; expandir sob demanda)_
- [NSHostingController](https://developer.apple.com/documentation/swiftui/nshostingcontroller) — An AppKit view controller that hosts SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [NSHostingView](https://developer.apple.com/documentation/swiftui/nshostingview) — An AppKit view that hosts a SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [NSHostingMenu](https://developer.apple.com/documentation/swiftui/nshostingmenu) — An AppKit menu with menu items that are defined by a SwiftUI View. _(Apple Developer; expandir sob demanda)_
- [NSHostingSizingOptions](https://developer.apple.com/documentation/swiftui/nshostingsizingoptions) — Options for how hosting views and controllers reflect their content’s size into Auto Layout constraints. _(Apple Developer; expandir sob demanda)_
- [NSHostingSceneRepresentation](https://developer.apple.com/documentation/swiftui/nshostingscenerepresentation) — An AppKit type that hosts and can present SwiftUI scenes _(Apple Developer; expandir sob demanda)_
- [NSHostingSceneBridgingOptions](https://developer.apple.com/documentation/swiftui/nshostingscenebridgingoptions) — Options for how hosting views and controllers manage aspects of the associated window. _(Apple Developer; expandir sob demanda)_

### Adding AppKit views to SwiftUI view hierarchies

- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable) — A wrapper that you use to integrate an AppKit view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [NSViewRepresentableContext](https://developer.apple.com/documentation/swiftui/nsviewrepresentablecontext) — Contextual information about the state of the system that you use to create and update your AppKit view. _(Apple Developer; expandir sob demanda)_
- [NSViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/nsviewcontrollerrepresentable) — A wrapper that you use to integrate an AppKit view controller into your SwiftUI interface. _(Apple Developer; expandir sob demanda)_
- [NSViewControllerRepresentableContext](https://developer.apple.com/documentation/swiftui/nsviewcontrollerrepresentablecontext) — Contextual information about the state of the system that you use to create and update your AppKit view controller. _(Apple Developer; expandir sob demanda)_

### Adding AppKit gesture recognizers into SwiftUI view hierarchies

- [NSGestureRecognizerRepresentable](https://developer.apple.com/documentation/swiftui/nsgesturerecognizerrepresentable) — A wrapper for an that you use to integrate that gesture recognizer into your SwiftUI hierarchy. _(Apple Developer; expandir sob demanda)_
- [NSGestureRecognizerRepresentableContext](https://developer.apple.com/documentation/swiftui/nsgesturerecognizerrepresentablecontext) — Contextual information about the state of the system that you use to create and update a represented gesture recognizer. _(Apple Developer; expandir sob demanda)_
- [NSGestureRecognizerRepresentableCoordinateSpaceConverter](https://developer.apple.com/documentation/swiftui/nsgesturerecognizerrepresentablecoordinatespaceconverter) — A structure used to convert locations to and from coordinate spaces in the hierarchy of the SwiftUI view associated with an NSGestureRecognizerRepresentable. _(Apple Developer; expandir sob demanda)_

### Framework integration

- [UIKit integration](swiftui-uikit-integration.md) — Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app. _(contexto local)_
- [WatchKit integration](swiftui-watchkit-integration.md) — Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app. _(contexto local)_
- [Technology-specific views](swiftui-technology-specific-views.md) — Use SwiftUI views that other Apple frameworks provide. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/appkit-integration)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `10a53535b11cd0a1fce1deeb51ac5d2bd2e893e8b03197f3bc73f3d05db7c206`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
