---
title: "Accessible navigation"
source_url: "https://developer.apple.com/documentation/swiftui/accessible-navigation"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Accessible-navigation"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "0446650c211c3312c555bd2c3f0b178892cb61245bd0939eef633e4734f1faa2"
source_etag: "W/\"9046e06c23bc3c9b5164cfae5f12da28\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Accessibility"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Accessible navigation

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Enable users to navigate to specific user interface elements using rotors.

An accessibility rotor is a shortcut that enables users to quickly navigate to specific elements of the user interface, and, optionally, to specific ranges of text within those elements. The system automatically provides rotors for many navigable elements, but you can supply additional rotors for specific purposes, or replace system rotors when they don’t automatically pick up off-screen elements, like those far down in a LazyVStack or a List. For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack) — A view that arranges its children in a line that grows vertically, creating items only as needed. _(Apple Developer; expand on demand)_
- [List](https://developer.apple.com/documentation/swiftui/list) — A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members. _(Apple Developer; expand on demand)_
- [Accessibility](https://developer.apple.com/design/Human-Interface-Guidelines/accessibility#Navigation) — Accessible user interfaces empower everyone to have a great experience with your app or game. _(Apple Developer; expand on demand)_

### Working with rotors

- [accessibilityRotor(_:entries:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrotor(_:entries:)) — Create an Accessibility Rotor with the specified user-visible label, and entries generated from the content closure. _(Apple Developer; expand on demand)_
- [accessibilityRotor(_:entries:entryID:entryLabel:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrotor(_:entries:entryid:entrylabel:)) — Create an Accessibility Rotor with the specified user-visible label and entries. _(Apple Developer; expand on demand)_
- [accessibilityRotor(_:entries:entryLabel:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrotor(_:entries:entrylabel:)) — Create an Accessibility Rotor with the specified user-visible label and entries. _(Apple Developer; expand on demand)_
- [accessibilityRotor(_:textRanges:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrotor(_:textranges:)) — Create an Accessibility Rotor with the specified user-visible label and entries for each of the specified ranges. The Rotor will be attached to the… _(Apple Developer; expand on demand)_

### Creating rotors

- [AccessibilityRotorContent](https://developer.apple.com/documentation/swiftui/accessibilityrotorcontent) — Content within an accessibility rotor. _(Apple Developer; expand on demand)_
- [AccessibilityRotorContentBuilder](https://developer.apple.com/documentation/swiftui/accessibilityrotorcontentbuilder) — Result builder you use to generate rotor entry content. _(Apple Developer; expand on demand)_
- [AccessibilityRotorEntry](https://developer.apple.com/documentation/swiftui/accessibilityrotorentry) — A struct representing an entry in an Accessibility Rotor. _(Apple Developer; expand on demand)_

### Replacing system rotors

- [AccessibilitySystemRotor](https://developer.apple.com/documentation/swiftui/accessibilitysystemrotor) — Designates a Rotor that replaces one of the automatic, system-provided Rotors with a developer-provided Rotor. _(Apple Developer; expand on demand)_

### Configuring rotors

- [accessibilityRotorEntry(id:in:)](https://developer.apple.com/documentation/swiftui/view/accessibilityrotorentry(id:in:)) — Defines an explicit identifier tying an Accessibility element for this view to an entry in an Accessibility Rotor. _(Apple Developer; expand on demand)_
- [accessibilityLinkedGroup(id:in:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylinkedgroup(id:in:)) — Links multiple accessibility elements so that the user can quickly navigate from one element to another, even when the elements are not near each… _(Apple Developer; expand on demand)_
- [accessibilitySortPriority(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitysortpriority(_:)) — Sets the sort priority order for this view’s accessibility element, relative to other elements at the same level. _(Apple Developer; expand on demand)_

### Accessibility

- [Accessibility fundamentals](swiftui-accessibility-fundamentals.md) — Make your SwiftUI apps accessible to everyone, including people with disabilities. _(local context)_
- [Accessible appearance](swiftui-accessible-appearance.md) — Enhance the legibility of content in your app’s interface. _(local context)_
- [Accessible controls](swiftui-accessible-controls.md) — Improve access to actions that your app can undertake. _(local context)_
- [Accessible descriptions](swiftui-accessible-descriptions.md) — Describe interface elements to help people understand what they represent. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/accessible-navigation)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `0446650c211c3312c555bd2c3f0b178892cb61245bd0939eef633e4734f1faa2`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
