import XCTest
import SwiftUI
import MarkdownUI
import Splash
@testable import mdviewer

final class SyntaxHighlighterTests: XCTestCase {
    func testHighlightSwift() {
        let highlighter = SplashCodeSyntaxHighlighter(theme: .sundellsColors(withFont: .init(size: 14)))
        let code = "let x = 1"
        let _ = highlighter.highlightCode(code, language: "swift")
        // Execution without crash is the basic verification here since Text is opaque
    }

    func testHighlightOther() {
        let highlighter = SplashCodeSyntaxHighlighter(theme: .sundellsColors(withFont: .init(size: 14)))
        let code = "def foo(): pass"
        let _ = highlighter.highlightCode(code, language: "python")
    }
}
