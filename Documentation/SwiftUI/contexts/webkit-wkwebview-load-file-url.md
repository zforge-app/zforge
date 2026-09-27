---
title: "loadFileURL(_:allowingReadAccessTo:)"
source_url: "https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)"
source_identifier: "doc://com.apple.webkit/documentation/WebKit/WKWebView/loadFileURL(_:allowingReadAccessTo:)"
captured_at: "2026-09-27T12:39:12Z"
source_sha256: "c99ebd3eafb987060d1ee96ffefd20ab4130c0ee0899cfd6c401353bbaeca8fd"
source_etag: "\"76f4-65b3b266b901c\""
source_last_modified: "Fri, 11 Sep 2026 20:44:26 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# loadFileURL(_:allowingReadAccessTo:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: método de `WKWebView` para carregar conteúdo web de um arquivo local.
- Módulo: WebKit.
- Relevância para Zforge: direta; renderiza o preview de HTML local e seus recursos relativos.
- Disponibilidade: macOS 10.11+, além de iOS 9+, iPadOS 9+, Mac Catalyst 13.1+ e visionOS 1+.
- Declaração: `func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation?`

## Síntese

O primeiro argumento deve ser uma URL de arquivo com conteúdo web. O segundo deve ser uma URL de arquivo ou diretório não vazia que delimita o que o WebKit pode ler. Usar a própria URL do documento impede leitura de outros arquivos; usar um diretório permite carregar recursos relacionados. O método retorna uma navegação para acompanhar o progresso.

## Implicações práticas

- Para um HTML com CSS e imagens relativos, conceder somente a pasta que contém o documento, preservando o acesso necessário aos recursos vizinhos.
- A API delimita a leitura concedida pelo `WKWebView`; a autorização de acesso a arquivos da aplicação continua sendo responsabilidade do Zforge.
- A assinatura consta no SDK macOS 27.0 local e a build Debug assinada do Zforge compilou usando esta chamada em 2026-09-27.

## Mapa do conteúdo

- Declaração e disponibilidade por plataforma.
- Parâmetros do arquivo e do escopo de leitura.
- Valor retornado e nota sobre atribuição da requisição.
- Métodos relacionados de carregamento.

## Links do segundo nível

### Tipos relacionados

- [NSURL](https://developer.apple.com/documentation/foundation/nsurl) — _Apple Developer; expandir sob demanda_.
- [URL](https://developer.apple.com/documentation/foundation/url) — _Apple Developer; expandir sob demanda_.
- [NSURLRequest.Attribution.developer](https://developer.apple.com/documentation/foundation/nsurlrequest/attribution-swift.enum/developer) — _Apple Developer; expandir sob demanda_.
- [Technologies](https://developer.apple.com/documentation/technologies) — _Apple Developer; expandir sob demanda_.
- [WebKit](https://developer.apple.com/documentation/webkit) — _Apple Developer; expandir sob demanda_.
- [WKNavigation](https://developer.apple.com/documentation/webkit/wknavigation) — _Apple Developer; expandir sob demanda_.
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) — _Apple Developer; expandir sob demanda_.

### Carregamento e progresso

- [estimatedProgress](https://developer.apple.com/documentation/webkit/wkwebview/estimatedprogress) — _Apple Developer; expandir sob demanda_.
- [isLoading](https://developer.apple.com/documentation/webkit/wkwebview/isloading) — _Apple Developer; expandir sob demanda_.
- [load(_:) — requisição](https://developer.apple.com/documentation/webkit/wkwebview/load(_:)-4xx8m) — _Apple Developer; expandir sob demanda_.
- [load(_:) — dados](https://developer.apple.com/documentation/webkit/wkwebview/load(_:)-5siv6) — _Apple Developer; expandir sob demanda_.
- [load(_:mimeType:characterEncodingName:baseURL:)](https://developer.apple.com/documentation/webkit/wkwebview/load(_:mimetype:characterencodingname:baseurl:)) — _Apple Developer; expandir sob demanda_.
- [loadFileRequest(_:allowingReadAccessTo:)](https://developer.apple.com/documentation/webkit/wkwebview/loadfilerequest(_:allowingreadaccessto:)) — _Apple Developer; expandir sob demanda_.
- [loadHTMLString(_:baseURL:)](https://developer.apple.com/documentation/webkit/wkwebview/loadhtmlstring(_:baseurl:)) — _Apple Developer; expandir sob demanda_.
- [loadSimulatedRequest(_:response:responseData:)](https://developer.apple.com/documentation/webkit/wkwebview/loadsimulatedrequest(_:response:responsedata:)) — _Apple Developer; expandir sob demanda_.
- [loadSimulatedRequest(_:responseHTML:)](https://developer.apple.com/documentation/webkit/wkwebview/loadsimulatedrequest(_:responsehtml:)) — _Apple Developer; expandir sob demanda_.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/webkit/wkwebview/loadfileurl(_:allowingreadaccessto:)).
- Captura: `2026-09-27T12:39:12Z`.
- SHA-256 do payload: `c99ebd3eafb987060d1ee96ffefd20ab4130c0ee0899cfd6c401353bbaeca8fd`.
- Escopo: uma página JSON de DocC; os links absolutos acima ainda não foram percorridos.
