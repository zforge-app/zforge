---
title: "Documents"
source_url: "https://developer.apple.com/documentation/swiftui/documents"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Documents"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "64787f2bee6c5e28ad64c32eb3550b4eebfbd4bf63c1064fc6852a446f39eaaa"
source_etag: "W/\"dc5c44dfb75b6d3c28434f1e99fa6a9e\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Documents

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Enable people to open and manage documents.

Create a user interface for opening and editing documents. Use the ReadableDocument and WritableDocument protocols to define your document model. They give you direct access to file URLs, integrate with Swift concurrency, and support progress reporting. For simpler documents, you can use the FileDocument protocol, which handles serialization through a . You can also use SwiftData-backed documents using an initializer like init(editing:contentType:editor:prepareDocument:). SwiftUI supports standard behaviors people expect from a document-based app, appropriate for each platform, like multiwindow support, open and save panels. For related design guidance, see Patterns in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [ReadableDocument](https://developer.apple.com/documentation/swiftui/readabledocument) — A type that you use to read documents from file. _(Apple Developer; expand on demand)_
- [WritableDocument](https://developer.apple.com/documentation/swiftui/writabledocument) — A type that you use to write documents to file. _(Apple Developer; expand on demand)_
- [FileDocument](https://developer.apple.com/documentation/swiftui/filedocument) — A type that you use to serialize documents to and from file. _(Apple Developer; expand on demand)_
- [init(editing:contentType:editor:prepareDocument:)](https://developer.apple.com/documentation/swiftui/documentgroup/init(editing:contenttype:editor:preparedocument:)) — Instantiates a document group for creating and editing documents that store a specific model type. _(Apple Developer; expand on demand)_
- [Patterns](https://developer.apple.com/design/Human-Interface-Guidelines/patterns) — Get design guidance for supporting common user actions, tasks, and experiences. _(Apple Developer; expand on demand)_

### Creating a document

- [Building a document-based app with SwiftUI](swiftui-building-a-document-based-app-with-swiftui.md) — Create, save, and open documents in a multiplatform app. _(local context)_
- [Building a document-based app using SwiftData](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata) — Code along with the WWDC presenter to transform an app with SwiftData. _(Apple Developer; expand on demand)_
- [DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup) — A scene that enables support for opening, creating, and saving documents. _(Apple Developer; expand on demand)_

### Storing document data in a value type

- [FileDocumentConfiguration](https://developer.apple.com/documentation/swiftui/filedocumentconfiguration) — The properties of an open file document. _(Apple Developer; expand on demand)_

### Storing document data in a reference type instance

- [Document](https://developer.apple.com/documentation/swiftui/document) — _Apple Developer; expand on demand_
- [URLDocumentConfiguration](https://developer.apple.com/documentation/swiftui/urldocumentconfiguration) — A set of settings and properties of an open document. _(Apple Developer; expand on demand)_
- [DocumentCreationContext](https://developer.apple.com/documentation/swiftui/documentcreationcontext) — Provides context about how a document was created or opened. _(Apple Developer; expand on demand)_
- [DocumentBaseBox](https://developer.apple.com/documentation/swiftui/documentbasebox) — A Box that allows setting its Document base not requiring the caller to know the exact types of the box and its base. _(Apple Developer; expand on demand)_

### Accessing document configuration

- [documentConfiguration](https://developer.apple.com/documentation/swiftui/environmentvalues/documentconfiguration) — The configuration of a document in a DocumentGroup. _(Apple Developer; expand on demand)_
- [DocumentConfiguration](https://developer.apple.com/documentation/swiftui/documentconfiguration) — The configuration of a document in a DocumentGroup. _(Apple Developer; expand on demand)_
- [undoManager](https://developer.apple.com/documentation/swiftui/environmentvalues/undomanager) — The undo manager used to register a view’s undo operations. _(Apple Developer; expand on demand)_

### Reading and writing documents

- [DocumentReadConfiguration](https://developer.apple.com/documentation/swiftui/documentreadconfiguration) — Provides the information required to read a document from disk. _(Apple Developer; expand on demand)_
- [DocumentWriteConfiguration](https://developer.apple.com/documentation/swiftui/documentwriteconfiguration) — Provides the information required to write a document to disk. _(Apple Developer; expand on demand)_
- [FileDocumentReadConfiguration](https://developer.apple.com/documentation/swiftui/filedocumentreadconfiguration) — The configuration for reading file contents. _(Apple Developer; expand on demand)_
- [FileDocumentWriteConfiguration](https://developer.apple.com/documentation/swiftui/filedocumentwriteconfiguration) — The configuration for serializing file contents. _(Apple Developer; expand on demand)_
- [DocumentReader](https://developer.apple.com/documentation/swiftui/documentreader) — Implements logic of reading documents from disk. _(Apple Developer; expand on demand)_
- [DocumentWriter](https://developer.apple.com/documentation/swiftui/documentwriter) — Implements logic of writing documents to disk. _(Apple Developer; expand on demand)_
- [FileWrapperDocumentReader](https://developer.apple.com/documentation/swiftui/filewrapperdocumentreader) — A document reader that uses for reading. _(Apple Developer; expand on demand)_
- [FileWrapperDocumentWriter](https://developer.apple.com/documentation/swiftui/filewrapperdocumentwriter) — A document writer that uses for writing. _(Apple Developer; expand on demand)_

### Opening a document programmatically

- [newDocument](https://developer.apple.com/documentation/swiftui/environmentvalues/newdocument) — An action in the environment that presents a new document. _(Apple Developer; expand on demand)_
- [NewDocumentAction](https://developer.apple.com/documentation/swiftui/newdocumentaction) — An action that presents a new document. _(Apple Developer; expand on demand)_
- [openDocument](https://developer.apple.com/documentation/swiftui/environmentvalues/opendocument) — An action in the environment that presents an existing document. _(Apple Developer; expand on demand)_
- [OpenDocumentAction](https://developer.apple.com/documentation/swiftui/opendocumentaction) — An action that presents an existing document. _(Apple Developer; expand on demand)_

### Configuring the document launch experience

- [DocumentGroupLaunchScene](https://developer.apple.com/documentation/swiftui/documentgrouplaunchscene) — A launch scene for document-based applications. _(Apple Developer; expand on demand)_
- [documentLaunchTitle(_:)](https://developer.apple.com/documentation/swiftui/scene/documentlaunchtitle(_:)) — Sets the title displayed on the document launch card. _(Apple Developer; expand on demand)_
- [documentLaunchSubtitle(_:)](https://developer.apple.com/documentation/swiftui/scene/documentlaunchsubtitle(_:)) — Sets the subtitle displayed beneath the title on the document launch card. _(Apple Developer; expand on demand)_
- [DocumentLaunchView](https://developer.apple.com/documentation/swiftui/documentlaunchview) — A view to present when launching document-related user experience. _(Apple Developer; expand on demand)_
- [documentLaunchTitle(_:)](https://developer.apple.com/documentation/swiftui/view/documentlaunchtitle(_:)) — Sets the title displayed on the document launch card. _(Apple Developer; expand on demand)_
- [documentLaunchSubtitle(_:)](https://developer.apple.com/documentation/swiftui/view/documentlaunchsubtitle(_:)) — Sets the subtitle displayed beneath the title on the document launch card. _(Apple Developer; expand on demand)_
- [documentBrowserContextMenu(_:)](https://developer.apple.com/documentation/swiftui/view/documentbrowsercontextmenu(_:)) — Adds to a actions that accept a list of selected files as their parameter. _(Apple Developer; expand on demand)_
- [DocumentLaunchGeometryProxy](https://developer.apple.com/documentation/swiftui/documentlaunchgeometryproxy) — A proxy for access to the frame of the scene and its title view. _(Apple Developer; expand on demand)_
- [DefaultDocumentGroupLaunchActions](https://developer.apple.com/documentation/swiftui/defaultdocumentgrouplaunchactions) — The default actions for the document group launch scene and the document launch view. _(Apple Developer; expand on demand)_
- [NewDocumentButton](https://developer.apple.com/documentation/swiftui/newdocumentbutton) — A button that creates and opens new documents. _(Apple Developer; expand on demand)_
- [DefaultNewDocumentButtonLabel](https://developer.apple.com/documentation/swiftui/defaultnewdocumentbuttonlabel) — The default label used for a new document button. _(Apple Developer; expand on demand)_
- [DocumentCreationSource](https://developer.apple.com/documentation/swiftui/documentcreationsource) — Describes the source used to create a new document. _(Apple Developer; expand on demand)_

### Renaming a document

- [RenameButton](https://developer.apple.com/documentation/swiftui/renamebutton) — A button that triggers a standard rename action. _(Apple Developer; expand on demand)_
- [renameAction(_:)](https://developer.apple.com/documentation/swiftui/view/renameaction(_:)) — Sets a closure to run for the rename action. _(Apple Developer; expand on demand)_
- [rename](https://developer.apple.com/documentation/swiftui/environmentvalues/rename) — An action that activates the standard rename interaction. _(Apple Developer; expand on demand)_
- [RenameAction](https://developer.apple.com/documentation/swiftui/renameaction) — An action that activates a standard rename interaction. _(Apple Developer; expand on demand)_

### Deprecated

- [ReferenceFileDocument](https://developer.apple.com/documentation/swiftui/referencefiledocument) — A type that you use to serialize reference type documents to and from file. _(Apple Developer; expand on demand)_
- [ReferenceFileDocumentConfiguration](https://developer.apple.com/documentation/swiftui/referencefiledocumentconfiguration) — The properties of an open reference file document. _(Apple Developer; expand on demand)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(local context)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(local context)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(local context)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(local context)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(local context)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(local context)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(local context)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(local context)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/documents)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `64787f2bee6c5e28ad64c32eb3550b4eebfbd4bf63c1064fc6852a446f39eaaa`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
