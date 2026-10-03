import AppKit
import SwiftUI

extension View {
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
    let item: BrowserItem

    func makeNSView(context: Context) -> BrowserItemMenuHost { BrowserItemMenuHost(state: state, item: item) }
    func updateNSView(_ view: BrowserItemMenuHost, context: Context) { view.state = state; view.item = item }
    static func dismantleNSView(_ view: BrowserItemMenuHost, coordinator: ()) { view.stopMonitoring() }
}

@MainActor
private final class BrowserItemMenuHost: NSView {
    var state: FileBrowserState
    var item: BrowserItem
    private var eventMonitor: Any?

    init(state: FileBrowserState, item: BrowserItem) {
        self.state = state
        self.item = item
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown]) { [weak self] event in
            let consumed = MainActor.assumeIsolated {
                guard let self, event.window === self.window,
                      event.type == .rightMouseDown || event.modifierFlags.contains(.control),
                      self.convert(self.visibleRect.intersection(self.bounds), to: nil).contains(event.locationInWindow) else { return false }
                let menu = BrowserNativeContextMenu.make(state: self.state, item: self.item)
                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return true
            }
            return consumed ? nil : event
        }
    }

    func stopMonitoring() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
    }

}

@MainActor
enum BrowserNativeContextMenu {
    static func make(state: FileBrowserState, item: BrowserItem) -> NSMenu {
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
            menu.addItem(ClosureMenuItem(title: state.contextualTitle(action, items: items), systemImage: action.systemImage,
                                        isEnabled: !state.archiveOperationInProgress) {
                Task { state.contextualFeedbackMessage = await state.performContextualAction(action, items: items) }
            })
        }
        func applications(always: Bool) {
            let title: String.LocalizationValue = always ? "Always open with" : "Open with"
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
        menu.addItem(.separator())
        add("Share", "square.and.arrow.up", enabled: items.contains { !$0.isContainer }) { selectTargets(); state.shareItems() }
        add("Copy", "doc.on.doc", enabled: items.allSatisfy { $0.localURL != nil }) { selectTargets(); state.copySelectionToPasteboard() }
        add("Copy pathname", "document.on.clipboard", enabled: items.allSatisfy { $0.localURL != nil }, alternate: true) {
            selectTargets(); state.copySelectionPathnamesToPasteboard()
        }
        menu.addItem(.separator())
        add("Get Info", "info.circle") { selectTargets(); state.showGetInfo() }
        add("Quick Look", "eye") { selectTargets(); state.openQuickLook() }
        add("Slideshow", "play.rectangle", alternate: true) { selectTargets(); state.openQuickLook(slideshow: true) }
        menu.addItem(.separator())
        FinderTagQuickMenu.append(to: menu, state: state, items: items)
        if item.localURL != nil {
            menu.addItem(.separator())
            add("Rename", "pencil") { state.select(item); state.beginRenaming(item) }
            add("Duplicate", "plus.square.on.square") { selectTargets(); state.duplicateSelectedFiles() }
            add("Make Alias", "link") { state.select(item); state.makeAliasesForSelection() }
            add("Move to Trash", "trash") { state.select(item); state.moveSelectionToTrash() }
            add("Delete Immediately…", "trash.slash", alternate: true) { state.select(item); state.requestPermanentDeletion() }
        }
        return menu
    }
}
