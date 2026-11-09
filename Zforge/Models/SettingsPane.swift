import SwiftUI

/// The panes of the Settings window, listed in its sidebar as in System Settings (ZF-58).
/// The sidebar groups them; the last pane shown is remembered between openings.
enum SettingsPane: String, CaseIterable, Identifiable, Sendable {
    case general
    case viewOptions
    case sidebar
    case compression
    case previews
    case automation

    var id: Self { self }

    /// Sidebar groups, separated by a gap: browsing, archives, system integration.
    static let groups: [[SettingsPane]] = [[.general, .viewOptions, .sidebar], [.compression, .previews], [.automation]]

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
        case .general: "Language and the Zforge submenu in Finder."
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

    /// The top and bottom colours of the pane's tile. Fixed sRGB values, the same in light and
    /// dark appearance as System Settings' tiles: the system colours lighten in dark mode and
    /// their automatic gradient washed the tiles out.
    var tileColors: (top: Color, bottom: Color) {
        switch self {
        case .general: (Self.color(0xA4A4AA), Self.color(0x6E6E75))
        case .viewOptions: (Self.color(0x4AA3FF), Self.color(0x0A66E8))
        case .sidebar: (Self.color(0x8A86FF), Self.color(0x4C45DB))
        case .compression: (Self.color(0xFFA845), Self.color(0xF0700F))
        case .previews: (Self.color(0xC77BF5), Self.color(0x8E35D3))
        case .automation: (Self.color(0xFF6B9A), Self.color(0xE0245E))
        }
    }

    private static func color(_ rgb: UInt32) -> Color { Color(sRGBHex: rgb) }

    func title(locale: Locale) -> String { AppLocalization.string(titleKey, locale: locale) }
}
