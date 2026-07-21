---
title: "modifierKeyAlternate(_:_:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/modifierkeyalternate(_:_:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/modifierKeyAlternate(_:_:)"
captured_at: "2026-07-20T00:33:49+00:00"
source_sha256: "9e5dc4ed7b20d55f7f42d007ceee6a6c2ab7166cefc3229f038c2da412c80a76"
source_etag: "W/\"7c8be7da34a833f21f892e12b65d3f7c\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# modifierKeyAlternate(_:_:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Instance Method
- Módulo: SwiftUI
- Relevância para Zforge: Direta para comandos de menu que compartilham uma tecla base e mudam de ação com Option.
- Disponibilidade: macOS 15.0+
- Declaração: `nonisolated func modifierKeyAlternate<V>(_ modifiers: EventModifiers, @ContentBuilder _ alternate: () -> V) -> some View where V : View`

## Síntese

Constrói uma visualização alternativa que substitui a principal enquanto todos os modificadores indicados estão pressionados. Em contextos com estilo de menu, o SwiftUI transforma essa alternativa em um item de menu alternativo nativo.

Quando a visualização principal possui um atalho, ele serve de base para o atalho alternativo. Assim, um botão com `Command + V` e `modifierKeyAlternate(.option)` produz naturalmente `Option + Command + V` para sua alternativa. Um atalho explícito dentro do conteúdo alternativo substitui essa inferência.

## Implicações práticas

- Comandos que compartilham a mesma tecla e diferem por Option devem ser relacionados por `modifierKeyAlternate`, não adicionados como itens independentes do menu.
- Comandos que usam teclas-base diferentes devem permanecer como itens independentes, sem `modifierKeyAlternate`.
- A API foi validada no SDK macOS 26.5 do Xcode local e está disponível desde macOS 15.0.

## Mapa do conteúdo

- Parameters
- Return Value
- Discussion

## Links do segundo nível

### Tipos relacionados

- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers) — Modificadores de evento usados para definir quando a alternativa substitui o item principal. _(Apple Developer; expandir sob demanda)_
- [onModifierKeysChanged(mask:initial:_:)](https://developer.apple.com/documentation/swiftui/view/onmodifierkeyschanged(mask:initial:_:)) — Observa alterações nas teclas modificadoras. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/modifierkeyalternate(_:_:))
- Captura: `2026-07-20T00:33:49+00:00`
- SHA-256 do payload: `9e5dc4ed7b20d55f7f42d007ceee6a6c2ab7166cefc3229f038c2da412c80a76`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
