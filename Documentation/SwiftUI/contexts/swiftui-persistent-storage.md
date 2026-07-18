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

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Store data for use across sessions of your app.

The operating system provides ways to store data when your app closes, so that when people open your app again later, they can continue working without interruption. The mechanism that you use depends on factors like what and how much you need to store, whether you need serialized or random access to the data, and so on. You use the same kinds of storage in a SwiftUI app that you use in any other app. For example, you can access files on disk using the FileManager interface. However, SwiftUI also provides conveniences that make it easier to use certain kinds of persistent storage in a declarative environment. For example, you can use FetchRequest and FetchedResults to interact with a Core Data model.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [FileManager](https://developer.apple.com/documentation/Foundation/FileManager) — A convenient interface to the contents of the file system, and the primary means of interacting with it. _(Apple Developer; expandir sob demanda)_
- [FetchRequest](https://developer.apple.com/documentation/swiftui/fetchrequest) — A property wrapper type that retrieves entities from a Core Data persistent store. _(Apple Developer; expandir sob demanda)_
- [FetchedResults](https://developer.apple.com/documentation/swiftui/fetchedresults) — A collection of results retrieved from a Core Data store. _(Apple Developer; expandir sob demanda)_

### Saving state across app launches

- [Restoring your app’s state with SwiftUI](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui) — Provide app continuity for users by preserving their current activities. _(Apple Developer; expandir sob demanda)_
- [defaultAppStorage(_:)](https://developer.apple.com/documentation/swiftui/view/defaultappstorage(_:)) — The default store used by contained within the view. _(Apple Developer; expandir sob demanda)_
- [AppStorage](https://developer.apple.com/documentation/swiftui/appstorage) — A property wrapper type that reflects a value from and invalidates a view on a change in value in that user default. _(Apple Developer; expandir sob demanda)_
- [SceneStorage](https://developer.apple.com/documentation/swiftui/scenestorage) — A property wrapper type that reads and writes to persisted, per-scene storage. _(Apple Developer; expandir sob demanda)_

### Accessing Core Data

- [Loading and displaying a large data feed](https://developer.apple.com/documentation/swiftui/loading-and-displaying-a-large-data-feed) — Consume data in the background, and lower memory use by batching imports and preventing duplicate records. _(Apple Developer; expandir sob demanda)_
- [managedObjectContext](https://developer.apple.com/documentation/swiftui/environmentvalues/managedobjectcontext) — _Apple Developer; expandir sob demanda_
- [SectionedFetchRequest](https://developer.apple.com/documentation/swiftui/sectionedfetchrequest) — A property wrapper type that retrieves entities, grouped into sections, from a Core Data persistent store. _(Apple Developer; expandir sob demanda)_
- [SectionedFetchResults](https://developer.apple.com/documentation/swiftui/sectionedfetchresults) — A collection of results retrieved from a Core Data persistent store, grouped into sections. _(Apple Developer; expandir sob demanda)_

### Data and storage

- [Model data](swiftui-model-data.md) — Manage the data that your app uses to drive its interface. _(contexto local)_
- [Environment values](swiftui-environment-values.md) — Share data throughout a view hierarchy using the environment. _(contexto local)_
- [Preferences](swiftui-preferences.md) — Indicate configuration preferences from views to their container views. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/persistent-storage)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `e44ef095dadc5943ed06bca345a4d26c368a775700a4528bee817b1831fd15a0`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
