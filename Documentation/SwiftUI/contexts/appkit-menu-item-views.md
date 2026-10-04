---
title: "Views in Menu Items"
source_url: "https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/ViewsInMenuItems.html"
source_identifier: "https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/ViewsInMenuItems.html"
captured_at: "2026-10-03T17:20:42.555896+00:00"
source_sha256: "ae53df9fa1083c999122091540e08f7e2a2f3ca8ea6f3b7b94f9c17853b85615"
source_etag: null
source_last_modified: "Fri, 30 Jan 2026 23:11:39 GMT"
source_format: "text/html"
depth: 1
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Views in Menu Items

## Síntese

`NSMenuItem.view` permite uma linha customizada em menus AppKit. O menu delega o desenho à view, incluindo título e estado. Eventos de mouse chegam à view; teclado não é encaminhado automaticamente. O tamanho parte do frame da view, e `.width` permite preencher a largura do menu. A view entra/sai da janela ao abrir/fechar o menu; tracking deve acompanhar esse ciclo. Mudanças de tamanho durante tracking não são suportadas. Eventos com botão mantido podem chegar como `mouseDragged`.

## Aplicação no Zforge

A linha rápida de tags usa sete `NSButton`s com círculos, tracking de hover e acessibilidade. A segunda linha permanece um `NSMenuItem` convencional, com símbolo `tag`, preservando navegação de teclado para o editor completo. O clique rápido encerra o tracking antes de alterar metadados. As APIs foram verificadas no SDK macOS 27.0; não usam APIs privadas do Finder.

## Links secundários

- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/index.html
- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/RevisionHistory.html
- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MenuList/Articles/DisplayContextMenu.html
- https://developer.apple.com/library/archive/Resources/1282/CSS/screen.css
- https://developer.apple.com/library/archive/Resources/1282/CSS/feedback.css
- https://developer.apple.com/documentation/appkit/nsmenuitem/1514835-view
- https://developer.apple.com/documentation/appkit/nsview/1483360-needsdisplay
- https://developer.apple.com/documentation/appkit/nsview/1483487-display
- https://developer.apple.com/documentation/appkit/nsview/1483329-viewdidmovetowindow
- http://www.apple.com/legal/internet-services/terms/site.html
- http://www.apple.com/privacy/
- https://developer.apple.com/bugreporter/
- http://www.apple.com/legal/policies/ideas.html

## Proveniência

Página Apple arquivada, atualizada em 2014-07-15, capturada pelo URL acima; hash do HTML integral no front matter. As regras ainda foram conferidas na compilação com o SDK atual.

Nota do SDK macOS 27.0 (`NSMenuItem.h`): imagens de menu podem ser ocultadas por padrão. O item Edit Tags define `preferredImageVisibility = .visible`, com disponibilidade protegida para macOS 27, para manter o símbolo solicitado; macOS 26 mantém o comportamento anterior.
