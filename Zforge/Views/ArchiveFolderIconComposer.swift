import AppKit
import CoreImage

/// A stamp on the native folder face, using the app's hydraulic press and Z identity.
/// Normalized paths keep the engraving legible without introducing the app icon's colors.
enum ArchiveFolderIconComposer {
    static let compactSizeThreshold: CGFloat = 32

    enum Scale: CaseIterable {
        case compact, small, regular, large

        init(size: CGFloat) {
            self = size <= 32 ? .compact : size <= 48 ? .small : size < 128 ? .regular : .large
        }

        var diameter: CGFloat {
            switch self {
            case .compact: 0.48
            case .small: 0.38
            case .regular: 0.34
            case .large: 0.30
            }
        }
    }

    static func stampRect(in bounds: NSRect, scale: Scale) -> NSRect {
        let compact = scale == .compact
        let diameter = bounds.width * scale.diameter
        return NSRect(
            x: bounds.minX + bounds.width * (compact ? 0.50 : 0.72) - diameter / 2,
            y: bounds.minY + bounds.height * (compact ? 0.46 : 0.35) - diameter / 2,
            width: diameter,
            height: diameter
        )
    }

    static func compose(from folder: NSImage, scale: Scale, containsFiles: Bool = false, isOpen: Bool = false, showsArchiveStamp: Bool = true) -> NSImage {
        guard folder.size.width > 0, folder.size.height > 0 else { return folder }
        // NSWorkspace defaults to a 32 pt canvas. A large composition canvas makes
        // Icon Services choose its detailed representation instead of enlarging
        // the small folder's simplified bands along the base.
        let nativeFolder = folder.copy() as! NSImage
        nativeFolder.size = NSSize(width: 512, height: 512)
        let smoothFolder = smoothBase(of: nativeFolder)
        let relief = showsArchiveStamp ? approvedRelief : nil
        if isOpen {
            return composeOpen(from: smoothFolder, scale: scale, containsFiles: containsFiles, showsArchiveStamp: showsArchiveStamp)
        }
        return NSImage(size: nativeFolder.size, flipped: false) { bounds in
            smoothFolder.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
            if containsFiles {
                drawClosedFolderContents(in: bounds, front: smoothFolder)
            }
            let rect = stampRect(in: bounds, scale: scale)
            relief?.draw(in: rect)
            return true
        }
    }

