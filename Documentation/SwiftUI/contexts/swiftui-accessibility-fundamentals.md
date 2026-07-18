---
title: "Accessibility fundamentals"
source_url: "https://developer.apple.com/documentation/swiftui/accessibility-fundamentals"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Accessibility-fundamentals"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "4d537ece94d8722d74df45d13b41f67e73942c6bbc38e9db149dca15860d88e8"
source_etag: "W/\"f49b282d7abf833a910122b9fd85d74c\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Accessibility"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Accessibility fundamentals

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Make your SwiftUI apps accessible to everyone, including people with disabilities.

Like all Apple UI frameworks, SwiftUI comes with built-in accessibility support. The framework introspects common elements like navigation views, lists, text fields, sliders, buttons, and so on, and provides basic accessibility labels and values by default. You don’t have to do any extra work to enable these standard accessibility features. SwiftUI also provides tools to help you enhance the accessibility of your app. To find out what enhancements you need, try using your app with accessibility features like VoiceOver, Voice Control, and Switch Control, or get feedback from users of your app that regularly use these features. Then use the accessibility view modifiers that SwiftUI provides to improve the experience. For example, you can explicitly add accessibility labels to elements in your UI using the accessibilityLabel(_:) or the accessibilityValue(_:) view modifier. Customize your use of accessibility modifiers for all the platforms that your app runs on. For example, you may…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [accessibilityLabel(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)) — Adds a label to the view that describes its contents. _(Apple Developer; expandir sob demanda)_
- [accessibilityValue(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:)) — Adds a textual description of the value that the view contains. _(Apple Developer; expandir sob demanda)_
- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable) — A wrapper that you use to integrate an AppKit view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable) — A wrapper for a UIKit view that you use to integrate that view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [Accessibility](https://developer.apple.com/design/Human-Interface-Guidelines/accessibility) — Accessible user interfaces empower everyone to have a great experience with your app or game. _(Apple Developer; expandir sob demanda)_

### Essentials

- [Creating accessible views](https://developer.apple.com/documentation/swiftui/creating-accessible-views) — Make your app accessible to everyone by applying accessibility modifiers to your SwiftUI views. _(Apple Developer; expandir sob demanda)_

### Creating accessible elements

- [accessibilityElement(children:)](https://developer.apple.com/documentation/swiftui/view/accessibilityelement(children:)) — Creates a new accessibility element, or modifies the AccessibilityChildBehavior of the existing accessibility element. _(Apple Developer; expandir sob demanda)_
- [accessibilityChildren(children:)](https://developer.apple.com/documentation/swiftui/view/accessibilitychildren(children:)) — Replaces the existing accessibility element’s children with one or more new synthetic accessibility elements. _(Apple Developer; expandir sob demanda)_
- [accessibilityRepresentation(representation:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrepresentation(representation:)) — Replaces one or more accessibility elements for this view with new accessibility elements. _(Apple Developer; expandir sob demanda)_
- [AccessibilityChildBehavior](https://developer.apple.com/documentation/swiftui/accessibilitychildbehavior) — Defines the behavior for the child elements of the new parent element. _(Apple Developer; expandir sob demanda)_

### Identifying elements

- [accessibilityIdentifier(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityidentifier(_:)) — Uses the string you specify to identify the view. _(Apple Developer; expandir sob demanda)_
- [accessibilityIdentifier(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityidentifier(_:isenabled:)) — Uses the string you specify to identify the view. _(Apple Developer; expandir sob demanda)_

### Hiding elements

- [accessibilityHidden(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityhidden(_:)) — Specifies whether to hide this view from system accessibility features. _(Apple Developer; expandir sob demanda)_
- [accessibilityHidden(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityhidden(_:isenabled:)) — Specifies whether to hide this view from system accessibility features. _(Apple Developer; expandir sob demanda)_

### Supporting types

- [AccessibilityTechnologies](https://developer.apple.com/documentation/swiftui/accessibilitytechnologies) — Accessibility technologies available to the system. _(Apple Developer; expandir sob demanda)_
- [AccessibilityAttachmentModifier](https://developer.apple.com/documentation/swiftui/accessibilityattachmentmodifier) — A view modifier that adds accessibility properties to the view _(Apple Developer; expandir sob demanda)_

### Accessibility

- [Accessible appearance](swiftui-accessible-appearance.md) — Enhance the legibility of content in your app’s interface. _(contexto local)_
- [Accessible controls](swiftui-accessible-controls.md) — Improve access to actions that your app can undertake. _(contexto local)_
- [Accessible descriptions](swiftui-accessible-descriptions.md) — Describe interface elements to help people understand what they represent. _(contexto local)_
- [Accessible navigation](swiftui-accessible-navigation.md) — Enable users to navigate to specific user interface elements using rotors. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `4d537ece94d8722d74df45d13b41f67e73942c6bbc38e9db149dca15860d88e8`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
