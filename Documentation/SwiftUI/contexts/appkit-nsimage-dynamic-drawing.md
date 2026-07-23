---
title: "init(size:flipped:drawingHandler:)"
source_url: "https://developer.apple.com/documentation/appkit/nsimage/init(size:flipped:drawinghandler:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSImage/init(size:flipped:drawingHandler:)"
captured_at: "2026-07-22T23:47:15Z"
source_sha256: "bedbe97d1088e42fbec356508312ac39e036285757dc0a3c46d5f728b23f58a5"
source_etag: "W/\"785f8cebc910c90c93b19d36acbaf1b6\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Drawing and graphics"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# init(size:flipped:drawingHandler:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: inicializador de `NSImage` cuja representação redesenha o conteúdo sob demanda.
- Módulo: AppKit.
- Relevância para Zforge: direta; permite compor o indicador de pasta não vazia sem rasterizá-lo em resolução fixa.
- Disponibilidade: macOS.
- Declaração: `convenience init(size: NSSize, flipped: Bool, drawingHandler: @escaping (NSRect) -> Bool)`

## Síntese

A Apple orienta usar esse inicializador para gerar imagens corretas em qualquer resolução. O `NSImage` mantém um `NSCustomImageRep` com o bloco de desenho e o executa apenas quando a imagem precisa ser desenhada. Se a densidade de pixels ou o espaço de cor do contexto de destino mudar, o AppKit descarta o cache correspondente e executa novamente o bloco; uma transição de tela padrão para Retina é o exemplo explícito da documentação.

O retângulo fornecido ao bloco é medido em pontos. O bloco pode ser executado na thread que desenhar a imagem, portanto o estado capturado precisa admitir esse uso.

## Implicações práticas

- Não usar `lockFocus()` para produzir a composição, pois ele cria uma rasterização dependente da resolução do contexto naquele momento.
- Descrever folha, recorte e nova aplicação da face da pasta dentro do `drawingHandler`, usando o retângulo de destino recebido.
- Manter o `NSImage` retornado pelo `NSWorkspace` como camada base; o AppKit seleciona a representação adequada ao contexto de destino quando o bloco é executado.

## Mapa do conteúdo

- Assinatura, tamanho em pontos e orientação do contexto.
- Execução tardia e requisitos do bloco.
- Cache por densidade de pixels e espaço de cor.
- Uso recomendado com conteúdo vetorial e imagens rasterizadas.

## Links do segundo nível

### Representação e cache

- [NSCustomImageRep](https://developer.apple.com/documentation/appkit/nscustomimagerep) — _Apple Developer; expandir sob demanda_
- [NSImage.cacheMode](https://developer.apple.com/documentation/appkit/nsimage/cachemode-swift.property) — _Apple Developer; expandir sob demanda_
- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsimage/init(size:flipped:drawinghandler:))
- Captura: `2026-07-22T23:47:15Z`
- SHA-256 do payload: `bedbe97d1088e42fbec356508312ac39e036285757dc0a3c46d5f728b23f58a5`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
