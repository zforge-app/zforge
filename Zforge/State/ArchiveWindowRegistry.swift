import Foundation

/// The open browser windows, to keep archive windows in order (D-73): closing the last
/// window of an archive first closes the windows of archives opened from inside it,
/// innermost first, so that their changes are written back from the innermost up.
@MainActor
final class ArchiveWindowRegistry {
    static let shared = ArchiveWindowRegistry()

    private struct Entry {
        weak var state: FileBrowserState?
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    var openBrowsers: [FileBrowserState] {
        entries.values.compactMap(\.state)
    }

    func register(_ state: FileBrowserState) {
        entries[ObjectIdentifier(state)] = Entry(state: state)
    }

    func unregister(_ state: FileBrowserState) {
        entries.removeValue(forKey: ObjectIdentifier(state))
    }

    /// Called as a window closes, before it releases its sessions.
    func windowWillClose(_ state: FileBrowserState) {
        unregister(state)
        let others = openBrowsers
        let stillShown = Set(others.flatMap(\.heldArchiveSessionIDs))
        let released = state.heldArchiveSessionIDs.subtracting(stillShown)
        guard !released.isEmpty else { return }
        let parents = mergedParents(including: state)
        let inner = others.compactMap { other -> (FileBrowserState, Int)? in
            let depth = other.heldArchiveSessionIDs.compactMap { Self.depth(of: $0, under: released, parents: parents) }.max()
            return depth.map { (other, $0) }
        }
        for (other, _) in inner.sorted(by: { $0.1 > $1.1 }) where !other.isClosedForRegistry {
            other.closeWindow()
        }
    }

    /// Closes every browser window, innermost archive windows first, and waits until each
    /// has released its sessions (quitting).
    func closeAllWindows() async {
        let browsers = openBrowsers
        let parents = mergedParents(including: nil)
        let ordered = browsers.sorted { lhs, rhs in
            Self.chainLength(lhs, parents: parents) > Self.chainLength(rhs, parents: parents)
        }
        for browser in ordered where !browser.isClosedForRegistry { browser.closeWindow() }
        for browser in ordered { await browser.closingTask?.value }
    }

    /// Whether a window shows an archive opened from inside another archive.
    var showsInnerArchives: Bool {
        let parents = mergedParents(including: nil)
        return openBrowsers.contains { browser in browser.heldArchiveSessionIDs.contains { parents[$0] != nil } }
    }

    private func mergedParents(including state: FileBrowserState?) -> [UUID: UUID] {
        var parents: [UUID: UUID] = [:]
        for browser in openBrowsers + [state].compactMap({ $0 }) {
            parents.merge(browser.archiveSessionParents) { current, _ in current }
        }
        return parents
    }

    /// Steps from `session` up to a session in `ancestors`, or nil when it is not inside one.
    static func depth(of session: UUID, under ancestors: Set<UUID>, parents: [UUID: UUID]) -> Int? {
        var current = session
        var steps = 0
        var visited: Set<UUID> = [session]
        while let parent = parents[current] {
            steps += 1
            if ancestors.contains(parent) { return steps }
            guard visited.insert(parent).inserted else { return nil }
            current = parent
        }
        return nil
    }

    private static func chainLength(_ browser: FileBrowserState, parents: [UUID: UUID]) -> Int {
        browser.heldArchiveSessionIDs.map { session in
            var length = 0
            var current = session
            var visited: Set<UUID> = [session]
            while let parent = parents[current], visited.insert(parent).inserted {
                length += 1
                current = parent
            }
            return length
        }.max() ?? 0
    }
}
