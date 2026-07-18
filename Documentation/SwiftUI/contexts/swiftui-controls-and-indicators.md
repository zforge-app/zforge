---
title: "Controls and indicators"
source_url: "https://developer.apple.com/documentation/swiftui/controls-and-indicators"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Controls-and-indicators"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "91d3ef97276213ba74e2a3eac05a5e0d545f1dac8f8472df83f96519149b0119"
source_etag: "W/\"c3af4da0639efdb187b55d94c58c6db9\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Controls and indicators

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Display values and get user selections.

SwiftUI provides controls that enable user interaction specific to each platform and context. For example, people can initiate events with buttons and links, or choose among a set of discrete values with different kinds of pickers. You can also display information to the user with indicators like progress views and gauges. Use these built-in controls and indicators when composing custom views, and style them to match the needs of your app’s user interface. For design guidance, see Menus and actions, Selection and input, and Status in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Menus and actions](https://developer.apple.com/design/Human-Interface-Guidelines/menus-and-actions) — _Apple Developer; expandir sob demanda_
- [Selection and input](https://developer.apple.com/design/Human-Interface-Guidelines/selection-and-input) — _Apple Developer; expandir sob demanda_
- [Status](https://developer.apple.com/design/Human-Interface-Guidelines/status) — _Apple Developer; expandir sob demanda_

### Creating buttons

- [Button](https://developer.apple.com/documentation/swiftui/button) — A control that initiates an action. _(Apple Developer; expandir sob demanda)_
- [buttonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/buttonstyle(_:)) — Sets the style for buttons within this view to a button style with a custom appearance and standard interaction behavior. _(Apple Developer; expandir sob demanda)_
- [buttonBorderShape(_:)](https://developer.apple.com/documentation/swiftui/view/buttonbordershape(_:)) — Sets the border shape for buttons in this view. _(Apple Developer; expandir sob demanda)_
- [ButtonBorderShape](https://developer.apple.com/documentation/swiftui/buttonbordershape) — A shape used to draw a button’s border. _(Apple Developer; expandir sob demanda)_
- [buttonRepeatBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/buttonrepeatbehavior(_:)) — Sets whether buttons in this view should repeatedly trigger their actions on prolonged interactions. _(Apple Developer; expandir sob demanda)_
- [ButtonRepeatBehavior](https://developer.apple.com/documentation/swiftui/buttonrepeatbehavior) — The options for controlling the repeatability of button actions. _(Apple Developer; expandir sob demanda)_
- [buttonRepeatBehavior](https://developer.apple.com/documentation/swiftui/environmentvalues/buttonrepeatbehavior) — Whether buttons with this associated environment should repeatedly trigger their actions on prolonged interactions. _(Apple Developer; expandir sob demanda)_
- [buttonSizing(_:)](https://developer.apple.com/documentation/swiftui/view/buttonsizing(_:)) — The preferred sizing behavior of buttons in the view hierarchy. _(Apple Developer; expandir sob demanda)_
- [ButtonSizing](https://developer.apple.com/documentation/swiftui/buttonsizing) — The sizing behavior of s and other button-like controls. _(Apple Developer; expandir sob demanda)_
- [ButtonRole](https://developer.apple.com/documentation/swiftui/buttonrole) — A value that describes the purpose of a button. _(Apple Developer; expandir sob demanda)_

### Creating special-purpose buttons

- [EditButton](https://developer.apple.com/documentation/swiftui/editbutton) — A button that toggles the edit mode environment value. _(Apple Developer; expandir sob demanda)_
- [PasteButton](https://developer.apple.com/documentation/swiftui/pastebutton) — A system button that reads items from the pasteboard and delivers it to a closure. _(Apple Developer; expandir sob demanda)_
- [RenameButton](https://developer.apple.com/documentation/swiftui/renamebutton) — A button that triggers a standard rename action. _(Apple Developer; expandir sob demanda)_

### Linking to other content

- [Link](https://developer.apple.com/documentation/swiftui/link) — A control for navigating to a URL. _(Apple Developer; expandir sob demanda)_
- [ShareLink](https://developer.apple.com/documentation/swiftui/sharelink) — A view that controls a sharing presentation. _(Apple Developer; expandir sob demanda)_
- [SharePreview](https://developer.apple.com/documentation/swiftui/sharepreview) — A representation of a type to display in a share preview. _(Apple Developer; expandir sob demanda)_
- [TextFieldLink](https://developer.apple.com/documentation/swiftui/textfieldlink) — A control that requests text input from the user when pressed. _(Apple Developer; expandir sob demanda)_
- [HelpLink](https://developer.apple.com/documentation/swiftui/helplink) — A button with a standard appearance that opens app-specific help documentation. _(Apple Developer; expandir sob demanda)_

### Getting numeric inputs

- [Slider](https://developer.apple.com/documentation/swiftui/slider) — A control for selecting a value from a bounded linear range of values. _(Apple Developer; expandir sob demanda)_
- [Stepper](https://developer.apple.com/documentation/swiftui/stepper) — A control that performs increment and decrement actions. _(Apple Developer; expandir sob demanda)_
- [Toggle](https://developer.apple.com/documentation/swiftui/toggle) — A control that toggles between on and off states. _(Apple Developer; expandir sob demanda)_
- [toggleStyle(_:)](https://developer.apple.com/documentation/swiftui/view/togglestyle(_:)) — Sets the style for toggles in a view hierarchy. _(Apple Developer; expandir sob demanda)_

### Choosing from a set of options

- [Picker](https://developer.apple.com/documentation/swiftui/picker) — A control for selecting from a set of mutually exclusive values. _(Apple Developer; expandir sob demanda)_
- [pickerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/pickerstyle(_:)) — Sets the style for pickers within this view. _(Apple Developer; expandir sob demanda)_
- [horizontalRadioGroupLayout()](https://developer.apple.com/documentation/swiftui/view/horizontalradiogrouplayout()) — Sets the style for radio group style pickers within this view to be horizontally positioned with the radio buttons inside the layout. _(Apple Developer; expandir sob demanda)_
- [defaultWheelPickerItemHeight(_:)](https://developer.apple.com/documentation/swiftui/view/defaultwheelpickeritemheight(_:)) — Sets the default wheel-style picker item height. _(Apple Developer; expandir sob demanda)_
- [defaultWheelPickerItemHeight](https://developer.apple.com/documentation/swiftui/environmentvalues/defaultwheelpickeritemheight) — The default height of an item in a wheel-style picker, such as a date picker. _(Apple Developer; expandir sob demanda)_
- [paletteSelectionEffect(_:)](https://developer.apple.com/documentation/swiftui/view/paletteselectioneffect(_:)) — Specifies the selection effect to apply to a palette item. _(Apple Developer; expandir sob demanda)_
- [PaletteSelectionEffect](https://developer.apple.com/documentation/swiftui/paletteselectioneffect) — The selection effect to apply to a palette item. _(Apple Developer; expandir sob demanda)_

### Choosing dates

- [DatePicker](https://developer.apple.com/documentation/swiftui/datepicker) — A control for selecting an absolute date. _(Apple Developer; expandir sob demanda)_
- [datePickerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/datepickerstyle(_:)) — Sets the style for date pickers within this view. _(Apple Developer; expandir sob demanda)_
- [MultiDatePicker](https://developer.apple.com/documentation/swiftui/multidatepicker) — A control for picking multiple dates. _(Apple Developer; expandir sob demanda)_
- [calendar](https://developer.apple.com/documentation/swiftui/environmentvalues/calendar) — The current calendar that views should use when handling dates. _(Apple Developer; expandir sob demanda)_
- [timeZone](https://developer.apple.com/documentation/swiftui/environmentvalues/timezone) — The current time zone that views should use when handling dates. _(Apple Developer; expandir sob demanda)_

### Choosing a color

- [ColorPicker](https://developer.apple.com/documentation/swiftui/colorpicker) — A control used to select a color from the system color picker UI. _(Apple Developer; expandir sob demanda)_

### Indicating a value

- [Gauge](https://developer.apple.com/documentation/swiftui/gauge) — A view that shows a value within a range. _(Apple Developer; expandir sob demanda)_
- [gaugeStyle(_:)](https://developer.apple.com/documentation/swiftui/view/gaugestyle(_:)) — Sets the style for gauges within this view. _(Apple Developer; expandir sob demanda)_
- [ProgressView](https://developer.apple.com/documentation/swiftui/progressview) — A view that shows the progress toward completion of a task. _(Apple Developer; expandir sob demanda)_
- [progressViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/progressviewstyle(_:)) — Sets the style for progress views in this view. _(Apple Developer; expandir sob demanda)_
- [DefaultDateProgressLabel](https://developer.apple.com/documentation/swiftui/defaultdateprogresslabel) — The default type of the current value label when used by a date-relative progress view. _(Apple Developer; expandir sob demanda)_
- [DefaultButtonLabel](https://developer.apple.com/documentation/swiftui/defaultbuttonlabel) — The default label to use for a button. _(Apple Developer; expandir sob demanda)_

### Indicating missing content

- [ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview) — An interface, consisting of a label and additional content, that you display when the content of your app is unavailable to users. _(Apple Developer; expandir sob demanda)_

### Providing haptic feedback

- [sensoryFeedback(_:trigger:)](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:)) — Plays the specified when the provided value changes. _(Apple Developer; expandir sob demanda)_
- [sensoryFeedback(trigger:_:)](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(trigger:_:)) — Plays feedback when returned from the closure after the provided value changes. _(Apple Developer; expandir sob demanda)_
- [sensoryFeedback(_:trigger:condition:)](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:condition:)) — Plays the specified when the provided value changes and the closure returns . _(Apple Developer; expandir sob demanda)_
- [SensoryFeedback](https://developer.apple.com/documentation/swiftui/sensoryfeedback) — Represents a type of haptic and/or audio feedback that can be played. _(Apple Developer; expandir sob demanda)_

### Sizing controls

- [controlSize(_:)](https://developer.apple.com/documentation/swiftui/view/controlsize(_:)) — Sets the size for controls within this view. _(Apple Developer; expandir sob demanda)_
- [controlSize](https://developer.apple.com/documentation/swiftui/environmentvalues/controlsize) — The size to apply to controls within a view. _(Apple Developer; expandir sob demanda)_
- [ControlSize](https://developer.apple.com/documentation/swiftui/controlsize) — The size classes, like regular or small, that you can apply to controls within a view. _(Apple Developer; expandir sob demanda)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(contexto local)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(contexto local)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(contexto local)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(contexto local)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(contexto local)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(contexto local)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(contexto local)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(contexto local)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/controls-and-indicators)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `91d3ef97276213ba74e2a3eac05a5e0d545f1dac8f8472df83f96519149b0119`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
