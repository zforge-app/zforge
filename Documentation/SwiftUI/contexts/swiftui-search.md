---
title: "Search"
source_url: "https://developer.apple.com/documentation/swiftui/search"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Search"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "bdcf4acde7e2d01d9387e6446709da7f68b76e4b8619939b0b79945da0589475"
source_etag: "W/\"533d082a76bffe2c1d628e44fa686db5\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Search

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Enable people to search for text or other content within your app.

To present a search field in your app, create and manage storage for search text and optionally for discrete search terms known as tokens. Then bind the storage to the search field by applying the searchable view modifier to a view in your app. As people interact with the field, they implicitly modify the underlying storage and, thereby, the search parameters. Your app correspondingly updates other parts of its interface. To enhance the search interaction, you can also: Offer suggestions during search, for both text and tokens. Implement search scopes that help people to narrow the search space. Detect when people activate the search field, and programmatically dismiss the search field using environment values. For design guidance, see Searching in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Searching](https://developer.apple.com/design/Human-Interface-Guidelines/searching) — People use various search techniques to find content on their device, within an app, and within a document or file. _(Apple Developer; expandir sob demanda)_

### Searching your app’s data model

- [Adding a search interface to your app](https://developer.apple.com/documentation/swiftui/adding-a-search-interface-to-your-app) — Present an interface that people can use to search for content in your app. _(Apple Developer; expandir sob demanda)_
- [Performing a search operation](https://developer.apple.com/documentation/swiftui/performing-a-search-operation) — Update search results based on search text and optional tokens that you store. _(Apple Developer; expandir sob demanda)_
- [searchable(text:placement:prompt:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)) — Marks this view as searchable, which configures the display of a search field. _(Apple Developer; expandir sob demanda)_
- [searchable(text:tokens:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:tokens:placement:prompt:token:)) — Marks this view as searchable with text and tokens. _(Apple Developer; expandir sob demanda)_
- [searchable(text:editableTokens:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:editabletokens:placement:prompt:token:)) — Marks this view as searchable, which configures the display of a search field. _(Apple Developer; expandir sob demanda)_
- [SearchFieldPlacement](https://developer.apple.com/documentation/swiftui/searchfieldplacement) — The placement of a search field in a view hierarchy. _(Apple Developer; expandir sob demanda)_

### Making search suggestions

- [Suggesting search terms](https://developer.apple.com/documentation/swiftui/suggesting-search-terms) — Provide suggestions to people searching for content in your app. _(Apple Developer; expandir sob demanda)_
- [searchSuggestions(_:)](https://developer.apple.com/documentation/swiftui/view/searchsuggestions(_:)) — Configures the search suggestions for this view. _(Apple Developer; expandir sob demanda)_
- [searchSuggestions(_:for:)](https://developer.apple.com/documentation/swiftui/view/searchsuggestions(_:for:)) — Configures how to display search suggestions within this view. _(Apple Developer; expandir sob demanda)_
- [searchCompletion(_:)](https://developer.apple.com/documentation/swiftui/view/searchcompletion(_:)) — Associates a fully formed string with the value of this view when used as a search suggestion. _(Apple Developer; expandir sob demanda)_
- [searchable(text:tokens:suggestedTokens:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:tokens:suggestedtokens:placement:prompt:token:)) — Marks this view as searchable with text, tokens, and suggestions. _(Apple Developer; expandir sob demanda)_
- [SearchSuggestionsPlacement](https://developer.apple.com/documentation/swiftui/searchsuggestionsplacement) — The ways that SwiftUI displays search suggestions. _(Apple Developer; expandir sob demanda)_

### Limiting search scope

- [Scoping a search operation](https://developer.apple.com/documentation/swiftui/scoping-a-search-operation) — Divide the search space into a few broad categories. _(Apple Developer; expandir sob demanda)_
- [searchScopes(_:scopes:)](https://developer.apple.com/documentation/swiftui/view/searchscopes(_:scopes:)) — Configures the search scopes for this view. _(Apple Developer; expandir sob demanda)_
- [searchScopes(_:activation:_:)](https://developer.apple.com/documentation/swiftui/view/searchscopes(_:activation:_:)) — Configures the search scopes for this view with the specified activation strategy. _(Apple Developer; expandir sob demanda)_
- [SearchScopeActivation](https://developer.apple.com/documentation/swiftui/searchscopeactivation) — The ways that searchable modifiers can show or hide search scopes. _(Apple Developer; expandir sob demanda)_

### Detecting, activating, and dismissing search

- [Managing search interface activation](https://developer.apple.com/documentation/swiftui/managing-search-interface-activation) — Programmatically detect and dismiss a search field. _(Apple Developer; expandir sob demanda)_
- [isSearching](https://developer.apple.com/documentation/swiftui/environmentvalues/issearching) — A Boolean value that indicates when the user is searching. _(Apple Developer; expandir sob demanda)_
- [dismissSearch](https://developer.apple.com/documentation/swiftui/environmentvalues/dismisssearch) — An action that ends the current search interaction. _(Apple Developer; expandir sob demanda)_
- [DismissSearchAction](https://developer.apple.com/documentation/swiftui/dismisssearchaction) — An action that can end a search interaction. _(Apple Developer; expandir sob demanda)_
- [searchable(text:isPresented:placement:prompt:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:ispresented:placement:prompt:)) — Marks this view as searchable with programmatic presentation of the search field. _(Apple Developer; expandir sob demanda)_
- [searchable(text:tokens:isPresented:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:tokens:ispresented:placement:prompt:token:)) — Marks this view as searchable with text and tokens, as well as programmatic presentation. _(Apple Developer; expandir sob demanda)_
- [searchable(text:editableTokens:isPresented:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:editabletokens:ispresented:placement:prompt:token:)) — Marks this view as searchable, which configures the display of a search field. _(Apple Developer; expandir sob demanda)_
- [searchable(text:tokens:suggestedTokens:isPresented:placement:prompt:token:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:tokens:suggestedtokens:ispresented:placement:prompt:token:)) — Marks this view as searchable with text, tokens, and suggestions, as well as programmatic presentation. _(Apple Developer; expandir sob demanda)_

### Displaying toolbar content during search

- [searchPresentationToolbarBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/searchpresentationtoolbarbehavior(_:)) — Configures the search toolbar presentation behavior for any searchable modifiers within this view. _(Apple Developer; expandir sob demanda)_
- [SearchPresentationToolbarBehavior](https://developer.apple.com/documentation/swiftui/searchpresentationtoolbarbehavior) — A type that defines how the toolbar behaves when presenting search. _(Apple Developer; expandir sob demanda)_

### Searching for text in a view

- [findNavigator(isPresented:)](https://developer.apple.com/documentation/swiftui/view/findnavigator(ispresented:)) — Programmatically presents the find and replace interface for text editor views. _(Apple Developer; expandir sob demanda)_
- [findDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/finddisabled(_:)) — Prevents find and replace operations in a text editor. _(Apple Developer; expandir sob demanda)_
- [replaceDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/replacedisabled(_:)) — Prevents replace operations in a text editor. _(Apple Developer; expandir sob demanda)_
- [FindContext](https://developer.apple.com/documentation/swiftui/findcontext) — The status of the find navigator for views which support text editing. _(Apple Developer; expandir sob demanda)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(contexto local)_
- [Modal presentations](swiftui-modal-presentations.md) — Present content in a separate view that offers focused interaction. _(contexto local)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(contexto local)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/search)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `bdcf4acde7e2d01d9387e6446709da7f68b76e4b8619939b0b79945da0589475`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
