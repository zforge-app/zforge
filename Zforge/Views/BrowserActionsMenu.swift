import AppKit

@MainActor
enum BrowserActionsMenu {
    static func make(
        state browser: FileBrowserState,
        menu: NSMenu = NSMenu(),
        includesViewSelector: Bool = false,
        includesArchiveAction: Bool = false,
        includesShareAction: Bool = false,
        showToast: @escaping @MainActor (String) -> Void,
        restoreContentFocus: @escaping @MainActor () -> Void = {}
    ) -> NSMenu {
        let locale = browser.preferences.language.locale
        menu.autoenablesItems = false
        func addItem(
            _ title: String.LocalizationValue,
            systemImage: String,
            isEnabled: Bool,
            handler: @escaping @MainActor () -> Void
        ) {
            menu.addItem(
                ClosureMenuItem(
                    title: AppLocalization.string(title, locale: locale),
                    systemImage: systemImage,
                    isEnabled: isEnabled,
                    handler: handler
                )
            )
        }

        if includesViewSelector {
            let viewItem = NSMenuItem(
                title: AppLocalization.string("View", locale: locale),
                action: nil,
                keyEquivalent: ""
            )
            viewItem.image = NSImage(
                systemSymbolName: browser.viewMode.systemImage,
                accessibilityDescription: viewItem.title
            )
            let viewMenu = NSMenu(title: viewItem.title)
            for mode in BrowserViewMode.allCases {
                let modeItem = ClosureMenuItem(
                    title: mode.title(locale: locale),
                    systemImage: mode.systemImage,
                    isEnabled: true
                ) {
                    browser.viewMode = mode
                }
                modeItem.state = mode == browser.viewMode ? .on : .off
                viewMenu.addItem(modeItem)
            }
            viewItem.submenu = viewMenu
            menu.addItem(viewItem)
            menu.addItem(.separator())
        }

        if includesArchiveAction && browser.selectedItems.isEmpty {
            let archiveAction = browser.archiveToolbarAction
            menu.addItem(
                ClosureMenuItem(
                    title: archiveAction.title(locale: locale),
                    systemImage: "archivebox",
                    isEnabled: archiveAction.isEnabled,
                    handler: {
                        Task {
                            if let message = await browser.performArchiveToolbarAction() { showToast(message) }
                            restoreContentFocus()
                        }
                    }
                )
            )
        }
        if includesShareAction {
            addItem("Share", systemImage: "square.and.arrow.up", isEnabled: browser.selectedItems.contains { !$0.isContainer }) {
                browser.shareItems()
            }
        }
        if (includesArchiveAction && browser.selectedItems.isEmpty) || includesShareAction {
            menu.addItem(.separator())
        }

        let selected = browser.selectedItems
        addItem("Open", systemImage: "arrow.up.forward.app", isEnabled: !selected.isEmpty) {
            Task { _ = await browser.performContextualAction(.open, items: selected) }
        }
        for action in browser.contextualActions(for: selected) where action != .open {
            menu.addItem(
                ClosureMenuItem(
                    title: browser.contextualTitle(action, items: selected),
                    systemImage: action.systemImage,
                    isEnabled: !browser.archiveOperationInProgress
                ) {
                    Task {
                        if let message = await browser.performContextualAction(action, items: selected) {
                            showToast(message)
                        }
                        restoreContentFocus()
                    }
                }
            )
        }
        addItem("Quick Look", systemImage: "eye", isEnabled: browser.primarySelection != nil) {
            browser.openQuickLook()
        }
        addItem("Get Info", systemImage: "info.circle", isEnabled: browser.primarySelection != nil) {
            browser.showGetInfo()
        }
        menu.addItem(.separator())
        FinderTagQuickMenu.append(to: menu, state: browser, items: selected)
        addItem("Rename", systemImage: "pencil", isEnabled: browser.canRenameSelection) {
            browser.beginRenamingSelectedItem()
        }
        addItem("Duplicate", systemImage: "plus.square.on.square", isEnabled: browser.hasLocalSelection) {
            browser.duplicateSelectedFiles()
        }

        return menu
    }
}

extension ArchiveToolbarAction {
    var titleKey: String.LocalizationValue {
        switch self {
        case .extractAll: "Extract All"
        case .extractSelected, .unavailableInsideArchive: "Extract Selected"
        case .compress, .unavailableOutsideArchive: "Compress Selected"
        }
    }

    var title: String {
        AppLocalization.string(titleKey)
    }

    func title(locale: Locale) -> String {
        AppLocalization.string(titleKey, locale: locale)
    }

    var feedbackMessage: String {
        switch self {
        case .extractAll: AppLocalization.string("Extract all selected archives.")
        case .extractSelected: AppLocalization.string("Extract selected items.")
        case .compress: AppLocalization.string("Compress selected items.")
        case .unavailableInsideArchive, .unavailableOutsideArchive: title
        }
    }
}
