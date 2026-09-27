import Foundation

/// Derives the visible browser rows from one window's item collections.
/// Callers invalidate the affected projection when a source collection changes.
@MainActor
final class BrowserItemProjection {
    private var sortedRootCache: (sort: BrowserSort, showsHidden: Bool, items: [BrowserItem])?
    private var knownItemsCache: [BrowserItemID: BrowserItem]?
    private var flattenedCache: (
        sort: BrowserSort, showsHidden: Bool,
        entries: [VisibleBrowserItem], orderedItems: [BrowserItem]
    )?
    private var sortedColumnsCache: [BrowserLocation: (sort: BrowserSort, items: [BrowserItem])] = [:]

    func invalidateRoot() {
        sortedRootCache = nil
        flattenedCache = nil
        knownItemsCache = nil
    }

    func invalidateExpansion() {
        flattenedCache = nil
    }

    func invalidateExpandedChildren() {
        flattenedCache = nil
        knownItemsCache = nil
    }

    func invalidateColumns() {
        sortedColumnsCache.removeAll()
        knownItemsCache = nil
    }

    func sortedRootItems(
        _ items: [BrowserItem], sort: BrowserSort, showsHidden: Bool
    ) -> [BrowserItem] {
        if let cache = sortedRootCache,
           cache.sort == sort, cache.showsHidden == showsHidden {
            return cache.items
        }
        let result = sort.sorted(items.filter { showsHidden || !$0.isHidden })
        sortedRootCache = (sort, showsHidden, result)
        return result
    }

    func sortedColumnItems(
        at location: BrowserLocation, sourceItems: [BrowserItem], sort: BrowserSort
    ) -> [BrowserItem] {
        if let cache = sortedColumnsCache[location], cache.sort == sort {
            return cache.items
        }
        let result = sort.sorted(sourceItems)
        sortedColumnsCache[location] = (sort, result)
        return result
    }

    func knownItems(
        roots: [BrowserItem],
        expandedChildren: [BrowserItemID: [BrowserItem]],
        columns: [BrowserLocation: [BrowserItem]]
    ) -> [BrowserItemID: BrowserItem] {
        if let knownItemsCache { return knownItemsCache }
        var values: [BrowserItemID: BrowserItem] = [:]
        for item in roots { values[item.id] = item }
        for children in expandedChildren.values {
            for item in children { values[item.id] = item }
        }
        for children in columns.values {
            for item in children { values[item.id] = item }
        }
        knownItemsCache = values
        return values
    }

    func flattenedList(
        sortedRoots: [BrowserItem],
        expandedIDs: Set<BrowserItemID>,
        expandedChildren: [BrowserItemID: [BrowserItem]],
        sort: BrowserSort,
        showsHidden: Bool
    ) -> [VisibleBrowserItem] {
        if let cache = flattenedCache,
           cache.sort == sort, cache.showsHidden == showsHidden {
            return cache.entries
        }

        var entries: [VisibleBrowserItem] = []
        func append(_ children: [BrowserItem], depth: Int, alreadySorted: Bool = false) {
            let visible = children.filter { showsHidden || !$0.isHidden }
            let ordered = alreadySorted ? visible : sort.sorted(visible)
            for child in ordered {
                entries.append(VisibleBrowserItem(
                    item: child, depth: depth,
                    isExpanded: expandedIDs.contains(child.id), rowIndex: entries.count
                ))
                if expandedIDs.contains(child.id), let nested = expandedChildren[child.id] {
                    append(nested, depth: depth + 1)
                }
            }
        }
        append(sortedRoots, depth: 0, alreadySorted: true)
        flattenedCache = (sort, showsHidden, entries, entries.map(\.item))
        return entries
    }

    func flattenedItems(
        sortedRoots: [BrowserItem],
        expandedIDs: Set<BrowserItemID>,
        expandedChildren: [BrowserItemID: [BrowserItem]],
        sort: BrowserSort,
        showsHidden: Bool
    ) -> [BrowserItem] {
        _ = flattenedList(
            sortedRoots: sortedRoots, expandedIDs: expandedIDs,
            expandedChildren: expandedChildren, sort: sort,
            showsHidden: showsHidden
        )
        return flattenedCache?.orderedItems ?? []
    }
}
