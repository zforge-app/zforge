// Draws the media files of the website capture fixture: fictional pictures
// (PNG, JPEG) and short PDF documents, with no real photo or person in them.
//
//     swift draw_fixture_media.swift <kind> <output> [arguments]
//
// Kinds:
//   cover <out.png>                      the landscape of Capa.png
//   photo <out.jpg> <seed>               an abstract picture for the archives
//   noise <out.jpg> <seed> <width>       an incompressible picture (volumes)
//   pdf <out.pdf> <title> <lines…>       a one-page document
import AppKit
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: draw_fixture_media.swift <kind> <output> …\n".utf8))
    exit(2)
}
let kind = arguments[1]
let output = URL(fileURLWithPath: arguments[2])
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func bitmap(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func write(_ context: CGContext, as type: UTType, quality: Double = 0.9) {
    let image = context.makeImage()!
    let destination = CGImageDestinationCreateWithURL(output as CFURL, type.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(output.path)") }
}

/// A deterministic generator, so the fixture is the same on every run.
struct Seeded: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

func landscape(_ context: CGContext, width: CGFloat, height: CGFloat, sky: UInt32, far: UInt32, near: UInt32,
               sun: UInt32, sunAt: CGPoint) {
    context.setFillColor(color(sky))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(color(sun))
    let radius = height * 0.11
    context.fillEllipse(in: CGRect(x: sunAt.x * width - radius, y: sunAt.y * height - radius,
                                   width: radius * 2, height: radius * 2))
    for (fill, peaks, base) in [(far, [0.0, 0.42, 0.25, 0.62, 0.38, 0.55, 1.0], 0.46),
                                (near, [0.0, 0.3, 0.15, 0.4, 0.22, 0.34, 1.0], 0.28)] {
        context.setFillColor(color(fill))
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: 0))
        for (index, peak) in peaks.enumerated() {
            let x = width * CGFloat(index) / CGFloat(peaks.count - 1)
            context.addLine(to: CGPoint(x: x, y: height * (index.isMultiple(of: 2) ? base : peak)))
        }
        context.addLine(to: CGPoint(x: width, y: 0))
        context.closePath()
        context.fillPath()
    }
}

switch kind {
case "cover":
    let context = bitmap(1600, 1000)
    landscape(context, width: 1600, height: 1000, sky: 0xEDE4D3, far: 0x5B8A9A, near: 0x3D5F6E,
              sun: 0xE0542E, sunAt: CGPoint(x: 0.72, y: 0.72))
    write(context, as: .png)

case "photo":
    let seed = UInt64(arguments.count > 3 ? Int(arguments[3]) ?? 1 : 1)
    let palettes: [(UInt32, UInt32, UInt32, UInt32)] = [
        (0xF3D9C4, 0xC98A6B, 0x7A4E3A, 0xF6B26B), (0xCFE3EE, 0x6D9BB8, 0x34556E, 0xF2C14E),
        (0xE6E0F0, 0x9C8BC4, 0x4E4277, 0xF08A5D), (0xDDEBD5, 0x7FA86A, 0x3F5E36, 0xF4D35E),
        (0xF5E6CC, 0xD49A5A, 0x8C5A2B, 0xE85D4A),
    ]
    let (sky, far, near, sun) = palettes[Int(seed) % palettes.count]
    let context = bitmap(1200, 900)
    landscape(context, width: 1200, height: 900, sky: sky, far: far, near: near, sun: sun,
              sunAt: CGPoint(x: 0.2 + 0.15 * CGFloat(seed % 4), y: 0.7))
    write(context, as: .jpeg)

case "noise":
    let seed = UInt64(Int(arguments[3]) ?? 1)
    let width = Int(arguments[4]) ?? 900
    let height = width * 3 / 4
    let context = bitmap(width, height)
    var random = Seeded(state: seed)
    let pixels = context.data!.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * context.bytesPerRow + x * 4
            let value = random.next()
            // A soft blue-grey picture, with the grain that makes it incompressible.
            pixels[offset] = UInt8(90 + Int(value & 0x3F))
            pixels[offset + 1] = UInt8(110 + Int((value >> 8) & 0x3F))
            pixels[offset + 2] = UInt8(140 + Int((value >> 16) & 0x3F))
            pixels[offset + 3] = 255
        }
    }
    write(context, as: .jpeg, quality: 1)

case "pdf":
    let title = arguments.count > 3 ? arguments[3] : ""
    let lines = Array(arguments.dropFirst(4))
    var box = CGRect(x: 0, y: 0, width: 595, height: 842)
    let context = CGContext(output as CFURL, mediaBox: &box, [kCGPDFContextTitle: title] as CFDictionary)!
    context.beginPDFPage(nil)
    func text(_ string: String, size: CGFloat, weight: NSFont.Weight, at point: CGPoint, color hex: UInt32) {
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        let attributed = NSAttributedString(string: string, attributes: [
            .font: font, .foregroundColor: NSColor(cgColor: color(hex))!,
        ])
        context.textPosition = point
        CTLineDraw(CTLineCreateWithAttributedString(attributed), context)
    }
    context.setFillColor(color(0x2F6FDB))
    context.fill(CGRect(x: 56, y: 760, width: 48, height: 6))
    text(title, size: 26, weight: .semibold, at: CGPoint(x: 56, y: 716), color: 0x1D1D1F)
    var y: CGFloat = 670
    for line in lines {
        if line.isEmpty { y -= 14; continue }
        text(line, size: 12, weight: .regular, at: CGPoint(x: 56, y: y), color: 0x3A3A3C)
        y -= 20
    }
    // Grey bars stand for the rest of the text.
    context.setFillColor(color(0xD8D8DC))
    var random = Seeded(state: UInt64(title.utf8.count))
    while y > 90 {
        let width = 380 + CGFloat(random.next() % 100)
        context.fill(CGRect(x: 56, y: y, width: width, height: 7))
        y -= 18
    }
    context.endPDFPage()
    context.closePDF()

default:
    FileHandle.standardError.write(Data("unknown kind \(kind)\n".utf8))
    exit(2)
}
