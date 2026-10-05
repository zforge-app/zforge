---
title: "Creating your app icon using Icon Composer"
source_url: "https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer"
source_identifier: "doc://com.apple.Xcode/documentation/Xcode/creating-your-app-icon-using-icon-composer"
captured_at: "2026-10-02T01:13:11+00:00"
source_sha256: "3458352b0e40d4488d5e31d413d47ece2b150bcddf4ab9b406f34865d73f728e"
source_etag: "\"d9ba-65b3a4494b5cd\""
source_last_modified: "Fri, 11 Sep 2026 19:41:17 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Xcode"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Creating your app icon using Icon Composer

Standard context of official Xcode orientation for `.icon` files produced by Icon Composer.

## Quick reference

- Roll: integration article and layer icon creation.
- Module: Xcode / Icon Composer.
- Relevance to Zforge: direct, because target macOS passes to use a file `.icon` exported by the user.
- Availability: Xcode with suporte a Icon Composer; the page describes iOS, iPadOS, macOS, watchOS and previous versions with art derived by Xcode.
- Declaration: there is no code API; the integration uses the `.icon` file in the project and the icon name in target.

## Summary

An Icon Composer file brings together layers and appearance variants. To use it, add it to the project and select as the target Icon App the filename without the extension. Xcode compiles the appropriate versions for platforms, appearances and sizes. In the current Xcode, this file replaces the previous icon catalog as the source of the main icon. Apple recommends exporting layers with ordered names, removing effects that Icon Composer applies, and not exporting a clipping mask.

## Practical implications

- `Zforge/zforge_icon.icon` must belong to target and `ASSETCATALOG_COMPILER_APPICON_NAME` must be `zforge_icon` in the settings used.
- The app must not reassign the old icon at runtime, as this replaces the icon provided by the bundle.
- Check the compiled bundle (`zforge_icon.icns`, `Assets.car` and `CFBundleIconName`) and the visual appearance in Finder/Dock. A build confirms compilation, not all visual variants.

## Content map

- Preparation and export of layers.
- Creating the document in Icon Composer and customizing appearances.
- File inclusion `.icon` in project and name selection in target.
- Tests on devices and appearances.

## Second-level links

### Xcode and design

- [Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) — _Apple Developer; expand on demand_.
- [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) — _Apple Developer; expand on demand_.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) — _Apple Developer; expand on demand_.
- [Apple Design Resources](https://developer.apple.com/design/resources/) — _Apple Developer; expand on demand_.
- [Icon Composer](https://developer.apple.com/icon-composer) — _Apple Developer; expand on demand_.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
- Captured: `2026-10-02T01:13:11+00:00`.
- Payload SHA-256: `3458352b0e40d4488d5e31d413d47ece2b150bcddf4ab9b406f34865d73f728e`.
- Scope: a page in JSON; the above absolute links have not yet been covered.
