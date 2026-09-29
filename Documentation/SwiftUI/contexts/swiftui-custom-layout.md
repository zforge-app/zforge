---
title: "Custom layout"
source_url: "https://developer.apple.com/documentation/swiftui/custom-layout"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Custom-layout"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "b77128410b57c786a71045ec2c4d39d45192a8c09a89f77986de2acee99926b8"
source_etag: "W/\"32c3d990a656c5a4289d08bf593df2e2\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Custom layout

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Place views in custom arrangements and create animated transitions between layout types.

You can create complex view layouts using the built-in layout containers and layout view modifiers that SwiftUI provides. However, if you need behavior that you can’t achieve with the built-in layout tools, create a custom layout container type using the Layout protocol. A container that you define asks for the sizes of all its subviews, and then indicates where to place the subviews within its own bounds. You can also create animated transitions among layout types that conform to the Layout procotol, including both built-in and custom layouts. For design guidance, see Layout in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Layout](https://developer.apple.com/documentation/swiftui/layout) — A type that defines the geometry of a collection of views. _(Apple Developer; expandir sob demanda)_
- [Layout](hig-layout.md) — A consistent layout that adapts to various contexts makes your experience more approachable and helps people enjoy their favorite apps and games on all… _(Apple Developer; expandir sob demanda)_

### Creating a custom layout container

- [Composing custom layouts with SwiftUI](https://developer.apple.com/documentation/swiftui/composing-custom-layouts-with-swiftui) — Arrange views in your app’s interface using layout tools that SwiftUI provides. _(Apple Developer; expandir sob demanda)_
- [LayoutSubview](https://developer.apple.com/documentation/swiftui/layoutsubview) — A proxy that represents one subview of a layout. _(Apple Developer; expandir sob demanda)_
- [LayoutSubviews](https://developer.apple.com/documentation/swiftui/layoutsubviews) — A collection of proxy values that represent the subviews of a layout view. _(Apple Developer; expandir sob demanda)_

### Configuring a custom layout

- [LayoutProperties](https://developer.apple.com/documentation/swiftui/layoutproperties) — Layout-specific properties of a layout container. _(Apple Developer; expandir sob demanda)_
- [ProposedViewSize](https://developer.apple.com/documentation/swiftui/proposedviewsize) — A proposal for the size of a view. _(Apple Developer; expandir sob demanda)_
- [ViewSpacing](https://developer.apple.com/documentation/swiftui/viewspacing) — A collection of the geometric spacing preferences of a view. _(Apple Developer; expandir sob demanda)_

### Associating values with views in a custom layout

- [layoutValue(key:value:)](https://developer.apple.com/documentation/swiftui/view/layoutvalue(key:value:)) — Associates a value with a custom layout property. _(Apple Developer; expandir sob demanda)_
- [LayoutValueKey](https://developer.apple.com/documentation/swiftui/layoutvaluekey) — A key for accessing a layout value of a layout container’s subviews. _(Apple Developer; expandir sob demanda)_

### Transitioning between layout types

- [AnyLayout](https://developer.apple.com/documentation/swiftui/anylayout) — A type-erased instance of the layout protocol. _(Apple Developer; expandir sob demanda)_
- [HStackLayout](https://developer.apple.com/documentation/swiftui/hstacklayout) — A horizontal container that you can use in conditional layouts. _(Apple Developer; expandir sob demanda)_
- [VStackLayout](https://developer.apple.com/documentation/swiftui/vstacklayout) — A vertical container that you can use in conditional layouts. _(Apple Developer; expandir sob demanda)_
- [ZStackLayout](https://developer.apple.com/documentation/swiftui/zstacklayout) — An overlaying container that you can use in conditional layouts. _(Apple Developer; expandir sob demanda)_
- [GridLayout](https://developer.apple.com/documentation/swiftui/gridlayout) — A grid that you can use in conditional layouts. _(Apple Developer; expandir sob demanda)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(contexto local)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(contexto local)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(contexto local)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(contexto local)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(contexto local)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/custom-layout)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `b77128410b57c786a71045ec2c4d39d45192a8c09a89f77986de2acee99926b8`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
