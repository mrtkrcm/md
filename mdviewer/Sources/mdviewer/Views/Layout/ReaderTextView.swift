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

    // MARK: - Accessibility Elements

    /// Represents a heading in the document for semantic VoiceOver navigation.
    final class AccessibilityHeading: NSAccessibilityElement {
        let info: HeadingInfo
        weak var parentView: ReaderTextView?

        init(info: HeadingInfo, parent: ReaderTextView) {
            self.info = info
            parentView = parent
            super.init()
        }

        override func accessibilityLabel() -> String? { info.text }
        override func accessibilityRole() -> NSAccessibility.Role? { .staticText }
        override func accessibilitySubrole() -> NSAccessibility.Subrole? { .init(rawValue: "Heading") }

        override nonisolated func accessibilityFrame() -> NSRect {
            let targetView = parentView
            let headingRange = info.range
            return MainActor.assumeIsolated {
                guard
                    let targetView, let lm = targetView.layoutManager,
                    let tc = targetView.textContainer else { return .zero }
                let glyphRange = lm.glyphRange(forCharacterRange: headingRange, actualCharacterRange: nil)
                let rect = lm.boundingRect(forGlyphRange: glyphRange, in: tc)
                let viewRect = NSRect(
                    x: rect.origin.x + targetView.textContainerInset.width,
                    y: rect.origin.y + targetView.textContainerInset.height,
                    width: rect.width,
                    height: rect.height
                )
                return targetView.window?.convertToScreen(targetView.convert(viewRect, to: nil)) ?? .zero
            }
        }

        override nonisolated func accessibilityParent() -> Any? {
            parentView
        }

        override nonisolated func accessibilityPerformPress() -> Bool {
            let targetView = parentView
            let headingRange = info.range
            return MainActor.assumeIsolated {
                targetView?.setSelectedRange(headingRange)
                targetView?.scrollRangeToVisible(headingRange)
                return true
            }
        }
    }

    // MARK: - ReaderTextView

    /// Custom NSTextView subclass that constrains its text container to a readable
    /// width and centers the column horizontally within the enclosing scroll view.
    @MainActor
    final class ReaderTextView: NSTextView, @unchecked Sendable {
        enum OutlineNavigationTarget: Equatable {
            case heading(Int)
            case line(Int)
        }

        var preferredReadableWidth: CGFloat = 720
        /// Minimum inset applied on each side of the content column. Drives both the
        /// minimum padding and the vertical top/bottom inset. Settable so the caller
        /// can reflect the user's chosen content padding preference.
        var preferredHorizontalInset: CGFloat = 24
        private var lastAvailableWidth: CGFloat = 0
        private var lastAppliedContainerWidth: CGFloat = 0
        private var lastAppliedInsetWidth: CGFloat = 0
        private var deferredHeightRecomputeTask: Task<Void, Never>?

        /// Cached heading information for accessibility rotor navigation.
        private var headingInfos: [HeadingInfo] = []

        /// Current heading index for rotor navigation.
        private var currentHeadingIndex: Int = 0

        /// Cached accessibility elements for headings
        private var accessibilityHeadings: [AccessibilityHeading] = []

        /// Triggered when the view is added to the window hierarchy — the scroll view
        /// is guaranteed to exist here, so we can do the initial geometry pass.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            recomputeGeometry(force: true)
            scheduleHeadingCacheUpdate()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleJumpToLine),
                name: NSNotification.Name("JumpToLine"),
                object: nil
            )
        }

        override func layout() {
            super.layout()
            recomputeGeometry(force: false)
        }

        /// Called after content changes — always recomputes layout and frame.
        /// Heading cache is rebuilt asynchronously on a utility thread to keep
        /// the main-thread frame budget free for layout/rendering.
        func updateContainerGeometry() {
            recomputeGeometry(force: true)
            scheduleHeadingCacheUpdate()
        }

        /// Schedules heading cache rebuild off the main thread.
        private func scheduleHeadingCacheUpdate() {
            guard let storage = textStorage, storage.length > 0 else {
                headingInfos = []
                accessibilityHeadings = []
                return
            }

            // Snapshot the immutable attributed string for background scanning.
            nonisolated(unsafe) let snapshot = NSAttributedString(attributedString: storage)
            let headingKey = MarkdownRenderAttribute.headingLevel

            Task.detached(priority: .utility) { [weak self] in
                var newHeadings: [HeadingInfo] = []
                let fullRange = NSRange(location: 0, length: snapshot.length)

                snapshot.enumerateAttribute(headingKey, in: fullRange, options: []) { value, range, _ in
                    guard let level = value as? Int else { return }
                    let text = snapshot.attributedSubstring(from: range).string
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    newHeadings.append(HeadingInfo(range: range, level: level, text: text))
                }

                let sorted = newHeadings.sorted { $0.range.location < $1.range.location }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    headingInfos = sorted
                    accessibilityHeadings = sorted.map { AccessibilityHeading(info: $0, parent: self) }
                    currentHeadingIndex = 0
                }
            }
        }

        @objc
        private func handleJumpToLine(_ notification: Notification) {
            guard let target = Self.outlineNavigationTarget(from: notification.userInfo) else { return }

            switch target {
            case .heading(let headingIndex):
                if jumpToHeading(at: headingIndex) {
                    return
                }
                if let lineIndex = notification.userInfo?["lineIndex"] as? Int {
                    jumpToLine(lineIndex)
                }
            case .line(let lineIndex):
                jumpToLine(lineIndex)
            }
        }

        static func outlineNavigationTarget(from userInfo: [AnyHashable: Any]?) -> OutlineNavigationTarget? {
            if let headingIndex = userInfo?["headingIndex"] as? Int {
                return .heading(headingIndex)
            }
            if let lineIndex = userInfo?["lineIndex"] as? Int {
                return .line(lineIndex)
            }
            return nil
        }

        private func jumpToHeading(at headingIndex: Int) -> Bool {
            populateHeadingCacheIfNeeded()
            guard headingIndex >= 0, headingIndex < headingInfos.count else { return false }

            let heading = headingInfos[headingIndex]
            currentHeadingIndex = headingIndex
            setSelectedRange(heading.range)
            scrollRangeToVisible(heading.range)
            showFindIndicator(for: heading.range)
            setAccessibilityValue("\(heading.text), heading level \(heading.level)")
            return true
        }

        private func jumpToLine(_ lineIndex: Int) {
            guard let storage = textStorage else { return }
            let string = storage.string as NSString

            var currentLine = 0
            var charIndex = 0

            while charIndex < string.length {
                if currentLine == lineIndex {
                    let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))
                    setSelectedRange(lineRange)
                    scrollRangeToVisible(lineRange)

                    // Flash the target line visually
                    showFindIndicator(for: lineRange)
                    return
                }

                let range = string.lineRange(for: NSRange(location: charIndex, length: 0))
                charIndex = NSMaxRange(range)
                currentLine += 1
            }
        }

        private func populateHeadingCacheIfNeeded() {
            guard headingInfos.isEmpty, let storage = textStorage, storage.length > 0 else { return }

            var newHeadings: [HeadingInfo] = []
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.enumerateAttribute(
                MarkdownRenderAttribute.headingLevel,
                in: fullRange,
                options: []
            ) { value, range, _ in
                guard let level = value as? Int else { return }
                let text = storage.attributedSubstring(from: range).string
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                newHeadings.append(HeadingInfo(range: range, level: level, text: text))
            }

            let sorted = newHeadings.sorted { $0.range.location < $1.range.location }
            headingInfos = sorted
            accessibilityHeadings = sorted.map { AccessibilityHeading(info: $0, parent: self) }
            currentHeadingIndex = min(currentHeadingIndex, max(0, sorted.count - 1))
        }

        // MARK: - Accessibility Hierarchy

        override func accessibilityChildren() -> [Any]? {
            var children = super.accessibilityChildren() ?? []
            children.append(contentsOf: accessibilityHeadings)
            return children
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
            let minimumUsable = preferredHorizontalInset * 2 + 1
            guard availableWidth >= minimumUsable else { return }

            // Calculate target width with insets
            let maxContentWidth = availableWidth - (preferredHorizontalInset * 2)
            let targetWidth = min(preferredReadableWidth, maxContentWidth)

            // Calculate centering padding if we have extra space
            let hPadding = max(preferredHorizontalInset, (availableWidth - targetWidth) / 2)

            // Compare against our own stored values — not AppKit's reported values —
            // to avoid a layout invalidation loop caused by AppKit rounding
            // container sizes internally (the floating-point equality hazard).
            let widthChanged = abs(lastAppliedContainerWidth - targetWidth) >= 0.5
            let insetChanged = abs(lastAppliedInsetWidth - hPadding) >= 0.5
            let availableWidthChanged = abs(lastAvailableWidth - availableWidth) >= 0.5
            if !force, !widthChanged, !insetChanged, !availableWidthChanged {
                return
            }
            lastAvailableWidth = availableWidth
            lastAppliedContainerWidth = targetWidth
            lastAppliedInsetWidth = hPadding

            // Update container and insets
            textContainer.containerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
            textContainerInset = NSSize(width: hPadding, height: preferredHorizontalInset)
            if force {
                deferredHeightRecomputeTask?.cancel()
                applyAccurateHeight(for: textContainer, availableWidth: availableWidth)
                return
            }

            // Avoid full layout synchronously during interactive resize/toolbar changes.
            let currentHeight = max(frame.height, bounds.height, 1)
            setFrameSize(NSSize(width: availableWidth, height: currentHeight))
            scheduleDeferredHeightRecompute(for: textContainer, availableWidth: availableWidth)
        }

        private func scheduleDeferredHeightRecompute(for textContainer: NSTextContainer, availableWidth: CGFloat) {
            deferredHeightRecomputeTask?.cancel()
            deferredHeightRecomputeTask = Task { @MainActor [weak self, weak textContainer] in
                try? await Task.sleep(for: .milliseconds(140))
                guard !Task.isCancelled, let self, let textContainer else { return }
                applyAccurateHeight(for: textContainer, availableWidth: availableWidth)
            }
        }

        private func applyAccurateHeight(for textContainer: NSTextContainer, availableWidth: CGFloat) {
            layoutManager?.ensureLayout(for: textContainer)
            let usedHeight = layoutManager?.usedRect(for: textContainer).height ?? 0
            let totalHeight = usedHeight + (preferredHorizontalInset * 2)
            setFrameSize(NSSize(width: availableWidth, height: max(totalHeight, 1)))
        }
    }
#endif
