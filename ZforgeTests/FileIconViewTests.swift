import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("File icon rendering")
struct FileIconViewTests {
    @Test("Folder tint keeps transparency and uses the requested hue")
    @MainActor
    func folderTintRendering() throws {
        let base = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { _ in
            NSColor.systemBlue.setFill()
            NSRect(x: 8, y: 8, width: 48, height: 48).fill()
            NSColor.white.setFill()
            NSRect(x: 12, y: 46, width: 40, height: 6).fill()
            return true
        }
        let red = FolderTagIconColor.compose(base, colorIndex: 6)
        let redData = try #require(red.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: redData))
        let center = try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.deviceRGB))
        #expect(center.redComponent > center.blueComponent)
        #expect(bitmap.colorAt(x: 0, y: 0)?.alphaComponent == 0)
        let neutral = FolderTagIconColor.recolored(red: 0.96, green: 0.96, blue: 0.96, index: 5)
        #expect(neutral.0 == 0.96 && neutral.1 == 0.96 && neutral.2 == 0.96)
        let paperPixels = (0..<bitmap.pixelsHigh).compactMap { bitmap.colorAt(x: bitmap.pixelsWide / 2, y: $0)?.usingColorSpace(.deviceRGB) }
        #expect(paperPixels.contains { $0.redComponent > 0.99 && $0.greenComponent > 0.99 && $0.blueComponent > 0.99 && $0.alphaComponent > 0.99 })
    }

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
