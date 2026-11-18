import AppKit
import Testing
@testable import Zforge

/// Offscreen characterization of the browser's native menus: the toolbar More (`•••`)
/// menu, the menu of a right-click on a blank area, and an item's context menu. The
/// real right-click gesture and hover stay in the UI suite; these tests build the same
/// `NSMenu`s for the same selections and compare what the user would read and choose.
@Suite("Browser menu parity")
@MainActor
struct BrowserMenuParityTests {
    private static let archiveActions = [
        "Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate", "Add to Archive…"
    ]

    @Test("A blank-area right-click shows the toolbar More menu for every selection in every view mode")
    func blankAreaMenuMatchesMoreMenu() async throws {
        var reference: [String: [String]] = [:]
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            for selection in BrowserMenuFixture.Selection.allCases {
                try await fixture.select(selection)
                let context = "\(mode), \(selection)"
                let more = fixture.moreMenu()
                let blank = fixture.blankAreaMenu()
                #expect(signature(blank) == signature(more), "\(context)")
                // Finder's Action menu and blank-area menu start with New Folder (ZF-85, D-105).
                #expect(more.items.first?.title == "New Folder", "\(context)")
                #expect(more.items.dropFirst().first?.isSeparatorItem == true, "\(context)")
                let open = try #require(more.items.dropFirst(2).first, "\(context)")
                #expect(open.title == "Open", "\(context)")
                #expect(open.isEnabled == (selection != .none), "\(context)")
                #expect(!more.items.contains { $0.title == "Open with" }, "Only an item's menu offers Open with: \(context)")
                // The menus read the selection, never the view mode.
                if let expected = reference[selection.rawValue] {
                    #expect(signature(more) == expected, "\(context)")
                } else {
                    reference[selection.rawValue] = signature(more)
                }
            }
        }
        #expect(reference.count == BrowserMenuFixture.Selection.allCases.count)
    }

    @Test("New Folder leads the More, blank-area and overflow menus with Finder's symbol, enabled where File ▸ New Folder is, and stays out of item menus")
    func newFolderLeadsSharedMenus() async throws {
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            for selection in BrowserMenuFixture.Selection.allCases {
                let target = try await fixture.select(selection)
                let context = "\(mode), \(selection)"
                // The fixture lists Recents, then an archive's contents: neither is a folder that can receive a
                // new folder, so New Folder is disabled, like File ▸ New Folder. The enabled case in a real
                // folder is covered by FolderWithSelectionFlowTests.contextMenuNewFolder.
                if selection == .archiveEntry {
                    guard case .archive = fixture.state.location else {
                        Issue.record("Expected the archive's contents: \(context)"); continue
                    }
                } else {
                    #expect(fixture.state.location == .recents, "\(context)")
                }
                let enabled = false
                #expect(fixture.state.canModifyCurrentDirectory == enabled, "File ▸ New Folder enablement: \(context)")
                for (name, menu) in [("More", fixture.moreMenu()), ("blank area", fixture.blankAreaMenu()),
                                     ("overflow", fixture.overflowMenu())] {
                    let titles = menu.items.map { $0.isSeparatorItem ? "—" : $0.title }
                    let index = try #require(menu.items.firstIndex { $0.title == "New Folder" }, "\(name) menu, \(context): \(titles)")
                    let entry = menu.items[index]
                    #expect(menu.items.filter { $0.title == "New Folder" }.count == 1, "\(name) menu, \(context): \(titles)")
                    #expect(entry.isEnabled == enabled, "\(name) menu, \(context)")
                    #expect(!entry.isAlternate, "\(name) menu, \(context)")
                    #expect(entry.image?.isTemplate == true, "\(name) menu, \(context)")
                    #expect(entry.image?.accessibilityDescription == "New Folder", "\(name) menu, \(context)")
                    let expectedImage = try #require(NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil))
                    #expect(entry.image?.size == expectedImage.size, "\(name) menu, \(context)")
                    // New Folder heads the selection actions in its own group: nothing above it but the
                    // overflow's own additions, a separator below it, then Open.
                    #expect(index == 0 || menu.items[index - 1].isSeparatorItem, "\(name) menu, \(context): \(titles)")
                    #expect(menu.items[index + 1].isSeparatorItem, "\(name) menu, \(context): \(titles)")
                    #expect(menu.items[index + 2].title == "Open", "\(name) menu, \(context): \(titles)")
                }
                #expect(fixture.moreMenu().items.first?.title == "New Folder", "More menu, \(context)")
                // Finder's item menus have no New Folder: the item's menu stays as it was.
                if selection != .none {
                    #expect(!fixture.itemMenu(for: target).items.contains { $0.title == "New Folder" }, "item menu, \(context)")
                }
            }
        }
    }

    @Test("New Folder uses the app language in the shared menus")
    func newFolderIsLocalized() async throws {
        let fixture = try await BrowserMenuFixture(mode: .icons)
        defer { fixture.close() }
        fixture.state.preferences.language = .portugueseBrazil
        let entry = try #require(fixture.blankAreaMenu().items.first)
        #expect(entry.title == "Nova Pasta")
        #expect(entry.title == AppLocalization.string("New Folder", locale: fixture.state.preferences.language.locale))
    }

    @Test("A selected archive offers the same archive actions in the More menu and its context menu, without Compress")
    func archiveActionsMatch() async throws {
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            let archive = try await fixture.select(.archive)
            for (name, menu) in [("More", fixture.moreMenu()), ("context", fixture.itemMenu(for: archive))] {
                let titles = menu.items.map(\.title)
                for title in Self.archiveActions {
                    let item = menu.items.first { $0.title == title }
                    #expect(item?.isEnabled == true, "Missing \(title) from the \(name) menu in \(mode): \(titles)")
                }
                #expect(!titles.contains("Compress"), "\(name) menu in \(mode): \(titles)")
                #expect(!titles.contains("Remove from Archive…"), "\(name) menu in \(mode): \(titles)")
            }
        }
    }

    @Test("The overflow menu's archive action shows the toolbar button's symbol, outside and inside an archive")
    func overflowArchiveActionSymbol() async throws {
        let fixture = try await BrowserMenuFixture(mode: .list)
        defer { fixture.close() }
        for selection in [BrowserMenuFixture.Selection.none, .archiveEntry] {
            try await fixture.select(selection)
            if selection == .archiveEntry { fixture.state.selection = [] }
            let action = fixture.state.archiveToolbarAction
            #expect(action == (selection == .none ? .unavailableOutsideArchive : .unavailableInsideArchive))
            let item = try #require(fixture.overflowMenu().items.first { $0.title == action.title(locale: fixture.state.preferences.language.locale) },
                                    "\(selection)")
            let image = try #require(item.image, "\(selection)")
            let expected = try #require(MenuSymbolImage.image(for: action.symbol))
            #expect(image.isTemplate)
            #expect(image.size == expected.size, "\(selection)")
            #expect(Self.pixels(image) == Self.pixels(expected), "\(selection): \(action) draws another symbol")
            #expect(!item.isEnabled)
        }
    }

    private static func pixels(_ image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return NSBitmapImageRep(cgImage: cgImage).tiffRepresentation
    }

    @Test("Remove from Archive… is offered by the More menu and an archive entry's context menu")
    func archiveRemovalIsShared() async throws {
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            let entry = try await fixture.select(.archiveEntry)
            for (name, menu) in [("More", fixture.moreMenu()), ("context", fixture.itemMenu(for: entry))] {
                let removal = menu.items.first { $0.title == "Remove from Archive…" }
                #expect(removal?.isEnabled == true, "\(name) menu in \(mode): \(menu.items.map(\.title))")
            }
        }
        // Outside an archive neither menu offers removal.
        let fixture = try await BrowserMenuFixture(mode: .list)
        defer { fixture.close() }
        let file = try await fixture.select(.file)
        #expect(!fixture.moreMenu().items.contains { $0.title == "Remove from Archive…" })
        #expect(!fixture.itemMenu(for: file).items.contains { $0.title == "Remove from Archive…" })
    }

    @Test("A file's context menu offers Open with, Edit Tags and a circle for each of the seven fixture tags, marking its own, selected or not",
          arguments: [true, false])
    func itemMenuOffersTags(selected: Bool) async throws {
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            let file = try await fixture.select(selected ? .file : .none)
            let selection = fixture.state.selection
            let context = "\(mode), selected: \(selected)"
            let menu = fixture.itemMenu(for: file)
            #expect(menu.items.first { $0.title == "Open with" }?.isEnabled == true, "\(context)")
            try expectTagRow(in: menu, named: "Welcome.txt", context: context)
            // Building or reading the menu never changes the selection the toolbar acts on.
            #expect(fixture.state.selection == selection, "\(context)")
            #expect(fixture.state.canEditTags == selected, "\(context)")
        }
    }

    @Test("The More menu and the blank-area menu tag the selection with the same circles for the seven fixture tags")
    func moreMenuOffersTags() async throws {
        for mode in BrowserViewMode.allCases {
            let fixture = try await BrowserMenuFixture(mode: mode)
            defer { fixture.close() }
            try await fixture.select(.file)
            try expectTagRow(in: fixture.moreMenu(), named: "Welcome.txt", context: "More, \(mode)")
            try expectTagRow(in: fixture.blankAreaMenu(), named: "Welcome.txt", context: "blank area, \(mode)")
        }
    }

    private func expectTagRow(in menu: NSMenu, named name: String, context: String) throws {
        let row = try #require(menu.items.first { $0.identifier?.rawValue == "quick-tags-\(name)" }?.view as? FinderTagQuickRowView,
                               "\(context): \(menu.items.map(\.title))")
        let buttons = row.buttons
        #expect(buttons.count == 7, "\(context)")
        #expect(buttons.map(\.finderTag.name) == ["Blue", "Gray", "Green", "Orange", "Purple", "Red", "Yellow"], "\(context)")
        #expect(buttons.allSatisfy { $0.isEnabled }, "\(context)")
        #expect(buttons.map { $0.accessibilityValue() as? String } == ["0", "0", "0", "0", "0", "1", "0"], "\(context)")
        #expect(buttons.first { $0.finderTag.name == "Red" }?.accessibilityIdentifier() == "quick-tag-Red", "\(context)")
        let editorIndex = try #require(menu.items.firstIndex { $0.identifier?.rawValue == "edit-tags" }, "\(context)")
        #expect(menu.items[editorIndex - 1].view === row, "Edit Tags follows the circles: \(context)")
        #expect(menu.items[editorIndex].title == "Edit Tags", "\(context)")
        #expect(menu.items[editorIndex].isEnabled, "\(context)")
    }

    /// Everything the user reads or chooses in a menu, in order.
    private func signature(_ menu: NSMenu) -> [String] {
        menu.items.map { item in
            if item.isSeparatorItem { return "—" }
            var entry = "\(item.title)|enabled:\(item.isEnabled)|alternate:\(item.isAlternate)|\(item.identifier?.rawValue ?? "")"
            if let row = item.view as? FinderTagQuickRowView {
                entry += "|" + row.buttons.map { "\($0.finderTag.name):\($0.accessibilityValue() as? String ?? "?"):\($0.isEnabled)" }
                    .joined(separator: ",")
            }
            if let submenu = item.submenu { entry += "|[" + signature(submenu).joined(separator: "; ") + "]" }
            return entry
        }
    }
}

