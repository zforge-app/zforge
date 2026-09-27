import AppKit
import SwiftUI

enum BrowserResizeGeometry {
    static func width(
        startWidth: CGFloat, dragStartX: CGFloat, currentX: CGFloat,
        scale: CGFloat, direction: CGFloat
    ) -> CGFloat {
        startWidth + direction * (currentX - dragStartX) / max(scale, 0.01)
    }
}

enum BrowserColumnsLayout {
    static let minimumPreviewWidth: CGFloat = 320

    static func terminalColumnWidth(
        availableWidth: CGFloat,
        precedingColumnCount: Int,
        columnWidth: CGFloat,
        minimumWidth: CGFloat = 0
    ) -> CGFloat {
        max(
            columnWidth,
            minimumWidth,
            availableWidth - CGFloat(precedingColumnCount) * columnWidth
        )
    }

    static func initialPreviewWidth(
        availableWidth: CGFloat,
        columnCount: Int,
        columnWidth: CGFloat
    ) -> CGFloat {
        max(
            minimumPreviewWidth,
            availableWidth - CGFloat(columnCount) * columnWidth
        )
    }
}

enum BrowserMetrics {
    static let selectionColor = Color(nsColor: .selectedContentBackgroundColor)
    static let finderColumnWidth: CGFloat = 260
    static let iconGridItemWidth: CGFloat = 110
    static let iconGridSpacing: CGFloat = 24
    static let iconGridPadding: CGFloat = 16
    static let rowHeight: CGFloat = 24
    static let iconSize: CGFloat = 16
    static let horizontalInset: CGFloat = 8
    static let rowContentInset: CGFloat = 4
    static let columnContentInset: CGFloat = 6
    static let disclosureWidth: CGFloat = 18
    static let rowCornerRadius: CGFloat = 7
}

struct BrowserColumnResizeHandle: NSViewRepresentable {
    let currentWidth: CGFloat
    let scale: CGFloat
    var direction: CGFloat = 1
    var isPreview = false
    let onResize: (CGFloat) -> Void

    func makeNSView(context: Context) -> ResizeView {
        ResizeView()
    }

    func updateNSView(_ view: ResizeView, context: Context) {
        view.currentWidth = currentWidth
        view.scale = scale
        view.direction = direction
        view.onResize = onResize
        view.setAccessibilityLabel(AppLocalization.string(
            isPreview ? "Drag to resize preview" : "Drag to resize column"
        ))
    }

    final class ResizeView: NSView {
        var currentWidth: CGFloat = 0
        var scale: CGFloat = 1
        var direction: CGFloat = 1
        var onResize: ((CGFloat) -> Void)?
        private var dragStartX: CGFloat?
        private var dragStartWidth: CGFloat = 0

        override var acceptsFirstResponder: Bool { false }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .resizeLeftRight)
        }

        override func mouseDown(with event: NSEvent) {
            dragStartX = event.locationInWindow.x
            dragStartWidth = currentWidth
        }

        override func mouseDragged(with event: NSEvent) {
            guard let dragStartX else { return }
            onResize?(BrowserResizeGeometry.width(
                startWidth: dragStartWidth, dragStartX: dragStartX,
                currentX: event.locationInWindow.x, scale: scale, direction: direction
            ))
        }

        override func mouseUp(with event: NSEvent) {
            dragStartX = nil
        }
    }
}

enum BrowserListLayout {
    static let minimumNameColumnWidth: CGFloat = 168
    static let modificationDateColumnWidth: CGFloat = 180
    static let sizeColumnWidth: CGFloat = 90
    static let kindColumnWidth: CGFloat = 150

    static func minimumTableWidth(scale: CGFloat, columnWidths: [CGFloat]? = nil) -> CGFloat {
        let columnWidth = (columnWidths ?? [minimumNameColumnWidth,
            modificationDateColumnWidth, sizeColumnWidth, kindColumnWidth]).reduce(0, +)
        let horizontalChrome = 2 * (BrowserMetrics.horizontalInset + BrowserMetrics.rowContentInset)
        let baseline = minimumNameColumnWidth + modificationDateColumnWidth
            + sizeColumnWidth + kindColumnWidth + horizontalChrome
        return max(columnWidth + horizontalChrome, baseline) * scale
    }

    static func tableWidth(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat = 0,
        scale: CGFloat,
        columnWidths: [CGFloat]? = nil
    ) -> CGFloat {
        let visibleWidth = max(availableWidth - max(obscuredTrailingWidth, 0), 0)
        return max(visibleWidth, minimumTableWidth(scale: scale, columnWidths: columnWidths))
    }

    static func scrollContentWidth(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat,
        scale: CGFloat,
        columnWidths: [CGFloat]? = nil
    ) -> CGFloat {
        tableWidth(
            availableWidth: availableWidth,
            obscuredTrailingWidth: obscuredTrailingWidth,
            scale: scale,
            columnWidths: columnWidths
        ) + max(obscuredTrailingWidth, 0)
    }

    static func requiresHorizontalScrolling(
        availableWidth: CGFloat,
        obscuredTrailingWidth: CGFloat,
        scale: CGFloat,
        columnWidths: [CGFloat]? = nil
    ) -> Bool {
        scrollContentWidth(
            availableWidth: availableWidth,
            obscuredTrailingWidth: obscuredTrailingWidth,
            scale: scale,
            columnWidths: columnWidths
        ) > availableWidth
    }
}
