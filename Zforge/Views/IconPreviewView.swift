import SwiftUI

struct IconPreviewView: View {
    let item: BrowserItem
    let size: CGFloat
    let enabled: Bool
    let state: FileBrowserState
    @Binding var isLoaded: Bool
    @Environment(\.displayScale) private var displayScale
    @Environment(\.iconPreviewLoadObserver) private var loadObserver
    @State private var model = IconPreviewModel()

    private var pixelSize: Int { min(256, Int((size * displayScale).rounded(.up))) }
    private var request: Request { Request(item: item, pixels: pixelSize, enabled: enabled) }
    private var isShowingPreview: Bool {
        enabled && model.item == item && model.image != nil
    }

    var body: some View {
        Group {
            if isShowingPreview, let image = model.image {
                Image(decorative: image, scale: displayScale)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .overlay {
                        if item.showsVideoPlayBadge {
                            VideoPlayBadge(thumbnailSize: CGSize(width: size, height: size))
                        }
                    }
            } else {
                FileIconView(item: item, size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .onChange(of: isShowingPreview, initial: true) { _, value in
            isLoaded = value
            loadObserver?(item.id, value)
        }
        .task(id: request) {
            await model.load(item: item, pixelSize: pixelSize, enabled: enabled) { item, pixels in
                try await state.iconPreview(for: item, pixelSize: pixels)
            }
        }
    }

    private struct Request: Hashable {
        let item: BrowserItem
        let pixels: Int
        let enabled: Bool
    }
}

extension EnvironmentValues {
    /// Observes whether each Icons cell shows its content thumbnail rather than the fallback
    /// icon, so hosted views can await loading without the accessibility tree.
    @Entry var iconPreviewLoadObserver: (@MainActor (BrowserItemID, Bool) -> Void)?
}
