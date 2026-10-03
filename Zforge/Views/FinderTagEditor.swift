import SwiftUI

struct FinderTagEditor: View {
    let request: TagEditingRequest
    let browser: FileBrowserState
    @Environment(\.dismiss) private var dismiss
    @State private var additions: [String: Int] = [:]
    @State private var removals: Set<String> = []
    @State private var newName = ""
    @State private var newColor = 0
    @State private var saving = false
    @State private var failure: String?

    private var tags: [FinderTag] {
        var colors = Dictionary(uniqueKeysWithValues: FinderTagCatalog.shared.tags.map { ($0.name, $0.colorIndex) })
        for item in request.items {
            for name in item.tags { colors[name] = item.tagColorIndexes[name] ?? 0 }
        }
        colors.merge(additions) { _, new in new }
        return colors.map { FinderTag(name: $0.key, colorIndex: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func count(_ name: String) -> Int {
        if removals.contains(name) { return 0 }
        if additions[name] != nil { return request.items.count }
        return request.items.filter { $0.tags.contains(name) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Tags").font(.headline)
            Text("Changes apply to all selected items. Other tags are preserved.")
                .font(.callout).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tags) { tag in
                        Button {
                            if count(tag.name) == request.items.count {
                                additions.removeValue(forKey: tag.name)
                                removals.insert(tag.name)
                            } else {
                                removals.remove(tag.name)
                                additions[tag.name] = tag.colorIndex
                            }
                        } label: {
                            HStack {
                                Image(systemName: count(tag.name) == request.items.count ? "checkmark.square.fill"
                                      : count(tag.name) > 0 ? "minus.square" : "square")
                                FinderTagDot(colorIndex: tag.colorIndex, size: 12)
                                Text(tag.name)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(count(tag.name) == request.items.count ? Text("All selected items")
                                            : count(tag.name) > 0 ? Text("Some selected items") : Text("No selected items"))
                    }
                }.padding(4)
            }.frame(height: 190)
            Divider()
            Text("New Tag").font(.subheadline)
            HStack {
                TextField("Tag name", text: $newName)
                    .onSubmit(createTag)
                Picker("Color", selection: $newColor) {
                    ForEach(0..<8) { index in
                        Text(LocalizedStringKey(FinderTagMetadata.colorName(index))).tag(index)
                    }
                }.frame(width: 150)
                Button("Add", action: createTag).disabled(validName.isEmpty)
            }
            if let failure { Text(failure).foregroundStyle(.red).font(.callout) }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Apply") {
                    createTag()
                    saving = true
                    Task {
                        failure = await browser.applyTags(additions: additions, removals: removals, items: request.items)
                        saving = false
                        if failure == nil { dismiss() }
                    }
                }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480)
        .disabled(saving)
        .interactiveDismissDisabled(saving)
    }

    private var validName: String { newName.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ") }
    private func createTag() {
        guard !validName.isEmpty else { return }
        additions[validName] = newColor
        removals.remove(validName)
        newName = ""
    }
}
