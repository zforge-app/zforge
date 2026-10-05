---
title: "takeSnapshot(with:completionHandler:)"
source_url: "https://developer.apple.com/documentation/webkit/wkwebview/takesnapshot(with:completionhandler:)"
source_identifier: "doc://com.apple.webkit/documentation/WebKit/WKWebView/takeSnapshot(with:completionHandler:)"
captured_at: "2026-10-05T16:33:36.362505+00:00"
source_sha256: "18cdfa693021f6adac4add0d16663a12dce65493a2e4167007c08dfe365b3e22"
source_etag: "\"72db-659024a60d7d7\""
source_last_modified: "Fri, 14 Aug 2026 14:03:52 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Icon previews"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# takeSnapshot(with:completionHandler:)

## Quick reference

- Module: WebKit
- Availability recorded by the source: iOS 11.0, iPadOS 11.0, Mac Catalyst 13.1, macOS 10.13, visionOS 1.0.
- Zforge SDK verification: Xcode 27.0, macOS SDK 27.0, arm64; application target macOS 26.0.
- Declaration: `func takeSnapshot(with snapshotConfiguration: WKSnapshotConfiguration?, completionHandler: @escaping @MainActor @Sendable (UIImage?, (any Error)?) -> Void)`
- Declaration: `func takeSnapshot(configuration snapshotConfiguration: WKSnapshotConfiguration?) async throws -> UIImage`
- Declaration: `func takeSnapshot(with snapshotConfiguration: WKSnapshotConfiguration?, completionHandler: @escaping @MainActor @Sendable (NSImage?, (any Error)?) -> Void)`
- Declaration: `func takeSnapshot(configuration snapshotConfiguration: WKSnapshotConfiguration?) async throws -> NSImage`

## Summary and practical implications

Capture a static image of a web view using an asynchronous completion. Zforge restricts document scripts before loading, uses a bounded viewport, and checks request identity before publishing its result. The macOS SDK supplies NSImage in the completion.

## Content map

Declaration and discussion.

## Second-level links

- [Error](https://developer.apple.com/documentation/swift/error) — _Apple Developer; expand on demand_
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — _Apple Developer; expand on demand_
- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — _Apple Developer; expand on demand_
- [UIImage](https://developer.apple.com/documentation/uikit/uiimage) — _Apple Developer; expand on demand_
- [Void](https://developer.apple.com/documentation/swift/void) — _Apple Developer; expand on demand_
- [WKPDFConfiguration](https://developer.apple.com/documentation/webkit/wkpdfconfiguration) — _Apple Developer; expand on demand_
- [WKSnapshotConfiguration](https://developer.apple.com/documentation/webkit/wksnapshotconfiguration) — _Apple Developer; expand on demand_
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) — _Apple Developer; expand on demand_
- [WebKit](https://developer.apple.com/documentation/webkit) — _Apple Developer; expand on demand_
- [createPDF(configuration:completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebview/createpdf(configuration:completionhandler:)) — _Apple Developer; expand on demand_
- [createPDFWithConfiguration:completionHandler:](https://developer.apple.com/documentation/webkit/wkwebview/createpdfwithconfiguration:completionhandler:) — _Apple Developer; expand on demand_
- [createWebArchiveData(completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebview/createwebarchivedata(completionhandler:)) — _Apple Developer; expand on demand_
- [createWebArchiveDataWithCompletionHandler:](https://developer.apple.com/documentation/webkit/wkwebview/createwebarchivedatawithcompletionhandler:) — _Apple Developer; expand on demand_
- [pdf(configuration:)](https://developer.apple.com/documentation/webkit/wkwebview/pdf(configuration:)) — _Apple Developer; expand on demand_
- [printOperation(with:)](https://developer.apple.com/documentation/webkit/wkwebview/printoperation(with:)) — _Apple Developer; expand on demand_
- [takeSnapshot(with:completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebview/takesnapshot(with:completionhandler:)) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/webkit/wkwebview/takesnapshot(with:completionhandler:))
- Captured: `2026-10-05T16:33:36.362505+00:00`
- Payload SHA-256: `18cdfa693021f6adac4add0d16663a12dce65493a2e4167007c08dfe365b3e22`
- Scope: one page; secondary links were not traversed.
