# Application localization

Implemented catalog and language-selection contract, 2026-10-11. [CURRENT-STATE §9](CURRENT-STATE.md#9-preferences-location-and-visual) remains the implemented-behavior authority; [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md) records executed evidence and verification gaps.

## Supported languages

Settings offers System Default first, followed by these 21 language autonyms. Autonyms remain identical in every interface language so users can recover from an unfamiliar selection.

| Identifier | Language | Settings label |
| --- | --- | --- |
| `en` | English | English |
| `pt-BR` | Brazilian Portuguese | Português (Brasil) |
| `zh-Hans` | Simplified Chinese | 简体中文 |
| `zh-Hant` | Traditional Chinese | 繁體中文 |
| `ja` | Japanese | 日本語 |
| `de` | German | Deutsch |
| `fr` | French | Français |
| `es` | Spanish | Español |
| `ko` | Korean | 한국어 |
| `it` | Italian | Italiano |
| `ru` | Russian | Русский |
| `pl` | Polish | Polski |
| `uk` | Ukrainian | Українська |
| `tr` | Turkish | Türkçe |
| `th` | Thai | ไทย |
| `da` | Danish | Dansk |
| `cs` | Czech | Čeština |
| `nl` | Dutch | Nederlands |
| `sv` | Swedish | Svenska |
| `hi` | Hindi | हिन्दी |
| `bn` | Bengali | বাংলা |

Romansh and additional regional translations are outside this request. Spanish uses one translation across supported regional preferences. Portuguese regional preferences use Brazilian Portuguese while it is the only Portuguese translation.

## Selection and resolution

- Preserve the existing saved `system`, `english` and `portugueseBrazil` values. Every explicit language persists through preferences reopening. Invalid saved values resolve to System Default.
- System Default walks `Locale.preferredLanguages` in order, skipping unsupported languages. Empty or entirely unsupported lists fall back to English.
- Regional preferences map to their supported language. Chinese matches the explicit script first; Foundation infers the regional script when one is absent. Mainland China/Singapore use Simplified Chinese; Taiwan/Hong Kong/Macao use Traditional Chinese. Explicit `zh-Hans-TW` and `zh-Hant-CN` retain their explicit script.
- SwiftUI receives the selected canonical `Locale`. Dates and file sizes use that locale. Service/model messages outside SwiftUI use `AppLocalization` and the same canonical bundle mapping.
- App-provided menus, settings, tooltips, accessibility text, progress and error messages use the String Catalog. macOS-provided controls and standard system menu headings retain the operating system's own localization behavior.
- Native action terminology follows current macOS conventions. An identical spelling across languages can be intentional: Dutch `Open` is the native Finder command, verified in `nl.lproj/LocalizableMerged.strings`, key `N151`. It is not evidence of an English fallback; complete bundled-resource coverage is verified independently.

## Catalog and grammatical rules

The delivered catalog contains 415 keys with explicit entries for all 21 languages, including the language autonyms and the automation strings added in the shared working tree. English symbolic archive/browser error keys have readable messages. New strings must be populated in every supported language in the same change. ZF-58 (2026-11-02) added 12 keys for the two-column Settings window (pane title General, five pane descriptions, Profiles, Add Profile, Duplicate Profile, the delete confirmation and its message, and the Solid summary token) in all 21 languages; the catalog now has 478 keys. Their translations follow the existing terminology of each language and await native review (TASKS ZF-58).

- Preserve all named intent parameters (`${files}`, `${archiveName}`, `${destinationFolder}` and related names) exactly. Their order may change with grammar.
- Preserve the types and order of nonpositional printf arguments (`%lld`, `%@`). Destination and original-archive substitutions must retain their semantic roles.
- Retain format/codec names, protocol examples, product names and keyboard glyphs. Localize native feature/action names such as Quick Look and Slideshow when macOS localizes them.
- Russian, Polish, Ukrainian, Czech and Danish use catalog plural variations for document/folder counts, item totals, Info totals, both Add confirmations, and Copying/Moving confirmations: ten keys per language. Each plural branch preserves the complete warning and its substitutions. Other languages retain their applicable singular/plural or invariant count wording.
- Authorization text must distinguish the exact requested folder from a broader ancestor grant, separate automation grants from browser permissions, and disclose future agent/shortcut read/write access. Destructive warnings must preserve irreversibility; moving removes source entries only after successful transfer, while copying preserves them.

## Translation workflow and review

The user required Codex-authored translations before refinement with Google Translate and DeepL and explicitly authorized dividing authoring among Codex agents. All 19 new languages received complete own drafts before that language's external comparison. The initial drafts were preserved under `/private/tmp/zforge-localization-work/authored` and `own-before-refinement`.

Google candidates were compared with the own drafts. Malformed batch markers or changed parameters were rejected; critical/ambiguous strings were subsequently compared individually where necessary. Candidates that changed extraction into quotation, Store into a shop, hierarchy into bird nesting, or windowless operation into Microsoft Windows were rejected. Native wording and warning semantics take precedence over machine suggestions.

DeepL comparison covered four critical messages in each of the 18 supported new languages, plus Brazilian Portuguese; Japanese also received a back-translation check. This is targeted semantic review, not a full second translation of every key. Thai was absent from the available DeepL target-language selector; its external comparison used Google. Native preview/action terminology was also checked against installed Finder localization resources. External machine comparison is not independent human linguistic review.

## Verification boundaries

`LocalizationTests` checks exact language scope, preference persistence/legacy compatibility, ordered system matching, Chinese scripts, readable English errors, all compiled catalog keys and variants, substitutions, grammatical count cases and archive confirmations with multiple arguments. `LocalizationUITests` exercises native Settings selection, File Open in all four modes for all 21 languages, and persistence after relaunch.

Focused localization coverage passes 11 cases / 87 executions, including the compiled catalog audit. The native Settings/menu scenario is blocked before execution by macOS authentication for Enable UI Automation. The full unit suite's seven tag-persistence failures also reproduce in a temporary control with localization changes excluded; their underlying cause remains open.

The final executed counts, UI observations, screenshots and outstanding themes/accessibility/linguistic checks belong in [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md). Source presence, a successful build and machine comparison alone do not establish interface polish.

## Acknowledgments strings — ZF-75, 2026-11-10

The window title and menu item use Apple's own translation of “Acknowledgments” in each language, read from the `Acknowledgments` key of the macOS 27.2 Books and Shortcuts `Localizable.loctable` (identical in both): cs Uznání, da Tak til, de Anmerkungen, es Reconocimientos, fr Remerciements, hi अभिस्वीकृतियाँ, it Note legali, ja 謝辞, ko 승인서, nl Colofon, pl Podziękowania, pt-BR Reconhecimentos, ru Подтверждения, sv Tillkännagivanden, th กิตติกรรมประกาศ, tr Teşekkürler, uk Подяки, zh-Hans 版权声明, zh-Hant 版權宣告. Bengali has no system translation; it keeps the own draft স্বীকৃতি. “License”, “Website” and the 7-Zip note are own translations, reviewed on 2026-11-10 for meaning and terminology: “repository” is never translated with the word the catalog uses for a compressed archive (Danish and Swedish use kodelager and kodförråd), and the bridge and source terms match the English note. No native-speaker review.

