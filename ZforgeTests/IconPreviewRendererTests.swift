import AppKit
import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Zforge

@Suite("Icon content rendering", .serialized)
@MainActor
struct IconPreviewRendererTests {
    @Test("Image content preserves aspect ratio, transparency and requested pixel bounds")
    func imageContentAndAspectRatio() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Wide.png")
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(
            data: nil, width: 400, height: 200, bitsPerComponent: 8, bytesPerRow: 400 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 40, y: 40, width: 320, height: 120))
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
        #expect(CGImageDestinationFinalize(destination))

        let item = try await FileSystemService().item(at: url)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 160))
        #expect(image.width == 160)
        #expect(image.height == 80)
        let bitmap = NSBitmapImageRep(cgImage: image)
        // Read the declared sRGB sample values directly. NSColor's conversion to a
        // device/calibrated color space changes even the source fixture's green value.
        var center = [UInt](repeating: 0, count: bitmap.samplesPerPixel)
        bitmap.getPixel(&center, atX: 80, y: 40)
        let offset = bitmap.bitmapFormat.contains(.alphaFirst) ? 1 : 0
        #expect(center[offset] == 255)
        #expect(center[offset + 1] == 0)
        #expect(center[offset + 2] == 0)
        #expect(bitmap.colorAt(x: 0, y: 0)?.alphaComponent == 0)
    }

    @Test("SVG content uses the system document provider instead of a bitmap decoder")
    func vectorImageContent() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Vector.svg")
        try "<svg xmlns='http://www.w3.org/2000/svg' width='200' height='100'><rect width='200' height='100' fill='#ff0000'/></svg>"
            .write(to: url, atomically: true, encoding: .utf8)
        let item = try await FileSystemService().item(at: url)
        #expect(item.contentType?.conforms(to: .image) == true)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 160))
        #expect(max(image.width, image.height) <= 160)
        let bitmap = NSBitmapImageRep(cgImage: image)
        Attachment.record(try #require(bitmap.representation(using: .png, properties: [:])), named: "svg-icon-preview.png")
        // The encoded PNG contains exact sRGB red. NSColor conversion through
        // the display profile changes component values; verify raw samples.
        var center = [UInt](repeating: 0, count: bitmap.samplesPerPixel)
        bitmap.getPixel(&center, atX: image.width / 2, y: image.height / 2)
        let offset = bitmap.bitmapFormat.contains(.alphaFirst) ? 1 : 0
        #expect(center[offset] == 255)
        #expect(center[offset + 1] == 0)
        #expect(center[offset + 2] == 0)
    }

    @Test("PDF thumbnail uses the first page and preserves its portrait aspect ratio")
    func pdfFirstPage() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Two pages.pdf")
        var page = CGRect(x: 0, y: 0, width: 200, height: 300)
        let context = try #require(CGContext(url as CFURL, mediaBox: &page, nil))
        for color in [CGColor(red: 1, green: 0, blue: 0, alpha: 1), CGColor(red: 0, green: 0, blue: 1, alpha: 1)] {
            context.beginPDFPage(nil)
            context.setFillColor(color)
            context.fill(page)
            context.endPDFPage()
        }
        context.closePDF()

        let item = try await FileSystemService().item(at: url)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 192))
        #expect(image.width == 128)
        #expect(image.height == 192)
        let bitmap = NSBitmapImageRep(cgImage: image)
        let center = try #require(bitmap.colorAt(x: 64, y: 96)?.usingColorSpace(.deviceRGB))
        #expect(center.redComponent > 0.95)
        #expect(center.blueComponent < 0.05)
    }

    @Test("Text icon renders content from the start of the document")
    func textContent() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Readme.txt")
        try "Visible document heading\nContent shown inside the icon.".write(to: url, atomically: true, encoding: .utf8)
        let item = try await FileSystemService().item(at: url)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 128))
        let bitmap = NSBitmapImageRep(cgImage: image)
        var darkPixels = 0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB), color.redComponent < 0.5 {
                    darkPixels += 1
                }
            }
        }
        #expect(darkPixels > 20)
        #expect(image.height == 128)
        #expect(image.width < image.height)
    }

    @Test("Text icon never reads content after the first 1 KiB")
    func textReadLimit() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Bounded.txt")
        try (String(repeating: " ", count: 1_024) + "CONTENT_AFTER_THE_LIMIT").write(
            to: url, atomically: true, encoding: .utf8
        )
        let item = try await FileSystemService().item(at: url)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 96))
        let bitmap = NSBitmapImageRep(cgImage: image)
        var unexpectedPixels = 0
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                      color.redComponent == 1, color.greenComponent == 1, color.blueComponent == 1 else {
                    unexpectedPixels += 1
                    continue
                }
            }
        }
        #expect(unexpectedPixels == 0)
    }

    @Test("HTML icon loads adjacent CSS without executing document scripts")
    func htmlContentAndScriptRestriction() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Preview.html")
        try "html, body { margin: 0; width: 100%; height: 100%; background: rgb(255, 0, 0); }".write(
            to: directory.appendingPathComponent("style.css"), atomically: true, encoding: .utf8
        )
        try "<link rel='stylesheet' href='style.css'><body><script>document.body.style.background='rgb(0, 0, 255)'</script></body>".write(
            to: url, atomically: true, encoding: .utf8
        )
        let item = try await FileSystemService().item(at: url)
        let image = try #require(try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 160))
        #expect(max(image.width, image.height) <= 160)
        let bitmap = NSBitmapImageRep(cgImage: image)
        let center = try #require(bitmap.colorAt(x: image.width / 2, y: image.height / 2)?.usingColorSpace(.deviceRGB))
        #expect(center.redComponent > 0.95)
        #expect(center.greenComponent < 0.05)
        #expect(center.blueComponent < 0.05)
    }

    @Test("Invalid image content falls back without a thumbnail")
    func invalidImageHasNoContentThumbnail() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Invalid.png")
        try Data("Invalid image fixture".utf8).write(to: url)
        let item = try await FileSystemService().item(at: url)
        let result = try await IconPreviewRenderer().image(for: item, at: url, pixelSize: 96)
        #expect(result == nil)
    }

    @Test("Folders keep their existing static icon")
    func folderHasNoContentThumbnail() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let item = try await FileSystemService().item(at: directory)
        let result = try await IconPreviewRenderer().image(for: item, at: directory, pixelSize: 96)
        #expect(result == nil)
    }

    @Test("A cancelled request exits before loading content")
    func alreadyCancelledRequest() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Cancelled.txt")
        try "Cancelled content".write(to: url, atomically: true, encoding: .utf8)
        let item = try await FileSystemService().item(at: url)
        let renderer = IconPreviewRenderer()
        let task = Task { try await renderer.image(for: item, at: url, pixelSize: 96) }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("A cancelled thumbnail request completed successfully")
        } catch is CancellationError {
            // Cancellation is the expected observable result.
        }
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("IconPreviewRenderer-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
