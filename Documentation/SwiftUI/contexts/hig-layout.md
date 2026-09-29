---
title: "Layout"
source_url: "https://developer.apple.com/design/human-interface-guidelines/layout"
source_identifier: "doc://com.apple.HIG/design/Human-Interface-Guidelines/layout"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "d41f32ddf76c597f0edd54eac361fa294a8736cfc4ccc627d1709fe092ed7267"
source_etag: "\"14bcb-65b1173956df8\""
source_last_modified: "Wed, 09 Sep 2026 18:59:32 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Human Interface Guidelines"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Layout

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: article
- Módulo: Não informado
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** A consistent layout that adapts across display sizes, orientations, and multitasking configurations helps people understand and enjoy your app or game on all their devices.

Your layout provides the structure for people to understand your content from the moment they open your app. Familiar relationships between controls and content let people use and discover features right away, and make your design feel at home on every platform. Apple provides templates and layout guides that can help you integrate Apple technologies and design your apps and games to run on all Apple platforms. See Apple Design Resources. Order content by relative importance. People often start by viewing content in reading order — that is, from top to bottom and from the leading to trailing side — so place the most important items near the top and leading side of the window or display. To support right-to-left languages, prefer standard system components that can automatically adapt UI elements to better reflect each language’s natural reading order. For guidance, see Right to left. Align elements to make them…

## Implicações práticas

- Inferência para o modal do Zforge: a página não estabelece uma posição obrigatória para rótulos de seletores. O critério explícito é alinhar elementos, agrupar os relacionados e preservar hierarquia e leitura.
- A adaptação a janelas menores deve preservar espaçamento e legibilidade, inclusive com nomes localizados.

## Mapa do conteúdo

- Visual hierarchy
- Adaptability
- Size classes
- Guides and safe areas
- Platform considerations
- macOS
- tvOS
- Grids
- Two-column grid
- Three-column grid
- Four-column grid
- Five-column grid
- Six-column grid
- Seven-column grid
- Eight-column grid
- Nine-column grid
- visionOS
- watchOS
- Resources
- Related
- Developer documentation
- Videos
- Change log

## Links do segundo nível

### Overview and featured references

