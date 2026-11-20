import SwiftUI
@preconcurrency import AppKit
import UniformTypeIdentifiers

nonisolated enum ArchiveDragPolicy {
    static let type = "app.zforge.archive-items"
    static func operation(option: Bool, insideArchive: Bool = false) -> NSDragOperation {
        (insideArchive ? !option : option) ? .move : .copy
    }
}

/// A promise keeps the virtual item's identity; no temporary file URL is exported.
final class ArchiveDragPromise: NSFilePromiseProvider {
    nonisolated let token: String
    nonisolated override init() { token = UUID().uuidString; super.init() }
    init(type: String, delegate: NSFilePromiseProviderDelegate, token: String) {
        self.token = token
        super.init()
        self.fileType = type
        self.delegate = delegate
    }
    nonisolated override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        super.writableTypes(for: pasteboard) + [NSPasteboard.PasteboardType(ArchiveDragPolicy.type)]
    }
    nonisolated override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        type.rawValue == ArchiveDragPolicy.type ? Data(token.utf8) : super.pasteboardPropertyList(forType: type)
    }
    nonisolated override func writingOptions(forType type: NSPasteboard.PasteboardType,
                                            pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        // The identity is eager data, not another file promise. The inherited
        // provider otherwise handles this type as a deferred file URL promise.
        type.rawValue == ArchiveDragPolicy.type ? [] : super.writingOptions(forType: type, pasteboard: pasteboard)
    }
}

/// The local files a drag started in Zforge carries, so drop targets can refuse their own
/// folders while the drag hovers instead of failing after the drop (ZF-89).
@MainActor
enum BrowserLocalDrag {
    private(set) static var sourceURLs: [URL] = []

    static func begin(_ urls: [URL]) { sourceURLs = urls }
    static func end() { sourceURLs = [] }

    static func refuses(_ destination: URL, operation: BrowserFileTransferOperation) -> Bool {
        !sourceURLs.isEmpty && BrowserDropDestinationPolicy.refuses(destination, for: sourceURLs, operation: operation)
    }
}

@MainActor
final class ArchiveDragTransfer {
    static var active: [String: ArchiveDragTransfer] = [:]
    static var hasLiveDrag: Bool { active.values.contains { $0.isDragging } }
    var isDragging: Bool { endedOperation == nil }
    let token = UUID().uuidString
    let state: FileBrowserState
    let items: [BrowserItem]
    let optionPressed: () -> Bool
    var delegates: [ArchivePromiseDelegate] = []
    private var requests: [(Int, URL, (Error?) -> Void)] = []
    private var published: Set<Int> = []
    private var failed = false
    private var endedOperation: NSDragOperation?
    private var started = false
    private var externalMoving: Bool?
    /// Whether the last source mask offered outside the application was a move: the operation
    /// the drop chose. Finder requests promised files after the drop, when Option may be released.
    private var dropMoving: Bool?
    private var externalConfirmed = false
    private var promiseTask: Task<Void, Never>?
    private var completionTask: Task<Void, Never>?

