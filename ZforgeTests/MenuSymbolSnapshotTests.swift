import AppKit
import Testing
@testable import Zforge

@Suite("Menu symbol snapshots")
@MainActor
struct MenuSymbolSnapshotTests {
    /// Finder's copies of every action symbol, in order, on the theme's menu background:
    /// the badges, sizes, alignment and theme colors users see in the Zforge submenu.
    @Test("Finder submenu symbols keep their shapes and theme colors", arguments: ZforgeSnapshot.appearances.map(\.name))
    func finderSymbolStrip(appearanceName: String) throws {
        let name = try #require(ZforgeSnapshot.appearances.first { $0.name == appearanceName }?.appearance)
        let appearance = try #require(NSAppearance(named: name))
        let text = MenuSymbolImage.menuTextColor(for: appearance)
        let symbols = BrowserSelectionAction.allCases.compactMap { $0.menuSymbol.flatMap { MenuSymbolImage.image(for: $0) } }
        #expect(symbols.count == BrowserSelectionAction.allCases.count)
        let side = try #require(symbols.map { max($0.size.width, $0.size.height) }.max())
        let cell = side + 8
        let strip = NSImage(size: NSSize(width: cell * CGFloat(symbols.count), height: cell), flipped: false) { bounds in
            var background = NSColor.windowBackgroundColor
            appearance.performAsCurrentDrawingAppearance {
                background = NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB) ?? .gray
            }
            background.setFill()
            bounds.fill()
            for (index, symbol) in symbols.enumerated() {
                let copy = MenuSymbolImage.bitmapCopy(symbol, size: NSSize(width: side, height: side), tint: text)
                copy?.draw(in: NSRect(x: CGFloat(index) * cell + 4, y: 4, width: side, height: side))
            }
            return true
        }
        ZforgeSnapshot.assert(strip, named: appearanceName)
    }
}
