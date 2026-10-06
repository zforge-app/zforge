import AppKit
import CoreGraphics
import Darwin
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Zforge

/// Reproducible measurements, with structural/resource assertions rather than timing
/// thresholds that would conflate runner load with a product regression.
@Suite("Icon preview performance", .serialized)
@MainActor
struct IconPreviewPerformanceTests {
    @Test("Measure disabled, cold 200-file, and warm 32-file icon workloads")
    func mixedFileWorkload() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IconPreviewBenchmark-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        // Encoding the source images is setup, not UI work or part of the measured
        // workload. Keep it off the main actor shared by the interaction tests.
        try await Task.detached(priority: .utility) {
            try Self.makeFixtures(in: directory)
        }.value
        let fileSystem = FileSystemService()
        var items: [BrowserItem] = []
        for index in 0..<50 {
            for suffix in ["png", "jpg", "pdf", "txt"] {
                items.append(try await fileSystem.item(at: directory.appendingPathComponent("File-\(index).\(suffix)")))
            }
        }

        let provider = IconPreviewRenderer()
        let metrics = PreviewBenchmarkMetrics()
        let service = IconPreviewService { item, url, pixels in
            metrics.renderCalls += 1
            metrics.activeRequests += 1
            metrics.maximumActiveRequests = max(metrics.maximumActiveRequests, metrics.activeRequests)
            defer { metrics.activeRequests -= 1 }
            let image = try await provider.image(for: item, at: url, pixelSize: pixels)
            if let image {
                metrics.outputCount += 1
                let cost = image.bytesPerRow * image.height
                metrics.maximumOutputBytes = max(metrics.maximumOutputBytes, cost)
                metrics.maximumPixelDimension = max(metrics.maximumPixelDimension, image.width, image.height)
            }
            return image
        }
        let archives = UIFixtureArchiveEngine()
        let disabledCPUStart = processCPUSeconds()
        let disabledStarted = DispatchTime.now().uptimeNanoseconds
        for item in items {
            await IconPreviewModel().load(item: item, pixelSize: 256, enabled: false) { item, size in
                try await service.image(for: item, pixelSize: size, archives: archives)
            }
        }
        let disabledMilliseconds = milliseconds(since: disabledStarted)
        let disabledCPU = processCPUSeconds() - disabledCPUStart
        #expect(metrics.renderCalls == 0)

        let rssBeforeCold = residentBytes()
        metrics.recording = true
        let pings = Task.detached(priority: .utility) {
            while await metrics.recording {
                let started = DispatchTime.now().uptimeNanoseconds
                await metrics.ping(started: started)
                // Sampling cadence is part of the measurement, not test synchronization.
                do { try await Task.sleep(for: .milliseconds(1)) } catch { return }
            }
        }
        let coldCPUStart = processCPUSeconds()
        let coldStarted = DispatchTime.now().uptimeNanoseconds
        // Explicit actor-inherited tasks avoid a Swift 6 region-checker failure
        // for an isolated closure passed to TaskGroup.addTask in the current SDK.
        let jobs = items.map { item in
            Task { @MainActor in
                _ = try await service.image(for: item, pixelSize: 256, archives: archives)
            }
        }
        defer { jobs.forEach { $0.cancel() } }
        for job in jobs { try await job.value }
        let coldMilliseconds = milliseconds(since: coldStarted)
        let coldCPU = processCPUSeconds() - coldCPUStart
        metrics.recording = false
        await pings.value
        let rssAfterCold = residentBytes()
        #expect(metrics.renderCalls == 200)
        #expect(metrics.outputCount == 200)
        #expect(metrics.maximumActiveRequests <= 4)
        #expect(metrics.maximumPixelDimension <= 256)
        #expect(metrics.maximumOutputBytes <= 256 * 256 * 4)

