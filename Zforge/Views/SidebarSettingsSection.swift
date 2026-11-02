import SwiftUI

/// Finder's Settings ▸ Sidebar Locations checkboxes, in Settings ▸ Sidebar. "Remove from Sidebar" on a Locations item
/// turns its category off here; turning it back on shows the items again in every window.
struct SidebarSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences

    var body: some View {
        Section {
            Text("Choose the items shown in the sidebar Locations and Shared sections.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(SidebarLocationCategory.allCases, id: \.self) { category in
                Toggle(isOn: Binding(
                    get: { preferences.isSidebarLocationVisible(category) },
                    set: { preferences.setSidebarLocation(category, visible: $0) }
                )) {
                    title(for: category)
                }
                .accessibilityIdentifier("settings-sidebar-\(category.rawValue)")
            }
        }
    }

    private func title(for category: SidebarLocationCategory) -> Text {
        switch category {
        case .computer: Text(verbatim: ComputerIdentity.name(locale: preferences.language.locale))
        case .home: Text(verbatim: UserDirectoryService.homeURL.lastPathComponent)
        case .hardDisks: Text("Hard disks")
        case .externalDisks: Text("External disks")
        case .network: Text("Network")
        case .connectedServers: Text("Connected servers")
        }
    }
}
