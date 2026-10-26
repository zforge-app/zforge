import AppKit

@MainActor
enum FinderTagQuickMenu {
    static func tags(for items: [BrowserItem], catalogTags: [FinderTag] = FinderTagCatalog.shared.tags) -> [FinderTag] {
        var tags = catalogTags
        for item in items {
            for name in item.tags where !tags.contains(where: { $0.name == name }) {
                tags.append(FinderTag(name: name, colorIndex: item.tagColorIndexes[name] ?? 0))
            }
        }
        tags.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return FinderTagPresentation.quickTags(tags)
    }

    static func append(to menu: NSMenu, state: FileBrowserState, items: [BrowserItem],
                       catalogTags: [FinderTag] = FinderTagCatalog.shared.tags) {
        let enabled = !items.isEmpty && items.allSatisfy { $0.localURL != nil } && !state.archiveOperationInProgress
        let tags = tags(for: items, catalogTags: catalogTags)
        let row = NSMenuItem(title: AppLocalization.string("Tags", locale: state.preferences.language.locale), action: nil, keyEquivalent: "")
        row.identifier = NSUserInterfaceItemIdentifier("quick-tags-" + items.map(\.name).joined(separator: ","))
        let editorTitle = AppLocalization.string("Edit Tags", locale: state.preferences.language.locale)
        let editor = ClosureMenuItem(title: editorTitle, systemImage: "tag", isEnabled: enabled) { state.editTags(items: items) }
        editor.identifier = NSUserInterfaceItemIdentifier("edit-tags")
        if #available(macOS 27.0, *) { editor.preferredImageVisibility = .visible }
        // While a circle is hovered the editor item names its tag, as Finder does.
        let view = FinderTagQuickRowView(frame: NSRect(x: 0, y: 0, width: 246, height: 36)) { [weak editor] tag in
            editor?.title = tag?.name ?? editorTitle
        }
        view.autoresizingMask = [.width]
        for (index, tag) in tags.enumerated() {
            let count = items.filter { $0.tags.contains(tag.name) }.count
            let button = FinderTagQuickButton(tag: tag, applied: count == items.count && !items.isEmpty,
                                              mixed: count > 0 && count < items.count) { [weak menu] in
                // Close the native tracking loop before mutating files or opening an error alert.
                menu?.cancelTracking()
                Task {
                    let allApplied = count == items.count
                    let failure = await state.applyTags(additions: allApplied ? [:] : [tag.name: tag.colorIndex],
                                                        removals: allApplied ? [tag.name] : [], items: items)
                    if let failure { state.error = .unavailable(failure) }
                }
            }
            button.frame = NSRect(x: 18 + CGFloat(index) * 30, y: 7, width: 22, height: 22)
            button.isEnabled = enabled
            view.addSubview(button)
        }
        row.view = view
        menu.addItem(row)
        menu.addItem(editor)
    }
}

/// Owns hover for the whole circle row. A single tracking area that resolves the
/// circle under the pointer on every event cannot strand a hover symbol, unlike
/// per-circle areas, whose exit events are lost when the pointer crosses them quickly.
@MainActor
final class FinderTagQuickRowView: NSView {
    private let hoverChanged: (FinderTag?) -> Void
    private var hoverTracking: NSTrackingArea?
    /// Last circle named by the editor item; kept across the gaps between circles
    /// so the title does not flicker, and cleared when the pointer leaves the row.
    private var namedTag: FinderTag?

    init(frame: NSRect, hoverChanged: @escaping (FinderTag?) -> Void) {
        self.hoverChanged = hoverChanged
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { nil }

    var buttons: [FinderTagQuickButton] { subviews.compactMap { $0 as? FinderTagQuickButton } }

    override func updateTrackingAreas() {
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                                      owner: self)
        hoverTracking = tracking
        addTrackingArea(tracking)
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) { updateHover(at: convert(event.locationInWindow, from: nil)) }
    override func mouseMoved(with event: NSEvent) { updateHover(at: convert(event.locationInWindow, from: nil)) }
    override func mouseExited(with event: NSEvent) { updateHover(at: nil) }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { updateHover(at: nil) }
        super.viewWillMove(toWindow: newWindow)
    }

    /// Marks at most one circle as hovered; `nil` means the pointer left the row.
    func updateHover(at point: NSPoint?) {
        let target = point.flatMap { point in buttons.first { $0.isEnabled && $0.frame.contains(point) } }
        for button in buttons { button.isHovered = button === target }
        let named = point == nil ? nil : target?.finderTag ?? namedTag
        guard named != namedTag else { return }
        namedTag = named
        hoverChanged(named)
    }
}

@MainActor
final class FinderTagQuickButton: NSButton {
    let finderTag: FinderTag
    let applied: Bool
    let mixed: Bool
    private let handler: () -> Void
    /// Set by `FinderTagQuickRowView`, the single owner of the row's hover state.
    var isHovered = false {
        didSet { if isHovered != oldValue { needsDisplay = true } }
    }

    init(tag: FinderTag, applied: Bool, mixed: Bool, handler: @escaping () -> Void) {
        self.finderTag = tag
        self.applied = applied
        self.mixed = mixed
        self.handler = handler
        super.init(frame: .zero)
        setButtonType(.momentaryChange)
        allowsMixedState = true
        state = applied ? .on : mixed ? .mixed : .off
        isBordered = false
        title = ""
        target = self
        action = #selector(toggleTag)
        setAccessibilityLabel(tag.name)
        setAccessibilityIdentifier("quick-tag-\(tag.name)")
    }

    required init?(coder: NSCoder) { nil }

    override func accessibilityValue() -> Any? { applied ? "1" : mixed ? "mixed" : "0" }

    var symbolName: String? {
        if isHovered { return applied ? "xmark" : "plus" }
        return applied ? "checkmark" : mixed ? "minus" : nil
    }

    override func draw(_ dirtyRect: NSRect) {
        let colors: [NSColor] = [.clear, .systemGray, .systemGreen, .systemPurple, .systemBlue, .systemYellow, .systemRed, .systemOrange]
        let index = min(7, max(0, finderTag.colorIndex))
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        colors[index].withAlphaComponent(isEnabled ? 1 : 0.35).setFill()
        circle.fill()
        (index == 0 ? NSColor.secondaryLabelColor : colors[index].blended(withFraction: 0.2, of: .black) ?? colors[index]).setStroke()
        circle.lineWidth = 1
        circle.stroke()
        if let symbolName, isEnabled,
           let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 10, weight: .bold)) {
            let ink: NSColor = [0, 5, 7].contains(index) ? .labelColor : .white
            let symbol = image.copy() as! NSImage
            symbol.isTemplate = false
            symbol.lockFocus()
            ink.setFill()
            NSRect(origin: .zero, size: symbol.size).fill(using: .sourceAtop)
            symbol.unlockFocus()
            symbol.draw(in: bounds.insetBy(dx: 5, dy: 5))
        }
    }

    @objc private func toggleTag() { handler() }
}
