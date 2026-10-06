---
title: "Using the FSEvents Framework"
source_url: "https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html"
source_identifier: "https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html"
captured_at: "2026-10-06T11:03:34.191637+00:00"
source_sha256: "28e280a68e4cf7553d83882a5d21eac0c68d6cb1b4d171e57cf1c790110bdebf"
source_etag: null
source_last_modified: "Fri, 30 Jan 2026 23:11:44 GMT"
source_format: "text/html"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Using the FSEvents Framework

## Quick reference

- Module: Core Services / FSEvents.
- Availability: macOS 10.5 and later; native declarations verified with the macOS 27.0 SDK.
- Relevance: durable, authorized global tag discovery without a whole-tree scan on every launch.

## Summary

Persist the last processed event ID and resume from it to obtain changes across launches. Apple recommends per-device streams for persistent work. Start monitoring before the initial tree scan. Historical delivery ends with HistoryDone; only checkpoint after the corresponding work has been applied. MustScanSubDirs requires subtree reconciliation; dropped events require reconciling all watched paths. WatchRoot reports root changes with ID zero.

## Practical implications

- Save records and an applied cursor atomically after scan/replay work drains.
- Match scope identity and journal UUID; reconcile invalid histories before saving a new checkpoint.
- Validate historical delivery in the sandboxed application, not just through static API inspection.

## SDK flag clarification

The macOS 27.0 SDK `FSEvents.h` declares `kFSEventStreamEventFlagItemInodeMetaMod` (0x400, macOS 10.7+) for inode metadata changes. Zforge treats this as relevant and reconciles descendants when the event identifies a directory, so changing UF_HIDDEN while the app is closed is reflected during replay. This is local SDK evidence added to the captured framework guide, not a claim that the archived page documents the flag.

## Content map

- Stream lifecycle and persistent identity.
- Historical delivery and invalidation.

## Second-level links

