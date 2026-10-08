---
title: "App Shortcuts"
source_url: "https://developer.apple.com/documentation/appintents/app-shortcuts"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/app-shortcuts"
captured_at: "2026-10-07T14:23:22.620934+00:00"
source_sha256: "c952170c359851f92dedbef0d852dda2bdc80dc9bf57b8a37219bc3ab4ca33ea"
source_etag: null
source_last_modified: "Fri, 14 Aug 2026 14:10:15 GMT"
source_format: "application/json"
depth: 1
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App Shortcuts

## Quick reference

- Role: framework topic collection.
- Module: AppIntents.
- Relevance: native macOS app action discovery.
- Availability: collection does not specify one deployment floor; verify individual symbols. Zforge uses the macOS 27 SDK to compile for macOS 26.0.

## Summary

An AppShortcutsProvider publishes ready-to-use shortcuts with invocation phrases, titles and icons over app intents.

## Practical implications

Share operation services with MCP and the UI. Localize user-facing action metadata and phrases. Compilation and extracted metadata establish registration inputs, not successful Siri execution. Test actual supported system surfaces separately.

## Content map

- App Shortcut management
- App Shortcut definition
- App Shortcut options
- App Shortcut parameter presentation
- Buttons
- Tip views

## Second-level links

- [Adopting App Intents to support system experiences](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences) — expand on demand
- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [AppShortcut](https://developer.apple.com/documentation/appintents/appshortcut) — expand on demand
- [AppShortcutOptionsCollection](https://developer.apple.com/documentation/appintents/appshortcutoptionscollection) — expand on demand
- [AppShortcutOptionsCollectionProtocol](https://developer.apple.com/documentation/appintents/appshortcutoptionscollectionprotocol) — expand on demand
- [AppShortcutOptionsCollectionSpecification](https://developer.apple.com/documentation/appintents/appshortcutoptionscollectionspecification) — expand on demand
- [AppShortcutOptionsCollectionSpecificationBuilder](https://developer.apple.com/documentation/appintents/appshortcutoptionscollectionspecificationbuilder) — expand on demand
- [AppShortcutParameterPresentation](https://developer.apple.com/documentation/appintents/appshortcutparameterpresentation) — expand on demand
- [AppShortcutParameterPresentationSummary](https://developer.apple.com/documentation/appintents/appshortcutparameterpresentationsummary) — expand on demand
- [AppShortcutParameterPresentationSummaryString](https://developer.apple.com/documentation/appintents/appshortcutparameterpresentationsummarystring) — expand on demand
- [AppShortcutParameterPresentationTitle](https://developer.apple.com/documentation/appintents/appshortcutparameterpresentationtitle) — expand on demand
- [AppShortcutParameterPresentationTitleString](https://developer.apple.com/documentation/appintents/appshortcutparameterpresentationtitlestring) — expand on demand
- [AppShortcutPhrase](https://developer.apple.com/documentation/appintents/appshortcutphrase) — expand on demand
- [AppShortcutPhraseToken](https://developer.apple.com/documentation/appintents/appshortcutphrasetoken) — expand on demand
- [AppShortcutsBuilder](https://developer.apple.com/documentation/appintents/appshortcutsbuilder) — expand on demand
- [AppShortcutsContent](https://developer.apple.com/documentation/appintents/appshortcutscontent) — expand on demand
- [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider) — expand on demand
- [Apple Intelligence and Siri AI](appintents-siri-ai.md) — expand on demand
- [Focus](https://developer.apple.com/documentation/appintents/focus) — expand on demand
- [Hardware interactions](https://developer.apple.com/documentation/appintents/hardware-interactions) — expand on demand
- [NSAppIconActionTintColorName](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleicons/cfbundleprimaryicon/nsappiconactiontintcolorname) — expand on demand
- [NSAppIconComplementingColorNames](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleicons/cfbundleprimaryicon/nsappiconcomplementingcolornames) — expand on demand
- [NegativeAppShortcutPhrase](https://developer.apple.com/documentation/appintents/negativeappshortcutphrase) — expand on demand
- [NegativeAppShortcutPhrases](https://developer.apple.com/documentation/appintents/negativeappshortcutphrases) — expand on demand
- [ShortcutTileColor](https://developer.apple.com/documentation/appintents/shortcuttilecolor) — expand on demand
- [ShortcutsLink](appintents-shortcutslink.md) — expand on demand
- [ShortcutsLinkStyle](https://developer.apple.com/documentation/appintents/shortcutslinkstyle) — expand on demand
- [ShortcutsUIButton](https://developer.apple.com/documentation/appintents/shortcutsuibutton) — expand on demand
- [SiriTipUIView](https://developer.apple.com/documentation/appintents/siritipuiview) — expand on demand
- [SiriTipView](https://developer.apple.com/documentation/appintents/siritipview) — expand on demand
- [SiriTipViewStyle](https://developer.apple.com/documentation/appintents/siritipviewstyle) — expand on demand
- [Spotlight integration](https://developer.apple.com/documentation/appintents/spotlight) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [Visual intelligence](https://developer.apple.com/documentation/appintents/visual-intelligence) — expand on demand
- [Widgets, Live Activities, and Controls](https://developer.apple.com/documentation/appintents/widgets-live-activities-and-controls) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/app-shortcuts).
- Captured: `2026-10-07T14:23:22.620934+00:00`.
- Payload SHA-256: `c952170c359851f92dedbef0d852dda2bdc80dc9bf57b8a37219bc3ab4ca33ea`.
- Scope: one DocC JSON page; secondary links remain unvisited.
