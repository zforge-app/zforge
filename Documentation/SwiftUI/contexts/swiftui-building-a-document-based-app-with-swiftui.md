---
title: "Building a document-based app with SwiftUI"
source_url: "https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Building-a-document-based-app-with-SwiftUI"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "2cb0e6fd2d9ea5e5b695e1e1b6a035553ed73b520d0eaddcf21f504915c6f385"
source_etag: "W/\"ee865747b39d560b85016a00c3214660\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Featured samples"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Building a document-based app with SwiftUI

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Sample Code
- Module: SwiftUI
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, Xcode 16.0+

## Summary

**Official summary:** Create, save, and open documents in a multiplatform app.

The Writing App sample builds a document-based app for iOS, iPadOS, and macOS. In the app definition, it has a DocumentGroup scene, and its document type conforms to the FileDocument protocol. People can create a writing app document, modify the title and contents of the document, and read the story in focus mode. To build and run this sample on your device, select your development team for the project’s target using these steps: Open the sample with the latest version of Xcode. Select the top-level project. For the project’s target, choose your team from the Team pop-up menu in the Signing & Capabilities pane to let Xcode automatically manage your provisioning profile. A document-based SwiftUI app returns a scene from its property. The parameter that an app supplies to the document group’s init(newDocument:editor:) initializer conforms to either FileDocument or ReferenceFileDocument. In this sample, the document type conforms to . The…

## Content map

- Overview
- Configure the sample code project
- Define the app’s scene
- Customize the iOS and iPadOS launch experience
- Create the data model
- Adopt the file document protocol
- Export a custom document type
- See Also
- Related samples
- Related articles
- Related videos

## Second-level links

### Overview and featured references

- [DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup) — A scene that enables support for opening, creating, and saving documents. _(Apple Developer; expand on demand)_
- [FileDocument](https://developer.apple.com/documentation/swiftui/filedocument) — A type that you use to serialize documents to and from file. _(Apple Developer; expand on demand)_
- [init(newDocument:editor:)](https://developer.apple.com/documentation/swiftui/documentgroup/init(newdocument:editor:)-4toe2) — Creates a document group for creating and editing file documents. _(Apple Developer; expand on demand)_
- [ReferenceFileDocument](https://developer.apple.com/documentation/swiftui/referencefiledocument) — A type that you use to serialize reference type documents to and from file. _(Apple Developer; expand on demand)_
- [NewDocumentButton](https://developer.apple.com/documentation/swiftui/newdocumentbutton) — A button that creates and opens new documents. _(Apple Developer; expand on demand)_
- [init(_:backgroundStyle:_:backgroundAccessoryView:overlayAccessoryView:)](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene/init(_:backgroundstyle:_:backgroundaccessoryview:overlayaccessoryview:)-2d13c) — Creates a launch scene for document-based applications with a title, a background style, a set of actions, and background and overlay accessory views. _(Apple Developer; expand on demand)_
- [init(_:_:background:)](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene/init(_:_:background:)-2iefz) — Creates a launch scene for document-based applications with a title, a set of actions, and a background. _(Apple Developer; expand on demand)_
- [init(_:_:background:backgroundAccessoryView:)](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene/init(_:_:background:backgroundaccessoryview:)-1valf) — Creates a launch scene for document-based applications with a title, a set of actions, a background, and a background accessory view. _(Apple Developer; expand on demand)_
- [init(_:_:background:overlayAccessoryView:)](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene/init(_:_:background:overlayaccessoryview:)-1143c) — Creates a launch scene for document-based applications with a title, a set of actions, a background, and an overlay accessory view. _(Apple Developer; expand on demand)_
- [offset(x:y:)](https://developer.apple.com/documentation/swiftui/view/offset(x:y:)) — Offset this view by the specified horizontal and vertical distances. _(Apple Developer; expand on demand)_
- [frame(width:height:alignment:)](https://developer.apple.com/documentation/swiftui/view/frame(width:height:alignment:)) — Positions this view within an invisible frame with the specified size. _(Apple Developer; expand on demand)_
- [init(_:_:background:backgroundAccessoryView:overlayAccessoryView:)](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene/init(_:_:background:backgroundaccessoryview:overlayaccessoryview:)-1re6d) — Creates a launch scene for document-based applications with a title, a set of actions, and a background. _(Apple Developer; expand on demand)_
- [readableContentTypes](https://developer.apple.com/documentation/swiftui/filedocument/readablecontenttypes) — The file and data types that the document reads from. _(Apple Developer; expand on demand)_
- [init(configuration:)](https://developer.apple.com/documentation/swiftui/filedocument/init(configuration:)) — Creates a document and initializes it with the contents of a file. _(Apple Developer; expand on demand)_
- [file](https://developer.apple.com/documentation/swiftui/filedocumentreadconfiguration/file) — The file wrapper containing the document content. _(Apple Developer; expand on demand)_
- [fileWrapper(configuration:)](https://developer.apple.com/documentation/swiftui/filedocument/filewrapper(configuration:)) — Serializes a document snapshot to a file wrapper. _(Apple Developer; expand on demand)_
- [Information Property List](https://developer.apple.com/documentation/BundleResources/Information-Property-List) — A resource containing key-value pairs that identify and configure a bundle. _(Apple Developer; expand on demand)_
- [UTExportedTypeDeclarations](https://developer.apple.com/documentation/BundleResources/Information-Property-List/UTExportedTypeDeclarations) — The uniform type identifiers owned and exported by the app. _(Apple Developer; expand on demand)_
- [Defining file and data types for your app](https://developer.apple.com/documentation/UniformTypeIdentifiers/defining-file-and-data-types-for-your-app) — Declare uniform type identifiers to support your app’s proprietary data formats. _(Apple Developer; expand on demand)_
- [Building a document-based app using SwiftData](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata) — Code along with the WWDC presenter to transform an app with SwiftData. _(Apple Developer; expand on demand)_
- [Customizing a document-based app’s launch experience](https://developer.apple.com/documentation/UIKit/customizing-a-document-based-app-s-launch-experience) — Add unique elements to your app’s document launch scene. _(Apple Developer; expand on demand)_
- [Evolve your document launch experience](https://developer.apple.com/videos/play/wwdc2024/10132) — Make your document-based app stand out, and bring its unique identity into focus with the new document launch experience. Learn how to leverage the… _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `2cb0e6fd2d9ea5e5b695e1e1b6a035553ed73b520d0eaddcf21f504915c6f385`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
