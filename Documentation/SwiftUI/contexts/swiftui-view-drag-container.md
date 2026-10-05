---
title: "dragContainer(for:itemID:in:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/dragContainer(for:itemID:in:_:)"
captured_at: "2026-10-04T22:10:19.050472+00:00"
source_sha256: "127a60e70dd01577e61a8169502f556fe9b28d5ea0191bd865e2562da12d13bb"
source_etag: "\"7bfc-65b3b3b74d145\""
source_last_modified: null
source_format: "application/json"
platforms: [{"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "iOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "iPadOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "Mac Catalyst", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "26.0", "name": "macOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "27.0", "name": "visionOS", "unavailable": false}]
authority: "Apple Developer"
confidence: "primary-source"
---

# dragContainer(for:itemID:in:_:)

## Síntese

O container associa identidades a payloads Transferable e reutiliza as representações das células. O Zforge já usa esse caminho para arquivos locais; fontes virtuais precisam preservar a apresentação do mesmo modo.

## Declaração

```swift
nonisolated func dragContainer<ItemID, Item, Data>(for itemType: Item.Type = Item.self, itemID: KeyPath<Item, ItemID>, in namespace: Namespace.ID? = nil, _ payload: @escaping (Array<ItemID>) -> Data) -> some View where ItemID : Hashable, ItemID : Sendable, Item : Transferable, Item == Data.Element, Data : Collection

```

## Mapa do conteúdo

- declarations
- parameters
- content
- content

## Links secundários

- [Array](https://developer.apple.com/documentation/swift/array) — expandir sob demanda.
- [Collection](https://developer.apple.com/documentation/swift/collection) — expandir sob demanda.
- [DragConfiguration](https://developer.apple.com/documentation/swiftui/dragconfiguration) — expandir sob demanda.
- [DropConfiguration](https://developer.apple.com/documentation/swiftui/dropconfiguration) — expandir sob demanda.
- [Element](https://developer.apple.com/documentation/swift/sequence/element) — expandir sob demanda.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — expandir sob demanda.
- [KeyPath](https://developer.apple.com/documentation/swift/keypath) — expandir sob demanda.
- [Namespace.ID](https://developer.apple.com/documentation/swiftui/namespace/id) — expandir sob demanda.
- [Namespace](https://developer.apple.com/documentation/swiftui/namespace) — expandir sob demanda.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — expandir sob demanda.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — expandir sob demanda.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expandir sob demanda.
- [View](https://developer.apple.com/documentation/swiftui/view) — expandir sob demanda.
- [dragConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dragconfiguration(_:)) — expandir sob demanda.
- [dragContainer(for:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:in:_:)) — expandir sob demanda.
- [dragContainer(for:itemID:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)-7xrvw) — expandir sob demanda.
- [dragContainerSelection(_:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/dragcontainerselection(_:containernamespace:)) — expandir sob demanda.
- [draggable(_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:)) — expandir sob demanda.
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(containeritemid:containernamespace:)) — expandir sob demanda.
- [dropConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dropconfiguration(_:)) — expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)).
- Captura de uma página, sem percorrer links secundários. SDK consultado: macOS 27.0, Xcode local.
