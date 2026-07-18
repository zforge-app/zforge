---
title: "WatchKit"
source_url: "https://developer.apple.com/documentation/WatchKit"
source_identifier: "doc://com.apple.watchkit/documentation/WatchKit"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "84a0addd5917e8626b809ba9eb5ab0387e8587798e2b0715b22604a80a8eb4e9"
source_etag: "W/\"8f878e1943d4c0759ca301054ec0a61c\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Overview"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# WatchKit

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Framework
- Módulo: WatchKit
- Relevância para Zforge: Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge.
- Disponibilidade: watchOS 2.0+

## Síntese

**Resumo oficial:** Build watchOS apps that use features the app delegate monitors or controls, such as background tasks and extended runtime sessions.

The WatchKit framework provides infrastructure for creating watchOS apps, including an extension delegate that manages background tasks, extended runtime sessions, and Siri intents. The framework also performs other support tasks, such as accessing information about the user’s Apple Watch. You can also use WatchKit to design your app’s user interface in a storyboard, connecting UI elements to an interface controller. Building your app with SwiftUI gives you more control over the user interface than designing it in a storyboard. When creating a new watchOS app, strongly consider using SwiftUI. For more information, see Building a watchOS app. For more information on building watchOS apps, see watchOS apps.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [SwiftUI](swiftui.md) — Declare the user interface and behavior for your app on every platform. _(contexto local)_
- [Building a watchOS app](https://developer.apple.com/documentation/watchOS-Apps/building_a_watchos_app) — Set up your app’s life cycle and create its user interface with SwiftUI. _(Apple Developer; expandir sob demanda)_
- [watchOS apps](https://developer.apple.com/documentation/watchOS-Apps) — Build watchOS apps that combine complications, notifications, and Siri to create a personal experience on Apple Watch. _(Apple Developer; expandir sob demanda)_

### App structure

- [Setting up a watchOS project](https://developer.apple.com/documentation/watchOS-Apps/setting-up-a-watchos-project) — Create a new watchOS project or add a watch target to an existing iOS project. _(Apple Developer; expandir sob demanda)_
- [WKApplication](https://developer.apple.com/documentation/watchkit/wkapplication) — The centralized point of control and coordination for apps with a single watchOS app target. _(Apple Developer; expandir sob demanda)_
- [WKApplicationDelegate](https://developer.apple.com/documentation/watchkit/wkapplicationdelegate) — A collection of methods that manages the app-level behavior for a single-target watchOS app. _(Apple Developer; expandir sob demanda)_
- [WKExtension](https://developer.apple.com/documentation/watchkit/wkextension) — The centralized point of control and coordination for extension-based apps running in watchOS. _(Apple Developer; expandir sob demanda)_
- [WKExtensionDelegate](https://developer.apple.com/documentation/watchkit/wkextensiondelegate) — A collection of methods that manages the app-level behavior of a WatchKit extension. _(Apple Developer; expandir sob demanda)_
- [WKApplicationMain(_:_:_:)](https://developer.apple.com/documentation/watchkit/wkapplicationmain(_:_:_:)) — Creates the application object and the application delegate, and sets up the app’s event cycle. _(Apple Developer; expandir sob demanda)_
- [WKInterfaceDevice](https://developer.apple.com/documentation/watchkit/wkinterfacedevice) — An object that provides information about the user’s Apple Watch. _(Apple Developer; expandir sob demanda)_
- [WKPrefersNetworkUponForeground](https://developer.apple.com/documentation/BundleResources/Information-Property-List/WKPrefersNetworkUponForeground) — A Boolean value that indicates whether an app requires network access on launch. _(Apple Developer; expandir sob demanda)_

### Runtime management

- [Background execution](https://developer.apple.com/documentation/watchkit/background-execution) — Manage background sessions and tasks. _(Apple Developer; expandir sob demanda)_
- [Life cycles](https://developer.apple.com/documentation/watchkit/life-cycles) — Receive and respond to life-cycle notifications. _(Apple Developer; expandir sob demanda)_
- [Using extended runtime sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions) — Create an extended runtime session that continues running your app after the user stops interacting with it. _(Apple Developer; expandir sob demanda)_
- [WKExtendedRuntimeSession](https://developer.apple.com/documentation/watchkit/wkextendedruntimesession) — A session that continues to run your app after the user has stopped interacting. _(Apple Developer; expandir sob demanda)_
- [Interacting with Bluetooth peripherals during background app refresh](https://developer.apple.com/documentation/watchkit/interacting-with-bluetooth-peripherals-during-background-app-refresh) — Keep your complications up-to-date by reading values from a Bluetooth peripheral while your app is running in the background. _(Apple Developer; expandir sob demanda)_

### User interface

- [Storyboard support](https://developer.apple.com/documentation/watchkit/storyboard-support) — Connect your code to storyboard elements using interface controllers, interface objects, and event handlers. _(Apple Developer; expandir sob demanda)_
- [NowPlayingView](https://developer.apple.com/documentation/watchkit/nowplayingview) — A view that displays the system’s Now Playing interface so that the user can control audio. _(Apple Developer; expandir sob demanda)_

### Errors

- [WatchKitError](https://developer.apple.com/documentation/watchkit/watchkiterror) — An error reported by WatchKit. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/WatchKit)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `84a0addd5917e8626b809ba9eb5ab0387e8587798e2b0715b22604a80a8eb4e9`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
