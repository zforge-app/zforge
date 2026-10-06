import AppKit
import SwiftUI

struct FinderClickGestureModifier: ViewModifier {
    let onSingleClick: (NSEvent.ModifierFlags) -> Void
    let onDoubleClick: (NSEvent.ModifierFlags) -> Void
    @State private var modifiers = FinderClickModifiers()

    func body(content: Content) -> some View {
        content
            .background {
                FinderClickModifiersReader(modifiers: modifiers)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .gesture(
                TapGesture(count: 2)
                    .exclusively(before: TapGesture(count: 1))
                    .onEnded { gesture in
                        switch gesture {
                        case .first: onDoubleClick(modifiers.value)
                        case .second: onSingleClick(modifiers.value)
                        }
                    },
                including: .gesture
            )
    }
}

@MainActor
private final class FinderClickModifiers {
    var value: NSEvent.ModifierFlags = []
}

private struct FinderClickModifiersReader: NSViewRepresentable {
    let modifiers: FinderClickModifiers

    func makeNSView(context: Context) -> FinderClickModifiersHost {
        FinderClickModifiersHost(modifiers: modifiers)
    }
    func updateNSView(_ view: FinderClickModifiersHost, context: Context) { view.modifiers = modifiers }
    static func dismantleNSView(_ view: FinderClickModifiersHost, coordinator: ()) { view.stopMonitoring() }
}

@MainActor
private final class FinderClickModifiersHost: NSView {
    var modifiers: FinderClickModifiers

    init(modifiers: FinderClickModifiers) {
        self.modifiers = modifiers
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { nil }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        FinderClickModifiersMonitor.shared.register(self)
    }

    func capture(_ event: NSEvent) {
        guard !isHiddenOrHasHiddenAncestor, event.window === window,
              bounds.intersection(visibleRect).contains(convert(event.locationInWindow, from: nil)) else { return }
        modifiers.value = event.modifierFlags
    }

    func stopMonitoring() { FinderClickModifiersMonitor.shared.unregister(self) }
}

/// One native subscription for all cells; weak registrations cannot retain a
/// closed window or accumulate subscriptions as the user scrolls.
@MainActor
private final class FinderClickModifiersMonitor {
    static let shared = FinderClickModifiersMonitor()
    private let hosts = NSHashTable<FinderClickModifiersHost>.weakObjects()
    private var monitor: Any?

    func register(_ host: FinderClickModifiersHost) {
        hosts.add(host)
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            MainActor.assumeIsolated {
                self?.hosts.allObjects.forEach { $0.capture(event) }
            }
            return event
        }
    }

    func unregister(_ host: FinderClickModifiersHost) {
        hosts.remove(host)
        guard hosts.allObjects.isEmpty else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
