import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SidebarDropFeedback {
    enum Target: Equatable {
        case folder(URL)
        case insertion(URL?)
    }

    private(set) var owner: String?
    private(set) var target: Target?

    func update(owner: String, target: Target) { self.owner = owner; self.target = target }
    func clear() { owner = nil; target = nil }
    func leave(owner: String) { if self.owner == owner { clear() } }
    func validateSession(owner: String, pointerInside: Bool, buttonDown: Bool) {
        if self.owner == owner && (!pointerInside || !buttonDown) { clear() }
    }

    static func rowTarget(url: URL, canInsert: Bool, nextFavorite: URL?, height: CGFloat, y: CGFloat) -> Target {
        guard canInsert else { return .folder(url) }
        if y <= 5 { return .insertion(url) }
        if y >= height - 5 { return .insertion(nextFavorite) }
        return .folder(url)
    }

    static func isCurrentDirectory(_ destination: URL, current: URL?) -> Bool {
        guard let current else { return false }
        return destination.standardizedFileURL.resolvingSymlinksInPath().path
            == current.standardizedFileURL.resolvingSymlinksInPath().path
    }
}

nonisolated enum SidebarInsertionEdge { case top, bottom }

/// List supplies its own native drop background. Disable only that feedback in the
/// sidebar's table, allowing one consistent SwiftUI drawing for both drop zones.
struct SidebarNativeDropFeedback: NSViewRepresentable {
    var feedback: SidebarDropFeedback? = nil
    var owner: String? = nil
    var insertionEdge: SidebarInsertionEdge? = nil
    var insertionOffset: CGFloat = 0
    func makeNSView(context: Context) -> SidebarNativeDropFeedbackView { SidebarNativeDropFeedbackView() }
    func updateNSView(_ view: SidebarNativeDropFeedbackView, context: Context) {
        view.feedback = feedback
        view.owner = owner
        view.insertionEdge = insertionEdge
        view.insertionOffset = insertionOffset
        view.scheduleUpdate()
        view.trackIfNeeded(active: feedback?.owner == owner && owner != nil)
    }
    static func dismantleNSView(_ view: SidebarNativeDropFeedbackView, coordinator: ()) { view.stopTracking(); view.clearIndicator() }
}

@MainActor
final class SidebarNativeDropFeedbackView: NSView {
    private var updateTask: Task<Void, Never>?
    private var trackingTask: Task<Void, Never>?
    weak var feedback: SidebarDropFeedback?
    var owner: String?
    var insertionEdge: SidebarInsertionEdge?
    var insertionOffset: CGFloat = 0
    private weak var indicator: SidebarInsertionOverlayView?

    override func layout() { super.layout(); refreshIndicator() }

    func clearIndicator() {
        if indicator?.anchor === self { indicator?.setAnchor(nil, edge: .top, offset: 0) }
    }

    private func refreshIndicator() {
        var ancestor = superview
        while let view = ancestor {
            if let table = view as? NSTableView, let scroll = table.enclosingScrollView {
                guard let edge = insertionEdge else { clearIndicator(); return }
                let overlay: SidebarInsertionOverlayView
                if let existing = scroll.subviews.compactMap({ $0 as? SidebarInsertionOverlayView }).first {
                    overlay = existing
                } else {
                    overlay = SidebarInsertionOverlayView(frame: scroll.bounds)
                    overlay.autoresizingMask = [.width, .height]
                    scroll.addSubview(overlay, positioned: .above, relativeTo: nil)
                    overlay.observeScrolling(scroll.contentView)
                }
                indicator = overlay
                overlay.setAnchor(self, edge: edge, offset: insertionOffset)
                return
            }
            ancestor = view.superview
        }
        clearIndicator()
    }

    func trackIfNeeded(active: Bool) {
        guard active else { stopTracking(); return }
        guard trackingTask == nil else { return }
        trackingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(30))
                guard !Task.isCancelled, let self else { return }
                guard let window, let owner, feedback?.owner == owner else { stopTracking(); return }
                let point = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
                feedback?.validateSession(owner: owner, pointerInside: bounds.insetBy(dx: -8, dy: -5).contains(point),
                                          buttonDown: NSEvent.pressedMouseButtons & 1 != 0)
                if feedback?.owner != owner { stopTracking(); return }
            }
        }
    }
    func stopTracking() { trackingTask?.cancel(); trackingTask = nil }


    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidMoveToSuperview() { super.viewDidMoveToSuperview(); scheduleUpdate() }
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); scheduleUpdate() }

    func suppressFeedback() {
        var ancestor = superview
        while let view = ancestor {
            if let table = view as? NSTableView {
                table.draggingDestinationFeedbackStyle = .none
                return
            }
            ancestor = view.superview
        }
    }

    func scheduleUpdate() {
        suppressFeedback()
        refreshIndicator()
        updateTask?.cancel()
        updateTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard !Task.isCancelled, let self else { return }
            suppressFeedback()
            refreshIndicator()
            updateTask = nil
        }
    }
}


/// Sibling of the clip view, above the table's cells. Painting across a row edge
/// here cannot be cropped by the cell hosting the drop destination.
@MainActor
final class SidebarInsertionOverlayView: NSView {
    private(set) weak var anchor: NSView?
    private var edge: SidebarInsertionEdge = .top
    private var offset: CGFloat = 0
    private var scrollObserver: (any NSObjectProtocol)?

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func setAnchor(_ anchor: NSView?, edge: SidebarInsertionEdge, offset: CGFloat) {
        self.anchor = anchor
        self.edge = edge
        self.offset = offset
        // Row backgrounds are layer-backed and may be attached after this view.
        // Keep our own backing layer above every sibling, including those updates.
        wantsLayer = true
        let highestSibling = superview?.subviews.filter { $0 !== self }
            .map { $0.layer?.zPosition ?? 0 }.max() ?? 0
        layer?.zPosition = max(0, highestSibling) + 1
        needsDisplay = true
    }

    func observeScrolling(_ clip: NSClipView) {
        stopObserving()
        clip.postsBoundsChangedNotifications = true
        scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification, object: clip, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { stopObserving() }
    }

    private func stopObserving() {
        if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
        scrollObserver = nil
    }

    var indicatorFrame: CGRect? {
        guard let anchor, anchor.superview != nil else { return nil }
        let row = convert(anchor.bounds, from: anchor)
        let y = (edge == .top ? row.minY : row.maxY) + offset
        return CGRect(x: row.minX - 8, y: y - 4, width: row.width + 8, height: 8)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let frame = indicatorFrame, frame.intersects(bounds) else { return }
        NSColor.controlAccentColor.setStroke()
        let circle = NSBezierPath(ovalIn: CGRect(x: frame.minX + 1, y: frame.minY + 1,
                                               width: 6, height: 6))
        circle.lineWidth = 2
        circle.stroke()
        let line = NSBezierPath()
        line.lineWidth = 2
        line.lineCapStyle = .round
        line.move(to: CGPoint(x: frame.minX + 8, y: frame.midY))
        line.line(to: CGPoint(x: frame.maxX - 1, y: frame.midY))
        line.stroke()
    }
}
