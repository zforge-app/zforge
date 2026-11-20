import AppKit
import SwiftUI

/// Tells the browser toolbar where the sidebar ends (ZF-88).
///
/// The toolbar's room runs from the sidebar's trailing edge (with the sidebar collapsed, from the
/// traffic lights) to the window's trailing edge. This view sits in the sidebar, so it is in the
/// window whenever the sidebar is laid out, and it reads the edge from AppKit on demand: the split
/// view item's width (SwiftUI's own geometry of the sidebar can report a transient width during
/// the first layout) and its collapsed state, which the toolbar's sidebar button changes in
/// AppKit. `onChange` runs when that state changes and after the SwiftUI update that installed
/// this view, never during a SwiftUI update.
struct BrowserSidebarObserver: NSViewRepresentable {
    let metrics: BrowserToolbarMetrics
    let onChange: () -> Void

    func makeNSView(context: Context) -> BrowserSidebarObserverView {
        let view = BrowserSidebarObserverView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ nsView: BrowserSidebarObserverView, context: Context) {
        metrics.sidebarObserver = nsView
        nsView.onChange = onChange
        // The window's content can be rebuilt around this view with new state, so the new
        // handler is told about the current edge too.
        nsView.reportAfterUpdate()
    }
}

@MainActor
final class BrowserSidebarObserverView: NSView {
    var onChange: () -> Void = {}
    private var reportScheduled = false
    private var collapseObservation: NSKeyValueObservation?
    private weak var sidebarItem: NSSplitViewItem?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Leaving the window (it closed) removes the observation.
        collapseObservation = nil
        sidebarItem = nil
        guard window != nil else { return }
        reportAfterUpdate()
    }

    /// The sidebar's trailing edge in the window (the split view spans the window from its
    /// leading edge, so it is the sidebar's width), nil inside while it is collapsed, or nil when
    /// AppKit cannot tell yet (no split view, or a sidebar without a width).
    func sidebarTrailingEdge() -> CGFloat?? {
        if sidebarItem == nil { observeSidebar() }
        guard let item = sidebarItem else { return nil }
        if item.isCollapsed { return .some(nil) }
        let width = item.viewController.view.frame.width
        return width > 0 ? .some(width) : nil
    }

    /// Reports after the current SwiftUI update, once however many updates ask.
    func reportAfterUpdate() {
        guard !reportScheduled else { return }
        reportScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reportScheduled = false
            self.onChange()
        }
    }

    private func observeSidebar() {
        guard let controller = window?.contentView.flatMap(Self.splitViewController(in:)),
              let item = controller.splitViewItems.first(where: { $0.behavior == .sidebar }) else { return }
        sidebarItem = item
        collapseObservation = item.observe(\.isCollapsed) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.onChange() }
        }
    }

    private static func splitViewController(in view: NSView) -> NSSplitViewController? {
        if let split = view as? NSSplitView, let controller = split.delegate as? NSSplitViewController {
            return controller
        }
        for subview in view.subviews {
            if let controller = splitViewController(in: subview) { return controller }
        }
        return nil
    }
}
