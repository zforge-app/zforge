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
    @State private var preferences = FileBrowserPreferences.shared

    var body: some Scene {
        WindowGroup(
            "Zforge",
            id: "browser",
            for: BrowserWindowRequest.self
        ) { request in
            BrowserWindowRoot(request: request, appDelegate: appDelegate)
        } defaultValue: {
            BrowserWindowRequest(initialURL: appDelegate.takeNextArchiveURL())
        }
        .defaultSize(width: defaultWindowWidth, height: 720)
        .environment(\.locale, preferences.language.locale)
        .commands {
            BrowserCommands()
            KeyboardShortcutHelpCommands()
        }

        Settings {
            ZforgeSettingsView()
        }
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }

        Window("Keyboard Shortcuts", id: "keyboard-shortcuts") {
            KeyboardShortcutsView()
        }
        .defaultSize(width: 720, height: 680)
        .windowResizability(.contentMinSize)
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }
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

private struct BrowserWindowRoot: View {
    @Environment(\.openWindow) private var openWindow
    @Binding var request: BrowserWindowRequest
    let appDelegate: AppDelegate
    @State private var hasAppeared = false

    var body: some View {
        ContentView(
            initialURL: request.initialURL,
            tabSourceWindowNumber: request.tabSourceWindowNumber
        )
            .id(request.id)
            .onAppear {
                // A file can arrive after SwiftUI computes the default scene value.
                // In that case, use the first new window for the archive.
                if !hasAppeared && request.initialURL == nil,
                   let url = appDelegate.takeNextArchiveURL() {
                    request = BrowserWindowRequest(initialURL: url)
                }
                hasAppeared = true
                openPendingArchives()
            }
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.archiveURLsReceived)) { _ in
                openPendingArchives()
            }
    }

    private func openPendingArchives() {
        for url in appDelegate.takePendingArchiveURLs() {
            openWindow(id: "browser", value: BrowserWindowRequest(initialURL: url))
        }
    }
}

