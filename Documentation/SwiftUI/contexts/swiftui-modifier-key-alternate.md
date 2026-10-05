---
title: "modifierKeyAlternate(_:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/modifierkeyalternate(_:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/modifierKeyAlternate(_:_:)"
captured_at: "2026-07-20T00:33:49+00:00"
source_sha256: "9e5dc4ed7b20d55f7f42d007ceee6a6c2ab7166cefc3229f038c2da412c80a76"
source_etag: "W/\"7c8be7da34a833f21f892e12b65d3f7c\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# modifierKeyAlternate(_:_:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Instance Method
- Module: SwiftUI
- Relevance to Zforge: Direct to menu commands that share a base key and change action with Option.
- Availability: macOS 15.0+
- Declaration: `nonisolated func modifierKeyAlternate<V>(_ modifiers: EventModifiers, @ContentBuilder _ alternate: () -> V) -> some View where V : View`

## Summary

Builds an alternative view that replaces the main while all the specified modifiers are pressed. In menu-style contexts, SwiftUI transforms this alternative into an alternative menu item native.

When the main view has a shortcut, it serves as the basis for the alternative shortcut. Thus, a button with `Command + V` and `modifierKeyAlternate(.option)` naturally produces `Option + Command + V` for its alternative. An explicit shortcut within the alternative content replaces this inference.

## Practical implications

- Commands that share the same key and differ by Option must be related by `modifierKeyAlternate`, not added as menu-independent items.
- Commands using different base keys must remain as independent items without `modifierKeyAlternate`.
- The API was validated at SDK macOS 26.5 of the local Xcode and is available since macOS 15.0.

## Content map

- Parameters
- Return Value
- Discussion

## Second-level links

### Related types

- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers) — Event modifiers used to define when the alternative replaces the main item. _(Apple Developer; expand on demand)_
- [onModifierKeysChanged(mask:initial:_:)](https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:)) — Observes changes in modifier keys. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/modifierkeyalternate(_:_:))
- Captured: `2026-07-20T00:33:49+00:00`
- Payload SHA-256: `9e5dc4ed7b20d55f7f42d007ceee6a6c2ab7166cefc3229f038c2da412c80a76`
- Scope: one page; the above absolute links have not yet been covered.
