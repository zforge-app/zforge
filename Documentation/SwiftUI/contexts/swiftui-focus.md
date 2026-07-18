---
title: "Focus"
source_url: "https://developer.apple.com/documentation/swiftui/focus"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Focus"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "afc40c7d8f9c89e9ce85e68250c398850fa76ee69f0f1fe252a4c9ab529316f1"
source_etag: "W/\"1e14931decfb606b6f8b936a01f443b1\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Focus

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Identify and control which visible object responds to user interaction.

Focus indicates which element in the display receives the next input. Use view modifiers to indicate which views can receive focus, to detect which view has focus, and to programmatically control focus state. For design guidance, see Focus and selection in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Focus and selection](https://developer.apple.com/design/Human-Interface-Guidelines/focus-and-selection) — Focus helps people visually confirm the object that their interaction targets. _(Apple Developer; expandir sob demanda)_

### Essentials

- [Focus Cookbook: Supporting and enhancing focus-driven interactions in your SwiftUI app](https://developer.apple.com/documentation/swiftui/focus-cookbook-sample) — Create custom focusable views with key-press handlers that accelerate keyboard input and support movement, and control focus programmatically. _(Apple Developer; expandir sob demanda)_

### Indicating that a view can receive focus

- [focusable(_:)](https://developer.apple.com/documentation/swiftui/view/focusable(_:)) — Specifies if the view is focusable. _(Apple Developer; expandir sob demanda)_
- [focusable(_:interactions:)](https://developer.apple.com/documentation/swiftui/view/focusable(_:interactions:)) — Specifies if the view is focusable, and if so, what focus-driven interactions it supports. _(Apple Developer; expandir sob demanda)_
- [FocusInteractions](https://developer.apple.com/documentation/swiftui/focusinteractions) — Values describe different focus interactions that a view can support. _(Apple Developer; expandir sob demanda)_

### Managing focus state

- [focused(_:equals:)](https://developer.apple.com/documentation/swiftui/view/focused(_:equals:)) — Modifies this view by binding its focus state to the given state value. _(Apple Developer; expandir sob demanda)_
- [focused(_:)](https://developer.apple.com/documentation/swiftui/view/focused(_:)) — Modifies this view by binding its focus state to the given Boolean state value. _(Apple Developer; expandir sob demanda)_
- [isFocused](https://developer.apple.com/documentation/swiftui/environmentvalues/isfocused) — Returns whether the nearest focusable ancestor has focus. _(Apple Developer; expandir sob demanda)_
- [FocusState](https://developer.apple.com/documentation/swiftui/focusstate) — A property wrapper type that can read and write a value that SwiftUI updates as the placement of focus within the scene changes. _(Apple Developer; expandir sob demanda)_
- [FocusedValue](https://developer.apple.com/documentation/swiftui/focusedvalue) — A property wrapper for observing values from the focused view or one of its ancestors. _(Apple Developer; expandir sob demanda)_
- [Entry()](https://developer.apple.com/documentation/swiftui/entry()) — Creates an environment values, transaction, container values, or focused values entry. _(Apple Developer; expandir sob demanda)_
- [FocusedValueKey](https://developer.apple.com/documentation/swiftui/focusedvaluekey) — A protocol for identifier types used when publishing and observing focused values. _(Apple Developer; expandir sob demanda)_
- [FocusedBinding](https://developer.apple.com/documentation/swiftui/focusedbinding) — A convenience property wrapper for observing and automatically unwrapping state bindings from the focused view or one of its ancestors. _(Apple Developer; expandir sob demanda)_
- [searchFocused(_:)](https://developer.apple.com/documentation/swiftui/view/searchfocused(_:)) — Modifies this view by binding the focus state of the search field associated with the nearest searchable modifier to the given Boolean value. _(Apple Developer; expandir sob demanda)_
- [searchFocused(_:equals:)](https://developer.apple.com/documentation/swiftui/view/searchfocused(_:equals:)) — Modifies this view by binding the focus state of the search field associated with the nearest searchable modifier to the given value. _(Apple Developer; expandir sob demanda)_

### Exposing value types to focused views

- [focusedValue(_:)](https://developer.apple.com/documentation/swiftui/view/focusedvalue(_:)) — Sets the focused value for the given object type. _(Apple Developer; expandir sob demanda)_
- [focusedValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/focusedvalue(_:_:)) — Modifies this view by injecting a value that you provide for use by other views whose state depends on the focused view hierarchy. _(Apple Developer; expandir sob demanda)_
- [focusedSceneValue(_:)](https://developer.apple.com/documentation/swiftui/view/focusedscenevalue(_:)) — Sets the focused value for the given object type at a scene-wide scope. _(Apple Developer; expandir sob demanda)_
- [focusedSceneValue(_:_:)](https://developer.apple.com/documentation/swiftui/view/focusedscenevalue(_:_:)) — Modifies this view by injecting a value that you provide for use by other views whose state depends on the focused scene. _(Apple Developer; expandir sob demanda)_
- [FocusedValues](https://developer.apple.com/documentation/swiftui/focusedvalues) — A collection of state exported by the focused scene or view and its ancestors. _(Apple Developer; expandir sob demanda)_

### Exposing reference types to focused views

- [focusedObject(_:)](https://developer.apple.com/documentation/swiftui/view/focusedobject(_:)) — Creates a new view that exposes the provided object to other views whose whose state depends on the focused view hierarchy. _(Apple Developer; expandir sob demanda)_
- [focusedSceneObject(_:)](https://developer.apple.com/documentation/swiftui/view/focusedsceneobject(_:)) — Creates a new view that exposes the provided object to other views whose whose state depends on the active scene. _(Apple Developer; expandir sob demanda)_
- [FocusedObject](https://developer.apple.com/documentation/swiftui/focusedobject) — A property wrapper type for an observable object supplied by the focused view or one of its ancestors. _(Apple Developer; expandir sob demanda)_

### Setting focus scope

- [focusScope(_:)](https://developer.apple.com/documentation/swiftui/view/focusscope(_:)) — Creates a focus scope that SwiftUI uses to limit default focus preferences. _(Apple Developer; expandir sob demanda)_
- [focusSection()](https://developer.apple.com/documentation/swiftui/view/focussection()) — Indicates that the view’s frame and cohort of focusable descendants should be used to guide focus movement. _(Apple Developer; expandir sob demanda)_

### Controlling default focus

- [prefersDefaultFocus(_:in:)](https://developer.apple.com/documentation/swiftui/view/prefersdefaultfocus(_:in:)) — Indicates that the view should receive focus by default for a given namespace. _(Apple Developer; expandir sob demanda)_
- [defaultFocus(_:_:priority:)](https://developer.apple.com/documentation/swiftui/view/defaultfocus(_:_:priority:)) — Defines a region of the window in which default focus is evaluated by assigning a value to a given focus state binding. _(Apple Developer; expandir sob demanda)_
- [DefaultFocusEvaluationPriority](https://developer.apple.com/documentation/swiftui/defaultfocusevaluationpriority) — Prioritizations for default focus preferences when evaluating where to move focus in different circumstances. _(Apple Developer; expandir sob demanda)_

### Resetting focus

- [resetFocus](https://developer.apple.com/documentation/swiftui/environmentvalues/resetfocus) — An action that requests the focus system to reevaluate default focus. _(Apple Developer; expandir sob demanda)_
- [ResetFocusAction](https://developer.apple.com/documentation/swiftui/resetfocusaction) — An environment value that provides the ability to reevaluate default focus. _(Apple Developer; expandir sob demanda)_

### Configuring effects

- [focusEffectDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/focuseffectdisabled(_:)) — Adds a condition that controls whether this view can display focus effects, such as a default focus ring or hover effect. _(Apple Developer; expandir sob demanda)_
- [isFocusEffectEnabled](https://developer.apple.com/documentation/swiftui/environmentvalues/isfocuseffectenabled) — A Boolean value that indicates whether the view associated with this environment allows focus effects to be displayed. _(Apple Developer; expandir sob demanda)_

### Event handling

- [Gestures](swiftui-gestures.md) — Define interactions from taps, clicks, and swipes to fine-grained gestures. _(contexto local)_
- [Input events](swiftui-input-events.md) — Respond to input from a hardware device, like a keyboard or a Touch Bar. _(contexto local)_
- [Clipboard](swiftui-clipboard.md) — Enable people to move or duplicate items by issuing Copy and Paste commands. _(contexto local)_
- [Drag and drop](swiftui-drag-and-drop.md) — Enable people to move or duplicate items by dragging them from one location to another. _(contexto local)_
- [System events](swiftui-system-events.md) — React to system events, like opening a URL. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/focus)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `afc40c7d8f9c89e9ce85e68250c398850fa76ee69f0f1fe252a4c9ab529316f1`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
