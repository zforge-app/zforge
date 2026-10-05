---
title: "Clipboard"
source_url: "https://developer.apple.com/documentation/swiftui/clipboard"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Clipboard"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "02e5684339ad6c6c4cd476e1b902a01b96b36c308fdaac584575fd8bf29af7f0"
source_etag: "W/\"c1cb30d7dfd2b26efbd1d0c8c3117ff3\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Clipboard

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Enable people to move or duplicate items by issuing Copy and Paste commands.

When people issue standard Copy and Cut commands, they expect to move items to the system’s Clipboard, from which they can paste the items into another place in the same app or into another app. Your app can participate in this activity if you add view modifiers that indicate how to respond to the standard commands. In your copy and paste modifiers, provide or accept types that conform to the Transferable protocol, or that inherit from the NSItemProvider class. When possible, prefer using transferable items.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Transferable](https://developer.apple.com/documentation/CoreTransferable/Transferable) — A protocol that describes how a type interacts with transport APIs such as drag and drop or copy and paste. _(Apple Developer; expand on demand)_
- [NSItemProvider](foundation-nsitemprovider.md) — An item provider for conveying data or a file between processes during drag-and-drop or copy-and-paste activities. _(local context)_

### Copying transferable items

- [copyable(_:)](https://developer.apple.com/documentation/swiftui/view/copyable(_:)) — Specifies a list of items to copy in response to the system’s Copy command. _(Apple Developer; expand on demand)_
- [cuttable(for:action:)](https://developer.apple.com/documentation/swiftui/view/cuttable(for:action:)) — Specifies an action that moves items to the Clipboard in response to the system’s Cut command. _(Apple Developer; expand on demand)_
- [pasteDestination(for:action:validator:)](https://developer.apple.com/documentation/swiftui/view/pastedestination(for:action:validator:)) — Specifies an action that adds validated items to a view in response to the system’s Paste command. _(Apple Developer; expand on demand)_

### Copying items using item providers

- [onCopyCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/oncopycommand(perform:)) — Adds an action to perform in response to the system’s Copy command. _(Apple Developer; expand on demand)_
- [onCutCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/oncutcommand(perform:)) — Adds an action to perform in response to the system’s Cut command. _(Apple Developer; expand on demand)_
- [onPasteCommand(of:perform:)](https://developer.apple.com/documentation/swiftui/view/onpastecommand(of:perform:)) — Adds an action to perform in response to the system’s Paste command. _(Apple Developer; expand on demand)_
- [onPasteCommand(of:validator:perform:)](https://developer.apple.com/documentation/swiftui/view/onpastecommand(of:validator:perform:)) — Adds an action to perform in response to the system’s Paste command with items that you validate. _(Apple Developer; expand on demand)_

### Event handling

- [Gestures](swiftui-gestures.md) — Define interactions from taps, clicks, and swipes to fine-grained gestures. _(local context)_
- [Input events](swiftui-input-events.md) — Respond to input from a hardware device, like a keyboard or a Touch Bar. _(local context)_
- [Drag and drop](swiftui-drag-and-drop.md) — Enable people to move or duplicate items by dragging them from one location to another. _(local context)_
- [Focus](swiftui-focus.md) — Identify and control which visible object responds to user interaction. _(local context)_
- [System events](swiftui-system-events.md) — React to system events, like opening a URL. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/clipboard)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `02e5684339ad6c6c4cd476e1b902a01b96b36c308fdaac584575fd8bf29af7f0`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
