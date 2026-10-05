---
title: "NSGestureRecognizer"
source_url: "https://developer.apple.com/documentation/appkit/nsgesturerecognizer"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSGestureRecognizer"
captured_at: "2026-10-04T12:33:54.519715+00:00"
source_sha256: "0554343ffe93d00c3f4482b5f78c70b467879cfec37fedc09c2e9ca85e8e2515"
source_etag: "\"1ad51-65b79219fe8a1\""
source_last_modified: "Mon, 14 Sep 2026 22:41:13 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSGestureRecognizer

## Quick reference

- Module: AppKit, macOS. Signatures found in SDK macOS 27.0.
- classes of gesture available since macOS 10.10; delegate attempt since 10.11, according to SDK.

## Summary and implications

Recognizers follow the events of the view and its descendants. Zforge uses a custom subclass of NSGestureRecognizer in the window host, without delaying primary mouse events.

## Content map

- Recognition, configuration, delegate and relationships between gestures.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit)
- [CVarArg](https://developer.apple.com/documentation/swift/cvararg)
- [CustomDebugStringConvertible](https://developer.apple.com/documentation/swift/customdebugstringconvertible)
- [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible)
- [Equatable](https://developer.apple.com/documentation/swift/equatable)
- [Hashable](https://developer.apple.com/documentation/swift/hashable)
- [MainActor](https://developer.apple.com/documentation/swift/mainactor)
- [NSClickGestureRecognizer](https://developer.apple.com/documentation/appkit/nsclickgesturerecognizer)
- [NSCoding](https://developer.apple.com/documentation/foundation/nscoding)
- [NSGestureRecognizer.State.changed](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.enum/changed)
- [NSGestureRecognizer.State.failed](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.enum/failed)
- [NSGestureRecognizer.State.possible](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.enum/possible)
- [NSGestureRecognizer.State](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.enum)
- [NSGestureRecognizerDelegate](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate)
- [NSMagnificationGestureRecognizer](https://developer.apple.com/documentation/appkit/nsmagnificationgesturerecognizer)
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol)
- [NSObject](https://developer.apple.com/documentation/objectivec/nsobject-swift.class)
- [NSPanGestureRecognizer](https://developer.apple.com/documentation/appkit/nspangesturerecognizer)
- [NSPressGestureRecognizer](https://developer.apple.com/documentation/appkit/nspressgesturerecognizer)
- [NSRotationGestureRecognizer](https://developer.apple.com/documentation/appkit/nsrotationgesturerecognizer)
- [NSTouchBar](https://developer.apple.com/documentation/appkit/nstouchbar)
- [Sendable](https://developer.apple.com/documentation/swift/sendable)
- [State Transitions](https://developer.apple.com/documentation/appkit/nsgesturerecognizer#State-Transitions)
- [Technologies](https://developer.apple.com/documentation/technologies)
- [action](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/action)
- [addGestureRecognizer(_:)](https://developer.apple.com/documentation/appkit/nsview/addgesturerecognizer(_:))
- [allowedTouchTypes](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/allowedtouchtypes)
- [canBePrevented(by:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/canbeprevented(by:))
- [canPrevent(_:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/canprevent(_:))
- [delaysKeyEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delayskeyevents)
- [delaysMagnificationEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delaysmagnificationevents)
- [delaysOtherMouseButtonEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delaysothermousebuttonevents)
- [delaysPrimaryMouseButtonEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delaysprimarymousebuttonevents)
- [delaysRotationEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delaysrotationevents)
- [delaysSecondaryMouseButtonEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delayssecondarymousebuttonevents)
- [delegate](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delegate)
- [flagsChanged(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/flagschanged(with:))
- [init(coder:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/init(coder:))
- [init(target:action:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/init(target:action:))
- [isCancellableByScrollGesture](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/iscancellablebyscrollgesture)
- [isEnabled](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/isenabled)
- [keyDown(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/keydown(with:))
- [keyUp(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/keyup(with:))
- [location(in:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/location(in:))
- [magnify(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/magnify(with:))
- [modifierFlags](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/modifierflags)
- [mouseCancelled(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/mousecancelled(with:))
- [mouseDown(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/mousedown(with:))
- [mouseDragged(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/mousedragged(with:))
- [mouseUp(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/mouseup(with:))
- [name](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/name)
- [otherMouseDown(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/othermousedown(with:))
- [otherMouseDragged(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/othermousedragged(with:))
- [otherMouseUp(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/othermouseup(with:))
- [pressureChange(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/pressurechange(with:))
- [pressureConfiguration](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/pressureconfiguration)
- [recognized](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.enum/recognized)
- [reset()](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/reset())
- [rightMouseDown(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/rightmousedown(with:))
- [rightMouseDragged(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/rightmousedragged(with:))
- [rightMouseUp(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/rightmouseup(with:))
- [rotate(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/rotate(with:))
- [shouldBeRequiredToFail(by:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/shouldberequiredtofail(by:))
- [shouldRequireFailure(of:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/shouldrequirefailure(of:))
- [state](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/state-swift.property)
- [tabletPoint(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/tabletpoint(with:))
- [target](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/target)
- [touchesBegan(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/touchesbegan(with:))
- [touchesCancelled(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/touchescancelled(with:))
- [touchesEnded(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/touchesended(with:))
- [touchesMoved(with:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/touchesmoved(with:))
- [view](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/view)

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsgesturerecognizer)
- Captured: `2026-10-04T12:33:54.519715+00:00`
- SHA-256: `0554343ffe93d00c3f4482b5f78c70b467879cfec37fedc09c2e9ca85e8e2515`
- Scope: one page; secondary links not covered.

### Session associated with gesture no SDK site

SDK macOS 27.0 adds `NSView.beginDraggingSession(items:gesture:source:) -> NSDraggingSession?`, available since macOS 27.0. This association was experienced in ZF-30. The final implementation uses `beginDraggingSession(with:event:source:)` while dispatching mouseDragged in macOS 26/27, shared with local files; the association with the recognizer is not the current path. This signature was consulted in `AppKit.framework/Headers/NSView.h` of the local Xcode; It's not a new web capture.
