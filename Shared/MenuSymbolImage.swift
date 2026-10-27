import AppKit

/// Template images for `MenuSymbol`, colored by the menu like any system symbol:
/// label color in light and dark mode, white on the highlighted row.
@MainActor
enum MenuSymbolImage {
    static func image(for symbol: MenuSymbol, accessibilityDescription: String? = nil) -> NSImage? {
        guard let base = NSImage(systemSymbolName: symbol.name, accessibilityDescription: accessibilityDescription) else { return nil }
        guard let badgeName = symbol.badge else { return base }
        // The body keeps the default symbol size, like the unbadged symbols beside it.
        let body = base
        guard let badge = NSImage(systemSymbolName: badgeName, accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: body.size.height * 0.5, weight: .semibold)) else { return nil }
        let bodySize = body.size
        // Like SF Symbols' own badged symbols: the badge overhangs the lower trailing
        // corner and a clear ring separates it from the body.
        let side = bodySize.height * 0.58
        let fit = side / max(badge.size.width, badge.size.height)
        let badgeSize = NSSize(width: badge.size.width * fit, height: badge.size.height * fit)
        let overhang = side * 0.28
        let size = NSSize(width: bodySize.width + overhang, height: bodySize.height + overhang * 0.25)
        let image = NSImage(size: size, flipped: false) { _ in
            body.draw(in: NSRect(x: 0, y: size.height - bodySize.height, width: bodySize.width, height: bodySize.height))
            let badgeRect = NSRect(x: size.width - badgeSize.width, y: 0, width: badgeSize.width, height: badgeSize.height)
            let gap = bodySize.height * 0.09
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            NSBezierPath(ovalIn: badgeRect.insetBy(dx: -gap, dy: -gap)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            badge.draw(in: badgeRect)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = accessibilityDescription
        return image
    }

    /// A bitmap copy for Finder's Zforge submenu. Finder copies extension menus into its
    /// own process: icon-services images are dropped with the whole menu, and template
    /// images are not recolored (they stay black on a dark menu). `tint` paints the
    /// symbol in a resolved color instead; nil keeps the image's own colors. Finder
    /// draws the first bitmap at its pixel size, so the copy holds one Retina
    /// representation.
    static func bitmapCopy(_ image: NSImage?, size: NSSize? = nil, tint: NSColor? = nil) -> NSImage? {
        let size = size ?? image?.size ?? .zero
        guard size.width > 0, size.height > 0,
              let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int((size.width * 2).rounded(.up)),
                pixelsHigh: Int((size.height * 2).rounded(.up)), bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
              ) else { return nil }
        // Set before creating the context, which takes its point space from it.
        bitmap.size = size
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
        if let image {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            // Centered, so a blank placeholder size can hold any symbol.
            let drawn = image.size
            image.draw(in: NSRect(x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2,
                                  width: drawn.width, height: drawn.height))
            if let tint {
                tint.set()
                NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
            }
            NSGraphicsContext.restoreGraphicsState()
        }
        let copy = NSImage(size: size)
        copy.addRepresentation(bitmap)
        return copy
    }

    /// The menu text color of the system's current light or dark appearance.
    static func menuTextColor(for appearance: NSAppearance) -> NSColor {
        var color = NSColor.labelColor
        appearance.performAsCurrentDrawingAppearance {
            color = NSColor.labelColor.usingColorSpace(.deviceRGB) ?? .labelColor
        }
        return color
    }
}
