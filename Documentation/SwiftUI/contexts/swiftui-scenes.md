---
title: "Scenes"
source_url: "https://developer.apple.com/documentation/swiftui/scenes"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Scenes"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "ee58c95c81893e0c9632b04d69ece6a6e63131f693cfe9c19ef5ba69724f1c89"
source_etag: "W/\"52c0735db730fb7514a7e37f6eb00989\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Scenes

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Declare the user interface groupings that make up the parts of your app.

A scene represents a part of your app’s user interface that has a life cycle that the system manages. An App instance presents the scenes it contains, while each Scene acts as the root element of a View hierarchy. The system presents scenes in different ways depending on the type of scene, the platform, and the context. A scene might fill the entire display, part of the display, a window, a tab in a window, or something else. In some cases, your app might also be able to display more than one instance of the scene at a time, like when a user simultaneously opens multiple windows based on a single WindowGroup declaration in your app. For more information about the primary built-in scene types, see Windows and Documents. You configure scenes using modifiers, similar to how you configure views. For example, you can adjust the appearance of the window…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [App](swiftui-app.md) — A type that represents the structure and behavior of an app. _(local context)_
- [Scene](https://developer.apple.com/documentation/swiftui/scene) — A part of an app’s user interface with a life cycle managed by the system. _(Apple Developer; expand on demand)_
- [View](swiftui-view.md) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(local context)_
- [WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup) — A scene that presents a group of identically structured windows. _(Apple Developer; expand on demand)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(local context)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(local context)_
- [windowStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowstyle(_:)) — Sets the style for windows created by this scene. _(Apple Developer; expand on demand)_
- [commands(content:)](https://developer.apple.com/documentation/swiftui/scene/commands(content:)) — Adds commands to the scene. _(Apple Developer; expand on demand)_

### Creating scenes

- [SceneBuilder](https://developer.apple.com/documentation/swiftui/scenebuilder) — A result builder for composing a collection of scenes into a single composite scene. _(Apple Developer; expand on demand)_

### Monitoring scene life cycle

- [scenePhase](https://developer.apple.com/documentation/swiftui/environmentvalues/scenephase) — The current phase of the scene. _(Apple Developer; expand on demand)_
- [ScenePhase](https://developer.apple.com/documentation/swiftui/scenephase) — An indication of a scene’s operational state. _(Apple Developer; expand on demand)_

### Managing a settings window

- [Settings](https://developer.apple.com/documentation/swiftui/settings) — A scene that presents an interface for viewing and modifying an app’s settings. _(Apple Developer; expand on demand)_
- [SettingsLink](https://developer.apple.com/documentation/swiftui/settingslink) — A view that opens the Settings scene defined by an app. _(Apple Developer; expand on demand)_
- [OpenSettingsAction](https://developer.apple.com/documentation/swiftui/opensettingsaction) — An action that presents the settings scene for an app. _(Apple Developer; expand on demand)_
- [openSettings](https://developer.apple.com/documentation/swiftui/environmentvalues/opensettings) — A Settings presentation action stored in a view’s environment. _(Apple Developer; expand on demand)_

### Building a menu bar

- [Building and customizing the menu bar with SwiftUI](https://developer.apple.com/documentation/swiftui/building-and-customizing-the-menu-bar-with-swiftui) — Provide a seamless, cross-platform user experience by building a native menu bar for iPadOS and macOS. _(Apple Developer; expand on demand)_

### Creating a menu bar extra

- [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) — A scene that renders itself as a persistent control in the system menu bar. _(Apple Developer; expand on demand)_
- [menuBarExtraStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/menubarextrastyle(_:)) — Sets the style for menu bar extra created by this scene. _(Apple Developer; expand on demand)_
- [MenuBarExtraStyle](https://developer.apple.com/documentation/swiftui/menubarextrastyle) — A specification for the appearance and behavior of a menu bar extra scene. _(Apple Developer; expand on demand)_

### Creating watch notifications

- [WKNotificationScene](https://developer.apple.com/documentation/swiftui/wknotificationscene) — A scene which appears in response to receiving the specified category of remote or local notifications. _(Apple Developer; expand on demand)_

### Presenting content on an external display

- [sceneAccessory(content:)](https://developer.apple.com/documentation/swiftui/view/sceneaccessory(content:)) — Defines any scene accessories associated with . _(Apple Developer; expand on demand)_
- [SceneAccessoryContent](https://developer.apple.com/documentation/swiftui/sceneaccessorycontent) — Conforming types represent items which define content for scene accessories. _(Apple Developer; expand on demand)_
- [ExternalNonInteractiveAccessory](https://developer.apple.com/documentation/swiftui/externalnoninteractiveaccessory) — A scene accessory that presents non-interactive content on an external display. _(Apple Developer; expand on demand)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(local context)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(local context)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(local context)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(local context)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(local context)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(local context)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/scenes)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `ee58c95c81893e0c9632b04d69ece6a6e63131f693cfe9c19ef5ba69724f1c89`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
