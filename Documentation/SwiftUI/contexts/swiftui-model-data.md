---
title: "Model data"
source_url: "https://developer.apple.com/documentation/swiftui/model-data"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Model-data"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "f30ed03d27587efbe85ea74b60499c11b921bc7b232915dc67662716f8fa7c10"
source_etag: "W/\"6b70f12394a95b048ab8771594aa7c40\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Data and storage"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Model data

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Manage the data that your app uses to drive its interface.

SwiftUI offers a declarative approach to user interface design. As you compose a hierarchy of views, you also indicate data dependencies for the views. When the data changes, either due to an external event or because of an action that the user performs, SwiftUI automatically updates the affected parts of the interface. As a result, the framework automatically performs most of the work that view controllers traditionally do. The framework provides tools, like state variables and bindings, for connecting your app’s data to the user interface. These tools help you maintain a single source of truth for every piece of data in your app, in part by reducing the amount of glue logic you write. Select the tool that best suits the task you need to perform: Manage transient UI state locally within a view by wrapping value types as State() properties. Share a reference to a source of truth…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [State()](https://developer.apple.com/documentation/swiftui/state()) — Creates a property that can read and write a value managed by SwiftUI. _(Apple Developer; expand on demand)_
- [Binding](https://developer.apple.com/documentation/swiftui/binding) — A property wrapper type that can read and write a value owned by a source of truth. _(Apple Developer; expand on demand)_
- [Observable()](https://developer.apple.com/documentation/Observation/Observable()) — Defines and implements conformance of the Observable protocol. _(Apple Developer; expand on demand)_
- [Environment](https://developer.apple.com/documentation/swiftui/environment) — A property wrapper that reads a value from a view’s environment. _(Apple Developer; expand on demand)_

### Creating and sharing view state

- [Managing user interface state](https://developer.apple.com/documentation/swiftui/managing-user-interface-state) — Encapsulate view-specific data within your app’s view hierarchy to make your views reusable. _(Apple Developer; expand on demand)_
- [State(initialValue:)](https://developer.apple.com/documentation/swiftui/state(initialvalue:)) — Creates a property with an initial value that can read and write a value managed by SwiftUI. _(Apple Developer; expand on demand)_
- [State(wrappedValue:)](https://developer.apple.com/documentation/swiftui/state(wrappedvalue:)) — Creates a property with a wrapped value that can read and write a value managed by SwiftUI. _(Apple Developer; expand on demand)_
- [State](https://developer.apple.com/documentation/swiftui/state) — A property wrapper type that can read and write a value managed by SwiftUI. _(Apple Developer; expand on demand)_
- [Bindable](https://developer.apple.com/documentation/swiftui/bindable) — A property wrapper type that supports creating bindings to the mutable properties of observable objects. _(Apple Developer; expand on demand)_

### Creating model data

- [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) — Create connections between your app’s data model and views. _(Apple Developer; expand on demand)_
- [Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro) — Update your existing app to leverage the benefits of Observation in Swift. _(Apple Developer; expand on demand)_
- [Monitoring data changes in your app](https://developer.apple.com/documentation/swiftui/monitoring-model-data-changes-in-your-app) — Show changes to data in your app’s user interface by using observable objects. _(Apple Developer; expand on demand)_
- [StateObject](https://developer.apple.com/documentation/swiftui/stateobject) — A property wrapper type that instantiates an observable object. _(Apple Developer; expand on demand)_
- [ObservedObject](https://developer.apple.com/documentation/swiftui/observedobject) — A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes. _(Apple Developer; expand on demand)_
- [ObservableObject](https://developer.apple.com/documentation/Combine/ObservableObject) — A type of object with a publisher that emits before the object has changed. _(Apple Developer; expand on demand)_

### Responding to data changes

- [onChange(of:initial:_:)](https://developer.apple.com/documentation/swiftui/view/onchange(of:initial:_:)) — Adds a modifier for this view that fires an action when a specific value changes. _(Apple Developer; expand on demand)_
- [onReceive(_:perform:)](https://developer.apple.com/documentation/swiftui/view/onreceive(_:perform:)) — Adds an action to perform when this view detects data emitted by the given publisher. _(Apple Developer; expand on demand)_

### Distributing model data throughout your app

- [environmentObject(_:)](https://developer.apple.com/documentation/swiftui/view/environmentobject(_:)) — Supplies an observable object to a view’s hierarchy. _(Apple Developer; expand on demand)_
- [environmentObject(_:)](https://developer.apple.com/documentation/swiftui/scene/environmentobject(_:)) — Supplies an to a view subhierarchy. _(Apple Developer; expand on demand)_
- [EnvironmentObject](https://developer.apple.com/documentation/swiftui/environmentobject) — A property wrapper type for an observable object that a parent or ancestor view supplies. _(Apple Developer; expand on demand)_

### Managing dynamic data

- [DynamicProperty](https://developer.apple.com/documentation/swiftui/dynamicproperty) — An interface for a stored variable that updates an external property of a view. _(Apple Developer; expand on demand)_

### Data and storage

- [Environment values](swiftui-environment-values.md) — Share data throughout a view hierarchy using the environment. _(local context)_
- [Preferences](swiftui-preferences.md) — Indicate configuration preferences from views to their container views. _(local context)_
- [Persistent storage](swiftui-persistent-storage.md) — Store data for use across sessions of your app. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/model-data)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `f30ed03d27587efbe85ea74b60499c11b921bc7b232915dc67662716f8fa7c10`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
