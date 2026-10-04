---
title: "NSPasteboardWriting"
source_url: "https://developer.apple.com/documentation/appkit/nspasteboardwriting"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSPasteboardWriting"
captured_at: "2026-10-04T13:01:09.738317+00:00"
source_sha256: "3bd28ec45e98fedfff1a63479b43e5dff117073ee21bc4c79d2f3124e3c10f7c"
source_etag: "\"850b-659026dadbf7d\""
source_last_modified: "Fri, 14 Aug 2026 14:13:45 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSPasteboardWriting

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS; assinaturas verificadas no SDK macOS 27.0
- Declaração: `protocol   NSPasteboardWriting  :  NSObjectProtocol`

## Síntese

Uma promessa representa um arquivo futuro; a identidade auxiliar do item deve ser dado imediato no pasteboard, com writingOptions vazio. O conteúdo permanece uma promessa e seu delegate escreve na URL fornecida ao cumprir a solicitação. O provider deve ter fileType e delegate definidos antes de ser escrito no pasteboard.

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [NSAttributedString](https://developer.apple.com/documentation/foundation/nsattributedstring) — Apple Developer; expandir sob demanda.
- [NSColor](https://developer.apple.com/documentation/appkit/nscolor) — Apple Developer; expandir sob demanda.
- [NSFilePromiseProvider](appkit-nsfile-promise-provider.md) — Apple Developer; expandir sob demanda.
- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — Apple Developer; expandir sob demanda.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expandir sob demanda.
- [NSPasteboard.ContentsOptions](https://developer.apple.com/documentation/appkit/nspasteboard/contentsoptions) — Apple Developer; expandir sob demanda.
- [NSPasteboard.WritingOptions](https://developer.apple.com/documentation/appkit/nspasteboard/writingoptions) — Apple Developer; expandir sob demanda.
- [NSPasteboardItemDataProvider](https://developer.apple.com/documentation/appkit/nspasteboarditemdataprovider) — Apple Developer; expandir sob demanda.
- [NSPasteboardItem](https://developer.apple.com/documentation/appkit/nspasteboarditem) — Apple Developer; expandir sob demanda.
- [NSPasteboardReading](https://developer.apple.com/documentation/appkit/nspasteboardreading) — Apple Developer; expandir sob demanda.
- [NSPasteboardTypeOwner](https://developer.apple.com/documentation/appkit/nspasteboardtypeowner) — Apple Developer; expandir sob demanda.
- [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard) — Apple Developer; expandir sob demanda.
- [NSSound](https://developer.apple.com/documentation/appkit/nssound) — Apple Developer; expandir sob demanda.
- [NSString](https://developer.apple.com/documentation/foundation/nsstring) — Apple Developer; expandir sob demanda.
- [NSTextStorage](https://developer.apple.com/documentation/appkit/nstextstorage) — Apple Developer; expandir sob demanda.
- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — Apple Developer; expandir sob demanda.
- [Pasteboard Writing Options](https://developer.apple.com/documentation/appkit/pasteboard-writing-options) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [pasteboardPropertyList(forType:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/pasteboardpropertylist(fortype:)) — Apple Developer; expandir sob demanda.
- [writableTypes(for:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/writabletypes(for:)) — Apple Developer; expandir sob demanda.
- [writeObjects(_:)](https://developer.apple.com/documentation/appkit/nspasteboard/writeobjects(_:)) — Apple Developer; expandir sob demanda.
- [writingOptions(forType:pasteboard:)](https://developer.apple.com/documentation/appkit/nspasteboardwriting/writingoptions(fortype:pasteboard:)) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nspasteboardwriting).
- Captura: `2026-10-04T13:01:09.738317+00:00`; SHA-256: `3bd28ec45e98fedfff1a63479b43e5dff117073ee21bc4c79d2f3124e3c10f7c`.
- Escopo: uma página; links secundários não percorridos.