- [Reference 1](http://www.apple.com/legal/internet-services/terms/site.html) — expand on demand.
- [Reference 2](http://www.apple.com/legal/policies/ideas.html) — expand on demand.
- [Reference 3](http://www.apple.com/privacy/) — expand on demand.
- [Reference 4](https://developer.apple.com/) — expand on demand.
- [Reference 5](https://developer.apple.com/bugreporter/) — expand on demand.
- [Reference 6](https://developer.apple.com/documentation/corefoundation/1542011-cfrunlooprun) — expand on demand.
- [Reference 7](https://developer.apple.com/documentation/corefoundation/1542428-cfrunloopgetcurrent) — expand on demand.
- [Reference 8](https://developer.apple.com/documentation/corefoundation/1542812-cfdategetabsolutetime) — expand on demand.
- [Reference 9](https://developer.apple.com/documentation/corefoundation/cfabsolutetime) — expand on demand.
- [Reference 10](https://developer.apple.com/documentation/corefoundation/cfarray) — expand on demand.
- [Reference 11](https://developer.apple.com/documentation/corefoundation/cfdateref) — expand on demand.
- [Reference 12](https://developer.apple.com/documentation/corefoundation/kcfabsolutetimeintervalsince1904) — expand on demand.
- [Reference 13](https://developer.apple.com/documentation/corefoundation/kcfabsolutetimeintervalsince1970) — expand on demand.
- [Reference 14](https://developer.apple.com/documentation/coreservices/1441727-fseventstreamflushasync) — expand on demand.
- [Reference 15](https://developer.apple.com/documentation/coreservices/1441982-fseventstreamunschedulefromrunlo) — expand on demand.
- [Reference 16](https://developer.apple.com/documentation/coreservices/1442917-fseventsgetcurrenteventid) — expand on demand.
- [Reference 17](https://developer.apple.com/documentation/coreservices/1443980-fseventstreamcreate) — expand on demand.
- [Reference 18](https://developer.apple.com/documentation/coreservices/1444453-fseventscopyuuidfordevice) — expand on demand.
- [Reference 19](https://developer.apple.com/documentation/coreservices/1445629-fseventstreamflushsync) — expand on demand.
- [Reference 20](https://developer.apple.com/documentation/coreservices/1445989-fseventstreamrelease) — expand on demand.
- [Reference 21](https://developer.apple.com/documentation/coreservices/1446030-fseventstreamgetlatesteventid) — expand on demand.
- [Reference 22](https://developer.apple.com/documentation/coreservices/1446990-fseventstreaminvalidate) — expand on demand.
- [Reference 23](coreservices-device-relative-event-stream.md) — expand on demand.
- [Reference 24](https://developer.apple.com/documentation/coreservices/1447673-fseventstreamstop) — expand on demand.
- [Reference 25](https://developer.apple.com/documentation/coreservices/1447824-fseventstreamschedulewithrunloop) — expand on demand.
- [Reference 26](https://developer.apple.com/documentation/coreservices/1447917-fseventstreamcopypathsbeingwatch) — expand on demand.
- [Reference 27](https://developer.apple.com/documentation/coreservices/1447985-fseventspurgeeventsfordeviceupto) — expand on demand.
- [Reference 28](https://developer.apple.com/documentation/coreservices/1448000-fseventstreamstart) — expand on demand.
- [Reference 29](https://developer.apple.com/documentation/coreservices/1449675-fseventstreamgetdevicebeingwatch) — expand on demand.
- [Reference 30](https://developer.apple.com/documentation/coreservices/1449772-fseventsgetlasteventidfordeviceb) — expand on demand.
- [Reference 31](https://developer.apple.com/documentation/coreservices/1455361-fseventstreameventflags/kfseventstreameventflageventidswrapped) — expand on demand.
- [Reference 32](https://developer.apple.com/documentation/coreservices/1455361-fseventstreameventflags/kfseventstreameventflagkerneldropped) — expand on demand.
- [Reference 33](https://developer.apple.com/documentation/coreservices/fseventstreamcallback) — expand on demand.
- [Reference 34](https://developer.apple.com/documentation/coreservices/fseventstreameventid) — expand on demand.
- [Reference 35](https://developer.apple.com/documentation/coreservices/kfseventstreamcreateflagusecftypes) — expand on demand.
- [Reference 36](https://developer.apple.com/documentation/coreservices/kfseventstreamcreateflagwatchroot) — expand on demand.
- [Reference 37](https://developer.apple.com/documentation/coreservices/kfseventstreameventflagmustscansubdirs) — expand on demand.
- [Reference 38](https://developer.apple.com/documentation/coreservices/kfseventstreameventflagrootchanged) — expand on demand.
- [Reference 39](https://developer.apple.com/documentation/coreservices/kfseventstreameventflaguserdropped) — expand on demand.
- [Reference 40](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDatesAndTimes/CFDatesAndTimes.html#//apple_ref/doc/uid/10000125i) — expand on demand.
- [Reference 41](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFRunLoops/CFRunLoops.html#//apple_ref/doc/uid/10000135i) — expand on demand.
- [Reference 42](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/FileSystemEventSecurity/FileSystemEventSecurity.html) — expand on demand.
- [Reference 43](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/TechnologyOverview/TechnologyOverview.html) — expand on demand.
- [Reference 44](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/index.html) — expand on demand.
- [Reference 45](https://developer.apple.com/library/archive/documentation/LegacyTechnologies/WebObjects/WebObjects_3.5/Reference/Frameworks/ObjC/Foundation/Classes/NSDateClassCluster/Description.html#//apple_ref/occ/cl/NSDate) — expand on demand.
- [Reference 46](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fcntl.2.html#//apple_ref/doc/man/2/fcntl) — expand on demand.
- [Reference 47](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/lstat.2.html#//apple_ref/doc/man/2/lstat) — expand on demand.
- [Reference 48](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/stat.2.html#//apple_ref/doc/man/2/stat) — expand on demand.
- [Reference 49](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/opendir.3.html#//apple_ref/doc/man/3/opendir) — expand on demand.
- [Reference 50](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/readdir.3.html#//apple_ref/doc/man/3/readdir) — expand on demand.
- [Reference 51](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/scandir.3.html#//apple_ref/doc/man/3/scandir) — expand on demand.
- [Reference 52](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/tdelete.3.html#//apple_ref/doc/man/3/tdelete) — expand on demand.
- [Reference 53](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/tfind.3.html#//apple_ref/doc/man/3/tfind) — expand on demand.
- [Reference 54](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/tsearch.3.html#//apple_ref/doc/man/3/tsearch) — expand on demand.
- [Reference 55](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/twalk.3.html#//apple_ref/doc/man/3/twalk) — expand on demand.
- [Reference 56](https://developer.apple.com/library/archive/navigation/) — expand on demand.
- [Reference 57](https://developer.apple.com/library/archive/samplecode/Watcher/Introduction/Intro.html#//apple_ref/doc/uid/DTS10004054) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html).
- Captured: `2026-10-06T11:03:34.191637+00:00`; payload SHA-256: `28e280a68e4cf7553d83882a5d21eac0c68d6cb1b4d171e57cf1c790110bdebf`.
- Scope: one page; secondary links were retained without traversal.
