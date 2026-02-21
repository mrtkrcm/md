internal import SwiftUI
#if os(macOS)
internal import AppKit
#endif

enum AppearanceMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    static func from(rawValue: String) -> AppearanceMode {
        AppearanceMode(rawValue: rawValue) ?? .auto
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum ReaderFontFamily: String, CaseIterable, Identifiable {
    case mapleMonoNF = "Maple Mono NF"
    case sfPro = "SF Pro Text"
    case newYork = "New York"
    case georgia = "Georgia"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderFontFamily {
        ReaderFontFamily(rawValue: rawValue) ?? .newYork
    }

    func font(size: CGFloat) -> SwiftUI.Font {
        switch self {
        case .mapleMonoNF:
            return .custom("Maple Mono NF", size: size)
        case .sfPro:
            return .system(size: size, weight: .regular, design: .default)
        case .newYork:
            return .custom("New York", size: size)
        case .georgia:
            return .custom("Georgia", size: size)
        }
    }

    #if os(macOS)
    /// Returns an NSFont for this family at the given size.
    /// Pass `monospaced: true` to get the code font regardless of the chosen family.
    /// Pass `weight` to control font weight (light, regular, medium, semibold, bold, heavy).
    /// Pass `traits` to apply bold/italic/both on top of the base descriptor.
    func nsFont(
        size: CGFloat,
        monospaced: Bool = false,
        weight: NSFont.Weight = .regular,
        traits: NSFontDescriptor.SymbolicTraits = []
    ) -> NSFont {
        let base: NSFont = resolveBaseFont(size: size, monospaced: monospaced, weight: weight)
        guard !traits.isEmpty else { return base }
        let desc = base.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: desc, size: base.pointSize) ?? base
    }

    private func resolveBaseFont(size: CGFloat, monospaced: Bool, weight: NSFont.Weight) -> NSFont {
        // Monospaced: prefer Maple Mono NF when available, fall back to system mono.
        if monospaced {
            if weight == .regular {
                if let f = NSFont(name: "MapleMono-NF-Regular", size: size) { return f }
                if let f = NSFont(name: "Maple Mono NF", size: size) { return f }
            }
            let desc = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.monospaced)
            return desc.flatMap { NSFont(descriptor: $0, size: size) }
                ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        }

        switch self {
        case .mapleMonoNF:
            // For monospace family, use system mono with weight
            let desc = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.monospaced)
            return desc.flatMap { NSFont(descriptor: $0, size: size) }
                ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)

        case .sfPro:
            // Use system font with specified weight
            return NSFont.systemFont(ofSize: size, weight: weight)

        case .newYork:
            // "New York" is not accessible via NSFont(name:) — use descriptor design.
            let baseFont = NSFont.systemFont(ofSize: size, weight: weight)
            let desc = baseFont.fontDescriptor.withDesign(.serif)
            if let f = desc.flatMap({ NSFont(descriptor: $0, size: size) }) { return f }
            if let f = NSFont(name: "Georgia", size: size) { return f }
            return baseFont

        case .georgia:
            if let f = NSFont(name: "Georgia", size: size) {
                // Georgia loaded by name won't have weight, apply it via descriptor
                if weight != .regular {
                    let desc = f.fontDescriptor.withSymbolicTraits(.bold)
                    if let weighted = NSFont(descriptor: desc, size: size) { return weighted }
                }
                return f
            }
            let baseFont = NSFont.systemFont(ofSize: size, weight: weight)
            let desc = baseFont.fontDescriptor.withDesign(.serif)
            return desc.flatMap { NSFont(descriptor: $0, size: size) }
                ?? baseFont
        }
    }
    #endif
}

enum ReaderFontSize: Int, CaseIterable, Identifiable {
    case compact = 13
    case standard = 16
    case comfortable = 17

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .comfortable: return "Comfortable"
        }
    }

    var points: CGFloat {
        CGFloat(rawValue)
    }

    static func from(rawValue: Int) -> ReaderFontSize {
        ReaderFontSize(rawValue: rawValue) ?? .standard
    }
}

enum CodeFontSize: Int, CaseIterable, Identifiable {
    case small = 12
    case medium = 14
    case large = 16

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    static func from(rawValue: Int) -> CodeFontSize {
        CodeFontSize(rawValue: rawValue) ?? .medium
    }
}

enum ReaderTextSpacing: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case balanced = "Balanced"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderTextSpacing {
        ReaderTextSpacing(rawValue: rawValue) ?? .balanced
    }

    // MARK: - Ratio-Based Typography

    /// Line height multiplier for ratio-based leading.
    /// Returns the line height as a multiple of font size.
    /// - Compact: 1.4x (tight, code-like)
    /// - Balanced: 1.55x (classic book typography)
    /// - Relaxed: 1.7x (airy, accessible)
    var lineHeightMultiplier: CGFloat {
        switch self {
        case .compact:  return 1.4
        case .balanced: return 1.55
        case .relaxed:  return 1.7
        }
    }

    /// Calculates line spacing for a given font size.
    /// This ensures consistent vertical rhythm regardless of font size.
    func lineSpacing(for fontSize: CGFloat) -> CGFloat {
        let targetLineHeight = fontSize * lineHeightMultiplier
        return max(0, targetLineHeight - fontSize)
    }

    /// Calculates paragraph spacing as a multiple of line height.
    /// This maintains visual separation proportional to text size.
    func paragraphSpacing(for fontSize: CGFloat) -> CGFloat {
        let lineHeight = fontSize * lineHeightMultiplier
        switch self {
        case .compact:  return lineHeight * 0.5
        case .balanced: return lineHeight * 0.75
        case .relaxed:  return lineHeight * 1.0
        }
    }

    // MARK: - Legacy Fixed Spacing (for backward compatibility)

    /// Extra pixels added after each line (fixed value for 16pt body).
    @available(*, deprecated, message: "Use lineSpacing(for:) instead")
    var lineSpacing: CGFloat {
        lineSpacing(for: 16)
    }

    /// Space between paragraph blocks (fixed value for 16pt body).
    @available(*, deprecated, message: "Use paragraphSpacing(for:) instead")
    var paragraphSpacing: CGFloat {
        paragraphSpacing(for: 16)
    }

    var kern: CGFloat {
        switch self {
        case .compact:  return 0.04
        case .balanced: return 0.10
        case .relaxed:  return 0.16
        }
    }

    var hyphenationFactor: Float {
        switch self {
        case .compact:  return 0.15
        case .balanced: return 0.20
        case .relaxed:  return 0.25
        }
    }
}

enum ReaderColumnWidth: String, CaseIterable, Identifiable {
    case narrow = "Narrow"
    case balanced = "Balanced"
    case wide = "Wide"

    var id: String { rawValue }

    static func from(rawValue: String) -> ReaderColumnWidth {
        ReaderColumnWidth(rawValue: rawValue) ?? .balanced
    }

    var points: CGFloat {
        switch self {
        case .narrow: return 680
        case .balanced: return 760
        case .wide: return 860
        }
    }
}

enum SyntaxPalette: String, CaseIterable, Identifiable {
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
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return SyntaxPalette.allCases.first {
            $0.rawValue
                .replacingOccurrences(of: "’", with: "'")
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

#if os(macOS)
struct NativeSyntaxStyle {
    let keyword: NSColor
    let string: NSColor
    let type: NSColor
    let number: NSColor
    let comment: NSColor
    let call: NSColor
}
#endif
