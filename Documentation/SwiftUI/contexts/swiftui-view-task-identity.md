---
title: "task(id:name:priority:file:line:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/task(id:name:priority:file:line:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/task(id:name:priority:file:line:_:)"
captured_at: "2026-10-05T16:41:25.903716+00:00"
source_sha256: "75a9a6d18a1d61c4dca4fc1dcd238dac0fba65242b22458d19dc1aa262e257b5"
source_etag: "\"74a9-659025e3e428d\""
source_last_modified: "Fri, 14 Aug 2026 14:09:26 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Icon previews"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# task(id:name:priority:file:line:_:)

## Quick reference

- Module: SwiftUI
- Availability recorded by the source: iOS 15.0, iPadOS 15.0, Mac Catalyst 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0.
- Zforge SDK verification: Xcode 27.0, macOS SDK 27.0, arm64; application target macOS 26.0.
- Declaration: `@export(implementation) nonisolated func task<T>(id: T, name: String? = nil, priority: TaskPriority = .userInitiated, file: String = #fileID, line: Int = #line, _ action: sending @escaping @isolated(any) () async -> Void) -> some View where T : Equatable
`

## Summary and practical implications

Attach asynchronous work to the lifetime and identity of a view. Zforge keys thumbnail work by item metadata, pixel size and preference; cancellation and generation checks keep obsolete output out of the current cell.

## Content map

Declaration and discussion.

## Second-level links

- [AsyncSequence](https://developer.apple.com/documentation/swift/asyncsequence) — _Apple Developer; expand on demand_
- [Equatable](https://developer.apple.com/documentation/swift/equatable) — _Apple Developer; expand on demand_
- [Int](https://developer.apple.com/documentation/swift/int) — _Apple Developer; expand on demand_
- [String](https://developer.apple.com/documentation/swift/string) — _Apple Developer; expand on demand_
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — _Apple Developer; expand on demand_
- [TaskPriority](https://developer.apple.com/documentation/swift/taskpriority) — _Apple Developer; expand on demand_
- [Text](https://developer.apple.com/documentation/swiftui/text) — _Apple Developer; expand on demand_
- [View](https://developer.apple.com/documentation/swiftui/view) — _Apple Developer; expand on demand_
- [Void](https://developer.apple.com/documentation/swift/void) — _Apple Developer; expand on demand_
- [notifications(named:object:)](https://developer.apple.com/documentation/foundation/notificationcenter/notifications(named:object:)) — _Apple Developer; expand on demand_
- [task(id:name:executorPreference:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(id:name:executorpreference:priority:file:line:_:)) — _Apple Developer; expand on demand_
- [task(id:name:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(id:name:priority:file:line:_:)) — _Apple Developer; expand on demand_
- [task(name:executorPreference:priority:file:line:action:)](https://developer.apple.com/documentation/swiftui/view/task(name:executorpreference:priority:file:line:action:)) — _Apple Developer; expand on demand_
- [task(name:priority:file:line:_:)](https://developer.apple.com/documentation/swiftui/view/task(name:priority:file:line:_:)) — _Apple Developer; expand on demand_
- [userInitiated](https://developer.apple.com/documentation/swift/taskpriority/userinitiated) — _Apple Developer; expand on demand_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/task(id:name:priority:file:line:_:))
- Captured: `2026-10-05T16:41:25.903716+00:00`
- Payload SHA-256: `75a9a6d18a1d61c4dca4fc1dcd238dac0fba65242b22458d19dc1aa262e257b5`
- Scope: one page; secondary links were not traversed.
