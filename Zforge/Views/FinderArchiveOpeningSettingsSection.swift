import SwiftUI

/// What opening an archive from Finder does when Zforge is the default app for its type
/// (ZF-78); the open-or-extract dialog's “Don’t ask again” saves its answer here.
struct FinderArchiveOpeningSettingsSection: View {
    @Bindable var preferences: FileBrowserPreferences

    var body: some View {
        SettingsGroup(header: Text("Archives Opened from Finder")) {
            SettingsPickerRow(title: Text("When Zforge Is the Default App"), identifier: "settings-finder-archive-opening",
                              selection: $preferences.finderArchiveOpening) {
                ForEach(FinderArchiveOpeningChoice.allCases) { choice in
                    Text(AppLocalization.string(choice.titleKey, locale: preferences.language.locale)).tag(choice)
                }
            }
        } footer: {
            Text("Double-clicking an archive whose type opens with Zforge asks, opens it, or extracts it into a folder named after it, next to it, showing only the progress. Open With always opens.")
        }
    }
}
