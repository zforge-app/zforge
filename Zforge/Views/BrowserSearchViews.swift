import AppKit
import SwiftUI

/// The toolbar's trailing search button, in its own capsule as in Finder: a magnifying
/// glass that opens the search field (`BrowserToolbarSearchField`).
///
/// The button and the field are two toolbar items, and the toolbar shows one of them
/// (ZF-88): `NSToolbar` measures a SwiftUI item when it is presented, so a single item
/// that changed from the button to the 200 pt field kept the button's width and drew the
/// field over its neighbours. Switching items is instant, as Finder switches its search.
struct BrowserToolbarSearchButton: View {
    @Bindable var state: FileBrowserState

    var body: some View {
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
    }
}

/// The toolbar's search field: shown while a search is in use and, with room to spare,
/// at rest without the keyboard focus (ZF-88).
struct BrowserToolbarSearchField: View {
    static let fieldWidth: CGFloat = 200
    /// The field's width when the toolbar has no room for the full one: only a sidebar dragged
    /// near its maximum while a search is open (ZF-88).
    static let compactFieldWidth: CGFloat = 140
    /// The magnifying glass's inset from the capsule's leading edge, as in Finder's field.
    static let leadingInset: CGFloat = 10
    static let trailingInset: CGFloat = 8

    @Bindable var state: FileBrowserState
    var isCompact = false
    var restoreContentFocus: () -> Void = {}

    var body: some View { field }

    private var field: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
                .onTapGesture { state.beginSearch() }
                .accessibilityHidden(true)
            ToolbarSearchTextField(
                text: state.searchText,
                placeholder: AppLocalization.string("Search", locale: state.preferences.language.locale),
                focusRequest: state.searchFieldFocusRequest,
                // A field opened for a search takes the focus; a field shown at rest leaves it alone.
                focusesOnAppear: state.isSearchPresented,
                onTextChange: { text in
                    state.activateSearchField()
                    state.updateSearchText(text)
                },
                onSubmit: { state.submitSearch() },
                onCancel: {
                    Task {
                        await state.cancelSearch()
                        restoreContentFocus()
                    }
                },
                onFocusChange: { focused in
                    state.searchFieldHasFocus = focused
                    if focused {
                        // Clicking into the field shown at rest puts it in use, as ⌘F does.
                        state.activateSearchField()
                    } else {
                        state.dismissSearchFieldIfIdle()
                    }
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
        .padding(.leading, Self.leadingInset)
        .padding(.trailing, Self.trailingInset)
        .frame(width: isCompact ? Self.compactFieldWidth : Self.fieldWidth, height: 22)
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
    /// A new value moves the keyboard focus into the field.
    let focusRequest: Int
    /// Whether the field takes the keyboard focus when it appears.
    let focusesOnAppear: Bool
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
        if focusesOnAppear { field.requestFocus() }
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
    /// The field's editing ended and the blur is reported at the next turn of the run loop.
    private var pendingBlur = false
    /// The field took the keyboard focus and has not reported losing it.
    private var hasFocus = false
    /// The field left its window after its editing ended: `NSToolbar` is moving its capsule.
    private var isRelocating = false
    /// The responder that had the keyboard focus before the field, normally the browser content.
    private weak var previousResponder: NSResponder?

    /// Takes the keyboard focus now, or as soon as the toolbar shows the field. ⌘F can ask while
    /// the field's toolbar item is still hidden, just before the toolbar shows it (ZF-88: the
    /// search then opened without the focus), so a request that cannot be met is kept and met
    /// when the field is shown or on one of the next turns of the run loop.
    func requestFocus() {
        guard let window, !isHiddenOrHasHiddenAncestor else {
            keepFocusRequest()
            return
        }
        guard currentEditor() == nil else {
            focusesInWindow = false
            return
        }
        if window.makeFirstResponder(self), currentEditor() != nil {
            focusesInWindow = false
        } else {
            keepFocusRequest()
        }
    }

    private var focusRetries = 0

    private func keepFocusRequest() {
        if !focusesInWindow { focusRetries = 0 }
        focusesInWindow = true
        guard focusRetries < 10 else { return }
        focusRetries += 1
        DispatchQueue.main.async { [weak self] in
            guard let self, self.focusesInWindow, self.window != nil else { return }
            self.requestFocus()
        }
    }

    override func viewDidUnhide() {
        super.viewDidUnhide()
        if focusesInWindow { requestFocus() }
    }

    /// When a stage switch re-tiles the toolbar, `NSToolbar` removes the glass capsule around the
    /// field and adds it back in the same layout pass; removing it ends the field's editing (ZF-88:
    /// an empty search then closed right after ⌘F). An editing that ends because the field leaves
    /// its window and comes back keeps the keyboard focus; any other blur is reported.
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        // SwiftUI can also take the field out of its window while it edits without ending the
        // editing first (the toolbar item's content is re-hosted): that is a move as well.
        if newWindow == nil, !isRelocating, pendingBlur || hasFocus {
            isRelocating = true
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRelocating, self.window == nil else { return }
                self.isRelocating = false
                self.pendingBlur = false
                self.hasFocus = false
                self.onFocusChange(false)
            }
        }
        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        if isRelocating {
            isRelocating = false
            pendingBlur = false
            if currentEditor() == nil { window.makeFirstResponder(self) }
        } else if focusesInWindow {
            requestFocus()
        }
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
        if became {
            hasFocus = true
            onFocusChange(true)
        }
        return became
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        pendingBlur = true
        DispatchQueue.main.async { [weak self] in
            guard let self, self.pendingBlur else { return }
            self.pendingBlur = false
            self.isRelocating = false
            // The field may have taken the focus again meanwhile (⌘F right after a re-tiling).
            guard self.currentEditor() == nil else { return }
            self.hasFocus = false
            self.onFocusChange(false)
        }
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
