import Foundation

struct SevenZipCommandResult: Sendable {
    let code: Int32
    let stdout: Data
    let stderr: Data
}

nonisolated final class SevenZipProcessRunner: @unchecked Sendable {
    private let helperURL: URL?
    private let lock = NSLock()
    private var processes: [UUID: Process] = [:]

    init(helperURL: URL?) {
        self.helperURL = helperURL
    }

    func run(
        arguments: [String],
        password: String?,
        standardOutputURL: URL?,
        workingDirectory: URL,
        hardOutputLimit: Int64? = nil
    ) async throws -> SevenZipCommandResult {
        let operationID = UUID()
        return try await withTaskCancellationHandler {
            try await Task.detached(priority: .userInitiated) { [self] in
                try runSynchronously(
                    operationID: operationID,
                    arguments: arguments,
                    password: password,
                    standardOutputURL: standardOutputURL,
                    workingDirectory: workingDirectory,
                    hardOutputLimit: hardOutputLimit
                )
            }.value
        } onCancel: {
            self.cancel(operationID)
        }
    }

    func cancelAll() {
        lock.lock()
        let current = Array(processes.values)
        lock.unlock()
        for process in current { requestCancellation(of: process) }
    }

    private func runSynchronously(
        operationID: UUID,
        arguments: [String],
        password: String?,
        standardOutputURL: URL?,
        workingDirectory: URL,
        hardOutputLimit: Int64?
    ) throws -> SevenZipCommandResult {
        guard let helperURL, FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw ArchiveEngineError.helperUnavailable
        }

        let ioDirectory = workingDirectory.appendingPathComponent(".zforge-io-\(operationID.uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: ioDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: ioDirectory) }

        let stdoutURL = standardOutputURL ?? ioDirectory.appendingPathComponent("stdout")
        let stderrURL = ioDirectory.appendingPathComponent("stderr")
        FileManager.default.createFile(atPath: stdoutURL.path, contents: nil)
        FileManager.default.createFile(atPath: stderrURL.path, contents: nil)
        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)
        defer {
            try? stdoutHandle.close()
            try? stderrHandle.close()
        }

        let input = Pipe()
        let process = Process()
        process.executableURL = helperURL
        // 7zz reads the password from stdin when no -p switch is present. Keeping
        // the switch out also guarantees that secrets never appear in argv.
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory
        process.standardOutput = stdoutHandle
        process.standardError = stderrHandle
        process.standardInput = input
        register(process, for: operationID)
        defer { unregister(operationID) }

        try process.run()
        if let password { input.fileHandleForWriting.write(Data((password + "\n").utf8)) }
        try? input.fileHandleForWriting.close()

        var exceededLimit = false
        while process.isRunning {
            Thread.sleep(forTimeInterval: 0.05)
            if let hardOutputLimit,
               let attributes = try? FileManager.default.attributesOfItem(atPath: stdoutURL.path),
               let written = (attributes[.size] as? NSNumber)?.int64Value,
               written > hardOutputLimit {
                exceededLimit = true
                requestCancellation(of: process)
                break
            }
        }
        process.waitUntilExit()
        try? stdoutHandle.synchronize()
        try? stderrHandle.synchronize()
        if exceededLimit {
            try? FileManager.default.removeItem(at: stdoutURL)
            throw ArchiveEngineError.sizeLimitExceeded
        }

        return SevenZipCommandResult(
            code: process.terminationStatus,
            stdout: standardOutputURL == nil ? (try Data(contentsOf: stdoutURL)) : Data(),
            stderr: try Data(contentsOf: stderrURL)
        )
    }

    private func register(_ process: Process, for id: UUID) {
        lock.lock(); defer { lock.unlock() }
        processes[id] = process
    }

    private func unregister(_ id: UUID) {
        lock.lock(); defer { lock.unlock() }
        processes.removeValue(forKey: id)
    }

    private func cancel(_ id: UUID) {
        lock.lock()
        let process = processes[id]
        lock.unlock()
        if let process { requestCancellation(of: process) }
    }

    private func requestCancellation(of process: Process) {
        guard process.isRunning else { return }
        process.interrupt()
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.75) {
            if process.isRunning { process.terminate() }
        }
    }
}