    /// Open the same native front rather than switching to the older textured ofld artwork.
    /// The face and relief share one perspective warp, so their material and lighting stay together.
    private static func composeOpen(from folder: NSImage, scale: Scale, containsFiles: Bool, showsArchiveStamp: Bool) -> NSImage {
        let relief = showsArchiveStamp ? approvedRelief : nil
        let front = NSImage(size: folder.size, flipped: false) { bounds in
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            NSBezierPath(roundedRect: NSRect(x: bounds.width * 0.042, y: bounds.height * 0.13,
                                            width: bounds.width * 0.916, height: bounds.height * 0.60),
                         xRadius: bounds.width * 0.06, yRadius: bounds.height * 0.06).addClip()
            folder.draw(in: bounds)
            relief?.draw(in: stampRect(in: bounds, scale: scale))
            return true
        }
        guard let warped = tiltedFront(front) else {
            return compose(from: folder, scale: scale, containsFiles: containsFiles, showsArchiveStamp: showsArchiveStamp)
        }
        let cleanBack = continuousBackPanel(from: folder)
        return NSImage(size: folder.size, flipped: false) { bounds in
            cleanBack.draw(in: bounds)
            if containsFiles {
                let paper = NSBezierPath(roundedRect: NSRect(x: bounds.width * 0.08, y: bounds.height * 0.61,
                                                             width: bounds.width * 0.84, height: bounds.height * 0.15),
                                         xRadius: bounds.width * 0.024, yRadius: bounds.width * 0.024)
                NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
                paper.fill()
            }
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
            shadow.shadowBlurRadius = bounds.width * 0.012
            shadow.shadowOffset = NSSize(width: 0, height: -bounds.height * 0.007)
            shadow.set()
            warped.draw(in: bounds)
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
    }

    /// Replace only the exposed rear strip with a continuous gradient sampled from its native material.
    /// Raster sampling keeps the same color profile and alpha silhouette, avoiding bitmap-row seams.
    private static func continuousBackPanel(from image: NSImage) -> NSImage {
        let side = 1024
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let bytes = bitmap.bitmapData else { return image }
        bytes.initialize(repeating: 0, count: bitmap.bytesPerRow * side)
        bitmap.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        let top = Int(Double(side) * 0.19)
        let bottom = Int(Double(side) * 0.40)
        // Both samples come from intact rear material, above the closed front lip.
        let upper = (0..<3).map { Double(bytes[Int(Double(side) * 0.21) * bitmap.bytesPerRow + (side / 2) * 4 + $0]) }
        let lower = (0..<3).map { Double(bytes[Int(Double(side) * 0.225) * bitmap.bytesPerRow + (side / 2) * 4 + $0]) }
        for y in top..<side {
            let height = 1 - (Double(y) + 0.5) / Double(side)
            let cornerY = max(0, height - 0.744)
            let rightEdge = cornerY > 0 ? 0.898 + sqrt(max(0, 0.06 * 0.06 - cornerY * cornerY)) : 0.958
            // Fade from the native top into the continuous interior; no horizontal join.
            let blend = max(0, min(1, (0.81 - height) / 0.045))
            let smoothBlend = blend * blend * (3 - 2 * blend)
            for x in 0..<side {
                let offset = y * bitmap.bytesPerRow + x * 4
                if y >= bottom {
                    for channel in 0..<4 { bytes[offset + channel] = 0 }
                } else {
                    let t = Double(y - top) / Double(bottom - top)
                    let rightCoverage = max(0, min(1, rightEdge * Double(side) - Double(x)))
                    let leftCoverage = max(0, min(1, Double(x + 1) - 0.0405 * Double(side)))
                    let coverage = rightCoverage * leftCoverage
                    let originalAlpha = Double(bytes[offset + 3]) / 255
                    let alpha = originalAlpha * ((1 - smoothBlend) + smoothBlend * coverage)
                    for channel in 0..<3 {
                        let native = Double(bytes[offset + channel])
                        let clean = (upper[channel] * (1 - t) + lower[channel] * t) * originalAlpha * coverage
                        bytes[offset + channel] = UInt8((native * (1 - smoothBlend) + clean * smoothBlend).rounded())
                    }
                    bytes[offset + 3] = UInt8((alpha * 255).rounded())
                }
            }
        }
        let result = NSImage(size: image.size)
        result.addRepresentation(bitmap)
        return result
    }

    /// Bilinear sampling avoids strip seams and works without a Core Image rendering device.
    private static func tiltedFront(_ image: NSImage) -> NSImage? {
        let side = 1024
        func bitmap() -> NSBitmapImageRep? {
            NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                             colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        }
        guard let source = bitmap(), let target = bitmap(),
              let sourceBytes = source.bitmapData, let targetBytes = target.bitmapData else { return nil }
        sourceBytes.initialize(repeating: 0, count: source.bytesPerRow * side)
        targetBytes.initialize(repeating: 0, count: target.bytesPerRow * side)
        source.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: source)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        for y in 0..<side {
            let normalizedY = 1 - (Double(y) + 0.5) / Double(side)
            let t = (normalizedY - 0.13) / 0.53
            guard t >= 0, t <= 1 else { continue }
            // The hinge retains the closed width; only the approaching top edge grows.
            let margin = -0.02 * t
            let sourceY = (1 - (0.13 + 0.60 * t)) * Double(side) - 0.5
            let y0 = Int(floor(sourceY)), fy = sourceY - Double(y0)
            guard y0 >= 0, y0 + 1 < side else { continue }
            for x in 0..<side {
                let normalizedX = (Double(x) + 0.5) / Double(side)
                let sourceX = (normalizedX - margin) / (1 - 2 * margin) * Double(side) - 0.5
                let x0 = Int(floor(sourceX)), fx = sourceX - Double(x0)
                guard x0 >= 0, x0 + 1 < side else { continue }
                for channel in 0..<4 {
                    func sample(_ sx: Int, _ sy: Int) -> Double {
                        Double(sourceBytes[sy * source.bytesPerRow + sx * 4 + channel])
                    }
                    let upper = sample(x0, y0) * (1 - fx) + sample(x0 + 1, y0) * fx
                    let lower = sample(x0, y0 + 1) * (1 - fx) + sample(x0 + 1, y0 + 1) * fx
                    targetBytes[y * target.bytesPerRow + x * 4 + channel] = UInt8((upper * (1 - fy) + lower * fy).rounded())
                }
            }
        }
        let result = NSImage(size: image.size)
        result.addRepresentation(target)
        return result
    }

