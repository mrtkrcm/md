//
//  NativeMarkdownTextView.swift
//  mdviewer
//

internal import Foundation
internal import OSLog
internal import SwiftUI
#if os(macOS)
    internal import AppKit

    /// Signpost logger for markdown rendering pipeline profiling.
    private let markdownRenderSignposter = OSSignposter(subsystem: "mdviewer", category: "MarkdownRenderPipeline")

    /// Threshold for considering a document "large" and needing a loading announcement.
    private let largeDocumentThreshold: Int = 50_000

    /// A native AppKit-based text view for rendering formatted markdown content.
    /// Provides full VoiceOver support with heading navigation and document structure announcement.
    struct NativeMarkdownTextView: NSViewRepresentable {
        let markdown: String
        let readerFontFamily: ReaderFontFamily
        let readerFontSize: CGFloat
        let codeFontSize: CGFloat
        let appTheme: AppTheme
        let syntaxPalette: SyntaxPalette
        let colorScheme: ColorScheme
        let textSpacing: ReaderTextSpacing
        let readableWidth: CGFloat
        let contentPadding: CGFloat
        let showLineNumbers: Bool
        let typographyPreferences: TypographyPreferences
        var onScrollGestureStart: ((CGFloat) -> Void)?
        var onScrollGestureLive: ((CGFloat, CGFloat, Bool) -> Void)?
        var onScrollGestureEnd: ((CGFloat, CGFloat, Bool) -> Void)?

        func makeNSView(context: Context) -> NSScrollView {
            // Signpost: TextView creation start
            let signpostID = markdownRenderSignposter.makeSignpostID()
            let intervalState = markdownRenderSignposter.beginInterval("TextViewCreation", id: signpostID)
            defer { markdownRenderSignposter.endInterval("TextViewCreation", intervalState) }

            // Force TextKit 1 (NSLayoutManager) — TextKit 2 (the macOS 14+ default) does not
            // call NSTextBlock.drawBackground(withFrame:), so blockquote/code NSTextBlock
            // backgrounds and borders are invisible without explicit TK1 opt-in.
            //
            // The correct TK1 initialisation sequence:
            //   NSTextStorage → NSLayoutManager → NSTextContainer → NSTextView
            // NSTextView's textStorage property then points to the same NSTextStorage,
            // so setAttributedString updates go through the correct layout pipeline.
            let textStorage = NSTextStorage()
            let layoutManager = ReaderLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
            textContainer.lineFragmentPadding = 0
            // ReaderTextView manages readable column width manually; do not auto-track full width.
            textContainer.widthTracksTextView = false
            // Ensure proper container sizing behavior for macOS native rendering
            textContainer.heightTracksTextView = false
            layoutManager.addTextContainer(textContainer)

            // This designated initialiser adopts the textContainer (and its storage chain)
            // instead of creating a fresh TK2 text layout manager.
            let textView = ReaderTextView(frame: .zero, textContainer: textContainer)
            textView.isEditable = false
            textView.isSelectable = true
            textView.drawsBackground = false
            textView.focusRingType = NSFocusRingType.none
            textView.usesFindBar = true
            textView.isRichText = true
            textView.allowsUndo = false
            textView.preferredReadableWidth = readableWidth
            textView.preferredHorizontalInset = contentPadding

            // Configure accessibility for VoiceOver
            // ReaderTextView provides heading rotor support via accessibilityCustomActions()
            textView.setAccessibilityLabel("Rendered Markdown Document")
            textView.setAccessibilityRole(.textArea)
            textView.setAccessibilityIdentifier("RenderedMarkdownView")
            textView.setAccessibilityHelp("Use VoiceOver rotor to navigate by headings")

            let scrollView = ScrollTrackingScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.focusRingType = .none
            scrollView.wantsLayer = true
            scrollView.layer?.borderWidth = 0
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.documentView = textView
            scrollView.onScrollGestureStart = onScrollGestureStart
            scrollView.onScrollGestureLive = onScrollGestureLive
            scrollView.onScrollGestureEnd = onScrollGestureEnd

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            if let trackingScrollView = scrollView as? ScrollTrackingScrollView {
                trackingScrollView.onScrollGestureStart = onScrollGestureStart
                trackingScrollView.onScrollGestureLive = onScrollGestureLive
                trackingScrollView.onScrollGestureEnd = onScrollGestureEnd
            }
            guard let textView = scrollView.documentView as? ReaderTextView else { return }
            let previousReadableWidth = textView.preferredReadableWidth
            let previousHorizontalInset = textView.preferredHorizontalInset
            textView.preferredReadableWidth = readableWidth
            textView.preferredHorizontalInset = contentPadding
            if
                abs(previousReadableWidth - readableWidth) > 0.5
                || abs(previousHorizontalInset - contentPadding) > 0.5
            {
                textView.updateContainerGeometry()
            }

            let request = RenderRequest(
                markdown: markdown,
                readerFontFamily: readerFontFamily,
                readerFontSize: readerFontSize,
                codeFontSize: codeFontSize,
                appTheme: appTheme,
                syntaxPalette: syntaxPalette,
                colorScheme: colorScheme,
                textSpacing: textSpacing,
                readableWidth: readableWidth,
                showLineNumbers: showLineNumbers,
                typographyPreferences: typographyPreferences
            )

            let coordinator = context.coordinator
            guard coordinator.currentRequest != request else { return }
            let previousRequest = coordinator.currentRequest
            let isWidthOnlyChange: Bool
            if let previousRequest {
                isWidthOnlyChange = previousRequest.equalsIgnoringReadableWidth(request)
                    && abs(previousRequest.readableWidth - request.readableWidth) > 0.5
            } else {
                isWidthOnlyChange = false
            }

            coordinator.currentRequest = request
            coordinator.generation += 1
            let generation = coordinator.generation
            coordinator.renderTask?.cancel()

            // Width-only changes do not require a full render for regular markdown.
            if isWidthOnlyChange, !request.requiresWidthAwareRerender {
                return
            }

            // Announce loading state for large documents
            let documentSize = request.markdown.count
            let isLargeDocument = documentSize > largeDocumentThreshold
            if isLargeDocument {
                textView.setAccessibilityValue("Loading document...")
            }

            coordinator.renderTask = Task { @MainActor [weak textView] in
                if isWidthOnlyChange {
                    try? await Task.sleep(for: .milliseconds(140))
                }
                guard !Task.isCancelled else { return }

                // Signpost: Track async markdown render start
                let signpostID = markdownRenderSignposter.makeSignpostID()
                let intervalState = markdownRenderSignposter.beginInterval("AsyncMarkdownRender", id: signpostID)
                let rendered = await MarkdownRenderService.shared.render(request)
                markdownRenderSignposter.endInterval("AsyncMarkdownRender", intervalState)

                guard !Task.isCancelled else { return }
                guard
                    coordinator.generation == generation,
                    coordinator.currentRequest == request,
                    let textView
                else { return }

                // Signpost: Track UI update
                let uiSignpostID = markdownRenderSignposter.makeSignpostID()
                let uiInterval = markdownRenderSignposter.beginInterval("TextViewUIUpdate", id: uiSignpostID)
                defer { markdownRenderSignposter.endInterval("TextViewUIUpdate", uiInterval) }

                // Preserve scroll position across re-renders
                let scrollPoint = textView.enclosingScrollView?.documentVisibleRect.origin
                textView.textStorage?.setAttributedString(rendered.attributedString)
                textView.updateContainerGeometry()

                // Update accessibility value with document info
                let charCount = rendered.attributedString.length
                let accessibilityValue: String
                if charCount == 0 {
                    accessibilityValue = "Empty document"
                } else if isLargeDocument {
                    accessibilityValue = "\(charCount) characters, document loaded"
                } else {
                    accessibilityValue = "\(charCount) characters, formatted markdown"
                }
                textView.setAccessibilityValue(accessibilityValue)

                if let scrollPoint {
                    textView.scroll(scrollPoint)
                }

                // Emit event for completed render
                markdownRenderSignposter.emitEvent("MarkdownRenderCompleted", id: signpostID)
            }
        }

        static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
            coordinator.renderTask?.cancel()
            coordinator.renderTask = nil
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        @MainActor
        final class Coordinator {
            var currentRequest: RenderRequest?
            var generation: Int = 0
            var renderTask: Task<Void, Never>?
        }
    }

    /// NSScrollView subclass that reports scroll position changes for toolbar auto-hide.
    @MainActor
    private final class ScrollTrackingScrollView: NSScrollView {
        var onScrollGestureStart: ((CGFloat) -> Void)?
        var onScrollGestureLive: ((CGFloat, CGFloat, Bool) -> Void)?
        var onScrollGestureEnd: ((CGFloat, CGFloat, Bool) -> Void)?

        private var liveScrollStartOffset: CGFloat?
        private var liveScrollLastOffset: CGFloat?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupScrollTracking()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupScrollTracking()
        }

        private func setupScrollTracking() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(willStartLiveScroll),
                name: NSScrollView.willStartLiveScrollNotification,
                object: self
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didEndLiveScroll),
                name: NSScrollView.didEndLiveScrollNotification,
                object: self
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didLiveScroll),
                name: NSScrollView.didLiveScrollNotification,
                object: self
            )
        }

        @objc
        private func willStartLiveScroll() {
            let startOffset = contentView.bounds.origin.y
            liveScrollStartOffset = startOffset
            liveScrollLastOffset = startOffset
            onScrollGestureStart?(startOffset)
        }

        @objc
        private func didLiveScroll() {
            guard let onScrollGestureLive else { return }
            let currentOffset = contentView.bounds.origin.y
            let previousOffset = liveScrollLastOffset ?? currentOffset
            let delta = currentOffset - previousOffset
            liveScrollLastOffset = currentOffset
            let canScroll = canScrollVertically()
            guard abs(delta) > 1 else { return }
            onScrollGestureLive(delta, currentOffset, canScroll)
        }

        @objc
        private func didEndLiveScroll() {
            guard let onScrollGestureEnd else { return }
            guard let startOffset = liveScrollStartOffset else { return }
            let finalOffset = contentView.bounds.origin.y
            let delta = finalOffset - startOffset
            let canScroll = canScrollVertically()
            liveScrollStartOffset = nil
            liveScrollLastOffset = nil
            if !canScroll {
                onScrollGestureEnd(0, finalOffset, false)
                return
            }
            guard abs(delta) > 1 else { return }
            onScrollGestureEnd(delta, finalOffset, true)
        }

        private func canScrollVertically() -> Bool {
            guard let documentView else { return false }
            return documentView.bounds.height > contentView.bounds.height + 1
        }
    }
#endif
