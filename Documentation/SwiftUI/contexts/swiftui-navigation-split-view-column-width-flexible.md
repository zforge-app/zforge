---
title: "navigationSplitViewColumnWidth(min:ideal:max:)"
source_url: "https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/View/navigationSplitViewColumnWidth(min:ideal:max:)"
captured_at: "2026-07-18T02:53:50Z"
source_sha256: "6aaf33d60f84d9af6927fcbfb752f2fb5c7a1537b0afea85eeddfea23473d3b3"
source_etag: "W/\"ec71fe1bbeefcc0c36babfa35669b393\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# navigationSplitViewColumnWidth(min:ideal:max:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: modificador de `View`
- Módulo: SwiftUI
- Relevância para Zforge: direta; expressa as preferências flexíveis de largura da sidebar do `NavigationSplitView`.
- Disponibilidade: macOS 13.0+; demais plataformas conforme a página oficial.
- Declaração: `nonisolated func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View`

## Síntese

Configura uma largura flexível preferida para a coluna que contém a view. `min`, `ideal` e `max` são preferências do container, e SwiftUI pode usar outra largura quando o ambiente de apresentação não suporta o valor solicitado. O modificador não oferece um binding para a largura efetiva nem define qual painel absorve mudanças no tamanho da janela.

## Implicações práticas

- Manter este modificador para comunicar as métricas da coluna ao layout SwiftUI.
- Não tratá-lo como fonte de estado para a posição atual do divisor.
- Quando o macOS exigir controle sobre a distribuição automática de espaço, complementar a configuração no `NSSplitViewItem` subjacente por uma ponte AppKit deliberada.
- Assinatura e disponibilidade confirmadas também no SDK macOS 26.5 do Xcode local.

## Mapa do conteúdo

- Declaração
- Parâmetros
- Discussão e exemplo
- Plataformas que permitem redimensionamento de colunas

## Links do segundo nível

### Navegação em colunas

- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview) — _Apple Developer; expandir sob demanda_
- [navigationSplitViewColumnWidth(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:)) — _Apple Developer; expandir sob demanda_
- [navigationSplitViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewstyle(_:)) — _Apple Developer; expandir sob demanda_
- [NavigationSplitViewVisibility](https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:))
- Captura: `2026-07-18T02:53:50Z`
- SHA-256 do payload: `6aaf33d60f84d9af6927fcbfb752f2fb5c7a1537b0afea85eeddfea23473d3b3`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
