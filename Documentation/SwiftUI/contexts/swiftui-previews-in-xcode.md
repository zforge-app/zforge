---
title: "Previews in Xcode"
source_url: "https://developer.apple.com/documentation/swiftui/previews-in-xcode"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Previews-in-Xcode"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "fdc7a3ed44cc30c7374fb317951823821a07f6c504bf1d6d887feeb0587697d4"
source_etag: "W/\"bb32ff4dcaf4fc13070e951f2f687231\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Tool support"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Previews in Xcode

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Generate dynamic, interactive previews of your custom views.

When you create a custom View with SwiftUI, Xcode can display a preview of the view’s content that stays up-to-date as you make changes to the view’s code. You use one of the preview macros — like Preview(_:body:) — to tell Xcode what to display. Xcode shows the preview in a canvas beside your code. Different preview macros enable different kinds of configuration. For example, you can add traits that affect the preview’s appearance using the Preview(_:traits:_:body:) macro or add custom viewpoints for the preview using the Preview(_:traits:body:cameras:) macro. You can also check how your view behaves inside a specific scene type. For example, in visionOS you can use the Preview(_:immersionStyle:traits:body:) macro to preview your view inside an ImmersiveSpace. You typically rely on preview macros to create previews in your code. However, if you can’t get the behavior you need using a preview macro, you can use the PreviewProvider protocol…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(contexto local)_
- [Preview(_:body:)](https://developer.apple.com/documentation/swiftui/preview(_:body:)) — Creates a preview of a SwiftUI view. _(Apple Developer; expandir sob demanda)_
- [Preview(_:traits:_:body:)](https://developer.apple.com/documentation/swiftui/preview(_:traits:_:body:)) — Creates a preview of a SwiftUI view using the specified traits. _(Apple Developer; expandir sob demanda)_
- [Preview(_:traits:body:cameras:)](https://developer.apple.com/documentation/swiftui/preview(_:traits:body:cameras:)) — Creates a preview of a SwiftUI view using the specified traits and custom viewpoints. _(Apple Developer; expandir sob demanda)_
- [Preview(_:immersionStyle:traits:body:)](https://developer.apple.com/documentation/swiftui/preview(_:immersionstyle:traits:body:)) — Creates a preview of a SwiftUI view in an immersive space. _(Apple Developer; expandir sob demanda)_
- [ImmersiveSpace](https://developer.apple.com/documentation/swiftui/immersivespace) — A scene that presents its content in an unbounded space. _(Apple Developer; expandir sob demanda)_
- [PreviewProvider](https://developer.apple.com/documentation/swiftui/previewprovider) — A type that produces view previews in Xcode. _(Apple Developer; expandir sob demanda)_

### Essentials

- [Previewing your app’s interface in Xcode](https://developer.apple.com/documentation/Xcode/previewing-your-apps-interface-in-xcode) — Iterate designs quickly and preview your apps’ displays across different Apple devices. _(Apple Developer; expandir sob demanda)_

### Creating a preview

- [Preview(_:traits:arguments:body:)](https://developer.apple.com/documentation/swiftui/preview(_:traits:arguments:body:)) — Creates a group of previews of a parameterized SwiftUI view, varying its inputs over the provided arguments. _(Apple Developer; expandir sob demanda)_

### Creating a preview in the context of a scene

- [Preview(_:immersionStyle:traits:body:cameras:)](https://developer.apple.com/documentation/swiftui/preview(_:immersionstyle:traits:body:cameras:)) — Creates a preview of a SwiftUI view in an immersive space with custom viewpoints. _(Apple Developer; expandir sob demanda)_
- [Preview(_:windowStyle:traits:body:)](https://developer.apple.com/documentation/swiftui/preview(_:windowstyle:traits:body:)) — Creates a preview of a SwiftUI view in a window. _(Apple Developer; expandir sob demanda)_
- [Preview(_:windowStyle:traits:body:cameras:)](https://developer.apple.com/documentation/swiftui/preview(_:windowstyle:traits:body:cameras:)) — Creates a preview of a SwiftUI view in a window with custom viewpoints. _(Apple Developer; expandir sob demanda)_

### Defining a preview

- [Previewable()](https://developer.apple.com/documentation/swiftui/previewable()) — Tag allowing a dynamic property to appear inline in a preview. _(Apple Developer; expandir sob demanda)_
- [PreviewPlatform](https://developer.apple.com/documentation/swiftui/previewplatform) — Platforms that can run the preview. _(Apple Developer; expandir sob demanda)_
- [previewDisplayName(_:)](https://developer.apple.com/documentation/swiftui/view/previewdisplayname(_:)) — Sets a user visible name to show in the canvas for a preview. _(Apple Developer; expandir sob demanda)_
- [PreviewModifier](https://developer.apple.com/documentation/swiftui/previewmodifier) — A type that defines an environment in which previews can appear. _(Apple Developer; expandir sob demanda)_
- [PreviewModifierContent](https://developer.apple.com/documentation/swiftui/previewmodifiercontent) — The type-erased content of a preview. _(Apple Developer; expandir sob demanda)_

### Customizing a preview

- [previewDevice(_:)](https://developer.apple.com/documentation/swiftui/view/previewdevice(_:)) — Overrides the device for a preview. _(Apple Developer; expandir sob demanda)_
- [PreviewDevice](https://developer.apple.com/documentation/swiftui/previewdevice) — A simulator device that runs a preview. _(Apple Developer; expandir sob demanda)_
- [previewLayout(_:)](https://developer.apple.com/documentation/swiftui/view/previewlayout(_:)) — Overrides the size of the container for the preview. _(Apple Developer; expandir sob demanda)_
- [previewInterfaceOrientation(_:)](https://developer.apple.com/documentation/swiftui/view/previewinterfaceorientation(_:)) — Overrides the orientation of the preview. _(Apple Developer; expandir sob demanda)_
- [InterfaceOrientation](https://developer.apple.com/documentation/swiftui/interfaceorientation) — The orientation of the interface from the user’s perspective. _(Apple Developer; expandir sob demanda)_

### Setting a context

- [previewContext(_:)](https://developer.apple.com/documentation/swiftui/view/previewcontext(_:)) — Declares a context for the preview. _(Apple Developer; expandir sob demanda)_
- [PreviewContext](https://developer.apple.com/documentation/swiftui/previewcontext) — A context type for use with a preview. _(Apple Developer; expandir sob demanda)_
- [PreviewContextKey](https://developer.apple.com/documentation/swiftui/previewcontextkey) — A key type for a preview context. _(Apple Developer; expandir sob demanda)_

### Building in debug mode

- [DebugReplaceableView](https://developer.apple.com/documentation/swiftui/debugreplaceableview) — Erases view opaque result types in debug builds. _(Apple Developer; expandir sob demanda)_

### Tool support

- [Xcode library customization](swiftui-xcode-library-customization.md) — Expose custom views and modifiers in the Xcode library. _(contexto local)_
- [Performance analysis](swiftui-performance-analysis.md) — Measure and improve your app’s responsiveness. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/previews-in-xcode)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `fdc7a3ed44cc30c7374fb317951823821a07f6c504bf1d6d887feeb0587697d4`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
