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
            appDelegate.makeDefaultWindowRequest()
        }
        .defaultSize(width: defaultWindowWidth, height: 720)
        // Files and URLs opened from outside go to `AppDelegate`, which decides whether a
        // window opens (ZF-78); SwiftUI must not add a window of its own for each of them.
        .handlesExternalEvents(matching: [])
        // The unit test host opens no browser window (RNF-Q08).
        .defaultLaunchBehavior(UnitTestHostPresentation.isQuietLaunch ? .suppressed : .automatic)
        .environment(\.locale, preferences.language.locale)
        .commands {
            BrowserCommands(appDelegate: appDelegate)
            KeyboardShortcutHelpCommands()
            AcknowledgmentsCommands()
            if ProcessInfo.processInfo.arguments.contains("--ui-fixtures"),
               ProcessInfo.processInfo.arguments.contains("--ui-contextual-permission") {
                CommandMenu("Automation test") {
                    Button("Disconnect test client") { AutomationPermissionUIFixture.disconnect() }
                }
            }
        }

        Settings {
            ZforgeSettingsView()
        }
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }

        Window("Keyboard Shortcuts", id: "keyboard-shortcuts") {
            KeyboardShortcutsView()
        }
        .handlesExternalEvents(matching: [])
        .defaultSize(width: KeyboardShortcutsLayout.defaultWidth, height: KeyboardShortcutsLayout.defaultHeight)
        .windowResizability(.contentMinSize)
        .environment(\.locale, preferences.language.locale)
        .commands { KeyboardShortcutHelpCommands() }

        Window("Acknowledgments", id: "acknowledgments") {
            AcknowledgmentsView()
        }
        .handlesExternalEvents(matching: [])
        .defaultSize(width: KeyboardShortcutsLayout.defaultWidth, height: KeyboardShortcutsLayout.defaultHeight)
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
            tabSourceWindowNumber: request.tabSourceWindowNumber,
            automationAccess: request.automationAccess,
            archiveSearch: request.archiveSearch,
            finderRequest: request.finderRequest
        )
            .id(request.id)
            // Requests go to open browser windows; with none, they open their own (ZF-78).
            .background(HostingWindowReader { window in appDelegate.registerBrowserWindow(window) })
            .onAppear {
                // A file can arrive after SwiftUI computes the default scene value.
                // In that case, use the first new window for the archive.
                if !hasAppeared && request.initialURL == nil && request.archiveSearch == nil && request.finderRequest == nil,
                   let pending = appDelegate.takeNextArchiveRequest() {
                    appDelegate.releaseLaunchWindow(request.id)
                    request = pending
                }
                hasAppeared = true
                AutomationPermissionUIFixture.startIfRequested()
                openPendingArchives()
            }
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.archiveURLsReceived)) { _ in
                // A request that launched Zforge replaces its untouched launch
                // window, so the launch shows one window instead of two.
                if let pending = appDelegate.takeRequest(forLaunchWindow: request.id) {
                    request = pending
                }
                openPendingArchives()
            }
            // No release on `onDisappear`: SwiftUI also removes and re-adds the launch
            // window's content while launching, before the file that launched Zforge
            // arrives, and ending the offer there opened that file in a second window
            // over the first. A closed window can never take the offer: only its own
            // root presents a request for it, and a click or key press to close it
            // already ends the offer.
    }

    private func openPendingArchives() {
        for pending in appDelegate.takePendingArchiveRequests() {
            openWindow(id: "browser", value: pending)
        }
    }
}

