import QuickLookUI
import SwiftUI
import UniformTypeIdentifiers

enum BrowserLayoutMetrics {
    static let previewWidth: CGFloat = 300
}

@MainActor
final class QuickLookPanelCoordinator: NSObject, QLPreviewPanelDataSource {
    private var urls: [URL] = []

    func present(_ urls: [URL]) {
        self.urls = urls
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.currentPreviewItemIndex = 0
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { urls.count }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> any QLPreviewItem {
        urls[index] as NSURL
    }
}

struct QuickLookPreview: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = true
        return view
    }

    func updateNSView(_ view: QLPreviewView, context: Context) {
        guard view.previewItem?.previewItemURL != url else { return }
        view.previewItem = url as NSURL?
    }
}

enum SelectionOverviewPresentation {
    case gallery
    case column
}

struct SelectionOverview: View {
    @Bindable var state: FileBrowserState
    let items: [BrowserItem]
    let presentation: SelectionOverviewPresentation
    let scale: CGFloat

    private var summary: BrowserSelectionSummary {
        BrowserSelectionSummary(items: items, locale: .current)
    }

    var body: some View {
        if presentation == .gallery {
            galleryOverview
        } else {
            columnOverview
                .frame(width: BrowserLayoutMetrics.previewWidth * scale)
                .overlay(alignment: .leading) {
                    Rectangle().fill(.separator).frame(width: 1)
                }
        }
    }

    private var galleryOverview: some View {
        HStack(spacing: 0) {
            SelectionHero(state: state, items: items, scale: scale)
                .frame(maxWidth: 760 * scale, maxHeight: .infinity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24 * scale)
                .contentShape(Rectangle())
                .onTapGesture { state.clearSelection() }

            if state.previewVisible {
                SelectionInspector(items: items, scale: scale)
                    .frame(width: BrowserLayoutMetrics.previewWidth * scale)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.separator).frame(width: 1)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var columnOverview: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                SelectionHero(state: state, items: items, scale: scale)
                    .frame(height: 320 * scale)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12 * scale)
                    .padding(.top, 12 * scale)

                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.title)
                        .font(.system(size: 15 * scale, weight: .semibold))
                        .lineLimit(2)
                    Text(summary.subtitle)
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12 * scale)
                .padding(.top, 14 * scale)

                PreviewSection(title: "Information", scale: scale) {
                    PreviewMetadataRow(title: "Created", value: summary.creationRange, scale: scale)
                    PreviewMetadataRow(title: "Modified", value: summary.modificationRange, scale: scale)
                    if items.count == 1 {
                        PreviewMetadataRow(title: "Last opened", value: summary.accessRange, scale: scale)
                    }
                }

                PreviewSection(title: "Tags", scale: scale) {
                    Text(summary.tags)
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 7 * scale)
                }
            }
            .padding(.bottom, 12 * scale)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct SelectionHero: View {
    @Bindable var state: FileBrowserState
    let items: [BrowserItem]
    let scale: CGFloat

    var body: some View {
        Group {
            if items.count > 1 {
                ZStack {
                    ForEach(Array(items.prefix(5).enumerated()).reversed(), id: \.element.id) { index, item in
                        FileIconView(item: item, size: 200 * scale)
                            .rotationEffect(.degrees(rotation(for: index)))
                            .offset(
                                x: offset(for: index).width * scale,
                                y: offset(for: index).height * scale
                            )
                            .shadow(color: .black.opacity(0.22), radius: 7 * scale, y: 4 * scale)
                    }
                }
                .frame(width: 360 * scale, height: 300 * scale)
            } else if let item = items.first {
                if item.usesStaticIconPreview {
                    FileIconView(item: item, size: 190 * scale)
                } else if let previewURL = state.previewURL {
                    QuickLookPreview(url: previewURL)
                        .clipShape(RoundedRectangle(cornerRadius: 10 * scale, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                                .stroke(.separator, lineWidth: 1)
                        }
                } else if state.previewRequiresManualLoad {
                    ContentUnavailableView {
                        Label("Preview not loaded", systemImage: "doc.badge.ellipsis")
                    } description: {
                        Text("This archive item is larger than 10 MB.")
                    } actions: {
                        Button("Load Preview") { state.updatePreview(manual: true) }
                    }
                } else {
                    ProgressView()
                }
            }
        }
    }

    private func rotation(for index: Int) -> Double {
        [0.0, -6.0, 5.0, -9.0, 8.0][min(index, 4)]
    }

    private func offset(for index: Int) -> CGSize {
        [
            CGSize(width: 0, height: 8),
            CGSize(width: -28, height: -2),
            CGSize(width: 30, height: 0),
            CGSize(width: -46, height: -18),
            CGSize(width: 48, height: -16)
        ][min(index, 4)]
    }
}

private struct SelectionInspector: View {
    let items: [BrowserItem]
    let scale: CGFloat

    private var summary: BrowserSelectionSummary {
        BrowserSelectionSummary(items: items, locale: .current)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 10 * scale) {
                    SelectionInspectorIcon(items: items, scale: scale)
                    VStack(alignment: .leading, spacing: 3 * scale) {
                        Text(summary.title)
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .lineLimit(2)
                        Text(summary.subtitle)
                            .font(.system(size: 12 * scale))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 12 * scale)
                .padding(.top, 16 * scale)

                PreviewSection(title: "Information", scale: scale) {
                    PreviewMetadataRow(title: "Created", value: summary.creationRange, scale: scale)
                    PreviewMetadataRow(title: "Modified", value: summary.modificationRange, scale: scale)
                    if items.count == 1 {
                        PreviewMetadataRow(title: "Last opened", value: summary.accessRange, scale: scale)
                    }
                }

                PreviewSection(title: "Tags", scale: scale) {
                    Text(summary.tags)
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 7 * scale)
                }
            }
            .padding(.bottom, 16 * scale)
        }
    }
}

