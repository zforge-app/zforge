import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("File icon rendering")
struct FileIconViewTests {
    @Test("Composed folder icons remain resolution independent")
    @MainActor
    func composedFolderIconIsResolutionIndependent() {
        let baseIcon = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { bounds in
            NSColor.systemBlue.setFill()
            bounds.fill()
            return true
        }

        let composed = NonEmptyFolderIconComposer.compose(from: baseIcon)

        #expect(composed.representations.contains { $0 is NSCustomImageRep })
    }

    @Test("Open drop-target folders reflect their actual contents state")
    @MainActor
    func openDropTargetFolderReflectsContentsState() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeOpenFolderIcon-\(UUID().uuidString)", isDirectory: true)
        let empty = root.appendingPathComponent("Empty", isDirectory: true)
        let nonEmpty = root.appendingPathComponent("NonEmpty", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nonEmpty, withIntermediateDirectories: true)
        try Data().write(to: nonEmpty.appendingPathComponent("document.txt"))

        let emptyIcon = FileIconCache.shared.openFolderIcon(for: empty)
        let nonEmptyIcon = FileIconCache.shared.openFolderIcon(for: nonEmpty)

        #expect(!emptyIcon.representations.contains { $0 is NSCustomImageRep })
        #expect(nonEmptyIcon.representations.contains { $0 is NSCustomImageRep })
    }
}
