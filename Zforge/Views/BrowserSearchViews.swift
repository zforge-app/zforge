import AppKit
import SwiftUI

/// The toolbar's trailing search item, in its own capsule as in Finder: a
/// magnifying glass that expands into a search field.
struct BrowserToolbarSearchControl: View {
    static let fieldWidth: CGFloat = 200

    @Bindable var state: FileBrowserState
    var restoreContentFocus: () -> Void = {}
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
            ToolbarSearchTextField(
                text: state.searchText,
                placeholder: AppLocalization.string("Search", locale: state.preferences.language.locale),
                focusRequest: state.searchFieldFocusRequest,
                onTextChange: { state.updateSearchText($0) },
                onSubmit: { state.submitSearch() },
                onCancel: {
                    Task {
                        await state.cancelSearch()
                        restoreContentFocus()
                    }
                },
                onFocusChange: { focused in
                    state.searchFieldHasFocus = focused
                    if !focused { state.dismissSearchFieldIfIdle() }
                }
            )
            if !state.searchText.isEmpty {
                Button {
                    state.updateSearchText("")
                    state.focusSearchField()
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
        .onDisappear { state.searchFieldHasFocus = false }
    }
}

/// The text field of the expanded toolbar search.
///
/// Toolbar items are hosted outside the window's SwiftUI focus system: there a SwiftUI
/// `TextField` ignores `@FocusState` requests, never reports its focus and never receives
/// `onExitCommand`, so ⌘F could not focus it and Escape could not collapse it. This AppKit
/// field takes the first responder itself when asked (as soon as the toolbar puts it in a
/// window) and reports its focus, text, Return and Escape.
struct ToolbarSearchTextField: NSViewRepresentable {
    let text: String
    let placeholder: String
    /// A new value moves the keyboard focus into the field; the field also takes it when it appears.
    let focusRequest: Int
    let onTextChange: (String) -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let onFocusChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> ToolbarSearchNSTextField {
        let field = ToolbarSearchNSTextField()
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.lineBreakMode = .byTruncatingTail
        field.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.onFocusChange = { [coordinator = context.coordinator] focused in coordinator.parent.onFocusChange(focused) }
        field.setAccessibilityIdentifier("toolbar-search-field")
        field.stringValue = text
        context.coordinator.focusRequest = focusRequest
        field.requestFocus()
        return field
    }

    func updateNSView(_ field: ToolbarSearchNSTextField, context: Context) {
        context.coordinator.parent = self
        field.placeholderString = placeholder
        field.setAccessibilityLabel(placeholder)
        if field.stringValue != text { field.stringValue = text }
        if context.coordinator.focusRequest != focusRequest {
            context.coordinator.focusRequest = focusRequest
            field.requestFocus()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ToolbarSearchNSTextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 120, height: nsView.intrinsicContentSize.height)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ToolbarSearchTextField
        var focusRequest = 0

        init(_ parent: ToolbarSearchTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.onTextChange(field.stringValue)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                (control as? ToolbarSearchNSTextField)?.returnFocus()
                parent.onCancel()
                return true
            default:
                return false
            }
        }
    }
}

final class ToolbarSearchNSTextField: NSTextField {
    var onFocusChange: (Bool) -> Void = { _ in }
    private var focusesInWindow = false
    /// The responder that had the keyboard focus before the field, normally the browser content.
    private weak var previousResponder: NSResponder?

    /// Takes the keyboard focus now, or as soon as the toolbar puts the field in a window.
    func requestFocus() {
        guard let window else {
            focusesInWindow = true
            return
        }
        focusesInWindow = false
        if currentEditor() == nil { window.makeFirstResponder(self) }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if focusesInWindow, window != nil { requestFocus() }
    }

    /// Escape gives the keyboard focus back to where it was before the field took it. SwiftUI
    /// does not see the field take the focus, so its own focus value still names that place.
    func returnFocus() {
        guard let window else { return }
        if let view = previousResponder as? NSView, view.window === window {
            window.makeFirstResponder(view)
        } else {
            window.makeFirstResponder(nil)
        }
    }

    override func becomeFirstResponder() -> Bool {
        if let current = window?.firstResponder, current !== self, current !== currentEditor() {
            previousResponder = current
        }
        let became = super.becomeFirstResponder()
        if became { onFocusChange(true) }
        return became
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onFocusChange(false)
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
