import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    // Avoid name collision with system type if it exists in future/other contexts
    static var customMarkdown: UTType {
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
            // Check if UTType.markdown is available, otherwise fallback
            // Since the compiler complains about .markdown missing, we use our custom type directly.
            // This ensures compilation regardless of SDK version nuances.
            return [.customMarkdown, .plainText]
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
