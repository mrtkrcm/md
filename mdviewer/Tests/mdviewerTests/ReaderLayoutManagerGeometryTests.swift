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

            func testTableRowDrawRectUsesNaturalColumnWidthInsteadOfFullContainerWidth() {
                let style = NSMutableParagraphStyle()
                style.headIndent = TableLayoutMetrics.contentInset
                style.firstLineHeadIndent = TableLayoutMetrics.contentInset
                style.paragraphSpacingBefore = 4
                style.paragraphSpacing = 8
                style.tabStops = TableLayoutMetrics.tabStops(readableWidth: 720, columnCount: 3)
                let naturalWidth = TableLayoutMetrics.naturalTableWidth(
                    leadingInset: TableLayoutMetrics.contentInset,
                    dividerLocations: TableLayoutMetrics.tabStopLocations(paragraphStyle: style, columnCount: 3),
                    columnCount: 3
                )

                let rect = ReaderLayoutManager.tableRowDrawRect(
                    usedRect: CGRect(x: 0, y: 100, width: 320, height: 24),
                    origin: NSPoint(x: 180, y: 0),
                    containerWidth: 720,
                    naturalTableWidth: naturalWidth,
                    rowInsets: TableLayoutMetrics.rowInsets(paragraphStyle: style, isTerminalRow: false)
                )

                XCTAssertEqual(rect.origin.x, 180, accuracy: 0.1)
                XCTAssertLessThan(rect.width, 720, "Table frame should hug the configured column layout")
                XCTAssertEqual(
                    rect.width,
                    TableLayoutMetrics.tableWidth(
                        paragraphStyle: style,
                        columnCount: 3,
                        containerWidth: 720
                    ),
                    accuracy: 0.1
                )
                XCTAssertEqual(rect.origin.y, 92, accuracy: 0.1)
                XCTAssertEqual(rect.height, 40, accuracy: 0.1)
            }

            func testTableRowDrawRectIgnoresOverwideUsedRectFromLongCellContent() {
                let style = NSMutableParagraphStyle()
                style.headIndent = TableLayoutMetrics.contentInset
                style.firstLineHeadIndent = TableLayoutMetrics.contentInset
                style.paragraphSpacingBefore = 4
                style.paragraphSpacing = 8
                style.tabStops = TableLayoutMetrics.tabStops(readableWidth: 720, columnCount: 2)
                let naturalWidth = TableLayoutMetrics.naturalTableWidth(
                    leadingInset: TableLayoutMetrics.contentInset,
                    dividerLocations: TableLayoutMetrics.tabStopLocations(paragraphStyle: style, columnCount: 2),
                    columnCount: 2
                )

                let rect = ReaderLayoutManager.tableRowDrawRect(
                    usedRect: CGRect(x: 0, y: 100, width: 980, height: 24),
                    origin: NSPoint(x: 180, y: 0),
                    containerWidth: 720,
                    naturalTableWidth: naturalWidth,
                    rowInsets: TableLayoutMetrics.rowInsets(paragraphStyle: style, isTerminalRow: false)
                )

                XCTAssertEqual(
                    rect.width,
                    TableLayoutMetrics.tableWidth(
                        paragraphStyle: style,
                        columnCount: 2,
                        containerWidth: 720
                    ),
                    accuracy: 0.1
                )
                XCTAssertLessThan(rect.width, 720, "Long cell content must not widen table backgrounds")
            }

            func testTerminalTableRowKeepsCompactBottomPadding() {
                let style = NSMutableParagraphStyle()
                style.headIndent = TableLayoutMetrics.contentInset
                style.firstLineHeadIndent = TableLayoutMetrics.contentInset
                style.paragraphSpacingBefore = 5
                style.paragraphSpacing = 18
                style.tabStops = TableLayoutMetrics.tabStops(readableWidth: 680, columnCount: 2)
                let naturalWidth = TableLayoutMetrics.naturalTableWidth(
                    leadingInset: TableLayoutMetrics.contentInset,
                    dividerLocations: TableLayoutMetrics.tabStopLocations(paragraphStyle: style, columnCount: 2),
                    columnCount: 2
                )

                let rect = ReaderLayoutManager.tableRowDrawRect(
                    usedRect: CGRect(x: 0, y: 48, width: 260, height: 20),
                    origin: NSPoint(x: 120, y: 0),
                    containerWidth: 680,
                    naturalTableWidth: naturalWidth,
                    rowInsets: TableLayoutMetrics.rowInsets(paragraphStyle: style, isTerminalRow: true)
                )

                XCTAssertEqual(rect.origin.y, 40, accuracy: 0.1)
                XCTAssertEqual(
                    rect.height,
                    20 + max(TableLayoutMetrics.rowVerticalPadding, style.paragraphSpacingBefore) +
                        TableLayoutMetrics.rowVerticalPadding,
                    accuracy: 0.1
                )
            }

            func testDividerLocationLeavesPaddingBeforeNextColumnText() {
                let tabStops = TableLayoutMetrics.tabStops(readableWidth: 720, columnCount: 3)
                XCTAssertEqual(tabStops.count, 2)

                let firstDivider = TableLayoutMetrics.dividerLocation(for: tabStops[0].location)

                XCTAssertLessThan(firstDivider, tabStops[0].location)
                XCTAssertEqual(
                    tabStops[0].location - firstDivider,
                    TableLayoutMetrics.columnDividerInset,
                    accuracy: 0.1
                )
            }
        }
    #endif
#endif
