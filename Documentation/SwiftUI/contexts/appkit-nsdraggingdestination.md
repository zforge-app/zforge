---
title: "NSDraggingDestination"
source_url: "https://developer.apple.com/documentation/appkit/nsdraggingdestination"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSDraggingDestination"
captured_at: "2026-10-04T21:12:06.603314+00:00"
source_sha256: "1d78a1e7eecfb0a84370b67c1d6656b1bb65e2e595cda46f61c289a61f23e3f0"
source_etag: '"156d0-659026f472fd1"'
source_last_modified: "Fri, 14 Aug 2026 14:14:12 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# NSDraggingDestination

## Síntese e aplicação

Protocolo macOS para destinos de arraste: draggingEntered/draggingUpdated negociam a operação, draggingExited limpa feedback, prepareForDragOperation confirma disponibilidade e performDragOperation aceita o conteúdo. NSView declara estes callbacks; assinaturas conferidas no SDK macOS 27.0. Registrar tipos desejados e ler identidade diretamente de draggingPasteboard. O destino fornece a pasta real da extração e devolve copy/move compatível com a máscara da origem.

No Zforge, o receptor participa do hit testing apenas durante uma transferência virtual ativa; cliques, menus e arraste local conservam os handlers anteriores. A operação assíncrona fica retida após o aceite. Gesto/roteamento exige validação separada dos testes do callback.

## Links do segundo nível

