import SwiftUI

/// Finder's Settings ▸ Sidebar Locations checkboxes, in Settings ▸ Sidebar. "Remove from Sidebar" on a Locations item
/// turns its category off here; turning it back on shows the items again in every window.
struct SidebarSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences
    /// Names of this Mac and its home folder; tests pass fixed ones so snapshots do not depend on the machine.
    var computerName: String?
    var homeName: String?

    var body: some View {
        SettingsGroup(header: Text("Locations")) {
            ForEach(SidebarLocationCategory.allCases, id: \.self) { category in
                SettingsToggleRow(title(for: category), identifier: "settings-sidebar-\(category.rawValue)", isOn: Binding(
                    get: { preferences.isSidebarLocationVisible(category) },
                    set: { preferences.setSidebarLocation(category, visible: $0) }
                ))
            }
        } footer: {
            Text("Choose the items shown in the sidebar Locations and Shared sections.")
        }
    }

    private func title(for category: SidebarLocationCategory) -> Text {
        switch category {
        case .computer: Text(verbatim: computerName ?? ComputerIdentity.name(locale: preferences.language.locale))
        case .home: Text(verbatim: homeName ?? UserDirectoryService.homeURL.lastPathComponent)
        case .hardDisks: Text("Hard disks")
        case .externalDisks: Text("External disks")
        case .connectedServers: Text("Connected servers")
        }
    }
}
