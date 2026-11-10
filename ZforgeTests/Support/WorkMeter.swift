import Darwin
import Dispatch
import Foundation

/// Measures the work an operation does instead of how long it waits for a processor.
///
/// The unit plan runs hundreds of suites in parallel in one test host, and other agents and
/// builds share the machine. There, wall-clock time mostly measures waiting for the shared
/// cooperative pool and the cores, and even thread CPU time grows about 1.6 times under load
/// (efficiency cores, kernel contention), while the instructions an operation retires stay
/// within about 2 % (ZF-68, D-86). The operation runs with this meter as its task executor
/// preference: its nonisolated work and the default actors it calls run as jobs on a private
/// serial queue, and each job's retired instructions, thread CPU time and count are added up.
///
/// Work that leaves the task (another task, the main actor, a system daemon) is not counted;
/// use it only for operations whose work stays on their own actors.
nonisolated final class WorkMeter: TaskExecutor, @unchecked Sendable {
    /// Instructions per nanosecond that a performance core of the reference Mac retires on the
    /// archive discovery workload: 720 M instructions took 75 ms of wall-clock time alone on a
    /// lightly loaded machine (2026-11-09). A latency budget in milliseconds becomes an
    /// instruction budget at this rate.
    static let referenceInstructionsPerNanosecond: UInt64 = 10

    struct Measurement: Sendable {
        /// Instructions the operation's jobs retired (user and kernel).
        let instructions: UInt64
        /// The instructions at the reference rate: the gated measure.
        var work: Duration { .nanoseconds(Int64(instructions / WorkMeter.referenceInstructionsPerNanosecond)) }
        /// Thread CPU time, for the record: it grows with machine load.
        let cpu: Duration
        /// Wall-clock time, for the record: it includes waiting for the processor.
        let wall: Duration
        let jobs: Int
    }

    enum MeterError: Error { case instructionCounterUnavailable }

    private typealias SelfCounts = @convention(c) (Int32, UnsafeMutableRawPointer, Int) -> Int32
    /// `thread_selfcounts(1, …)` (libsystem_kernel) reads the calling thread's fixed counters:
    /// instructions, then cycles. Not public API; the test target uses it only to measure.
    private static let selfCounts: SelfCounts? = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "thread_selfcounts")
        .map { unsafeBitCast($0, to: SelfCounts.self) }

    private static func threadInstructions() -> UInt64? {
        guard let selfCounts else { return nil }
        var counters: (instructions: UInt64, cycles: UInt64) = (0, 0)
        let status = withUnsafeMutableBytes(of: &counters) { selfCounts(1, $0.baseAddress!, $0.count) }
        return status == 0 ? counters.instructions : nil
    }

    private let queue = DispatchQueue(label: "ZforgeTests.WorkMeter", qos: .userInitiated)
    private let lock = NSLock()
    private var instructions: UInt64 = 0
    private var cpu: UInt64 = 0
    private var jobs = 0
    private var countersFailed = false

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        let executor = asUnownedTaskExecutor()
        queue.async {
            let cpuStart = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)
            let before = Self.threadInstructions()
            job.runSynchronously(on: executor)
            let after = Self.threadInstructions()
            let cpuUsed = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - cpuStart
            self.lock.withLock {
                if let before, let after { self.instructions += after - before } else { self.countersFailed = true }
                self.cpu += cpuUsed
                self.jobs += 1
            }
        }
    }

    /// Runs `operation` on this meter and returns its result with the work it did.
    func measure<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> (T, Measurement) {
        let before = lock.withLock { (instructions, cpu, jobs) }
        let start = ContinuousClock.now
        let value = try await withTaskExecutorPreference(self) { try await operation() }
        let wall = start.duration(to: .now)
        // The queue is serial: once this runs, the last job's counts have been added.
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in queue.async { done.resume() } }
        let (after, failed) = lock.withLock { ((instructions, cpu, jobs), countersFailed) }
        guard !failed, after.0 > before.0 else { throw MeterError.instructionCounterUnavailable }
        return (value, Measurement(
            instructions: after.0 - before.0,
            cpu: .nanoseconds(Int64(after.1 - before.1)),
            wall: wall,
            jobs: after.2 - before.2
        ))
    }
}
