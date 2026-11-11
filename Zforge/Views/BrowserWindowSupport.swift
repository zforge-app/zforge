import AppKit
import SwiftUI

nonisolated struct BrowserWindowRequest: Codable, Hashable {
    let id: UUID
    let initialURL: URL?
    let tabSourceWindowNumber: Int?
    let automationAccess: BrowserOpeningAccess?
    /// Archive name search requested by a system action. Restoration repeats the
    /// search under the then-current automation grants; no lease is serialized.
    let archiveSearch: String?
    /// An action chosen in Finder. It runs once; restoration never repeats it.
    let finderRequest: FinderMenuRequest?
    /// An archive opened from inside another archive, shown in this window. Its session
    /// lives in memory only: restoration does not reopen it.
    let archiveSession: ArchiveSessionHandoff?

    init(id: UUID = UUID(), initialURL: URL? = nil, tabSourceWindowNumber: Int? = nil,
         automationAccess: BrowserOpeningAccess? = nil, archiveSearch: String? = nil,
         finderRequest: FinderMenuRequest? = nil, archiveSession: ArchiveSessionHandoff? = nil) {
        self.id = id
        self.initialURL = initialURL
        self.tabSourceWindowNumber = tabSourceWindowNumber
        self.automationAccess = automationAccess
        self.archiveSearch = archiveSearch
        self.finderRequest = finderRequest
        self.archiveSession = archiveSession
    }

    private enum CodingKeys: String, CodingKey { case id, initialURL, tabSourceWindowNumber, archiveSearch }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        initialURL = try values.decodeIfPresent(URL.self, forKey: .initialURL)
        tabSourceWindowNumber = try values.decodeIfPresent(Int.self, forKey: .tabSourceWindowNumber)
        archiveSearch = try values.decodeIfPresent(String.self, forKey: .archiveSearch)
        automationAccess = nil
        finderRequest = nil
        archiveSession = nil
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.initialURL == rhs.initialURL && lhs.tabSourceWindowNumber == rhs.tabSourceWindowNumber
            && lhs.archiveSearch == rhs.archiveSearch && lhs.finderRequest == rhs.finderRequest
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id); hasher.combine(initialURL); hasher.combine(tabSourceWindowNumber); hasher.combine(archiveSearch)
        hasher.combine(finderRequest)
    }
}

/// A live opening scope can be consumed once; restoration never grants access.
@MainActor final class BrowserOpeningAccess {
    private var lease: AutomationAccessLease?
    init(_ lease: AutomationAccessLease) { self.lease = lease }
    func take() -> AutomationAccessLease? {
        defer { lease = nil }
        return lease
    }
}

struct BrowserWindowConfigurationView: NSViewRepresentable {
    let representedURL: URL?
    let tabSourceWindowNumber: Int?
    let browser: FileBrowserState

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
            BrowserWindowLifecycle.shared.register(window, browser: browser)
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

/// Reports the window that hosts a SwiftUI view once the view is in it.
struct HostingWindowReader: NSViewRepresentable {
    let onWindow: @MainActor (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView { ReaderView(onWindow: onWindow) }
    func updateNSView(_ view: NSView, context: Context) {}

    private final class ReaderView: NSView {
        let onWindow: @MainActor (NSWindow) -> Void
        init(onWindow: @escaping @MainActor (NSWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { onWindow(window) }
        }
    }
}

/// Save at native window closure, not SwiftUI disappearance (which also occurs
/// when a tab or scene content is replaced). Keep only weak window/state links.
@MainActor
final class BrowserWindowLifecycle: NSObject {
    static let shared = BrowserWindowLifecycle()

    private struct Entry {
        weak var window: NSWindow?
        weak var browser: FileBrowserState?
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    init(notificationCenter: NotificationCenter = .default) {
        super.init()
        notificationCenter.addObserver(self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil)
    }

    func register(_ window: NSWindow, browser: FileBrowserState) {
        entries = entries.filter { $0.value.window != nil && $0.value.browser != nil }
        entries[ObjectIdentifier(window)] = Entry(window: window, browser: browser)
    }

    func window(for browser: FileBrowserState) -> NSWindow? {
        entries.values.first { $0.browser === browser }?.window
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let entry = entries.removeValue(forKey: ObjectIdentifier(window)),
              let browser = entry.browser else { return }
        browser.preferences.viewMode = browser.viewMode
    }

    /// Quit can terminate without individual window-close notifications. The
    /// frontmost remaining browser supplies the mode; auxiliary windows do not.
    func applicationWillTerminate(orderedWindows: [NSWindow]) {
        for window in orderedWindows {
            if let browser = entries[ObjectIdentifier(window)]?.browser {
                browser.preferences.viewMode = browser.viewMode
                break
            }
        }
        // Do not let teardown notifications overwrite the selected mode.
        entries.removeAll()
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
