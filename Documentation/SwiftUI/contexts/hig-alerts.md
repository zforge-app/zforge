---
title: "Alerts"
source_url: "https://developer.apple.com/design/human-interface-guidelines/alerts"
source_identifier: "doc://com.apple.HIG/design/Human-Interface-Guidelines/alerts"
captured_at: "2026-07-26T01:54:18Z"
source_sha256: "5a209e6c67818f2e11c213094852d015adeedf8b1faca4e2072faeabd114d3fb"
source_etag: "W/\"0cde5823d83af3fd8f1b6e6ca9b97713\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Human Interface Guidelines"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Alerts

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Human Interface Guidelines
- Module: Design
- Relevance to Zforge: direct to confirmation alerts and destructive actions in macOS
- Availability: multiplatform orientation, with specific considerations for macOS
- Declaration: not applicable

## Summary

Alerts must be reserved for critical information and actions that require immediate decision. Apple recommends confirming unusual and irreversible destructive actions, but distinguishes between an unexpected destructive consequence and a destructive action deliberately chosen by the person.

On buttons, destructive style must identify a destructive action that does not correspond to the original intention. When the person deliberately chose the action — the official example is emptying the Trash — Apple advises that confirmation can avoid destructive style and accept `Return`, as convenience outweighs the need to reaffirm destructive character. When it is important to prevent automatic confirmation before reading, no button must be set to default.

A destructive action must offer `Cancel`. In macOS, `Escape` and `Command-Period` are recommended alternatives to cancel the alert.

## Practical implications

- Confirmation remains necessary for permanent exclusion because it is unusual and irreversible.
- A permanent exclusion explicitly initiated by `Option-Command-Delete` is similar to the example of emptying the Recycle Bin; allowing `Return` to confirm is compatible with Apple orientation.
- Removing the default action is also valid when the product wants to force a deliberate reading, but it is not a general requirement for any destructive action.
- The cancel button must remain available and respond to `Escape`.

## Content map

- Best practices
- Anatomy
- Content
- Buttons
- Platform considerations
- Resources
- Change log

## Second-level links

### Design

- [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) — _Apple Developer; expand on demand_
- [Presentation](https://developer.apple.com/design/human-interface-guidelines/presentation) — _Apple Developer; expand on demand_
- [Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets) — _Apple Developer; expand on demand_
- [Modality](https://developer.apple.com/design/human-interface-guidelines/modality) — _Apple Developer; expand on demand_

### Developer documentation

- [NSAlert](https://developer.apple.com/documentation/AppKit/NSAlert) — _Apple Developer; expand on demand_
- [alert(_:isPresented:actions:)](https://developer.apple.com/documentation/SwiftUI/View/alert(_:isPresented:actions:)-1bkka) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/design/human-interface-guidelines/alerts)
- Captured: `2026-07-26T01:54:18Z`
- Payload SHA-256: `5a209e6c67818f2e11c213094852d015adeedf8b1faca4e2072faeabd114d3fb`
- Scope: one page; the above absolute links have not yet been covered.
