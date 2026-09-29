---
title: "accessoryView"
source_url: "https://developer.apple.com/documentation/appkit/nssavepanel/accessoryview"
source_identifier: "doc://com.apple.appkit/documentation/AppKit/NSSavePanel/accessoryView"
captured_at: "2026-09-28T23:25:02+00:00"
source_sha256: "06b8eeadd21e07b6a3ea21e01b29d3da2c5a895e01f32448e3fd53777275dd87"
source_etag: "\"45f5-659026d729d20\""
source_last_modified: "Fri, 14 Aug 2026 14:13:41 GMT"
source_format: "application/json"
depth: 2
categories: ["On-demand expansion", "AppKit integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# accessoryView

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: Instance Property
- Módulo: AppKit
- Relevância para Zforge: Direct. Use this context for SwiftUI decisions that must remain native to macOS.
- Disponibilidade: macOS
- Declaração: `var accessoryView: NSView? { get set }`

## Síntese

**Resumo oficial:** The custom accessory view for the current app.

You can customize the panel by adding a custom view. The custom object you add appears just above the OK and Cancel buttons at the bottom of the panel. The object automatically resizes itself to accommodate . Use this property to change the accessory view as needed. If is , the Save panel removes the current accessory view. The panel relinquishes ownership of the accessory view after the panel is closed. If you want to reuse the accessory view, don’t rely on the panel to hold onto the accessory view until the next time you use it; instead, maintain your own strong reference to the view.

## Implicações práticas

- O acessório customizado aparece acima dos botões OK/Cancel e o NSSavePanel ajusta sua altura para comportá-lo.
- Inferência a partir da API pública documentada: `accessoryView` acrescenta conteúdo ao rodapé e não oferece reposicionamento dos controles internos de nome, Tags e Where. A reorganização desses campos não deve ser tratada como viável dentro do painel nativo sem um protótipo próprio.

## Mapa do conteúdo

- Discussion

## Links do segundo nível

### Configuring the Panel’s Appearance

- [title](https://developer.apple.com/documentation/appkit/nssavepanel/title) — The title of the panel. _(Apple Developer; expandir sob demanda)_
- [prompt](https://developer.apple.com/documentation/appkit/nssavepanel/prompt) — The text to display in the default button. _(Apple Developer; expandir sob demanda)_
- [message](https://developer.apple.com/documentation/appkit/nssavepanel/message) — The message text displayed in the panel. _(Apple Developer; expandir sob demanda)_
- [nameFieldLabel](https://developer.apple.com/documentation/appkit/nssavepanel/namefieldlabel) — The label text displayed in front of the filename text field. _(Apple Developer; expandir sob demanda)_
- [nameFieldStringValue](https://developer.apple.com/documentation/appkit/nssavepanel/namefieldstringvalue) — The user-editable filename currently shown in the name field. _(Apple Developer; expandir sob demanda)_
- [directoryURL](https://developer.apple.com/documentation/appkit/nssavepanel/directoryurl) — The current directory shown in the panel. _(Apple Developer; expandir sob demanda)_
- [showsTagField](https://developer.apple.com/documentation/appkit/nssavepanel/showstagfield) — A Boolean value that indicates whether the panel displays the Tags field. _(Apple Developer; expandir sob demanda)_
- [tagNames](https://developer.apple.com/documentation/appkit/nssavepanel/tagnames) — The tag names that you want to include on a saved file. _(Apple Developer; expandir sob demanda)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/appkit/nssavepanel/accessoryview)
- Captura: `2026-09-28T23:25:02+00:00`
- SHA-256 do payload: `06b8eeadd21e07b6a3ea21e01b29d3da2c5a895e01f32448e3fd53777275dd87`
- Escopo: expansão sob demanda de uma página; links absolutos acima ainda não foram percorridos.
