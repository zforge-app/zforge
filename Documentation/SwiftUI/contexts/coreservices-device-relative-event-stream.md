---
title: "FSEventStreamCreateRelativeToDevice"
source_url: "https://developer.apple.com/documentation/coreservices/1447341-fseventstreamcreaterelativetodev"
source_identifier: "doc://com.apple.documentation/documentation/coreservices/1447341-fseventstreamcreaterelativetodev"
captured_at: "2026-10-06T12:01:05.635002+00:00"
payload_sha256: "1facf1dc23111020315c58a5a8f2305da7b3e53297714bf2ee35e6c87a65c517"
format: "DocC JSON"
platforms: ["macOS", "Mac Catalyst"]
availability: "macOS 10.5+; Mac Catalyst 13.1+"
origin: "Apple Developer; local macOS 27.0 SDK header"
confidence: "high"
---

# FSEventStreamCreateRelativeToDevice

Creates a stream on a specified device and resumes changes after a supplied event ID. Paths are relative to the device mount. The native macOS 27.0 SDK header explicitly restricts each stream to one path even though the signature accepts a CFArray. The captured DocC prose does not repeat this limit; use the SDK restriction when configuring streams. A valid object still requires successful scheduling and start.

## Signature

```swift
func FSEventStreamCreateRelativeToDevice(_ allocator: CFAllocator?, _ callback: FSEventStreamCallback, _ context: UnsafeMutablePointer<FSEventStreamContext>?, _ deviceToWatch: dev_t, _ pathsToWatchRelativeToDevice: CFArray, _ sinceWhen: FSEventStreamEventId, _ latency: CFTimeInterval, _ flags: FSEventStreamCreateFlags) -> FSEventStreamRef?
```

## Section map

- Parameters: device identity, device-relative paths, historical event cursor, callback context and latency.
- Return value: an optional native stream reference.
- Discussion: stream creation precedes scheduling and start.

## Zforge implications and SDK evidence

- Create one stream per authorized discovery scope, including Home and Shared on the same device.
- Persist each scope's processed cursor separately and validate the volume journal UUID before reuse.
- Check start success; object creation alone does not establish history delivery.
- SDK evidence: `MacOSX.sdk/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/FSEvents.framework/Versions/A/Headers/FSEvents.h`, declaration discussion and `pathsToWatchRelativeToDevice` parameter, SDK macOS 27.0. This restriction caused real multi-scope startup to reject the first implementation; native multi-scope tests now reproduce it.

## Secondary links

- [CFAllocator](https://developer.apple.com/documentation/corefoundation/cfallocator) — expand on demand.
- [CFArray](https://developer.apple.com/documentation/corefoundation/cfarray) — expand on demand.
- [CFTimeInterval](https://developer.apple.com/documentation/corefoundation/cftimeinterval) — expand on demand.
- [Core Services](https://developer.apple.com/documentation/coreservices) — expand on demand.
- [FSEventStreamCallback](https://developer.apple.com/documentation/coreservices/fseventstreamcallback) — expand on demand.
- [FSEventStreamContext](https://developer.apple.com/documentation/coreservices/fseventstreamcontext) — expand on demand.
- [FSEventStreamCreateFlags](https://developer.apple.com/documentation/coreservices/fseventstreamcreateflags) — expand on demand.
- [FSEventStreamEventId](https://developer.apple.com/documentation/coreservices/fseventstreameventid) — expand on demand.
- [FSEventStreamRef](https://developer.apple.com/documentation/coreservices/fseventstreamref) — expand on demand.
- [File System Events](https://developer.apple.com/documentation/coreservices/file_system_events) — expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand.
- [UnsafeMutablePointer](https://developer.apple.com/documentation/swift/unsafemutablepointer) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/coreservices/1447341-fseventstreamcreaterelativetodev); fetched [DocC JSON](https://developer.apple.com/tutorials/data/documentation/coreservices/1447341-fseventstreamcreaterelativetodev.json).
- Captured: `2026-10-06T12:01:05.635002+00:00`; payload SHA-256: `1facf1dc23111020315c58a5a8f2305da7b3e53297714bf2ee35e6c87a65c517`.
- ETag: `"99cd-65b3a469cdede"`; Last-Modified: `Fri, 11 Sep 2026 19:41:51 GMT`.
- Scope: one page. Secondary links were retained without traversal. The Markdown representation returned HTTP 404; DocC JSON capture succeeded.
