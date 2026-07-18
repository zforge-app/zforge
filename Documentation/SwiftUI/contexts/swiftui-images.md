---
title: "Images"
source_url: "https://developer.apple.com/documentation/swiftui/images"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Images"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "315c31e3d7fe10add90558480af1673c1d8a183d2e92c1ac6be1ecd58a28e9a0"
source_etag: "W/\"3f230109b7a9a0c098655114d35087df\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Images

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Add images and symbols to your app’s user interface.

Display images, including SF Symbols, images that you store in an asset catalog, and images that you store on disk, using an Image view. For images that take time to retrieve — for example, when you load an image from a network endpoint — load the image asynchronously using AsyncImage. You can instruct that view to display a placeholder during the load operation. For design guidance, see Images in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [SF Symbols](https://developer.apple.com/design/Human-Interface-Guidelines/sf-symbols) — SF Symbols provides thousands of consistent, highly configurable symbols that integrate seamlessly with the San Francisco system font, automatically aligning with text in all… _(Apple Developer; expandir sob demanda)_
- [Image](https://developer.apple.com/documentation/swiftui/image) — A view that displays an image. _(Apple Developer; expandir sob demanda)_
- [AsyncImage](https://developer.apple.com/documentation/swiftui/asyncimage) — A view that asynchronously loads and displays an image. _(Apple Developer; expandir sob demanda)_
- [Images](https://developer.apple.com/design/Human-Interface-Guidelines/images) — To make sure your artwork looks great on all devices you support, learn how the system displays content and how to deliver art at… _(Apple Developer; expandir sob demanda)_

### Configuring an image

- [Fitting images into available space](https://developer.apple.com/documentation/swiftui/fitting-images-into-available-space) — Adjust the size and shape of images in your app’s user interface by applying view modifiers. _(Apple Developer; expandir sob demanda)_
- [imageScale(_:)](https://developer.apple.com/documentation/swiftui/view/imagescale(_:)) — Scales images within the view according to one of the relative sizes available including small, medium, and large images sizes. _(Apple Developer; expandir sob demanda)_
- [imageScale](https://developer.apple.com/documentation/swiftui/environmentvalues/imagescale) — The image scale for this environment. _(Apple Developer; expandir sob demanda)_
- [Image.Scale](https://developer.apple.com/documentation/swiftui/image/scale) — A scale to apply to vector images relative to text. _(Apple Developer; expandir sob demanda)_
- [Image.Orientation](https://developer.apple.com/documentation/swiftui/image/orientation) — The orientation of an image. _(Apple Developer; expandir sob demanda)_
- [Image.ResizingMode](https://developer.apple.com/documentation/swiftui/image/resizingmode) — The modes that SwiftUI uses to resize an image to fit within its containing view. _(Apple Developer; expandir sob demanda)_

### Loading images asynchronously

- [AsyncImagePhase](https://developer.apple.com/documentation/swiftui/asyncimagephase) — The current phase of the asynchronous image loading operation. _(Apple Developer; expandir sob demanda)_

### Setting a symbol variant

- [symbolVariant(_:)](https://developer.apple.com/documentation/swiftui/view/symbolvariant(_:)) — Makes symbols within the view show a particular variant. _(Apple Developer; expandir sob demanda)_
- [symbolVariants](https://developer.apple.com/documentation/swiftui/environmentvalues/symbolvariants) — The symbol variant to use in this environment. _(Apple Developer; expandir sob demanda)_
- [SymbolVariants](https://developer.apple.com/documentation/swiftui/symbolvariants) — A variant of a symbol. _(Apple Developer; expandir sob demanda)_

### Managing symbol effects

- [symbolEffect(_:options:isActive:)](https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:isactive:)) — Returns a new view with a symbol effect added to it. _(Apple Developer; expandir sob demanda)_
- [symbolEffect(_:options:value:)](https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:)) — Returns a new view with a symbol effect added to it. _(Apple Developer; expandir sob demanda)_
- [symbolEffectsRemoved(_:)](https://developer.apple.com/documentation/swiftui/view/symboleffectsremoved(_:)) — Returns a new view with its inherited symbol image effects either removed or left unchanged. _(Apple Developer; expandir sob demanda)_
- [SymbolEffectTransition](https://developer.apple.com/documentation/swiftui/symboleffecttransition) — Creates a transition that applies the Appear, Disappear, DrawOn or DrawOff symbol animation to symbol images within the inserted or removed view hierarchy. _(Apple Developer; expandir sob demanda)_

### Setting symbol rendering modes

- [symbolRenderingMode(_:)](https://developer.apple.com/documentation/swiftui/view/symbolrenderingmode(_:)) — Sets the rendering mode for symbol images within this view. _(Apple Developer; expandir sob demanda)_
- [symbolRenderingMode](https://developer.apple.com/documentation/swiftui/environmentvalues/symbolrenderingmode) — The current symbol rendering mode, or denoting that the mode is picked automatically using the current image and foreground style as parameters. _(Apple Developer; expandir sob demanda)_
- [SymbolRenderingMode](https://developer.apple.com/documentation/swiftui/symbolrenderingmode) — A symbol rendering mode. _(Apple Developer; expandir sob demanda)_
- [SymbolColorRenderingMode](https://developer.apple.com/documentation/swiftui/symbolcolorrenderingmode) — A method of filling a layer in a symbol image. _(Apple Developer; expandir sob demanda)_
- [SymbolVariableValueMode](https://developer.apple.com/documentation/swiftui/symbolvariablevaluemode) — A method of rendering the variable value of a symbol image. _(Apple Developer; expandir sob demanda)_

### Rendering images from views

- [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer) — An object that creates images from SwiftUI views. _(Apple Developer; expandir sob demanda)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(contexto local)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(contexto local)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(contexto local)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(contexto local)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(contexto local)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(contexto local)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(contexto local)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(contexto local)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/images)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `315c31e3d7fe10add90558480af1673c1d8a183d2e92c1ac6be1ecd58a28e9a0`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
