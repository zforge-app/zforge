---
title: "Views in Menu Items"
source_url: "https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/ViewsInMenuItems.html"
source_identifier: "https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/ViewsInMenuItems.html"
captured_at: "2026-10-03T17:20:42.555896+00:00"
source_sha256: "ae53df9fa1083c999122091540e08f7e2a2f3ca8ea6f3b7b94f9c17853b85615"
source_etag: null
source_last_modified: "Fri, 30 Jan 2026 23:11:39 GMT"
source_format: "text/html"
depth: 1
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Views in Menu Items

## Summary

`NSMenuItem.view` allows a custom line in menus AppKit. The menu delegates the drawing to the view, including title and status. Mouse events reach the view; keyboard is not automatically routed. The size part of the view frame, and `.width` allows you to fill in the menu width. The view comes in/out of the window when opening/closing the menu; Tracking must follow that cycle. Size changes during tracking are not supported. Events with a maintained button can reach as `mouseDragged`.

## Application in Zforge

The fast line of tags uses seven `NSButton`s with circles, hover tracking and accessibility. The second line remains a conventional `NSMenuItem`, with symbol `tag`, preserving keyboard navigation for the full editor. Quick click closes tracking before changing metadata. APIs were checked at SDK macOS 27.0; They don't use Finder's private APIs.

## Secondary links

- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/index.html
- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/RevisionHistory.html
- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/DisplayContextMenu.html
- https://developer.apple.com/library/archive/Resources/1282/CSS/screen.css
- https://developer.apple.com/library/archive/Resources/1282/CSS/feedback.css
- https://developer.apple.com/documentation/appkit/nsmenuitem/1514835-view
- https://developer.apple.com/documentation/appkit/nsview/1483360-needsdisplay
- https://developer.apple.com/documentation/appkit/nsview/1483487-display
- https://developer.apple.com/documentation/appkit/nsview/1483329-viewdidmovetowindow
- http://www.apple.com/legal/internet-services/terms/site.html
- http://www.apple.com/privacy/
- https://developer.apple.com/bugreporter/
- http://www.apple.com/legal/policies/ideas.html

## Provenance

Apple page archived, updated in 2014-07-15, captured by the URL above; hash do HTML integral no front matter. The rules were still checked in the compilation with the current SDK.

Note SDK macOS 27.0 (`NSMenuItem.h`): Menu images can be hidden by default. The Edit Tags item defines `preferredImageVisibility = .visible`, with a protected availability for macOS 27, to keep the symbol requested; macOS 26 maintains previous behavior.
