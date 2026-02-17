import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var markdownDocument: UTType {
        if #available(macOS 11.0, iOS 14.0, *) {
            return UTType(importedAs: "net.daringfireball.markdown")
        }
        return UTType(filenameExtension: "md") ?? .plainText
    }

    static var markdownExtensions: [UTType] {
        let types = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown"),
            UTType(filenameExtension: "mdown"),
            UTType(filenameExtension: "mkd")
        ]
        return types.compactMap { $0 }
    }
}

struct MarkdownDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] {
        var seen = Set<String>()
        let types = [UTType.markdownDocument] + UTType.markdownExtensions + [.plainText]
        return types.filter { seen.insert($0.identifier).inserted }
    }

    static var writableContentTypes: [UTType] {
        [.markdownDocument]
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        // Support the most common encodings used by markdown files.
        let candidateEncodings: [String.Encoding] = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian, .ascii]
        if let decoded = candidateEncodings.lazy.compactMap({ String(data: data, encoding: $0) }).first {
            text = decoded
            return
        }

        throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
