import AppKit
import FinderSync
import SwiftUI

/// Finder lists Zforge's submenu only after the user turns on its extension in System Settings.
struct FinderExtensionSettingsSection: View {
    @State private var enabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        SettingsGroup(header: Text("Finder")) {
            HStack {
                if enabled {
                    Label("Finder extension enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Finder extension not enabled", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Finder Extensions…") { FIFinderSyncController.showExtensionManagementInterface() }
                    .accessibilityIdentifier("finder-extension-manage")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("finder-extension-status")
        } footer: {
            Text("Adds a Zforge submenu to Finder's shortcut menu for files, folders and archives. Turn on the Zforge extension in System Settings to use it.")
        }
        // Returning from System Settings reactivates Zforge.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            enabled = FIFinderSyncController.isExtensionEnabled
        }
    }
}
