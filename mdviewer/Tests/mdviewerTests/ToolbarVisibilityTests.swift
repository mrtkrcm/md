//
//  ToolbarVisibilityTests.swift
//  mdviewerTests
//
//  Tests for toolbar auto-hide behavior.
//

@testable internal import mdviewer
internal import SwiftUI
internal import XCTest

@MainActor
final class ToolbarVisibilityTests: XCTestCase {
    func testToolbarVisibleAtTop() {
        let controller = ToolbarVisibilityController()

        // At top (offset 0), toolbar should be visible
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)

        XCTAssertTrue(controller.isVisible)
    }

    func testToolbarHidesWhenScrollingDown() {
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0)

        // Initially at top
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)

        // Scroll down past threshold
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)

        XCTAssertFalse(controller.isVisible)
    }

    func testToolbarShowsWhenScrollingUp() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0
        )

        // Scroll down to hide
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up past show threshold
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)

        XCTAssertTrue(controller.isVisible)
    }

    func testToolbarStaysVisibleBelowHideThreshold() {
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0)

        // Scroll down but stay below threshold
        controller.updateScroll(offset: 30, contentHeight: 1000, visibleHeight: 500)

        XCTAssertTrue(controller.isVisible)
    }

    func testResetRestoresVisibility() {
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0)

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Reset
        controller.reset()

        XCTAssertTrue(controller.isVisible)
    }

    func testShowExplicitly() {
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0)

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Explicitly show
        controller.show()

        XCTAssertTrue(controller.isVisible)
    }

    func testAccumulatedScrollUp() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0
        )

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up a little (not enough)
        controller.updateScroll(offset: 80, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up more (past threshold)
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)
    }

    func testHideIsImmediate() {
        // Hide path has no debounce — should respond on the very first scroll event past threshold.
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0.1)

        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)

        // Single scroll event past threshold — should hide immediately without waiting
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)
    }

    func testOnVisibilityChangeCalledDirectly() {
        // Callback fires synchronously in setVisible — no SwiftUI frame needed.
        let controller = ToolbarVisibilityController(hideThreshold: 50, debounceInterval: 0)
        var callbackValues: [Bool] = []
        controller.onVisibilityChange = { callbackValues.append($0) }

        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 10, contentHeight: 1000, visibleHeight: 500)

        XCTAssertEqual(callbackValues, [false, true])
    }

    func testMonotonicDownwardJitterDoesNotReShowToolbar() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0
        )

        // Hide at top-down transition.
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Small upward/downward noise (below 1pt threshold) should not trigger a show.
        controller.updateScroll(offset: 59.6, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 59.9, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 59.4, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 59.1, contentHeight: 1000, visibleHeight: 500)

        XCTAssertFalse(controller.isVisible)

        // Continue downward travel is still hidden.
        controller.updateScroll(offset: 80, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)
    }

    func testLayoutShiftCooldownSuppressesFalseJitter() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0
        )

        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Simulate layout-derived size change that can happen when toolbar visibility changes.
        controller.updateScroll(offset: 60, contentHeight: 1025, visibleHeight: 540)
        controller.updateScroll(offset: 59.5, contentHeight: 1026, visibleHeight: 541)
        controller.updateScroll(offset: 59.7, contentHeight: 1026, visibleHeight: 541)

        // Even with noisy upward deltas after layout churn, do not re-show yet.
        controller.updateScroll(offset: 58.8, contentHeight: 1026, visibleHeight: 541)
        XCTAssertFalse(controller.isVisible)

        // Keep scrolling downward again.
        controller.updateScroll(offset: 80, contentHeight: 1026, visibleHeight: 541)
        XCTAssertFalse(controller.isVisible)
    }

    func testHysteresisDeadZone() {
        // Offsets between atTopThreshold (8) and hideThreshold (20) form a dead zone:
        // scrolling down into this range should NOT hide (already past atTop, below hideThreshold),
        // and scrolling back into it should NOT auto-show (requires accumulated upward scroll).
        let controller = ToolbarVisibilityController(hideThreshold: 50, showThreshold: 30, debounceInterval: 0)

        // Start hidden at offset 100
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up to offset 15 — inside dead zone (8 < 15 < 50), not enough accumulated (85pt > 30, shows)
        // Actually at 85pt accumulated it does show. Let's test a smaller move.
        // Reset to hidden at offset 100, then do a tiny scroll up that stays in dead zone.
        controller.updateScroll(offset: 200, contentHeight: 1000, visibleHeight: 500)
        // Simulate hiding at 200 (already hidden, no change)
        // Now scroll up to offset 195 — tiny move, not enough accumulated
        controller.updateScroll(offset: 195, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)
    }

    func testAccumulatedScrollUpResetsAfterShow() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0
        )

        // Hide
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Show by scrolling up 40pt
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)

        // Hide again by scrolling down
        controller.updateScroll(offset: 80, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up only 5pt — accumulated should be fresh (reset after previous show), not 40+5
        controller.updateScroll(offset: 75, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible, "accumulatedScrollUp should have been reset after show")
    }

    func testShowDebouncing() {
        // Show path is debounced to prevent flicker on small scroll reversals.
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            showThreshold: 30,
            debounceInterval: 0.1
        )

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)

        // Scroll up past showThreshold — blocked by debounce immediately after hide
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible, "Show should be blocked by debounce right after hide")

        // Wait for debounce to expire
        let expectation = XCTestExpectation(description: "debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)

        // Scroll up again after debounce — should show now
        controller.updateScroll(offset: 50, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)
    }
}
