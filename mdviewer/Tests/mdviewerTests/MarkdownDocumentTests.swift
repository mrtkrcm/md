import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import mdviewer

final class MarkdownDocumentTests: XCTestCase {
    func testInitialization() {
        let text = "# Hello"
        let document = MarkdownDocument(text: text)
        XCTAssertEqual(document.text, text)
    }
}
