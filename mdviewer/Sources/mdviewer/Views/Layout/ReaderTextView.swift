//
//  ReaderTextView.swift
//  mdviewer
//

#if os(macOS)
    internal import AppKit

    // MARK: - ReaderTextView

    /// Custom NSTextView subclass that constrains its text container to a readable
    /// width and centers the column horizontally within the enclosing scroll view.
    @MainActor
    final class ReaderTextView: NSTextView, @unchecked Sendable {
        var preferredReadableWidth: CGFloat = 720
        private let minimumHorizontalInset: CGFloat = 24
        private var lastAvailableWidth: CGFloat = 0

        /// Triggered when the view is added to the window hierarchy — the scroll view
        /// is guaranteed to exist here, so we can do the initial geometry pass.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            recomputeGeometry(force: true)
        }

        override func layout() {
            super.layout()
            recomputeGeometry(force: false)
        }

        /// Called after content changes — always recomputes layout and frame.
        func updateContainerGeometry() {
            recomputeGeometry(force: true)
        }

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
            if !force,
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
