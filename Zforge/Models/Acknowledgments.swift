import Foundation

/// A component whose license notices the app ships: Zforge itself, 7-Zip and the Swift
/// packages linked into the app. `Scripts/update-notices.py` writes the list
/// (`Acknowledgments.json`) and the license texts it names into the bundle's resources.
nonisolated struct AcknowledgedComponent: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let license: String
    let url: URL
    /// The upstream version; nil for Zforge, whose version is the app's.
    let version: String?
    /// The license texts, in reading order.
    let files: [LicenseFile]

    /// A shipped license text: its resource name in the bundle and the upstream file it copies
    /// (`7-Zip-LGPL.txt` from `DOC/copying.txt`), which titles it in the window.
    nonisolated struct LicenseFile: Decodable, Hashable, Sendable {
        let name: String
        let source: String
    }
}

nonisolated enum Acknowledgments {
    static let manifestName = "Acknowledgments"

    /// The components listed in `bundle`, in display order; empty when the list is missing or
    /// unreadable (the window then shows nothing rather than failing).
    static func components(in bundle: Bundle = .main) -> [AcknowledgedComponent] {
        guard let url = bundle.url(forResource: manifestName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return [] }
        return manifest.components
    }

    /// The text of one shipped license file, or nil when the bundle lacks it.
    static func text(ofFile file: String, in bundle: Bundle = .main) -> String? {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        guard let url = bundle.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    /// The version shown for a component: its upstream version, or the app's own for Zforge.
    static func displayVersion(of component: AcknowledgedComponent, in bundle: Bundle = .main) -> String? {
        component.version ?? bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    private struct Manifest: Decodable {
        let components: [AcknowledgedComponent]
    }
}
