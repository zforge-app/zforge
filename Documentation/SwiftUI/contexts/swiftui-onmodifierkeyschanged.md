---
title: "onModifierKeysChanged(mask:initial:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/onModifierKeysChanged(mask:initial:_:)"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "227d3b6efe67d062b86163ed14ca9b91dae234fb43b267ae74e706be5f3913e6"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# onModifierKeysChanged(mask:initial:_:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Roll: Modifier key observation modifier
- Module: SwiftUI
- Relevance to Zforge: direta for acompanhar Option e Command durante drag and drop
- Availability: macOS 15.0+
- Declaration: `func onModifierKeysChanged(mask: EventModifiers = .all, initial: Bool = true, _ action: (EventModifiers, EventModifiers) -> Void) -> some View`

## Summary

Performs an action when a hardware modifier key is pressed or released. `mask` limits the observed keys, `initial` asks for a read when it appears and the action receives the previous and current values.

With `initial` enabled, SwiftUI checks the keys when the view appears; then emits changes of the keys included in the mask. The state emitted combines the connected keyboards.

## Practical implications

- Observing only `.option` and `.command` in the browser avoids irrelevant updates.
- An ongoing drop session must share a reference object updated by the action; capture only a value of `EventModifiers` can freeze the initial state in the delegate.
- The observation defines the intention of copying, moving or aliasing, but does not replace the obligation to start loading within `performDrop(info:)`.

## Content map

- Parameters
- Return value
- Discussion

## Second-level links

### Related types

- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers) — conjunto de teclas modificadoras. _Apple Developer; expand on demand_
- [modifierKeyAlternate(_:_:)](swiftui-modifier-key-alternate.md) — alternative control content based on modifiers. _(local context)_
- [performDrop(info:)](swiftui-dropdelegate-performdrop.md) — safe payload consumption of drop. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:))
- Captured: `2026-07-20T02:07:43Z`
- Payload SHA-256: `227d3b6efe67d062b86163ed14ca9b91dae234fb43b267ae74e706be5f3913e6`
- Scope: one page; the above absolute links have not yet been covered.
