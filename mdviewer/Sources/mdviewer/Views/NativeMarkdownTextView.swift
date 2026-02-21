internal import SwiftUI
internal import Foundation
#if os(macOS)
    @preconcurrency internal import AppKit

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

        func makeNSView(context: Context) -> NSScrollView {
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
            textView.textContainerInset = NSSize(width: 24, height: 24)
            textView.preferredReadableWidth = readableWidth

            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            scrollView.borderType = .noBorder
            scrollView.focusRingType = .none
            scrollView.wantsLayer = true
            scrollView.layer?.borderWidth = 0
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.documentView = textView

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            guard let textView = scrollView.documentView as? ReaderTextView else { return }
            textView.preferredReadableWidth = readableWidth

            let request = RenderRequest(
                markdown: markdown,
                readerFontFamily: readerFontFamily,
                readerFontSize: readerFontSize,
                codeFontSize: codeFontSize,
                appTheme: appTheme,
                syntaxPalette: syntaxPalette,
                colorScheme: colorScheme,
                textSpacing: textSpacing,
                readableWidth: readableWidth
            )

            let coordinator = context.coordinator
            guard coordinator.currentRequest != request else { return }

            coordinator.currentRequest = request
            coordinator.generation += 1
            let generation = coordinator.generation
            coordinator.renderTask?.cancel()

            coordinator.renderTask = Task { @MainActor [weak textView] in
                let rendered = await MarkdownRenderService.shared.render(request)
                guard !Task.isCancelled else { return }
                guard
                    coordinator.generation == generation,
                    coordinator.currentRequest == request,
                    let textView
                else { return }

                textView.textStorage?.setAttributedString(rendered.attributedString)
                textView.updateContainerGeometry()
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
#endif
