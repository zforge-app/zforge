---
title: "NSTableView.DraggingDestinationFeedbackStyle"
source_url: "https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSTableView/DraggingDestinationFeedbackStyle-swift.enum"
captured_at: "2026-10-03T21:50:10.394140+00:00"
source_sha256: "6242a5f60dba545a480582eb149cda90a3c71cf9c0c398efc9f6160fcf34ddcb"
source_etag: "\"bb6b-659026eabb221\""
source_last_modified: "Fri, 14 Aug 2026 14:14:01 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "AppKit drag and drop"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSTableView.DraggingDestinationFeedbackStyle

## Consulta rápida

- Enumeração AppKit usada por `NSTableView.draggingDestinationFeedbackStyle`.
- Declaração: `enum DraggingDestinationFeedbackStyle`.
- Disponibilidade: macOS; validada contra o SDK macOS 27.0 do Xcode local.

## Síntese

Controla o feedback visual nativo do destino de drag na tabela. `none` desativa esse feedback para permitir desenho próprio; `regular` usa fundo arredondado e marcador de inserção; `sourceList` é o estilo associado às listas de origem; `gap` abre espaço para inserção em tabelas baseadas em views.

## Implicações práticas para Zforge

- Na sidebar, aplicar `.none` somente à tabela que contém a linha evita sobrepor feedback nativo ao desenho SwiftUI próprio.
- Preservar o comportamento das tabelas de conteúdo e os handlers de transferência.
- Esta API não controla o ícone da linha, a seleção atual ou a validade da operação; esses estados precisam de coordenação própria.
- Validar a montagem da tabela real e a transição entre alvos na interface; compilar não comprova o gesto.

## Mapa do conteúdo

- Declaração
- Constants: none, regular, sourceList, gap
- Tipos relacionados de NSTableView

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit) — Apple Developer; expandir sob demanda.
- [BitwiseCopyable](https://developer.apple.com/documentation/swift/bitwisecopyable) — Apple Developer; expandir sob demanda.
- [Equatable](https://developer.apple.com/documentation/swift/equatable) — Apple Developer; expandir sob demanda.
- [Hashable](https://developer.apple.com/documentation/swift/hashable) — Apple Developer; expandir sob demanda.
- [NSInteger](https://developer.apple.com/documentation/objectivec/nsinteger) — Apple Developer; expandir sob demanda.
- [NSTableCellView](https://developer.apple.com/documentation/appkit/nstablecellview) — Apple Developer; expandir sob demanda.
- [NSTableView](https://developer.apple.com/documentation/appkit/nstableview) — Apple Developer; expandir sob demanda.
- [NSTableView.AnimationOptions](https://developer.apple.com/documentation/appkit/nstableview/animationoptions) — Apple Developer; expandir sob demanda.
- [NSTableView.ColumnAutoresizingStyle](https://developer.apple.com/documentation/appkit/nstableview/columnautoresizingstyle-swift.enum) — Apple Developer; expandir sob demanda.
- [NSTableView.DraggingDestinationFeedbackStyle](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum) — Apple Developer; expandir sob demanda.
- [NSTableView.DraggingDestinationFeedbackStyle.gap](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/gap) — Apple Developer; expandir sob demanda.
- [NSTableView.DraggingDestinationFeedbackStyle.none](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/none) — Apple Developer; expandir sob demanda.
- [NSTableView.DraggingDestinationFeedbackStyle.regular](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/regular) — Apple Developer; expandir sob demanda.
- [NSTableView.DraggingDestinationFeedbackStyle.sourceList](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/sourcelist) — Apple Developer; expandir sob demanda.
- [NSTableView.DropOperation](https://developer.apple.com/documentation/appkit/nstableview/dropoperation) — Apple Developer; expandir sob demanda.
- [NSTableView.GridLineStyle](https://developer.apple.com/documentation/appkit/nstableview/gridlinestyle) — Apple Developer; expandir sob demanda.
- [NSTableView.RowActionEdge](https://developer.apple.com/documentation/appkit/nstableview/rowactionedge) — Apple Developer; expandir sob demanda.
- [NSTableView.RowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/rowsizestyle-swift.enum) — Apple Developer; expandir sob demanda.
- [NSTableView.SelectionHighlightStyle](https://developer.apple.com/documentation/appkit/nstableview/selectionhighlightstyle-swift.enum) — Apple Developer; expandir sob demanda.
- [NSTableViewGridNone](https://developer.apple.com/documentation/appkit/nstableviewgridlinestyle/nstableviewgridnone) — Apple Developer; expandir sob demanda.
- [NSView](https://developer.apple.com/documentation/appkit/nsview) — Apple Developer; expandir sob demanda.
- [RawRepresentable](https://developer.apple.com/documentation/swift/rawrepresentable) — Apple Developer; expandir sob demanda.
- [Sendable](https://developer.apple.com/documentation/swift/sendable) — Apple Developer; expandir sob demanda.
- [SendableMetatype](https://developer.apple.com/documentation/swift/sendablemetatype) — Apple Developer; expandir sob demanda.
- [Specifying a Custom Row View in a Nib File](https://developer.apple.com/documentation/appkit/specifying-a-custom-row-view-in-a-nib-file) — Apple Developer; expandir sob demanda.
- [Technologies](https://developer.apple.com/documentation/technologies) — Apple Developer; expandir sob demanda.
- [columnAutoresizingStyle](https://developer.apple.com/documentation/appkit/nstableview/columnautoresizingstyle-swift.property) — Apple Developer; expandir sob demanda.
- [draggingDestinationFeedbackStyle](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.property) — Apple Developer; expandir sob demanda.
- [effectiveRowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/effectiverowsizestyle) — Apple Developer; expandir sob demanda.
- [gridStyleMask](https://developer.apple.com/documentation/appkit/nstableview/gridstylemask) — Apple Developer; expandir sob demanda.
- [init(rawValue:)](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum/init(rawvalue:)) — Apple Developer; expandir sob demanda.
- [rowSizeStyle](https://developer.apple.com/documentation/appkit/nstablecellview/rowsizestyle) — Apple Developer; expandir sob demanda.
- [rowSizeStyle](https://developer.apple.com/documentation/appkit/nstableview/rowsizestyle-swift.property) — Apple Developer; expandir sob demanda.
- [selectionHighlightStyle](https://developer.apple.com/documentation/appkit/nstableview/selectionhighlightstyle-swift.property) — Apple Developer; expandir sob demanda.
- [tableView(_:draggingSession:willBeginAt:forRowIndexes:)](https://developer.apple.com/documentation/appkit/nstableviewdatasource/tableview(_:draggingsession:willbeginat:forrowindexes:)) — Apple Developer; expandir sob demanda.
- [unhideRows(at:withAnimation:)](https://developer.apple.com/documentation/appkit/nstableview/unhiderows(at:withanimation:)) — Apple Developer; expandir sob demanda.

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nstableview/draggingdestinationfeedbackstyle-swift.enum)
- Captura: `2026-10-03T21:50:10.394140+00:00`
- SHA-256: `6242a5f60dba545a480582eb149cda90a3c71cf9c0c398efc9f6160fcf34ddcb`
- Escopo: uma página; links secundários não consultados.
