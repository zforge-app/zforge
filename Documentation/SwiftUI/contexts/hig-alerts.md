---
title: "Alerts"
source_url: "https://developer.apple.com/design/human-interface-guidelines/alerts"
source_identifier: "doc://com.apple.HIG/design/Human-Interface-Guidelines/alerts"
captured_at: "2026-07-26T01:54:18Z"
source_sha256: "5a209e6c67818f2e11c213094852d015adeedf8b1faca4e2072faeabd114d3fb"
source_etag: "W/\"0cde5823d83af3fd8f1b6e6ca9b97713\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Human Interface Guidelines"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Alerts

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Human Interface Guidelines
- Módulo: Design
- Relevância para Zforge: direta para alertas de confirmação e ações destrutivas no macOS
- Disponibilidade: orientação multiplataforma, com considerações específicas para macOS
- Declaração: não aplicável

## Síntese

Alertas devem ser reservados para informações críticas e ações que exigem uma decisão imediata. A Apple recomenda confirmar ações destrutivas incomuns e irreversíveis, mas distingue entre uma consequência destrutiva inesperada e uma ação destrutiva escolhida deliberadamente pela pessoa.

Nos botões, o estilo destrutivo deve identificar uma ação destrutiva que não corresponda à intenção original. Quando a pessoa escolheu deliberadamente a ação — o exemplo oficial é esvaziar a Lixeira — a Apple orienta que a confirmação pode evitar o estilo destrutivo e aceitar `Return`, pois a conveniência supera a necessidade de reafirmar o caráter destrutivo. Quando for importante impedir uma confirmação automática antes da leitura, nenhum botão deve ser definido como padrão.

Uma ação destrutiva deve oferecer `Cancel`. No macOS, `Escape` e `Command-Period` são alternativas recomendadas para cancelar o alerta.

## Implicações práticas

- A confirmação continua necessária para uma exclusão permanente por ser incomum e irreversível.
- Uma exclusão permanente iniciada explicitamente por `Option-Command-Delete` é análoga ao exemplo de esvaziar a Lixeira; permitir `Return` para confirmar é compatível com a orientação da Apple.
- Remover a ação padrão também é válido quando o produto deseja forçar uma leitura deliberada, mas não é uma exigência geral para toda ação destrutiva.
- O botão de cancelamento deve permanecer disponível e responder a `Escape`.

## Mapa do conteúdo

- Best practices
- Anatomy
- Content
- Buttons
- Platform considerations
- Resources
- Change log

## Links do segundo nível

### Design

- [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) — _Apple Developer; expandir sob demanda_
- [Presentation](https://developer.apple.com/design/human-interface-guidelines/presentation) — _Apple Developer; expandir sob demanda_
- [Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets) — _Apple Developer; expandir sob demanda_
- [Modality](https://developer.apple.com/design/human-interface-guidelines/modality) — _Apple Developer; expandir sob demanda_

### Developer documentation

- [NSAlert](https://developer.apple.com/documentation/AppKit/NSAlert) — _Apple Developer; expandir sob demanda_
- [alert(_:isPresented:actions:)](https://developer.apple.com/documentation/SwiftUI/View/alert(_:isPresented:actions:)-1bkka) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/design/human-interface-guidelines/alerts)
- Captura: `2026-07-26T01:54:18Z`
- SHA-256 do payload: `5a209e6c67818f2e11c213094852d015adeedf8b1faca4e2072faeabd114d3fb`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
