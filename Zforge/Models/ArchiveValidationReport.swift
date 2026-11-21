import Foundation

/// The result of Validate with several archives selected (OR-26, D-116): every archive is
/// tested, and the ones that failed are listed by name with the reason, so the user knows
/// which files are damaged. Shown only when at least one archive failed.
nonisolated struct ArchiveValidationReport: Identifiable, Equatable, Sendable {
    struct Failure: Identifiable, Equatable, Sendable {
        let url: URL
        let reason: String

        var id: URL { url }
        var name: String { url.lastPathComponent }
    }

    let id = UUID()
    /// The archives that failed, in the order they were tested.
    let failures: [Failure]
    /// The archives selected (one per split set).
    let archiveCount: Int
    /// The archives whose test finished, valid or not; fewer than `archiveCount` when the
    /// user stopped the validation (Cancel in the progress overlay or in the password sheet).
    let testedCount: Int

    var wasStopped: Bool { testedCount < archiveCount }

    func title(locale: Locale?) -> String {
        AppLocalization.string("\(failures.count) Invalid Archives", locale: locale)
    }

    /// What the list does not say: whether the archives not listed are valid or were not
    /// tested. Nil when every archive was tested and none is valid.
    func summary(locale: Locale?) -> String? {
        if wasStopped {
            return AppLocalization.string("Validation was stopped before every archive was tested.", locale: locale)
        }
        guard failures.count < archiveCount else { return nil }
        return AppLocalization.string("Every other archive is valid.", locale: locale)
    }
}
