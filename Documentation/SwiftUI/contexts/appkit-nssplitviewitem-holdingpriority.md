---
title: "holdingPriority"
source_url: "https://developer.apple.com/documentation/appkit/nssplitviewitem/holdingpriority"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSSplitViewItem/holdingPriority"
captured_at: "2026-07-18T02:53:50Z"
source_sha256: "2276dea0b847f56c1cd227abe1725e8068e3923357404412ddde003074fe9892"
source_etag: "W/\"2ee660e156163d2824d880da353925ee\""
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# holdingPriority

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: propriedade de instância de `NSSplitViewItem`
- Módulo: AppKit
- Relevância para Zforge: direta; controla qual painel preserva sua largura durante o redimensionamento de uma split view no macOS.
- Disponibilidade: macOS 10.10+
- Declaração: `var holdingPriority: NSLayoutConstraint.Priority { get set }`

## Síntese

Define a prioridade com que um item mantém sua espessura: largura em uma split view vertical ou altura em uma horizontal. O item com a menor prioridade é o primeiro a receber a variação de tamanho quando a split view cresce ou encolhe. O padrão é `defaultLow`.

## Implicações práticas

- Uma sidebar que deve manter largura absoluta precisa de prioridade maior que o painel de conteúdo que deve absorver a variação da janela.
- A prioridade governa redimensionamento automático; ela não fixa o divisor nem impede que o usuário redimensione manualmente o item.
- No Zforge, aplicar a propriedade ao `NSSplitViewItem` gerenciado pelo `NSSplitViewController`, preservando os limites `minimumThickness` e `maximumThickness`.
- Assinatura e disponibilidade confirmadas também no SDK macOS 26.5 do Xcode local.

## Mapa do conteúdo

- Declaração
- Discussão
- APIs relacionadas de Auto Layout

## Links do segundo nível

### Tipos e propriedades relacionadas

- [NSSplitViewItem](https://developer.apple.com/documentation/appkit/nssplitviewitem) — _Apple Developer; expandir sob demanda_
- [NSLayoutConstraint.Priority](https://developer.apple.com/documentation/appkit/nslayoutconstraint/priority-swift.struct) — _Apple Developer; expandir sob demanda_
- [defaultLow](https://developer.apple.com/documentation/appkit/nslayoutconstraint/priority-swift.struct/defaultlow) — _Apple Developer; expandir sob demanda_
- [automaticallyAdjustsSafeAreaInsets](https://developer.apple.com/documentation/appkit/nssplitviewitem/automaticallyadjustssafeareainsets) — _Apple Developer; expandir sob demanda_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nssplitviewitem/holdingpriority)
- Captura: `2026-07-18T02:53:50Z`
- SHA-256 do payload: `2276dea0b847f56c1cd227abe1725e8068e3923357404412ddde003074fe9892`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
