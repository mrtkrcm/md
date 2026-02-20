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
        let expected = "# Merhaba"
        let document = MarkdownDocument(text: expected)
        let configuration = MarkdownDocument.WriteConfiguration(contentType: .markdownDocument)

        let wrapper = try document.fileWrapper(configuration: configuration)
        let data = try XCTUnwrap(wrapper.regularFileContents)
        let decoded = String(data: data, encoding: .utf8)

        XCTAssertEqual(decoded, expected)
    }

    func testReadConfigurationDecodesUTF16() throws {
        let source = "# UTF16"
        let data = try XCTUnwrap(source.data(using: .utf16))
        let wrapper = FileWrapper(regularFileWithContents: data)
        let configuration = MarkdownDocument.ReadConfiguration(file: wrapper, contentType: .markdownDocument)

        let document = try MarkdownDocument(configuration: configuration)
        XCTAssertEqual(document.text, source)
    }

    func testReadConfigurationDecodesUTF32WithBOM() throws {
        let source = "# UTF32"
        let payload = try XCTUnwrap(source.data(using: .utf32LittleEndian))
        let data = Data([0xFF, 0xFE, 0x00, 0x00]) + payload
        let wrapper = FileWrapper(regularFileWithContents: data)
        let configuration = MarkdownDocument.ReadConfiguration(file: wrapper, contentType: .markdownDocument)

        let document = try MarkdownDocument(configuration: configuration)
        XCTAssertEqual(document.text, source)
    }

    func testReadConfigurationRejectsVeryLargeFiles() {
        let overLimitSize = MarkdownDocument.maxReadableFileSizeBytes + 1
        let large = Data(repeating: 0x61, count: overLimitSize)
        let wrapper = FileWrapper(regularFileWithContents: large)
        let configuration = MarkdownDocument.ReadConfiguration(file: wrapper, contentType: .markdownDocument)

        XCTAssertThrowsError(try MarkdownDocument(configuration: configuration)) { error in
            guard case let MarkdownDocumentError.fileTooLarge(actualBytes, maxBytes) = error else {
                return XCTFail("Expected MarkdownDocumentError.fileTooLarge, got \(error)")
            }
            XCTAssertEqual(actualBytes, overLimitSize)
            XCTAssertEqual(maxBytes, MarkdownDocument.maxReadableFileSizeBytes)
        }
    }
}
#endif
