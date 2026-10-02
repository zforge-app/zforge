import AppKit
import CoreFoundation
import CoreServices
import Darwin
import Foundation
import Observation
import SwiftUI

nonisolated struct FinderTag: Identifiable, Equatable, Sendable {
    let name: String
    let colorIndex: Int

    var id: String { name }
}

nonisolated enum FinderTagMetadata {
    static let attribute = "com.apple.metadata:_kMDItemUserTags"

    static func colorIndexes(at url: URL) -> [String: Int] {
        url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return [:] }
            let size = getxattr(path, attribute, nil, 0, 0, 0)
            guard size > 0 else { return [:] }
            var bytes = [UInt8](repeating: 0, count: size)
            let count = bytes.withUnsafeMutableBytes { buffer in
                getxattr(path, attribute, buffer.baseAddress, size, 0, 0)
            }
            guard count > 0 else { return [:] }
            return colorIndexes(in: Data(bytes.prefix(count)))
        }
    }

    static func colorIndexes(in data: Data) -> [String: Int] {
        guard let values = try? PropertyListSerialization.propertyList(from: data, format: nil)
            as? [String] else { return [:] }
        var colors: [String: Int] = [:]
        for value in values {
            let parts = value.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            guard let name = parts.first, !name.isEmpty else { continue }
            let index = parts.count == 2 ? Int(parts[1]) ?? 0 : 0
            colors[String(name)] = (1...7).contains(index) ? index : 0
        }
        return colors
    }

    static func defaultColorIndex(for name: String) -> Int {
        switch name.localizedLowercase {
        case "gray", "grey", "cinza": 1
        case "green", "verde": 2
        case "purple", "roxo": 3
        case "blue", "azul": 4
        case "yellow", "amarelo": 5
        case "red", "vermelho": 6
        case "orange", "laranja": 7
        default: 0
        }
    }
}

@MainActor
@Observable
final class FinderTagCatalog: NSObject {
    static let shared = FinderTagCatalog()

    private(set) var tags: [FinderTag] = []
    private(set) var revision: UInt64 = 0
    @ObservationIgnored private var query: MDQuery?
    @ObservationIgnored private var notificationTokens: [NSObjectProtocol] = []
    @ObservationIgnored private var records: [String: [String: Int]] = [:]
    @ObservationIgnored private var searchScopes: [URL] = []
    @ObservationIgnored private var leasedScopes: [URL] = []
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var pendingPaths: Set<String> = []
    @ObservationIgnored private var stream: FSEventStreamRef?
    @ObservationIgnored private var generation: UInt64 = 0