    init(state: FileBrowserState, items: [BrowserItem], optionPressed: @escaping () -> Bool = { NSEvent.modifierFlags.contains(.option) }) {
        self.state = state; self.items = items; self.optionPressed = optionPressed
        Self.active[token] = self
    }
    /// The source operations offered outside the application while the drag moves. Option
    /// (move) is offered only when the original archive can be changed.
    func externalOperationMask(option: Bool) -> NSDragOperation {
        if option, !state.canRemoveArchiveItems(items) { dropMoving = nil; return [] }
        let operation = ArchiveDragPolicy.operation(option: option)
        dropMoving = operation.contains(.move)
        return operation
    }
    func receive(index: Int, url: URL, completion: @escaping (Error?) -> Void) {
        guard !started, items.indices.contains(index), endedOperation?.isEmpty != true else {
            completion(ArchiveEngineError.cancelled); return
        }
        requests.append((index, url, completion))
        guard promiseTask == nil else { return }
        promiseTask = Task {
            // Receivers may request one file and wait for its completion before
            // requesting another. Fulfill each promise without waiting for the
            // final drag callback; only source removal depends on that callback.
            while !requests.isEmpty {
                let (index, url, completion) = requests.removeFirst()
                do {
                    if externalMoving == nil {
                        externalMoving = endedOperation.map { $0.contains(.move) } ?? dropMoving ?? optionPressed()
                    }
                    if externalMoving == true, !externalConfirmed {
                        guard state.canRemoveArchiveItems(items) else { throw ArchiveEngineError.updateUnsupported }
                        try await state.confirmArchiveTransfer(items, destination: url.deletingLastPathComponent().path, moving: true)
                        externalConfirmed = true
                    }
                    guard !failed else { throw ArchiveEngineError.cancelled }
                    try await state.transferArchiveItems([items[index]], to: [url], moving: false, resolveConflicts: false, promised: true)
                    published.insert(index)
                    completion(nil)
                } catch {
                    failed = true
                    completion(error)
                }
            }
            promiseTask = nil
            finishPromisesIfReady()
        }
    }
    func ended(_ operation: NSDragOperation) {
        endedOperation = operation
        if operation.isEmpty {
            requests.forEach { $0.2(ArchiveEngineError.cancelled) }
            requests.removeAll()
            if !started, promiseTask == nil { Self.active.removeValue(forKey: token) }
        } else {
            finishPromisesIfReady()
        }
    }
    private func finishPromisesIfReady() {
        guard !started, promiseTask == nil, let operation = endedOperation else { return }
        if operation.isEmpty {
            Self.active.removeValue(forKey: token); return
        }
        guard published.count == items.count || failed else { return }
        started = true
        completionTask = Task {
            if !failed, published.count == items.count, operation.contains(.move), externalConfirmed {
                do { try await state.finishPromisedArchiveMove(items) }
                catch { state.reportArchiveDragError(error) }
            }
            Self.active.removeValue(forKey: token)
        }
    }
    func drop(to directory: URL, moving: Bool) {
        guard !started else { return }
        started = true
        let pending = promiseTask
        completionTask = Task {
            await pending?.value
            let urls = (delegates.isEmpty ? items.map(\.name) : delegates.map(\.name)).map { directory.appendingPathComponent($0) }
            do { try await state.transferArchiveItems(items, to: urls, moving: moving, resolveConflicts: true) }
            catch { state.reportArchiveDragError(error) }
            Self.active.removeValue(forKey: token)
        }
    }
    func drop(to address: ArchiveAddress, moving: Bool) {
        guard !started else { return }
        started = true
        completionTask = Task {
            do { try await state.reorganizeArchiveItems(items, to: address, moving: moving) }
            catch { state.reportArchiveDragError(error) }
            Self.active.removeValue(forKey: token)
        }
    }
    func waitForCompletion() async {
        await promiseTask?.value
        await completionTask?.value
    }

}

/// AppKit's completion is handed off exactly once to the main queue chosen by
/// this delegate. The wrapper bridges its pre-concurrency closure signature.
nonisolated final class ArchivePromiseCompletion: @unchecked Sendable {
    let handler: (Error?) -> Void
    init(_ handler: @escaping (Error?) -> Void) { self.handler = handler }
}

final class ArchivePromiseDelegate: NSObject, NSFilePromiseProviderDelegate {
    weak var transfer: ArchiveDragTransfer?
    let index: Int
    let name: String
    init(transfer: ArchiveDragTransfer, index: Int, name: String) {
        self.transfer = transfer; self.index = index; self.name = name
    }
    func filePromiseProvider(_ provider: NSFilePromiseProvider, fileNameForType type: String) -> String { name }
    nonisolated func filePromiseProvider(_ provider: NSFilePromiseProvider, writePromiseTo url: URL,
                                        completionHandler: @escaping (Error?) -> Void) {
        // AppKit defaults to the main operation queue for this delegate.
        let completion = ArchivePromiseCompletion(completionHandler)
        MainActor.assumeIsolated {
            guard let transfer else { completion.handler(ArchiveEngineError.cancelled); return }
            transfer.receive(index: index, url: url, completion: { completion.handler($0) })
        }
    }
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue { .main }
}

/// The part of an item's cell its drag image shows: the cell inset horizontally, with rounded
/// corners. Everything outside it is transparent, so the image carries the selection's shape and
/// not the column or window background around it (ZF-90).
nonisolated struct BrowserDragImageShape: Equatable, Sendable {
    /// A rounded rectangle in the cell's own coordinates (origin at the top left, as in SwiftUI).
    nonisolated struct Region: Equatable, Sendable {
        var rect: CGRect
        var cornerRadius: CGFloat
    }

    var horizontalInset: CGFloat = 0
    var cornerRadius: CGFloat = 0
    /// When set, the image shows only these parts of the cell (Icons: the icon's tile and the
    /// name's capsule), instead of the inset cell.
    var regions: [Region] = []
    static let fullCell = BrowserDragImageShape()
}

