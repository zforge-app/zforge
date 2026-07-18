---
title: "Toolbars"
source_url: "https://developer.apple.com/documentation/swiftui/toolbars"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Toolbars"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "406106e901ef6c8125d8f2cfac941dfbbba533762e2cad8f71e1eb04bfc02ed1"
source_etag: "W/\"b8ad34667a0418c27927de1b051ab295\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Toolbars

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Provide immediate access to frequently used commands and controls.

The system might present toolbars above or below your app’s content, depending on the platform and the context. Add items to a toolbar by applying the toolbar(content:) view modifier to a view in your app. You can also configure the toolbar using view modifiers. For example, you can set the visibility of a toolbar with the toolbar(_:for:) modifier. For design guidance, see Toolbars in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [toolbar(content:)](https://developer.apple.com/documentation/swiftui/view/toolbar(content:)) — Populates the toolbar or navigation bar with the specified items. _(Apple Developer; expandir sob demanda)_
- [toolbar(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbar(_:for:)) — Specifies the visibility of a bar managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [Toolbars](https://developer.apple.com/design/Human-Interface-Guidelines/toolbars) — A toolbar provides convenient access to frequently used commands, controls, navigation, and search. _(Apple Developer; expandir sob demanda)_

### Populating a toolbar

- [ToolbarItem](https://developer.apple.com/documentation/swiftui/toolbaritem) — A model that represents an item which can be placed in the toolbar or navigation bar. _(Apple Developer; expandir sob demanda)_
- [ToolbarItemGroup](https://developer.apple.com/documentation/swiftui/toolbaritemgroup) — A model that represents a group of s which can be placed in the toolbar or navigation bar. _(Apple Developer; expandir sob demanda)_
- [ToolbarItemPlacement](https://developer.apple.com/documentation/swiftui/toolbaritemplacement) — A structure that defines the placement of a toolbar item. _(Apple Developer; expandir sob demanda)_
- [toolbarOverflowMenu(content:)](https://developer.apple.com/documentation/swiftui/view/toolbaroverflowmenu(content:)) — Configures the overflow menu of a toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarOverflowMenu](https://developer.apple.com/documentation/swiftui/toolbaroverflowmenu) — The overflow menu of a toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarContent](https://developer.apple.com/documentation/swiftui/toolbarcontent) — Conforming types represent items that can be placed in various locations in a toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarContentBuilder](https://developer.apple.com/documentation/swiftui/toolbarcontentbuilder) — Constructs a toolbar item set from multi-expression closures. _(Apple Developer; expandir sob demanda)_
- [ToolbarSpacer](https://developer.apple.com/documentation/swiftui/toolbarspacer) — A standard space item in toolbars. _(Apple Developer; expandir sob demanda)_
- [DefaultToolbarItem](https://developer.apple.com/documentation/swiftui/defaulttoolbaritem) — A toolbar item that represents a system component. _(Apple Developer; expandir sob demanda)_

### Populating a customizable toolbar

- [toolbar(id:content:)](https://developer.apple.com/documentation/swiftui/view/toolbar(id:content:)) — Populates the toolbar or navigation bar with the specified items, allowing for user customization. _(Apple Developer; expandir sob demanda)_
- [toolbarItemHidden(_:)](https://developer.apple.com/documentation/swiftui/view/toolbaritemhidden(_:)) — Hides an individual view within a control group toolbar item. _(Apple Developer; expandir sob demanda)_
- [CustomizableToolbarContent](https://developer.apple.com/documentation/swiftui/customizabletoolbarcontent) — Conforming types represent items that can be placed in various locations in a customizable toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarCustomizationBehavior](https://developer.apple.com/documentation/swiftui/toolbarcustomizationbehavior) — The customization behavior of customizable toolbar content. _(Apple Developer; expandir sob demanda)_
- [ToolbarCustomizationOptions](https://developer.apple.com/documentation/swiftui/toolbarcustomizationoptions) — Options that influence the default customization behavior of customizable toolbar content. _(Apple Developer; expandir sob demanda)_
- [SearchToolbarBehavior](https://developer.apple.com/documentation/swiftui/searchtoolbarbehavior) — The behavior of a search field in a toolbar. _(Apple Developer; expandir sob demanda)_

### Removing default items

- [toolbar(removing:)](https://developer.apple.com/documentation/swiftui/view/toolbar(removing:)) — Remove a toolbar item present by default _(Apple Developer; expandir sob demanda)_
- [ToolbarDefaultItemKind](https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind) — A kind of toolbar item a adds by default. _(Apple Developer; expandir sob demanda)_

### Setting toolbar visibility

- [toolbarVisibility(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarvisibility(_:for:)) — Specifies the visibility of a bar managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [toolbarBackgroundVisibility(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarbackgroundvisibility(_:for:)) — Specifies the preferred visibility of backgrounds on a bar managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [ToolbarPlacement](https://developer.apple.com/documentation/swiftui/toolbarplacement) — The placement of a toolbar. _(Apple Developer; expandir sob demanda)_
- [ContentToolbarPlacement](https://developer.apple.com/documentation/swiftui/contenttoolbarplacement) — _Apple Developer; expandir sob demanda_

### Specifying the role of toolbar content

- [toolbarRole(_:)](https://developer.apple.com/documentation/swiftui/view/toolbarrole(_:)) — Configures the semantic role for the content populating the toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarRole](https://developer.apple.com/documentation/swiftui/toolbarrole) — The purpose of content that populates the toolbar. _(Apple Developer; expandir sob demanda)_

### Styling a toolbar

- [toolbarBackground(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarbackground(_:for:)) — Specifies the preferred shape style of the background of a bar managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [toolbarColorScheme(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarcolorscheme(_:for:)) — Specifies the preferred color scheme of a bar managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [toolbarForegroundStyle(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarforegroundstyle(_:for:)) — Specifies the preferred foreground style of bars managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [windowToolbarStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarstyle(_:)) — Sets the style for the toolbar defined within this scene. _(Apple Developer; expandir sob demanda)_
- [WindowToolbarStyle](https://developer.apple.com/documentation/swiftui/windowtoolbarstyle) — A specification for the appearance and behavior of a window’s toolbar. _(Apple Developer; expandir sob demanda)_
- [toolbarLabelStyle](https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarlabelstyle) — The label style to apply to controls within a toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarLabelStyle](https://developer.apple.com/documentation/swiftui/toolbarlabelstyle) — The label style of a toolbar. _(Apple Developer; expandir sob demanda)_
- [SpacerSizing](https://developer.apple.com/documentation/swiftui/spacersizing) — A type which defines how spacers should size themselves. _(Apple Developer; expandir sob demanda)_

### Configuring the toolbar title display mode

- [toolbarTitleDisplayMode(_:)](https://developer.apple.com/documentation/swiftui/view/toolbartitledisplaymode(_:)) — Configures the toolbar title display mode for this view. _(Apple Developer; expandir sob demanda)_
- [ToolbarTitleDisplayMode](https://developer.apple.com/documentation/swiftui/toolbartitledisplaymode) — A type that defines the behavior of title of a toolbar. _(Apple Developer; expandir sob demanda)_

### Setting the toolbar title menu

- [toolbarTitleMenu(content:)](https://developer.apple.com/documentation/swiftui/view/toolbartitlemenu(content:)) — Configure the title menu of a toolbar. _(Apple Developer; expandir sob demanda)_
- [ToolbarTitleMenu](https://developer.apple.com/documentation/swiftui/toolbartitlemenu) — The title menu of a toolbar. _(Apple Developer; expandir sob demanda)_

### Creating an ornament

- [ornament(visibility:attachmentAnchor:contentAlignment:ornament:)](https://developer.apple.com/documentation/swiftui/view/ornament(visibility:attachmentanchor:contentalignment:ornament:)) — Presents an ornament. _(Apple Developer; expandir sob demanda)_
- [OrnamentAttachmentAnchor](https://developer.apple.com/documentation/swiftui/ornamentattachmentanchor) — An attachment anchor for an ornament. _(Apple Developer; expandir sob demanda)_

### Controlling item visibility

- [visibilityPriority(_:)](https://developer.apple.com/documentation/swiftui/toolbarcontent/visibilitypriority(_:)) — Defines the visibility priority for a toolbar item. _(Apple Developer; expandir sob demanda)_
- [ToolbarItemVisibilityPriority](https://developer.apple.com/documentation/swiftui/toolbaritemvisibilitypriority) — A value that defines the visibility priority of a toolbar item. _(Apple Developer; expandir sob demanda)_

### Minimizing a toolbar

- [toolbarMinimizationSafeAreaAdjustment(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationsafeareaadjustment(_:for:)) — Sets the safe area adjustment for the specified bars during minimization. _(Apple Developer; expandir sob demanda)_
- [ToolbarMinimizationSafeAreaAdjustment](https://developer.apple.com/documentation/swiftui/toolbarminimizationsafeareaadjustment) — The safe area adjustment during toolbar minimization. _(Apple Developer; expandir sob demanda)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(contexto local)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(contexto local)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(contexto local)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/toolbars)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `406106e901ef6c8125d8f2cfac941dfbbba533762e2cad8f71e1eb04bfc02ed1`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
