---
title: "Windows"
source_url: "https://developer.apple.com/documentation/swiftui/windows"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Windows"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "189c72e59a3f636e9e49d9efd4a0f3d5ee8043ecf20096dff39f1f895f625780"
source_etag: "W/\"d44b356e54221ce52a2e923c15a596e3\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Windows

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Display user interface content in a window or a collection of windows.

The most common way to present a view hierarchy in your app’s interface is with a WindowGroup, which produces a platform-specific behavior and appearance. On platforms that support it, people can open multiple windows from the group simultaneously. Each window relies on the same root view definition, but retains its own view state. On some platforms, you can also supplement your app’s user interface with a single-instance window using the Window scene type. Configure windows using scene modifiers that you add to the window declaration, like windowStyle(_:) or defaultPosition(_:). You can also indicate how to configure new windows that you present from a view hierarchy by adding the presentedWindowStyle(_:) view modifier to a view in the hierarchy. For design guidance, see Windows in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup) — A scene that presents a group of identically structured windows. _(Apple Developer; expand on demand)_
- [Window](https://developer.apple.com/documentation/swiftui/window) — A scene that presents its content in a single, unique window. _(Apple Developer; expand on demand)_
- [windowStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowstyle(_:)) — Sets the style for windows created by this scene. _(Apple Developer; expand on demand)_
- [defaultPosition(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultposition(_:)) — Sets a default position for a window. _(Apple Developer; expand on demand)_
- [presentedWindowStyle(_:)](https://developer.apple.com/documentation/swiftui/view/presentedwindowstyle(_:)) — Sets the style for windows created by interacting with this view. _(Apple Developer; expand on demand)_
- [Windows](https://developer.apple.com/design/Human-Interface-Guidelines/windows) — A window presents UI views and components in your app or game. _(Apple Developer; expand on demand)_

### Essentials

- [Customizing window styles and state-restoration behavior in macOS](https://developer.apple.com/documentation/swiftui/customizing-window-styles-and-state-restoration-behavior-in-macos) — Configure how your app’s windows look and function in macOS to provide an engaging and more coherent experience. _(Apple Developer; expand on demand)_
- [Bringing multiple windows to your SwiftUI app](https://developer.apple.com/documentation/swiftui/bringing-multiple-windows-to-your-swiftui-app) — Compose rich views by reacting to state changes and customize your app’s scene presentation and behavior on iPadOS and macOS. _(Apple Developer; expand on demand)_

### Creating windows

- [UtilityWindow](https://developer.apple.com/documentation/swiftui/utilitywindow) — A specialized window scene that provides secondary utility to the content of the main scenes of an application. _(Apple Developer; expand on demand)_
- [WindowStyle](https://developer.apple.com/documentation/swiftui/windowstyle) — A specification for the appearance and interaction of a window. _(Apple Developer; expand on demand)_

### Styling the associated toolbar

- [windowToolbarStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarstyle(_:)) — Sets the style for the toolbar defined within this scene. _(Apple Developer; expand on demand)_
- [windowToolbarLabelStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarlabelstyle(_:)) — Sets the label style of items in a toolbar and enables user customization. _(Apple Developer; expand on demand)_
- [windowToolbarLabelStyle(fixed:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarlabelstyle(fixed:)) — Sets the label style of items in a toolbar. _(Apple Developer; expand on demand)_
- [WindowToolbarStyle](https://developer.apple.com/documentation/swiftui/windowtoolbarstyle) — A specification for the appearance and behavior of a window’s toolbar. _(Apple Developer; expand on demand)_

### Opening windows

- [Presenting windows and spaces](https://developer.apple.com/documentation/visionOS/presenting-windows-and-spaces) — Open and close the scenes that make up your app’s interface. _(Apple Developer; expand on demand)_
- [supportsMultipleWindows](https://developer.apple.com/documentation/swiftui/environmentvalues/supportsmultiplewindows) — A Boolean value that indicates whether the current platform supports opening multiple windows. _(Apple Developer; expand on demand)_
- [openWindow](https://developer.apple.com/documentation/swiftui/environmentvalues/openwindow) — A window presentation action stored in a view’s environment. _(Apple Developer; expand on demand)_
- [OpenWindowAction](https://developer.apple.com/documentation/swiftui/openwindowaction) — An action that presents a window. _(Apple Developer; expand on demand)_
- [PushWindowAction](https://developer.apple.com/documentation/swiftui/pushwindowaction) — An action that opens the requested window in place of the window the action is called from. _(Apple Developer; expand on demand)_

### Closing windows

- [dismissWindow](https://developer.apple.com/documentation/swiftui/environmentvalues/dismisswindow) — A window dismissal action stored in a view’s environment. _(Apple Developer; expand on demand)_
- [DismissWindowAction](https://developer.apple.com/documentation/swiftui/dismisswindowaction) — An action that dismisses a window associated to a particular scene. _(Apple Developer; expand on demand)_
- [dismiss](https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss) — An action that dismisses the current presentation. _(Apple Developer; expand on demand)_
- [DismissAction](https://developer.apple.com/documentation/swiftui/dismissaction) — An action that dismisses a presentation. _(Apple Developer; expand on demand)_
- [DismissBehavior](https://developer.apple.com/documentation/swiftui/dismissbehavior) — Programmatic window dismissal behaviors. _(Apple Developer; expand on demand)_

### Sizing a window

- [Positioning and sizing windows](https://developer.apple.com/documentation/visionOS/positioning-and-sizing-windows) — Influence the initial geometry of windows that your app presents. _(Apple Developer; expand on demand)_
- [defaultSize(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultsize(_:)) — Sets a default size for a window. _(Apple Developer; expand on demand)_
- [defaultSize(width:height:)](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:)) — Sets a default width and height for a window. _(Apple Developer; expand on demand)_
- [defaultSize(width:height:depth:)](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:depth:)) — Sets a default size for a volumetric window. _(Apple Developer; expand on demand)_
- [defaultSize(_:in:)](https://developer.apple.com/documentation/swiftui/scene/defaultsize(_:in:)) — Sets a default size for a volumetric window. _(Apple Developer; expand on demand)_
- [defaultSize(width:height:depth:in:)](https://developer.apple.com/documentation/swiftui/scene/defaultsize(width:height:depth:in:)) — Sets a default size for a volumetric window. _(Apple Developer; expand on demand)_
- [windowResizability(_:)](https://developer.apple.com/documentation/swiftui/scene/windowresizability(_:)) — Sets the kind of resizability to use for a window. _(Apple Developer; expand on demand)_
- [WindowResizability](https://developer.apple.com/documentation/swiftui/windowresizability) — The resizability of a window. _(Apple Developer; expand on demand)_
- [windowIdealSize(_:)](https://developer.apple.com/documentation/swiftui/scene/windowidealsize(_:)) — Specifies how windows derived form this scene should determine their size when zooming. _(Apple Developer; expand on demand)_
- [WindowIdealSize](https://developer.apple.com/documentation/swiftui/windowidealsize) — A type which defines the size a window should use when zooming. _(Apple Developer; expand on demand)_

### Positioning a window

- [WindowLevel](https://developer.apple.com/documentation/swiftui/windowlevel) — The level of a window. _(Apple Developer; expand on demand)_
- [windowLevel(_:)](https://developer.apple.com/documentation/swiftui/scene/windowlevel(_:)) — Sets the window level of this scene. _(Apple Developer; expand on demand)_
- [WindowLayoutRoot](https://developer.apple.com/documentation/swiftui/windowlayoutroot) — A proxy which represents the root contents of a window. _(Apple Developer; expand on demand)_
- [WindowPlacement](https://developer.apple.com/documentation/swiftui/windowplacement) — A type which represents a preferred size and position for a window. _(Apple Developer; expand on demand)_
- [defaultWindowPlacement(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultwindowplacement(_:)) — Defines a function used for determining the default placement of windows. _(Apple Developer; expand on demand)_
- [windowIdealPlacement(_:)](https://developer.apple.com/documentation/swiftui/scene/windowidealplacement(_:)) — Provides a function which determines a placement to use when windows of a scene zoom. _(Apple Developer; expand on demand)_
- [WindowPlacementContext](https://developer.apple.com/documentation/swiftui/windowplacementcontext) — A type which represents contextual information used for sizing and positioning windows. _(Apple Developer; expand on demand)_
- [WindowProxy](https://developer.apple.com/documentation/swiftui/windowproxy) — The proxy for an open window in the app. _(Apple Developer; expand on demand)_
- [DisplayProxy](https://developer.apple.com/documentation/swiftui/displayproxy) — A type which provides information about display hardware. _(Apple Developer; expand on demand)_

### Configuring window visibility

- [WindowVisibilityToggle](https://developer.apple.com/documentation/swiftui/windowvisibilitytoggle) — A specialized button for toggling the visibility of a window. _(Apple Developer; expand on demand)_
- [defaultLaunchBehavior(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultlaunchbehavior(_:)) — Sets the default launch behavior for this scene. _(Apple Developer; expand on demand)_
- [restorationBehavior(_:)](https://developer.apple.com/documentation/swiftui/scene/restorationbehavior(_:)) — Sets the restoration behavior for this scene. _(Apple Developer; expand on demand)_
- [SceneLaunchBehavior](https://developer.apple.com/documentation/swiftui/scenelaunchbehavior) — The launch behavior for a scene. _(Apple Developer; expand on demand)_
- [SceneRestorationBehavior](https://developer.apple.com/documentation/swiftui/scenerestorationbehavior) — The restoration behavior for a scene. _(Apple Developer; expand on demand)_
- [persistentSystemOverlays(_:)](https://developer.apple.com/documentation/swiftui/scene/persistentsystemoverlays(_:)) — Sets the preferred visibility of the non-transient system views overlaying the app. _(Apple Developer; expand on demand)_
- [windowToolbarFullScreenVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/windowtoolbarfullscreenvisibility(_:)) — Configures the visibility of the window toolbar when the window enters full screen mode. _(Apple Developer; expand on demand)_
- [WindowToolbarFullScreenVisibility](https://developer.apple.com/documentation/swiftui/windowtoolbarfullscreenvisibility) — The visibility of the window toolbar with respect to full screen mode. _(Apple Developer; expand on demand)_

### Managing window behavior

- [WindowManagerRole](https://developer.apple.com/documentation/swiftui/windowmanagerrole) — Options for defining how a scene’s windows behave when used within a managed window context, such as full screen mode and Stage Manager. _(Apple Developer; expand on demand)_
- [windowManagerRole(_:)](https://developer.apple.com/documentation/swiftui/scene/windowmanagerrole(_:)) — Configures the role for windows derived from when participating in a managed window context, such as full screen or Stage Manager. _(Apple Developer; expand on demand)_
- [WindowInteractionBehavior](https://developer.apple.com/documentation/swiftui/windowinteractionbehavior) — Options for enabling and disabling window interaction behaviors. _(Apple Developer; expand on demand)_
- [windowDismissBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/windowdismissbehavior(_:)) — Configures the dismiss functionality for the window enclosing . _(Apple Developer; expand on demand)_
- [windowFullScreenBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/windowfullscreenbehavior(_:)) — Configures the full screen functionality for the window enclosing . _(Apple Developer; expand on demand)_
- [windowMinimizeBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/windowminimizebehavior(_:)) — Configures the minimize functionality for the window enclosing . _(Apple Developer; expand on demand)_
- [windowResizeBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/windowresizebehavior(_:)) — Configures the resize functionality for the window enclosing . _(Apple Developer; expand on demand)_
- [windowBackgroundDragBehavior(_:)](https://developer.apple.com/documentation/swiftui/scene/windowbackgrounddragbehavior(_:)) — Configures the behavior of dragging a window by its background. _(Apple Developer; expand on demand)_
- [allowsWindowActivationEvents()](https://developer.apple.com/documentation/swiftui/view/allowswindowactivationevents()) — Configures gestures in this view hierarchy to handle events that activate the containing window. _(Apple Developer; expand on demand)_
- [allowsWindowActivationEvents(_:)](https://developer.apple.com/documentation/swiftui/view/allowswindowactivationevents(_:)) — Configures whether gestures in this view hierarchy can handle events that activate the containing window. _(Apple Developer; expand on demand)_

### Interacting with volumes

- [onVolumeViewpointChange(updateStrategy:initial:_:)](https://developer.apple.com/documentation/swiftui/view/onvolumeviewpointchange(updatestrategy:initial:_:)) — Adds an action to perform when the viewpoint of the volume changes. _(Apple Developer; expand on demand)_
- [supportedVolumeViewpoints(_:)](https://developer.apple.com/documentation/swiftui/view/supportedvolumeviewpoints(_:)) — Specifies which viewpoints are supported for the window bar and ornaments in a volume. _(Apple Developer; expand on demand)_
- [VolumeViewpointUpdateStrategy](https://developer.apple.com/documentation/swiftui/volumeviewpointupdatestrategy) — A type describing when the action provided to onVolumeViewpointChange(updateStrategy:initial:_:) should be called. _(Apple Developer; expand on demand)_
- [Viewpoint3D](https://developer.apple.com/documentation/swiftui/viewpoint3d) — A type describing what direction something is being viewed from. _(Apple Developer; expand on demand)_
- [SquareAzimuth](https://developer.apple.com/documentation/swiftui/squareazimuth) — A type describing what direction something is being viewed from along the horizontal plane and snapped to 4 directions. _(Apple Developer; expand on demand)_
- [WorldAlignmentBehavior](https://developer.apple.com/documentation/swiftui/worldalignmentbehavior) — A type representing the world alignment behavior for a scene. _(Apple Developer; expand on demand)_
- [volumeWorldAlignment(_:)](https://developer.apple.com/documentation/swiftui/scene/volumeworldalignment(_:)) — Specifies how a volume should be aligned when moved in the world. _(Apple Developer; expand on demand)_
- [WorldScalingBehavior](https://developer.apple.com/documentation/swiftui/worldscalingbehavior) — Specifies the scaling behavior a window should have within the world. _(Apple Developer; expand on demand)_
- [defaultWorldScaling(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultworldscaling(_:)) — Specify the world scaling behavior for the window. _(Apple Developer; expand on demand)_
- [WorldScalingCompensation](https://developer.apple.com/documentation/swiftui/worldscalingcompensation) — Indicates whether returned metrics will take dynamic scaling into account. _(Apple Developer; expand on demand)_
- [worldTrackingLimitations](https://developer.apple.com/documentation/swiftui/environmentvalues/worldtrackinglimitations) — The current limitations of the device tracking the user’s surroundings. _(Apple Developer; expand on demand)_
- [WorldTrackingLimitation](https://developer.apple.com/documentation/swiftui/worldtrackinglimitation) — A structure to represent limitations of tracking the user’s surroundings. _(Apple Developer; expand on demand)_
- [SurfaceSnappingInfo](https://developer.apple.com/documentation/swiftui/surfacesnappinginfo) — A type representing information about the window scenes snap state. _(Apple Developer; expand on demand)_

### Deprecated Types

- [ControlActiveState](https://developer.apple.com/documentation/swiftui/controlactivestate) — The active appearance expected of controls in a window. _(Apple Developer; expand on demand)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(local context)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(local context)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(local context)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(local context)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(local context)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(local context)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(local context)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(local context)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/windows)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `189c72e59a3f636e9e49d9efd4a0f3d5ee8043ecf20096dff39f1f895f625780`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
