import Darwin
import Foundation

/// Preference suites created by tests (ZF-54). Every suite a test creates is named with
/// `prefix`. Removing a suite empties it, but cfprefsd keeps the domain and writes its file
/// back when the test host exits, so the files cannot be deleted during the run. Instead,
/// the first removal in a run deletes the test suite files that earlier runs left, so the
/// container holds at most one run's empty files.
enum TestSuites {
    static let prefix = "ZforgeTestSuite."

    static var preferencesDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences", isDirectory: true)
    }

    /// When this test host process started, from the kernel.
    static let processStart: Date = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&name, u_int(name.count), &info, &size, nil, 0) == 0 else { return Date() }
        let start = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: TimeInterval(start.tv_sec) + TimeInterval(start.tv_usec) / 1_000_000)
    }()

    /// Deletes the files of test suites last written before `date`; other files are untouched.
    @discardableResult
    static func sweep(olderThan date: Date, in directory: URL = preferencesDirectory) -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return files.filter { file in
            guard file.hasPrefix(prefix), file.hasSuffix(".plist") else { return false }
            let url = directory.appendingPathComponent(file)
            guard let modified = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date,
                  modified < date else { return false }
            return (try? FileManager.default.removeItem(at: url)) != nil
        }
    }

    /// The files earlier runs left, deleted once per test host process.
    static let sweptAtLaunch: [String] = sweep(olderThan: processStart)
}

extension UserDefaults {
    /// Empties a suite a test created and, once per run, deletes the suite files earlier runs
    /// left (see `TestSuites`).
    func removeTestSuite(named suite: String) {
        removePersistentDomain(forName: suite)
        _ = TestSuites.sweptAtLaunch
    }
}
