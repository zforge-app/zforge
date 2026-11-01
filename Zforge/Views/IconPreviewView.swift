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
            loadObserver?.report(item.id, value)
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

/// Observes whether each Icons cell shows its content thumbnail rather than the fallback
/// icon, so hosted views can await loading without the accessibility tree. Observers compare
/// by identity: a closure cannot be compared, so the environment would otherwise treat every
/// update as a change and invalidate every cell that reads it.
struct IconPreviewLoadObserver: Equatable {
    private let id = UUID()
    let report: @MainActor (BrowserItemID, Bool) -> Void

    init(_ report: @escaping @MainActor (BrowserItemID, Bool) -> Void) {
        self.report = report
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension EnvironmentValues {
    @Entry var iconPreviewLoadObserver: IconPreviewLoadObserver?
}
