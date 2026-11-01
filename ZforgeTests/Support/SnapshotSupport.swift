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
