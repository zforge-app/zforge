import AppKit
import Testing
@testable import Zforge

@Suite("Icon preview loading", .timeLimit(.minutes(1)))
@MainActor
struct IconPreviewServiceTests {
    @Test("Disabling previews clears content and never requests background work")
    func disabledPreviews() async throws {
        let model = IconPreviewModel()
        let image = try sampleImage()
        var calls = 0
        let loader: @MainActor (BrowserItem, Int) async throws -> CGImage? = { _, _ in calls += 1; return image }
        await model.load(item: item("Photo.png"), pixelSize: 128, enabled: true, loader: loader)
        #expect(model.image === image)
        await model.load(item: item("Photo.png"), pixelSize: 128, enabled: false, loader: loader)
        #expect(model.image == nil)
        #expect(calls == 1)
    }

    @Test("Every noncontainer format requests a preview and containers retain their icons")
    func eligibility() async throws {
        var names: [String] = []
        let service = IconPreviewService { item, _, _ in names.append(item.name); return nil }
        for name in ["Photo.png", "Photo.jpg", "Document.pdf", "Table.csv", "Page.html", "Document.docx", "Slides.pptx", "Movie.mov", "Sound.mp3", "Unknown.bin"] {
            _ = try await service.image(for: item(name), pixelSize: 128, archives: UIFixtureArchiveEngine())
        }
        #expect(names.count == 10)
        _ = try await service.image(for: item("Folder", directory: true), pixelSize: 128, archives: UIFixtureArchiveEngine())
        _ = try await service.image(for: item("Container.zip", archive: true), pixelSize: 128, archives: UIFixtureArchiveEngine())
        #expect(names.count == 10)
    }

    @Test("Success and unavailable representations are cached, revisions and zoom reload")
    func cacheInvalidation() async throws {
        let image = try sampleImage()
        var calls = 0
        var dimensions: [Int] = []
        let service = IconPreviewService { item, _, pixels in
            calls += 1; dimensions.append(pixels)
            return item.name == "Unknown.bin" ? nil : image
        }
        let archives = UIFixtureArchiveEngine()
        for _ in 0..<2 {
            #expect(try await service.image(for: item("Photo.png"), pixelSize: 128, archives: archives) === image)
            #expect(try await service.image(for: item("Unknown.bin"), pixelSize: 128, archives: archives) == nil)
        }
        #expect(calls == 2)
        _ = try await service.image(for: item("Photo.png", revision: 2), pixelSize: 128, archives: archives)
        _ = try await service.image(for: item("Photo.png"), pixelSize: 256, archives: archives)
        _ = try await service.image(for: item("Photo.png"), pixelSize: 1_024, archives: archives)
        #expect(calls == 4)
        #expect(dimensions == [128, 128, 128, 256])
    }

    @Test("Transient rendering errors retain fallback and can recover on the next request")
    func failedPreviewCanRecover() async throws {
        var calls = 0
        let image = try sampleImage()
        let service = IconPreviewService { _, _, _ in
            calls += 1
            if calls == 1 { throw CocoaError(.fileReadNoPermission) }
            return image
        }
        let model = IconPreviewModel()
        let archives = UIFixtureArchiveEngine()
        let loader: @MainActor (BrowserItem, Int) async throws -> CGImage? = {
            try await service.image(for: $0, pixelSize: $1, archives: archives)
        }
        await model.load(item: item("Photo.png"), pixelSize: 128, enabled: true, loader: loader)
        #expect(model.image == nil)
        await model.load(item: item("Photo.png"), pixelSize: 128, enabled: true, loader: loader)
        #expect(model.image === image)
        #expect(calls == 2)
    }

    @Test("The bitmap cache evicts least recently used content before exceeding 16 MiB")
    func bitmapCacheIsBounded() async throws {
        let image = try sampleImage(width: 256, height: 256)
        #expect(image.bytesPerRow * image.height == 256 * 256 * 4)
        var calls = 0
        let service = IconPreviewService { _, _, _ in calls += 1; return image }
        let archives = UIFixtureArchiveEngine()
        for index in 0..<65 {
            _ = try await service.image(for: item("\(index).png"), pixelSize: 256, archives: archives)
        }
        #expect(calls == 65)
        _ = try await service.image(for: item("1.png"), pixelSize: 256, archives: archives)
        #expect(calls == 65)
        _ = try await service.image(for: item("65.png"), pixelSize: 256, archives: archives)
        _ = try await service.image(for: item("1.png"), pixelSize: 256, archives: archives)
        #expect(calls == 66)
        _ = try await service.image(for: item("0.png"), pixelSize: 256, archives: archives)
        #expect(calls == 67)
    }

