---
title: "Pop-up buttons"
source_url: "https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons"
source_identifier: "doc://com.apple.HIG/design/Human-Interface-Guidelines/pop-up-buttons"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "64ef3e8079e3a1dd2742d377fbf98f7d141cca8798d2dd1985f71b5c24043a4d"
source_etag: "\"4a55-658580f133047\""
source_last_modified: "Thu, 06 Aug 2026 02:58:13 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Human Interface Guidelines"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Pop-up buttons

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: article
- Module: Not specified
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** A pop-up button displays a menu of mutually exclusive options.

After people choose an item from a pop-up button’s menu, the menu closes, and the button can update its content to indicate the current selection. Use a pop-up button to present a flat list of mutually exclusive options or states. A pop-up button helps people make a choice that affects their content or the surrounding view. Use a pull-down button instead if you need to: Offer a list of actions Let people select multiple items Include a submenu Provide a useful default selection. A pop-up button can update its content to identify the current selection, but if people haven’t made a selection yet, it shows the default item you specify. When possible, make the default selection an item that most people are likely to want. Give people a way to predict a pop-up button’s options without opening it. For example, you can use an introductory label or a button label…

## Practical implications

- An introductory label can explain the selector without needing to be positioned laterally.
- Pop-up buttons are suitable for lists of mutually exclusive options and save space in the modal.

## Content map

- Best practices
- Platform considerations
- iPadOS
- Resources
- Related
- Developer documentation
- Change log

## Second-level links

### Overview and featured references

- [pull-down button](https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons) — _Apple Developer; expand on demand_
- [Pull-down buttons](https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons) — A pull-down button displays a menu of items or actions that directly relate to the button’s purpose. _(Apple Developer; expand on demand)_
- [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) — A button initiates an instantaneous action. _(Apple Developer; expand on demand)_
- [Menus](https://developer.apple.com/design/human-interface-guidelines/menus) — A menu reveals its options when people interact with it, making it a space-efficient way to present commands in your app or game. _(Apple Developer; expand on demand)_
- [MenuPickerStyle](https://developer.apple.com/documentation/swiftui/menupickerstyle) — A picker style that presents the options as a menu when the user presses a button, or as a submenu when nested within a… _(Apple Developer; expand on demand)_
- [changesSelectionAsPrimaryAction](https://developer.apple.com/documentation/uikit/uibutton/changesselectionasprimaryaction) — A Boolean value that indicates whether the button tracks a selection, either through a menu or a toggle. _(Apple Developer; expand on demand)_
- [NSPopUpButton](https://developer.apple.com/documentation/appkit/nspopupbutton) — A control for selecting an item from a list. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons)
- Captured: `2026-09-28T23:25:02+00:00`
- Payload SHA-256: `64ef3e8079e3a1dd2742d377fbf98f7d141cca8798d2dd1985f71b5c24043a4d`
- Scope: expansion on demand of a page; absolute links above have not yet been covered.