- [AppKit](https://developer.apple.com/documentation/appkit)
- [NSBackgroundExtensionView](https://developer.apple.com/documentation/appkit/nsbackgroundextensionview)
- [NSBox](https://developer.apple.com/documentation/appkit/nsbox)
- [NSBrowser](https://developer.apple.com/documentation/appkit/nsbrowser)
- [NSButton](https://developer.apple.com/documentation/appkit/nsbutton)
- [NSClipView](https://developer.apple.com/documentation/appkit/nsclipview)
- [NSCollectionView](https://developer.apple.com/documentation/appkit/nscollectionview)
- [NSColorWell](https://developer.apple.com/documentation/appkit/nscolorwell)
- [NSComboBox](https://developer.apple.com/documentation/appkit/nscombobox)
- [NSComboButton](https://developer.apple.com/documentation/appkit/nscombobutton)
- [NSControl](https://developer.apple.com/documentation/appkit/nscontrol)
- [NSDatePicker](https://developer.apple.com/documentation/appkit/nsdatepicker)
- [NSDraggingDestination](https://developer.apple.com/documentation/appkit/nsdraggingdestination)
- [concludeDragOperation(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/concludedragoperation(_:))
- [draggingEnded(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/draggingended(_:))
- [draggingEntered(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/draggingentered(_:))
- [draggingExited(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/draggingexited(_:))
- [draggingUpdated(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/draggingupdated(_:))
- [performDragOperation(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/performdragoperation(_:))
- [prepareForDragOperation(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/preparefordragoperation(_:))
- [updateDraggingItemsForDrag(_:)](https://developer.apple.com/documentation/appkit/nsdraggingdestination/updatedraggingitemsfordrag(_:))
- [wantsPeriodicDraggingUpdates()](https://developer.apple.com/documentation/appkit/nsdraggingdestination/wantsperiodicdraggingupdates())
- [NSDraggingInfo](https://developer.apple.com/documentation/appkit/nsdragginginfo)
- [NSForm](https://developer.apple.com/documentation/appkit/nsform)
- [NSFormCell](https://developer.apple.com/documentation/appkit/nsformcell)
- [NSGlassEffectContainerView](https://developer.apple.com/documentation/appkit/nsglasseffectcontainerview)
- [NSGlassEffectView](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [NSGridView](https://developer.apple.com/documentation/appkit/nsgridview)
- [NSImageView](https://developer.apple.com/documentation/appkit/nsimageview)
- [NSLevelIndicator](https://developer.apple.com/documentation/appkit/nslevelindicator)
- [NSMatrix](https://developer.apple.com/documentation/appkit/nsmatrix)
- [NSOpenGLView](https://developer.apple.com/documentation/appkit/nsopenglview)
- [NSOutlineView](https://developer.apple.com/documentation/appkit/nsoutlineview)
- [NSPathControl](https://developer.apple.com/documentation/appkit/nspathcontrol)
- [NSPopUpButton](https://developer.apple.com/documentation/appkit/nspopupbutton)
- [NSPredicateEditor](https://developer.apple.com/documentation/appkit/nspredicateeditor)
- [NSProgressIndicator](https://developer.apple.com/documentation/appkit/nsprogressindicator)
- [NSRuleEditor](https://developer.apple.com/documentation/appkit/nsruleeditor)
- [NSRulerView](https://developer.apple.com/documentation/appkit/nsrulerview)
- [NSScrollView](https://developer.apple.com/documentation/appkit/nsscrollview)
- [NSScroller](https://developer.apple.com/documentation/appkit/nsscroller)
- [NSScrubber](https://developer.apple.com/documentation/appkit/nsscrubber)
- [NSScrubberArrangedView](https://developer.apple.com/documentation/appkit/nsscrubberarrangedview)
- [NSScrubberImageItemView](https://developer.apple.com/documentation/appkit/nsscrubberimageitemview)
- [NSScrubberItemView](https://developer.apple.com/documentation/appkit/nsscrubberitemview)
- [NSScrubberSelectionView](https://developer.apple.com/documentation/appkit/nsscrubberselectionview)
- [NSScrubberTextItemView](https://developer.apple.com/documentation/appkit/nsscrubbertextitemview)
- [NSSearchField](https://developer.apple.com/documentation/appkit/nssearchfield)
- [NSSecureTextField](https://developer.apple.com/documentation/appkit/nssecuretextfield)
- [NSSegmentedControl](https://developer.apple.com/documentation/appkit/nssegmentedcontrol)
- [NSSlider](https://developer.apple.com/documentation/appkit/nsslider)
- [NSSplitView](https://developer.apple.com/documentation/appkit/nssplitview)
- [NSSpringLoadingDestination](https://developer.apple.com/documentation/appkit/nsspringloadingdestination)
- [NSStackView](https://developer.apple.com/documentation/appkit/nsstackview)
- [NSStatusBarButton](https://developer.apple.com/documentation/appkit/nsstatusbarbutton)
- [NSStepper](https://developer.apple.com/documentation/appkit/nsstepper)
- [NSSwitch](https://developer.apple.com/documentation/appkit/nsswitch)
- [NSTabView](https://developer.apple.com/documentation/appkit/nstabview)
- [NSTableCellView](https://developer.apple.com/documentation/appkit/nstablecellview)
- [NSTableHeaderView](https://developer.apple.com/documentation/appkit/nstableheaderview)
- [NSTableRowView](https://developer.apple.com/documentation/appkit/nstablerowview)
- [NSTableView](https://developer.apple.com/documentation/appkit/nstableview)
- [NSText](https://developer.apple.com/documentation/appkit/nstext)
- [NSTextField](https://developer.apple.com/documentation/appkit/nstextfield)
- [NSTextInsertionIndicator](https://developer.apple.com/documentation/appkit/nstextinsertionindicator)
- [NSTextView](https://developer.apple.com/documentation/appkit/nstextview)
- [NSTokenField](https://developer.apple.com/documentation/appkit/nstokenfield)
- [NSView](https://developer.apple.com/documentation/appkit/nsview)
- [NSVisualEffectView](https://developer.apple.com/documentation/appkit/nsvisualeffectview)
- [NSObjectProtocol](https://developer.apple.com/documentation/objectivec/nsobjectprotocol)
- [Technologies](https://developer.apple.com/documentation/technologies)

## Proveniência

[Apple Developer](https://developer.apple.com/documentation/appkit/nsdraggingdestination); captura 2026-10-04T21:12:06.603314+00:00; SHA-256 `1d78a1e7eecfb0a84370b67c1d6656b1bb65e2e595cda46f61c289a61f23e3f0`. Uma página.