/// A browser window's state over the UI fixture folder, with the UI fixture's isolated
/// quick-tag favorites, so no test reads the Mac's own files, tags or preferences.
@MainActor
private final class BrowserMenuFixture {
    enum Selection: String, CaseIterable {
        case none, file, archive, archiveEntry
    }

    let state: FileBrowserState
    private let defaults: UserDefaults
    private let suite: String
    private let catalog = FinderTagCatalog.uiFixture()

    init(mode: BrowserViewMode) async throws {
        suite = "ZforgeTestSuite.BrowserMenuParity-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = mode
        state = FileBrowserState(preferences: preferences, fileSystem: UIFixtureFileSystemService(),
            recentItems: UIFixtureRecentItemsService(), grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine())
        await state.start()
        #expect(state.viewMode == mode)
    }

    /// Selects one item for the scenario and returns the item a right-click would target.
    @discardableResult
    func select(_ selection: Selection) async throws -> BrowserItem {
        if selection == .archiveEntry {
            let archive = try #require(state.items.first { $0.name == "Sample.zip" })
            await state.open(archive)
            let entry = try #require(state.items.first { $0.name == "Inside.txt" }, "\(state.items.map(\.name))")
            state.select(entry)
            return entry
        }
        let name = selection == .archive ? "Sample.zip" : "Welcome.txt"
        let item = try #require(state.items.first { $0.name == name }, "\(state.items.map(\.name))")
        if selection == .none { state.selection = [] } else { state.select(item) }
        #expect(state.selectedItems.map(\.name) == (selection == .none ? [] : [name]))
        return item
    }

