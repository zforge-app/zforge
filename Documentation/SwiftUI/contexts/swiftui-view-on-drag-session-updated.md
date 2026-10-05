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

## Summary

Callback follows phases of gesture and transference. The web documentation shows example signatures different from those available in SDK macOS 27.0: in SDK see draggedItemIDs(for:) and ended(DropOperation). Do not infer that ending gesture proves publication of content.

## Declaration

```swift
nonisolated func onDragSessionUpdated(_ onUpdate: @escaping (DragSession) -> Void) -> some View

```

## Content map

- declarations
- content

## Secondary links

- [DragSession](https://developer.apple.com/documentation/swiftui/dragsession) — expand on demand.
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand.
- [View](https://developer.apple.com/documentation/swiftui/view) — expand on demand.
- [Void](https://developer.apple.com/documentation/swift/void) — expand on demand.
- [dragConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dragconfiguration(_:)) — expand on demand.
- [dragContainer(for:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:in:_:)) — expand on demand.
- [dragContainer(for:itemID:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:itemid:in:_:)) — expand on demand.
- [dragContainerSelection(_:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/dragcontainerselection(_:containernamespace:)) — expand on demand.
- [dragPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/dragpreviewsformation(_:)) — expand on demand.
- [draggable(_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:)) — expand on demand.
- [draggable(_:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:containernamespace:_:)) — expand on demand.
- [draggable(_:id:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:containernamespace:_:)) — expand on demand.
- [draggable(_:id:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:item:containernamespace:)) — expand on demand.
- [draggable(_:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:item:containernamespace:)) — expand on demand.
- [draggable(_:preview:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:preview:)) — expand on demand.
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(containeritemid:containernamespace:)) — expand on demand.
- [dropConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dropconfiguration(_:)) — expand on demand.
- [dropDestination(for:isEnabled:action:)](https://developer.apple.com/documentation/swiftui/view/dropdestination(for:isenabled:action:)) — expand on demand.
- [dropPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/droppreviewsformation(_:)) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/ondragsessionupdated(_:)).
- Capture of a page, without going through secondary links. SDK consulted: macOS 27.0, Xcode local.
