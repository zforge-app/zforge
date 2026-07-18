---
title: "Navigation"
source_url: "https://developer.apple.com/documentation/swiftui/navigation"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Navigation"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "8fbbd519584b4a38556fbe2ace918082b08a46fd8faa783a56313ed8a68190bf"
source_etag: "W/\"788553b429cdb9402b8341657f8d5710\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Navigation

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Enable people to move between different parts of your app’s view hierarchy within a scene.

Use navigation containers to provide structure to your app’s user interface, enabling people to easily move among the parts of your app. For example, people can move forward and backward through a stack of views using a NavigationStack, or choose which view to display from a tab bar using a TabView. Configure navigation containers by adding view modifiers like navigationSplitViewStyle(_:) to the container. Use other modifiers on the views inside the container to affect the container’s behavior when showing that view. For example, you can use navigationTitle(_:) on a view to provide a toolbar title to display when showing that view.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) — A view that displays a root view and enables you to present additional views over the root view. _(Apple Developer; expandir sob demanda)_
- [TabView](https://developer.apple.com/documentation/swiftui/tabview) — A view that switches between multiple child views using interactive user interface elements. _(Apple Developer; expandir sob demanda)_
- [navigationSplitViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewstyle(_:)) — Sets the style for navigation split views within this view. _(Apple Developer; expandir sob demanda)_
- [navigationTitle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)) — Configures the view’s title for purposes of navigation, using a localized string resource. _(Apple Developer; expandir sob demanda)_

### Essentials

- [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack) — Learn about the navigation stack, links, and how to manage navigation types in your app’s structure. _(Apple Developer; expandir sob demanda)_

### Presenting views in columns

