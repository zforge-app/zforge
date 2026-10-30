import AppKit
import SwiftUI

extension FileBrowserState {
    /// Opens the window's connect-to-server sheet. Network ▸ Add Remote and Go ▸ Remote (⌘K)
    /// share this entry point and the single sheet presented by the browser window.
    func showServerConnection() {
        showingServerConnection = true
    }
}

/// The bar at the top of the Network level, like the button row of Finder's Network window.
/// It is shown for the whole level in every view mode and does not depend on the discovered
/// servers, so it never moves as servers appear or disappear.
struct NetworkLevelBar: View {
    @Bindable var state: FileBrowserState

    static func isShown(for state: FileBrowserState) -> Bool {
        state.location == .network
    }

    var body: some View {
        HStack(spacing: 10) {
            Button("Add Remote…", systemImage: "plus", action: addRemote)
                .help("Connect to a file server by its SMB, AFP, or NFS address.")
                .accessibilityIdentifier("network-add-remote")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    /// The button's action.
    func addRemote() {
        state.showServerConnection()
    }
}

/// Shown on the Network level while Local Network privacy blocks discovery and no server is
/// known: it is the only explanation for an empty level and leads to the setting. Add Remote
/// in the bar above still connects by address.
struct NetworkLocalAccessDeniedView: View {
    private static let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork"
    )

    var body: some View {
        ContentUnavailableView {
            Label("Local Network Access Is Off", systemImage: "network.badge.shield.half.filled")
        } description: {
            Text("Allow Zforge in System Settings ▸ Privacy & Security ▸ Local Network to find servers.")
        } actions: {
            if let url = Self.privacySettingsURL {
                Button("Open Privacy Settings") { NSWorkspace.shared.open(url) }
            }
        }
        .accessibilityIdentifier("network-access-denied")
    }
}
