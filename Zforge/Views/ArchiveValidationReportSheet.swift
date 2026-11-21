import SwiftUI

/// Lists the archives a batch Validate found invalid, each with the reason, so the user knows
/// which files are damaged (OR-26). The list scrolls when it is taller than the sheet allows.
struct ArchiveValidationReportSheet: View {
    static let width: CGFloat = 440
    static let listMaximumHeight: CGFloat = 260

    let report: ArchiveValidationReport
    let locale: Locale
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text(verbatim: report.title(locale: locale))
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            .font(.title2.weight(.semibold))

            if let summary = report.summary(locale: locale) {
                Text(verbatim: summary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .vertical) {
                failureRows
                ScrollView { failureRows }
            }
            .frame(maxHeight: Self.listMaximumHeight)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))

            HStack {
                Spacer()
                Button("OK", action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: Self.width)
        .onExitCommand(perform: dismiss)
    }

    private var failureRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(report.failures.enumerated()), id: \.element.id) { index, failure in
                if index > 0 { Divider().padding(.leading, 36) }
                row(failure)
            }
        }
    }

    private func row(_ failure: ArchiveValidationReport.Failure) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: failure.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(verbatim: failure.reason)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .help(failure.url.path)
        .accessibilityElement(children: .combine)
    }
}
