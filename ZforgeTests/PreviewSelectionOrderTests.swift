import AppKit
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Zforge

@Suite("Preview selection order")
struct PreviewSelectionOrderTests {
    @Test("The most recently selected item is on top of the preview stack")
    @MainActor
    func multiplePreviewUsesSelectionRecency() {
        let state = FileBrowserState()
        let first = item("First.pdf")
        let second = item("Second.pdf")
        let third = item("Third.pdf")
        state.items = [first, second, third]

        state.select(first)
        state.select(third, modifiers: [.command])
        state.select(second, modifiers: [.command])
        #expect(state.previewItems.map(\.id) == [second.id, third.id, first.id])

        state.select(third, modifiers: [.command])
        #expect(state.previewItems.map(\.id) == [second.id, first.id])
        #expect(state.primarySelection?.id == second.id)

        state.select(third, modifiers: [.command])
        #expect(state.previewItems.map(\.id) == [third.id, second.id, first.id])

        state.select(first)
        state.select(third, modifiers: [.shift], orderedItems: state.items)
        #expect(state.previewItems.map(\.id) == [third.id, second.id, first.id])
    }

    @Test("Two text previews keep the window constraint layout stable")
    @MainActor
    func multipleTextPreviewsKeepStableConstraints() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let swiftURL = directory.appendingPathComponent("Example.swift")
        let markdownURL = directory.appendingPathComponent("README.md")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let firstKiB = String(repeating: "A", count: TextPreviewBuffer.byteLimit)
        try Data((firstKiB + "CONTENT_AFTER_THE_PREVIEW_BUFFER").utf8).write(to: swiftURL)
        try Data("# Example".utf8).write(to: markdownURL)
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(TextPreviewBuffer.load(at: swiftURL) == firstKiB)
        let fileSystem = FileSystemService()
        let swiftItem = try await fileSystem.item(at: swiftURL)
        let markdownItem = try await fileSystem.item(at: markdownURL)
        #expect(swiftItem.contentType?.conforms(to: .text) == true)
        #expect(markdownItem.contentType?.conforms(to: .text) == true)
        let state = FileBrowserState()
        state.viewMode = .list
        state.previewVisible = true
        state.items = [swiftItem, markdownItem]
        state.selection = [swiftItem.id, markdownItem.id]
        state.focusedItemID = markdownItem.id
        state.updatePreview()

        let preview = SelectionOverview(
            state: state,
            items: state.previewItems,
            presentation: .column,
            scale: 1
        )
        .frame(width: BrowserLayoutMetrics.previewWidth, height: 640)
        let host = NSHostingView(rootView: preview)
        let window = TestWindow.make(
            contentRect: NSRect(x: 0, y: 0, width: BrowserLayoutMetrics.previewWidth, height: 640)
        )
        window.contentView = host
        window.contentView?.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(250))
        window.contentView?.layoutSubtreeIfNeeded()
        window.close()

        #expect(state.previewURLs.count == 2)
    }

    @Test("Word and Pages documents use native static thumbnails")
    func documentFormatsAvoidInteractiveQuickLook() {
        #expect(item("Document.doc").usesStaticDocumentThumbnailPreview)
        #expect(item("Document.docx").usesStaticDocumentThumbnailPreview)
        #expect(item("Document.pages").usesStaticDocumentThumbnailPreview)
        #expect(!item("Document.pdf").usesStaticDocumentThumbnailPreview)
    }

    private func item(_ name: String) -> BrowserItem {
        BrowserItem(
            id: BrowserItemID(rawValue: name),
            name: name,
            location: .fileSystem(URL(fileURLWithPath: "/tmp/\(name)")),
            isContainer: false,
            isDirectory: false,
            isPackage: false,
            isSymbolicLink: false,
            isHidden: false,
            isArchive: false,
            size: 0,
            packedSize: nil,
            creationDate: nil,
            modificationDate: nil,
            accessDate: nil,
            tags: [],
            contentTypeIdentifier: nil,
            encrypted: false,
            checksum: nil,
            compressionMethod: nil
        )
    }
}
