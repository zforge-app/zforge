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
            Text(verbatim: Self.footer(locale: preferences.language.locale))
        }
    }

    /// What the choice covers (D-116): every way Finder opens an archive of a type that
    /// opens with Zforge, not only a double click.
    static func footer(locale: Locale?) -> String {
        AppLocalization.string("When you double-click an archive whose type opens with Zforge, choose Zforge in Open With, or drop it on the Dock icon, Zforge asks, opens it, or extracts it into a folder named after it, next to it, showing only the progress. An archive whose type opens with another app always opens.", locale: locale)
    }
}
