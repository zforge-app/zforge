@main @MainActor
struct LoggingProfile {
    static func main() throws {
        let log = OSLog(subsystem: "io.libor.Zforge", category: "TagDiscovery")
        let enabled = log.isEnabled(type: .debug)
        let journal = TagJournal(onChanges: { _ in }, onHistory: {})
        let volume = TagJournal.Volume(device: 0, journal: "Logging Fixture",
            paths: [(logical: "/fixture", relative: "/fixture")])
        let start = ContinuousClock.now
        for index in 0..<1000 {
            journal.receive(volume: volume, paths: ["fixture/file.txt"],
                flags: [FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod)], ids: [UInt64(index + 1)])
        }
        let elapsed = start.duration(to: .now)
        Logger(subsystem: "io.libor.Zforge", category: "TagDiscovery").notice("Release logging diagnostic completed: batches=1000")
        let report: [String: Any] = ["debug_enabled": enabled, "batches": 1000,
            "elapsed_seconds": Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18]
        FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) + Data([10]))
    }
}
