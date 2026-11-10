import XCTest

/// Drags that start a native dragging session the way a person performs them:
/// press until the item lifts, move onto the target, pause over it, then release.
///
/// Zforge starts the dragging session from the first `leftMouseDragged` past its
/// pickup distance (`ArchiveDragSourceView`), and under macOS 27.2 the session only
/// begins after that event has been handled. XCTest 27.2 posts the whole move and
/// the release of `click(forDuration:thenDragTo:)` within a few milliseconds (1.6 ms
/// and 10 ms measured), so the release reached the app before the session existed;
/// the session then waited for a release
/// that never came, the drop never happened and the app stayed disabled (D-92). A
/// person never releases that fast: the pause over the target lets the session start,
/// track the pointer onto the target (the target's `dropEntered`) and receive the
/// release, so the drop is performed by the same AppKit path as a manual drag.
enum DragGesture {
    /// How long the button is held before moving, so the item lifts as under a person's press.
    static let pressDuration: TimeInterval = 0.3
    /// How long the pointer rests over the target before the release. Measured on
    /// macOS 27.2 (D-92): the session began 88 ms after the pickup and reported the
    /// target row about 370 ms after it; a person's pause before letting go is longer.
    static let pauseOverTarget: TimeInterval = 1.0
}

extension XCUIElement {
    /// Presses this element, drags it onto `target`, pauses there and releases.
    func dragAndDrop(onto target: XCUIElement) {
        click(forDuration: DragGesture.pressDuration, thenDragTo: target,
              withVelocity: .default, thenHoldForDuration: DragGesture.pauseOverTarget)
    }
}

extension XCUICoordinate {
    /// Presses at this point, drags to `target`, pauses there and releases.
    func dragAndDrop(onto target: XCUICoordinate) {
        click(forDuration: DragGesture.pressDuration, thenDragTo: target,
              withVelocity: .default, thenHoldForDuration: DragGesture.pauseOverTarget)
    }
}