    func start() {
        guard query == nil else { return }
        publish()
        guard let query = MDQueryCreate(
            kCFAllocatorDefault, "kMDItemUserTags == '*'" as CFString, nil, nil
        ) else { return }
        self.query = query
        MDQuerySetDispatchQueue(query, .main)
        MDQuerySetSearchScope(query, [kMDQueryScopeComputer, kMDQueryScopeNetwork] as CFArray, 0)
        for name in [kMDQueryDidFinishNotification, kMDQueryDidUpdateNotification].compactMap({ $0 }) {
            notificationTokens.append(NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: name as String), object: query, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.queryChanged() }
            })
        }
        if !MDQueryExecute(query, CFOptionFlags(kMDQueryWantsUpdates.rawValue)) { stopQuery() }
    }

    func refresh(searchScopes newScopes: [URL]? = nil) {
        if let newScopes {
            let additions = newScopes.filter { scope in
                !searchScopes.contains { $0.standardizedFileURL == scope.standardizedFileURL }
            }
            if !additions.isEmpty {
                // Own a security scope independently of the window that supplied it.
                for scope in additions where scope.startAccessingSecurityScopedResource() {
                    leasedScopes.append(scope)
                }
                searchScopes.append(contentsOf: additions)
                startMonitoring()
                scan(additions)
            }
        }
        stopQuery()
        start()
    }

    func observe(_ items: [BrowserItem]) {
        var changed = false
        for item in items {
            guard let url = item.localURL else { continue }
            let colors = Dictionary(uniqueKeysWithValues: Set(item.tags).map {
                ($0, item.tagColorIndexes[$0] ?? FinderTagMetadata.defaultColorIndex(for: $0))
            })
            let path = url.standardizedFileURL.path
            if records[path] != colors && (!colors.isEmpty || records[path] != nil) {
                records[path] = colors.isEmpty ? nil : colors
                changed = true
            }
        }
        if changed { publish(); revision &+= 1 }
    }

    func itemURLs(tagged name: String) -> [URL] {
        records.compactMap { path, colors in
            colors.keys.contains(name) ? URL(fileURLWithPath: path) : nil
        }.sorted { $0.path < $1.path }
    }

    func stop() {
        generation &+= 1
        stopQuery()
        scanTask?.cancel()
        eventTask?.cancel()
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        for scope in leasedScopes { scope.stopAccessingSecurityScopedResource() }
        leasedScopes.removeAll()
        searchScopes.removeAll()
    }

    private func queryChanged() {
        guard let query else { return }
        MDQueryDisableUpdates(query)
        defer { MDQueryEnableUpdates(query) }
        var urls: [URL] = []
        for index in 0..<MDQueryGetResultCount(query) {
            guard let pointer = MDQueryGetResultAtIndex(query, index) else { continue }
            let item = unsafeBitCast(pointer, to: MDItem.self)
            if let path = MDItemCopyAttribute(item, "kMDItemPath" as CFString) as? String {
                urls.append(URL(fileURLWithPath: path))
            }
        }
        update(urls)
    }

    private func scan(_ scopes: [URL]) {
        let previous = scanTask
        let generation = generation
        scanTask = Task { [weak self] in
            await previous?.value
            guard let self, !Task.isCancelled else { return }
            await TaggedFileScanner.scan(scopes) { [weak self] batch in
                await self?.receive(batch, generation: generation)
            }
        }
    }

    private func receive(_ batch: [String: [String: Int]], generation: UInt64) {
        guard generation == self.generation else { return }
        var changed = false
        for (path, colors) in batch where records[path] != colors {
            records[path] = colors.isEmpty ? nil : colors
            changed = true
        }
        if changed { publish(); revision &+= 1 }
    }

    private func update(_ urls: [URL]) {
        let generation = generation
        Task { [weak self] in
            let batch = await TaggedFileScanner.read(urls)
            self?.receive(batch, generation: generation)
        }
    }

    private func publish() {
        var colors: [String: Int] = [:]
        for record in records.values { colors.merge(record) { old, new in new == 0 ? old : new } }
        // This plist is read through the same Home authorization as user files.
        // Cross-domain CFPreferences alone is unavailable in the App Sandbox.
        let prefsURL = UserDirectoryService.homeURL.appendingPathComponent("Library/Preferences/com.apple.finder.plist")
        let prefs = (try? Data(contentsOf: prefsURL)).flatMap {
            try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: Any]
        }
        let favorites = prefs?["FavoriteTagNames"] as? [String]
            ?? CFPreferencesCopyAppValue("FavoriteTagNames" as CFString, "com.apple.finder" as CFString) as? [String]
            ?? []
        let colorBySlot = [0, 6, 7, 5, 2, 4, 3, 1]
        for (slot, name) in favorites.enumerated() where !name.isEmpty {
            colors[name] = colors[name] ?? (slot < colorBySlot.count ? colorBySlot[slot] : 0)
        }
        let updated = colors.map { FinderTag(name: $0.key, colorIndex: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if updated != tags { tags = updated }
    }

    private func startMonitoring() {
        if let stream { FSEventStreamStop(stream); FSEventStreamInvalidate(stream); FSEventStreamRelease(stream) }
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        stream = FSEventStreamCreate(
            kCFAllocatorDefault, { _, context, count, paths, flags, _ in
                guard let context else { return }
                let catalog = Unmanaged<FinderTagCatalog>.fromOpaque(context).takeUnretainedValue()
                let paths = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
                let relevant: [String] = (0..<min(count, paths.count)).compactMap { index in
                    let mask = kFSEventStreamEventFlagItemXattrMod | kFSEventStreamEventFlagItemCreated
                        | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemRenamed
                        | kFSEventStreamEventFlagMustScanSubDirs
                    return flags[index] & FSEventStreamEventFlags(mask) != 0 ? paths[index] : nil
                }
                Task { @MainActor in catalog.filesChanged(relevant) }
            }, &context, searchScopes.map(\.path) as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        )
        if let stream {
            FSEventStreamSetDispatchQueue(stream, .main)
            FSEventStreamStart(stream)
        }
    }

    private func filesChanged(_ paths: [String]) {
        guard stream != nil else { return }
        pendingPaths.formUnion(paths.filter { !ZforgeTemporaryStorage.contains(URL(fileURLWithPath: $0)) })
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard let self, !Task.isCancelled else { return }
            let paths = pendingPaths
            pendingPaths.removeAll()
            for path in paths {
                let prefix = path + "/"
                if !FileManager.default.fileExists(atPath: path) {
                    records = records.filter { $0.key != path && !$0.key.hasPrefix(prefix) }
                }
            }
            publish()
            revision &+= 1
            update(paths.map { URL(fileURLWithPath: $0) })
            let directories = paths.compactMap { path -> URL? in
                let url = URL(fileURLWithPath: path)
                return (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true ? url : nil
            }
            if !directories.isEmpty { scan(directories) }
        }
    }

    private func stopQuery() {
        for token in notificationTokens { NotificationCenter.default.removeObserver(token) }
        notificationTokens.removeAll()
        if let query { MDQueryStop(query) }
        query = nil
    }
}

