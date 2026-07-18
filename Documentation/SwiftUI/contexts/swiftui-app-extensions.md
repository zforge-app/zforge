---
title: "App extensions"
source_url: "https://developer.apple.com/documentation/swiftui/app-extensions"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/App-extensions"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "6d97b3163fb152d7df5fc704f6f632a66157648b80ef6ae6a00b2a4a988a1dc5"
source_etag: "W/\"13bae6885bad0676379ac67eca9320e1\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App extensions

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Extend your app’s basic functionality to other parts of the system, like by adding a Widget.

Use SwiftUI along with WidgetKit to add widgets to your app. Widgets provide quick access to relevant content from your app. Define a structure that conforms to the Widget protocol, and declare a view hierarchy for the widget. Configure the views inside the widget as you do other SwiftUI views, using view modifiers, including a few widget-specific modifiers. For design guidance, see Widgets in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [WidgetKit](https://developer.apple.com/documentation/WidgetKit) — Extend the reach of your app by creating widgets, watch complications, Live Activities, and controls. _(Apple Developer; expandir sob demanda)_
- [Widget](https://developer.apple.com/documentation/swiftui/widget) — The configuration and content of a widget to display on the Home screen or in Notification Center. _(Apple Developer; expandir sob demanda)_
- [Widgets](https://developer.apple.com/design/Human-Interface-Guidelines/widgets) — A widget provides quick access to essential information and focused interactions from your app or game in additional contexts. _(Apple Developer; expandir sob demanda)_

### Creating widgets

- [Building Widgets Using WidgetKit and SwiftUI](https://developer.apple.com/documentation/widgetkit/building_widgets_using_widgetkit_and_swiftui) — Create widgets to show your app’s content on the Home screen, with custom intents for user-customizable settings. _(Apple Developer; expandir sob demanda)_
- [Creating a widget extension](https://developer.apple.com/documentation/WidgetKit/Creating-a-Widget-Extension) — Display your app’s content in a convenient, informative widget on various devices. _(Apple Developer; expandir sob demanda)_
- [Keeping a widget up to date](https://developer.apple.com/documentation/WidgetKit/Keeping-a-Widget-Up-To-Date) — Plan your widget’s timeline to show timely, relevant information using dynamic views, and update the timeline when things change. _(Apple Developer; expandir sob demanda)_
- [Making a configurable widget](https://developer.apple.com/documentation/WidgetKit/Making-a-Configurable-Widget) — Give people the option to customize their widgets by adding a custom app intent to your project. _(Apple Developer; expandir sob demanda)_
- [WidgetBundle](https://developer.apple.com/documentation/swiftui/widgetbundle) — A container used to expose multiple widgets from a single widget extension. _(Apple Developer; expandir sob demanda)_
- [LimitedAvailabilityConfiguration](https://developer.apple.com/documentation/swiftui/limitedavailabilityconfiguration) — A type-erased widget configuration. _(Apple Developer; expandir sob demanda)_
- [WidgetConfiguration](https://developer.apple.com/documentation/swiftui/widgetconfiguration) — A type that describes a widget’s content. _(Apple Developer; expandir sob demanda)_
- [EmptyWidgetConfiguration](https://developer.apple.com/documentation/swiftui/emptywidgetconfiguration) — An empty widget configuration. _(Apple Developer; expandir sob demanda)_

### Composing control widgets

- [ControlWidget](https://developer.apple.com/documentation/swiftui/controlwidget) — The configuration and content of a control widget to display in system spaces such as Control Center, the Lock Screen, and the Action Button. _(Apple Developer; expandir sob demanda)_
- [ControlWidgetConfiguration](https://developer.apple.com/documentation/swiftui/controlwidgetconfiguration) — A type that describes a control widget’s content. _(Apple Developer; expandir sob demanda)_
- [EmptyControlWidgetConfiguration](https://developer.apple.com/documentation/swiftui/emptycontrolwidgetconfiguration) — An empty control widget configuration. _(Apple Developer; expandir sob demanda)_
- [ControlWidgetConfigurationBuilder](https://developer.apple.com/documentation/swiftui/controlwidgetconfigurationbuilder) — A custom attribute that constructs a control widget’s body. _(Apple Developer; expandir sob demanda)_
- [ControlWidgetTemplate](https://developer.apple.com/documentation/swiftui/controlwidgettemplate) — A type that describes a control widget’s content. _(Apple Developer; expandir sob demanda)_
- [EmptyControlWidgetTemplate](https://developer.apple.com/documentation/swiftui/emptycontrolwidgettemplate) — An empty control widget template. _(Apple Developer; expandir sob demanda)_
- [ControlWidgetTemplateBuilder](https://developer.apple.com/documentation/swiftui/controlwidgettemplatebuilder) — A custom attribute that constructs a control widget template’s body. _(Apple Developer; expandir sob demanda)_
- [controlWidgetActionHint(_:)](https://developer.apple.com/documentation/swiftui/view/controlwidgetactionhint(_:)) — The action hint of the control described by the modified label. _(Apple Developer; expandir sob demanda)_
- [controlWidgetStatus(_:)](https://developer.apple.com/documentation/swiftui/view/controlwidgetstatus(_:)) — The status of the control described by the modified label. _(Apple Developer; expandir sob demanda)_

### Labeling a widget

- [widgetLabel(_:)](https://developer.apple.com/documentation/swiftui/view/widgetlabel(_:)) — Returns a localized text label that displays additional content outside the accessory family widget’s main SwiftUI view. _(Apple Developer; expandir sob demanda)_
- [widgetLabel(label:)](https://developer.apple.com/documentation/swiftui/view/widgetlabel(label:)) — Creates a label for displaying additional content outside an accessory family widget’s main SwiftUI view. _(Apple Developer; expandir sob demanda)_

### Styling a widget group

- [accessoryWidgetGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/accessorywidgetgroupstyle(_:)) — The view modifier that can be applied to to specify the shape the three content views will be masked with. The value of is… _(Apple Developer; expandir sob demanda)_

### Controlling the accented group

- [widgetAccentable(_:)](https://developer.apple.com/documentation/swiftui/view/widgetaccentable(_:)) — Adds the view and all of its subviews to the accented group. _(Apple Developer; expandir sob demanda)_

### Managing placement in the Dynamic Island

- [dynamicIsland(verticalPlacement:)](https://developer.apple.com/documentation/swiftui/view/dynamicisland(verticalplacement:)) — Specifies the vertical placement for a view of an expanded Live Activity that appears in the Dynamic Island. _(Apple Developer; expandir sob demanda)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(contexto local)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(contexto local)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(contexto local)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/app-extensions)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `6d97b3163fb152d7df5fc704f6f632a66157648b80ef6ae6a00b2a4a988a1dc5`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