    /// The menu of the expanded toolbar's More button (`ContentView.showToolbarActionsMenu`).
    func moreMenu() -> NSMenu {
        BrowserActionsMenu.make(state: state, menu: NSMenu(), includesViewSelector: false, includesArchiveAction: false,
                                includesShareAction: false, showToast: { _ in }, restoreContentFocus: {},
                                catalogTags: catalog.tags)
    }

    /// The menu of the compact toolbar's overflow button, which holds the archive action below 840 pt.
    func overflowMenu() -> NSMenu {
        BrowserActionsMenu.make(state: state, menu: NSMenu(), includesViewSelector: false, includesArchiveAction: true,
                                includesShareAction: true, showToast: { _ in }, restoreContentFocus: {},
                                catalogTags: catalog.tags)
    }

    /// The menu a right-click on a blank area presents (`BrowserItemMenuHost` without an item).
    func blankAreaMenu() -> NSMenu {
        BrowserActionsMenu.make(state: state, showToast: { _ in }, catalogTags: catalog.tags)
    }

    func itemMenu(for item: BrowserItem) -> NSMenu {
        BrowserNativeContextMenu.make(state: state, item: item, catalogTags: catalog.tags)
    }

    func close() {
        catalog.stop()
        state.close()
        defaults.removeTestSuite(named: suite)
    }
}
