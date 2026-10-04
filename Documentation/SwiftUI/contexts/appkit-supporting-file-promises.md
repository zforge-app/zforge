---
title: "Supporting Drag and Drop Through File Promises"
source_url: "https://developer.apple.com/documentation/appkit/supporting-drag-and-drop-through-file-promises"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/supporting-drag-and-drop-through-file-promises"
captured_at: "2026-10-04T21:06:22.124690+00:00"
source_sha256: "ad5aea4873ea3fd5f914db6321f2c20104c4ee73964d5eddf097ed08f76a76d5"
source_etag: '"4b48-659026dbffe03"'
source_last_modified: "Fri, 14 Aug 2026 14:13:46 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Supporting Drag and Drop Through File Promises

## Síntese

Exemplo oficial macOS 10.15+/Xcode 13.3+: exportar conteúdo ainda não materializado por NSFilePromiseProvider; receber promises antes de URLs. O receptor registra NSFilePromiseReceiver.readableDraggedTypes, solicita receivePromisedFiles na pasta escolhida e processa a URL entregue no callback. O provider informa nome, fila e escreve na URL exata solicitada, concluindo só após a escrita. A fila de background evita bloquear UI.

## Implicações no Zforge

Não deduzir destino do ponto final na tela. Destinos internos recebem a identidade virtual e chamam a extração com a pasta explícita; destinos externos recebem a promessa e escolhem a URL. Remover do archive apenas após exportações bem-sucedidas e aceite de movimento. Validar com drop real e existência/conteúdo no destino, além dos testes diretos dos delegates.

## Mapa

- Configuração do exemplo de imagens.
- Importação de promises e URLs.
- Exportação com os três métodos do delegate.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit)
- [NSFilePromiseProvider](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider)
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate)
- [operationQueue(for:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/operationqueue(for:))
- [NSFilePromiseReceiver](https://developer.apple.com/documentation/appkit/nsfilepromisereceiver)
- [Documents, Data, and Pasteboard](https://developer.apple.com/documentation/appkit/documents-data-and-pasteboard)
- [Supporting Collection View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-collection-view-drag-and-drop-through-file-promises)
- [Supporting Table View Drag and Drop Through File Promises](https://developer.apple.com/documentation/appkit/supporting-table-view-drag-and-drop-through-file-promises)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Proveniência

Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/supporting-drag-and-drop-through-file-promises); captura 2026-10-04T21:06:22.124690+00:00, SHA-256 `ad5aea4873ea3fd5f914db6321f2c20104c4ee73964d5eddf097ed08f76a76d5`. Uma página; links secundários não percorridos.
