import SwiftUI

/// The measurements of a Settings pane (ZF-62), shared by every pane so spacing never drifts:
/// 20 pt side margins, 20 pt between groups, a 13 pt semibold header 8 pt above its group, an
/// 11 pt footer 6 pt below it, rows of at least 36 pt with 12 pt of inner padding.
enum SettingsMetrics {
    static let margin: CGFloat = 20
    static let groupSpacing: CGFloat = 20
    static let headerGap: CGFloat = 8
    static let footerGap: CGFloat = 6
    static let rowMinHeight: CGFloat = 36
    static let rowPadding: CGFloat = 12
    static let rowVerticalPadding: CGFloat = 6
    /// A size slider is inset 10 pt more on each side, so its track keeps the 484 pt the 568 pt form gave it
    /// (the measured steps of the logarithmic scale, D-62/D-73).
    static let sliderInset: CGFloat = 10
    static let groupCornerRadius: CGFloat = 10
    static let topInset: CGFloat = 8
    static let bottomInset: CGFloat = 20
}

/// A pane's scrolling column: its groups stacked 20 pt apart between the 20 pt margins.
struct SettingsPaneColumn<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsMetrics.groupSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.margin)
            .padding(.top, SettingsMetrics.topInset)
            .padding(.bottom, SettingsMetrics.bottomInset)
        }
    }
}

/// A rounded group of rows with an optional header above it and an optional footer below it.
/// The explanation of a group is its footer, never a row inside it.
struct SettingsGroup<Content: View, Footer: View>: View {
    let header: Text?
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    init(header: Text? = nil, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.header = header
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                header
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.leading, 2)
                    .padding(.bottom, SettingsMetrics.headerGap)
            }
            SettingsRows { content }
            footer
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
                .padding(.top, SettingsMetrics.footerGap)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension SettingsGroup where Footer == EmptyView {
    init(header: Text? = nil, @ViewBuilder content: () -> Content) {
        self.init(header: header, content: content, footer: { EmptyView() })
    }
}

/// The rows of a group on its rounded background, a hairline between neighbours.
///
/// Each row keeps its own identity, never its position: a row inserted, removed or moved
/// moves the others instead of rebuilding them, so they keep their state, their focus and a
/// gesture in progress, such as the List Columns drag that moves its own row (D-85).
struct SettingsRows<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SettingsMetrics.groupCornerRadius, style: .continuous)
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Rectangle()
                            .fill(.primary.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, SettingsMetrics.rowPadding)
                    }
                    row
                        .padding(.horizontal, SettingsMetrics.rowPadding)
                        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
                        .frame(maxWidth: .infinity, minHeight: SettingsMetrics.rowMinHeight, alignment: .leading)
                }
            }
        }
        .background(.primary.opacity(0.04), in: shape)
        .overlay(shape.strokeBorder(.primary.opacity(0.06), lineWidth: 0.5))
    }
}

/// A row with a title on the leading edge and its control on the trailing edge.
struct SettingsRow<Title: View, Control: View>: View {
    let title: Title
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 8) {
            title
                .frame(maxWidth: .infinity, alignment: .leading)
            control
        }
    }
}

/// A switch row: the title leads, a small switch trails. The switch keeps the title as its
/// accessibility label.
struct SettingsToggleRow: View {
    let title: Text
    let identifier: String
    @Binding var isOn: Bool

    init(_ title: Text, identifier: String, isOn: Binding<Bool>) {
        self.title = title
        self.identifier = identifier
        _isOn = isOn
    }

    var body: some View {
        SettingsRow(title: title.accessibilityHidden(true)) {
            Toggle(isOn: $isOn) { title }
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .accessibilityIdentifier(identifier)
        }
    }
}

/// A pop-up row: the title leads, the menu trails.
struct SettingsPickerRow<Value: Hashable, Items: View>: View {
    let title: Text
    let identifier: String
    @Binding var selection: Value
    @ViewBuilder let items: Items

    var body: some View {
        SettingsRow(title: title.accessibilityHidden(true)) {
            Picker(selection: $selection) { items } label: { title }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .accessibilityIdentifier(identifier)
        }
    }
}
