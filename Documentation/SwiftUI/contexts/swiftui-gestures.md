---
title: "Gestures"
source_url: "https://developer.apple.com/documentation/swiftui/gestures"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Gestures"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "13b04edc1622ce2978db04e708cfcb2a2beb01658d1b77813450e64428488ef7"
source_etag: "W/\"a86bdb207693f9d0af719c38a336a15b\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Gestures

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Define interactions from taps, clicks, and swipes to fine-grained gestures.

Respond to gestures by adding gesture modifiers to your views. You can listen for taps, drags, pinches, and other standard gestures. You can also compose custom gestures from individual gestures using the simultaneously(with:), sequenced(before:), or exclusively(before:) modifiers, or combine gestures with keyboard modifiers using the modifiers(_:) modifier. When you need a button, use a Button instance rather than a tap gesture. You can use any view as the button’s label, and the button type automatically provides many of the standard behaviors that users expect from a button, like accessibility labels and hints. For design guidance, see Gestures in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [simultaneously(with:)](https://developer.apple.com/documentation/swiftui/gesture/simultaneously(with:)) — Combines a gesture with another gesture to create a new gesture that recognizes both gestures at the same time. _(Apple Developer; expand on demand)_
- [sequenced(before:)](https://developer.apple.com/documentation/swiftui/gesture/sequenced(before:)) — Sequences a gesture with another one to create a new gesture, which results in the second gesture only receiving events after the first gesture… _(Apple Developer; expand on demand)_
- [exclusively(before:)](https://developer.apple.com/documentation/swiftui/gesture/exclusively(before:)) — Combines two gestures exclusively to create a new gesture where only one gesture succeeds, giving precedence to the first gesture. _(Apple Developer; expand on demand)_
- [modifiers(_:)](https://developer.apple.com/documentation/swiftui/gesture/modifiers(_:)) — Combines a gesture with keyboard modifiers. _(Apple Developer; expand on demand)_
- [Button](https://developer.apple.com/documentation/swiftui/button) — A control that initiates an action. _(Apple Developer; expand on demand)_
- [Gestures](https://developer.apple.com/design/Human-Interface-Guidelines/gestures) — A gesture is a physical motion that a person uses to directly affect an object in an app or game on their device. _(Apple Developer; expand on demand)_

### Essentials

- [Adding interactivity with gestures](https://developer.apple.com/documentation/swiftui/adding-interactivity-with-gestures) — Use gesture modifiers to add interactivity to your app. _(Apple Developer; expand on demand)_

### Recognizing tap gestures

- [onTapGesture(count:perform:)](https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:perform:)) — Adds an action to perform when this view recognizes a tap gesture. _(Apple Developer; expand on demand)_
- [onTapGesture(count:coordinateSpace:perform:)](https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:coordinatespace:perform:)) — Adds an action to perform when this view recognizes a tap gesture, and provides the action with the location of the interaction. _(Apple Developer; expand on demand)_
- [onTapGesture(count:coordinateSpace:inputKinds:perform:)](https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:coordinatespace:inputkinds:perform:)) — Adds an action to perform when this view recognizes a tap gesture, and provides the action with the location of the interaction. _(Apple Developer; expand on demand)_
- [TapGesture](https://developer.apple.com/documentation/swiftui/tapgesture) — A gesture that recognizes one or more taps. _(Apple Developer; expand on demand)_
- [SpatialTapGesture](https://developer.apple.com/documentation/swiftui/spatialtapgesture) — A gesture that recognizes one or more taps and reports their location. _(Apple Developer; expand on demand)_

### Recognizing long-press gestures

- [onLongPressGesture(minimumDuration:maximumDistance:perform:onPressingChanged:)](https://developer.apple.com/documentation/swiftui/view/onlongpressgesture(minimumduration:maximumdistance:perform:onpressingchanged:)) — Adds an action to perform when this view recognizes a long press gesture. _(Apple Developer; expand on demand)_
- [onLongPressGesture(minimumDuration:maximumDistance:inputKinds:perform:onPressingChanged:)](https://developer.apple.com/documentation/swiftui/view/onlongpressgesture(minimumduration:maximumdistance:inputkinds:perform:onpressingchanged:)) — Adds an action to perform when this view recognizes a long press gesture. _(Apple Developer; expand on demand)_
- [onLongPressGesture(minimumDuration:perform:onPressingChanged:)](https://developer.apple.com/documentation/swiftui/view/onlongpressgesture(minimumduration:perform:onpressingchanged:)) — Adds an action to perform when this view recognizes a long press gesture. _(Apple Developer; expand on demand)_
- [onLongTouchGesture(minimumDuration:perform:onTouchingChanged:)](https://developer.apple.com/documentation/swiftui/view/onlongtouchgesture(minimumduration:perform:ontouchingchanged:)) — Adds an action to perform when this view recognizes a remote long touch gesture. A long touch gesture is when the finger is on… _(Apple Developer; expand on demand)_
- [LongPressGesture](https://developer.apple.com/documentation/swiftui/longpressgesture) — A gesture that succeeds when the user performs a long press. _(Apple Developer; expand on demand)_

### Recognizing spatial events

- [SpatialEventGesture](https://developer.apple.com/documentation/swiftui/spatialeventgesture) — A gesture that provides information about ongoing spatial events like clicks and touches. _(Apple Developer; expand on demand)_
- [SpatialEventCollection](https://developer.apple.com/documentation/swiftui/spatialeventcollection) — A collection of spatial input events that target a specific view. _(Apple Developer; expand on demand)_
- [Chirality](https://developer.apple.com/documentation/swiftui/chirality) — The chirality, or handedness, of a pose. _(Apple Developer; expand on demand)_

### Recognizing gestures that change over time

- [gesture(_:)](https://developer.apple.com/documentation/swiftui/view/gesture(_:)) — Attaches an NSGestureRecognizerRepresentable to the view. _(Apple Developer; expand on demand)_
- [gesture(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/gesture(_:isenabled:)) — Attaches a gesture to the view with a lower precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [gesture(_:name:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/gesture(_:name:isenabled:)) — Attaches a gesture to the view with a lower precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [gesture(_:including:)](https://developer.apple.com/documentation/swiftui/view/gesture(_:including:)) — Attaches a gesture to the view with a lower precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [DragGesture](https://developer.apple.com/documentation/swiftui/draggesture) — A dragging motion that invokes an action as the drag-event sequence changes. _(Apple Developer; expand on demand)_
- [WindowDragGesture](https://developer.apple.com/documentation/swiftui/windowdraggesture) — A gesture that recognizes the motion of and handles dragging a window. _(Apple Developer; expand on demand)_
- [MagnifyGesture](https://developer.apple.com/documentation/swiftui/magnifygesture) — A gesture that recognizes a magnification motion and tracks the amount of magnification. _(Apple Developer; expand on demand)_
- [RotateGesture](https://developer.apple.com/documentation/swiftui/rotategesture) — A gesture that recognizes a rotation motion and tracks the angle of the rotation. _(Apple Developer; expand on demand)_
- [RotateGesture3D](https://developer.apple.com/documentation/swiftui/rotategesture3d) — A gesture that recognizes 3D rotation motion and tracks the angle and axis of the rotation. _(Apple Developer; expand on demand)_
- [GestureMask](https://developer.apple.com/documentation/swiftui/gesturemask) — Options that control how adding a gesture to a view affects other gestures recognized by the view and its subviews. _(Apple Developer; expand on demand)_

### Recognizing Apple Pencil gestures

- [onPencilDoubleTap(perform:)](https://developer.apple.com/documentation/swiftui/view/onpencildoubletap(perform:)) — Adds an action to perform after the user double-taps their Apple Pencil. _(Apple Developer; expand on demand)_
- [onPencilSqueeze(perform:)](https://developer.apple.com/documentation/swiftui/view/onpencilsqueeze(perform:)) — Adds an action to perform when the user squeezes their Apple Pencil. _(Apple Developer; expand on demand)_
- [preferredPencilDoubleTapAction](https://developer.apple.com/documentation/swiftui/environmentvalues/preferredpencildoubletapaction) — The action that the user prefers to perform after double-tapping their Apple Pencil, as selected in the Settings app. _(Apple Developer; expand on demand)_
- [preferredPencilSqueezeAction](https://developer.apple.com/documentation/swiftui/environmentvalues/preferredpencilsqueezeaction) — The action that the user prefers to perform when squeezing their Apple Pencil, as selected in the Settings app. _(Apple Developer; expand on demand)_
- [PencilPreferredAction](https://developer.apple.com/documentation/swiftui/pencilpreferredaction) — An action that the user prefers to perform after double-tapping their Apple Pencil. _(Apple Developer; expand on demand)_
- [PencilDoubleTapGestureValue](https://developer.apple.com/documentation/swiftui/pencildoubletapgesturevalue) — Describes the value of an Apple Pencil double-tap gesture. _(Apple Developer; expand on demand)_
- [PencilSqueezeGestureValue](https://developer.apple.com/documentation/swiftui/pencilsqueezegesturevalue) — Describes the value of an Apple Pencil squeeze gesture. _(Apple Developer; expand on demand)_
- [PencilSqueezeGesturePhase](https://developer.apple.com/documentation/swiftui/pencilsqueezegesturephase) — Describes the phase and value of an Apple Pencil squeeze gesture. _(Apple Developer; expand on demand)_
- [PencilHoverPose](https://developer.apple.com/documentation/swiftui/pencilhoverpose) — A value describing the location and distance of an Apple Pencil hovering in the area above a view’s bounds. _(Apple Developer; expand on demand)_

### Combining gestures

- [Composing SwiftUI gestures](https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures) — Combine gestures to create complex interactions. _(Apple Developer; expand on demand)_
- [simultaneousGesture(_:including:)](https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:including:)) — Attaches a gesture to the view to process simultaneously with gestures defined by the view. _(Apple Developer; expand on demand)_
- [simultaneousGesture(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:isenabled:)) — Attaches a gesture to the view to process simultaneously with gestures defined by the view. _(Apple Developer; expand on demand)_
- [simultaneousGesture(_:name:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:name:isenabled:)) — Attaches a gesture to the view to process simultaneously with gestures defined by the view. _(Apple Developer; expand on demand)_
- [SequenceGesture](https://developer.apple.com/documentation/swiftui/sequencegesture) — A gesture that’s a sequence of two gestures. _(Apple Developer; expand on demand)_
- [SimultaneousGesture](https://developer.apple.com/documentation/swiftui/simultaneousgesture) — A gesture containing two gestures that can happen at the same time with neither of them preceding the other. _(Apple Developer; expand on demand)_
- [ExclusiveGesture](https://developer.apple.com/documentation/swiftui/exclusivegesture) — A gesture that consists of two gestures where only one of them can succeed. _(Apple Developer; expand on demand)_

### Customizing gestures

- [GestureInputKinds](https://developer.apple.com/documentation/swiftui/gestureinputkinds) — An option set that specifies which input kinds a gesture should recognize. _(Apple Developer; expand on demand)_

### Defining custom gestures

- [highPriorityGesture(_:including:)](https://developer.apple.com/documentation/swiftui/view/highprioritygesture(_:including:)) — Attaches a gesture to the view with a higher precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [highPriorityGesture(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/highprioritygesture(_:isenabled:)) — Attaches a gesture to the view with a higher precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [highPriorityGesture(_:name:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/highprioritygesture(_:name:isenabled:)) — Attaches a gesture to the view with a higher precedence than gestures defined by the view. _(Apple Developer; expand on demand)_
- [handGestureShortcut(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/handgestureshortcut(_:isenabled:)) — Assigns a hand gesture shortcut to the modified control. _(Apple Developer; expand on demand)_
- [defersSystemGestures(on:)](https://developer.apple.com/documentation/swiftui/view/deferssystemgestures(on:)) — Sets the screen edge from which you want your gesture to take precedence over the system gesture. _(Apple Developer; expand on demand)_
- [Gesture](https://developer.apple.com/documentation/swiftui/gesture) — An instance that matches a sequence of events to a gesture, and returns a stream of values for each of its states. _(Apple Developer; expand on demand)_
- [AnyGesture](https://developer.apple.com/documentation/swiftui/anygesture) — A type-erased gesture. _(Apple Developer; expand on demand)_
- [HandActivationBehavior](https://developer.apple.com/documentation/swiftui/handactivationbehavior) — An activation behavior specific to hand-driven input. _(Apple Developer; expand on demand)_
- [HandGestureShortcut](https://developer.apple.com/documentation/swiftui/handgestureshortcut) — Hand gesture shortcuts describe finger and wrist movements that the user can perform in order to activate a button or toggle. _(Apple Developer; expand on demand)_

### Managing gesture state

- [GestureState](https://developer.apple.com/documentation/swiftui/gesturestate) — A property wrapper type that updates a property while the user performs a gesture and resets the property back to its initial state when… _(Apple Developer; expand on demand)_
- [GestureStateGesture](https://developer.apple.com/documentation/swiftui/gesturestategesture) — A gesture that updates the state provided by a gesture’s updating callback. _(Apple Developer; expand on demand)_

### Handling activation events

- [allowsWindowActivationEvents(_:)](https://developer.apple.com/documentation/swiftui/view/allowswindowactivationevents(_:)) — Configures whether gestures in this view hierarchy can handle events that activate the containing window. _(Apple Developer; expand on demand)_

### Deprecated gestures

- [MagnificationGesture](https://developer.apple.com/documentation/swiftui/magnificationgesture) — A gesture that recognizes a magnification motion and tracks the amount of magnification. _(Apple Developer; expand on demand)_
- [RotationGesture](https://developer.apple.com/documentation/swiftui/rotationgesture) — A gesture that recognizes a rotation motion and tracks the angle of the rotation. _(Apple Developer; expand on demand)_

### Event handling

- [Input events](swiftui-input-events.md) — Respond to input from a hardware device, like a keyboard or a Touch Bar. _(local context)_
- [Clipboard](swiftui-clipboard.md) — Enable people to move or duplicate items by issuing Copy and Paste commands. _(local context)_
- [Drag and drop](swiftui-drag-and-drop.md) — Enable people to move or duplicate items by dragging them from one location to another. _(local context)_
- [Focus](swiftui-focus.md) — Identify and control which visible object responds to user interaction. _(local context)_
- [System events](swiftui-system-events.md) — React to system events, like opening a URL. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/gestures)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `13b04edc1622ce2978db04e708cfcb2a2beb01658d1b77813450e64428488ef7`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
