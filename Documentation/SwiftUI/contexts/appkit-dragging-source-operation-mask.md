---
title: "draggingSourceOperationMask"
source_url: "https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsourceoperationmask"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingInfo/draggingSourceOperationMask"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "a719c5e7a53379626f3030d28497f24610e5d177c22a20610439bc257d0472b7"
source_etag: "\"73ea-659026d849472\""
source_last_modified: "Fri, 14 Aug 2026 14:13:42 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# draggingSourceOperationMask

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS; assinatura validada no SDK macOS 27.0. A captura não informa a versão de introdução.
- Declaração: `@ MainActor   var   draggingSourceOperationMask :  NSDragOperation  {  get  }`

## Síntese

O destino consulta a máscara anunciada pela origem. Quando modificadores são processados pelo sistema, Option escolhe cópia, Command movimentação e a combinação cria link. A origem pode desativar essa tradução por ignoreModifierKeys(for:).

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [MainActor](https://developer.apple.com/documentation/swift/mainactor) — Apple Developer; expandir sob demanda.
- [NSDragOperationNone](https://developer.apple.com/documentation/appkit/nsdragoperation/nsdragoperationnone) — Apple Developer; expandir sob demanda.
- [NSDragOperation](https://developer.apple.com/documentation/appkit/nsdragoperation) — Apple Developer; expandir sob demanda.
- [NSDraggingInfo](https://developer.apple.com/documentation/appkit/nsdragginginfo) — Apple Developer; expandir sob demanda.
- [NSDraggingSource](https://developer.apple.com/documentation/appkit/nsdraggingsource) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [copy](https://developer.apple.com/documentation/appkit/nsdragoperation/copy) — Apple Developer; expandir sob demanda.
- [draggingDestinationWindow](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingdestinationwindow) — Apple Developer; expandir sob demanda.
- [draggingLocation](https://developer.apple.com/documentation/appkit/nsdragginginfo/dragginglocation) — Apple Developer; expandir sob demanda.
- [draggingPasteboard](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingpasteboard) — Apple Developer; expandir sob demanda.
- [draggingSequenceNumber](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsequencenumber) — Apple Developer; expandir sob demanda.
- [draggingSession(_:sourceOperationMaskFor:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)) — Apple Developer; expandir sob demanda.
- [draggingSource](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsource) — Apple Developer; expandir sob demanda.
- [ignoreModifierKeys(for:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/ignoremodifierkeys(for:)) — Apple Developer; expandir sob demanda.
- [link](https://developer.apple.com/documentation/appkit/nsdragoperation/link) — Apple Developer; expandir sob demanda.
- [move](https://developer.apple.com/documentation/appkit/nsdragoperation/move) — Apple Developer; expandir sob demanda.
- [namesOfPromisedFilesDropped(atDestination:)](https://developer.apple.com/documentation/appkit/nsdragginginfo/namesofpromisedfilesdropped(atdestination:)) — Apple Developer; expandir sob demanda.
- [numberOfValidItemsForDrop](https://developer.apple.com/documentation/appkit/nsdragginginfo/numberofvaliditemsfordrop) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdragginginfo/draggingsourceoperationmask).
- Captura: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `a719c5e7a53379626f3030d28497f24610e5d177c22a20610439bc257d0472b7`.
- Escopo: uma página; links secundários não percorridos.
