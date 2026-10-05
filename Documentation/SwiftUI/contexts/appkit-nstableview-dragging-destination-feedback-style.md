---
title: "NSTableView.DraggingDestinationFeedbackStyle"
source_url: "https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSTableView/DraggingDestinationFeedbackStyle-swift.enum"
captured_at: "2026-10-03T21:50:10.394140+00:00"
source_sha256: "6242a5f60dba545a480582eb149cda90a3c71cf9c0c398efc9f6160fcf34ddcb"
source_etag: "\"bb6b-659026eabb221\""
source_last_modified: "Fri, 14 Aug 2026 14:14:01 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "AppKit drag and drop"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSTableView.DraggingDestinationFeedbackStyle

## Quick reference

- Enumeration AppKit used by `NSTableView.draggingDestinationFeedbackStyle`.
- Declaration: `enum DraggingDestinationFeedbackStyle`.
- Availability: macOS; validated against the SDK macOS 27.0 of the local Xcode.

## Summary

Controls the visual feedback native of the drag destination in the table. `none` disables this feedback to allow own drawing; `regular` uses rounded background and insertion marker; `sourceList` is the style associated with the source lists; `gap` opens space for insertion into views-based tables.

## Practical implications for Zforge

- In the sidebar, apply `.none` only the table containing the line avoids overlaying feedback native to the drawing SwiftUI itself.
- Preserve the behavior of content tables and transfer handlers.
- This API does not control the line icon, current selection or operation validity; these states need their own coordination.
- Validate the actual table assembly and transition between targets in the interface; compile does not prove gesture.

## Content map

- Declaration
- Constants: none, regular, sourceList, gap
- Related types of NSTableView

## Second-level links

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expand on demand.
- [BitwiseCopyable](https://developer.apple.com/documentation/swift/bitwisecopyable) — Apple Developer; expand on demand.
- [Equatable](https://developer.apple.com/documentation/swift/equatable) — Apple Developer; expand on demand.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — Apple Developer; expand on demand.
- [NSInteger](https://developer.apple.com/documentation/objectivec/nsinteger) — Apple Developer; expand on demand.
- [NSTableCellView](https://developer.apple.com/documentation/appkit/nstablecellview) — Apple Developer; expand on demand.
- [NSTableView](https://developer.apple.com/documentation/appkit/nstableview) — Apple Developer; expand on demand.
- [NSTableView.AnimationOptions](https://developer.apple.com/documentation/appkit/nstableview/animationoptions) — Apple Developer; expand on demand.
- [NSTableView.ColumnAutoresizingStyle](https://developer.apple.com/documentation/appkit/nstableview/columnautoresizingstyle-swift.enum) — Apple Developer; expand on demand.
- [NSTableView.DraggingDestinationFeedbackStyle](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum) — Apple Developer; expand on demand.
- [NSTableView.DraggingDestinationFeedbackStyle.gap](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/gap) — Apple Developer; expand on demand.
- [NSTableView.DraggingDestinationFeedbackStyle.none](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/none) — Apple Developer; expand on demand.
- [NSTableView.DraggingDestinationFeedbackStyle.regular](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/regular) — Apple Developer; expand on demand.
- [NSTableView.DraggingDestinationFeedbackStyle.sourceList](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/sourcelist) — Apple Developer; expand on demand.
- [NSTableView.DropOperation](https://developer.apple.com/documentation/appkit/nstableview/dropoperation) — Apple Developer; expand on demand.
- [NSTableView.GridLineStyle](https://developer.apple.com/documentation/appkit/nstableview/gridlinestyle) — Apple Developer; expand on demand.
- [NSTableView.RowActionEdge](https://developer.apple.com/documentation/appkit/nstableview/rowactionedge) — Apple Developer; expand on demand.
- [NSTableView.RowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/rowsizestyle-swift.enum) — Apple Developer; expand on demand.
- [NSTableView.SelectionHighlightStyle](https://developer.apple.com/documentation/appkit/nstableview/selectionhighlightstyle-swift.enum) — Apple Developer; expand on demand.
- [NSTableViewGridNone](https://developer.apple.com/documentation/appkit/nstableviewgridlinestyle/nstableviewgridnone) — Apple Developer; expand on demand.
- [NSView](https://developer.apple.com/documentation/appkit/nsview) — Apple Developer; expand on demand.
- [RawRepresentable](https://developer.apple.com/documentation/swift/rawrepresentable) — Apple Developer; expand on demand.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — Apple Developer; expand on demand.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — Apple Developer; expand on demand.
- [Specifying a Custom Row View in a Nib File](https://developer.apple.com/documentation/appkit/specifying-a-custom-row-view-in-a-nib-file) — Apple Developer; expand on demand.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expand on demand.
- [columnAutoresizingStyle](https://developer.apple.com/documentation/appkit/nstableview/columnautoresizingstyle-swift.property) — Apple Developer; expand on demand.
- [draggingDestinationFeedbackStyle](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.property) — Apple Developer; expand on demand.
- [effectiveRowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/effectiverowsizestyle) — Apple Developer; expand on demand.
- [gridStyleMask](https://developer.apple.com/documentation/appkit/nstableview/gridstylemask) — Apple Developer; expand on demand.
- [init(rawValue:)](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/init(rawvalue:)) — Apple Developer; expand on demand.
- [rowSizeStyle](https://developer.apple.com/documentation/appkit/nstablecellview/rowsizestyle) — Apple Developer; expand on demand.
- [rowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/rowsizestyle-swift.property) — Apple Developer; expand on demand.
- [selectionHighlightStyle](https://developer.apple.com/documentation/appkit/nstableview/selectionhighlightstyle-swift.property) — Apple Developer; expand on demand.
- [tableView(_:draggingSession:willBeginAt:forRowIndexes:)](https://developer.apple.com/documentation/appkit/nstableviewdatasource/tableview(_:draggingsession:willbeginat:forrowindexes:)) — Apple Developer; expand on demand.
- [unhideRows(at:withAnimation:)](https://developer.apple.com/documentation/appkit/nstableview/unhiderows(at:withanimation:)) — Apple Developer; expand on demand.

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum)
- Captured: `2026-10-03T21:50:10.394140+00:00`
- SHA-256: `6242a5f60dba545a480582eb149cda90a3c71cf9c0c398efc9f6160fcf34ddcb`
- Scope: one page; secondary links not consulted.
