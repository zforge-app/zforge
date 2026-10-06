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

    static func colorName(_ index: Int) -> String {
        ["None", "Gray", "Green", "Purple", "Blue", "Yellow", "Red", "Orange"][min(7, max(0, index))]
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

nonisolated enum FinderTagPresentation {
    /// Metadata order is retained; newer/frontmost tags appear on the left.
    static func leadingNames(_ tags: [String]) -> [String] { Array(tags.reversed()) }

    static func folderColor(tags: [String], colors: [String: Int]) -> Int? {
        leadingNames(tags).compactMap { colors[$0] }.first { (1...7).contains($0) }
    }

    static func quickTags(_ tags: [FinderTag]) -> [FinderTag] { Array(tags.prefix(7)) }
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
    @ObservationIgnored private var tagReferences: [String: [Int: Int]] = [:]
    @ObservationIgnored private var searchScopes: [URL] = []
    @ObservationIgnored private var leasedScopes: [URL] = []
    @ObservationIgnored private var workTask: Task<Void, Never>?
    @ObservationIgnored private var pendingScans = TagScanRoots()
    @ObservationIgnored private var pendingReads: Set<URL> = []
    @ObservationIgnored private let scanner: TaggedFileScanner.Scan
    @ObservationIgnored private let reader: TaggedFileScanner.Read
    @ObservationIgnored private let monitorsFiles: Bool
    @ObservationIgnored private let usesSpotlight: Bool
    @ObservationIgnored private var running = false
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var pendingChanges: [String: TagFileChange] = [:]
    @ObservationIgnored private var stream: FSEventStreamRef?
    @ObservationIgnored private var generation: UInt64 = 0

    init(
        scanner: @escaping TaggedFileScanner.Scan = { roots, publish in
            await TaggedFileScanner.scan(roots, onBatch: publish)
        },
        reader: @escaping TaggedFileScanner.Read = { await TaggedFileScanner.read($0) },
        monitorsFiles: Bool = true,
        usesSpotlight: Bool = true
    ) {
        self.scanner = scanner
        self.reader = reader
        self.monitorsFiles = monitorsFiles
        self.usesSpotlight = usesSpotlight
        super.init()
    }

    var isIdle: Bool { workTask == nil && eventTask == nil }

    func waitForEvents() async { await eventTask?.value }

    /// Await finite queued work; no polling or production timer is introduced.
    func waitForIdle() async {
        while let task = eventTask ?? workTask { await task.value }
    }

    func start() {
        running = true
        guard usesSpotlight, query == nil else { return }
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
            ) { [weak self] notification in
                let updates = notification.name.rawValue == kMDQueryDidUpdateNotification as String
                    ? FinderTagQueryUpdates.urls(in: notification.userInfo) : nil
                Task { @MainActor [weak self] in
                    if let updates { self?.update(updates) }
                    else { self?.queryChanged() }
                }
            })
        }
        if !MDQueryExecute(query, CFOptionFlags(kMDQueryWantsUpdates.rawValue)) { stopQuery() }
    }

    func refresh(searchScopes newScopes: [URL]? = nil) {
        running = true
        var covered = TagScanRoots()
        for scope in searchScopes { covered.insert(scope) }
        var additions = TagScanRoots()
        for scope in newScopes ?? [] where !covered.contains(scope.standardizedFileURL) {
            additions.insert(scope)
            covered.insert(scope)
            // Keep the lease from the authorized URL, including its bookmark.
            if scope.startAccessingSecurityScopedResource() { leasedScopes.append(scope) }
        }
        if !additions.urls.isEmpty {
            searchScopes = covered.urls
            if monitorsFiles { startMonitoring() }
            scan(additions.urls)
        }
        // An existing query already has live updates. Restarting it on sidebar
        // navigation or another window would repeat the global result read.
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
            changed = setRecord(path, colors: colors) || changed
            if running, workTask != nil { pendingReads.insert(url) }
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
        running = false
        workTask?.cancel()
        eventTask?.cancel()
        eventTask = nil
        pendingScans = TagScanRoots()
        pendingReads.removeAll()
        pendingChanges.removeAll()
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
        for scope in scopes { pendingScans.insert(scope) }
        scheduleWork()
    }

    private func scheduleWork() {
        guard running, workTask == nil,
              !pendingScans.urls.isEmpty || !pendingReads.isEmpty else { return }
        let generation = generation
        workTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, running {
                if !pendingReads.isEmpty {
                    let urls = Array(pendingReads.prefix(128))
                    pendingReads.subtract(urls)
                    let batch = await reader(urls)
                    guard !Task.isCancelled else { break }
                    receive(batch, generation: generation)
                } else if !pendingScans.urls.isEmpty {
                    let scopes = pendingScans.take()
                    // Reconcile previously indexed metadata after a subtree
                    // rescan, including removals hidden by lost/coalesced events.
                    let indexed = records.keys.filter { path in
                        scopes.contains { TagScanRoots.covers($0.path, path) }
                    }
                    await scanner(scopes) { [weak self] batch in
                        await self?.receiveScanBatch(batch, generation: generation)
                    }
                    guard !Task.isCancelled else { break }
                    pendingReads.formUnion(indexed.map { URL(fileURLWithPath: $0) })
                } else { break }
            }
            workTask = nil
            // A stop followed immediately by restart waits for the canceled
            // worker to retire before starting another filesystem worker.
            scheduleWork()
        }
    }

    private func receive(_ batch: [String: [String: Int]], generation: UInt64) {
        guard running, generation == self.generation else { return }
        var changed = false
        for (path, colors) in batch {
            changed = setRecord(path, colors: colors) || changed
        }
        if changed { publish(); revision &+= 1 }
    }

    private func receiveScanBatch(_ batch: TaggedFileScanner.Batch, generation: UInt64) async {
        guard running, generation == self.generation else { return }
        receive(batch, generation: generation)
        if !pendingReads.isEmpty {
            let urls = Array(pendingReads.prefix(128))
            pendingReads.subtract(urls)
            let updated = await reader(urls)
            guard !Task.isCancelled else { return }
            receive(updated, generation: generation)
        }
    }

    /// Maintain the catalog incrementally instead of recounting every indexed
    /// file each time another scan batch or edited item is published.
    private func setRecord(_ path: String, colors: [String: Int]) -> Bool {
        guard records[path] != (colors.isEmpty ? nil : colors) else { return false }
        for (name, color) in records[path] ?? [:] {
            let count = (tagReferences[name]?[color] ?? 1) - 1
            tagReferences[name]?[color] = count > 0 ? count : nil
            if tagReferences[name]?.isEmpty == true { tagReferences[name] = nil }
        }
        records[path] = colors.isEmpty ? nil : colors
        for (name, color) in colors { tagReferences[name, default: [:]][color, default: 0] += 1 }
        return true
    }

    private func update(_ urls: [URL]) {
        guard running, !urls.isEmpty else { return }
        pendingReads.formUnion(urls)
        scheduleWork()
    }

    private func publish() {
        var colors: [String: Int] = [:]
        for (name, references) in tagReferences {
            colors[name] = references.keys.filter { $0 != 0 }.min() ?? 0
        }
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
                let relevant = (0..<min(count, paths.count)).compactMap { index -> TagFileChange? in
                    let change = TagFileChange(path: paths[index], flags: flags[index])
                    return change.isRelevant ? change : nil
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

    func filesChanged(_ changes: [TagFileChange]) {
        guard running, !changes.isEmpty else { return }
        for change in changes where change.isRelevant {
            guard searchScopes.contains(where: { TagScanRoots.covers($0.path, change.path) }) else { continue }
            if var previous = pendingChanges[change.path] {
                previous.flags |= change.flags
                pendingChanges[change.path] = previous
            } else { pendingChanges[change.path] = change }
            if pendingChanges.count > 512 {
                // A large burst is a finite reconciliation of affected scopes,
                // rather than an unbounded array of per-file tasks/URLs.
                for scope in searchScopes {
                    let affected = pendingChanges.values.filter { TagScanRoots.covers(scope.path, $0.path) }
                    guard let first = affected.first else { continue }
                    var ancestor = first.reconciliationPath
                    for change in affected {
                        while !TagScanRoots.covers(ancestor, change.reconciliationPath) {
                            ancestor = (ancestor as NSString).deletingLastPathComponent
                        }
                    }
                    // Reconcile the smallest common affected subtree, rather
                    // than restarting all of Home for a burst in one folder.
                    pendingScans.insert(URL(fileURLWithPath: ancestor, isDirectory: true))
                }
                pendingChanges.removeAll(keepingCapacity: true)
            }
        }
        guard !pendingChanges.isEmpty || !pendingScans.urls.isEmpty else { return }
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            guard let self, !Task.isCancelled else { return }
            let changes = Array(pendingChanges.values)
            pendingChanges.removeAll(keepingCapacity: true)
            var changed = false
            for change in changes {
                // The worker handles metadata and temporary-file checks. Only
                // deletion invalidates descendants of an indexed directory.
                if !FileManager.default.fileExists(atPath: change.path) {
                    let paths = records.keys.filter { TagScanRoots.covers(change.path, $0) }
                    for path in paths { changed = setRecord(path, colors: [:]) || changed }
                }
                let url = URL(fileURLWithPath: change.path)
                pendingReads.insert(url)
                if change.requiresRecursiveScan { pendingScans.insert(url) }
            }
            if changed { publish(); revision &+= 1 }
            eventTask = nil
            scheduleWork()
        }
    }

    private func stopQuery() {
        for token in notificationTokens { NotificationCenter.default.removeObserver(token) }
        notificationTokens.removeAll()
        if let query { MDQueryStop(query) }
        query = nil
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
            ForEach(Array(tags.enumerated().reversed()), id: \.element) { entry in
                let name = entry.element
                FinderTagDot(
                    colorIndex: colorIndexes[name]
                        ?? FinderTagCatalog.shared.tags.first { $0.name == name }?.colorIndex
                        ?? FinderTagMetadata.defaultColorIndex(for: name),
                    size: dotSize
                )
                .zIndex(Double(entry.offset))
            }
        }
        .accessibilityLabel(tags.joined(separator: ", "))
    }
}

