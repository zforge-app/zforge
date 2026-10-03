import AppKit

@MainActor
enum FinderTagQuickMenu {
    static func tags(for items: [BrowserItem]) -> [FinderTag] {
        var tags = FinderTagCatalog.shared.tags
        for item in items {
            for name in item.tags where !tags.contains(where: { $0.name == name }) {
                tags.append(FinderTag(name: name, colorIndex: item.tagColorIndexes[name] ?? 0))
            }
        }
        tags.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return FinderTagPresentation.quickTags(tags)
    }

    static func append(to menu: NSMenu, state: FileBrowserState, items: [BrowserItem]) {
        let enabled = !items.isEmpty && items.allSatisfy { $0.localURL != nil } && !state.archiveOperationInProgress
        let tags = tags(for: items)
        let row = NSMenuItem(title: AppLocalization.string("Tags", locale: state.preferences.language.locale), action: nil, keyEquivalent: "")
        row.identifier = NSUserInterfaceItemIdentifier("quick-tags-" + items.map(\.name).joined(separator: ","))
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 246, height: 36))
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
        let editor = ClosureMenuItem(title: AppLocalization.string("Edit Tags", locale: state.preferences.language.locale),
                                     systemImage: "tag", isEnabled: enabled) { state.editTags(items: items) }
        if #available(macOS 27.0, *) { editor.preferredImageVisibility = .visible }
        menu.addItem(editor)
    }
}

@MainActor
final class FinderTagQuickButton: NSButton {
    let finderTag: FinderTag
    let applied: Bool
    let mixed: Bool
    private let handler: () -> Void
    private var hovered = false
    private var hoverTracking: NSTrackingArea?

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
        toolTip = tag.name
        setAccessibilityLabel(tag.name)
        setAccessibilityIdentifier("quick-tag-\(tag.name)")

    }

    required init?(coder: NSCoder) { nil }

    override func accessibilityValue() -> Any? { applied ? "1" : mixed ? "mixed" : "0" }

    var symbolName: String? {
        if hovered { return applied ? "xmark" : "plus" }
        return applied ? "checkmark" : mixed ? "minus" : nil
    }

    override func updateTrackingAreas() {
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let tracking = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        hoverTracking = tracking
        addTrackingArea(tracking)
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) { hovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovered = false; needsDisplay = true }

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
