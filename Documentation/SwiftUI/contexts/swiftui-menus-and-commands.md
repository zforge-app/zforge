---
title: "Menus and commands"
source_url: "https://developer.apple.com/documentation/swiftui/menus-and-commands"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Menus-and-commands"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "443eb2622a981d2c87327c5bc1a2bc966eb01164ad244adfcfe046a7f6fd75a0"
source_etag: "W/\"a9b84b7ca524abe34c976d62e7fc15fb\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Menus and commands

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Provide space-efficient, context-dependent access to commands and controls.

Use a menu to provide people with easy access to common commands. You can add items to a macOS or iPadOS app’s menu bar using the commands(content:) scene modifier, or create context menus that people reveal near their current task using the contextMenu(menuItems:) view modifier. Create submenus by nesting Menu instances inside others. Use a Divider view to create a separator between menu elements. For design guidance, see Menus in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [commands(content:)](https://developer.apple.com/documentation/swiftui/scene/commands(content:)) — Adds commands to the scene. _(Apple Developer; expand on demand)_
- [contextMenu(menuItems:)](https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:)) — Adds a context menu to a view. _(Apple Developer; expand on demand)_
- [Menu](https://developer.apple.com/documentation/swiftui/menu) — A control for presenting a menu of actions. _(Apple Developer; expand on demand)_
- [Divider](https://developer.apple.com/documentation/swiftui/divider) — A visual element that can be used to separate other content. _(Apple Developer; expand on demand)_
- [Menus](https://developer.apple.com/design/Human-Interface-Guidelines/menus) — A menu reveals its options when people interact with it, making it a space-efficient way to present commands in your app or game. _(Apple Developer; expand on demand)_

### Building a menu bar

- [Building and customizing the menu bar with SwiftUI](https://developer.apple.com/documentation/swiftui/building-and-customizing-the-menu-bar-with-swiftui) — Provide a seamless, cross-platform user experience by building a native menu bar for iPadOS and macOS. _(Apple Developer; expand on demand)_

### Creating a menu

- [Populating SwiftUI menus with adaptive controls](https://developer.apple.com/documentation/swiftui/populating-swiftui-menus-with-adaptive-controls) — Improve your app by populating menus with controls and organizing your content intuitively. _(Apple Developer; expand on demand)_
- [menuStyle(_:)](https://developer.apple.com/documentation/swiftui/view/menustyle(_:)) — Sets the style for menus within this view. _(Apple Developer; expand on demand)_

### Creating context menus

- [contextMenu(menuItems:preview:)](https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:preview:)) — Adds a context menu with a custom preview to a view. _(Apple Developer; expand on demand)_
- [contextMenu(forSelectionType:menu:primaryAction:)](https://developer.apple.com/documentation/swiftui/view/contextmenu(forselectiontype:menu:primaryaction:)) — Adds an item-based context menu to a view. _(Apple Developer; expand on demand)_

### Defining commands

- [commandsRemoved()](https://developer.apple.com/documentation/swiftui/scene/commandsremoved()) — Removes all commands defined by the modified scene. _(Apple Developer; expand on demand)_
- [commandsReplaced(content:)](https://developer.apple.com/documentation/swiftui/scene/commandsreplaced(content:)) — Replaces all commands defined by the modified scene with the commands from the builder. _(Apple Developer; expand on demand)_
- [Commands](https://developer.apple.com/documentation/swiftui/commands) — Conforming types represent a group of related commands that can be exposed to the user via the main menu on macOS and key commands… _(Apple Developer; expand on demand)_
- [CommandMenu](https://developer.apple.com/documentation/swiftui/commandmenu) — Command menus are stand-alone, top-level containers for controls that perform related, app-specific commands. _(Apple Developer; expand on demand)_
- [CommandGroup](https://developer.apple.com/documentation/swiftui/commandgroup) — Groups of controls that you can add to existing command menus. _(Apple Developer; expand on demand)_
- [CommandsBuilder](https://developer.apple.com/documentation/swiftui/commandsbuilder) — Constructs command sets from multi-expression closures. Like , it supports up to ten expressions in the closure body. _(Apple Developer; expand on demand)_
- [CommandGroupPlacement](https://developer.apple.com/documentation/swiftui/commandgroupplacement) — The standard locations that you can place new command groups relative to. _(Apple Developer; expand on demand)_

### Getting built-in command groups

- [SidebarCommands](https://developer.apple.com/documentation/swiftui/sidebarcommands) — A built-in set of commands for manipulating window sidebars. _(Apple Developer; expand on demand)_
- [TextEditingCommands](https://developer.apple.com/documentation/swiftui/texteditingcommands) — A built-in group of commands for searching, editing, and transforming selections of text. _(Apple Developer; expand on demand)_
- [TextFormattingCommands](https://developer.apple.com/documentation/swiftui/textformattingcommands) — A built-in set of commands for transforming the styles applied to selections of text. _(Apple Developer; expand on demand)_
- [ToolbarCommands](https://developer.apple.com/documentation/swiftui/toolbarcommands) — A built-in set of commands for manipulating window toolbars. _(Apple Developer; expand on demand)_
- [ImportFromDevicesCommands](https://developer.apple.com/documentation/swiftui/importfromdevicescommands) — A built-in set of commands that enables importing content from nearby devices. _(Apple Developer; expand on demand)_
- [InspectorCommands](https://developer.apple.com/documentation/swiftui/inspectorcommands) — A built-in set of commands for manipulating inspectors. _(Apple Developer; expand on demand)_
- [EmptyCommands](https://developer.apple.com/documentation/swiftui/emptycommands) — An empty group of commands. _(Apple Developer; expand on demand)_

### Showing a menu indicator

- [menuIndicator(_:)](https://developer.apple.com/documentation/swiftui/view/menuindicator(_:)) — Sets the menu indicator visibility for controls within this view. _(Apple Developer; expand on demand)_
- [menuIndicatorVisibility](https://developer.apple.com/documentation/swiftui/environmentvalues/menuindicatorvisibility) — The menu indicator visibility to apply to controls within a view. _(Apple Developer; expand on demand)_

### Configuring menu dismissal

- [menuActionDismissBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/menuactiondismissbehavior(_:)) — Tells a menu whether to dismiss after performing an action. _(Apple Developer; expand on demand)_
- [MenuActionDismissBehavior](https://developer.apple.com/documentation/swiftui/menuactiondismissbehavior) — The set of menu dismissal behavior options. _(Apple Developer; expand on demand)_

### Setting a preferred order

- [menuOrder(_:)](https://developer.apple.com/documentation/swiftui/view/menuorder(_:)) — Sets the preferred order of items for menus presented from this view. _(Apple Developer; expand on demand)_
- [menuOrder](https://developer.apple.com/documentation/swiftui/environmentvalues/menuorder) — The preferred order of items for menus presented from this view. _(Apple Developer; expand on demand)_
- [MenuOrder](https://developer.apple.com/documentation/swiftui/menuorder) — The order in which a menu presents its content. _(Apple Developer; expand on demand)_

### Deprecated types

- [MenuButton](https://developer.apple.com/documentation/swiftui/menubutton) — A button that displays a menu containing a list of choices when pressed. _(Apple Developer; expand on demand)_
- [PullDownButton](https://developer.apple.com/documentation/swiftui/pulldownbutton) — _Apple Developer; expand on demand_
- [ContextMenu](https://developer.apple.com/documentation/swiftui/contextmenu) — A container for views that you present as menu items in a context menu. _(Apple Developer; expand on demand)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(local context)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(local context)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(local context)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/menus-and-commands)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `443eb2622a981d2c87327c5bc1a2bc966eb01164ad244adfcfe046a7f6fd75a0`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
