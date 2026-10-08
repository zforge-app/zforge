import AppKit
import MCP

/// Native UI fixtures exercise the real adapter without spawning a GUI app from
/// the sandboxed XCTest runner. Stdio lifecycle has separate packaged-process coverage.
@MainActor
final class AutomationPermissionUIFixture: NSObject {
    private static var instance: AutomationPermissionUIFixture?
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 140),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
    private let result = NSTextField(labelWithString: "Waiting for folder permission")
    private var access: ContextualAutomationAccess?
    private var operations: AutomationOperations?

    static func startIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-fixtures"), arguments.contains("--ui-contextual-permission"), instance == nil else { return }
        let fixture = AutomationPermissionUIFixture()
        instance = fixture
        fixture.start()
    }

    private func start() {
        window.title = "Contextual permission test"
        result.setAccessibilityIdentifier("contextual-permission-result")
        let disconnect = NSButton(title: "Disconnect test client", target: self, action: #selector(disconnectClient))
        disconnect.setAccessibilityIdentifier("contextual-permission-disconnect")
        let stack = NSStackView(views: [result, disconnect])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(stack)
        if let content = window.contentView {
            NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                                         stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)])
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        Task {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("ContextualPermissionUI-" + UUID().uuidString)
            let suite = "ContextualPermissionUI-" + UUID().uuidString
            defer {
                try? FileManager.default.removeItem(at: root)
                UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
            }
            do {
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                let input = root.appendingPathComponent("Input.txt")
                let output = root.appendingPathComponent("Output.zip")
                try Data("Contextual UI fixture".utf8).write(to: input)
                guard let defaults = UserDefaults(suiteName: suite) else { throw AutomationError.invalidArguments }
                let store = AutomationGrantStore(defaults: defaults)
                let access = ContextualAutomationAccess(store: store)
                let operations = AutomationOperations(access: access)
                self.access = access
                self.operations = operations
                let response = await ZforgeMCPServer.call(name: "compress", arguments: ["sources": .array([.string(input.path)]), "destination": .string(output.path), "format": .string("zip")], operations: operations)
                let grants = await store.authorizedFolders()
                let code = response.structuredContent?.objectValue?["error_code"]?.stringValue ?? "missing result"
                result.stringValue = code + "; grants=" + String(grants.count) + "; output=" + String(FileManager.default.fileExists(atPath: output.path))
                await operations.shutdown()
                window.makeKeyAndOrderFront(nil)
            } catch {
                result.stringValue = "Fixture setup failed"
            }
        }
    }

    static func disconnect() { instance?.disconnectClient() }

    @objc private func disconnectClient() {
        Task {
            await operations?.shutdown()
            await access?.cancelPending()
        }
    }
}
