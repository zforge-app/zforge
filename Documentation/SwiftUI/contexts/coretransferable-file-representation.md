---
title: "FileRepresentation"
source_url: "https://developer.apple.com/documentation/coretransferable/filerepresentation"
source_identifier: "doc://com.apple.CoreTransferable/documentation/CoreTransferable/FileRepresentation"
captured_at: "2026-10-04T22:10:19.050472+00:00"
source_sha256: "5e26a298d6c662bc828b8d3bc4750d25a1afa6defb0b7d4f64be04398ae21ed8"
source_etag: "\"46ed-659029bae6b26\""
source_last_modified: null
source_format: "application/json"
platforms: [{"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "iOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "iPadOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "Mac Catalyst", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "13.0", "name": "macOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "16.0", "name": "tvOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "1.0", "name": "visionOS", "unavailable": false}, {"beta": false, "deprecated": false, "introducedAt": "9.0", "name": "watchOS", "unavailable": false}]
authority: "Apple Developer"
confidence: "primary-source"
---

# FileRepresentation

## Síntese

A exportação Transferable fornece um arquivo e permite representar conteúdo por arquivo. Não equivale ao destino final de uma promessa NSFilePromiseProvider; o Zforge precisa da URL exata fornecida pelo receptor para confirmar antes de escrever e coordenar remoção das origens.

## Declaração

```swift
struct FileRepresentation<Item> where Item : Transferable
```

## Mapa do conteúdo

- declarations
- mentions
- content

## Links secundários

- [Choosing a transfer representation for a model type](https://developer.apple.com/documentation/coretransferable/choosing-a-transfer-representation-for-a-model-type) — expandir sob demanda.
- [Core Transferable](https://developer.apple.com/documentation/coretransferable) — expandir sob demanda.
- [ReceivedTransferredFile](https://developer.apple.com/documentation/coretransferable/receivedtransferredfile) — expandir sob demanda.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — expandir sob demanda.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — expandir sob demanda.
- [SentTransferredFile](https://developer.apple.com/documentation/coretransferable/senttransferredfile) — expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — expandir sob demanda.
- [TransferRepresentation](https://developer.apple.com/documentation/coretransferable/transferrepresentation) — expandir sob demanda.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — expandir sob demanda.
- [init(contentType:shouldAttemptToOpenInPlace:exporting:importing:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(contenttype:shouldattempttoopeninplace:exporting:importing:)) — expandir sob demanda.
- [init(exportedContentType:shouldAllowToOpenInPlace:exporting:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(exportedcontenttype:shouldallowtoopeninplace:exporting:)) — expandir sob demanda.
- [init(importedContentType:shouldAttemptToOpenInPlace:importing:)](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(importedcontenttype:shouldattempttoopeninplace:importing:)) — expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/coretransferable/filerepresentation).
- Captura de uma página, sem percorrer links secundários. SDK consultado: macOS 27.0, Xcode local.