        // A visible viewport fits the cache budget even though the complete directory
        // exceeds it. Repeat the most recently requested 32 mixed files at max pixels.
        let callsBeforeWarm = metrics.renderCalls
        let warmCPUStart = processCPUSeconds()
        let warmStarted = DispatchTime.now().uptimeNanoseconds
        for item in items.suffix(32) {
            _ = try await service.image(for: item, pixelSize: 256, archives: archives)
        }
        let warmMilliseconds = milliseconds(since: warmStarted)
        let warmCPU = processCPUSeconds() - warmCPUStart
        #expect(metrics.renderCalls == callsBeforeWarm)

        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let pingDelays = metrics.pingDelays.sorted()
        let p95Index = max(0, Int((Double(pingDelays.count) * 0.95).rounded(.up)) - 1)
        let result: [String: Any] = [
            "workload": "200 local files: 50 PNG, 50 JPEG (2560x1600), 50 three-page PDF, 50 32-KiB text; requested 256 pixels",
            "baselineDisabledFiles": items.count,
            "baselineDisabledMilliseconds": disabledMilliseconds,
            "baselineDisabledCPUSeconds": disabledCPU,
            "coldMilliseconds": coldMilliseconds,
            "coldCPUSeconds": coldCPU,
            "warmViewportFiles": 32,
            "warmMilliseconds": warmMilliseconds,
            "warmCPUSeconds": warmCPU,
            "warmAdditionalRenderCalls": metrics.renderCalls - callsBeforeWarm,
            "coldRenderCalls": callsBeforeWarm,
            "maximumConcurrentServiceRequests": metrics.maximumActiveRequests,
            "maximumRasterBytes": metrics.maximumOutputBytes,
            "maximumRasterDimension": metrics.maximumPixelDimension,
            "residentBytesBeforeCold": rssBeforeCold,
            "residentBytesAfterCold": rssAfterCold,
            "processPeakResidentBytes": usage.ru_maxrss,
            "mainActorPingSamples": pingDelays.count,
            "mainActorPingMaximumMilliseconds": pingDelays.last ?? 0,
            "mainActorPingP95Milliseconds": pingDelays.isEmpty ? 0 : pingDelays[p95Index]
        ]
        let json = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
        Attachment.record(json, named: "icon-preview-benchmark.json")
        print("ICON_PREVIEW_BENCHMARK \(String(decoding: json, as: UTF8.self))")
    }

    nonisolated private static func makeFixtures(in directory: URL) throws {
        let context = try #require(CGContext(
            data: nil, width: 2_560, height: 1_600, bitsPerComponent: 8, bytesPerRow: 2_560 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2_560, height: 1_600))
        context.setFillColor(CGColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 200, y: 200, width: 800, height: 800))
        let image = try #require(context.makeImage())
        for type in [UTType.png, .jpeg] {
            let suffix = type == .png ? "png" : "jpg"
            let url = directory.appendingPathComponent("File-0.\(suffix)")
            let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            #expect(CGImageDestinationFinalize(destination))
        }
        let pdfURL = directory.appendingPathComponent("File-0.pdf")
        var page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let pdf = try #require(CGContext(pdfURL as CFURL, mediaBox: &page, nil))
        for _ in 0..<3 {
            pdf.beginPDFPage(nil)
            pdf.setFillColor(CGColor(gray: 1, alpha: 1))
            pdf.fill(page)
            pdf.setFillColor(CGColor(gray: 0.2, alpha: 1))
            for line in 0..<30 {
                pdf.fill(CGRect(x: 30, y: 30 + line * 22, width: 500, height: 7))
            }
            pdf.endPDFPage()
        }
        pdf.closePDF()
        let text = String(repeating: "Document content for a bounded icon preview.\n", count: 800)
        try Data(text.utf8.prefix(32 * 1_024)).write(to: directory.appendingPathComponent("File-0.txt"))
        for index in 1..<50 {
            for suffix in ["png", "jpg", "pdf", "txt"] {
                try FileManager.default.copyItem(
                    at: directory.appendingPathComponent("File-0.\(suffix)"),
                    to: directory.appendingPathComponent("File-\(index).\(suffix)")
                )
            }
        }
    }

    private func milliseconds(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    }

    private func processCPUSeconds() -> Double {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
            + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
    }

    private func residentBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return status == KERN_SUCCESS ? info.resident_size : 0
    }
}

@MainActor
private final class PreviewBenchmarkMetrics {
    var recording = false
    var renderCalls = 0
    var outputCount = 0
    var activeRequests = 0
    var maximumActiveRequests = 0
    var maximumOutputBytes = 0
    var maximumPixelDimension = 0
    var pingDelays: [Double] = []

    func ping(started: UInt64) {
        guard recording else { return }
        pingDelays.append(Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
    }
}
