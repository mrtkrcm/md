#if os(macOS)
@preconcurrency internal import AppKit

// MARK: - ReaderTextView

/// Custom NSTextView subclass that constrains its text container to a readable
/// width and centers the column horizontally within the enclosing scroll view.
final class ReaderTextView: NSTextView {
    var preferredReadableWidth: CGFloat = 760
    private let minimumHorizontalInset: CGFloat = 24

    // Triggered when the view is added to the window hierarchy — the scroll view
    // is guaranteed to exist here, so we can do the initial geometry pass.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        recomputeGeometry(force: true)
    }

    override func layout() {
        super.layout()
        recomputeGeometry(force: false)
    }

    // Called after content changes — always recomputes layout and frame.
    func updateContainerGeometry() {
        recomputeGeometry(force: true)
    }

    private func recomputeGeometry(force: Bool) {
        guard let textContainer else { return }

        // Prefer the scroll view's content width; fall back to our own bounds
        // for the brief window between init and insertion into the hierarchy.
        let availableWidth: CGFloat
        if let sv = enclosingScrollView {
            availableWidth = sv.contentSize.width
        } else if bounds.width > 0 {
            availableWidth = bounds.width
        } else {
            return  // nothing to measure yet
        }

        let targetWidth      = min(preferredReadableWidth, max(0, availableWidth - minimumHorizontalInset * 2))
        let hInset           = max(minimumHorizontalInset, (availableWidth - targetWidth) / 2)
        let newContainerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)

        // Skip redundant work when neither the column width nor the inset has changed.
        if !force,
           abs(textContainer.containerSize.width - newContainerSize.width) < 0.5,
           abs(textContainerInset.width - hInset) < 0.5 {
            return
        }

        textContainer.containerSize = newContainerSize
        textContainerInset          = NSSize(width: hInset, height: 24)

        // Compute full document height and resize the view so NSScrollView knows
        // the complete scroll extent.
        layoutManager?.ensureLayout(for: textContainer)
        let usedHeight  = layoutManager?.usedRect(for: textContainer).height ?? 0
        let totalHeight = usedHeight + textContainerInset.height * 2
        let viewWidth   = max(availableWidth, targetWidth + hInset * 2)
        setFrameSize(NSSize(width: viewWidth, height: max(totalHeight, 1)))
    }
}
#endif
