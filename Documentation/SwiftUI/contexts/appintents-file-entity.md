---
title: "FileEntity"
source_url: "https://developer.apple.com/documentation/appintents/fileentity"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/FileEntity"
captured_at: "2026-10-11T15:17:51.245542+00:00"
source_sha256: "beb699c4ddf9ea0ae534937392b2b558af06bfffbd209a2387174bf939967356"
source_etag: "\"4d7f-65bb9648f76b8\""
source_last_modified: "Fri, 18 Sep 2026 03:21:14 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand Siri routing diagnosis"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# FileEntity

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Protocol
- Module: App Intents
- Relevance to Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, watchOS 11.0+
- Declaration: `protocol FileEntity : AppEntity where Self.ID == FileEntityIdentifier`

## Summary

**Official summary:** An entity that refers to a document or other file.


## Second-level links

### Type Properties

- [supportedContentTypes](https://developer.apple.com/documentation/appintents/fileentity/supportedcontenttypes) — A list of selectable type identifiers. The default value is ‘public.item’. _(Apple Developer; expand on demand)_

### App entity types

- [AppEntity](https://developer.apple.com/documentation/appintents/appentity) — An interface for making a custom type or app-specific concept discoverable by Apple Intelligence and experiences like Siri or the Shortcuts app. _(Apple Developer; expand on demand)_
- [IndexedEntity](https://developer.apple.com/documentation/appintents/indexedentity) — An interface that allows you to include an entity in your app’s Spotlight index. _(Apple Developer; expand on demand)_
- [SyncableEntity](https://developer.apple.com/documentation/appintents/syncableentity) — An interface that indicates your entity has an identifier that’s consistent across devices. _(Apple Developer; expand on demand)_
- [TransientAppEntity](https://developer.apple.com/documentation/appintents/transientappentity) — A type that represents a transient model object which exposes its interface to App Intents via properties. Note that types are not meant to… _(Apple Developer; expand on demand)_
- [UniqueAppEntity](https://developer.apple.com/documentation/appintents/uniqueappentity) — An AppEntity subtype for entities that only have a single instance. _(Apple Developer; expand on demand)_
- [OwnershipProvidingEntity](https://developer.apple.com/documentation/appintents/ownershipprovidingentity) — A type that provides the system with ownership and sharing context for an app entity. _(Apple Developer; expand on demand)_
- [UnionValue()](https://developer.apple.com/documentation/appintents/unionvalue()) — _Apple Developer; expand on demand_
- [AppUnionValue](https://developer.apple.com/documentation/appintents/appunionvalue) — A protocol that provides nominal type identity and metadata for union values. _(Apple Developer; expand on demand)_
- [AppUnionValueCasesProviding](https://developer.apple.com/documentation/appintents/appunionvaluecasesproviding) — A protocol for the cases enumeration of an . _(Apple Developer; expand on demand)_

### Inherits From

- [AppValue](https://developer.apple.com/documentation/appintents/appvalue) — An interface that describes conceptual types you use in app intents. _(Apple Developer; expand on demand)_
- [CustomLocalizedStringResourceConvertible](https://developer.apple.com/documentation/foundation/customlocalizedstringresourceconvertible) — A type that provides an out-of-process localizable description. _(Apple Developer; expand on demand)_
- [DisplayRepresentable](https://developer.apple.com/documentation/appintents/displayrepresentable) — An interface for providing a dynamic visual representation of a specific type and instances of that type. _(Apple Developer; expand on demand)_
- [Identifiable](https://developer.apple.com/documentation/swift/identifiable) — A class of types whose instances hold the value of an entity with stable identity. _(Apple Developer; expand on demand)_
- [InstanceDisplayRepresentable](https://developer.apple.com/documentation/appintents/instancedisplayrepresentable) — An interface for providing the visual representation for an instance of a specific type. _(Apple Developer; expand on demand)_
- [PersistentlyIdentifiable](https://developer.apple.com/documentation/appintents/persistentlyidentifiable) — Defines a string that uniquely identifies a type. This is useful for maintaining the identity of a type, even when its type name is… _(Apple Developer; expand on demand)_
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — A thread-safe type whose values can be shared across arbitrary concurrent contexts without introducing a risk of data races. _(Apple Developer; expand on demand)_
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — A type whose metatype can be shared across arbitrary isolation domains without introducing a risk of data races. _(Apple Developer; expand on demand)_
- [TypeDisplayRepresentable](https://developer.apple.com/documentation/appintents/typedisplayrepresentable) — An interface for providing the visual representation of a specific type. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/fileentity)
- Captured: `2026-10-11T15:17:51.245542+00:00`
- Payload SHA-256: `beb699c4ddf9ea0ae534937392b2b558af06bfffbd209a2387174bf939967356`
- Scope: one on-demand primary page; secondary links remain unvisited. No asset is downloaded.
