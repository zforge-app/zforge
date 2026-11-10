import SwiftUI

/// A profile opened from Settings ▸ Compression.
struct CompressionProfileRoute: Hashable {
    let id: UUID
}

/// Settings ▸ Compression (ZF-58): the default profile, then the profiles as a list whose rows
/// open each profile's settings, as System Settings opens its rows. Add Profile creates one
/// with the standard options and opens it.
struct CompressionSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences
    let openProfile: (UUID) -> Void

    var body: some View {
        SettingsGroup {
            SettingsPickerRow(title: Text("Default compression profile"), identifier: "settings-default-compression-profile",
                              selection: $preferences.defaultCompressionProfileID) {
                ForEach(preferences.compressionProfiles) { profile in
                    Text(verbatim: profile.name).tag(profile.id)
                }
            }
        }
        SettingsGroup(header: Text("Profiles")) {
            ForEach(preferences.compressionProfiles) { profile in
                NavigationLink(value: CompressionProfileRoute(id: profile.id)) {
                    HStack {
                        CompressionProfileRow(profile: profile, isDefault: profile.id == preferences.defaultCompressionProfileID)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-compression-profile-\(profile.name)")
            }
        } footer: {
            HStack {
                Spacer()
                Button("Add Profile") { openProfile(preferences.addCompressionProfile()) }
                    .accessibilityIdentifier("settings-add-compression-profile")
            }
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.trailing, -2)
        }
    }
}

/// One profile in the list, without an icon (user request, 2026-11-02): its name, a Default badge on the default profile and a summary
/// of its options.
struct CompressionProfileRow: View {
    @Environment(\.locale) private var locale
    let profile: CompressionProfile
    let isDefault: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(verbatim: profile.name)
                if isDefault {
                    Text("Default")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.tint.opacity(0.16), in: Capsule())
                }
            }
            Text(verbatim: profile.options.summary(locale: locale))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The settings of one profile. Every change is saved as it is made, as in System Settings;
/// an emptied name returns to the saved one when the field loses focus. The password stays in
/// memory for the session and is kept only once both fields match.
struct CompressionProfileDetailView: View {
    @Bindable var preferences: FileBrowserPreferences
    let id: UUID
    /// Shows another profile in place of this one (after Duplicate Profile).
    let show: (UUID) -> Void
    /// Returns to the profile list (after Delete Profile).
    let close: () -> Void

    @State private var name: String
    @State private var password: String
    @State private var confirmation: String
    @State private var confirmingDelete = false
    @FocusState private var nameFocused: Bool

    init(preferences: FileBrowserPreferences, id: UUID, show: @escaping (UUID) -> Void, close: @escaping () -> Void) {
        self.preferences = preferences
        self.id = id
        self.show = show
        self.close = close
        let session = preferences.sessionPassword(for: id)
        _name = State(initialValue: preferences.compressionProfiles.first { $0.id == id }?.name ?? "")
        _password = State(initialValue: session)
        _confirmation = State(initialValue: session)
    }

    private var profile: CompressionProfile? { preferences.compressionProfiles.first { $0.id == id } }

    private var options: Binding<CompressionOptions> {
        Binding(
            get: { profile?.options ?? CompressionOptions() },
            set: { preferences.updateCompressionProfile(id, options: $0) }
        )
    }

    var body: some View {
        if let profile {
            Form {
                Section {
                    TextField("Profile name", text: $name)
                        .focused($nameFocused)
                        .accessibilityIdentifier("settings-profile-name")
                        .onChange(of: name) { _, name in
                            preferences.updateCompressionProfile(id, name: name)
                            // The field's last edit can arrive after it lost focus.
                            if !nameFocused { restoreEmptyName() }
                        }
                        .onChange(of: nameFocused) { _, focused in
                            if !focused { restoreEmptyName() }
                        }
                        .onSubmit(restoreEmptyName)
                }
                Section {
                    CompressionOptionsFields(options: options)
                }
                if profile.options.requiresPassword && profile.options.supportsPassword {
                    Section {
                        SecureField("Password", text: $password)
                        SecureField("Confirm password", text: $confirmation)
                        if !password.isEmpty && password != confirmation {
                            Text("Passwords do not match.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    } footer: {
                        Text("Passwords stay in memory for this session and are never saved in profiles.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onChange(of: password) { _, _ in storeSessionPassword() }
                    .onChange(of: confirmation) { _, _ in storeSessionPassword() }
                }
                Section {
                } footer: {
                    HStack {
                        Spacer()
                        Button("Duplicate Profile") {
                            if let copy = preferences.duplicateCompressionProfile(id) { show(copy) }
                        }
                        .accessibilityIdentifier("settings-duplicate-compression-profile")
                        Button("Delete Profile", role: .destructive) { confirmingDelete = true }
                            .disabled(preferences.compressionProfiles.count < 2)
                            .accessibilityIdentifier("settings-delete-compression-profile")
                    }
                }
            }
            .formStyle(.grouped)
            .windowToolbar(title: Text(verbatim: profile.name))
            .confirmationDialog(
                Text("Delete “\(profile.name)”?"), isPresented: $confirmingDelete
            ) {
                Button("Delete Profile", role: .destructive) {
                    close()
                    preferences.deleteCompressionProfile(id)
                }
            } message: {
                Text("Archives created with this profile are not affected.")
            }
        } else {
            Color.clear.onAppear(perform: close)
        }
    }

    /// An emptied name is never saved; once editing ends the field shows the saved name again.
    private func restoreEmptyName() {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let saved = profile?.name else { return }
        name = saved
    }

    private func storeSessionPassword() {
        if let stored = Self.sessionPassword(password: password, confirmation: confirmation) {
            preferences.setSessionPassword(stored, for: id)
        }
    }

    /// The password to keep for the session, if any: both fields emptied clear it; a pair that
    /// does not match yet leaves the previous password in place.
    static func sessionPassword(password: String, confirmation: String) -> String? {
        if password.isEmpty && confirmation.isEmpty { return "" }
        return password == confirmation ? password : nil
    }
}
