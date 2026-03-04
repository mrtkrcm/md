//
//  RenderRequest.swift
//  mdviewer
//

internal import CryptoKit
internal import Foundation
internal import SwiftUI

#if os(macOS)

    // MARK: - RenderRequest

    struct RenderRequest: Hashable, Sendable {
        let markdown: String
        let readerFontFamily: ReaderFontFamily
        let readerFontSize: CGFloat
        let codeFontSize: CGFloat
        let appTheme: AppTheme
        let syntaxPalette: SyntaxPalette
        let colorScheme: ColorScheme
        let textSpacing: ReaderTextSpacing
        let readableWidth: CGFloat
        let showLineNumbers: Bool
        let typographyPreferences: TypographyPreferences

        var cacheKey: String {
            let prefsHash = typographyPreferences.hashValue
            let payload = [
                markdown,
                readerFontFamily.rawValue,
                String(format: "%.2f", readerFontSize),
                String(format: "%.2f", codeFontSize),
                appTheme.rawValue,
                syntaxPalette.rawValue,
                colorScheme == .dark ? "dark" : "light",
                textSpacing.rawValue,
                String(format: "%.0f", readableWidth),
                showLineNumbers ? "ln" : "no-ln",
                String(prefsHash),
            ].joined(separator: "|")

            let digest = SHA256.hash(data: Data(payload.utf8))
            return digest.map { String(format: "%02x", $0) }.joined()
        }
    }

#endif
