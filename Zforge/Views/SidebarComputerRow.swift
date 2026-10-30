import SwiftUI

/// Finder's computer item: the first Locations row, titled with the Mac's name. It opens
/// the computer level and, unlike folder rows, accepts no drops.
struct SidebarComputerRow: View {
    @Bindable var browser: FileBrowserState
    let computer: SidebarComputer
    let restoreContentFocus: () -> Void

    var body: some View {
        SidebarVirtualLocationRow(title: Text(verbatim: computer.name), systemImage: computer.systemImage,
                                  isCurrent: browser.location == .computer, identifier: "sidebar-computer") {
            restoreContentFocus()
            Task { await browser.navigateToComputer() }
        }
    }
}

/// Finder's Network item: the last Locations row, after the volumes. It opens the Network level
/// (the same path as Go ▸ Network) and accepts no drops.
struct SidebarNetworkRow: View {
    @Bindable var browser: FileBrowserState
    let restoreContentFocus: () -> Void

    /// Highlighted only while the Network level itself is shown, not inside a mounted share.
    static func isCurrent(in browser: FileBrowserState) -> Bool { browser.location == .network }

    var body: some View {
        SidebarVirtualLocationRow(title: Text("Network"), systemImage: "network",
                                  isCurrent: Self.isCurrent(in: browser), identifier: "sidebar-network",
                                  action: open)
    }

    /// The row's action: the same navigation as Go ▸ Network.
    func open() {
        restoreContentFocus()
        Task { await browser.navigateToNetwork() }
    }
}

/// A Locations row for a virtual level (computer, Network): drawn like the destination rows,
/// highlighted while its level is current, and never a drop target.
struct SidebarVirtualLocationRow: View {
    let title: Text
    let systemImage: String
    let isCurrent: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label {
                    title.fontWeight(isCurrent ? .semibold : .regular)
                } icon: {
                    Image(systemName: systemImage)
                        .resizable().scaledToFit().frame(width: 16, height: 16)
                        .sidebarIconStyle()
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sidebarLabelStyle()
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityIdentifier(identifier)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color(nsColor: .unemphasizedSelectedContentBackgroundColor) : .clear)
                .padding(.horizontal, 10)
        )
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
