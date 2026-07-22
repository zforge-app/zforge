---
title: "NSItemProvider"
source_url: "https://developer.apple.com/documentation/foundation/nsitemprovider"
source_identifier: "doc://com.apple.foundation/documentation/Foundation/NSItemProvider"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "d497a61d31294da0fbf6e42981f82efec2fe5be095e0d1842dbf32c7bb3c0d33"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSItemProvider

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: classe de transporte de dados e arquivos entre processos
- Módulo: Foundation
- Relevância para Zforge: direta para drag and drop e copy/paste de URLs de arquivos
- Disponibilidade: macOS 10.10+
- Declaração: `class NSItemProvider`

## Síntese

`NSItemProvider` transporta dados ou arquivos em drag and drop, copy/paste e extensões. Um provider pode publicar representações de arquivo, dados ou objetos e o consumidor deve solicitar uma representação compatível.

`init(contentsOf:)` cria um provider respaldado por um arquivo existente. `init(object:)` usa os identificadores fornecidos por um objeto que conforma a `NSItemProviderWriting`; `NSURL` é um desses tipos e publica representações de URL. `loadObject(ofClass:completionHandler:)` é o caminho correspondente para recuperar um objeto de uma classe registrada.

## Implicações práticas

- Para operações de arquivos, o provider e o consumidor precisam concordar sobre `public.file-url` ou sobre o contrato de objeto `NSURL`.
- A conclusão de carregamento pode ocorrer posteriormente e fora da fila principal; atualizações de UI devem retornar à main queue ou ao `MainActor`.
- As restrições temporais específicas do drop são definidas por `DropDelegate.performDrop(info:)`.

## Mapa do conteúdo

- Creating an item provider
- Registering data, files and objects
- Loading representations
- Content types and visibility

## Links do segundo nível

### Criação e consumo

- [init(object:)](https://developer.apple.com/documentation/foundation/nsitemprovider/init(object:)) — cria um provider a partir de `NSItemProviderWriting`. _Apple Developer; expandir sob demanda_
- [init(contentsOf:)](https://developer.apple.com/documentation/foundation/nsitemprovider/init(contentsof:)) — fornece conteúdo respaldado por um arquivo. _Apple Developer; expandir sob demanda_
- [loadObject(ofClass:completionHandler:)](https://developer.apple.com/documentation/foundation/nsitemprovider/loadobject(ofclass:completionhandler:)-6pysm) — carrega assincronamente um objeto da classe solicitada. _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/foundation/nsitemprovider)
- Captura: `2026-07-20T02:07:43Z`
- SHA-256 do payload: `d497a61d31294da0fbf6e42981f82efec2fe5be095e0d1842dbf32c7bb3c0d33`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