- [Apple Design Resources](https://developer.apple.com/design/resources/) — _Apple Developer; expandir sob demanda_
- [Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left) — Support right-to-left languages like Arabic and Hebrew by reversing your interface as needed to match the reading direction of the related scripts. _(Apple Developer; expandir sob demanda)_
- [Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views) — A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally. _(Apple Developer; expandir sob demanda)_
- [backgroundExtensionEffect()](https://developer.apple.com/documentation/swiftui/view/backgroundextensioneffect()) — Adds the background extension effect to the view. The view will be duplicated into mirrored copies which will be placed around the view on… _(Apple Developer; expandir sob demanda)_
- [UIBackgroundExtensionView](https://developer.apple.com/documentation/uikit/uibackgroundextensionview) — A view that extends content to fill its own bounds. _(Apple Developer; expandir sob demanda)_
- [Supporting Dynamic Type](https://developer.apple.com/design/human-interface-guidelines/typography#Supporting-Dynamic-Type) — _Apple Developer; expandir sob demanda_
- [Apple – Accessibility](https://github.com/apple/unityplugins/blob/main/plug-ins/Apple.Accessibility/Apple.Accessibility_Unity/Assets/Apple.Accessibility/Documentation~/Apple.Accessibility.md) — _Apple Developer; expandir sob demanda_
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography) — Your typographic choices can help you display legible text, convey an information hierarchy, communicate important content, and express your brand or style. _(Apple Developer; expandir sob demanda)_
- [Device Hub](https://developer.apple.com/documentation/xcode/device-hub) — Manage the simulated and physical devices that you use to test your app. _(Apple Developer; expandir sob demanda)_
- [Windows](https://developer.apple.com/design/human-interface-guidelines/windows) — A window presents UI views and components in your app or game. _(Apple Developer; expandir sob demanda)_
- [Multitasking](https://developer.apple.com/design/human-interface-guidelines/multitasking) — Multitasking lets people switch quickly from one app to another, performing tasks in each. _(Apple Developer; expandir sob demanda)_
- [UITraitChangeObservable](https://developer.apple.com/documentation/uikit/uitraitchangeobservable-67e94) — A type that calls your code in reaction to changes in the trait environment. _(Apple Developer; expandir sob demanda)_
- [UserInterfaceSizeClass](https://developer.apple.com/documentation/swiftui/userinterfacesizeclass) — A set of values that indicate the visual size available to the view. _(Apple Developer; expandir sob demanda)_
- [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) — A tab bar lets people navigate between top-level sections of your app. _(Apple Developer; expandir sob demanda)_
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars) — A sidebar appears on the leading side of a view and lets people navigate between areas of your app or top-level collections of content… _(Apple Developer; expandir sob demanda)_
- [UILayoutGuide](https://developer.apple.com/documentation/uikit/uilayoutguide) — A rectangular area that can interact with Auto Layout. _(Apple Developer; expandir sob demanda)_
- [NSLayoutGuide](https://developer.apple.com/documentation/appkit/nslayoutguide) — A rectangular area that can interact with Auto Layout. _(Apple Developer; expandir sob demanda)_
- [SafeAreaRegions](https://developer.apple.com/documentation/swiftui/safearearegions) — A set of symbolic safe area regions. _(Apple Developer; expandir sob demanda)_
- [Positioning content relative to the safe area](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area) — Position views so that they aren’t obstructed by other content. _(Apple Developer; expandir sob demanda)_
- [NSPrefersDisplaySafeAreaCompatibilityMode](https://developer.apple.com/documentation/bundleresources/information-property-list/nsprefersdisplaysafeareacompatibilitymode) — A Boolean value that indicates whether the app prefers to run in compatibility mode when necessary. _(Apple Developer; expandir sob demanda)_
- [About focus interactions for Apple TV](https://developer.apple.com/documentation/uikit/about-focus-interactions-for-apple-tv) — Design and implement intuitive control schemes for menus and interactive user interface layouts. _(Apple Developer; expandir sob demanda)_
- [UICollectionViewFlowLayout](https://developer.apple.com/documentation/uikit/uicollectionviewflowlayout) — A layout object that organizes items into a grid with optional header and footer views for each section. _(Apple Developer; expandir sob demanda)_
- [Spatial layout](https://developer.apple.com/design/human-interface-guidelines/spatial-layout) — Spatial layout techniques help you take advantage of the infinite canvas of Apple Vision Pro and present your content in engaging, comfortable ways. _(Apple Developer; expandir sob demanda)_
- [visionOS](https://developer.apple.com/design/human-interface-guidelines/windows#visionOS) — _Apple Developer; expandir sob demanda_
- [Positioning and sizing windows](https://developer.apple.com/documentation/visionos/positioning-and-sizing-windows) — Influence the initial geometry of windows that your app presents. _(Apple Developer; expandir sob demanda)_
- [Ornaments](https://developer.apple.com/design/human-interface-guidelines/ornaments) — In visionOS, an ornament presents controls and information related to a window, without crowding or obscuring the window’s contents. _(Apple Developer; expandir sob demanda)_
- [defaultWindowPlacement(_:)](https://developer.apple.com/documentation/swiftui/scene/defaultwindowplacement(_:)) — Defines a function used for determining the default placement of windows. _(Apple Developer; expandir sob demanda)_
- [Eyes](https://developer.apple.com/design/human-interface-guidelines/eyes) — In visionOS, people look at a virtual object to identify it as a target they can interact with. _(Apple Developer; expandir sob demanda)_
- [visionOS](https://developer.apple.com/design/human-interface-guidelines/buttons#visionOS) — _Apple Developer; expandir sob demanda_
- [isAutorotating](https://developer.apple.com/documentation/watchkit/wkextension/isautorotating) — A Boolean value that determines whether the interface automatically rotates when the user flips their wrist. _(Apple Developer; expandir sob demanda)_
- [Layout and organization](https://developer.apple.com/design/human-interface-guidelines/layout-and-organization) — _Apple Developer; expandir sob demanda_
- [Composing custom layouts with SwiftUI](https://developer.apple.com/documentation/swiftui/composing-custom-layouts-with-swiftui) — Arrange views in your app’s interface using layout tools that SwiftUI provides. _(Apple Developer; expandir sob demanda)_
- [Get to know the new design system](https://developer.apple.com/videos/play/wwdc2025/356) — Dive deeper into the new design system to explore key changes to visual design, information architecture, and core system components. Learn how the system… _(Apple Developer; expandir sob demanda)_
- [Compose custom layouts with SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10056) — SwiftUI now offers powerful tools to level up your layouts and arrange views for your app’s interface. We’ll introduce you to the Grid container… _(Apple Developer; expandir sob demanda)_
- [Essential Design Principles](https://developer.apple.com/videos/play/wwdc2017/802) — Design principles are the key to understanding how design serves human needs for safety, meaning, achievement and beauty. Learn what these principles are and… _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/design/human-interface-guidelines/layout)
- Captura: `2026-09-28T23:25:02+00:00`
- SHA-256 do payload: `d41f32ddf76c597f0edd54eac361fa294a8736cfc4ccc627d1709fe092ed7267`
- Escopo: expansão sob demanda de uma página; links absolutos acima ainda não foram percorridos.
