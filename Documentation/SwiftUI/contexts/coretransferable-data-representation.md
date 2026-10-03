---
title: "DataRepresentation"
source_url: "https://developer.apple.com/documentation/coretransferable/datarepresentation"
source_identifier: "doc://com.apple.CoreTransferable/documentation/CoreTransferable/DataRepresentation"
captured_at: "2026-10-03T22:58:36.198078+00:00"
source_sha256: "6ddeba931f6c773c91010a27a3f1e6106dc38e31cd728eb3754c0f414f35290a"
source_etag: "\"4455-659029bad3bff\""
source_last_modified: "Fri, 14 Aug 2026 14:26:36 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Drag and drop"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# DataRepresentation

## Consulta rápida

- `struct DataRepresentation<Item> where Item: Transferable` declara uma representação de bytes identificada por um UTType.
- A variante `init(exportedContentType:exporting:)` oferece somente exportação; o closure assíncrono retorna `Data`.
- API compilada contra o SDK macOS 27.0; disponível desde macOS 13.

## Aplicação no Zforge

O drag de arquivos exporta `public.file-url` como bytes da URL absoluta original. O destino lê a localização usando `NSURL`/`NSItemProvider`, sem transformar a URL em um arquivo prometido. Essa escolha de formato é do app; a página descreve a API genérica, não prova a causa de uma regressão específica. Conferir a URL decodificada com o provider real e os gestos no app.

## Mapa

- Overview: bytes como formato interoperável; combinação de representações.
- Initializers: importação/exportação, exportação apenas e importação apenas.

## Links secundários

- [Choosing a transfer representation for a model type](https://developer.apple.com/documentation/coretransferable/choosing-a-transfer-representation-for-a-model-type) — não consultado nesta captura.
- [CodableRepresentation](https://developer.apple.com/documentation/coretransferable/codablerepresentation) — não consultado nesta captura.
- [Core Transferable](https://developer.apple.com/documentation/coretransferable) — não consultado nesta captura.
- [DataRepresentation](https://developer.apple.com/documentation/coretransferable/datarepresentation) — não consultado nesta captura.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — não consultado nesta captura.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — não consultado nesta captura.
- [Technologies](https://developer.apple.com/documentation/technologies) — não consultado nesta captura.
- [TransferRepresentation](https://developer.apple.com/documentation/coretransferable/transferrepresentation) — não consultado nesta captura.
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable) — não consultado nesta captura.
- [init(contentType:exporting:importing:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(contenttype:exporting:importing:)) — não consultado nesta captura.
- [init(exportedContentType:exporting:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(exportedcontenttype:exporting:)) — não consultado nesta captura.
- [init(importedContentType:importing:)](https://developer.apple.com/documentation/coretransferable/datarepresentation/init(importedcontenttype:importing:)) — não consultado nesta captura.

## Proveniência

- Captura de uma página Apple; SHA-256 `6ddeba931f6c773c91010a27a3f1e6106dc38e31cd728eb3754c0f414f35290a`; `2026-10-03T22:58:36.198078+00:00`.
