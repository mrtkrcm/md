import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var markdownType: UTType {
        UTType.types(tag: "md", tagClass: .filenameExtension, conformingTo: nil).first ?? .plainText
    }
}

struct MarkdownDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] {
        if #available(macOS 11.0, iOS 14.0, *) {
            return [.markdown, .plainText]
        } else {
            return [.plainText]
        }
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
