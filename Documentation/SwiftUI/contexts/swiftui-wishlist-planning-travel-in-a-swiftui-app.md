---
title: "Wishlist: Planning travel in a SwiftUI app"
source_url: "https://developer.apple.com/documentation/swiftui/wishlist-planning-travel-in-a-swiftui-app"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/wishlist-planning-travel-in-a-swiftui-app"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "68d8ba49575d62a1c072e087df5fc3287427f1576d8ab1d309a38739cebeb9fe"
source_etag: "W/\"66031376af1137a45591230c7dbfcb42\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Featured samples"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Wishlist: Planning travel in a SwiftUI app

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Sample Code
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.
- Disponibilidade: iOS 27.0+ (beta), iPadOS 27.0+ (beta), Mac Catalyst 27.0+ (beta), Xcode 27.0+ (beta)

## Síntese

**Resumo oficial:** Build a travel planning app that organizes trips into collections and tracks activity completion.

The Wishlist sample app helps people organize travel plans by grouping trips into seasonal collections. Within each trip, people can create activities and mark them complete as they explore. The app rewards progress with achievement badges, tracking milestones like completing a first trip or reaching an activity milestone across all adventures. The sample project demonstrates how to: Compose custom views. Manage state with the Observable() macro. Customize navigation title appearance. Animate view changes. Create zoom transitions to navigation destinations and between buttons and sheets. SwiftUI views conform to the View protocol and define their content through a computed property. Each view returns a description of what appears on screen, and SwiftUI handles the rendering. Wishlist builds custom views by combining built-in components like VStack, HStack, Text, Image, and Button: The outer stacks the image and text vertically, aligning content to the leading edge. Apply transformations sequentially by stacking modifiers, with…

## Mapa do conteúdo

- Overview
- Compose custom views
- Manage state with an observable macro
- Customize navigation title appearance
- Animate view changes
- Create zoom transitions between navigation destinations

## Links do segundo nível

### Overview and featured references

