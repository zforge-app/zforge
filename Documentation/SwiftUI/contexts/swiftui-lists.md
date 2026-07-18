---
title: "Lists"
source_url: "https://developer.apple.com/documentation/swiftui/lists"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Lists"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "ee43f6257e7601221cedab97f26a164cdd07a431203d51d337ff80d3a06fc700"
source_etag: "W/\"d5667ace18190a27bbf40600618082f4\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Lists

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Display a structured, scrollable column of information.

Use a list to display a one-dimensional vertical collection of views. The list is a complex container type that automatically provides scrolling when it grows too large for the current display. You build a list by providing it with individual views for the rows in the list, or by using a ForEach to enumerate a group of rows. You can also mix these strategies, blending any number of individual views and constructs. Use view modifiers to configure the appearance and behavior of a list and its rows, headers, sections, and separators. For example, you can apply a style to the list, add swipe gestures to individual rows, or make the list refreshable with a pull-down gesture. You can also use the configuration associated with Scroll views to control the list’s implicit scrolling behavior. For design guidance, see Lists and tables in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [ForEach](https://developer.apple.com/documentation/swiftui/foreach) — A structure that computes views on demand from an underlying collection of identified data. _(Apple Developer; expandir sob demanda)_
- [Scroll views](swiftui-scroll-views.md) — Enable people to scroll to content that doesn’t fit in the current display. _(contexto local)_
- [Lists and tables](https://developer.apple.com/design/Human-Interface-Guidelines/lists-and-tables) — Lists and tables present data in one or more columns of rows. _(Apple Developer; expandir sob demanda)_

### Creating a list

- [Displaying data in lists](https://developer.apple.com/documentation/swiftui/displaying-data-in-lists) — Visualize collections of data with platform-appropriate appearance. _(Apple Developer; expandir sob demanda)_
- [List](https://developer.apple.com/documentation/swiftui/list) — A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members. _(Apple Developer; expandir sob demanda)_
- [listStyle(_:)](https://developer.apple.com/documentation/swiftui/view/liststyle(_:)) — Sets the style for lists within this view. _(Apple Developer; expandir sob demanda)_

### Disclosing information progressively

- [OutlineGroup](https://developer.apple.com/documentation/swiftui/outlinegroup) — A structure that computes views and disclosure groups on demand from an underlying collection of tree-structured, identified data. _(Apple Developer; expandir sob demanda)_
- [DisclosureGroup](https://developer.apple.com/documentation/swiftui/disclosuregroup) — A view that shows or hides another content view, based on the state of a disclosure control. _(Apple Developer; expandir sob demanda)_
- [disclosureGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/disclosuregroupstyle(_:)) — Sets the style for disclosure groups within this view. _(Apple Developer; expandir sob demanda)_

### Configuring a list’s layout

- [listRowInsets(_:)](https://developer.apple.com/documentation/swiftui/view/listrowinsets(_:)) — Applies an inset to the rows in a list. _(Apple Developer; expandir sob demanda)_
- [listRowInsets(_:_:)](https://developer.apple.com/documentation/swiftui/view/listrowinsets(_:_:)) — Sets the insets of rows in a list on the specified edges. _(Apple Developer; expandir sob demanda)_
- [defaultMinListRowHeight](https://developer.apple.com/documentation/swiftui/environmentvalues/defaultminlistrowheight) — The default minimum height of rows in a list. _(Apple Developer; expandir sob demanda)_
- [defaultMinListHeaderHeight](https://developer.apple.com/documentation/swiftui/environmentvalues/defaultminlistheaderheight) — The default minimum height of a header in a list. _(Apple Developer; expandir sob demanda)_
- [listRowSpacing(_:)](https://developer.apple.com/documentation/swiftui/view/listrowspacing(_:)) — Sets the vertical spacing between two adjacent rows in a List. _(Apple Developer; expandir sob demanda)_
- [listSectionSpacing(_:)](https://developer.apple.com/documentation/swiftui/view/listsectionspacing(_:)) — Sets the spacing between adjacent sections in a List to a custom value. _(Apple Developer; expandir sob demanda)_
- [ListSectionSpacing](https://developer.apple.com/documentation/swiftui/listsectionspacing) — The spacing options between two adjacent sections in a list. _(Apple Developer; expandir sob demanda)_
- [listSectionMargins(_:_:)](https://developer.apple.com/documentation/swiftui/view/listsectionmargins(_:_:)) — Set the section margins for the specific edges. _(Apple Developer; expandir sob demanda)_

### Configuring rows

- [listItemTint(_:)](https://developer.apple.com/documentation/swiftui/view/listitemtint(_:)) — Sets a fixed tint color for content in a list. _(Apple Developer; expandir sob demanda)_
- [ListItemTint](https://developer.apple.com/documentation/swiftui/listitemtint) — A tint effect configuration that you can apply to content in a list. _(Apple Developer; expandir sob demanda)_

### Configuring headers

- [headerProminence(_:)](https://developer.apple.com/documentation/swiftui/view/headerprominence(_:)) — Sets the header prominence for this view. _(Apple Developer; expandir sob demanda)_
- [headerProminence](https://developer.apple.com/documentation/swiftui/environmentvalues/headerprominence) — The prominence to apply to section headers within a view. _(Apple Developer; expandir sob demanda)_
- [Prominence](https://developer.apple.com/documentation/swiftui/prominence) — A type indicating the prominence of a view hierarchy. _(Apple Developer; expandir sob demanda)_

### Configuring separators

- [listRowSeparatorTint(_:edges:)](https://developer.apple.com/documentation/swiftui/view/listrowseparatortint(_:edges:)) — Sets the tint color associated with a row. _(Apple Developer; expandir sob demanda)_
- [listSectionSeparatorTint(_:edges:)](https://developer.apple.com/documentation/swiftui/view/listsectionseparatortint(_:edges:)) — Sets the tint color associated with a section. _(Apple Developer; expandir sob demanda)_
- [listRowSeparator(_:edges:)](https://developer.apple.com/documentation/swiftui/view/listrowseparator(_:edges:)) — Sets the display mode for the separator associated with this specific row. _(Apple Developer; expandir sob demanda)_
- [listSectionSeparator(_:edges:)](https://developer.apple.com/documentation/swiftui/view/listsectionseparator(_:edges:)) — Sets whether to hide the separator associated with a list section. _(Apple Developer; expandir sob demanda)_

### Configuring backgrounds

- [listRowBackground(_:)](https://developer.apple.com/documentation/swiftui/view/listrowbackground(_:)) — Places a custom background view behind a list row item. _(Apple Developer; expandir sob demanda)_
- [alternatingRowBackgrounds(_:)](https://developer.apple.com/documentation/swiftui/view/alternatingrowbackgrounds(_:)) — Overrides whether lists and tables in this view have alternating row backgrounds. _(Apple Developer; expandir sob demanda)_
- [AlternatingRowBackgroundBehavior](https://developer.apple.com/documentation/swiftui/alternatingrowbackgroundbehavior) — The styling of views with respect to alternating row backgrounds. _(Apple Developer; expandir sob demanda)_
- [backgroundProminence](https://developer.apple.com/documentation/swiftui/environmentvalues/backgroundprominence) — The prominence of the background underneath views associated with this environment. _(Apple Developer; expandir sob demanda)_
- [BackgroundProminence](https://developer.apple.com/documentation/swiftui/backgroundprominence) — The prominence of backgrounds underneath other views. _(Apple Developer; expandir sob demanda)_

### Displaying a badge on a list item

- [badge(_:)](https://developer.apple.com/documentation/swiftui/view/badge(_:)) — Generates a badge for the view from a localized string resource. _(Apple Developer; expandir sob demanda)_
- [badgeProminence(_:)](https://developer.apple.com/documentation/swiftui/view/badgeprominence(_:)) — Specifies the prominence of badges created by this view. _(Apple Developer; expandir sob demanda)_
- [badgeProminence](https://developer.apple.com/documentation/swiftui/environmentvalues/badgeprominence) — The prominence to apply to badges associated with this environment. _(Apple Developer; expandir sob demanda)_
- [BadgeProminence](https://developer.apple.com/documentation/swiftui/badgeprominence) — The visual prominence of a badge. _(Apple Developer; expandir sob demanda)_

### Configuring interaction

- [swipeActions(edge:allowsFullSwipe:content:)](https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:)) — Adds custom swipe actions to a row in a list. _(Apple Developer; expandir sob demanda)_
- [selectionDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/selectiondisabled(_:)) — Adds a condition that controls whether users can select this view. _(Apple Developer; expandir sob demanda)_
- [listRowHoverEffect(_:)](https://developer.apple.com/documentation/swiftui/view/listrowhovereffect(_:)) — Requests that the containing list row use the provided hover effect. _(Apple Developer; expandir sob demanda)_
- [listRowHoverEffectDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/listrowhovereffectdisabled(_:)) — Requests that the containing list row have its hover effect disabled. _(Apple Developer; expandir sob demanda)_

### Refreshing a list’s content

- [refreshable(action:)](https://developer.apple.com/documentation/swiftui/view/refreshable(action:)) — Adds an asynchronous handler that can update the data the view displays when a person initiates a request, such as by pulling to refresh. _(Apple Developer; expandir sob demanda)_
- [refresh](https://developer.apple.com/documentation/swiftui/environmentvalues/refresh) — A refresh action stored in a view’s environment. _(Apple Developer; expandir sob demanda)_
- [RefreshAction](https://developer.apple.com/documentation/swiftui/refreshaction) — An action that initiates a refresh operation. _(Apple Developer; expandir sob demanda)_

### Editing a list

- [moveDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/movedisabled(_:)) — Adds a condition for whether the view’s view hierarchy is movable. _(Apple Developer; expandir sob demanda)_
- [deleteDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/deletedisabled(_:)) — Adds a condition for whether the view’s view hierarchy is deletable. _(Apple Developer; expandir sob demanda)_
- [editMode](https://developer.apple.com/documentation/swiftui/environmentvalues/editmode) — An indication of whether the user can edit the contents of a view associated with this environment. _(Apple Developer; expandir sob demanda)_
- [EditMode](https://developer.apple.com/documentation/swiftui/editmode) — A mode that indicates whether the user can edit a view’s content. _(Apple Developer; expandir sob demanda)_
- [EditActions](https://developer.apple.com/documentation/swiftui/editactions) — A set of edit actions on a collection of data that a view can offer to a user. _(Apple Developer; expandir sob demanda)_
- [EditableCollectionContent](https://developer.apple.com/documentation/swiftui/editablecollectioncontent) — An opaque wrapper view that adds editing capabilities to a row in a list. _(Apple Developer; expandir sob demanda)_
- [IndexedIdentifierCollection](https://developer.apple.com/documentation/swiftui/indexedidentifiercollection) — A collection wrapper that iterates over the indices and identifiers of a collection together. _(Apple Developer; expandir sob demanda)_

### Configuring a section index

- [listSectionIndexVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/listsectionindexvisibility(_:)) — Changes the visibility of the list section index. _(Apple Developer; expandir sob demanda)_
- [sectionIndexLabel(_:)](https://developer.apple.com/documentation/swiftui/view/sectionindexlabel(_:)) — Sets the label that is used in a section index to point to this section, typically only a single character long. _(Apple Developer; expandir sob demanda)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(contexto local)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(contexto local)_
- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(contexto local)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(contexto local)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/lists)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `ee43f6257e7601221cedab97f26a164cdd07a431203d51d337ff80d3a06fc700`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
