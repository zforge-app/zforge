---
title: "UIKit integration"
source_url: "https://developer.apple.com/documentation/swiftui/uikit-integration"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/UIKit-integration"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "88142549e5cf001b9fd1bb198101b4b03123effd5ce65961d8aa33930e5616d1"
source_etag: "W/\"44befdf2195e675c5b02799d476916d5\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# UIKit integration

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge.

## Síntese

**Resumo oficial:** Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app.

Integrate SwiftUI with your app’s existing content using hosting controllers to add SwiftUI views into UIKit interfaces. A hosting controller wraps a set of SwiftUI views in a form that you can then add to your storyboard-based app. You can also add UIKit views and view controllers to your SwiftUI interfaces. A representable object wraps the designated view or view controller, and facilitates communication between the wrapped object and your SwiftUI views. For design guidance, see the following sections in the Human Interface Guidelines: Designing for iOS Designing for iPadOS Designing for tvOS

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Designing for iOS](https://developer.apple.com/design/Human-Interface-Guidelines/designing-for-ios) — People depend on their iPhone to help them stay connected, play games, view media, accomplish tasks, and track personal data in any location and… _(Apple Developer; expandir sob demanda)_
- [Designing for iPadOS](https://developer.apple.com/design/Human-Interface-Guidelines/designing-for-ipados) — People value the power, mobility, and flexibility of iPad as they enjoy media, play games, perform detailed productivity tasks, and bring their creations to… _(Apple Developer; expandir sob demanda)_
- [Designing for tvOS](https://developer.apple.com/design/Human-Interface-Guidelines/designing-for-tvos) — People enjoy the vibrant content, immersive experiences, and streamlined interactions that tvOS delivers in media and games, as well as in fitness, education, and… _(Apple Developer; expandir sob demanda)_

### Displaying SwiftUI views in UIKit

- [Using SwiftUI with UIKit](https://developer.apple.com/documentation/UIKit/using-swiftui-with-uikit) — Learn how to incorporate SwiftUI views into a UIKit app. _(Apple Developer; expandir sob demanda)_
- [Unifying your app’s animations](https://developer.apple.com/documentation/swiftui/unifying-your-app-s-animations) — Create a consistent UI animation experience across SwiftUI, UIKit, and AppKit. _(Apple Developer; expandir sob demanda)_
- [UIHostingController](https://developer.apple.com/documentation/swiftui/uihostingcontroller) — A UIKit view controller that manages a SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [UIHostingControllerSizingOptions](https://developer.apple.com/documentation/swiftui/uihostingcontrollersizingoptions) — Options for how a hosting controller tracks its content’s size. _(Apple Developer; expandir sob demanda)_
- [UIHostingConfiguration](https://developer.apple.com/documentation/swiftui/uihostingconfiguration) — A content configuration suitable for hosting a hierarchy of SwiftUI views. _(Apple Developer; expandir sob demanda)_
- [UIHostingSceneDelegate](https://developer.apple.com/documentation/swiftui/uihostingscenedelegate) — Extends to bridge SwiftUI scenes. _(Apple Developer; expandir sob demanda)_

### Adding UIKit views to SwiftUI view hierarchies

- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable) — A wrapper for a UIKit view that you use to integrate that view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [UIViewRepresentableContext](https://developer.apple.com/documentation/swiftui/uiviewrepresentablecontext) — Contextual information about the state of the system that you use to create and update your UIKit view. _(Apple Developer; expandir sob demanda)_
- [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable) — A view that represents a UIKit view controller. _(Apple Developer; expandir sob demanda)_
- [UIViewControllerRepresentableContext](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentablecontext) — Contextual information about the state of the system that you use to create and update your UIKit view controller. _(Apple Developer; expandir sob demanda)_

### Adding UIKit gesture recognizers into SwiftUI view hierarchies

- [UIGestureRecognizerRepresentable](https://developer.apple.com/documentation/swiftui/uigesturerecognizerrepresentable) — A wrapper for a that you use to integrate that gesture recognizer into your SwiftUI hierarchy. _(Apple Developer; expandir sob demanda)_
- [UIGestureRecognizerRepresentableContext](https://developer.apple.com/documentation/swiftui/uigesturerecognizerrepresentablecontext) — Contextual information about the state of the system that you use to create and update a represented gesture recognizer. _(Apple Developer; expandir sob demanda)_
- [UIGestureRecognizerRepresentableCoordinateSpaceConverter](https://developer.apple.com/documentation/swiftui/uigesturerecognizerrepresentablecoordinatespaceconverter) — A proxy structure used to convert locations to/from coordinate spaces in the hierarchy of the SwiftUI view associated with a UIGestureRecognizerRepresentable. _(Apple Developer; expandir sob demanda)_

### Sharing configuration information

- [UITraitBridgedEnvironmentKey](https://developer.apple.com/documentation/swiftui/uitraitbridgedenvironmentkey) — _Apple Developer; expandir sob demanda_

### Hosting an ornament in UIKit

- [UIHostingOrnament](https://developer.apple.com/documentation/swiftui/uihostingornament) — A model that represents an ornament suitable for being hosted in UIKit. _(Apple Developer; expandir sob demanda)_
- [UIOrnament](https://developer.apple.com/documentation/swiftui/uiornament) — The abstract base class that represents an ornament. _(Apple Developer; expandir sob demanda)_

### Framework integration

- [AppKit integration](swiftui-appkit-integration.md) — Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app. _(contexto local)_
- [WatchKit integration](swiftui-watchkit-integration.md) — Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app. _(contexto local)_
- [Technology-specific views](swiftui-technology-specific-views.md) — Use SwiftUI views that other Apple frameworks provide. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/uikit-integration)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `88142549e5cf001b9fd1bb198101b4b03123effd5ce65961d8aa33930e5616d1`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
