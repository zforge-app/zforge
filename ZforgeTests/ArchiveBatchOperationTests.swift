import Foundation
import Testing
@testable import Zforge

/// Extract and Validate with several archives selected run one archive after another through
/// the browser's own path (`performContextualAction`, reached here from a Finder request, as the
/// context menu does). D-116: cancelling is not a failure; Validate tests every archive and
/// lists the invalid ones (OR-26).
@Suite("Archive batch operations", .serialized)
@MainActor
struct ArchiveBatchOperationTests {
    @Test("Cancelling a batch extraction stops it without an error alert, and the next batch starts afresh")
    func cancellingBatchExtractionIsNotAnError() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.suspendExtraction(of: "B.zip")

        let run = Task {
            await fixture.state.performFinderRequest(FinderMenuRequest(action: .extractNamed, urls: fixture.archives))
            await fixture.engine.runEnded()
        }
        await fixture.engine.waitUntilSuspended()
        #expect(fixture.state.archiveOperationInProgress, "The overlay with Cancel is shown while B extracts")
        fixture.state.cancelArchiveOperation()
        await run.value

        #expect(await fixture.engine.extracted() == ["A.zip", "B.zip"], "C is not extracted after Cancel")
        #expect(fixture.state.error == nil, "Cancel is not reported as an error: \(String(describing: fixture.state.error))")
        #expect(fixture.state.contextualFeedbackMessage == nil, "No success message after Cancel")
        #expect(!fixture.state.archiveOperationInProgress)
        #expect(fixture.state.archiveProgress == nil)
        #expect(fixture.state.passwordOperation == nil)

