//
//  TableLayoutMetrics.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Table Layout Metrics

    /// Shared sizing rules for markdown tables so text layout, truncation,
    /// and decoration drawing all agree on the same column geometry.
    enum TableLayoutMetrics {
        private final class TabStopCacheEntry {
            let stops: [NSTextTab]

            init(stops: [NSTextTab]) {
                self.stops = stops
            }
        }

        struct RowInsets: Hashable {
            let top: CGFloat
            let bottom: CGFloat
        }

        static let maximumTabStops = 8
        private nonisolated(unsafe) static let tabStopCache: NSCache<NSString, TabStopCacheEntry> = {
            let cache = NSCache<NSString, TabStopCacheEntry>()
            cache.countLimit = 24
            return cache
        }()

        static var contentInset: CGFloat {
            DesignTokens.Component.Table.contentInset
        }

        static var trailingPadding: CGFloat {
            DesignTokens.Spacing.standard
        }

        static var minimumColumnWidth: CGFloat {
            DesignTokens.Component.Table.minColumnWidth
        }

        static var columnDividerInset: CGFloat {
            DesignTokens.Component.Table.columnDividerInset
        }

        static var minimumTableWidth: CGFloat {
            contentInset + minimumColumnWidth
        }

        static var rowVerticalPadding: CGFloat {
            DesignTokens.Component.Table.rowVerticalPadding
        }

        static func columnWidth(readableWidth: CGFloat, columnCount: Int) -> CGFloat {
            let resolvedColumnCount = max(1, columnCount)
            let usableWidth = max(
                minimumColumnWidth * CGFloat(resolvedColumnCount),
                readableWidth - DesignTokens.Component.Table.horizontalPadding - contentInset
            )
            return max(minimumColumnWidth, usableWidth / CGFloat(resolvedColumnCount))
        }

        static func tabStops(readableWidth: CGFloat, columnCount: Int) -> [NSTextTab] {
            let resolvedColumnCount = max(1, min(maximumTabStops, columnCount))
            let cacheKey = tabStopCacheKey(readableWidth: readableWidth, columnCount: resolvedColumnCount)
            if let cachedStops = tabStopCache.object(forKey: cacheKey) {
                return cachedStops.stops
            }

            let width = columnWidth(readableWidth: readableWidth, columnCount: resolvedColumnCount)
            let stops = (0 ..< max(0, resolvedColumnCount - 1)).map { index in
                NSTextTab(
                    textAlignment: .left,
                    location: contentInset + (width * CGFloat(index + 1)),
                    options: [:]
                )
            }
            tabStopCache.setObject(TabStopCacheEntry(stops: stops), forKey: cacheKey)
            return stops
        }

        static func tabStopLocations(paragraphStyle: NSParagraphStyle, columnCount: Int) -> [CGFloat] {
            paragraphStyle.tabStops
                .prefix(max(0, columnCount - 1))
                .map(\.location)
        }

        static func dividerLocations(paragraphStyle: NSParagraphStyle, columnCount: Int) -> [CGFloat] {
            tabStopLocations(paragraphStyle: paragraphStyle, columnCount: columnCount).map(dividerLocation(for:))
        }

        static func dividerLocation(for tabStopLocation: CGFloat) -> CGFloat {
            max(contentInset, tabStopLocation - columnDividerInset)
        }

        static func nonTerminalCellContentWidth(readableWidth: CGFloat, columnCount: Int) -> CGFloat {
            max(
                minimumColumnWidth - columnDividerInset,
                columnWidth(readableWidth: readableWidth, columnCount: columnCount) -
                    columnDividerInset
            )
        }

        static func tableWidth(
            paragraphStyle: NSParagraphStyle?,
            columnCount: Int,
            containerWidth: CGFloat
        ) -> CGFloat {
            let clampedContainerWidth = max(minimumTableWidth, containerWidth)
            let resolvedColumnCount = max(1, columnCount)
            guard let paragraphStyle else {
                let fallbackWidth = contentInset + (minimumColumnWidth * CGFloat(resolvedColumnCount))
                return min(clampedContainerWidth, max(minimumTableWidth, fallbackWidth))
            }

            let leadingInset = max(contentInset, paragraphStyle.firstLineHeadIndent, paragraphStyle.headIndent)
            let dividerLocations = tabStopLocations(paragraphStyle: paragraphStyle, columnCount: resolvedColumnCount)
            let naturalWidth = naturalTableWidth(
                leadingInset: leadingInset,
                dividerLocations: dividerLocations,
                columnCount: resolvedColumnCount
            )
            return min(clampedContainerWidth, max(minimumTableWidth, naturalWidth))
        }

        static func naturalTableWidth(
            leadingInset: CGFloat,
            dividerLocations: [CGFloat],
            columnCount: Int
        ) -> CGFloat {
            let resolvedColumnCount = max(1, columnCount)

            guard !dividerLocations.isEmpty else {
                let singleColumnWidth = leadingInset + (minimumColumnWidth * CGFloat(resolvedColumnCount))
                return max(minimumTableWidth, singleColumnWidth)
            }

            var previousLocation = leadingInset
            var trailingColumnWidth = minimumColumnWidth

            for dividerLocation in dividerLocations {
                let columnWidth = max(minimumColumnWidth, dividerLocation - previousLocation)
                trailingColumnWidth = columnWidth
                previousLocation = dividerLocation
            }

            let naturalWidth = previousLocation + trailingColumnWidth
            return max(minimumTableWidth, naturalWidth)
        }

        static func rowInsets(paragraphStyle: NSParagraphStyle?, isTerminalRow: Bool) -> RowInsets {
            let top = max(
                rowVerticalPadding,
                paragraphStyle?.paragraphSpacingBefore ?? 0
            )
            let bottom = max(
                rowVerticalPadding,
                isTerminalRow ? rowVerticalPadding : (paragraphStyle?.paragraphSpacing ?? 0)
            )
            return RowInsets(top: top, bottom: bottom)
        }

        private static func tabStopCacheKey(readableWidth: CGFloat, columnCount: Int) -> NSString {
            let roundedWidth = Int((readableWidth * 100).rounded())
            return "\(roundedWidth)-\(columnCount)" as NSString
        }
    }
#endif
