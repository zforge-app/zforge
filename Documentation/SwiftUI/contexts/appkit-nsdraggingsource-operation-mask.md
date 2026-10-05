---
title: "draggingSession(_:sourceOperationMaskFor:)"
source_url: "https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingSource/draggingSession(_:sourceOperationMaskFor:)"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "eac28bc9fe845f196da379b8565bcf23e88f74cbe3533368db68ebb284ae0d56"
source_etag: "\"3be4-659026e43247b\""
source_last_modified: "Fri, 14 Aug 2026 14:13:54 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# draggingSession(_:sourceOperationMaskFor:)

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS 10.7+
- Declaração: `@ MainActor   func   draggingSession ( _   session :  NSDraggingSession ,  sourceOperationMaskFor   context :  NSDraggingContext ) ->  NSDragOperation`

## Síntese

A origem informa ao AppKit um conjunto de operações aceitas conforme o contexto (dentro ou fora da aplicação). O método devolve NSDragOperation; contextos desconhecidos devem receber uma política explícita.

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — Apple Developer; expandir sob demanda.
- [NSDragOperation](https://developer.apple.com/documentation/appkit/nsdragoperation) — Apple Developer; expandir sob demanda.
- [NSDraggingContext](https://developer.apple.com/documentation/appkit/nsdraggingcontext) — Apple Developer; expandir sob demanda.
- [NSDraggingSession](https://developer.apple.com/documentation/appkit/nsdraggingsession) — Apple Developer; expandir sob demanda.
- [NSDraggingSource](https://developer.apple.com/documentation/appkit/nsdraggingsource) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)).
- Captura: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `eac28bc9fe845f196da379b8565bcf23e88f74cbe3533368db68ebb284ae0d56`.
- Escopo: uma página; links secundários não percorridos.
