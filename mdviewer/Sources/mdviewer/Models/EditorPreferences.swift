import SwiftUI
#if os(macOS)
import AppKit
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
    /// Pass `traits` to apply bold/italic/both on top of the base descriptor.
    func nsFont(
        size: CGFloat,
        monospaced: Bool = false,
        traits: NSFontDescriptor.SymbolicTraits = []
    ) -> NSFont {
        let base: NSFont = resolveBaseFont(size: size, monospaced: monospaced)
        guard !traits.isEmpty else { return base }
        let desc = base.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: desc, size: base.pointSize) ?? base
    }

    private func resolveBaseFont(size: CGFloat, monospaced: Bool) -> NSFont {
        // Monospaced: prefer Maple Mono NF when available, fall back to system mono.
        if monospaced {
            if let f = NSFont(name: "MapleMono-NF-Regular", size: size) { return f }
            if let f = NSFont(name: "Maple Mono NF", size: size) { return f }
            let desc = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.monospaced)
            return desc.flatMap { NSFont(descriptor: $0, size: size) }
                ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }

        switch self {
        case .mapleMonoNF:
            if let f = NSFont(name: "MapleMono-NF-Regular", size: size) { return f }
            if let f = NSFont(name: "Maple Mono NF", size: size) { return f }
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)

        case .sfPro:
            // Use system font with default design for SF Pro Text
            return NSFont.systemFont(ofSize: size, weight: .regular)

        case .newYork:
            // "New York" is not accessible via NSFont(name:) — use descriptor design.
            let desc = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)
            if let f = desc.flatMap({ NSFont(descriptor: $0, size: size) }) { return f }
            if let f = NSFont(name: "Georgia", size: size) { return f }
            return NSFont.systemFont(ofSize: size)

        case .georgia:
            if let f = NSFont(name: "Georgia", size: size) { return f }
            let desc = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)
            return desc.flatMap { NSFont(descriptor: $0, size: size) }
                ?? NSFont.systemFont(ofSize: size)
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

    // Extra pixels added after each line (NSParagraphStyle.lineSpacing).
    // At 16pt body: compact ≈ 20pt leading, balanced ≈ 24pt, relaxed ≈ 28pt.
    var lineSpacing: CGFloat {
        switch self {
        case .compact:  return 3
        case .balanced: return 7
        case .relaxed:  return 11
        }
    }

    // Space between paragraph blocks. Expressed as a base that block-specific
    // styles scale — body paragraphs use the full value, headings use multiples.
    // At 16pt body: compact ≈ 0.6 lines, balanced ≈ 1 line, relaxed ≈ 1.5 lines.
    var paragraphSpacing: CGFloat {
        switch self {
        case .compact:  return 10
        case .balanced: return 16
        case .relaxed:  return 22
        }
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
                keyword: NSColor(red: 0.91, green: 0.2, blue: 0.54, alpha: 1),
                string: NSColor(red: 0.98, green: 0.39, blue: 0.12, alpha: 1),
                type: NSColor(red: 0.51, green: 0.51, blue: 0.79, alpha: 1),
                number: NSColor(red: 0.86, green: 0.44, blue: 0.34, alpha: 1),
                comment: NSColor(red: 0.42, green: 0.54, blue: 0.58, alpha: 1),
                call: NSColor(red: 0.2, green: 0.56, blue: 0.9, alpha: 1)
            )
        case .midnight:
            return .init(
                keyword: NSColor(red: 0.828, green: 0.095, blue: 0.583, alpha: 1),
                string: NSColor(red: 1.0, green: 0.171, blue: 0.219, alpha: 1),
                type: NSColor(red: 0.137, green: 1.0, blue: 0.512, alpha: 1),
                number: NSColor(red: 0.469, green: 0.426, blue: 1.0, alpha: 1),
                comment: NSColor(red: 0.255, green: 0.801, blue: 0.27, alpha: 1),
                call: NSColor(red: 0.137, green: 1.0, blue: 0.512, alpha: 1)
            )
        case .sunset:
            return .init(
                keyword: NSColor(red: 0.161, green: 0.259, blue: 0.467, alpha: 1),
                string: NSColor(red: 0.875, green: 0.027, blue: 0, alpha: 1),
                type: NSColor(red: 0.706, green: 0.27, blue: 0, alpha: 1),
                number: NSColor(red: 0.161, green: 0.259, blue: 0.467, alpha: 1),
                comment: NSColor(red: 0.765, green: 0.455, blue: 0.11, alpha: 1),
                call: NSColor(red: 0.278, green: 0.415, blue: 0.593, alpha: 1)
            )
        case .presentation:
            return .init(
                keyword: NSColor(red: 0.706, green: 0.0, blue: 0.384, alpha: 1),
                string: NSColor(red: 0.729, green: 0.0, blue: 0.067, alpha: 1),
                type: NSColor(red: 0.267, green: 0.537, blue: 0.576, alpha: 1),
                number: NSColor(red: 0.0, green: 0.043, blue: 1.0, alpha: 1),
                comment: NSColor(red: 0.336, green: 0.376, blue: 0.42, alpha: 1),
                call: NSColor(red: 0.267, green: 0.537, blue: 0.576, alpha: 1)
            )
        case .wwdc17:
            return .init(
                keyword: NSColor(red: 0.992, green: 0.791, blue: 0.45, alpha: 1),
                string: NSColor(red: 0.966, green: 0.517, blue: 0.29, alpha: 1),
                type: NSColor(red: 0.431, green: 0.714, blue: 0.533, alpha: 1),
                number: NSColor(red: 0.559, green: 0.504, blue: 0.745, alpha: 1),
                comment: NSColor(red: 0.484, green: 0.483, blue: 0.504, alpha: 1),
                call: NSColor(red: 0.431, green: 0.714, blue: 0.533, alpha: 1)
            )
        case .wwdc18:
            return .init(
                keyword: NSColor(red: 0.948, green: 0.140, blue: 0.547, alpha: 1),
                string: NSColor(red: 0.988, green: 0.273, blue: 0.317, alpha: 1),
                type: NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1),
                number: NSColor(red: 0.587, green: 0.517, blue: 0.974, alpha: 1),
                comment: NSColor(red: 0.424, green: 0.475, blue: 0.529, alpha: 1),
                call: NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1)
            )
        }
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
