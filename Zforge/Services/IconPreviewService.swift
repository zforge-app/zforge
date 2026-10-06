import AppKit
import Observation

/// Limits background work and retains only bounded, display-sized previews.
@MainActor
final class IconPreviewService {
    static let shared = IconPreviewService()
    static let archiveByteLimit: Int64 = 10 * 1_024 * 1_024

    typealias Renderer = @MainActor (BrowserItem, URL, Int) async throws -> CGImage?
    private let render: Renderer
    private let work: IconPreviewWorkQueue
    private let materialization = IconPreviewWorkQueue(limit: 1)
    private var cache: [PreviewKey: PreviewEntry] = [:]
    private var cacheCost = 0
    private var accessSequence: UInt64 = 0
    private let cacheCostLimit = 16 * 1_024 * 1_024

    var requestDidQueue: (@MainActor () -> Void)? {
        get { work.didQueue }
        set { work.didQueue = newValue }
    }

    init(maximumConcurrentRequests: Int = 4, renderer: Renderer? = nil) {
        work = IconPreviewWorkQueue(limit: maximumConcurrentRequests)
        let provider = IconPreviewRenderer()
        render = renderer ?? { item, url, pixels in
            try await provider.image(for: item, at: url, pixelSize: pixels)
        }
    }

    func image(for item: BrowserItem, pixelSize: Int, archives: any ArchiveServing) async throws -> CGImage? {
        guard !item.usesStaticIconPreview, !item.isDirectory else { return nil }
        if item.localURL == nil {
            // Unlike an explicit inspector request, a grid must never expand an
            // unbounded/large entry merely because it scrolled into view.
            guard let size = item.size, size <= Self.archiveByteLimit else { return nil }
        }
        let pixels = min(max(pixelSize, 32), 256)
        let key = PreviewKey(item: item, pixels: pixels)
        try Task.checkCancellation()
        if let cached = cachedEntry(for: key) { return cached.image }

        try await work.acquire()
        defer { work.release() }
        try Task.checkCancellation()
        // Another visible instance may have generated it while this request waited.
        if let cached = cachedEntry(for: key) { return cached.image }

        let url: URL
        if let localURL = item.localURL {
            url = localURL
        } else {
            try await materialization.acquire()
            do {
                try Task.checkCancellation()
                url = try await archives.materialize(item: item, purpose: .preview, automaticLimit: Self.archiveByteLimit)
                materialization.release()
            } catch {
                materialization.release()
                throw error
            }
        }
        try Task.checkCancellation()
        let image = try await render(item, url, pixels)
        try Task.checkCancellation()
        insert(image, for: key)
        return image
    }

    private func cachedEntry(for key: PreviewKey) -> PreviewEntry? {
        guard var entry = cache[key] else { return nil }
        accessSequence &+= 1
        entry.lastAccess = accessSequence
        cache[key] = entry
        return entry
    }

    private func insert(_ image: CGImage?, for key: PreviewKey) {
        let cost = image.map { $0.bytesPerRow * $0.height } ?? 1
        guard cost <= cacheCostLimit else { return }
        if let previous = cache.removeValue(forKey: key) { cacheCost -= previous.cost }
        while cache.count >= 256 || cacheCost + cost > cacheCostLimit {
            guard let oldest = cache.min(by: { $0.value.lastAccess < $1.value.lastAccess }) else { break }
            cache.removeValue(forKey: oldest.key)
            cacheCost -= oldest.value.cost
        }
        accessSequence &+= 1
        cache[key] = PreviewEntry(image: image, cost: cost, lastAccess: accessSequence)
        cacheCost += cost
    }

    private struct PreviewEntry {
        let image: CGImage?
        let cost: Int
        var lastAccess: UInt64
    }

    private struct PreviewKey: Hashable {
        let item: BrowserItem
        let pixels: Int
    }
}

/// FIFO permits with explicit cancellation; cancelled cells leave no queued work.
@MainActor
private final class IconPreviewWorkQueue {
    private let limit: Int
    var didQueue: (@MainActor () -> Void)?
    private var active = 0
    private var pending: [(UUID, CheckedContinuation<Void, any Error>)] = []

    init(limit: Int, didQueue: (@MainActor () -> Void)? = nil) {
        self.limit = max(1, limit)
        self.didQueue = didQueue
    }

    func acquire() async throws {
        try Task.checkCancellation()
        if active < limit { active += 1; return }
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending.append((id, continuation))
                didQueue?()
            }
        } onCancel: {
            Task { @MainActor in self.cancel(id) }
        }
    }

    func release() {
        if pending.isEmpty { active -= 1 }
        else { pending.removeFirst().1.resume() }
    }

    private func cancel(_ id: UUID) {
        guard let index = pending.firstIndex(where: { $0.0 == id }) else { return }
        pending.remove(at: index).1.resume(throwing: CancellationError())
    }
}

@MainActor
@Observable
final class IconPreviewModel {
    private(set) var image: CGImage?
    private(set) var item: BrowserItem?
    private(set) var pixelSize = 0
    @ObservationIgnored private var generation: UInt64 = 0

    func load(item: BrowserItem, pixelSize: Int, enabled: Bool,
              loader: @MainActor (BrowserItem, Int) async throws -> CGImage?) async {
        generation &+= 1
        let request = generation
        let retainsCurrentContent = enabled && self.item == item
        self.item = item
        self.pixelSize = pixelSize
        if !retainsCurrentContent { image = nil }
        guard enabled else { return }
        let result = try? await loader(item, pixelSize)
        guard !Task.isCancelled, request == generation else { return }
        image = result
    }
}
