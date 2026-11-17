import AppIntents
import CoreSpotlight
import Foundation
import Observation
import OSLog

nonisolated protocol ArchiveIndexWriting: Sendable {
    func reset() async throws
    func remove(_ identifiers: [String]) async throws
    func upsert(_ entities: [ZforgeArchiveEntity]) async throws
    func contextIdentifiers(for entities: [ZforgeArchiveEntity]) async throws -> [String: EntityIdentifier]
}

extension ArchiveIndexWriting {
    func contextIdentifiers(for entities: [ZforgeArchiveEntity]) async throws -> [String: EntityIdentifier] {
        try await ArchiveContextPreparation.shared.identifiers(for: entities)
    }
}

/// Test writers and the legacy route prepare associations away from UI lookup.
actor ArchiveContextPreparation {
    static let shared = ArchiveContextPreparation()
    func identifiers(for entities: [ZforgeArchiveEntity]) throws -> [String: EntityIdentifier] {
        var result: [String: EntityIdentifier] = [:]
        for entity in entities {
            try Task.checkCancellation()
            if #available(macOS 27.0, *) {
                result[entity.id] = EntityIdentifier(for: try ZforgeFileArchiveEntity.published(entity))
            } else {
                result[entity.id] = EntityIdentifier(for: ZforgeLegacyArchiveEntity.self, identifier: entity.id)
            }
        }
        return result
    }
}

/// One owner serializes mutations. A failed/partial scan must not retain stale grants.
actor ArchiveIndexCoordinator {
    private let discovery: AutomationArchiveEntities
    private let writer: any ArchiveIndexWriting
    private struct Revision: Equatable {
        let name: String
        let fileIdentity: Data?
        init(_ entity: ZforgeArchiveEntity) { name = entity.name; fileIdentity = entity.fileIdentity }
    }
    private var published: [String: Revision] = [:]
    private var initialized = false
    private var running = false

    init(discovery: AutomationArchiveEntities, writer: any ArchiveIndexWriting) {
        self.discovery = discovery
        self.writer = writer
    }

    func contextIdentifiers(for entities: [ZforgeArchiveEntity]) async throws -> [String: EntityIdentifier] {
        try await writer.contextIdentifiers(for: entities)
    }

    func invalidate() async throws {
        guard !running else { throw AutomationError.busy }
        running = true
        defer { running = false }
        initialized = false
        published = [:]
        try await writer.reset()
    }

    func reconcile(reset: Bool = false) async throws -> [ZforgeArchiveEntity] {
        guard !running else { throw AutomationError.busy }
        running = true
        defer { running = false }
        do {
            if !initialized || reset {
                try await writer.reset()
                published = [:]
                initialized = true
            }
            let entities = try await discovery.snapshot()
            try Task.checkCancellation()
            let current = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, Revision($0)) })
            let removed = published.keys.filter { current[$0] == nil }.sorted()
            if !removed.isEmpty { try await writer.remove(removed) }
            try Task.checkCancellation()
            let changed = entities.filter { published[$0.id] != Revision($0) }
            // Bound individual donation payloads independently of the scan limit.
            for offset in stride(from: 0, to: changed.count, by: 100) {
                try Task.checkCancellation()
                try await writer.upsert(Array(changed[offset..<min(offset + 100, changed.count)]))
            }
            try Task.checkCancellation()
            published = current
            return entities
        } catch {
            initialized = false
            published = [:]
            // Do not treat a partially donated snapshot as a successful index.
            do { try await writer.reset() }
            catch {
                Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").error("Archive index cleanup failed; reconciliation is required.")
            }
            throw error
        }
    }
}

