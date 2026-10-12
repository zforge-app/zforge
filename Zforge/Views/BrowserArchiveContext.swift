import AppIntents
import SwiftUI

extension View {
    func browserArchiveContext(_ item: BrowserItem, isSelected: @escaping @MainActor () -> Bool) -> some View {
        modifier(BrowserArchiveContext(item: item, isSelected: isSelected))
    }
}

private struct BrowserArchiveContext: ViewModifier {
    let item: BrowserItem
    let isSelected: @MainActor () -> Bool
    private var catalog: ArchiveContextCatalog { .shared }

    func body(content: Content) -> some View {
        content.appEntityUIElements { context in
            // System callbacks can outlive a layout snapshot. Read the shared
            // catalog and browser selection at request time, without disk work.
            guard let identifier = catalog.identifier(for: item) else { return [] }
            let selected = isSelected()
            catalog.recordContextSelection(selected)
            guard ArchiveContextSelection.isRequested(context.requests, bounds: context.bounds, isSelected: selected) else { return [] }
            return [AppEntityUIElement(identifier: identifier, bounds: context.bounds, state: .init(isSelected: selected))]
        }
    }

}

nonisolated enum ArchiveContextSelection {
    static func isRequested(_ requests: Set<AppEntityUIElementsContext.ElementsRequest>, bounds: CGRect, isSelected: Bool) -> Bool {
        requests.contains { request in
            switch request {
            case .visible(let rect): bounds.intersects(rect)
            case .selected: isSelected
            @unknown default: false
            }
        }
    }
}
