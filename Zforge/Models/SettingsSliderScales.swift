import Foundation

/// Maps a Settings slider's track to its values. Positions run from 0 at the leading end
/// to 1 at the trailing end, and the tick marks are evenly spaced over that range.
nonisolated protocol SettingsSliderScale: Sendable {
    var range: ClosedRange<Int64> { get }
    var tickCount: Int { get }
    /// Unlabelled marks between the ticks, as track positions.
    var minorTickPositions: [Double] { get }
    func position(for value: Int64) -> Double
    func value(at position: Double) -> Int64
    /// The neighbouring step, used by the arrow keys and accessibility adjustments.
    func value(after value: Int64) -> Int64
    func value(before value: Int64) -> Int64
    /// The neighbouring round value, used by Option with the arrow keys.
    func roundValue(after value: Int64) -> Int64
    func roundValue(before value: Int64) -> Int64
    /// Round values hold the knob while it is dragged and give haptic feedback.
    func isRoundValue(_ value: Int64) -> Bool
}

/// Whole steps on a linear track; every step has a tick mark.
nonisolated struct LinearSettingsSliderScale: SettingsSliderScale {
    let range: ClosedRange<Int64>

    var tickCount: Int { Int(range.upperBound - range.lowerBound) + 1 }
    var minorTickPositions: [Double] { [] }

    func position(for value: Int64) -> Double {
        Double(clamped(value) - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }

    func value(at position: Double) -> Int64 {
        let span = Double(range.upperBound - range.lowerBound)
        return clamped(range.lowerBound + Int64((min(max(position, 0), 1) * span).rounded()))
    }

    func value(after value: Int64) -> Int64 { clamped(value + 1) }
    func value(before value: Int64) -> Int64 { clamped(value - 1) }
    func roundValue(after value: Int64) -> Int64 { self.value(after: value) }
    func roundValue(before value: Int64) -> Int64 { self.value(before: value) }
    func isRoundValue(_ value: Int64) -> Bool { false }

    private func clamped(_ value: Int64) -> Int64 {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

/// The root archive size limit track: 256 MB to 16 GB in decimal bytes.
///
/// Every doubling takes the same track length, with a tick mark at each one. Inside a
/// doubling the value moves in steps of 1/32 of its start (8 MB from 256 MB, 16 MB from
/// 512 MB, 1/32 GB from 1 GB and so on). The doublings below 1 GB read as 256 and
/// 512 MB, so the second one ends at 1 GB and its last step is shorter.
///
/// Each doubling and its midpoint (384 MB, 768 MB, 1.5 GB…) is a round value. A round
/// value holds the knob over `holdWidth` of extra track on each side, and the track
/// beyond the hold continues with the very next step, so no step is lost to the hold.
nonisolated struct ArchiveSizeLimitSliderScale: SettingsSliderScale {
    static let doublings: [Int64] = [
        256_000_000, 512_000_000, 1_000_000_000, 2_000_000_000,
        4_000_000_000, 8_000_000_000, 16_000_000_000,
    ]
    static let roundValues: [Int64] = doublings.dropLast().flatMap { [$0, $0 + $0 / 2] } + [doublings.last!]

    /// Half the hold of each round value, as a fraction of the track.
    let holdWidth: Double

    init(holdWidth: Double = 0.008) {
        self.holdWidth = holdWidth
    }

    var range: ClosedRange<Int64> { Self.doublings.first!...Self.doublings.last! }
    var tickCount: Int { Self.doublings.count }
    /// The midpoint round values (384 MB, 768 MB, 1.5 GB…).
    var minorTickPositions: [Double] {
        Self.roundValues.filter { !Self.doublings.contains($0) }.map(position(for:))
    }

    func position(for value: Int64) -> Double {
        let value = clamped(value)
        let index = Self.roundValues.lastIndex { $0 <= value } ?? 0
        let held = unitPosition(of: value) * valueTrackLength + 2 * holdWidth * Double(index)
        return Self.roundValues[index] == value ? held : held + holdWidth
    }

    func value(at position: Double) -> Int64 {
        let position = min(max(position, 0), 1)
        let rounds = Self.roundValues
        // The first hold ending at or after the position either contains it or follows
        // the stretch of steps that does, so every position resolves to a value.
        for index in rounds.indices {
            let center = holdCenter(index)
            guard position <= center + holdWidth else { continue }
            if index == 0 || position >= center - holdWidth { return rounds[index] }
            let previous = index - 1
            let unit = (position - 2 * holdWidth * Double(previous) - holdWidth) / valueTrackLength
            let stepped = steppedValue(nearest: value(atUnitPosition: unit))
            return min(max(stepped, rounds[previous]), rounds[index])
        }
        return range.upperBound
    }

    func value(after value: Int64) -> Int64 {
        let value = clamped(value)
        guard value < range.upperBound else { return value }
        let doubling = Self.doublings.lastIndex { $0 <= value }!
        let start = Self.doublings[doubling], step = start / 32
        return min(start + ((value - start) / step + 1) * step, Self.doublings[doubling + 1])
    }

    func value(before value: Int64) -> Int64 {
        let value = clamped(value)
        guard value > range.lowerBound else { return value }
        let doubling = Self.doublings.lastIndex { $0 < value }!
        let start = Self.doublings[doubling], step = start / 32
        let stepsAbove = (value - start + step - 1) / step
        return start + (stepsAbove - 1) * step
    }

    func roundValue(after value: Int64) -> Int64 {
        Self.roundValues.first { $0 > value } ?? range.upperBound
    }

    func roundValue(before value: Int64) -> Int64 {
        Self.roundValues.last { $0 < value } ?? range.lowerBound
    }

    func isRoundValue(_ value: Int64) -> Bool {
        Self.roundValues.contains(value)
    }

    /// The track left for values once every hold is taken out.
    private var valueTrackLength: Double {
        1 - 2 * holdWidth * Double(Self.roundValues.count - 1)
    }

    private func holdCenter(_ index: Int) -> Double {
        unitPosition(of: Self.roundValues[index]) * valueTrackLength + 2 * holdWidth * Double(index)
    }

    /// Position on a track without holds: equal length per doubling, logarithmic inside it.
    private func unitPosition(of value: Int64) -> Double {
        let doublings = Self.doublings
        let index = min(doublings.lastIndex { $0 <= value } ?? 0, doublings.count - 2)
        let fraction = log(Double(value) / Double(doublings[index]))
            / log(Double(doublings[index + 1]) / Double(doublings[index]))
        return (Double(index) + fraction) / Double(doublings.count - 1)
    }

    private func value(atUnitPosition unit: Double) -> Double {
        let doublings = Self.doublings
        let scaled = min(max(unit, 0), 1) * Double(doublings.count - 1)
        let index = min(Int(scaled), doublings.count - 2)
        let start = Double(doublings[index]), end = Double(doublings[index + 1])
        return start * pow(end / start, scaled - Double(index))
    }

    private func steppedValue(nearest value: Double) -> Int64 {
        let doublings = Self.doublings
        let index = min(doublings.lastIndex { Double($0) <= value } ?? 0, doublings.count - 2)
        let start = doublings[index], step = start / 32
        let steps = Int64(((value - Double(start)) / Double(step)).rounded())
        return min(start + steps * step, doublings[index + 1])
    }

    private func clamped(_ value: Int64) -> Int64 {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
