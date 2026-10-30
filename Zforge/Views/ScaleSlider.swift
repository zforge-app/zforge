import AppKit
import SwiftUI

/// A native slider whose values follow a `SettingsSliderScale`, with a label under each
/// tick mark. Dragging lands on the scale's steps and holds at its round values; the arrow
/// keys move one step and Option with an arrow moves to the next round value.
struct ScaleSlider: NSViewRepresentable {
    let scale: any SettingsSliderScale
    @Binding var value: Int64
    let tickLabels: [String]
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let describe: (Int64) -> String

    func makeNSView(context: Context) -> ScaleSliderView {
        ScaleSliderView(scale: scale, value: value)
    }

    func updateNSView(_ view: ScaleSliderView, context: Context) {
        view.scale = scale
        view.tickLabels = tickLabels
        view.describe = describe
        view.onChange = { value = $0 }
        view.slider.setAccessibilityLabel(accessibilityLabel)
        view.slider.setAccessibilityIdentifier(accessibilityIdentifier)
        if view.value != value { view.value = value }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ScaleSliderView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 240, height: nsView.intrinsicContentSize.height)
    }
}

final class ScaleSliderView: NSView {
    let slider = ScaleSliderControl()
    var scale: any SettingsSliderScale {
        didSet {
            slider.numberOfTickMarks = scale.tickCount
            slider.doubleValue = scale.position(for: value)
            needsLayout = true
        }
    }
    var value: Int64 {
        didSet { slider.doubleValue = scale.position(for: value) }
    }
    var tickLabels: [String] = [] {
        didSet {
            guard tickLabels != oldValue else { return }
            labels.forEach { $0.removeFromSuperview() }
            labels = tickLabels.map(Self.makeLabel)
            labels.forEach(addSubview)
            invalidateIntrinsicContentSize()
            needsLayout = true
        }
    }
    var describe: (Int64) -> String = { "\($0)" }
    var onChange: ((Int64) -> Void)?
    private(set) var labels: [NSTextField] = []
    private let minorTicks = MinorTickMarksView()

    private static let labelSpacing: CGFloat = 1

    init(scale: any SettingsSliderScale, value: Int64) {
        self.scale = scale
        self.value = value
        super.init(frame: .zero)
        slider.owner = self
        slider.minValue = 0
        slider.maxValue = 1
        slider.isContinuous = true
        slider.numberOfTickMarks = scale.tickCount
        slider.tickMarkPosition = .below
        slider.allowsTickMarkValuesOnly = false
        slider.doubleValue = scale.position(for: value)
        slider.target = self
        slider.action = #selector(sliderMoved)
        addSubview(minorTicks)
        // Behind the slider, so the knob covers them as it covers the native tick marks.
        addSubview(slider, positioned: .above, relativeTo: minorTicks)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        let labelHeight = labels.map(\.intrinsicContentSize.height).max() ?? 0
        return NSSize(width: NSView.noIntrinsicMetric,
                      height: slider.intrinsicContentSize.height + Self.labelSpacing + labelHeight)
    }

    override func layout() {
        super.layout()
        slider.frame = NSRect(x: 0, y: 0, width: bounds.width, height: slider.intrinsicContentSize.height)
        minorTicks.frame = slider.frame
        minorTicks.centers = scale.minorTickPositions.map { trackX(at: $0) - slider.frame.minX }
        // Each label is centred under its tick mark, kept inside the view at both ends.
        let lastTick = max(slider.numberOfTickMarks - 1, 1)
        for (index, label) in labels.enumerated() where index < slider.numberOfTickMarks {
            // Text fields clip their last glyph at their exact intrinsic width.
            let size = NSSize(width: ceil(label.intrinsicContentSize.width) + 2, height: ceil(label.intrinsicContentSize.height))
            let tick = trackX(at: Double(index) / Double(lastTick))
            let x = min(max(tick - size.width / 2, 0), bounds.width - size.width)
            label.frame = NSRect(x: x, y: slider.frame.maxY + Self.labelSpacing, width: size.width, height: size.height)
        }
    }

    /// Where the slider draws the knob centre and tick mark for a track position. On
    /// macOS 26 they are inset by half the knob from each end, while `rectOfTickMark(at:)`
    /// reports marks at the very ends of the slider.
    func trackX(at position: Double) -> CGFloat {
        let knobWidth = (slider.cell as? NSSliderCell)?.knobRect(flipped: slider.isFlipped).width ?? 20
        let inset = knobWidth / 2
        return slider.frame.minX + inset + (slider.frame.width - 2 * inset) * position
    }

    /// Dragging: the knob shows the value the scale resolves, so it holds on round values.
    @objc private func sliderMoved() {
        let newValue = scale.value(at: slider.doubleValue)
        slider.doubleValue = scale.position(for: newValue)
        guard newValue != value else { return }
        commit(newValue)
        if scale.isRoundValue(newValue) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    func step(forward: Bool, toRoundValue: Bool) {
        let newValue = switch (forward, toRoundValue) {
        case (true, false): scale.value(after: value)
        case (false, false): scale.value(before: value)
        case (true, true): scale.roundValue(after: value)
        case (false, true): scale.roundValue(before: value)
        }
        if newValue != value { commit(newValue) }
    }

    func moveToEnd(_ forward: Bool) {
        let newValue = forward ? scale.range.upperBound : scale.range.lowerBound
        if newValue != value { commit(newValue) }
    }

    private func commit(_ newValue: Int64) {
        value = newValue
        onChange?(newValue)
        NSAccessibility.post(element: slider, notification: .valueChanged)
    }

    private static func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize(for: .mini), weight: .regular)
        label.textColor = .secondaryLabelColor
        label.setAccessibilityElement(false)
        return label
    }
}

/// Unlabelled marks drawn like the slider's own tick marks: 2 pt dots at the bottom of
/// the slider, in the tertiary label colour.
final class MinorTickMarksView: NSView {
    var centers: [CGFloat] = [] {
        didSet { if centers != oldValue { needsDisplay = true } }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.tertiaryLabelColor.setFill()
        for x in centers {
            NSBezierPath(ovalIn: NSRect(x: x - 1, y: bounds.height - 2, width: 2, height: 2)).fill()
        }
    }
}

/// Routes the keyboard and accessibility adjustments through the scale instead of the
/// slider's evenly divided track.
final class ScaleSliderControl: NSSlider {
    weak var owner: ScaleSliderView?

    override func keyDown(with event: NSEvent) {
        guard let owner else { return super.keyDown(with: event) }
        let toRoundValue = event.modifierFlags.contains(.option)
        switch event.specialKey {
        case .rightArrow?, .upArrow?: owner.step(forward: true, toRoundValue: toRoundValue)
        case .leftArrow?, .downArrow?: owner.step(forward: false, toRoundValue: toRoundValue)
        case .home?: owner.moveToEnd(false)
        case .end?: owner.moveToEnd(true)
        default: super.keyDown(with: event)
        }
    }

    override func accessibilityValue() -> Any? {
        guard let owner else { return super.accessibilityValue() }
        return owner.describe(owner.value)
    }

    override func accessibilityPerformIncrement() -> Bool {
        owner?.step(forward: true, toRoundValue: false)
        return owner != nil
    }

    override func accessibilityPerformDecrement() -> Bool {
        owner?.step(forward: false, toRoundValue: false)
        return owner != nil
    }
}
