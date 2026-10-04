import AppKit
import Testing
@testable import Zforge

@Suite("Sidebar selection and drop feedback")
@MainActor
struct SidebarInteractionTests {
    @Test("Pointer exit/release clears the final row, while a stale row cannot clear the next")
    func clearsWithoutRowExit() {
        let state = SidebarDropFeedback()
        let a = URL(fileURLWithPath: "/Applications"), b = URL(fileURLWithPath: "/Downloads")
        state.update(owner: "A", target: .folder(a))
        state.validateSession(owner: "A", pointerInside: true, buttonDown: true)
        #expect(state.target == .folder(a))
        state.validateSession(owner: "A", pointerInside: false, buttonDown: true)
        #expect(state.target == nil)
        state.update(owner: "A", target: .folder(a))
        state.update(owner: "B", target: .folder(b))
        state.leave(owner: "A")
        state.validateSession(owner: "A", pointerInside: false, buttonDown: false)
        #expect(state.target == .folder(b))
        state.validateSession(owner: "B", pointerInside: true, buttonDown: false)
        #expect(state.target == nil)
    }

    @Test("Adjacent row edges resolve to the same pin position and the last row appends")
    func rowInsertionTargets() {
        let a = URL(fileURLWithPath: "/A"), b = URL(fileURLWithPath: "/B")
        for y in 27...32 {
            #expect(SidebarDropFeedback.rowTarget(url: a, canInsert: true, nextFavorite: b,
                                                 height: 32, y: CGFloat(y)) == .insertion(b))
        }
        for y in 0...5 {
            #expect(SidebarDropFeedback.rowTarget(url: b, canInsert: true, nextFavorite: nil,
                                                 height: 32, y: CGFloat(y)) == .insertion(b))
        }
        #expect(SidebarDropFeedback.rowTarget(url: b, canInsert: true, nextFavorite: nil,
                                             height: 32, y: 30) == .insertion(nil))
        #expect(SidebarDropFeedback.rowTarget(url: a, canInsert: true, nextFavorite: b,
                                             height: 32, y: 16) == .folder(a))
        #expect(SidebarDropFeedback.rowTarget(url: a, canInsert: false, nextFavorite: nil,
                                             height: 32, y: 0) == .folder(a))
    }

    @Test("The current directory matches canonical URLs, not ancestors or virtual locations")
    func matchesCurrentDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("Folder"), link = root.appendingPathComponent("Link")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: folder)
        #expect(SidebarDropFeedback.isCurrentDirectory(link, current: folder))
        #expect(!SidebarDropFeedback.isCurrentDirectory(root, current: folder))
        #expect(!SidebarDropFeedback.isCurrentDirectory(folder, current: nil))
        #expect(!SidebarDropFeedback.isCurrentDirectory(folder, current: folder.appendingPathComponent("Child")))
    }

    @Test("Insertion draws above the clip view, crosses row bounds, and never intercepts drops")
    func insertionEscapesCellClipping() throws {
        let scroll = NSScrollView(frame: CGRect(x: 0, y: 0, width: 220, height: 180))
        let table = NSTableView(frame: CGRect(x: 0, y: 0, width: 220, height: 180))
        scroll.documentView = table
        let cell = NSView(frame: CGRect(x: 20, y: 50, width: 180, height: 32))
        cell.clipsToBounds = true
        table.addSubview(cell)
        let adapter = SidebarNativeDropFeedbackView(frame: cell.bounds)
        cell.addSubview(adapter)
        adapter.insertionEdge = .top
        adapter.scheduleUpdate()
        let overlay = try #require(scroll.subviews.compactMap { $0 as? SidebarInsertionOverlayView }.first)
        #expect(overlay.superview === scroll)
        #expect(scroll.subviews.last === overlay)
        #expect(overlay.hitTest(.zero) == nil)
        #expect(overlay.wantsLayer)
        // Simulate a selection background added later and raised by native UI.
        let highlight = NSView(frame: cell.frame)
        highlight.wantsLayer = true
        highlight.layer?.zPosition = 3
        scroll.addSubview(highlight, positioned: .above, relativeTo: nil)
        adapter.scheduleUpdate()
        #expect((overlay.layer?.zPosition ?? 0) > (highlight.layer?.zPosition ?? 0))
        let row = overlay.convert(adapter.bounds, from: adapter)
        let top = try #require(overlay.indicatorFrame)
        #expect(top.minY < row.minY && top.maxY > row.minY)
        #expect(top.minX == row.minX - 8)
        #expect(top.height == 8 && scroll.bounds.contains(top))
        adapter.insertionEdge = .bottom
        adapter.scheduleUpdate()
        let bottom = try #require(overlay.indicatorFrame)
        #expect(bottom.minY < row.maxY && bottom.maxY > row.maxY)
        #expect(scroll.bounds.contains(bottom))
        adapter.insertionEdge = nil
        adapter.scheduleUpdate()
        #expect(overlay.indicatorFrame == nil)
    }

    @Test("Native drag feedback is disabled only on the enclosing sidebar table")
    func suppressesOnlyEnclosingTable() {
        let sidebar = NSTableView(), detail = NSTableView()
        let cell = NSView(), adapter = SidebarNativeDropFeedbackView()
        sidebar.draggingDestinationFeedbackStyle = .regular
        detail.draggingDestinationFeedbackStyle = .regular
        sidebar.addSubview(cell)
        cell.addSubview(adapter)
        adapter.suppressFeedback()
        #expect(sidebar.draggingDestinationFeedbackStyle == .none)
        #expect(detail.draggingDestinationFeedbackStyle == .regular)
        #expect(adapter.hitTest(.zero) == nil)
    }
}
