import AppKit
import SnapshotTesting
import SwiftUI
import Testing

/// Offscreen snapshot checks for appearance contracts (theme, language, width,
/// zoom) that do not need the real event system, so they run without taking
/// over the screen like XCUITest does.
///
/// References live in `ZforgeSnapshots/<test file>/` at the project root, outside
/// the synchronized test folder so they are not copied into the test bundle.
/// A missing reference is recorded and the test fails once; review the recorded
/// image before committing it. Set `ZFORGE_RECORD_SNAPSHOTS=1` to re-record
/// deliberately after an approved visual change.
///
/// The unit test host is isolated from the user's preferences and grants (ZF-54), so the
/// sandbox does not let it write into the project. A reference it cannot write is attached
/// to the test result under its path in the project; `Scripts/export-snapshots.py` copies
/// those attachments from the `.xcresult` into `ZforgeSnapshots/`.
@MainActor
enum ZforgeSnapshot {
    nonisolated static let appearances: [(name: String, appearance: NSAppearance.Name)] = [("light", .aqua), ("dark", .darkAqua)]

    /// Hosts a SwiftUI view at a fixed size and appearance and compares it with its reference.
    static func assert<V: View>(
        _ view: V, size: CGSize, appearance: NSAppearance.Name, named name: String,
        precision: Float = 1, perceptualPrecision: Float = 0.98,
        fileID: StaticString = #fileID, filePath: StaticString = #filePath,
        testName: String = #function, line: UInt = #line, column: UInt = #column
    ) {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        host.frame = CGRect(origin: .zero, size: size)
        assert(host, appearance: appearance, named: name, precision: precision, perceptualPrecision: perceptualPrecision,
               fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    /// Compares an AppKit view, laid out at its current frame, with its reference.
    static func assert(
        _ view: NSView, appearance: NSAppearance.Name, named name: String,
        precision: Float = 1, perceptualPrecision: Float = 0.98,
        fileID: StaticString = #fileID, filePath: StaticString = #filePath,
        testName: String = #function, line: UInt = #line, column: UInt = #column
    ) {
        view.appearance = NSAppearance(named: appearance)
        view.layoutSubtreeIfNeeded()
        verify(view, as: .image(precision: precision, perceptualPrecision: perceptualPrecision), named: name,
               recording: { pngData(of: view) },
               fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    /// Compares an image (for example a menu symbol) with its reference.
    static func assert(
        _ image: NSImage, named name: String, precision: Float = 1, perceptualPrecision: Float = 0.98,
        fileID: StaticString = #fileID, filePath: StaticString = #filePath,
        testName: String = #function, line: UInt = #line, column: UInt = #column
    ) {
        verify(image, as: .image(precision: precision, perceptualPrecision: perceptualPrecision), named: name,
               recording: { pngData(of: image) },
               fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    private static func verify<Value, Format>(
        _ value: Value, as strategy: Snapshotting<Value, Format>, named name: String,
        recording: () -> Data?,
        fileID: StaticString, filePath: StaticString, testName: String, line: UInt, column: UInt
    ) {
        let file = URL(fileURLWithPath: "\(filePath)")
        let directory = file.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ZforgeSnapshots", isDirectory: true)
            .appendingPathComponent(file.deletingPathExtension().lastPathComponent, isDirectory: true)
        let record: SnapshotTestingConfiguration.Record =
            ProcessInfo.processInfo.environment["ZFORGE_RECORD_SNAPSHOTS"] == "1" ? .all : .missing
        let started = Date()
        let failure = withSnapshotTesting(record: record) {
            verifySnapshot(of: value, as: strategy, named: name, snapshotDirectory: directory.path,
                           fileID: fileID, file: filePath, testName: testName, line: line, column: column)
        }
        guard let failure else { return }
        let location = SourceLocation(fileID: "\(fileID)", filePath: "\(filePath)", line: Int(line), column: Int(column))
        let reference = directory.appendingPathComponent("\(sanitizedPathComponent(testName)).\(name).\(strategy.pathExtension ?? "png")")
        // The library records a missing reference (or every one with `.all`); when the sandbox
        // stopped it, the file is absent or older than this check.
        let modified = (try? FileManager.default.attributesOfItem(atPath: reference.path))?[.modificationDate] as? Date
        let recordingFailed = (record == .all || failure.contains("No reference was found") || modified == nil)
            && (modified ?? .distantPast) < started
        if recordingFailed {
            let recorded = recording()
            let projectPath = "ZforgeSnapshots/\(directory.lastPathComponent)/\(reference.lastPathComponent)"
            if let recorded {
                // Result bundles drop "/" from attachment names; the export script maps "__" back.
                Attachment.record(recorded, named: projectPath.replacingOccurrences(of: "/", with: "__"), sourceLocation: location)
                Issue.record(Comment(rawValue: "\(failure)\nRecorded as the attachment \(projectPath); copy it into the project with Scripts/export-snapshots.py <result bundle>, then review it."),
                             sourceLocation: location)
                return
            }
        }
        Issue.record(Comment(rawValue: failure), sourceLocation: location)
    }

    /// Waits until `icon` (by default the application icon, which `NSAlert` shows) draws as
    /// Zforge's own icon rather than IconServices' placeholder.
    ///
    /// IconServices renders the application icon on demand. When the render misses its
    /// deadline on a loaded machine, the icon draws a dashed placeholder; in the full unit plan
    /// this made the write-back alert snapshots fail intermittently (D-89). The check draws the
    /// icon at 64 pt and compares it with the bundle's icon file: the rendered icon differs
    /// from it by about 7 / 255 per channel on average (glass rendering), the placeholder by
    /// about 106. Each draw asks IconServices again. The hang guard counts attempts.
    static func waitUntilApplicationIconRenders(
        _ icon: NSImage? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async throws {
        let icon = try #require(icon ?? NSImage(named: NSImage.applicationIconName), sourceLocation: sourceLocation)
        let name = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String, sourceLocation: sourceLocation)
        let fileURL = try #require(Bundle.main.url(forResource: (name as NSString).deletingPathExtension, withExtension: "icns"),
                                   sourceLocation: sourceLocation)
        let expected = rendering(of: try #require(NSImage(contentsOf: fileURL), sourceLocation: sourceLocation))
        var difference = Double.infinity
        for attempt in 0..<100 {
            difference = meanDifference(rendering(of: icon), expected)
            if difference < 40 { return }
            if attempt < 99 { try await Task.sleep(for: .milliseconds(100)) }
        }
        Issue.record(Comment(rawValue: "The application icon still draws IconServices' placeholder after 100 attempts (mean difference \(difference) from the bundle's icon)."),
                     sourceLocation: sourceLocation)
    }

    private static func rendering(of image: NSImage) -> NSBitmapImageRep {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 128, pixelsHigh: 128, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = NSSize(width: 64, height: 64)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(x: 0, y: 0, width: 64, height: 64))
        NSGraphicsContext.restoreGraphicsState()
        return bitmap
    }

    private static func meanDifference(_ first: NSBitmapImageRep, _ second: NSBitmapImageRep) -> Double {
        guard let a = first.bitmapData, let b = second.bitmapData else { return .infinity }
        let count = first.bytesPerRow * first.pixelsHigh
        var total = 0
        for index in 0..<count { total += abs(Int(a[index]) - Int(b[index])) }
        return Double(total) / Double(count)
    }

    /// The image swift-snapshot-testing records for a view: its cached display.
    private static func pngData(of view: NSView) -> Data? {
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap.representation(using: .png, properties: [:])
    }

    private static func pngData(of image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// The reference file name swift-snapshot-testing derives from a test name.
    private static func sanitizedPathComponent(_ string: String) -> String {
        string.replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
    }
}
