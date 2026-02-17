#if canImport(XCTest)
import XCTest
@testable import mdviewer

final class MarkdownDocumentTests: XCTestCase {
    func testInitializationPersistsText() {
        let text = "# Hello"
        let document = MarkdownDocument(text: text)
        XCTAssertEqual(document.text, text)
    }
}
#endif