- [Observable()](https://developer.apple.com/documentation/Observation/Observable()) — Defines and implements conformance of the Observable protocol. _(Apple Developer; expandir sob demanda)_
- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(contexto local)_
- [VStack](https://developer.apple.com/documentation/swiftui/vstack) — A view that arranges its subviews in a vertical line. _(Apple Developer; expandir sob demanda)_
- [HStack](https://developer.apple.com/documentation/swiftui/hstack) — A view that arranges its subviews in a horizontal line. _(Apple Developer; expandir sob demanda)_
- [Text](https://developer.apple.com/documentation/swiftui/text) — A view that displays one or more lines of read-only text. _(Apple Developer; expandir sob demanda)_
- [Image](https://developer.apple.com/documentation/swiftui/image) — A view that displays an image. _(Apple Developer; expandir sob demanda)_
- [Button](https://developer.apple.com/documentation/swiftui/button) — A control that initiates an action. _(Apple Developer; expandir sob demanda)_
- [Dictionary](https://developer.apple.com/documentation/Swift/Dictionary) — A collection whose elements are key-value pairs. _(Apple Developer; expandir sob demanda)_
- [State](https://developer.apple.com/documentation/swiftui/state) — A property wrapper type that can read and write a value managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [App](swiftui-app.md) — A type that represents the structure and behavior of an app. _(contexto local)_
- [environment(_:)](https://developer.apple.com/documentation/swiftui/view/environment(_:)) — Places an observable object in the view’s environment. _(Apple Developer; expandir sob demanda)_
- [Environment](https://developer.apple.com/documentation/swiftui/environment) — A property wrapper that reads a value from a view’s environment. _(Apple Developer; expandir sob demanda)_
- [Toggle](https://developer.apple.com/documentation/swiftui/toggle) — A control that toggles between on and off states. _(Apple Developer; expandir sob demanda)_
- [searchable(text:placement:prompt:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)) — Marks this view as searchable, which configures the display of a search field. _(Apple Developer; expandir sob demanda)_
- [Binding](https://developer.apple.com/documentation/swiftui/binding) — A property wrapper type that can read and write a value owned by a source of truth. _(Apple Developer; expandir sob demanda)_
- [Bindable](https://developer.apple.com/documentation/swiftui/bindable) — A property wrapper type that supports creating bindings to the mutable properties of observable objects. _(Apple Developer; expandir sob demanda)_
- [ToolbarItem](https://developer.apple.com/documentation/swiftui/toolbaritem) — A model that represents an item which can be placed in the toolbar or navigation bar. _(Apple Developer; expandir sob demanda)_
- [title](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/title) — A placement for items in the title area of the navigation bar. _(Apple Developer; expandir sob demanda)_
- [navigationTitle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)) — Configures the view’s title for purposes of navigation, using a localized string resource. _(Apple Developer; expandir sob demanda)_
- [toolbarTitleDisplayMode(_:)](https://developer.apple.com/documentation/swiftui/view/toolbartitledisplaymode(_:)) — Configures the toolbar title display mode for this view. _(Apple Developer; expandir sob demanda)_
- [inline](https://developer.apple.com/documentation/swiftui/toolbartitledisplaymode/inline) — The inline mode. _(Apple Developer; expandir sob demanda)_
- [largeTitle](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/largetitle) — A placement for items in the navigation bar’s title area. _(Apple Developer; expandir sob demanda)_
- [withAnimation(_:_:)](https://developer.apple.com/documentation/swiftui/withanimation(_:_:)) — Returns the result of recomputing the view’s body with the provided animation. _(Apple Developer; expandir sob demanda)_
- [animation(_:value:)](https://developer.apple.com/documentation/swiftui/view/animation(_:value:)) — Applies the given animation to this view when the specified value changes. _(Apple Developer; expandir sob demanda)_
- [Animatable](https://developer.apple.com/documentation/swiftui/animatable) — A type that describes how to animate a property of a view. _(Apple Developer; expandir sob demanda)_
- [Animatable()](https://developer.apple.com/documentation/swiftui/animatable()) — A member and extension macro that, when applied to a struct, class or enum declaration, synthesizes the conformance to and its requirement, the property… _(Apple Developer; expandir sob demanda)_
- [10156: Explore SwiftUI animation](https://developer.apple.com/videos/play/wwdc2023/10156/) — _Apple Developer; expandir sob demanda_
- [matchedTransitionSource(id:in:)](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:)) — Identifies this view as the source of a navigation transition, such as a zoom transition. _(Apple Developer; expandir sob demanda)_
- [navigationTransition(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:)) — Sets the navigation transition style for this view. _(Apple Developer; expandir sob demanda)_
- [zoom(sourceID:in:)](https://developer.apple.com/documentation/swiftui/navigationtransition/zoom(sourceid:in:)) — A navigation transition that zooms the appearing view from a given source view. _(Apple Developer; expandir sob demanda)_
- [Namespace](https://developer.apple.com/documentation/swiftui/namespace) — A dynamic property type that allows access to a namespace defined by the persistent identity of the object containing the property (e.g. a view). _(Apple Developer; expandir sob demanda)_
- [10145: Enhance your UI animations and transitions](https://developer.apple.com/videos/play/wwdc2024/10145/) — _Apple Developer; expandir sob demanda_

### Creating a view

- [Declaring a custom view](https://developer.apple.com/documentation/swiftui/declaring-a-custom-view) — Define views and assemble them into a view hierarchy. _(Apple Developer; expandir sob demanda)_
- [ContentBuilder](https://developer.apple.com/documentation/swiftui/contentbuilder) — A custom parameter attribute that constructs views and other content types from closures. _(Apple Developer; expandir sob demanda)_
- [ViewBuilder](https://developer.apple.com/documentation/swiftui/viewbuilder) — A custom parameter attribute that constructs views from closures. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/wishlist-planning-travel-in-a-swiftui-app)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `68d8ba49575d62a1c072e087df5fc3287427f1576d8ab1d309a38739cebeb9fe`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
