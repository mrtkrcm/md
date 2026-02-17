#if canImport(XCTest)
import XCTest
import Splash
@testable import mdviewer

final class SyntaxHighlighterTests: XCTestCase {
    func testHighlightSwiftCodeSmokeTest() {
        let highlighter = SplashCodeSyntaxHighlighter(theme: .sundellsColors(withFont: .init(size: 14)))
        let code = "let x = 1"
        _ = highlighter.highlightCode(code, language: "swift")
    }

    func testHighlightNonSwiftCodeSmokeTest() {
        let highlighter = SplashCodeSyntaxHighlighter(theme: .sundellsColors(withFont: .init(size: 14)))
        let code = "def foo(): pass"
        _ = highlighter.highlightCode(code, language: "python")
    }
}
#endif
