import AppKit
import SwiftUI
import Testing
@testable import Zforge

/// The Archive Navigation sliders in Settings. The scales are checked as values; the
/// slider view is laid out offscreen and driven through its own action, key and
/// accessibility handlers. Real drag delivery is covered by `SettingsUITests`.
@Suite("Settings sliders")
@MainActor
struct SettingsSliderTests {
    private let scale = ArchiveSizeLimitSliderScale()
    private static let megabyte: Int64 = 1_000_000
    private static let gigabyte: Int64 = 1_000_000_000

    @Test("Root size limit steps by 1/32 of each doubling, in decimal bytes")
    func sizeLimitSteps() {
        let mb = Self.megabyte, gb = Self.gigabyte
        #expect(scale.range == ArchiveBrowsingPolicy.rootSizeLimitRange)
        #expect(scale.value(after: 256 * mb) == 264 * mb)
        #expect(scale.value(before: 256 * mb) == 256 * mb)
        #expect(scale.value(after: 384 * mb) == 392 * mb)
        #expect(scale.value(before: 384 * mb) == 376 * mb)
        #expect(scale.value(after: 512 * mb) == 528 * mb)
        #expect(scale.value(before: 512 * mb) == 504 * mb)
        // 512 MB–1 GB ends at 1 GB, so its last step is 8 MB.
        #expect(scale.value(after: 992 * mb) == gb)
        #expect(scale.value(before: gb) == 992 * mb)
        #expect(scale.value(after: gb) == 1_031_250_000)
        #expect(scale.value(before: 2 * gb) == 1_968_750_000)
        #expect(scale.value(after: 8 * gb) == 8_250_000_000)
        #expect(scale.value(before: 16 * gb) == 15_750_000_000)
        #expect(scale.value(after: 16 * gb) == 16 * gb)
        // A value between steps moves to the adjacent step on each side.
        #expect(scale.value(after: 400 * mb + 3) == 408 * mb)
        #expect(scale.value(before: 400 * mb + 3) == 400 * mb)
    }