private struct SelectionInspectorIcon: View {
    let items: [BrowserItem]
    let scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(items.prefix(3).enumerated()).reversed(), id: \.element.id) { index, item in
                FileIconView(item: item, size: 44 * scale)
                    .offset(x: CGFloat(index) * 5 * scale, y: CGFloat(index) * -2 * scale)
            }
        }
        .frame(width: 58 * scale, height: 52 * scale)
    }
}

private struct BrowserSelectionSummary {
    let items: [BrowserItem]
    let locale: Locale

    var title: String {
        guard items.count != 1 else { return items[0].name }
        return "\(items.count) items"
    }

    var subtitle: String {
        guard items.count > 1 else {
            let item = items[0]
            return "\(kind(item)) · \(item.formattedSize)"
        }

        let folders = items.filter(\.isContainer).count
        let documents = items.count - folders
        var parts: [String] = []
        if documents > 0 { parts.append("\(documents) \(documents == 1 ? "document" : "documents")") }
        if folders > 0 { parts.append("\(folders) \(folders == 1 ? "folder" : "folders")") }
        let totalSize = items.compactMap(\.size).reduce(0, +)
        if totalSize > 0 {
            parts.append(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
        }
        return parts.joined(separator: " · ")
    }

    var creationRange: String { dateRange(items.compactMap(\.creationDate)) }
    var modificationRange: String { dateRange(items.compactMap(\.modificationDate)) }
    var accessRange: String { dateRange(items.compactMap(\.accessDate)) }

    var tags: String {
        let tags = Set(items.flatMap(\.tags)).sorted()
        return tags.isEmpty ? String(localized: "No tags") : tags.joined(separator: ", ")
    }

    private func kind(_ item: BrowserItem) -> String {
        if item.isDirectory { return String(localized: "Folder") }
        if item.isArchive { return String(localized: "Archive") }
        return item.contentType?.localizedDescription ?? String(localized: "Document")
    }

    private func dateRange(_ dates: [Date]) -> String {
        guard let first = dates.min(), let last = dates.max() else { return "—" }
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale)
        let firstText = first.formatted(style)
        let lastText = last.formatted(style)
        return firstText == lastText ? firstText : "\(firstText) – \(lastText)"
    }
}

private struct PreviewSection<Content: View>: View {
    let title: LocalizedStringKey
    let scale: CGFloat
    let content: Content

    init(title: LocalizedStringKey, scale: CGFloat, @ViewBuilder content: () -> Content) {
        self.title = title
        self.scale = scale
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 15 * scale, weight: .semibold))
            content
        }
        .padding(.horizontal, 12 * scale)
        .padding(.top, 16 * scale)
    }
}

private struct PreviewMetadataRow: View {
    let title: LocalizedStringKey
    let value: String
    let scale: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12 * scale) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12 * scale)
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 12 * scale))
        .padding(.vertical, 7 * scale)
        .overlay(alignment: .bottom) { Divider() }
    }
}