    /// Native back, a thin document stack, then the unchanged native front face.
    /// The documents stay behind the front, unlike the rejected open-folder study.
    private static func drawClosedFolderContents(in bounds: NSRect, front: NSImage) {
        let paper = NSRect(x: bounds.width * 0.08, y: bounds.height * 0.60,
                           width: bounds.width * 0.84, height: bounds.height * 0.16)
        let document = NSBezierPath(roundedRect: paper,
                                   xRadius: bounds.width * 0.024, yRadius: bounds.width * 0.024)
        NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
        document.fill()
        NSColor(calibratedWhite: 0.78, alpha: 0.6).setStroke()
        document.lineWidth = bounds.width * 0.003
        document.stroke()
        NSGraphicsContext.saveGraphicsState()
        // Restore the entire rounded front lip above the paper, including its upper edge.
        // A horizontal crop below that edge makes the document paint over the folder face.
        NSBezierPath(roundedRect: NSRect(x: bounds.width * 0.042, y: bounds.height * 0.13,
                                        width: bounds.width * 0.916, height: bounds.height * 0.60),
                     xRadius: bounds.width * 0.06, yRadius: bounds.width * 0.06).addClip()
        front.draw(in: bounds)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func smoothBase(of folder: NSImage) -> NSImage {
        var proposed = NSRect(origin: .zero, size: folder.size)
        guard let source = folder.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else { return folder }
        let input = CIImage(cgImage: source)
        let blurred = input.clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 18.0])
        guard let softened = CIContext(options: [.useSoftwareRenderer: true]).createCGImage(blurred, from: input.extent) else { return folder }
        let detailedFolder = NSImage(cgImage: source, size: folder.size)
        let softImage = NSImage(cgImage: softened, size: folder.size)
        return NSImage(size: folder.size, flipped: false) { bounds in
            detailedFolder.draw(in: bounds)
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            guard let context = NSGraphicsContext.current?.cgContext else { return true }
            // Restrict the refinement to the opaque front face: blurring the
            // native drop shadow would create a halo around the folder base.
            context.clip(to: bounds, mask: source)
            NSBezierPath(roundedRect: NSRect(x: bounds.width * 0.042,
                                             y: bounds.height * 0.13,
                                             width: bounds.width * 0.916,
                                             height: bounds.height * 0.60),
                         xRadius: bounds.width * 0.06, yRadius: bounds.height * 0.06).addClip()
            for index in 0..<26 {
                NSGraphicsContext.saveGraphicsState()
                let lower = CGFloat(index) * 0.01
                NSBezierPath(rect: NSRect(x: 0, y: bounds.height * lower,
                                          width: bounds.width, height: bounds.height * 0.01)).addClip()
                let fraction = min(1, (0.26 - lower) / 0.05)
                softImage.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: fraction)
                NSGraphicsContext.restoreGraphicsState()
            }
            return true
        }
    }

    /// The approved artwork is a lighting reference, not a replacement folder.
    static let approvedRelief: Relief? = {
        guard let image = NSImage(named: "ArchiveFolderRelief") else { return nil }
        return Relief(reference: image)
    }()

    static func standaloneStamp(size: CGFloat = 512) -> NSImage {
        let relief = approvedRelief
        return NSImage(size: NSSize(width: size, height: size), flipped: false) { bounds in
            relief?.draw(in: bounds.insetBy(dx: size * 0.06, dy: size * 0.06))
            return relief != nil
        }
    }

    struct Relief {
        let shadows: NSImage
        let highlights: NSImage

        init?(reference: NSImage) {
            var proposed = NSRect(origin: .zero, size: reference.size)
            guard let source = reference.cgImage(forProposedRect: &proposed, context: nil, hints: nil),
                  source.width >= 1024, source.height == source.width else { return nil }
            let pixels = NSBitmapImageRep(cgImage: source)
            // Coordinates are in the approved reference's top-left pixel system.
            // This square contains the entire circular rim, including its lighting.
            let origin = NSPoint(x: 690, y: 570)
            let diameter = 452
            func bitmap() -> NSBitmapImageRep? {
                NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: diameter, pixelsHigh: diameter,
                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                    colorSpaceName: .deviceRGB, bitmapFormat: .alphaNonpremultiplied, bytesPerRow: 0, bitsPerPixel: 0)
            }
            guard let dark = bitmap(), let light = bitmap(),
                  let darkBytes = dark.bitmapData, let lightBytes = light.bitmapData else { return nil }
            func luminance(x: Int, y: Int) -> Double {
                guard let color = pixels.colorAt(x: x * source.width / 1254, y: y * source.height / 1254)?.usingColorSpace(.deviceRGB) else { return 0 }
                return 0.2126 * color.redComponent + 0.7152 * color.greenComponent + 0.0722 * color.blueComponent
            }
            for y in 0..<diameter {
                let referenceY = Int(origin.y) + y
                // Unmarked material on both sides reconstructs the folder gradient.
                let left = luminance(x: 650, y: referenceY)
                let right = luminance(x: 1175, y: referenceY)
                for x in 0..<diameter {
                    let referenceX = Int(origin.x) + x
                    let blend = Double(referenceX - 650) / 525
                    let surface = left * (1 - blend) + right * blend
                    let actual = luminance(x: referenceX, y: referenceY)
                    let distance = hypot(Double(x) - 225.5, Double(y) - 225.5)
                    let coverage = max(0, min(1, 226 - distance))
                    let shade = max(0, min(1, (surface - actual) / max(surface, 0.01))) * coverage
                    let shine = max(0, min(1, (actual - surface) / max(1 - surface, 0.01))) * coverage
                    let darkOffset = y * dark.bytesPerRow + x * 4
                    let lightOffset = y * light.bytesPerRow + x * 4
                    darkBytes[darkOffset] = 0
                    darkBytes[darkOffset + 1] = 0
                    darkBytes[darkOffset + 2] = 0
                    darkBytes[darkOffset + 3] = UInt8((shade * 255).rounded())
                    lightBytes[lightOffset] = 255
                    lightBytes[lightOffset + 1] = 255
                    lightBytes[lightOffset + 2] = 255
                    lightBytes[lightOffset + 3] = UInt8((shine * 255).rounded())
                }
            }
            shadows = NSImage(size: NSSize(width: diameter, height: diameter))
            shadows.addRepresentation(dark)
            highlights = NSImage(size: shadows.size)
            highlights.addRepresentation(light)
        }

        func draw(in rect: NSRect) {
            shadows.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            highlights.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        }
    }
}
