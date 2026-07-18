---
title: "Scroll views"
source_url: "https://developer.apple.com/documentation/swiftui/scroll-views"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Scroll-views"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "c07db57f0f697e1663abfeb2e721a54753c3196d8cfad3d32d89903d3083191a"
source_etag: "W/\"211a22ce3dcbca1122c11ead1a0297b2\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["View layout"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Scroll views

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Enable people to scroll to content that doesn’t fit in the current display.

When the content of a view doesn’t fit in the display, you can wrap the view in a ScrollView to enable people to scroll on one or more axes. Configure the scroll view using view modifiers. For example, you can set the visibility of the scroll indicators or the availability of scrolling in a given dimension. You can put any view type in a scroll view, but you most often use a scroll view for a layout container with too many elements to fit in the display. For some container views that you put in a scroll view, like lazy stacks, the container doesn’t load views until they are visible or almost visible. For others, like regular stacks and grids, the container loads the content all at once, regardless of the state of scrolling. Lists and Tables implicitly include a scroll view, so you don’t need to add scrolling to…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview) — A scrollable view. _(Apple Developer; expandir sob demanda)_
- [Lists](swiftui-lists.md) — Display a structured, scrollable column of information. _(contexto local)_
- [Tables](swiftui-tables.md) — Display selectable, sortable data arranged in rows and columns. _(contexto local)_
- [Scroll views](https://developer.apple.com/design/Human-Interface-Guidelines/scroll-views) — A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally. _(Apple Developer; expandir sob demanda)_

### Creating a scroll view

- [ScrollViewReader](https://developer.apple.com/documentation/swiftui/scrollviewreader) — A view that provides programmatic scrolling, by working with a proxy to scroll to known child views. _(Apple Developer; expandir sob demanda)_
- [ScrollViewProxy](https://developer.apple.com/documentation/swiftui/scrollviewproxy) — A proxy value that supports programmatic scrolling of the scrollable views within a view hierarchy. _(Apple Developer; expandir sob demanda)_

### Managing scroll position

- [scrollPosition(_:anchor:)](https://developer.apple.com/documentation/swiftui/view/scrollposition(_:anchor:)) — Associates a binding to a scroll position with a scroll view within this view. _(Apple Developer; expandir sob demanda)_
- [scrollPosition(id:anchor:)](https://developer.apple.com/documentation/swiftui/view/scrollposition(id:anchor:)) — Associates a binding to be updated when a scroll view within this view scrolls. _(Apple Developer; expandir sob demanda)_
- [defaultScrollAnchor(_:)](https://developer.apple.com/documentation/swiftui/view/defaultscrollanchor(_:)) — Associates an anchor to control which part of the scroll view’s content should be rendered by default. _(Apple Developer; expandir sob demanda)_
- [defaultScrollAnchor(_:for:)](https://developer.apple.com/documentation/swiftui/view/defaultscrollanchor(_:for:)) — Associates an anchor to control the position of a scroll view in a particular circumstance. _(Apple Developer; expandir sob demanda)_
- [ScrollAnchorRole](https://developer.apple.com/documentation/swiftui/scrollanchorrole) — A type defining the role of a scroll anchor. _(Apple Developer; expandir sob demanda)_
- [ScrollPosition](https://developer.apple.com/documentation/swiftui/scrollposition) — A type that defines the semantic position of where a scroll view is scrolled within its content. _(Apple Developer; expandir sob demanda)_

### Defining scroll targets

- [scrollTargetBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/scrolltargetbehavior(_:)) — Sets the scroll behavior of views scrollable in the provided axes. _(Apple Developer; expandir sob demanda)_
- [scrollTargetLayout(isEnabled:)](https://developer.apple.com/documentation/swiftui/view/scrolltargetlayout(isenabled:)) — Configures the outermost layout as a scroll target layout. _(Apple Developer; expandir sob demanda)_
- [ScrollTarget](https://developer.apple.com/documentation/swiftui/scrolltarget) — A type defining the target in which a scroll view should try and scroll to. _(Apple Developer; expandir sob demanda)_
- [ScrollTargetBehavior](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior) — A type that defines the scroll behavior of a scrollable view. _(Apple Developer; expandir sob demanda)_
- [ScrollTargetBehaviorContext](https://developer.apple.com/documentation/swiftui/scrolltargetbehaviorcontext) — The context in which a scroll target behavior updates its scroll target. _(Apple Developer; expandir sob demanda)_
- [PagingScrollTargetBehavior](https://developer.apple.com/documentation/swiftui/pagingscrolltargetbehavior) — The scroll behavior that aligns scroll targets to container-based geometry. _(Apple Developer; expandir sob demanda)_
- [ViewAlignedScrollTargetBehavior](https://developer.apple.com/documentation/swiftui/viewalignedscrolltargetbehavior) — The scroll behavior that aligns scroll targets to view-based geometry. _(Apple Developer; expandir sob demanda)_
- [AnyScrollTargetBehavior](https://developer.apple.com/documentation/swiftui/anyscrolltargetbehavior) — A type-erased scroll target behavior. _(Apple Developer; expandir sob demanda)_
- [ScrollTargetBehaviorProperties](https://developer.apple.com/documentation/swiftui/scrolltargetbehaviorproperties) — Properties influencing the scroll view a scroll target behavior applies to. _(Apple Developer; expandir sob demanda)_
- [ScrollTargetBehaviorPropertiesContext](https://developer.apple.com/documentation/swiftui/scrolltargetbehaviorpropertiescontext) — The context in which a scroll target behavior can decide its properties. _(Apple Developer; expandir sob demanda)_

### Animating scroll transitions

- [scrollTransition(_:axis:transition:)](https://developer.apple.com/documentation/swiftui/view/scrolltransition(_:axis:transition:)) — Applies the given transition, animating between the phases of the transition as this view appears and disappears within the visible region of the containing… _(Apple Developer; expandir sob demanda)_
- [scrollTransition(topLeading:bottomTrailing:axis:transition:)](https://developer.apple.com/documentation/swiftui/view/scrolltransition(topleading:bottomtrailing:axis:transition:)) — Applies the given transition, animating between the phases of the transition as this view appears and disappears within the visible region of the containing… _(Apple Developer; expandir sob demanda)_
- [ScrollTransitionPhase](https://developer.apple.com/documentation/swiftui/scrolltransitionphase) — The phases that a view transitions between when it scrolls among other views. _(Apple Developer; expandir sob demanda)_
- [ScrollTransitionConfiguration](https://developer.apple.com/documentation/swiftui/scrolltransitionconfiguration) — The configuration of a scroll transition that controls how a transition is applied as a view is scrolled through the visible region of a… _(Apple Developer; expandir sob demanda)_

### Responding to scroll view changes

- [onScrollGeometryChange(for:of:action:)](https://developer.apple.com/documentation/swiftui/view/onscrollgeometrychange(for:of:action:)) — Adds an action to be performed when a value, created from a scroll geometry, changes. _(Apple Developer; expandir sob demanda)_
- [onScrollTargetVisibilityChange(idType:threshold:_:)](https://developer.apple.com/documentation/swiftui/view/onscrolltargetvisibilitychange(idtype:threshold:_:)) — Adds an action to be called with information about what views would be considered visible. _(Apple Developer; expandir sob demanda)_
- [onScrollVisibilityChange(threshold:_:)](https://developer.apple.com/documentation/swiftui/view/onscrollvisibilitychange(threshold:_:)) — Adds an action to be called when the view crosses the threshold to be considered on/off screen. _(Apple Developer; expandir sob demanda)_
- [onScrollPhaseChange(_:)](https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:)) — Adds an action to perform when the scroll phase of the first scroll view in the hierarchy changes. _(Apple Developer; expandir sob demanda)_
- [ScrollGeometry](https://developer.apple.com/documentation/swiftui/scrollgeometry) — A type that defines the geometry of a scroll view. _(Apple Developer; expandir sob demanda)_
- [ScrollPhase](https://developer.apple.com/documentation/swiftui/scrollphase) — A type that describes the state of a scroll gesture of a scrollable view like a scroll view. _(Apple Developer; expandir sob demanda)_
- [ScrollPhaseChangeContext](https://developer.apple.com/documentation/swiftui/scrollphasechangecontext) — A type that provides you with more content when the phase of a scroll view changes. _(Apple Developer; expandir sob demanda)_

### Showing scroll indicators

- [scrollIndicatorsFlash(onAppear:)](https://developer.apple.com/documentation/swiftui/view/scrollindicatorsflash(onappear:)) — Flashes the scroll indicators of a scrollable view when it appears. _(Apple Developer; expandir sob demanda)_
- [scrollIndicatorsFlash(trigger:)](https://developer.apple.com/documentation/swiftui/view/scrollindicatorsflash(trigger:)) — Flashes the scroll indicators of scrollable views when a value changes. _(Apple Developer; expandir sob demanda)_
- [scrollIndicators(_:axes:)](https://developer.apple.com/documentation/swiftui/view/scrollindicators(_:axes:)) — Sets the visibility of scroll indicators within this view. _(Apple Developer; expandir sob demanda)_
- [horizontalScrollIndicatorVisibility](https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalscrollindicatorvisibility) — The visibility to apply to scroll indicators of any horizontally scrollable content. _(Apple Developer; expandir sob demanda)_
- [verticalScrollIndicatorVisibility](https://developer.apple.com/documentation/swiftui/environmentvalues/verticalscrollindicatorvisibility) — The visiblity to apply to scroll indicators of any vertically scrollable content. _(Apple Developer; expandir sob demanda)_
- [ScrollIndicatorVisibility](https://developer.apple.com/documentation/swiftui/scrollindicatorvisibility) — The visibility of scroll indicators of a UI element. _(Apple Developer; expandir sob demanda)_

### Managing content visibility

- [scrollContentBackground(_:)](https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:)) — Specifies the visibility of the background for scrollable views within this view. _(Apple Developer; expandir sob demanda)_
- [scrollClipDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/scrollclipdisabled(_:)) — Sets whether a scroll view clips its content to its bounds. _(Apple Developer; expandir sob demanda)_
- [ScrollContentOffsetAdjustmentBehavior](https://developer.apple.com/documentation/swiftui/scrollcontentoffsetadjustmentbehavior) — A type that defines the different kinds of content offset adjusting behaviors a scroll view can have. _(Apple Developer; expandir sob demanda)_

### Disabling scrolling

- [scrollDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/scrolldisabled(_:)) — Disables or enables scrolling in scrollable views. _(Apple Developer; expandir sob demanda)_
- [isScrollEnabled](https://developer.apple.com/documentation/swiftui/environmentvalues/isscrollenabled) — A Boolean value that indicates whether any scroll views associated with this environment allow scrolling to occur. _(Apple Developer; expandir sob demanda)_

### Configuring scroll bounce behavior

- [scrollBounceBehavior(_:axes:)](https://developer.apple.com/documentation/swiftui/view/scrollbouncebehavior(_:axes:)) — Configures the bounce behavior of scrollable views along the specified axis. _(Apple Developer; expandir sob demanda)_
- [horizontalScrollBounceBehavior](https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalscrollbouncebehavior) — The scroll bounce mode for the horizontal axis of scrollable views. _(Apple Developer; expandir sob demanda)_
- [verticalScrollBounceBehavior](https://developer.apple.com/documentation/swiftui/environmentvalues/verticalscrollbouncebehavior) — The scroll bounce mode for the vertical axis of scrollable views. _(Apple Developer; expandir sob demanda)_
- [ScrollBounceBehavior](https://developer.apple.com/documentation/swiftui/scrollbouncebehavior) — The ways that a scrollable view can bounce when it reaches the end of its content. _(Apple Developer; expandir sob demanda)_

### Configuring scroll edge effects

- [scrollEdgeEffectStyle(_:for:)](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)) — Configures the scroll edge effect style for scroll views within this hierarchy. _(Apple Developer; expandir sob demanda)_
- [scrollEdgeEffectHidden(_:for:)](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffecthidden(_:for:)) — Hides any scroll edge effects for scroll views within this hierarchy. _(Apple Developer; expandir sob demanda)_
- [ScrollEdgeEffectStyle](https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle) — A structure that specifies blur transitions between scrolling content and an area with controls, such as toolbars. _(Apple Developer; expandir sob demanda)_
- [safeAreaBar(edge:alignment:spacing:content:)](https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:)) — Shows the specified content as a custom bar beside the modified view. _(Apple Developer; expandir sob demanda)_

### Interacting with a software keyboard

- [scrollDismissesKeyboard(_:)](https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:)) — Configures the behavior in which scrollable content interacts with the software keyboard. _(Apple Developer; expandir sob demanda)_
- [scrollDismissesKeyboardMode](https://developer.apple.com/documentation/swiftui/environmentvalues/scrolldismisseskeyboardmode) — The way that scrollable content interacts with the software keyboard. _(Apple Developer; expandir sob demanda)_
- [ScrollDismissesKeyboardMode](https://developer.apple.com/documentation/swiftui/scrolldismisseskeyboardmode) — The ways that scrollable content can interact with the software keyboard. _(Apple Developer; expandir sob demanda)_

### Managing scrolling for different inputs

- [scrollInputBehavior(_:for:)](https://developer.apple.com/documentation/swiftui/view/scrollinputbehavior(_:for:)) — Enables or disables scrolling in scrollable views when using particular inputs. _(Apple Developer; expandir sob demanda)_
- [ScrollInputKind](https://developer.apple.com/documentation/swiftui/scrollinputkind) — Inputs used to scroll views. _(Apple Developer; expandir sob demanda)_
- [ScrollInputBehavior](https://developer.apple.com/documentation/swiftui/scrollinputbehavior) — A type that defines whether input should scroll a view. _(Apple Developer; expandir sob demanda)_

### View layout

- [Layout fundamentals](swiftui-layout-fundamentals.md) — Arrange views inside built-in layout containers like stacks and grids. _(contexto local)_
- [Layout adjustments](swiftui-layout-adjustments.md) — Make fine adjustments to alignment, spacing, padding, and other layout parameters. _(contexto local)_
- [Custom layout](swiftui-custom-layout.md) — Place views in custom arrangements and create animated transitions between layout types. _(contexto local)_
- [View groupings](swiftui-view-groupings.md) — Present views in different kinds of purpose-driven containers, like forms or control groups. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/scroll-views)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `c07db57f0f697e1663abfeb2e721a54753c3196d8cfad3d32d89903d3083191a`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
