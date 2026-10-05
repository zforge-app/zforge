---
title: "Adopting Liquid Glass"
source_url: "https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass"
source_identifier: "doc://com.apple.TechnologyOverviews/documentation/TechnologyOverviews/adopting-liquid-glass"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "e5435d0746739d634c8f205ab72883040bb910572a1c7ebcb9f4faf078efe99c"
source_etag: "W/\"675354a73663f85ffac83dc83852bf5e\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Essentials"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Adopting Liquid Glass

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: article
- Module: Technology Overviews
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Find out how to bring the new material to your app.

If you have an existing app, adopting Liquid Glass doesn’t mean reinventing your app from the ground up. Start by building your app in the latest version of Xcode to see the changes. As you review your app, use the following sections to understand the scope of changes and learn how you can adopt these best practices in your interface. If your app uses standard components from SwiftUI, UIKit, or AppKit, your interface picks up the latest look and feel on the latest platform releases for iOS, iPadOS, macOS, tvOS, and watchOS. In Xcode, build your app with the latest SDKs, and run it on the latest platform releases to see the changes in your interface. Interfaces across Apple platforms feature a new dynamic Materials called Liquid Glass, which combines the optical properties of glass with a sense of fluidity. This material forms a distinct functional layer for controls and…

## Content map

- Overview
- See your app with Liquid Glass
- Visual refresh
- App icons
- Controls
- Navigation
- Menus and toolbars
- Windows and modals
- Organization and layout
- Search
- Platform considerations

## Second-level links

### Overview and featured references