struct ArchiveDragSource: NSViewRepresentable {
    let state: FileBrowserState
    let item: BrowserItem
    var imageShape = BrowserDragImageShape.fullCell
    func makeNSView(context: Context) -> ArchiveDragSourceView {
        let view = ArchiveDragSourceView(); view.state = state; view.item = item; view.imageShape = imageShape
        return view
    }
    func updateNSView(_ view: ArchiveDragSourceView, context: Context) {
        view.state = state; view.item = item; view.imageShape = imageShape
    }
    static func dismantleNSView(_ view: ArchiveDragSourceView, coordinator: ()) { view.stopMonitoring() }
}

final class ArchiveDragSourceView: NSView, NSDraggingSource {
    weak var state: FileBrowserState?
    var item: BrowserItem?
    var imageShape = BrowserDragImageShape.fullCell
    private var origin: NSPoint?
    private var transfer: ArchiveDragTransfer?
    private var localDrag = false
    private var didDrag = false
    private static let sources = NSHashTable<ArchiveDragSourceView>.weakObjects()
    private var eventMonitor: Any?
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        Self.sources.add(self)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            let consumed = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return consumed ? nil : event
        }
    }
    func stopMonitoring() {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil; origin = nil
    }
    private func handle(_ event: NSEvent) -> Bool {
        guard event.window === window, let state, !state.archiveOperationInProgress else { return false }
        switch event.type {
        case .leftMouseDown:
            didDrag = false; origin = nil
            guard !event.modifierFlags.contains(.control), startsDrag(at: event.locationInWindow) else { return false }
            origin = event.locationInWindow
        case .leftMouseDragged:
            guard !didDrag, let origin,
                  hypot(event.locationInWindow.x - origin.x, event.locationInWindow.y - origin.y) > 4 else { return false }
            didDrag = true
            return begin(event)
        case .leftMouseUp: origin = nil
        default: break
        }
        return false
    }
    /// Whether a press at this window point picks up this item. The monitor sees every
    /// press in the window, so the point must be on the visible row and not on a
    /// pane drawn above it, such as List's preview over the rows' trailing part.
    func startsDrag(at locationInWindow: NSPoint) -> Bool {
        guard let state else { return false }
        let local = convert(locationInWindow, from: nil)
        guard bounds.intersection(visibleRect).contains(local),
              !BrowserForegroundArea.contains(locationInWindow, in: window),
              !Self.isSplitViewDivider(at: locationInWindow, in: window) else { return false }
        if state.viewMode == .list, let item,
           let entry = state.flattenedList().first(where: { $0.id == item.id }),
           local.x < CGFloat(entry.depth * 20 + 24) * state.preferences.scale + 8 { return false }
        return true
    }
    /// Whether the window gives a press at this point to a split view: its divider, whose hit area
    /// (and resize pointer) reaches over the first pixels of Columns' first column (ZF-89: pressing
    /// there to resize the sidebar dragged the file under the pointer instead).
    static func isSplitViewDivider(at locationInWindow: NSPoint, in window: NSWindow?) -> Bool {
        guard let frameView = window?.contentView?.superview ?? window?.contentView else { return false }
        return frameView.hitTest(frameView.convert(locationInWindow, from: nil)) is NSSplitView
    }

    /// The visible part of this item's cell as rendered in the window, in `host` coordinates,
    /// with everything outside `imageShape` transparent; nil while the cell is not visible.
    func dragImage(in host: NSView) -> (frame: NSRect, image: NSImage)? {
        let frame = convert(bounds.intersection(visibleRect), to: host)
        guard !frame.isEmpty, let bitmap = host.bitmapImageRepForCachingDisplay(in: frame) else { return nil }
        host.cacheDisplay(in: frame, to: bitmap)
        // A rect in this view's coordinates, in the image's own coordinates (origin at the bottom left).
        func imageRect(_ rect: NSRect) -> NSRect {
            let shape = convert(rect, to: host)
            return NSRect(x: shape.minX - frame.minX,
                          y: host.isFlipped ? frame.maxY - shape.maxY : shape.minY - frame.minY,
                          width: shape.width, height: shape.height)
        }
        let path = NSBezierPath()
        if imageShape.regions.isEmpty {
            let rect = imageRect(bounds.insetBy(dx: imageShape.horizontalInset, dy: 0))
            path.append(NSBezierPath(roundedRect: rect, xRadius: imageShape.cornerRadius, yRadius: imageShape.cornerRadius))
        } else {
            for region in imageShape.regions {
                // Region rects use SwiftUI's top-left origin.
                let flipped = isFlipped ? region.rect
                    : NSRect(x: region.rect.minX, y: bounds.height - region.rect.maxY,
                             width: region.rect.width, height: region.rect.height)
                path.append(NSBezierPath(roundedRect: imageRect(flipped), xRadius: region.cornerRadius,
                                         yRadius: region.cornerRadius))
            }
        }
        let image = NSImage(size: frame.size, flipped: false) { rect in
            path.addClip()
            bitmap.draw(in: rect)
            return true
        }
        return (frame, image)
    }

    private func begin(_ event: NSEvent) -> Bool {
        guard let state, let item, !state.archiveOperationInProgress else { return false }
        let items: [BrowserItem]
        let transfer: ArchiveDragTransfer?
        if let url = item.localURL {
            _ = state.prepareDragPayload([url])
            items = state.selectedItems.filter { $0.localURL != nil }
            transfer = nil
            localDrag = true
        } else {
            items = state.archiveDragItems(startingWith: item)
            guard !items.isEmpty else { return false }
            transfer = ArchiveDragTransfer(state: state, items: items)
            localDrag = false
        }
        guard !items.isEmpty else { return false }
        self.transfer = transfer
        var names: Set<String> = []
        guard let host = window?.contentView else { transfer?.ended([]); return false }
        let draggingItems = items.enumerated().map { index, item in
            var name = item.name
            var suffix = 2
            while names.contains(name) {
                let base = (item.name as NSString).deletingPathExtension
                let ext = (item.name as NSString).pathExtension
                name = "\(base) (\(suffix))" + (ext.isEmpty ? "" : ".\(ext)"); suffix += 1
            }
            names.insert(name)
            let dragging: NSDraggingItem
            if let transfer {
                let delegate = ArchivePromiseDelegate(transfer: transfer, index: index, name: name)
                transfer.delegates.append(delegate)
                let provider = ArchiveDragPromise(type: item.isDirectory ? UTType.folder.identifier : UTType.data.identifier,
                    delegate: delegate, token: transfer.token)
                dragging = NSDraggingItem(pasteboardWriter: provider)
            } else {
                dragging = NSDraggingItem(pasteboardWriter: item.localURL! as NSURL)
            }
            // Capture the same rendered cell used by the local drag source.
            // All frames belong to the NSView that starts the native session.
            let source = Self.sources.allObjects.first { $0.item?.id == item.id && $0.window === self.window } ?? self
            let frame: NSRect
            let image: NSImage
            if let snapshot = source.dragImage(in: host) {
                (frame, image) = snapshot
            } else {
                frame = self.convert(self.bounds, to: host)
                // Offscreen selected entries still get a named preview at the
                // pickup position; an unset frame would animate from (0, 0).
                let scale = state.preferences.scale
                let renderer = ImageRenderer(content: HStack(spacing: 4 * scale) {
                    FileIconView(item: item, size: 16 * scale)
                    Text(item.name).font(.system(size: 13 * scale))
                    Spacer()
                }.padding(.horizontal, 8 * scale).frame(width: frame.width, height: frame.height))
                image = renderer.nsImage ?? NSImage(size: frame.size)
            }
            dragging.setDraggingFrame(frame, contents: image)
            return dragging
        }
        if localDrag { BrowserLocalDrag.begin(items.compactMap(\.localURL)) }
        let session = host.beginDraggingSession(with: draggingItems, event: event, source: self)
        session.draggingFormation = state.viewMode.archiveDragFormation
        return true
    }
    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool { !localDrag }
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if localDrag { return [.copy, .move, .link] }
        if context == .withinApplication { return [.copy, .move] }
        let moving = NSEvent.modifierFlags.contains(.option)
        guard let transfer else { return ArchiveDragPolicy.operation(option: moving) }
        return transfer.externalOperationMask(option: moving)
    }
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if localDrag { BrowserLocalDrag.end() }
        transfer?.ended(operation)
        transfer = nil
    }
}

