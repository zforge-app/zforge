---
title: "WKWebpagePreferences.allowsContentJavaScript"
source_url: "https://developer.apple.com/documentation/webkit/wkwebpagepreferences/allowscontentjavascript"
source_identifier: "doc://com.apple.webkit/documentation/WebKit/WKWebpagePreferences/allowsContentJavaScript"
captured_at: "2026-09-27T13:15:08Z"
source_sha256: "6e84b1627ba82794f9dbc6964881f976a4f537712ecbfe12a605d5ce5289ce30"
source_etag: "\"2755-659024a232c5a\""
source_last_modified: "Fri, 14 Aug 2026 14:03:48 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# WKWebpagePreferences.allowsContentJavaScript

## Consulta rápida

- Papel: controla se o JavaScript contido na página pode executar no `WKWebView`.
- Módulo: WebKit.
- Relevância para Zforge: o preview de HTML segue o comportamento estático observado no Finder.
- Disponibilidade: macOS 11.0+, iOS/iPadOS/Mac Catalyst 14.0+ e visionOS 1.0+.
- Declaração: `var allowsContentJavaScript: Bool { get set }`.

## Síntese

O valor padrão é `true`. Quando `false`, o WebKit não executa código JavaScript do conteúdo, incluindo elementos `<script>` inline, URLs `javascript:` e scripts referenciados. Isso permite renderizar HTML e CSS sem executar os scripts fornecidos pelo arquivo.

## Implicações práticas

- Definir `configuration.defaultWebpagePreferences.allowsContentJavaScript = false` antes de criar a view do preview.
- A propriedade restringe scripts da página; não restringe o carregamento de imagens, fontes e folhas de estilo referenciadas pelo documento. O Finder foi observado requisitando uma imagem HTTP referenciada por HTML local no preview da Galeria e no painel Quick Look.
- A assinatura foi conferida com o SDK macOS 27.0 local.

## Mapa do conteúdo

- Declaração e disponibilidade por plataforma.
- Valor padrão e tipos de script afetados quando a propriedade é desativada.

## Links do segundo nível

- [WKWebpagePreferences](https://developer.apple.com/documentation/webkit/wkwebpagepreferences) — _Apple Developer; expandir sob demanda_.
- [WebKit](https://developer.apple.com/documentation/webkit) — _Apple Developer; expandir sob demanda_.
- [Bool](https://developer.apple.com/documentation/swift/bool) — _Apple Developer; expandir sob demanda_.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/webkit/wkwebpagepreferences/allowscontentjavascript).
- Captura: `2026-09-27T13:15:08Z`.
- SHA-256 do payload: `6e84b1627ba82794f9dbc6964881f976a4f537712ecbfe12a605d5ce5289ce30`.
- Escopo: uma página JSON de DocC; os links absolutos acima ainda não foram percorridos.
