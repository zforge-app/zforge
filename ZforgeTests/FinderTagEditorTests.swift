import AppKit
import SwiftUI
import Testing
@testable import Zforge

@MainActor
@Suite("Finder tag editor (ZF-79)")
struct FinderTagEditorTests {
    private func item(_ name: String, tags: [String: Int] = [:]) -> BrowserItem {
        var item = BrowserItem(
            id: BrowserItemID(rawValue: "tag-editor:\(name)"), name: name,
            location: .fileSystem(URL(fileURLWithPath: "/ZforgeFixtures/\(name)")),
            isContainer: false, isDirectory: false, isPackage: false, isSymbolicLink: false, isHidden: false,
            isArchive: false, size: 1, packedSize: nil, creationDate: nil, modificationDate: nil, accessDate: nil,
            tags: tags.keys.sorted(), contentTypeIdentifier: nil, encrypted: false, checksum: nil, compressionMethod: nil)
        item.tagColorIndexes = tags
        return item
    }

    private let catalog = [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Archive", colorIndex: 1),
                           FinderTag(name: "Home", colorIndex: 0)]

    // MARK: Draft

    @Test("The list merges catalog, target and drafted tags by name; a target's color wins over the catalog's and a drafted color over both")
    func listMergesSources() {
        let items = [item("a.txt", tags: ["Work": 6, "Zebra": 2]), item("b.txt", tags: ["item 10": 0, "item 9": 3])]
        var draft = FinderTagDraft()
        #expect(draft.tags(for: items, catalogTags: catalog) == [
            FinderTag(name: "Archive", colorIndex: 1), FinderTag(name: "Home", colorIndex: 0),
            FinderTag(name: "item 9", colorIndex: 3), FinderTag(name: "item 10", colorIndex: 0),
            FinderTag(name: "Work", colorIndex: 6), FinderTag(name: "Zebra", colorIndex: 2),
        ])
        #expect(draft.create(name: "Home", colorIndex: 5) == "Home")
        #expect(draft.create(name: "Brand new", colorIndex: 7) == "Brand new")
        let drafted = draft.tags(for: items, catalogTags: catalog)
        #expect(drafted.map(\.name) == ["Archive", "Brand new", "Home", "item 9", "item 10", "Work", "Zebra"])
        #expect(drafted.first { $0.name == "Home" }?.colorIndex == 5)
        #expect(drafted.first { $0.name == "Brand new" }?.colorIndex == 7)
    }

    @Test("A catalog that repeats a name does not break the list")
    func duplicateCatalogNames() {
        let tags = FinderTagDraft().tags(for: [item("a.txt")],
            catalogTags: [FinderTag(name: "Work", colorIndex: 4), FinderTag(name: "Work", colorIndex: 2)])
        #expect(tags == [FinderTag(name: "Work", colorIndex: 4)])
    }

    @Test("Coverage tells a tag on every target from one on some or none of them")
    func coverage() {
        let items = [item("a.txt", tags: ["Shared": 1, "Partial": 2]), item("b.txt", tags: ["Shared": 1])]
        let draft = FinderTagDraft()
        #expect(draft.coverage(of: "Shared", in: items) == .all)
        #expect(draft.coverage(of: "Partial", in: items) == .some)
        #expect(draft.coverage(of: "Work", in: items) == .none)
        #expect(draft.coverage(of: "Shared", in: [items[0]]) == .all)
    }

    @Test("Toggling applies a partial or absent tag to every target and removes one that is on all; untouched tags stay out of the draft")
    func toggle() {
        let items = [item("a.txt", tags: ["Shared": 1, "Partial": 2, "Kept": 3]), item("b.txt", tags: ["Shared": 1])]
        var draft = FinderTagDraft()

        draft.toggle(FinderTag(name: "Partial", colorIndex: 2), in: items)
        #expect(draft.coverage(of: "Partial", in: items) == .all)
        #expect(draft.additions == ["Partial": 2])
        draft.toggle(FinderTag(name: "Partial", colorIndex: 2), in: items)
        #expect(draft.coverage(of: "Partial", in: items) == .none)
        #expect(draft.additions.isEmpty)
        #expect(draft.removals == ["Partial"])

        draft.toggle(FinderTag(name: "Shared", colorIndex: 1), in: items)
        #expect(draft.coverage(of: "Shared", in: items) == .none)
        draft.toggle(FinderTag(name: "Shared", colorIndex: 1), in: items)
        #expect(draft.coverage(of: "Shared", in: items) == .all)

        draft.toggle(FinderTag(name: "Work", colorIndex: 4), in: items)
        #expect(draft.coverage(of: "Work", in: items) == .all)

        #expect(draft.additions == ["Shared": 1, "Work": 4])
        #expect(draft.removals == ["Partial"])
        #expect(draft.coverage(of: "Kept", in: items) == .some)
    }

    @Test("Creating a tag trims its name, rejects a blank one and applies it to every target, also after it was removed")
    func create() {
        let items = [item("a.txt", tags: ["Old": 3]), item("b.txt")]
        var draft = FinderTagDraft()
        #expect(draft.create(name: "  \n ", colorIndex: 2) == nil)
        #expect(draft == FinderTagDraft())
        #expect(draft.create(name: "  Two\nlines ", colorIndex: 2) == "Two lines")
        #expect(draft.additions == ["Two lines": 2])
        #expect(draft.coverage(of: "Two lines", in: items) == .all)

        draft.toggle(FinderTag(name: "Old", colorIndex: 3), in: items)
        draft.toggle(FinderTag(name: "Old", colorIndex: 3), in: items)
        #expect(draft.removals == ["Old"])
        #expect(draft.create(name: "Old", colorIndex: 6) == "Old")
        #expect(draft.removals.isEmpty)
        #expect(draft.additions["Old"] == 6)
    }

    // MARK: Layout

    @Test("The list is as tall as its rows up to eight; a longer one ends on half a row and scrolls; an empty list keeps room for its message")
    func listHeight() {
        let row = FinderTagEditorLayout.rowHeight, inset = FinderTagEditorLayout.listInset * 2
        #expect(FinderTagEditorLayout.listHeight(rows: 0) == FinderTagEditorLayout.emptyListHeight)
        #expect(FinderTagEditorLayout.listHeight(rows: 1) == row + inset)
        #expect(FinderTagEditorLayout.listHeight(rows: 8) == 8 * row + inset)
        #expect(FinderTagEditorLayout.listHeight(rows: 9) == 8.5 * row + inset / 2)
        #expect(FinderTagEditorLayout.listHeight(rows: 200) == 8.5 * row + inset / 2)
    }

    @Test("The color choices are no color and Finder's seven colors, each once, at the tag dot scale")
    func colorChoices() {
        #expect(FinderTagEditorLayout.colorOrder.first == 0)
        #expect(FinderTagEditorLayout.colorOrder.sorted() == Array(0..<8))
        #expect(FinderTagEditorLayout.colorOrder.dropFirst().map(FinderTagMetadata.colorName)
                == ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray"])
        #expect(FinderTagEditorLayout.swatchHitSize >= FinderTagEditorLayout.swatchDiameter + 6)
    }

    @Test("The sheet keeps its width and grows only with the list, in the languages with the longest labels",
          arguments: [AppLanguagePreference.english, .german, .portugueseBrazil, .russian, .japanese])
    func sheetSize(language: AppLanguagePreference) throws {
        let (state, defaults, suite) = try browser()
        defer {
            state.close()
            defaults.removeTestSuite(named: suite)
        }
        func height(tags: Int) -> CGFloat {
            let editor = FinderTagEditor(request: TagEditingRequest(items: [item("a.txt")]), browser: state,
                                         catalogTags: (0..<tags).map { FinderTag(name: "Tag \($0)", colorIndex: $0 % 8) })
                .environment(\.locale, language.locale)
            let size = NSHostingView(rootView: editor).fittingSize
            #expect(size.width == FinderTagEditorLayout.width, "\(language) with \(tags) tags")
            return size.height
        }
        let three = height(tags: 3), eight = height(tags: 8), nine = height(tags: 9), many = height(tags: 40)
        #expect(eight - three == 5 * FinderTagEditorLayout.rowHeight, "\(language)")
        #expect(nine - eight == FinderTagEditorLayout.listHeight(rows: 9) - FinderTagEditorLayout.listHeight(rows: 8), "\(language)")
        #expect(many == nine, "\(language)")
        #expect(height(tags: 0) - three == FinderTagEditorLayout.emptyListHeight - FinderTagEditorLayout.listHeight(rows: 3), "\(language)")
    }

    // MARK: Snapshots

    @Test("Snapshot: the editor", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english, "mixed"),
        ("dark", .darkAqua, .english, "mixed"),
        ("dark-pt-BR", .darkAqua, .portugueseBrazil, "mixed"),
        ("light-de", .aqua, .german, "mixed"),
        ("light-scrolling", .aqua, .english, "scrolling"),
        ("dark-empty", .darkAqua, .english, "empty"),
    ])
    func editorSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference, scenario: String) throws {
        let (state, defaults, suite) = try browser()
        defer {
            state.close()
            defaults.removeTestSuite(named: suite)
        }
        let items: [BrowserItem], tags: [FinderTag]
        switch scenario {
        case "scrolling":
            items = [item("a.txt", tags: ["Tag 02": 2])]
            tags = (0..<14).map { FinderTag(name: String(format: "Tag %02d", $0), colorIndex: $0 % 8) }
        case "empty":
            items = [item("a.txt")]
            tags = []
        default:
            // Every Finder color and the uncolored outline; one tag on both targets, one on a single target.
            items = [item("a.txt", tags: ["Blue": 4, "Project": 0]), item("b.txt", tags: ["Blue": 4])]
            tags = zip(["Blue", "Gray", "Green", "Orange", "Project", "Purple", "Red", "Yellow"], [4, 1, 2, 7, 0, 3, 6, 5])
                .map { FinderTag(name: $0, colorIndex: $1) }
        }
        let editor = FinderTagEditor(request: TagEditingRequest(items: items), browser: state, catalogTags: tags)
            .environment(\.locale, language.locale)
            .background(Color(nsColor: .windowBackgroundColor))
        let host = NSHostingView(rootView: editor)
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        ZforgeSnapshot.assert(host, appearance: appearance, named: "editor-\(name)")
    }

    private func browser() throws -> (FileBrowserState, UserDefaults, String) {
        let suite = "ZforgeTestSuite.FinderTagEditor-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let state = FileBrowserState(preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(), recentItems: UIFixtureRecentItemsService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine())
        return (state, defaults, suite)
    }
}
