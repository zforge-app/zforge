import AppKit
import SwiftUI
import Testing
import WebKit
@testable import Zforge

@Suite("HTML preview")
struct HTMLPreviewTests {
    @Test("Local HTML renders with adjacent CSS and changes with the selected file")
    @MainActor
    func rendersLocalDocumentAndReplacesSelection() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstURL = directory.appendingPathComponent("first.html")
        let secondURL = directory.appendingPathComponent("second.htm")
        try "body { color: rgb(10, 20, 30); }".write(
            to: directory.appendingPathComponent("style.css"), atomically: true, encoding: .utf8
        )
        try "<link rel='stylesheet' href='style.css'><body>First page<script>document.body.innerText = 'Script ran'</script></body>".write(
            to: firstURL, atomically: true, encoding: .utf8
        )
        try "<body>Second page</body>".write(
            to: secondURL, atomically: true, encoding: .utf8
        )

        let firstItem = try await FileSystemService().item(at: firstURL)
        let secondItem = try await FileSystemService().item(at: secondURL)
        #expect(firstItem.usesHTMLDocumentPreview)
        #expect(secondItem.usesHTMLDocumentPreview)
        #expect(!firstItem.usesTextThumbnailPreview)

        let host = HTMLPreviewHostView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = host
        defer { window.close() }

        host.display(firstURL)
        let firstWebView = try #require(host.subviews.first as? WKWebView)
        try await expectJavaScript("document.body.innerText", equals: "First page", in: firstWebView)
        try await expectJavaScript(
            "getComputedStyle(document.body).color", equals: "rgb(10, 20, 30)", in: firstWebView
        )

        host.display(secondURL)
        let secondWebView = try #require(host.subviews.first as? WKWebView)
        #expect(firstWebView !== secondWebView)
        #expect(firstWebView.superview == nil)
        try await expectJavaScript("document.body.innerText", equals: "Second page", in: secondWebView)
        host.reset()
        #expect(host.subviews.isEmpty)
    }

    @Test("HTML receives a visible frame in the real selection preview layout")
    @MainActor
    func rendersInsideSelectionOverview() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("preview.html")
        try "<body>Visible HTML preview</body>".write(to: url, atomically: true, encoding: .utf8)
        let item = try await FileSystemService().item(at: url)

        let state = FileBrowserState()
        state.preferences.viewMode = .list
        state.previewVisible = true
        state.items = [item]
        state.selection = [item.id]
        state.focusedItemID = item.id
        state.updatePreview()
        #expect(state.previewURL == url)

        let overview = SelectionOverview(
            state: state, items: state.previewItems, presentation: .column, scale: 1
        )
        .frame(width: 300, height: 640)
        let hostingView = NSHostingView(rootView: overview)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 640),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.contentView = hostingView
        defer { window.close() }
        hostingView.layoutSubtreeIfNeeded()

        let webView = try #require(allSubviews(of: hostingView).compactMap { $0 as? WKWebView }.first)
        #expect(webView.bounds.width > 200)
        #expect(webView.bounds.height > 200)
        try await expectJavaScript("document.body.innerText", equals: "Visible HTML preview", in: webView)
    }

    @MainActor
    private func allSubviews(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + allSubviews(of: $0) }
    }

    @MainActor
    private func expectJavaScript(_ script: String, equals expected: String, in webView: WKWebView) async throws {
        for _ in 0..<50 {
            if let result = try? await webView.evaluateJavaScript(script),
               let value = result as? String, value == expected {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }
        Issue.record("HTML preview did not render expected value: \(expected)")
    }
}
