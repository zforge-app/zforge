---
title: "NSDraggingSource"
source_url: "https://developer.apple.com/documentation/appkit/nsdraggingsource"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingSource"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "9d51b11142080f08a75d66d1556b81b8e4a18722ae098638a2bea86a41f8c9f1"
source_etag: "\"6df4-659026d43a608\""
source_last_modified: "Fri, 14 Aug 2026 14:13:38 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSDraggingSource

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS; assinatura validada no SDK macOS 27.0. A captura não informa a versão de introdução.
- Declaração: `protocol   NSDraggingSource  :  NSObjectProtocol`

## Síntese

Protocolo da origem de uma sessão de arraste no macOS. Define quais operações são permitidas, o tratamento dos modificadores e callbacks de início, movimento e fim. A interface moderna do protocolo existe desde macOS 10.7.

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [Drag and Drop](https://developer.apple.com/documentation/appkit/drag-and-drop) — Apple Developer; expandir sob demanda.
- [NSCollectionView](https://developer.apple.com/documentation/appkit/nscollectionview) — Apple Developer; expandir sob demanda.
- [NSDraggingImageComponent](https://developer.apple.com/documentation/appkit/nsdraggingimagecomponent) — Apple Developer; expandir sob demanda.
- [NSDraggingItem](https://developer.apple.com/documentation/appkit/nsdraggingitem) — Apple Developer; expandir sob demanda.
- [NSDraggingSession](https://developer.apple.com/documentation/appkit/nsdraggingsession) — Apple Developer; expandir sob demanda.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expandir sob demanda.
- [NSOutlineView](https://developer.apple.com/documentation/appkit/nsoutlineview) — Apple Developer; expandir sob demanda.
- [NSTableView](https://developer.apple.com/documentation/appkit/nstableview) — Apple Developer; expandir sob demanda.
- [NSTextView](https://developer.apple.com/documentation/appkit/nstextview) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [draggingSession(_:endedAt:operation:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:endedat:operation:)) — Apple Developer; expandir sob demanda.
- [draggingSession(_:movedTo:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:movedto:)) — Apple Developer; expandir sob demanda.
- [draggingSession(_:sourceOperationMaskFor:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:sourceoperationmaskfor:)) — Apple Developer; expandir sob demanda.
- [draggingSession(_:willBeginAt:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/draggingsession(_:willbeginat:)) — Apple Developer; expandir sob demanda.
- [ignoreModifierKeys(for:)](https://developer.apple.com/documentation/appkit/nsdraggingsource/ignoremodifierkeys(for:)) — Apple Developer; expandir sob demanda.
- [namesOfPromisedFilesDropped(atDestination:)](https://developer.apple.com/documentation/objectivec/nsobject-swift.class/namesofpromisedfilesdropped(atdestination:)) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsdraggingsource).
- Captura: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `9d51b11142080f08a75d66d1556b81b8e4a18722ae098638a2bea86a41f8c9f1`.
- Escopo: uma página; links secundários não percorridos.
