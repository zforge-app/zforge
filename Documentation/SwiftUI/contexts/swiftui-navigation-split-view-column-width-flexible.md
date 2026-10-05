---
title: "navigationSplitViewColumnWidth(min:ideal:max:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/navigationSplitViewColumnWidth(min:ideal:max:)"
captured_at: "2026-07-18T02:53:50Z"
source_sha256: "6aaf33d60f84d9af6927fcbfb752f2fb5c7a1537b0afea85eeddfea23473d3b3"
source_etag: "W/\"ec71fe1bbeefcc0c36babfa35669b393\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# navigationSplitViewColumnWidth(min:ideal:max:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Roll: `View` modifier
- Module: SwiftUI
- Relevance to Zforge: direta; expresses the flexible sidebar width preferences of `NavigationSplitView`.
- Availability: macOS 13.0+; other platforms according to the official page.
- Declaration: `nonisolated func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View`

## Summary

Set a preferred flexible width for the column containing the view. `min`, `ideal` and `max` are container preferences, and SwiftUI may use another width when the display environment does not support the requested value. The modifier does not offer binding for effective width nor defines which panel absorbs changes in window size.

## Practical implications

- Keep this modifier to communicate column metrics to layout SwiftUI.
- Do not treat it as a state source for the current position of the splitter.
- When the macOS requires control over the automatic space distribution, complement the configuration in the `NSSplitViewItem` underlying by a deliberate AppKit bridge.
- Signature and availability confirmed also in SDK macOS 26.5 of the local Xcode.

## Content map

- Declaration
- Parameters
- Discussion and example
- Platforms that allow column resizing

## Second-level links

### Column navigation

- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) — _Apple Developer; expand on demand_
- [navigationSplitViewColumnWidth(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:)) — _Apple Developer; expand on demand_
- [navigationSplitViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewstyle(_:)) — _Apple Developer; expand on demand_
- [NavigationSplitViewVisibility](https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:))
- Captured: `2026-07-18T02:53:50Z`
- Payload SHA-256: `6aaf33d60f84d9af6927fcbfb752f2fb5c7a1537b0afea85eeddfea23473d3b3`
- Scope: one page; the above absolute links have not yet been covered.
