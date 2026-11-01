import AppKit
import SwiftUI

enum CompressionSaveDialogLayout {
    static let width: CGFloat = 580
    static let horizontalInset: CGFloat = 20
    static let contentWidth = width - 2 * horizontalInset
    static let columnSpacing: CGFloat = 10
    static let dividerWidth: CGFloat = 1
    static let columnWidth = (contentWidth - 2 * columnSpacing - dividerWidth) / 2
}

struct CompressionSaveRequest {
    let name: String
    let directory: URL
    let tags: [String]
}

@MainActor
final class CompressionSaveDialogSession {
    private let draft: CompressionDraft
    private let preferences: FileBrowserPreferences
    private let initialName: String
    private let initialDirectory: URL
    private var panel: NSPanel?
    private var host: NSHostingView<CompressionSaveDialog>?
    private weak var parentWindow: NSWindow?
    private var continuation: CheckedContinuation<CompressionSaveRequest?, Never>?

    init(
        draft: CompressionDraft,
        preferences: FileBrowserPreferences,
        name: String,
        directory: URL
    ) {
        self.draft = draft
        self.preferences = preferences
        initialName = name
        initialDirectory = directory
    }

    static func present(
        draft: CompressionDraft,
        preferences: FileBrowserPreferences,
        name: String,
        directory: URL
    ) async -> CompressionSaveRequest? {
        let session = CompressionSaveDialogSession(
            draft: draft, preferences: preferences, name: name, directory: directory
        )
        return await withCheckedContinuation { continuation in
            session.continuation = continuation
            session.show()
        }
    }

    private func show() {
        let panel = makePanel()
        parentWindow = NSApp.keyWindow ?? NSApp.mainWindow
        if let parentWindow {
            parentWindow.beginSheet(panel)
        } else {
            panel.center()
            panel.makeKeyAndOrderFront(nil)
        }
    }

    /// Builds the panel sized to its content without presenting it.
    func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: CompressionSaveDialogLayout.width, height: 480),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        panel.title = AppLocalization.string(
            "Compress Custom…", locale: preferences.language.locale
        )
        panel.isReleasedWhenClosed = false
        let host = NSHostingView(rootView: CompressionSaveDialog(
            draft: draft,
            preferences: preferences,
            initialName: initialName,
            initialDirectory: initialDirectory,
            onSave: { self.finish($0) },
            onCancel: { self.finish(nil) },
            onContentChange: { self.scheduleHeightUpdate() }
        ))
        self.panel = panel
        self.host = host
        panel.contentView = host
        panel.setContentSize(NSSize(width: CompressionSaveDialogLayout.width, height: host.fittingSize.height))
        return panel
    }

    private func scheduleHeightUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let panel = self.panel, let host = self.host else { return }
            let height = host.fittingSize.height
            if abs(panel.contentLayoutRect.height - height) > 1 {
                panel.setContentSize(NSSize(width: CompressionSaveDialogLayout.width, height: height))
            }
        }
    }

    private func finish(_ request: CompressionSaveRequest?) {
        guard let continuation else { return }
        self.continuation = nil
        if let parentWindow, let panel {
            parentWindow.endSheet(panel)
        } else {
            panel?.orderOut(nil)
        }
        host = nil
        panel = nil
        continuation.resume(returning: request)
    }
}

private struct CompressionSaveDialog: View {
    @Bindable var draft: CompressionDraft
    @Bindable var preferences: FileBrowserPreferences
    @State private var name: String
    @State private var tags = ""
    @State private var directory: URL
    let onSave: (CompressionSaveRequest) -> Void
    let onCancel: () -> Void
    let onContentChange: () -> Void

    init(
        draft: CompressionDraft,
        preferences: FileBrowserPreferences,
        initialName: String,
        initialDirectory: URL,
        onSave: @escaping (CompressionSaveRequest) -> Void,
        onCancel: @escaping () -> Void,
        onContentChange: @escaping () -> Void
    ) {
        self.draft = draft
        self.preferences = preferences
        _name = State(initialValue: initialName)
        _directory = State(initialValue: initialDirectory)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onContentChange = onContentChange
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Compress Custom…")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CompressionSaveDialogLayout.horizontalInset)
                .padding(.top, 14)

            VStack(spacing: 12) {
                topRow("Save As") {
                    TextField("", text: $name)
                        .accessibilityLabel(Text("Save As"))
                        .accessibilityIdentifier("compression-save-name")
                }
                topRow("Tags") {
                    TextField("", text: $tags)
                        .accessibilityLabel(Text("Tags"))
                        .accessibilityIdentifier("compression-save-tags")
                }
                topRow("Where") {
                    Button(action: chooseDirectory) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(directory.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel(Text("Where"))
                    .accessibilityIdentifier("compression-save-where")
                }
            }
            .padding(.horizontal, CompressionSaveDialogLayout.horizontalInset)
            .padding(.vertical, 16)

            Divider()

            CompressionProfileEditor(
                draft: draft,
                preferences: preferences,
                forSavePanel: true,
                onContentChange: onContentChange
            )
            .padding(.horizontal, CompressionSaveDialogLayout.horizontalInset)
            .padding(.vertical, 14)

            Divider()

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!validName)
            }
            .padding(.horizontal, CompressionSaveDialogLayout.horizontalInset)
            .padding(.vertical, 16)
        }
        .frame(width: CompressionSaveDialogLayout.width)
        .environment(\.locale, preferences.language.locale)
    }

    private func topRow<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .frame(width: 96, alignment: .trailing)
            content().frame(maxWidth: .infinity)
        }
    }

    private var validName: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains("/") && !trimmed.contains(":")
    }

    private func chooseDirectory() {
        let chooser = UITestLaunchIsolation.openPanel()
        chooser.title = AppLocalization.string("Choose Folder…", locale: preferences.language.locale)
        chooser.prompt = AppLocalization.string("Choose", locale: preferences.language.locale)
        chooser.canChooseFiles = false
        chooser.canChooseDirectories = true
        chooser.canCreateDirectories = true
        chooser.directoryURL = directory
        guard chooser.runModal() == .OK, let selected = chooser.url else { return }
        directory = selected
    }

    private func save() {
        guard validName else { return }
        let parsedTags = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        onSave(CompressionSaveRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            directory: directory,
            tags: parsedTags
        ))
    }
}
