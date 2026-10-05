---
title: "View configuration"
source_url: "https://developer.apple.com/documentation/swiftui/view-configuration"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View-configuration"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "39cbb23f5bb5da3b87e5aceeb3d5e3245c3ff5a56ff1302f5a74b5f1bb0940cb"
source_etag: "W/\"4c79ead411f15781507dcc6cdeed0a86\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# View configuration

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Adjust the characteristics of views in a hierarchy.

SwiftUI enables you to tune the appearance and behavior of views using view modifiers. Many modifiers apply to specific kinds of views or behaviors, but some apply more generally. For example, you can conditionally hide any view by dynamically setting its opacity, display contextual help when people hover over a view, or request the light or dark appearance for a view.

## Content map

- Overview

## Second-level links

### Hiding views

- [opacity(_:)](https://developer.apple.com/documentation/swiftui/view/opacity(_:)) — Sets the transparency of this view. _(Apple Developer; expand on demand)_
- [hidden()](https://developer.apple.com/documentation/swiftui/view/hidden()) — Hides this view unconditionally. _(Apple Developer; expand on demand)_

### Hiding system elements

- [labelsHidden()](https://developer.apple.com/documentation/swiftui/view/labelshidden()) — Hides the labels of any controls contained within this view. _(Apple Developer; expand on demand)_
- [labelsVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/labelsvisibility(_:)) — Controls the visibility of labels of any controls contained within this view. _(Apple Developer; expand on demand)_
- [labelsVisibility](https://developer.apple.com/documentation/swiftui/environmentvalues/labelsvisibility) — The labels visibility set by labelsVisibility(_:). _(Apple Developer; expand on demand)_
- [menuIndicator(_:)](https://developer.apple.com/documentation/swiftui/view/menuindicator(_:)) — Sets the menu indicator visibility for controls within this view. _(Apple Developer; expand on demand)_
- [statusBarHidden(_:)](https://developer.apple.com/documentation/swiftui/view/statusbarhidden(_:)) — Sets the visibility of the status bar. _(Apple Developer; expand on demand)_
- [persistentSystemOverlays(_:)](https://developer.apple.com/documentation/swiftui/view/persistentsystemoverlays(_:)) — Sets the preferred visibility of the non-transient system views overlaying the app. _(Apple Developer; expand on demand)_
- [Visibility](https://developer.apple.com/documentation/swiftui/visibility) — The visibility of a UI element, chosen automatically based on the platform, current context, and other factors. _(Apple Developer; expand on demand)_

### Managing view interaction

- [disabled(_:)](https://developer.apple.com/documentation/swiftui/view/disabled(_:)) — Adds a condition that controls whether users can interact with this view. _(Apple Developer; expand on demand)_
- [isEnabled](https://developer.apple.com/documentation/swiftui/environmentvalues/isenabled) — A Boolean value that indicates whether the view associated with this environment allows user interaction. _(Apple Developer; expand on demand)_
- [interactionActivityTrackingTag(_:)](https://developer.apple.com/documentation/swiftui/view/interactionactivitytrackingtag(_:)) — Sets a tag that you use for tracking interactivity. _(Apple Developer; expand on demand)_
- [invalidatableContent(_:)](https://developer.apple.com/documentation/swiftui/view/invalidatablecontent(_:)) — Mark the receiver as their content might be invalidated. _(Apple Developer; expand on demand)_

### Providing contextual help

- [help(_:)](https://developer.apple.com/documentation/swiftui/view/help(_:)) — Adds help text to a view using a localized string resource that you provide. _(Apple Developer; expand on demand)_

### Detecting and requesting the light or dark appearance

- [preferredColorScheme(_:)](https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:)) — Sets the preferred color scheme for this presentation. _(Apple Developer; expand on demand)_
- [colorScheme](https://developer.apple.com/documentation/swiftui/environmentvalues/colorscheme) — The color scheme of this environment. _(Apple Developer; expand on demand)_
- [ColorScheme](https://developer.apple.com/documentation/swiftui/colorscheme) — The possible color schemes, corresponding to the light and dark appearances. _(Apple Developer; expand on demand)_

### Getting the color scheme contrast

- [colorSchemeContrast](https://developer.apple.com/documentation/swiftui/environmentvalues/colorschemecontrast) — The contrast associated with the color scheme of this environment. _(Apple Developer; expand on demand)_
- [ColorSchemeContrast](https://developer.apple.com/documentation/swiftui/colorschemecontrast) — The contrast between the app’s foreground and background colors. _(Apple Developer; expand on demand)_

### Configuring passthrough

- [preferredSurroundingsEffect(_:)](https://developer.apple.com/documentation/swiftui/view/preferredsurroundingseffect(_:)) — Applies an effect to passthrough video. _(Apple Developer; expand on demand)_
- [SurroundingsEffect](https://developer.apple.com/documentation/swiftui/surroundingseffect) — Effects that the system can apply to passthrough video. _(Apple Developer; expand on demand)_
- [breakthroughEffect(_:)](https://developer.apple.com/documentation/swiftui/view/breakthrougheffect(_:)) — Ensures that the view is always visible to the user, even when other content is occluding it, like 3D models. _(Apple Developer; expand on demand)_
- [BreakthroughEffect](https://developer.apple.com/documentation/swiftui/breakthrougheffect) — _Apple Developer; expand on demand_

### Redacting private content

- [Designing your app for the Always On state](https://developer.apple.com/documentation/watchOS-Apps/designing-your-app-for-the-always-on-state) — Customize your watchOS app’s user interface for continuous display. _(Apple Developer; expand on demand)_
- [Protecting sensitive content when screen sharing and remote control are active](https://developer.apple.com/documentation/swiftui/protecting-sensitive-content-when-screen-sharing) — Detect active screen capture sessions and respond appropriately to protect sensitive content in your app. _(Apple Developer; expand on demand)_
- [privacySensitive(_:)](https://developer.apple.com/documentation/swiftui/view/privacysensitive(_:)) — Marks the view as containing sensitive, private user data. _(Apple Developer; expand on demand)_
- [redacted(reason:)](https://developer.apple.com/documentation/swiftui/view/redacted(reason:)) — Adds a reason to apply a redaction to this view hierarchy. _(Apple Developer; expand on demand)_
- [unredacted()](https://developer.apple.com/documentation/swiftui/view/unredacted()) — Removes any reason to apply a redaction to this view hierarchy. _(Apple Developer; expand on demand)_
- [redactionReasons](https://developer.apple.com/documentation/swiftui/environmentvalues/redactionreasons) — The current redaction reasons applied to the view hierarchy. _(Apple Developer; expand on demand)_
- [isSceneCaptured](https://developer.apple.com/documentation/swiftui/environmentvalues/isscenecaptured) — The current capture state. _(Apple Developer; expand on demand)_
- [RedactionReasons](https://developer.apple.com/documentation/swiftui/redactionreasons) — The reasons to apply a redaction to data displayed on screen. _(Apple Developer; expand on demand)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(local context)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(local context)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(local context)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view-configuration)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `39cbb23f5bb5da3b87e5aceeb3d5e3245c3ff5a56ff1302f5a74b5f1bb0940cb`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
