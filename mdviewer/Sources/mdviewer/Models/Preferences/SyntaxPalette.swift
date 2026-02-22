//
//  SyntaxPalette.swift
//  mdviewer
//

internal import Foundation
#if os(macOS)
    @preconcurrency internal import AppKit
#endif

// MARK: - Syntax Palette

enum SyntaxPalette: String, CaseIterable, Identifiable, Sendable {
    case sundellsColors = "Sundell's Colors"
    case midnight = "Midnight"
    case sunset = "Sunset"
    case presentation = "Presentation"
    case wwdc17 = "WWDC 2017"
    case wwdc18 = "WWDC 2018"

    var id: String { rawValue }

    static func from(rawValue: String) -> SyntaxPalette {
        if let exact = SyntaxPalette(rawValue: rawValue) {
            return exact
        }

        let normalized = rawValue
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return SyntaxPalette.allCases.first {
            $0.rawValue
                .replacingOccurrences(of: "\u{2019}", with: "'")
                .lowercased() == normalized
        } ?? .midnight
    }

    #if os(macOS)
        var nativeSyntax: NativeSyntaxStyle {
            switch self {
            case .sundellsColors:
                return .init(
                    keyword: Self.p3(r: 0.91, g: 0.2, b: 0.54),
                    string: Self.p3(r: 0.98, g: 0.39, b: 0.12),
                    type: Self.p3(r: 0.51, g: 0.51, b: 0.79),
                    number: Self.p3(r: 0.86, g: 0.44, b: 0.34),
                    comment: Self.p3(r: 0.42, g: 0.54, b: 0.58),
                    call: Self.p3(r: 0.2, g: 0.56, b: 0.9)
                )
            case .midnight:
                return .init(
                    keyword: Self.p3(r: 0.828, g: 0.095, b: 0.583),
                    string: Self.p3(r: 1.0, g: 0.171, b: 0.219),
                    type: Self.p3(r: 0.137, g: 1.0, b: 0.512),
                    number: Self.p3(r: 0.469, g: 0.426, b: 1.0),
                    comment: Self.p3(r: 0.255, g: 0.801, b: 0.27),
                    call: Self.p3(r: 0.137, g: 1.0, b: 0.512)
                )
            case .sunset:
                return .init(
                    keyword: Self.p3(r: 0.161, g: 0.259, b: 0.467),
                    string: Self.p3(r: 0.875, g: 0.027, b: 0),
                    type: Self.p3(r: 0.706, g: 0.27, b: 0),
                    number: Self.p3(r: 0.161, g: 0.259, b: 0.467),
                    comment: Self.p3(r: 0.765, g: 0.455, b: 0.11),
                    call: Self.p3(r: 0.278, g: 0.415, b: 0.593)
                )
            case .presentation:
                return .init(
                    keyword: Self.p3(r: 0.706, g: 0.0, b: 0.384),
                    string: Self.p3(r: 0.729, g: 0.0, b: 0.067),
                    type: Self.p3(r: 0.267, g: 0.537, b: 0.576),
                    number: Self.p3(r: 0.0, g: 0.043, b: 1.0),
                    comment: Self.p3(r: 0.336, g: 0.376, b: 0.42),
                    call: Self.p3(r: 0.267, g: 0.537, b: 0.576)
                )
            case .wwdc17:
                return .init(
                    keyword: Self.p3(r: 0.992, g: 0.791, b: 0.45),
                    string: Self.p3(r: 0.966, g: 0.517, b: 0.29),
                    type: Self.p3(r: 0.431, g: 0.714, b: 0.533),
                    number: Self.p3(r: 0.559, g: 0.504, b: 0.745),
                    comment: Self.p3(r: 0.484, g: 0.483, b: 0.504),
                    call: Self.p3(r: 0.431, g: 0.714, b: 0.533)
                )
            case .wwdc18:
                return .init(
                    keyword: Self.p3(r: 0.948, g: 0.140, b: 0.547),
                    string: Self.p3(r: 0.988, g: 0.273, b: 0.317),
                    type: Self.p3(r: 0.584, g: 0.898, b: 0.361),
                    number: Self.p3(r: 0.587, g: 0.517, b: 0.974),
                    comment: Self.p3(r: 0.424, g: 0.475, b: 0.529),
                    call: Self.p3(r: 0.584, g: 0.898, b: 0.361)
                )
            }
        }

        private static func p3(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> NSColor {
            NSColor(displayP3Red: r, green: g, blue: b, alpha: a)
        }
    #endif
}

// MARK: - StoredPreference Conformance

extension SyntaxPalette: StoredPreference {}
