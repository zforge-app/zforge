import AppKit
import SwiftUI

@MainActor
final class BrowserInfoWindowCoordinator: NSObject, NSWindowDelegate {
    static let shared = BrowserInfoWindowCoordinator()

    private var controllers: [ObjectIdentifier: NSWindowController] = [:]

    func present(
        items: [BrowserItem],
        locale: Locale,
        fileSystem: any FileSystemServing,
        archives: any ArchiveServing
    ) {
        guard !items.isEmpty else { return }
        let content = NSHostingController(
            rootView: BrowserInfoWindow(
                items: items,
                locale: locale,
                fileSystem: fileSystem,
                archives: archives
            )
                .environment(\.locale, locale)
        )
        let window = NSWindow(contentViewController: content)
        let controller = NSWindowController(window: window)
        window.title = Self.title(for: items, locale: locale)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 360, height: 470))
        window.minSize = NSSize(width: 320, height: 360)
        window.isReleasedWhenClosed = false
        window.delegate = self
        controllers[ObjectIdentifier(window)] = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    nonisolated static func title(for items: [BrowserItem], locale: Locale) -> String {
        items.count == 1
            ? AppLocalization.string("Info: \(items[0].name)", locale: locale)
            : AppLocalization.string("Info: \(items.count) Items", locale: locale)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        controllers.removeValue(forKey: ObjectIdentifier(window))
    }
}

private struct BrowserInfoWindow: View {
    let items: [BrowserItem]
    let locale: Locale
    let fileSystem: any FileSystemServing
    let archives: any ArchiveServing

    @State private var resolvedFolderSizes: [BrowserItemID: Int64] = [:]
    @State private var calculatingFolderSizes: Set<BrowserItemID> = []

    init(
        items: [BrowserItem],
        locale: Locale,
        fileSystem: any FileSystemServing,
        archives: any ArchiveServing
    ) {
        self.items = items
        self.locale = locale
        self.fileSystem = fileSystem
        self.archives = archives
        _calculatingFolderSizes = State(
            initialValue: Set(
                items
                    .filter(\.hasComputedSize)
                    .map(\.id)
            )
        )
    }

    private var summary: BrowserSelectionSummary {
        BrowserSelectionSummary(
            items: items,
            locale: locale,
            sizeOverrides: resolvedFolderSizes,
            calculatingSizeIDs: calculatingFolderSizes
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    infoIcon
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.title)
                            .font(.title3.weight(.semibold))
                            .lineLimit(3)
                        Text(summary.subtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("Information") {
                    VStack(spacing: 0) {
                        infoRow("Created", summary.creationRange)
                        Divider()
                        infoRow("Modified", summary.modificationRange)
                        if items.count == 1 {
                            Divider()
                            infoRow("Last opened", summary.accessRange)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                GroupBox("Tags") {
                    Text(summary.tags)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
        .task(id: items.map(\.id)) {
            await calculateFolderSizes()
        }
    }

    private var infoIcon: some View {
        ZStack {
            ForEach(Array(items.prefix(3).enumerated()).reversed(), id: \.element.id) { index, item in
                FileIconView(item: item, size: 72)
                    .offset(x: CGFloat(index) * 8, y: CGFloat(index) * -4)
            }
        }
        .frame(width: 96, height: 84)
    }

    private func infoRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }

    private func calculateFolderSizes() async {
        let folders = items.filter {
            $0.hasComputedSize
        }
        calculatingFolderSizes = Set(folders.map(\.id))
        resolvedFolderSizes = [:]

        await withTaskGroup(of: (BrowserItemID, Int64?).self) { group in
            for folder in folders {
                group.addTask {
                    do {
                        let size: Int64
                        if let url = folder.localURL {
                            size = try await fileSystem.recursiveSize(at: url)
                        } else {
                            size = try await archives.recursiveSize(of: folder)
                        }
                        return (folder.id, size)
                    } catch {
                        return (folder.id, nil)
                    }
                }
            }

            for await (id, size) in group {
                guard !Task.isCancelled else {
                    group.cancelAll()
                    return
                }
                if let size {
                    resolvedFolderSizes[id] = size
                }
                calculatingFolderSizes.remove(id)
            }
        }
    }
}
