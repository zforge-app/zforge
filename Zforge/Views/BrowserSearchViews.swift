import SwiftUI

/// The toolbar's trailing search item, in its own capsule as in Finder: a
/// magnifying glass that expands into a search field.
struct BrowserToolbarSearchControl: View {
    static let fieldWidth: CGFloat = 200

    @Bindable var state: FileBrowserState
    var restoreContentFocus: () -> Void = {}
    @FocusState private var fieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if state.isSearchPresented {
                field
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
            } else {
                Button {
                    state.beginSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .regular))
                        .frame(width: 25, height: 18)
                        .accessibilityHidden(true)
                }
                .focusable(false)
                .help("Search")
                .accessibilityLabel("Search")
                .accessibilityIdentifier("toolbar-search")
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: state.isSearchPresented)
    }

    private var field: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search", text: Binding(get: { state.searchText }, set: { state.updateSearchText($0) }))
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onSubmit { state.submitSearch() }
                .onExitCommand {
                    Task {
                        await state.cancelSearch()
                        restoreContentFocus()
                    }
                }
                .accessibilityLabel("Search")
                .accessibilityIdentifier("toolbar-search-field")
            if !state.searchText.isEmpty {
                Button {
                    state.updateSearchText("")
                    fieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Clear Search")
                .accessibilityLabel("Clear Search")
                .accessibilityIdentifier("toolbar-search-clear")
            }
        }
        .padding(.horizontal, 4)
        .frame(width: Self.fieldWidth, height: 22)
        .task { fieldFocused = true }
        .onChange(of: state.searchFieldFocusRequest) { fieldFocused = true }
        .onChange(of: fieldFocused) { _, focused in
            state.searchFieldHasFocus = focused
            if !focused { state.dismissSearchFieldIfIdle() }
        }
        .onDisappear { state.searchFieldHasFocus = false }
    }
}

/// Finder's “Search: This Mac | “Folder”” bar, shown above the results.
struct BrowserSearchScopeBar: View {
    @Bindable var state: FileBrowserState
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 10) {
            Picker("search.scope.label", selection: Binding(
                get: { state.searchScope },
                set: { scope in Task { await state.setSearchScope(scope) } }
            )) {
                Text("This Mac")
                    .help("Searches the folders Zforge is allowed to open.")
                    .tag(BrowserSearchScope.thisMac)
                if let folder = state.currentFolderSearchName {
                    // The folder name in the app language's quotation marks, as in Finder.
                    Text(verbatim: (locale.quotationBeginDelimiter ?? "“") + folder + (locale.quotationEndDelimiter ?? "”"))
                        .tag(BrowserSearchScope.currentFolder)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier("search-scope")

            Spacer(minLength: 0)

            if state.searchResultsAreLimited {
                Text("Only the first \(BrowserSearchService.maximumResultCount) results are shown.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if state.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading…")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}
