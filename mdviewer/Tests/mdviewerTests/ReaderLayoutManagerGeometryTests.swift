//
//  ReaderLayoutManagerGeometryTests.swift
//  mdviewer
//
//  Tests for layout-manager decoration geometry calculations.
//

#if canImport(XCTest)
    internal import XCTest
    #if os(macOS)
        internal import AppKit
        @testable internal import mdviewer

        final class ReaderLayoutManagerGeometryTests: XCTestCase {
            func testBlockquoteDrawRectDoesNotSubtractCenteredOriginFromWidth() {
                let usedRect = CGRect(x: 0, y: 120, width: 420, height: 32)
                let origin = NSPoint(x: 260, y: 0)
                let rect = ReaderLayoutManager.blockquoteDrawRect(
                    usedRect: usedRect,
                    origin: origin,
                    containerWidth: 720,
                    depth: 1
                )

                XCTAssertEqual(rect.origin.x, 260, accuracy: 0.1)
                XCTAssertEqual(rect.width, 720, accuracy: 0.1)
                XCTAssertEqual(rect.origin.y, 116, accuracy: 0.1)
                XCTAssertEqual(rect.height, 40, accuracy: 0.1)
            }

            func testNestedBlockquoteDrawRectOnlyReducesWidthByNestingInset() {
                let usedRect = CGRect(x: 0, y: 80, width: 300, height: 24)
                let origin = NSPoint(x: 180, y: 0)
                let rect = ReaderLayoutManager.blockquoteDrawRect(
                    usedRect: usedRect,
                    origin: origin,
                    containerWidth: 640,
                    depth: 3
                )

                XCTAssertEqual(rect.origin.x, 212, accuracy: 0.1)
                XCTAssertEqual(rect.width, 608, accuracy: 0.1)
            }
        }
    #endif
#endif