/// File-level metadata changes need one read. New/moved subtrees and lost-event
/// notifications require reconciliation; directory xattr changes do not.
nonisolated struct TagFileChange: Sendable {
    let path: String
    var flags: FSEventStreamEventFlags

    var isRelevant: Bool {
        let mask = kFSEventStreamEventFlagItemXattrMod | kFSEventStreamEventFlagItemCreated
            | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemRenamed
            | kFSEventStreamEventFlagMustScanSubDirs
        return flags & FSEventStreamEventFlags(mask) != 0
    }

    var requiresRecursiveScan: Bool {
        flags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs) != 0
            || (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir) != 0
                && flags & FSEventStreamEventFlags(
                    kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRenamed
                ) != 0)
    }

    var reconciliationPath: String {
        requiresRecursiveScan ? path : (path as NSString).deletingLastPathComponent
    }
}

/// Spotlight live notifications already identify the changed results; rereading
/// the entire query for each notification would repeat unrelated metadata work.
nonisolated enum FinderTagQueryUpdates {
    static func urls(in info: [AnyHashable: Any]?) -> [URL] {
        var urls: Set<URL> = []
        for key in [kMDQueryUpdateAddedItems, kMDQueryUpdateChangedItems, kMDQueryUpdateRemovedItems] {
            guard let key, let items = info?[key as String] as? [MDItem] else { continue }
            for item in items {
                autoreleasepool {
                    if let path = MDItemCopyAttribute(item, kMDItemPath) as? String {
                        urls.insert(URL(fileURLWithPath: path))
                    }
                }
            }
        }
        return Array(urls)
    }
}
