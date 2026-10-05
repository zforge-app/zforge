---
title: "UIKit"
source_url: "https://developer.apple.com/documentation/UIKit"
source_identifier: "doc://com.apple.uikit/documentation/UIKit"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "1798eb5b7ec68919c42aec6d007bb95a8b794204abfc1fcc9163f9b87cef6bd3"
source_etag: "W/\"e787d1a035db099f4f31bcaf07ccfc00\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Overview"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# UIKit

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Framework
- Module: UIKit
- Relevance to Zforge: Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge.
- Availability: iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.0+, tvOS 9.0+, visionOS 1.0+, watchOS 2.0+

## Summary

**Official summary:** Construct and manage a graphical, event-driven user interface for your iOS, iPadOS, or tvOS app.

UIKit provides a variety of features for building apps, including components you can use to construct the core infrastructure of your iOS, iPadOS, or tvOS apps. The framework provides the window and view architecture for implementing your UI, the event-handling infrastructure for delivering Multi-Touch and other types of input to your app, and the main run loop for managing interactions between the user, the system, and your app. UIKit also includes support for animations, documents, drawing and printing, text management and display, search, app extensions, resource management, and getting information about the current device. You can also customize accessibility support, and localize your app’s interface for different languages, countries, or cultural regions. UIKit works seamlessly with the SwiftUI framework, so you can implement parts of your UIKit app in SwiftUI or mix interface elements between the two frameworks. For example, you can place UIKit views and view controllers inside SwiftUI…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [SwiftUI](swiftui.md) — Declare the user interface and behavior for your app on every platform. _(local context)_
- [AppKit](appkit.md) — Construct and manage a graphical, event-driven user interface for your macOS app. _(local context)_
- [Mac Catalyst](https://developer.apple.com/documentation/uikit/mac-catalyst) — Create a version of your iPad app that users can run on a Mac device. _(Apple Developer; expand on demand)_
- [UIResponder](https://developer.apple.com/documentation/uikit/uiresponder) — An abstract interface for responding to and handling events. _(Apple Developer; expand on demand)_

### Essentials

- [Adopting Liquid Glass](technologyoverviews-adopting-liquid-glass.md) — Find out how to bring the new material to your app. _(local context)_
- [UIKit updates](https://developer.apple.com/documentation/Updates/UIKit) — Learn about important changes to UIKit. _(Apple Developer; expand on demand)_
- [About app development with UIKit](https://developer.apple.com/documentation/uikit/about-app-development-with-uikit) — Learn about the basic support that UIKit and Xcode provide for your iOS and tvOS apps. _(Apple Developer; expand on demand)_
- [Protecting the User’s Privacy](https://developer.apple.com/documentation/uikit/protecting-the-user-s-privacy) — Secure personal data, and respect user preferences for how data is used. _(Apple Developer; expand on demand)_

### App structure

- [App and environment](https://developer.apple.com/documentation/uikit/app-and-environment) — Manage life-cycle events and your app’s UI scenes, and get information about traits and the environment in which your app runs. _(Apple Developer; expand on demand)_
- [Documents, data, and pasteboard](https://developer.apple.com/documentation/uikit/documents-data-and-pasteboard) — Organize your app’s data and share that data on the pasteboard. _(Apple Developer; expand on demand)_
- [Resource management](https://developer.apple.com/documentation/uikit/resource-management) — Manage the images, strings, storyboards, and nib files that you use to implement your app’s interface. _(Apple Developer; expand on demand)_
- [App extensions](https://developer.apple.com/documentation/uikit/app-extensions) — Extend your app’s basic functionality to other parts of the system. _(Apple Developer; expand on demand)_
- [Interprocess communication](https://developer.apple.com/documentation/uikit/interprocess-communication) — Display activity-based services to people. _(Apple Developer; expand on demand)_

### User interface

- [Views and controls](https://developer.apple.com/documentation/uikit/views-and-controls) — Present your content onscreen and define the interactions allowed with that content. _(Apple Developer; expand on demand)_
- [View controllers](https://developer.apple.com/documentation/uikit/view-controllers) — Manage your interface using view controllers and facilitate navigation around your app’s content. _(Apple Developer; expand on demand)_
- [View layout](https://developer.apple.com/documentation/uikit/view-layout) — Use stack views to lay out the views of your interface automatically. Use Auto Layout when you require precise placement of your views. _(Apple Developer; expand on demand)_
- [Appearance customization](https://developer.apple.com/documentation/uikit/appearance-customization) — Apply Liquid Glass to views, support Dark Mode in your app, customize the appearance of bars, and use appearance proxies to modify your UI. _(Apple Developer; expand on demand)_
- [Animation and haptics](https://developer.apple.com/documentation/uikit/animation-and-haptics) — Provide feedback to users using view-based animations and haptics. _(Apple Developer; expand on demand)_
- [Windows and screens](https://developer.apple.com/documentation/uikit/windows-and-screens) — Provide a container for your view hierarchies and other content. _(Apple Developer; expand on demand)_

### User interactions

- [Touches, presses, and gestures](https://developer.apple.com/documentation/uikit/touches-presses-and-gestures) — Encapsulate your app’s event-handling logic in gesture recognizers so that you can reuse that code throughout your app. _(Apple Developer; expand on demand)_
- [Menus and shortcuts](https://developer.apple.com/documentation/uikit/menus-and-shortcuts) — Simplify interactions with your app using menu systems, contextual menus, Home Screen quick actions, and keyboard shortcuts. _(Apple Developer; expand on demand)_
- [Drag and drop](https://developer.apple.com/documentation/uikit/drag-and-drop) — Bring drag and drop to your app by using interaction APIs with your views. _(Apple Developer; expand on demand)_
- [Pointer interactions](https://developer.apple.com/documentation/uikit/pointer-interactions) — Support pointer interactions in your custom controls and views. _(Apple Developer; expand on demand)_
- [Apple Pencil interactions](https://developer.apple.com/documentation/uikit/apple-pencil-interactions) — Handle user interactions like double tap and squeeze on Apple Pencil. _(Apple Developer; expand on demand)_
- [Focus-based navigation](https://developer.apple.com/documentation/uikit/focus-based-navigation) — Navigate the interface of your UIKit app using a remote, game controller, or keyboard. _(Apple Developer; expand on demand)_
- [Accessibility for UIKit](https://developer.apple.com/documentation/uikit/accessibility-for-uikit) — Make your UIKit apps accessible to everyone who uses iOS and tvOS. _(Apple Developer; expand on demand)_

### Graphics, drawing, and printing

- [Images and PDF](https://developer.apple.com/documentation/uikit/images-and-pdf) — Create and manage images, including those that use bitmap and PDF formats. _(Apple Developer; expand on demand)_
- [Drawing](https://developer.apple.com/documentation/uikit/drawing) — Configure your app’s drawing environment using colors, renderers, draw paths, strings, and shadows. _(Apple Developer; expand on demand)_
- [Printing](https://developer.apple.com/documentation/uikit/printing) — Display the system print panels and manage the printing process. _(Apple Developer; expand on demand)_

### Text

- [Text display and fonts](https://developer.apple.com/documentation/uikit/text-display-and-fonts) — Display text, manage fonts, and check spelling. _(Apple Developer; expand on demand)_
- [TextKit](https://developer.apple.com/documentation/uikit/textkit) — Manage text storage and perform custom layout of text-based content in your app’s views. _(Apple Developer; expand on demand)_
- [Keyboards and input](https://developer.apple.com/documentation/uikit/keyboards-and-input) — Configure the system keyboard, create your own keyboards to handle input, or detect key presses on a physical keyboard. _(Apple Developer; expand on demand)_
- [Writing Tools](https://developer.apple.com/documentation/uikit/writing-tools) — Add support for Writing Tools to your app’s text views. _(Apple Developer; expand on demand)_
- [Handwriting recognition](https://developer.apple.com/documentation/uikit/handwriting-recognition) — Configure text fields and custom views that accept text to handle input from Apple Pencil. _(Apple Developer; expand on demand)_

### Deprecated

- [Deprecated symbols](https://developer.apple.com/documentation/uikit/deprecated-symbols) — Review unsupported symbols and their replacements. _(Apple Developer; expand on demand)_

### Reference

- [UIKit Enumerations](https://developer.apple.com/documentation/uikit/uikit-enumerations) — _Apple Developer; expand on demand_
- [UIKit Constants](https://developer.apple.com/documentation/uikit/uikit-constants) — This document describes constants that are used throughout the UIKit framework. _(Apple Developer; expand on demand)_
- [UIKit Data Types](https://developer.apple.com/documentation/uikit/uikit-data-types) — The UIKit framework defines data types that are used in multiple places throughout the framework. _(Apple Developer; expand on demand)_
- [UIKit Functions](https://developer.apple.com/documentation/uikit/uikit-functions) — The UIKit framework defines a number of functions, many of them used in graphics and drawing operations. _(Apple Developer; expand on demand)_

### Classes

- [UIColorEffect](https://developer.apple.com/documentation/uikit/uicoloreffect) — A visual effect that applies a solid color background. _(Apple Developer; expand on demand)_
- [UILookToScrollInteraction](https://developer.apple.com/documentation/uikit/uilooktoscrollinteraction) — _Apple Developer; expand on demand_
- [UISceneAccessory](https://developer.apple.com/documentation/uikit/uisceneaccessory) — A type which can be used to register for a specific type of scene accessory presentation. _(Apple Developer; expand on demand)_
- [UISceneAccessoryRegistration](https://developer.apple.com/documentation/uikit/uisceneaccessoryregistration) — A type which represents the registration for a given scene accessory. _(Apple Developer; expand on demand)_
- [UISceneClosureConfirmation](https://developer.apple.com/documentation/uikit/uisceneclosureconfirmation) — A configuration specifying a confirmation dialog that will be shown before a user action will result in destruction of the scene session and the… _(Apple Developer; expand on demand)_

### Structures

- [UIBarButtonItemVisibilityPriority](https://developer.apple.com/documentation/uikit/uibarbuttonitemvisibilitypriority) — _Apple Developer; expand on demand_
- [UIBarMinimization](https://developer.apple.com/documentation/uikit/uibarminimization-swift.struct) — _Apple Developer; expand on demand_

### Macros

- [Preview(_:traits:arguments:body:)](https://developer.apple.com/documentation/uikit/preview(_:traits:arguments:body:)-6gm4c) — _Apple Developer; expand on demand_
- [Preview(_:traits:arguments:body:)](https://developer.apple.com/documentation/uikit/preview(_:traits:arguments:body:)-7cbjv) — _Apple Developer; expand on demand_

### Enumerations

- [UIBarMinimizationBehavior](https://developer.apple.com/documentation/uikit/uibarminimizationbehavior) — _Apple Developer; expand on demand_
- [UIBarMinimizationRestorationBehavior](https://developer.apple.com/documentation/uikit/uibarminimizationrestorationbehavior) — _Apple Developer; expand on demand_
- [UIBarMinimizationSafeAreaAdjustment](https://developer.apple.com/documentation/uikit/uibarminimizationsafeareaadjustment) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/UIKit)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `1798eb5b7ec68919c42aec6d007bb95a8b794204abfc1fcc9163f9b87cef6bd3`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
