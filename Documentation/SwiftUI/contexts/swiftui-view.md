---
title: "View"
source_url: "https://developer.apple.com/documentation/swiftui/view"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "b562c24ef65197c645bccaecf9fe4e5d9e0bfb88e0b0844b4d0cb189e3121875"
source_etag: "W/\"e811f5e765b6c249001a4581d406270c\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Overview"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# View

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Protocol
- Módulo: SwiftUI
- Relevância para Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Disponibilidade: iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 6.0+
- Declaração: `@MainActor @preconcurrency protocol View`

## Síntese

**Resumo oficial:** A type that represents part of your app’s user interface and provides modifiers that you use to configure views.

You create custom views by declaring types that conform to the protocol. Implement the required body computed property to provide the content for your custom view. Assemble the view’s body by combining one or more of the built-in views provided by SwiftUI, like the Text instance in the example above, plus other custom views that you define, into a hierarchy of views. For more information about creating custom views, see Declaring a custom view. The protocol provides a set of modifiers — protocol methods with default implementations — that you use to configure views in the layout of your app. Modifiers work by wrapping the view instance on which you call them in another view with the specified characteristics, as described in Configuring views. For example, adding the opacity(_:) modifier to a text view returns a new view with some amount of transparency: The complete list of default modifiers provides…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [body](https://developer.apple.com/documentation/swiftui/view/body-8kl5o) — The content and behavior of the view. _(Apple Developer; expandir sob demanda)_
- [Text](https://developer.apple.com/documentation/swiftui/text) — A view that displays one or more lines of read-only text. _(Apple Developer; expandir sob demanda)_
- [Declaring a custom view](https://developer.apple.com/documentation/swiftui/declaring-a-custom-view) — Define views and assemble them into a view hierarchy. _(Apple Developer; expandir sob demanda)_
- [Configuring views](https://developer.apple.com/documentation/swiftui/configuring-views) — Adjust the characteristics of a view by applying view modifiers. _(Apple Developer; expandir sob demanda)_
- [opacity(_:)](https://developer.apple.com/documentation/swiftui/view/opacity(_:)) — Sets the transparency of this view. _(Apple Developer; expandir sob demanda)_
- [Layout modifiers](https://developer.apple.com/documentation/swiftui/view-layout) — Tell a view how to arrange itself within a view hierarchy by adjusting its size, position, alignment, padding, and so on. _(Apple Developer; expandir sob demanda)_
- [Accessibility modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility) — Make your SwiftUI apps accessible to everyone, including people with disabilities. _(Apple Developer; expandir sob demanda)_
- [Input and event modifiers](https://developer.apple.com/documentation/swiftui/view-input-and-events) — Supply actions for a view to perform in response to user input and system events. _(Apple Developer; expandir sob demanda)_

### Implementing a custom view

- [Body](https://developer.apple.com/documentation/swiftui/view/body-swift.associatedtype) — The type of view representing the body of this view. _(Apple Developer; expandir sob demanda)_
- [modifier(_:)](https://developer.apple.com/documentation/swiftui/view/modifier(_:)) — Applies a modifier to a view and returns a new view. _(Apple Developer; expandir sob demanda)_
- [Previews in Xcode](swiftui-previews-in-xcode.md) — Generate dynamic, interactive previews of your custom views. _(contexto local)_

### Configuring view elements

- [Appearance modifiers](https://developer.apple.com/documentation/swiftui/view-appearance) — Configure a view’s foreground and background styles, controls, and visibility. _(Apple Developer; expandir sob demanda)_
- [Text and symbol modifiers](https://developer.apple.com/documentation/swiftui/view-text-and-symbols) — Manage the rendering, selection, and entry of text in your view. _(Apple Developer; expandir sob demanda)_
- [Auxiliary view modifiers](https://developer.apple.com/documentation/swiftui/view-auxiliary-views) — Add and configure supporting views, like toolbars and context menus. _(Apple Developer; expandir sob demanda)_
- [Chart view modifiers](https://developer.apple.com/documentation/swiftui/view-chart-view) — Configure charts that you declare with Swift Charts. _(Apple Developer; expandir sob demanda)_

### Drawing views

- [Style modifiers](https://developer.apple.com/documentation/swiftui/view-style-modifiers) — Apply built-in styles to different types of views. _(Apple Developer; expandir sob demanda)_
- [Graphics and rendering modifiers](https://developer.apple.com/documentation/swiftui/view-graphics-and-rendering) — Affect the way the system draws a view, for example by scaling or masking a view, or by applying graphical effects. _(Apple Developer; expandir sob demanda)_

### Providing interactivity

- [Search modifiers](https://developer.apple.com/documentation/swiftui/view-search) — Enable people to search for content in your app. _(Apple Developer; expandir sob demanda)_
- [Presentation modifiers](https://developer.apple.com/documentation/swiftui/view-presentation) — Define additional views for the view to present under specified conditions. _(Apple Developer; expandir sob demanda)_
- [State modifiers](https://developer.apple.com/documentation/swiftui/view-state) — Access storage and provide child views with configuration data. _(Apple Developer; expandir sob demanda)_

### Modifying technology-specific views

- [Technology-specific modifiers](https://developer.apple.com/documentation/swiftui/view-technology-modifiers) — Add modifiers to customize SwiftUI views that other Apple frameworks provide. _(Apple Developer; expandir sob demanda)_

### Deprecated modifiers

- [Deprecated modifiers](https://developer.apple.com/documentation/swiftui/view-deprecated) — Review unsupported modifiers and their replacements. _(Apple Developer; expandir sob demanda)_

### Instance Methods

- [toolbarMinimizationBehavior(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)) — Sets the minimize behavior for the specified bars. _(Apple Developer; expandir sob demanda)_
- [toolbarMinimizationRestoration(_:for:)](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationrestoration(_:for:)) — Sets the restoration behavior for the specified bars during minimization. _(Apple Developer; expandir sob demanda)_

### Creating a view

- [Wishlist: Planning travel in a SwiftUI app](swiftui-wishlist-planning-travel-in-a-swiftui-app.md) — Build a travel planning app that organizes trips into collections and tracks activity completion. _(contexto local)_
- [ContentBuilder](https://developer.apple.com/documentation/swiftui/contentbuilder) — A custom parameter attribute that constructs views and other content types from closures. _(Apple Developer; expandir sob demanda)_
- [ViewBuilder](https://developer.apple.com/documentation/swiftui/viewbuilder) — A custom parameter attribute that constructs views from closures. _(Apple Developer; expandir sob demanda)_

### Inherited By

- [DynamicViewContent](https://developer.apple.com/documentation/swiftui/dynamicviewcontent) — A type of view that generates views from an underlying collection of data. _(Apple Developer; expandir sob demanda)_
- [InsettableShape](https://developer.apple.com/documentation/swiftui/insettableshape) — A shape type that is able to inset itself to produce another shape. _(Apple Developer; expandir sob demanda)_
- [NSViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/nsviewcontrollerrepresentable) — A wrapper that you use to integrate an AppKit view controller into your SwiftUI interface. _(Apple Developer; expandir sob demanda)_
- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable) — A wrapper that you use to integrate an AppKit view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [RoundedRectangularShape](https://developer.apple.com/documentation/swiftui/roundedrectangularshape) — A protocol of InsettableShape that describes a rounded rectangular shape. _(Apple Developer; expandir sob demanda)_
- [Shape](https://developer.apple.com/documentation/swiftui/shape) — A 2D shape that you can use when drawing a view. _(Apple Developer; expandir sob demanda)_
- [ShapeView](https://developer.apple.com/documentation/swiftui/shapeview) — A view that provides a shape that you can use for drawing operations. _(Apple Developer; expandir sob demanda)_
- [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable) — A view that represents a UIKit view controller. _(Apple Developer; expandir sob demanda)_
- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable) — A wrapper for a UIKit view that you use to integrate that view into your SwiftUI view hierarchy. _(Apple Developer; expandir sob demanda)_
- [WKInterfaceObjectRepresentable](https://developer.apple.com/documentation/swiftui/wkinterfaceobjectrepresentable) — A view that represents a WatchKit interface object. _(Apple Developer; expandir sob demanda)_

### Conforming Types

- [AngularGradient](https://developer.apple.com/documentation/swiftui/angulargradient) — An angular gradient. _(Apple Developer; expandir sob demanda)_
- [AnyShape](https://developer.apple.com/documentation/swiftui/anyshape) — A type-erased shape value. _(Apple Developer; expandir sob demanda)_
- [AnyView](https://developer.apple.com/documentation/swiftui/anyview) — A type-erased view. _(Apple Developer; expandir sob demanda)_
- [AsyncImage](https://developer.apple.com/documentation/swiftui/asyncimage) — A view that asynchronously loads and displays an image. _(Apple Developer; expandir sob demanda)_
- [Button](https://developer.apple.com/documentation/swiftui/button) — A control that initiates an action. _(Apple Developer; expandir sob demanda)_
- [ButtonBorderShape](https://developer.apple.com/documentation/swiftui/buttonbordershape) — A shape used to draw a button’s border. _(Apple Developer; expandir sob demanda)_
- [ButtonStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/buttonstyleconfiguration/label-swift.struct) — A type-erased label of a button. _(Apple Developer; expandir sob demanda)_
- [Canvas](https://developer.apple.com/documentation/swiftui/canvas) — A view type that supports immediate mode drawing. _(Apple Developer; expandir sob demanda)_
- [Capsule](https://developer.apple.com/documentation/swiftui/capsule) — A capsule shape aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [Circle](https://developer.apple.com/documentation/swiftui/circle) — A circle centered on the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [Color](https://developer.apple.com/documentation/swiftui/color) — A representation of a color that adapts to a given context. _(Apple Developer; expandir sob demanda)_
- [ColorPicker](https://developer.apple.com/documentation/swiftui/colorpicker) — A control used to select a color from the system color picker UI. _(Apple Developer; expandir sob demanda)_
- [ConcentricRectangle](https://developer.apple.com/documentation/swiftui/concentricrectangle) — A shape whose corners you configure, individually or uniformly, to be squared, rounded, or concentric relative to a container shape’s corners. _(Apple Developer; expandir sob demanda)_
- [ContainerRelativeShape](https://developer.apple.com/documentation/swiftui/containerrelativeshape) — A shape whose dimensions the system calculates from an inset version of the current container shape. _(Apple Developer; expandir sob demanda)_
- [ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview) — An interface, consisting of a label and additional content, that you display when the content of your app is unavailable to users. _(Apple Developer; expandir sob demanda)_
- [ControlGroup](https://developer.apple.com/documentation/swiftui/controlgroup) — A container view that displays semantically-related controls in a visually-appropriate manner for the context _(Apple Developer; expandir sob demanda)_
- [ControlGroupStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/controlgroupstyleconfiguration/content-swift.struct) — A type-erased content of a . _(Apple Developer; expandir sob demanda)_
- [ControlGroupStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/controlgroupstyleconfiguration/label-swift.struct) — A type-erased label of a ControlGroup. _(Apple Developer; expandir sob demanda)_
- [DatePicker](https://developer.apple.com/documentation/swiftui/datepicker) — A control for selecting an absolute date. _(Apple Developer; expandir sob demanda)_
- [DatePickerStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/datepickerstyleconfiguration/label-swift.struct) — A type-erased label of a . _(Apple Developer; expandir sob demanda)_
- [DebugReplaceableView](https://developer.apple.com/documentation/swiftui/debugreplaceableview) — Erases view opaque result types in debug builds. _(Apple Developer; expandir sob demanda)_
- [DefaultButtonLabel](https://developer.apple.com/documentation/swiftui/defaultbuttonlabel) — The default label to use for a button. _(Apple Developer; expandir sob demanda)_
- [DefaultDateProgressLabel](https://developer.apple.com/documentation/swiftui/defaultdateprogresslabel) — The default type of the current value label when used by a date-relative progress view. _(Apple Developer; expandir sob demanda)_
- [DefaultDocumentGroupLaunchActions](https://developer.apple.com/documentation/swiftui/defaultdocumentgrouplaunchactions) — The default actions for the document group launch scene and the document launch view. _(Apple Developer; expandir sob demanda)_
- [DefaultGlassEffectShape](https://developer.apple.com/documentation/swiftui/defaultglasseffectshape) — The default shape applied by glass effects, a capsule. _(Apple Developer; expandir sob demanda)_
- [DefaultNewDocumentButtonLabel](https://developer.apple.com/documentation/swiftui/defaultnewdocumentbuttonlabel) — The default label used for a new document button. _(Apple Developer; expandir sob demanda)_
- [DefaultSettingsLinkLabel](https://developer.apple.com/documentation/swiftui/defaultsettingslinklabel) — The default label to use for a settings link. _(Apple Developer; expandir sob demanda)_
- [DefaultShareLinkLabel](https://developer.apple.com/documentation/swiftui/defaultsharelinklabel) — The default label used for a share link. _(Apple Developer; expandir sob demanda)_
- [DefaultTabLabel](https://developer.apple.com/documentation/swiftui/defaulttablabel) — The default label to use for a tab or tab section. _(Apple Developer; expandir sob demanda)_
- [DefaultWindowVisibilityToggleLabel](https://developer.apple.com/documentation/swiftui/defaultwindowvisibilitytogglelabel) — The default label of a window visibility toggle. _(Apple Developer; expandir sob demanda)_
- [DisclosureGroup](https://developer.apple.com/documentation/swiftui/disclosuregroup) — A view that shows or hides another content view, based on the state of a disclosure control. _(Apple Developer; expandir sob demanda)_
- [DisclosureGroupStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/disclosuregroupstyleconfiguration/content-swift.struct) — A type-erased content of a disclosure group. _(Apple Developer; expandir sob demanda)_
- [DisclosureGroupStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/disclosuregroupstyleconfiguration/label-swift.struct) — A type-erased label of a disclosure group. _(Apple Developer; expandir sob demanda)_
- [Divider](https://developer.apple.com/documentation/swiftui/divider) — A visual element that can be used to separate other content. _(Apple Developer; expandir sob demanda)_
- [DocumentLaunchView](https://developer.apple.com/documentation/swiftui/documentlaunchview) — A view to present when launching document-related user experience. _(Apple Developer; expandir sob demanda)_
- [EditButton](https://developer.apple.com/documentation/swiftui/editbutton) — A button that toggles the edit mode environment value. _(Apple Developer; expandir sob demanda)_
- [EditableCollectionContent](https://developer.apple.com/documentation/swiftui/editablecollectioncontent) — An opaque wrapper view that adds editing capabilities to a row in a list. _(Apple Developer; expandir sob demanda)_
- [Ellipse](https://developer.apple.com/documentation/swiftui/ellipse) — An ellipse aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [EllipticalGradient](https://developer.apple.com/documentation/swiftui/ellipticalgradient) — A radial gradient that draws an ellipse. _(Apple Developer; expandir sob demanda)_
- [EmptyView](https://developer.apple.com/documentation/swiftui/emptyview) — A view that doesn’t contain any content. _(Apple Developer; expandir sob demanda)_
- [EquatableView](https://developer.apple.com/documentation/swiftui/equatableview) — A view type that compares itself against its previous value and prevents its child updating if its new value is the same as its… _(Apple Developer; expandir sob demanda)_
- [FillShapeView](https://developer.apple.com/documentation/swiftui/fillshapeview) — A shape provider that fills its shape. _(Apple Developer; expandir sob demanda)_
- [ForEach](https://developer.apple.com/documentation/swiftui/foreach) — A structure that computes views on demand from an underlying collection of identified data. _(Apple Developer; expandir sob demanda)_
- [Form](swiftui-form.md) — A container for grouping controls used for data entry, such as in settings or inspectors. _(Apple Developer; expandir sob demanda)_
- [FormStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/formstyleconfiguration/content-swift.struct) — A type-erased content of a form. _(Apple Developer; expandir sob demanda)_
- [Gauge](https://developer.apple.com/documentation/swiftui/gauge) — A view that shows a value within a range. _(Apple Developer; expandir sob demanda)_
- [GaugeStyleConfiguration.CurrentValueLabel](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration/currentvaluelabel-swift.struct) — A type-erased value label of a gauge that contains the current value. _(Apple Developer; expandir sob demanda)_
- [GaugeStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration/label-swift.struct) — A type-erased label of a gauge, describing its purpose. _(Apple Developer; expandir sob demanda)_
- [GaugeStyleConfiguration.MarkedValueLabel](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration/markedvaluelabel) — A type-erased label describing a specific value of a gauge. _(Apple Developer; expandir sob demanda)_
- [GaugeStyleConfiguration.MaximumValueLabel](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration/maximumvaluelabel-swift.struct) — A type-erased value label of a gauge describing the maximum value. _(Apple Developer; expandir sob demanda)_
- [GaugeStyleConfiguration.MinimumValueLabel](https://developer.apple.com/documentation/swiftui/gaugestyleconfiguration/minimumvaluelabel-swift.struct) — A type-erased value label of a gauge describing the minimum value. _(Apple Developer; expandir sob demanda)_
- [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader) — A container view that defines its content as a function of its own size and coordinate space. _(Apple Developer; expandir sob demanda)_
- [GeometryReader3D](https://developer.apple.com/documentation/swiftui/geometryreader3d) — A container view that defines its content as a function of its own size and coordinate space. _(Apple Developer; expandir sob demanda)_
- [GlassBackgroundEffectConfiguration.Content](https://developer.apple.com/documentation/swiftui/glassbackgroundeffectconfiguration/content-swift.struct) — A type-erased content of a glass background. _(Apple Developer; expandir sob demanda)_
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) — A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another. _(Apple Developer; expandir sob demanda)_
- [Grid](https://developer.apple.com/documentation/swiftui/grid) — A container view that arranges other views in a two dimensional layout. _(Apple Developer; expandir sob demanda)_
- [GridRow](https://developer.apple.com/documentation/swiftui/gridrow) — A horizontal row in a two dimensional grid container. _(Apple Developer; expandir sob demanda)_
- [Group](https://developer.apple.com/documentation/swiftui/group) — A type that collects multiple instances of a content type — like views, scenes, or commands — into a single unit. _(Apple Developer; expandir sob demanda)_
- [GroupBox](https://developer.apple.com/documentation/swiftui/groupbox) — A stylized view, with an optional label, that visually collects a logical grouping of content. _(Apple Developer; expandir sob demanda)_
- [GroupBoxStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/groupboxstyleconfiguration/content-swift.struct) — A type-erased content of a group box. _(Apple Developer; expandir sob demanda)_
- [GroupBoxStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/groupboxstyleconfiguration/label-swift.struct) — A type-erased label of a group box. _(Apple Developer; expandir sob demanda)_
- [GroupElementsOfContent](https://developer.apple.com/documentation/swiftui/groupelementsofcontent) — Transforms the subviews of a given view into a resulting content view. _(Apple Developer; expandir sob demanda)_
- [GroupSectionsOfContent](https://developer.apple.com/documentation/swiftui/groupsectionsofcontent) — Transforms the sections of a given view into a resulting content view. _(Apple Developer; expandir sob demanda)_
- [HSplitView](https://developer.apple.com/documentation/swiftui/hsplitview) — A layout container that arranges its children in a horizontal line and allows the user to resize them using dividers placed between them. _(Apple Developer; expandir sob demanda)_
- [HStack](https://developer.apple.com/documentation/swiftui/hstack) — A view that arranges its subviews in a horizontal line. _(Apple Developer; expandir sob demanda)_
- [HelpLink](https://developer.apple.com/documentation/swiftui/helplink) — A button with a standard appearance that opens app-specific help documentation. _(Apple Developer; expandir sob demanda)_
- [Image](https://developer.apple.com/documentation/swiftui/image) — A view that displays an image. _(Apple Developer; expandir sob demanda)_
- [KeyframeAnimator](https://developer.apple.com/documentation/swiftui/keyframeanimator) — A container that animates its content with keyframes. _(Apple Developer; expandir sob demanda)_
- [Label](https://developer.apple.com/documentation/swiftui/label) — A standard label for user interface items, consisting of an icon with a title. _(Apple Developer; expandir sob demanda)_
- [LabelStyleConfiguration.Icon](https://developer.apple.com/documentation/swiftui/labelstyleconfiguration/icon-swift.struct) — A type-erased icon view of a label. _(Apple Developer; expandir sob demanda)_
- [LabelStyleConfiguration.Title](https://developer.apple.com/documentation/swiftui/labelstyleconfiguration/title-swift.struct) — A type-erased title view of a label. _(Apple Developer; expandir sob demanda)_
- [LabeledContent](https://developer.apple.com/documentation/swiftui/labeledcontent) — A container for attaching a label to a value-bearing view. _(Apple Developer; expandir sob demanda)_
- [LabeledContentStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/labeledcontentstyleconfiguration/content-swift.struct) — A type-erased content of a labeled content instance. _(Apple Developer; expandir sob demanda)_
- [LabeledContentStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/labeledcontentstyleconfiguration/label-swift.struct) — A type-erased label of a labeled content instance. _(Apple Developer; expandir sob demanda)_
- [LabeledControlGroupContent](https://developer.apple.com/documentation/swiftui/labeledcontrolgroupcontent) — A view that represents the body of a control group with a specified label. _(Apple Developer; expandir sob demanda)_
- [LabeledToolbarItemGroupContent](https://developer.apple.com/documentation/swiftui/labeledtoolbaritemgroupcontent) — A view that represents the view of a toolbar item group with a specified label. _(Apple Developer; expandir sob demanda)_
- [LazyHGrid](https://developer.apple.com/documentation/swiftui/lazyhgrid) — A container view that arranges its child views in a grid that grows horizontally, creating items only as needed. _(Apple Developer; expandir sob demanda)_
- [LazyHStack](https://developer.apple.com/documentation/swiftui/lazyhstack) — A view that arranges its children in a line that grows horizontally, creating items only as needed. _(Apple Developer; expandir sob demanda)_
- [LazyVGrid](https://developer.apple.com/documentation/swiftui/lazyvgrid) — A container view that arranges its child views in a grid that grows vertically, creating items only as needed. _(Apple Developer; expandir sob demanda)_
- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack) — A view that arranges its children in a line that grows vertically, creating items only as needed. _(Apple Developer; expandir sob demanda)_
- [LinearGradient](https://developer.apple.com/documentation/swiftui/lineargradient) — A linear gradient. _(Apple Developer; expandir sob demanda)_
- [Link](https://developer.apple.com/documentation/swiftui/link) — A control for navigating to a URL. _(Apple Developer; expandir sob demanda)_
- [List](https://developer.apple.com/documentation/swiftui/list) — A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members. _(Apple Developer; expandir sob demanda)_
- [Menu](https://developer.apple.com/documentation/swiftui/menu) — A control for presenting a menu of actions. _(Apple Developer; expandir sob demanda)_
- [MenuButton](https://developer.apple.com/documentation/swiftui/menubutton) — A button that displays a menu containing a list of choices when pressed. _(Apple Developer; expandir sob demanda)_
- [MenuStyleConfiguration.Content](https://developer.apple.com/documentation/swiftui/menustyleconfiguration/content) — A type-erased content of a menu. _(Apple Developer; expandir sob demanda)_
- [MenuStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/menustyleconfiguration/label) — A type-erased label of a menu. _(Apple Developer; expandir sob demanda)_
- [MeshGradient](https://developer.apple.com/documentation/swiftui/meshgradient) — A two-dimensional gradient defined by a 2D grid of positioned colors. _(Apple Developer; expandir sob demanda)_
- [ModifiedContent](https://developer.apple.com/documentation/swiftui/modifiedcontent) — A value with a modifier applied to it. _(Apple Developer; expandir sob demanda)_
- [MultiDatePicker](https://developer.apple.com/documentation/swiftui/multidatepicker) — A control for picking multiple dates. _(Apple Developer; expandir sob demanda)_
- [NavigationLink](https://developer.apple.com/documentation/swiftui/navigationlink) — A view that controls a navigation presentation. _(Apple Developer; expandir sob demanda)_
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) — A view that presents views in two or three columns, where selections in leading columns control presentations in subsequent columns. _(Apple Developer; expandir sob demanda)_
- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) — A view that displays a root view and enables you to present additional views over the root view. _(Apple Developer; expandir sob demanda)_
- [NavigationView](https://developer.apple.com/documentation/swiftui/navigationview) — A view for presenting a stack of views that represents a visible path in a navigation hierarchy. _(Apple Developer; expandir sob demanda)_
- [NewDocumentButton](https://developer.apple.com/documentation/swiftui/newdocumentbutton) — A button that creates and opens new documents. _(Apple Developer; expandir sob demanda)_
- [OffsetShape](https://developer.apple.com/documentation/swiftui/offsetshape) — A shape with a translation offset transform applied to it. _(Apple Developer; expandir sob demanda)_
- [OutlineGroup](https://developer.apple.com/documentation/swiftui/outlinegroup) — A structure that computes views and disclosure groups on demand from an underlying collection of tree-structured, identified data. _(Apple Developer; expandir sob demanda)_
- [OutlineSubgroupChildren](https://developer.apple.com/documentation/swiftui/outlinesubgroupchildren) — A type-erased view representing the children in an outline subgroup. _(Apple Developer; expandir sob demanda)_
- [PasteButton](https://developer.apple.com/documentation/swiftui/pastebutton) — A system button that reads items from the pasteboard and delivers it to a closure. _(Apple Developer; expandir sob demanda)_
- [Path](https://developer.apple.com/documentation/swiftui/path) — The outline of a 2D shape. _(Apple Developer; expandir sob demanda)_
- [PhaseAnimator](https://developer.apple.com/documentation/swiftui/phaseanimator) — A container that animates its content by automatically cycling through a collection of phases that you provide, each defining a discrete step within an… _(Apple Developer; expandir sob demanda)_
- [Picker](https://developer.apple.com/documentation/swiftui/picker) — A control for selecting from a set of mutually exclusive values. _(Apple Developer; expandir sob demanda)_
- [PlaceholderContentView](https://developer.apple.com/documentation/swiftui/placeholdercontentview) — A placeholder used to construct an inline modifier, transition, or other helper type. _(Apple Developer; expandir sob demanda)_
- [PresentedWindowContent](https://developer.apple.com/documentation/swiftui/presentedwindowcontent) — A view that represents the content of a presented window. _(Apple Developer; expandir sob demanda)_
- [PreviewModifierContent](https://developer.apple.com/documentation/swiftui/previewmodifiercontent) — The type-erased content of a preview. _(Apple Developer; expandir sob demanda)_
- [PrimitiveButtonStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/primitivebuttonstyleconfiguration/label-swift.struct) — A type-erased label of a button. _(Apple Developer; expandir sob demanda)_
- [ProgressView](https://developer.apple.com/documentation/swiftui/progressview) — A view that shows the progress toward completion of a task. _(Apple Developer; expandir sob demanda)_
- [ProgressViewStyleConfiguration.CurrentValueLabel](https://developer.apple.com/documentation/swiftui/progressviewstyleconfiguration/currentvaluelabel-swift.struct) — A type-erased label that describes the current value of a progress view. _(Apple Developer; expandir sob demanda)_
- [ProgressViewStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/progressviewstyleconfiguration/label-swift.struct) — A type-erased label describing the task represented by the progress view. _(Apple Developer; expandir sob demanda)_
- [RadialGradient](https://developer.apple.com/documentation/swiftui/radialgradient) — A radial gradient. _(Apple Developer; expandir sob demanda)_
- [Rectangle](https://developer.apple.com/documentation/swiftui/rectangle) — A rectangular shape aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [RenameButton](https://developer.apple.com/documentation/swiftui/renamebutton) — A button that triggers a standard rename action. _(Apple Developer; expandir sob demanda)_
- [RotatedShape](https://developer.apple.com/documentation/swiftui/rotatedshape) — A shape with a rotation transform applied to it. _(Apple Developer; expandir sob demanda)_
- [RoundedRectangle](https://developer.apple.com/documentation/swiftui/roundedrectangle) — A rectangular shape with rounded corners, aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [ScaledShape](https://developer.apple.com/documentation/swiftui/scaledshape) — A shape with a scale transform applied to it. _(Apple Developer; expandir sob demanda)_
- [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview) — A scrollable view. _(Apple Developer; expandir sob demanda)_
- [ScrollViewReader](https://developer.apple.com/documentation/swiftui/scrollviewreader) — A view that provides programmatic scrolling, by working with a proxy to scroll to known child views. _(Apple Developer; expandir sob demanda)_
- [SearchUnavailableContent.Actions](https://developer.apple.com/documentation/swiftui/searchunavailablecontent/actions) — A view that represents the actions of a static view. _(Apple Developer; expandir sob demanda)_
- [SearchUnavailableContent.Description](https://developer.apple.com/documentation/swiftui/searchunavailablecontent/description) — A view that represents the description of a static view. _(Apple Developer; expandir sob demanda)_
- [SearchUnavailableContent.Label](https://developer.apple.com/documentation/swiftui/searchunavailablecontent/label) — A view that represents the label of a static placeholder search view. _(Apple Developer; expandir sob demanda)_
- [Section](https://developer.apple.com/documentation/swiftui/section) — A container view that you can use to add hierarchy within certain views. _(Apple Developer; expandir sob demanda)_
- [SectionConfiguration.Actions](https://developer.apple.com/documentation/swiftui/sectionconfiguration/actions-swift.struct) — The type-erased actions of a section. _(Apple Developer; expandir sob demanda)_
- [SecureField](https://developer.apple.com/documentation/swiftui/securefield) — A control into which people securely enter private text. _(Apple Developer; expandir sob demanda)_
- [SettingsLink](https://developer.apple.com/documentation/swiftui/settingslink) — A view that opens the Settings scene defined by an app. _(Apple Developer; expandir sob demanda)_
- [ShareLink](https://developer.apple.com/documentation/swiftui/sharelink) — A view that controls a sharing presentation. _(Apple Developer; expandir sob demanda)_
- [Slider](https://developer.apple.com/documentation/swiftui/slider) — A control for selecting a value from a bounded linear range of values. _(Apple Developer; expandir sob demanda)_
- [Spacer](https://developer.apple.com/documentation/swiftui/spacer) — A flexible space that expands along the major axis of its containing stack layout, or on both axes if not contained in a stack. _(Apple Developer; expandir sob demanda)_
- [Stepper](https://developer.apple.com/documentation/swiftui/stepper) — A control that performs increment and decrement actions. _(Apple Developer; expandir sob demanda)_
- [StrokeBorderShapeView](https://developer.apple.com/documentation/swiftui/strokebordershapeview) — A shape provider that strokes the border of its shape. _(Apple Developer; expandir sob demanda)_
- [StrokeShapeView](https://developer.apple.com/documentation/swiftui/strokeshapeview) — A shape provider that strokes its shape. _(Apple Developer; expandir sob demanda)_
- [SubscriptionView](https://developer.apple.com/documentation/swiftui/subscriptionview) — A view that subscribes to a publisher with an action. _(Apple Developer; expandir sob demanda)_
- [Subview](https://developer.apple.com/documentation/swiftui/subview) — An opaque value representing a subview of another view. _(Apple Developer; expandir sob demanda)_
- [SubviewsCollection](https://developer.apple.com/documentation/swiftui/subviewscollection) — An opaque collection representing the subviews of view. _(Apple Developer; expandir sob demanda)_
- [SubviewsCollectionSlice](https://developer.apple.com/documentation/swiftui/subviewscollectionslice) — A slice of a SubviewsCollection. _(Apple Developer; expandir sob demanda)_
- [TabContentBuilder.Content](https://developer.apple.com/documentation/swiftui/tabcontentbuilder/content) — A view representation of the content of a builder-based tab view with selection. _(Apple Developer; expandir sob demanda)_
- [TabView](https://developer.apple.com/documentation/swiftui/tabview) — A view that switches between multiple child views using interactive user interface elements. _(Apple Developer; expandir sob demanda)_
- [Table](https://developer.apple.com/documentation/swiftui/table) — A container that presents rows of data arranged in one or more columns, optionally providing the ability to select one or more members. _(Apple Developer; expandir sob demanda)_
- [TextEditor](https://developer.apple.com/documentation/swiftui/texteditor) — A view that can display and edit long-form text. _(Apple Developer; expandir sob demanda)_
- [TextField](https://developer.apple.com/documentation/swiftui/textfield) — A control that displays an editable text interface. _(Apple Developer; expandir sob demanda)_
- [TextFieldLink](https://developer.apple.com/documentation/swiftui/textfieldlink) — A control that requests text input from the user when pressed. _(Apple Developer; expandir sob demanda)_
- [TextInputBorderShape](https://developer.apple.com/documentation/swiftui/textinputbordershape) — A shape used to draw the border of a text input control. _(Apple Developer; expandir sob demanda)_
- [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview) — A view that updates according to a schedule that you provide. _(Apple Developer; expandir sob demanda)_
- [Toggle](https://developer.apple.com/documentation/swiftui/toggle) — A control that toggles between on and off states. _(Apple Developer; expandir sob demanda)_
- [ToggleStyleConfiguration.Label](https://developer.apple.com/documentation/swiftui/togglestyleconfiguration/label-swift.struct) — A type-erased label of a toggle. _(Apple Developer; expandir sob demanda)_
- [TransformedShape](https://developer.apple.com/documentation/swiftui/transformedshape) — A shape with an affine transform applied to it. _(Apple Developer; expandir sob demanda)_
- [TupleContent](https://developer.apple.com/documentation/swiftui/tuplecontent) — Content created from a tuple of content to be treated as siblings. _(Apple Developer; expandir sob demanda)_
- [TupleView](https://developer.apple.com/documentation/swiftui/tupleview) — A View created from a swift tuple of View values. _(Apple Developer; expandir sob demanda)_
- [UnevenRoundedRectangle](https://developer.apple.com/documentation/swiftui/unevenroundedrectangle) — A rectangular shape with rounded corners with different values, aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [VSplitView](https://developer.apple.com/documentation/swiftui/vsplitview) — A layout container that arranges its children in a vertical line and allows the user to resize them using dividers placed between them. _(Apple Developer; expandir sob demanda)_
- [VStack](https://developer.apple.com/documentation/swiftui/vstack) — A view that arranges its subviews in a vertical line. _(Apple Developer; expandir sob demanda)_
- [ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits) — A view that adapts to the available space by providing the first child view that fits. _(Apple Developer; expandir sob demanda)_
- [WindowVisibilityToggle](https://developer.apple.com/documentation/swiftui/windowvisibilitytoggle) — A specialized button for toggling the visibility of a window. _(Apple Developer; expandir sob demanda)_
- [ZStack](https://developer.apple.com/documentation/swiftui/zstack) — A view that overlays its subviews, aligning them in both axes. _(Apple Developer; expandir sob demanda)_
- [ZStackContent3D](https://developer.apple.com/documentation/swiftui/zstackcontent3d) — A type that adds spacing to a ZStack. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `b562c24ef65197c645bccaecf9fe4e5d9e0bfb88e0b0844b4d0cb189e3121875`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
