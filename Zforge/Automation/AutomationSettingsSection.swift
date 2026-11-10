import AppKit
import SwiftUI

struct AutomationSettingsSection: View {
    @State private var folders: [AutomationFolder] = []
    @State private var error: String?
    @State private var copied = false

    var body: some View {
        // The groups are siblings in the pane column; modifiers attach to a container.
        Group {
            SettingsGroup {
                if folders.isEmpty {
                    Text("No folders allowed")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("automation-no-folders")
                }
                ForEach(folders) { folder in
                    HStack {
                        Text(folder.url.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(folder.url.path)
                        Spacer()
                        Button("Remove") {
                            Task {
                                await AutomationGrantStore.shared.remove(folder.id)
                                await reload()
                            }
                        }
                        .accessibilityLabel(Text("Remove automation access to \(folder.url.lastPathComponent)"))
                    }
                }
                HStack {
                    Button("Allow Folder…", action: chooseFolder)
                        .accessibilityIdentifier("automation-allow-folder")
                    Spacer()
                    Button(copied ? "Configuration copied" : "Copy MCP Configuration") {
                        guard let executable = Bundle.main.executableURL else { return }
                        do {
                            let configuration = try Self.configuration(executable: executable.path)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(configuration, forType: .string)
                            copied = true
                        } catch { self.error = error.localizedDescription }
                    }
                    .accessibilityIdentifier("automation-copy-mcp")
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Allow folders that agents and Zforge shortcuts may read and write. Existing browser permissions are separate. Removing a folder blocks new requests; running operations must be cancelled by their caller.")
                    Text("Use the copied configuration in a local MCP client. Missing folder access is requested when needed. Zforge needs no additional runtime. Disconnecting cancels pending authorization and that connection's running job.")
                }
            }
            SettingsGroup {
                if ArchiveContextCatalog.shared.unavailable {
                    HStack {
                        Text("Archive search is unavailable. Try again.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Try Again") {
                            Task { try? await ArchiveIndexRuntime.shared.reindex() }
                        }
                        .accessibilityIdentifier("automation-retry-index")
                    }
                }
                HStack {
                    Button("Open Shortcuts") {
                        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.shortcuts"),
                              NSWorkspace.shared.open(url) else {
                            error = AppLocalization.string("Shortcuts is unavailable on this Mac.")
                            return
                        }
                    }
                    .accessibilityIdentifier("automation-open-shortcuts")
                    Spacer()
                }
            } footer: {
                Text("Archive names directly inside allowed folders are shared with Spotlight and Siri. Siri availability depends on macOS. Save shortcuts for compression and extraction.")
                    .accessibilityIdentifier("automation-shortcuts-instructions")
            }
        }
        .task { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: AutomationGrantStore.changed)) { _ in
            Task { await reload() }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: AutomationGrantStore.changed, object: Bundle.main.bundleIdentifier.map { $0 as NSString })) { _ in
            Task { await reload() }
        }
        .alert("Automation", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }

    private func reload() async { folders = await AutomationGrantStore.shared.folders() }

    private func chooseFolder() {
        let panel = UITestLaunchIsolation.openPanel()
        panel.title = AppLocalization.string("Allow Folder for Automation")
        panel.prompt = AppLocalization.string("Allow")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                do {
                    try await AutomationGrantStore.shared.add(url)
                    await reload()
                } catch { self.error = error.localizedDescription }
            }
        }
    }

    nonisolated static func configuration(executable: String) throws -> String {
        let object = ["mcpServers": ["zforge": ["command": executable, "args": ["--mcp"]] as [String: Any]]]
        return String(decoding: try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), as: UTF8.self)
    }
}
