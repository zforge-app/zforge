import AppKit
import Testing
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