        // Repeating the action extracts every archive from the first one.
        await fixture.engine.reset()
        await fixture.state.performFinderRequest(FinderMenuRequest(action: .extractNamed, urls: fixture.archives))
        #expect(await fixture.engine.extracted() == ["A.zip", "B.zip", "C.zip"])
        #expect(fixture.state.error == nil)
        #expect(fixture.state.contextualFeedbackMessage == "Archives extracted successfully.")
    }

    @Test("Cancelling a batch validation stops it without an error alert, and the next batch starts afresh")
    func cancellingBatchValidationIsNotAnError() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.suspendTest(of: "B.zip")

        let run = Task {
            await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))
            await fixture.engine.runEnded()
        }
        await fixture.engine.waitUntilSuspended()
        fixture.state.cancelArchiveOperation()
        await run.value

        #expect(await fixture.engine.tested() == ["A.zip", "B.zip"])
        #expect(fixture.state.error == nil, "Cancel is not reported as an error: \(String(describing: fixture.state.error))")
        #expect(fixture.state.contextualFeedbackMessage == nil)
        #expect(fixture.state.archiveValidationReport == nil, "Nothing invalid was found before Cancel")
        #expect(!fixture.state.archiveOperationInProgress)

        await fixture.engine.reset()
        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))
        #expect(await fixture.engine.tested() == ["A.zip", "B.zip", "C.zip"])
        #expect(fixture.state.contextualFeedbackMessage == "Archives validated successfully.")
    }

    @Test("A failure in a batch extraction is still reported as an error")
    func batchExtractionFailureIsReported() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.failExtraction(of: "B.zip", with: .invalidArchive("Data error"))

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .extractNamed, urls: fixture.archives))

        #expect(fixture.state.error == .archive("Data error"))
        #expect(!fixture.state.archiveOperationInProgress)
    }

    @Test("Validate with several archives tests every one and lists each invalid archive with its reason")
    func validationListsEveryInvalidArchive() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip", "D.zip"])
        defer { fixture.close() }
        await fixture.engine.failTest(of: "B.zip", with: .invalidArchive("CRC failed"))
        await fixture.engine.failTest(of: "C.zip", with: .invalidArchive("Data error"))

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))

        #expect(await fixture.engine.tested() == ["A.zip", "B.zip", "C.zip", "D.zip"], "Every archive is tested")
        #expect(fixture.state.error == nil, "The failures are listed in the report, not in an alert")
        #expect(fixture.state.contextualFeedbackMessage == nil, "No success message when an archive is invalid")
        #expect(!fixture.state.archiveOperationInProgress)
        let report = try #require(fixture.state.archiveValidationReport)
        #expect(report.failures.map(\.name) == ["B.zip", "C.zip"])
        #expect(report.failures.map(\.reason) == ["CRC failed", "Data error"])
        #expect(report.failures.map(\.url) == [fixture.archives[1], fixture.archives[2]])
        #expect(report.archiveCount == 4 && report.testedCount == 4 && !report.wasStopped)
        #expect(report.title(locale: Self.english) == "2 Invalid Archives")
        #expect(report.summary(locale: Self.english) == "Every other archive is valid.")
    }

    @Test("When every archive is invalid, all are listed and nothing claims the others are valid")
    func validationWithEveryArchiveInvalid() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip"])
        defer { fixture.close() }
        await fixture.engine.failTest(of: "A.zip", with: .invalidArchive("Unexpected end of archive"))
        await fixture.engine.failTest(of: "B.zip", with: .invalidArchive("CRC failed"))

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))

        let report = try #require(fixture.state.archiveValidationReport)
        #expect(report.failures.map(\.name) == ["A.zip", "B.zip"])
        #expect(report.summary(locale: Self.english) == nil)
        #expect(fixture.state.error == nil)
    }

    @Test("Validate with every archive valid shows the success message and no report")
    func validationWithEveryArchiveValid() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip"])
        defer { fixture.close() }

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))

        #expect(fixture.state.archiveValidationReport == nil)
        #expect(fixture.state.error == nil)
        #expect(fixture.state.contextualFeedbackMessage == "Archives validated successfully.")
    }

    @Test("Validating one archive that fails keeps the error alert")
    func singleValidationFailureIsAnAlert() async throws {
        let fixture = try BatchFixture(names: ["A.zip"])
        defer { fixture.close() }
        await fixture.engine.failTest(of: "A.zip", with: .invalidArchive("CRC failed"))

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))

        #expect(fixture.state.error == .archive("CRC failed"))
        #expect(fixture.state.archiveValidationReport == nil)
    }

    @Test("Cancel after an invalid archive stops the rest and still lists what was found, saying it stopped")
    func cancellingAfterAFailureListsWhatWasFound() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.failTest(of: "A.zip", with: .invalidArchive("CRC failed"))
        await fixture.engine.suspendTest(of: "B.zip")

        let run = Task {
            await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))
            await fixture.engine.runEnded()
        }
        await fixture.engine.waitUntilSuspended()
        fixture.state.cancelArchiveOperation()
        await run.value

        #expect(await fixture.engine.tested() == ["A.zip", "B.zip"], "C.zip is not tested after Cancel")
        #expect(fixture.state.error == nil, "Cancel is not an error")
        let report = try #require(fixture.state.archiveValidationReport)
        #expect(report.failures.map(\.name) == ["A.zip"])
        #expect(report.archiveCount == 3 && report.testedCount == 1 && report.wasStopped)
        #expect(report.summary(locale: Self.english) == "Validation was stopped before every archive was tested.")
    }

    @Test("An encrypted archive in the batch asks for its password, and the batch goes on after it")
    func passwordInTheMiddleOfTheBatch() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.requirePassword("secret", for: "B.zip")
        await fixture.engine.failTest(of: "C.zip", with: .invalidArchive("CRC failed"))

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))
        #expect(fixture.state.passwordOperation?.prompt(locale: Self.english) == "Enter the password to validate “B.zip”.")
        #expect(fixture.state.archiveValidationReport == nil, "No report while archives remain")

        await fixture.state.submitPassword("wrong")
        #expect(fixture.state.passwordError == "Incorrect password. Try again.")
        #expect(fixture.state.archiveValidationReport == nil)

        await fixture.state.submitPassword("secret")
        #expect(fixture.state.passwordOperation == nil)
        #expect(await fixture.engine.tested() == ["A.zip", "B.zip", "B.zip", "B.zip", "C.zip"])
        let report = try #require(fixture.state.archiveValidationReport)
        #expect(report.failures.map(\.name) == ["C.zip"])
        #expect(!report.wasStopped)
    }

    @Test("Cancel in the password sheet stops the batch like the overlay's Cancel, listing what was found")
    func cancellingThePasswordStopsTheBatch() async throws {
        let fixture = try BatchFixture(names: ["A.zip", "B.zip", "C.zip"])
        defer { fixture.close() }
        await fixture.engine.failTest(of: "A.zip", with: .invalidArchive("CRC failed"))
        await fixture.engine.requirePassword("secret", for: "B.zip")

        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: fixture.archives))
        #expect(fixture.state.passwordOperation != nil)
        fixture.state.cancelPasswordEntry()

        #expect(fixture.state.passwordOperation == nil)
        #expect(await fixture.engine.tested() == ["A.zip", "B.zip"])
        #expect(fixture.state.error == nil)
        let report = try #require(fixture.state.archiveValidationReport)
        #expect(report.failures.map(\.name) == ["A.zip"])
        #expect(report.testedCount == 1 && report.wasStopped)

        // The next Validate starts afresh, with no leftover failure or queue.
        fixture.state.archiveValidationReport = nil
        await fixture.engine.reset()
        await fixture.state.performFinderRequest(FinderMenuRequest(action: .validate, urls: [fixture.archives[2]]))
        #expect(await fixture.engine.tested() == ["C.zip"])
        #expect(fixture.state.archiveValidationReport == nil)
        #expect(fixture.state.contextualFeedbackMessage == "Archives validated successfully.")
    }

    private static let english = Locale(identifier: "en")
}

