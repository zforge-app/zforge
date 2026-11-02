import AppKit
import Observation
import SwiftUI

/// The profile and options of one Compress Custom… operation; never written back to the profile.
@MainActor
@Observable
final class CompressionDraft {
    var selectedProfileID: UUID
    var options: CompressionOptions
    var password: String
    var confirmation: String

    init(preferences: FileBrowserPreferences) {
        let profile = preferences.defaultCompressionProfile
        selectedProfileID = profile.id
        options = profile.options
        let initialPassword = preferences.sessionPassword(for: profile.id)
        password = initialPassword
        confirmation = initialPassword
    }

    var passwordIsValid: Bool {
        !options.requiresPassword || (!password.isEmpty && password == confirmation)
    }

    func load(_ profile: CompressionProfile, preferences: FileBrowserPreferences) {
        selectedProfileID = profile.id
        options = profile.options
        password = preferences.sessionPassword(for: profile.id)
        confirmation = password
    }
}

/// The profile choice and the options of one Compress Custom… operation. Profiles are
/// created and edited in Settings ▸ Compression (`CompressionProfileDetailView`).
struct CompressionProfileEditor: View {
    @Bindable var draft: CompressionDraft
    @Bindable var preferences: FileBrowserPreferences
    var onContentChange: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Compression profile")
                FullWidthPopUp(
                    label: AppLocalization.string("Compression profile", locale: preferences.language.locale),
                    items: preferences.compressionProfiles.map { ($0.name, $0.id) },
                    selection: $draft.selectedProfileID,
                    onSelect: { loadSelectedProfile() }
                )
                .frame(maxWidth: .infinity)
            }
            .frame(width: CompressionSaveDialogLayout.contentWidth, alignment: .leading)

            Text("Changes apply to this archive only.")
                .font(.caption)
                .foregroundStyle(.secondary)
            CompressionOptionsFields(
                options: $draft.options,
                password: $draft.password,
                confirmation: $draft.confirmation,
                compact: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: draft.options) { _, _ in onContentChange?() }
        .onChange(of: draft.password) { _, _ in onContentChange?() }
        .onChange(of: draft.confirmation) { _, _ in onContentChange?() }
    }

    private func loadSelectedProfile() {
        if let profile = preferences.compressionProfiles.first(where: { $0.id == draft.selectedProfileID }) {
            draft.load(profile, preferences: preferences)
        }
    }
}

/// The options of a profile: a compact two-column grid in Compress Custom…, Settings rows otherwise.
struct CompressionOptionsFields: View {
    @Environment(\.locale) private var locale
    @Binding var options: CompressionOptions
    var password: Binding<String>? = nil
    var confirmation: Binding<String>? = nil
    var compact = false

    var body: some View {
        if compact {
            compactFields
        } else {
            stackedFields
        }
    }

