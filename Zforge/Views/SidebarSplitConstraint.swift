import AppKit
import SwiftUI

struct SidebarSplitConstraint: NSViewRepresentable {
    let minimumWidth: CGFloat
    let maximumWidth: CGFloat
    /// When set, the maximum follows the window: the width the detail column must keep.
    var minimumDetailWidth: CGFloat?

    init(minimumWidth: CGFloat, maximumWidth: CGFloat) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
    }

    /// A sidebar whose maximum leaves `minimumDetailWidth` to the detail column at every window
    /// width, tracked by the view itself so the SwiftUI sidebar is not re-evaluated on resize.
    init(minimumWidth: CGFloat, minimumDetailWidth: CGFloat) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = .greatestFiniteMagnitude
        self.minimumDetailWidth = minimumDetailWidth
    }

    func makeNSView(context: Context) -> SidebarSplitConstraintView {
        let view = SidebarSplitConstraintView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ nsView: SidebarSplitConstraintView, context: Context) {
        if let minimumDetailWidth {
            nsView.update(minimumWidth: minimumWidth, minimumDetailWidth: minimumDetailWidth)
        } else {
            nsView.update(minimumWidth: minimumWidth, maximumWidth: maximumWidth)
        }
    }
}

@MainActor
final class SidebarSplitConstraintView: NSView {
    private static let sidebarHoldingPriority = NSLayoutConstraint.Priority(
        rawValue: NSLayoutConstraint.Priority.defaultLow.rawValue + 1
    )

    private var minimumWidth: CGFloat = 0
    private var maximumWidth: CGFloat = 0
    private var minimumDetailWidth: CGFloat?
    private var updateTask: Task<Void, Never>?
    private var windowResizeObserver: NSObjectProtocol?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        scheduleConstraintUpdate()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observeWindowResizing()
        scheduleConstraintUpdate()
    }

    /// SwiftUI can reset the split item's limits after they were applied: the Settings window
    /// sets its sidebar back to a 140 pt minimum and 144 pt width (D-75). A column that ends up
    /// outside the limits applies them again.
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        guard minimumWidth > 0, newSize.width < minimumWidth - 0.5 || newSize.width > maximumWidth + 0.5 else { return }
        scheduleConstraintUpdate()
    }

    func update(minimumWidth: CGFloat, maximumWidth: CGFloat) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = max(minimumWidth, maximumWidth)
        minimumDetailWidth = nil
        scheduleConstraintUpdate()
    }

    /// The maximum leaves `minimumDetailWidth` to the detail column of the current window.
    func update(minimumWidth: CGFloat, minimumDetailWidth: CGFloat) {
        guard self.minimumWidth != minimumWidth || self.minimumDetailWidth != minimumDetailWidth else { return }
        self.minimumWidth = minimumWidth
        self.minimumDetailWidth = minimumDetailWidth
        updateWindowDependentMaximum()
        scheduleConstraintUpdate()
    }

    /// The window-dependent maximum for a window content width.
    func updateWindowDependentMaximum(windowWidth: CGFloat? = nil) {
        guard let minimumDetailWidth else { return }
        guard let width = windowWidth ?? window?.contentView?.bounds.width ?? window?.frame.width else { return }
        maximumWidth = max(minimumWidth, width - minimumDetailWidth)
    }

    private func observeWindowResizing() {
        if let windowResizeObserver { NotificationCenter.default.removeObserver(windowResizeObserver) }
        windowResizeObserver = nil
        guard let window else { return }
        windowResizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.minimumDetailWidth != nil else { return }
                self.updateWindowDependentMaximum()
                // Applied at once: the split view lays out right after the resize.
                self.applyConstraint()
            }
        }
    }

    func applyConstraint() {
        updateWindowDependentMaximum()
        guard let (splitViewController, itemIndex) = enclosingSplitView(),
              splitViewController.splitViewItems.indices.contains(itemIndex) else { return }

        let splitViewItem = splitViewController.splitViewItems[itemIndex]
        applyConstraint(to: splitViewItem)
        for (index, item) in splitViewController.splitViewItems.enumerated() where index != itemIndex {
            item.holdingPriority = .defaultLow
        }
    }

    func applyConstraint(to splitViewItem: NSSplitViewItem) {
        splitViewItem.minimumThickness = minimumWidth
        splitViewItem.maximumThickness = maximumWidth
        splitViewItem.holdingPriority = Self.sidebarHoldingPriority
        splitViewItem.preferredThicknessFraction = NSSplitViewItem.unspecifiedDimension
    }

    private func scheduleConstraintUpdate() {
        updateTask?.cancel()
        updateTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard !Task.isCancelled, let self else { return }
            applyConstraint()
            updateTask = nil
        }
    }

    private func enclosingSplitView() -> (NSSplitViewController, Int)? {
        var responder: NSResponder? = self
        while let currentResponder = responder {
            if let splitViewController = currentResponder as? NSSplitViewController,
               let itemIndex = itemIndex(in: splitViewController) {
                return (splitViewController, itemIndex)
            }
            responder = currentResponder.nextResponder
        }

        var ancestor = superview
        while let view = ancestor {
            if let splitView = view as? NSSplitView,
               let splitViewController = splitView.delegate as? NSSplitViewController,
               let itemIndex = itemIndex(in: splitViewController) {
                return (splitViewController, itemIndex)
            }
            ancestor = view.superview
        }
        return nil
    }

    private func itemIndex(in splitViewController: NSSplitViewController) -> Int? {
        if let descendantIndex = splitViewController.splitViewItems.firstIndex(where: { item in
            self === item.viewController.view || self.isDescendant(of: item.viewController.view)
        }) {
            return descendantIndex
        }
        return splitViewController.splitViewItems.firstIndex(where: { $0.behavior == .sidebar })
    }
}
