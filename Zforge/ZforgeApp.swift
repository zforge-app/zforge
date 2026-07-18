import AppKit
import SwiftUI

struct FileBrowserStateFocusedKey: FocusedValueKey {
    typealias Value = FileBrowserState
}

extension FocusedValues {
    var fileBrowserState: FileBrowserState? {
        get { self[FileBrowserStateFocusedKey.self] }
        set { self[FileBrowserStateFocusedKey.self] = newValue }
    }
}

@main
struct ZforgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: defaultWindowWidth, height: 720)
        .commands { BrowserCommands() }

        Settings {
            ZforgeSettingsView()
        }
    }

    private var defaultWindowWidth: CGFloat {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--ui-window-width"),
              arguments.indices.contains(flagIndex + 1),
              let width = Double(arguments[flagIndex + 1]) else {
            return 1100
        }
        return CGFloat(width)
    }
}

private struct BrowserCommands: Commands {
    @FocusedValue(\.fileBrowserState) private var browser

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Back") { Task { await browser?.goBack() } }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(browser?.canGoBack != true)
            Button("Forward") { Task { await browser?.goForward() } }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(browser?.canGoForward != true)
            Button("Enclosing Folder") { Task { await browser?.goUp() } }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button("Open") { Task { if let item = browser?.primarySelection { await browser?.open(item) } } }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Button("Show Hidden Files") { browser?.toggleHiddenFiles() }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            Button(browser?.previewVisible == true ? "Hide Preview" : "Show Preview") {
                browser?.togglePreviewVisibility()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Quick Look") { browser?.openQuickLook() }
                .keyboardShortcut(.space, modifiers: [])
        }
    }
}

private struct ZforgeSettingsView: View {
    @State private var preferences = FileBrowserPreferences.shared

    var body: some View {
        Form {
            Picker("Language", selection: $preferences.language) {
                Text("System Default").tag(AppLanguagePreference.system)
                Text("English").tag(AppLanguagePreference.english)
                Text("Português (Brasil)").tag(AppLanguagePreference.portugueseBrazil)
            }
            Picker("Default View", selection: $preferences.viewMode) {
                ForEach(BrowserViewMode.allCases) { mode in
                    Label(String(localized: mode.titleKey), systemImage: mode.systemImage).tag(mode)
                }
            }
            Toggle("Show hidden files", isOn: $preferences.showHiddenFiles)

            Section("Archive Navigation") {
                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Maximum nesting depth") {
                        Stepper(value: $preferences.archiveNestingLimit, in: 1...10) {
                            Text(preferences.archiveNestingLimit.formatted())
                                .monospacedDigit()
                                .frame(minWidth: 24, alignment: .trailing)
                        }
                        .fixedSize()
                    }
                    Text("Limits how many compressed files can be opened inside one another. The root archive is not counted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Root archive size limit") {
                        Stepper(value: $preferences.archiveRootSizeLimitGB, in: 1...5) {
                            Text("\(preferences.archiveRootSizeLimitGB) GB")
                                .monospacedDigit()
                                .frame(minWidth: 48, alignment: .trailing)
                        }
                        .fixedSize()
                    }
                    Text("Sub-archives are only navigable when the combined size of the root archive and its volumes is below this limit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520, height: 430)
        .environment(\.locale, preferences.language.locale)
    }
}
