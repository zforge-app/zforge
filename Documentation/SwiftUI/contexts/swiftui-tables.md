---
title: "Tables"
source_url: "https://developer.apple.com/documentation/swiftui/tables"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Tables"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "44cf4dc439536907fc5aefa93460f9cc8501637fb1c299b58cadc189bc2476cc"
source_etag: "W/\"b1f5346d793f3703456bb56bac7cb2ec\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Tables

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Display selectable, sortable data arranged in rows and columns.

Use a table to display multiple values across a collection of elements. Each element in the collection appears in a different row of the table, while each value for a given element appears in a different column. Narrow displays may adapt to show only the first column of the table. When you create a table, you provide a collection of elements, and then tell the table how to find the needed value for each column. In simple cases, SwiftUI infers the element for each row, but you can also specify the row elements explicitly in more complex scenarios. With a small amount of additional configuration, you can also make the items in the table selectable, and the columns sortable. Like a List, a table includes implicit vertical scrolling that you can configure using the view modifiers described in Scroll views. For design guidance, see Lists and tables in the Human…

## Content map

- Overview

## Second-level links

### Overview and featured references

- [List](https://developer.apple.com/documentation/swiftui/list) — A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members. _(Apple Developer; expand on demand)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(local context)_
- [Lists and tables](https://developer.apple.com/design/Human-Interface-Guidelines/lists-and-tables) — Lists and tables present data in one or more columns of rows. _(Apple Developer; expand on demand)_

### Creating a table

- [Building a great Mac app with SwiftUI](https://developer.apple.com/documentation/swiftui/building-a-great-mac-app-with-swiftui) — Create engaging SwiftUI Mac apps by incorporating side bars, tables, toolbars, and several other popular user interface elements. _(Apple Developer; expand on demand)_
- [Table](https://developer.apple.com/documentation/swiftui/table) — A container that presents rows of data arranged in one or more columns, optionally providing the ability to select one or more members. _(Apple Developer; expand on demand)_
- [tableStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tablestyle(_:)) — Sets the style for tables within this view. _(Apple Developer; expand on demand)_

### Creating columns

- [TableColumn](https://developer.apple.com/documentation/swiftui/tablecolumn) — A column that displays a view for each row in a table. _(Apple Developer; expand on demand)_
- [TableColumnContent](https://developer.apple.com/documentation/swiftui/tablecolumncontent) — A type used to represent columns within a table. _(Apple Developer; expand on demand)_
- [TableColumnAlignment](https://developer.apple.com/documentation/swiftui/tablecolumnalignment) — Describes the alignment of the content of a table column. _(Apple Developer; expand on demand)_
- [TableColumnBuilder](https://developer.apple.com/documentation/swiftui/tablecolumnbuilder) — A result builder that creates table column content from closures. _(Apple Developer; expand on demand)_
- [TableColumnForEach](https://developer.apple.com/documentation/swiftui/tablecolumnforeach) — A structure that computes columns on demand from an underlying collection of identified data. _(Apple Developer; expand on demand)_

### Customizing columns

- [tableColumnHeaders(_:)](https://developer.apple.com/documentation/swiftui/view/tablecolumnheaders(_:)) — Controls the visibility of a ’s column header views. _(Apple Developer; expand on demand)_
- [TableColumnCustomization](https://developer.apple.com/documentation/swiftui/tablecolumncustomization) — A representation of the state of the columns in a table. _(Apple Developer; expand on demand)_
- [TableColumnCustomizationBehavior](https://developer.apple.com/documentation/swiftui/tablecolumncustomizationbehavior) — A set of customization behaviors of a column that a table can offer to a user. _(Apple Developer; expand on demand)_

### Creating rows

- [TableRow](https://developer.apple.com/documentation/swiftui/tablerow) — A row that represents a data value in a table. _(Apple Developer; expand on demand)_
- [TableRowContent](https://developer.apple.com/documentation/swiftui/tablerowcontent) — A type used to represent table rows. _(Apple Developer; expand on demand)_
- [TableHeaderRowContent](https://developer.apple.com/documentation/swiftui/tableheaderrowcontent) — A table row that displays a single view instead of columned content. _(Apple Developer; expand on demand)_
- [TupleTableRowContent](https://developer.apple.com/documentation/swiftui/tupletablerowcontent) — A type of table column content that creates table rows created from a Swift tuple of table rows. _(Apple Developer; expand on demand)_
- [TableForEachContent](https://developer.apple.com/documentation/swiftui/tableforeachcontent) — A type of table row content that creates table rows created by iterating over a collection. _(Apple Developer; expand on demand)_
- [EmptyTableRowContent](https://developer.apple.com/documentation/swiftui/emptytablerowcontent) — A table row content that doesn’t produce any rows. _(Apple Developer; expand on demand)_
- [DynamicTableRowContent](https://developer.apple.com/documentation/swiftui/dynamictablerowcontent) — A type of table row content that generates table rows from an underlying collection of data. _(Apple Developer; expand on demand)_
- [TableRowBuilder](https://developer.apple.com/documentation/swiftui/tablerowbuilder) — A result builder that creates table row content from closures. _(Apple Developer; expand on demand)_

### Adding progressive disclosure

- [DisclosureTableRow](https://developer.apple.com/documentation/swiftui/disclosuretablerow) — A kind of table row that shows or hides additional rows based on the state of a disclosure control. _(Apple Developer; expand on demand)_
- [TableOutlineGroupContent](https://developer.apple.com/documentation/swiftui/tableoutlinegroupcontent) — An opaque table row type created by a table’s hierarchical initializers. _(Apple Developer; expand on demand)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(local context)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(local context)_
- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(local context)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(local context)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/tables)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `44cf4dc439536907fc5aefa93460f9cc8501637fb1c299b58cadc189bc2476cc`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