- [Materials](https://developer.apple.com/design/Human-Interface-Guidelines/materials) — A material is a visual effect that creates a sense of depth, layering, and hierarchy between foreground and background elements. _(Apple Developer; expand on demand)_
- [NavigationStack](https://developer.apple.com/documentation/SwiftUI/NavigationStack) — A view that displays a root view and enables you to present additional views over the root view. _(Apple Developer; expand on demand)_
- [NavigationSplitView](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView) — A view that presents views in two or three columns, where selections in leading columns control presentations in subsequent columns. _(Apple Developer; expand on demand)_
- [titleBar](https://developer.apple.com/documentation/SwiftUI/WindowStyle/titleBar) — A window style which displays the title bar section of the window. _(Apple Developer; expand on demand)_
- [toolbar(content:)](https://developer.apple.com/documentation/SwiftUI/View/toolbar(content:)) — Populates the toolbar or navigation bar with the specified items. _(Apple Developer; expand on demand)_
- [UINavigationBar](https://developer.apple.com/documentation/UIKit/UINavigationBar) — Navigational controls that display in a bar along the top of the screen, usually in conjunction with a navigation controller. _(Apple Developer; expand on demand)_
- [UITabBar](https://developer.apple.com/documentation/UIKit/UITabBar) — A control that displays one or more buttons in a tab bar for selecting between different subtasks, views, or modes in an app. _(Apple Developer; expand on demand)_
- [UIToolbar](https://developer.apple.com/documentation/UIKit/UIToolbar) — A control that displays one or more buttons along an edge of your interface. _(Apple Developer; expand on demand)_
- [UISplitViewController](https://developer.apple.com/documentation/UIKit/UISplitViewController) — A container view controller that implements a hierarchical interface. _(Apple Developer; expand on demand)_
- [NSToolbar](https://developer.apple.com/documentation/AppKit/NSToolbar) — An object that manages the space above your app’s custom content and either below or integrated with the window’s title bar. _(Apple Developer; expand on demand)_
- [NSSplitView](https://developer.apple.com/documentation/AppKit/NSSplitView) — A view that arranges two or more views in a linear stack running horizontally or vertically. _(Apple Developer; expand on demand)_
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) — Configure, combine, and morph views using Liquid Glass effects. _(Apple Developer; expand on demand)_
- [glassEffect(_:in:)](https://developer.apple.com/documentation/SwiftUI/View/glassEffect(_:in:)) — Applies the Liquid Glass effect to a view. _(Apple Developer; expand on demand)_
- [UIGlassEffect](https://developer.apple.com/documentation/UIKit/UIGlassEffect) — A visual effect that renders a glass material. _(Apple Developer; expand on demand)_
- [NSGlassEffectView](https://developer.apple.com/documentation/AppKit/NSGlassEffectView) — A view that embeds its content view in a dynamic glass effect. _(Apple Developer; expand on demand)_
- [App icons](https://developer.apple.com/design/Human-Interface-Guidelines/app-icons) — A unique, memorable icon expresses your app’s or game’s purpose and personality and helps people recognize it at a glance. _(Apple Developer; expand on demand)_
- [Apple Design Resources](https://developer.apple.com/design/resources/) — _Apple Developer; expand on demand_
- [Creating your app icon using Icon Composer](xcode-creating-your-app-icon-using-icon-composer.md) — Use Icon Composer to stylize your app icon for different platforms and appearances.
- [Buttons](https://developer.apple.com/design/Human-Interface-Guidelines/buttons) — A button initiates an instantaneous action. _(Apple Developer; expand on demand)_
- [Button](https://developer.apple.com/documentation/SwiftUI/Button) — A control that initiates an action. _(Apple Developer; expand on demand)_
- [Toggle](https://developer.apple.com/documentation/SwiftUI/Toggle) — A control that toggles between on and off states. _(Apple Developer; expand on demand)_
- [Slider](https://developer.apple.com/documentation/SwiftUI/Slider) — A control for selecting a value from a bounded linear range of values. _(Apple Developer; expand on demand)_
- [Stepper](https://developer.apple.com/documentation/SwiftUI/Stepper) — A control that performs increment and decrement actions. _(Apple Developer; expand on demand)_
- [Picker](https://developer.apple.com/documentation/SwiftUI/Picker) — A control for selecting from a set of mutually exclusive values. _(Apple Developer; expand on demand)_
- [TextField](https://developer.apple.com/documentation/SwiftUI/TextField) — A control that displays an editable text interface. _(Apple Developer; expand on demand)_
- [UIButton](https://developer.apple.com/documentation/UIKit/UIButton) — A control that executes your custom code in response to user interactions. _(Apple Developer; expand on demand)_
- [UISwitch](https://developer.apple.com/documentation/UIKit/UISwitch) — A control that offers a binary choice, such as on/off. _(Apple Developer; expand on demand)_
- [UISlider](https://developer.apple.com/documentation/UIKit/UISlider) — A control for selecting a single value from a continuous range of values. _(Apple Developer; expand on demand)_
- [UIStepper](https://developer.apple.com/documentation/UIKit/UIStepper) — A control for incrementing or decrementing a value. _(Apple Developer; expand on demand)_
- [UISegmentedControl](https://developer.apple.com/documentation/UIKit/UISegmentedControl) — A horizontal control that consists of multiple segments, each segment functioning as a discrete button. _(Apple Developer; expand on demand)_
- [UITextField](https://developer.apple.com/documentation/UIKit/UITextField) — An object that displays an editable text area in your interface. _(Apple Developer; expand on demand)_
- [NSButton](https://developer.apple.com/documentation/AppKit/NSButton) — A control that defines an area on the screen that a user clicks to trigger an action. _(Apple Developer; expand on demand)_
- [NSSwitch](https://developer.apple.com/documentation/AppKit/NSSwitch) — A control that offers a binary choice. _(Apple Developer; expand on demand)_
- [NSSlider](https://developer.apple.com/documentation/AppKit/NSSlider) — A display of a bar representing a continuous range of numerical values and a knob representing the currently selected value. _(Apple Developer; expand on demand)_
- [NSStepper](https://developer.apple.com/documentation/AppKit/NSStepper) — An interface with up and down arrow buttons for incrementing or decrementing a value. _(Apple Developer; expand on demand)_
- [NSSegmentedControl](https://developer.apple.com/documentation/AppKit/NSSegmentedControl) — Display one or more buttons in a single horizontal group. _(Apple Developer; expand on demand)_
- [NSTextField](https://developer.apple.com/documentation/AppKit/NSTextField) — Text the user can select or edit to send an action message to a target when the user presses the Return key. _(Apple Developer; expand on demand)_
- [Color](https://developer.apple.com/design/Human-Interface-Guidelines/color) — Judicious use of color can enhance communication, evoke your brand, provide visual continuity, communicate status and feedback, and help people understand information. _(Apple Developer; expand on demand)_
- [scrollEdgeEffectStyle(_:for:)](https://developer.apple.com/documentation/SwiftUI/View/scrollEdgeEffectStyle(_:for:)) — Configures the scroll edge effect style for scroll views within this hierarchy. _(Apple Developer; expand on demand)_
- [safeAreaBar(edge:alignment:spacing:content:)](https://developer.apple.com/documentation/SwiftUI/View/safeAreaBar(edge:alignment:spacing:content:)) — Shows the specified content as a custom bar beside the modified view. _(Apple Developer; expand on demand)_
- [UIScrollEdgeElementContainerInteraction](https://developer.apple.com/documentation/UIKit/UIScrollEdgeElementContainerInteraction) — Add this interaction to a container view of views that overlay the edge of a scroll view. Any descendants of this view that should… _(Apple Developer; expand on demand)_
- [rect(corners:isUniform:)](https://developer.apple.com/documentation/SwiftUI/Shape/rect(corners:isUniform:)) — Creates a rectangle with the same corner style set on four corners. _(Apple Developer; expand on demand)_
- [ConcentricRectangle](https://developer.apple.com/documentation/SwiftUI/ConcentricRectangle) — A shape whose corners you configure, individually or uniformly, to be squared, rounded, or concentric relative to a container shape’s corners. _(Apple Developer; expand on demand)_
- [cornerConfiguration](https://developer.apple.com/documentation/UIKit/UIView/cornerConfiguration-7l0ja) — A configuration that defines the corners of the view. _(Apple Developer; expand on demand)_
- [UICornerConfiguration](https://developer.apple.com/documentation/UIKit/UICornerConfiguration-swift.struct) — A configuration that defines how corner radii are mapped to the corners of a rectangle. _(Apple Developer; expand on demand)_
- [glass](https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/glass) — A button style that applies a Liquid Glass effect based on the button’s context. _(Apple Developer; expand on demand)_
- [glassProminent](https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/glassProminent) — A button style that applies a prominent Liquid Glass effect based on the button’s context. _(Apple Developer; expand on demand)_
- [glass(_:)](https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/glass(_:)) — A button style that applies a configurable Liquid Glass effect based on the button’s context. _(Apple Developer; expand on demand)_
- [glass()](https://developer.apple.com/documentation/UIKit/UIButton/Configuration-swift.struct/glass()) — Creates a configuration for a button that has a Liquid Glass style. _(Apple Developer; expand on demand)_
- [prominentGlass()](https://developer.apple.com/documentation/UIKit/UIButton/Configuration-swift.struct/prominentGlass()) — Creates a configuration for a button that has a prominent Liquid Glass style. _(Apple Developer; expand on demand)_
- [clearGlass()](https://developer.apple.com/documentation/UIKit/UIButton/Configuration-swift.struct/clearGlass()) — Creates a configuration for a button that has a clear Liquid Glass style. _(Apple Developer; expand on demand)_
- [prominentClearGlass()](https://developer.apple.com/documentation/UIKit/UIButton/Configuration-swift.struct/prominentClearGlass()) — Creates a configuration for a button that has a prominent, clear Liquid Glass style. _(Apple Developer; expand on demand)_
- [NSButton.BezelStyle.glass](https://developer.apple.com/documentation/AppKit/NSButton/BezelStyle-swift.enum/glass) — A bezel style with a glass effect _(Apple Developer; expand on demand)_
- [Tab bars](https://developer.apple.com/design/Human-Interface-Guidelines/tab-bars) — A tab bar lets people navigate between top-level sections of your app. _(Apple Developer; expand on demand)_
- [Sidebars](https://developer.apple.com/design/Human-Interface-Guidelines/sidebars) — A sidebar appears on the leading side of a view and lets people navigate between areas of your app or top-level collections of content… _(Apple Developer; expand on demand)_
- [sidebarAdaptable](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) — A tab bar style that adapts to each platform. _(Apple Developer; expand on demand)_
- [UITabBarController.Mode.tabSidebar](https://developer.apple.com/documentation/UIKit/UITabBarController/Mode-swift.enum/tabSidebar) — The system displays the content as either a tab bar or a sidebar, depending on the context. _(Apple Developer; expand on demand)_
- [Split views](https://developer.apple.com/design/Human-Interface-Guidelines/split-views) — A split view manages the presentation of multiple adjacent panes of content, each of which can contain a variety of components, including tables, collections… _(Apple Developer; expand on demand)_
- [inspector(isPresented:content:)](https://developer.apple.com/documentation/SwiftUI/View/inspector(isPresented:content:)) — Inserts an inspector at the applied position in the view hierarchy. _(Apple Developer; expand on demand)_
- [UISplitViewController.Column.inspector](https://developer.apple.com/documentation/UIKit/UISplitViewController/Column/inspector) — The column for the inspector, or trailing, view controller. _(Apple Developer; expand on demand)_
- [NSSplitViewController](https://developer.apple.com/documentation/AppKit/NSSplitViewController) — An object that manages an array of adjacent child views, and has a split view object for managing dividers between those views. _(Apple Developer; expand on demand)_
- [init(inspectorWithViewController:)](https://developer.apple.com/documentation/AppKit/NSSplitViewItem/init(inspectorWithViewController:)) — Creates a split view item that represents an inspector for the specified view controller. _(Apple Developer; expand on demand)_
- [backgroundExtensionEffect()](https://developer.apple.com/documentation/SwiftUI/View/backgroundExtensionEffect()) — Adds the background extension effect to the view. The view will be duplicated into mirrored copies which will be placed around the view on… _(Apple Developer; expand on demand)_
- [UIBackgroundExtensionView](https://developer.apple.com/documentation/UIKit/UIBackgroundExtensionView) — A view that extends content to fill its own bounds. _(Apple Developer; expand on demand)_
- [NSBackgroundExtensionView](https://developer.apple.com/documentation/AppKit/NSBackgroundExtensionView) — A view that extends content to fill its own bounds. _(Apple Developer; expand on demand)_
- [Menus](https://developer.apple.com/design/Human-Interface-Guidelines/menus) — A menu reveals its options when people interact with it, making it a space-efficient way to present commands in your app or game. _(Apple Developer; expand on demand)_
- [The menu bar](https://developer.apple.com/design/Human-Interface-Guidelines/the-menu-bar) — On a Mac or an iPad, the menu bar at the top of the screen displays the top-level menus in your app or game. _(Apple Developer; expand on demand)_
- [Toolbars](https://developer.apple.com/design/Human-Interface-Guidelines/toolbars) — A toolbar provides convenient access to frequently used commands, controls, navigation, and search. _(Apple Developer; expand on demand)_
- [fixed](https://developer.apple.com/documentation/SwiftUI/SpacerSizing/fixed) — The fixed spacer sizing behavior. The spacer will use a pre-defined size determined by the system and the context in which the spacer is… _(Apple Developer; expand on demand)_
- [ToolbarSpacer](https://developer.apple.com/documentation/SwiftUI/ToolbarSpacer) — A standard space item in toolbars. _(Apple Developer; expand on demand)_
- [fixedSpace(_:)](https://developer.apple.com/documentation/UIKit/UIBarButtonItem/fixedSpace(_:)) — Creates a new fixed-width space item. _(Apple Developer; expand on demand)_
- [space](https://developer.apple.com/documentation/AppKit/NSToolbarItem/Identifier/space) — The identifier for a toolbar item that displays an empty space with a standard fixed size. _(Apple Developer; expand on demand)_
- [Icons](https://developer.apple.com/design/Human-Interface-Guidelines/icons) — An effective icon is a graphic asset that expresses a single concept in ways people instantly understand. _(Apple Developer; expand on demand)_
- [hidden(_:)](https://developer.apple.com/documentation/SwiftUI/ToolbarContent/hidden(_:)) — Hides a toolbar item within its toolbar. _(Apple Developer; expand on demand)_
- [isHidden](https://developer.apple.com/documentation/UIKit/UIBarButtonItem/isHidden) — A Boolean that determines the visibility of the item. _(Apple Developer; expand on demand)_
- [isHidden](https://developer.apple.com/documentation/AppKit/NSToolbarItem/isHidden) — Determines whether an item is visible in the toolbar. _(Apple Developer; expand on demand)_
- [Windows](https://developer.apple.com/design/Human-Interface-Guidelines/windows) — A window presents UI views and components in your app or game. _(Apple Developer; expand on demand)_
- [Sheets](https://developer.apple.com/design/Human-Interface-Guidelines/sheets) — A sheet helps people perform a scoped task that’s closely related to their current context. _(Apple Developer; expand on demand)_
- [Action sheets](https://developer.apple.com/design/Human-Interface-Guidelines/action-sheets) — An action sheet is a modal view that presents choices related to an action people initiate. _(Apple Developer; expand on demand)_
- [confirmationDialog(_:isPresented:titleVisibility:presenting:actions:)](https://developer.apple.com/documentation/SwiftUI/View/confirmationDialog(_:isPresented:titleVisibility:presenting:actions:)-9ibgk) — Presents a confirmation dialog using data to produce the dialog’s content and a localized string key for the title. _(Apple Developer; expand on demand)_
- [sourceView](https://developer.apple.com/documentation/UIKit/UIPopoverPresentationController/sourceView) — The view containing the anchor rectangle for the popover. _(Apple Developer; expand on demand)_
- [sourceItem](https://developer.apple.com/documentation/UIKit/UIPopoverPresentationController/sourceItem) — The item on which to anchor the popover. _(Apple Developer; expand on demand)_
- [beginSheetModal(for:completionHandler:)](https://developer.apple.com/documentation/AppKit/NSAlert/beginSheetModal(for:completionHandler:)) — Runs the alert modally as a sheet attached to the specified window. _(Apple Developer; expand on demand)_
- [Lists and tables](https://developer.apple.com/design/Human-Interface-Guidelines/lists-and-tables) — Lists and tables present data in one or more columns of rows. _(Apple Developer; expand on demand)_
- [init(content:header:)](https://developer.apple.com/documentation/SwiftUI/Section/init(content:header:)) — Creates a section with a header and the provided section content. _(Apple Developer; expand on demand)_
- [grouped](https://developer.apple.com/documentation/SwiftUI/FormStyle/grouped) — A form style with grouped rows. _(Apple Developer; expand on demand)_
- [Search fields](https://developer.apple.com/design/Human-Interface-Guidelines/search-fields) — A search field lets people search a collection of content for specific terms they enter. _(Apple Developer; expand on demand)_
- [focusable(_:)](https://developer.apple.com/documentation/SwiftUI/View/focusable(_:)) — Specifies if the view is focusable. _(Apple Developer; expand on demand)_
- [isFocused](https://developer.apple.com/documentation/SwiftUI/EnvironmentValues/isFocused) — Returns whether the nearest focusable ancestor has focus. _(Apple Developer; expand on demand)_
- [UIFocusItem](https://developer.apple.com/documentation/UIKit/UIFocusItem) — An object that can become focused. _(Apple Developer; expand on demand)_
- [focused](https://developer.apple.com/documentation/UIKit/UIControl/State-swift.struct/focused) — The focused state of a control. _(Apple Developer; expand on demand)_
- [GlassEffectContainer](https://developer.apple.com/documentation/SwiftUI/GlassEffectContainer) — A view that combines multiple Liquid Glass shapes into a single shape that can morph individual shapes into one another. _(Apple Developer; expand on demand)_
- [Improving your app’s performance](https://developer.apple.com/documentation/Xcode/improving-your-app-s-performance) — Model, measure, and boost the performance of your app by using a continuous-improvement cycle. _(Apple Developer; expand on demand)_
- [UIDesignRequiresCompatibility](https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIDesignRequiresCompatibility) — A Boolean value that indicates whether the system runs the app using a compatibility mode for UI. _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `e5435d0746739d634c8f205ab72883040bb910572a1c7ebcb9f4faf078efe99c`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
