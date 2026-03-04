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
        var onScroll: ((CGFloat, CGFloat, CGFloat) -> Void)?

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
            textContainer.widthTracksTextView = true
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
            scrollView.onScroll = onScroll

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            if let trackingScrollView = scrollView as? ScrollTrackingScrollView {
                trackingScrollView.onScroll = onScroll
            }
            guard let textView = scrollView.documentView as? ReaderTextView else { return }
            textView.preferredReadableWidth = readableWidth
            textView.preferredHorizontalInset = contentPadding

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

            coordinator.currentRequest = request
            coordinator.generation += 1
            let generation = coordinator.generation
            coordinator.renderTask?.cancel()

            // Announce loading state for large documents
            let documentSize = request.markdown.count
            let isLargeDocument = documentSize > largeDocumentThreshold
            if isLargeDocument {
                textView.setAccessibilityValue("Loading document...")
            }

            // Signpost: Track async markdown render start
            let signpostID = markdownRenderSignposter.makeSignpostID()
            let intervalState = markdownRenderSignposter.beginInterval("AsyncMarkdownRender", id: signpostID)

            coordinator.renderTask = Task { @MainActor [weak textView] in
                let rendered = await MarkdownRenderService.shared.render(request)

                // End the async render interval when complete
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
    /// Uses coalesced updates to prevent excessive notifications during smooth scrolling.
    @MainActor
    private final class ScrollTrackingScrollView: NSScrollView {
        var onScroll: ((CGFloat, CGFloat, CGFloat) -> Void)?

        private var lastReportedOffset: CGFloat = 0
        private var scrollUpdateTask: Task<Void, Never>?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupScrollTracking()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupScrollTracking()
        }

        private func setupScrollTracking() {
            // Use coalesced notifications instead of every bounds change
            postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(boundsDidChange),
                name: NSView.boundsDidChangeNotification,
                object: contentView
            )
        }

        @objc
        private func boundsDidChange() {
            // Cancel any pending update and schedule a new one
            scrollUpdateTask?.cancel()
            scrollUpdateTask = Task { @MainActor [weak self] in
                // Small delay to coalesce rapid scroll events
                try? await Task.sleep(for: .milliseconds(4)) // ~240fps coalescing
                guard !Task.isCancelled else { return }
                self?.reportScrollPosition()
            }
        }

        private func reportScrollPosition() {
            guard
                let onScroll,
                let documentView else { return }

            let offset = contentView.bounds.origin.y
            let contentHeight = documentView.frame.height
            let visibleHeight = contentView.bounds.height

            // Only report if offset changed significantly (prevents micro-updates)
            guard abs(offset - lastReportedOffset) > 0.5 else { return }
            lastReportedOffset = offset

            onScroll(offset, contentHeight, visibleHeight)
        }

        deinit {
            scrollUpdateTask?.cancel()
        }
    }
#endif
