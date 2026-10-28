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
               fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    /// Compares an image (for example a menu symbol) with its reference.
    static func assert(
        _ image: NSImage, named name: String, precision: Float = 1, perceptualPrecision: Float = 0.98,
        fileID: StaticString = #fileID, filePath: StaticString = #filePath,
        testName: String = #function, line: UInt = #line, column: UInt = #column
    ) {
        verify(image, as: .image(precision: precision, perceptualPrecision: perceptualPrecision), named: name,
               fileID: fileID, filePath: filePath, testName: testName, line: line, column: column)
    }

    private static func verify<Value, Format>(
        _ value: Value, as strategy: Snapshotting<Value, Format>, named name: String,
        fileID: StaticString, filePath: StaticString, testName: String, line: UInt, column: UInt
    ) {
        let file = URL(fileURLWithPath: "\(filePath)")
        let directory = file.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ZforgeSnapshots", isDirectory: true)
            .appendingPathComponent(file.deletingPathExtension().lastPathComponent, isDirectory: true)
        let record: SnapshotTestingConfiguration.Record =
            ProcessInfo.processInfo.environment["ZFORGE_RECORD_SNAPSHOTS"] == "1" ? .all : .missing
        let failure = withSnapshotTesting(record: record) {
            verifySnapshot(of: value, as: strategy, named: name, snapshotDirectory: directory.path,
                           fileID: fileID, file: filePath, testName: testName, line: line, column: column)
        }
        if let failure {
            Issue.record(Comment(rawValue: failure),
                         sourceLocation: SourceLocation(fileID: "\(fileID)", filePath: "\(filePath)", line: Int(line), column: Int(column)))
        }
    }
}
