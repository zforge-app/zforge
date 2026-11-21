import AppKit
import SwiftUI

extension View {
    func browserContextMenuExcludedArea(state: FileBrowserState) -> some View {
        background {
            GeometryReader { geometry in
                BrowserNativeItemMenu(state: state, item: nil, excludesBackgroundMenu: true)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    func browserBackgroundContextMenu(state: FileBrowserState) -> some View {
        background {
            GeometryReader { geometry in
                BrowserNativeItemMenu(state: state, item: nil)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    func browserItemContextMenu(state: FileBrowserState, item: BrowserItem) -> some View {
        background {
            GeometryReader { geometry in
                BrowserNativeItemMenu(state: state, item: item)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct BrowserNativeItemMenu: NSViewRepresentable {
    let state: FileBrowserState
    let item: BrowserItem?
    var excludesBackgroundMenu = false

    func makeNSView(context: Context) -> BrowserItemMenuHost { BrowserItemMenuHost(state: state, item: item, excludesBackgroundMenu: excludesBackgroundMenu) }
    func updateNSView(_ view: BrowserItemMenuHost, context: Context) { view.state = state; view.item = item; view.excludesBackgroundMenu = excludesBackgroundMenu }
    static func dismantleNSView(_ view: BrowserItemMenuHost, coordinator: ()) { view.stopMonitoring() }
}

/// Panes drawn above browser rows (previews, resize handles), marked with
/// `browserContextMenuExcludedArea`. Rows watch the whole window's events, so
/// they must not treat a press on one of these panes as their own.
@MainActor
enum BrowserForegroundArea {
    static func contains(_ locationInWindow: NSPoint, in window: NSWindow?) -> Bool {
        guard let root = window?.contentView else { return false }
        return contains(locationInWindow, in: root)
    }

    private static func contains(_ point: NSPoint, in view: NSView) -> Bool {
        if let host = view as? BrowserItemMenuHost, host.excludesBackgroundMenu,
           !host.isHiddenOrHasHiddenAncestor,
           host.convert(host.visibleRect.intersection(host.bounds), to: nil).contains(point) {
            return true
        }
        return view.subviews.contains { contains(point, in: $0) }
    }
}

@MainActor
final class BrowserItemMenuHost: NSView {
    var state: FileBrowserState
    var item: BrowserItem?
    var excludesBackgroundMenu: Bool
    private var eventMonitor: Any?

    init(state: FileBrowserState, item: BrowserItem?, excludesBackgroundMenu: Bool) {
        self.state = state
        self.item = item
        self.excludesBackgroundMenu = excludesBackgroundMenu
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil, !excludesBackgroundMenu else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown]) { [weak self] event in
            let consumed = MainActor.assumeIsolated {
                guard let self, event.window === self.window,
                      event.type == .rightMouseDown || event.modifierFlags.contains(.control),
                      self.presentsMenu(at: event.locationInWindow) else { return false }
                let menu = self.item.map { BrowserNativeContextMenu.make(state: self.state, item: $0) }
                    ?? BrowserActionsMenu.make(state: self.state, showToast: { [state = self.state] in
                        state.contextualFeedbackMessage = $0
                    })
                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return true
            }
            return consumed ? nil : event
        }
    }

    /// Whether a secondary click at this window point opens this host's menu: the point
    /// is on its visible area and not on a pane drawn above it.
    func presentsMenu(at locationInWindow: NSPoint) -> Bool {
        guard !excludesBackgroundMenu, !isHiddenOrHasHiddenAncestor,
              convert(visibleRect.intersection(bounds), to: nil).contains(locationInWindow),
              !BrowserForegroundArea.contains(locationInWindow, in: window) else { return false }
        // Item menus take priority regardless of local-monitor registration order.
        if item == nil, let root = window?.contentView,
           containsForegroundMenuArea(at: locationInWindow, in: root) { return false }
        return true
    }

    private func containsForegroundMenuArea(at point: NSPoint, in view: NSView) -> Bool {
        if let host = view as? BrowserItemMenuHost, (host.item != nil || host.excludesBackgroundMenu),
           !host.isHiddenOrHasHiddenAncestor,
           host.convert(host.visibleRect.intersection(host.bounds), to: nil).contains(point) {
            return true
        }
        return view.subviews.contains { containsForegroundMenuArea(at: point, in: $0) }
    }

    func stopMonitoring() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
    }

}

@MainActor
enum BrowserNativeContextMenu {
    static func make(state: FileBrowserState, item: BrowserItem,
                     catalogTags: [FinderTag] = FinderTagCatalog.shared.tags) -> NSMenu {
        let items = state.selection.contains(item.id) ? state.selectedItems : [item]
        let menu = NSMenu(title: item.name)
        menu.autoenablesItems = false
        let locale = state.preferences.language.locale
        func add(_ title: String.LocalizationValue, _ symbol: String, enabled: Bool = true, alternate: Bool = false, action: @escaping @MainActor () -> Void) {
            let entry = ClosureMenuItem(title: AppLocalization.string(title, locale: locale), systemImage: symbol, isEnabled: enabled, handler: action)
            entry.isAlternate = alternate
            if alternate { entry.keyEquivalentModifierMask = .option }
            menu.addItem(entry)
        }
        func selectTargets() { if !state.selection.contains(item.id) { state.select(item) } }
        for action in state.contextualActions(for: items) {
            menu.addItem(ClosureMenuItem(title: state.contextualTitle(action, items: items), action: action,
                                        isEnabled: !state.archiveOperationInProgress) {
                Task { state.contextualFeedbackMessage = await state.performContextualAction(action, items: items) }
            })
        }
        func applications(always: Bool) {
            let title: String.LocalizationValue = always ? "Always Open With" : "Open With"
            let entry = NSMenuItem(title: AppLocalization.string(title, locale: locale), action: nil, keyEquivalent: "")
            entry.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: entry.title)
            entry.isEnabled = !items.isEmpty && !items.contains { $0.isContainer || (always && $0.localURL == nil) }
            entry.isAlternate = always
            if always { entry.keyEquivalentModifierMask = .option }
            let sub = NSMenu()
            sub.autoenablesItems = false
            for app in state.applicationsForOpening(items) {
                sub.addItem(ClosureMenuItem(title: FileManager.default.displayName(atPath: app.path), systemImage: "app", isEnabled: true) {
                    state.openWith(items, application: app, always: always)
                })
            }
            sub.addItem(.separator())
            sub.addItem(ClosureMenuItem(title: AppLocalization.string("Other…", locale: locale), systemImage: "app", isEnabled: true) {
                state.chooseApplicationForOpening(items, always: always)
            })
            entry.submenu = sub
            menu.addItem(entry)
        }
        applications(always: false)
        applications(always: true)
        if !items.isEmpty && items.allSatisfy({ $0.isDirectory && !$0.isPackage && $0.localURL != nil }) {
            menu.addItem(.separator())
            add("Add to Sidebar", "pin", enabled: !items.allSatisfy { item in
                item.localURL.map { PinnedFolderStore.shared.contains($0) } ?? false
            }) {
                let urls = items.compactMap(\.localURL)
                Task { await state.pinFolders(urls) }
            }
        }
        menu.addItem(.separator())
        add("Share", "square.and.arrow.up", enabled: items.contains { !$0.isContainer }) { selectTargets(); state.shareItems() }
        add("Copy", "doc.on.doc", enabled: items.allSatisfy { $0.localURL != nil }) { selectTargets(); state.copySelectionToPasteboard() }
        add("Copy Pathname", "document.on.clipboard", enabled: items.allSatisfy { $0.localURL != nil }, alternate: true) {
            selectTargets(); state.copySelectionPathnamesToPasteboard()
        }
        menu.addItem(.separator())
        add("Get Info", "info.circle") { selectTargets(); state.showGetInfo() }
        add("Quick Look", "eye") { selectTargets(); state.openQuickLook() }
        add("Slideshow", "play.rectangle", alternate: true) { selectTargets(); state.openQuickLook(slideshow: true) }
        menu.addItem(.separator())
        FinderTagQuickMenu.append(to: menu, state: state, items: items, catalogTags: catalogTags)
        if item.localURL != nil {
            menu.addItem(.separator())
            add("Rename", "pencil", enabled: state.canRename(item)) { state.select(item); state.beginRenaming(item) }
            add("Duplicate", "plus.square.on.square") { selectTargets(); state.duplicateSelectedFiles() }
            add("Make Alias", "link") { state.select(item); state.makeAliasesForSelection() }
            add("Move to Trash", "trash") { state.select(item); state.moveSelectionToTrash() }
            add("Delete Immediately…", "trash.slash", alternate: true) { state.select(item); state.requestPermanentDeletion() }
        }
        return menu
    }
}
