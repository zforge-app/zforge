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

        let composed = ArchiveFolderIconComposer.compose(from: baseIcon, scale: .large, containsFiles: true, showsArchiveStamp: false)

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

        #expect(emptyIcon.representations.contains { $0 is NSCustomImageRep })
        #expect(emptyIcon !== nonEmptyIcon)
        #expect(nonEmptyIcon.representations.contains { $0 is NSCustomImageRep })
    }

    @Test("Local folders share archive material and contents geometry without the compression seal")
    @MainActor
    func localFoldersHaveConsistentUnstampedStates() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalFolderStates-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        func bitmap(_ image: NSImage) throws -> NSBitmapImageRep {
            var bounds = NSRect(origin: .zero, size: image.size)
            return NSBitmapImageRep(cgImage: try #require(image.cgImage(forProposedRect: &bounds, context: nil, hints: nil)))
        }
        for hasContents in [false, true] {
            let folder = root.appendingPathComponent(hasContents ? "Full" : "Empty")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if hasContents { try Data().write(to: folder.appendingPathComponent("file.txt")) }
            for isOpen in [false, true] {
                let local = try bitmap(isOpen ? FileIconCache.shared.openFolderIcon(for: folder) : FileIconCache.shared.icon(for: folder))
                let archive = try bitmap(FileIconCache.shared.archiveDirectoryIcon(size: 190, containsFiles: hasContents, isExpanded: isOpen))
                var changedSealPixels = 0
                for y in stride(from: 0, to: local.pixelsHigh, by: 6) {
                    for x in stride(from: 0, to: local.pixelsWide, by: 6) {
                        let a = try #require(local.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                        let b = try #require(archive.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                        let difference = max(abs(a.redComponent - b.redComponent), abs(a.greenComponent - b.greenComponent), abs(a.blueComponent - b.blueComponent))
                        let insideSeal = Double(x) / Double(local.pixelsWide) > 0.54 && Double(y) / Double(local.pixelsHigh) > 0.43
                        if insideSeal, difference > 0.03 { changedSealPixels += 1 }
                        if !insideSeal { #expect(difference < 0.015) }
                    }
                }
                #expect(changedSealPixels > 20)
            }
        }
    }

    @Test("Approved archive relief is bundled and has neutral light and shadow masks")
    @MainActor
    func approvedArchiveReliefIsAvailable() throws {
        let relief = try #require(ArchiveFolderIconComposer.approvedRelief)
        let dark = try #require(relief.shadows.representations.first as? NSBitmapImageRep)
        let light = try #require(relief.highlights.representations.first as? NSBitmapImageRep)
        var shadedPixels = 0
        var litPixels = 0
        for y in stride(from: 0, to: dark.pixelsHigh, by: 4) {
            for x in stride(from: 0, to: dark.pixelsWide, by: 4) {
                let shadow = try #require(dark.colorAt(x: x, y: y))
                let highlight = try #require(light.colorAt(x: x, y: y))
                if shadow.alphaComponent > 0.05 { shadedPixels += 1 }
                if highlight.alphaComponent > 0.05 { litPixels += 1 }
                // No blue pixels from the reference folder may enter the lighting masks.
                #expect(shadow.redComponent == shadow.greenComponent)
                #expect(shadow.greenComponent == shadow.blueComponent)
                #expect(highlight.redComponent == highlight.greenComponent)
                #expect(highlight.greenComponent == highlight.blueComponent)
            }
        }
        #expect(shadedPixels > 500)
        #expect(litPixels > 100)
        #expect(dark.colorAt(x: 0, y: 0)?.alphaComponent == 0)
        #expect(light.colorAt(x: 0, y: 0)?.alphaComponent == 0)
    }


    @Test("Archive folders with files reveal paper while empty folders keep the native face")
    @MainActor
    func closedArchiveFolderContents() throws {
        let empty = FileIconCache.shared.archiveDirectoryIcon(size: 190, containsFiles: false)
        let full = FileIconCache.shared.archiveDirectoryIcon(size: 190, containsFiles: true)
        #expect(empty !== full)
        #expect(full === FileIconCache.shared.archiveDirectoryIcon(size: 190, containsFiles: true))
        func paperPixel(_ image: NSImage, y: Double = 0.255) throws -> NSColor {
            var bounds = NSRect(origin: .zero, size: image.size)
            let cgImage = try #require(image.cgImage(forProposedRect: &bounds, context: nil, hints: nil))
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            return try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2,
                y: Int(Double(bitmap.pixelsHigh) * y))?.usingColorSpace(.deviceRGB))
        }
        let emptyPixel = try paperPixel(empty)
        let fullPixel = try paperPixel(full)
        #expect(fullPixel.redComponent > 0.85)
        #expect(abs(fullPixel.redComponent - fullPixel.blueComponent) < 0.06)
        #expect(emptyPixel.blueComponent - emptyPixel.redComponent > 0.15)
        // The native front lip must cover the document, rather than becoming white.
        let fullLip = try paperPixel(full, y: 0.28)
        let emptyLip = try paperPixel(empty, y: 0.28)
        #expect(fullLip.blueComponent - fullLip.redComponent > 0.15)
        #expect(abs(fullLip.redComponent - emptyLip.redComponent) < 0.02)
        #expect(abs(fullLip.greenComponent - emptyLip.greenComponent) < 0.02)
        #expect(abs(fullLip.blueComponent - emptyLip.blueComponent) < 0.02)
    }

    @Test("Folder expansion uses the open icon only in List and archive states have separate cache entries")
    @MainActor
    func archiveExpansionIconState() throws {
        let defaultsName = "ArchiveExpansionIcons-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let state = FileBrowserState(
            preferences: FileBrowserPreferences(defaults: defaults),
            fileSystem: UIFixtureFileSystemService(),
            grants: UIFixtureAccessGrantStore(), archives: UIFixtureArchiveEngine()
        )
        var folder = BrowserItem(
            id: BrowserItemID(rawValue: "archive-folder"), name: "Folder",
            location: .archive(ArchiveAddress(sessionID: UUID(), archiveID: UUID(), internalPath: "Folder")),
            isContainer: true, isDirectory: true, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: false,
            size: 0, packedSize: nil, creationDate: nil, modificationDate: nil,
            accessDate: nil, tags: [], contentTypeIdentifier: nil,
            encrypted: false, checksum: nil, compressionMethod: nil
        )
        state.preferences.viewMode = .list
        #expect(!state.usesOpenFolderIcon(for: folder))
        state.expandedItems.insert(folder.id)
        #expect(state.usesOpenFolderIcon(for: folder))
        folder.archiveDirectoryContainsFiles = true
        #expect(state.usesOpenFolderIcon(for: folder))
        for mode in [BrowserViewMode.columns, .icons, .gallery] {
            state.preferences.viewMode = mode
            #expect(!state.usesOpenFolderIcon(for: folder))
        }
        state.preferences.viewMode = .list
        state.expandedItems.remove(folder.id)
        #expect(!state.usesOpenFolderIcon(for: folder))
        state.expandedItems.insert(folder.id)
        let localFolder = BrowserItem(
            id: folder.id, name: "Folder", location: .fileSystem(URL(fileURLWithPath: "/tmp/Folder")),
            isContainer: true, isDirectory: true, isPackage: false,
            isSymbolicLink: false, isHidden: false, isArchive: false,
            size: 0, packedSize: nil, creationDate: nil, modificationDate: nil,
            accessDate: nil, tags: [], contentTypeIdentifier: nil,
            encrypted: false, checksum: nil, compressionMethod: nil
        )
        #expect(state.usesOpenFolderIcon(for: localFolder))
        for size: CGFloat in [16, 24, 32, 48, 64, 190] {
            for hasFiles in [false, true] {
                let open = FileIconCache.shared.archiveDirectoryIcon(size: size, containsFiles: hasFiles, isExpanded: true)
                let closed = FileIconCache.shared.archiveDirectoryIcon(size: size, containsFiles: hasFiles)
                #expect(open !== closed)
                #expect(open === FileIconCache.shared.archiveDirectoryIcon(size: size, containsFiles: hasFiles, isExpanded: true))
                #expect(open.tiffRepresentation != closed.tiffRepresentation)
            }
        }
    }

    @Test("Open archive folders preserve the closed folder material through the face tilt")
    @MainActor
    func openArchiveFolderPreservesMaterial() throws {
        func bitmap(_ image: NSImage) throws -> NSBitmapImageRep {
            var bounds = NSRect(origin: .zero, size: image.size)
            return NSBitmapImageRep(cgImage: try #require(image.cgImage(forProposedRect: &bounds, context: nil, hints: nil)))
        }
        let closed = try bitmap(FileIconCache.shared.archiveDirectoryIcon(size: 190))
        let open = try bitmap(FileIconCache.shared.archiveDirectoryIcon(size: 190, isExpanded: true))
        func color(_ bitmap: NSBitmapImageRep, x: Double, y: Double) throws -> NSColor {
            try #require(bitmap.colorAt(x: Int(x * Double(bitmap.pixelsWide)),
                                        y: Int((1 - y) * Double(bitmap.pixelsHigh)))?.usingColorSpace(.deviceRGB))
        }
        for (x, y) in [(0.28, 0.35), (0.40, 0.50), (0.50, 0.58)] {
            let t = (y - 0.13) / 0.53
            let margin = -0.02 * t
            let original = try color(closed, x: (x - margin) / (1 - 2 * margin), y: 0.13 + 0.60 * t)
            let tilted = try color(open, x: x, y: y)
            #expect(abs(original.redComponent - tilted.redComponent) < 0.02)
            #expect(abs(original.greenComponent - tilted.greenComponent) < 0.02)
            #expect(abs(original.blueComponent - tilted.blueComponent) < 0.02)
            #expect(tilted.alphaComponent > 0.98)
        }
        #expect(try color(open, x: 0.05, y: 0.20).alphaComponent > 0.98)
        #expect(try color(open, x: 0.03, y: 0.60).alphaComponent > 0.98)
        #expect(try color(closed, x: 0.03, y: 0.60).alphaComponent < 0.15)
        #expect(try color(closed, x: 0.05, y: 0.20).alphaComponent > 0.98)
    }

}
