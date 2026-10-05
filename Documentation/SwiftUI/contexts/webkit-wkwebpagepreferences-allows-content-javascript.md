---
title: "WKWebpagePreferences.allowsContentJavaScript"
source_url: "https://developer.apple.com/documentation/webkit/wkwebpagepreferences/allowscontentjavascript"
source_identifier: "doc://com.apple.webkit/documentation/WebKit/WKWebpagePreferences/allowsContentJavaScript"
captured_at: "2026-09-27T13:15:08Z"
source_sha256: "6e84b1627ba82794f9dbc6964881f976a4f537712ecbfe12a605d5ce5289ce30"
source_etag: "\"2755-659024a232c5a\""
source_last_modified: "Fri, 14 Aug 2026 14:03:48 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# WKWebpagePreferences.allowsContentJavaScript

## Quick reference

- Scroll: Controls whether the JavaScript contained in the page can run in `WKWebView`.
- Module: WebKit.
- Relevance to Zforge: HTML preview follows the static behavior observed in Finder.
- Availability: macOS 11.0+, iOS/iPadOS/Mac Catalyst 14.0+ and visionOS 1.0+.
- Declaration: `var allowsContentJavaScript: Bool { get set }`.

## Summary

The default value is `true`. When `false`, WebKit does not execute JavaScript content code, including `<script>` inline elements, `javascript:` URLs, and referenced scripts. This allows rendering HTML and CSS without executing the scripts provided by the file.

## Practical implications

- Set `configuration.defaultWebpagePreferences.allowsContentJavaScript = false` before creating the preview view.
- Property restricts page scripts; does not restrict the loading of images, sources and style sheets referenced by the document. Finder was observed requesting a local HTML referenced HTTP image in the Gallery preview and Quick Look panel.
- The signature was checked with the SDK macOS 27.0 local.

## Content map

- Declaration and availability by platform.
- Default value and types of script affected when the property is disabled.

## Second-level links

- [WKWebpagePreferences](https://developer.apple.com/documentation/webkit/wkwebpagepreferences) — _Apple Developer; expand on demand_.
- [WebKit](https://developer.apple.com/documentation/webkit) — _Apple Developer; expand on demand_.
- [Bool](https://developer.apple.com/documentation/swift/bool) — _Apple Developer; expand on demand_.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/webkit/wkwebpagepreferences/allowscontentjavascript).
- Captured: `2026-09-27T13:15:08Z`.
- Payload SHA-256: `6e84b1627ba82794f9dbc6964881f976a4f537712ecbfe12a605d5ce5289ce30`.
- Scope: a DocC JSON page; the above absolute links have not yet been covered.
