---
title: "onModifierKeysChanged(mask:initial:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/onModifierKeysChanged(mask:initial:_:)"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "227d3b6efe67d062b86163ed14ca9b91dae234fb43b267ae74e706be5f3913e6"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# onModifierKeysChanged(mask:initial:_:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: modificador de observação de teclas modificadoras
- Módulo: SwiftUI
- Relevância para Zforge: direta para acompanhar Option e Command durante drag and drop
- Disponibilidade: macOS 15.0+
- Declaração: `func onModifierKeysChanged(mask: EventModifiers = .all, initial: Bool = true, _ action: (EventModifiers, EventModifiers) -> Void) -> some View`

## Síntese

Executa uma ação quando uma tecla modificadora de hardware é pressionada ou solta. O `mask` limita as teclas observadas, `initial` solicita uma leitura ao aparecer e a ação recebe os valores anterior e atual.

Com `initial` habilitado, o SwiftUI verifica as teclas quando a view aparece; depois, emite mudanças das teclas incluídas na máscara. O estado emitido combina os teclados conectados.

## Implicações práticas

- Observar apenas `.option` e `.command` no navegador evita atualizações irrelevantes.
- Uma sessão de drop em andamento deve compartilhar um objeto de referência atualizado pela ação; capturar apenas um valor de `EventModifiers` pode congelar o estado inicial no delegate.
- A observação define a intenção de cópia, movimentação ou alias, mas não substitui a obrigação de iniciar o carregamento dentro de `performDrop(info:)`.

## Mapa do conteúdo

- Parameters
- Return value
- Discussion

## Links do segundo nível

### Tipos relacionados

- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers) — conjunto de teclas modificadoras. _Apple Developer; expandir sob demanda_
- [modifierKeyAlternate(_:_:)](swiftui-modifier-key-alternate.md) — conteúdo alternativo de controles baseado em modificadores. _(contexto local)_
- [performDrop(info:)](swiftui-dropdelegate-performdrop.md) — consumo seguro do payload do drop. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:))
- Captura: `2026-07-20T02:07:43Z`
- SHA-256 do payload: `227d3b6efe67d062b86163ed14ca9b91dae234fb43b267ae74e706be5f3913e6`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
