---
title: "Input events"
source_url: "https://developer.apple.com/documentation/swiftui/input-events"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Input-events"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "a1c2c249312c4bda53f9b311b6faa8d6e1ff477f2941f24ab893ac650462cf75"
source_etag: "W/\"98863f1cc867d630c51095da2c9da046\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Input events

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Respond to input from a hardware device, like a keyboard or a Touch Bar.

SwiftUI provides view modifiers that enable your app to listen for and react to various kinds of user input. For example, you can create keyboard shortcuts, respond to a form submission, or take input from the digital crown of an Apple Watch. For design guidance, see Inputs in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Inputs](https://developer.apple.com/design/Human-Interface-Guidelines/inputs) — Learn about the various methods people use to control your app or game and enter data. _(Apple Developer; expand on demand)_

### Responding to keyboard input

- [onKeyPress(_:action:)](https://developer.apple.com/documentation/swiftui/view/onkeypress(_:action:)) — Performs an action if the user presses a key on a hardware keyboard while the view has focus. _(Apple Developer; expand on demand)_
- [onKeyPress(phases:action:)](https://developer.apple.com/documentation/swiftui/view/onkeypress(phases:action:)) — Performs an action if the user presses any key on a hardware keyboard while the view has focus. _(Apple Developer; expand on demand)_
- [onKeyPress(_:phases:action:)](https://developer.apple.com/documentation/swiftui/view/onkeypress(_:phases:action:)) — Performs an action if the user presses a key on a hardware keyboard while the view has focus. _(Apple Developer; expand on demand)_
- [onKeyPress(characters:phases:action:)](https://developer.apple.com/documentation/swiftui/view/onkeypress(characters:phases:action:)) — Performs an action if the user presses one or more keys on a hardware keyboard while the view has focus. _(Apple Developer; expand on demand)_
- [onKeyPress(keys:phases:action:)](https://developer.apple.com/documentation/swiftui/view/onkeypress(keys:phases:action:)) — Performs an action if the user presses one or more keys on a hardware keyboard while the view has focus. _(Apple Developer; expand on demand)_
- [KeyPress](https://developer.apple.com/documentation/swiftui/keypress) — _Apple Developer; expand on demand_

### Creating keyboard shortcuts

- [keyboardShortcut(_:)](https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:)) — Assigns a keyboard shortcut to the modified control. _(Apple Developer; expand on demand)_
- [keyboardShortcut(_:modifiers:)](https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:modifiers:)) — Defines a keyboard shortcut and assigns it to the modified control. _(Apple Developer; expand on demand)_
- [keyboardShortcut(_:modifiers:localization:)](https://developer.apple.com/documentation/swiftui/view/keyboardshortcut(_:modifiers:localization:)) — Defines a keyboard shortcut and assigns it to the modified control. _(Apple Developer; expand on demand)_
- [keyboardShortcut](https://developer.apple.com/documentation/swiftui/environmentvalues/keyboardshortcut) — The keyboard shortcut that buttons in this environment will be triggered with. _(Apple Developer; expand on demand)_
- [KeyboardShortcut](https://developer.apple.com/documentation/swiftui/keyboardshortcut) — Keyboard shortcuts describe combinations of keys on a keyboard that the user can press in order to activate a button or toggle. _(Apple Developer; expand on demand)_
- [KeyEquivalent](https://developer.apple.com/documentation/swiftui/keyequivalent) — Key equivalents consist of a letter, punctuation, or function key that can be combined with an optional set of modifier keys to specify a… _(Apple Developer; expand on demand)_
- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers) — A set of key modifiers that you can add to a gesture. _(Apple Developer; expand on demand)_

### Responding to modifier keys

- [onModifierKeysChanged(mask:initial:_:)](swiftui-onmodifierkeyschanged.md) — Performs an action whenever the user presses or releases a hardware modifier key. _(local context)_
- [modifierKeyAlternate(_:_:)](swiftui-modifier-key-alternate.md) — Builds a view to use in place of the modified view when the user presses the modifier key(s) indicated by the given set. _(local context)_

### Responding to hover events

- [onHover(perform:)](https://developer.apple.com/documentation/swiftui/view/onhover(perform:)) — Adds an action to perform when the user moves the pointer over or away from the view’s frame. _(Apple Developer; expand on demand)_
- [onContinuousHover(coordinateSpace:perform:)](https://developer.apple.com/documentation/swiftui/view/oncontinuoushover(coordinatespace:perform:)) — Adds an action to perform when the pointer enters, moves within, and exits the view’s bounds. _(Apple Developer; expand on demand)_
- [hoverEffect(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/hovereffect(_:isenabled:)) — Applies a hover effect to this view. _(Apple Developer; expand on demand)_
- [hoverEffectDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/hovereffectdisabled(_:)) — Adds a condition that controls whether this view can display hover effects. _(Apple Developer; expand on demand)_
- [defaultHoverEffect(_:)](https://developer.apple.com/documentation/swiftui/view/defaulthovereffect(_:)) — Sets the default hover effect to use for views within this view. _(Apple Developer; expand on demand)_
- [isHoverEffectEnabled](https://developer.apple.com/documentation/swiftui/environmentvalues/ishovereffectenabled) — A Boolean value that indicates whether the view associated with this environment allows hover effects to be displayed. _(Apple Developer; expand on demand)_
- [HoverPhase](https://developer.apple.com/documentation/swiftui/hoverphase) — The current hovering state and value of the pointer. _(Apple Developer; expand on demand)_
- [HoverEffectPhaseOverride](https://developer.apple.com/documentation/swiftui/hovereffectphaseoverride) — Options for overriding a hover effect’s current phase. _(Apple Developer; expand on demand)_
- [OrnamentHoverContentEffect](https://developer.apple.com/documentation/swiftui/ornamenthovercontenteffect) — Presents an ornament on hover using a custom effect. _(Apple Developer; expand on demand)_
- [OrnamentHoverEffect](https://developer.apple.com/documentation/swiftui/ornamenthovereffect) — Presents an ornament on hover. _(Apple Developer; expand on demand)_

### Modifying pointer appearance

- [pointerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/pointerstyle(_:)) — Sets the pointer style to display when the pointer is over the view. _(Apple Developer; expand on demand)_
- [PointerStyle](https://developer.apple.com/documentation/swiftui/pointerstyle) — A style describing the appearance of the pointer (also called a cursor) when it’s hovered over a view. _(Apple Developer; expand on demand)_
- [pointerVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/pointervisibility(_:)) — Sets the visibility of the pointer when it’s over the view. _(Apple Developer; expand on demand)_

### Changing view appearance for hover events

- [hoverEffect(_:)](https://developer.apple.com/documentation/swiftui/view/hovereffect(_:)) — Applies a hover effect to this view. _(Apple Developer; expand on demand)_
- [HoverEffect](https://developer.apple.com/documentation/swiftui/hovereffect) — An effect applied when the pointer hovers over a view. _(Apple Developer; expand on demand)_
- [hoverEffect(_:in:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/hovereffect(_:in:isenabled:)) — Applies a hover effect to this view, optionally adding it to a HoverEffectGroup. _(Apple Developer; expand on demand)_
- [hoverEffect(in:isEnabled:body:)](https://developer.apple.com/documentation/swiftui/view/hovereffect(in:isenabled:body:)) — Applies a hover effect to this view described by the given closure. _(Apple Developer; expand on demand)_
- [CustomHoverEffect](https://developer.apple.com/documentation/swiftui/customhovereffect) — A type that represents how a view should change when a pointer hovers over a view, or when someone looks at the view. _(Apple Developer; expand on demand)_
- [ContentHoverEffect](https://developer.apple.com/documentation/swiftui/contenthovereffect) — A that applies effects to a view on hover using a closure. _(Apple Developer; expand on demand)_
- [HoverEffectGroup](https://developer.apple.com/documentation/swiftui/hovereffectgroup) — Describes a grouping of effects that activate together. _(Apple Developer; expand on demand)_
- [hoverEffectGroup()](https://developer.apple.com/documentation/swiftui/view/hovereffectgroup()) — Adds an implicit HoverEffectGroup to all effects defined on descendant views, so that all effects added to subviews activate as a group whenever this… _(Apple Developer; expand on demand)_
- [hoverEffectGroup(_:)](https://developer.apple.com/documentation/swiftui/view/hovereffectgroup(_:)) — Adds a HoverEffectGroup to all effects defined on descendant views, and activates the group whenever this view or any descendant views are hovered. _(Apple Developer; expand on demand)_
- [hoverEffectGroup(id:in:behavior:)](https://developer.apple.com/documentation/swiftui/view/hovereffectgroup(id:in:behavior:)) — Adds a HoverEffectGroup to all effects defined on descendant views, and activates the group whenever this view or any descendant views are hovered. _(Apple Developer; expand on demand)_
- [GroupHoverEffect](https://developer.apple.com/documentation/swiftui/grouphovereffect) — A that activates a named group of effects. _(Apple Developer; expand on demand)_
- [HoverEffectContent](https://developer.apple.com/documentation/swiftui/hovereffectcontent) — A type that describes the effects of a view for a particular hover effect phase. _(Apple Developer; expand on demand)_
- [EmptyHoverEffectContent](https://developer.apple.com/documentation/swiftui/emptyhovereffectcontent) — An empty base effect that you use to build other effects. _(Apple Developer; expand on demand)_
- [handPointerBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/handpointerbehavior(_:)) — Sets the behavior of the hand pointer while the user is interacting with the view. _(Apple Developer; expand on demand)_
- [HandPointerBehavior](https://developer.apple.com/documentation/swiftui/handpointerbehavior) — A behavior that can be applied to the hand pointer while the user is interacting with a view. _(Apple Developer; expand on demand)_

### Responding to submission events

- [onSubmit(of:_:)](https://developer.apple.com/documentation/swiftui/view/onsubmit(of:_:)) — Adds an action to perform when the user submits a value to this view. _(Apple Developer; expand on demand)_
- [submitScope(_:)](https://developer.apple.com/documentation/swiftui/view/submitscope(_:)) — Prevents submission triggers originating from this view to invoke a submission action configured by a submission modifier higher up in the view hierarchy. _(Apple Developer; expand on demand)_
- [SubmitTriggers](https://developer.apple.com/documentation/swiftui/submittriggers) — A type that defines various triggers that result in the firing of a submission action. _(Apple Developer; expand on demand)_

### Labeling a submission event

- [submitLabel(_:)](https://developer.apple.com/documentation/swiftui/view/submitlabel(_:)) — Sets the submit label for this view. _(Apple Developer; expand on demand)_
- [SubmitLabel](https://developer.apple.com/documentation/swiftui/submitlabel) — A semantic label describing the label of submission within a view hierarchy. _(Apple Developer; expand on demand)_

### Responding to commands

- [onMoveCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/onmovecommand(perform:)) — Adds an action to perform in response to a move command, like when the user presses an arrow key on a Mac keyboard, or… _(Apple Developer; expand on demand)_
- [onDeleteCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/ondeletecommand(perform:)) — Adds an action to perform in response to the system’s Delete command, or pressing either the ⌫ (backspace) or ⌦ (forward delete) keys while… _(Apple Developer; expand on demand)_
- [pageCommand(value:in:step:)](https://developer.apple.com/documentation/swiftui/view/pagecommand(value:in:step:)) — Steps a value through a range in response to page up or page down commands. _(Apple Developer; expand on demand)_
- [onExitCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/onexitcommand(perform:)) — Sets up an action that triggers in response to receiving the exit command while the view has focus. _(Apple Developer; expand on demand)_
- [onPlayPauseCommand(perform:)](https://developer.apple.com/documentation/swiftui/view/onplaypausecommand(perform:)) — Adds an action to perform in response to the system’s Play/Pause command. _(Apple Developer; expand on demand)_
- [onCommand(_:perform:)](https://developer.apple.com/documentation/swiftui/view/oncommand(_:perform:)) — Adds an action to perform in response to the given selector. _(Apple Developer; expand on demand)_
- [MoveCommandDirection](https://developer.apple.com/documentation/swiftui/movecommanddirection) — Specifies the direction of an arrow key movement. _(Apple Developer; expand on demand)_

### Controlling hit testing

- [allowsTightening(_:)](https://developer.apple.com/documentation/swiftui/view/allowstightening(_:)) — Sets whether text in this view can compress the space between characters when necessary to fit text in a line. _(Apple Developer; expand on demand)_
- [contentShape(_:eoFill:)](https://developer.apple.com/documentation/swiftui/view/contentshape(_:eofill:)) — Defines the content shape for hit testing. _(Apple Developer; expand on demand)_
- [contentShape(_:_:eoFill:)](https://developer.apple.com/documentation/swiftui/view/contentshape(_:_:eofill:)) — Sets the content shape for this view. _(Apple Developer; expand on demand)_
- [ContentShapeKinds](https://developer.apple.com/documentation/swiftui/contentshapekinds) — A kind for the content shape of a view. _(Apple Developer; expand on demand)_

### Interacting with the Digital Crown

- [digitalCrownAccessory(_:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownaccessory(_:)) — Specifies the visibility of Digital Crown accessory Views on Apple Watch. _(Apple Developer; expand on demand)_
- [digitalCrownAccessory(content:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownaccessory(content:)) — Places an accessory View next to the Digital Crown on Apple Watch. _(Apple Developer; expand on demand)_
- [digitalCrownRotation(_:from:through:sensitivity:isContinuous:isHapticFeedbackEnabled:onChange:onIdle:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownrotation(_:from:through:sensitivity:iscontinuous:ishapticfeedbackenabled:onchange:onidle:)) — Tracks Digital Crown rotations by updating the specified binding. _(Apple Developer; expand on demand)_
- [digitalCrownRotation(_:onChange:onIdle:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownrotation(_:onchange:onidle:)) — Tracks Digital Crown rotations by updating the specified binding. _(Apple Developer; expand on demand)_
- [digitalCrownRotation(detent:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:onChange:onIdle:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownrotation(detent:from:through:by:sensitivity:iscontinuous:ishapticfeedbackenabled:onchange:onidle:)) — Tracks Digital Crown rotations by updating the specified binding. _(Apple Developer; expand on demand)_
- [digitalCrownRotation(_:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownrotation(_:)) — Tracks Digital Crown rotations by updating the specified binding. _(Apple Developer; expand on demand)_
- [digitalCrownRotation(_:from:through:by:sensitivity:isContinuous:isHapticFeedbackEnabled:)](https://developer.apple.com/documentation/swiftui/view/digitalcrownrotation(_:from:through:by:sensitivity:iscontinuous:ishapticfeedbackenabled:)) — Tracks Digital Crown rotations by updating the specified binding. _(Apple Developer; expand on demand)_
- [DigitalCrownEvent](https://developer.apple.com/documentation/swiftui/digitalcrownevent) — An event emitted when the user rotates the Digital Crown. _(Apple Developer; expand on demand)_
- [DigitalCrownRotationalSensitivity](https://developer.apple.com/documentation/swiftui/digitalcrownrotationalsensitivity) — The amount of Digital Crown rotation needed to move between two integer numbers. _(Apple Developer; expand on demand)_

### Managing Touch Bar input

- [touchBar(content:)](https://developer.apple.com/documentation/swiftui/view/touchbar(content:)) — Sets the content that the Touch Bar displays. _(Apple Developer; expand on demand)_
- [touchBar(_:)](https://developer.apple.com/documentation/swiftui/view/touchbar(_:)) — Sets the Touch Bar content to be shown in the Touch Bar when applicable. _(Apple Developer; expand on demand)_
- [touchBarItemPrincipal(_:)](https://developer.apple.com/documentation/swiftui/view/touchbaritemprincipal(_:)) — Sets principal views that have special significance to this Touch Bar. _(Apple Developer; expand on demand)_
- [touchBarCustomizationLabel(_:)](https://developer.apple.com/documentation/swiftui/view/touchbarcustomizationlabel(_:)) — Sets a user-visible string that identifies the view’s functionality. _(Apple Developer; expand on demand)_
- [touchBarItemPresence(_:)](https://developer.apple.com/documentation/swiftui/view/touchbaritempresence(_:)) — Sets the behavior of the user-customized view. _(Apple Developer; expand on demand)_
- [TouchBar](https://developer.apple.com/documentation/swiftui/touchbar) — A container for a view that you can show in the Touch Bar. _(Apple Developer; expand on demand)_
- [TouchBarItemPresence](https://developer.apple.com/documentation/swiftui/touchbaritempresence) — Options that affect user customization of the Touch Bar. _(Apple Developer; expand on demand)_

### Responding to capture events

- [onCameraCaptureEvent(isEnabled:action:)](https://developer.apple.com/documentation/swiftui/view/oncameracaptureevent(isenabled:action:)) — Used to register an action triggered by system capture events. _(Apple Developer; expand on demand)_
- [onCameraCaptureEvent(isEnabled:primaryAction:secondaryAction:)](https://developer.apple.com/documentation/swiftui/view/oncameracaptureevent(isenabled:primaryaction:secondaryaction:)) — Used to register actions triggered by system capture events. _(Apple Developer; expand on demand)_

### Event handling

- [Gestures](swiftui-gestures.md) — Define interactions from taps, clicks, and swipes to fine-grained gestures. _(local context)_
- [Clipboard](swiftui-clipboard.md) — Enable people to move or duplicate items by issuing Copy and Paste commands. _(local context)_
- [Drag and drop](swiftui-drag-and-drop.md) — Enable people to move or duplicate items by dragging them from one location to another. _(local context)_
- [Focus](swiftui-focus.md) — Identify and control which visible object responds to user interaction. _(local context)_
- [System events](swiftui-system-events.md) — React to system events, like opening a URL. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/input-events)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `a1c2c249312c4bda53f9b311b6faa8d6e1ff477f2941f24ab893ac650462cf75`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
