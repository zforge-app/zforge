---
title: "NSGestureRecognizerDelegate"
source_url: "https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSGestureRecognizerDelegate"
captured_at: "2026-10-04T12:33:54.519715+00:00"
source_sha256: "0a57c924cacfb4eb5f1d302a8dfa0e0a3be19eb3b63f437595397794522cd634"
source_etag: "\"565c-659026db0009a\""
source_last_modified: "Fri, 14 Aug 2026 14:13:45 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSGestureRecognizerDelegate

## Quick reference

- Module: AppKit, macOS. Signatures found in SDK macOS 27.0.
- classes of gesture available since macOS 10.10; delegate attempt since 10.11, according to SDK.

## Summary and implications

The delegate filters the beginning of an event sequence and controls simultaneous recognition. Return false in the initial attempt excludes the recognizator from the sequence.

## Content map

- Recognition, configuration, delegate and relationships between gestures.

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit)
- [NSGestureRecognizer](https://developer.apple.com/documentation/appkit/nsgesturerecognizer)
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol)
- [Technologies](https://developer.apple.com/documentation/technologies)
- [gestureRecognizer(_:shouldAttemptToRecognizeWith:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizer(_:shouldattempttorecognizewith:))
- [gestureRecognizer(_:shouldBeRequiredToFailBy:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizer(_:shouldberequiredtofailby:))
- [gestureRecognizer(_:shouldReceive:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizer(_:shouldreceive:))
- [gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizer(_:shouldrecognizesimultaneouslywith:))
- [gestureRecognizer(_:shouldRequireFailureOf:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizer(_:shouldrequirefailureof:))
- [gestureRecognizerShouldBegin(_:)](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate/gesturerecognizershouldbegin(_:))

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nsgesturerecognizerdelegate)
- Captured: `2026-10-04T12:33:54.519715+00:00`
- SHA-256: `0a57c924cacfb4eb5f1d302a8dfa0e0a3be19eb3b63f437595397794522cd634`
- Scope: one page; secondary links not covered.
