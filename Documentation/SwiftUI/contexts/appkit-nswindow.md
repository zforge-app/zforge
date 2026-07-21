---
title: "NSWindow"
source_url: "https://developer.apple.com/documentation/appkit/nswindow"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSWindow"
captured_at: "2026-07-18T22:54:20Z"
source_sha256: "9c0bb122b670afc94781687540aed350531019f089410341a5c37d9749f5a172"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSWindow

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: classe que representa uma janela exibida pelo aplicativo.
- Módulo: AppKit.
- Relevância para Zforge: direta; fornece o sistema nativo de abas de janela e a integração do título com uma URL representada.
- Disponibilidade: macOS.
- Declaração: `@MainActor class NSWindow`

## Síntese

Cada instância de `NSWindow` corresponde a no máximo uma janela visível, hospeda a hierarquia de views e distribui eventos de mouse e teclado. A classe inclui uma seção específica para gerenciamento de abas de janela, com identificação dos grupos compatíveis, política de tabulação automática, ações do responder chain para mostrar a barra, selecionar abas e mover uma aba para outra janela.

## Implicações práticas

- Usar a tab bar gerenciada por `NSWindow`, em vez de desenhar uma barra dentro do conteúdo SwiftUI, mantém aparência, comandos, agrupamento e acessibilidade nativos.
- Janelas do navegador devem compartilhar um `tabbingIdentifier` e usar `tabbingMode = .automatic`; `toggleTabBar(_:)` atende ao comando de mostrar ou ocultar a barra.
- Por pertencer à moldura da janela, a tab bar nativa atravessa a largura da janela acima de toda a hierarquia de conteúdo, incluindo a região ocupada pelo preview. Ela não deve ser limitada pelo split interno entre conteúdo e inspector.
- Definir `representedURL` permite que AppKit associe a janela à localização atual e forneça o menu de ancestrais ao clicar no título com Command.

## Mapa do conteúdo

- Visão geral e criação de janelas.
- Configuração do conteúdo, aparência e comportamento.
- Gerenciamento de abas de janela.
- Informações, layout, redimensionamento, sheets e eventos.

## Links do segundo nível

### Abas de janela

- [tabbingIdentifier](https://developer.apple.com/documentation/appkit/nswindow/tabbingidentifier-swift.property) — _Apple Developer; expandir sob demanda_
- [tabbingMode](https://developer.apple.com/documentation/appkit/nswindow/tabbingmode-swift.property) — _Apple Developer; expandir sob demanda_
- [toggleTabBar(_:)](https://developer.apple.com/documentation/appkit/nswindow/toggletabbar(_:)) — _Apple Developer; expandir sob demanda_
- [selectNextTab(_:)](https://developer.apple.com/documentation/appkit/nswindow/selectnexttab(_:)) — _Apple Developer; expandir sob demanda_
- [selectPreviousTab(_:)](https://developer.apple.com/documentation/appkit/nswindow/selectprevioustab(_:)) — _Apple Developer; expandir sob demanda_

### Integração com a localização

- [representedURL](https://developer.apple.com/documentation/appkit/nswindow/representedurl) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nswindow)
- Captura: `2026-07-18T22:54:20Z`
- SHA-256 do payload: `9c0bb122b670afc94781687540aed350531019f089410341a5c37d9749f5a172`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
