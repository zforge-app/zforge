import Foundation
import Testing
@testable import Zforge

@Suite("Automation grant consolidation")
struct AutomationGrantConsolidationTests {
    @Test("A parent replaces child grants, persists and revokes all covered future access")
    func parentReplacement() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.child)
        let runningLease = try await fixture.store.authorize([fixture.file])
        try await fixture.store.add(fixture.root)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
        let reopened = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: fixture.suite)))
        #expect(await reopened.authorizedFolders() == [fixture.root.path])
        let parentLease = try await reopened.authorize([fixture.file])
        await reopened.remove(fixture.root.path)
        #expect(await reopened.authorizedFolders().isEmpty)
        await #expect(throws: AutomationError.authorizationRequired) { try await reopened.authorize([fixture.file]) }
        // Existing leases retain their scopes even after their stored bookmark is removed.
        withExtendedLifetime((runningLease, parentLease)) {
            #expect((try? Data(contentsOf: fixture.file)) == Data("Consolidation fixture".utf8))
        }
    }

    @Test("An already covered child or physical alias does not add a redundant bookmark")
    func coveredChild() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.root)
        let original = fixture.defaults.dictionary(forKey: "automationSecurityScopedFolders") as? [String: Data]
        try await fixture.store.add(fixture.child)
        let alias = fixture.container.appendingPathComponent("Alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.child)
        try await fixture.store.add(alias)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
        #expect(fixture.defaults.dictionary(forKey: "automationSecurityScopedFolders") as? [String: Data] == original)
    }

    @Test("Sibling folders with a shared string prefix keep independent access")
    func siblingBoundary() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        let sibling = fixture.container.appendingPathComponent("ParentElsewhere")
        try FileManager.default.createDirectory(at: sibling, withIntermediateDirectories: false)
        try await fixture.store.add(fixture.child)
        try await fixture.store.add(sibling)
        try await fixture.store.add(fixture.root)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path, sibling.path].sorted())
    }

    @Test("A symlink inside the parent pointing outside retains its independent grant")
    func outsideSymlink() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        let outside = fixture.container.appendingPathComponent("Outside")
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: false)
        let link = fixture.root.appendingPathComponent("External")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        try await fixture.store.add(link)
        try await fixture.store.add(fixture.child)
        try await fixture.store.add(fixture.root)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path, link.path].sorted())
        let lease = try await fixture.store.authorize([outside.appendingPathComponent("Future.txt")])
        withExtendedLifetime(lease) {}
    }

    @Test("Invalid parent selection leaves existing bookmarks and access unchanged")
    func failedReplacement() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        try await fixture.store.add(fixture.child)
        let original = fixture.defaults.dictionary(forKey: "automationSecurityScopedFolders") as? [String: Data]
        await #expect(throws: AutomationError.invalidArguments) { try await fixture.store.add(fixture.file) }
        await #expect(throws: (any Error).self) { try await fixture.store.add(fixture.container.appendingPathComponent("Missing")) }
        #expect(fixture.defaults.dictionary(forKey: "automationSecurityScopedFolders") as? [String: Data] == original)
        let lease = try await fixture.store.authorize([fixture.file])
        withExtendedLifetime(lease) {}
    }

    @Test("A parent can consolidate a full 128-folder grant list without exceeding the limit")
    func capacityReplacement() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        for index in 0..<128 {
            let child = fixture.root.appendingPathComponent("Folder-\(index)")
            try FileManager.default.createDirectory(at: child, withIntermediateDirectories: false)
            try await fixture.store.add(child)
        }
        #expect(await fixture.store.authorizedFolders().count == 128)
        try await fixture.store.add(fixture.root)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
    }

    @Test("Adding an already granted parent cleans redundant bookmarks from earlier versions")
    func legacyRedundancy() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        let options: URL.BookmarkCreationOptions = [.withSecurityScope]
        fixture.defaults.set([
            fixture.root.path: try fixture.root.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil),
            fixture.child.path: try fixture.child.bookmarkData(options: options, includingResourceValuesForKeys: nil, relativeTo: nil)
        ], forKey: "automationSecurityScopedFolders")
        #expect(await fixture.store.authorizedFolders().count == 2)
        try await fixture.store.add(fixture.root)
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
    }

    @Test("Concurrent parent and child additions converge to one parent grant")
    func concurrentAdditions() async throws {
        let fixture = try GrantFixture()
        defer { fixture.cleanUp() }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                let folder = index.isMultiple(of: 2) ? fixture.root : fixture.child
                group.addTask { try await fixture.store.add(folder) }
            }
            try await group.waitForAll()
        }
        #expect(await fixture.store.authorizedFolders() == [fixture.root.path])
    }
}

private struct GrantFixture: Sendable {
    let container: URL
    let root: URL
    let child: URL
    let file: URL
    let suite: String
    let store: AutomationGrantStore
    var defaults: UserDefaults { UserDefaults(suiteName: suite)! }

    init() throws {
        container = FileManager.default.temporaryDirectory.appendingPathComponent("GrantConsolidation-" + UUID().uuidString)
        root = container.appendingPathComponent("Parent")
        child = root.appendingPathComponent("Child")
        file = child.appendingPathComponent("Input.txt")
        suite = "GrantConsolidationTests-" + UUID().uuidString
        store = AutomationGrantStore(defaults: try #require(UserDefaults(suiteName: suite)))
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        try Data("Consolidation fixture".utf8).write(to: file)
    }
    func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: container)
    }
}
