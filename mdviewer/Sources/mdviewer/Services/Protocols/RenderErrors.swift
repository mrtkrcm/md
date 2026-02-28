//
//  RenderErrors.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    internal import AppKit
#endif

// MARK: - Rendering Errors

/// Errors that can occur during Markdown rendering.
enum MarkdownRenderError: Error, LocalizedError {
    case parsingFailed(underlying: Error)
    case emptyResult
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .parsingFailed(let error):
            return "Failed to parse Markdown: \(error.localizedDescription)"
        case .emptyResult:
            return "Rendering produced empty output"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}

/// Errors that can occur during Markdown parsing.
enum MarkdownParsingError: Error, LocalizedError {
    case invalidInput
    case systemParserUnavailable
    case parsingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid Markdown input"
        case .systemParserUnavailable:
            return "System Markdown parser is unavailable"
        case .parsingFailed(let error):
            return "Parsing failed: \(error.localizedDescription)"
        }
    }
}