/// Reads actual Finder metadata in authorized directories, including files
/// that Spotlight omits from a sandboxed query or has not indexed yet.
nonisolated enum TaggedFileScanner {
    static func read(_ urls: [URL]) async -> [String: [String: Int]] {
        await Task.detached(priority: .utility) {
            var records: [String: [String: Int]] = [:]
            for url in urls where !ZforgeTemporaryStorage.contains(url) {
                records[url.standardizedFileURL.path] = FinderTagMetadata.colorIndexes(at: url)
            }
            return records
        }.value
    }

    static func scan(
        _ roots: [URL],
        onBatch: @escaping @Sendable ([String: [String: Int]]) async -> Void
    ) async {
        await Task.detached(priority: .utility) {
            var seenRoots: Set<String> = []
            var batch: [String: [String: Int]] = [:]
            for root in roots {
                // Publish common user locations before the larger Home tree.
                let priorityRoots = root == UserDirectoryService.homeURL ? [
                    root.appendingPathComponent("Downloads"), root.appendingPathComponent("Documents"),
                    root.appendingPathComponent("Desktop"),
                    root.appendingPathComponent("Library/Mobile Documents"),
                    root.appendingPathComponent("Library/CloudStorage"), root
                ] : [root]
                for directory in priorityRoots where seenRoots.insert(directory.path).inserted {
                    if !FinderTagMetadata.colorIndexes(at: directory).isEmpty {
                        batch[directory.path] = FinderTagMetadata.colorIndexes(at: directory)
                    }
                    guard let enumerator = FileManager.default.enumerator(
                        at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                        options: [.skipsPackageDescendants], errorHandler: { _, _ in true }
                    ) else { continue }
                    var inspected = 0
                    while let url = enumerator.nextObject() as? URL {
                        guard !Task.isCancelled else { return }
                        if seenRoots.contains(url.path) || ZforgeTemporaryStorage.contains(url) {
                            enumerator.skipDescendants(); continue
                        }
                        let colors = FinderTagMetadata.colorIndexes(at: url)
                        if !colors.isEmpty { batch[url.standardizedFileURL.path] = colors }
                        inspected += 1
                        if inspected.isMultiple(of: 1_000) && !batch.isEmpty {
                            await onBatch(batch); batch.removeAll()
                        }
                    }
                    if !batch.isEmpty { await onBatch(batch); batch.removeAll() }
                }
            }
        }.value
    }
}

struct FinderTagDot: View {
    let colorIndex: Int
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(colorIndex == 0 ? Color.clear : color)
            .overlay {
                Circle()
                    .strokeBorder(colorIndex == 0 ? Color.secondary : Color.clear, lineWidth: 1.3)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch colorIndex {
        case 1: .gray
        case 2: .green
        case 3: .purple
        case 4: .blue
        case 5: .yellow
        case 6: .red
        case 7: .orange
        default: .clear
        }
    }
}

struct FinderTagDots: View {
    let tags: [String]
    let colorIndexes: [String: Int]
    let dotSize: CGFloat

    var body: some View {
        HStack(spacing: -dotSize * 0.45) {
            ForEach(tags, id: \.self) { name in
                FinderTagDot(
                    colorIndex: colorIndexes[name]
                        ?? FinderTagCatalog.shared.tags.first { $0.name == name }?.colorIndex
                        ?? FinderTagMetadata.defaultColorIndex(for: name),
                    size: dotSize
                )
            }
        }
        .accessibilityLabel(tags.joined(separator: ", "))
    }
}