/// The named index owns archive metadata only; framework-generated identifiers
/// retain the AppEntity/OpenIntent association. No archive contents are donated.
nonisolated final class SpotlightArchiveWriter: NSObject, ArchiveIndexWriting, CSSearchableIndexDelegate, @unchecked Sendable {
    static let indexName = "ZforgeAuthorizedArchives"
    private let index = CSSearchableIndex(name: indexName)
    @available(macOS 27.0, *)
    private var filePublication: ArchiveFilePublication {
        // The holder avoids referencing a newer stored-property type at the
        // macOS 26 floor, while giving the writer one persistent identity owner.
        publicationHolder.publication
    }
    private let publicationHolder: ArchiveFilePublicationHolder
    override init() {
        publicationHolder = ArchiveFilePublicationHolder(index: index)
        super.init()
        index.indexDelegate = self
    }
    func reset() async throws {
        try await index.deleteAppEntities(ofType: ZforgeArchiveEntity.self)
        try await index.deleteAppEntities(ofType: ZforgeLegacyArchiveEntity.self)
        if #available(macOS 27.0, *) { try await filePublication.reset() }
    }
    func remove(_ identifiers: [String]) async throws {
        if #available(macOS 27.0, *) {
            try await filePublication.remove(identifiers)
        } else {
            try await index.deleteAppEntities(identifiedBy: identifiers, ofType: ZforgeLegacyArchiveEntity.self)
        }
    }
    func upsert(_ entities: [ZforgeArchiveEntity]) async throws {
        if #available(macOS 27.0, *) { try await filePublication.upsert(entities) }
        else { try await index.indexAppEntities(entities.map(ZforgeLegacyArchiveEntity.init)) }
    }

    func contextIdentifiers(for entities: [ZforgeArchiveEntity]) async throws -> [String: EntityIdentifier] {
        if #available(macOS 27.0, *) { return try await filePublication.contextIdentifiers(for: entities) }
        return try await ArchiveContextPreparation.shared.identifiers(for: entities)
    }

    // The delegate supplies the macOS 26 reindex path. macOS 27 additionally
    // exposes IndexedEntityQuery; both rebuild from live scopes, never the index.
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        acknowledgeAfterReindex(acknowledgementHandler)
    }
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        acknowledgeAfterReindex(acknowledgementHandler)
    }
    private func acknowledgeAfterReindex(_ callback: @escaping () -> Void) {
        let acknowledgement = IndexAcknowledgement(callback)
        Task { @MainActor in
            do { try await ArchiveIndexRuntime.shared.reindex() }
            catch { Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").error("System archive reindex request failed.") }
            acknowledgement.call()
        }
    }
}

nonisolated private final class IndexAcknowledgement: @unchecked Sendable {
    private let callback: () -> Void
    init(_ callback: @escaping () -> Void) { self.callback = callback }
    func call() { callback() }
}

/// Read-only UI snapshot. Lookup in a cell performs no filesystem work.
@MainActor @Observable final class ArchiveContextCatalog {
    static let shared = ArchiveContextCatalog()
    private static let diagnosticsEnabled = CommandLine.arguments.contains("--archive-context-diagnostics")
    private(set) var identifiers: Set<String> = []
    private var presentationIdentifiers: [String: EntityIdentifier] = [:]
    private var physicalIdentifiers: [Data: EntityIdentifier] = [:]
    var unavailable = false

    func replace(_ entities: [ZforgeArchiveEntity], associations: [String: EntityIdentifier]) {
        identifiers = Set(entities.map(\.id))
        presentationIdentifiers = [:]
        physicalIdentifiers = [:]
        var ambiguous: Set<Data> = []
        for entity in entities {
            guard let identifier = associations[entity.id] else { continue }
            for path in entity.presentationPaths { presentationIdentifiers[path] = identifier }
            if let identity = entity.fileIdentity, !ambiguous.contains(identity) {
                if physicalIdentifiers[identity] != nil {
                    // Multiple indexed hard-link paths have no unique fallback.
                    physicalIdentifiers[identity] = nil
                    ambiguous.insert(identity)
                } else { physicalIdentifiers[identity] = identifier }
            }
        }
    }
    func clear() { identifiers = []; presentationIdentifiers = [:]; physicalIdentifiers = [:] }

    func identifier(for item: BrowserItem) -> EntityIdentifier? {
        guard !item.isHidden, !item.isDirectory, !item.isSymbolicLink, item.isArchive, var url = item.localURL else { return nil }
        // Any volume of a split archive stands for the set, published under its opening volume (ZF-83).
        if let volume = item.archiveVolume, !volume.opensSet {
            url = url.deletingLastPathComponent().appendingPathComponent(volume.openingName)
        }
        let identifier = presentationIdentifiers[url.path] ?? item.fileIdentity.flatMap { physicalIdentifiers[$0] }
        if Self.diagnosticsEnabled {
            Logger(subsystem: "io.libor.Zforge", category: "ArchiveContext").notice("Archive context lookup; published=\(self.identifiers.count); matched=\(identifier != nil).")
        }
        return identifier
    }
    func recordContextSelection(_ selected: Bool) {
        guard Self.diagnosticsEnabled else { return }
        Logger(subsystem: "io.libor.Zforge", category: "ArchiveContext").notice("Archive context provider; selected=\(selected).")
    }
}

