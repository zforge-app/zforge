import AppKit
import UniformTypeIdentifiers

// Compile with ArchiveFolderIconComposer.swift.
@main struct Preview {
    static func save(_ image: NSImage, to path: String) throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width * 2), pixelsHigh: Int(image.size.height * 2),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    }

    static func main() throws {
        let directory = CommandLine.arguments[1]
        let reference = CommandLine.arguments.count > 2 ? NSImage(contentsOfFile: CommandLine.arguments[2]) : nil
        reference?.setName("ArchiveFolderRelief")
        defer { withExtendedLifetime(reference) {} }
        let folder = NSWorkspace.shared.icon(for: .folder)
        folder.size = NSSize(width: 512, height: 512)
        let states = [("Fechada vazia", false, false), ("Fechada com conteúdo", true, false), ("Aberta vazia", false, true), ("Aberta com conteúdo", true, true)]
        let output = NSImage(size: NSSize(width: 720, height: 910), flipped: false) { bounds in
            NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
            bounds.fill()
            for (row, state) in states.enumerated() {
                let y = CGFloat(3 - row) * 220 + 28
                (state.0 as NSString).draw(at: NSPoint(x: 16, y: y + 188),
                    withAttributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 14)])
                var x: CGFloat = 16
                for size: CGFloat in [16, 24, 32, 48, 64, 190] {
                    let icon = ArchiveFolderIconComposer.compose(from: folder, scale: .init(size: size), containsFiles: state.1, isOpen: state.2, showsArchiveStamp: false)
                    icon.draw(in: NSRect(x: x, y: y, width: size, height: size))
                    ("\(Int(size)) pt" as NSString).draw(at: NSPoint(x: x, y: y - 20),
                        withAttributes: [.foregroundColor: NSColor.white])
                    x += size + 25
                }
            }
            return true
        }
        try save(ArchiveFolderIconComposer.compose(from: folder, scale: .large, containsFiles: false, isOpen: true, showsArchiveStamp: false), to: directory + "/open-empty-folder-implemented.png")
        try save(ArchiveFolderIconComposer.compose(from: folder, scale: .large, containsFiles: true, isOpen: true, showsArchiveStamp: false), to: directory + "/open-folder-implemented.png")
        try save(output, to: directory + "/folder-states-v2.png")
        for (name, containsFiles) in [("folder", false), ("folder-with-files", true)] {
            try save(ArchiveFolderIconComposer.compose(from: folder, scale: .large, containsFiles: containsFiles, showsArchiveStamp: false),
                     to: directory + "/" + name + "-v2.png")
        }
    }
}
