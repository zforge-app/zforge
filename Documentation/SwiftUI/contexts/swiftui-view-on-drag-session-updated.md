---
title: "onDragSessionUpdated(_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/ondragsessionupdated(_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/onDragSessionUpdated(_:)"
captured_at: "2026-10-04T22:10:19.050472+00:00"
source_sha256: "424da9026779798aecec79712a37212d4744cf9c88fc4b8760e767b504ec059b"
source_etag: "\"7434-65b3b3b6add2b\""
source_last_modified: null
source_format: "application/json"
platforms: [{"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "iOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "iPadOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "Mac Catalyst", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "26.0", "name": "macOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "visionOS", "unavailable": false}]
authority: "Apple Developer"
confidence: "primary-source"
---

# onDragSessionUpdated(_:)

## Síntese

O callback acompanha fases do gesto e transferência. A documentação web mostra assinaturas de exemplo diferentes das disponíveis no SDK macOS 27.0: no SDK consultar draggedItemIDs(for:) e ended(DropOperation). Não inferir que encerrar o gesto prova publicação de conteúdo.

## Declaração

```swift
nonisolated func onDragSessionUpdated(_ onUpdate: @escaping (DragSession) -> Void) -> some View

```

## Mapa do conteúdo

- declarations
- content

## Links secundários

- [DragSession](https://developer.apple.com/documentation/swiftui/dragsession) — expandir sob demanda.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — expandir sob demanda.
- [View](https://developer.apple.com/documentation/swiftui/view) — expandir sob demanda.
- [Void](https://developer.apple.com/documentation/swift/void) — expandir sob demanda.
- [dragConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dragconfiguration(_:)) — expandir sob demanda.
- [dragContainer(for:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:in:_:)) — expandir sob demanda.
- [dragContainer(for:itemID:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)) — expandir sob demanda.
- [dragContainerSelection(_:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/dragcontainerselection(_:containernamespace:)) — expandir sob demanda.
- [dragPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/dragpreviewsformation(_:)) — expandir sob demanda.
- [draggable(_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:)) — expandir sob demanda.
- [draggable(_:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:containernamespace:_:)) — expandir sob demanda.
- [draggable(_:id:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:containernamespace:_:)) — expandir sob demanda.
- [draggable(_:id:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:item:containernamespace:)) — expandir sob demanda.
- [draggable(_:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:item:containernamespace:)) — expandir sob demanda.
- [draggable(_:preview:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:preview:)) — expandir sob demanda.
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(containeritemid:containernamespace:)) — expandir sob demanda.
- [dropConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dropconfiguration(_:)) — expandir sob demanda.
- [dropDestination(for:isEnabled:action:)](https://developer.apple.com/documentation/swiftui/view/dropdestination(for:isenabled:action:)) — expandir sob demanda.
- [dropPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/droppreviewsformation(_:)) — expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/ondragsessionupdated(_:)).
- Captura de uma página, sem percorrer links secundários. SDK consultado: macOS 27.0, Xcode local.
