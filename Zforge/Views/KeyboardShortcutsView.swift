import SwiftUI

struct KeyboardShortcutsView: View {
    @State private var preferences = FileBrowserPreferences.shared
    @State private var searchText = ""

    private var filteredSections: [KeyboardShortcutSection] {
        let query = normalized(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !query.isEmpty else { return KeyboardShortcutCatalog.sections }

        return KeyboardShortcutCatalog.sections.compactMap { section in
            let matchingItems = section.items.filter { item in
                let localizedAction = String(
                    localized: String.LocalizationValue(item.action),
                    locale: preferences.language.locale
                )
                let localizedSection = String(
                    localized: String.LocalizationValue(section.title),
                    locale: preferences.language.locale
                )
                let shortcutAliases = item.input
                    .replacingOccurrences(of: "⌃", with: " control ctrl ")
                    .replacingOccurrences(of: "⌥", with: " option alt ")
                    .replacingOccurrences(of: "⇧", with: " shift ")
                    .replacingOccurrences(of: "⌘", with: " command cmd ")

                return [localizedAction, localizedSection, item.input, shortcutAliases]
                    .contains { normalized($0).contains(query) }
            }
            guard !matchingItems.isEmpty else { return nil }
            return section.withItems(matchingItems)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if filteredSections.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        ForEach(filteredSections) { section in
                            KeyboardShortcutSectionView(section: section)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 620, minHeight: 520)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Shortcuts")
        .environment(\.locale, preferences.language.locale)
    }

    private func normalized(_ value: String) -> String {
        value.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: preferences.language.locale
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "keyboard")
                .font(.system(size: 28, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text("Keyboard Shortcuts")
                    .font(.title2.weight(.semibold))
                Text("Commands and gestures available in Zforge")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct KeyboardShortcutSectionView: View {
    let section: KeyboardShortcutSection

    var body: some View {
        GroupBox {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                ForEach(section.items) { item in
                    GridRow {
                        Text(LocalizedStringKey(item.action))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        KeyboardShortcutInputView(input: item.input)
                            .gridColumnAlignment(.trailing)
                    }

                    if item.id != section.items.last?.id {
                        Divider()
                            .gridCellColumns(2)
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Label(LocalizedStringKey(section.title), systemImage: section.systemImage)
                .font(.headline)
        }
    }
}

private struct KeyboardShortcutInputView: View {
    let input: String

    private var alternatives: [String] {
        input.split(separator: "|").map(String.init)
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(alternatives.enumerated()), id: \.offset) { _, alternative in
                KeyboardShortcutKeycap(input: alternative)
            }
        }
        .fixedSize()
    }
}

private struct KeyboardShortcutKeycap: View {
    let input: String

    private var compactKeys: [String]? {
        guard !input.contains(where: { $0.isWhitespace }),
              input.contains(where: { "⌃⌥⇧⌘".contains($0) }) else { return nil }
        return input.map(String.init)
    }

    var body: some View {
        Group {
            if let compactKeys {
                HStack(spacing: 1) {
                    ForEach(Array(compactKeys.enumerated()), id: \.offset) { _, key in
                        Text(verbatim: key)
                    }
                }
            } else {
                Text(LocalizedStringKey(input))
            }
        }
        .font(.system(.body, design: .monospaced).weight(.medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(.separator, lineWidth: 0.5)
        }
    }
}

private struct KeyboardShortcutSection: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let items: [KeyboardShortcutItem]

    func withItems(_ items: [KeyboardShortcutItem]) -> KeyboardShortcutSection {
        KeyboardShortcutSection(id: id, title: title, systemImage: systemImage, items: items)
    }
}

private struct KeyboardShortcutItem: Identifiable {
    let id: String
    let action: String
    let input: String
}

private enum KeyboardShortcutCatalog {
    static let sections: [KeyboardShortcutSection] = [
        section("files", "Files and Items", "doc.on.doc", [
            ("Undo", "⌘Z"),
            ("New Zforge Window", "⌘N"),
            ("New Folder", "⇧⌘N"),
            ("Duplicate", "⌘D"),
            ("Get Info", "⌘I"),
            ("Show Original", "⌘R"),
            ("Make Alias", "⌃⌘A"),
            ("Rename", "Return"),
            ("Copy", "⌘C"),
            ("Paste", "⌘V"),
            ("Move Items Here", "⌥⌘V"),
            ("Move to Trash", "⌘⌫"),
            ("Delete Immediately…", "⌥⌘⌫"),
            ("Eject", "⌘E")
        ]),
        section("go", "Go", "arrow.triangle.turn.up.right.diamond", [
            ("Computer", "⇧⌘C"),
            ("Desktop", "⇧⌘D"),
            ("Recents", "⇧⌘F"),
            ("Go to Folder…", "⇧⌘G"),
            ("Home", "⇧⌘H"),
            ("Downloads", "⌥⌘L"),
            ("Documents", "⇧⌘O"),
            ("Connect to Server…", "⌘K"),
            ("Open Enclosing Folder in New Window", "⌃⌘↑")
        ]),
        section("navigation", "Navigation", "arrow.left.arrow.right", [
            ("Back", "⌘["),
            ("Forward", "⌘]"),
            ("Enclosing Folder", "⌘↑"),
            ("Open", "⌘↓")
        ]),
        section("view", "View", "rectangle.3.group", [
            ("Icons", "⌘1"),
            ("List", "⌘2"),
            ("Columns", "⌘3"),
            ("Gallery", "⌘4"),
            ("Zoom In", "⌘+|⌘="),
            ("Zoom Out", "⌘−"),
            ("Actual Size", "⌘0"),
            ("Show or Hide Tab Bar", "⇧⌘T"),
            ("Show Hidden Files", "⇧⌘."),
            ("Show or Hide Preview", "⇧⌘P")
        ]),
        section("preview", "Preview", "eye", [
            ("Quick Look", "Space|⌘Y"),
            ("Quick Look Slideshow", "⌥⌘Y")
        ]),
        section("help", "Help", "questionmark.circle", [
            ("Keyboard Shortcuts…", "⌘/")
        ]),
        section("mouse", "Mouse and Drag", "cursorarrow.motionlines", [
            ("Open a folder in a separate window", "⌘ + double-click"),
            ("Move to another volume", "⌘ + drag"),
            ("Copy an item", "⌥ + drag"),
            ("Make an alias", "⌥⌘ + drag"),
            ("Expand or collapse the entire hierarchy", "⌥ + click disclosure"),
            ("Show the folders that contain the current folder", "⌘ + click window title")
        ])
    ]

    private static func section(
        _ id: String,
        _ title: String,
        _ systemImage: String,
        _ items: [(String, String)]
    ) -> KeyboardShortcutSection {
        KeyboardShortcutSection(
            id: id,
            title: title,
            systemImage: systemImage,
            items: items.enumerated().map {
                KeyboardShortcutItem(id: "\(id)-\($0.offset)", action: $0.element.0, input: $0.element.1)
            }
        )
    }
}
