---
title: "FSEventsCopyUUIDForDevice(_:)"
source_url: "https://developer.apple.com/documentation/coreservices/1444453-fseventscopyuuidfordevice"
source_identifier: "https://developer.apple.com/documentation/coreservices/1444453-fseventscopyuuidfordevice"
captured_at: "2026-10-06T11:03:34.191637+00:00"
source_sha256: "0a77660438f887544841f37a8b03574ccc73e9b55d0aeb5ea85494068de8dd56"
source_etag: "\"43d0-65b3a465d1364\""
source_last_modified: "Fri, 11 Sep 2026 19:41:46 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# FSEventsCopyUUIDForDevice(_:)

## Quick reference

- Module: Core Services / FSEvents.
- Availability: macOS 10.5 and later; native declarations verified with the macOS 27.0 SDK.
- Relevance: durable, authorized global tag discovery without a whole-tree scan on every launch.

## Summary

A non-null UUID identifies the persistent event database on a volume. It travels with the device and changes when history is purged, the disk is erased, or event IDs wrap. A null UUID means historical events are unavailable; use a live watcher instead of trusting a saved index. Compare the UUID across launches rather than persisting a transient device number.

## Practical implications

- Save records and an applied cursor atomically after scan/replay work drains.
- Match scope identity and journal UUID; reconcile invalid histories before saving a new checkpoint.
- Validate historical delivery in the sandboxed application, not just through static API inspection.

## Content map

- Stream lifecycle and persistent identity.
- Historical delivery and invalidation.

## Second-level links

- [Core Services](https://developer.apple.com/documentation/coreservices) — expand on demand.
- [File System Events](https://developer.apple.com/documentation/coreservices/file_system_events) — expand on demand.
- [CFUUID](https://developer.apple.com/documentation/corefoundation/cfuuid) — expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/coreservices/1444453-fseventscopyuuidfordevice).
- Captured: `2026-10-06T11:03:34.191637+00:00`; payload SHA-256: `0a77660438f887544841f37a8b03574ccc73e9b55d0aeb5ea85494068de8dd56`.
- Scope: one page; secondary links were retained without traversal.
