import CoreServices
import Darwin
import Foundation
import OSLog

/// A volume-local event history can survive process restarts and device-number
/// changes. Its UUID changes when the persistent history is invalidated.
@MainActor
final class TagJournal {
    nonisolated struct Scope: Codable, Equatable, Sendable {
        let path: String
        let inode: UInt64
        let journal: String
    }
    struct Volume {
        let device: dev_t
        let journal: String
        var paths: [(logical: String, relative: String)]
    }
    struct Description {
        let scopes: [Scope]
        let volumes: [Volume]
    }
    private final class Context {
        weak var owner: TagJournal?
        let volume: Volume
        init(owner: TagJournal, volume: Volume) { self.owner = owner; self.volume = volume }
    }
    private var streams: [FSEventStreamRef] = []
    private var contexts: [Context] = []
    private var histories: Set<String> = []
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let onChanges: ([TagFileChange]) -> Void
    private let onHistory: () -> Void
    private(set) var cursors: [String: UInt64] = [:]
    private(set) var available = true
    var isReplaying: Bool { !histories.isEmpty }

    init(onChanges: @escaping ([TagFileChange]) -> Void, onHistory: @escaping () -> Void) {
        self.onChanges = onChanges
        self.onHistory = onHistory
    }

    static func describe(_ roots: [URL]) -> Description? {
        var scopes: [Scope] = []
        var volumes: [Volume] = []
        for root in roots.sorted(by: { $0.path < $1.path }) {
            var info = stat()
            var filesystem = statfs()
            guard stat(root.path, &info) == 0 else {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Tag journal scope stat failed: errno=\(errno, privacy: .public)")
                return nil
            }
            guard statfs(root.path, &filesystem) == 0 else {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Tag journal filesystem stat failed: errno=\(errno, privacy: .public)")
                return nil
            }
            guard let uuid = FSEventsCopyUUIDForDevice(info.st_dev) else {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Tag journal UUID unavailable: device=\(info.st_dev, privacy: .public)")
                return nil
            }
            let journal = CFUUIDCreateString(nil, uuid) as String
            let mount = withUnsafePointer(to: &filesystem.f_mntonname) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) }
            }
            // APFS firmlinks expose Data-volume roots as /Users, while external
            // mounts need their mount prefix removed for per-device streams.
            let relative = mount != "/" && TagScanRoots.covers(mount, root.path)
                ? String(root.path.dropFirst(mount.count)) : root.path
            scopes.append(Scope(path: root.path, inode: UInt64(info.st_ino), journal: journal))
            // Despite its array argument, the per-device API accepts exactly
            // one path. Keep independent streams and processed cursors so one
            // scope cannot checkpoint events still pending for another scope.
            volumes.append(Volume(device: info.st_dev, journal: journal,
                paths: [(root.path, relative.isEmpty ? "/" : relative)]))
        }
        return Description(scopes: scopes, volumes: volumes)
    }

    func start(_ description: Description, since saved: [String: UInt64]) {
        let now = FSEventsGetCurrentEventId()
        for volume in description.volumes {
            let key = volume.paths[0].logical
            let since = saved[key] ?? now
            cursors[key] = since
            let context = Context(owner: self, volume: volume)
            contexts.append(context)
            var nativeContext = FSEventStreamContext(version: 0,
                info: Unmanaged.passUnretained(context).toOpaque(), retain: nil, release: nil, copyDescription: nil)
            guard let stream = FSEventStreamCreateRelativeToDevice(kCFAllocatorDefault,
                { _, pointer, count, paths, flags, ids in
                    guard let pointer else { return }
                    let paths = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
                    // The dispatch queue is main. Deliver the entire ordered batch
                    // synchronously so no checkpoint can overtake its work.
                    MainActor.assumeIsolated {
                        let context = Unmanaged<Context>.fromOpaque(pointer).takeUnretainedValue()
                        context.owner?.receive(volume: context.volume, paths: paths,
                            flags: Array(UnsafeBufferPointer(start: flags, count: count)),
                            ids: Array(UnsafeBufferPointer(start: ids, count: count)))
                    }
                }, &nativeContext, volume.device, volume.paths.map(\.relative) as CFArray, since, 0.3,
                FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents
                    | kFSEventStreamCreateFlagWatchRoot)) else {
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Tag journal creation failed")
                available = false; continue
            }
            FSEventStreamSetDispatchQueue(stream, .main)
            guard FSEventStreamStart(stream) else {
                FSEventStreamInvalidate(stream); FSEventStreamRelease(stream)
                Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Tag journal start failed: errno=\(errno, privacy: .public)")
                available = false
                continue
            }
            streams.append(stream)
            histories.insert(key)
        }
    }

    func waitForHistory() async {
        guard isReplaying else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func stop() {
        for stream in streams {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        streams.removeAll()
        contexts.removeAll()
        histories.removeAll()
        finishHistory()
    }

    func receive(volume: Volume, paths: [String], flags: [FSEventStreamEventFlags], ids: [UInt64]) {
        var changes: [TagFileChange] = []
        var done = false
        let loss = FSEventStreamEventFlags(kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped
            | kFSEventStreamEventFlagEventIdsWrapped | kFSEventStreamEventFlagRootChanged)
        for index in flags.indices {
            let flag = flags[index]
            let id = ids[index]
            if id > 0, id < UInt64.max {
                for path in volume.paths { cursors[path.logical] = max(cursors[path.logical] ?? 0, id) }
            }
            if flag & loss != 0 {
                // Loss is volume-level, even if the supplied path is hidden or
                // empty. Every watched scope on this volume needs reconciliation.
                let siblings = contexts.filter { $0.volume.device == volume.device && $0.volume.journal == volume.journal }
                    .flatMap { $0.volume.paths }
                changes += (siblings.isEmpty ? volume.paths : siblings).map { TagFileChange(path: $0.logical,
                    flags: FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs)) }
            }
            if flag & FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone) != 0 { done = true; continue }
            guard index < paths.count else { continue }
            let relative = paths[index].hasPrefix("/") ? paths[index] : "/" + paths[index]
            guard let mapping = volume.paths.sorted(by: { $0.relative.count > $1.relative.count })
                .first(where: { TagScanRoots.covers($0.relative, relative) }) else { continue }
            let suffix = relative.dropFirst(mapping.relative == "/" ? 0 : mapping.relative.count)
            let logical = mapping.logical == "/" ? String(suffix) : mapping.logical + suffix
            let change = TagFileChange(path: logical, flags: flag)
            if change.isRelevant { changes.append(change) }
        }
        onChanges(changes)
        Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").debug(
            "Tag journal batch: events=\(flags.count, privacy: .public), relevant=\(changes.count, privacy: .public), recursive=\(changes.filter(\.requiresRecursiveScan).count, privacy: .public), history_done=\(done, privacy: .public), loss_events=\(flags.filter { $0 & loss != 0 }.count, privacy: .public)"
        )
        if done {
            for path in volume.paths { histories.remove(path.logical) }
            finishHistory(); onHistory()
        }
    }

    private func finishHistory() {
        guard !isReplaying else { return }
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
}
