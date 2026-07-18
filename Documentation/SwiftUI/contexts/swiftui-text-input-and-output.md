---
title: "Text input and output"
source_url: "https://developer.apple.com/documentation/swiftui/text-input-and-output"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Text-input-and-output"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "688f394d0c1edc9a760ef48afcd3612dbfda24ccb616f10514c4dfaa0baf24da"
source_etag: "W/\"cab8af76d3da8034927c48eccd29b8fe\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Text input and output

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Display formatted text and get text input from the user.

To display read-only text, or read-only text paired with an image, use the built-in Text or Label views, respectively. When you need to collect text input from the user, use an appropriate text input view, like TextField or TextEditor. You add view modifiers to control the text’s font, selectability, alignment, layout direction, and so on. These modifiers also affect other views that display text, like the labels on controls, even if you don’t define an explicit Text view. For design guidance, see Typography in the Human Interface Guidelines.

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [Text](https://developer.apple.com/documentation/swiftui/text) — A view that displays one or more lines of read-only text. _(Apple Developer; expandir sob demanda)_
- [Label](https://developer.apple.com/documentation/swiftui/label) — A standard label for user interface items, consisting of an icon with a title. _(Apple Developer; expandir sob demanda)_
- [TextField](https://developer.apple.com/documentation/swiftui/textfield) — A control that displays an editable text interface. _(Apple Developer; expandir sob demanda)_
- [TextEditor](https://developer.apple.com/documentation/swiftui/texteditor) — A view that can display and edit long-form text. _(Apple Developer; expandir sob demanda)_
- [Typography](https://developer.apple.com/design/Human-Interface-Guidelines/typography) — Your typographic choices can help you display legible text, convey an information hierarchy, communicate important content, and express your brand or style. _(Apple Developer; expandir sob demanda)_

### Displaying text

- [labelStyle(_:)](https://developer.apple.com/documentation/swiftui/view/labelstyle(_:)) — Sets the style for labels within this view. _(Apple Developer; expandir sob demanda)_

### Getting text input

- [Building rich SwiftUI text experiences](https://developer.apple.com/documentation/swiftui/building-rich-swiftui-text-experiences) — Build an editor for formatted text using SwiftUI text editor views and attributed strings. _(Apple Developer; expandir sob demanda)_
- [textFieldStyle(_:)](https://developer.apple.com/documentation/swiftui/view/textfieldstyle(_:)) — Sets the style for text fields within this view. _(Apple Developer; expandir sob demanda)_
- [SecureField](https://developer.apple.com/documentation/swiftui/securefield) — A control into which people securely enter private text. _(Apple Developer; expandir sob demanda)_

### Selecting text

- [textSelection(_:)](https://developer.apple.com/documentation/swiftui/view/textselection(_:)) — Controls whether people can select text within this view. _(Apple Developer; expandir sob demanda)_
- [TextSelectability](https://developer.apple.com/documentation/swiftui/textselectability) — A type that describes the ability to select text. _(Apple Developer; expandir sob demanda)_
- [TextSelection](https://developer.apple.com/documentation/swiftui/textselection) — Represents a selection of text. _(Apple Developer; expandir sob demanda)_
- [textSelectionAffinity(_:)](https://developer.apple.com/documentation/swiftui/view/textselectionaffinity(_:)) — Sets the direction of a selection or cursor relative to a text character. _(Apple Developer; expandir sob demanda)_
- [textSelectionAffinity](https://developer.apple.com/documentation/swiftui/environmentvalues/textselectionaffinity) — A representation of the direction or association of a selection or cursor relative to a text character. This concept becomes much more prominent when… _(Apple Developer; expandir sob demanda)_
- [TextSelectionAffinity](https://developer.apple.com/documentation/swiftui/textselectionaffinity) — A representation of the direction or association of a selection or cursor relative to a text character. This concept becomes much more prominent when… _(Apple Developer; expandir sob demanda)_
- [AttributedTextSelection](https://developer.apple.com/documentation/swiftui/attributedtextselection) — Represents a selection of attributed text. _(Apple Developer; expandir sob demanda)_

### Setting a font

- [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text) — Add and use a font in your app that scales with Dynamic Type. _(Apple Developer; expandir sob demanda)_
- [font(_:)](https://developer.apple.com/documentation/swiftui/view/font(_:)) — Sets the default font for text in this view. _(Apple Developer; expandir sob demanda)_
- [fontDesign(_:)](https://developer.apple.com/documentation/swiftui/view/fontdesign(_:)) — Sets the font design of the text in this view. _(Apple Developer; expandir sob demanda)_
- [fontWeight(_:)](https://developer.apple.com/documentation/swiftui/view/fontweight(_:)) — Sets the font weight of the text in this view. _(Apple Developer; expandir sob demanda)_
- [fontWidth(_:)](https://developer.apple.com/documentation/swiftui/view/fontwidth(_:)) — Sets the font width of the text in this view. _(Apple Developer; expandir sob demanda)_
- [font](https://developer.apple.com/documentation/swiftui/environmentvalues/font) — The default font of this environment. _(Apple Developer; expandir sob demanda)_
- [Font](https://developer.apple.com/documentation/swiftui/font) — An environment-dependent font. _(Apple Developer; expandir sob demanda)_

### Adjusting text size

- [textScale(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/textscale(_:isenabled:)) — Applies a text scale to text in the view. _(Apple Developer; expandir sob demanda)_
- [dynamicTypeSize(_:)](https://developer.apple.com/documentation/swiftui/view/dynamictypesize(_:)) — Sets the Dynamic Type size within the view to the given value. _(Apple Developer; expandir sob demanda)_
- [dynamicTypeSize](https://developer.apple.com/documentation/swiftui/environmentvalues/dynamictypesize) — The current Dynamic Type size. _(Apple Developer; expandir sob demanda)_
- [DynamicTypeSize](https://developer.apple.com/documentation/swiftui/dynamictypesize) — A Dynamic Type size, which specifies how large scalable content should be. _(Apple Developer; expandir sob demanda)_
- [ScaledMetric](https://developer.apple.com/documentation/swiftui/scaledmetric) — A dynamic property that scales a numeric value. _(Apple Developer; expandir sob demanda)_
- [TextVariantPreference](https://developer.apple.com/documentation/swiftui/textvariantpreference) — A protocol for controlling the size variant of text views. _(Apple Developer; expandir sob demanda)_
- [FixedTextVariant](https://developer.apple.com/documentation/swiftui/fixedtextvariant) — The default text variant preference that chooses the largest available variant. _(Apple Developer; expandir sob demanda)_
- [SizeDependentTextVariant](https://developer.apple.com/documentation/swiftui/sizedependenttextvariant) — The size dependent variant preference allows the text to take the available space into account when choosing the variant to display. _(Apple Developer; expandir sob demanda)_

### Controlling text style

- [bold(_:)](https://developer.apple.com/documentation/swiftui/view/bold(_:)) — Applies a bold font weight to the text in this view. _(Apple Developer; expandir sob demanda)_
- [italic(_:)](https://developer.apple.com/documentation/swiftui/view/italic(_:)) — Applies italics to the text in this view. _(Apple Developer; expandir sob demanda)_
- [underline(_:pattern:color:)](https://developer.apple.com/documentation/swiftui/view/underline(_:pattern:color:)) — Applies an underline to the text in this view. _(Apple Developer; expandir sob demanda)_
- [strikethrough(_:pattern:color:)](https://developer.apple.com/documentation/swiftui/view/strikethrough(_:pattern:color:)) — Applies a strikethrough to the text in this view. _(Apple Developer; expandir sob demanda)_
- [textCase(_:)](https://developer.apple.com/documentation/swiftui/view/textcase(_:)) — Sets a transform for the case of the text contained in this view when displayed. _(Apple Developer; expandir sob demanda)_
- [textCase](https://developer.apple.com/documentation/swiftui/environmentvalues/textcase) — A stylistic override to transform the case of when displayed, using the environment’s locale. _(Apple Developer; expandir sob demanda)_
- [monospaced(_:)](https://developer.apple.com/documentation/swiftui/view/monospaced(_:)) — Modifies the fonts of all child views to use the fixed-width variant of the current font, if possible. _(Apple Developer; expandir sob demanda)_
- [monospacedDigit()](https://developer.apple.com/documentation/swiftui/view/monospaceddigit()) — Modifies the fonts of all child views to use fixed-width digits, if possible, while leaving other characters proportionally spaced. _(Apple Developer; expandir sob demanda)_
- [AttributedTextFormattingDefinition](https://developer.apple.com/documentation/swiftui/attributedtextformattingdefinition) — A protocol for defining how text can be styled in a view. _(Apple Developer; expandir sob demanda)_
- [AttributedTextValueConstraint](https://developer.apple.com/documentation/swiftui/attributedtextvalueconstraint) — A protocol for defining a constraint on the value of a certain attribute. _(Apple Developer; expandir sob demanda)_
- [AttributedTextFormatting](https://developer.apple.com/documentation/swiftui/attributedtextformatting) — A namespace for types related to attributed text formatting definitions. _(Apple Developer; expandir sob demanda)_

### Managing text layout

- [truncationMode(_:)](https://developer.apple.com/documentation/swiftui/view/truncationmode(_:)) — Sets the truncation mode for lines of text that are too long to fit in the available space. _(Apple Developer; expandir sob demanda)_
- [truncationMode](https://developer.apple.com/documentation/swiftui/environmentvalues/truncationmode) — A value that indicates how the layout truncates the last line of text to fit into the available space. _(Apple Developer; expandir sob demanda)_
- [allowsTightening(_:)](https://developer.apple.com/documentation/swiftui/view/allowstightening(_:)) — Sets whether text in this view can compress the space between characters when necessary to fit text in a line. _(Apple Developer; expandir sob demanda)_
- [allowsTightening](https://developer.apple.com/documentation/swiftui/environmentvalues/allowstightening) — A Boolean value that indicates whether inter-character spacing should tighten to fit the text into the available space. _(Apple Developer; expandir sob demanda)_
- [minimumScaleFactor(_:)](https://developer.apple.com/documentation/swiftui/view/minimumscalefactor(_:)) — Sets the minimum amount that text in this view scales down to fit in the available space. _(Apple Developer; expandir sob demanda)_
- [minimumScaleFactor](https://developer.apple.com/documentation/swiftui/environmentvalues/minimumscalefactor) — The minimum permissible proportion to shrink the font size to fit the text into the available space. _(Apple Developer; expandir sob demanda)_
- [baselineOffset(_:)](https://developer.apple.com/documentation/swiftui/view/baselineoffset(_:)) — Sets the vertical offset for the text relative to its baseline in this view. _(Apple Developer; expandir sob demanda)_
- [kerning(_:)](https://developer.apple.com/documentation/swiftui/view/kerning(_:)) — Sets the spacing, or kerning, between characters for the text in this view. _(Apple Developer; expandir sob demanda)_
- [tracking(_:)](https://developer.apple.com/documentation/swiftui/view/tracking(_:)) — Sets the tracking for the text in this view. _(Apple Developer; expandir sob demanda)_
- [flipsForRightToLeftLayoutDirection(_:)](https://developer.apple.com/documentation/swiftui/view/flipsforrighttoleftlayoutdirection(_:)) — Sets whether this view mirrors its contents horizontally when the layout direction is right-to-left. _(Apple Developer; expandir sob demanda)_
- [TextAlignment](https://developer.apple.com/documentation/swiftui/textalignment) — An alignment position for text along the horizontal axis. _(Apple Developer; expandir sob demanda)_

### Rendering text

- [Creating visual effects with SwiftUI](https://developer.apple.com/documentation/swiftui/creating-visual-effects-with-swiftui) — Add scroll effects, rich color treatments, custom transitions, and advanced effects using shaders and a text renderer. _(Apple Developer; expandir sob demanda)_
- [TextAttribute](https://developer.apple.com/documentation/swiftui/textattribute) — A value that you can attach to text views and that text renderers can query. _(Apple Developer; expandir sob demanda)_
- [textRenderer(_:)](https://developer.apple.com/documentation/swiftui/view/textrenderer(_:)) — Returns a new view such that any text views within it will use to draw themselves. _(Apple Developer; expandir sob demanda)_
- [TextRenderer](https://developer.apple.com/documentation/swiftui/textrenderer) — A value that can replace the default text view rendering behavior. _(Apple Developer; expandir sob demanda)_
- [TextProxy](https://developer.apple.com/documentation/swiftui/textproxy) — A proxy for a text view that custom text renderers use. _(Apple Developer; expandir sob demanda)_

### Limiting line count for multiline text

- [lineLimit(_:)](https://developer.apple.com/documentation/swiftui/view/linelimit(_:)) — Sets to a closed range the number of lines that text can occupy in this view. _(Apple Developer; expandir sob demanda)_
- [lineLimit(_:reservesSpace:)](https://developer.apple.com/documentation/swiftui/view/linelimit(_:reservesspace:)) — Sets a limit for the number of lines text can occupy in this view. _(Apple Developer; expandir sob demanda)_
- [lineLimit](https://developer.apple.com/documentation/swiftui/environmentvalues/linelimit) — The maximum number of lines that text can occupy in a view. _(Apple Developer; expandir sob demanda)_

### Formatting multiline text

- [lineSpacing(_:)](https://developer.apple.com/documentation/swiftui/view/linespacing(_:)) — Sets the amount of space between lines of text in this view. _(Apple Developer; expandir sob demanda)_
- [lineSpacing](https://developer.apple.com/documentation/swiftui/environmentvalues/linespacing) — The distance in points between the bottom of one line fragment and the top of the next. _(Apple Developer; expandir sob demanda)_
- [multilineTextAlignment(_:)](https://developer.apple.com/documentation/swiftui/view/multilinetextalignment(_:)) — Sets the alignment of a text view that contains multiple lines of text. _(Apple Developer; expandir sob demanda)_
- [multilineTextAlignment](https://developer.apple.com/documentation/swiftui/environmentvalues/multilinetextalignment) — An environment value that indicates how a text view aligns its lines when the content wraps or contains newlines. _(Apple Developer; expandir sob demanda)_

### Formatting date and time

- [SystemFormatStyle](https://developer.apple.com/documentation/swiftui/systemformatstyle) — A collection of format styles for displaying live-updating time information in text views. _(Apple Developer; expandir sob demanda)_
- [TimeDataSource](https://developer.apple.com/documentation/swiftui/timedatasource) — A source of time related data. _(Apple Developer; expandir sob demanda)_

### Managing text entry

- [autocorrectionDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/autocorrectiondisabled(_:)) — Sets whether to disable autocorrection for this view. _(Apple Developer; expandir sob demanda)_
- [autocorrectionDisabled](https://developer.apple.com/documentation/swiftui/environmentvalues/autocorrectiondisabled) — A Boolean value that determines whether the view hierarchy has auto-correction enabled. _(Apple Developer; expandir sob demanda)_
- [keyboardType(_:)](https://developer.apple.com/documentation/swiftui/view/keyboardtype(_:)) — Sets the keyboard type for this view. _(Apple Developer; expandir sob demanda)_
- [scrollDismissesKeyboard(_:)](https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:)) — Configures the behavior in which scrollable content interacts with the software keyboard. _(Apple Developer; expandir sob demanda)_
- [textContentType(_:)](https://developer.apple.com/documentation/swiftui/view/textcontenttype(_:)) — Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on macOS. _(Apple Developer; expandir sob demanda)_
- [textInputAutocapitalization(_:)](https://developer.apple.com/documentation/swiftui/view/textinputautocapitalization(_:)) — Sets how often the shift key in the keyboard is automatically enabled. _(Apple Developer; expandir sob demanda)_
- [TextInputAutocapitalization](https://developer.apple.com/documentation/swiftui/textinputautocapitalization) — The kind of autocapitalization behavior applied during text input. _(Apple Developer; expandir sob demanda)_
- [textInputBorderShape(_:)](https://developer.apple.com/documentation/swiftui/view/textinputbordershape(_:)) — Sets the border shape for text input controls in the view hierarchy. _(Apple Developer; expandir sob demanda)_
- [TextInputBorderShape](https://developer.apple.com/documentation/swiftui/textinputbordershape) — A shape used to draw the border of a text input control. _(Apple Developer; expandir sob demanda)_
- [textInputCompletion(_:)](https://developer.apple.com/documentation/swiftui/view/textinputcompletion(_:)) — Associates a fully formed string with the value of this view when used as a text input suggestion _(Apple Developer; expandir sob demanda)_
- [textInputSuggestions(_:)](https://developer.apple.com/documentation/swiftui/view/textinputsuggestions(_:)) — Configures the text input suggestions for this view. _(Apple Developer; expandir sob demanda)_
- [textInputSuggestions(_:content:)](https://developer.apple.com/documentation/swiftui/view/textinputsuggestions(_:content:)) — Configures the text input suggestions for this view. _(Apple Developer; expandir sob demanda)_
- [textInputSuggestions(_:id:content:)](https://developer.apple.com/documentation/swiftui/view/textinputsuggestions(_:id:content:)) — Configures the text input suggestions for this view. _(Apple Developer; expandir sob demanda)_
- [textContentType(_:)](https://developer.apple.com/documentation/swiftui/view/textcontenttype(_:)-4dqqb) — Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on a watchOS device. _(Apple Developer; expandir sob demanda)_
- [textContentType(_:)](https://developer.apple.com/documentation/swiftui/view/textcontenttype(_:)-6fic1) — Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on macOS. _(Apple Developer; expandir sob demanda)_
- [textContentType(_:)](https://developer.apple.com/documentation/swiftui/view/textcontenttype(_:)-ufdv) — Sets the text content type for this view, which the system uses to offer suggestions while the user enters text on an iOS or… _(Apple Developer; expandir sob demanda)_
- [textInputFormattingControlVisibility(_:for:)](https://developer.apple.com/documentation/swiftui/view/textinputformattingcontrolvisibility(_:for:)) — Specifies which system text formatting controls are available for people to format text. _(Apple Developer; expandir sob demanda)_
- [TextInputFormattingControlPlacement](https://developer.apple.com/documentation/swiftui/textinputformattingcontrolplacement) — A structure defining the system text formatting controls available on each platform. _(Apple Developer; expandir sob demanda)_

### Dictating text

- [searchDictationBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/searchdictationbehavior(_:)) — Configures the dictation behavior for any search fields configured by the searchable modifier. _(Apple Developer; expandir sob demanda)_
- [TextInputDictationActivation](https://developer.apple.com/documentation/swiftui/textinputdictationactivation) — _Apple Developer; expandir sob demanda_
- [TextInputDictationBehavior](https://developer.apple.com/documentation/swiftui/textinputdictationbehavior) — _Apple Developer; expandir sob demanda_

### Configuring the Writing Tools behavior

- [writingToolsBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/writingtoolsbehavior(_:)) — Specifies the Writing Tools behavior for text and text input in the environment. _(Apple Developer; expandir sob demanda)_
- [WritingToolsBehavior](https://developer.apple.com/documentation/swiftui/writingtoolsbehavior) — The Writing Tools editing experience for text and text input. _(Apple Developer; expandir sob demanda)_
- [writingToolsAffordanceVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/writingtoolsaffordancevisibility(_:)) — Specifies whether the system should show the Writing Tools affordance for text input views affected by the environment. _(Apple Developer; expandir sob demanda)_

### Specifying text equivalents

- [typeSelectEquivalent(_:)](https://developer.apple.com/documentation/swiftui/view/typeselectequivalent(_:)) — Sets an explicit type select equivalent text in a collection, such as a list or table. _(Apple Developer; expandir sob demanda)_

### Localizing text

- [Preparing views for localization](https://developer.apple.com/documentation/swiftui/preparing-views-for-localization) — Specify hints and add strings to localize your SwiftUI views. _(Apple Developer; expandir sob demanda)_
- [LocalizedStringKey](https://developer.apple.com/documentation/swiftui/localizedstringkey) — The key used to look up an entry in a strings file or strings dictionary file. _(Apple Developer; expandir sob demanda)_
- [locale](https://developer.apple.com/documentation/swiftui/environmentvalues/locale) — The current locale that views should use. _(Apple Developer; expandir sob demanda)_
- [typesettingLanguage(_:isEnabled:)](https://developer.apple.com/documentation/swiftui/view/typesettinglanguage(_:isenabled:)) — Specifies the language for typesetting. _(Apple Developer; expandir sob demanda)_
- [TypesettingLanguage](https://developer.apple.com/documentation/swiftui/typesettinglanguage) — Defines how typesetting language is determined for text. _(Apple Developer; expandir sob demanda)_

### Deprecated types

- [ContentSizeCategory](https://developer.apple.com/documentation/swiftui/contentsizecategory) — The sizes that you can specify for content. _(Apple Developer; expandir sob demanda)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(contexto local)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(contexto local)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(contexto local)_
- [Animations](swiftui-animations.md) — Create smooth visual updates in response to state changes. _(contexto local)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(contexto local)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(contexto local)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(contexto local)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(contexto local)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/text-input-and-output)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `688f394d0c1edc9a760ef48afcd3612dbfda24ccb616f10514c4dfaa0baf24da`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
