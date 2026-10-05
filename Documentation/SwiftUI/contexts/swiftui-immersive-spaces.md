---
title: "Immersive spaces"
source_url: "https://developer.apple.com/documentation/swiftui/immersive-spaces"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Immersive-spaces"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "3b8efdc35a4b9683f2ac73c421fd4d4f45e0c9cbfd728cff3ad183ea16832307"
source_etag: "W/\"7a78c3aba3be1d46b77bedf3b1c61cc7\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Immersive spaces

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge.

## Summary

**Official summary:** Display unbounded content in a person’s surroundings.

Use an immersive space in visionOS to present SwiftUI views outside of any containers. You can include any views in a space, although you typically use a RealityView to present RealityKit content. You can request one of three styles of spaces with the immersionStyle(selection:in:) scene modifier: The mixed style blends your content with passthrough. This enables you to place virtual objects in a person’s surroundings. The full style displays only your content, with passthrough turned off. This enables you to completely control the visual experience, like when you want to transport people to a new world. The progressive style completely replaces passthrough in a portion of the display. You might use this style to keep people grounded in the real world while displaying a view into another world. When you open an immersive space, the system continues to display all of your app’s windows, but hides windows from other apps.…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [RealityView](https://developer.apple.com/documentation/RealityKit/RealityView) — A view that contains RealityKit content. _(Apple Developer; expand on demand)_
- [immersionStyle(selection:in:)](https://developer.apple.com/documentation/swiftui/scene/immersionstyle(selection:in:)) — Sets the style for an immersive space. _(Apple Developer; expand on demand)_
- [mixed](https://developer.apple.com/documentation/swiftui/immersionstyle/mixed) — An immersion style that displays unbounded content intermixed with other app content, along with passthrough video. _(Apple Developer; expand on demand)_
- [full](https://developer.apple.com/documentation/swiftui/immersionstyle/full) — An immersion style that displays unbounded content that completely replaces passthrough video. _(Apple Developer; expand on demand)_
- [progressive](https://developer.apple.com/documentation/swiftui/immersionstyle/progressive) — An immersion style that displays unbounded content that partially replaces passthrough video. _(Apple Developer; expand on demand)_

### Creating an immersive space

- [ImmersiveSpace](https://developer.apple.com/documentation/swiftui/immersivespace) — A scene that presents its content in an unbounded space. _(Apple Developer; expand on demand)_
- [ImmersiveSpaceContentBuilder](https://developer.apple.com/documentation/swiftui/immersivespacecontentbuilder) — A result builder for composing a collection of immersive space elements. _(Apple Developer; expand on demand)_
- [ImmersionStyle](https://developer.apple.com/documentation/swiftui/immersionstyle) — The styles that an immersive space can have. _(Apple Developer; expand on demand)_
- [immersiveSpaceDisplacement](https://developer.apple.com/documentation/swiftui/environmentvalues/immersivespacedisplacement) — The displacement that the system applies to the immersive space when moving the space away from its default position, in meters. _(Apple Developer; expand on demand)_
- [ImmersiveEnvironmentBehavior](https://developer.apple.com/documentation/swiftui/immersiveenvironmentbehavior) — The behavior of the system-provided immersive environments when a scene is opened by your app. _(Apple Developer; expand on demand)_
- [ProgressiveImmersionAspectRatio](https://developer.apple.com/documentation/swiftui/progressiveimmersionaspectratio) — _Apple Developer; expand on demand_

### Opening an immersive space

- [openImmersiveSpace](https://developer.apple.com/documentation/swiftui/environmentvalues/openimmersivespace) — An action that presents an immersive space. _(Apple Developer; expand on demand)_
- [OpenImmersiveSpaceAction](https://developer.apple.com/documentation/swiftui/openimmersivespaceaction) — An action that presents an immersive space. _(Apple Developer; expand on demand)_

### Closing the immersive space

- [dismissImmersiveSpace](https://developer.apple.com/documentation/swiftui/environmentvalues/dismissimmersivespace) — An immersive space dismissal action stored in a view’s environment. _(Apple Developer; expand on demand)_
- [DismissImmersiveSpaceAction](https://developer.apple.com/documentation/swiftui/dismissimmersivespaceaction) — An action that dismisses an immersive space. _(Apple Developer; expand on demand)_

### Hiding upper limbs during immersion

- [upperLimbVisibility(_:)](https://developer.apple.com/documentation/swiftui/scene/upperlimbvisibility(_:)) — Sets the preferred visibility of the user’s upper limbs, while an ImmersiveSpace scene is presented. _(Apple Developer; expand on demand)_
- [upperLimbVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/upperlimbvisibility(_:)) — Sets the preferred visibility of the user’s upper limbs, while an ImmersiveSpace scene is presented. _(Apple Developer; expand on demand)_

### Adjusting content brightness

- [immersiveContentBrightness(_:)](https://developer.apple.com/documentation/swiftui/scene/immersivecontentbrightness(_:)) — Sets the content brightness of an immersive space. _(Apple Developer; expand on demand)_
- [ImmersiveContentBrightness](https://developer.apple.com/documentation/swiftui/immersivecontentbrightness) — The content brightness of an immersive space. _(Apple Developer; expand on demand)_

### Responding to immersion changes

- [onImmersionChange(initial:_:)](https://developer.apple.com/documentation/swiftui/view/onimmersionchange(initial:_:)) — Performs an action when the immersion state of your app changes. _(Apple Developer; expand on demand)_
- [ImmersionChangeContext](https://developer.apple.com/documentation/swiftui/immersionchangecontext) — A structure that represents a state of immersion of your app. _(Apple Developer; expand on demand)_

### Adding menu items to an immersive space

- [immersiveEnvironmentPicker(content:)](https://developer.apple.com/documentation/swiftui/view/immersiveenvironmentpicker(content:)) — Add menu items to open immersive spaces from a media player’s environment picker. _(Apple Developer; expand on demand)_

### Handling remote immersive spaces

- [RemoteImmersiveSpace](https://developer.apple.com/documentation/swiftui/remoteimmersivespace) — A scene that presents its content in an unbounded space on a remote device. _(Apple Developer; expand on demand)_
- [RemoteDeviceIdentifier](https://developer.apple.com/documentation/swiftui/remotedeviceidentifier) — An opaque type that identifies a remote device displaying scene content in a RemoteImmersiveSpace. _(Apple Developer; expand on demand)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(local context)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(local context)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(local context)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(local context)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(local context)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(local context)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(local context)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(local context)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/immersive-spaces)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `3b8efdc35a4b9683f2ac73c421fd4d4f45e0c9cbfd728cff3ad183ea16832307`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