- [Bringing robust navigation structure to your SwiftUI app](https://developer.apple.com/documentation/swiftui/bringing-robust-navigation-structure-to-your-swiftui-app) — Use navigation links, stacks, destinations, and paths to provide a streamlined experience for all platforms, as well as behaviors such as deep linking and… _(Apple Developer; expandir sob demanda)_
- [Migrating to new navigation types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types) — Improve navigation behavior in your app by replacing navigation views with navigation stacks and navigation split views. _(Apple Developer; expandir sob demanda)_
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) — A view that presents views in two or three columns, where selections in leading columns control presentations in subsequent columns. _(Apple Developer; expandir sob demanda)_
- [navigationSplitViewColumnWidth(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:)) — Sets a fixed, preferred width for the column containing this view. _(Apple Developer; expandir sob demanda)_
- [navigationSplitViewColumnWidth(min:ideal:max:)](swiftui-navigation-split-view-column-width-flexible.md) — Sets a flexible, preferred width for the column containing this view. _(Apple Developer; contexto local)_
- [NavigationSplitViewVisibility](https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility) — The visibility of the leading columns in a navigation split view. _(Apple Developer; expandir sob demanda)_
- [NavigationLink](https://developer.apple.com/documentation/swiftui/navigationlink) — A view that controls a navigation presentation. _(Apple Developer; expandir sob demanda)_

### Stacking views in one column

- [NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath) — A type-erased list of data representing the content of a navigation stack. _(Apple Developer; expandir sob demanda)_
- [navigationDestination(for:destination:)](https://developer.apple.com/documentation/swiftui/view/navigationdestination(for:destination:)) — Associates a destination view with a presented data type for use within a navigation stack. _(Apple Developer; expandir sob demanda)_
- [navigationDestination(isPresented:destination:)](https://developer.apple.com/documentation/swiftui/view/navigationdestination(ispresented:destination:)) — Associates a destination view with a binding that can be used to push the view onto a NavigationStack. _(Apple Developer; expandir sob demanda)_
- [navigationDestination(item:destination:)](https://developer.apple.com/documentation/swiftui/view/navigationdestination(item:destination:)) — Associates a destination view with a bound value for use within a navigation stack or navigation split view _(Apple Developer; expandir sob demanda)_

### Managing column collapse

- [NavigationSplitViewColumn](https://developer.apple.com/documentation/swiftui/navigationsplitviewcolumn) — A view that represents a column in a navigation split view. _(Apple Developer; expandir sob demanda)_

### Setting titles for navigation content

- [navigationSubtitle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsubtitle(_:)) — Configures the view’s subtitle for purposes of navigation, using a localized string resource. _(Apple Developer; expandir sob demanda)_
- [navigationDocument(_:)](https://developer.apple.com/documentation/swiftui/view/navigationdocument(_:)) — Configures the view’s document for purposes of navigation. _(Apple Developer; expandir sob demanda)_
- [navigationDocument(_:preview:)](https://developer.apple.com/documentation/swiftui/view/navigationdocument(_:preview:)) — Configures the view’s document for purposes of navigation. _(Apple Developer; expandir sob demanda)_

### Configuring the navigation bar

- [navigationBarBackButtonHidden(_:)](https://developer.apple.com/documentation/swiftui/view/navigationbarbackbuttonhidden(_:)) — Hides the navigation bar back button for the view. _(Apple Developer; expandir sob demanda)_
- [navigationBarTitleDisplayMode(_:)](https://developer.apple.com/documentation/swiftui/view/navigationbartitledisplaymode(_:)) — Configures the title display mode for this view. _(Apple Developer; expandir sob demanda)_
- [NavigationBarItem](https://developer.apple.com/documentation/swiftui/navigationbaritem) — A configuration for a navigation bar that represents a view at the top of a navigation stack. _(Apple Developer; expandir sob demanda)_

### Configuring the sidebar

- [sidebarRowSize](https://developer.apple.com/documentation/swiftui/environmentvalues/sidebarrowsize) — The current size of sidebar rows. _(Apple Developer; expandir sob demanda)_
- [SidebarRowSize](https://developer.apple.com/documentation/swiftui/sidebarrowsize) — The standard sizes of sidebar rows. _(Apple Developer; expandir sob demanda)_

### Presenting views in tabs

- [Enhancing your app’s content with tab navigation](https://developer.apple.com/documentation/swiftui/enhancing-your-app-content-with-tab-navigation) — Keep your app content front and center while providing quick access to navigation using the tab bar. _(Apple Developer; expandir sob demanda)_
- [Tab](https://developer.apple.com/documentation/swiftui/tab) — The content for a tab and the tab’s associated tab item in a tab view. _(Apple Developer; expandir sob demanda)_
- [TabRole](https://developer.apple.com/documentation/swiftui/tabrole) — A value that defines the purpose of the tab. _(Apple Developer; expandir sob demanda)_
- [TabSection](https://developer.apple.com/documentation/swiftui/tabsection) — A container that you can use to add hierarchy within a tab view. _(Apple Developer; expandir sob demanda)_
- [tabViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tabviewstyle(_:)) — Sets the style for the tab view within the current environment. _(Apple Developer; expandir sob demanda)_

### Configuring a tab bar

- [defaultAdaptableTabBarPlacement(_:)](https://developer.apple.com/documentation/swiftui/view/defaultadaptabletabbarplacement(_:)) — Specifies the default placement for the tabs in a tab view using the adaptable sidebar style. _(Apple Developer; expandir sob demanda)_
- [defaultTabBarPlacement(_:)](https://developer.apple.com/documentation/swiftui/view/defaulttabbarplacement(_:)) — Specifies the preferred placement for the tabs of a TabView in the sidebarAdaptable style on platforms where the tab bar cannot adapt between different… _(Apple Developer; expandir sob demanda)_
- [tabViewSidebarHeader(content:)](https://developer.apple.com/documentation/swiftui/view/tabviewsidebarheader(content:)) — Adds a custom header to the sidebar of a tab view. _(Apple Developer; expandir sob demanda)_
- [tabViewSidebarFooter(content:)](https://developer.apple.com/documentation/swiftui/view/tabviewsidebarfooter(content:)) — Adds a custom footer to the sidebar of a tab view. _(Apple Developer; expandir sob demanda)_
- [tabViewSidebarBottomBar(content:)](https://developer.apple.com/documentation/swiftui/view/tabviewsidebarbottombar(content:)) — Adds a custom bottom bar to the sidebar of a tab view. _(Apple Developer; expandir sob demanda)_
- [AdaptableTabBarPlacement](https://developer.apple.com/documentation/swiftui/adaptabletabbarplacement) — A placement for tabs in a tab view using the adaptable sidebar style. _(Apple Developer; expandir sob demanda)_
- [tabBarPlacement](https://developer.apple.com/documentation/swiftui/environmentvalues/tabbarplacement) — The current placement of the tab bar. _(Apple Developer; expandir sob demanda)_
- [TabBarPlacement](https://developer.apple.com/documentation/swiftui/tabbarplacement) — A placement for tabs in a tab view. _(Apple Developer; expandir sob demanda)_
- [isTabBarShowingSections](https://developer.apple.com/documentation/swiftui/environmentvalues/istabbarshowingsections) — A Boolean value that determines whether a tab view shows the expanded contents of a tab section. _(Apple Developer; expandir sob demanda)_
- [tabBarMinimizeBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)) — Sets the behavior for tab bar minimization. _(Apple Developer; expandir sob demanda)_
- [TabBarMinimizeBehavior](https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior) — _Apple Developer; expandir sob demanda_
- [TabViewBottomAccessoryPlacement](https://developer.apple.com/documentation/swiftui/tabviewbottomaccessoryplacement) — A placement of the bottom accessory in a tab view. You can use this to adjust the content of the accessory view based on… _(Apple Developer; expandir sob demanda)_

### Configuring a tab

- [sectionActions(content:)](https://developer.apple.com/documentation/swiftui/view/sectionactions(content:)) — Adds custom actions to a section. _(Apple Developer; expandir sob demanda)_
- [TabPlacement](https://developer.apple.com/documentation/swiftui/tabplacement) — A place that a tab can appear. _(Apple Developer; expandir sob demanda)_
- [TabContentBuilder](https://developer.apple.com/documentation/swiftui/tabcontentbuilder) — A result builder that constructs tabs for a tab view that supports programmatic selection. This builder requires that all tabs in the tab view… _(Apple Developer; expandir sob demanda)_
- [TabContent](https://developer.apple.com/documentation/swiftui/tabcontent) — A type that provides content for programmatically selectable tabs in a tab view. _(Apple Developer; expandir sob demanda)_
- [AnyTabContent](https://developer.apple.com/documentation/swiftui/anytabcontent) — Type erased tab content. _(Apple Developer; expandir sob demanda)_

### Enabling tab customization

- [tabViewCustomization(_:)](https://developer.apple.com/documentation/swiftui/view/tabviewcustomization(_:)) — Specifies the customizations to apply to the sidebar representation of the tab view. _(Apple Developer; expandir sob demanda)_
- [TabViewCustomization](https://developer.apple.com/documentation/swiftui/tabviewcustomization) — The customizations a person makes to an adaptable sidebar tab view. _(Apple Developer; expandir sob demanda)_
- [TabCustomizationBehavior](https://developer.apple.com/documentation/swiftui/tabcustomizationbehavior) — The customization behavior of customizable tab view content. _(Apple Developer; expandir sob demanda)_

### Displaying views in multiple panes

- [HSplitView](https://developer.apple.com/documentation/swiftui/hsplitview) — A layout container that arranges its children in a horizontal line and allows the user to resize them using dividers placed between them. _(Apple Developer; expandir sob demanda)_
- [VSplitView](https://developer.apple.com/documentation/swiftui/vsplitview) — A layout container that arranges its children in a vertical line and allows the user to resize them using dividers placed between them. _(Apple Developer; expandir sob demanda)_

### Deprecated Types

- [NavigationView](https://developer.apple.com/documentation/swiftui/navigationview) — A view for presenting a stack of views that represents a visible path in a navigation hierarchy. _(Apple Developer; expandir sob demanda)_
- [tabItem(_:)](https://developer.apple.com/documentation/swiftui/view/tabitem(_:)) — Sets the tab bar item associated with this view. _(Apple Developer; expandir sob demanda)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(contexto local)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(contexto local)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(contexto local)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/navigation)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `8fbbd519584b4a38556fbe2ace918082b08a46fd8faa783a56313ed8a68190bf`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
