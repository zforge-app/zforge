---
title: "AppKit"
source_url: "https://developer.apple.com/documentation/AppKit"
source_identifier: "doc://com.apple.appkit/documentation/AppKit"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "9a841008d1e8b1f8ae93506da53f4604e472f9e350ea73d5bc89ed7a8b3f5519"
source_etag: "W/\"b5c3f135015e31be5a239fba0febf2d1\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Overview"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# AppKit

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Framework
- Módulo: AppKit
- Relevância para Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Disponibilidade: Mac Catalyst 13.0+, macOS 10.0+

## Síntese

**Resumo oficial:** Construct and manage a graphical, event-driven user interface for your macOS app.

AppKit contains the objects you need to build the user interface for a macOS app. In addition to drawing windows, buttons, panels, and text fields, it handles all the event management and interaction between your app, people, and macOS. Aside from drawing and managing interactions, AppKit handles printing, animating, as well as creating documents with large amounts of data efficiently. The framework also contains built-in support for localization and accessibility to ensure that your app reaches as many people as possible. AppKit also works with SwiftUI, so you can implement parts of your AppKit app in SwiftUI or mix interface elements between the two frameworks. For example, you can place AppKit views and view controllers inside SwiftUI views, and vice versa. For information about bringing your iPad app to Mac, see Mac Catalyst. To build an iOS app, you can use SwiftUI to create an app that works across all…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [SwiftUI](swiftui.md) — Declare the user interface and behavior for your app on every platform. _(contexto local)_
- [Mac Catalyst](https://developer.apple.com/documentation/UIKit/mac-catalyst) — Create a version of your iPad app that users can run on a Mac device. _(Apple Developer; expandir sob demanda)_
- [UIKit](uikit.md) — Construct and manage a graphical, event-driven user interface for your iOS, iPadOS, or tvOS app. _(contexto local)_

### Essentials

- [Adopting Liquid Glass](technologyoverviews-adopting-liquid-glass.md) — Find out how to bring the new material to your app. _(contexto local)_
- [AppKit updates](https://developer.apple.com/documentation/Updates/AppKit) — Learn about important changes to AppKit. _(Apple Developer; expandir sob demanda)_
- [Protecting the User’s Privacy](https://developer.apple.com/documentation/UIKit/protecting-the-user-s-privacy) — Secure personal data, and respect user preferences for how data is used. _(Apple Developer; expandir sob demanda)_
- [Porting your macOS apps to Apple silicon](https://developer.apple.com/documentation/Apple-Silicon/porting-your-macos-apps-to-apple-silicon) — Create a version of your macOS app that runs on both Apple silicon and Intel-based Mac computers. _(Apple Developer; expandir sob demanda)_

### App Structure

- [App and Environment](https://developer.apple.com/documentation/appkit/app-and-environment) — Learn about the objects that you use to interact with the system. _(Apple Developer; expandir sob demanda)_
- [Documents, Data, and Pasteboard](https://developer.apple.com/documentation/appkit/documents-data-and-pasteboard) — Organize your app’s data and preferences, and share that data on the pasteboard or in iCloud. _(Apple Developer; expandir sob demanda)_
- [Cocoa Bindings](https://developer.apple.com/documentation/appkit/cocoa-bindings) — Automatically synchronize your data model with your app’s interface using Cocoa Bindings. _(Apple Developer; expandir sob demanda)_
- [Resource Management](https://developer.apple.com/documentation/appkit/resource-management) — Manage the storyboards and nib files containing your app’s user interface, and learn how to load data that is stored in resource files. _(Apple Developer; expandir sob demanda)_
- [App Extensions](https://developer.apple.com/documentation/appkit/app-extensions) — Extend your app’s basic functionality to other parts of the system. _(Apple Developer; expandir sob demanda)_

### User Interface

- [Views and Controls](https://developer.apple.com/documentation/appkit/views-and-controls) — Present your content onscreen and handle user input and events. _(Apple Developer; expandir sob demanda)_
- [View Management](https://developer.apple.com/documentation/appkit/view-management) — Manage your user interface, including the size and position of views in a window. _(Apple Developer; expandir sob demanda)_
- [View Layout](https://developer.apple.com/documentation/appkit/view-layout) — Position and size views using a stack view or Auto Layout constraints. _(Apple Developer; expandir sob demanda)_
- [Appearance Customization](https://developer.apple.com/documentation/appkit/appearance-customization) — Add Dark Mode support to your app, and use appearance proxies to modify your UI. _(Apple Developer; expandir sob demanda)_
- [Animation](https://developer.apple.com/documentation/appkit/animation) — Animate your views and other content to create a more engaging experience for users. _(Apple Developer; expandir sob demanda)_
- [Windows, Panels, and Screens](https://developer.apple.com/documentation/appkit/windows-panels-and-screens) — Organize your view hierarchies and facilitate their display onscreen. _(Apple Developer; expandir sob demanda)_
- [Sound, Speech, and Haptics](https://developer.apple.com/documentation/appkit/sound-speech-and-haptics) — Play sounds and haptic feedback, and incorporate speech recognition and synthesis into your interface. _(Apple Developer; expandir sob demanda)_
- [Supporting Continuity Camera in Your Mac App](https://developer.apple.com/documentation/appkit/supporting-continuity-camera-in-your-mac-app) — Incorporate scanned documents and pictures from a user’s iPhone, iPad, or iPod touch into your Mac app using Continuity Camera. _(Apple Developer; expandir sob demanda)_

### User Interactions

- [Mouse, Keyboard, and Trackpad](https://developer.apple.com/documentation/appkit/mouse-keyboard-and-trackpad) — Handle events related to mouse, keyboard, and trackpad input. _(Apple Developer; expandir sob demanda)_
- [Menus, Cursors, and the Dock](https://developer.apple.com/documentation/appkit/menus-cursors-and-the-dock) — Implement menus and cursors to facilitate interactions with your app, and use your app’s Dock tile to convey updated information. _(Apple Developer; expandir sob demanda)_
- [Gestures](https://developer.apple.com/documentation/appkit/gestures) — Encapsulate your app’s event-handling logic in gesture recognizers so that you can reuse that code throughout your app. _(Apple Developer; expandir sob demanda)_
- [Touch Bar](https://developer.apple.com/documentation/appkit/touch-bar) — Display interactive content and controls in the Touch Bar. _(Apple Developer; expandir sob demanda)_
- [Drag and Drop](https://developer.apple.com/documentation/appkit/drag-and-drop) — Support the direct manipulation of your app’s content using drag and drop. _(Apple Developer; expandir sob demanda)_
- [Accessibility for AppKit](https://developer.apple.com/documentation/appkit/accessibility-for-appkit) — Make your AppKit apps accessible to everyone who uses macOS. _(Apple Developer; expandir sob demanda)_

### Graphics, Drawing, Color, and Printing

- [Images and PDF](https://developer.apple.com/documentation/appkit/images-and-pdf) — Create and manage images, in bitmap, PDF, and other formats. _(Apple Developer; expandir sob demanda)_
- [Drawing](https://developer.apple.com/documentation/appkit/drawing) — Draw shapes, images, and other content on the screen. _(Apple Developer; expandir sob demanda)_
- [Color](https://developer.apple.com/documentation/appkit/color) — Represent colors using built-in or custom formats, and give users options for selecting and applying colors. _(Apple Developer; expandir sob demanda)_
- [Printing](https://developer.apple.com/documentation/appkit/printing) — Display the system print panels and manage the printing process. _(Apple Developer; expandir sob demanda)_

### Text

- [Text Display](https://developer.apple.com/documentation/appkit/text-display) — Display text and check spelling. _(Apple Developer; expandir sob demanda)_
- [TextKit](https://developer.apple.com/documentation/appkit/textkit) — Manage text storage and perform custom layout of text-based content in your app’s views. _(Apple Developer; expandir sob demanda)_
- [Fonts](https://developer.apple.com/documentation/appkit/fonts) — Manage the fonts used to display text. _(Apple Developer; expandir sob demanda)_
- [Writing Tools](https://developer.apple.com/documentation/appkit/writing-tools) — Add support for Writing Tools to your app’s text views. _(Apple Developer; expandir sob demanda)_

### Deprecated

- [Deprecated Symbols](https://developer.apple.com/documentation/appkit/deprecated-symbols) — Review symbols that are no longer supported, and find the replacements to use instead. _(Apple Developer; expandir sob demanda)_

### Reference

- [Enumerations](https://developer.apple.com/documentation/appkit/enumerations) — Enumerations for use with multiple classes. _(Apple Developer; expandir sob demanda)_
- [Constants](https://developer.apple.com/documentation/appkit/constants) — Constants for use with multiple classes. _(Apple Developer; expandir sob demanda)_
- [Data Types](https://developer.apple.com/documentation/appkit/data-types) — Data types for use with multiple classes. _(Apple Developer; expandir sob demanda)_
- [Macros](https://developer.apple.com/documentation/appkit/macros) — Macros for use with multiple classes. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/AppKit)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `9a841008d1e8b1f8ae93506da53f4604e472f9e350ea73d5bc89ed7a8b3f5519`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
