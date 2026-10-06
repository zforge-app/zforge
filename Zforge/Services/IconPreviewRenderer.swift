import AppKit
import CoreGraphics
import CoreText
import ImageIO
@preconcurrency import QuickLookThumbnailing
import UniformTypeIdentifiers
import WebKit

/// Produces content images only. The caller owns file authorization and the fallback icon.
@MainActor
final class IconPreviewRenderer {
    private var backgroundJobs: [UUID: BackgroundJob] = [:]
    private var pendingBackgroundJobs: [UUID] = []
    private var activeBackgroundJobs = 0
    private var quickLookJobs: [UUID: QuickLookJob] = [:]
    private var htmlJobs: [UUID: HTMLJob] = [:]
    private var pendingHTMLJobs: [UUID] = []
    private var activeHTMLJob: UUID?

    func image(for item: BrowserItem, at url: URL, pixelSize: Int) async throws -> CGImage? {
        try Task.checkCancellation()
        guard !item.usesStaticIconPreview, url.isFileURL else { return nil }
        let size = min(max(pixelSize, 32), 512)

        // SVG is an image type, but ImageIO does not decode its vector document.
        // Let the system content provider render it with the other document types.
        if item.contentType?.conforms(to: .image) == true,
           item.contentType?.conforms(to: .svg) != true {
            return try await backgroundImage {
                try Self.imageThumbnail(at: url, pixelSize: size)
            }
        }
        if item.contentType?.conforms(to: .pdf) == true {
            return try await backgroundImage {
                try Self.pdfThumbnail(at: url, pixelSize: size)
            }
        }
        if item.usesHTMLDocumentPreview {
            return try await htmlImage(at: url, pixelSize: size)
        }
        if item.usesTextThumbnailPreview, item.contentType?.conforms(to: .svg) != true {
            return try await backgroundImage {
                try Self.textThumbnail(at: url, pixelSize: size)
            }
        }

        guard let image = try await quickLookImage(at: url, type: item.contentType, pixelSize: size) else {
            return nil
        }
        return try await backgroundImage {
            try Task.checkCancellation()
            return Self.fittedImage(image, pixelSize: size)
        }
    }

