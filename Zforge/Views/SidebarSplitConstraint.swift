import AppKit
import SwiftUI

struct SidebarSplitConstraint: NSViewRepresentable {
    let minimumWidth: CGFloat
    let maximumWidth: CGFloat

    func makeNSView(context: Context) -> SidebarSplitConstraintView {
        let view = SidebarSplitConstraintView()
        view.update(minimumWidth: minimumWidth, maximumWidth: maximumWidth)
        return view
    }

    func updateNSView(_ nsView: SidebarSplitConstraintView, context: Context) {
        nsView.update(minimumWidth: minimumWidth, maximumWidth: maximumWidth)
    }
}

@MainActor
final class SidebarSplitConstraintView: NSView {
    private static let sidebarHoldingPriority = NSLayoutConstraint.Priority(
        rawValue: NSLayoutConstraint.Priority.defaultLow.rawValue + 1
    )

    private var minimumWidth: CGFloat = 0
    private var maximumWidth: CGFloat = 0
    private var updateTask: Task<Void, Never>?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        scheduleConstraintUpdate()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleConstraintUpdate()
    }

    func update(minimumWidth: CGFloat, maximumWidth: CGFloat) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = max(minimumWidth, maximumWidth)
        scheduleConstraintUpdate()
    }

    func applyConstraint() {
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
