---
title: "SwiftUI updates"
source_url: "https://developer.apple.com/documentation/Updates/SwiftUI"
source_identifier: "doc://com.apple.Updates/documentation/Updates/SwiftUI"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "818a25f109c9b6a8296bd116466bafafa37bee5162ad08d412b5265db6f22a96"
source_etag: "W/\"50823d021c79da2384412d4695309a44\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Essentials"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# SwiftUI updates

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Article
- Módulo: Updates
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Learn about important changes to SwiftUI.

Browse notable changes in SwiftUI. Build your project in Xcode 27 or later so that the attribute uses the State() macro to create a state value in an App, Scene, or View. This change only initializes and stores your property once when it’s a class. Build your project in Xcode 27 or later to construct type-agnostic content from closures that you mark with ContentBuilder, which serves as the unified replacement for type-specific builders like ToolbarContentBuilder and CommandsBuilder. Add reordering by drag-and-drop in containers such as lists, stacks, grids, or custom layouts with reorderable() and reorderContainer(for:isEnabled:move:). Add custom swipe actions to views in containers such as scroll views, stacks, grids, or custom layouts using swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:) and swipeActionsContainer(). Specify the crossFade transition to have a sheet appear by fading in over content. Cache images locally that you download with AsyncImage, using asyncImageURLSession(_:), init(request:scale:), init(request:scale:content:placeholder:), and init(request:scale:transaction:content:). Use the visibilityPriority(_:) modifier to prioritize…

## Mapa do conteúdo

- Overview
- June 2026
- General
- Transitions
- Images
- Toolbars
- Documents
- Tab bars
- Alerts and confirmation dialogs
- Gestures
- June 2025
- Text
- Accessibility
- HDR
- UIKit and AppKit integration
- Immersive spaces
- June 2024
- Volumes
- Windows
- Navigation
- Modal presentations
- Views
- Animation
- Text input and output
- Drawing and graphics
- Layout
- Scrolling
- Input events
- Previews in Xcode
- Framework interoperability
- June 2023, visionOS
- Scenes
- Toolbars and ornaments
- View configuration
- View layout
- June 2023
- Search
- Data and storage
- Shapes
- Lists and tables
- Focus

## Links do segundo nível

### Overview and featured references

