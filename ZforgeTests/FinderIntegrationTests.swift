import AppKit
import Foundation
import Testing
@testable import Zforge

@Suite("Finder shortcut-menu integration")
@MainActor
struct FinderIntegrationTests {
    // MARK: Submenu contents

    @Test("A single archive offers Open, the extraction actions, Validate and Add to Archive")
    func singleArchiveActions() {
        let urls = [URL(fileURLWithPath: "/Users/test/Downloads/Project.7z")]
        #expect(FinderMenuPolicy.actions(for: urls, isDirectory: { _ in false }) == [
            .open, .extractHere, .extractNamed, .extractChoose, .validate, .addToArchive
        ])
    }

    @Test("Several archives also offer compression, like the browser's context menu")
    func multipleArchiveActions() {
        let urls = ["A.zip", "B.tar.gz"].map { URL(fileURLWithPath: "/Users/test/\($0)") }
        #expect(FinderMenuPolicy.actions(for: urls, isDirectory: { _ in false }) == [
            .open, .extractHere, .extractNamed, .extractChoose, .validate, .compress, .compressCustom, .addToArchive
        ])
    }

    @Test("Files, folders and mixed selections leave Open to Finder and offer only compression")
    func plainItemActions() {
        let file = URL(fileURLWithPath: "/Users/test/Report.pdf")
        let folder = URL(fileURLWithPath: "/Users/test/Photos", isDirectory: true)
        let archive = URL(fileURLWithPath: "/Users/test/Old.zip")
        let directories: Set<URL> = [folder]
        let compression: [BrowserSelectionAction] = [.compress, .compressCustom, .addToArchive]
        #expect(FinderMenuPolicy.actions(for: [file], isDirectory: directories.contains) == compression)
        #expect(FinderMenuPolicy.actions(for: [folder], isDirectory: directories.contains) == compression)
        #expect(FinderMenuPolicy.actions(for: [file, archive], isDirectory: directories.contains) == compression)
    }

    @Test("A folder whose name ends in an archive extension is treated as a folder")
    func archiveNamedFolder() {
        let folder = URL(fileURLWithPath: "/Users/test/Backup.zip", isDirectory: true)
        #expect(FinderMenuPolicy.actions(for: [folder], isDirectory: { _ in true }) == [.compress, .compressCustom, .addToArchive])
    }

    @Test("Menu symbols: Open uses the open-in-app arrow, compression actions share doc.zipper with distinct badges")
    func menuSymbolChoices() {
        #expect(BrowserSelectionAction.open.menuSymbol == MenuSymbol("arrow.up.forward.app"))
        #expect(BrowserSelectionAction.compress.menuSymbol == MenuSymbol("doc.zipper"))
        #expect(BrowserSelectionAction.compressCustom.menuSymbol == MenuSymbol("doc.zipper", badge: "gearshape.fill"))
        #expect(BrowserSelectionAction.addToArchive.menuSymbol == MenuSymbol("doc.zipper", badge: "plus.circle.fill"))
        #expect(BrowserSelectionAction.extractHere.menuSymbol == MenuSymbol("square.and.arrow.down"))
        #expect(BrowserSelectionAction.extractNamed.menuSymbol == MenuSymbol("folder.badge.plus"))
        #expect(BrowserSelectionAction.extractChoose.menuSymbol == MenuSymbol("folder"))
        #expect(BrowserSelectionAction.validate.menuSymbol == MenuSymbol("checkmark.circle"))
    }

    @Test("Every action symbol and badge exists and renders as a template for the app's menus", arguments: BrowserSelectionAction.allCases)
    func actionSymbolsExist(action: BrowserSelectionAction) throws {
        guard let symbol = action.menuSymbol else { return }
        #expect(NSImage(systemSymbolName: symbol.name, accessibilityDescription: nil) != nil, "\(action): \(symbol.name)")
        if let badge = symbol.badge {
            #expect(NSImage(systemSymbolName: badge, accessibilityDescription: nil) != nil, "\(action): \(badge)")
        }
        let image = try #require(MenuSymbolImage.image(for: symbol, accessibilityDescription: "Action"))
        #expect(image.isTemplate)
        #expect(image.size.width > 0 && image.size.height > 0)
    }

    @Test("Finder copies are painted in the theme's menu text color at full Retina size",
          arguments: BrowserSelectionAction.allCases, [NSAppearance.Name.darkAqua, .aqua])
    func finderCopyFollowsTheme(action: BrowserSelectionAction, appearanceName: NSAppearance.Name) throws {
        guard let symbol = action.menuSymbol else { return }
        let image = try #require(MenuSymbolImage.image(for: symbol))
        let appearance = try #require(NSAppearance(named: appearanceName))
        let text = MenuSymbolImage.menuTextColor(for: appearance)
        // Finder does not recolor template images: a black symbol on the dark menu was the reported defect.
        let copy = try #require(MenuSymbolImage.bitmapCopy(image, tint: text))
        #expect(copy.size == image.size)
        // Finder draws the first bitmap at its pixel size: one Retina representation only.
        let bitmap = try #require(copy.representations.first as? NSBitmapImageRep)
        #expect(copy.representations.count == 1)
        #expect(bitmap.pixelsWide == Int((image.size.width * 2).rounded(.up)))
        let opaque = (0..<bitmap.pixelsWide).flatMap { x in (0..<bitmap.pixelsHigh).map { (x, $0) } }
            .compactMap { point -> (Int, Int, Double)? in
                guard let color = bitmap.colorAt(x: point.0, y: point.1)?.usingColorSpace(.deviceRGB),
                      color.alphaComponent > 0.9 else { return nil }
                return (point.0, point.1, Double(color.redComponent + color.greenComponent + color.blueComponent) / 3)
            }
        // The symbol fills the copy, not a quarter of it.
        let maxX = opaque.map(\.0).max() ?? 0, maxY = opaque.map(\.1).max() ?? 0
        #expect(Double(maxX) > Double(bitmap.pixelsWide) * 0.6, "\(action) spans \(maxX) of \(bitmap.pixelsWide) pixels")
        #expect(Double(maxY) > Double(bitmap.pixelsHigh) * 0.6, "\(action) spans \(maxY) of \(bitmap.pixelsHigh) pixels")
        let luminance = opaque.map(\.2)
        #expect(!luminance.isEmpty)
        if appearanceName == .darkAqua {
            #expect(luminance.allSatisfy { $0 > 0.8 }, "\(action) is not light on the dark menu")
        } else {
            #expect(luminance.allSatisfy { $0 < 0.2 }, "\(action) is not dark on the light menu")
        }
    }

    @Test("Finder's blank placeholder keeps the symbol column's width and draws nothing")
    func blankPlaceholder() throws {
        let blank = try #require(MenuSymbolImage.bitmapCopy(nil, size: NSSize(width: 18, height: 18), tint: .white))
        #expect(blank.size == NSSize(width: 18, height: 18))
        let bitmap = try #require(blank.representations.first as? NSBitmapImageRep)
        #expect((0..<bitmap.pixelsWide).allSatisfy { x in (0..<bitmap.pixelsHigh).allSatisfy { (bitmap.colorAt(x: x, y: $0)?.alphaComponent ?? 0) == 0 } })
    }

    @Test("Badged symbols keep the body's height and add room for the badge")
    func badgedSymbolGeometry() throws {
        let plain = try #require(MenuSymbolImage.image(for: MenuSymbol("doc.zipper")))
        let badged = try #require(MenuSymbolImage.image(for: MenuSymbol("doc.zipper", badge: "gearshape.fill")))
        let body = try #require(NSImage(systemSymbolName: "doc.zipper", accessibilityDescription: nil))
        #expect(plain.isTemplate)
        #expect(badged.size.width > body.size.width)
        #expect(badged.size.height >= body.size.height)
        #expect(badged.size.height < body.size.height * 1.2)
    }

    @Test("Empty and oversized selections show no Zforge submenu")
    func boundedSelections() {
        #expect(FinderMenuPolicy.actions(for: [], isDirectory: { _ in false }).isEmpty)
        let tooMany = (0...FinderMenuRequest.maximumItems).map { URL(fileURLWithPath: "/Users/test/\($0).zip") }
        #expect(FinderMenuPolicy.actions(for: tooMany, isDirectory: { _ in false }).isEmpty)
    }

    @Test("Finder offers the browser's actions for the same real items, except Open for plain items")
    func parityWithBrowserMenu() async throws {
        let root = try temporaryFolder("ZforgeFinderParity")
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("Note.txt")
        let folder = root.appendingPathComponent("Folder", isDirectory: true)
        let archiveFolder = root.appendingPathComponent("Looks.zip", isDirectory: true)
        let archive = root.appendingPathComponent("Real.zip")
        let second = root.appendingPathComponent("Second.7z")
        try Data("note".utf8).write(to: file)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: archiveFolder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"), to: archive)
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("nested.7z"), to: second)

        let service = FileSystemService()
        for selection in [[file], [folder], [archiveFolder], [archive], [archive, second], [archive, file], [folder, second]] {
            var items: [BrowserItem] = []
            for url in selection { items.append(try await service.item(at: url)) }
            let browser = BrowserSelectionActionPolicy.actions(for: items)
            let expected = items.allSatisfy(\.isArchive) ? browser : browser.filter { $0 != .open }
            let finder = FinderMenuPolicy.actions(for: selection) {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            #expect(finder == expected, "Selection: \(selection.map(\.lastPathComponent))")
        }
    }

    @Test("Extract to names match the browser's menu title, including compound suffixes")
    func extractionNames() async throws {
        let root = try temporaryFolder("ZforgeFinderNames")
        defer { try? FileManager.default.removeItem(at: root) }
        let urls = ["Photos.tar.gz", "Backup.7z", ".zip"].map { root.appendingPathComponent($0) }
        for url in urls { try Data().write(to: url) }
        #expect(FinderMenuPolicy.extractionNames(for: urls, fallback: "Archive") == "Photos, Backup, .zip")

        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }
        var items: [BrowserItem] = []
        for url in urls { items.append(try await FileSystemService().item(at: url)) }
        let names = FinderMenuPolicy.extractionNames(for: urls, fallback: "Archive")
        #expect(state.contextualTitle(.extractNamed, items: items) == "Extract to \"\(names)\"")
    }

    // MARK: Request hand-off

    @Test("A submitted request is delivered once and removed from the inbox")
    func inboxDeliversOnce() throws {
        let inbox = FinderRequestInbox(directory: try temporaryFolder("ZforgeFinderInbox"))
        defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let request = FinderMenuRequest(action: .extractHere, urls: [URL(fileURLWithPath: "/Users/test/A.zip")])
        try inbox.submit(request)

        #expect(inbox.drain() == [request])
        #expect(inbox.drain().isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: inbox.directory.path).isEmpty)
    }

    @Test("Requests are delivered in the order they were chosen")
    func inboxOrder() throws {
        let inbox = FinderRequestInbox(directory: try temporaryFolder("ZforgeFinderInboxOrder"))
        defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let now = Date()
        let later = FinderMenuRequest(action: .validate, urls: [URL(fileURLWithPath: "/a/B.zip")], createdAt: now)
        let earlier = FinderMenuRequest(action: .compress, urls: [URL(fileURLWithPath: "/a/A.txt")], createdAt: now.addingTimeInterval(-3))
        try inbox.submit(later)
        try inbox.submit(earlier)
        #expect(inbox.drain(now: now) == [earlier, later])
    }

    @Test("Stale, future, malformed and unsupported requests are discarded and removed")
    func inboxRejectsInvalidRequests() throws {
        let inbox = FinderRequestInbox(directory: try temporaryFolder("ZforgeFinderInboxInvalid"))
        defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let now = Date()
        let archive = [URL(fileURLWithPath: "/Users/test/A.zip")]
        try inbox.submit(FinderMenuRequest(action: .extractHere, urls: archive,
                                           createdAt: now.addingTimeInterval(-FinderRequestInbox.maximumAge - 1)))
        try inbox.submit(FinderMenuRequest(action: .extractHere, urls: archive, createdAt: now.addingTimeInterval(60)))
        try inbox.submit(FinderMenuRequest(action: .removeFromArchive, urls: archive, createdAt: now))
        try inbox.submit(FinderMenuRequest(action: .compress, urls: [], createdAt: now))
        try writeRaw(#"{"id":"\#(UUID().uuidString)","action":"compress","paths":["relative/file.txt"],"createdAt":\#(now.timeIntervalSinceReferenceDate)}"#, to: inbox)
        try writeRaw(#"{"id":"\#(UUID().uuidString)","action":"compress","paths":["/"],"createdAt":\#(now.timeIntervalSinceReferenceDate)}"#, to: inbox)
        try writeRaw(#"{"id":"\#(UUID().uuidString)","action":"delete","paths":["/a"],"createdAt":\#(now.timeIntervalSinceReferenceDate)}"#, to: inbox)
        try writeRaw("not json", to: inbox)

        #expect(inbox.drain(now: now).isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: inbox.directory.path).isEmpty)
    }

    @Test("A missing inbox directory yields no requests")
    func missingInbox() {
        let inbox = FinderRequestInbox(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("ZforgeFinderMissing-\(UUID().uuidString)", isDirectory: true))
        #expect(inbox.drain().isEmpty)
    }

    @Test("The wake URL queues one browser window per request")
    func appDelegateQueuesRequests() throws {
        let inbox = FinderRequestInbox(directory: try temporaryFolder("ZforgeFinderDelegate"))
        defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let first = FinderMenuRequest(action: .extractHere, urls: [URL(fileURLWithPath: "/a/A.zip")], createdAt: Date().addingTimeInterval(-1))
        let second = FinderMenuRequest(action: .compress, urls: [URL(fileURLWithPath: "/a/B.txt")])
        try inbox.submit(first)
        try inbox.submit(second)
        let delegate = AppDelegate()
        var notified = 0
        let observer = NotificationCenter.default.addObserver(forName: AppDelegate.archiveURLsReceived, object: delegate, queue: nil) { _ in
            MainActor.assumeIsolated { notified += 1 }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        delegate.receiveFinderRequests(from: inbox)
        let queued = delegate.takePendingArchiveRequests()
        #expect(queued.map(\.finderRequest) == [first, second])
        #expect(queued.allSatisfy { $0.initialURL == nil && $0.automationAccess == nil })
        #expect(notified == 1)

        delegate.receiveFinderRequests(from: inbox)
        #expect(delegate.takePendingArchiveRequests().isEmpty)
        #expect(notified == 1)
    }

    @Test("Window restoration never repeats a Finder action")
    func restorationDropsRequest() throws {
        let request = BrowserWindowRequest(finderRequest: FinderMenuRequest(action: .extractHere, urls: [URL(fileURLWithPath: "/a/A.zip")]))
        let restored = try JSONDecoder().decode(BrowserWindowRequest.self, from: JSONEncoder().encode(request))
        #expect(restored.id == request.id)
        #expect(restored.finderRequest == nil)
    }

    // MARK: Running the action in a browser window

    @Test("Extract Here from Finder shows the archive selected in its folder and extracts beside it")
    func extractHereRunsInWindow() async throws {
        let root = try temporaryFolder("ZforgeFinderExtract")
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = root.appendingPathComponent("Bundle.zip")
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"), to: archive)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]),
                                            request: FinderMenuRequest(action: .extractHere, urls: [archive]))
        defer { cleanup() }

        await state.start()

        #expect(state.location == .fileSystem(root.standardizedFileURL))
        #expect(state.selectedItems.map(\.name) == ["Bundle.zip"])
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("hello.txt").path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Folder/nested.txt").path))
        #expect(state.error == nil)
        #expect(state.pendingAuthorizationURL == nil)
    }

    @Test("Extract to Name from Finder creates the named folder")
    func extractNamedRunsInWindow() async throws {
        let root = try temporaryFolder("ZforgeFinderExtractNamed")
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = root.appendingPathComponent("Bundle.zip")
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"), to: archive)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .extractNamed, urls: [archive]))

        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Bundle/hello.txt").path))
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("hello.txt").path))
    }

    @Test("Compress from Finder creates an archive with the default profile beside the items")
    func compressRunsInWindow() async throws {
        let root = try temporaryFolder("ZforgeFinderCompress")
        defer { try? FileManager.default.removeItem(at: root) }
        let note = root.appendingPathComponent("Note.txt")
        try Data("Finder compression".utf8).write(to: note)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .compress, urls: [note]))

        let output = root.appendingPathComponent("Note.\(state.preferences.defaultCompressionProfile.options.format.fileExtension)")
        #expect(FileManager.default.fileExists(atPath: output.path))
        try await NativeSevenZipArchiveEngine().testArchive(at: output, password: nil)
        #expect(state.contextualFeedbackMessage != nil)
    }

    @Test("Validate from Finder tests the archive and reports the result")
    func validateRunsInWindow() async throws {
        let root = try temporaryFolder("ZforgeFinderValidate")
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = root.appendingPathComponent("Bundle.zip")
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"), to: archive)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .validate, urls: [archive]))

        #expect(state.contextualFeedbackMessage != nil)
        #expect(state.error == nil)
    }

    @Test("A folder without browser access asks for it first and runs the action once granted")
    func authorizationPrecedesAction() async throws {
        let root = try temporaryFolder("ZforgeFinderAuthorize")
        defer { try? FileManager.default.removeItem(at: root) }
        let archive = root.appendingPathComponent("Bundle.zip")
        try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"), to: archive)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: []),
                                            request: FinderMenuRequest(action: .extractHere, urls: [archive]))
        defer { cleanup() }

        await state.start()

        #expect(state.pendingAuthorizationURL == root.standardizedFileURL)
        #expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("hello.txt").path))

        await state.authorize(root, intendedURL: root)

        #expect(state.pendingAuthorizationURL == nil)
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("hello.txt").path))
        #expect(state.selectedItems.map(\.name) == ["Bundle.zip"])
    }

    @Test("Items in several folders are authorized folder by folder and each extracts in place")
    func multipleFolders() async throws {
        let root = try temporaryFolder("ZforgeFinderFolders")
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("First", isDirectory: true)
        let second = root.appendingPathComponent("Second", isDirectory: true)
        for folder in [first, second] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: fixturesURL.appendingPathComponent("sample-root.zip"),
                                             to: folder.appendingPathComponent("Bundle.zip"))
        }
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: []))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .extractHere, urls: [
            first.appendingPathComponent("Bundle.zip"), second.appendingPathComponent("Bundle.zip")
        ]))
        #expect(state.pendingAuthorizationURL == first.standardizedFileURL)
        await state.authorize(first, intendedURL: first)
        #expect(state.pendingAuthorizationURL == second.standardizedFileURL)
        #expect(!FileManager.default.fileExists(atPath: first.appendingPathComponent("hello.txt").path))
        await state.authorize(second, intendedURL: second)

        #expect(state.pendingAuthorizationURL == nil)
        #expect(FileManager.default.fileExists(atPath: first.appendingPathComponent("hello.txt").path))
        #expect(FileManager.default.fileExists(atPath: second.appendingPathComponent("hello.txt").path))
    }

    @Test("An action that no longer applies to the items reports an error and changes nothing")
    func staleActionIsRejected() async throws {
        let root = try temporaryFolder("ZforgeFinderStale")
        defer { try? FileManager.default.removeItem(at: root) }
        let note = root.appendingPathComponent("Note.txt")
        try Data("plain".utf8).write(to: note)
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .extractHere, urls: [note]))

        #expect(state.error != nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path) == ["Note.txt"])
    }

    @Test("A missing item reports an error without running the action")
    func missingItemIsRejected() async throws {
        let root = try temporaryFolder("ZforgeFinderMissingItem")
        defer { try? FileManager.default.removeItem(at: root) }
        let (state, cleanup) = try makeState(grants: FinderTestGrants(granted: [root]))
        defer { cleanup() }

        await state.performFinderRequest(FinderMenuRequest(action: .extractHere, urls: [root.appendingPathComponent("Gone.zip")]))

        #expect(state.error != nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty)
    }

    // MARK: Helpers

    private var fixturesURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
    }

    private func temporaryFolder(_ prefix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeRaw(_ text: String, to inbox: FinderRequestInbox) throws {
        try Data(text.utf8).write(to: inbox.directory.appendingPathComponent("\(UUID().uuidString).json"))
    }

    private func makeState(grants: FinderTestGrants, request: FinderMenuRequest? = nil) throws -> (FileBrowserState, () -> Void) {
        let suite = "ZforgeFinderIntegration-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = .english
        preferences.viewMode = .list
        let state = FileBrowserState(
            preferences: preferences, fileSystem: FileSystemService(), fileOperations: FileOperationService(),
            recentItems: FinderTestRecents(), grants: grants, archives: NativeSevenZipArchiveEngine(),
            initialFinderRequest: request
        )
        return (state, { state.close(); defaults.removePersistentDomain(forName: suite) })
    }
}

private actor FinderTestGrants: AccessGrantStoring {
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

private final class FinderTestRecents: RecentItemsServing {
    func recentItemURLs() async -> [URL] { [] }
    func stop() {}
}