    @Test("Round values are each doubling and its midpoint, reached with Option")
    func sizeLimitRoundValues() {
        let mb = Self.megabyte, gb = Self.gigabyte
        #expect(ArchiveSizeLimitSliderScale.roundValues == [
            256 * mb, 384 * mb, 512 * mb, 768 * mb, gb, 1_500 * mb, 2 * gb,
            3 * gb, 4 * gb, 6 * gb, 8 * gb, 12 * gb, 16 * gb,
        ])
        #expect(scale.roundValue(after: 392 * mb) == 512 * mb)
        #expect(scale.roundValue(before: 392 * mb) == 384 * mb)
        #expect(scale.roundValue(after: 384 * mb) == 512 * mb)
        #expect(scale.roundValue(before: 256 * mb) == 256 * mb)
        #expect(scale.roundValue(after: 16 * gb) == 16 * gb)
        #expect(scale.isRoundValue(768 * mb))
        #expect(!scale.isRoundValue(776 * mb))
    }

    @Test("Each doubling takes the same track length and sits on a tick mark")
    func sizeLimitTicks() {
        #expect(scale.tickCount == 7)
        for (index, doubling) in ArchiveSizeLimitSliderScale.doublings.enumerated() {
            #expect(abs(scale.position(for: doubling) - Double(index) / 6) < 1e-9, "\(doubling)")
        }
    }

    @Test("Dragging across the track reaches every step in order, round values included")
    func sizeLimitDragReachesEveryStep() {
        var steps = [scale.range.lowerBound]
        while steps.last! < scale.range.upperBound { steps.append(scale.value(after: steps.last!)) }
        // 32 steps per doubling, except 512 MB–1 GB with 31 (its last step is 8 MB), plus 256 MB.
        #expect(steps.count == 1 + 32 + 31 + 4 * 32)

        var dragged: [Int64] = []
        for sample in 0...40_000 {
            let value = scale.value(at: Double(sample) / 40_000)
            if dragged.last != value { dragged.append(value) }
        }
        #expect(dragged == steps)
        for step in steps {
            #expect(scale.value(at: scale.position(for: step)) == step, "\(step)")
        }
    }

    @Test("A round value holds the knob without hiding the steps beside it")
    func sizeLimitHolds() throws {
        let hold = scale.holdWidth
        for round in ArchiveSizeLimitSliderScale.roundValues {
            let center = scale.position(for: round)
            #expect(scale.value(at: center - hold * 0.95) == round, "\(round)")
            #expect(scale.value(at: center + hold * 0.95) == round, "\(round)")
        }
        // Leaving 384 MB's hold to the right, 392 MB comes next; to the left, 376 MB.
        let center = scale.position(for: 384 * Self.megabyte)
        let right = stride(from: center, through: center + 0.05, by: 0.0001).map(scale.value(at:))
        #expect(right.first { $0 != 384 * Self.megabyte } == 392 * Self.megabyte)
        let left = stride(from: center, through: center - 0.05, by: -0.0001).map(scale.value(at:))
        #expect(left.first { $0 != 384 * Self.megabyte } == 376 * Self.megabyte)
        // The hold is a stretch of track, not a single point.
        #expect(scale.position(for: 392 * Self.megabyte) - center > hold)
    }

    @Test("Nesting depth stops on each whole value")
    func nestingDepthScale() {
        let depth = LinearSettingsSliderScale(range: 1...10)
        #expect(depth.tickCount == 10)
        for value in Int64(1)...10 {
            #expect(depth.value(at: depth.position(for: value)) == value)
            #expect(abs(depth.position(for: value) - Double(value - 1) / 9) < 1e-9)
        }
        #expect(depth.value(at: 0.04) == 1)
        #expect(depth.value(at: 0.07) == 2)
        #expect(depth.value(after: 10) == 10)
        #expect(depth.value(before: 1) == 1)
        #expect(depth.roundValue(after: 4) == 5)
        #expect(!depth.isRoundValue(5))
    }

    @Test("Tick labels sit under their tick marks and stay inside the slider")
    func tickLabelLayout() throws {
        let view = makeSizeSlider(value: Self.gigabyte)
        #expect(view.labels.map(\.stringValue) == ["256 MB", "512 MB", "1 GB", "2 GB", "4 GB", "8 GB", "16 GB"])
        #expect(view.intrinsicContentSize.height > view.slider.frame.height)
        for label in view.labels {
            #expect(label.frame.minX >= 0 && label.frame.maxX <= view.bounds.width, "\(label.stringValue)")
            #expect(label.frame.minY >= view.slider.frame.maxY, "\(label.stringValue)")
        }
        // Labels never overlap at the Settings width.
        for (left, right) in zip(view.labels, view.labels.dropFirst()) {
            #expect(left.frame.maxX < right.frame.minX, "\(left.stringValue) / \(right.stringValue)")
        }
    }

    /// The marks are read from the rendered slider: AppKit's `rectOfTickMark(at:)` does not
    /// match where macOS 26 draws them, so it cannot serve as the reference.
    @Test("Labels are centred on the drawn tick marks, and the size slider marks its midpoints", arguments: [
        NSAppearance.Name.aqua, .darkAqua,
    ])
    func labelsFollowDrawnTickMarks(appearance: NSAppearance.Name) throws {
        let depth = ScaleSliderView(scale: LinearSettingsSliderScale(range: 1...10), value: 1)
        depth.tickLabels = (1...10).map { "\($0)" }
        let size = makeSizeSlider(value: 450 * Self.megabyte)
        for view in [depth, size] {
            view.frame = NSRect(x: 0, y: 0, width: 508, height: view.intrinsicContentSize.height)
            let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.contentView = view
            view.appearance = NSAppearance(named: appearance)
            view.layoutSubtreeIfNeeded()

            let knob = view.trackX(at: view.slider.doubleValue)
            let drawn = try drawnTickMarks(in: view).filter { abs($0 - knob) > 12 }
            let majors = (0..<view.scale.tickCount).map { view.trackX(at: Double($0) / Double(view.scale.tickCount - 1)) }
            let expected = (majors + view.scale.minorTickPositions.map(view.trackX(at:))).sorted().filter { abs($0 - knob) > 12 }
            #expect(drawn.count == expected.count, "Drawn \(drawn), expected \(expected)")
            for (mark, position) in zip(drawn, expected) {
                #expect(abs(mark - position) < 0.75, "Drawn \(drawn), expected \(expected)")
            }
            for (label, tick) in zip(view.labels, majors) where abs(tick - knob) > 12 {
                let clamped = label.frame.minX <= 0 || label.frame.maxX >= view.bounds.width
                guard !clamped else { continue }
                let mark = try #require(drawn.min { abs($0 - tick) < abs($1 - tick) })
                #expect(abs(label.frame.midX - mark) < 1, "\(label.stringValue): label \(label.frame.midX), mark \(mark)")
            }
        }
        #expect(size.scale.minorTickPositions.count == 6)
    }

    @Test("The slider's drag action lands on steps and holds on round values")
    func dragActionSnapsTheKnob() throws {
        var reported: [Int64] = []
        let view = makeSizeSlider(value: Self.gigabyte)
        view.onChange = { reported.append($0) }
        let hold = scale.position(for: 384 * Self.megabyte)

        moveKnob(view, to: hold + scale.holdWidth * 0.6)
        #expect(view.value == 384 * Self.megabyte)
        #expect(abs(view.slider.doubleValue - hold) < 1e-9, "The knob stays at the round value inside its hold")

        moveKnob(view, to: scale.position(for: 392 * Self.megabyte) + 0.0002)
        #expect(view.value == 392 * Self.megabyte)
        #expect(abs(view.slider.doubleValue - scale.position(for: 392 * Self.megabyte)) < 1e-9)

        moveKnob(view, to: scale.position(for: 392 * Self.megabyte))
        #expect(reported == [384 * Self.megabyte, 392 * Self.megabyte], "Unchanged values are not reported again")
    }

    /// The distances `SettingsUITests` drags at the real Settings width (510 pt). Measured on
    /// macOS 27 (2026-11-01), AppKit proposes the press position plus the pointer's travel over
    /// the knob's travel, also inside a hold, so the slider's action is driven the same way here.
    /// Each doubling is about 66 pt long in 32 logarithmic steps: the first step after 1 GB is
    /// about 2.9 pt, wider than the 2 pt average, so 8 pt still reads 1.03 GB (D-62).
    @Test("At the Settings width, drags from 1 GB hold, then continue step by step")
    func dragDistancesAtSettingsWidth() throws {
        let view = makeSizeSlider(value: Self.gigabyte)
        view.frame.size.width = 510
        view.layoutSubtreeIfNeeded()
        let travel = view.trackX(at: 1) - view.trackX(at: 0)
        let start = view.slider.doubleValue
        func value(afterDragging distance: CGFloat) -> Int64 {
            moveKnob(view, to: start + Double(distance / travel))
            defer { view.value = Self.gigabyte }
            return view.value
        }
        #expect(value(afterDragging: 2) == Self.gigabyte, "Inside the hold")
        #expect(value(afterDragging: 3.5) == Self.gigabyte, "Inside the hold")
        #expect(value(afterDragging: 6.5) == 1_031_250_000)
        #expect(value(afterDragging: 8) == 1_031_250_000, "The 8 pt the UI test first assumed reads 1.03 GB")
        #expect(value(afterDragging: 10) == 1_062_500_000)
        #expect(value(afterDragging: -2) == Self.gigabyte, "Inside the hold")
        // Every half point of a slow 12 pt drag lands on the hold or the step that follows the previous one.
        var steps: [Int64] = []
        for half in 0...24 {
            let current = value(afterDragging: CGFloat(half) / 2)
            if steps.last != current { steps.append(current) }
        }
        #expect(steps == [Self.gigabyte, 1_031_250_000, 1_062_500_000, 1_093_750_000])
    }

    @Test("Arrow keys move one step, Option moves to the next round value")
    func keyboardSteps() throws {
        var reported: [Int64] = []
        let view = makeSizeSlider(value: 384 * Self.megabyte)
        view.onChange = { reported.append($0) }

        try press(NSRightArrowFunctionKey, keyCode: 124, on: view.slider)
        #expect(view.value == 392 * Self.megabyte)
        try press(NSLeftArrowFunctionKey, keyCode: 123, on: view.slider)
        try press(NSLeftArrowFunctionKey, keyCode: 123, on: view.slider)
        #expect(view.value == 376 * Self.megabyte)
        try press(NSRightArrowFunctionKey, keyCode: 124, option: true, on: view.slider)
        #expect(view.value == 384 * Self.megabyte)
        try press(NSRightArrowFunctionKey, keyCode: 124, option: true, on: view.slider)
        #expect(view.value == 512 * Self.megabyte)
        try press(NSUpArrowFunctionKey, keyCode: 126, on: view.slider)
        #expect(view.value == 528 * Self.megabyte)
        try press(NSEndFunctionKey, keyCode: 119, on: view.slider)
        #expect(view.value == 16 * Self.gigabyte)
        try press(NSRightArrowFunctionKey, keyCode: 124, on: view.slider)
        #expect(reported.last == 16 * Self.gigabyte)
        #expect(reported.count == 7, "A key at the end of the range reports nothing")
        #expect(abs(view.slider.doubleValue - 1) < 1e-9)
    }

    @Test("Accessibility reads the formatted size and adjusts by one step")
    func accessibility() {
        let view = makeSizeSlider(value: 384 * Self.megabyte)
        #expect(view.slider.accessibilityValue() as? String == "384 MB")
        #expect(view.slider.accessibilityPerformIncrement())
        #expect(view.value == 392 * Self.megabyte)
        #expect(view.slider.accessibilityValue() as? String == "392 MB")
        #expect(view.slider.accessibilityPerformDecrement())
        #expect(view.slider.accessibilityPerformDecrement())
        #expect(view.value == 376 * Self.megabyte)
        #expect(view.slider.accessibilityValue() as? String == "376 MB")
    }

    @Test("Settings shows both limits as sliders bound to the preferences", arguments: [
        ("light", NSAppearance.Name.aqua, AppLanguagePreference.english),
        ("dark", NSAppearance.Name.darkAqua, AppLanguagePreference.english),
        ("dark-pt-BR", NSAppearance.Name.darkAqua, AppLanguagePreference.portugueseBrazil),
    ])
    func settingsSection(name: String, appearance: NSAppearance.Name, language: AppLanguagePreference) async throws {
        let suite = "ZforgeTestSuite.SettingsSliderTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removeTestSuite(named: suite) }
        let preferences = FileBrowserPreferences(defaults: defaults)
        preferences.language = language
        preferences.archiveRootSizeLimit = 1_531_250_000

        let settingsBody = String(reflecting: ZforgeSettingsView.Body.self)
        #expect(settingsBody.contains("ArchiveNavigationSettingsSection"), "\(settingsBody)")

        let section = Form { ArchiveNavigationSettingsSection(preferences: preferences) }
            .formStyle(.grouped)
            .environment(\.locale, language.locale)
        let size = CGSize(width: 568, height: 300)
        let host = NSHostingView(rootView: section.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = host
        host.layoutSubtreeIfNeeded()

        let sliders = host.descendants(of: ScaleSliderView.self)
        #expect(sliders.count == 2)
        let depth = try #require(sliders.first { $0.slider.accessibilityIdentifier() == "settings-archive-nesting-depth" })
        let rootSize = try #require(sliders.first { $0.slider.accessibilityIdentifier() == "settings-archive-root-size-limit" })
        #expect(depth.value == 5)
        #expect(depth.labels.count == 10)
        #expect(rootSize.value == 1_531_250_000)
        #expect(rootSize.slider.frame.width > 400, "The size slider spans the row so its steps stay wide enough to drag")
        ZforgeSnapshot.assert(host, appearance: appearance, named: "archive-navigation-\(name)")

        // Moving the slider writes the preference, and the preference moves the slider.
        rootSize.step(forward: true, toRoundValue: false)
        #expect(preferences.archiveRootSizeLimit == 1_562_500_000)
        depth.step(forward: true, toRoundValue: false)
        #expect(preferences.archiveNestingLimit == 6)
        preferences.archiveRootSizeLimit = 768_000_000
        try await waitUntil { rootSize.value == 768_000_000 }
        #expect(abs(rootSize.slider.doubleValue - ArchiveSizeLimitSliderScale().position(for: 768_000_000)) < 1e-9)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() { try await Task.sleep(for: .milliseconds(5)) }
        #expect(condition())
    }

    private func drawnTickMarks(in view: ScaleSliderView) throws -> [CGFloat] {
        let rep = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        let scale = CGFloat(rep.pixelsWide) / view.bounds.width
        // The marks are 2 pt dots at the bottom of the slider, below its track.
        let row = Int(((view.slider.frame.maxY - 1) * scale).rounded(.down))
        var centers: [CGFloat] = []
        var runStart: Int?
        for x in 0...rep.pixelsWide {
            let opaque = x < rep.pixelsWide && (rep.colorAt(x: x, y: row)?.alphaComponent ?? 0) > 0.1
            if opaque, runStart == nil { runStart = x }
            if !opaque, let start = runStart {
                centers.append(CGFloat(start + x) / 2 / scale)
                runStart = nil
            }
        }
        return centers
    }

    private func makeSizeSlider(value: Int64) -> ScaleSliderView {
        let view = ScaleSliderView(scale: scale, value: value)
        let locale = Locale(identifier: "en_US")
        view.tickLabels = ArchiveSizeLimitSliderScale.doublings.map { AppLocalization.byteCount($0, locale: locale) }
        view.describe = { AppLocalization.byteCount($0, locale: locale) }
        view.frame = NSRect(x: 0, y: 0, width: 520, height: view.intrinsicContentSize.height)
        view.layoutSubtreeIfNeeded()
        return view
    }

    private func moveKnob(_ view: ScaleSliderView, to position: Double) {
        view.slider.doubleValue = position
        view.slider.sendAction(view.slider.action, to: view.slider.target)
    }

    private func press(_ key: Int, keyCode: UInt16, option: Bool = false, on slider: NSSlider) throws {
        let characters = String(Character(try #require(UnicodeScalar(key))))
        let event = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: option ? [.option, .function] : [.function],
            timestamp: 0, windowNumber: 0, context: nil, characters: characters,
            charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode
        ))
        slider.keyDown(with: event)
    }
}

private extension NSView {
    func descendants<T: NSView>(of type: T.Type) -> [T] {
        subviews.flatMap { subview in [subview as? T].compactMap { $0 } + subview.descendants(of: type) }
    }
}
