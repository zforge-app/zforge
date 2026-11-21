import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Zforge

/// The report of a batch Validate (OR-26, D-116): which archives are invalid and why, and
/// whether the others are valid or were not tested.
@Suite("Archive validation report")
@MainActor
struct ArchiveValidationReportTests {
    private static let english = Locale(identifier: "en")

    static func report(failures: Int, of archiveCount: Int, tested: Int? = nil) -> ArchiveValidationReport {
        let reasons = ["CRC failed", "Data error", "Unexpected end of archive", "Headers error"]
        let names = ["Photos 2024.zip", "Backup.7z", "Project Archive (old copy).tar.gz", "Notes.rar"]
        return ArchiveValidationReport(
            failures: (0..<failures).map { index in
                ArchiveValidationReport.Failure(
                    url: URL(fileURLWithPath: "/Users/Shared/Archives").appendingPathComponent(names[index % names.count]),
                    reason: reasons[index % reasons.count])
            },
            archiveCount: archiveCount, testedCount: tested ?? archiveCount)
    }

    @Test("The title counts the invalid archives, singular and plural")
    func titleCountsFailures() {
        #expect(Self.report(failures: 1, of: 3).title(locale: Self.english) == "1 Invalid Archive")
        #expect(Self.report(failures: 2, of: 3).title(locale: Self.english) == "2 Invalid Archives")
    }

    @Test("The summary says whether the archives not listed are valid or were not tested")
    func summaryDescribesTheRest() {
        #expect(Self.report(failures: 1, of: 3).summary(locale: Self.english) == "Every other archive is valid.")
        #expect(Self.report(failures: 2, of: 2).summary(locale: Self.english) == nil)
        #expect(Self.report(failures: 1, of: 3, tested: 2).summary(locale: Self.english)
            == "Validation was stopped before every archive was tested.")
        #expect(Self.report(failures: 1, of: 3, tested: 1).wasStopped)
    }

    @Test("Every text is translated, with the count in the title", arguments: AppLanguagePreference.supportedLanguages.filter { $0 != .english })
    func textsAreTranslated(language: AppLanguagePreference) {
        let locale = language.locale
        let one = Self.report(failures: 1, of: 3).title(locale: locale)
        let few = Self.report(failures: 3, of: 4).title(locale: locale)
        let many = Self.report(failures: 4, of: 4).title(locale: locale)
        #expect(one != "1 Invalid Archive" && few != "3 Invalid Archives", "\(language): \(one) / \(few)")
        #expect(one.contains("1") && few.contains("3"), "\(language): \(one) / \(few)")
        #expect(!many.isEmpty && many.contains("4"), "\(language): \(many)")
        let valid = Self.report(failures: 1, of: 3).summary(locale: locale)
        let stopped = Self.report(failures: 1, of: 3, tested: 2).summary(locale: locale)
        #expect(valid != "Every other archive is valid." && valid != nil, "\(language): \(String(describing: valid))")
        #expect(stopped != "Validation was stopped before every archive was tested." && stopped != nil && stopped != valid,
                "\(language): \(String(describing: stopped))")
    }

    @Test("Plural forms follow each language's rules", arguments: [
        (AppLanguagePreference.portugueseBrazil, 1, "1 arquivo compactado inválido"), (.portugueseBrazil, 2, "2 arquivos compactados inválidos"),
        (.russian, 1, "1 недействительный архив"), (.russian, 3, "3 недействительных архива"), (.russian, 5, "5 недействительных архивов"),
        (.polish, 1, "1 nieprawidłowe archiwum"), (.polish, 3, "3 nieprawidłowe archiwa"), (.polish, 5, "5 nieprawidłowych archiwów"),
    ])
    func pluralForms(language: AppLanguagePreference, count: Int, expected: String) {
        #expect(Self.report(failures: count, of: count + 1).title(locale: language.locale) == expected)
    }

    private static func sheet(_ report: ArchiveValidationReport, language: AppLanguagePreference) -> NSHostingView<some View> {
        let view = ArchiveValidationReportSheet(report: report, locale: language.locale, dismiss: {})
            .environment(\.locale, language.locale)
            .background(Color(nsColor: .windowBackgroundColor))
        let host = NSHostingView(rootView: view)
        host.frame.size = host.fittingSize
        host.layoutSubtreeIfNeeded()
        return host
    }

    @Test("The sheet fits a short list and scrolls a long one within a bounded height")
    func sheetHeightIsBounded() {
        let short = Self.sheet(Self.report(failures: 2, of: 3), language: .english).fittingSize
        let long = Self.sheet(Self.report(failures: 40, of: 40), language: .english).fittingSize
        #expect(short.width == ArchiveValidationReportSheet.width && long.width == ArchiveValidationReportSheet.width)
        #expect(short.height < long.height, "Two rows need less room than the scrolling list: \(short) / \(long)")
        #expect(long.height < ArchiveValidationReportSheet.listMaximumHeight + 200,
                "Forty rows scroll instead of growing the sheet: \(long)")
    }

    @Test("Snapshot: the report sheet", arguments: [
        ("two-light", NSAppearance.Name.aqua, AppLanguagePreference.english, 2, 3, 3),
        ("two-dark", .darkAqua, .english, 2, 3, 3),
        ("stopped-pt-BR", .aqua, .portugueseBrazil, 1, 4, 2),
        ("long-de", .darkAqua, .german, 9, 9, 9),
    ])
    func sheetSnapshot(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference,
                       failures: Int, archives: Int, tested: Int) {
        let report = Self.report(failures: failures, of: archives, tested: tested)
        ZforgeSnapshot.assert(Self.sheet(report, language: language), appearance: appearance, named: "sheet-\(name)")
    }
}
