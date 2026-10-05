---
title: "NSWindow"
source_url: "https://developer.apple.com/documentation/appkit/nswindow"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSWindow"
captured_at: "2026-07-18T22:54:20Z"
source_sha256: "9c0bb122b670afc94781687540aed350531019f089410341a5c37d9749f5a172"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSWindow

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Scroll: class that represents a window displayed by the application.
- Module: AppKit.
- Relevance to Zforge: direta; provides the window tab system native and the title integration with a represented URL.
- Availability: macOS.
- Declaration: `@MainActor class NSWindow`

## Summary

Each instance of `NSWindow` corresponds to a visible window at most, hosts the view hierarchy and distributes mouse and keyboard events. The class includes a specific section for window tab management, with the identification of compatible groups, automatic tab policy, chain response actions to show the bar, select tabs, and move a tab to another window.

## Practical implications

- Using the bar managed by `NSWindow` instead of drawing a bar within the SwiftUI content, it maintains native appearance, commands, grouping, and accessibility.
- Browser windows must share a `tabbingIdentifier` and use `tabbingMode = .automatic`; `toggleTabBar(_:)` meets the command to show or hide the bar.
- By belonging to the window frame, the native tab bar crosses the width of the window above the entire content hierarchy, including the region occupied by the preview. It must not be limited by the internal split between content and inspector.
- Set `representedURL` allows AppKit to associate the window to the current location and provide the ancestral menu when clicking on the Command title.

## Content map

- Overview and window creation.
- Configuration of content, appearance and behavior.
- Window tab management.
- Information, layout, resizing, sheets and events.

## Second-level links

### Window tabs

- [tabbingIdentifier](https://developer.apple.com/documentation/appkit/nswindow/tabbingidentifier-swift.property) — _Apple Developer; expand on demand_
- [tabbingMode](https://developer.apple.com/documentation/appkit/nswindow/tabbingmode-swift.property) — _Apple Developer; expand on demand_
- [toggleTabBar(_:)](https://developer.apple.com/documentation/appkit/nswindow/toggletabbar(_:)) — _Apple Developer; expand on demand_
- [selectNextTab(_:)](https://developer.apple.com/documentation/appkit/nswindow/selectnexttab(_:)) — _Apple Developer; expand on demand_
- [selectPreviousTab(_:)](https://developer.apple.com/documentation/appkit/nswindow/selectprevioustab(_:)) — _Apple Developer; expand on demand_

### Integration with location

- [representedURL](https://developer.apple.com/documentation/appkit/nswindow/representedurl) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nswindow)
- Captured: `2026-07-18T22:54:20Z`
- Payload SHA-256: `9c0bb122b670afc94781687540aed350531019f089410341a5c37d9749f5a172`
- Scope: one page; the above absolute links have not yet been covered.
