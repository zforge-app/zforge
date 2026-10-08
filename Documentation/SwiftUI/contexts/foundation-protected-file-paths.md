---
title: "Protected file paths in macOS bookmark and IPC delivery"
source_url: "https://developer.apple.com/forums/thread/798402"
source_identifier: "Apple Developer Forums thread 798402"
captured_at: "2026-10-07T16:20:54.971425+00:00"
source_sha256: "127de9089f42a9f5697f298b20d8756f2684c3f8e45b57bb51e09d3756a534be"
source_etag: null
source_last_modified: null
source_format: "text/plain; web-tool-normalized-excerpt"
depth: 2
categories: ["On-demand Foundation"]
language: "en"
authority: "Apple DTS staff guidance"
confidence: "primary-staff-source; runtime verification required"
---

# Protected file paths in macOS bookmark and IPC delivery

## Summary

Apple DTS explains that /.nofollow/ is a kernel-recognized namespace for a path whose links must not be followed. It can appear when security-sensitive URLs cross process boundaries, including bookmark infrastructure. Removing this protection from an operational path can change security behavior. The discussion separately describes historical root-directory bugs and their OS-specific repairs; those are not a general instruction to disable bookmarks.

## Zforge implications and current evidence

On macOS 27.0.1, Shortcuts delivers the synthetic archive as /.nofollow/private/tmp/ZforgeAutomationSmoke-20261007/Stdio Output.7z. The initial string boundary check refuses that native alias despite an explicit grant. Canonicalize the namespace only for physical authorization comparison, retain the original protected URL/path for the operation and bookmark lease, and continue rejecting physical symlink escapes. The new characterization must fail before repair and prove real archive operations and revocation afterward. No operational prefix stripping or broader default grant is permitted.

## Content map

- Bookmark and IPC URL delivery.
- Kernel no-follow semantics.
- Historical Foundation root-path issue.
- Discussion of symlinks, canonicalization and sandbox differences.

## Secondary links

The normalized excerpt exposes a TOC/TOU reference and forum reply/profile references without recoverable absolute destinations. Full HTML link enumeration is blocked by the origin verification response; these references remain unexpanded.

## Provenance

- Source: [Apple DTS discussion](https://developer.apple.com/forums/thread/798402).
- Captured: `2026-10-07T16:20:54.971425+00:00`.
- Payload SHA-256: `127de9089f42a9f5697f298b20d8756f2684c3f8e45b57bb51e09d3756a534be`.
- Scope: normalized primary-source excerpt around lines 420–714, obtained through the web retrieval tool. Direct HTML capture returned a verification page and is not used as source evidence; no source response headers are available for the excerpt. Guidance is attributed only to Apple DTS staff. Namespace normalization for authorization is a Zforge implementation decision verified by tests, not an Apple-prescribed workaround. Secondary-link enumeration remains incomplete.
