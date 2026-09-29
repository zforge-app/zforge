---
title: "Form"
source_url: "https://developer.apple.com/documentation/swiftui/form"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Form"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "3776ceb73e7400e3f65833673a3aea06e47de6e192e86fb0f706e910f6864f98"
source_etag: "\"41aa-659025e844438\""
source_last_modified: "Fri, 14 Aug 2026 14:09:30 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Form

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Structure
- Módulo: SwiftUI
- Relevância para Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Disponibilidade: iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- Declaração: `nonisolated struct Form<Content> where Content : View`

## Síntese

**Resumo oficial:** A container for grouping controls used for data entry, such as in settings or inspectors.

SwiftUI applies platform-appropriate styling to views contained inside a form, to group them together. Form-specific styling applies to things like buttons, toggles, labels, lists, and more. Keep in mind that these stylings may be platform-specific. For example, forms appear as grouped lists on iOS, and as aligned vertical stacks on macOS. The following example shows a simple data entry form on iOS, grouped into two sections. The supporting types ( and ) and state variables (, , , and ) are omitted for simplicity. On macOS, a similar form renders as a vertical stack. To adhere to macOS platform conventions, this version doesn’t use sections, and uses colons at the end of its labels. It also sets the picker to use the inline style, which produces radio buttons on macOS.

## Implicações práticas

- O Form do macOS tem aparência de pilha vertical alinhada e usa convenções próprias; ele não estabelece uma proibição geral a rótulos acima de controles em um acessório customizado.
- Uma composição VStack de rótulo e Picker permite a densidade proposta, desde que use controles nativos e associe o rótulo para acessibilidade.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [inline](https://developer.apple.com/documentation/swiftui/pickerstyle/inline) — A where each option is displayed inline with other views in the current container. _(Apple Developer; expandir sob demanda)_

### Creating a form

- [init(content:)](https://developer.apple.com/documentation/swiftui/form/init(content:)) — Creates a form with the provided content. _(Apple Developer; expandir sob demanda)_

### Creating a form from a configuration

- [init(_:)](https://developer.apple.com/documentation/swiftui/form/init(_:)) — Creates a form based on a form style configuration. _(Apple Developer; expandir sob demanda)_

### Grouping inputs

- [formStyle(_:)](https://developer.apple.com/documentation/swiftui/view/formstyle(_:)) — Sets the style for forms in a view hierarchy. _(Apple Developer; expandir sob demanda)_
- [LabeledContent](https://developer.apple.com/documentation/swiftui/labeledcontent) — A container for attaching a label to a value-bearing view. _(Apple Developer; expandir sob demanda)_
- [labeledContentStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labeledcontentstyle(_:)) — Sets a style for labeled content. _(Apple Developer; expandir sob demanda)_

### Conforms To

- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/form)
- Captura: `2026-09-28T23:25:02+00:00`
- SHA-256 do payload: `3776ceb73e7400e3f65833673a3aea06e47de6e192e86fb0f706e910f6864f98`
- Escopo: expansão sob demanda de uma página; links absolutos acima ainda não foram percorridos.
