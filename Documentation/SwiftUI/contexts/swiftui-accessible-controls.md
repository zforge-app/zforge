---
title: "Accessible controls"
source_url: "https://developer.apple.com/documentation/swiftui/accessible-controls"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Accessible-controls"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "f74aa5badbf5f71a15e049aaefbb563304a41c89a19d1b5bae0a89ee1b7ddcdf"
source_etag: "W/\"4f8f22aa782fe830083eb315fdd8a520\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Accessibility"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Accessible controls

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Improve access to actions that your app can undertake.

Help people using assistive technologies to gain access to controls in your app. For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Accessibility](https://developer.apple.com/design/Human-Interface-Guidelines/accessibility#Buttons-and-controls) — Accessible user interfaces empower everyone to have a great experience with your app or game. _(Apple Developer; expand on demand)_

### Adding actions to views

- [accessibilityAction(_:_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(_:_:)) — Adds an accessibility action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. _(Apple Developer; expand on demand)_
- [accessibilityActions(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityactions(_:)) — Adds multiple accessibility actions to the view. _(Apple Developer; expand on demand)_
- [accessibilityAction(named:_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(named:_:)) — Adds an accessibility action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. _(Apple Developer; expand on demand)_
- [accessibilityAction(action:label:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(action:label:)) — Adds an accessibility action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the action. _(Apple Developer; expand on demand)_
- [accessibilityAction(intent:label:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(intent:label:)) — Adds an accessibility action labeled by the contents of to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the… _(Apple Developer; expand on demand)_
- [accessibilityAction(_:intent:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(_:intent:)) — Adds an accessibility action representing to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the… _(Apple Developer; expand on demand)_
- [accessibilityAction(named:intent:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaction(named:intent:)) — Adds an accessibility action labeled to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the… _(Apple Developer; expand on demand)_
- [accessibilityAdjustableAction(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityadjustableaction(_:)) — Adds an accessibility adjustable action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the… _(Apple Developer; expand on demand)_
- [accessibilityScrollAction(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityscrollaction(_:)) — Adds an accessibility scroll action to the view. Actions allow assistive technologies, such as the VoiceOver, to interact with the view by invoking the… _(Apple Developer; expand on demand)_
- [accessibilityActions(category:_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityactions(category:_:)) — Adds multiple accessibility actions to the view with a specific category. Actions allow assistive technologies, such as VoiceOver, to interact with the view by… _(Apple Developer; expand on demand)_
- [AccessibilityActionKind](https://developer.apple.com/documentation/swiftui/accessibilityactionkind) — The structure that defines the kinds of available accessibility actions. _(Apple Developer; expand on demand)_
- [AccessibilityAdjustmentDirection](https://developer.apple.com/documentation/swiftui/accessibilityadjustmentdirection) — A directional indicator you use when making an accessibility adjustment. _(Apple Developer; expand on demand)_
- [AccessibilityActionCategory](https://developer.apple.com/documentation/swiftui/accessibilityactioncategory) — Designates an accessibility action category that is provided and named by the system. _(Apple Developer; expand on demand)_

### Offering Quick Actions to people

- [accessibilityQuickAction(style:content:)](https://developer.apple.com/documentation/swiftui/view/accessibilityquickaction(style:content:)) — Adds a quick action to be shown by the system when active. _(Apple Developer; expand on demand)_
- [accessibilityQuickAction(style:isActive:content:)](https://developer.apple.com/documentation/swiftui/view/accessibilityquickaction(style:isactive:content:)) — Adds a quick action to be shown by the system when active. _(Apple Developer; expand on demand)_
- [AccessibilityQuickActionStyle](https://developer.apple.com/documentation/swiftui/accessibilityquickactionstyle) — A type that describes the presentation style of an accessibility quick action. _(Apple Developer; expand on demand)_

### Making gestures accessible

- [accessibilityActivationPoint(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityactivationpoint(_:)) — The activation point for an element is the location assistive technologies use to initiate gestures. _(Apple Developer; expand on demand)_
- [accessibilityActivationPoint(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityactivationpoint(_:isenabled:)) — The activation point for an element is the location assistive technologies use to initiate gestures. _(Apple Developer; expand on demand)_
- [accessibilityDragPoint(_:description:)](https://developer.apple.com/documentation/swiftui/view/accessibilitydragpoint(_:description:)) — The point an assistive technology should use to begin a drag interaction. _(Apple Developer; expand on demand)_
- [accessibilityDragPoint(_:description:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilitydragpoint(_:description:isenabled:)) — The point an assistive technology should use to begin a drag interaction. _(Apple Developer; expand on demand)_
- [accessibilityDropPoint(_:description:)](https://developer.apple.com/documentation/swiftui/view/accessibilitydroppoint(_:description:)) — The point an assistive technology should use to end a drag interaction. _(Apple Developer; expand on demand)_
- [accessibilityDropPoint(_:description:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilitydroppoint(_:description:isenabled:)) — The point an assistive technology should use to end a drag interaction. _(Apple Developer; expand on demand)_
- [accessibilityDirectTouch(_:options:)](https://developer.apple.com/documentation/swiftui/view/accessibilitydirecttouch(_:options:)) — Explicitly set whether this accessibility element is a direct touch area. Direct touch areas passthrough touch events to the app rather than being handled… _(Apple Developer; expand on demand)_
- [accessibilityZoomAction(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityzoomaction(_:)) — Adds an accessibility zoom action to the view. Actions allow assistive technologies, such as VoiceOver, to interact with the view by invoking the action. _(Apple Developer; expand on demand)_
- [AccessibilityDirectTouchOptions](https://developer.apple.com/documentation/swiftui/accessibilitydirecttouchoptions) — An option set that defines the functionality of a view’s direct touch area. _(Apple Developer; expand on demand)_
- [AccessibilityZoomGestureAction](https://developer.apple.com/documentation/swiftui/accessibilityzoomgestureaction) — Position and direction information of a zoom gesture that someone performs with an assistive technology like VoiceOver. _(Apple Developer; expand on demand)_

### Controlling focus

- [accessibilityFocused(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityfocused(_:)) — Modifies this view by binding its accessibility element’s focus state to the given boolean state value. _(Apple Developer; expand on demand)_
- [accessibilityFocused(_:equals:)](https://developer.apple.com/documentation/swiftui/view/accessibilityfocused(_:equals:)) — Modifies this view by binding its accessibility element’s focus state to the given state value. _(Apple Developer; expand on demand)_
- [AccessibilityFocusState](https://developer.apple.com/documentation/swiftui/accessibilityfocusstate) — A property wrapper type that can read and write a value that SwiftUI updates as the focus of any active accessibility technology, such as… _(Apple Developer; expand on demand)_

### Managing interactivity

- [accessibilityRespondsToUserInteraction(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrespondstouserinteraction(_:)) — Explicitly set whether this Accessibility element responds to user interaction and would thus be interacted with by technologies such as Switch Control, Voice Control… _(Apple Developer; expand on demand)_
- [accessibilityRespondsToUserInteraction(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrespondstouserinteraction(_:isenabled:)) — Explicitly set whether this Accessibility element responds to user interaction and would thus be interacted with by technologies such as Switch Control, Voice Control… _(Apple Developer; expand on demand)_

### Accessibility

- [Accessibility fundamentals](swiftui-accessibility-fundamentals.md) — Make your SwiftUI apps accessible to everyone, including people with disabilities. _(local context)_
- [Accessible appearance](swiftui-accessible-appearance.md) — Enhance the legibility of content in your app’s interface. _(local context)_
- [Accessible descriptions](swiftui-accessible-descriptions.md) — Describe interface elements to help people understand what they represent. _(local context)_
- [Accessible navigation](swiftui-accessible-navigation.md) — Enable users to navigate to specific user interface elements using rotors. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/accessible-controls)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `f74aa5badbf5f71a15e049aaefbb563304a41c89a19d1b5bae0a89ee1b7ddcdf`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