- [SwiftUI](swiftui.md) — Declare the user interface and behavior for your app on every platform. _(contexto local)_
- [State()](https://developer.apple.com/documentation/SwiftUI/State()) — Creates a property that can read and write a value managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [App](https://developer.apple.com/documentation/SwiftUI/App) — A type that represents the structure and behavior of an app. _(Apple Developer; expandir sob demanda)_
- [Scene](https://developer.apple.com/documentation/SwiftUI/Scene) — A part of an app’s user interface with a life cycle managed by the system. _(Apple Developer; expandir sob demanda)_
- [View](https://developer.apple.com/documentation/SwiftUI/View) — A type that represents part of your app’s user interface and provides modifiers that you use to configure views. _(Apple Developer; expandir sob demanda)_
- [ContentBuilder](https://developer.apple.com/documentation/SwiftUI/ContentBuilder) — A custom parameter attribute that constructs views and other content types from closures. _(Apple Developer; expandir sob demanda)_
- [ToolbarContentBuilder](https://developer.apple.com/documentation/SwiftUI/ToolbarContentBuilder) — Constructs a toolbar item set from multi-expression closures. _(Apple Developer; expandir sob demanda)_
- [CommandsBuilder](https://developer.apple.com/documentation/SwiftUI/CommandsBuilder) — Constructs command sets from multi-expression closures. Like `ContentBuilder`, it supports up to ten expressions in the closure body. _(Apple Developer; expandir sob demanda)_
- [reorderable()](https://developer.apple.com/documentation/SwiftUI/DynamicViewContent/reorderable()) — Enables reordering of views from this content inside the scope of a reorderable container modifier. _(Apple Developer; expandir sob demanda)_
- [reorderContainer(for:isEnabled:move:)](https://developer.apple.com/documentation/SwiftUI/View/reorderContainer(for:isEnabled:move:)) — Defines a container of reorderable views. _(Apple Developer; expandir sob demanda)_
- [swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:)](https://developer.apple.com/documentation/SwiftUI/View/swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:)) — Adds custom swipe actions to a row in a list or container, notifying you when the actions are revealed or dismissed. _(Apple Developer; expandir sob demanda)_
- [swipeActionsContainer()](https://developer.apple.com/documentation/SwiftUI/View/swipeActionsContainer()) — Coordinates swipe action dismissal and mutual exclusion across rows in a container. _(Apple Developer; expandir sob demanda)_
- [crossFade](https://developer.apple.com/documentation/SwiftUI/NavigationTransition/crossFade) — A navigation transition that cross-fades between the appearing view and the disappearing view. _(Apple Developer; expandir sob demanda)_
- [AsyncImage](https://developer.apple.com/documentation/SwiftUI/AsyncImage) — A view that asynchronously loads and displays an image. _(Apple Developer; expandir sob demanda)_
- [asyncImageURLSession(_:)](https://developer.apple.com/documentation/SwiftUI/View/asyncImageURLSession(_:)) — A modifier that adds a URL session for asynchronous images contained in the view to use when fetching image data. _(Apple Developer; expandir sob demanda)_
- [init(request:scale:)](https://developer.apple.com/documentation/SwiftUI/AsyncImage/init(request:scale:)) — Loads and displays an image from the specified URL load request. _(Apple Developer; expandir sob demanda)_
- [init(request:scale:content:placeholder:)](https://developer.apple.com/documentation/SwiftUI/AsyncImage/init(request:scale:content:placeholder:)) — Loads and displays a modifiable image from the specified URL load request using a custom placeholder until the image loads. _(Apple Developer; expandir sob demanda)_
- [init(request:scale:transaction:content:)](https://developer.apple.com/documentation/SwiftUI/AsyncImage/init(request:scale:transaction:content:)) — Loads and displays a modifiable image from the specified URL load request in phases. _(Apple Developer; expandir sob demanda)_
- [visibilityPriority(_:)](https://developer.apple.com/documentation/SwiftUI/ToolbarContent/visibilityPriority(_:)) — Defines the visibility priority for a toolbar item. _(Apple Developer; expandir sob demanda)_
- [ToolbarOverflowMenu](https://developer.apple.com/documentation/SwiftUI/ToolbarOverflowMenu) — The overflow menu of a toolbar. _(Apple Developer; expandir sob demanda)_
- [topBarPinnedTrailing](https://developer.apple.com/documentation/SwiftUI/ToolbarItemPlacement/topBarPinnedTrailing) — A placement that pins the item to the trailing edge of the toolbar. _(Apple Developer; expandir sob demanda)_
- [ReadableDocument](https://developer.apple.com/documentation/SwiftUI/ReadableDocument) — A type that you use to read documents from file. _(Apple Developer; expandir sob demanda)_
- [WritableDocument](https://developer.apple.com/documentation/SwiftUI/WritableDocument) — A type that you use to write documents to file. _(Apple Developer; expandir sob demanda)_
- [DocumentReader](https://developer.apple.com/documentation/SwiftUI/DocumentReader) — Implements logic of reading documents from disk. _(Apple Developer; expandir sob demanda)_
- [DocumentWriter](https://developer.apple.com/documentation/SwiftUI/DocumentWriter) — Implements logic of writing documents to disk. _(Apple Developer; expandir sob demanda)_
- [FileWrapperDocumentReader](https://developer.apple.com/documentation/SwiftUI/FileWrapperDocumentReader) — A document reader that uses `FileWrapper` for reading. _(Apple Developer; expandir sob demanda)_
- [FileWrapperDocumentWriter](https://developer.apple.com/documentation/SwiftUI/FileWrapperDocumentWriter) — A document writer that uses `FileWrapper` for writing. _(Apple Developer; expandir sob demanda)_
- [URLDocumentConfiguration](https://developer.apple.com/documentation/SwiftUI/URLDocumentConfiguration) — A set of settings and properties of an open document. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:onCancellation:)](https://developer.apple.com/documentation/SwiftUI/View/fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:onCancellation:)) — Presents a system dialog for allowing the user to export a `WritableDocument` to a file on disk. _(Apple Developer; expandir sob demanda)_
- [prominent](https://developer.apple.com/documentation/SwiftUI/TabRole/prominent) — The prominent role. _(Apple Developer; expandir sob demanda)_
- [alert(_:item:actions:)](https://developer.apple.com/documentation/SwiftUI/View/alert(_:item:actions:)) — Presents an alert using the given data to produce the alert’s content and a text view as a title. _(Apple Developer; expandir sob demanda)_
- [alert(error:actions:)](https://developer.apple.com/documentation/SwiftUI/View/alert(error:actions:)) — Presents an alert when an error is present. _(Apple Developer; expandir sob demanda)_
- [alert(_:item:actions:message:)](https://developer.apple.com/documentation/SwiftUI/View/alert(_:item:actions:message:)) — Presents an alert with a message using the given data to produce the alert’s content and a localized string key for a title. _(Apple Developer; expandir sob demanda)_
- [alert(error:actions:message:)](https://developer.apple.com/documentation/SwiftUI/View/alert(error:actions:message:)) — Presents an alert with a message when an error is present. _(Apple Developer; expandir sob demanda)_
- [confirmationDialog(_:item:titleVisibility:actions:)](https://developer.apple.com/documentation/SwiftUI/View/confirmationDialog(_:item:titleVisibility:actions:)) — Presents a confirmation dialog using data to produce the dialog’s content and a text view for the title. _(Apple Developer; expandir sob demanda)_
- [confirmationDialog(_:item:titleVisibility:actions:message:)](https://developer.apple.com/documentation/SwiftUI/View/confirmationDialog(_:item:titleVisibility:actions:message:)) — Presents a confirmation dialog with a message using data to produce the dialog’s content and a text view for the message. _(Apple Developer; expandir sob demanda)_
- [DragGesture](https://developer.apple.com/documentation/SwiftUI/DragGesture) — A dragging motion that invokes an action as the drag-event sequence changes. _(Apple Developer; expandir sob demanda)_
- [LongPressGesture](https://developer.apple.com/documentation/SwiftUI/LongPressGesture) — A gesture that succeeds when the user performs a long press. _(Apple Developer; expandir sob demanda)_
- [MagnifyGesture](https://developer.apple.com/documentation/SwiftUI/MagnifyGesture) — A gesture that recognizes a magnification motion and tracks the amount of magnification. _(Apple Developer; expandir sob demanda)_
- [RotateGesture](https://developer.apple.com/documentation/SwiftUI/RotateGesture) — A gesture that recognizes a rotation motion and tracks the angle of the rotation. _(Apple Developer; expandir sob demanda)_
- [RotateGesture3D](https://developer.apple.com/documentation/SwiftUI/RotateGesture3D) — A gesture that recognizes 3D rotation motion and tracks the angle and axis of the rotation. _(Apple Developer; expandir sob demanda)_
- [SpatialEventGesture](https://developer.apple.com/documentation/SwiftUI/SpatialEventGesture) — A gesture that provides information about ongoing spatial events like clicks and touches. _(Apple Developer; expandir sob demanda)_
- [SpatialTapGesture](https://developer.apple.com/documentation/SwiftUI/SpatialTapGesture) — A gesture that recognizes one or more taps and reports their location. _(Apple Developer; expandir sob demanda)_
- [TapGesture](https://developer.apple.com/documentation/SwiftUI/TapGesture) — A gesture that recognizes one or more taps. _(Apple Developer; expandir sob demanda)_
- [WindowDragGesture](https://developer.apple.com/documentation/SwiftUI/WindowDragGesture) — A gesture that recognizes the motion of and handles dragging a window. _(Apple Developer; expandir sob demanda)_
- [GestureInputKinds](https://developer.apple.com/documentation/SwiftUI/GestureInputKinds) — An option set that specifies which input kinds a gesture should recognize. _(Apple Developer; expandir sob demanda)_
- [glassEffect(_:in:)](https://developer.apple.com/documentation/SwiftUI/View/glassEffect(_:in:)) — Applies the Liquid Glass effect to a view. _(Apple Developer; expandir sob demanda)_
- [glass](https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/glass) — A button style that applies a Liquid Glass effect based on the button’s context. _(Apple Developer; expandir sob demanda)_
- [buttonStyle(_:)](https://developer.apple.com/documentation/SwiftUI/View/buttonStyle(_:)-66fbx) — Sets the style for buttons within this view to a button style with a custom appearance and custom interaction behavior. _(Apple Developer; expandir sob demanda)_
- [ToolbarSpacer](https://developer.apple.com/documentation/SwiftUI/ToolbarSpacer) — A standard space item in toolbars. _(Apple Developer; expandir sob demanda)_
- [scrollEdgeEffectStyle(_:for:)](https://developer.apple.com/documentation/SwiftUI/View/scrollEdgeEffectStyle(_:for:)) — Configures the scroll edge effect style for scroll views within this hierarchy. _(Apple Developer; expandir sob demanda)_
- [backgroundExtensionEffect()](https://developer.apple.com/documentation/SwiftUI/View/backgroundExtensionEffect()) — Adds the background extension effect to the view. The view will be duplicated into mirrored copies which will be placed around the view on… _(Apple Developer; expandir sob demanda)_
- [tabBarMinimizeBehavior(_:)](https://developer.apple.com/documentation/SwiftUI/View/tabBarMinimizeBehavior(_:)) — Sets the behavior for tab bar minimization. _(Apple Developer; expandir sob demanda)_
- [search](https://developer.apple.com/documentation/SwiftUI/TabRole/search) — The search role. _(Apple Developer; expandir sob demanda)_
- [TabViewBottomAccessoryPlacement](https://developer.apple.com/documentation/SwiftUI/TabViewBottomAccessoryPlacement) — A placement of the bottom accessory in a tab view. You can use this to adjust the content of the accessory view based on… _(Apple Developer; expandir sob demanda)_
- [WebView](https://developer.apple.com/documentation/WebKit/WebView-swift.struct) — A view that displays some web content. _(Apple Developer; expandir sob demanda)_
- [WebPage](https://developer.apple.com/documentation/WebKit/WebPage) — An object that controls and manages the behavior of interactive web content. _(Apple Developer; expandir sob demanda)_
- [draggable(containerItemID:containerNamespace:)](https://developer.apple.com/documentation/SwiftUI/View/draggable(containerItemID:containerNamespace:)) — Inside a drag container, activates this view as the source of a drag and drop operation. Supports lazy drag containers. _(Apple Developer; expandir sob demanda)_
- [dragContainer(for:itemID:in:_:)](https://developer.apple.com/documentation/SwiftUI/View/dragContainer(for:itemID:in:_:)) — A container with draggable views. _(Apple Developer; expandir sob demanda)_
- [Animatable()](https://developer.apple.com/documentation/SwiftUI/Animatable()) — A member and extension macro that, when applied to a struct, class or enum declaration, synthesizes the conformance to `Animatable` and its requirement, the… _(Apple Developer; expandir sob demanda)_
- [Slider](https://developer.apple.com/documentation/SwiftUI/Slider) — A control for selecting a value from a bounded linear range of values. _(Apple Developer; expandir sob demanda)_
- [windowResizeAnchor(_:)](https://developer.apple.com/documentation/SwiftUI/View/windowResizeAnchor(_:)) — Sets the window anchor point used when the size of the view changes such that the window must resize. _(Apple Developer; expandir sob demanda)_
- [TextEditor](https://developer.apple.com/documentation/SwiftUI/TextEditor) — A view that can display and edit long-form text. _(Apple Developer; expandir sob demanda)_
- [AttributedString](https://developer.apple.com/documentation/Foundation/AttributedString) — A value type for a string with associated attributes for portions of its text. _(Apple Developer; expandir sob demanda)_
- [AttributedTextSelection](https://developer.apple.com/documentation/SwiftUI/AttributedTextSelection) — Represents a selection of attributed text. _(Apple Developer; expandir sob demanda)_
- [AttributedTextFormattingDefinition](https://developer.apple.com/documentation/SwiftUI/AttributedTextFormattingDefinition) — A protocol for defining how text can be styled in a view. _(Apple Developer; expandir sob demanda)_
- [FindContext](https://developer.apple.com/documentation/SwiftUI/FindContext) — The status of the find navigator for views which support text editing. _(Apple Developer; expandir sob demanda)_
- [AssistiveAccess](https://developer.apple.com/documentation/SwiftUI/AssistiveAccess) — A scene that presents an interface appropriate for Assistive Access on iOS and iPadOS. On other platforms, this scene is unused. _(Apple Developer; expandir sob demanda)_
- [Color.ResolvedHDR](https://developer.apple.com/documentation/SwiftUI/Color/ResolvedHDR) — A concrete color value, including HDR headroom information. _(Apple Developer; expandir sob demanda)_
- [UIHostingSceneDelegate](https://developer.apple.com/documentation/SwiftUI/UIHostingSceneDelegate) — Extends `UIKit/UISceneDelegate` to bridge SwiftUI scenes. _(Apple Developer; expandir sob demanda)_
- [NSHostingSceneRepresentation](https://developer.apple.com/documentation/SwiftUI/NSHostingSceneRepresentation) — An AppKit type that hosts and can present SwiftUI scenes _(Apple Developer; expandir sob demanda)_
- [NSGestureRecognizerRepresentable](https://developer.apple.com/documentation/SwiftUI/NSGestureRecognizerRepresentable) — A wrapper for an `NSGestureRecognizer` that you use to integrate that gesture recognizer into your SwiftUI hierarchy. _(Apple Developer; expandir sob demanda)_
- [manipulable(coordinateSpace:operations:inertia:isEnabled:onChanged:)](https://developer.apple.com/documentation/SwiftUI/View/manipulable(coordinateSpace:operations:inertia:isEnabled:onChanged:)) — Allows this view to be manipulated using common hand gestures. _(Apple Developer; expandir sob demanda)_
- [SurfaceSnappingInfo](https://developer.apple.com/documentation/SwiftUI/SurfaceSnappingInfo) — A type representing information about the window scenes snap state. _(Apple Developer; expandir sob demanda)_
- [RemoteImmersiveSpace](https://developer.apple.com/documentation/SwiftUI/RemoteImmersiveSpace) — A scene that presents its content in an unbounded space on a remote device. _(Apple Developer; expandir sob demanda)_
- [SpatialContainer](https://developer.apple.com/documentation/SwiftUI/SpatialContainer) — A layout container that aligns overlapping content in 3D space. _(Apple Developer; expandir sob demanda)_
- [aspectRatio3D(_:contentMode:)](https://developer.apple.com/documentation/SwiftUI/View/aspectRatio3D(_:contentMode:)) — Constrains this view’s dimensions to the specified 3D aspect ratio. _(Apple Developer; expandir sob demanda)_
- [rotation3DLayout(_:)](https://developer.apple.com/documentation/SwiftUI/View/rotation3DLayout(_:)) — Rotates a view with impacts to its frame in a containing layout _(Apple Developer; expandir sob demanda)_
- [depthAlignment(_:)](https://developer.apple.com/documentation/SwiftUI/Layout/depthAlignment(_:)) — Sets the depth alignment for this layout. _(Apple Developer; expandir sob demanda)_
- [volumeWorldAlignment(_:)](https://developer.apple.com/documentation/SwiftUI/Scene/volumeWorldAlignment(_:)) — Specifies how a volume should be aligned when moved in the world. _(Apple Developer; expandir sob demanda)_
- [defaultWorldScaling(_:)](https://developer.apple.com/documentation/SwiftUI/Scene/defaultWorldScaling(_:)) — Specify the world scaling behavior for the window. _(Apple Developer; expandir sob demanda)_
- [volumeBaseplateVisibility(_:)](https://developer.apple.com/documentation/SwiftUI/View/volumeBaseplateVisibility(_:)) — Sets the visibility of the baseplate of a volume, which appears when a user looks towards the ‘floor’ of a volume and during resize.… _(Apple Developer; expandir sob demanda)_
- [onVolumeViewpointChange(updateStrategy:initial:_:)](https://developer.apple.com/documentation/SwiftUI/View/onVolumeViewpointChange(updateStrategy:initial:_:)) — Adds an action to perform when the viewpoint of the volume changes. _(Apple Developer; expandir sob demanda)_
- [defaultWindowPlacement(_:)](https://developer.apple.com/documentation/SwiftUI/Scene/defaultWindowPlacement(_:)) — Defines a function used for determining the default placement of windows. _(Apple Developer; expandir sob demanda)_
- [WindowIdealSize](https://developer.apple.com/documentation/SwiftUI/WindowIdealSize) — A type which defines the size a window should use when zooming. _(Apple Developer; expandir sob demanda)_
- [windowIdealPlacement(_:)](https://developer.apple.com/documentation/SwiftUI/Scene/windowIdealPlacement(_:)) — Provides a function which determines a placement to use when windows of a scene zoom. _(Apple Developer; expandir sob demanda)_
- [UtilityWindow](https://developer.apple.com/documentation/SwiftUI/UtilityWindow) — A specialized window scene that provides secondary utility to the content of the main scenes of an application. _(Apple Developer; expandir sob demanda)_
- [WindowVisibilityToggle](https://developer.apple.com/documentation/SwiftUI/WindowVisibilityToggle) — A specialized button for toggling the visibility of a window. _(Apple Developer; expandir sob demanda)_
- [window](https://developer.apple.com/documentation/SwiftUI/ContainerBackgroundPlacement/window) — A background placement inside a `Window` or `WindowGroup` _(Apple Developer; expandir sob demanda)_
- [toolbar(removing:)](https://developer.apple.com/documentation/SwiftUI/View/toolbar(removing:)) — Remove a toolbar item present by default _(Apple Developer; expandir sob demanda)_
- [plain](https://developer.apple.com/documentation/SwiftUI/WindowStyle/plain) — The plain window style. _(Apple Developer; expandir sob demanda)_
- [defaultLaunchBehavior(_:)](https://developer.apple.com/documentation/SwiftUI/Scene/defaultLaunchBehavior(_:)) — Sets the default launch behavior for this scene. _(Apple Developer; expandir sob demanda)_
- [pushWindow](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/pushWindow) — A window presentation action stored in a view’s environment. _(Apple Developer; expandir sob demanda)_
- [onImmersionChange(_:)](https://developer.apple.com/documentation/SwiftUI/View/onImmersionChange(_:)) — Performs an action when the immersion state of your app changes. _(Apple Developer; expandir sob demanda)_
- [colorMultiply(_:)](https://developer.apple.com/documentation/SwiftUI/SurroundingsEffect/colorMultiply(_:)) — An effect that applies a custom tint to the passthrough video by multiplying the passthrough with a `Color`. _(Apple Developer; expandir sob demanda)_
- [dim(intensity:)](https://developer.apple.com/documentation/SwiftUI/SurroundingsEffect/dim(intensity:)) — An effect that dims the passthrough video a custom amount. _(Apple Developer; expandir sob demanda)_
- [DocumentGroupLaunchScene](https://developer.apple.com/documentation/SwiftUI/DocumentGroupLaunchScene) — A launch scene for document-based applications. _(Apple Developer; expandir sob demanda)_
- [NewDocumentButton](https://developer.apple.com/documentation/SwiftUI/NewDocumentButton) — A button that creates and opens new documents. _(Apple Developer; expandir sob demanda)_
- [TabView](https://developer.apple.com/documentation/SwiftUI/TabView) — A view that switches between multiple child views using interactive user interface elements. _(Apple Developer; expandir sob demanda)_
- [tabViewStyle(_:)](https://developer.apple.com/documentation/SwiftUI/View/tabViewStyle(_:)) — Sets the style for the tab view within the current environment. _(Apple Developer; expandir sob demanda)_
- [sidebarAdaptable](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) — A tab bar style that adapts to each platform. _(Apple Developer; expandir sob demanda)_
- [tabBarOnly](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/tabBarOnly) — A tab view style that displays a tab bar when possible. _(Apple Developer; expandir sob demanda)_
- [grouped](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/grouped) — A tab view style that displays a tab bar that groups its tabs together. _(Apple Developer; expandir sob demanda)_
- [TabSection](https://developer.apple.com/documentation/SwiftUI/TabSection) — A container that you can use to add hierarchy within a tab view. _(Apple Developer; expandir sob demanda)_
- [tabViewCustomization(_:)](https://developer.apple.com/documentation/SwiftUI/View/tabViewCustomization(_:)) — Specifies the customizations to apply to the sidebar representation of the tab view. _(Apple Developer; expandir sob demanda)_
- [AppStorage](https://developer.apple.com/documentation/SwiftUI/AppStorage) — A property wrapper type that reflects a value from `UserDefaults` and invalidates a view on a change in value in that user default. _(Apple Developer; expandir sob demanda)_
- [TabViewCustomization](https://developer.apple.com/documentation/SwiftUI/TabViewCustomization) — The customizations a person makes to an adaptable sidebar tab view. _(Apple Developer; expandir sob demanda)_
- [form](https://developer.apple.com/documentation/SwiftUI/PresentationSizing/form) — The size is appropriate for forms and slightly less wide than`.page` _(Apple Developer; expandir sob demanda)_
- [page](https://developer.apple.com/documentation/SwiftUI/PresentationSizing/page) — The size is roughly the size of a page of paper, appropriate for informational or compositional content. _(Apple Developer; expandir sob demanda)_
- [presentationSizing(_:)](https://developer.apple.com/documentation/SwiftUI/View/presentationSizing(_:)) — Sets the sizing of the containing presentation. _(Apple Developer; expandir sob demanda)_
- [PresentationSizing](https://developer.apple.com/documentation/SwiftUI/PresentationSizing) — A type that defines the size of the presentation content and how the presentation size adjusts to its content’s size changing. _(Apple Developer; expandir sob demanda)_
- [ToolbarLabelStyle](https://developer.apple.com/documentation/SwiftUI/ToolbarLabelStyle) — The label style of a toolbar. _(Apple Developer; expandir sob demanda)_
- [toolbarForegroundStyle(_:for:)](https://developer.apple.com/documentation/SwiftUI/View/toolbarForegroundStyle(_:for:)) — Specifies the preferred foreground style of bars managed by SwiftUI. _(Apple Developer; expandir sob demanda)_
- [scene(_:)](https://developer.apple.com/documentation/SwiftUI/OrnamentAttachmentAnchor/scene(_:)-1l8wf) — The anchor point for the ornament expressed as a 3D unit point relative to the scene. _(Apple Developer; expandir sob demanda)_
- [UnitPoint3D](https://developer.apple.com/documentation/SwiftUI/UnitPoint3D) — A normalized 3D point in a view’s coordinate space. _(Apple Developer; expandir sob demanda)_
- [Picker](https://developer.apple.com/documentation/SwiftUI/Picker) — A control for selecting from a set of mutually exclusive values. _(Apple Developer; expandir sob demanda)_
- [List](https://developer.apple.com/documentation/SwiftUI/List) — A container that presents rows of data arranged in a single column, optionally providing the ability to select one or more members. _(Apple Developer; expandir sob demanda)_
- [Group](https://developer.apple.com/documentation/SwiftUI/Group) — A type that collects multiple instances of a content type — like views, scenes, or commands — into a single unit. _(Apple Developer; expandir sob demanda)_
- [ForEach](https://developer.apple.com/documentation/SwiftUI/ForEach) — A structure that computes views on demand from an underlying collection of identified data. _(Apple Developer; expandir sob demanda)_
- [init(subviews:transform:)](https://developer.apple.com/documentation/SwiftUI/Group/init(subviews:transform:)) — Constructs a group from the subviews of the given view. _(Apple Developer; expandir sob demanda)_
- [init(subviews:content:)](https://developer.apple.com/documentation/SwiftUI/ForEach/init(subviews:content:)) — Creates an instance that uniquely identifies and creates views across updates based on the subviews of a given view. _(Apple Developer; expandir sob demanda)_
- [ContainerValueKey](https://developer.apple.com/documentation/SwiftUI/ContainerValueKey) — A key for accessing container values. _(Apple Developer; expandir sob demanda)_
- [containerValue(_:_:)](https://developer.apple.com/documentation/SwiftUI/View/containerValue(_:_:)) — Sets a particular container value of a view. _(Apple Developer; expandir sob demanda)_
- [EnvironmentValues](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues) — A collection of environment values propagated through a view hierarchy. _(Apple Developer; expandir sob demanda)_
- [Transaction](https://developer.apple.com/documentation/SwiftUI/Transaction) — The context of the current state-processing update. _(Apple Developer; expandir sob demanda)_
- [ContainerValues](https://developer.apple.com/documentation/SwiftUI/ContainerValues) — A collection of container values associated with a given view. _(Apple Developer; expandir sob demanda)_
- [FocusedValues](https://developer.apple.com/documentation/SwiftUI/FocusedValues) — A collection of state exported by the focused scene or view and its ancestors. _(Apple Developer; expandir sob demanda)_
- [Entry()](https://developer.apple.com/documentation/SwiftUI/Entry()) — Creates an environment values, transaction, container values, or focused values entry. _(Apple Developer; expandir sob demanda)_
- [navigationTransition(_:)](https://developer.apple.com/documentation/SwiftUI/View/navigationTransition(_:)) — Sets the navigation transition style for this view. _(Apple Developer; expandir sob demanda)_
- [wiggle](https://developer.apple.com/documentation/Symbols/SymbolEffect/wiggle) — A symbol effect that applies the Wiggle animation to symbol images. _(Apple Developer; expandir sob demanda)_
- [rotate](https://developer.apple.com/documentation/Symbols/SymbolEffect/rotate) — A symbol effect that applies the Rotate animation to symbol images. _(Apple Developer; expandir sob demanda)_
- [breathe](https://developer.apple.com/documentation/Symbols/SymbolEffect/breathe) — A symbol effect that applies the Breathe animation to symbol images. _(Apple Developer; expandir sob demanda)_
- [symbolEffect(_:options:value:)](https://developer.apple.com/documentation/SwiftUI/View/symbolEffect(_:options:value:)) — Returns a new view with a symbol effect added to it. _(Apple Developer; expandir sob demanda)_
- [textInputSuggestions(_:)](https://developer.apple.com/documentation/SwiftUI/View/textInputSuggestions(_:)) — Configures the text input suggestions for this view. _(Apple Developer; expandir sob demanda)_
- [textInputCompletion(_:)](https://developer.apple.com/documentation/SwiftUI/View/textInputCompletion(_:)) — Associates a fully formed string with the value of this view when used as a text input suggestion _(Apple Developer; expandir sob demanda)_
- [TextSelection](https://developer.apple.com/documentation/SwiftUI/TextSelection) — Represents a selection of text. _(Apple Developer; expandir sob demanda)_
- [TextField](https://developer.apple.com/documentation/SwiftUI/TextField) — A control that displays an editable text interface. _(Apple Developer; expandir sob demanda)_
- [searchFocused(_:equals:)](https://developer.apple.com/documentation/SwiftUI/View/searchFocused(_:equals:)) — Modifies this view by binding the focus state of the search field associated with the nearest searchable modifier to the given value. _(Apple Developer; expandir sob demanda)_
- [compile(as:)](https://developer.apple.com/documentation/SwiftUI/Shader/compile(as:)) — Attempts to asynchronously compile a shader function, to minimize the chance of stalling when it is first used for rendering. _(Apple Developer; expandir sob demanda)_
- [MeshGradient](https://developer.apple.com/documentation/SwiftUI/MeshGradient) — A two-dimensional gradient defined by a 2D grid of positioned colors. _(Apple Developer; expandir sob demanda)_
- [TextAttribute](https://developer.apple.com/documentation/SwiftUI/TextAttribute) — A value that you can attach to text views and that text renderers can query. _(Apple Developer; expandir sob demanda)_
- [Text.Layout](https://developer.apple.com/documentation/SwiftUI/Text/Layout) — A value describing the layout and custom attributes of a tree of `Text` views. _(Apple Developer; expandir sob demanda)_
- [TextRenderer](https://developer.apple.com/documentation/SwiftUI/TextRenderer) — A value that can replace the default text view rendering behavior. _(Apple Developer; expandir sob demanda)_
- [Color](https://developer.apple.com/documentation/SwiftUI/Color) — A representation of a color that adapts to a given context. _(Apple Developer; expandir sob demanda)_
- [mix(with:by:in:)](https://developer.apple.com/documentation/SwiftUI/Color/mix(with:by:in:)) — Returns a version of self mixed with `rhs` by the amount specified by `fraction`. _(Apple Developer; expandir sob demanda)_
- [ZStack](https://developer.apple.com/documentation/SwiftUI/ZStack) — A view that overlays its subviews, aligning them in both axes. _(Apple Developer; expandir sob demanda)_
- [init(alignment:spacing:content:)](https://developer.apple.com/documentation/SwiftUI/ZStack/init(alignment:spacing:content:)) — Creates an instance with the given spacing and alignment. _(Apple Developer; expandir sob demanda)_
- [scrollPosition(_:anchor:)](https://developer.apple.com/documentation/SwiftUI/View/scrollPosition(_:anchor:)) — Associates a binding to a scroll position with a scroll view within this view. _(Apple Developer; expandir sob demanda)_
- [ScrollPosition](https://developer.apple.com/documentation/SwiftUI/ScrollPosition) — A type that defines the semantic position of where a scroll view is scrolled within its content. _(Apple Developer; expandir sob demanda)_
- [alwaysByFew](https://developer.apple.com/documentation/SwiftUI/ViewAlignedScrollTargetBehavior/LimitBehavior/alwaysByFew) — The always-by-few limit behavior. _(Apple Developer; expandir sob demanda)_
- [alwaysByOne](https://developer.apple.com/documentation/SwiftUI/ViewAlignedScrollTargetBehavior/LimitBehavior/alwaysByOne) — The always-by-one limit behavior. _(Apple Developer; expandir sob demanda)_
- [onScrollVisibilityChange(threshold:_:)](https://developer.apple.com/documentation/SwiftUI/View/onScrollVisibilityChange(threshold:_:)) — Adds an action to be called when the view crosses the threshold to be considered on/off screen. _(Apple Developer; expandir sob demanda)_
- [onScrollPhaseChange(_:)](https://developer.apple.com/documentation/SwiftUI/View/onScrollPhaseChange(_:)-7mica) — Adds an action to perform when the scroll phase of the first scroll view in the hierarchy changes. _(Apple Developer; expandir sob demanda)_
- [gesture(_:isEnabled:)](https://developer.apple.com/documentation/SwiftUI/View/gesture(_:isEnabled:)) — Attaches a gesture to the view with a lower precedence than gestures defined by the view. _(Apple Developer; expandir sob demanda)_
- [HandGestureShortcut](https://developer.apple.com/documentation/SwiftUI/HandGestureShortcut) — Hand gesture shortcuts describe finger and wrist movements that the user can perform in order to activate a button or toggle. _(Apple Developer; expandir sob demanda)_
- [allowsWindowActivationEvents(_:)](https://developer.apple.com/documentation/SwiftUI/View/allowsWindowActivationEvents(_:)) — Configures whether gestures in this view hierarchy can handle events that activate the containing window. _(Apple Developer; expandir sob demanda)_
- [HoverEffectGroup](https://developer.apple.com/documentation/SwiftUI/HoverEffectGroup) — Describes a grouping of effects that activate together. _(Apple Developer; expandir sob demanda)_
- [hoverEffect(in:isEnabled:body:)](https://developer.apple.com/documentation/SwiftUI/View/hoverEffect(in:isEnabled:body:)) — Applies a hover effect to this view described by the given closure. _(Apple Developer; expandir sob demanda)_
- [pointerStyle(_:)](https://developer.apple.com/documentation/SwiftUI/View/pointerStyle(_:)) — Sets the pointer style to display when the pointer is over the view. _(Apple Developer; expandir sob demanda)_
- [pointerVisibility(_:)](https://developer.apple.com/documentation/SwiftUI/View/pointerVisibility(_:)) — Sets the visibility of the pointer when it’s over the view. _(Apple Developer; expandir sob demanda)_
- [onModifierKeysChanged(mask:initial:_:)](https://developer.apple.com/documentation/SwiftUI/View/onModifierKeysChanged(mask:initial:_:)) — Performs an action whenever the user presses or releases a hardware modifier key. _(Apple Developer; expandir sob demanda)_
- [modifierKeyAlternate(_:_:)](https://developer.apple.com/documentation/SwiftUI/View/modifierKeyAlternate(_:_:)) — Builds a view to use in place of the modified view when the user presses the modifier key(s) indicated by the given set. _(Apple Developer; expandir sob demanda)_
- [handPointerBehavior(_:)](https://developer.apple.com/documentation/SwiftUI/View/handPointerBehavior(_:)) — Sets the behavior of the hand pointer while the user is interacting with the view. _(Apple Developer; expandir sob demanda)_
- [Previewable()](https://developer.apple.com/documentation/SwiftUI/Previewable()) — Tag allowing a dynamic property to appear inline in a preview. _(Apple Developer; expandir sob demanda)_
- [PreviewModifier](https://developer.apple.com/documentation/SwiftUI/PreviewModifier) — A type that defines an environment in which previews can appear. _(Apple Developer; expandir sob demanda)_
- [isTabBar](https://developer.apple.com/documentation/SwiftUI/AccessibilityTraits/isTabBar) — The accessibility element is a tab bar. _(Apple Developer; expandir sob demanda)_
- [accessibilityAddTraits(_:)](https://developer.apple.com/documentation/SwiftUI/View/accessibilityAddTraits(_:)) — Adds the given traits to the view. _(Apple Developer; expandir sob demanda)_
- [tabBar](https://developer.apple.com/documentation/UIKit/UIAccessibilityTraits/tabBar) — The accessibility element behaves like a tab bar. _(Apple Developer; expandir sob demanda)_
- [UIGestureRecognizerRepresentable](https://developer.apple.com/documentation/SwiftUI/UIGestureRecognizerRepresentable) — A wrapper for a `UIGestureRecognizer` that you use to integrate that gesture recognizer into your SwiftUI hierarchy. _(Apple Developer; expandir sob demanda)_
- [name](https://developer.apple.com/documentation/UIKit/UIGestureRecognizer/name) — The unique name of the gesture recognizer. _(Apple Developer; expandir sob demanda)_
- [NSHostingMenu](https://developer.apple.com/documentation/SwiftUI/NSHostingMenu) — An AppKit menu with menu items that are defined by a SwiftUI View. _(Apple Developer; expandir sob demanda)_
- [volumetric](https://developer.apple.com/documentation/SwiftUI/WindowStyle/volumetric) — A window style that creates a 3D volumetric window. _(Apple Developer; expandir sob demanda)_
- [ImmersiveSpace](https://developer.apple.com/documentation/SwiftUI/ImmersiveSpace) — A scene that presents its content in an unbounded space. _(Apple Developer; expandir sob demanda)_
- [mixed](https://developer.apple.com/documentation/SwiftUI/ImmersionStyle/mixed) — An immersion style that displays unbounded content intermixed with other app content, along with passthrough video. _(Apple Developer; expandir sob demanda)_
- [full](https://developer.apple.com/documentation/SwiftUI/ImmersionStyle/full) — An immersion style that displays unbounded content that completely replaces passthrough video. _(Apple Developer; expandir sob demanda)_
- [Model3D](https://developer.apple.com/documentation/RealityKit/Model3D) — A view that asynchronously loads and displays a 3D model. _(Apple Developer; expandir sob demanda)_
- [RealityView](https://developer.apple.com/documentation/RealityKit/RealityView) — A view that contains RealityKit content. _(Apple Developer; expandir sob demanda)_
- [bottomOrnament](https://developer.apple.com/documentation/SwiftUI/ToolbarItemPlacement/bottomOrnament) — A placement for items in an ornament under the window. _(Apple Developer; expandir sob demanda)_
- [ornament(visibility:attachmentAnchor:contentAlignment:ornament:)](https://developer.apple.com/documentation/SwiftUI/View/ornament(visibility:attachmentAnchor:contentAlignment:ornament:)) — Presents an ornament. _(Apple Developer; expandir sob demanda)_
- [GeometryReader3D](https://developer.apple.com/documentation/SwiftUI/GeometryReader3D) — A container view that defines its content as a function of its own size and coordinate space. _(Apple Developer; expandir sob demanda)_
- [visualEffect3D(_:)](https://developer.apple.com/documentation/SwiftUI/View/visualEffect3D(_:)) — Applies effects to this view, while providing access to layout information through a 3D geometry proxy. _(Apple Developer; expandir sob demanda)_
- [rotation3DEffect(_:anchor:)](https://developer.apple.com/documentation/SwiftUI/View/rotation3DEffect(_:anchor:)) — Rotates the view’s content by the specified 3D rotation value. _(Apple Developer; expandir sob demanda)_
- [scaleEffect(x:y:z:anchor:)](https://developer.apple.com/documentation/SwiftUI/View/scaleEffect(x:y:z:anchor:)) — Scales this view by the specified horizontal, vertical, and depth factors, relative to an anchor point. _(Apple Developer; expandir sob demanda)_
- [PhysicalMetricsConverter](https://developer.apple.com/documentation/SwiftUI/PhysicalMetricsConverter) — A physical metrics converter provides conversion between point values and their extent in 3D space, in the form of physical length measurements. _(Apple Developer; expandir sob demanda)_
- [glassBackgroundEffect(displayMode:)](https://developer.apple.com/documentation/SwiftUI/View/glassBackgroundEffect(displayMode:)) — Fills the view’s background with an automatic glass background effect and container-relative rounded rectangle shape. _(Apple Developer; expandir sob demanda)_
- [preferredSurroundingsEffect(_:)](https://developer.apple.com/documentation/SwiftUI/View/preferredSurroundingsEffect(_:)) — Applies an effect to passthrough video. _(Apple Developer; expandir sob demanda)_
- [offset(z:)](https://developer.apple.com/documentation/SwiftUI/View/offset(z:)) — Brings a view forward in Z by the provided distance in points. _(Apple Developer; expandir sob demanda)_
- [padding3D(_:)](https://developer.apple.com/documentation/SwiftUI/View/padding3D(_:)-6bex4) — Pads this view using the edge insets you specify. _(Apple Developer; expandir sob demanda)_
- [frame(depth:alignment:)](https://developer.apple.com/documentation/SwiftUI/View/frame(depth:alignment:)) — Positions this view within an invisible frame with the specified depth. _(Apple Developer; expandir sob demanda)_
- [dismissWindow](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/dismissWindow) — A window dismissal action stored in a view’s environment. _(Apple Developer; expandir sob demanda)_
- [SettingsLink](https://developer.apple.com/documentation/SwiftUI/SettingsLink) — A view that opens the Settings scene defined by an app. _(Apple Developer; expandir sob demanda)_
- [navigationDestination(item:destination:)](https://developer.apple.com/documentation/SwiftUI/View/navigationDestination(item:destination:)) — Associates a destination view with a bound value for use within a navigation stack or navigation split view _(Apple Developer; expandir sob demanda)_
- [init(columnVisibility:preferredCompactColumn:sidebar:content:detail:)](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView/init(columnVisibility:preferredCompactColumn:sidebar:content:detail:)) — Creates a three-column navigation split view that enables programmatic control of leading columns’ visibility in regular sizes and which column appears on top when… _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:document:contentTypes:defaultFilename:onCompletion:onCancellation:)](https://developer.apple.com/documentation/SwiftUI/View/fileExporter(isPresented:document:contentTypes:defaultFilename:onCompletion:onCancellation:)-34bd6) — Presents a system dialog for allowing the user to export a `FileDocument` to a file on disk. _(Apple Developer; expandir sob demanda)_
- [Transferable](https://developer.apple.com/documentation/CoreTransferable/Transferable) — A protocol that describes how a type interacts with transport APIs such as drag and drop or copy and paste. _(Apple Developer; expandir sob demanda)_
- [dialogSeverity(_:)](https://developer.apple.com/documentation/SwiftUI/View/dialogSeverity(_:)) — _Apple Developer; expandir sob demanda_
- [dialogIcon(_:)](https://developer.apple.com/documentation/SwiftUI/View/dialogIcon(_:)) — Configures the icon used by dialogs within this view. _(Apple Developer; expandir sob demanda)_
- [dialogSuppressionToggle(isSuppressed:)](https://developer.apple.com/documentation/SwiftUI/View/dialogSuppressionToggle(isSuppressed:)) — Enables user suppression of dialogs and alerts presented within `self`, with a default suppression message on macOS. Unused on other platforms. _(Apple Developer; expandir sob demanda)_
- [toolbarTitleDisplayMode(_:)](https://developer.apple.com/documentation/SwiftUI/View/toolbarTitleDisplayMode(_:)) — Configures the toolbar title display mode for this view. _(Apple Developer; expandir sob demanda)_
- [searchable(text:isPresented:placement:prompt:)](https://developer.apple.com/documentation/SwiftUI/View/searchable(text:isPresented:placement:prompt:)-1hn4y) — Marks this view as searchable with programmatic presentation of the search field. _(Apple Developer; expandir sob demanda)_
- [searchable(text:editableTokens:isPresented:placement:prompt:token:)](https://developer.apple.com/documentation/SwiftUI/View/searchable(text:editableTokens:isPresented:placement:prompt:token:)-2ilmg) — Marks this view as searchable, which configures the display of a search field. _(Apple Developer; expandir sob demanda)_
- [UITraitBridgedEnvironmentKey](https://developer.apple.com/documentation/SwiftUI/UITraitBridgedEnvironmentKey) — _Apple Developer; expandir sob demanda_
- [Observable()](https://developer.apple.com/documentation/Observation/Observable()) — Defines and implements conformance of the Observable protocol. _(Apple Developer; expandir sob demanda)_
- [onChange(of:initial:_:)](https://developer.apple.com/documentation/SwiftUI/View/onChange(of:initial:_:)-4psgg) — Adds a modifier for this view that fires an action when a specific value changes. _(Apple Developer; expandir sob demanda)_
- [ContentUnavailableView](https://developer.apple.com/documentation/SwiftUI/ContentUnavailableView) — An interface, consisting of a label and additional content, that you display when the content of your app is unavailable to users. _(Apple Developer; expandir sob demanda)_
- [inspector(isPresented:content:)](https://developer.apple.com/documentation/SwiftUI/View/inspector(isPresented:content:)) — Inserts an inspector at the applied position in the view hierarchy. _(Apple Developer; expandir sob demanda)_
- [withAnimation(_:completionCriteria:_:completion:)](https://developer.apple.com/documentation/SwiftUI/withAnimation(_:completionCriteria:_:completion:)) — Returns the result of recomputing the view’s body with the provided animation, and runs the completion when all animations are complete. _(Apple Developer; expandir sob demanda)_
- [CustomAnimation](https://developer.apple.com/documentation/SwiftUI/CustomAnimation) — A type that defines how an animatable value changes over time. _(Apple Developer; expandir sob demanda)_
- [PhaseAnimator](https://developer.apple.com/documentation/SwiftUI/PhaseAnimator) — A container that animates its content by automatically cycling through a collection of phases that you provide, each defining a discrete step within an… _(Apple Developer; expandir sob demanda)_
- [Keyframes](https://developer.apple.com/documentation/SwiftUI/Keyframes) — A type that defines changes to a value over time. _(Apple Developer; expandir sob demanda)_
- [TransactionKey](https://developer.apple.com/documentation/SwiftUI/TransactionKey) — A key for accessing values in a transaction. _(Apple Developer; expandir sob demanda)_
- [UnitCurve](https://developer.apple.com/documentation/SwiftUI/UnitCurve) — A function defined by a two-dimensional curve that maps an input progress in the range [0,1] to an output progress that is also in… _(Apple Developer; expandir sob demanda)_
- [spring(duration:bounce:blendDuration:)](https://developer.apple.com/documentation/SwiftUI/Animation/spring(duration:bounce:blendDuration:)) — A persistent spring animation. When mixed with other `spring()` or `interactiveSpring()` animations on the same property, each animation will be replaced by their successor… _(Apple Developer; expandir sob demanda)_
- [Spring](https://developer.apple.com/documentation/SwiftUI/Spring) — A representation of a spring’s motion. _(Apple Developer; expandir sob demanda)_
- [Text](https://developer.apple.com/documentation/SwiftUI/Text) — A view that displays one or more lines of read-only text. _(Apple Developer; expandir sob demanda)_
- [typesettingLanguage(_:isEnabled:)](https://developer.apple.com/documentation/SwiftUI/View/typesettingLanguage(_:isEnabled:)-4ldzm) — Specifies the language for typesetting. _(Apple Developer; expandir sob demanda)_
- [textScale(_:isEnabled:)](https://developer.apple.com/documentation/SwiftUI/View/textScale(_:isEnabled:)) — Applies a text scale to text in the view. _(Apple Developer; expandir sob demanda)_
- [fill(_:style:)](https://developer.apple.com/documentation/SwiftUI/Shape/fill(_:style:)-3y2ud) — Fills this shape with a color or gradient. _(Apple Developer; expandir sob demanda)_
- [stroke(_:style:antialiased:)](https://developer.apple.com/documentation/SwiftUI/Shape/stroke(_:style:antialiased:)) — Traces the outline of this shape with a color or gradient. _(Apple Developer; expandir sob demanda)_
- [Shape](https://developer.apple.com/documentation/SwiftUI/Shape) — A 2D shape that you can use when drawing a view. _(Apple Developer; expandir sob demanda)_
- [intersection(_:eoFill:)](https://developer.apple.com/documentation/SwiftUI/Shape/intersection(_:eoFill:)) — Returns a new shape with filled regions common to both shapes. _(Apple Developer; expandir sob demanda)_
- [union(_:eoFill:)](https://developer.apple.com/documentation/SwiftUI/Shape/union(_:eoFill:)) — Returns a new shape with filled regions in either this shape or the given shape. _(Apple Developer; expandir sob demanda)_
- [rect](https://developer.apple.com/documentation/SwiftUI/Shape/rect) — A rectangular shape aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [rect(topLeadingRadius:bottomLeadingRadius:bottomTrailingRadius:topTrailingRadius:style:)](https://developer.apple.com/documentation/SwiftUI/Shape/rect(topLeadingRadius:bottomLeadingRadius:bottomTrailingRadius:topTrailingRadius:style:)) — A rectangular shape with rounded corners with different values, aligned inside the frame of the view containing it. _(Apple Developer; expandir sob demanda)_
- [Shader](https://developer.apple.com/documentation/SwiftUI/Shader) — A reference to a function in a Metal shader library, along with its bound uniform argument values. _(Apple Developer; expandir sob demanda)_
- [allowedDynamicRange(_:)](https://developer.apple.com/documentation/SwiftUI/View/allowedDynamicRange(_:)) — Returns a new view configured with the specified allowed dynamic range. _(Apple Developer; expandir sob demanda)_
- [visualEffect(_:)](https://developer.apple.com/documentation/SwiftUI/View/visualEffect(_:)) — Applies effects to this view, while providing access to layout information through a geometry proxy. _(Apple Developer; expandir sob demanda)_
- [CoordinateSpaceProtocol](https://developer.apple.com/documentation/SwiftUI/CoordinateSpaceProtocol) — A frame of reference within the layout system. _(Apple Developer; expandir sob demanda)_
- [GeometryProxy](https://developer.apple.com/documentation/SwiftUI/GeometryProxy) — A proxy for access to the size and coordinate space (for anchor resolution) of the container view. _(Apple Developer; expandir sob demanda)_
- [bounds(of:)](https://developer.apple.com/documentation/SwiftUI/GeometryProxy/bounds(of:)) — Returns the given coordinate space’s bounds rectangle, converted to the local coordinate space. _(Apple Developer; expandir sob demanda)_
- [frame(in:)](https://developer.apple.com/documentation/SwiftUI/GeometryProxy/frame(in:)-68tks) — Returns the container view’s bounds rectangle, converted to a defined coordinate space. _(Apple Developer; expandir sob demanda)_
- [containerRelativeFrame(_:alignment:)](https://developer.apple.com/documentation/SwiftUI/View/containerRelativeFrame(_:alignment:)) — Positions this view within an invisible frame with a size relative to the nearest container. _(Apple Developer; expandir sob demanda)_
- [containerBackground(_:for:)](https://developer.apple.com/documentation/SwiftUI/View/containerBackground(_:for:)) — Sets the container background of the enclosing container using a view. _(Apple Developer; expandir sob demanda)_
- [Table](https://developer.apple.com/documentation/SwiftUI/Table) — A container that presents rows of data arranged in one or more columns, optionally providing the ability to select one or more members. _(Apple Developer; expandir sob demanda)_
- [selectionDisabled(_:)](https://developer.apple.com/documentation/SwiftUI/View/selectionDisabled(_:)) — Adds a condition that controls whether users can select this view. _(Apple Developer; expandir sob demanda)_
- [Section](https://developer.apple.com/documentation/SwiftUI/Section) — A container view that you can use to add hierarchy within certain views. _(Apple Developer; expandir sob demanda)_
- [listRowSpacing(_:)](https://developer.apple.com/documentation/SwiftUI/View/listRowSpacing(_:)) — Sets the vertical spacing between two adjacent rows in a List. _(Apple Developer; expandir sob demanda)_
- [listSectionSpacing(_:)](https://developer.apple.com/documentation/SwiftUI/View/listSectionSpacing(_:)-5t518) — Sets the spacing between adjacent sections in a `List`. _(Apple Developer; expandir sob demanda)_
- [badgeProminence(_:)](https://developer.apple.com/documentation/SwiftUI/View/badgeProminence(_:)) — Specifies the prominence of badges created by this view. _(Apple Developer; expandir sob demanda)_
- [alternatingRowBackgrounds(_:)](https://developer.apple.com/documentation/SwiftUI/View/alternatingRowBackgrounds(_:)) — Overrides whether lists and tables in this view have alternating row backgrounds. _(Apple Developer; expandir sob demanda)_
- [TableColumnCustomization](https://developer.apple.com/documentation/SwiftUI/TableColumnCustomization) — A representation of the state of the columns in a table. _(Apple Developer; expandir sob demanda)_
- [DisclosureTableRow](https://developer.apple.com/documentation/SwiftUI/DisclosureTableRow) — A kind of table row that shows or hides additional rows based on the state of a disclosure control. _(Apple Developer; expandir sob demanda)_
- [OutlineGroup](https://developer.apple.com/documentation/SwiftUI/OutlineGroup) — A structure that computes views and disclosure groups on demand from an underlying collection of tree-structured, identified data. _(Apple Developer; expandir sob demanda)_
- [tableColumnHeaders(_:)](https://developer.apple.com/documentation/SwiftUI/View/tableColumnHeaders(_:)) — Controls the visibility of a `Table`’s column header views. _(Apple Developer; expandir sob demanda)_
- [scrollPosition(id:anchor:)](https://developer.apple.com/documentation/SwiftUI/View/scrollPosition(id:anchor:)) — Associates a binding to be updated when a scroll view within this view scrolls. _(Apple Developer; expandir sob demanda)_
- [scrollIndicatorsFlash(onAppear:)](https://developer.apple.com/documentation/SwiftUI/View/scrollIndicatorsFlash(onAppear:)) — Flashes the scroll indicators of a scrollable view when it appears. _(Apple Developer; expandir sob demanda)_
- [scrollClipDisabled(_:)](https://developer.apple.com/documentation/SwiftUI/View/scrollClipDisabled(_:)) — Sets whether a scroll view clips its content to its bounds. _(Apple Developer; expandir sob demanda)_
- [scrollTargetBehavior(_:)](https://developer.apple.com/documentation/SwiftUI/View/scrollTargetBehavior(_:)) — Sets the scroll behavior of views scrollable in the provided axes. _(Apple Developer; expandir sob demanda)_
- [ScrollTargetBehavior](https://developer.apple.com/documentation/SwiftUI/ScrollTargetBehavior) — A type that defines the scroll behavior of a scrollable view. _(Apple Developer; expandir sob demanda)_
- [safeAreaPadding(_:)](https://developer.apple.com/documentation/SwiftUI/View/safeAreaPadding(_:)-5lh9p) — Adds the provided insets into the safe area of this view. _(Apple Developer; expandir sob demanda)_
- [contentMargins(_:_:for:)](https://developer.apple.com/documentation/SwiftUI/View/contentMargins(_:_:for:)-1lt8b) — Configures the content margin for a provided placement. _(Apple Developer; expandir sob demanda)_
- [scrollTransition(_:axis:transition:)](https://developer.apple.com/documentation/SwiftUI/View/scrollTransition(_:axis:transition:)) — Applies the given transition, animating between the phases of the transition as this view appears and disappears within the visible region of the containing… _(Apple Developer; expandir sob demanda)_
- [verticalPage](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/verticalPage) — A `TabViewStyle` that displays a vertical page `TabView` interaction and appearance. _(Apple Developer; expandir sob demanda)_
- [velocity](https://developer.apple.com/documentation/SwiftUI/DragGesture/Value/velocity) — The current drag velocity. _(Apple Developer; expandir sob demanda)_
- [tracksVelocity](https://developer.apple.com/documentation/SwiftUI/Transaction/tracksVelocity) — Whether this transaction will track the velocity of any animatable properties that change. _(Apple Developer; expandir sob demanda)_
- [onKeyPress(_:action:)](https://developer.apple.com/documentation/SwiftUI/View/onKeyPress(_:action:)) — Performs an action if the user presses a key on a hardware keyboard while the view has focus. _(Apple Developer; expandir sob demanda)_
- [Menu](https://developer.apple.com/documentation/SwiftUI/Menu) — A control for presenting a menu of actions. _(Apple Developer; expandir sob demanda)_
- [palette](https://developer.apple.com/documentation/SwiftUI/PickerStyle/palette) — A picker style that presents the options as a row of compact elements. _(Apple Developer; expandir sob demanda)_
- [sensoryFeedback(_:trigger:)](https://developer.apple.com/documentation/SwiftUI/View/sensoryFeedback(_:trigger:)) — Plays the specified `feedback` when the provided `trigger` value changes. _(Apple Developer; expandir sob demanda)_
- [AppIntent](https://developer.apple.com/documentation/AppIntents/AppIntent) — An interface you use to express app-specific actions and make them available to the rest of the system. _(Apple Developer; expandir sob demanda)_
- [init(_:intent:)](https://developer.apple.com/documentation/SwiftUI/Button/init(_:intent:)-7urde) — Creates a button that performs an `AppIntent` and generates its label from a localized string key. _(Apple Developer; expandir sob demanda)_
- [init(_:isOn:intent:)](https://developer.apple.com/documentation/SwiftUI/Toggle/init(_:isOn:intent:)-4lsrf) — Creates a toggle performing an `AppIntent` and generates its label from a localized string key. _(Apple Developer; expandir sob demanda)_
- [focusable(_:interactions:)](https://developer.apple.com/documentation/SwiftUI/View/focusable(_:interactions:)) — Specifies if the view is focusable, and if so, what focus-driven interactions it supports. _(Apple Developer; expandir sob demanda)_
- [focusEffectDisabled(_:)](https://developer.apple.com/documentation/SwiftUI/View/focusEffectDisabled(_:)) — Adds a condition that controls whether this view can display focus effects, such as a default focus ring or hover effect. _(Apple Developer; expandir sob demanda)_
- [Preview(_:traits:_:body:)](https://developer.apple.com/documentation/SwiftUI/Preview(_:traits:_:body:)) — Creates a preview of a SwiftUI view using the specified traits. _(Apple Developer; expandir sob demanda)_

### Technology and frameworks

- [Accelerate updates](https://developer.apple.com/documentation/updates/accelerate) — Learn about important changes to Accelerate. _(Apple Developer; expandir sob demanda)_
- [Accessibility updates](https://developer.apple.com/documentation/updates/accessibility) — Learn about important changes to Accessibility. _(Apple Developer; expandir sob demanda)_
- [ActivityKit updates](https://developer.apple.com/documentation/updates/activitykit) — Learn about important changes in ActivityKit. _(Apple Developer; expandir sob demanda)_
- [AdAttributionKit Updates](https://developer.apple.com/documentation/updates/adattributionkit) — Learn about important changes to AdAttributionKit. _(Apple Developer; expandir sob demanda)_
- [App Clips updates](https://developer.apple.com/documentation/updates/appclips) — Learn about important changes in App Clips. _(Apple Developer; expandir sob demanda)_
- [App Intents updates](https://developer.apple.com/documentation/updates/appintents) — Learn about important changes in App Intents. _(Apple Developer; expandir sob demanda)_
- [AppKit updates](https://developer.apple.com/documentation/updates/appkit) — Learn about important changes to AppKit. _(Apple Developer; expandir sob demanda)_
- [Apple Intelligence updates](https://developer.apple.com/documentation/updates/apple-intelligence) — Learn about important changes to Apple Intelligence. _(Apple Developer; expandir sob demanda)_
- [AppleMapsServerAPI Updates](https://developer.apple.com/documentation/updates/applemapsserverapi) — Learn about important changes to AppleMapsServerAPI. _(Apple Developer; expandir sob demanda)_
- [Apple Pencil updates](https://developer.apple.com/documentation/updates/applepencil) — Learn about important changes to Apple Pencil. _(Apple Developer; expandir sob demanda)_
- [ARKit updates](https://developer.apple.com/documentation/updates/arkit) — Learn about important changes to ARKit. _(Apple Developer; expandir sob demanda)_
- [Audio Toolbox updates](https://developer.apple.com/documentation/updates/audiotoolbox) — Learn about important changes to Audio Toolbox. _(Apple Developer; expandir sob demanda)_
- [AuthenticationServices updates](https://developer.apple.com/documentation/updates/authenticationservices) — Learn about important changes to AuthenticationServices. _(Apple Developer; expandir sob demanda)_
- [AVFAudio updates](https://developer.apple.com/documentation/updates/avfaudio) — Learn about important changes to AVFAudio. _(Apple Developer; expandir sob demanda)_
- [AVFoundation updates](https://developer.apple.com/documentation/updates/avfoundation) — Learn about important changes to AVFoundation. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/Updates/SwiftUI)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `818a25f109c9b6a8296bd116466bafafa37bee5162ad08d412b5265db6f22a96`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
