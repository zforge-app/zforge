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

## Summary

The container associates identities to Transferable payloads and reuses cell representations. Zforge already uses this path for local files; virtual sources need to preserve the presentation in the same way.

## Declaration

```swift
nonisolated func dragContainer<ItemID, Item, Data>(for itemType: Item.Type = Item.self, itemID: KeyPath<Item, ItemID>, in namespace: Namespace.ID? = nil, _ payload: @escaping (Array<ItemID>) -> Data) -> some View where ItemID : Hashable, ItemID : Sendable, Item : Transferable, Item == Data.Element, Data : Collection

```

## Content map

- declarations
- parameters
- content
- content

## Secondary links

- [Array](https://developer.apple.com/documentation/swift/array) — expand on demand.
- [Collection](https://developer.apple.com/documentation/swift/collection) — expand on demand.
- [DragConfiguration](https://developer.apple.com/documentation/swiftui/dragconfiguration) — expand on demand.
- [DropConfiguration](https://developer.apple.com/documentation/swiftui/dropconfiguration) — expand on demand.
- [Element](https://developer.apple.com/documentation/swift/sequence/element) — expand on demand.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — expand on demand.
- [KeyPath](https://developer.apple.com/documentation/swift/keypath) — expand on demand.
- [Namespace.ID](https://developer.apple.com/documentation/swiftui/namespace/id) — expand on demand.
- [Namespace](https://developer.apple.com/documentation/swiftui/namespace) — expand on demand.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — expand on demand.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expand on demand.
- [View](https://developer.apple.com/documentation/swiftui/view) — expand on demand.
- [dragConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dragconfiguration(_:)) — expand on demand.
- [dragContainer(for:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:in:_:)) — expand on demand.
- [dragContainer(for:itemID:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)-7xrvw) — expand on demand.
- [dragContainerSelection(_:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/dragcontainerselection(_:containernamespace:)) — expand on demand.
- [draggable(_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:)) — expand on demand.
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(containeritemid:containernamespace:)) — expand on demand.
- [dropConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dropconfiguration(_:)) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)).
- Capture of a page, without going through secondary links. SDK consulted: macOS 27.0, Xcode local.
