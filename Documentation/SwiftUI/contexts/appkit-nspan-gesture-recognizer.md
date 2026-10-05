---
title: "NSPanGestureRecognizer"
source_url: "https://developer.apple.com/documentation/appkit/nspangesturerecognizer"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSPanGestureRecognizer"
captured_at: "2026-10-04T12:33:54.519715+00:00"
source_sha256: "34274c2313dc58e2e0524eba2b43b46413282537ce8e3df50a60fd490768745b"
source_etag: "\"882e-65b3b459ae12c\""
source_last_modified: "Fri, 11 Sep 2026 20:53:09 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSPanGestureRecognizer

## Quick reference

- Module: AppKit, macOS. Signatures found in SDK macOS 27.0.
- classes of gesture available since macOS 10.10; delegate attempt since 10.11, according to SDK.

## Summary and implications

Recognises displacement of the primary button. The implementation of Zforge uses a custom recognizator in the window host, limited to the virtual item, to start drag while mouseDragged. The target/action of pan has been consulted; its action occurs in another lap of the run loop and was not adopted to start the session.

## Content map

- Recognition, configuration, delegate and relationships between gestures.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit)
- [CVarArg](https://developer.apple.com/documentation/swift/cvararg)
- [CustomDebugStringConvertible](https://developer.apple.com/documentation/swift/customdebugstringconvertible)
- [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible)
- [Equatable](https://developer.apple.com/documentation/swift/equatable)
- [Hashable](https://developer.apple.com/documentation/swift/hashable)
- [NSClickGestureRecognizer](https://developer.apple.com/documentation/appkit/nsclickgesturerecognizer)
- [NSCoding](https://developer.apple.com/documentation/foundation/nscoding)
- [NSGestureRecognizer](https://developer.apple.com/documentation/appkit/nsgesturerecognizer)
- [NSMagnificationGestureRecognizer](https://developer.apple.com/documentation/appkit/nsmagnificationgesturerecognizer)
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol)
- [NSPressGestureRecognizer](https://developer.apple.com/documentation/appkit/nspressgesturerecognizer)
- [NSRotationGestureRecognizer](https://developer.apple.com/documentation/appkit/nsrotationgesturerecognizer)
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype)
- [Sendable](https://developer.apple.com/documentation/swift/sendable)
- [Technologies](https://developer.apple.com/documentation/technologies)
- [buttonMask](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/buttonmask)
- [delaysPrimaryMouseButtonEvents](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/delaysprimarymousebuttonevents)
- [location(in:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizer/location(in:))
- [maximumNumberOfTouches](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/maximumnumberoftouches)
- [minimumNumberOfTouches](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/minimumnumberoftouches)
- [numberOfTouchesRequired](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/numberoftouchesrequired)
- [setTranslation(_:in:)](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/settranslation(_:in:))
- [translation(in:)](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/translation(in:))
- [true](https://developer.apple.com/documentation/swift/true)
- [velocity(in:)](https://developer.apple.com/documentation/appkit/nspangesturerecognizer/velocity(in:))

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nspangesturerecognizer)
- Captured: `2026-10-04T12:33:54.519715+00:00`
- SHA-256: `34274c2313dc58e2e0524eba2b43b46413282537ce8e3df50a60fd490768745b`
- Scope: one page; secondary links not covered.
