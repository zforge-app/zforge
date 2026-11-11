import SwiftUI

/// The panes of the Settings window, listed in its sidebar as in System Settings (ZF-58).
/// The sidebar lists them in one flat list; the last pane shown is remembered between openings.
enum SettingsPane: String, CaseIterable, Identifiable, Sendable {
    case general
    case viewOptions
    case sidebar
    case compression
    case previews
    case automation

    var id: Self { self }

    var titleKey: String.LocalizationValue {
        switch self {
        case .general: "General"
        case .viewOptions: "View Options"
        case .sidebar: "Sidebar"
        case .compression: "Compression"
        case .previews: "Previews in Archives"
        case .automation: "Automation"
        }
    }

    /// What the pane holds, shown as the sidebar row's help tag.
    var descriptionKey: String.LocalizationValue {
        switch self {
        case .general: "Language and how Zforge works with Finder."
        case .viewOptions: "How folders and archives appear in browser windows."
        case .sidebar: "Choose the items shown in the sidebar Locations and Shared sections."
        case .compression: "Profiles used to create archives."
        case .previews: "Limits for previews and thumbnails of items inside archives."
        case .automation: "Folders that agents and Zforge shortcuts may read and write."
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gear"
        case .viewOptions: "eye.fill"
        case .sidebar: "sidebar.left"
        case .compression: "doc.zipper"
        case .previews: "rectangle.and.text.magnifyingglass"
        case .automation: "wand.and.sparkles"
        }
    }

    /// The pane's tile colour: a macOS system colour, so it adapts to light and dark appearance
    /// (ZF-62). General gray, View Options blue, Sidebar teal, Compression orange, Previews in
    /// Archives green, Automation indigo.
    var tileColor: Color {
        switch self {
        case .general: .gray
        case .viewOptions: .blue
        case .sidebar: .teal
        case .compression: .orange
        case .previews: .green
        case .automation: .indigo
        }
    }

    /// The top and bottom colours of the tile: the system colour, lightened a little at the top.
    var tileColors: (top: Color, bottom: Color) {
        (tileColor.mix(with: .white, by: 0.18), tileColor)
    }

    func title(locale: Locale) -> String { AppLocalization.string(titleKey, locale: locale) }
}
