import SwiftUI

/// The pending edits of the tag editor: tags to apply to every target and tags to remove from all of them.
/// Tags the user does not touch stay out of both sets, so applying preserves them per item.
struct FinderTagDraft: Equatable {
    /// How many of the targets carry a tag once the draft is applied.
    enum Coverage: Equatable { case none, some, all }

    private(set) var additions: [String: Int] = [:]
    private(set) var removals: Set<String> = []

    /// Catalog tags, the targets' own tags and the draft's new ones, by name. A target's color wins over
    /// the catalog's and a drafted color wins over both.
    func tags(for items: [BrowserItem], catalogTags: [FinderTag]) -> [FinderTag] {
        var colors = Dictionary(catalogTags.map { ($0.name, $0.colorIndex) }) { first, _ in first }
        for item in items {
            for name in item.tags { colors[name] = item.tagColorIndexes[name] ?? 0 }
        }
        colors.merge(additions) { _, new in new }
        return colors.map { FinderTag(name: $0.key, colorIndex: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func coverage(of name: String, in items: [BrowserItem]) -> Coverage {
        if removals.contains(name) { return .none }
        if additions[name] != nil { return .all }
        let count = items.filter { $0.tags.contains(name) }.count
        return count == 0 ? .none : count == items.count ? .all : .some
    }

    /// A tag on every target is removed from all of them; otherwise (none or some) it is applied to all.
    mutating func toggle(_ tag: FinderTag, in items: [BrowserItem]) {
        if coverage(of: tag.name, in: items) == .all {
            additions.removeValue(forKey: tag.name)
            removals.insert(tag.name)
        } else {
            removals.remove(tag.name)
            additions[tag.name] = tag.colorIndex
        }
    }

    /// Drafts a new tag applied to every target. Returns the stored name, or `nil` when the name is blank.
    @discardableResult
    mutating func create(name: String, colorIndex: Int) -> String? {
        let name = Self.normalizedName(name)
        guard !name.isEmpty else { return nil }
        additions[name] = colorIndex
        removals.remove(name)
        return name
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
    }
}

enum FinderTagEditorLayout {
    static let width: CGFloat = 460
    static let padding: CGFloat = 20
    static let rowHeight: CGFloat = 28
    static let listInset: CGFloat = 4
    /// Rows a list shows without scrolling. A longer list ends on half a row, which shows that it scrolls.
    static let visibleRows = 8
    static let emptyListHeight: CGFloat = 64
    static let swatchDiameter: CGFloat = 14
    static let swatchHitSize: CGFloat = 22
    /// No color first (the default), then Finder's menu order.
    static let colorOrder = [0, 6, 7, 5, 2, 4, 3, 1]

    static func listHeight(rows: Int) -> CGFloat {
        if rows == 0 { return emptyListHeight }
        if rows > visibleRows { return (CGFloat(visibleRows) + 0.5) * rowHeight + listInset }
        return CGFloat(rows) * rowHeight + listInset * 2
    }
}

struct FinderTagEditor: View {
    let request: TagEditingRequest
    let browser: FileBrowserState
    var catalogTags: [FinderTag] = FinderTagCatalog.shared.tags
    @Environment(\.dismiss) private var dismiss
    @State private var draft = FinderTagDraft()
    @State private var newName = ""
    @State private var newColor = 0
    @State private var saving = false
    @State private var failure: String?
    @State private var created: CreatedTag?

    /// The last tag created in this sheet; the serial makes creating the same name again a new value.
    private struct CreatedTag: Equatable {
        let name: String
        let serial: Int
    }

    private var tags: [FinderTag] { draft.tags(for: request.items, catalogTags: catalogTags) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Tags").font(.headline)
                Text("Changes apply to all selected items. Other tags are preserved.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            tagList
            VStack(alignment: .leading, spacing: 8) {
                Text("New Tag").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    TextField("Tag name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(createTag)
                    colorSwatches
                    Button("Add", action: createTag)
                        .disabled(FinderTagDraft.normalizedName(newName).isEmpty)
                }
            }
            if let failure {
                Text(failure).font(.callout).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                Spacer()
                if saving { ProgressView().controlSize(.small).padding(.trailing, 4) }
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Apply", action: apply).keyboardShortcut(.defaultAction)
            }
        }
        .padding(FinderTagEditorLayout.padding)
        .frame(width: FinderTagEditorLayout.width)
        .disabled(saving)
        .interactiveDismissDisabled(saving)
    }

    private var tagList: some View {
        let tags = tags
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tags) { tag in
                        FinderTagEditorRow(tag: tag, coverage: draft.coverage(of: tag.name, in: request.items)) {
                            draft.toggle(tag, in: request.items)
                        }
                    }
                }
                .padding(FinderTagEditorLayout.listInset)
            }
            .onChange(of: created) { _, created in
                // A created tag sorts by name and can land outside the visible rows.
                if let created { proxy.scrollTo(created.name, anchor: .center) }
            }
        }
        .overlay {
            if tags.isEmpty { Text("No tags").font(.subheadline).foregroundStyle(.secondary) }
        }
        .frame(height: FinderTagEditorLayout.listHeight(rows: tags.count))
        .background(Color.primary.opacity(0.04), in: shape)
        .overlay { shape.strokeBorder(Color.primary.opacity(0.1)) }
        .accessibilityIdentifier("tag-editor-list")
    }

    private var colorSwatches: some View {
        HStack(spacing: 0) {
            ForEach(FinderTagEditorLayout.colorOrder, id: \.self) { index in
                let name = LocalizedStringKey(FinderTagMetadata.colorName(index))
                Button { newColor = index } label: {
                    FinderTagDot(colorIndex: index, size: FinderTagEditorLayout.swatchDiameter)
                        .overlay {
                            // "No color" is a struck-through outline, so its selection ring does not read as a second outline.
                            if index == 0 {
                                Capsule().fill(.secondary)
                                    .frame(width: FinderTagEditorLayout.swatchDiameter - 1.3, height: 1.3)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                        .frame(width: FinderTagEditorLayout.swatchHitSize, height: FinderTagEditorLayout.swatchHitSize)
                        .overlay {
                            if newColor == index { Circle().strokeBorder(Color.primary.opacity(0.55), lineWidth: 1.5) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(name)
                .accessibilityLabel(name)
                .accessibilityAddTraits(newColor == index ? .isSelected : [])
                .accessibilityIdentifier("tag-color-\(index)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color")
    }

    private func createTag() {
        guard let name = draft.create(name: newName, colorIndex: newColor) else { return }
        created = CreatedTag(name: name, serial: (created?.serial ?? 0) + 1)
        newName = ""
    }

    private func apply() {
        createTag()
        saving = true
        Task {
            failure = await browser.applyTags(additions: draft.additions, removals: draft.removals, items: request.items)
            saving = false
            if failure == nil { dismiss() }
        }
    }
}

/// One tag of the editor's list: the whole row toggles the tag, a check marks it on every target and a
/// dash on only some of them.
private struct FinderTagEditorRow: View {
    let tag: FinderTag
    let coverage: FinderTagDraft.Coverage
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                FinderTagDot(colorIndex: tag.colorIndex, size: SidebarTagDot.size)
                Text(tag.name).lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 8)
                Image(systemName: coverage == .some ? "minus" : "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(coverage == .all ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .opacity(coverage == .none ? 0 : 1)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .frame(height: FinderTagEditorLayout.rowHeight)
            .background(Color.primary.opacity(hovered ? 0.07 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityValue(coverage == .all ? Text("All selected items")
                            : coverage == .some ? Text("Some selected items") : Text("No selected items"))
    }
}