@MainActor
private final class BatchFixture {
    let root: URL
    let archives: [URL]
    let engine: ScriptedBatchEngine
    let state: FileBrowserState
    private let suite: String
    private let defaults: UserDefaults

    init(names: [String]) throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeArchiveBatch-\(UUID().uuidString)", isDirectory: true)
        self.root = root
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        archives = try names.map { name in
            let url = root.appendingPathComponent(name)
            try Data("placeholder for \(name)".utf8).write(to: url)
            return url
        }
        engine = ScriptedBatchEngine()
        suite = "ZforgeTestSuite.ArchiveBatch-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
        state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(), fileOperations: FileOperationService(),
            recentItems: BatchTestRecents(), grants: BatchTestGrants(granted: [root]), archives: engine
        )
    }

    func close() {
        state.close()
        defaults.removeTestSuite(named: suite)
        try? FileManager.default.removeItem(at: root)
    }
}

/// Records the archives it is asked to extract or test; an archive can fail, or wait for
/// `cancelAllOperations` (the overlay's Cancel) and then report `cancelled` as the native
/// engine does.
private actor ScriptedBatchEngine: ArchiveServing {
    private var extractedNames: [String] = []
    private var testedNames: [String] = []
    private var failures: [String: ArchiveEngineError] = [:]
    private var passwords: [String: String] = [:]
    private var suspendedExtraction: String?
    private var suspendedTest: String?
    private var suspended: CheckedContinuation<Void, Never>?
    private var suspensionWaiters: [CheckedContinuation<Void, Never>] = []
    private var isSuspended = false
    private var hasRunEnded = false

    func runEnded() {
        hasRunEnded = true
        suspensionWaiters.forEach { $0.resume() }
        suspensionWaiters.removeAll()
    }

    func extracted() -> [String] { extractedNames }
    func tested() -> [String] { testedNames }

    func failExtraction(of name: String, with error: ArchiveEngineError) { failures["extract:" + name] = error }
    func failTest(of name: String, with error: ArchiveEngineError) { failures["test:" + name] = error }
    func suspendExtraction(of name: String) { suspendedExtraction = name }
    func suspendTest(of name: String) { suspendedTest = name }
    func requirePassword(_ password: String, for name: String) { passwords[name] = password }

    func reset() {
        extractedNames = []
        testedNames = []
        failures = [:]
        passwords = [:]
        suspendedExtraction = nil
        suspendedTest = nil
        hasRunEnded = false
    }

    /// Returns once an operation is suspended, or once the run ended without suspending (a
    /// regression), so a test fails on its expectations instead of hanging.
    func waitUntilSuspended() async {
        if isSuspended || hasRunEnded { return }
        await withCheckedContinuation { suspensionWaiters.append($0) }
    }

    private func run(_ kind: String, _ name: String, password: String?, suspends: Bool) async throws {
        if let required = passwords[name] {
            guard let password else { throw ArchiveEngineError.passwordRequired }
            guard password == required else { throw ArchiveEngineError.invalidPassword }
        }
        if suspends {
            await withCheckedContinuation { continuation in
                suspended = continuation
                isSuspended = true
                suspensionWaiters.forEach { $0.resume() }
                suspensionWaiters.removeAll()
            }
            throw ArchiveEngineError.cancelled
        }
        if let failure = failures[kind + ":" + name] { throw failure }
    }

    func extractArchive(at url: URL, to destinationURL: URL, password: String?,
                        resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {
        let name = url.lastPathComponent
        extractedNames.append(name)
        try await run("extract", name, password: password, suspends: name == suspendedExtraction)
    }

    func testArchive(at url: URL, password: String?) async throws {
        let name = url.lastPathComponent
        testedNames.append(name)
        try await run("test", name, password: password, suspends: name == suspendedTest)
    }

    func cancelAllOperations() async {
        isSuspended = false
        suspended?.resume()
        suspended = nil
    }

    func openArchive(at url: URL, password: String?) async throws -> ArchiveOpenResult { throw ArchiveEngineError.itemNotFound }
    func items(at address: ArchiveAddress) async throws -> [BrowserItem] { [] }
    func materialize(item: BrowserItem, purpose: ArchiveMaterializationPurpose, automaticLimit: Int64?) async throws -> URL {
        throw ArchiveEngineError.itemNotFound
    }
    func createArchive(from sourceURLs: [URL], outputURL: URL, options: CompressionOptions, password: String?,
                       progress: @escaping ArchiveProgressHandler) async throws {}
    func extractItems(_ items: [BrowserItem], to destinationURL: URL, password: String?,
                      resolveConflict: @escaping ArchiveConflictResolver, progress: @escaping ArchiveProgressHandler) async throws {}
    func recursiveSize(of item: BrowserItem) async throws -> Int64 { 0 }
    func archiveRootURL(for address: ArchiveAddress) async throws -> URL { throw ArchiveEngineError.itemNotFound }
    func setPassword(_ password: String?, for sessionID: UUID) async {}
    func closeSession(_ sessionID: UUID) async {}
    func closeAllSessions() async {}
    func cleanupStaleSessions() async {}
}

private actor BatchTestGrants: AccessGrantStoring {
    private var granted: [String]

    init(granted: [URL]) { self.granted = granted.map { $0.standardizedFileURL.path } }

    func hasGrant(for url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return granted.contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    func storeGrant(for url: URL) { granted.append(url.standardizedFileURL.path) }

    func activateGrant(for url: URL) throws -> URL {
        guard hasGrant(for: url) else { throw BrowserError.permissionDenied(url) }
        return url.standardizedFileURL
    }

    func removeGrant(for url: URL) { granted.removeAll { $0 == url.standardizedFileURL.path } }
    func stopAll() {}
}

private final class BatchTestRecents: RecentItemsServing {
    func recentItemURLs() async -> [URL] { [] }
    func stop() {}
}
