import SwiftUI

/// The Acknowledgments window (Zforge ▸ Acknowledgments…): the components the app contains on
/// the left, the chosen one's version, license, website and complete license texts on the
/// right, in the layout of the Keyboard Shortcuts and Settings windows.
struct AcknowledgmentsView: View {
    @State private var preferences = FileBrowserPreferences.shared
    @State private var selection: AcknowledgedComponent.ID?
    private let components: [AcknowledgedComponent]
    private let bundle: Bundle

    init(preferences: FileBrowserPreferences = .shared, bundle: Bundle = .main, selection: String? = nil) {
        _preferences = State(initialValue: preferences)
        let components = Acknowledgments.components(in: bundle)
        self.components = components
        self.bundle = bundle
        _selection = State(initialValue: selection ?? components.first?.id)
    }

    private var locale: Locale { preferences.language.locale }
    private var selected: AcknowledgedComponent? { components.first { $0.id == selection } ?? components.first }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(components, selection: $selection) { component in
                AcknowledgmentRow(component: component, version: Acknowledgments.displayVersion(of: component, in: bundle))
                    .tag(component.id)
            }
            .environment(\.sidebarRowSize, .small)
            .accessibilityIdentifier("acknowledgment-components")
            .navigationSplitViewColumnWidth(
                min: KeyboardShortcutsLayout.sidebarWidth,
                ideal: KeyboardShortcutsLayout.sidebarWidth,
                max: KeyboardShortcutsLayout.sidebarWidth
            )
            // SwiftUI alone can leave a sidebar narrower than its column width (D-75).
            .background {
                SidebarSplitConstraint(
                    minimumWidth: KeyboardShortcutsLayout.sidebarWidth,
                    maximumWidth: KeyboardShortcutsLayout.sidebarWidth
                )
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                if let selected {
                    AcknowledgmentDetail(component: selected, bundle: bundle)
                        .id(selected.id)
                } else {
                    ContentUnavailableView("Acknowledgments", systemImage: "doc.text")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .windowToolbar(title: Text(verbatim: selected?.name ?? ""))
        }
        .frame(minWidth: KeyboardShortcutsLayout.minimumWidth, minHeight: KeyboardShortcutsLayout.minimumHeight)
        .unifiedWindowToolbarStyle()
        .environment(\.locale, locale)
    }
}

/// A component row: its name and, trailing in tertiary text, its version.
struct AcknowledgmentRow: View {
    let component: AcknowledgedComponent
    let version: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: component.name)
                .font(.system(size: 13))
                .lineLimit(1)
            Spacer(minLength: 4)
            if let version {
                Text(verbatim: version)
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: SettingsLayout.sidebarContentHeight, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("acknowledgment-\(component.id)")
    }
}

/// The chosen component: a group with its version, license and website, then each license
/// text in full, selectable, in a group of its own.
struct AcknowledgmentDetail: View {
    let component: AcknowledgedComponent
    let bundle: Bundle

    var body: some View {
        SettingsPaneColumn {
            SettingsGroup {
                if let version = Acknowledgments.displayVersion(of: component, in: bundle) {
                    SettingsRow(title: Text("Version")) {
                        Text(verbatim: version).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                }
                SettingsRow(title: Text("License")) {
                    Text(verbatim: component.license)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SettingsRow(title: Text("Website")) {
                    Link(destination: component.url) {
                        Text(verbatim: component.url.host() ?? component.url.absoluteString)
                    }
                }
            } footer: {
                if component.id == "7zip" {
                    Text("acknowledgments.7zip.note")
                }
            }
            ForEach(component.files, id: \.self) { file in
                SettingsGroup(header: Text(verbatim: file.source)) {
                    // Notices are preformatted plain text: lines keep their breaks and scroll
                    // sideways when they are wider than the pane, as in a text editor.
                    ScrollView(.horizontal) {
                        Text(verbatim: Acknowledgments.text(ofFile: file.name, in: bundle) ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize()
                            .padding(.vertical, 6)
                            .accessibilityIdentifier("acknowledgment-text-\(file.name)")
                    }
                    .scrollIndicators(.automatic)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
