---
title: "getattrlistbulk(2)"
source_url: "https://github.com/apple/darwin-xnu/blob/main/bsd/man/man2/getattrlistbulk.2"
source_identifier: "bsd/man/man2/getattrlistbulk.2"
captured_at: "2026-10-06T11:13:42.444572+00:00"
source_sha256: "20487d8f262f9cff2b969aa093cb3b72b50c3d34011b1cae6e1542147c55d4b3"
source_etag: null
source_last_modified: null
source_format: "text/plain"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Open Source"
confidence: "primary-source"
---

# Bulk directory attributes

## Quick reference

- Module: Darwin; available since OS X 10.10.
- Declaration: `getattrlistbulk(int dirfd, struct attrlist *, void *, size_t, uint64_t)`; verified with macOS SDK 27.0.
- Relevance: read directory names, object types and hidden flags in a bounded buffer.

## Summary

The call returns metadata for multiple directory entries. Name and returned-attribute masks are mandatory. Records have an overall length and packed attributes; inspect the returned mask before decoding optional fields. Symbolic-link metadata describes the link. Zero indicates completion; minus one reports failure.

## Practical implications

- Bound buffers, validate offsets and lengths, and honor per-entry errors.
- Use physical directory traversal and skip hidden items and package descendants.
- Fall back on unsupported volumes without weakening the discovery contract.

## Content map

- Description and buffer layout.
- Options, return values, errors and sample decoding.

## Second-level links

- [getattrlist(2)](darwin-extended-attribute-presence.md) — expand on demand.
- [lseek(2)](https://github.com/apple/darwin-xnu/blob/main/bsd/man/man2/lseek.2) — expand on demand.

## Provenance

- Source: [Apple Open Source](https://github.com/apple/darwin-xnu/blob/main/bsd/man/man2/getattrlistbulk.2).
- Raw capture: `https://raw.githubusercontent.com/apple/darwin-xnu/main/bsd/man/man2/getattrlistbulk.2`.
- Captured: `2026-10-06T11:13:42.444572+00:00`; SHA-256: `20487d8f262f9cff2b969aa093cb3b72b50c3d34011b1cae6e1542147c55d4b3`. One manual page only.