/// Read the virtual identity directly from the dragging pasteboard. Bridging a
/// file promise through SwiftUI's NSItemProvider can request its file URL before
/// the destination has supplied the directory in which to fulfill that promise.
struct ArchiveDropDestination: NSViewRepresentable {
    var directory: URL? = nil
    var address: ArchiveAddress? = nil
    var onTargetedChange: (Bool) -> Void = { _ in }
    func makeNSView(context: Context) -> ArchiveDropDestinationView {
        let view = ArchiveDropDestinationView()
        view.registerForDraggedTypes([NSPasteboard.PasteboardType(ArchiveDragPolicy.type)])
        updateNSView(view, context: context)
        return view
    }
    func updateNSView(_ view: ArchiveDropDestinationView, context: Context) {
        view.directory = directory
        view.address = address
        view.onTargetedChange = onTargetedChange
    }
    static func dismantleNSView(_ view: ArchiveDropDestinationView, coordinator: ()) {
        view.onTargetedChange(false)
        view.unregisterDraggedTypes()
    }
}

final class ArchiveDropDestinationView: NSView {
    private static let destinations = NSHashTable<ArchiveDropDestinationView>.weakObjects()
    private weak var targetedView: ArchiveDropDestinationView?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { Self.destinations.add(self) }
    }
    func destination(at windowPoint: NSPoint) -> ArchiveDropDestinationView {
        Self.destinations.allObjects.filter { view in
            view.window === window && !view.isHiddenOrHasHiddenAncestor && (view.directory != nil || view.address != nil)
                && view.bounds.intersection(view.visibleRect).contains(view.convert(windowPoint, from: nil))
        }.min { $0.bounds.width * $0.bounds.height < $1.bounds.width * $1.bounds.height } ?? self
    }
    var directory: URL?
    var address: ArchiveAddress?
    var onTargetedChange: (Bool) -> Void = { _ in }
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only participate in native hit testing while a virtual drag is live.
        // Clicks, menus and local-file drags keep their existing SwiftUI routing.
        guard ArchiveDragTransfer.hasLiveDrag else { return nil }
        return super.hitTest(point)
    }
    func transfer(from pasteboard: NSPasteboard) -> ArchiveDragTransfer? {
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(ArchiveDragPolicy.type)),
              let token = String(data: data, encoding: .utf8) else { return nil }
        return ArchiveDragTransfer.active[token]
    }
    private func operation(_ sender: NSDraggingInfo) -> NSDragOperation {
        operation(for: transfer(from: sender.draggingPasteboard), option: NSEvent.modifierFlags.contains(.option),
                  sourceMask: sender.draggingSourceOperationMask)
    }
    /// The drop decision for a virtual drag, separated from the live dragging session.
    func operation(for transfer: ArchiveDragTransfer?, option: Bool, sourceMask: NSDragOperation) -> NSDragOperation {
        guard directory != nil || address != nil, let transfer else { return [] }
        if let address {
            guard transfer.state.canReorganizeArchiveItems(transfer.items, to: address) else { return [] }
        }
        let operation = ArchiveDragPolicy.operation(option: option, insideArchive: address != nil)
        guard sourceMask.contains(operation),
              operation != .move || transfer.state.canRemoveArchiveItems(transfer.items) else { return [] }
        return operation
    }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { draggingUpdated(sender) }
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let target = destination(at: sender.draggingLocation)
        if targetedView !== target { targetedView?.onTargetedChange(false); targetedView = target }
        let operation = target.operation(sender)
        target.onTargetedChange(!operation.isEmpty)
        return operation
    }
    override func draggingExited(_ sender: NSDraggingInfo?) { targetedView?.onTargetedChange(false); targetedView = nil }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { !destination(at: sender.draggingLocation).operation(sender).isEmpty }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let target = destination(at: sender.draggingLocation)
        targetedView?.onTargetedChange(false); targetedView = nil
        return target.perform(pasteboard: sender.draggingPasteboard, operation: target.operation(sender))
    }
    /// Starts the transfer for the operation chosen by `operation(for:option:sourceMask:)`.
    func perform(pasteboard: NSPasteboard, operation: NSDragOperation) -> Bool {
        guard !operation.isEmpty else { return false }
        if let address, let transfer = transfer(from: pasteboard) {
            transfer.drop(to: address, moving: operation == .move); return true
        }
        guard let directory else { return false }
        return accept(pasteboard: pasteboard, directory: directory, operation: operation)
    }
    func accept(pasteboard: NSPasteboard, directory: URL, operation: NSDragOperation) -> Bool {
        guard operation == .copy || operation == .move,
              let transfer = transfer(from: pasteboard),
              operation != .move || transfer.state.canRemoveArchiveItems(transfer.items) else { return false }
        transfer.drop(to: directory, moving: operation == .move)
        return true
    }
}

extension BrowserViewMode {
    var archiveDragFormation: NSDraggingFormation {
        switch self {
        case .list, .columns: .list
        case .icons, .gallery: .default
        }
    }
}
