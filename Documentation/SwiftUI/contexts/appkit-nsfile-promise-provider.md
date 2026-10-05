---
title: "NSFilePromiseProvider"
source_url: "https://developer.apple.com/documentation/appkit/nsfilepromiseprovider"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSFilePromiseProvider"
captured_at: "2026-10-04T13:01:09.738317+00:00"
source_sha256: "b3d86ec60ab7decea9ce9c90d28d9d5681af05d16de9142f657c17f82e6b6d5c"
source_etag: "\"67a7-659026f05e728\""
source_last_modified: "Fri, 14 Aug 2026 14:14:07 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSFilePromiseProvider

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS; assinaturas verificadas no SDK macOS 27.0
- Declaração: `class   NSFilePromiseProvider`

## Síntese

Uma promessa representa um arquivo futuro; a identidade auxiliar do item deve ser dado imediato no pasteboard, com writingOptions vazio. O conteúdo permanece uma promessa e seu delegate escreve na URL fornecida ao cumprir a solicitação. O provider deve ter fileType e delegate definidos antes de ser escrito no pasteboard.

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [CVarArg](https://developer.apple.com/documentation/swift/cvararg) — Apple Developer; expandir sob demanda.
- [CustomDebugStringConvertible](https://developer.apple.com/documentation/swift/customdebugstringconvertible) — Apple Developer; expandir sob demanda.
- [CustomStringConvertible](https://developer.apple.com/documentation/swift/customstringconvertible) — Apple Developer; expandir sob demanda.
- [Equatable](https://developer.apple.com/documentation/swift/equatable) — Apple Developer; expandir sob demanda.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — Apple Developer; expandir sob demanda.
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate) — Apple Developer; expandir sob demanda.
- [NSFilePromiseReceiver](https://developer.apple.com/documentation/appkit/nsfilepromisereceiver) — Apple Developer; expandir sob demanda.
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol) — Apple Developer; expandir sob demanda.
- [NSObject](https://developer.apple.com/documentation/objectivec/nsobject-swift.class) — Apple Developer; expandir sob demanda.
- [NSPasteboardWriting](appkit-nspasteboard-writing.md) — Apple Developer; expandir sob demanda.
- [Supporting Collection View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-collection-view-drag-and-drop-through-file-promises) — Apple Developer; expandir sob demanda.
- [Supporting Drag and Drop Through File Promises](appkit-supporting-file-promises.md) — Apple Developer; expandir sob demanda.
- [Supporting Table View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-table-view-drag-and-drop-through-file-promises) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [delegate](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/delegate) — Apple Developer; expandir sob demanda.
- [fileType](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/filetype) — Apple Developer; expandir sob demanda.
- [init()](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/init()) — Apple Developer; expandir sob demanda.
- [init(fileType:delegate:)](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/init(filetype:delegate:)) — Apple Developer; expandir sob demanda.
- [userInfo](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider/userinfo) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider).
- Captura: `2026-10-04T13:01:09.738317+00:00`; SHA-256: `b3d86ec60ab7decea9ce9c90d28d9d5681af05d16de9142f657c17f82e6b6d5c`.
- Escopo: uma página; links secundários não percorridos.