/// Event-driven, coalesced reconciliation. The stdio launcher never starts this
/// runtime; its successful grant changes notify a running normal application.
@MainActor final class ArchiveIndexRuntime {
    static let shared = ArchiveIndexRuntime()
    private let access: any AutomationAuthorizing
    private let coordinator: ArchiveIndexCoordinator
    private let catalog: ArchiveContextCatalog
    private var monitors: [(DirectoryMonitor, AutomationAccessLease)] = []
    private var observers: [NSObjectProtocol] = []
    private var task: Task<Void, Never>?
    private var revision = 0
    private var resetRequired = false
    private var started = false
    var isStarted: Bool { started }
    private var waiters: [CheckedContinuation<Void, any Error>] = []

    init(access: any AutomationAuthorizing = AutomationGrantStore.shared,
         writer: any ArchiveIndexWriting = SpotlightArchiveWriter(), catalog: ArchiveContextCatalog = .shared) {
        self.access = access
        self.catalog = catalog
        coordinator = ArchiveIndexCoordinator(discovery: AutomationArchiveEntities(access: access), writer: writer)
    }

    func start() {
        guard !started else { return }
        started = true
        observers.append(NotificationCenter.default.addObserver(forName: AutomationGrantStore.changed, object: access as AnyObject, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.requestRefresh() }
        })
        observers.append(DistributedNotificationCenter.default().addObserver(forName: AutomationGrantStore.changed, object: Bundle.main.bundleIdentifier, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.requestRefresh() }
        })
        requestRefresh()
    }

    func stop() {
        started = false
        revision += 1
        task?.cancel()
        stopMonitors()
        catalog.clear()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observers = []
        finishWaiters(.failure(CancellationError()))
    }

    func reindex() async throws {
        guard waiters.count < 32 else { throw AutomationError.busy }
        if !started { start() }
        resetRequired = true
        requestRefresh()
        try await withCheckedThrowingContinuation { waiters.append($0) }
        try Task.checkCancellation()
    }

    func requestRefresh() {
        guard started else { return }
        revision += 1
        catalog.clear()
        stopMonitors()
        if let task { task.cancel(); return }
        launchRefresh()
    }

    private func launchRefresh() {
        let version = revision
        let reset = resetRequired
        resetRequired = false
        task = Task { [weak self] in
            guard let self else { return }
            let start = ContinuousClock.now
            var result: Result<Void, any Error> = .success(())
            do {
                let roots = await access.authorizedFolders()
                try Task.checkCancellation()
                guard roots.count <= 128 else { throw AutomationError.invalidArguments }
                // Watch before scanning: a directory change during enumeration
                // invalidates this generation rather than silently going missing.
                for path in roots {
                    let url = try AutomationPath.url(path)
                    let lease: AutomationAccessLease
                    do { lease = try await access.authorize([url]) }
                    catch AutomationError.authorizationRequired { continue }
                    try Task.checkCancellation()
                    let monitor = DirectoryMonitor()
                    guard monitor.watch(url, onChange: { [weak self] in self?.requestRefresh() }) else { throw AutomationError.notFound }
                    monitors.append((monitor, lease))
                }
                let entities = try await coordinator.reconcile(reset: reset)
                let associations = try await coordinator.contextIdentifiers(for: entities)
                try Task.checkCancellation()
                guard version == revision, started else { throw CancellationError() }
                catalog.replace(entities, associations: associations)
                catalog.unavailable = false
                Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").notice("Archive index reconciled; entities=\(entities.count); duration=\(String(describing: start.duration(to: .now)), privacy: .public).")
            } catch {
                result = .failure(error)
                catalog.clear()
                do { try await coordinator.invalidate() }
                catch { Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").error("Archive index invalidation failed; retry required.") }
                if !(error is CancellationError) {
                    catalog.unavailable = true
                    Logger(subsystem: "io.libor.Zforge", category: "ArchiveDiscovery").error("Archive index reconciliation failed: \(error.localizedDescription, privacy: .private)")
                }
            }
            task = nil
            if started, version != revision { launchRefresh() }
            else { finishWaiters(result) }
        }
    }

    private func stopMonitors() {
        monitors.forEach { $0.0.stop() }
        monitors = []
    }
    private func finishWaiters(_ result: Result<Void, any Error>) {
        let pending = waiters
        waiters = []
        pending.forEach { $0.resume(with: result) }
    }
}
