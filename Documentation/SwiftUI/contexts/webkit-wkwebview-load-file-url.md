---
title: "loadFileURL(_:allowingReadAccessTo:)"
source_url: "https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)"
source_identifier: "doc://com.apple.webkit/documentation/WebKit/WKWebView/loadFileURL(_:allowingReadAccessTo:)"
captured_at: "2026-09-27T12:39:12Z"
source_sha256: "c99ebd3eafb987060d1ee96ffefd20ab4130c0ee0899cfd6c401353bbaeca8fd"
source_etag: "\"76f4-65b3b266b901c\""
source_last_modified: "Fri, 11 Sep 2026 20:44:26 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# loadFileURL(_:allowingReadAccessTo:)

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Roll: `WKWebView` method to load web content from a local file.
- Module: WebKit.
- Relevance to Zforge: direta; renders the local HTML preview and its relative features.
- Availability: macOS 10.11+, in addition to iOS 9+, iPadOS 9+, Mac Catalyst 13.1+ and visionOS 1+.
- Declaration: `func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation?`

## Summary

The first argument must be a file URL with web content. The second must be a non-empty file URL or directory that delimits what WebKit can read. Using the document URL itself prevents reading other files; use a directory lets you load related features. The method returns a navigation to track progress.

## Practical implications

- For an HTML with CSS and relative images, grant only the folder containing the document, preserving the necessary access to neighboring resources.
- The API delimits the reading granted by `WKWebView`; the application file access authorization remains the responsibility of Zforge.
- The signature is in the SDK macOS 27.0 local and the signed build Debug of the Zforge compiled using this call in 2026-09-27.

## Content map

- Declaration and availability by platform.
- File parameters and read scope.
- Value returned and note on request assignment.
- Related loading methods.

## Second-level links

### Related types

- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — _Apple Developer; expand on demand_.
- [URL](https://developer.apple.com/documentation/foundation/url) — _Apple Developer; expand on demand_.
- [NSURLRequest.Attribution.developer](https://developer.apple.com/documentation/foundation/nsurlrequest/attribution-swift.enum/developer) — _Apple Developer; expand on demand_.
- [Technologies](https://developer.apple.com/documentation/technologies) — _Apple Developer; expand on demand_.
- [WebKit](https://developer.apple.com/documentation/webkit) — _Apple Developer; expand on demand_.
- [WKNavigation](https://developer.apple.com/documentation/webkit/wknavigation) — _Apple Developer; expand on demand_.
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) — _Apple Developer; expand on demand_.

### Loading and progress

- [estimatedProgress](https://developer.apple.com/documentation/webkit/wkwebview/estimatedprogress) — _Apple Developer; expand on demand_.
- [isLoading](https://developer.apple.com/documentation/webkit/wkwebview/isloading) — _Apple Developer; expand on demand_.
- [load(_:) — request](https://developer.apple.com/documentation/webkit/wkwebview/load(_:)-4xx8m) — _Apple Developer; expand on demand_.
- [load(_:) — data](https://developer.apple.com/documentation/webkit/wkwebview/load(_:)-5siv6) — _Apple Developer; expand on demand_.
- [load(_:mimeType:characterEncodingName:baseURL:)](https://developer.apple.com/documentation/webkit/wkwebview/load(_:mimetype:characterencodingname:baseurl:)) — _Apple Developer; expand on demand_.
- [loadFileRequest(_:allowingReadAccessTo:)](https://developer.apple.com/documentation/webkit/wkwebview/loadfilerequest(_:allowingreadaccessto:)) — _Apple Developer; expand on demand_.
- [loadHTMLString(_:baseURL:)](https://developer.apple.com/documentation/webkit/wkwebview/loadhtmlstring(_:baseurl:)) — _Apple Developer; expand on demand_.
- [loadSimulatedRequest(_:response:responseData:)](https://developer.apple.com/documentation/webkit/wkwebview/loadsimulatedrequest(_:response:responsedata:)) — _Apple Developer; expand on demand_.
- [loadSimulatedRequest(_:responseHTML:)](https://developer.apple.com/documentation/webkit/wkwebview/loadsimulatedrequest(_:responsehtml:)) — _Apple Developer; expand on demand_.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)).
- Captured: `2026-09-27T12:39:12Z`.
- Payload SHA-256: `c99ebd3eafb987060d1ee96ffefd20ab4130c0ee0899cfd6c401353bbaeca8fd`.
- Scope: a DocC JSON page; the above absolute links have not yet been covered.
