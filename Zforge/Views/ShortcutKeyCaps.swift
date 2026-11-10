import SwiftUI

/// One key of a displayed shortcut: a single glyph (`⌘`, `N`, `↑`) or a word key (`Return`, `Space`).
nonisolated struct ShortcutKey: Equatable, Hashable, Sendable {
    enum Kind: Sendable { case glyph, word }

    let text: String
    let kind: Kind
}

/// One way to trigger an action: its keys, plus the mouse gesture that follows the modifiers
/// for pointer shortcuts (`⌘ + drag` has the key `⌘` and the action `drag`).
nonisolated struct ShortcutCombination: Equatable, Sendable {
    let keys: [ShortcutKey]
    let action: String?
}

/// The notation of the shortcut reference: `⇧⌘N`, `Space|⌘Y` (alternatives are separated by `|`),
/// `⌥⌘ + drag` (modifiers, then a gesture). Parsed once for the key caps and for the spoken form.
nonisolated enum ShortcutNotation {
    private static let gestureSeparator = " + "

    static func parse(_ input: String) -> [ShortcutCombination] {
        input.split(separator: "|", omittingEmptySubsequences: true).map { alternative in
            let text = String(alternative)
            let keysPart: String
            let action: String?
            if let separator = text.range(of: gestureSeparator) {
                keysPart = String(text[..<separator.lowerBound])
                let gesture = String(text[separator.upperBound...])
                action = gesture.isEmpty ? nil : gesture
            } else {
                keysPart = text
                action = nil
            }
            return ShortcutCombination(keys: keys(in: keysPart), action: action)
        }
    }

    /// A run of two or more letters is one word key (`Return`); anything else is one cap per glyph.
    private static func keys(in text: String) -> [ShortcutKey] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.count >= 2, trimmed.allSatisfy(\.isLetter) {
            return [ShortcutKey(text: trimmed, kind: .word)]
        }
        return trimmed.filter { !$0.isWhitespace }.map { ShortcutKey(text: String($0), kind: .glyph) }
    }

    /// The key as VoiceOver should say it: modifier and arrow glyphs spelled out in the app
    /// language, word keys localized, other glyphs as written.
    static func spokenName(of key: ShortcutKey, locale: Locale) -> String {
        func localized(_ value: String) -> String {
            AppLocalization.string(String.LocalizationValue(value), locale: locale)
        }
        if key.kind == .word { return localized(key.text) }
        switch key.text {
        case "⌘": return localized("Command")
        case "⇧": return localized("Shift")
        case "⌥": return localized("Option")
        case "⌃": return localized("Control")
        case "↑": return localized("Up Arrow")
        case "↓": return localized("Down Arrow")
        case "⌫": return localized("Delete")
        default: return key.text
        }
    }

    /// The whole shortcut as spoken: keys in the order shown (`Shift Command N`), the gesture
    /// after them, and alternatives joined by the localized “or”.
    static func spokenDescription(of input: String, locale: Locale) -> String {
        let alternatives = parse(input).map { combination -> String in
            var parts = combination.keys.map { spokenName(of: $0, locale: locale) }
            if let action = combination.action {
                parts.append(AppLocalization.string(String.LocalizationValue(action), locale: locale))
            }
            return parts.joined(separator: " ")
        }
        let separator = " " + AppLocalization.string("or", locale: locale) + " "
        return alternatives.joined(separator: separator)
    }
}

/// A shortcut as key caps: each glyph in its own cap, a word key in one wider cap, mouse gestures
/// as secondary text after the modifier caps, alternatives separated by a tertiary “or”.
struct ShortcutKeysView: View {
    @Environment(\.locale) private var locale
    let input: String

    var body: some View {
        let combinations = ShortcutNotation.parse(input)
        HStack(spacing: 3) {
            ForEach(Array(combinations.enumerated()), id: \.offset) { index, combination in
                if index > 0 {
                    Text("or")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                }
                ForEach(Array(combination.keys.enumerated()), id: \.offset) { _, key in
                    ShortcutKeyCap(key: key)
                }
                if let action = combination.action {
                    Text(LocalizedStringKey(action))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 3)
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: ShortcutNotation.spokenDescription(of: input, locale: locale)))
        .accessibilityIdentifier("shortcut-\(input)")
    }
}

/// One key cap: 20 pt tall (scaled with the text size), at least 20 pt wide, a subtle fill with a
/// light top edge and a darker edge underneath, in the system font (not monospaced).
struct ShortcutKeyCap: View {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 20
    let key: ShortcutKey

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4.5, style: .continuous)
        label
            .font(.system(size: key.kind == .word ? 11 : 11.5, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, key.kind == .word ? 7 : 5)
            .frame(minWidth: height, minHeight: height)
            .background {
                shape.fill(Self.fill)
                    .shadow(color: Self.edge, radius: 0, y: 1)
            }
            .overlay {
                shape.strokeBorder(Self.rim, lineWidth: 0.5)
                shape.strokeBorder(
                    LinearGradient(colors: [Self.highlight, .clear], startPoint: .top, endPoint: .center),
                    lineWidth: 0.5
                )
            }
    }

    @ViewBuilder private var label: some View {
        switch key.kind {
        case .glyph: Text(verbatim: key.text)
        case .word: Text(LocalizedStringKey(key.text))
        }
    }

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    private static let fill = adaptive(light: .white, dark: NSColor(srgbRed: 0.227, green: 0.227, blue: 0.239, alpha: 1))
    private static let edge = adaptive(light: NSColor(white: 0, alpha: 0.2), dark: NSColor(white: 0, alpha: 0.5))
    private static let rim = adaptive(light: NSColor(white: 0, alpha: 0.1), dark: NSColor(white: 1, alpha: 0.1))
    private static let highlight = adaptive(light: NSColor(white: 1, alpha: 0.9), dark: NSColor(white: 1, alpha: 0.12))
}