private struct BrowserCommands: Commands {
    let appDelegate: AppDelegate
    @FocusedValue(\.fileBrowserState) private var browser
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Commands exist before any window: they give the app its way to open a browser
        // window for a request that no open window takes (ZF-78).
        let _ = appDelegate.offerWindowOpener { [openWindow] request in openWindow(id: "browser", value: request) }
        CommandGroup(replacing: .newItem) {
            Button("New Zforge Window") {
                openWindow(id: "browser", value: BrowserWindowRequest())
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Tab") {
                openWindow(
                    id: "browser",
                    value: BrowserWindowRequest(
                        tabSourceWindowNumber: NSApp.keyWindow?.windowNumber
                    )
                )
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(browser == nil)

            Button(AppLocalization.string("New Folder", locale: browser?.preferences.language.locale)) {
                browser?.createNewFolder()
            }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(browser?.canModifyCurrentDirectory != true)
                .modifierKeyAlternate(.option) {
                    Button(AppLocalization.string("New Folder with Selection", locale: browser?.preferences.language.locale)) {
                        browser?.createNewFolderWithSelection()
                    }
                        // The shortcut's Control modifier must not become part
                        // of AppKit's visibility condition for the Option alternate.
                        .keyboardShortcut(nil)
                        .disabled(browser?.canCreateFolderWithSelection != true)
                }
        }

        CommandGroup(after: .newItem) {
            Button(AppLocalization.string("Open", locale: browser?.preferences.language.locale)) {
                browser?.openSelection()
            }
            .disabled(browser?.canOpenSelection != true)

            Menu(AppLocalization.string("Open With", locale: browser?.preferences.language.locale)) {
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
            .disabled(browser?.canOpenSelectionWithApplication != true)
            .modifierKeyAlternate(.option) {
                Menu(AppLocalization.string("Always Open With", locale: browser?.preferences.language.locale)) {
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
                .disabled(browser?.canAlwaysOpenSelectionWithApplication != true)
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
                .disabled(browser?.canRenameSelection != true || browser?.searchFieldHasFocus == true)
            Divider()
            Button("Quick Look") { browser?.openQuickLook() }
                .keyboardShortcut("y", modifiers: .command)
                .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                .modifierKeyAlternate(.option) {
                    Button("Slideshow") { browser?.openQuickLook(slideshow: true) }
                        .disabled(browser?.selectedItems.contains(where: { !$0.isContainer }) != true)
                }
            Divider()
            Button(browser?.canRemoveArchiveItems(browser?.selectedItems ?? []) == true ? "Remove from Archive…" : "Move to Trash") {
                if let browser, browser.canRemoveArchiveItems(browser.selectedItems) { browser.requestArchiveRemoval() }
                else { browser?.moveSelectionToTrash() }
            }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(browser?.hasLocalSelection != true && browser?.canRemoveArchiveItems(browser?.selectedItems ?? []) != true
                    || browser?.searchFieldHasFocus == true)
            Button("Delete Immediately…") { browser?.requestPermanentDeletion() }
                .keyboardShortcut(.delete, modifiers: [.option, .command])
                .disabled(browser?.hasLocalSelection != true || browser?.searchFieldHasFocus == true)
            Button("Eject") { browser?.ejectSelectedVolume() }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(browser?.canEjectSelection != true)
            Divider()
            Button("Find") { browser?.beginSearch() }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(browser == nil)
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
                .keyboardShortcut("k", modifiers: [.command, .shift])
            Button("Downloads") { Task { await browser?.navigateToDownloads() } }
                .keyboardShortcut("l", modifiers: [.option, .command])
            Button("Documents") { Task { await browser?.navigateToDocuments() } }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button("Remote") { browser?.showServerConnection() }
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
            Button("Icons") { browser?.viewMode = .icons }
                .keyboardShortcut("1", modifiers: .command)
            Button("List") { browser?.viewMode = .list }
                .keyboardShortcut("2", modifiers: .command)
            Button("Columns") { browser?.viewMode = .columns }
                .keyboardShortcut("3", modifiers: .command)
            Button("Gallery") { browser?.viewMode = .gallery }
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

/// Zforge ▸ Acknowledgments…, right below About Zforge. Scenes' commands share the menu bar
/// and an `after:` group is added once per scene that declares it, so only the browser scene
/// declares this one (the Help group replaces, so every scene can declare it).
private struct AcknowledgmentsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Acknowledgments…") {
                openWindow(id: "acknowledgments")
            }
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

/// Where a dragged Settings column row lands: one place per row pitch travelled from
/// where the drag started, never before Name (index 0) or past the last visible column.
enum ListColumnReorder {
    static func targetIndex(from start: Int, translation: CGFloat, rowPitch: CGFloat, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let steps = rowPitch > 0 ? Int((translation / rowPitch).rounded()) : 0
        return min(max(start + steps, 1), count - 1)
    }
}

/// Automatic previews and thumbnails of items inside archives (D-73). Every limit uses the
/// logarithmic size slider: equal track per doubling, a tick per doubling, held round values.
struct ArchivePreviewSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences

    /// The formats whose items can be in solid blocks (format names, the same in every language).
    static let solidFormats = "7z, RAR, CAB, WIM/ESD, tar.gz/tgz, tar.bz2/tbz, tar.xz/txz, tar.zst/tzst, gz, bz2, xz, zst, lzma"

    var body: some View {
        let locale = preferences.language.locale
        SettingsGroup {
            ArchiveSizeLimitRow(
                title: "Preview size limit", value: $preferences.previewSizeLimit, scale: .preview,
                identifier: "settings-preview-size-limit", locale: locale,
                caption: "Larger items inside archives show their icon until you load the preview."
            )
            ArchiveSizeLimitRow(
                title: "Thumbnail size limit", value: $preferences.thumbnailSizeLimit, scale: .thumbnail,
                identifier: "settings-thumbnail-size-limit", locale: locale,
                caption: "Applies to thumbnails of items inside archives in the icon view and in multiple selections."
            )
            VStack(alignment: .leading, spacing: 3) {
                SettingsToggleRow(Text("Preview solid archives"), identifier: "settings-preview-solid-archives",
                                  isOn: $preferences.previewSolidArchives)
                Text(verbatim: Self.solidFormats)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("An item in a solid block is measured by the compressed size of its block.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SettingsToggleRow(Text("Preview on removable drives"), identifier: "settings-preview-removable",
                              isOn: $preferences.previewOnRemovableVolumes.animation())
            if preferences.previewOnRemovableVolumes {
                ArchiveSizeLimitRow(
                    title: "Size limit on removable drives", value: $preferences.removableVolumePreviewLimit,
                    scale: .preview, identifier: "settings-preview-removable-limit", locale: locale, caption: nil
                )
            }
            SettingsToggleRow(Text("Preview on network volumes"), identifier: "settings-preview-network",
                              isOn: $preferences.previewOnNetworkVolumes.animation())
            if preferences.previewOnNetworkVolumes {
                ArchiveSizeLimitRow(
                    title: "Size limit on network volumes", value: $preferences.networkVolumePreviewLimit,
                    scale: .preview, identifier: "settings-preview-network-limit", locale: locale, caption: nil
                )
            }
        }
    }
}

/// A size limit: its title with the current value, the logarithmic slider and a caption.
struct ArchiveSizeLimitRow: View {
    let title: String.LocalizationValue
    @Binding var value: Int64
    let scale: ArchiveSizeLimitSliderScale
    let identifier: String
    let locale: Locale
    let caption: String.LocalizationValue?

    var body: some View {
        let titleString = AppLocalization.string(title, locale: locale)
        VStack(alignment: .leading, spacing: 5) {
            LabeledContent(titleString) {
                Text(AppLocalization.byteCount(value, locale: locale))
                    .monospacedDigit()
            }
            ScaleSlider(
                scale: scale,
                value: $value,
                tickLabels: scale.doublingValues.map { AppLocalization.byteCount($0, locale: locale) },
                accessibilityLabel: titleString,
                accessibilityIdentifier: identifier,
                describe: { AppLocalization.byteCount($0, locale: locale) }
            )
            .padding(.horizontal, SettingsMetrics.sliderInset)
            if let caption {
                Text(AppLocalization.string(caption, locale: locale))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

}

/// UI test fixture only (`--ui-scale-slider-fixture`): the logarithmic size slider that
/// the preview limits of a later ZF-55 stage reuse, so that real mouse tracking of its
/// holds stays covered after the nesting limits were removed (D-73). Never shown otherwise.
struct ScaleSliderUIFixtureSection: View {
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains("--ui-scale-slider-fixture") }
    private static let sizeScale = ArchiveSizeLimitSliderScale()
    @State private var value: Int64 = 1_000_000_000

    var body: some View {
        let locale = Locale(identifier: "en_US")
        SettingsGroup {
            VStack(alignment: .leading, spacing: 5) {
                LabeledContent {
                    Text(verbatim: AppLocalization.byteCount(value, locale: locale)).monospacedDigit()
                } label: {
                    Text(verbatim: "Size slider fixture")
                }
                ScaleSlider(
                    scale: Self.sizeScale,
                    value: $value,
                    tickLabels: ArchiveSizeLimitSliderScale.doublings.map { AppLocalization.byteCount($0, locale: locale) },
                    accessibilityLabel: "Size slider fixture",
                    accessibilityIdentifier: "ui-fixture-size-slider",
                    describe: { AppLocalization.byteCount($0, locale: locale) }
                )
                .padding(.horizontal, SettingsMetrics.sliderInset)
            }
        }
    }
}