    @Test("Late completion cannot restore a replaced item or a disabled preference")
    func staleCompletionIsDiscarded() async throws {
        let model = IconPreviewModel()
        let gate = PreviewTestGate()
        let old = try sampleImage()
        let current = try sampleImage()
        let first = Task { await model.load(item: item("Old.png"), pixelSize: 128, enabled: true) { _, _ in
            await gate.pause(); return old
        } }
        await gate.waitUntilStarted()
        await model.load(item: item("New.png"), pixelSize: 128, enabled: true) { _, _ in current }
        gate.release()
        await first.value
        #expect(model.item?.name == "New.png")
        #expect(model.image === current)
        await model.load(item: item("New.png"), pixelSize: 128, enabled: false) { _, _ in old }
        #expect(model.image == nil)
    }

    @Test("Zoom retains the current file preview while replacing its raster and discards obsolete sizes")
    func zoomKeepsCurrentContentUntilReplacement() async throws {
        let model = IconPreviewModel()
        let file = item("Photo.png")
        let initial = try sampleImage()
        let current = try sampleImage()
        let obsolete = try sampleImage()
        await model.load(item: file, pixelSize: 128, enabled: true) { _, _ in initial }
        let gate = PreviewTestGate()
        let pending = Task {
            await model.load(item: file, pixelSize: 256, enabled: true) { _, _ in
                await gate.pause()
                return obsolete
            }
        }
        await gate.waitUntilStarted()
        #expect(model.image === initial)
        await model.load(item: file, pixelSize: 192, enabled: true) { _, _ in current }
        gate.release()
        await pending.value
        #expect(model.pixelSize == 192)
        #expect(model.image === current)
    }

    @Test("Cancelled queued work never renders and active work respects the concurrency limit")
    func queuedCancellation() async throws {
        let gate = PreviewTestGate()
        let queued = PreviewTestGate()
        var rendered: [String] = []
        let service = IconPreviewService(maximumConcurrentRequests: 1) { item, _, _ in
            rendered.append(item.name)
            if item.name == "First.png" { await gate.pause() }
            return nil
        }
        service.requestDidQueue = { queued.signalStarted() }
        let archives = UIFixtureArchiveEngine()
        let first = Task { try await service.image(for: item("First.png"), pixelSize: 128, archives: archives) }
        await gate.waitUntilStarted()
        let second = Task { try await service.image(for: item("Cancelled.png"), pixelSize: 128, archives: archives) }
        await queued.waitUntilStarted()
        second.cancel()
        await #expect(throws: CancellationError.self) { _ = try await second.value }
        gate.release()
        _ = try await first.value
        _ = try await service.image(for: item("Next.png"), pixelSize: 128, archives: archives)
        #expect(rendered == ["First.png", "Next.png"])
    }

    @Test("Automatic archive thumbnails skip oversized and unknown-size entries")
    func automaticArchiveLimits() async throws {
        var calls = 0
        let service = IconPreviewService { _, _, _ in calls += 1; return nil }
        let address = ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: "Preview.txt")
        let archives = UIFixtureArchiveEngine()
        for size in [nil, IconPreviewService.archiveByteLimit + 1] {
            _ = try await service.image(for: item("Preview.txt", location: .archive(address), bytes: size), pixelSize: 128, archives: archives)
        }
        #expect(calls == 0)
        _ = try await service.image(for: item("Preview.txt", location: .archive(address), bytes: IconPreviewService.archiveByteLimit), pixelSize: 128, archives: archives)
        #expect(calls == 1)
    }

    private func item(_ name: String, directory: Bool = false, archive: Bool = false,
                      location: BrowserLocation? = nil, bytes: Int64? = 128, revision: TimeInterval = 1) -> BrowserItem {
        BrowserItem(id: BrowserItemID(rawValue: name), name: name,
            location: location ?? .fileSystem(URL(fileURLWithPath: "/tmp/IconPreviewTests/\(name)")),
            isContainer: directory, isDirectory: directory, isPackage: false, isSymbolicLink: false,
            isHidden: false, isArchive: archive, size: bytes, packedSize: nil, creationDate: nil,
            modificationDate: Date(timeIntervalSince1970: revision), accessDate: nil, tags: [],
            contentTypeIdentifier: nil, encrypted: false, checksum: nil, compressionMethod: nil)
    }

    private func sampleImage(width: Int = 32, height: Int = 16) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        return try #require(context.makeImage())
    }
}

@MainActor
private final class PreviewTestGate {
    private var pending: CheckedContinuation<Void, Never>?
    private var started = false
    private var observer: CheckedContinuation<Void, Never>?
    func pause() async {
        await withCheckedContinuation { pending = $0; signalStarted() }
    }
    func signalStarted() { started = true; observer?.resume(); observer = nil }
    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { observer = $0 }
    }
    func release() { pending?.resume(); pending = nil }
}
