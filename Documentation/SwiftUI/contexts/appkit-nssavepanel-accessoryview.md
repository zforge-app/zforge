---
title: "accessoryView"
source_url: "https://developer.apple.com/documentation/appkit/nssavepanel/accessoryview"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSSavePanel/accessoryView"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "06b8eeadd21e07b6a3ea21e01b29d3da2c5a895e01f32448e3fd53777275dd87"
source_etag: "\"45f5-659026d729d20\""
source_last_modified: "Fri, 14 Aug 2026 14:13:41 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "AppKit integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# accessoryView

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Instance Property
- Module: AppKit
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: macOS
- Declaration: `var accessoryView: NSView? { get set }`

## Summary

**Official summary:** The custom accessory view for the current app.

You can customize the panel by adding a custom view. The custom object you add appears just above the OK and Cancel buttons at the bottom of the panel. The object automatically resizes itself to accommodate . Use this property to change the accessory view as needed. If is , the Save panel removes the current accessory view. The panel relinquishes ownership of the accessory view after the panel is closed. If you want to reuse the accessory view, don’t rely on the panel to hold onto the accessory view until the next time you use it; instead, maintain your own strong reference to the view.

## Practical implications

- The custom accessory appears above the OK/Cancel buttons and the NSSavePanel adjusts its height to behave it.
- Inference from the documented public API: `accessoryView` adds content to the footer and does not offer repositioning of internal name controls, Tags and Where. The reorganization of these fields must not be treated as feasible within the native panel without a prototype of its own.

## Content map

- Discussion

## Second-level links

### Configuring the Panel’s Appearance

- [title](https://developer.apple.com/documentation/appkit/nssavepanel/title) — The title of the panel. _(Apple Developer; expand on demand)_
- [prompt](https://developer.apple.com/documentation/appkit/nssavepanel/prompt) — The text to display in the default button. _(Apple Developer; expand on demand)_
- [message](https://developer.apple.com/documentation/appkit/nssavepanel/message) — The message text displayed in the panel. _(Apple Developer; expand on demand)_
- [nameFieldLabel](https://developer.apple.com/documentation/appkit/nssavepanel/namefieldlabel) — The label text displayed in front of the filename text field. _(Apple Developer; expand on demand)_
- [nameFieldStringValue](https://developer.apple.com/documentation/appkit/nssavepanel/namefieldstringvalue) — The user-editable filename currently shown in the name field. _(Apple Developer; expand on demand)_
- [directoryURL](https://developer.apple.com/documentation/appkit/nssavepanel/directoryurl) — The current directory shown in the panel. _(Apple Developer; expand on demand)_
- [showsTagField](https://developer.apple.com/documentation/appkit/nssavepanel/showstagfield) — A Boolean value that indicates whether the panel displays the Tags field. _(Apple Developer; expand on demand)_
- [tagNames](https://developer.apple.com/documentation/appkit/nssavepanel/tagnames) — The tag names that you want to include on a saved file. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nssavepanel/accessoryview)
- Captured: `2026-09-28T23:25:02+00:00`
- Payload SHA-256: `06b8eeadd21e07b6a3ea21e01b29d3da2c5a895e01f32448e3fd53777275dd87`
- Scope: expansion on demand of a page; absolute links above have not yet been covered.
