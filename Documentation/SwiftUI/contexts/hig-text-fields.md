---
title: "Text fields"
source_url: "https://developer.apple.com/design/human-interface-guidelines/text-fields"
source_identifier: "doc://com.apple.HIG/design/Human-Interface-Guidelines/text-fields"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "18324cc7181a498b9324a1980231260785ee427eb9ae48f775bfa06a96153d40"
source_etag: "\"6425-658580f133047\""
source_last_modified: "Thu, 06 Aug 2026 02:58:13 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Human Interface Guidelines"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Text fields

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: article
- Module: Not specified
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** A text field is a rectangular area in which people enter or edit small, specific pieces of text.

Use a text field to request a small amount of information, such as a name or an email address. To let people input larger amounts of text, use a Text views instead. Show a hint in a text field to help communicate its purpose. A text field can contain placeholder text — such as “Email” or “Password” — when there’s no other text in the field. Because placeholder text disappears when people start typing, it can also be useful to include a separate label describing the field to remind people of its purpose. Use secure text fields to hide private data. Always use a secure text field when your app asks for sensitive data, such as a password. For developer guidance, see SecureField. To the extent possible, match the size of a text field to the quantity of anticipated text. The size of a text field helps people visually gauge…

## Practical implications

- Introductory labels shall remain clearly associated with field; consistent widths help organize forms.
- Password field needs to be secure; check tab order and spacing when expanding the panel.

## Content map

- Best practices
- Platform considerations
- iOS, iPadOS
- macOS
- watchOS
- Resources
- Related
- Developer documentation
- Change log

## Second-level links

### Overview and featured references

- [Text views](https://developer.apple.com/design/human-interface-guidelines/text-views) — A text view displays multiline, styled text content, which can optionally be editable. _(Apple Developer; expand on demand)_
- [SecureField](https://developer.apple.com/documentation/swiftui/securefield) — A control into which people securely enter private text. _(Apple Developer; expand on demand)_
- [tooltip](https://developer.apple.com/design/human-interface-guidelines/offering-help#macOS-visionOS) — _Apple Developer; expand on demand_
- [Virtual keyboards](https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards) — On devices without physical keyboards, the system offers various types of virtual keyboards people can use to enter data. _(Apple Developer; expand on demand)_
- [Combo boxes](https://developer.apple.com/design/human-interface-guidelines/combo-boxes) — A combo box combines a text field with a pull-down button in a single control. _(Apple Developer; expand on demand)_
- [Entering data](https://developer.apple.com/design/human-interface-guidelines/entering-data) — When you need information from people, design ways that make it easy for them to provide it without making mistakes. _(Apple Developer; expand on demand)_
- [TextField](https://developer.apple.com/documentation/swiftui/textfield) — A control that displays an editable text interface. _(Apple Developer; expand on demand)_
- [UITextField](https://developer.apple.com/documentation/uikit/uitextfield) — An object that displays an editable text area in your interface. _(Apple Developer; expand on demand)_
- [NSTextField](https://developer.apple.com/documentation/appkit/nstextfield) — Text the user can select or edit to send an action message to a target when the user presses the Return key. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/design/human-interface-guidelines/text-fields)
- Captured: `2026-09-28T23:25:02+00:00`
- Payload SHA-256: `18324cc7181a498b9324a1980231260785ee427eb9ae48f775bfa06a96153d40`
- Scope: expansion on demand of a page; absolute links above have not yet been covered.
