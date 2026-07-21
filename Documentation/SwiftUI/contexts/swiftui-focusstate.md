---
title: "FocusState"
source_url: "https://developer.apple.com/documentation/swiftui/focusstate"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/FocusState"
captured_at: "2026-07-19T00:24:22+00:00"
source_sha256: "1c22c2f51ca851696edd2494294a6af7cfb7ff4de6b0ecbb92ad0b94876082d6"
source_etag: "W/\"f3760b7b8936f022ed3abf9a929a9548\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# FocusState

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Structure and property wrapper
- Módulo: SwiftUI
- Relevância para Zforge: direta para distinguir o foco persistente da área do navegador do foco temporário do editor de nome.
- Disponibilidade: macOS 12.0 ou posterior; também disponível nas demais plataformas SwiftUI indicadas pela Apple.
- Declaração: `@frozen @propertyWrapper struct FocusState<Value> where Value: Hashable`

## Síntese

`FocusState` mantém um valor que acompanha a posição do foco na cena. Associar views por `focused(_:equals:)` permite representar destinos distintos com um único valor opcional e `Hashable`; atribuir esse valor programaticamente move o foco para a view correspondente.

A Apple destaca que bindings ambíguos produzem candidatos indistinguíveis. Em hierarquias com um container focável e um campo interno, dois estados booleanos independentes também têm semântica diferente: o Boolean do container pode indicar tanto que ele recebeu foco quanto que contém um descendente focado. Um único estado tipado, com casos separados para container e campo, oferece controle granular e desambigua os destinos.

## Implicações práticas

- Modelar a área persistente do navegador e cada editor inline como casos diferentes de um único `FocusState` opcional.
- Usar `focused(_:equals:)` no container e no `TextField`, atribuindo programaticamente o caso do item que deve ser renomeado.
- Não reutilizar o mesmo valor de foco em duas views simultaneamente; SwiftUI pode escolher um candidato e emitir aviso em runtime.
- Usar `nil` para representar ausência total de foco e restaurar explicitamente o caso do conteúdo quando a edição terminar.

## Mapa do conteúdo

- Overview
- Avoid ambiguous focus bindings
- Nest focusable views
- Creating a focus state
- Inspecting the focus state

## Links do segundo nível

### APIs relacionadas

- [focused(_:equals:)](https://developer.apple.com/documentation/swiftui/view/focused(_:equals:)) — associa uma view a um valor específico do estado de foco. _Apple Developer; expandir sob demanda_
- [focused(_:)](https://developer.apple.com/documentation/swiftui/view/focused(_:)) — associa uma view a um estado booleano que também pode indicar foco contido. _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/focusstate)
- Captura: `2026-07-19T00:24:22+00:00`
- SHA-256 do payload: `1c22c2f51ca851696edd2494294a6af7cfb7ff4de6b0ecbb92ad0b94876082d6`
- Escopo: uma página oficial expandida sob demanda; os links absolutos acima ainda não foram percorridos.
