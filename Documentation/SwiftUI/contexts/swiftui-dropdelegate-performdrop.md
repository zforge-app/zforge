---
title: "performDrop(info:)"
source_url: "https://developer.apple.com/documentation/swiftui/dropdelegate/performdrop(info:)"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/DropDelegate/performDrop(info:)"
captured_at: "2026-07-20T02:07:43Z"
source_sha256: "3db5711d2cafc098fb699efb050de5cb7f70d84885882445646c97fa52361934"
source_etag: null
source_last_modified: null
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "Event handling"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# performDrop(info:)

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: método obrigatório de `DropDelegate`
- Módulo: SwiftUI
- Relevância para Zforge: direta para consumir URLs e executar cópia, movimentação ou criação de alias após um drop
- Disponibilidade: macOS 10.15+
- Declaração: `func performDrop(info: DropInfo) -> Bool`

## Síntese

O método informa que o delegate pode solicitar os dados dos item providers presentes em `DropInfo` e deve retornar se aceitou o drop. A incorporação dos dados ao modelo da aplicação é responsabilidade do delegate.

A Apple exige que o carregamento dos `NSItemProvider` seja iniciado dentro do escopo de `performDrop(info:)`. A conclusão pode ocorrer depois, mas transferir a própria chamada de carregamento para outra `Task` ou actor é tarde demais: por segurança, o receptor pode perder acesso ao payload quando o método retorna.

## Implicações práticas

- Chamar `loadObject`, `loadDataRepresentation` ou API equivalente antes de `performDrop(info:)` retornar.
- Somente o tratamento da conclusão e a operação de arquivos subsequente devem ser assíncronos.
- Retornar `true` apenas quando o drop foi aceito e as cargas foram iniciadas.

## Mapa do conteúdo

- Declaration
- Return value
- Discussion

## Links do segundo nível

### Tipos relacionados

- [DropInfo](https://developer.apple.com/documentation/swiftui/dropinfo) — estado atual do drop e seus item providers. _Apple Developer; expandir sob demanda_
- [DropDelegate](https://developer.apple.com/documentation/swiftui/dropdelegate) — protocolo completo de destino de drop. _Apple Developer; expandir sob demanda_
- [NSItemProvider](foundation-nsitemprovider.md) — transporte das URLs e representações de arquivo. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/dropdelegate/performdrop(info:))
- Captura: `2026-07-20T02:07:43Z`
- SHA-256 do payload: `3db5711d2cafc098fb699efb050de5cb7f70d84885882445646c97fa52361934`
- Escopo: uma página; os links absolutos acima ainda não foram percorridos.
