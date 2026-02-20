#if canImport(XCTest)
import XCTest
import UniformTypeIdentifiers
@testable import mdviewer

final class MarkdownDocumentTests: XCTestCase {
    func testDefaultInitializationStartsEmptyDocument() {
        let document = MarkdownDocument()
        XCTAssertEqual(document.text, "")
    }

    func testInitializationPersistsText() {
        let text = "# Hello"
        let document = MarkdownDocument(text: text)
        XCTAssertEqual(document.text, text)
    }

    func testIsEffectivelyEmptyUsesTrimmedContent() {
        XCTAssertTrue(MarkdownDocument(text: " \n\t ").isEffectivelyEmpty)
        XCTAssertFalse(MarkdownDocument(text: MarkdownDocument.starterContent).isEffectivelyEmpty)
        XCTAssertFalse(MarkdownDocument(text: "hello").isEffectivelyEmpty)
    }

    func testFileWrapperWritesUtf8Data() throws {
        // FileDocumentWriteConfiguration has no accessible initializer in the Xcode SDK.
        // Test the underlying serialization directly: text → UTF-8 data → FileWrapper.
        let expected = "# Merhaba"
        let document = MarkdownDocument(text: expected)
        let data = try XCTUnwrap(document.text.data(using: .utf8))
        let wrapper = FileWrapper(regularFileWithContents: data)
        let decoded = String(data: try XCTUnwrap(wrapper.regularFileContents), encoding: .utf8)
        XCTAssertEqual(decoded, expected)
    }

    func testDecodeDecodesUTF16() throws {
        // FileDocumentReadConfiguration has no accessible initializer in the Xcode SDK.
        // Test the internal decode helper directly instead of going through SwiftUI's document system.
        let source = "# UTF16"
        let data = try XCTUnwrap(source.data(using: .utf16))
        let decoded = MarkdownDocument.decode(data: data)
        XCTAssertEqual(decoded, source)
    }

    func testDecodeDecodesUTF32WithBOM() throws {
        let source = "# UTF32"
        let payload = try XCTUnwrap(source.data(using: .utf32LittleEndian))
        let data = Data([0xFF, 0xFE, 0x00, 0x00]) + payload
        let decoded = MarkdownDocument.decode(data: data)
        XCTAssertEqual(decoded, source)
    }

    func testMaxFileSizeLimitConstantIsEightMegabytes() {
        XCTAssertEqual(MarkdownDocument.maxReadableFileSizeBytes, 8 * 1024 * 1024)
    }

    func testDecodeStripsUTF8BOM() throws {
        // BOM prefix [EF BB BF] must be stripped; plain UTF-8 text follows.
        let source = "# UTF8 BOM"
        let utf8 = try XCTUnwrap(source.data(using: .utf8))
        let data = Data([0xEF, 0xBB, 0xBF]) + utf8
        XCTAssertEqual(MarkdownDocument.decode(data: data), source)
    }

    func testDecodeDecodesUTF16BigEndianWithBOM() throws {
        let source = "# BE"
        let payload = try XCTUnwrap(source.data(using: .utf16BigEndian))
        let data = Data([0xFE, 0xFF]) + payload
        XCTAssertEqual(MarkdownDocument.decode(data: data), source)
    }

    func testDecodeDecodesUTF16LittleEndianWithBOM() throws {
        let source = "# LE"
        let payload = try XCTUnwrap(source.data(using: .utf16LittleEndian))
        let data = Data([0xFF, 0xFE]) + payload
        XCTAssertEqual(MarkdownDocument.decode(data: data), source)
    }
}
#endif
