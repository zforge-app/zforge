---
title: "View styles"
source_url: "https://developer.apple.com/documentation/swiftui/view-styles"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View-styles"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "58c34e0d2c1eb941ef7df0bfae963f2cfa7b1cc341ea94b22be2db8e793d964e"
source_etag: "W/\"16c08b0fba4eabbbe173e555e526b3b1\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# View styles

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Apply built-in and custom appearances and behaviors to different types of views.

SwiftUI defines built-in styles for certain kinds of views and automatically selects the appropriate style for a particular presentation context. For example, a Label might appear as an icon, a string title, or both, depending on factors like the platform, whether the view appears in a toolbar, and so on. You can override the automatic style by using one of the style view modifiers. These modifiers typically propagate throughout a container view, so that you can wrap a view hierarchy in a style modifier to affect all the views of the given type within the hierarchy. Any of the style protocols that define a method, like ToggleStyle, also enable you to define custom styles. Create a type that conforms to the corresponding style protocol and implement its method. Then apply the new style using a style view modifier exactly like a built-in style.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Label](https://developer.apple.com/documentation/swiftui/label) — A standard label for user interface items, consisting of an icon with a title. _(Apple Developer; expand on demand)_
- [ToggleStyle](https://developer.apple.com/documentation/swiftui/togglestyle) — The appearance and behavior of a toggle. _(Apple Developer; expand on demand)_

### Styling views with Liquid Glass

- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) — Configure, combine, and morph views using Liquid Glass effects. _(Apple Developer; expand on demand)_
- [Landmarks: Building an app with Liquid Glass](swiftui-landmarks-building-an-app-with-liquid-glass.md) — Enhance your app experience with system-provided and custom Liquid Glass. _(local context)_
- [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) — Applies the Liquid Glass effect to a view. _(Apple Developer; expand on demand)_
- [glassEffectID(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:)) — Associates an identity value to Liquid Glass effects defined within this view. _(Apple Developer; expand on demand)_
- [glassEffectTransition(_:)](https://developer.apple.com/documentation/swiftui/view/glasseffecttransition(_:)) — Associates a glass effect transition with any glass effects defined within this view. _(Apple Developer; expand on demand)_
- [glassEffectUnion(id:namespace:)](https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:)) — Associates any Liquid Glass effects defined within this view to a union with the provided identifier. _(Apple Developer; expand on demand)_
- [interactive(_:)](https://developer.apple.com/documentation/swiftui/glass/interactive(_:)) — Returns a copy of the structure configured to be interactive. _(Apple Developer; expand on demand)_
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) — A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another. _(Apple Developer; expand on demand)_
- [GlassEffectTransition](https://developer.apple.com/documentation/swiftui/glasseffecttransition) — A structure that describes changes to apply when a glass effect is added or removed from the view hierarchy. _(Apple Developer; expand on demand)_
- [GlassButtonStyle](https://developer.apple.com/documentation/swiftui/glassbuttonstyle) — A button style that applies glass border artwork based on the button’s context. _(Apple Developer; expand on demand)_
- [GlassProminentButtonStyle](https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle) — A button style that applies prominent glass border artwork based on the button’s context. _(Apple Developer; expand on demand)_
- [DefaultGlassEffectShape](https://developer.apple.com/documentation/swiftui/defaultglasseffectshape) — The default shape applied by glass effects, a capsule. _(Apple Developer; expand on demand)_

### Styling buttons

- [buttonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/buttonstyle(_:)) — Sets the style for buttons within this view to a button style with a custom appearance and standard interaction behavior. _(Apple Developer; expand on demand)_
- [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle) — A type that applies standard interaction behavior and a custom appearance to all buttons within a view hierarchy. _(Apple Developer; expand on demand)_
- [ButtonStyleConfiguration](https://developer.apple.com/documentation/swiftui/buttonstyleconfiguration) — The properties of a button. _(Apple Developer; expand on demand)_
- [PrimitiveButtonStyle](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle) — A type that applies custom interaction behavior and a custom appearance to all buttons within a view hierarchy. _(Apple Developer; expand on demand)_
- [PrimitiveButtonStyleConfiguration](https://developer.apple.com/documentation/swiftui/primitivebuttonstyleconfiguration) — The properties of a button. _(Apple Developer; expand on demand)_
- [signInWithAppleButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/signinwithapplebuttonstyle(_:)) — Sets the style used for displaying the control (see ). _(Apple Developer; expand on demand)_
- [buttonSizing(_:)](https://developer.apple.com/documentation/swiftui/view/buttonsizing(_:)) — The preferred sizing behavior of buttons in the view hierarchy. _(Apple Developer; expand on demand)_
- [ButtonSizing](https://developer.apple.com/documentation/swiftui/buttonsizing) — The sizing behavior of s and other button-like controls. _(Apple Developer; expand on demand)_

### Styling pickers

- [pickerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/pickerstyle(_:)) — Sets the style for pickers within this view. _(Apple Developer; expand on demand)_
- [PickerStyle](https://developer.apple.com/documentation/swiftui/pickerstyle) — A type that specifies the appearance and interaction of all pickers within a view hierarchy. _(Apple Developer; expand on demand)_
- [datePickerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/datepickerstyle(_:)) — Sets the style for date pickers within this view. _(Apple Developer; expand on demand)_
- [DatePickerStyle](https://developer.apple.com/documentation/swiftui/datepickerstyle) — A type that specifies the appearance and interaction of all date pickers within a view hierarchy. _(Apple Developer; expand on demand)_

### Styling menus

- [menuStyle(_:)](https://developer.apple.com/documentation/swiftui/view/menustyle(_:)) — Sets the style for menus within this view. _(Apple Developer; expand on demand)_
- [MenuStyle](https://developer.apple.com/documentation/swiftui/menustyle) — A type that applies standard interaction behavior and a custom appearance to all menus within a view hierarchy. _(Apple Developer; expand on demand)_
- [MenuStyleConfiguration](https://developer.apple.com/documentation/swiftui/menustyleconfiguration) — A configuration of a menu. _(Apple Developer; expand on demand)_

### Styling toggles

- [toggleStyle(_:)](https://developer.apple.com/documentation/swiftui/view/togglestyle(_:)) — Sets the style for toggles in a view hierarchy. _(Apple Developer; expand on demand)_
- [ToggleStyleConfiguration](https://developer.apple.com/documentation/swiftui/togglestyleconfiguration) — The properties of a toggle instance. _(Apple Developer; expand on demand)_

### Styling indicators

- [gaugeStyle(_:)](https://developer.apple.com/documentation/swiftui/view/gaugestyle(_:)) — Sets the style for gauges within this view. _(Apple Developer; expand on demand)_
- [GaugeStyle](https://developer.apple.com/documentation/swiftui/gaugestyle) — Defines the implementation of all gauge instances within a view hierarchy. _(Apple Developer; expand on demand)_
- [GaugeStyleConfiguration](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration) — The properties of a gauge instance. _(Apple Developer; expand on demand)_
- [progressViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/progressviewstyle(_:)) — Sets the style for progress views in this view. _(Apple Developer; expand on demand)_
- [ProgressViewStyle](https://developer.apple.com/documentation/swiftui/progressviewstyle) — A type that applies standard interaction behavior to all progress views within a view hierarchy. _(Apple Developer; expand on demand)_
- [ProgressViewStyleConfiguration](https://developer.apple.com/documentation/swiftui/progressviewstyleconfiguration) — The properties of a progress view instance. _(Apple Developer; expand on demand)_

### Styling views that display text

- [labelStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labelstyle(_:)) — Sets the style for labels within this view. _(Apple Developer; expand on demand)_
- [LabelStyle](https://developer.apple.com/documentation/swiftui/labelstyle) — A type that applies a custom appearance to all labels within a view. _(Apple Developer; expand on demand)_
- [LabelStyleConfiguration](https://developer.apple.com/documentation/swiftui/labelstyleconfiguration) — The properties of a label. _(Apple Developer; expand on demand)_
- [textFieldStyle(_:)](https://developer.apple.com/documentation/swiftui/view/textfieldstyle(_:)) — Sets the style for text fields within this view. _(Apple Developer; expand on demand)_
- [TextFieldStyle](https://developer.apple.com/documentation/swiftui/textfieldstyle) — A specification for the appearance and interaction of a text field. _(Apple Developer; expand on demand)_
- [textEditorStyle(_:)](https://developer.apple.com/documentation/swiftui/view/texteditorstyle(_:)) — Sets the style for text editors within this view. _(Apple Developer; expand on demand)_
- [TextEditorStyle](https://developer.apple.com/documentation/swiftui/texteditorstyle) — A specification for the appearance and interaction of a text editor. _(Apple Developer; expand on demand)_
- [TextEditorStyleConfiguration](https://developer.apple.com/documentation/swiftui/texteditorstyleconfiguration) — The properties of a text editor. _(Apple Developer; expand on demand)_

### Styling collection views

- [listStyle(_:)](https://developer.apple.com/documentation/swiftui/view/liststyle(_:)) — Sets the style for lists within this view. _(Apple Developer; expand on demand)_
- [ListStyle](https://developer.apple.com/documentation/swiftui/liststyle) — A protocol that describes the behavior and appearance of a list. _(Apple Developer; expand on demand)_
- [tableStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tablestyle(_:)) — Sets the style for tables within this view. _(Apple Developer; expand on demand)_
- [TableStyle](https://developer.apple.com/documentation/swiftui/tablestyle) — A type that applies a custom appearance to all tables within a view. _(Apple Developer; expand on demand)_
- [TableStyleConfiguration](https://developer.apple.com/documentation/swiftui/tablestyleconfiguration) — The properties of a table. _(Apple Developer; expand on demand)_
- [disclosureGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/disclosuregroupstyle(_:)) — Sets the style for disclosure groups within this view. _(Apple Developer; expand on demand)_
- [DisclosureGroupStyle](https://developer.apple.com/documentation/swiftui/disclosuregroupstyle) — A type that specifies the appearance and interaction of disclosure groups within a view hierarchy. _(Apple Developer; expand on demand)_

### Styling navigation views

- [navigationSplitViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewstyle(_:)) — Sets the style for navigation split views within this view. _(Apple Developer; expand on demand)_
- [NavigationSplitViewStyle](https://developer.apple.com/documentation/swiftui/navigationsplitviewstyle) — A type that specifies the appearance and interaction of navigation split views within a view hierarchy. _(Apple Developer; expand on demand)_
- [tabViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tabviewstyle(_:)) — Sets the style for the tab view within the current environment. _(Apple Developer; expand on demand)_
- [TabViewStyle](https://developer.apple.com/documentation/swiftui/tabviewstyle) — A specification for the appearance and interaction of a tab view. _(Apple Developer; expand on demand)_

### Styling groups

- [controlGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/controlgroupstyle(_:)) — Sets the style for control groups within this view. _(Apple Developer; expand on demand)_
- [ControlGroupStyle](https://developer.apple.com/documentation/swiftui/controlgroupstyle) — Defines the implementation of all control groups within a view hierarchy. _(Apple Developer; expand on demand)_
- [ControlGroupStyleConfiguration](https://developer.apple.com/documentation/swiftui/controlgroupstyleconfiguration) — The properties of a control group. _(Apple Developer; expand on demand)_
- [formStyle(_:)](https://developer.apple.com/documentation/swiftui/view/formstyle(_:)) — Sets the style for forms in a view hierarchy. _(Apple Developer; expand on demand)_
- [FormStyle](https://developer.apple.com/documentation/swiftui/formstyle) — The appearance and behavior of a form. _(Apple Developer; expand on demand)_
- [FormStyleConfiguration](https://developer.apple.com/documentation/swiftui/formstyleconfiguration) — The properties of a form instance. _(Apple Developer; expand on demand)_
- [groupBoxStyle(_:)](https://developer.apple.com/documentation/swiftui/view/groupboxstyle(_:)) — Sets the style for group boxes within this view. _(Apple Developer; expand on demand)_
- [GroupBoxStyle](https://developer.apple.com/documentation/swiftui/groupboxstyle) — A type that specifies the appearance and interaction of all group boxes within a view hierarchy. _(Apple Developer; expand on demand)_
- [GroupBoxStyleConfiguration](https://developer.apple.com/documentation/swiftui/groupboxstyleconfiguration) — The properties of a group box instance. _(Apple Developer; expand on demand)_
- [indexViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/indexviewstyle(_:)) — Sets the style for the index view within the current environment. _(Apple Developer; expand on demand)_
- [IndexViewStyle](https://developer.apple.com/documentation/swiftui/indexviewstyle) — Defines the implementation of all instances within a view hierarchy. _(Apple Developer; expand on demand)_
- [labeledContentStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labeledcontentstyle(_:)) — Sets a style for labeled content. _(Apple Developer; expand on demand)_
- [LabeledContentStyle](https://developer.apple.com/documentation/swiftui/labeledcontentstyle) — The appearance and behavior of a labeled content instance.. _(Apple Developer; expand on demand)_
- [LabeledContentStyleConfiguration](https://developer.apple.com/documentation/swiftui/labeledcontentstyleconfiguration) — The properties of a labeled content instance. _(Apple Developer; expand on demand)_

### Styling windows from a view inside the window

- [presentedWindowStyle(_:)](https://developer.apple.com/documentation/swiftui/view/presentedwindowstyle(_:)) — Sets the style for windows created by interacting with this view. _(Apple Developer; expand on demand)_
- [presentedWindowToolbarStyle(_:)](https://developer.apple.com/documentation/swiftui/view/presentedwindowtoolbarstyle(_:)) — Sets the style for the toolbar in windows created by interacting with this view. _(Apple Developer; expand on demand)_

### Adding a glass background on views in visionOS

- [glassBackgroundEffect(displayMode:)](https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(displaymode:)) — Fills the view’s background with an automatic glass background effect and container-relative rounded rectangle shape. _(Apple Developer; expand on demand)_
- [glassBackgroundEffect(in:displayMode:)](https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(in:displaymode:)) — Fills the view’s background with an automatic glass background effect and a shape that you specify. _(Apple Developer; expand on demand)_
- [GlassBackgroundDisplayMode](https://developer.apple.com/documentation/swiftui/glassbackgrounddisplaymode) — The display mode of a glass background. _(Apple Developer; expand on demand)_
- [GlassBackgroundEffect](https://developer.apple.com/documentation/swiftui/glassbackgroundeffect) — A specification for the appearance of a glass background. _(Apple Developer; expand on demand)_
- [AutomaticGlassBackgroundEffect](https://developer.apple.com/documentation/swiftui/automaticglassbackgroundeffect) — The automatic glass background effect. _(Apple Developer; expand on demand)_
- [GlassBackgroundEffectConfiguration](https://developer.apple.com/documentation/swiftui/glassbackgroundeffectconfiguration) — A configuration used to build a custom effect. _(Apple Developer; expand on demand)_
- [FeatheredGlassBackgroundEffect](https://developer.apple.com/documentation/swiftui/featheredglassbackgroundeffect) — The feathered glass background effect. _(Apple Developer; expand on demand)_
- [PlateGlassBackgroundEffect](https://developer.apple.com/documentation/swiftui/plateglassbackgroundeffect) — The plate glass background effect. _(Apple Developer; expand on demand)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(local context)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(local context)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(local context)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(local context)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(local context)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(local context)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(local context)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(local context)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/view-styles)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `58c34e0d2c1eb941ef7df0bfae963f2cfa7b1cc341ea94b22be2db8e793d964e`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
