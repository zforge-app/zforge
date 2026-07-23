---
title: "icon(forFile:)"
source_url: "https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfile:)"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSWorkspace/icon(forFile:)"
captured_at: "2026-07-22T23:47:15Z"
source_sha256: "20e1ae982edde88c9efefb3288a5a7dedc4360f692cf32fde6d9c03279e299f4"
source_etag: "W/\"794ad20386b359b938cbbf2b7e42a2cf\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# icon(forFile:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: método de `NSWorkspace` que retorna o ícone associado a um caminho existente.
- Módulo: AppKit.
- Relevância para Zforge: direta; é a fonte pública para ícones de arquivos e diretórios locais.
- Disponibilidade: macOS.
- Declaração: `func icon(forFile fullPath: String) -> NSImage`

## Síntese

O método recebe somente o caminho completo e retorna o `NSImage` associado ao arquivo. A imagem retornada começa com tamanho lógico de 32 por 32 e a chamada pode ser feita com segurança em qualquer thread. A API não oferece opção, parâmetro ou tipo público para solicitar variantes visuais baseadas no conteúdo de um diretório, como o estado de pasta cheia usado internamente pelo Finder.

## Implicações práticas

- Usar `NSWorkspace.shared.icon(forFile:)` como base preserva o ícone, customizações e tipo reconhecidos pelo sistema.
- O estado visual de pasta não vazia não pode ser solicitado por esta API; `icon(for:)` retorna o ícone genérico de um `UTType`, não uma variante baseada no conteúdo do caminho.
- Qualquer indicador adicional do Zforge deve preservar as representações de alta resolução do `NSImage` original e não substituir o ícone do arquivo no sistema com `setIcon`.

## Mapa do conteúdo

- Declaração e parâmetro do caminho completo.
- Valor retornado.
- Tamanho inicial e segurança entre threads.

## Links do segundo nível

### Ícones e imagens

- [NSImage](https://developer.apple.com/documentation/appkit/nsimage) — _Apple Developer; expandir sob demanda_
- [icon(for:)](https://developer.apple.com/documentation/appkit/nsworkspace/icon(for:)) — _Apple Developer; expandir sob demanda_
- [icon(forFiles:)](https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfiles:)) — _Apple Developer; expandir sob demanda_
- [setIcon(_:forFile:options:)](https://developer.apple.com/documentation/appkit/nsworkspace/seticon(_:forfile:options:)) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nsworkspace/icon(forfile:))
- Captura: `2026-07-22T23:47:15Z`
- SHA-256 do payload: `20e1ae982edde88c9efefb3288a5a7dedc4360f692cf32fde6d9c03279e299f4`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
