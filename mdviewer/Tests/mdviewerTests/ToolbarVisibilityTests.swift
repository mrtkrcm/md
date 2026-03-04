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

    func testAnimationDuration() {
        let controller = ToolbarVisibilityController(animationDuration: 0.3)

        XCTAssertEqual(controller.animationDuration, 0.3)
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

    func testDebouncing() {
        let controller = ToolbarVisibilityController(
            hideThreshold: 50,
            debounceInterval: 0.1
        )

        // At top
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        XCTAssertTrue(controller.isVisible)

        // Scroll down past threshold - should hide after debounce
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)

        // Wait for debounce
        let expectation = XCTestExpectation(description: "debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.2)

        // After debounce, scrolling again should apply
        controller.updateScroll(offset: 70, contentHeight: 1000, visibleHeight: 500)
        XCTAssertFalse(controller.isVisible)
    }
}
