import SwiftUI

extension Color {
    /// A fixed sRGB colour from `0xRRGGBB`, the same in light and dark appearance.
    init(sRGBHex rgb: UInt32) {
        self.init(.sRGB, red: Double(rgb >> 16 & 0xFF) / 255, green: Double(rgb >> 8 & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}

/// An SF Symbol in a coloured rounded square, as System Settings draws its panes and sidebars:
/// a vertical gradient, a faint light rim and a slight shadow under the symbol and the tile.
/// Shared by the Settings sidebar and the Keyboard Shortcuts sidebar.
struct SymbolTile: View {
    let symbol: String
    let colors: (top: Color, bottom: Color)
    let size: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(.white.opacity(0.18), lineWidth: max(0.5, size / 40))
                .blendMode(.plusLighter)
            Image(systemName: symbol)
                .font(.system(size: size * 0.56, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: size / 40, y: size / 60)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: size / 80, y: size / 80)
        .accessibilityHidden(true)
    }
}
