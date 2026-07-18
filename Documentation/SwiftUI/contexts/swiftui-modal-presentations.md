---
title: "Modal presentations"
source_url: "https://developer.apple.com/documentation/swiftui/modal-presentations"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Modal-presentations"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "3f7a66956ce31bd9b48d6b5d3e8b9b0242d524af93a21dc2eb4a225f8009590f"
source_etag: "W/\"69fa9cf5b7d6438db2189af387c6aac8\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["App structure"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Modal presentations

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Present content in a separate view that offers focused interaction.

To draw attention to an important, narrowly scoped task, you display a modal presentation, like an alert, popover, sheet, or confirmation dialog. In SwiftUI, you create a modal presentation using a view modifier that defines how the presentation looks and the condition under which SwiftUI presents it. SwiftUI detects when the condition changes and makes the presentation for you. Because you provide a Binding to the condition that initiates the presentation, SwiftUI can reset the underlying value when the user dismisses the presentation. For design guidance, see Modality in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Binding](https://developer.apple.com/documentation/swiftui/binding) — A property wrapper type that can read and write a value owned by a source of truth. _(Apple Developer; expandir sob demanda)_
- [Modality](https://developer.apple.com/design/Human-Interface-Guidelines/modality) — Modality is a design technique that presents content in a separate, dedicated mode that prevents interaction with the parent view and requires an explicit… _(Apple Developer; expandir sob demanda)_

### Configuring a dialog

- [DialogSeverity](https://developer.apple.com/documentation/swiftui/dialogseverity) — The severity of an alert or confirmation dialog. _(Apple Developer; expandir sob demanda)_

### Showing a sheet, cover, or popover

- [sheet(isPresented:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)) — Presents a sheet when a binding to a Boolean value that you provide is true. _(Apple Developer; expandir sob demanda)_
- [sheet(item:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:)) — Presents a sheet using the given item as a data source for the sheet’s content. _(Apple Developer; expandir sob demanda)_
- [fullScreenCover(isPresented:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)) — Presents a modal view that covers as much of the screen as possible when binding to a Boolean value you provide is true. _(Apple Developer; expandir sob demanda)_
- [fullScreenCover(item:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/fullscreencover(item:ondismiss:content:)) — Presents a modal view that covers as much of the screen as possible using the binding you provide as a data source for the… _(Apple Developer; expandir sob demanda)_
- [popover(item:attachmentAnchor:arrowEdge:content:)](https://developer.apple.com/documentation/swiftui/view/popover(item:attachmentanchor:arrowedge:content:)) — Presents a popover using the given item as a data source for the popover’s content. _(Apple Developer; expandir sob demanda)_
- [popover(isPresented:attachmentAnchor:arrowEdge:content:)](https://developer.apple.com/documentation/swiftui/view/popover(ispresented:attachmentanchor:arrowedge:content:)) — Presents a popover when a given condition is true. _(Apple Developer; expandir sob demanda)_
- [PopoverAttachmentAnchor](https://developer.apple.com/documentation/swiftui/popoverattachmentanchor) — An attachment anchor for a popover. _(Apple Developer; expandir sob demanda)_

### Adapting a presentation size

- [presentationCompactAdaptation(horizontal:vertical:)](https://developer.apple.com/documentation/swiftui/view/presentationcompactadaptation(horizontal:vertical:)) — Specifies how to adapt a presentation to horizontally and vertically compact size classes. _(Apple Developer; expandir sob demanda)_
- [presentationCompactAdaptation(_:)](https://developer.apple.com/documentation/swiftui/view/presentationcompactadaptation(_:)) — Specifies how to adapt a presentation to compact size classes. _(Apple Developer; expandir sob demanda)_
- [PresentationAdaptation](https://developer.apple.com/documentation/swiftui/presentationadaptation) — Strategies for adapting a presentation to a different size class. _(Apple Developer; expandir sob demanda)_
- [presentationSizing(_:)](https://developer.apple.com/documentation/swiftui/view/presentationsizing(_:)) — Sets the sizing of the containing presentation. _(Apple Developer; expandir sob demanda)_
- [PresentationSizing](https://developer.apple.com/documentation/swiftui/presentationsizing) — A type that defines the size of the presentation content and how the presentation size adjusts to its content’s size changing. _(Apple Developer; expandir sob demanda)_
- [PresentationSizingRoot](https://developer.apple.com/documentation/swiftui/presentationsizingroot) — A proxy to a view provided to the presentation with a defined presentation size. _(Apple Developer; expandir sob demanda)_
- [PresentationSizingContext](https://developer.apple.com/documentation/swiftui/presentationsizingcontext) — Contextual information about a presentation. _(Apple Developer; expandir sob demanda)_

### Configuring a sheet’s height

- [presentationDetents(_:)](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)) — Sets the available detents for the enclosing sheet. _(Apple Developer; expandir sob demanda)_
- [presentationDetents(_:selection:)](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:selection:)) — Sets the available detents for the enclosing sheet, giving you programmatic control of the currently selected detent. _(Apple Developer; expandir sob demanda)_
- [presentationContentInteraction(_:)](https://developer.apple.com/documentation/swiftui/view/presentationcontentinteraction(_:)) — Configures the behavior of swipe gestures on a presentation. _(Apple Developer; expandir sob demanda)_
- [presentationDragIndicator(_:)](https://developer.apple.com/documentation/swiftui/view/presentationdragindicator(_:)) — Sets the visibility of the drag indicator on top of a sheet. _(Apple Developer; expandir sob demanda)_
- [PresentationDetent](https://developer.apple.com/documentation/swiftui/presentationdetent) — A type that represents a height where a sheet naturally rests. _(Apple Developer; expandir sob demanda)_
- [CustomPresentationDetent](https://developer.apple.com/documentation/swiftui/custompresentationdetent) — The definition of a custom detent with a calculated height. _(Apple Developer; expandir sob demanda)_
- [PresentationContentInteraction](https://developer.apple.com/documentation/swiftui/presentationcontentinteraction) — A behavior that you can use to influence how a presentation responds to swipe gestures. _(Apple Developer; expandir sob demanda)_

### Styling a sheet and its background

- [presentationCornerRadius(_:)](https://developer.apple.com/documentation/swiftui/view/presentationcornerradius(_:)) — Requests that the presentation have a specific corner radius. _(Apple Developer; expandir sob demanda)_
- [presentationBackground(_:)](https://developer.apple.com/documentation/swiftui/view/presentationbackground(_:)) — Sets the presentation background of the enclosing sheet using a shape style. _(Apple Developer; expandir sob demanda)_
- [presentationBackground(alignment:content:)](https://developer.apple.com/documentation/swiftui/view/presentationbackground(alignment:content:)) — Sets the presentation background of the enclosing sheet to a custom view. _(Apple Developer; expandir sob demanda)_
- [presentationBackgroundInteraction(_:)](https://developer.apple.com/documentation/swiftui/view/presentationbackgroundinteraction(_:)) — Controls whether people can interact with the view behind a presentation. _(Apple Developer; expandir sob demanda)_
- [PresentationBackgroundInteraction](https://developer.apple.com/documentation/swiftui/presentationbackgroundinteraction) — The kinds of interaction available to views behind a presentation. _(Apple Developer; expandir sob demanda)_

### Presenting an alert

- [AlertScene](https://developer.apple.com/documentation/swiftui/alertscene) — A scene that renders itself as a standalone alert dialog. _(Apple Developer; expandir sob demanda)_
- [alert(_:isPresented:actions:)](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:)) — Presents an alert when a given condition is true, using a localized string resource for the title. _(Apple Developer; expandir sob demanda)_
- [alert(_:isPresented:presenting:actions:)](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:presenting:actions:)) — Presents an alert using the given data to produce the alert’s content and a localized string resource for a title. _(Apple Developer; expandir sob demanda)_
- [alert(_:item:actions:)](https://developer.apple.com/documentation/swiftui/view/alert(_:item:actions:)) — Presents an alert using the given data to produce the alert’s content and a text view as a title. _(Apple Developer; expandir sob demanda)_
- [alert(error:actions:)](https://developer.apple.com/documentation/swiftui/view/alert(error:actions:)) — Presents an alert when an error is present. _(Apple Developer; expandir sob demanda)_
- [alert(isPresented:error:actions:)](https://developer.apple.com/documentation/swiftui/view/alert(ispresented:error:actions:)) — Presents an alert when an error is present. _(Apple Developer; expandir sob demanda)_
- [alert(_:isPresented:actions:message:)](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)) — Presents an alert with a message when a given condition is true, using a localized string resource for a title. _(Apple Developer; expandir sob demanda)_
- [alert(_:isPresented:presenting:actions:message:)](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:presenting:actions:message:)) — Presents an alert with a message using the given data to produce the alert’s content and a localized string resource for a title. _(Apple Developer; expandir sob demanda)_
- [alert(_:item:actions:message:)](https://developer.apple.com/documentation/swiftui/view/alert(_:item:actions:message:)) — Presents an alert with a message using the given data to produce the alert’s content and a localized string key for a title. _(Apple Developer; expandir sob demanda)_
- [alert(error:actions:message:)](https://developer.apple.com/documentation/swiftui/view/alert(error:actions:message:)) — Presents an alert with a message when an error is present. _(Apple Developer; expandir sob demanda)_
- [alert(isPresented:error:actions:message:)](https://developer.apple.com/documentation/swiftui/view/alert(ispresented:error:actions:message:)) — Presents an alert with a message when an error is present. _(Apple Developer; expandir sob demanda)_

### Getting confirmation for an action

- [confirmationDialog(_:isPresented:titleVisibility:actions:)](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:)) — Presents a confirmation dialog when a given condition is true, using a localized string resource for the title. _(Apple Developer; expandir sob demanda)_
- [confirmationDialog(_:isPresented:titleVisibility:presenting:actions:)](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:presenting:actions:)) — Presents a confirmation dialog using data to produce the dialog’s content and a localized string resource for the title. _(Apple Developer; expandir sob demanda)_
- [dismissalConfirmationDialog(_:shouldPresent:actions:)](https://developer.apple.com/documentation/swiftui/view/dismissalconfirmationdialog(_:shouldpresent:actions:)) — Presents a confirmation dialog when a dismiss action has been triggered. _(Apple Developer; expandir sob demanda)_

### Showing a confirmation dialog with a message

- [confirmationDialog(_:isPresented:titleVisibility:actions:message:)](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)) — Presents a confirmation dialog with a message when a given condition is true, using a localized string resource for the title. _(Apple Developer; expandir sob demanda)_
- [confirmationDialog(_:isPresented:titleVisibility:presenting:actions:message:)](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:presenting:actions:message:)) — Presents a confirmation dialog with a message using data to produce the dialog’s content and a localized string resource for the title. _(Apple Developer; expandir sob demanda)_
- [dismissalConfirmationDialog(_:shouldPresent:actions:message:)](https://developer.apple.com/documentation/swiftui/view/dismissalconfirmationdialog(_:shouldpresent:actions:message:)) — Presents a confirmation dialog when a dismiss action has been triggered. _(Apple Developer; expandir sob demanda)_

### Configuring a dialog

- [dialogIcon(_:)](https://developer.apple.com/documentation/swiftui/view/dialogicon(_:)) — Configures the icon used by dialogs within this view. _(Apple Developer; expandir sob demanda)_
- [dialogIcon(_:)](https://developer.apple.com/documentation/swiftui/scene/dialogicon(_:)) — Configures the icon used by alerts. _(Apple Developer; expandir sob demanda)_
- [dialogSeverity(_:)](https://developer.apple.com/documentation/swiftui/view/dialogseverity(_:)) — _Apple Developer; expandir sob demanda_
- [dialogSeverity(_:)](https://developer.apple.com/documentation/swiftui/scene/dialogseverity(_:)) — Sets the severity for alerts. _(Apple Developer; expandir sob demanda)_
- [dialogSuppressionToggle(isSuppressed:)](https://developer.apple.com/documentation/swiftui/view/dialogsuppressiontoggle(issuppressed:)) — Enables user suppression of dialogs and alerts presented within , with a default suppression message on macOS. Unused on other platforms. _(Apple Developer; expandir sob demanda)_
- [dialogSuppressionToggle(isSuppressed:)](https://developer.apple.com/documentation/swiftui/scene/dialogsuppressiontoggle(issuppressed:)) — Enables user suppression of an alert with a custom suppression message. _(Apple Developer; expandir sob demanda)_
- [dialogSuppressionToggle(_:isSuppressed:)](https://developer.apple.com/documentation/swiftui/view/dialogsuppressiontoggle(_:issuppressed:)) — Enables user suppression of dialogs and alerts presented within , with a custom suppression message on macOS. Unused on other platforms. _(Apple Developer; expandir sob demanda)_
- [dialogSuppressionToggle(_:isSuppressed:)](https://developer.apple.com/documentation/swiftui/scene/dialogsuppressiontoggle(_:issuppressed:)) — Enables user suppression of an alert with a custom suppression message. _(Apple Developer; expandir sob demanda)_
- [dialogPreventsAppTermination(_:)](https://developer.apple.com/documentation/swiftui/view/dialogpreventsapptermination(_:)) — Whether the alert or confirmation dialog prevents the app from being quit/terminated by the system or app termination menu item. _(Apple Developer; expandir sob demanda)_

### Exporting to file

- [fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttype:defaultfilename:oncompletion:)) — Presents a system dialog for exporting a document that’s stored in a value type, like a structure, to a file on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:documents:contentType:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:documents:contenttype:oncompletion:)) — Presents a system dialog for exporting a collection of value type documents to files on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:document:contentType:defaultFilename:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttype:defaultfilename:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to export a to a file on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:document:contentTypes:defaultFilename:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttypes:defaultfilename:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to export a to a file on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:documents:contentTypes:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:documents:contenttypes:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to export a collection of objects conforming to to files on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:item:contentTypes:defaultFilename:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:item:contenttypes:defaultfilename:oncompletion:oncancellation:)) — Presents a system dialog allowing the user to export a item to a file on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporter(isPresented:items:contentTypes:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:items:contenttypes:oncompletion:oncancellation:)) — Presents a system dialog allowing the user to export a collection of items to files on disk. _(Apple Developer; expandir sob demanda)_
- [fileExporterFilenameLabel(_:)](https://developer.apple.com/documentation/swiftui/view/fileexporterfilenamelabel(_:)) — On macOS, configures the with a label for the file name field. _(Apple Developer; expandir sob demanda)_

### Importing from file

- [fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:)) — Presents a system dialog for allowing the user to import multiple files. _(Apple Developer; expandir sob demanda)_
- [fileImporter(isPresented:allowedContentTypes:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)) — Presents a system dialog for allowing the user to import an existing file. _(Apple Developer; expandir sob demanda)_
- [fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to import multiple files. _(Apple Developer; expandir sob demanda)_

### Moving a file

- [fileMover(isPresented:file:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/filemover(ispresented:file:oncompletion:)) — Presents a system dialog for allowing the user to move an existing file to a new location. _(Apple Developer; expandir sob demanda)_
- [fileMover(isPresented:files:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/filemover(ispresented:files:oncompletion:)) — Presents a system dialog for allowing the user to move a collection of existing files to a new location. _(Apple Developer; expandir sob demanda)_
- [fileMover(isPresented:file:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/filemover(ispresented:file:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to move an existing file to a new location. _(Apple Developer; expandir sob demanda)_
- [fileMover(isPresented:files:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/filemover(ispresented:files:oncompletion:oncancellation:)) — Presents a system dialog for allowing the user to move a collection of existing files to a new location. _(Apple Developer; expandir sob demanda)_

### Configuring a file dialog

- [fileDialogBrowserOptions(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogbrowseroptions(_:)) — On macOS, configures the , , or to provide a refined URL search experience: include or exclude hidden files, allow searching by tag, etc. _(Apple Developer; expandir sob demanda)_
- [fileDialogConfirmationLabel(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogconfirmationlabel(_:)) — On macOS, configures the , , or with a custom confirmation button label. _(Apple Developer; expandir sob demanda)_
- [fileDialogCustomizationID(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogcustomizationid(_:)) — On macOS, configures the , , or to persist and restore the file dialog configuration. _(Apple Developer; expandir sob demanda)_
- [fileDialogDefaultDirectory(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogdefaultdirectory(_:)) — Configures the , , or to open with the specified default directory. _(Apple Developer; expandir sob demanda)_
- [fileDialogImportsUnresolvedAliases(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogimportsunresolvedaliases(_:)) — On macOS, configures the , , or behavior when a user chooses an alias. _(Apple Developer; expandir sob demanda)_
- [fileDialogMessage(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogmessage(_:)) — On macOS, configures the , , or with a custom message that is presented to the user, similar to a title. _(Apple Developer; expandir sob demanda)_
- [fileDialogURLEnabled(_:)](https://developer.apple.com/documentation/swiftui/view/filedialogurlenabled(_:)) — On macOS, configures the or to conditionally disable presented URLs. _(Apple Developer; expandir sob demanda)_
- [FileDialogBrowserOptions](https://developer.apple.com/documentation/swiftui/filedialogbrowseroptions) — The way that file dialogs present the file system. _(Apple Developer; expandir sob demanda)_

### Presenting an inspector

- [inspector(isPresented:content:)](https://developer.apple.com/documentation/swiftui/view/inspector(ispresented:content:)) — Inserts an inspector at the applied position in the view hierarchy. _(Apple Developer; expandir sob demanda)_
- [inspectorColumnWidth(_:)](https://developer.apple.com/documentation/swiftui/view/inspectorcolumnwidth(_:)) — Sets a fixed, preferred width for the inspector containing this view when presented as a trailing column. _(Apple Developer; expandir sob demanda)_
- [inspectorColumnWidth(min:ideal:max:)](https://developer.apple.com/documentation/swiftui/view/inspectorcolumnwidth(min:ideal:max:)) — Sets a flexible, preferred width for the inspector in a trailing-column presentation. _(Apple Developer; expandir sob demanda)_

### Dismissing a presentation

- [isPresented](https://developer.apple.com/documentation/swiftui/environmentvalues/ispresented) — A Boolean value that indicates whether the view associated with this environment is currently presented. _(Apple Developer; expandir sob demanda)_
- [dismiss](https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss) — An action that dismisses the current presentation. _(Apple Developer; expandir sob demanda)_
- [DismissAction](https://developer.apple.com/documentation/swiftui/dismissaction) — An action that dismisses a presentation. _(Apple Developer; expandir sob demanda)_
- [interactiveDismissDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)) — Conditionally prevents interactive dismissal of presentations like popovers, sheets, and inspectors. _(Apple Developer; expandir sob demanda)_

### Deprecated modal presentations

- [Alert](https://developer.apple.com/documentation/swiftui/alert) — A representation of an alert presentation. _(Apple Developer; expandir sob demanda)_
- [ActionSheet](https://developer.apple.com/documentation/swiftui/actionsheet) — A representation of an action sheet presentation. _(Apple Developer; expandir sob demanda)_

### App structure

- [App organization](swiftui-app-organization.md) — Define the entry point and top-level structure of your app. _(contexto local)_
- [Scenes](swiftui-scenes.md) — Declare the user interface groupings that make up the parts of your app. _(contexto local)_
- [Windows](swiftui-windows.md) — Display user interface content in a window or a collection of windows. _(contexto local)_
- [Immersive spaces](swiftui-immersive-spaces.md) — Display unbounded content in a person’s surroundings. _(contexto local)_
- [Documents](swiftui-documents.md) — Enable people to open and manage documents. _(contexto local)_
- [Navigation](swiftui-navigation.md) — Enable people to move between different parts of your app’s view hierarchy within a scene. _(contexto local)_
- [Toolbars](swiftui-toolbars.md) — Provide immediate access to frequently used commands and controls. _(contexto local)_
- [Search](swiftui-search.md) — Enable people to search for text or other content within your app. _(contexto local)_
- [App extensions](swiftui-app-extensions.md) — Extend your app’s basic functionality to other parts of the system, like by adding a Widget. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/modal-presentations)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `3f7a66956ce31bd9b48d6b5d3e8b9b0242d524af93a21dc2eb4a225f8009590f`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
