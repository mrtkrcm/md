//
//  ReaderTextView.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - Heading Info

    /// Information about a heading for accessibility navigation.
    struct HeadingInfo: Equatable {
        let range: NSRange
        let level: Int
        let text: String

        static func == (lhs: HeadingInfo, rhs: HeadingInfo) -> Bool {
            NSEqualRanges(lhs.range, rhs.range) && lhs.level == rhs.level && lhs.text == rhs.text
        }
    }

    // MARK: - ReaderTextView

    /// Custom NSTextView subclass that constrains its text container to a readable
    /// width and centers the column horizontally within the enclosing scroll view.
    @MainActor
    final class ReaderTextView: NSTextView, @unchecked Sendable {
        var preferredReadableWidth: CGFloat = 720
        private let minimumHorizontalInset: CGFloat = 24
        private var lastAvailableWidth: CGFloat = 0

        /// Cached heading information for accessibility rotor navigation.
        private var headingInfos: [HeadingInfo] = []

        /// Current heading index for rotor navigation.
        private var currentHeadingIndex: Int = 0

        /// Triggered when the view is added to the window hierarchy — the scroll view
        /// is guaranteed to exist here, so we can do the initial geometry pass.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            recomputeGeometry(force: true)
            updateHeadingCache()
        }

        override func layout() {
            super.layout()
            recomputeGeometry(force: false)
        }

        /// Called after content changes — always recomputes layout and frame.
        func updateContainerGeometry() {
            recomputeGeometry(force: true)
            updateHeadingCache()
        }

        // MARK: - Heading Cache

        /// Scans the attributed text for headings and caches their ranges.
        private func updateHeadingCache() {
            guard let storage = textStorage else {
                headingInfos = []
                return
            }

            var newHeadings: [HeadingInfo] = []
            let fullRange = NSRange(location: 0, length: storage.length)

            storage.enumerateAttribute(
                MarkdownRenderAttribute.headingLevel,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let level = value as? Int else { return }

                // Extract heading text
                let headingText = storage.attributedSubstring(from: range).string
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                newHeadings.append(HeadingInfo(
                    range: range,
                    level: level,
                    text: headingText
                ))
            }

            headingInfos = newHeadings.sorted { $0.range.location < $1.range.location }
            currentHeadingIndex = 0
        }

        // MARK: - Accessibility Rotor Support

        override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
            var actions = super.accessibilityCustomActions() ?? []

            // Add navigation actions if headings exist
            if !headingInfos.isEmpty {
                let nextHeading = NSAccessibilityCustomAction(
                    name: "Next Heading",
                    target: self,
                    selector: #selector(navigateToNextHeading)
                )
                actions.append(nextHeading)

                let previousHeading = NSAccessibilityCustomAction(
                    name: "Previous Heading",
                    target: self,
                    selector: #selector(navigateToPreviousHeading)
                )
                actions.append(previousHeading)
            }

            // Add jump to top/bottom actions
            let jumpToTop = NSAccessibilityCustomAction(
                name: "Jump to Top",
                target: self,
                selector: #selector(jumpToTop)
            )
            actions.append(jumpToTop)

            let jumpToBottom = NSAccessibilityCustomAction(
                name: "Jump to Bottom",
                target: self,
                selector: #selector(jumpToBottom)
            )
            actions.append(jumpToBottom)

            return actions
        }

        // MARK: - Navigation Actions

        @objc
        private func navigateToNextHeading() -> Bool {
            guard !headingInfos.isEmpty else { return false }

            let currentRange = selectedRange()
            guard let nextIndex = headingInfos.firstIndex(where: { $0.range.location > currentRange.location })
            else {
                // Wrap to first heading
                selectAndScrollToHeading(at: 0)
                return true
            }

            selectAndScrollToHeading(at: nextIndex)
            return true
        }

        @objc
        private func navigateToPreviousHeading() -> Bool {
            guard !headingInfos.isEmpty else { return false }

            let currentRange = selectedRange()
            guard let prevIndex = headingInfos.lastIndex(where: { $0.range.location < currentRange.location })
            else {
                // Wrap to last heading
                selectAndScrollToHeading(at: headingInfos.count - 1)
                return true
            }

            selectAndScrollToHeading(at: prevIndex)
            return true
        }

        @objc
        private func jumpToTop() -> Bool {
            scrollToBeginningOfDocument(nil)
            setSelectedRange(NSRange(location: 0, length: 0))
            return true
        }

        @objc
        private func jumpToBottom() -> Bool {
            scrollToEndOfDocument(nil)
            guard let storage = textStorage else { return true }
            let endLocation = storage.length
            setSelectedRange(NSRange(location: endLocation, length: 0))
            return true
        }

        // MARK: - Helper Methods

        private func selectAndScrollToHeading(at index: Int) {
            guard index >= 0, index < headingInfos.count else { return }

            let heading = headingInfos[index]
            currentHeadingIndex = index

            // Select the heading text
            setSelectedRange(heading.range)

            // Scroll to make it visible
            scrollRangeToVisible(heading.range)

            // Set accessibility value so VoiceOver announces the heading
            setAccessibilityValue("\(heading.text), heading level \(heading.level)")
        }

        // MARK: - Geometry

        private func recomputeGeometry(force: Bool) {
            guard let textContainer else { return }

            // Get available width from scroll view or fallback to bounds
            let availableWidth: CGFloat
            if let sv = enclosingScrollView {
                availableWidth = sv.contentSize.width
            } else if bounds.width > 0 {
                availableWidth = bounds.width
            } else {
                return
            }

            // Guard: need at least enough room for minimum insets + 1pt of content
            let minimumUsable = minimumHorizontalInset * 2 + 1
            guard availableWidth >= minimumUsable else { return }

            // Calculate target width with insets
            let maxContentWidth = availableWidth - (minimumHorizontalInset * 2)
            let targetWidth = min(preferredReadableWidth, maxContentWidth)
            let hInset = max(minimumHorizontalInset, (availableWidth - targetWidth) / 2)

            // Only update if changed significantly (skip redundant layout passes)
            if
                !force,
                abs(textContainer.containerSize.width - targetWidth) < 1.0,
                abs(textContainerInset.width - hInset) < 1.0,
                abs(lastAvailableWidth - availableWidth) < 1.0
            {
                return
            }
            lastAvailableWidth = availableWidth

            // Update container and insets
            textContainer.containerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
            textContainerInset = NSSize(width: hInset, height: minimumHorizontalInset)

            // Update view frame to match content
            layoutManager?.ensureLayout(for: textContainer)
            let usedHeight = layoutManager?.usedRect(for: textContainer).height ?? 0
            let totalHeight = usedHeight + (minimumHorizontalInset * 2)
            setFrameSize(NSSize(width: availableWidth, height: max(totalHeight, 1)))
        }
    }
#endif
