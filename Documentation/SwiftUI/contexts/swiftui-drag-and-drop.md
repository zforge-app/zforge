---
title: "Drag and drop"
source_url: "https://developer.apple.com/documentation/swiftui/drag-and-drop"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Drag-and-drop"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "d455ccf78fc1b22c79b48073df1d4da68bc337900bfa6abbf5c3a909905ffaaa"
source_etag: "W/\"934a41b3f616f06d6f31f28d21124ee5\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Drag and drop

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Enable people to move or duplicate items by dragging them from one location to another.

Drag and drop offers people a convenient way to move content from one part of your app to another, from one app to another, or to reorder content using an intuitive dragging gesture. Support this feature in your app by adding view modifiers to potential source and destination views within your app’s interface. In your modifiers, provide or accept types that conform to the Transferable protocol, or that conform to NSItemProviderReading and/or NSItemProviderWriting. In Swift, prefer using transferable items. For design guidance, see Drag and drop in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Transferable](https://developer.apple.com/documentation/CoreTransferable/Transferable) — A protocol that describes how a type interacts with transport APIs such as drag and drop or copy and paste. _(Apple Developer; expand on demand)_
- [NSItemProviderReading](https://developer.apple.com/documentation/Foundation/NSItemProviderReading) — The protocol for implementing a class to allow an item provider to create an instance of the class. _(Apple Developer; expand on demand)_
- [NSItemProviderWriting](https://developer.apple.com/documentation/Foundation/NSItemProviderWriting) — The protocol for implementing a class to allow an item provider to retrieve data from an instance of the class. _(Apple Developer; expand on demand)_
- [Drag and drop](https://developer.apple.com/design/Human-Interface-Guidelines/drag-and-drop) — Using drag and drop, people can move or duplicate selected photos, text, and other content by dragging the selection from one location to another. _(Apple Developer; expand on demand)_

### Essentials

- [Adopting drag and drop using SwiftUI](https://developer.apple.com/documentation/swiftui/adopting-drag-and-drop-using-swiftui) — Enable drag-and-drop interactions in lists, tables and custom views. _(Apple Developer; expand on demand)_
- [Making a view into a drag source](https://developer.apple.com/documentation/swiftui/making-a-view-into-a-drag-source) — Adopt draggable API to provide items for drag-and-drop operations. _(Apple Developer; expand on demand)_
- [Reordering items in lists, stacks, grids, and custom layouts](https://developer.apple.com/documentation/swiftui/reordering-items-in-lists-stacks-grids-and-custom-layouts) — Add drag-to-reorder interactions to SwiftUI layouts using reordering modifiers. _(Apple Developer; expand on demand)_

### Configuring drag-and-drop behavior

- [dragConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dragconfiguration(_:)) — Configures a drag session. _(Apple Developer; expand on demand)_
- [DragConfiguration](https://developer.apple.com/documentation/swiftui/dragconfiguration) — The behavior of the drag, proposed by the dragging source. A value that describes the drag operations a drag source supports. _(Apple Developer; expand on demand)_
- [dropConfiguration(_:)](https://developer.apple.com/documentation/swiftui/view/dropconfiguration(_:)) — Configures a drop session. _(Apple Developer; expand on demand)_
- [DropConfiguration](https://developer.apple.com/documentation/swiftui/dropconfiguration) — Describes the behavior of the drop. _(Apple Developer; expand on demand)_
- [dragContainer(for:in:_:)](https://developer.apple.com/documentation/swiftui/view/dragcontainer(for:in:_:)) — A container with draggable views where the drag payload is based on multiple identifiers of dragged items. _(Apple Developer; expand on demand)_
- [dragContainer(for:itemID:in:_:)](swiftui-view-drag-container.md) — A container with draggable views. _(Apple Developer; expand on demand)_
- [dragContainerSelection(_:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/dragcontainerselection(_:containernamespace:)) — Provides multiple item selection support for drag containers. _(Apple Developer; expand on demand)_

### Moving items

- [DragSession](https://developer.apple.com/documentation/swiftui/dragsession) — Describes the ongoing dragging session. _(Apple Developer; expand on demand)_
- [DropSession](https://developer.apple.com/documentation/swiftui/dropsession) — _Apple Developer; expand on demand_

### Moving transferable items

- [draggable(_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:)) — Activates this view as the source of a drag and drop operation. _(Apple Developer; expand on demand)_
- [draggable(_:preview:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:preview:)) — Activates this view as the source of a drag and drop operation. _(Apple Developer; expand on demand)_
- [draggable(_:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:containernamespace:_:)) — Activates this view as the source of a drag and drop operation, allowing to provide optional identifiable payload and specify the namespace of the… _(Apple Developer; expand on demand)_
- [draggable(_:id:containerNamespace:_:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:containernamespace:_:)) — Activates this view as the source of a drag and drop operation, allowing to provide optional payload and specify the namespace of the drag… _(Apple Developer; expand on demand)_
- [draggable(_:id:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:id:item:containernamespace:)) — Activates this view as the source of a drag and drop operation, allowing to provide optional payload and specify the namespace of the drag… _(Apple Developer; expand on demand)_
- [draggable(_:item:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(_:item:containernamespace:)) — Activates this view as the source of a drag and drop operation, allowing to provide optional identifiable payload and specify the namespace of the… _(Apple Developer; expand on demand)_
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/swiftui/view/draggable(containeritemid:containernamespace:)) — Inside a drag container, activates this view as the source of a drag and drop operation. Supports lazy drag containers. _(Apple Developer; expand on demand)_

### Moving items using item providers

- [itemProvider(_:)](https://developer.apple.com/documentation/swiftui/view/itemprovider(_:)) — Provides a closure that vends the drag representation to be used for a particular data element. _(Apple Developer; expand on demand)_
- [onDrag(_:preview:)](https://developer.apple.com/documentation/swiftui/view/ondrag(_:preview:)) — Activates this view as the source of a drag and drop operation. _(Apple Developer; expand on demand)_
- [onDrag(_:)](https://developer.apple.com/documentation/swiftui/view/ondrag(_:)) — Activates this view as the source of a drag and drop operation. _(Apple Developer; expand on demand)_
- [onDrop(of:isTargeted:perform:)](https://developer.apple.com/documentation/swiftui/view/ondrop(of:istargeted:perform:)) — Defines the destination of a drag-and-drop operation that handles the dropped content with a closure that you specify. _(Apple Developer; expand on demand)_
- [onDrop(of:delegate:)](https://developer.apple.com/documentation/swiftui/view/ondrop(of:delegate:)) — Defines the destination of a drag and drop operation using behavior controlled by the delegate that you provide. _(Apple Developer; expand on demand)_
- [DropDelegate](https://developer.apple.com/documentation/swiftui/dropdelegate) — An interface that you implement to interact with a drop operation in a view modified to accept drops. _(Apple Developer; expand on demand)_
- [performDrop(info:)](swiftui-dropdelegate-performdrop.md) — Start loading the accepted providers before the delegate returns. _(local context)_
- [DropProposal](https://developer.apple.com/documentation/swiftui/dropproposal) — The behavior of a drop. _(Apple Developer; expand on demand)_
- [DropOperation](https://developer.apple.com/documentation/swiftui/dropoperation) — Operation types that determine how a drag and drop session resolves when the user drops a drag item. _(Apple Developer; expand on demand)_
- [DropInfo](https://developer.apple.com/documentation/swiftui/dropinfo) — The current state of a drop. _(Apple Developer; expand on demand)_

### Reordering items

- [Making a card game with drag, drop, and reordering in SwiftUI](https://developer.apple.com/documentation/swiftui/making-a-card-game-with-drag-drop-and-reordering-in-swiftui) — Move cards between positions in a card game using drag, drop, and reordering modifiers. _(Apple Developer; expand on demand)_
- [reorderable()](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/reorderable()) — Enables reordering of views from this content inside the scope of a reorderable container modifier. _(Apple Developer; expand on demand)_
- [reorderable(collectionID:)](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/reorderable(collectionid:)) — Enables reordering views from this content within and between sections in the scope of a reorderable container modifier. _(Apple Developer; expand on demand)_
- [ReorderableSingleCollectionIdentifier](https://developer.apple.com/documentation/swiftui/reorderablesinglecollectionidentifier) — An opaque, empty type used to identify reorderable containers and modifiers with only a single collection. _(Apple Developer; expand on demand)_
- [reorderContainer(for:isEnabled:move:)](https://developer.apple.com/documentation/swiftui/view/reordercontainer(for:isenabled:move:)) — Defines a container of reorderable views. _(Apple Developer; expand on demand)_
- [reorderContainer(for:in:isEnabled:move:)](https://developer.apple.com/documentation/swiftui/view/reordercontainer(for:in:isenabled:move:)) — Defines a container of reorderable views, with a type you specify to identify sections. _(Apple Developer; expand on demand)_
- [reorderContainer(for:itemID:isEnabled:move:)](https://developer.apple.com/documentation/swiftui/view/reordercontainer(for:itemid:isenabled:move:)) — Defines a container of reorderable views, with a type and keypath you specify to identify items. _(Apple Developer; expand on demand)_
- [reorderContainer(for:itemID:in:isEnabled:move:)](https://developer.apple.com/documentation/swiftui/view/reordercontainer(for:itemid:in:isenabled:move:)) — Defines a container of reorderable views, with a type and keypath you use to identify items and a type you use to identify collections. _(Apple Developer; expand on demand)_
- [reorderDestination(for:in:)](https://developer.apple.com/documentation/swiftui/dropsession/reorderdestination(for:in:)) — Provides the destination value of a reordering operation that occurred in the container associated with this drop destination modifier. _(Apple Developer; expand on demand)_
- [reorderDestination(for:itemID:in:)](https://developer.apple.com/documentation/swiftui/dropsession/reorderdestination(for:itemid:in:)) — Provides the destination value of a reordering operation that occurred in the container associated with this drop destination modifier. _(Apple Developer; expand on demand)_
- [ReorderDifference](https://developer.apple.com/documentation/swiftui/reorderdifference) — The difference that a reordering operation produces. _(Apple Developer; expand on demand)_

### Describing preview formations

- [dragPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/dragpreviewsformation(_:)) — Describes the way dragged previews are visually composed. _(Apple Developer; expand on demand)_
- [dropPreviewsFormation(_:)](https://developer.apple.com/documentation/swiftui/view/droppreviewsformation(_:)) — Describes the way previews for a drop are composed. _(Apple Developer; expand on demand)_
- [DragDropPreviewsFormation](https://developer.apple.com/documentation/swiftui/dragdroppreviewsformation) — On macOS, describes the way the dragged previews are visually composed. Both drag sources and drop destination can specify their desired preview formation. _(Apple Developer; expand on demand)_

### Configuring spring loading

- [springLoadingBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/springloadingbehavior(_:)) — Sets the spring loading behavior this view. _(Apple Developer; expand on demand)_
- [springLoadingBehavior](https://developer.apple.com/documentation/swiftui/environmentvalues/springloadingbehavior) — The behavior of spring loaded interactions for the views associated with this environment. _(Apple Developer; expand on demand)_
- [SpringLoadingBehavior](https://developer.apple.com/documentation/swiftui/springloadingbehavior) — The options for controlling the spring loading behavior of views. _(Apple Developer; expand on demand)_

### Event handling

- [Gestures](swiftui-gestures.md) — Define interactions from taps, clicks, and swipes to fine-grained gestures. _(local context)_
- [Input events](swiftui-input-events.md) — Respond to input from a hardware device, like a keyboard or a Touch Bar. _(local context)_
- [Clipboard](swiftui-clipboard.md) — Enable people to move or duplicate items by issuing Copy and Paste commands. _(local context)_
- [Focus](swiftui-focus.md) — Identify and control which visible object responds to user interaction. _(local context)_
- [System events](swiftui-system-events.md) — React to system events, like opening a URL. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/drag-and-drop)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `d455ccf78fc1b22c79b48073df1d4da68bc337900bfa6abbf5c3a909905ffaaa`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.

## Source virtual in archives — AppKit

- [NSDraggingSource](appkit-nsdraggingsource.md): source, modifiers and completion.
- [Origin Mask](appkit-nsdraggingsource-operation-mask.md) and [combination with modifiers](appkit-dragging-source-operation-mask.md).
- [File promises Writing](appkit-file-promise-write.md): publish in the URL provided and complete after writing.
