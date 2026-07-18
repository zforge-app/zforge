---
title: "System events"
source_url: "https://developer.apple.com/documentation/swiftui/system-events"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/System-events"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "b541819cfce064e0c8660dce87a6b31656ea8ff52397679f96d7669cac029f62"
source_etag: "W/\"79634cf1e85cec940aec2072729e824e\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# System events

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** React to system events, like opening a URL.

Specify view and scene modifiers to indicate how your app responds to certain system events. For example, you can use the onOpenURL(perform:) view modifier to define an action to take when your app receives a universal link, or use the backgroundTask(_:action:) scene modifier to specify an asynchronous task to carry out in response to a background task event, like the completion of a background URL session.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [onOpenURL(perform:)](https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)) — Registers a handler to invoke in response to a URL that your app receives. _(Apple Developer; expandir sob demanda)_
- [backgroundTask(_:action:)](https://developer.apple.com/documentation/swiftui/scene/backgroundtask(_:action:)) — Runs the specified action when the system provides a background task. _(Apple Developer; expandir sob demanda)_

### Sending and receiving user activities

- [Restoring your app’s state with SwiftUI](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui) — Provide app continuity for users by preserving their current activities. _(Apple Developer; expandir sob demanda)_
- [userActivity(_:element:_:)](https://developer.apple.com/documentation/swiftui/view/useractivity(_:element:_:)) — Advertises a user activity type. _(Apple Developer; expandir sob demanda)_
- [userActivity(_:isActive:_:)](https://developer.apple.com/documentation/swiftui/view/useractivity(_:isactive:_:)) — Advertises a user activity type. _(Apple Developer; expandir sob demanda)_
- [onContinueUserActivity(_:perform:)](https://developer.apple.com/documentation/swiftui/view/oncontinueuseractivity(_:perform:)) — Registers a handler to invoke in response to a user activity that your app receives. _(Apple Developer; expandir sob demanda)_

### Sending and receiving URLs

- [openURL](https://developer.apple.com/documentation/swiftui/environmentvalues/openurl) — An action that opens a URL. _(Apple Developer; expandir sob demanda)_
- [OpenURLAction](https://developer.apple.com/documentation/swiftui/openurlaction) — An action that opens a URL. _(Apple Developer; expandir sob demanda)_

### Handling external events

- [handlesExternalEvents(matching:)](https://developer.apple.com/documentation/swiftui/scene/handlesexternalevents(matching:)) — Specifies the external events for which SwiftUI opens a new instance of the modified scene. _(Apple Developer; expandir sob demanda)_
- [handlesExternalEvents(preferring:allowing:)](https://developer.apple.com/documentation/swiftui/view/handlesexternalevents(preferring:allowing:)) — Specifies the external events that the view’s scene handles if the scene is already open. _(Apple Developer; expandir sob demanda)_

### Handling background tasks

- [BackgroundTask](https://developer.apple.com/documentation/swiftui/backgroundtask) — The kinds of background tasks that your app or extension can handle. _(Apple Developer; expandir sob demanda)_
- [SnapshotData](https://developer.apple.com/documentation/swiftui/snapshotdata) — The associated data of a snapshot background task. _(Apple Developer; expandir sob demanda)_
- [SnapshotResponse](https://developer.apple.com/documentation/swiftui/snapshotresponse) — Your application’s response to a snapshot background task. _(Apple Developer; expandir sob demanda)_

### Importing and exporting transferable items

- [importableFromServices(for:action:)](https://developer.apple.com/documentation/swiftui/view/importablefromservices(for:action:)) — Enables importing items from services, such as Continuity Camera on macOS. _(Apple Developer; expandir sob demanda)_
- [exportableToServices(_:)](https://developer.apple.com/documentation/swiftui/view/exportabletoservices(_:)) — Exports items for consumption by shortcuts, quick actions, and services. _(Apple Developer; expandir sob demanda)_
- [exportableToServices(_:onEdit:)](https://developer.apple.com/documentation/swiftui/view/exportabletoservices(_:onedit:)) — Exports read-write items for consumption by shortcuts, quick actions, and services. _(Apple Developer; expandir sob demanda)_

### Importing and exporting using item providers

- [importsItemProviders(_:onImport:)](https://developer.apple.com/documentation/swiftui/view/importsitemproviders(_:onimport:)) — Enables importing item providers from services, such as Continuity Camera on macOS. _(Apple Developer; expandir sob demanda)_
- [exportsItemProviders(_:onExport:)](https://developer.apple.com/documentation/swiftui/view/exportsitemproviders(_:onexport:)) — Exports a read-only item provider for consumption by shortcuts, quick actions, and services. _(Apple Developer; expandir sob demanda)_
- [exportsItemProviders(_:onExport:onEdit:)](https://developer.apple.com/documentation/swiftui/view/exportsitemproviders(_:onexport:onedit:)) — Exports a read-write item provider for consumption by shortcuts, quick actions, and services. _(Apple Developer; expandir sob demanda)_

### Event handling

- [Gestures](swiftui-gestures.md) — Define interactions from taps, clicks, and swipes to fine-grained gestures. _(contexto local)_
- [Input events](swiftui-input-events.md) — Respond to input from a hardware device, like a keyboard or a Touch Bar. _(contexto local)_
- [Clipboard](swiftui-clipboard.md) — Enable people to move or duplicate items by issuing Copy and Paste commands. _(contexto local)_
- [Drag and drop](swiftui-drag-and-drop.md) — Enable people to move or duplicate items by dragging them from one location to another. _(contexto local)_
- [Focus](swiftui-focus.md) — Identify and control which visible object responds to user interaction. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/system-events)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `b541819cfce064e0c8660dce87a6b31656ea8ff52397679f96d7669cac029f62`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
