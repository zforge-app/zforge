---
title: "Creating your app icon using Icon Composer"
source_url: "https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer"
source_identifier: "doc://com.apple.Xcode/documentation/Xcode/creating-your-app-icon-using-icon-composer"
captured_at: "2026-10-02T01:13:11+00:00"
source_sha256: "3458352b0e40d4488d5e31d413d47ece2b150bcddf4ab9b406f34865d73f728e"
source_etag: "\"d9ba-65b3a4494b5cd\""
source_last_modified: "Fri, 11 Sep 2026 19:41:17 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Xcode"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Creating your app icon using Icon Composer

Contexto normalizado da orientação oficial do Xcode para arquivos `.icon` produzidos pelo Icon Composer.

## Consulta rápida

- Papel: artigo de integração e criação de ícones em camadas.
- Módulo: Xcode / Icon Composer.
- Relevância para Zforge: direta, porque o alvo macOS passa a usar um arquivo `.icon` exportado pelo usuário.
- Disponibilidade: Xcode com suporte a Icon Composer; a página descreve iOS, iPadOS, macOS, watchOS e versões anteriores com arte derivada pelo Xcode.
- Declaração: não há API de código; a integração usa o arquivo `.icon` no projeto e o nome do ícone no alvo.

## Síntese

Um arquivo do Icon Composer reúne camadas e variantes de aparência. Para usá-lo, adicioná-lo ao projeto e selecionar como App Icon do alvo o nome do arquivo sem a extensão. O Xcode compila as versões apropriadas para as plataformas, aparências e tamanhos. No Xcode atual, esse arquivo substitui o catálogo de ícone anterior como fonte do ícone principal. A Apple recomenda exportar camadas com nomes ordenados, remover efeitos que o Icon Composer aplica e não exportar uma máscara de recorte.

## Implicações práticas

- `Zforge/zforge_icon.icon` deve pertencer ao alvo e `ASSETCATALOG_COMPILER_APPICON_NAME` deve ser `zforge_icon` nas configurações usadas.
- O app não deve reatribuir o ícone antigo em tempo de execução, pois isso substitui o ícone fornecido pelo bundle.
- Conferir o bundle compilado (`zforge_icon.icns`, `Assets.car` e `CFBundleIconName`) e a aparência visual em Finder/Dock. Uma build confirma compilação, não todas as variantes visuais.

## Mapa do conteúdo

- Preparação e exportação das camadas.
- Criação do documento no Icon Composer e personalização das aparências.
- Inclusão do arquivo `.icon` no projeto e seleção do nome no alvo.
- Testes em dispositivos e aparências.

## Links do segundo nível

### Xcode e design

- [Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) — _Apple Developer; expandir sob demanda_.
- [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) — _Apple Developer; expandir sob demanda_.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) — _Apple Developer; expandir sob demanda_.
- [Apple Design Resources](https://developer.apple.com/design/resources/) — _Apple Developer; expandir sob demanda_.
- [Icon Composer](https://developer.apple.com/icon-composer) — _Apple Developer; expandir sob demanda_.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
- Captura: `2026-10-02T01:13:11+00:00`.
- SHA-256 do payload: `3458352b0e40d4488d5e31d413d47ece2b150bcddf4ab9b406f34865d73f728e`.
- Escopo: uma página em JSON; os links absolutos acima ainda não foram percorridos.
