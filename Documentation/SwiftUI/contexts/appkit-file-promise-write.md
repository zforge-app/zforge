---
title: "filePromiseProvider(_:writePromiseTo:completionHandler:)"
source_url: "https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:writepromiseto:completionhandler:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSFilePromiseProviderDelegate/filePromiseProvider(_:writePromiseTo:completionHandler:)"
captured_at: "2026-10-04T10:57:06.062330+00:00"
source_sha256: "c5770fc257a31b7d790669c9af7bec260632eaf52264f5df47a337839bd130d6"
source_etag: "\"5da7-659026dc59565\""
source_last_modified: "Fri, 14 Aug 2026 14:13:46 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# filePromiseProvider(_:writePromiseTo:completionHandler:)

## Consulta rápida

- Módulo: AppKit; API nativa de arraste do macOS.
- Disponibilidade: macOS 10.12+
- Declaração: `nonisolated   func   filePromiseProvider ( _   filePromiseProvider :  NSFilePromiseProvider ,  writePromiseTo   url :  URL ,  completionHandler :  @escaping  @Sendable  ((any  Error )?) ->  Void ) nonisolated   func   filePromiseProvider ( _   filePromiseProvider :  NSFilePromiseProvider ,  writePromiseTo   url :  URL )  async   throws`

## Síntese

O delegate de file promise recebe a URL exata em que deve publicar o conteúdo quando o sistema solicita cumprir a promessa. A escrita roda na operation queue indicada pelo delegate; a conclusão deve ser chamada após a escrita. A coordenação de arquivos deve acompanhar a publicação.

## Implicações práticas no Zforge

A origem virtual usa file promises e determina a operação permitida. A regra de produto exige cópia por padrão e movimentação com Option; ignorar a tradução automática de modificadores do AppKit e aplicar a regra explicitamente na origem e no destino interno. Promises escrevem somente na URL fornecida e removem entradas do archive apenas após a publicação bem-sucedida. O SDK macOS 27.0 declara a escrita de promises nonisolated e permite escolher a main operation queue; manter a coordenação de UI no MainActor.

## Mapa do conteúdo

- Declaração, operações/modificadores ou escrita de promises.
- Referências de tipos e métodos relacionados.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [Error](https://developer.apple.com/documentation/swift/error) — Apple Developer; expandir sob demanda.
- [NSError](https://developer.apple.com/documentation/foundation/nserror) — Apple Developer; expandir sob demanda.
- [NSFileCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator) — Apple Developer; expandir sob demanda.
- [NSFilePromiseProviderDelegate](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate) — Apple Developer; expandir sob demanda.
- [NSFilePromiseProvider](appkit-nsfile-promise-provider.md) — Apple Developer; expandir sob demanda.
- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — Apple Developer; expandir sob demanda.
- [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [URL](https://developer.apple.com/documentation/foundation/url) — Apple Developer; expandir sob demanda.
- [Void](https://developer.apple.com/documentation/swift/void) — Apple Developer; expandir sob demanda.
- [filePromiseProvider(_:fileNameForType:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:filenamefortype:)) — Apple Developer; expandir sob demanda.
- [operationQueue(for:)](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/operationqueue(for:)) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsfilepromiseproviderdelegate/filepromiseprovider(_:writepromiseto:completionhandler:)).
- Captura: `2026-10-04T10:57:06.062330+00:00`; SHA-256: `c5770fc257a31b7d790669c9af7bec260632eaf52264f5df47a337839bd130d6`.
- Escopo: uma página; links secundários não percorridos.

### Coordenação no Zforge

A publicação de uma promessa não espera o callback final da origem. Receptores podem solicitar arquivos em sequência; completar cada escrita antes de atender a próxima. A remoção das origens espera todas as publicações e a operação final de movimento. O token adicional é dado imediato, com opções de escrita vazias; o conteúdo mantém a política de promessa do AppKit.

Movimentos externos confirmam a alteração do original antes da primeira publicação. Cancelar rejeita todas as promises sem gravar. Escritas são serializadas; a conclusão de cada uma não aguarda ended, mas a remoção exige confirmação, aceitação final de movimento e sucesso de todas. Testes congelam também cancelamento após cumprir promises e falha parcial.

A URL da promise pode carregar autorização de sandbox apenas para o arquivo final. Criar sibling staging ao lado dela falhou com NSCocoaErrorDomain 513 na integração real com Finder. Extrair/validar no staging do app e publicar na URL autorizada; não inferir acesso à pasta pai. Destinos internos já autorizados mantêm publicação por staging/rename vizinho.
