import AppKit
import SwiftUI

nonisolated struct BrowserWindowRequest: Codable, Hashable {
    let id: UUID
    let initialURL: URL?
    let tabSourceWindowNumber: Int?

    init(id: UUID = UUID(), initialURL: URL? = nil, tabSourceWindowNumber: Int? = nil) {
        self.id = id
        self.initialURL = initialURL
        self.tabSourceWindowNumber = tabSourceWindowNumber
    }
}

struct BrowserWindowConfigurationView: NSViewRepresentable {
    let representedURL: URL?
    let tabSourceWindowNumber: Int?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        configureWindow(for: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        configureWindow(for: view)
    }

    private func configureWindow(for view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.tabbingIdentifier = "io.libor.Zforge.browser"
            window.tabbingMode = .automatic
            window.representedURL = representedURL
            if let tabSourceWindowNumber,
               let source = NSApp.windows.first(where: { $0.windowNumber == tabSourceWindowNumber }),
               source !== window,
               source.tabbedWindows?.contains(window) != true {
                source.addTabbedWindow(window, ordered: .above)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

struct GoToFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var browser: FileBrowserState
    @State private var path = ""
    @State private var isNavigating = false
    @FocusState private var pathIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Go to Folder", systemImage: "folder")
                .font(.title2.weight(.semibold))
            TextField("/path/to/folder", text: $path)
                .textFieldStyle(.roundedBorder)
                .focused($pathIsFocused)
                .onSubmit { navigate() }
            Text("Enter an absolute path or start with ~ for your home folder.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Go") { navigate() }
                    .buttonStyle(.borderedProminent)
                    .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isNavigating)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear {
            if let current = browser.currentDirectoryURL?.path {
                path = current
            }
            pathIsFocused = true
        }
    }

    private func navigate() {
        guard !isNavigating else { return }
        isNavigating = true
        Task {
            let didNavigate = await browser.navigateToFolder(
                path: path.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isNavigating = false
            if didNavigate { dismiss() }
        }
    }
}