    private var compactFields: some View {
        HStack(alignment: .top, spacing: CompressionSaveDialogLayout.columnSpacing) {
            VStack(alignment: .leading, spacing: 12) {
                compactPicker("Archive format", selection: $options.format,
                              items: ArchiveCompressionFormat.allCases.map { ($0.title(locale: locale), $0) }) {
                    options = options.normalized()
                }
                if options.supportsLevel {
                    compactPicker("Compression level", selection: $options.level,
                                  items: [
                                    (AppLocalization.string("Store", locale: locale), 0),
                                    (AppLocalization.string("Fastest", locale: locale), 1),
                                    (AppLocalization.string("Fast", locale: locale), 3),
                                    (AppLocalization.string("Normal", locale: locale), 5),
                                    (AppLocalization.string("Maximum", locale: locale), 7),
                                    (AppLocalization.string("Ultra", locale: locale), 9)
                                  ])
                }
                if options.availableMethods.count > 1 {
                    compactPicker("Compression method", selection: $options.method,
                                  items: options.availableMethods.map {
                                      (AppLocalization.string($0.titleKey, locale: locale), $0)
                                  }) {
                        options = options.normalized()
                    }
                }
                if options.format == .sevenZip {
                    solidToggle
                }
                if options.supportsPassword {
                    passwordToggle
                }
                if options.requiresPassword && options.supportsPassword,
                   let password, let confirmation {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("Password", text: password)
                        SecureField("Confirm password", text: confirmation)
                        if !password.wrappedValue.isEmpty,
                           password.wrappedValue != confirmation.wrappedValue {
                            Text("Passwords do not match.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        Text("Passwords stay in memory for this session and are never saved in profiles.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(width: CompressionSaveDialogLayout.columnWidth, alignment: .leading)

            Divider()
                .frame(width: CompressionSaveDialogLayout.dividerWidth)

            VStack(alignment: .leading, spacing: 12) {
                if options.supportsDictionary {
                    compactPicker("Dictionary size", selection: $options.dictionaryMB,
                                  items: [(AppLocalization.string("Automatic", locale: locale), Int?.none)]
                                    + CompressionOptions.dictionaryChoices.map { ("\($0) MB", Int?.some($0)) })
                }
                if options.supportsFastBytes {
                    compactPicker("Fast bytes", selection: $options.fastBytes,
                                  items: [(AppLocalization.string("Automatic", locale: locale), Int?.none)]
                                    + CompressionOptions.fastBytesChoices.map { ("\($0)", Int?.some($0)) })
                }
                if options.supportsThreads {
                    compactPicker("CPU threads", selection: $options.threads,
                                  items: [(AppLocalization.string("Automatic", locale: locale), Int?.none)]
                                    + [1, 2, 4, 8, 16, 32].map { ("\($0)", Int?.some($0)) })
                }
                if options.requiresPassword && options.supportsPassword {
                    if options.format == .sevenZip {
                        encryptNamesToggle
                    } else {
                        compactPicker("ZIP encryption", selection: $options.zipEncryption,
                                      items: ZIPEncryption.allCases.map {
                                          (AppLocalization.string($0.titleKey, locale: locale), $0)
                                      })
                        if options.zipEncryption == .zipCrypto { zipCryptoWarning }
                    }
                }
            }
            .frame(width: CompressionSaveDialogLayout.columnWidth, alignment: .leading)
        }
    }

    private func compactPicker<Value: Hashable>(
        _ title: String.LocalizationValue,
        selection: Binding<Value>,
        items: [(String, Value)],
        onSelect: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppLocalization.string(title, locale: locale))
                .font(.callout)
                .foregroundStyle(.secondary)
            FullWidthPopUp(
                label: AppLocalization.string(title, locale: locale),
                items: items,
                selection: selection,
                onSelect: onSelect
            )
                .frame(width: CompressionSaveDialogLayout.columnWidth)
        }
    }

    @ViewBuilder
    private var stackedFields: some View {
        formatPicker
        if options.supportsLevel { levelPicker }
        if options.availableMethods.count > 1 { methodPicker }
        if options.supportsDictionary { dictionaryPicker }
        if options.supportsFastBytes { fastBytesPicker }
        if options.format == .sevenZip { solidToggle }
        if options.supportsThreads { threadsPicker }
        if options.supportsPassword {
            passwordToggle
            if options.requiresPassword {
                if options.format == .sevenZip {
                    encryptNamesToggle
                } else {
                    zipEncryptionPicker
                    if options.zipEncryption == .zipCrypto { zipCryptoWarning }
                }
            }
        }
    }

    private var formatPicker: some View {
        Picker("Archive format", selection: $options.format) {
            ForEach(ArchiveCompressionFormat.allCases) { format in
                Text(format.title(locale: locale)).tag(format)
            }
        }
        .onChange(of: options.format) { _, _ in options = options.normalized() }
    }

    private var levelPicker: some View {
        Picker("Compression level", selection: $options.level) {
            Text("Store").tag(0)
            Text("Fastest").tag(1)
            Text("Fast").tag(3)
            Text("Normal").tag(5)
            Text("Maximum").tag(7)
            Text("Ultra").tag(9)
        }
    }

    private var methodPicker: some View {
        Picker("Compression method", selection: $options.method) {
            ForEach(options.availableMethods) { method in
                Text(AppLocalization.string(method.titleKey, locale: locale)).tag(method)
            }
        }
        .onChange(of: options.method) { _, _ in options = options.normalized() }
    }

    private var dictionaryPicker: some View {
        Picker("Dictionary size", selection: $options.dictionaryMB) {
            Text("Automatic").tag(Int?.none)
            ForEach(CompressionOptions.dictionaryChoices, id: \.self) { size in
                Text("\(size) MB").tag(Int?.some(size))
            }
        }
    }

    private var fastBytesPicker: some View {
        Picker("Fast bytes", selection: $options.fastBytes) {
            Text("Automatic").tag(Int?.none)
            ForEach(CompressionOptions.fastBytesChoices, id: \.self) { count in
                Text("\(count)").tag(Int?.some(count))
            }
        }
    }

    private var threadsPicker: some View {
        Picker("CPU threads", selection: $options.threads) {
            Text("Automatic").tag(Int?.none)
            ForEach([1, 2, 4, 8, 16, 32], id: \.self) { count in
                Text("\(count)").tag(Int?.some(count))
            }
        }
    }

    private var zipEncryptionPicker: some View {
        Picker("ZIP encryption", selection: $options.zipEncryption) {
            ForEach(ZIPEncryption.allCases) { encryption in
                Text(AppLocalization.string(encryption.titleKey, locale: locale)).tag(encryption)
            }
        }
    }

    private var solidToggle: some View { Toggle("Solid archive", isOn: $options.solid) }
    private var passwordToggle: some View {
        Toggle("Protect with password", isOn: $options.requiresPassword)
    }
    private var encryptNamesToggle: some View {
        Toggle("Encrypt file names", isOn: $options.encryptFileNames)
    }
    private var zipCryptoWarning: some View {
        Text("ZipCrypto offers weaker protection than AES-256.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct FullWidthPopUp<Value: Hashable>: NSViewRepresentable {
    let label: String
    let items: [(String, Value)]
    @Binding var selection: Value
    var onSelect: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.select(_:))
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.parent = self
        button.setAccessibilityLabel(label)
        button.removeAllItems()
        for item in items { button.addItem(withTitle: item.0) }
        if let index = items.firstIndex(where: { $0.1 == selection }) {
            button.selectItem(at: index)
        }
    }

    final class Coordinator: NSObject {
        var parent: FullWidthPopUp

        init(parent: FullWidthPopUp) { self.parent = parent }

        @objc func select(_ button: NSPopUpButton) {
            let index = button.indexOfSelectedItem
            guard parent.items.indices.contains(index) else { return }
            parent.selection = parent.items[index].1
            parent.onSelect?()
        }
    }
}
