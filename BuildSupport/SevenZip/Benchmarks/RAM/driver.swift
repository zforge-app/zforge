// Injected only into temporary benchmark snapshots, never into shipped app targets.
import AppKit
import Darwin
import CryptoKit
import SwiftUI

@MainActor
enum ArchiveRAMBenchmark {
    static var descriptor: Int32 = -1
    static var windowController: NSWindowController?
    static func send(_ object: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: object) + Data([10])
        try data.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let count = Darwin.write(descriptor, buffer.baseAddress!.advanced(by: offset), buffer.count - offset)
                guard count > 0 else { throw NSError(domain: "RAMBenchmark.socket", code: Int(errno)) }
                offset += count
            }
        }
    }
    static func argument(_ flag: String) -> String {
        let args = ProcessInfo.processInfo.arguments
        return args[args.firstIndex(of: flag)! + 1]
    }
    static func start() {
        guard ProcessInfo.processInfo.arguments.contains("--ram-benchmark-port") else { return }
        Task {
            do {
                descriptor = socket(AF_INET, SOCK_STREAM, 0)
                var address = sockaddr_in()
                address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
                address.sin_family = sa_family_t(AF_INET)
                address.sin_port = UInt16(argument("--ram-benchmark-port"))!.bigEndian
                address.sin_addr.s_addr = inet_addr("127.0.0.1")
                let status = withUnsafePointer(to: &address) { pointer in
                    pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                guard status == 0 else { throw NSError(domain: "RAMBenchmark.connect", code: Int(errno)) }
                var noSigPipe: Int32 = 1
                setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
                let window = NSWindow(contentViewController: NSHostingController(rootView: ContentView()))
                window.title = "Zforge"
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                window.setContentSize(NSSize(width: 1100, height: 720))
                window.isReleasedWhenClosed = false
                windowController = NSWindowController(window: window)
                windowController?.showWindow(nil)
                try await Task.sleep(for: .seconds(2))
                let root = FileManager.default.temporaryDirectory.appendingPathComponent("RAMBenchmark-" + UUID().uuidString)
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: root) }
                let source = root.appendingPathComponent(argument("--ram-benchmark-dataset"))
                try autoreleasepool { try generate(source) }
                let originals = try autoreleasepool { try hashes(source) }
                try await Task.sleep(for: .seconds(1))
                let output = root.appendingPathComponent(argument("--ram-benchmark-output"))
                try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
                let format: ArchiveCompressionFormat = argument("--ram-benchmark-format") == "zip" ? .zip : .sevenZip
                let options = format == .zip
                    ? CompressionOptions(format: .zip, level: 5, method: .deflate, fastBytes: 32, threads: 2)
                    : CompressionOptions(format: .sevenZip, level: 5, method: .lzma2, dictionaryMB: 64, fastBytes: 32, solid: true, threads: 2)
                let archive = output.appendingPathComponent("Archive." + format.fileExtension)
                let engine = __ENGINE__()
                try send(["kind": "ready", "pid": getpid(), "windows": NSApp.windows.count, "benchmark_window_visible": window.isVisible])
                var acknowledgment: UInt8 = 0
                guard Darwin.read(descriptor, &acknowledgment, 1) == 1 && acknowledgment == 65 else { throw NSError(domain: "RAMBenchmark.ack", code: 1) }
                try await phase("baseline") { try await Task.sleep(for: .seconds(2)) }
                try await phase("create") {
                    try await engine.createArchive(from: [source], outputURL: archive, options: options, password: nil, progress: { _ in })
                }
                try await phase("list") {
                    let opened = try await engine.openArchive(at: archive, password: nil)
                    let items = try await engine.items(at: opened.address)
                    guard !items.isEmpty else { throw ArchiveEngineError.itemNotFound }
                }
                try await phase("test") { try await engine.testArchive(at: archive, password: nil) }
                let destination = output.appendingPathComponent("Extracted")
                try await phase("extract") {
                    try await engine.extractArchive(at: archive, to: destination, password: nil,
                        resolveConflict: { _ in .replace(applyToAll: true) }, progress: { _ in })
                }
                try await phase("cleanup") { await engine.closeAllSessions() }
                try await phase("post") { try await Task.sleep(for: .seconds(3)) }
                let extracted = destination.appendingPathComponent(source.lastPathComponent)
                guard try hashes(extracted) == originals else { throw NSError(domain: "RAMBenchmark.hash", code: 1) }
                try send(["kind": "done", "verified_files": originals.count, "hashes_match": true])
            } catch {
                try? send(["kind": "error", "message": String(describing: error)])
                NSLog("RAM benchmark failed: %@", String(describing: error))
            }
            if descriptor >= 0 { close(descriptor) }
            NSApp.terminate(nil)
        }
    }
    static func generate(_ source: URL) throws {
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        var seed: UInt64 = 42
        func bytes(_ count: Int) -> Data {
            var result = Data(count: count)
            result.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
                for offset in stride(from: 0, to: count, by: 8) {
                    seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
                    var value = seed.littleEndian
                    withUnsafeBytes(of: &value) { part in
                        buffer.baseAddress!.advanced(by: offset).copyMemory(from: part.baseAddress!, byteCount: 8)
                    }
                }
            }
            return result
        }
        if source.lastPathComponent == "Large" {
            let file = source.appendingPathComponent("Large.bin")
            FileManager.default.createFile(atPath: file.path, contents: nil)
            let handle = try FileHandle(forWritingTo: file)
            defer { try? handle.close() }
            let block = bytes(512 * 1024) + Data(count: 512 * 1024)
            for _ in 0..<256 { try autoreleasepool { try handle.write(contentsOf: block) } }
        } else {
            for index in 0..<10000 {
                let name = String(format: "Item-%05d.bin", index)
                try (bytes(2048) + Data(count: 2048)).write(to: source.appendingPathComponent(name))
            }
        }
    }
    static func hashes(_ folder: URL) throws -> [String: Data] {
        var result: [String: Data] = [:]
        for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            let handle = try FileHandle(forReadingFrom: file)
            var hash = SHA256()
            while try autoreleasepool(invoking: {
                guard let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty else { return false }
                hash.update(data: data)
                return true
            }) {}
            try handle.close()
            result[file.lastPathComponent] = Data(hash.finalize())
        }
        return result
    }
    static func phase(_ name: String, operation: () async throws -> Void) async throws {
        try send(["kind": "begin", "phase": name])
        let start = ContinuousClock.now
        try await operation()
        let elapsed = start.duration(to: .now)
        try send(["kind": "end", "phase": name, "duration": String(describing: elapsed)])
    }
}
