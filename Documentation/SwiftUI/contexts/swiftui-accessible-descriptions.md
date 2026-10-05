---
title: "Accessible descriptions"
source_url: "https://developer.apple.com/documentation/swiftui/accessible-descriptions"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Accessible-descriptions"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "b79c0655418d7ffcc8e6e3fb400b75628b02fd9d4228b277128802c4728fb977"
source_etag: "W/\"fac42024b8882698ba5a5e7dcaf82ec3\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Accessibility"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Accessible descriptions

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Describe interface elements to help people understand what they represent.

SwiftUI can often infer some information about your user interface elements, but you can use accessibility modifiers to provide even more information for users that need it. For design guidance, see Accessibility in the Accessibility section of the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Accessibility](https://developer.apple.com/design/Human-Interface-Guidelines/accessibility#Content-descriptions) — Accessible user interfaces empower everyone to have a great experience with your app or game. _(Apple Developer; expand on demand)_

### Applying labels

- [accessibilityLabel(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)) — Adds a label to the view that describes its contents. _(Apple Developer; expand on demand)_
- [accessibilityLabel(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:isenabled:)) — Adds a label to the view that describes its contents. _(Apple Developer; expand on demand)_
- [accessibilityLabel(content:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(content:)) — Adds a label to the view that describes its contents. _(Apple Developer; expand on demand)_
- [accessibilityInputLabels(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityinputlabels(_:)) — Sets alternate input labels with which users identify a view. _(Apple Developer; expand on demand)_
- [accessibilityInputLabels(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityinputlabels(_:isenabled:)) — Sets alternate input labels with which users identify a view. _(Apple Developer; expand on demand)_
- [accessibilityLabeledPair(role:id:in:)](https://developer.apple.com/documentation/swiftui/view/accessibilitylabeledpair(role:id:in:)) — Pairs an accessibility element representing a label with the element for the matching content. _(Apple Developer; expand on demand)_
- [AccessibilityLabeledPairRole](https://developer.apple.com/documentation/swiftui/accessibilitylabeledpairrole) — The role of an accessibility element in a label / content pair. _(Apple Developer; expand on demand)_

### Describing values

- [accessibilityValue(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:)) — Adds a textual description of the value that the view contains. _(Apple Developer; expand on demand)_
- [accessibilityValue(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:isenabled:)) — Adds a textual description of the value that the view contains. _(Apple Developer; expand on demand)_

### Describing content

- [accessibilityTextContentType(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitytextcontenttype(_:)) — Sets an accessibility text content type. _(Apple Developer; expand on demand)_
- [accessibilityHeading(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityheading(_:)) — Sets the accessibility level of this heading. _(Apple Developer; expand on demand)_
- [AccessibilityHeadingLevel](https://developer.apple.com/documentation/swiftui/accessibilityheadinglevel) — The hierarchy of a heading in relation to other headings. _(Apple Developer; expand on demand)_
- [AccessibilityTextContentType](https://developer.apple.com/documentation/swiftui/accessibilitytextcontenttype) — Textual context that assistive technologies can use to improve the presentation of spoken text. _(Apple Developer; expand on demand)_

### Describing charts

- [accessibilityChartDescriptor(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilitychartdescriptor(_:)) — Adds a descriptor to a View that represents a chart to make the chart’s contents accessible to all users. _(Apple Developer; expand on demand)_
- [AXChartDescriptorRepresentable](https://developer.apple.com/documentation/swiftui/axchartdescriptorrepresentable) — A type to generate an object that you use to provide information about a chart and its data for an accessible experience in VoiceOver… _(Apple Developer; expand on demand)_

### Adding custom descriptions

- [accessibilityCustomContent(_:_:importance:)](https://developer.apple.com/documentation/swiftui/view/accessibilitycustomcontent(_:_:importance:)) — Add additional accessibility information to the view. _(Apple Developer; expand on demand)_
- [AccessibilityCustomContentKey](https://developer.apple.com/documentation/swiftui/accessibilitycustomcontentkey) — Key used to specify the identifier and label associated with an entry of additional accessibility information. _(Apple Developer; expand on demand)_

### Assigning traits to content

- [accessibilityAddTraits(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityaddtraits(_:)) — Adds the given traits to the view. _(Apple Developer; expand on demand)_
- [accessibilityRemoveTraits(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityremovetraits(_:)) — Removes the given traits from this view. _(Apple Developer; expand on demand)_
- [AccessibilityTraits](https://developer.apple.com/documentation/swiftui/accessibilitytraits) — A set of accessibility traits that describe how an element behaves. _(Apple Developer; expand on demand)_

### Offering hints

- [accessibilityHint(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityhint(_:)) — Communicates to the user what happens after performing the view’s action. _(Apple Developer; expand on demand)_
- [accessibilityHint(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/accessibilityhint(_:isenabled:)) — Communicates to the user what happens after performing the view’s action. _(Apple Developer; expand on demand)_

### Configuring VoiceOver

- [speechAdjustedPitch(_:)](https://developer.apple.com/documentation/swiftui/view/speechadjustedpitch(_:)) — Raises or lowers the pitch of spoken text. _(Apple Developer; expand on demand)_
- [speechAlwaysIncludesPunctuation(_:)](https://developer.apple.com/documentation/swiftui/view/speechalwaysincludespunctuation(_:)) — Sets whether VoiceOver should always speak all punctuation in the text view. _(Apple Developer; expand on demand)_
- [speechAnnouncementsQueued(_:)](https://developer.apple.com/documentation/swiftui/view/speechannouncementsqueued(_:)) — Controls whether to queue pending announcements behind existing speech rather than interrupting speech in progress. _(Apple Developer; expand on demand)_
- [speechSpellsOutCharacters(_:)](https://developer.apple.com/documentation/swiftui/view/speechspellsoutcharacters(_:)) — Sets whether VoiceOver should speak the contents of the text view character by character. _(Apple Developer; expand on demand)_

### Accessibility

- [Accessibility fundamentals](swiftui-accessibility-fundamentals.md) — Make your SwiftUI apps accessible to everyone, including people with disabilities. _(local context)_
- [Accessible appearance](swiftui-accessible-appearance.md) — Enhance the legibility of content in your app’s interface. _(local context)_
- [Accessible controls](swiftui-accessible-controls.md) — Improve access to actions that your app can undertake. _(local context)_
- [Accessible navigation](swiftui-accessible-navigation.md) — Enable users to navigate to specific user interface elements using rotors. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/accessible-descriptions)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `b79c0655418d7ffcc8e6e3fb400b75628b02fd9d4228b277128802c4728fb977`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
