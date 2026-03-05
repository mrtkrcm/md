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

        // At top (offset 0), toolbar should be fully visible
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)

        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testToolbarShrinksWhenScrollingDown() {
        let controller = ToolbarVisibilityController()

        // Initially at top - fully visible
        controller.updateScroll(offset: 0, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 1.0)

        // Scroll to hide threshold - still fully visible
        controller.updateScroll(offset: 30, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 1.0)

        // Scroll into shrink range - should start shrinking
        controller.updateScroll(offset: 45, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.75) // (90-45)/60 = 45/60 = 0.75

        // Scroll to end of shrink range - fully hidden
        controller.updateScroll(offset: 90, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)
    }

    func testToolbarShowsWhenScrollingUp() {
        let controller = ToolbarVisibilityController()

        // Start fully hidden
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)

        // Scroll back into shrink range
        controller.updateScroll(offset: 75, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.25) // (90-75)/60 = 15/60 = 0.25

        // Scroll to hide threshold
        controller.updateScroll(offset: 30, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testToolbarStaysVisibleBelowHideThreshold() {
        let controller = ToolbarVisibilityController()

        // Scroll down but stay below threshold
        controller.updateScroll(offset: 25, contentHeight: 1000, visibleHeight: 500)

        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testResetRestoresVisibility() {
        let controller = ToolbarVisibilityController()

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)

        // Reset
        controller.reset()

        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testShowExplicitly() {
        let controller = ToolbarVisibilityController()

        // Hide toolbar
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)

        // Explicitly show
        controller.show()

        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testProgressiveShrinking() {
        let controller = ToolbarVisibilityController()

        // Test various points in the shrink range
        controller.updateScroll(offset: 30, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 1.0)

        controller.updateScroll(offset: 45, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.75)

        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.5)

        controller.updateScroll(offset: 75, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.25)

        controller.updateScroll(offset: 90, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)
    }

    func testImmediateShowAtTop() {
        let controller = ToolbarVisibilityController()

        // Start hidden
        controller.updateScroll(offset: 100, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.0)

        // Scroll to top - should immediately show
        controller.updateScroll(offset: 5, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 1.0)
    }

    func testOnVisibilityProgressChangeCalled() {
        let controller = ToolbarVisibilityController()
        var progressValues: [CGFloat] = []
        controller.onVisibilityProgressChange = { progressValues.append($0) }

        controller.updateScroll(offset: 45, contentHeight: 1000, visibleHeight: 500)
        controller.updateScroll(offset: 30, contentHeight: 1000, visibleHeight: 500)

        XCTAssertEqual(progressValues, [0.75, 1.0])
    }

    func testNoMicroUpdates() {
        let controller = ToolbarVisibilityController()

        // Start at a position that gives 0.5 progress
        controller.updateScroll(offset: 60, contentHeight: 1000, visibleHeight: 500)
        XCTAssertEqual(controller.visibilityProgress, 0.5)

        var callbackCount = 0
        controller.onVisibilityProgressChange = { _ in callbackCount += 1 }

        // Small movement that shouldn't trigger update (less than 0.01 difference)
        controller.updateScroll(offset: 60.005, contentHeight: 1000, visibleHeight: 500)

        XCTAssertEqual(callbackCount, 0)
    }
}
