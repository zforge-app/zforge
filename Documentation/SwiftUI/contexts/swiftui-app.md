---
title: "App"
source_url: "https://developer.apple.com/documentation/swiftui/app"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/App"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "7e2a774081033fbc41514d04dad8546cfb6e5985dd5fc90086fbdf4509967811"
source_etag: "W/\"b29d919abb87f07be813445ff778d85f\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Overview"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Protocol
- Module: SwiftUI
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 14.0+, iPadOS 14.0+, Mac Catalyst 14.0+, macOS 11.0+, tvOS 14.0+, visionOS 1.0+, watchOS 7.0+
- Declaration: `@MainActor @preconcurrency protocol App`

## Summary

**Official summary:** A type that represents the structure and behavior of an app.

Create an app by declaring a structure that conforms to the protocol. Implement the required body computed property to define the app’s content: Precede the structure’s declaration with the @main attribute to indicate that your custom protocol conformer provides the entry point into your app. The protocol provides a default implementation of the main() method that the system calls to launch your app. You can have exactly one entry point among all of your app’s files. Compose the app’s body from instances that conform to the Scene protocol. Each scene contains the root view of a view hierarchy and has a life cycle managed by the system. SwiftUI provides some concrete scene types to handle common scenarios, like for displaying documents or settings. You can also create custom scenes. You can declare state in your app to share across all of its scenes. For example, you can use the StateObject…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [body](https://developer.apple.com/documentation/swiftui/app/body-swift.property) — The content and behavior of the app. _(Apple Developer; expand on demand)_
- [@main](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID626) — _Apple Developer; expand on demand_
- [main()](https://developer.apple.com/documentation/swiftui/app/main()) — Initializes and runs the app. _(Apple Developer; expand on demand)_
- [Scene](https://developer.apple.com/documentation/swiftui/scene) — A part of an app’s user interface with a life cycle managed by the system. _(Apple Developer; expand on demand)_
- [StateObject](https://developer.apple.com/documentation/swiftui/stateobject) — A property wrapper type that instantiates an observable object. _(Apple Developer; expand on demand)_
- [ObservedObject](https://developer.apple.com/documentation/swiftui/observedobject) — A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes. _(Apple Developer; expand on demand)_
- [EnvironmentObject](https://developer.apple.com/documentation/swiftui/environmentobject) — A property wrapper type for an observable object that a parent or ancestor view supplies. _(Apple Developer; expand on demand)_

### Implementing an app

- [Body](https://developer.apple.com/documentation/swiftui/app/body-swift.associatedtype) — The type of scene representing the content of the app. _(Apple Developer; expand on demand)_

### Running an app

- [init()](https://developer.apple.com/documentation/swiftui/app/init()) — Creates an instance of the app using the body that you define for its content. _(Apple Developer; expand on demand)_

### Creating an app

- [Destination Video](visionos-destination-video.md) — Leverage SwiftUI to build an immersive media experience in a multiplatform app. _(local context)_
- [Hello World](https://developer.apple.com/documentation/visionOS/World) — Use windows, volumes, and immersive spaces to teach people about the Earth. _(Apple Developer; expand on demand)_
- [Backyard Birds: Building an app with SwiftData and widgets](https://developer.apple.com/documentation/swiftui/backyard-birds-sample) — Create an app with persistent data, interactive widgets, and an all new in-app purchase experience. _(Apple Developer; expand on demand)_
- [Food Truck: Building a SwiftUI multiplatform app](https://developer.apple.com/documentation/swiftui/food-truck-building-a-swiftui-multiplatform-app) — Create a single codebase and app target for Mac, iPad, and iPhone. _(Apple Developer; expand on demand)_
- [Fruta: Building a feature-rich app with SwiftUI](https://developer.apple.com/documentation/AppClip/fruta-building-a-feature-rich-app-with-swiftui) — Create a shared codebase to build a multiplatform app that offers widgets and an App Clip. _(Apple Developer; expand on demand)_
- [Migrating to the SwiftUI life cycle](https://developer.apple.com/documentation/swiftui/migrating-to-the-swiftui-life-cycle) — Use a scene-based life cycle in SwiftUI while keeping your existing codebase. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/app)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `7e2a774081033fbc41514d04dad8546cfb6e5985dd5fc90086fbdf4509967811`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