    // A cancelled native draw can finish in the background, but continues occupying its
    // slot until completion. Repeated navigation therefore cannot grow active decoders.
    private func backgroundImage(
        operation: @escaping @Sendable () throws -> CGImage?
    ) async throws -> CGImage? {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                backgroundJobs[id] = BackgroundJob(operation: operation, continuation: continuation)
                pendingBackgroundJobs.append(id)
                startBackgroundJobs()
            }
        } onCancel: { [weak self] in
            Task { @MainActor in self?.cancelBackgroundJob(id) }
        }
    }

    private func startBackgroundJobs() {
        while activeBackgroundJobs < 2, !pendingBackgroundJobs.isEmpty {
            let id = pendingBackgroundJobs.removeFirst()
            guard let job = backgroundJobs[id] else { continue }
            activeBackgroundJobs += 1
            let operation = job.operation
            job.task = Task.detached(priority: .utility) { [weak self] in
                let result: Result<CGImage?, Error>
                do {
                    try Task.checkCancellation()
                    let image = try operation()
                    try Task.checkCancellation()
                    result = .success(image)
                } catch {
                    result = .failure(error)
                }
                await self?.completeBackgroundJob(id, result: result)
            }
        }
    }

    private func cancelBackgroundJob(_ id: UUID) {
        guard let job = backgroundJobs[id] else { return }
        job.continuation?.resume(throwing: CancellationError())
        job.continuation = nil
        if let task = job.task {
            task.cancel()
        } else {
            backgroundJobs.removeValue(forKey: id)
            pendingBackgroundJobs.removeAll { $0 == id }
        }
    }

    private func completeBackgroundJob(_ id: UUID, result: Result<CGImage?, Error>) {
        guard let job = backgroundJobs.removeValue(forKey: id) else { return }
        activeBackgroundJobs -= 1
        job.continuation?.resume(with: result)
        job.continuation = nil
        startBackgroundJobs()
    }

    private func quickLookImage(at url: URL, type: UTType?, pixelSize: Int) async throws -> CGImage? {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                let request = QLThumbnailGenerator.Request(
                    fileAt: url,
                    size: CGSize(width: pixelSize, height: pixelSize),
                    scale: 1,
                    representationTypes: [.thumbnail, .lowQualityThumbnail]
                )
                if let type { request.contentType = type }
                let job = QuickLookJob(request: request, continuation: continuation)
                quickLookJobs[id] = job
                job.deadline = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(15)) } catch { return }
                    self?.finishQuickLookJob(id, result: .failure(CocoaError(.fileReadUnknown)))
                }
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, error in
                    let image = representation?.cgImage
                    Task { @MainActor in
                        if let error {
                            self?.finishQuickLookJob(id, result: .failure(error))
                        } else {
                            self?.finishQuickLookJob(id, result: .success(image))
                        }
                    }
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                self?.finishQuickLookJob(id, result: .failure(CancellationError()))
            }
        }
    }

    private func finishQuickLookJob(_ id: UUID, result: Result<CGImage?, Error>) {
        guard let job = quickLookJobs.removeValue(forKey: id) else { return }
        job.deadline?.cancel()
        QLThumbnailGenerator.shared.cancel(job.request)
        job.continuation.resume(with: result)
    }

    private func htmlImage(at url: URL, pixelSize: Int) async throws -> CGImage? {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                let job = HTMLJob(url: url, pixelSize: pixelSize, continuation: continuation) { [weak self] result in
                    self?.finishHTMLJob(id, result: result)
                }
                htmlJobs[id] = job
                pendingHTMLJobs.append(id)
                startHTMLJob()
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                self?.finishHTMLJob(id, result: .failure(CancellationError()))
            }
        }
    }

    private func startHTMLJob() {
        guard activeHTMLJob == nil else { return }
        while !pendingHTMLJobs.isEmpty {
            let id = pendingHTMLJobs.removeFirst()
            guard let job = htmlJobs[id] else { continue }
            activeHTMLJob = id
            job.start()
            return
        }
    }

    private func finishHTMLJob(_ id: UUID, result: Result<CGImage?, Error>) {
        guard let job = htmlJobs.removeValue(forKey: id) else { return }
        pendingHTMLJobs.removeAll { $0 == id }
        if activeHTMLJob == id { activeHTMLJob = nil }
        job.reset()
        job.continuation.resume(with: result)
        startHTMLJob()
    }

    private final class BackgroundJob {
        let operation: @Sendable () throws -> CGImage?
        var continuation: CheckedContinuation<CGImage?, Error>?
        var task: Task<Void, Never>?

        init(
            operation: @escaping @Sendable () throws -> CGImage?,
            continuation: CheckedContinuation<CGImage?, Error>
        ) {
            self.operation = operation
            self.continuation = continuation
        }
    }

    private final class QuickLookJob {
        let request: QLThumbnailGenerator.Request
        let continuation: CheckedContinuation<CGImage?, Error>
        var deadline: Task<Void, Never>?

        init(request: QLThumbnailGenerator.Request, continuation: CheckedContinuation<CGImage?, Error>) {
            self.request = request
            self.continuation = continuation
        }
    }

    private final class HTMLJob: NSObject, WKNavigationDelegate {
        let continuation: CheckedContinuation<CGImage?, Error>
        private let url: URL
        private let pixelSize: Int
        private let completion: (Result<CGImage?, Error>) -> Void
        private var webView: WKWebView?
        private var panel: NSPanel?
        private var snapshotStarted = false
        private var loadingDeadline: Task<Void, Never>?
        private var deadline: Task<Void, Never>?

        init(
            url: URL,
            pixelSize: Int,
            continuation: CheckedContinuation<CGImage?, Error>,
            completion: @escaping (Result<CGImage?, Error>) -> Void
        ) {
            self.url = url
            self.pixelSize = pixelSize
            self.continuation = continuation
            self.completion = completion
        }

        func start() {
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = false
            let bounds = CGRect(x: 0, y: 0, width: 640, height: 800)
            let view = WKWebView(frame: bounds, configuration: configuration)
            view.navigationDelegate = self
            webView = view

            // WebKit needs an attached rendering surface. Keep it offscreen and unable
            // to take focus; only one such host exists for this renderer at a time.
            let host = HTMLSnapshotPanel(
                contentRect: CGRect(x: -10_000, y: -10_000, width: bounds.width, height: bounds.height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            host.isReleasedWhenClosed = false
            host.hasShadow = false
            host.ignoresMouseEvents = true
            host.hidesOnDeactivate = false
            host.isExcludedFromWindowsMenu = true
            host.collectionBehavior.formUnion([.ignoresCycle, .transient])
            host.contentView = view
            panel = host
            host.orderBack(nil)

            deadline = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(10)) } catch { return }
                self?.completion(.failure(CocoaError(.fileReadUnknown)))
            }
            loadingDeadline = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                self?.snapshot(stoppingLoad: true)
            }
            let resolvedURL = url.resolvingSymlinksInPath()
            view.loadFileURL(resolvedURL, allowingReadAccessTo: resolvedURL.deletingLastPathComponent())
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            snapshot(stoppingLoad: false)
        }

        private func snapshot(stoppingLoad: Bool) {
            guard let webView, !snapshotStarted else { return }
            snapshotStarted = true
            loadingDeadline?.cancel()
            loadingDeadline = nil
            // A missing remote image or stylesheet must not serialize the grid behind
            // a network response. Snapshot the local content already loaded instead.
            if stoppingLoad { webView.stopLoading() }
            let configuration = WKSnapshotConfiguration()
            configuration.rect = webView.bounds
            configuration.snapshotWidth = NSNumber(value: Double(pixelSize) * 0.8)
            configuration.afterScreenUpdates = true
            webView.takeSnapshot(with: configuration) { [weak self] image, error in
                guard let self, self.webView === webView else { return }
                if let error { completion(.failure(error)); return }
                let raster = image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
                guard let raster else { completion(.failure(CocoaError(.fileReadUnknown))); return }
                completion(.success(IconPreviewRenderer.fittedImage(raster, pixelSize: pixelSize)))
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !snapshotStarted { completion(.failure(error)) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if !snapshotStarted { completion(.failure(error)) }
        }

        func reset() {
            loadingDeadline?.cancel()
            loadingDeadline = nil
            deadline?.cancel()
            deadline = nil
            webView?.navigationDelegate = nil
            webView?.stopLoading()
            webView?.removeFromSuperview()
            webView = nil
            panel?.orderOut(nil)
            panel?.close()
            panel = nil
        }
    }

    private final class HTMLSnapshotPanel: NSPanel {
        override var canBecomeKey: Bool { false }
        override var canBecomeMain: Bool { false }
    }

    nonisolated private static func imageThumbnail(at url: URL, pixelSize: Int) throws -> CGImage? {
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        try Task.checkCancellation()
        return image
    }

    nonisolated private static func pdfThumbnail(at url: URL, pixelSize: Int) throws -> CGImage? {
        try Task.checkCancellation()
        guard let document = CGPDFDocument(url as CFURL), let page = document.page(at: 1) else { return nil }
        let pageRect = page.getBoxRect(.cropBox)
        let rotation = abs(page.rotationAngle) % 180
        let sourceSize = rotation == 90
            ? CGSize(width: pageRect.height, height: pageRect.width)
            : pageRect.size
        guard let dimensions = fittedDimensions(sourceSize, pixelSize: pixelSize),
              let context = bitmapContext(width: dimensions.width, height: dimensions.height) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(bounds)
        context.concatenate(page.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true))
        context.drawPDFPage(page)
        try Task.checkCancellation()
        return context.makeImage()
    }

    nonisolated private static func textThumbnail(at url: URL, pixelSize: Int) throws -> CGImage? {
        try Task.checkCancellation()
        let text = TextPreviewBuffer.load(at: url)
        let width = max(1, Int(Double(pixelSize) * 0.76))
        guard let context = bitmapContext(width: width, height: pixelSize) else { return nil }
        let bounds = CGRect(x: 0, y: 0, width: width, height: pixelSize)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(bounds)
        let font = CTFontCreateWithName("Menlo" as CFString, CGFloat(pixelSize) * 0.042, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.12, alpha: 1)
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(string as CFAttributedString)
        let margin = CGFloat(pixelSize) * 0.06
        let path = CGPath(rect: bounds.insetBy(dx: margin, dy: margin), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(frame, context)
        try Task.checkCancellation()
        return context.makeImage()
    }

    nonisolated private static func fittedImage(_ image: CGImage, pixelSize: Int) -> CGImage {
        guard max(image.width, image.height) > pixelSize,
              let dimensions = fittedDimensions(
                CGSize(width: image.width, height: image.height), pixelSize: pixelSize
              ),
              let context = bitmapContext(width: dimensions.width, height: dimensions.height) else { return image }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height))
        return context.makeImage() ?? image
    }

    nonisolated private static func fittedDimensions(_ source: CGSize, pixelSize: Int) -> (width: Int, height: Int)? {
        guard source.width.isFinite, source.height.isFinite, source.width > 0, source.height > 0 else { return nil }
        let scale = CGFloat(pixelSize) / max(source.width, source.height)
        return (max(1, Int((source.width * scale).rounded())), max(1, Int((source.height * scale).rounded())))
    }

    nonisolated private static func bitmapContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
}
