import AppKit
import CoreFoundation
import CoreServices
import Darwin
import Foundation
import Observation
import OSLog
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
            return colorIndexes(atPath: path)
        }
    }

    /// Enumeration already supplies a filesystem path; avoid allocating a URL
    /// for every untagged file just to recover that same C representation.
    static func colorIndexes(atPath path: UnsafePointer<CChar>) -> [String: Int] {
        readColorIndexes(atPath: path).colors
    }

    struct ReadResult: Sendable {
        let colors: [String: Int]
        let complete: Bool
    }

    static func readColorIndexes(atPath path: UnsafePointer<CChar>) -> ReadResult {
        // A direct lookup of an absent attribute costs several times more than
        // listing names (measured on the real Home tree, where protected
        // provenance makes nearly every item carry some attribute). Both calls
        // follow symlinks. Only a successful listing that omits the tag name is
        // definitive; listing errors and oversized lists keep the direct read
        // and its exact error semantics.
        if listsTagAttribute(atPath: path) == false { return ReadResult(colors: [:], complete: true) }
        let size = getxattr(path, attribute, nil, 0, 0, 0)
        if size <= 0 {
            // Absence and a concurrently removed path are valid empty metadata;
            // access/I/O failures must not become a durable false-negative.
            let complete = size == 0 || errno == ENOATTR || errno == ENOENT || errno == ENOTDIR
            return ReadResult(colors: [:], complete: complete)
        }
        var bytes = [UInt8](repeating: 0, count: size)
        let count = bytes.withUnsafeMutableBytes { buffer in
            getxattr(path, attribute, buffer.baseAddress, size, 0, 0)
        }
        guard count >= 0 else { return ReadResult(colors: [:], complete: false) }
        return ReadResult(colors: colorIndexes(in: Data(bytes.prefix(count))), complete: true)
    }

    /// `false` only when the complete NUL-separated name list was returned and
    /// does not contain the tag attribute; `nil` when the list is unavailable.
    static func listsTagAttribute(atPath path: UnsafePointer<CChar>, capacity: Int = 4096) -> Bool? {
        withUnsafeTemporaryAllocation(of: CChar.self, capacity: capacity) { buffer -> Bool? in
            let size = listxattr(path, buffer.baseAddress, buffer.count, 0)
            guard size >= 0 else { return nil }
            return attributeNames(UnsafeRawBufferPointer(rebasing: UnsafeRawBufferPointer(buffer)[..<size]),
                contain: attributeBytes)
        }
    }

    private static let attributeBytes = Array(attribute.utf8)

    static func attributeNames(_ list: UnsafeRawBufferPointer, contain name: [UInt8]) -> Bool {
        var start = list.startIndex
        while start < list.endIndex {
            let end = list[start...].firstIndex(of: 0) ?? list.endIndex
            if end - start == name.count, list[start..<end].elementsEqual(name) { return true }
            start = end + 1
        }
        return false
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
    static let shared = ProcessInfo.processInfo.arguments.contains("--ui-fixtures")
        ? FinderTagCatalog.uiFixture() : FinderTagCatalog(indexStore: .standard)

    /// UI fixtures must not depend on the Mac's own Finder tags, which decide the quick-tag
    /// circles: an isolated catalog that offers Finder's standard English favorites. Slot 0 is
    /// colorless in Finder's layout, so it stays empty for each name to keep its own color.
    private static func uiFixture() -> FinderTagCatalog {
        let catalog = FinderTagCatalog(discoveryRoots: [], scanner: { _, _ in }, reader: { _ in [:] }, monitorsFiles: false,
            usesSpotlight: false, favoriteTagNames: { ["", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray"] })
        catalog.publish()
        return catalog
    }

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
    @ObservationIgnored private let scanner: @Sendable ([URL], @escaping TaggedFileScanner.Publish) async -> TaggedFileScanner.ScanResult
    @ObservationIgnored private let reader: @Sendable ([URL]) async -> TaggedFileScanner.ReadResult
    @ObservationIgnored private let monitorsFiles: Bool
    @ObservationIgnored private let usesSpotlight: Bool
    @ObservationIgnored private let eventDelay: @Sendable () async throws -> Void
    @ObservationIgnored private let favoriteTagNames: (() -> [String])?
    @ObservationIgnored private var running = false
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var pendingChanges: [String: TagFileChange] = [:]
    @ObservationIgnored private var stream: FSEventStreamRef?
    @ObservationIgnored private var generation: UInt64 = 0

    @ObservationIgnored private let indexStore: TagIndexStore?
    @ObservationIgnored private var loadedCheckpoint: TagIndexSnapshot?
    @ObservationIgnored private var preparationTask: Task<Void, Never>?
    @ObservationIgnored private var checkpointTask: Task<Void, Never>?
    @ObservationIgnored private var pendingPreparation = TagScanRoots()
    @ObservationIgnored private var journal: TagJournal?
    @ObservationIgnored private var journalScopes: [TagJournal.Scope] = []
    @ObservationIgnored private var checkpointDirty = false
    @ObservationIgnored private var deferredScans = TagScanRoots()
    private var checkpointComplete: Bool { deferredScans.urls.isEmpty }
    @ObservationIgnored private var discoveryStarted: ContinuousClock.Instant?
    @ObservationIgnored private var restoredIndex = false
    @ObservationIgnored private var reportedReady = false

    @ObservationIgnored let discoveryPolicy: TagDiscoveryPolicy

    init(
        discoveryRoots: [URL] = TagDiscoveryPolicy.standardRoots,
        scanner: TaggedFileScanner.Scan? = nil,
        reader: TaggedFileScanner.Read? = nil,
        monitorsFiles: Bool = true,
        usesSpotlight: Bool = true,
        indexStore: TagIndexStore? = nil,
        eventDelay: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .milliseconds(350)) },
        favoriteTagNames: (() -> [String])? = nil
    ) {
        self.discoveryPolicy = TagDiscoveryPolicy(roots: discoveryRoots)
        if let scanner {
            self.scanner = { roots, publish in await scanner(roots, publish); return .init(interrupted: Task.isCancelled) }
        } else {
            self.scanner = { await TaggedFileScanner.scanResult($0, onBatch: $1) }
        }
        if let reader {
            self.reader = { .init(records: await reader($0), complete: !Task.isCancelled) }
        } else { self.reader = { await TaggedFileScanner.readResult($0) } }
        self.monitorsFiles = monitorsFiles
        self.usesSpotlight = usesSpotlight
        self.indexStore = indexStore
        self.eventDelay = eventDelay
        self.favoriteTagNames = favoriteTagNames
        super.init()
    }

    var isIdle: Bool { workTask == nil && eventTask == nil && preparationTask == nil && checkpointTask == nil }

    func waitForEvents() async { await eventTask?.value }

    /// Await finite queued work; no polling or production timer is introduced.
    func waitForIdle() async {
        while let task = preparationTask ?? eventTask ?? workTask ?? checkpointTask { await task.value }
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
        MDQuerySetSearchScope(query, discoveryPolicy.roots.map(\.path) as CFArray, 0)
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
        for grant in (newScopes ?? []) + discoveryPolicy.roots.filter({ $0.path == "/Users/Shared" }) {
            for scope in discoveryPolicy.intersection(grant.standardizedFileURL) where !covered.contains(scope.standardizedFileURL) {
                // Acquire the existing authorization before probing access.
                let leased = grant.startAccessingSecurityScopedResource()
                guard let directory = opendir(scope.path) else {
                    if leased { grant.stopAccessingSecurityScopedResource() }
                    continue
                }
                closedir(directory)
                if leased { leasedScopes.append(grant) }
                additions.insert(scope)
                covered.insert(scope)
            }
        }
        if !additions.urls.isEmpty {
            if discoveryStarted == nil { discoveryStarted = .now }
            reportedReady = false
            searchScopes = covered.urls
            if indexStore != nil, monitorsFiles {
                for scope in additions.urls { pendingPreparation.insert(scope) }
                prepareDiscovery()
            } else {
                if monitorsFiles { startMonitoring() }
                scan(additions.urls)
            }
        }
        // An existing query already has live updates. Restarting it on sidebar
        // navigation or another window would repeat the global result read.
        start()
    }

    func observe(_ items: [BrowserItem]) {
        var changed = false
        for item in items {
            guard let url = item.localURL, discoveryPolicy.contains(url) else { continue }
            let colors = Dictionary(uniqueKeysWithValues: Set(item.tags).map {
                ($0, item.tagColorIndexes[$0] ?? FinderTagMetadata.defaultColorIndex(for: $0))
            })
            let path = url.standardizedFileURL.path
            changed = setRecord(path, colors: colors.isEmpty || discoveryPolicy.isVisible(url) ? colors : [:]) || changed
            if running, workTask != nil || preparationTask != nil, discoveryPolicy.isVisible(url) { pendingReads.insert(url) }
        }
        if changed { publish(); revision &+= 1; checkpointDirty = true; saveCheckpoint() }
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
        preparationTask?.cancel()
        journal?.stop()
        journal = nil
        journalScopes.removeAll()
        loadedCheckpoint = nil
        pendingPreparation = TagScanRoots()
        checkpointDirty = false
        deferredScans = TagScanRoots()
        discoveryStarted = nil
        restoredIndex = false
        reportedReady = false
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
        checkpointDirty = true
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
                    deferRetries(batch.deferred)
                    await receive(batch.records, generation: generation)
                } else if !pendingScans.urls.isEmpty {
                    let scopes = pendingScans.take()
                    // Reconcile previously indexed metadata after a subtree
                    // rescan, including removals hidden by lost/coalesced events.
                    let indexed = records.keys.filter { path in
                        scopes.contains { TagScanRoots.covers($0.path, path) }
                    }
                    let started = ContinuousClock.now
                    let outcome = await scanner(scopes) { [weak self] batch in
                        await self?.receiveScanBatch(batch, generation: generation)
                    }
                    guard !Task.isCancelled else { break }
                    guard !outcome.interrupted else { break }
                    deferredScans.remove(coveredBy: scopes)
                    deferRetries(outcome.deferred)
                    let elapsed = started.duration(to: .now)
                    Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice(
                        "Tag discovery completed: duration=\(String(describing: elapsed), privacy: .public), scopes_attempted=\(scopes.count, privacy: .public), complete=\(outcome.complete, privacy: .public), inspected=\(outcome.inspected, privacy: .public), metadata_reads=\(outcome.metadataReads, privacy: .public), deferred_scopes=\(outcome.deferred.count, privacy: .public)"
                    )
                    pendingReads.formUnion(indexed.map { URL(fileURLWithPath: $0) })
                } else { break }
            }
            workTask = nil
            // A stop followed immediately by restart waits for the canceled
            // worker to retire before starting another filesystem worker.
            scheduleWork()
            saveCheckpoint()
            reportReady()
        }
    }

    private func receive(_ batch: [String: [String: Int]], generation: UInt64, revalidateUncertainRecords: Bool = false) async {
        guard running, !Task.isCancelled, generation == self.generation else { return }
        let visible = await TaggedFileScanner.visibilityResult(batch, policy: discoveryPolicy)
        guard running, !Task.isCancelled, generation == self.generation else { return }
        if revalidateUncertainRecords { pendingReads.formUnion(visible.metadataRechecks) }
        var changed = false
        // Filesystem validation has completed off the main actor. Merge and
        // publish once; a canceled generation cannot publish a partial batch.
        for (path, colors) in visible.records {
            changed = setRecord(path, colors: colors) || changed
        }
        if changed { publish(); revision &+= 1; checkpointDirty = true }
    }

    private func receiveScanBatch(_ batch: TaggedFileScanner.Batch, generation: UInt64) async {
        guard running, generation == self.generation else { return }
        await receive(batch, generation: generation)
        guard running, !Task.isCancelled, generation == self.generation else { return }
        if !pendingReads.isEmpty {
            let urls = Array(pendingReads.prefix(128))
            pendingReads.subtract(urls)
            let updated = await reader(urls)
            guard !Task.isCancelled else { return }
            deferRetries(updated.deferred)
            await receive(updated.records, generation: generation)
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
        pendingReads.formUnion(urls.filter {
            discoveryPolicy.contains($0) && (discoveryPolicy.isVisible($0) || records[$0.standardizedFileURL.path] != nil)
        })
        scheduleWork()
    }

    private func publish() {
        var colors: [String: Int] = [:]
        for (name, references) in tagReferences {
            colors[name] = references.keys.filter { $0 != 0 }.min() ?? 0
        }
        let favorites = favoriteTagNames?() ?? Self.finderFavoriteTagNames()
        let colorBySlot = [0, 6, 7, 5, 2, 4, 3, 1]
        for (slot, name) in favorites.enumerated() where !name.isEmpty {
            colors[name] = colors[name] ?? (slot < colorBySlot.count ? colorBySlot[slot] : 0)
        }
        let updated = colors.map { FinderTag(name: $0.key, colorIndex: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if updated != tags { tags = updated }
    }

    private static func finderFavoriteTagNames() -> [String] {
        // This plist is read through the same Home authorization as user files.
        // Cross-domain CFPreferences alone is unavailable in the App Sandbox.
        let prefsURL = UserDirectoryService.homeURL.appendingPathComponent("Library/Preferences/com.apple.finder.plist")
        let prefs = (try? Data(contentsOf: prefsURL)).flatMap {
            try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: Any]
        }
        return prefs?["FavoriteTagNames"] as? [String]
            ?? CFPreferencesCopyAppValue("FavoriteTagNames" as CFString, "com.apple.finder" as CFString) as? [String]
            ?? []
    }

    /// Restore only after scopes have been authorized. Monitor before scanning
    /// so changes made during initial discovery cannot fall into a gap.
    private func prepareDiscovery() {
        guard running, preparationTask == nil, let indexStore, !pendingPreparation.urls.isEmpty else { return }
        let generation = generation
        preparationTask = Task { [weak self] in
            guard let self else { return }
            while running, !Task.isCancelled, !pendingPreparation.urls.isEmpty {
                let additions = pendingPreparation.take()
                if journal == nil { loadedCheckpoint = await indexStore.load() }
                let snapshot = loadedCheckpoint
                guard running, !Task.isCancelled, generation == self.generation else { break }
                guard let description = TagJournal.describe(searchScopes) else {
                    // Unavailable persistent history never authorizes stale reuse.
                    startMonitoring()
                    scan(additions)
                    break
                }
                // Bookmarks arrive independently. A checkpoint containing Home
                // and Shared is still reusable when only Shared is authorized
                // initially; retain it for Home's later authorization even if
                // a smaller checkpoint is written in the meantime.
                let reusableScopes = description.scopes.filter { scope in
                    additions.contains { $0.path == scope.path }
                        && snapshot?.matches([scope]) == true
                        && snapshot!.cursors[scope.path]! <= FSEventsGetCurrentEventId()
                }
                let restoredRoots = reusableScopes.map { URL(fileURLWithPath: $0.path) }
                let coldRoots = additions.filter { url in !restoredRoots.contains { $0.path == url.path } }
                var cursors = journal?.cursors ?? [:]
                var retryRoots: [URL] = []
                if !restoredRoots.isEmpty, let snapshot {
                    for scope in reusableScopes { cursors[scope.path] = snapshot.cursors[scope.path] }
                    restoredIndex = true
                    let cachedRecords = snapshot.records.filter { path, _ in restoredRoots.contains { TagScanRoots.covers($0.path, path) } }
                    Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice(
                        "Tag index restored: tagged_records=\(cachedRecords.count, privacy: .public), scopes_restored=\(restoredRoots.count, privacy: .public)"
                    )
                    await receive(cachedRecords, generation: generation, revalidateUncertainRecords: true)
                    guard running, !Task.isCancelled, generation == self.generation else { break }
                    // Persistent history revalidates changed paths. Enqueuing
                    // every cached item repeats metadata work on quiet launches;
                    // invalid or dropped history still reconciles the scope.
                    for path in snapshot.deferredPaths where restoredRoots.contains(where: { TagScanRoots.covers($0.path, path) }) {
                        let url = URL(fileURLWithPath: path)
                        deferredScans.insert(url)
                        pendingScans.insert(url)
                        retryRoots.append(url)
                    }
                }
                journal?.stop()
                let journal = TagJournal(onChanges: { [weak self] changes in
                    guard let self else { return }
                    // A cold scan begins after history delivery, and a restored
                    // retry starts once the journal has started. Both starting
                    // trees already include those historical changes; rescanning
                    // them again would repeat the very same pass.
                    let changes = self.journal?.isReplaying == true
                        ? changes.filter { change in
                            !(coldRoots + retryRoots).contains { TagScanRoots.covers($0.path, change.path) }
                        }
                        : changes
                    filesChanged(changes)
                }, onHistory: { [weak self] in self?.saveCheckpoint() })
                self.journal = journal
                journalScopes = description.scopes
                journal.start(description, since: cursors)
                if !restoredRoots.isEmpty, journal.available { scheduleWork() }
                checkpointDirty = true
                await journal.waitForHistory()
                guard running, !Task.isCancelled, generation == self.generation else { break }
                scan(journal.available ? coldRoots : additions)
            }
            preparationTask = nil
            prepareDiscovery()
            saveCheckpoint()
            reportReady()
        }
    }

    /// The cursor and records are captured only after all events through that
    /// cursor have drained. New events arriving during I/O get a later checkpoint.
    private func saveCheckpoint() {
        guard running, checkpointDirty, checkpointTask == nil, preparationTask == nil,
              workTask == nil, eventTask == nil, pendingScans.urls.isEmpty, pendingReads.isEmpty,
              let indexStore, let journal, journal.available, !journal.isReplaying else { return }
        let retainedScopes = loadedCheckpoint?.version == TagIndexSnapshot.currentVersion
            ? loadedCheckpoint!.scopes.filter { cached in
                !journalScopes.contains { current in
                    TagScanRoots.covers(current.path, cached.path) || TagScanRoots.covers(cached.path, current.path)
                }
            } : []
        func retained(_ path: String) -> Bool { retainedScopes.contains { TagScanRoots.covers($0.path, path) } }
        var savedRecords = loadedCheckpoint?.records.filter { path, _ in retained(path) } ?? [:]
        savedRecords.merge(records.filter { path, _ in searchScopes.contains { TagScanRoots.covers($0.path, path) } }) { _, current in current }
        var savedCursors = loadedCheckpoint?.cursors.filter { path, _ in retainedScopes.contains { $0.path == path } } ?? [:]
        savedCursors.merge(journal.cursors) { _, current in current }
        let savedDeferred = (loadedCheckpoint?.deferredPaths.filter(retained) ?? []) + deferredScans.urls.map(\.path)
        // Preserve ungranted, disjoint scope data on disk without publishing it
        // or trusting its identity. Later authorization validates it afresh.
        let snapshot = TagIndexSnapshot(scopes: (journalScopes + retainedScopes).sorted { $0.path < $1.path },
            cursors: savedCursors, records: savedRecords, deferredPaths: savedDeferred)
        checkpointDirty = false
        checkpointTask = Task { [weak self] in
            let saved = await indexStore.save(snapshot)
            if !saved {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").error("Tag index checkpoint could not be saved")
            } else {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice(
                    "Tag index checkpoint saved: scopes=\(snapshot.scopes.count, privacy: .public), tagged_records=\(snapshot.records.count, privacy: .public), deferred_scopes=\(snapshot.deferredPaths.count, privacy: .public)"
                )
            }
            guard let self else { return }
            checkpointTask = nil
            saveCheckpoint()
            reportReady()
        }
    }

    private func deferRetries(_ urls: [URL]) {
        for url in urls {
            for scope in searchScopes {
                if TagScanRoots.covers(scope.path, url.path) { deferredScans.insert(url) }
                else if TagScanRoots.covers(url.path, scope.path) { deferredScans.insert(scope) }
            }
        }
        if deferredScans.urls.count > 512 {
            let affected = deferredScans.urls
            deferredScans = TagScanRoots()
            for scope in searchScopes where affected.contains(where: { TagScanRoots.covers(scope.path, $0.path) }) {
                deferredScans.insert(scope)
            }
        }
    }

    private func reportReady() {
        guard running, isIdle, !reportedReady, let discoveryStarted else { return }
        reportedReady = true
        Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice(
            "Tag index ready: duration=\(String(describing: discoveryStarted.duration(to: .now)), privacy: .public), restored=\(self.restoredIndex, privacy: .public), complete=\(self.checkpointComplete, privacy: .public), scopes=\(self.searchScopes.count, privacy: .public)"
        )
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
        var acceptedChange = false
        // The cache lasts only for this synchronous delivery and cannot hide a
        // later visibility transition. Bound it even for an unusually large batch.
        var visibilityFlags: [URL: UInt32] = [:]
        func readFlags(_ url: URL) -> UInt32? {
            if let flags = visibilityFlags[url] { return flags }
            let flags = TagDiscoveryPolicy.flags(at: url)
            if visibilityFlags.count < 512 { visibilityFlags[url] = flags ?? 0 }
            return flags
        }
        for change in changes where change.isRelevant {
            guard searchScopes.contains(where: { TagScanRoots.covers($0.path, change.path) }) else { continue }
            let url = URL(fileURLWithPath: change.path)
            // Hidden activity cannot restart discovery. Retain a hide event only
            // when it must remove previously indexed items or descendants.
            guard discoveryPolicy.isVisible(url, readFlags: readFlags)
                    || records.keys.contains(where: { TagScanRoots.covers(change.path, $0) }) else { continue }
            acceptedChange = true
            checkpointDirty = true
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
        // Hidden-only noise cannot postpone accepted changes. A finite window
        // starts with the first change and keeps draining under continuous work.
        guard acceptedChange, eventTask == nil else { return }
        eventTask = Task { [weak self] in
            do { try await self?.eventDelay() } catch { return }
            guard let self, !Task.isCancelled else { return }
            let changes = Array(pendingChanges.values)
            pendingChanges.removeAll(keepingCapacity: true)
            var changed = false
            for change in changes {
                // The worker handles metadata and temporary-file checks. Only
                // deletion or hiding invalidates descendants of an indexed directory.
                if !FileManager.default.fileExists(atPath: change.path) || !discoveryPolicy.isVisible(URL(fileURLWithPath: change.path)) {
                    let paths = records.keys.filter { TagScanRoots.covers(change.path, $0) }
                    for path in paths { changed = setRecord(path, colors: [:]) || changed }
                }
                let url = URL(fileURLWithPath: change.path)
                pendingReads.insert(url)
                if change.requiresRecursiveScan { pendingScans.insert(url) }
            }
            if changed { publish(); revision &+= 1; checkpointDirty = true }
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
        let mask = kFSEventStreamEventFlagItemXattrMod | kFSEventStreamEventFlagItemFinderInfoMod | kFSEventStreamEventFlagItemCreated
            | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemRenamed
            | kFSEventStreamEventFlagItemInodeMetaMod | kFSEventStreamEventFlagMustScanSubDirs
        return flags & FSEventStreamEventFlags(mask) != 0
    }

    var requiresRecursiveScan: Bool {
        flags & FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs) != 0
            || (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir) != 0
                && flags & FSEventStreamEventFlags(
                    kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRenamed | kFSEventStreamEventFlagItemFinderInfoMod
                        | kFSEventStreamEventFlagItemInodeMetaMod
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