private struct BrowserCommands: Commands {
    @FocusedValue(\.fileBrowserState) private var browser
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Zforge Window") {
                openWindow(id: "browser", value: BrowserWindowRequest())
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New tab") {
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(
                        tabSourceWindowNumber: NSApp.keyWindow?.windowNumber
                    )
                )
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(browser == nil)

            Button("New Folder") { browser?.createNewFolder() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(browser?.canModifyCurrentDirectory != true)
        }

        CommandGroup(after: .newItem) {
            Menu("Open with") {
                if let browser {
                    ForEach(browser.applicationsForOpening(browser.selectedItems), id: \.self) { application in
                        Button(FileManager.default.displayName(atPath: application.path)) {
                            browser.openWith(browser.selectedItems, application: application)
                        }
                    }
                    Divider()
                    Button("Other…") {
                        browser.chooseApplicationForOpening(browser.selectedItems)
                    }
                }
            }
            .disabled(browser?.selectedItems.isEmpty != false
                || browser?.selectedItems.contains(where: \.isContainer) != false)
            .modifierKeyAlternate(.option) {
                Menu("Always open with") {
                    if let browser {
                        ForEach(browser.applicationsForOpening(browser.selectedItems), id: \.self) { application in
                            Button(FileManager.default.displayName(atPath: application.path)) {
                                browser.openWith(browser.selectedItems, application: application, always: true)
                            }
                        }
                        Divider()
                        Button("Other…") {
                            browser.chooseApplicationForOpening(browser.selectedItems, always: true)
                        }
                    }
                }
                .disabled(browser?.hasLocalSelection != true
                    || browser?.selectedItems.contains(where: \.isContainer) != false)
            }
            Divider()
            Button("Duplicate") { browser?.duplicateSelectedFiles() }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(browser?.hasLocalSelection != true)
            Button("Get Info") { browser?.showGetInfo() }
                .keyboardShortcut("i", modifiers: .command)
                .disabled(browser?.selectedItems.isEmpty != false)
            Button("Show Original") { browser?.showOriginal() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(browser?.canShowOriginal != true)
            Button("Make Alias") { browser?.makeAliasesForSelection() }
                .keyboardShortcut("a", modifiers: [.control, .command])
                .disabled(browser?.hasLocalSelection != true)
            Button("Rename") { browser?.beginRenamingSelectedItem() }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(browser?.canRenameSelection != true)
            Divider()
            Button("Quick Look") { browser?.openQuickLook() }
                .keyboardShortcut("y", modifiers: .command)
                .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                .modifierKeyAlternate(.option) {
                    Button("Slideshow") { browser?.openQuickLook(slideshow: true) }
                        .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                }
            Divider()
            Button("Move to Trash") { browser?.moveSelectionToTrash() }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(browser?.hasLocalSelection != true)
            Button("Delete Immediately…") { browser?.requestPermanentDeletion() }
                .keyboardShortcut(.delete, modifiers: [.option, .command])
                .disabled(browser?.hasLocalSelection != true)
            Button("Eject") { browser?.ejectSelectedVolume() }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(browser?.canEjectSelection != true)
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                if NSApp.keyWindow?.firstResponder is NSTextView {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                } else if browser?.copySelectionToPasteboard() != true {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Paste") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: .command)
            .modifierKeyAlternate(.option) {
                Button("Move Items Here") { browser?.moveClipboardItemsHere() }
                    .disabled(browser?.canModifyCurrentDirectory != true)
            }

            Button("Paste and Match Style") {
                NSApp.sendAction(#selector(NSTextView.pasteAsPlainText(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: [.option, .shift, .command])
        }

        CommandMenu("Go") {
            Button("Computer") { Task { await browser?.navigateToComputer() } }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            Button("Desktop") { Task { await browser?.navigateToDesktop() } }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button("Recents") { Task { await browser?.navigateToRecents() } }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            Button("Go to Folder…") { browser?.showingGoToFolder = true }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            Button("Home") { Task { await browser?.navigateToHome() } }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            Button("Network") { Task { await browser?.navigateToNetwork() } }
            Button("Downloads") { Task { await browser?.navigateToDownloads() } }
                .keyboardShortcut("l", modifiers: [.option, .command])
            Button("Documents") { Task { await browser?.navigateToDocuments() } }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button("Remote") { browser?.showingServerConnection = true }
                .keyboardShortcut("k", modifiers: .command)
            Button("Open Enclosing Folder in New Window") {
                if let parent = browser?.parentDirectoryURL {
                    openWindow(
                        id: "browser",
                        value: BrowserWindowRequest(initialURL: parent)
                    )
                }
            }
            .keyboardShortcut(.upArrow, modifiers: [.control, .command])
            .disabled(browser?.parentDirectoryURL == nil)
        }

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
            Button("Icons") { browser?.preferences.viewMode = .icons }
                .keyboardShortcut("1", modifiers: .command)
            Button("List") { browser?.preferences.viewMode = .list }
                .keyboardShortcut("2", modifiers: .command)
            Button("Columns") { browser?.preferences.viewMode = .columns }
                .keyboardShortcut("3", modifiers: .command)
            Button("Gallery") { browser?.preferences.viewMode = .gallery }
                .keyboardShortcut("4", modifiers: .command)
            Divider()
            Button("Zoom In") { browser?.preferences.zoomIn() }
                .keyboardShortcut("=", modifiers: .command)
                .modifierKeyAlternate(.shift) {
                    Button("Zoom In") { browser?.preferences.zoomIn() }
                        .keyboardShortcut("+", modifiers: .command)
                }
            Button("Zoom Out") { browser?.preferences.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size") { browser?.preferences.resetZoom() }
                .keyboardShortcut("0", modifiers: .command)
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

private struct KeyboardShortcutHelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Keyboard Shortcuts…") {
                openWindow(id: "keyboard-shortcuts")
            }
            .keyboardShortcut("/", modifiers: .command)
        }
    }
}

private struct ZforgeSettingsView: View {
    @State private var preferences = FileBrowserPreferences.shared
    @State private var compressionDraft = CompressionDraft(preferences: .shared)

    var body: some View {
        Form {
            Picker("Language", selection: $preferences.language) {
                Text("System Default").tag(AppLanguagePreference.system)
                Text("English").tag(AppLanguagePreference.english)
                Text("Português (Brasil)").tag(AppLanguagePreference.portugueseBrazil)
            }
            Picker("Default View", selection: $preferences.viewMode) {
                ForEach(BrowserViewMode.allCases) { mode in
                    Label(
                        AppLocalization.string(mode.titleKey, locale: preferences.language.locale),
                        systemImage: mode.systemImage
                    ).tag(mode)
                }
            }
            Toggle("Show hidden files", isOn: $preferences.showHiddenFiles)

            Section("Compression") {
                Picker("Default compression profile", selection: $preferences.defaultCompressionProfileID) {
                    ForEach(preferences.compressionProfiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
                CompressionProfileEditor(draft: compressionDraft, preferences: preferences)
                    .onChange(of: preferences.defaultCompressionProfileID) { _, id in
                        if let profile = preferences.compressionProfiles.first(where: { $0.id == id }) {
                            compressionDraft.load(profile, preferences: preferences)
                        }
                    }
            }

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
        .frame(width: 600, height: 680)
        .environment(\.locale, preferences.language.locale)
    }
}
