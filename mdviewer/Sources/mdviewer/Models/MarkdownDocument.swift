internal import SwiftUI
internal import UniformTypeIdentifiers
internal import OSLog

extension UTType {
    static var markdownDocument: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }

    static var markdownExtensions: [UTType] {
        let types = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown"),
            UTType(filenameExtension: "mdown"),
            UTType(filenameExtension: "mkd"),
        ]
        return types.compactMap(\.self)
    }
}

enum MarkdownDocumentError: LocalizedError {
    case fileTooLarge(actualBytes: Int, maxBytes: Int)

    var errorDescription: String? {
        switch self {
        case let .fileTooLarge(actualBytes, maxBytes):
            return "File is too large to open (\(actualBytes) bytes). Maximum supported size is \(maxBytes) bytes."
        }
    }
}

struct MarkdownDocument: FileDocument {
    static let starterContent = StarterTemplate.markdown
    static let maxReadableFileSizeBytes = 8 * 1024 * 1024

    private static let logger = Logger(subsystem: "mdviewer", category: "document")

    var text: String

    var isEffectivelyEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

        guard data.count <= Self.maxReadableFileSizeBytes else {
            Self.logger.error("Rejected file over size limit bytes=\(data.count, privacy: .public)")
            throw MarkdownDocumentError.fileTooLarge(actualBytes: data.count, maxBytes: Self.maxReadableFileSizeBytes)
        }

        if let decoded = Self.decode(data: data) {
            text = decoded
            return
        }

        Self.logger.error("Unsupported document string encoding. size=\(data.count, privacy: .public)")
        throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    static func decode(data: Data) -> String? {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return String(data: data.dropFirst(3), encoding: .utf8)
        }
        if data.starts(with: [0x00, 0x00, 0xFE, 0xFF]) {
            return String(data: data.dropFirst(4), encoding: .utf32BigEndian)
        }
        if data.starts(with: [0xFF, 0xFE, 0x00, 0x00]) {
            return String(data: data.dropFirst(4), encoding: .utf32LittleEndian)
        }
        if data.starts(with: [0xFE, 0xFF]) {
            return String(data: data.dropFirst(2), encoding: .utf16BigEndian)
        }
        if data.starts(with: [0xFF, 0xFE]) {
            return String(data: data.dropFirst(2), encoding: .utf16LittleEndian)
        }

        let candidateEncodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .utf32LittleEndian,
            .utf32BigEndian,
            .ascii,
        ]

        return candidateEncodings.lazy.compactMap { String(data: data, encoding: $0) }.first
    }
}
