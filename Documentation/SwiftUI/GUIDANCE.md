---
title: "SwiftUI guidance for Zforge"
synthesized_at: "2026-07-16"
scope: "Cross-cutting synthesis of the captured Apple Developer contexts"
authority: "Derived from primary Apple sources; verify details in linked contexts"
---

# SwiftUI principles for Zforge

This document is an operational synthesis. The linked contexts preserve the primary source, date, and availability; they take precedence when an API detail must be decided.

## Mental model

- Declare the application as a composition of `App`, scenes, and `View` hierarchies. A view describes what should appear for a given state, and the framework reconciles the affected parts when data changes. See [SwiftUI](contexts/swiftui.md), [App](contexts/swiftui-app.md), [App organization](contexts/swiftui-app-organization.md), and [View fundamentals](contexts/swiftui-view-fundamentals.md).
- Prefer composition over imperative control: combine views, containers, and modifiers; create custom views or modifiers when a pattern actually repeats. See [View configuration](contexts/swiftui-view-configuration.md) and [View styles](contexts/swiftui-view-styles.md).
- Treat identity, state, and dependencies as part of hierarchy design. Avoid turning `body` into a flow controller or a place for heavy work.

## Data and interface updates

- Keep a single source of truth for each piece of data. Use local state for transient UI, bindings for mutable access to a value owned by another source, observable models for domain state, and environment for dependencies shared by the hierarchy. See [Model data](contexts/swiftui-model-data.md) and [Environment values](contexts/swiftui-environment-values.md).
- Choose the most narrowly scoped tool that solves the problem. Global state or excessive use of environment hides dependencies and broadens updates.
- Let data changes drive visual updates. Side effects must be linked to explicit events, tasks, or lifecycles, with appropriate cancellation and isolation.

## Composition, layout, and navigation

- Start with stacks, grids, lists, tables, scroll views, and system navigation containers. They respond to variable content and dimensions; turn to fine adjustments and custom layouts only afterward. See [Layout fundamentals](contexts/swiftui-layout-fundamentals.md), [Layout adjustments](contexts/swiftui-layout-adjustments.md), and [Custom layout](contexts/swiftui-custom-layout.md).
- On macOS, design from the outset for resizable windows, keyboard, focus, menus, commands, toolbars, selection, drag and drop, and multiple windows. See [Windows](contexts/swiftui-windows.md), [Navigation](contexts/swiftui-navigation.md), [Toolbars](contexts/swiftui-toolbars.md), [Menus and commands](contexts/swiftui-menus-and-commands.md), [Focus](contexts/swiftui-focus.md), and [Drag and drop](contexts/swiftui-drag-and-drop.md).
- Use system adaptation by default. An operational inference for Zforge is to avoid fixed geometry when a native container already expresses the desired relationship.

## macOS and AppKit integration

- Prioritize native SwiftUI components available on macOS and the behavior defined in `UI-UX-GUIDE.md`. Functional semantics can span platforms, but the final interaction must belong on the Mac.
- Use AppKit as a deliberate bridge when SwiftUI does not expose a required capability. `NSViewRepresentable` and `NSViewControllerRepresentable` bring AppKit into the SwiftUI hierarchy; hosting views and controllers provide the reverse path. See [AppKit integration](contexts/swiftui-appkit-integration.md) and [AppKit](contexts/appkit.md).
- Do not introduce an AppKit bridge solely out of familiarity. It adds state synchronization, lifecycle, sizing, and accessibility responsibilities that need testing.

## Liquid Glass and system components

- First compile with the current Xcode and SDK and observe the application on current systems. Standard SwiftUI and AppKit components automatically receive much of the contemporary appearance. Consult [Adopting Liquid Glass](contexts/technologyoverviews-adopting-liquid-glass.md).
- Treat the material as a functional layer for controls, navigation, menus, toolbars, windows, modals, and search, rather than decoration applied indiscriminately to content.
- Add explicit effects only when a custom view actually needs to participate in this visual system. Preserve readability, contrast, hierarchy, accessibility, and performance.
- For Zforge, `UI-UX-GUIDE.md` remains the authority for visual composition and limits explicit effects to appropriate functional situations.

## Accessibility and localization

- Treat accessibility as part of the structure, not as a finishing touch: semantics, readable appearance, actionable controls, useful descriptions, and navigation must follow the hierarchy from the outset. Consult [Accessibility fundamentals](contexts/swiftui-accessibility-fundamentals.md) and the local appearance, controls, descriptions, and navigation collections.
- System components provide a better foundation but do not eliminate validation with VoiceOver, keyboard, contrast, content sizes, and reduced-motion or reduced-transparency states.
- Keep visible text and accessible labels localized through the String Catalog, without concatenating fragments that prevent natural translation.

## Previews, measurement, and performance

- Use preview macros to iterate on views in representative states, sizes, and contexts; previews accelerate feedback but do not replace tests in the actual application. Consult [Previews in Xcode](contexts/swiftui-previews-in-xcode.md).
- Measure before optimizing. Instruments helps locate hangs, hitches, long `body` updates, and frequent invalidations. Consult [Performance analysis](contexts/swiftui-performance-analysis.md).
- Avoid expensive synchronous work on the rendering path and reduce broad state dependencies that unnecessarily invalidate parts of the tree.

## Evidence hierarchy

1. Captured local context, when recent and applicable to the target platform.
2. Official Apple Developer page incorporated into the corpus through the incremental protocol.
3. Local SDK and Xcode for signatures, availability, and compilation behavior.
4. Minimal experiment or test in Zforge for behavior not fully determined by documentation.

When this evidence diverges, record the version, platform, and uncertainty rather than generalizing.
